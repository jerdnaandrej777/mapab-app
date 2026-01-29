# Changelog v1.7.3 - POI-Foto Batch-Enrichment

**Datum:** 2026-01-29

## Übersicht

Diese Version optimiert das Laden von POI-Fotos durch Wikipedia Multi-Title-Queries. Statt einzelner API-Anfragen pro POI werden bis zu 50 POIs in einem einzigen Request abgefragt.

## Neue Features

### Batch-Enrichment für POI-Fotos

**Problem:**
Bei vielen POIs (20+) wurden Fotos sehr langsam geladen wegen:
- Nur 3 parallele Enrichments erlaubt
- Wikimedia Rate-Limit (200 Req/Min)
- 3-5 API-Calls pro POI nacheinander

**Lösung:**
Wikipedia API unterstützt Multi-Title-Queries mit bis zu 50 Titeln pro Request.

**Performance-Verbesserung:**

| Metrik | Vorher | Nachher |
|--------|--------|---------|
| API-Calls für 20 POIs | ~80 | ~4 |
| Zeit für 20 POIs | 21+ Sek | ~3 Sek |
| Rate-Limit-Risiko | Hoch | Niedrig |

## Technische Änderungen

### poi_enrichment_service.dart

Neue Methoden:
- `enrichPOIsBatch(List<POI> pois)` - Hauptmethode für Batch-Enrichment
- `_fetchWikipediaBatch(List<String> titles)` - Wikipedia Multi-Title-Query

```dart
// Wikipedia Batch-Abfrage (bis zu 50 Titel pro Request)
final response = await _requestWithRetry(
  ApiEndpoints.wikipediaGeoSearch,
  {
    'action': 'query',
    'titles': titles.join('|'), // Pipe-separierte Titel
    'prop': 'extracts|pageimages|pageprops',
    // ...
  },
);
```

**Ablauf:**
1. Cache-Treffer zuerst prüfen
2. POIs mit Wikipedia-Titel sammeln (max 50)
3. Wikipedia Batch-Abfrage ausführen
4. POIs ohne Wikipedia-Titel: Wikimedia Geo-Suche (parallel, max 5)
5. Restliche POIs als "enriched" markieren

### poi_state_provider.dart

Neue Methode:
- `enrichPOIsBatch(List<POI> pois)` - Atomares State-Update für mehrere POIs

```dart
Future<void> enrichPOIsBatch(List<POI> pois) async {
  // Markiere alle als "in Arbeit"
  // Rufe Service-Batch auf
  // Aktualisiere State atomar
}
```

### poi_list_screen.dart

Angepasste Methoden:
- `_preEnrichVisiblePOIs()` - Nutzt jetzt Batch (30 POIs statt 15)
- `_enrichVisiblePOIs()` - Scroll-Handler nutzt ebenfalls Batch

```dart
// OPTIMIERT v1.7.3: Batch-Enrichment nutzen statt einzelner Requests
poiNotifier.enrichPOIsBatch(poisToEnrich);
```

## Betroffene Dateien

| Datei | Änderung |
|-------|----------|
| `lib/data/services/poi_enrichment_service.dart` | +150 Zeilen (Batch-Methoden) |
| `lib/features/poi/providers/poi_state_provider.dart` | +55 Zeilen (enrichPOIsBatch) |
| `lib/features/poi/poi_list_screen.dart` | Angepasst für Batch-Aufrufe |

## Verwendung

```dart
// Einzelner POI (wie bisher)
ref.read(pOIStateNotifierProvider.notifier).enrichPOI(poiId);

// Batch-Enrichment für mehrere POIs (NEU - 7x schneller)
ref.read(pOIStateNotifierProvider.notifier).enrichPOIsBatch(poisList);
```

## Testen

1. App starten: `flutter run`
2. Zu einer Region mit vielen POIs navigieren (z.B. München)
3. POI-Liste öffnen → Fotos sollten in ~3 Sekunden erscheinen
4. Console-Logs prüfen:
   - `[Enrichment] Batch-Request für X POIs`
   - `[Enrichment] Wikipedia-Batch: X Ergebnisse`
   - `[POIState] Batch-Enrichment abgeschlossen: X POIs aktualisiert`

## Kompatibilität

- Einzelnes `enrichPOI()` funktioniert weiterhin
- Kein Breaking Change für bestehende Aufrufe
- Rückwärtskompatibel mit Cache-Einträgen
