# CHANGELOG v1.7.39 - Aktiver Trip Persistenz

**Datum:** 2. Februar 2026
**Build:** 1.7.39+139

## Zusammenfassung

Mehrtaegige Euro Trips werden jetzt automatisch als **aktiver Trip** in Hive gespeichert, sobald der erste Tag an Google Maps exportiert wird. Nach App-Neustart erscheint ein **Resume-Banner** auf dem MapScreen, ueber das der Trip fortgesetzt werden kann. Nach Abschluss aller Tage erscheint ein **Abschluss-Dialog** mit Option zum Speichern in Favoriten.

---

## Neue Features

### 1. Automatische Trip-Persistenz

Bei mehrtaegigen Euro Trips wird der komplette State nach jeder Aenderung in Hive gespeichert:
- Nach `confirmTrip()` (Trip bestaetigt)
- Nach `completeDay()` (Tag exportiert)
- Nach `selectDay()` (Tag gewechselt)
- Nach `uncompleteDay()` (Tag zurueckgesetzt)

Gespeicherte Daten:
- Trip-Objekt (Name, Route, Stops mit day-Feld)
- Abgeschlossene Tage (Set<int>)
- Ausgewaehlter Tag
- Ausgewaehlte und verfuegbare POIs
- Konfiguration: Startort, Modus, Tage, Radius, Zielort

### 2. Resume-Banner auf MapScreen

Ein Banner erscheint auf dem MapScreen wenn:
- Ein aktiver Trip in Hive gespeichert ist
- Kein Trip aktuell im Arbeitsspeicher geladen ist
- Nicht alle Tage abgeschlossen sind

Das Banner zeigt:
- Trip-Name und Modus-Icon
- Fortschritts-Balken (LinearProgressIndicator)
- "Tag X steht an" / "X von Y Tagen abgeschlossen"
- **Fortsetzen** Button: Stellt Trip, Route und POIs wieder her
- **X** Button: "Trip verwerfen?" Bestaetigungs-Dialog

### 3. Ueberschreib-Warnung bei neuem Trip

Wenn ein aktiver Trip existiert und der User einen neuen Trip generieren will, erscheint ein Bestaetigungs-Dialog:
- "Aktiver Trip vorhanden"
- "X von Y Tagen abgeschlossen. Neuer Trip ueberschreibt diesen."
- Buttons: "Abbrechen" / "Neuen Trip erstellen"

### 4. Trip-Abschluss-Dialog

Nach Export des letzten Tages an Google Maps:
- "Trip abgeschlossen!" Dialog
- "Alle X Tage wurden erfolgreich exportiert."
- **In Favoriten speichern**: Speichert Trip + loescht aktiven Trip + navigiert zur Karte
- **Behalten**: Trip bleibt als aktiver Trip gespeichert

---

## Neue Dateien

| Datei | Beschreibung |
|-------|--------------|
| `lib/data/providers/active_trip_provider.dart` | Riverpod AsyncNotifier (keepAlive: true) fuer reaktiven Zugriff auf aktiven Trip |

---

## Geaenderte Dateien

| Datei | Aenderungen |
|-------|-------------|
| `lib/data/services/active_trip_service.dart` | Erweitert um POI-Serialisierung, Konfigurationsfelder (Start, Modus, Tage, Radius, Ziel). ActiveTripData mit allen neuen Feldern |
| `lib/data/providers/active_trip_provider.dart` | **NEU** - @Riverpod(keepAlive: true) ActiveTripNotifier mit build(), refresh(), clear(). Export von ActiveTripData |
| `lib/features/random_trip/providers/random_trip_provider.dart` | Neue Methoden: _persistActiveTrip(), restoreFromActiveTrip(). Persistenz in confirmTrip, completeDay, uncompleteDay, selectDay, reset, generateTrip |
| `lib/features/map/map_screen.dart` | _ActiveTripResumeBanner Widget, Ueberschreib-Dialog in _handleGenerateTrip() |
| `lib/features/trip/trip_screen.dart` | _showTripCompletedDialog() nach letztem Tag-Export |

---

## ActiveTripService Erweiterung

### Neue Hive-Keys

