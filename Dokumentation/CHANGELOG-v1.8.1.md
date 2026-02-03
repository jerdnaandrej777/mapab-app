# CHANGELOG v1.8.1 - Tagesrouten-Optimierung & Auto-Zoom

**Datum:** 2. Februar 2026
**Build:** 1.8.1+143

## Zusammenfassung

Drei zusammenhaengende Verbesserungen fuer die Trip-Planung: **Richtungs-optimierte Routen** (kein Hin-und-Her bei A→B Trips), **Distanz-basierte Tagesaufteilung** (200-700 km pro Reisetag statt gleichmaessige POI-Verteilung) und **Auto-Zoom bei Tageswechsel** (Hauptkarte zoomt auf jeweiliges Tages-Segment).

---

## Feature 1: Richtungs-optimierte Routen

### Problem
Der bestehende RouteOptimizer nutzt Nearest-Neighbor + 2-opt (TSP), was fuer Rundreisen gut funktioniert. Bei A→B Trips (z.B. Muenchen → Rom) konnte die optimierte Route aber Hin-und-Her-Fahrten erzeugen, weil der Algorithmus keine Reiserichtung beruecksichtigt.

### Loesung

**Neue Methode `optimizeDirectionalRoute()`** (`route_optimizer.dart:46`):
```dart
List<POI> optimizeDirectionalRoute({
  required List<POI> pois,
  required LatLng startLocation,
  required LatLng endLocation,
})
```

Algorithmus:
1. **Hauptachsen-Projektion**: Jeder POI wird auf die Achse Start→Ziel projiziert (Skalarprodukt)
2. **Vorwaerts-Sortierung**: POIs nach Projektions-Position sortiert (t=0.0 am Start, t=1.0 am Ziel)
3. **Lokale 2-opt**: Begrenzte Optimierung mit `windowSize=4`, um die Gesamtrichtung beizubehalten

**Neue Methode `_localTwoOpt()`** (`route_optimizer.dart:90`):
- Tauscht nur benachbarte Segmente innerhalb des Fensters
- Verhindert, dass weit entfernte POIs getauscht werden und die Richtung umkehren
- Max 50 Iterationen

**Hilfsklasse `_POIProjection`** (`route_optimizer.dart:318`):
- Speichert POI + Projektions-Wert (t) auf der Hauptachse

**Fallback**: Wenn Start und Ziel fast identisch sind (`axisLengthSq < 0.0001`), wird der Standard-TSP-Algorithmus verwendet.

### Integration in Trip-Generierung

**`trip_generator_repo.dart`** - Beide Trip-Typen nutzen jetzt bedingte Optimierung:
```dart
if (hasDestination) {
  optimizedPOIs = _routeOptimizer.optimizeDirectionalRoute(
    pois: selectedPOIs,
    startLocation: startLocation,
    endLocation: destinationLocation!,
  );
} else {
  optimizedPOIs = _routeOptimizer.optimizeRoute(
    pois: selectedPOIs,
    startLocation: startLocation,
    returnToStart: true,
  );
}
```

Betrifft:
- `generateDayTrip()` (Zeile ~111)
- `generateEuroTrip()` (Zeile ~242)

---

## Feature 2: Distanz-basierte Tagesaufteilung

### Problem
Der bisherige `_clusterPOIsByGeography()` verteilte POIs gleichmaessig nach Anzahl auf Tage. Das konnte dazu fuehren, dass ein Tag nur 50 km und ein anderer 800 km hatte.

### Loesung

**Neue Konstanten** (`trip_constants.dart:45`):
```dart
static const double minKmPerDay = 150.0;   // ~200km echte Fahrtstrecke
static const double maxKmPerDay = 500.0;    // ~650-700km echte Fahrtstrecke
static const double idealKmPerDay = 350.0;  // Mitte des Zielbereichs
```

> **Hinweis**: Haversine-Distanzen sind ca. 30% kuerzer als echte Fahrstrecken (Faktor ~1.3). Die Konstanten sind so gewaehlt, dass die reale Fahrdistanz im Bereich 200-700 km liegt.

