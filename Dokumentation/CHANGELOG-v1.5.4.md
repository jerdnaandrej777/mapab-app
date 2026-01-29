# Changelog v1.5.4

**Release-Datum:** 26. Januar 2026

## Verbesserungen

### GPS-Button ohne Test-Standort München

**Vorher:** Wenn GPS deaktiviert war oder ein Fehler auftrat, wurde automatisch München (48.1351, 11.5820) als Test-Standort verwendet.

**Nachher:**
- Bei deaktivierten Ortungsdiensten → Dialog fragt ob GPS-Einstellungen geöffnet werden sollen
- Bei GPS-Fehler → Fehlermeldung ohne Fallback-Standort

**Neues Verhalten:**

1. **GPS deaktiviert:**
   - Dialog erscheint: "GPS deaktiviert"
   - Text: "Die Ortungsdienste sind deaktiviert. Möchtest du die GPS-Einstellungen öffnen?"
   - Button "Nein" → Dialog schließt, keine Aktion
   - Button "Einstellungen öffnen" → Öffnet GPS-Einstellungen (`Geolocator.openLocationSettings()`)

2. **GPS-Fehler:**
   - SnackBar: "GPS-Position konnte nicht ermittelt werden."
   - Kein München-Fallback mehr

**Betroffene Datei:** `lib/features/map/map_screen.dart`

## Technische Details

### Geänderte Methode: `_centerOnLocation()`

```dart
// VORHER - München als Fallback
if (!serviceEnabled) {
  debugPrint('[GPS] Location Services deaktiviert - verwende Test-Standort (München)');
  const testLocation = LatLng(48.1351, 11.5820);
  mapController.move(testLocation, 12.0);
  _showSnackBar('Test-Standort: München\n(Emulator hat kein GPS)', duration: 4);
  return;
}

// NACHHER - Dialog anzeigen
if (!serviceEnabled) {
  debugPrint('[GPS] Location Services deaktiviert');
  final shouldOpenSettings = await _showGpsDialog();
  if (shouldOpenSettings) {
    await Geolocator.openLocationSettings();
  }
  return;
}
```

### Neue Methode: `_showGpsDialog()`

```dart
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
```

### Geänderte Dateien

| Datei | Änderung |
|-------|----------|
| `lib/features/map/map_screen.dart` | `_centerOnLocation()` ohne München-Fallback, neue `_showGpsDialog()` Methode |
| `pubspec.yaml` | Version 1.5.4 |
| `CLAUDE.md` | GPS-Dokumentation aktualisiert |

## Migration

Keine manuellen Schritte erforderlich. Die Änderungen sind abwärtskompatibel.

## Konsistenz mit anderen Features

Das Verhalten ist jetzt konsistent mit `RandomTripProvider`, der bereits bei deaktivierten Ortungsdiensten die Meldung "Bitte aktiviere die Ortungsdienste in den Einstellungen" anzeigt.

---

**Vorherige Version:** [v1.5.3](CHANGELOG-v1.5.3.md)
