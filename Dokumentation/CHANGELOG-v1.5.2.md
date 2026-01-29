# Changelog v1.5.2 - POI-Liste Filter & Debug Fix

**Datum:** 24.01.2026

## Bugfixes

### POI-Liste Filter Fix

**Problem:** POIs wurden in der Übersichtsliste nicht angezeigt - nur 1 POI war sichtbar.

**Ursache:** Mehrere Filter-bezogene Probleme:
1. `routeOnlyMode` wurde nicht zurückgesetzt wenn keine Route vorhanden
2. Filter-State blieb erhalten zwischen Navigationen (keepAlive Provider)
3. Cache-Check verhinderte Neuladen bei leerer POI-Liste

**Lösung:**

1. **Filter automatisch zurücksetzen** in `poi_list_screen.dart`:
```dart
// Wenn keine Route vorhanden ist
if (!tripState.hasRoute) {
  // FIX v1.5.2: Alle Filter zurücksetzen
  poiNotifier.resetFilters();
  debugPrint('[POIList] Keine Route vorhanden - alle Filter zurückgesetzt');
}
```

2. **RouteOnlyMode korrekt setzen** für Route-POIs:
```dart
if (tripState.hasRoute) {
  // FIX v1.5.2: RouteOnlyMode setzen für Route-POIs
  poiNotifier.setRouteOnlyMode(true);
  await poiNotifier.loadPOIsForRoute(tripState.route!);
}
```

3. **Cache-Check verbessert** in `poi_state_provider.dart`:
```dart
// FIX v1.5.2: Auch neu laden wenn keine POIs vorhanden sind
final hasEnoughPOIs = state.pois.isNotEmpty;
if (!forceReload &&
    hasEnoughPOIs &&  // NEU: Prüfe ob POIs vorhanden
    state.lastLoadedCenter != null &&
    state.lastLoadedRadius == radiusKm &&
    _isNearby(state.lastLoadedCenter!, center, 5)) {
  return; // Cache verwenden
}
```

## Debug-Verbesserungen

Umfangreiche Debug-Logs hinzugefügt für bessere Fehleranalyse:

- `[POIList] _loadPOIs gestartet - hasRoute: {bool}`
- `[POIList] Nach loadPOIsForRoute: {count} POIs geladen, {filtered} nach Filter`
- `[POIState] loadPOIsInRadius: center={...}, radius={...}, forceReload={...}`
- `[POIState] Aktueller State: {count} POIs, routeOnlyMode={bool}`
- `[POIState] _updatePOIInState: poiId={...}, currentIndex={...}, totalPOIs={...}`
- `[POIState] POI aktualisiert: {name}, neue Liste hat {count} POIs`
- `[POIState] Nach Update: {count} POIs im State`

## Geänderte Dateien

### lib/features/poi/poi_list_screen.dart
- `resetFilters()` wird aufgerufen wenn keine Route vorhanden
- `setRouteOnlyMode(true)` wird aufgerufen wenn Route vorhanden
- Mehr Debug-Output für Fehleranalyse

### lib/features/poi/providers/poi_state_provider.dart
- `loadPOIsInRadius()`: `forceReload` Parameter hinzugefügt
- `loadPOIsInRadius()`: Prüft ob POIs vorhanden vor Cache-Verwendung
- `loadPOIsForRoute()`: Mehr Debug-Output
- `_updatePOIInState()`: Mehr Debug-Output

## Zusammenhang mit v1.5.1

v1.5.1 hat die Race Condition beim parallelen Enrichment behoben. Das Problem war:
- Mehrere Enrichments überschrieben sich gegenseitig

v1.5.2 behebt zusätzliche Filter-Probleme:
- Filter-State bleibt erhalten zwischen Navigationen
- routeOnlyMode wird nicht korrekt zurückgesetzt
- Cache-Check verhindert Neuladen bei leerer Liste

## Test

1. App starten
2. Zur POI-Liste navigieren (ohne Route)
3. POIs sollten angezeigt werden
4. Zur Karte navigieren, Route erstellen
5. Zur POI-Liste navigieren
6. Route-POIs sollten angezeigt werden
7. Route löschen
8. Zur POI-Liste navigieren
9. POIs basierend auf GPS sollten angezeigt werden

## Migration

Keine Migration erforderlich.
