# Changelog v1.3.1 - Credentials-Sicherung

**Release-Datum:** 23. Januar 2026

## Sicherheits-Fix

### Credentials-Sicherung mit --dart-define

**Problem gefunden:** Supabase-Credentials waren direkt im Quellcode hardcodiert. Dies ist ein Sicherheitsrisiko:
- Credentials werden mit Git committed (auch in History)
- APK kann dekompiliert werden → Keys auslesbar
- Bei Open-Source-Projekten öffentlich sichtbar

**Falscher Ansatz verworfen:** `flutter_dotenv` mit `.env` als Flutter-Asset
- Flutter-Assets werden **in die APK eingebettet**
- Jeder kann die APK entpacken und `.env` im Klartext lesen
- Dies ist "Security Theater" - sieht sicher aus, ist es aber nicht!

**Korrekter Ansatz:** `--dart-define` zur Build-Zeit
- Credentials werden als Compiler-Flags übergeben
- In kompilierten Code eingebettet (nicht als separates Asset)
- Build-Scripts mit Credentials werden **nicht** committed

## Geänderte Dateien

| Datei | Änderung |
|-------|----------|
| `lib/core/supabase/supabase_config.dart` | `String.fromEnvironment()` statt hardcoded |
| `lib/core/constants/api_config.dart` | `String.fromEnvironment()` statt hardcoded |
| `lib/core/constants/api_keys.dart` | `String.fromEnvironment()` statt hardcoded |
| `.gitignore` | Build-Scripts + Secrets hinzugefügt |
| `run_dev.bat` (NEU) | Development Runner mit Credentials |
| `build_release.bat` (NEU) | Release Builder mit Credentials |
| `.env.local` (NEU) | Lokale Referenz-Datei für Entwickler |

## Neue Konfiguration

### supabase_config.dart
```dart
class SupabaseConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty &&
      !supabaseUrl.contains('your-project') &&
      supabaseAnonKey.isNotEmpty &&
      supabaseAnonKey != 'your-anon-key';
}
```

### api_config.dart
```dart
class ApiConfig {
  static const String backendBaseUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: '',
  );

  static bool get isConfigured => backendBaseUrl.isNotEmpty;
}
```

## Build-Scripts (nicht im Git!)

### run_dev.bat
```batch
@echo off
REM MapAB Development Runner
flutter run ^
  --dart-define=SUPABASE_URL=https://xxx.supabase.co ^
  --dart-define=SUPABASE_ANON_KEY=eyJhbGci... ^
  --dart-define=BACKEND_URL=https://backend.vercel.app
pause
```

### build_release.bat
```batch
@echo off
REM MapAB Release Build
flutter build apk --release ^
  --dart-define=SUPABASE_URL=https://xxx.supabase.co ^
  --dart-define=SUPABASE_ANON_KEY=eyJhbGci... ^
  --dart-define=BACKEND_URL=https://backend.vercel.app
pause
```

## .gitignore Ergänzungen

```gitignore
# Build scripts with credentials (niemals committen!)
run_dev.bat
build_release.bat
run_dev.sh
build_release.sh

# API Keys (niemals committen!)
**/secrets.dart
**/api_keys.dart
```

## Sicherheits-Vergleich

| Methode | Sicherheit | Erklärung |
|---------|------------|-----------|
| Hardcoded im Code | Kritisch | Im Git + APK sichtbar |
| flutter_dotenv + Asset | Kritisch | .env in APK eingebettet |
| --dart-define | Mittel | In kompiliertem Code, schwerer auslesbar |
| Backend-Proxy | Gut | Secrets nur auf Server |

## Wichtiger Hinweis

`--dart-define` ist **nicht 100% sicher**! Entschlossene Angreifer können dekompilierten Code analysieren.

**Für kritische Secrets (API-Keys mit Kosten):**
- Immer Backend-Proxy verwenden
- OpenAI-Key ist bereits auf Backend-Proxy (Vercel)

**Warum Supabase Anon Key "okay" ist:**
- Designed um im Client zu sein
- Row Level Security (RLS) schützt die Daten
- User können nur eigene Daten sehen/ändern

## Setup-Anleitung für Entwickler

1. **Clone Repository**
   ```bash
   git clone https://github.com/user/mapab-app.git
   cd mapab-app
   ```

2. **Erstelle Build-Scripts**
   ```bash
   # run_dev.bat erstellen mit deinen Credentials
   # Siehe .env.local als Vorlage
   ```

3. **App starten**
   ```bash
   # Nicht flutter run direkt!
   run_dev.bat  # oder run_dev.sh auf Linux/Mac
   ```

4. **Release Build**
   ```bash
   build_release.bat
   # APK in: build/app/outputs/flutter-apk/app-release.apk
   ```

---

**Vollständige Dokumentation:** Siehe CLAUDE.md → "Credentials-Sicherung mit --dart-define (v1.3.1)"