**Neue Methode `_clusterPOIsByDistance()`** (`day_planner.dart:122`):

Algorithmus:
1. POIs sind bereits in optimierter Reihenfolge (aus Feature 1)
2. Iteriere durch die Liste und berechne kumulative Haversine-Distanz
3. Neuer Tag wenn: kumulative Distanz > `maxKmPerDay` (500km) ODER 9 POIs erreicht (Google Maps Limit)
4. Sicherheit: Letzter einzelner POI wird nicht abgetrennt
5. Tagesanzahl wird dynamisch bestimmt (kann von User-Eingabe abweichen)

**Neue Methode `_mergeShortDays()`** (`day_planner.dart:197`):
- Post-Processing: Zu kurze Tage (< `minKmPerDay` = 150km) mit dem Vortag zusammenlegen
- Nur wenn Google Maps Limit (9 POIs) nicht ueberschritten wird
- Iteriert rueckwaerts durch die Cluster-Liste

**Neue Methode `_calculateClusterDistance()`** (`day_planner.dart:223`):
- Berechnet kumulative Haversine-Distanz eines Clusters
- Wird sowohl fuer Clustering als auch fuer Merge-Entscheidung genutzt

**Debug-Logging**:
```
[DayPlanner] Distanz-Clustering: 5 angefragt → 3 Tage
[DayPlanner]   Tag 1: 4 POIs, 320km (Haversine)
[DayPlanner]   Tag 2: 5 POIs, 410km (Haversine)
[DayPlanner]   Tag 3: 3 POIs, 280km (Haversine)
[DayPlanner] Merge: Tag 4 (90km) mit Tag 3 zusammengelegt
```

### Dynamische Tagesanzahl

**`trip_generator_repo.dart`** - Nach `planDays()` wird die tatsaechliche Cluster-Anzahl verwendet:
```dart
final actualDays = tripDays.length;
if (actualDays != effectiveDays) {
  debugPrint('[TripGenerator] Tagesanzahl angepasst: $effectiveDays angefragt → $actualDays optimal');
}
```

Trip-Erstellung nutzt `actualDays` statt `effectiveDays`. Gleiche Anpassung in `removePOI()` und `rerollPOI()` mit `updatedDays = tripDays.length`.

### Echte Tages-Distanzen im Trip-Model

**`trip.dart`** - `getDistanceForDay()` verbessert (Zeile 123):
- Tag 1 startet am `route.start`
- Ab Tag 2 am letzten Stop des Vortags
- Haversine-Summe ueber alle Stops des Tages
- Fallback: Gleichmaessige Aufteilung wenn Vortags-Stops fehlen

**Neue statische Methode `_haversineDistance()`** (`trip.dart:155`):
- Inline-Implementierung, da Freezed-Klassen keinen direkten GeoUtils-Import erlauben
- Erdradius: 6371 km

---

## Feature 3: Auto-Zoom bei Tageswechsel

### Problem
Beim Wechsel zwischen Tagen im DayEditorOverlay zoomte die Mini-Map korrekt auf das Tages-Segment, aber die Hauptkarte (MapView) blieb unveraendert.

### Loesung

**Neuer Listener in `map_view.dart`** (in `_setupWeatherListeners()`):
```dart
ref.listenManual(randomTripNotifierProvider, (previous, next) {
  if (previous?.selectedDay != next.selectedDay &&
      next.generatedTrip != null &&
      next.generatedTrip!.trip.actualDays > 1) {
    _zoomToDaySegment(next);
  }
});
```

**Neue Methode `_zoomToDaySegment()`** (`map_view.dart`):
1. Holt Stops fuer den ausgewaehlten Tag
2. Bestimmt Startpunkt: Tag 1 = Trip-Start, ab Tag 2 = letzter Stop des Vortags
3. Berechnet Bounds aus allen relevanten Punkten
4. `_mapController.fitCamera(CameraFit.bounds(padding: 60))`

### Distanz-Anzeige

