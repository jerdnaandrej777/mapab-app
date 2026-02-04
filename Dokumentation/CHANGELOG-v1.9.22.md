# Changelog v1.9.22 - Stabilitaets-Release

**Datum:** 2026-02-04
**Typ:** Stability / Crash-Fix
**Problem:** App stuerzt zufaellig ab - keine bestimmte Stelle, verteilt ueber verschiedene Screens und Aktionen

## Root Cause

Analyse mit 3 parallelen Agenten ergab **4 systemweite Crash-Patterns**:

1. **Future.wait ohne Timeout** → ANR (App Not Responding) wenn Overpass/Wikipedia haengen
2. **Force-Unwrap (!) ohne Null-Check** → NullPointerException bei async State-Aenderungen
3. **State-Updates nach Widget-Dispose** → StateError bei schnellem Screen-Wechsel
4. **Doppelte Navigator.pop()** → Navigation-Stack-Korruption im DayEditor

## Aenderungen

### Fix 1: Future.wait Timeouts in POI-Repository (KRITISCH)
**Datei:** `lib/data/repositories/poi_repo.dart`

`loadPOIsInRadius()` und `loadAllPOIs()` hatten `Future.wait` ohne Timeout. Wenn eine der 3 parallelen API-Quellen (Supabase, Overpass, Wikipedia) haengt, blockierte die gesamte App. Jetzt 12s Timeout analog zum bereits existierenden Timeout in `loadPOIsInBounds()` (v1.9.21).

```dart
// Vorher: Kein Timeout, API konnte endlos haengen
final results = await Future.wait(futures);

// Nachher: 12s Timeout mit Fallback auf leere Liste
List<List<POI>> results;
try {
  results = await Future.wait(futures).timeout(
    const Duration(seconds: 12),
  );
} on TimeoutException {
  debugPrint('[POI] ⚠️ Timeout bei loadPOIsInRadius nach 12s');
  results = [];
}
```

### Fix 2: Future.wait Timeouts im Enrichment-Service (KRITISCH)
**Datei:** `lib/data/services/poi_enrichment_service.dart`

3 Stellen mit `Future.wait` ohne Timeout:

| Stelle | Methode | Timeout |
|--------|---------|---------|
| Parallele Enrichment-Requests | `_enrichSinglePOI()` | 10s |
| Fallback-Batch (Wikipedia) | `_batchEnrichPOIs()` | 8s |
| Wikidata Geo-Suche | `_batchEnrichPOIs()` | 8s |

```dart
// Beispiel: Parallele Enrichment-Requests
List<POIEnrichmentData?> results;
try {
  results = await Future.wait(futures).timeout(
    const Duration(seconds: 10),
  );
} on TimeoutException {
  debugPrint('[Enrichment] ⚠️ Timeout bei parallelen Requests nach 10s');
  results = [];
}
```

### Fix 3: Null-Safety Guards im Random-Trip-Provider (KRITISCH)
**Datei:** `lib/features/random_trip/providers/random_trip_provider.dart`

`rerollPOI()`, `removePOI()`, `addPOIToDay()` und `removePOIFromDay()` prueften nur `generatedTrip == null`, nicht `startLocation == null`. Wenn der State waehrend einer async Operation zurueckgesetzt wird (z.B. User drueckt schnell "Zurueck"), crashte `state.startLocation!`.

```dart
// Vorher: Nur generatedTrip geprueft
if (state.generatedTrip == null) return;
// ... spaeter: state.startLocation! → CRASH wenn null

// Nachher: Beide Guards
if (state.generatedTrip == null || state.startLocation == null) return;
// ... spaeter: state.startAddress ?? '' statt state.startAddress!
```

Betroffene Methoden:
- `rerollPOI()` - startLocation + startAddress Guard
- `removePOI()` - startLocation + startAddress Guard
- `addPOIToDay()` - startLocation Guard
- `removePOIFromDay()` - startLocation Guard

### Fix 4: Navigator.pop() Doppel-Crash (KRITISCH)
**Datei:** `lib/features/trip/widgets/day_editor_overlay.dart`

Im Trip-Abschluss-Dialog wurde zuerst der Dialog geschlossen (`Navigator.pop(ctx)`) und danach der DayEditor (`Navigator.pop(context)`). Der zweite Pop konnte crashen weil `context` nach dem Dialog-Pop ungueltig sein kann.

```dart
// Vorher: Zweiter Pop ohne Guard
Navigator.pop(ctx);      // Dialog schliessen
Navigator.pop(context);  // DayEditor schliessen - CRASH moeglich!

// Nachher: Mounted-Check vor zweitem Pop
Navigator.pop(ctx);      // Dialog schliessen
if (context.mounted) {
  Navigator.pop(context);  // DayEditor nur schliessen wenn context noch gueltig
}
```

### Fix 5: Mounted-Checks nach async GPS-Operationen (HOCH)
**Datei:** `lib/features/map/map_screen.dart`

`_centerOnLocation()` und `_centerOnCurrentLocationSilent()` riefen nach `await Geolocator.getCurrentPosition()` direkt `setState()`, `ref.read()` und Snackbar-Methoden auf - ohne zu pruefen ob das Widget noch existiert.

