# Changelog v1.5.9

**Datum:** 26.01.2026

## Hotfix: APK mit Supabase-Credentials (27.01.2026)

Das erste Release wurde ohne `--dart-define` Parameter gebaut, wodurch die Supabase-Credentials fehlten und der Login nicht funktionierte.

**Problem:** Login nicht möglich - "Cloud nicht verfügbar"
**Ursache:** APK ohne `SUPABASE_URL` und `SUPABASE_ANON_KEY` gebaut
**Lösung:** APK neu gebaut mit korrektem Build-Befehl:

```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=... \
  --dart-define=BACKEND_URL=...
```

**WICHTIG:** Immer `build_release.bat` verwenden statt manuell `flutter build apk`!

---

## GPS-Teststandort München entfernt

### Problem

Bei deaktiviertem GPS oder fehlender Berechtigung wurde in der POI-Liste automatisch München (48.1351, 11.5820) als Fallback-Standort verwendet. Dies war verwirrend für Benutzer, die plötzlich POIs in München sahen, obwohl sie sich woanders befanden.

### Lösung

Konsistentes Verhalten wie beim GPS-Button auf der Karte (v1.5.4):

1. **GPS-Service-Check**: Prüfung ob Ortungsdienste aktiviert sind
2. **Dialog bei deaktiviertem GPS**: Fragt ob GPS-Einstellungen geöffnet werden sollen
3. **SnackBar bei verweigerter Berechtigung**: Informiert den Benutzer
4. **Kein automatischer Fallback**: Benutzer muss GPS aktivieren

### Verhalten

| Situation | Vorher (v1.5.8) | Nachher (v1.5.9) |
|-----------|-----------------|------------------|
| GPS deaktiviert | München als Fallback | Dialog: "GPS-Einstellungen öffnen?" |
| Berechtigung verweigert | München als Fallback | SnackBar: "GPS-Berechtigung wird benötigt" |
| GPS-Fehler | München als Fallback | SnackBar: "GPS-Position konnte nicht ermittelt werden" |

### Verbleibende München-Referenzen

Diese wurden bewusst beibehalten:

| Datei | Verwendung | Grund |
|-------|------------|-------|
| `sharing_service.dart` | Fallback für leere Routen | Technischer Fallback, praktisch nie erreicht |
| `search_screen.dart` | Autocomplete-Vorschlag | Feature: München neben Berlin, Hamburg, Köln |

## Geänderte Dateien

| Datei | Änderung |
|-------|----------|
| `lib/features/poi/poi_list_screen.dart` | GPS-Fallback durch Dialog ersetzt |
| `pubspec.yaml` | Version 1.5.9 |

## Technische Details

### Neue Methoden in POIListScreen

```dart
/// Dialog anzeigen wenn GPS deaktiviert ist (v1.5.9)
Future<bool> _showGpsDialog() async {
  return await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('GPS deaktiviert'),
      content: const Text(
        'Die Ortungsdienste sind deaktiviert. Möchtest du die GPS-Einstellungen öffnen?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Nein'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Einstellungen öffnen'),
        ),
      ],
    ),
  ) ?? false;
}

/// SnackBar anzeigen wenn GPS-Berechtigung verweigert wurde
void _showPermissionDeniedSnackBar() {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('GPS-Berechtigung wird benötigt um POIs in der Nähe zu finden'),
      duration: Duration(seconds: 4),
    ),
  );
}
```

### Geänderter GPS-Flow

```dart
// Prüfen ob Location Services aktiviert sind
final serviceEnabled = await Geolocator.isLocationServiceEnabled();
if (!serviceEnabled) {
  final openSettings = await _showGpsDialog();
  if (openSettings) {
    await Geolocator.openLocationSettings();
  }
  return; // Kein Fallback mehr
}

// Permission-Check mit Handling für denied/deniedForever
final permission = await Geolocator.checkPermission();
if (permission == LocationPermission.denied) {
  final newPermission = await Geolocator.requestPermission();
  if (newPermission == LocationPermission.denied ||
      newPermission == LocationPermission.deniedForever) {
    _showPermissionDeniedSnackBar();
    return;
  }
}
```

## Konsistenz

Diese Änderung macht das GPS-Verhalten konsistent über die gesamte App:

| Screen | GPS deaktiviert | Berechtigung verweigert |
|--------|-----------------|-------------------------|
| MapScreen (v1.5.4) | Dialog | - |
| POIListScreen (v1.5.9) | Dialog | SnackBar |
| RandomTripProvider | Fehlermeldung | Fehlermeldung |