**`day_editor_overlay.dart`** - Tilde (~) entfernt:
- Vorher: `~320 km`
- Nachher: `320 km`
- Grund: Werte sind jetzt echte Haversine-Berechnungen, keine Approximationen mehr

---

## Fix: Ziel-Eingabe BottomSheet oeffnet vollstaendig

### Problem
Das BottomSheet fuer die Zieleingabe (bei AI Trips) oeffnete sich nur minimal (`mainAxisSize: MainAxisSize.min`). Die Vorschlagsliste war auf `maxHeight: 200` begrenzt. Bei geoeffneter Tastatur wurde der Inhalt abgeschnitten und Vorschlaege waren kaum sichtbar.

### Loesung

**`map_screen.dart`** - `_showDestinationSheet()` Builder:
- Sheet bekommt jetzt feste Hoehe: `screenHeight * 0.5` (50% des Bildschirms)
- Tastatur wird weiterhin beruecksichtigt (`viewInsets.bottom` Padding)

```dart
final sheetHeight = screenHeight * 0.5;
return Padding(
  padding: EdgeInsets.only(bottom: keyboardHeight),
  child: SizedBox(
    height: sheetHeight,
    child: _DestinationSheetContent(...),
  ),
);
```

**`_DestinationSheetContent`**:
- `mainAxisSize: MainAxisSize.min` entfernt → Column fuellt verfuegbaren Platz
- Vorschlagsliste nutzt `Expanded` statt `BoxConstraints(maxHeight: 200)`
- `shrinkWrap: true` entfernt (nicht noetig mit Expanded)
- Ohne Vorschlaege: `SizedBox.shrink()` im Expanded

### Ergebnis
- Sheet oeffnet immer auf halbe Bildschirmhoehe
- Vorschlagsliste fuellt den gesamten Platz zwischen Suchfeld und Hinweistext
- Keine abgeschnittenen Vorschlaege mehr bei geoeffneter Tastatur

---

## Geaenderte Dateien

| # | Datei | Aenderung |
|---|-------|-----------|
| 1 | `lib/core/algorithms/route_optimizer.dart` | `optimizeDirectionalRoute()`, `_localTwoOpt()`, `_POIProjection` |
| 2 | `lib/core/constants/trip_constants.dart` | `minKmPerDay`, `maxKmPerDay`, `idealKmPerDay` |
| 3 | `lib/core/algorithms/day_planner.dart` | `_clusterPOIsByDistance()`, `_mergeShortDays()`, `_calculateClusterDistance()` |
| 4 | `lib/data/models/trip.dart` | `getDistanceForDay()` + `_haversineDistance()` |
| 5 | `lib/data/repositories/trip_generator_repo.dart` | Directional Optimization + dynamische Tagesanzahl |
| 6 | `lib/features/map/widgets/map_view.dart` | Auto-Zoom Listener + `_zoomToDaySegment()` |
| 7 | `lib/features/trip/widgets/day_editor_overlay.dart` | Tilde entfernt bei Distanz-Anzeige |
| 8 | `lib/features/map/map_screen.dart` | Ziel-BottomSheet: 50% Hoehe + Expanded Vorschlagsliste |

---

## Edge Cases

- **Kurze Routen** (< 200km gesamt): Bleibt als 1 Tag, kein Split
- **Sehr lange Tage**: `maxKmPerDay=500` (Haversine) sorgt fuer max ~700km echte Strecke
- **Weniger Tage als angefragt**: Wenn 7 Tage angefragt aber Route nur 3 Tage braucht → 3 Tage zurueckgeben
- **Letzter Tag zu kurz**: `_mergeShortDays()` merged mit Vortag wenn moeglich (POI-Limit beachtet)
- **Start = Ziel**: Fallback auf Standard-TSP (Nearest-Neighbor + 2-opt)
- **1-Tages-Trip**: Verhalten unveraendert (alle POIs in einem Tag)
- **rerollPOI/removePOI**: Tagesaufteilung wird neu berechnet, Tagesanzahl kann sich aendern
