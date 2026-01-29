# Changelog v1.5.8

**Datum:** 26.01.2026

## Login-Screen Verbesserungen

### Bugfix: Login-Formular immer sichtbar

**Problem:** Das Login-Formular wurde nur angezeigt, wenn Supabase konfiguriert war. Bei fehlenden `--dart-define` Parametern war nur der "Als Gast fortfahren" Button sichtbar - ohne Erklärung warum.

**Lösung:**
- Login-Formular wird jetzt **immer** angezeigt
- Bei fehlender Supabase-Konfiguration erscheint eine **Warnmeldung**
- Beim Login-Versuch ohne Konfiguration erscheint ein **Snackbar-Fehler**

### Debug-Output für Supabase-Konfiguration

Neuer Debug-Output im Login-Screen:
```
[Login] isCloudAvailable: true/false
[Login] SUPABASE_URL: https://...
[Login] SUPABASE_ANON_KEY: eyJ...
```

Dies hilft bei der Diagnose von Konfigurationsproblemen.

## Geänderte Dateien

| Datei | Änderung |
|-------|----------|
| `lib/features/auth/login_screen.dart` | Login-Formular immer anzeigen, Warnungen hinzugefügt |
| `pubspec.yaml` | Version 1.5.8 |

## Technische Details

### Vorher (fehlerhaft)
```dart
// Login-Formular nur wenn Cloud verfügbar
if (isCloudAvailable) ...[
  _buildCloudLoginForm(...),
],
```

### Nachher (korrekt)
```dart
// Login-Formular IMMER anzeigen
_buildCloudLoginForm(..., isCloudAvailable),

// Mit Warnung bei fehlender Konfiguration
if (!isCloudAvailable) ...[
  Container(
    // Warnmeldung: "Cloud nicht verfügbar..."
  ),
],
```

## Wichtig für Entwicklung

Die App muss mit `--dart-define` Parametern gebaut werden:
```bash
flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

Oder verwende die Build-Scripts:
- `run_dev.bat` - Entwicklung
- `build_release.bat` - Release
