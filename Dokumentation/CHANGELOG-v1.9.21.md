# Changelog v1.9.21 - Korridor-Browser ANR-Fix

**Datum:** 2026-02-04
**Typ:** Performance / Stability Fix
**Problem:** App friert ein ("MapAB reagiert nicht") wenn der Korridor-Browser im DayEditor ~150 POIs anzeigt

## Root Cause

Beim Slider-Drag mit 150 geladenen POIs entstand eine Freeze-Kaskade:

1. `onChanged` feuert ~50x/Sek → `setBufferKmLocal()` → `state.copyWith(bufferKm: ...)`
2. `copyWith()` erstellt neue `CorridorBrowserState` → `_filteredPOIsCache` geht verloren
3. `build()` re-rendert → `filteredPOIs` Getter refiltered 150 POIs
4. `_buildPOIList()` watcht Weather-Provider erneut (doppelter Watch!)
5. `sortByWeatherRelevance()` sortiert 150 POIs bei JEDEM Render
6. `ListView.builder` baut 150 `CompactPOICard`s ohne `ValueKey` (kein Recycling)
7. Alles wiederholt sich 50x/Sek → Main Thread 100% → ANR

## Aenderungen

### Fix 1: filteredPOIs Cache in copyWith() erhalten (KRITISCH)
**Datei:** `lib/features/trip/providers/corridor_browser_provider.dart`

`copyWith()` erhaelt jetzt `_filteredPOIsCache` und `_newPOICountCache` wenn sich nur `bufferKm`, `isLoading` oder `error` aendern - also keine filter-relevanten Felder. Bei Slider-Drag werden 150 POIs nicht mehr pro Frame neu gefiltert.

```dart
// Vorher: Jeder copyWith() zerstoerte den Cache
CorridorBrowserState copyWith({...}) {
  return CorridorBrowserState(...); // Cache immer null!
}

// Nachher: Cache bleibt erhalten bei nicht-filter-relevanten Updates
CorridorBrowserState copyWith({...}) {
  final newState = CorridorBrowserState(...);
  if (corridorPOIs == null && selectedCategories == null && addedPOIIds == null) {
    newState._filteredPOIsCache = _filteredPOIsCache;
    newState._newPOICountCache = _newPOICountCache;
  }
  return newState;
}
```

### Fix 2: Wetter-Sortierung gecacht (KRITISCH)
**Datei:** `lib/features/trip/widgets/corridor_browser_sheet.dart`

`WeatherPOIUtils.sortByWeatherRelevance()` wird jetzt mit `identical()`-Check gecacht. Sortierung laeuft nur noch einmal wenn sich die Input-Liste oder die WeatherCondition aendert, nicht bei jedem Widget-Rebuild.

### Fix 3: Doppelter Weather-Provider-Watch eliminiert (HOCH)
**Datei:** `lib/features/trip/widgets/corridor_browser_sheet.dart`

`routeWeatherNotifierProvider` und `locationWeatherNotifierProvider` werden jetzt einmal in `build()` gelesen und als `WeatherCondition`-Parameter an `_buildHeader()` und `_buildPOIList()` durchgereicht. Vorher wurden beide Provider in beiden Methoden separat gewatcht → doppelte Rebuilds.

### Fix 4: ValueKey auf CompactPOICard (HOCH)
**Datei:** `lib/features/trip/widgets/corridor_browser_sheet.dart`

Jede `CompactPOICard` im `ListView.builder` hat jetzt `key: ValueKey(poi.id)`. Flutter kann damit bei Sortier-Aenderungen Widgets stabil recyceln statt alle 150 Cards komplett neu aufzubauen.

### Fix 5: Future.wait Timeout in loadPOIsInBounds (HOCH)
**Datei:** `lib/data/repositories/poi_repo.dart`

`Future.wait(futures)` in `loadPOIsInBounds()` hat jetzt einen 12-Sekunden-Timeout. Verhindert endloses Haengen wenn APIs (besonders Overpass) nicht antworten.

```dart
// Vorher: Kein Timeout, Overpass konnte 25s+ haengen
final results = await Future.wait(futures);

// Nachher: 12s Timeout mit Fallback
List<List<POI>> results;
try {
  results = await Future.wait(futures).timeout(const Duration(seconds: 12));
} on TimeoutException {
  results = [];
}
```

### Fix 6: AI Advisor Re-Entry Guard gestaerkt (HOCH)
**Datei:** `lib/features/ai/providers/ai_trip_advisor_provider.dart`

Der `if (state.isLoading) return;` Guard wurde entfernt. Neue Anfragen canceln jetzt automatisch alte via `_loadRequestId++`. Vorher konnte ein Auto-Trigger (bei schlechtem Wetter) neue manuelle Anfragen blockieren, weil `isLoading` noch `true` war.

### Fix 7: newPOICount lazy gecacht (MITTEL)
**Datei:** `lib/features/trip/providers/corridor_browser_provider.dart`

`newPOICount` Getter iteriert nicht mehr bei jedem Zugriff ueber alle `filteredPOIs`, sondern ist lazy-gecacht mit `_newPOICountCache`.

## Betroffene Dateien

| Datei | Aenderungen |
|-------|------------|
| `lib/features/trip/providers/corridor_browser_provider.dart` | Fix 1, 7: Cache-Erhalt in copyWith, newPOICount Cache |
| `lib/features/trip/widgets/corridor_browser_sheet.dart` | Fix 2, 3, 4: Sortier-Cache, Weather-Watch, ValueKey |
| `lib/data/repositories/poi_repo.dart` | Fix 5: Future.wait 12s-Timeout |
| `lib/features/ai/providers/ai_trip_advisor_provider.dart` | Fix 6: Re-Entry Guard → requestId-Cancellation |

## Performance-Auswirkung

| Metrik | v1.9.20 | v1.9.21 |
|--------|---------|---------|
| Filter-Berechnungen bei Slider-Drag | ~50/Sek | 0 (gecacht) |
| Wetter-Sortierungen pro Render | 1 (150 POIs) | 0 (gecacht) |
| Weather-Provider Watches | 4 (2x Header + 2x Liste) | 2 (1x in build()) |
| ListView Recycling-Effizienz | Keine Keys | ValueKey pro POI |
| Max. API-Wartezeit | Unbegrenzt | 12 Sekunden |
| AI-Advisor Parallel-Requests | Blockiert durch isLoading | Cancelled via requestId |

## Test-Plan

1. AI Trip generieren (3 Tage Euro Trip)
2. DayEditor oeffnen → "POIs hinzufuegen" klicken
3. Korridor-Browser laedt ~150 POIs
4. **Slider-Test:** Korridor von 30km auf 100km und zurueck ziehen → fluessig, kein Freeze
5. **Filter-Test:** Indoor-Chip und Kategorie-Chips schnell klicken → fluessig
6. **AI-Test:** "POI-Empfehlungen laden" klicken → kein Freeze
7. **Tageswechsel-Test:** Zwischen Tagen wechseln → kein Crash
