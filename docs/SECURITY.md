# Security Guide - Credentials & API Keys

Diese Dokumentation beschreibt den sicheren Umgang mit Credentials und API-Keys in der MapAB Flutter App.

## Inhaltsverzeichnis

1. [Problem: Hardcoded Credentials](#problem-hardcoded-credentials)
2. [Falscher Ansatz: flutter_dotenv](#falscher-ansatz-flutter_dotenv)
3. [Korrekter Ansatz: --dart-define](#korrekter-ansatz---dart-define)
4. [Build-Scripts](#build-scripts)
5. [Sicherheitsvergleich](#sicherheitsvergleich)
6. [Best Practices](#best-practices)

---

## Problem: Hardcoded Credentials

**Sicherheitslücke:**
Credentials direkt im Quellcode sind ein Sicherheitsrisiko:

```dart
// UNSICHER!
class SupabaseConfig {
  static const String supabaseUrl = 'https://xyz.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGci...'; // Im Klartext!
}
```

**Warum ist das problematisch?**

1. **Git-History**: Credentials werden committed und bleiben in der History
2. **APK-Dekompilierung**: Android-APKs können einfach entpackt werden
3. **Open-Source**: Bei öffentlichen Repos sind Keys für jeden sichtbar
4. **Rotation schwierig**: Key-Änderung erfordert neuen Build

---

## Falscher Ansatz: flutter_dotenv

**Versuchte Lösung:**

```yaml
# pubspec.yaml
flutter:
  assets:
    - .env  # FALSCH!
```

**Problem:** Flutter-Assets werden **in die APK eingebettet**!

```bash
# APK entpacken → Assets im Klartext!
unzip app-release.apk -d extracted
cat extracted/assets/flutter_assets/.env
# SUPABASE_URL=https://xyz.supabase.co
# SUPABASE_ANON_KEY=eyJhbGci...
```

Dies ist **Security Theater** - sieht sicher aus, ist es aber nicht!

---

## Korrekter Ansatz: --dart-define

Credentials werden zur **Build-Zeit** über Compiler-Flags übergeben.

### Implementierung

```dart
// lib/core/supabase/supabase_config.dart
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

```dart
// lib/core/constants/api_config.dart
class ApiConfig {
  static const String backendBaseUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: '',
  );
}
```

### Verwendung

```bash
# Development
flutter run \
  --dart-define=SUPABASE_URL=https://xyz.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGci... \
  --dart-define=BACKEND_URL=https://backend.vercel.app

# Release Build
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://xyz.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGci... \
  --dart-define=BACKEND_URL=https://backend.vercel.app
```

---

## Build-Scripts

Erstelle lokale Build-Scripts, die **NICHT in Git committed** werden:

### Windows (run_dev.bat)

```batch
@REM run_dev.bat - Für Entwicklung
@echo off
flutter run ^
  --dart-define=SUPABASE_URL=https://xyz.supabase.co ^
  --dart-define=SUPABASE_ANON_KEY=eyJhbGci... ^
  --dart-define=BACKEND_URL=https://backend.vercel.app
pause
```

### Windows (build_release.bat)

```batch
@REM build_release.bat - Für Release-Build
@echo off
flutter build apk --release ^
  --dart-define=SUPABASE_URL=https://xyz.supabase.co ^
  --dart-define=SUPABASE_ANON_KEY=eyJhbGci... ^
  --dart-define=BACKEND_URL=https://backend.vercel.app
pause
```

### Linux/macOS (run_dev.sh)

```bash
#!/bin/bash
flutter run \
  --dart-define=SUPABASE_URL=https://xyz.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGci... \
  --dart-define=BACKEND_URL=https://backend.vercel.app
```

### .gitignore Ergänzungen

```gitignore
# Build scripts with credentials (niemals committen!)
run_dev.bat
build_release.bat
run_dev.sh
build_release.sh

# Environment files
.env
.env.local
.env.*.local

# API Keys (niemals committen!)
**/secrets.dart
**/api_keys.dart
```

### Referenz-Datei (.env.example)

Erstelle eine `.env.example` ohne echte Werte als Referenz:

```bash
# .env.example - Diese Datei KANN committed werden
# Kopiere zu .env.local und fülle die echten Werte ein

SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
BACKEND_URL=https://your-backend.vercel.app
```

---

## Sicherheitsvergleich

| Methode | Sicherheit | Problem |
|---------|------------|---------|
| Hardcoded im Code | Sehr schlecht | Im Git + APK sichtbar |
| flutter_dotenv + Asset | Schlecht | .env in APK eingebettet |
| --dart-define | Mittel | In kompiliertem Code, aber nicht trivial auslesbar |
| Backend-Proxy | Gut | Secrets nur auf Server |

### Wichtiger Hinweis

`--dart-define` ist **nicht 100% sicher**!

Entschlossene Angreifer können:
1. APK dekompilieren
2. Dart-Code analysieren
3. Strings im Binary finden

**Für kritische Secrets (API-Keys mit Kosten) immer Backend-Proxy verwenden!**

---

## Best Practices

### 1. Supabase Anon Key ist "okay" im Client

Der Supabase Anon Key ist designed, um im Client zu sein:
- **Row Level Security (RLS)** schützt die Daten
- User können nur eigene Daten sehen/ändern
- Kritische Operationen erfordern Server-Side Validation

### 2. OpenAI API-Key NIEMALS im Client

```dart
// FALSCH - API-Key im Client
final response = await dio.post(
  'https://api.openai.com/v1/chat/completions',
  options: Options(headers: {'Authorization': 'Bearer $openaiKey'}),
);

// RICHTIG - Über Backend-Proxy
final response = await dio.post(
  'https://your-backend.vercel.app/api/ai/chat',
  // Kein API-Key im Client!
);
```

### 3. Rate-Limiting im Backend

```javascript
// Backend: api/ai/chat.js
export default async function handler(req, res) {
  // Rate-Limiting prüfen
  const requests = await getRequestCount(req.ip);
  if (requests > 100) {
    return res.status(429).json({ error: 'Rate limit exceeded' });
  }

  // OpenAI Call mit Server-seitigem Key
  const response = await openai.createChatCompletion({
    // process.env.OPENAI_API_KEY ist nur auf Server verfügbar
  });
}
```

### 4. Key-Rotation

Bei kompromittierten Keys:
1. Neuen Key in Supabase/Backend generieren
2. Alten Key deaktivieren
3. Build-Scripts aktualisieren
4. Neuen Build veröffentlichen

### 5. CI/CD Secrets

Für GitHub Actions:

```yaml
# .github/workflows/build.yml
- name: Build APK
  run: |
    flutter build apk --release \
      --dart-define=SUPABASE_URL=${{ secrets.SUPABASE_URL }} \
      --dart-define=SUPABASE_ANON_KEY=${{ secrets.SUPABASE_ANON_KEY }}
```

Secrets werden in GitHub Repository Settings → Secrets → Actions hinterlegt.
