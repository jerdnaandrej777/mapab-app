# CHANGELOG v1.9.25 - Navigation Performance-Fix

**Datum:** 2026-02-04
**Version:** 1.9.25+172
**Typ:** Performance-Fix

## Problem

Die Navigation haengt sich auf / friert ein waehrend der Fahrt.

## Ursachen-Analyse

6 Performance-Probleme die zusammenwirken:

### 1. O(n*m) in `_findCurrentStep()` bei JEDEM GPS-Tick (KRITISCH)
- `_findCurrentStep()` iterierte durch ALLE Steps und rief fuer JEDEN Step `findNearestIndex()` auf (O(n) ueber alle Route-Koordinaten)
- Bei 50 Steps + 1000 Routenpunkten = **50.000 Operationen pro GPS-Update**
- GPS-Updates kommen ~1-2x pro Sekunde → 100.000 Operationen/Sekunde

### 2. Doppelter `findNearestIndex()` Aufruf pro GPS-Tick
- Zeile 411: `findNearestIndex(routeCoords, stepInfo.nextStepLocation)` wurde NOCHMAL aufgerufen um die Distanz zum naechsten Step zu berechnen
- Weitere O(n) = 1000 Operationen pro Tick unnoetig

### 3. `_updateRouteSources()` bei JEDEM `build()` (KRITISCH)
- `build()` wurde bei jedem State-Change aufgerufen (jeder GPS-Tick)
- Jeder Aufruf queute einen `PostFrameCallback` der 2x `setGeoJsonSource()` auf MapLibre ausfuehrte
- MapLibre GeoJSON-Updates sind synchron und blockieren den UI-Thread
- Ergebnis: ~2 teure MapLibre-Updates pro GPS-Tick

### 4. `_updatePOIMarkerColors()` bei JEDEM `build()`
- Iterierte ALLE POI-Marker und rief `controller.updateCircle()` auf - bei jedem Rebuild
- Bei 10 POIs = 10 native MapLibre-Calls pro GPS-Tick, auch wenn sich nichts geaendert hat

### 5. `animateCamera()` statt `moveCamera()` bei 60fps (KRITISCH)
- 60fps-Interpolation rief `animateCamera(duration: 100ms)` auf
- Bei 60fps kamen alle 16ms neue Aufrufe - jeder mit 100ms Animationsdauer
- Ergebnis: **6 gleichzeitige Animationen** stapelten sich, MapLibre Native Thread ueberlastet

### 6. POI-Discovery Listener feuerte bei JEDEM State-Change
- `ref.listen(navigationNotifierProvider, ...)` feuerte bei jedem `state.copyWith()`
- Jeder Aufruf berechnete `distanceBetween()` fuer alle Must-See POIs
- Bei 10 POIs + 2 GPS-Ticks/Sekunde = 20 Haversine-Berechnungen/Sekunde (nicht kritisch allein, aber addiert sich)

## Kumulativer Effekt

```
Pro GPS-Tick (1-2x pro Sekunde):
  _findCurrentStep:     50.000 Vergleiche (FIX: 50 Vergleiche via Cache)
  findNearestIndex:      1.000 Vergleiche (FIX: 0, gecachter Index)
  _updateRouteSources:   2 native MapLibre-Calls (FIX: nur bei Index-Aenderung)
  _updatePOIMarkerColors: 10 native Calls (FIX: nur bei visitedStopIds-Aenderung)
  animateCamera (60fps): 6 parallele Animationen (FIX: moveCamera, keine Stacking)
  POI-Discovery:         10 Haversine (FIX: max alle 500ms)
```

## Fixes (4 Dateien)

### `lib/features/navigation/providers/navigation_provider.dart`
1. **Step-Index-Cache:** `_stepRouteIndices` wird einmalig bei Route-Aenderung aufgebaut
2. **`_buildStepRouteIndexCache()`:** Mappt jeden Step auf seinen Route-Koordinaten-Index (einmalig O(n*m), danach O(m) pro Tick)
3. **`_findCurrentStep()` optimiert:** Nutzt gecachten Index statt `findNearestIndex()` → O(m) statt O(n*m)
4. **`_StepInfo.nextStepRouteIndex`:** Gecachter Index fuer Distanz-Berechnung, eliminiert zweiten `findNearestIndex()`-Aufruf
5. **Cache-Lifecycle:** Aufgebaut in `startNavigation()` + `_reroute()`, geleert in `stopNavigation()`

### `lib/features/navigation/navigation_screen.dart`
1. **Route-Update Throttling:** `_updateRouteSources()` nur wenn `matchedRouteIndex` sich aendert (statt bei jedem build)
2. **POI-Marker Throttling:** `_updatePOIMarkerColors()` nur wenn `visitedStopIds` sich aendert
3. **`moveCamera()` statt `animateCamera()`:** Keine Animation-Stacking bei 60fps, sofortige Kamera-Positionierung

### `lib/features/navigation/providers/navigation_poi_discovery_provider.dart`
1. **500ms Throttle:** POI-Proximity-Check max 2x pro Sekunde statt bei jedem State-Change

## Betroffene Dateien (4)

| Datei | Aenderungen |
|-------|-------------|
| `navigation_provider.dart` | Step-Index-Cache, _buildStepRouteIndexCache(), optimierte _findCurrentStep(), _StepInfo.nextStepRouteIndex |
| `navigation_screen.dart` | Route/POI-Update nur bei Aenderung, moveCamera statt animateCamera |
| `navigation_poi_discovery_provider.dart` | 500ms Throttle im Listener |
| `navigation_provider.g.dart` | Generiert (build_runner) |

## Performance-Verbesserung

| Metrik | Vorher | Nachher | Faktor |
|--------|--------|---------|--------|
| _findCurrentStep Ops/Tick | 50.000 | 50 | **1000x** |
| findNearestIndex Calls/Tick | 2 (je O(n)) | 0 | **eliminiert** |
| MapLibre native Calls/Tick | 12+ | 0-2 | **6x weniger** |
| Camera Animation Stacking | 6 parallel | 0 | **eliminiert** |
| POI Discovery Calls/Sekunde | 2+ | max 2 (throttled) | **garantiert** |

## Test-Plan

1. **Hang-Test:** Navigation starten → 5 Minuten fahren → App bleibt fluessig, kein Einfrieren
2. **Langer Trip:** Navigation mit 50+ Steps → keine CPU-Spitze
3. **Route-Update:** Route-Linie aktualisiert sich visuell bei Fortschritt
4. **POI-Besuch:** Besuchte POIs werden grau markiert
5. **Kamera:** Kamera folgt fluessig ohne Ruckeln
6. **POI-Discovery:** Must-See POIs werden bei Annaeherung angezeigt
7. **Rerouting:** Nach Abweichung → neue Route, Step-Cache wird neu aufgebaut
