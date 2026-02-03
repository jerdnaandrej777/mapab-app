# CHANGELOG v1.9.5 - 700km Absolutes Tageslimit + Korridor-Browser Fix

**Datum:** 3. Februar 2026
**Build:** 1.9.5+152 (vorher +151)

## Zusammenfassung

Tag 7 eines 7-Tage-Trips konnte ~1683km anzeigen (Movie Park Germany → Cambourne, England). Die 700km-Grenze wurde massiv ueberschritten, weil das Clustering nur die rohe Haversine-Distanz (500km) pruefte, nicht die angezeigte Distanz (Haversine × 1.35). Ausserdem wurde das Rueckkehr-Segment am letzten Tag beim Clustering ignoriert. Diese Version behebt das Problem auf 4 Ebenen.

---

## Fix 1: Display-basiertes Splitting in _clusterPOIsByDistance()

### Vorher

Das Splitting-Kriterium nutzte die rohe Haversine-Distanz (`maxKmPerDay = 500km`):

```dart
// VORHER - Nur Haversine-Distanz
if (projectedDayKm > TripConstants.maxKmPerDay) {
  shouldStartNewDay = true;
}
```

500km Haversine × 1.35 = 675km Display — knapp unter 700km, aber mit Rueckkehr-Segment leicht ueberschreitbar.

### Nachher

Splitting nutzt jetzt die projizierte Display-Distanz (Haversine × 1.35 > 700km):

```dart
// NACHHER - Display-Distanz
final projectedDisplayKm = projectedDayKm * TripConstants.haversineToDisplayFactor;
if (projectedDisplayKm > TripConstants.maxDisplayKmPerDay) {
  shouldStartNewDay = true;
}
```

### Entfernte "Sicherheitsregel"

Die alte Regel verhinderte das Splitten wenn nur 1 POI uebrig war — auch wenn 700km dadurch ueberschritten wurden:

```dart
// ENTFERNT
final remainingPOIs = pois.length - i;
if (shouldStartNewDay && remainingPOIs == 1 &&
    currentCluster.length < TripConstants.maxPoisPerDay) {
  shouldStartNewDay = false;
}
```

---

## Fix 2: Neue Methode _splitLastDayIfOverLimit()

Post-Processing fuer den letzten Tag bei Rundreisen (`returnToStart = true`).

### Problem

Das Clustering beruecksichtigte das Rueckkehr-Segment zum Startpunkt nicht. Ein letzter Tag mit 300km Haversine + 400km Rueckkehr = 700km Haversine × 1.35 = 945km Display.

### Loesung

```dart
void _splitLastDayIfOverLimit(List<List<POI>> clusters, LatLng startLocation) {
  // 1. Gesamt-Display-Distanz des letzten Tages inkl. Rueckkehr berechnen
  final dayKm = _calculateClusterDistance(lastCluster, lastDayStart);
  final returnKm = GeoUtils.haversineDistance(lastCluster.last.location, startLocation);
  final totalDisplayKm = (dayKm + returnKm) * TripConstants.haversineToDisplayFactor;

  // 2. Wenn > 700km: POIs vom Anfang des letzten Tages in neuen Tag verschieben
  while (remainingLast.length > 1) {
    newSecondToLast.add(remainingLast.removeAt(0));
    // Pruefen ob verbleibender letzter Tag + Rueckkehr jetzt unter 700km
    if (newTotalDisplay <= TripConstants.maxDisplayKmPerDay) break;
  }

  // 3. Neuen vorletzten Tag einfuegen
  clusters.insert(lastIdx, newSecondToLast);
}
```

---

## Fix 3: Merge-Guard in _mergeShortDays()

### Vorher

Kurze Tage (< 150km Haversine) wurden mit dem Vortag zusammengelegt — ohne Pruefung ob das 700km-Limit ueberschritten wird:

```dart
// VORHER - Kein Display-Limit-Check
if (dayKm < TripConstants.minKmPerDay &&
    prevCluster.length + cluster.length <= TripConstants.maxPoisPerDay) {
  clusters[i - 1] = [...prevCluster, ...cluster];
}
```