```dart
// Vorher: Kein Check nach GPS-await
final position = await Geolocator.getCurrentPosition(...);
final mapController = ref.read(mapControllerProvider);  // CRASH wenn disposed
setState(() => _isLoadingLocation = false);               // CRASH wenn disposed

// Nachher: Mounted-Check nach jedem await
final position = await Geolocator.getCurrentPosition(...);
if (!mounted) return;
final mapController = ref.read(mapControllerProvider);
// ... catch/finally auch mit mounted-Guard
```

3 Stellen gefixt:
1. `_centerOnLocation()` - nach GPS-Position-await
2. `_centerOnCurrentLocationSilent()` - nach GPS-Position-await
3. `_centerOnCurrentLocationSilent()` - nach reverseGeocode-await

### Fix 6: Weather-Provider Request-Cancellation (HOCH)
**Datei:** `lib/features/map/providers/weather_provider.dart`

`loadWeatherForRoute()` und `loadWeatherForRouteWithForecast()` laden sequentiell 5 Wetterpunkte (~5 Sekunden). Wenn waehrenddessen eine neue Route berechnet wird, lief die alte Anfrage weiter und ueberschrieb den State mit veralteten Daten.

```dart
// Neues Pattern: Request-ID Cancellation (analog AI-Advisor)
int _loadRequestId = 0;

Future<void> loadWeatherForRoute(List<LatLng> routeCoords) async {
  final requestId = ++_loadRequestId;
  state = state.copyWith(isLoading: true, error: null);

  try {
    for (int i = 0; i < 5 && i * step < routeCoords.length; i++) {
      if (requestId != _loadRequestId) {
        debugPrint('[Weather] Request $requestId abgebrochen (neuer aktiv)');
        return;  // Alte Anfrage sauber abbrechen
      }
      // ... Wetter laden ...
    }
    if (requestId != _loadRequestId) return;  // Nochmal pruefen vor State-Update
    state = state.copyWith(weatherPoints: points, isLoading: false);
  } catch (e) {
    if (requestId == _loadRequestId) {
      state = state.copyWith(isLoading: false, error: '...');
    }
  }
}
```

### Fix 7: Navigation-Screen Mounted-Check (MITTEL)
**Datei:** `lib/features/navigation/navigation_screen.dart`

`_onInterpolatedPosition()` wird ~60fps aufgerufen. Hatte bereits null-Check fuer `_mapController` und try/catch, aber keinen `mounted`-Check. Wenn die Navigation beendet wird waehrend ein Interpolation-Tick laeuft, konnte `setState()` auf ein disposed Widget zugreifen.

```dart
// Vorher:
if (_mapController == null || _isOverviewMode) return;

// Nachher:
if (!mounted || _mapController == null || _isOverviewMode) return;
```

## Betroffene Dateien

| Datei | Aenderungen | Prioritaet |
|-------|------------|------------|
| `lib/data/repositories/poi_repo.dart` | Fix 1: 2x Future.wait 12s-Timeout | KRITISCH |
| `lib/data/services/poi_enrichment_service.dart` | Fix 2: 3x Future.wait Timeout (10s/8s/8s) | KRITISCH |
| `lib/features/random_trip/providers/random_trip_provider.dart` | Fix 3: 4x Null-Safety Guard (startLocation + startAddress) | KRITISCH |
| `lib/features/trip/widgets/day_editor_overlay.dart` | Fix 4: context.mounted vor Navigator.pop | KRITISCH |
| `lib/features/map/map_screen.dart` | Fix 5: 3x mounted-Check nach async GPS | HOCH |
| `lib/features/map/providers/weather_provider.dart` | Fix 6: Request-ID Cancellation (2 Methoden) | HOCH |
| `lib/features/navigation/navigation_screen.dart` | Fix 7: mounted-Check in 60fps Callback | MITTEL |

## Crash-Pattern-Analyse

| Pattern | Vorkommen | Fix-Typ |
|---------|-----------|---------|
| Future.wait ohne Timeout | 5 Stellen | TimeoutException + Fallback |
| Force-Unwrap ohne Guard | 4 Methoden | Null-Check + Early Return |
| setState nach dispose | 4 Stellen | `if (!mounted) return` |
| Navigator-Stack-Korruption | 1 Stelle | `if (context.mounted)` |
| Veraltete async-Ergebnisse | 2 Methoden | Request-ID Cancellation |

## Test-Plan

1. **ANR-Test:** Trip generieren → waehrend POI-Laden App-Tab wechseln → kein Freeze
2. **Null-Safety-Test:** Trip generieren → schnell zurueck navigieren waehrend Reroll laeuft → kein Crash
3. **Navigator-Test:** DayEditor oeffnen → Trip abschliessen → kein Crash beim Schliessen
4. **GPS-Test:** MapScreen oeffnen → GPS-Button druecken → sofort anderen Tab oeffnen → kein Crash
5. **Weather-Test:** Route berechnen → waehrend Wetter laedt neue Route berechnen → keine veralteten Daten
6. **Navigation-Test:** Navigation starten → sofort zurueck druecken → kein Crash
7. **Netzwerk-Test:** Langsames Netzwerk simulieren (Flugmodus an/aus) → Timeouts greifen, kein ANR
