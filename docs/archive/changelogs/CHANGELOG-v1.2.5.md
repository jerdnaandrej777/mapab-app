# Changelog v1.2.5 - POI-System Erweiterung

**Release-Datum:** 21. Januar 2026

## Zusammenfassung

Diese Version implementiert ein umfassendes POI-Enrichment-System mit Integration kostenloser Datenquellen (Wikipedia, Wikimedia Commons, Wikidata). Die Map zeigt nun echte POI-Marker mit Preview-Sheets, und die POI-Liste verwendet Live-Daten statt Demo-Einträge.

---

## Neue Features

### POI Enrichment Service
- **Wikipedia Extracts API** - Lädt Beschreibungen und Hauptbilder
- **Wikimedia Commons API** - Geo-basierte Bildsuche als Fallback
- **Wikidata SPARQL** - Strukturierte Daten (UNESCO-Status, Gründungsjahr, Architekturstil)
- **Cache-First Strategie** - Enrichment-Daten werden 30 Tage gecacht

### POI Highlights System
- **UNESCO-Welterbe** (🌍) - Automatisch erkannt via Wikidata P1435
- **Must-See** (⭐) - Score ≥ 85 oder isMustSee Flag
- **Geheimtipp** (💎) - Score < 50 mit "secret" Tag
- **Historisch** (🏛️) - Via Wikidata Heritage-Status
- **Familienfreundlich** (👨‍👩‍👧‍👦) - Tag-basiert

### Map-Marker Implementierung
- **POI-Marker** mit Kategorie-Icons auf der Karte
- **Highlight-Marker** größer dargestellt (Must-See, UNESCO)
- **POI-Preview Sheet** bei Tap auf Marker
- **Route-Polyline** mit Start/Ziel-Markern
- **Trip-Stops** mit nummerierten Markern

### POI State Management
- **POIStateNotifier** - Zentrales State Management für POIs
- **Radius-basiertes Laden** - POIs im Umkreis von GPS/Route
- **Kategorie-Filter** - Dynamische Filterung
- **On-Demand Enrichment** - Lazy Loading von Details

### POI Caching
- **Hive-basierter Cache** - Offline-Unterstützung
- **Region-Cache** - 7 Tage für POI-Listen
- **Enrichment-Cache** - 30 Tage für angereicherte Daten
- **Auto-Cleanup** - Abgelaufene Einträge werden gelöscht

---

## Neue Dateien

| Datei | Beschreibung |
|-------|--------------|
| `lib/data/services/poi_enrichment_service.dart` | Wikipedia/Wikimedia/Wikidata Integration |
| `lib/data/services/poi_enrichment_service.g.dart` | Riverpod Code-Generierung |
| `lib/data/services/poi_cache_service.dart` | Hive-basiertes POI Caching |
| `lib/data/services/poi_cache_service.g.dart` | Riverpod Code-Generierung |
| `lib/features/poi/providers/poi_state_provider.dart` | POI State Management |
| `lib/features/poi/providers/poi_state_provider.g.dart` | Riverpod Code-Generierung |

---

## Geänderte Dateien

### POI Repository (`lib/data/repositories/poi_repo.dart`)
- **NEU:** `_inferCategoryFromTitle()` - Keyword-basiertes Kategorie-Mapping
- **NEU:** `_inferScoreFromTitle()` - Score-Ermittlung aus Titel-Keywords
- **FIX:** Wikipedia-POIs erhalten passende Kategorien (nicht mehr alle "attraction")

**Keyword-Mapping:**
```dart
'castle': ['schloss', 'burg', 'festung', 'castle', 'fortress', 'palast']
'church': ['kirche', 'dom', 'kathedrale', 'kloster', 'abtei', 'münster']
'museum': ['museum', 'galerie', 'gallery', 'ausstellung']
'nature': ['nationalpark', 'naturpark', 'naturschutz', 'biosphäre']
'lake': ['see', 'lake', 'teich', 'weiher', 'stausee', 'talsperre']
'viewpoint': ['aussicht', 'turm', 'tower', 'view', 'panorama']
'monument': ['denkmal', 'memorial', 'monument', 'gedenkstätte']
```

### POI Model (`lib/data/models/poi.dart`)
**Neue Felder:**
- `foundedYear` (int?) - Gründungsjahr aus Wikidata
- `architectureStyle` (String?) - Architekturstil aus Wikidata
- `isEnriched` (bool) - Enrichment-Status Flag
- `thumbnailUrl` (String?) - Thumbnail für Listen

**Neue Computed Properties:**
```dart
bool get isHistoric => tags.contains('historic') || tags.contains('unesco');
bool get isSecret => tags.contains('secret');
List<POIHighlight> get highlights;
bool get hasHighlights => highlights.isNotEmpty;
```

### Categories (`lib/core/constants/categories.dart`)
**Neues Enum:**
```dart
enum POIHighlight {
  unesco('🌍', 'UNESCO-Welterbe', 0xFF00CED1),
  mustSee('⭐', 'Must-See', 0xFFFFD700),
  secret('💎', 'Geheimtipp', 0xFF9370DB),
  historic('🏛️', 'Historisch', 0xFFA0522D),
  familyFriendly('👨‍👩‍👧‍👦', 'Familienfreundlich', 0xFF4CAF50);

  final String icon;
  final String label;
  final int colorValue;
  Color get color => Color(colorValue);
}
```

