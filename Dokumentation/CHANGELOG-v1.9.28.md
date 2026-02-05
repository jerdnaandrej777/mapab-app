# CHANGELOG v1.9.28 - Euro Trip Crash-Fix

**Datum:** 4. Februar 2026
**Version:** 1.9.28+175
**Typ:** Stabilitaets-Release (22 Fixes in 7 Phasen)

## Zusammenfassung

Euro Trips (mehrtaegige Reisen 1-14 Tage) verursachten Abstuerze durch Null-Safety-Verletzungen, Listener-Lifecycle-Fehler, Performance-Probleme bei grossen POI-Mengen und Race Conditions. Dieses Release behebt 22 Probleme in 14 Dateien.

---

## Phase 1: Null-Safety Guards (KRITISCH)

### Fix 1.1: Force-unwrap `startLocation!` abgesichert
**Datei:** `lib/features/random_trip/providers/random_trip_provider.dart`
**Problem:** `state.startLocation!` wurde in 5 Methoden force-unwrapped. Zwischen Null-Check und Verwendung konnte ein async-Op den State aendern → NPE.
**Fix:** Lokale Variable-Capture (`final startLoc = state.startLocation`) mit Null-Check und Fehlermeldung in: `generateTrip()`, `rerollPOI()`, `removePOI()`, `addPOIToDay()`, `removePOIFromDay()`.

### Fix 1.2: Force-unwrap `lastResult!` abgesichert
**Datei:** `lib/data/repositories/trip_generator_repo.dart`
**Problem:** In `rerollPOI()` und `_rerollPOIForDay()` wurde `lastResult!` force-unwrapped. Wenn alle Reroll-Versuche fehlschlugen → NPE.
**Fix:** Null-Check + `TripGenerationException` statt force-unwrap.

---

## Phase 2: Listener-Lifecycle Fixes (KRITISCH)

### Fix 2.1: MapScreen Listener-Subscriptions
**Datei:** `lib/features/map/map_screen.dart`
**Problem:** 3x `ref.listenManual()` ohne Cancellation in `dispose()`. Doppelter Listener auf `routePlannerProvider`.
**Fix:** `List<ProviderSubscription<dynamic>> _subscriptions` speichert alle Listener. Doppelter routePlannerProvider-Listener gemergt. Alle Subscriptions in `dispose()` mit `.close()` beendet.

### Fix 2.2: MapView Listener-Subscriptions
**Datei:** `lib/features/map/widgets/map_view.dart`
**Problem:** 4x `ref.listenManual()` ohne Cancellation. Doppelter Listener auf `randomTripNotifierProvider`.
**Fix:** Gleicher Ansatz wie MapScreen - Subscriptions speichern, Duplikate mergen, in `dispose()` canceln.

### Fix 2.3: DayEditorOverlay mounted-Guards
**Datei:** `lib/features/trip/widgets/day_editor_overlay.dart`
**Problem:** `loadSmartRecommendations()` in `addPostFrameCallback` ohne mounted-Guard. startLocation force-unwrap.
**Fix:** `if (!mounted) return;` in Callbacks. Null-Safety fuer `state.startLocation` mit Fallback-UI.

---

## Phase 3: Race-Condition Guards (HOCH)

### Fix 3.1: generateTrip() Doppel-Aufruf-Guard
**Datei:** `lib/features/random_trip/providers/random_trip_provider.dart`
**Problem:** Kein Guard gegen parallele Ausfuehrung - doppeltes Tippen startete 2 Generierungen.
**Fix:** `if (state.step == RandomTripStep.generating) return;` am Anfang.

### Fix 3.2: Provider-Refresh try-catch
**Datei:** `lib/features/random_trip/providers/random_trip_provider.dart`
**Problem:** `ref.read(activeTripNotifierProvider.notifier).refresh()` konnte crashen wenn Provider disposed.
**Fix:** In try-catch gewrapped an beiden Aufrufstellen.

---

## Phase 4: Performance-Fixes (HOCH)

### Fix 4.1: Wikipedia-Grid Batching
**Datei:** `lib/data/repositories/poi_repo.dart`
**Problem:** Bei Euro Trip (600km Radius) bis zu 36 Wikipedia-Requests gleichzeitig → ANR.
**Fix:** 4er-Batches mit 200ms Pause, 8s Timeout pro Request, 200-POI-Abbruchkriterium.

### Fix 4.2: Globaler Future.wait-Timeout
**Datei:** `lib/data/repositories/poi_repo.dart`
**Problem:** Kein globaler Timeout auf `Future.wait` - einzelne haengende API blockierte alles.
**Fix:** `.timeout(Duration(seconds: 20))` auf alle 3 `Future.wait`-Aufrufe.

