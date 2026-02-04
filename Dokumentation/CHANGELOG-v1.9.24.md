# Changelog v1.9.24 - POI-Laden Hotfix

**Datum:** 2026-02-04
**Typ:** Hotfix / POI-Loading
**Problem:** Keine POIs werden gefunden, keine Routen gebaut - "Trip-Generierung fehlgeschlagen" in beiden Modi (AI Trip und normale Route)

## Root Cause

Zwei zusammenwirkende Probleme:

1. **Supabase PostGIS-Funktionen nicht deployed** - Die SQL-Migration `002_pois_postgis.sql` existiert im Repo, wurde aber nie auf der Supabase-Instanz ausgefuehrt. `search_pois_in_radius` und `search_pois_in_bounds` RPC-Calls liefern 404.

2. **Future.wait().timeout() Anti-Pattern** - Der globale Timeout um `Future.wait(futures)` verwirft ALLE Ergebnisse wenn EINE Quelle haengt. Wenn Overpass (504 Gateway Timeout) laenger als 12s braucht, gehen auch die bereits fertigen Ergebnisse von Curated POIs und Wikipedia verloren.

**Fehlerkette:**
```
Supabase RPC 404 → Fallback auf Client-APIs →
Overpass haengt (504) → Globaler Future.wait Timeout →
ALLE Ergebnisse verworfen (auch Curated + Wikipedia) →
Leere POI-Liste → TripGenerationException
```

## Aenderungen

### Fix 1: Individuelle Timeouts in poi_repo.dart (KRITISCH)
**Datei:** `lib/data/repositories/poi_repo.dart`

3 Stellen gefixt: `loadPOIsInRadius()`, `loadPOIsInBounds()`, `loadAllPOIs()`

```dart
// VORHER: Globaler Timeout - ALLE Ergebnisse verloren bei Timeout
List<List<POI>> results;
try {
  results = await Future.wait(futures).timeout(
    const Duration(seconds: 12),
  );
} on TimeoutException {
  results = [];  // Curated + Wikipedia Ergebnisse auch weg!
}

// NACHHER: Individueller Timeout pro Quelle - schnelle Quellen bleiben erhalten
final timedFutures = futures.map((f) =>
  f.timeout(const Duration(seconds: 12), onTimeout: () {
    debugPrint('[POI] Einzelne Quelle Timeout nach 12s');
    return <POI>[];
  })
).toList();
final results = await Future.wait(timedFutures);
```

### Fix 2: Individuelle Timeouts in poi_enrichment_service.dart (HOCH)
**Datei:** `lib/data/services/poi_enrichment_service.dart`

3 Stellen gefixt:

| Stelle | Methode | Timeout |
|--------|---------|---------|
| Parallele Enrichment-Requests | `_enrichSinglePOI()` | 10s pro Request |
| Fallback-Batch (Wikipedia) | `_batchEnrichPOIs()` | 8s pro Fallback |
| Wikidata Geo-Suche | `_batchEnrichPOIs()` | 8s pro Geo-Request |

Gleiches Pattern: Individueller Timeout pro Future statt globaler Future.wait-Timeout.

## Betroffene Dateien (2 Stueck)

| Datei | Aenderungen | Prioritaet |
|-------|------------|------------|
| `lib/data/repositories/poi_repo.dart` | 3x Future.wait individueller Timeout (loadPOIsInRadius, loadPOIsInBounds, loadAllPOIs) | KRITISCH |
| `lib/data/services/poi_enrichment_service.dart` | 3x Future.wait individueller Timeout (Parallel, Fallback, Geo) | HOCH |

## API-Status bei Diagnose

| API | Status | Auswirkung |
|-----|--------|-----------|
| OSRM | 200 OK | Routing funktioniert |
| Wikipedia | 200 OK | POI-Quelle funktioniert |
| Supabase REST | 200 OK | Verbindung steht |
| Supabase RPC | 404 Not Found | PostGIS-Funktionen fehlen |
| Overpass | 504 Gateway Timeout | POI-Quelle haengt |

## Offener Punkt: Supabase PostGIS Migration

Die SQL-Migration `backend/supabase/migrations/002_pois_postgis.sql` muss noch auf der Supabase-Instanz ausgefuehrt werden. Dadurch wuerde:
- POI-Laden ueber PostGIS Spatial Queries deutlich schneller
- Abhaengigkeit von externen APIs (Overpass, Wikipedia) reduziert
- Curated POIs direkt aus Supabase geladen

## Test-Plan

1. **POI-Laden bei Overpass-Ausfall:** Trip generieren → Curated + Wikipedia POIs werden gefunden (Overpass-Timeout = leere Liste, nicht alles weg)
2. **Normaler Trip:** Startpunkt setzen → Trip generieren → POIs erscheinen
3. **Euro Trip:** Mehrtaegigen Trip generieren → POIs pro Tag erscheinen
4. **Enrichment:** POIs werden mit Bildern angereichert (auch wenn eine Quelle haengt)
5. **Timeout-Verhalten:** Langsame API → nur diese Quelle leer, andere Ergebnisse erhalten