```dart
static const String _selectedPOIsKey = 'selected_pois_json';
static const String _availablePOIsKey = 'available_pois_json';
static const String _startLatKey = 'start_lat';
static const String _startLngKey = 'start_lng';
static const String _startAddressKey = 'start_address';
static const String _modeKey = 'mode';
static const String _daysKey = 'days';
static const String _radiusKmKey = 'radius_km';
static const String _destinationLatKey = 'destination_lat';
static const String _destinationLngKey = 'destination_lng';
static const String _destinationAddressKey = 'destination_address';
```

### ActiveTripData (erweitert)

```dart
class ActiveTripData {
  final Trip trip;
  final Set<int> completedDays;
  final int selectedDay;
  final List<POI> selectedPOIs;      // NEU
  final List<POI> availablePOIs;     // NEU
  final LatLng? startLocation;       // NEU
  final String? startAddress;        // NEU
  final RandomTripMode mode;         // NEU
  final int days;                    // NEU
  final double radiusKm;             // NEU
  final LatLng? destinationLocation; // NEU
  final String? destinationAddress;  // NEU
}
```

---

## RandomTripProvider Erweiterung

### Neue Methoden

```dart
/// Speichert den kompletten Trip-State in Hive
Future<void> _persistActiveTrip() async {
  final generatedTrip = state.generatedTrip;
  if (generatedTrip == null) return;
  await ref.read(activeTripServiceProvider).saveTrip(
    trip: generatedTrip.trip,
    completedDays: state.completedDays,
    selectedDay: state.selectedDay,
    selectedPOIs: generatedTrip.selectedPOIs,
    availablePOIs: generatedTrip.availablePOIs,
    startLocation: state.startLocation,
    startAddress: state.startAddress,
    mode: state.mode,
    days: state.days,
    radiusKm: state.radiusKm,
    destinationLocation: state.destinationLocation,
    destinationAddress: state.destinationAddress,
  );
  ref.read(activeTripNotifierProvider.notifier).refresh();
}

/// Stellt Trip aus Hive wieder her
Future<void> restoreFromActiveTrip(ActiveTripData data) async {
  // 1. GeneratedTrip rekonstruieren
  // 2. State setzen (step: confirmed, completedDays, selectedDay, etc.)
  // 3. Route + Stops laden (setRouteAndStops)
  // 4. Auto-Zoom ausloesen
  // 5. POIs enrichen
}
```

### Geaenderte Methoden

| Methode | Aenderung |
|---------|-----------|
| `generateTrip()` | Loescht alten aktiven Trip, setzt completedDays/selectedDay zurueck |
| `confirmTrip()` | Persistiert bei Multi-Day |
| `completeDay()` | Persistiert nach Markierung |
| `uncompleteDay()` | Persistiert nach Aenderung |
| `selectDay()` | Aktualisiert Tag in Hive |
| `reset()` | Loescht aktiven Trip + refresht Provider |

---

## Edge Cases

| Szenario | Behandlung |
|----------|------------|
| App wird waehrend Trip beendet | State ist nach jedem completeDay() in Hive |
| Neuer Trip waehrend aktiver Trip | Bestaetigungs-Dialog → alter Trip wird ueberschrieben |
| Nur ein aktiver Trip gleichzeitig | Hive-Keys sind fix → neuer Save ueberschreibt alten |
| Einzel-Tag-Trip | Persistenz nur bei isMultiDay |
| uncompleteDay() (Rueckgaengig) | State wird neu persistiert |
| Alle Tage fertig | Dialog: Favoriten speichern oder Behalten |
| POI-Serialisierung defekt | try-catch in loadTrip() → gibt null zurueck, Banner erscheint nicht |

---

## Verifikation

1. Euro Trip (3+ Tage) generieren
2. Tag 1 an Google Maps exportieren → Trip wird in Hive gespeichert
3. App komplett schliessen und neu starten
4. MapScreen zeigt "Aktiver Trip" Banner mit Fortschritt
5. "Fortsetzen" klicken → Trip + Route wird wiederhergestellt
6. Tag 2 exportieren → Banner zeigt aktualisierten Fortschritt
7. Alle Tage exportieren → "Trip abgeschlossen" Dialog erscheint
8. Neuen Trip generieren waehrend aktiver Trip existiert → Ueberschreib-Warnung