### Fix 4.3: 2-opt Route-Optimizer Cap
**Datei:** `lib/core/algorithms/route_optimizer.dart`
**Problem:** O(n^3) bei 126 POIs (14 Tage x 9) = 200M+ Operationen auf Mobile.
**Fix:** Bei >50 POIs nur Nearest-Neighbor (kein 2-opt). Bei 20-50 POIs maxIterations auf 30 reduziert.

### Fix 4.4: POI-Selector Pool-Bereinigung
**Datei:** `lib/core/algorithms/random_poi_selector.dart`
**Problem:** `pool.removeWhere()` war O(n) pro Iteration = O(n^2) gesamt.
**Fix:** `removeAt(pool.indexOf(selectedPOI))` - O(n) statt O(n^2).

### Fix 4.5: Image Pre-Caching Limit
**Datei:** `lib/data/services/poi_enrichment_service.dart`
**Problem:** 100+ unawaited `_prefetchImage()` Calls = 50MB+ RAM gleichzeitig.
**Fix:** `_activePrefetches` Counter mit Limit 5. Bei Ueberschreitung wird Prefetch gedroppt.

### Fix 4.6: Marker-Rendering (bereits implementiert)
Nur Marker des aktuell ausgewaehlten Tages werden gerendert - war bereits in v1.9.12 umgesetzt.

---

## Phase 5: Weather-Provider Robustheit (HOCH)

### Fix 5.1: isLoading Stuck-State
**Datei:** `lib/features/map/providers/weather_provider.dart`
**Problem:** Bei Request-Cancellation kein finally-Block → isLoading blieb true, Spinner endlos.
**Fix:** `finally`-Block in `loadWeatherForRoute()` und `loadWeatherForRouteWithForecast()` setzt isLoading zurueck wenn noch aktiver Request.

---

## Phase 6: Post-Validierungs-Loop Fix (HOCH)

### Fix 6.1: Max-Tage-Cap bei Re-Split
**Datei:** `lib/data/repositories/trip_generator_repo.dart`
**Problem:** Post-Validierung konnte bei jedem Versuch MEHR Tage erzeugen. 3 Versuche reichten nicht.
**Fix:** `maxAllowedDays = (effectiveDays * 2).clamp(effectiveDays, 28)`. Schleife bricht ab wenn keine Verbesserung.

### Fix 6.2: splitOverlimitDays Iterations-Schutz
**Datei:** `lib/core/algorithms/day_planner.dart`
**Problem:** `maxIterations = clusters.length * 2` wuchs mit anwachsenden Clusters.
**Fix:** Absolute Obergrenze `min(clusters.length * 2, 50)`.

---

## Phase 7: Mittlere Prioritaet

### Fix 7.1: Slider-Debounce
**Datei:** `lib/features/map/map_screen.dart`
**Problem:** Euro Trip Tage-Slider und Radius-Slider feuerten bei jedem Pixel ein Provider-Update.
**Fix:** `onChanged` fuer leichtgewichtiges visuelles Update, `onChangeEnd` fuer teure Provider-Operation.

### Fix 7.2: Corridor-Browser Cache-Invalidierung
**Datei:** `lib/features/trip/providers/corridor_browser_provider.dart`
**Problem:** `copyWith()` mit `bufferKm`-Aenderung bewahrte alten filteredPOIs-Cache.
**Fix:** `bufferKm == null` zur Cache-Erhalt-Bedingung hinzugefuegt.

### Fix 7.3: Geocoding-Debounce
**Datei:** `lib/features/random_trip/widgets/start_location_picker.dart`
**Problem:** Nominatim-Geocoding bei jedem Tastendruck ohne Debounce.
**Fix:** 300ms Timer-Debounce + mounted-Guards nach async-Operationen.

---

## Betroffene Dateien (14)

| Datei | Fixes | Phase |
|-------|-------|-------|
| `random_trip_provider.dart` | 1.1, 3.1, 3.2 | 1, 3 |
| `trip_generator_repo.dart` | 1.2, 6.1 | 1, 6 |
| `map_screen.dart` | 2.1, 7.1 | 2, 7 |
| `map_view.dart` | 2.2 | 2 |
| `day_editor_overlay.dart` | 2.3 | 2 |
| `poi_repo.dart` | 4.1, 4.2 | 4 |
| `route_optimizer.dart` | 4.3 | 4 |
| `random_poi_selector.dart` | 4.4 | 4 |
| `poi_enrichment_service.dart` | 4.5 | 4 |
| `weather_provider.dart` | 5.1 | 5 |
| `day_planner.dart` | 6.2 | 6 |
| `corridor_browser_provider.dart` | 7.2 | 7 |
| `start_location_picker.dart` | 7.3 | 7 |

## Verifikation

- `flutter analyze`: 0 neue Errors in geaenderten Dateien
- `flutter test`: 298/298 Tests bestanden
