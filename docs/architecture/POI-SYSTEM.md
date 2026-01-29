# POI-System Dokumentation

Diese Dokumentation beschreibt das Point-of-Interest (POI) System der MapAB Flutter App.

## Inhaltsverzeichnis

1. [Datenstruktur](#datenstruktur)
2. [Kategorien](#kategorien)
3. [Enrichment-System](#enrichment-system)
4. [POI Highlights](#poi-highlights)
5. [Cache-Service](#cache-service)
6. [Map-Marker](#map-marker)
7. [State Management](#state-management)

---

## Datenstruktur

### Kuratierte POIs (JSON)

Die App enthält 527+ kuratierte POIs in `assets/data/curated_pois.json`:

```json
{
  "id": "de-1",
  "n": "Brandenburger Tor",
  "lat": 52.5163,
  "lng": 13.3777,
  "c": "monument",
  "r": 98,
  "tags": ["monument", "berlin"],
  "curated": true
}
```

**Feld-Mapping:**
- `n` = name
- `c` = category
- `r` = score (0-100)

### POI Model (Dart)

```dart
// lib/data/models/poi.dart
@freezed
class POI with _$POI {
  const factory POI({
    required String id,
    required String name,
    required double latitude,
    required double longitude,
    required String categoryId,
    @Default(50) int score,
    @Default([]) List<String> tags,
    String? description,
    String? imageUrl,
    String? thumbnailUrl,
    String? wikipediaUrl,

    // Route-spezifische Felder
    double? routePosition,      // 0 = Start, 1 = Ende
    double? detourKm,
    int? detourMinutes,
    double? effectiveScore,     // Nach Umweg-Berechnung

    // Enrichment-Felder (v1.2.5+)
    int? foundedYear,           // Gründungsjahr (Wikidata)
    String? architectureStyle,  // Architekturstil (Wikidata)
    @Default(false) bool isEnriched,
    @Default(false) bool isCurated,
  }) = _POI;

  // Computed Properties
  LatLng get location => LatLng(latitude, longitude);
  bool get isHistoric => tags.contains('historic') || tags.contains('unesco');
  bool get isMustSee => score >= 90;
  bool get isSecret => tags.contains('secret');
  List<POIHighlight> get highlights { ... }
}
```

---

## Kategorien

### Indoor-Kategorien (Wetter-Filter)

Bei schlechtem Wetter werden Indoor-POIs bevorzugt:

| Kategorie | Icon | Beschreibung |
|-----------|------|--------------|
| `museum` | museum | Museen, Galerien |
| `church` | church | Kirchen, Dome, Kathedralen |
| `restaurant` | restaurant | Restaurants, Cafés |
| `hotel` | hotel | Hotels, Unterkünfte |

### Outdoor-Kategorien

| Kategorie | Icon | Beschreibung |
|-----------|------|--------------|
| `castle` | castle | Schlösser, Burgen |
| `nature` | park | Naturparks, Wälder |
| `viewpoint` | terrain | Aussichtspunkte, Türme |
| `lake` | water | Seen, Gewässer |
| `coast` | beach_access | Küsten, Strände |
| `park` | nature | Stadtparks, Gärten |
| `city` | location_city | Städte, Altstädte |
| `activity` | sports | Sport, Aktivitäten |
| `monument` | account_balance | Denkmäler, Monumente |
| `attraction` | attractions | Sonstige Attraktionen |

### Wetter-basierte Score-Anpassung

```dart
// Bei schlechtem Wetter (bad/danger):
// Indoor-POIs: Score + 15
// Outdoor-POIs: Score - 10

// Bei gutem Wetter:
// Outdoor-POIs: Score + 5
```

---

## Enrichment-System

Das Enrichment-System (v1.2.5+) reichert POIs mit zusätzlichen Daten an.

### Architektur

```
┌─────────────────────────────────────────────────────┐
│                    UI Layer                          │
│  POIListScreen │ POIDetailScreen │ MapView (Marker) │
└────────────────────────┬────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────┐
│              POIStateNotifier (Riverpod)             │
│  loadPOIs() │ enrichPOI() │ filterPOIs()            │
└────────────────────────┬────────────────────────────┘
                         │
         ┌───────────────┼───────────────┐
         ▼               ▼               ▼
┌─────────────┐ ┌─────────────────┐ ┌─────────────┐
│ POIRepo     │ │ POIEnrichment   │ │ POICache    │
│ (3-Layer)   │ │ Service         │ │ (Hive)      │
└──────┬──────┘ └────────┬────────┘ └─────────────┘
       │                 │
       ▼                 ▼
┌─────────────────────────────────────────────────────┐
│                  Kostenlose APIs                     │
│ Wikipedia Extracts │ Wikimedia Commons │ Wikidata   │
└─────────────────────────────────────────────────────┘
```

### POI Enrichment Service

```dart
// lib/data/services/poi_enrichment_service.dart
class POIEnrichmentService {
  /// Enrichment-Flow:
  /// 1. Cache prüfen → falls Treffer, gecachten POI zurückgeben
  /// 2. Wikipedia Extracts API → Beschreibung + Hauptbild
  /// 3. Wikimedia Commons API → Geo-basierte Bildsuche (Fallback)
  /// 4. Wikidata SPARQL → UNESCO, Gründungsjahr, Architekturstil
  /// 5. Ergebnis cachen + zurückgeben
  Future<POI> enrichPOI(POI poi) async { ... }
}
```

### API-Endpoints

```dart
// Wikipedia Extracts (Beschreibung + Bild)
GET https://de.wikipedia.org/w/api.php
  ?action=query&titles={title}
  &prop=extracts|pageimages|pageprops
  &exintro=true&explaintext=true

// Wikimedia Commons (Geo-Suche)
GET https://commons.wikimedia.org/w/api.php
  ?action=query&generator=geosearch
  &ggscoord={lat}|{lng}&ggsradius=500
  &prop=imageinfo&iiprop=url

// Wikidata SPARQL (Strukturierte Daten)
GET https://query.wikidata.org/sparql
  ?query={SPARQL}&format=json
```

### Wikipedia Kategorie-Mapping

POIs aus Wikipedia erhalten automatisch passende Kategorien:

```dart
// lib/data/repositories/poi_repo.dart
String _inferCategoryFromTitle(String title) {
  final patterns = <String, List<String>>{
    'castle': ['schloss', 'burg', 'festung', 'castle', 'fortress', 'palast'],
    'church': ['kirche', 'dom', 'kathedrale', 'kloster', 'abtei', 'münster'],
    'museum': ['museum', 'galerie', 'gallery', 'ausstellung'],
    'nature': ['nationalpark', 'naturpark', 'naturschutz', 'biosphäre'],
    'lake': ['see', 'lake', 'teich', 'weiher', 'stausee', 'talsperre'],
    'viewpoint': ['aussicht', 'turm', 'tower', 'view', 'panorama'],
    'monument': ['denkmal', 'memorial', 'monument', 'gedenkstätte'],
  };
  // Match keywords → return category
}
```

---

## POI Highlights

POIs können spezielle Highlights haben, die in der UI angezeigt werden:

```dart
enum POIHighlight {
  unesco('UNESCO-Welterbe', 0xFF00CED1),
  mustSee('Must-See', 0xFFFFD700),
  secret('Geheimtipp', 0xFF9370DB),
  historic('Historisch', 0xFFA0522D),
  familyFriendly('Familienfreundlich', 0xFF4CAF50);
}
```

### Highlight-Berechnung

```dart
// Computed im POI Model:
List<POIHighlight> get highlights {
  final result = <POIHighlight>[];
  if (tags.contains('unesco')) result.add(POIHighlight.unesco);
  if (isMustSee) result.add(POIHighlight.mustSee);
  if (isSecret) result.add(POIHighlight.secret);
  if (isHistoric) result.add(POIHighlight.historic);
  return result;
}
```

---

## Cache-Service

Das POI-Caching reduziert API-Aufrufe und verbessert die Performance.

```dart
// lib/data/services/poi_cache_service.dart
class POICacheService {
  static const Duration poiCacheDuration = Duration(days: 7);
  static const Duration enrichmentCacheDuration = Duration(days: 30);

  Future<void> cacheEnrichedPOI(POI poi);
  Future<POI?> getCachedEnrichedPOI(String poiId);
  Future<void> cachePOIs(List<POI> pois, String regionKey);
  Future<List<POI>?> getCachedPOIs(String regionKey);
  Future<void> cleanExpiredCache();
}
```

### Cache-Strategie

| Daten | TTL | Speicher |
|-------|-----|----------|
| POI-Listen (Region) | 7 Tage | Hive |
| Enriched POIs | 30 Tage | Hive |
| Bilder | Unbegrenzt | CachedNetworkImage |

---

## Map-Marker

POIs werden auf der Karte als interaktive Marker angezeigt.

```dart
// lib/features/map/widgets/map_view.dart

// POI-Marker Layer
if (poiState.filteredPOIs.isNotEmpty)
  MarkerLayer(
    markers: poiState.filteredPOIs.map((poi) {
      return Marker(
        point: poi.location,
        width: _selectedPOIId == poi.id ? 48 : (poi.isMustSee ? 40 : 32),
        height: _selectedPOIId == poi.id ? 48 : (poi.isMustSee ? 40 : 32),
        child: POIMarker(
          icon: poi.categoryIcon,
          isHighlight: poi.isMustSee,
          isSelected: _selectedPOIId == poi.id,
          onTap: () => _onPOITap(poi),
        ),
      );
    }).toList(),
  ),
```

### Marker-Größen

| Zustand | Größe |
|---------|-------|
| Normal | 32x32 |
| Must-See | 40x40 |
| Ausgewählt | 48x48 |

---

## State Management

### POI State Provider

```dart
// lib/features/poi/providers/poi_state_provider.dart
@Riverpod(keepAlive: true)
class POIStateNotifier extends _$POIStateNotifier {
  // POIs laden
  Future<void> loadPOIsInRadius({required LatLng center, required double radiusKm});
  Future<void> loadPOIsForRoute(AppRoute route);

  // On-Demand Enrichment
  Future<void> enrichPOI(String poiId);

  // Auswahl & Filter
  void selectPOI(POI? poi);
  void setFilter(POICategory? category);
  void setSearchQuery(String query);

  // Gefilterte POIs (für UI)
  List<POI> get filteredPOIs;
}
```

### Pre-Enrichment

Die POI-Liste lädt automatisch Bilder für sichtbare POIs:

```dart
// lib/features/poi/poi_list_screen.dart
void _preEnrichVisiblePOIs() {
  final poisToEnrich = poiState.filteredPOIs
      .where((poi) => !poi.isEnriched && poi.imageUrl == null)
      .take(20)
      .toList();

  for (final poi in poisToEnrich) {
    unawaited(poiNotifier.enrichPOI(poi.id));
  }
}
```

---

## Bekannte Einschränkungen

1. **Wikipedia API**: 10km Radius-Limit pro Anfrage
2. **Wikipedia CORS**: Im Web-Modus blockiert (funktioniert auf Android/iOS)
3. **Wikimedia Rate-Limit**: Max 200 Anfragen/Minute
4. **Wikidata SPARQL**: Kann bei komplexen Queries langsam sein
5. **Cache-Größe**: Bei vielen POIs kann Hive-Box groß werden

---

## Debug-Logging

| Prefix | Beschreibung |
|--------|--------------|
| `[POI]` | POI-Laden |
| `[Enrichment]` | POI Enrichment Service |
| `[POICache]` | Cache Operationen |
| `[POIState]` | State Änderungen |
| `[POIList]` | POI-Liste Pre-Enrichment |

Beispiel-Output:
```
[Enrichment] Starte Enrichment für: Brandenburger Tor
[Enrichment] Wikipedia-Daten geladen: Bild ✓, Beschreibung ✓
[Enrichment] Wikidata-Daten geladen: UNESCO=true
[POICache] POI gecached: Brandenburger Tor
```