### Nachher

Vor dem Merge wird die kombinierte Display-Distanz geprueft:

```dart
// NACHHER - 700km-Guard
final mergedKm = _calculateClusterDistance(mergedCluster, prevStart);
final mergedDisplayKm = mergedKm * TripConstants.haversineToDisplayFactor;

if (mergedDisplayKm > TripConstants.maxDisplayKmPerDay) {
  debugPrint('[DayPlanner] Merge verhindert: ~${mergedDisplayKm}km > 700km Limit');
  continue; // Merge verhindern
}
```

---

## Fix 4: returnToStart in planDays() Distanzberechnung

### Vorher

Die Distanzberechnung im planDays-Loop nutzte immer `returnToStart: false` — auch fuer den letzten Tag einer Rundreise:

```dart
// VORHER - Immer false
final distance = _routeOptimizer.calculateTotalDistance(
  pois: optimizedDayPois,
  startLocation: currentStartLocation,
  returnToStart: false,  // Rueckkehr-Segment fehlt!
);
```

### Nachher

Letzter Tag einer Rundreise rechnet das Rueckkehr-Segment ein:

```dart
// NACHHER - returnToStart fuer letzten Tag
final includeReturn = isLastDay && returnToStart;
final distance = _routeOptimizer.calculateTotalDistance(
  pois: optimizedDayPois,
  startLocation: currentStartLocation,
  returnToStart: includeReturn,
);
```

---

## Fix 5: TripConstants Helper-Getter

Neuer Getter fuer die maximale Haversine-Distanz die das Display-Limit einhaelt:

```dart
/// 700 / 1.35 ≈ 518.5km Haversine
static double get maxHaversineKmForDisplay =>
    maxDisplayKmPerDay / haversineToDisplayFactor;
```

---

## Fix 6: Post-Validierung in trip_generator_repo.dart

### generateEuroTrip()

Diagnostische Warnung nach planDays() wenn ein Tag trotzdem > 700km Display-Distanz hat:

```dart
for (final day in tripDays) {
  if (day.distanceKm != null) {
    final displayKm = day.distanceKm! * TripConstants.haversineToDisplayFactor;
    if (displayKm > TripConstants.maxDisplayKmPerDay) {
      debugPrint('[TripGenerator] ⚠️ WARNING: Tag ${day.dayNumber} = ~${displayKm}km');
    }
  }
}
```

### _removePOIFromDay()

Display-Distanz des modifizierten Tages wird nach Rebuild geprueft:

```dart
final dayDisplayKm = result.trip.getDistanceForDay(targetDay);
if (dayDisplayKm > TripConstants.maxDisplayKmPerDay) {
  debugPrint('[TripGenerator] ⚠️ WARNING: RemovePOI Tag $targetDay = ~${dayDisplayKm}km');
}
```

---

## Geaenderte Dateien (3) — Build +151

| # | Datei | Aenderung |
|---|-------|-----------|
| 1 | `lib/core/constants/trip_constants.dart` | Neuer Getter `maxHaversineKmForDisplay` (700 / 1.35 ≈ 518.5km) |
| 2 | `lib/core/algorithms/day_planner.dart` | Display-basiertes Splitting, Sicherheitsregel entfernt, `_splitLastDayIfOverLimit()` neu, Merge-Guard, returnToStart durchgereicht, Distanzberechnung letzter Tag korrigiert |
| 3 | `lib/data/repositories/trip_generator_repo.dart` | Post-Validierung in `generateEuroTrip()` + `_removePOIFromDay()` |

---

## Debug-Logging

| Log | Bedeutung |
|-----|-----------|
| `[DayPlanner] Letzter Tag ~Xkm Display (inkl. Rueckkehr) > 700km Limit → Split` | Letzter Tag wird gesplittet |
| `[DayPlanner] Split: N POIs → neuer Tag, letzter Tag ~Xkm Display` | Split erfolgreich |
| `[DayPlanner] Merge verhindert: Tag X + Tag Y = ~Zkm Display > 700km Limit` | Merge durch Guard verhindert |
| `[DayPlanner]   Tag X: N POIs, Ykm Haversine, ~Zkm Display` | Cluster-Debug mit Display-Distanz |
| `[TripGenerator] ⚠️ WARNING: Tag X = ~Ykm Display > 700km Limit nach planDays()` | Post-Validierung Warnung |

