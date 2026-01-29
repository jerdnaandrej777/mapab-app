# Changelog v1.5.1 - POI-Liste Race Condition Bugfix

**Datum:** 24.01.2026

## Bugfix

### POI-Liste Race Condition behoben

**Problem:** POIs wurden geladen, kurz angezeigt und verschwanden dann - nur 1 POI blieb sichtbar.

**Symptome:**
- POI-Liste zeigte kurz alle geladenen POIs
- Nach wenigen Sekunden verschwanden fast alle POIs
- Nur 1 POI blieb in der Liste sichtbar
- Enrichment-Bilder wurden nicht angezeigt

**Ursache:** Race Condition beim parallelen POI-Enrichment

Beim Pre-Enrichment wurden bis zu 8 POIs gleichzeitig enriched. Jeder Enrichment-Call:
1. Startete asynchrones API-Call
2. Nach `await` las den `state.pois` Snapshot
3. Erstellte eine Kopie der Liste
4. Setzte den neuen State

Wenn mehrere Calls fast gleichzeitig fertig wurden:
```
Call 1: Liest state.pois = [A, B, C, D, E...]
Call 2: Liest state.pois = [A, B, C, D, E...] (gleicher Snapshot!)
Call 1: Setzt state.pois = [A-enriched, B, C, D, E...]
Call 2: Setzt state.pois = [A, B-enriched, C, D, E...] ← ÜBERSCHREIBT Call 1!
```

**Lösung:** Atomare State-Updates

Neue Methode `_updatePOIInState()` die:
1. Den **aktuellen** State liest (nicht eine alte Kopie)
2. Nur den einen POI atomar aktualisiert
3. Den State sofort setzt (synchron, ohne Unterbrechung)

## Geänderte Dateien

### lib/features/poi/providers/poi_state_provider.dart

**Neue Methode:**
```dart
/// Aktualisiert einen einzelnen POI im State atomar
/// FIX v1.5.1: Verhindert Race Conditions bei parallelen Updates
void _updatePOIInState(String poiId, POI updatedPOI) {
  // WICHTIG: Lese den AKTUELLEN State (nicht eine alte Kopie)
  final currentPOIs = state.pois;
  final currentIndex = currentPOIs.indexWhere((p) => p.id == poiId);

  if (currentIndex == -1) {
    // POI nicht mehr in der Liste - nur Loading State entfernen
    final newEnrichingIds = Set<String>.from(state.enrichingPOIIds)..remove(poiId);
    state = state.copyWith(
      isEnriching: newEnrichingIds.isNotEmpty,
      enrichingPOIIds: newEnrichingIds,
    );
    return;
  }

  // Neue Liste mit aktualisiertem POI erstellen
  final updatedPOIs = List<POI>.from(currentPOIs);
  updatedPOIs[currentIndex] = updatedPOI;

  // Loading State entfernen
  final newEnrichingIds = Set<String>.from(state.enrichingPOIIds)..remove(poiId);

  state = state.copyWith(
    pois: updatedPOIs,
    isEnriching: newEnrichingIds.isNotEmpty,
    enrichingPOIIds: newEnrichingIds,
    selectedPOI: state.selectedPOI?.id == poiId
        ? updatedPOI
        : state.selectedPOI,
  );
}
```

**Geänderte Methode `enrichPOI`:**
```dart
try {
  final enrichmentService = ref.read(poiEnrichmentServiceProvider);
  final enrichedPOI = await enrichmentService.enrichPOI(poi);

  // FIX v1.5.1: Race Condition - State ATOMAR aktualisieren
  _updatePOIInState(poiId, enrichedPOI.copyWith(isEnriched: true));

  debugPrint('[POIState] POI angereichert: ${poi.name}');
} catch (e) {
  // ...
}
```

## Technische Details

### Warum trat das Problem auf?

Dart ist single-threaded, aber nach jedem `await` kann der Event Loop andere Microtasks verarbeiten. Wenn mehrere async-Operationen gleichzeitig laufen:

1. Alle Operationen starten und warten (`await`)
2. Wenn API-Responses ankommen, werden Microtasks eingeplant
3. Microtasks werden sequentiell verarbeitet
4. ABER: Zwischen dem Lesen von `state.pois` und dem Setzen des neuen States kann ein anderer Microtask den State bereits geändert haben

### Lösung: Atomares Update

Die neue Methode `_updatePOIInState()` liest den State und setzt ihn in einer **synchronen** Operation - ohne `await` dazwischen. Dadurch kann kein anderer Code den State zwischen Lesen und Schreiben ändern.

### Best Practice für Riverpod

Bei asynchronen State-Updates:
```dart
// FALSCH
final snapshot = state.someList;  // Snapshot erstellen
await someAsyncOperation();       // Hier kann state geändert werden!
state = state.copyWith(someList: modifiedSnapshot);  // Überschreibt fremde Änderungen

// RICHTIG
await someAsyncOperation();
// State JETZT lesen und sofort setzen (synchron)
final current = state.someList;
final updated = modify(current);
state = state.copyWith(someList: updated);
```

## Test

1. POI-Liste öffnen
2. Warten bis POIs geladen werden
3. POIs bleiben sichtbar (verschwinden nicht mehr)
4. Enrichment-Bilder werden nach und nach angezeigt

## Migration

Keine Migration erforderlich. Der Fix ist rein im Code und beeinflusst keine gespeicherten Daten.