### POI List Screen (`lib/features/poi/poi_list_screen.dart`)
- **KOMPLETT NEUGESCHRIEBEN** - Verwendet echte POI-Daten
- GPS-basiertes oder Route-basiertes Laden
- Filter mit State-Anbindung
- Highlight-Badges in POI-Cards

### POI Detail Screen (`lib/features/poi/poi_detail_screen.dart`)
- **KOMPLETT NEUGESCHRIEBEN** - Dynamische POI-Anzeige
- On-Demand Enrichment beim Öffnen
- Zeigt Bild, Beschreibung, Metadaten
- Wikipedia-Link Button
- Highlight-Chips (UNESCO, Must-See, etc.)

### POI Card Widget (`lib/features/poi/widgets/poi_card.dart`)
- **NEU:** `highlights` Parameter für Badge-Anzeige
- **NEU:** Optional Distanz-Anzeige
- Highlight-Badges (UNESCO, Must-See, Secret)

### Map View (`lib/features/map/widgets/map_view.dart`)
- **KOMPLETT NEUGESCHRIEBEN** - Echte Marker-Implementierung
- POI MarkerLayer mit GestureDetector
- Route PolylineLayer
- Start/End Marker (grün/rot)
- Trip-Stops mit Nummern
- POI Preview Bottom Sheet

**Neue Marker-Widgets:**
```dart
class POIMarker extends StatelessWidget { ... }
class StartMarker extends StatelessWidget { ... }
class EndMarker extends StatelessWidget { ... }
class StopMarker extends StatelessWidget { ... }
```

### Chat Screen (`lib/features/ai_assistant/chat_screen.dart`)
- **FIX:** GeocodingResult Property-Zugriff korrigiert
- `result.latitude` → `result.location.latitude`
- `result.longitude` → `result.location.longitude`

---

## API-Integrationen

### Wikipedia Extracts API
```
GET https://de.wikipedia.org/w/api.php
  ?action=query
  &titles={title}
  &prop=extracts|pageimages|pageprops
  &exintro=true
  &explaintext=true
  &piprop=original|thumbnail
  &pithumbsize=400
  &ppprop=wikibase_item
  &format=json
```

### Wikimedia Commons Geo-Search
```
GET https://commons.wikimedia.org/w/api.php
  ?action=query
  &generator=geosearch
  &ggscoord={lat}|{lng}
  &ggsradius=500
  &prop=imageinfo
  &iiprop=url
  &iiurlwidth=800
  &format=json
```

### Wikidata SPARQL
```sparql
SELECT ?image ?heritageStatus ?inception ?archStyle ?archStyleLabel WHERE {
  BIND(wd:{wikidataId} AS ?item)
  OPTIONAL { ?item wdt:P18 ?image. }
  OPTIONAL { ?item wdt:P1435 ?heritageStatus. }
  OPTIONAL { ?item wdt:P571 ?inception. }
  OPTIONAL {
    ?item wdt:P149 ?archStyle.
    ?archStyle rdfs:label ?archStyleLabel.
    FILTER(LANG(?archStyleLabel) = "de")
  }
}
LIMIT 1
```

---

## Architektur

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
│ (Beschreibungen)   │ (Bilder)          │ (Daten)    │
└─────────────────────────────────────────────────────┘
```

---

## Provider

### Neue Provider

```dart
// POI State (keepAlive)
@Riverpod(keepAlive: true)
class POIStateNotifier extends _$POIStateNotifier {
  Future<void> loadPOIsInRadius({required LatLng center, required double radiusKm});
  Future<void> loadPOIsForRoute(AppRoute route);
  Future<void> enrichPOI(String poiId);
  void selectPOI(POI? poi);
  void setFilter(POICategory? category);
  void setSearchQuery(String query);
}

// POI Enrichment Service
@riverpod
POIEnrichmentService poiEnrichmentService(Ref ref);

// POI Cache Service (keepAlive)
@Riverpod(keepAlive: true)
POICacheService poiCacheService(Ref ref);
```

---

## Bekannte Einschränkungen

1. **Wikipedia CORS** - Im Web-Modus blockiert (funktioniert auf Android/iOS)
2. **Wikimedia Rate-Limit** - Max 200 Anfragen/Minute
3. **Wikidata SPARQL** - Kann bei komplexen Queries langsam sein
4. **Cache-Größe** - Bei vielen POIs kann Hive-Box groß werden

---

## Debugging

### Neue Log-Präfixe
- `[Enrichment]` - POI Enrichment Service
- `[POICache]` - Cache Operationen
- `[POIState]` - State Änderungen

### Beispiel-Logs
```
[POI] 1068 POIs von Overpass geladen
[Enrichment] Starte Enrichment für: Brandenburger Tor
[Enrichment] Wikipedia-Daten geladen: Bild ✓, Beschreibung ✓
[Enrichment] Wikidata-Daten geladen: UNESCO=true
[POICache] POI gecached: Brandenburger Tor
```

---

## Migration

Keine Breaking Changes. Bestehende POI-Daten werden automatisch mit neuen Feldern (Default-Werte) geladen.

---

## Nächste Schritte (geplant für v1.2.6)

- [ ] POI-Suche auf Map
- [ ] Offline-Karten mit POI-Overlay
- [ ] POI-Bewertungen von Nutzern
- [ ] Verbesserte Bild-Galerie mit Swipe
