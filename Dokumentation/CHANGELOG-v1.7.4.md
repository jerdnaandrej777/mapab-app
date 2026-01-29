# Changelog v1.7.4 - Auto-Route von GPS-Standort zu POI

**Release-Datum:** 29. Januar 2026

## Übersicht

Version 1.7.4 führt eine intuitive neue Funktion ein: Wenn ein POI zur Route hinzugefügt wird und noch keine Route existiert, wird automatisch eine Route vom aktuellen GPS-Standort zum ausgewählten POI erstellt.

## Neue Features

### Auto-Route bei POI-Hinzufügen

Wenn ein Benutzer einen POI zur Route hinzufügt (über POI-Liste, POI-Details oder Karten-Popup) und noch keine Route vorhanden ist:

1. **GPS-Standort wird ermittelt** - Der aktuelle Standort dient als Startpunkt
2. **POI wird als Ziel gesetzt** - Der ausgewählte POI ist das Routenziel
3. **Route wird automatisch berechnet** - OSRM berechnet die schnellste Route
4. **Navigation zum Trip-Tab** - Benutzer wird automatisch zum Trip-Tab geleitet

**Vorher:** Benutzer musste manuell Start und Ziel setzen, dann POIs hinzufügen.

**Nachher:** Ein Klick auf "Zur Route" genügt - der Rest passiert automatisch.

## Technische Änderungen

### trip_state_provider.dart

```dart
/// Neue Methode: addStopWithAutoRoute()
Future<AddStopResult> addStopWithAutoRoute(POI poi) async {
  // Wenn bereits eine Route existiert, einfach den Stop hinzufügen
  if (state.route != null) {
    addStop(poi);
    return const AddStopResult(success: true);
  }

  // Keine Route vorhanden - GPS-Standort als Start verwenden
  // 1. GPS-Status prüfen
  // 2. Berechtigung prüfen
  // 3. Position abrufen
  // 4. Route berechnen: GPS → POI
  // 5. Flag für Auto-Zoom setzen
}

/// Result-Klasse für Fehlerbehandlung
class AddStopResult {
  final bool success;
  final bool routeCreated;
  final String? error;
  final String? message;

  bool get isGpsDisabled => error == 'gps_disabled';
  bool get isPermissionDenied => ...;
}
```

### Angepasste UI-Dateien

- **poi_list_screen.dart** - `_addPOIToTrip()` async mit GPS-Dialog
- **poi_detail_screen.dart** - `_addToTrip()` async mit GPS-Dialog
- **map_view.dart** - Neuer `_addPOIToTripFromMap()` Handler

### GPS-Dialog bei deaktiviertem GPS

```dart
Future<bool> _showGpsDialog() async {
  return await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('GPS deaktiviert'),
      content: const Text(
        'Die Ortungsdienste sind deaktiviert. '
        'Möchtest du die GPS-Einstellungen öffnen?',
      ),
      actions: [
        TextButton(child: const Text('Nein'), ...),
        FilledButton(child: const Text('Einstellungen öffnen'), ...),
      ],
    ),
  ) ?? false;
}
```

## Benutzerfluss

### Szenario 1: Keine Route vorhanden

1. Benutzer öffnet POI-Liste oder POI-Details
2. Klickt auf "Zur Route" Button
3. GPS-Position wird ermittelt (ca. 1-2 Sekunden)
4. Route wird berechnet
5. SnackBar: "Route zu [POI-Name] erstellt"
6. Automatische Navigation zum Trip-Tab

### Szenario 2: Route bereits vorhanden

1. Benutzer hat bereits eine Route
2. Klickt auf "Zur Route" bei einem POI
3. POI wird als Zwischenstopp hinzugefügt
4. Route wird mit Waypoint neu berechnet
5. Normale Funktionsweise wie bisher

### Szenario 3: GPS deaktiviert

1. Benutzer klickt auf "Zur Route" ohne aktive Route
2. GPS-Dialog erscheint: "GPS deaktiviert"
3. Option A: "Einstellungen öffnen" → GPS-Settings
4. Option B: "Nein" → Abbrechen

## Fehlerbehandlung

| Fehlercode | Situation | Benutzer-Nachricht |
|------------|-----------|-------------------|
| `gps_disabled` | GPS deaktiviert | Dialog mit Option GPS-Einstellungen zu öffnen |
| `permission_denied` | Berechtigung verweigert | "GPS-Berechtigung wurde verweigert." |
| `permission_denied_forever` | Dauerhaft verweigert | "Bitte in den Einstellungen aktivieren." |
| `route_error` | Routing-Fehler | "Fehler beim Erstellen der Route: [Details]" |

## Code-Beispiele

### Verwendung im Code

```dart
// POI zur Route hinzufügen (automatisch oder manuell)
final result = await ref.read(tripStateProvider.notifier)
    .addStopWithAutoRoute(poi);

if (result.success) {
  if (result.routeCreated) {
    // Neue Route wurde erstellt
    context.go('/trip');
  }
  // Sonst: Stop wurde zu bestehender Route hinzugefügt
} else if (result.isGpsDisabled) {
  // GPS-Dialog anzeigen
  final shouldOpen = await _showGpsDialog();
  if (shouldOpen) {
    await Geolocator.openLocationSettings();
  }
}
```

## Dateien

### Geänderte Dateien

| Datei | Änderung |
|-------|----------|
| `lib/features/trip/providers/trip_state_provider.dart` | Neue `addStopWithAutoRoute()` Methode + `AddStopResult` Klasse |
| `lib/features/poi/poi_list_screen.dart` | `_addPOIToTrip()` async mit GPS-Handling |
| `lib/features/poi/poi_detail_screen.dart` | `_addToTrip()` async mit GPS-Handling |
| `lib/features/map/widgets/map_view.dart` | Neue `_addPOIToTripFromMap()` Methode |
| `pubspec.yaml` | Version 1.7.4 |

## Kompatibilität

- Vollständig abwärtskompatibel
- Bestehende `addStop()` Methode bleibt unverändert
- Keine Breaking Changes für andere Provider

## Bekannte Einschränkungen

1. GPS-Timeout: 10 Sekunden - bei schwachem Signal kann es fehlschlagen
2. Bei Indoor-Nutzung kann GPS ungenau sein
3. Erste Route wird immer als "schnelle Route" (OSRM) berechnet

---

**Nächste Version:** TBD