---

## Build +152: Korridor-Browser POI-Hinzufuegen Fix + Vollbild

### Problem 1: POI aus Korridor-Browser erscheint nicht im DayEditor

**Ursache:** Der Korridor-Browser fuegt POIs ueber `POITripHelper` zu `tripStateProvider` hinzu, aber der DayEditor liest aus `randomTripNotifierProvider.generatedTrip.trip.stops` — zwei getrennte State-Stores. Ergebnis: SnackBar zeigt "hinzugefuegt", aber der POI erscheint nicht in der Tagesliste.

**Loesung:** Neuer `onAddPOI`-Callback in `CorridorBrowserSheet`. Der DayEditor uebergibt eine Callback-Funktion die direkt `randomTripNotifier.addPOIToDay(poi, selectedDay)` aufruft:

```dart
// day_editor_overlay.dart - _BottomActions
CorridorBrowserSheet.show(
  context: context,
  route: trip.route,
  existingStopIds: trip.stops.map((s) => s.poiId).toSet(),
  onAddPOI: (poi) async {
    final success = await ref
        .read(randomTripNotifierProvider.notifier)
        .addPOIToDay(poi, selectedDay);
    return success;
  },
);
```

**Neue Methode `addPOIToDay()` in `RandomTripNotifier`:**
- Ruft `_tripGenerator.addPOIToTrip()` auf
- Re-optimiert nur den betroffenen Tag (Nearest-Neighbor + 2-opt)
- Berechnet OSRM-Gesamtroute neu via `_rebuildRouteForDayEdit()`
- Synchronisiert `tripStateProvider` via `setRouteAndStops()`
- Persistiert Active Trip bei Multi-Day
- Enriched den neuen POI fuer Foto-Anzeige

**Neue Methode `addPOIToTrip()` in `TripGeneratorRepository`:**
- Multi-Day: Delegiert an `_addPOIToDay()` (Pattern wie `_removePOIFromDay`)
- Single-Day: Globale Re-Optimierung + OSRM-Neuberechnung

### Problem 2: Korridor-Browser nicht Vollbild

**Loesung:** `DraggableScrollableSheet`-Parameter geaendert:
- `initialChildSize: 0.7` → `1.0` (oeffnet sofort Vollbild)
- `maxChildSize: 0.95` → `1.0`
- `minChildSize: 0.4` → `0.5` (Drag-to-close bleibt)
- Drag-Handle entfernt (nicht noetig bei Vollbild)
- `borderRadius` entfernt (Vollbild-Modus)

### Geaenderte Dateien (4) — Build +152

| # | Datei | Aenderung |
|---|-------|-----------|
| 1 | `lib/features/trip/widgets/corridor_browser_sheet.dart` | Vollbild (initialChildSize 1.0), `onAddPOI` Callback-Parameter, Drag-Handle entfernt |
| 2 | `lib/data/repositories/trip_generator_repo.dart` | Neue Methoden `addPOIToTrip()` + `_addPOIToDay()` |
| 3 | `lib/features/random_trip/providers/random_trip_provider.dart` | Neue Methode `addPOIToDay()`, POI-Import |
| 4 | `lib/features/trip/widgets/day_editor_overlay.dart` | `onAddPOI`-Callback an CorridorBrowserSheet uebergeben |

### Debug-Logging (Build +152)

| Log | Bedeutung |
|-----|-----------|
| `[TripGenerator] AddPOI Tag X: Fuege NAME hinzu` | POI wird zu Tag X hinzugefuegt |
| `[TripGenerator] AddPOI Tag X: N Stops total` | Anzahl Stops nach Hinzufuegen |
| `[TripGenerator] WARNING: AddPOI Tag X = ~Ykm Display > 700km Limit` | Distanz-Warnung |
| `[RandomTrip] POI "NAME" zu Tag X hinzugefuegt` | Erfolg im Provider |
