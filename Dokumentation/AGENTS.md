# AGENTS.md - Autonome Agent-Systeme in MapAB

Diese Dokumentation beschreibt die autonomen Agent-Systeme in der MapAB Flutter-App. Während [CLAUDE.md](../CLAUDE.md) die API-Details und Feature-Nutzung erklärt, fokussiert sich diese Datei auf die **Architektur-Patterns und Interaktionen** zwischen den Agents.

---

## 1. Einführung & Architektur-Übersicht

### Was sind "Agents" in diesem Projekt?

Im Kontext von MapAB sind **Agents** autonome Systeme, die:
- **Selbstständig Entscheidungen treffen** (z.B. POI-Auswahl basierend auf Wetter)
- **Asynchrone Workflows orchestrieren** (z.B. Multi-Source-Enrichment)
- **State Machines verwalten** (z.B. Trip-Generierung: config → generating → preview → confirmed)
- **Mit anderen Agents kommunizieren** über Provider-Events und Callbacks

### 5 Haupt-Agents

| Agent | Typ | Hauptaufgabe | Provider |
|-------|-----|--------------|----------|
| **AI Trip Generator** | State Machine | Autonome Tripplanung mit Wetter-Integration | `RandomTripNotifier` |
| **POI Enrichment Pipeline** | Asynchroner Batch-Prozessor | Multi-Source-Fallback für POI-Bilder & Daten | `POIEnrichmentService` |
| **AI Chat Assistant** | Context-Builder | Standortbasierte POI-Empfehlungen | `AIService` |
| **Route Session Manager** | Event-driven Orchestrator | Koordination von POIs, Wetter, RouteOnlyMode | `RouteSessionProvider` |
| **Auto-Route Calculator** | Automatisierungs-Agent | GPS→POI Auto-Routing, Route-Neuberechnung | `TripStateProvider` |

### System-Diagramm

```
┌─────────────────────────────────────────────────────────────────┐
│                    MAPAB AGENT ARCHITECTURE                     │
└─────────────────────────────────────────────────────────────────┘

        ┌──────────────────────────────────────────┐
        │  USER INTERACTION (MapScreen, Chat, etc) │
        └───────────────────┬──────────────────────┘
                            │
        ┌───────────────────┴───────────────────┐
        │                                       │
        ↓                                       ↓
┌──────────────────┐                  ┌──────────────────────┐
│ AI Trip Generator│◄────────────────►│ LocationWeather      │
│ (RandomTrip)     │  Wetter-Kategorien│ (weather.condition)  │
└────────┬─────────┘                  └──────────────────────┘
         │                                      │
         │ _enrichGeneratedPOIs()               └─ MapScreen
         ↓                                         (WeatherChip/Banner)
┌──────────────────────────────────────────────┐
│  POI Enrichment Pipeline                     │
│  ┌────────────────────────────────────────┐  │
│  │ Concurrency: max 3 parallel            │  │
│  │ Fallback: 7 Bildquellen                │  │
│  │ Batch: 5er-Gruppen mit 500ms Pause     │  │
│  │ 2-Stufen-UI: onPartialResult-Callback  │  │
│  └────────────────────────────────────────┘  │
└────────┬─────────────────────────────────────┘
         │
         ↓
┌──────────────────────────────────────────────┐
│  POIStateNotifier (keepAlive)                │
│  - POIs verwalten (add/enrich/clear)         │
│  - RouteOnlyMode Filter                      │
│  - enrichingPOIIds Set (Race-Protection)     │
└────────┬─────────────────────────────────────┘
         │
    ┌────┴────┐
    ↓         ↓
┌────────┐ ┌──────────────────────┐
│ Cache  │ │ AI Chat Assistant    │
│ (Hive) │ │ - TripContext bauen  │
└────────┘ │ - Keyword→Kategorie  │
           │ - Location-Based POI │
           └──────────────────────┘

┌──────────────────────────────────────────────┐
│  Route Session Manager                       │
│  startRoute() → loadPOIs + loadWeather       │
│  stopRoute()  → cleanup (POIs, Wetter, Mode) │
└────────┬─────────────────────────────────────┘
         │
         ↓
┌──────────────────────────────────────────────┐
│  Auto-Route Calculator (TripStateProvider)   │
│  - addStopWithAutoRoute() (GPS→POI v1.7.4)   │
│  - _recalculateRoute() (auto bei Änderungen) │
│  - AI-Trip-Integration (v1.7.8)              │
└────────┬─────────────────────────────────────┘
         │
         ↓
┌──────────────────────────────────────────────┐
│  RoutePlannerProvider                        │
│  - setStart/setEnd → _tryCalculateRoute()    │
│  - clearRoute() → Cascade-Cleanup            │
└────────┬─────────────────────────────────────┘
         │
         ↓
┌──────────────────────────────────────────────┐
│  MapControllerProvider                       │
│  - shouldFitToRouteProvider (Event-Signal)   │
│  - fitCamera() auf Route                     │
└──────────────────────────────────────────────┘
```

### Provider-Dependency-Graph

```
LocationManager (Geolocator)
    ├─ RandomTripNotifier
    ├─ LocationWeatherNotifier (keepAlive, v1.7.17)
    └─ ChatScreen (_initializeLocation)

RandomTripNotifier (keepAlive)
    ├─ POIStateNotifier.addPOI() + enrichPOIsBatch()
    ├─ TripStateProvider.setRoute/setStops
    └─ shouldFitToRouteProvider = true

POIStateNotifier (keepAlive)
    ├─ POIEnrichmentService (Singleton)
    ├─ POICacheService (Hive)
    └─ enrichingPOIIds Set (Race-Protection)

TripStateProvider (keepAlive)
    ├─ RoutingRepository (OSRM)
    ├─ RoutePlannerProvider (clearRoute bei Neuberechnung)
    └─ shouldFitToRouteProvider = true

RouteSessionProvider (keepAlive)
    ├─ POIStateNotifier (setRouteOnlyMode, clearPOIs)
    ├─ RouteWeatherNotifier (keepAlive, v1.7.17 - loadWeatherForRoute, clear)
    └─ lifecycle: startRoute() / stopRoute()

RoutePlannerProvider (keepAlive)
    ├─ TripStateProvider (setRoute)
    ├─ RouteSessionProvider (stopRoute)
    └─ shouldFitToRouteProvider = true

MapControllerProvider (StateProvider)
    ├─ shouldFitToRouteProvider (trigger)
    └─ MapScreen (fitCamera)
```

---

## 2. AI Trip Generator Agent

**Datei:** [lib/features/random_trip/providers/random_trip_provider.dart](../lib/features/random_trip/providers/random_trip_provider.dart)

### State Machine

```
┌─────────────────────────────────────────────────────────┐
│         RandomTripStep (4 States)                       │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  CONFIG                                                 │
│    │ User konfiguriert: Startpunkt, Radius, Kategorien │
│    ↓ generateTrip()                                     │
│  GENERATING                                             │
│    │ TripGenerator läuft, POIs werden geladen          │
│    ↓ Trip erfolgreich                                   │
│  PREVIEW ◄─────────────┐                                │
│    │ Trip angezeigt    │ rerollPOI() / removePOI()     │
│    │ Editierbar        │ backToConfig()                │
│    ↓ confirmTrip()     │                                │
│  CONFIRMED             │                                │
│    │ Route aktiv       │                                │
│    ↓ reset()           │                                │
│    └───────────────────┘                                │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

**State-Übergänge:**

| Von | Nach | Trigger | Aktion |
|-----|------|---------|--------|
| config | generating | `generateTrip()` | GPS-Standort abrufen, TripGenerator starten |
| generating | preview | Trip erfolgreich | `_enrichGeneratedPOIs()`, State speichern |
| generating | config | Fehler | Error-Message, zurück zu Konfiguration |
| preview | confirmed | `confirmTrip()` | Route zu TripStateProvider, alte Daten löschen |
| preview | preview | `rerollPOI(poiId)` | Einzelnen POI ersetzen, Route neu berechnen |
| preview | preview | `removePOI(poiId)` | POI entfernen (min. 2 bleiben), Route neu berechnen |
| preview | config | `backToConfig()` | Zurück zur Konfiguration |
| confirmed | config | `reset()` | Alle Daten löschen |
| * | config | `reset()` | Notfall-Reset |

**Zusätzlich (v1.7.8):**
- `markAsConfirmed()`: Setzt nur Step auf CONFIRMED **ohne** alte Daten zu löschen
- Wird verwendet wenn Stop über POI-Liste hinzugefügt wird (AI-Trip-Integration)

### Autonome POI-Auswahl-Logik

**Pipeline:**

```
1. POI-Laden
   ├─ POIRepository.loadPOIsInRadius(center, radiusKm)
   │  ├─ Curated POIs (assets/data/curated_pois.json)
   │  ├─ Wikipedia POIs (Geosearch API, parallel)
   │  └─ Overpass POIs (Kategorien-spezifisch, parallel)
   └─ Verfügbare POIs im Radius

2. Kategorie-Filter
   └─ selectedCategories anwenden
      └─ Falls weatherCategoriesApplied: Wetter-basierte Kategorien

3. POI-Count berechnen
   ├─ Daytrip: (radiusKm / 20).clamp(3, 8)
   │  └─ 30km → 3, 100km → 5, 160km → 8
   └─ Euro Trip: days * estimatePoisPerDay()
      └─ ~4-5 POIs pro Tag (max 9 wegen Google Maps Limit)

4. Zufällige Auswahl mit Scoring
   ├─ Distanz-Scoring (näher = besser)
   ├─ Must-See-Bevorzugung (isMustSee: true)
   ├─ Score-Ranking (höhere Scores bevorzugt)
   └─ Zufällige Auswahl aus Top-Kandidaten

5. Route-Optimierung (TSP)
   └─ Traveling Salesman Problem für beste Besuchsreihenfolge

6. OSRM-Route berechnen
   └─ Reale Distanz (km) + Fahrzeit (Minuten)
```

**Code-Referenz:**
- Kategorie-Filter: `random_trip_provider.dart:generateTrip()`
- POI-Count: `trip_generator_repo.dart:generateDayTrip()`
- Scoring: `trip_generator_repo.dart:_selectRandomPOIs()`

### Wetter-Integration (v1.7.6+)

**Funktion:** `applyWeatherBasedCategories(WeatherCondition condition)`

```dart
// Mapping: WeatherCondition → empfohlene Kategorien
WeatherCondition.danger → [museum, church]
  // Nur Indoor! (8% Varianz durch andere)

WeatherCondition.bad → [museum, church, castle, city]
  // Indoor bevorzugt, mit Outdoor-Fallback

WeatherCondition.mixed → []
  // Alle Kategorien erlaubt (flexibel planen)

WeatherCondition.good → [nature, viewpoint, lake, coast, park,
                         activity, castle, monument]
  // Outdoor bevorzugen

WeatherCondition.unknown → []
  // Keine Einschränkung
```

**State-Flag:**
- `weatherCategoriesApplied: bool` - Prüfen ob Wetter-Filter aktiv

**Reset-Funktion (v1.7.9 - Toggle):**
```dart
resetWeatherCategories()
  ├─ selectedCategories = alle außer hotel
  └─ weatherCategoriesApplied = false
```

**UI-Integration:**
```dart
// MapScreen: UnifiedWeatherWidget (v1.7.19)
// Standort-Modus (ohne Route): Wetter-Kategorien Toggle
// Route-Modus (mit Route): Indoor-Filter Toggle
if (weatherState.showWarning) {
  // ON: applyWeatherBasedCategories()
  // OFF: resetWeatherCategories()
}
```

### POI-Reroll & Remove

**Reroll Einzelner POI:**

```
rerollPOI(poiId)
    ↓
1. Alten POI finden in selectedPOIs
    ↓
2. RandomPOISelector.rerollSinglePOI()
    ├─ Verfügbare POIs (außer bereits ausgewählten)
    ├─ Ähnliche Kategorie bevorzugt
    ├─ Distanz-Scoring
    └─ Neuer POI auswählen
    ↓
3. Route neu optimieren (TSP mit neuen POIs)
    ↓
4. OSRM neu berechnen
    ↓
5. State aktualisieren
    ├─ generatedTrip: neue selectedPOIs
    ├─ generatedTrip.trip.route: neue Route
    └─ loadingPOIId: null
```

**Remove POI:**

```
removePOI(poiId)
    ↓
1. Minimum-Check: selectedPOIs.length > 2?
    ├─ NEIN → Error "Mindestens 2 Stops erforderlich"
    └─ JA → Fortfahren
    ↓
2. POI entfernen aus selectedPOIs
    ↓
3. Route neu optimieren
    ↓
4. OSRM neu berechnen
    ↓
5. Trip-Name neu generieren
    ↓
6. State aktualisieren
```

**Loading-States:**
```dart
// Per-POI Loading State
loadingPOIId: String?

// UI kann prüfen:
bool isPOILoading(String poiId) =>
    loadingPOIId == poiId;

// State-Constraint für UI
bool get canRemovePOI =>
    generatedTrip != null &&
    generatedTrip!.selectedPOIs.length > 2;
```

### Mehrtägige Euro Trips (v1.5.7+)

**Tagesberechnung:**

```dart
import '../../core/constants/trip_constants.dart';

// Formel: 600km pro Tag
days = ceil(radiusKm / TripConstants.kmPerDay)
days = clamp(1, 14)  // Max 14 Tage

// Beispiele:
600km  → 1 Tag
1200km → 2 Tage
1800km → 3 Tage
4200km → 7 Tage
```

**DayPlanner-Algorithmus:**

```
Optimierte POIs (nach TSP)
    ↓
DayPlanner._clusterPOIsByGeography(pois, days)
    ├─ poisPerDay = ceil(pois.length / days)
    ├─ poisPerDay.clamp(2, 9)  ← Google Maps Limit!
    └─ Erstelle geografische Clusters
    ↓
Für jeden Tag (Cluster):
    ├─ Lokales TSP (Route-Optimierung)
    ├─ OSRM: Distanz + Dauer berechnen
    ├─ Titel generieren: "Tag N: {MainHighlight}"
    ├─ TripDay erstellen
    │  ├─ stops: List<POI>
    │  ├─ distanceKm: double
    │  ├─ durationMinutes: int
    │  └─ title: String
    └─ Nächster Tag startet am letzten POI
    ↓
TripDays: List<TripDay>
```

**Google Maps Constraint:**
- Max 9 Waypoints pro Tag (= Google Maps API Limit)
- `TripConstants.maxPoisPerDay = 9`

**Übernachtungs-Logik (Hotels, v1.7.8+):**

```dart
calculateOvernightLocations()
    └─ Für jeden Tag außer dem letzten:
       Übernachtung = letzter POI des Tages
    ↓
HotelService.searchHotelsForMultipleLocations()
    ├─ 15km Radius pro Location
    ├─ Max 3 Hotels pro Location
    └─ Sortiert nach Rating
    ↓
Beste Hotels als TripStops hinzufügen
    ├─ order: Nach bestehenden Stops
    ├─ isOvernightStop: true
    └─ In TripDays integrieren
```

### Tagesweiser Export (v1.5.7+)

**State-Tracking:**

```dart
selectedDay: int           // 1-basiert (Tag 1, Tag 2, ...)
completedDays: Set<int>    // {1, 2} = Tag 1 & 2 exportiert
```

**Workflow:**

```
User: selectDay(2)
    └─ selectedDay = 2
    ↓
UI zeigt: Stops für Tag 2
    ├─ stopsForSelectedDay: List<POI>
    ├─ stopsCountForSelectedDay: int
    └─ selectedDayOverLimit: bool (> 9 POIs?)
    ↓
User: Export zu Google Maps
    ├─ Tag 1: Start = Trip-Start
    ├─ Tag 2-N: Start = letzter Stop vom Vortag
    ├─ Waypoints: Alle Stops des Tages (max 9)
    └─ Ziel: Letzter Tag = Trip-Start, sonst erster Stop vom Folgetag
    ↓
completeDay(2)
    ├─ completedDays.add(2)
    └─ Auto-Wechsel zu Tag 3 (falls vorhanden)
```

**Getter:**

```dart
// Prüfen ob Tag exportiert
bool isDayCompleted(int day) =>
    completedDays.contains(day);

// Anzahl Tage
int get tripDays =>
    generatedTrip?.trip.days.length ?? 0;
```

### Integration mit anderen Agents

**1. POIEnrichmentService:**

```dart
_enrichGeneratedPOIs(GeneratedTrip result) async {
  // 1. POIs zu POIState hinzufügen
  for (poi in result.selectedPOIs) {
    ref.read(pOIStateNotifierProvider.notifier).addPOI(poi);
  }

  // 2. Batch-Enrichment für POIs ohne Bilder
  final poisToEnrich = result.selectedPOIs
      .where((p) => p.imageUrl == null && !p.isEnriched)
      .take(10)
      .toList();

  if (poisToEnrich.isNotEmpty) {
    await ref.read(pOIStateNotifierProvider.notifier)
        .enrichPOIsBatch(poisToEnrich);
  }
}
```

**2. TripStateProvider:**

```dart
confirmTrip() {
  // 1. Alte Route löschen
  ref.read(routePlannerProvider.notifier).clearStart();
  ref.read(routePlannerProvider.notifier).clearEnd();

  // 2. Alte Route-Session stoppen
  ref.read(routeSessionProvider.notifier).stopRoute();

  // 3. Alte POIs löschen
  ref.read(pOIStateNotifierProvider.notifier).clearPOIs();

  // 4. Neue Route setzen
  ref.read(tripStateProvider.notifier).setRoute(trip.route);

  // 5. Neue Stops setzen
  for (poi in selectedPOIs) {
    ref.read(tripStateProvider.notifier).addStop(poi);
  }

  // 6. State → CONFIRMED
  state = state.copyWith(step: RandomTripStep.confirmed);
}
```

**3. shouldFitToRouteProvider (Auto-Zoom):**

```dart
// Nach Trip-Generierung
ref.listenManual(randomTripNotifierProvider, (previous, next) {
  if (next.step == RandomTripStep.preview) {
    ref.read(shouldFitToRouteProvider.notifier).state = true;
  }
});
```

---

## 3. POI Enrichment Pipeline

**Datei:** [lib/data/services/poi_enrichment_service.dart](../lib/data/services/poi_enrichment_service.dart)

### Workflow-Diagramm

```
┌─────────────────────────────────────────────────────────────────┐
│                  POI ENRICHMENT PIPELINE v1.7.9                 │
└─────────────────────────────────────────────────────────────────┘

ENTRY: enrichPOI(poi) oder enrichPOIsBatch(pois)
           │
           ▼
   ┌───────────────────┐
   │ 1. CACHE LOOKUP   │
   │ (Hive 30-day TTL) │
   └────────┬──────────┘
            │
    ┌───────▼────────┐
    │ Cache Hit?     │
    └───┬────────┬───┘
        │        │
    YES │        │ NO
        ▼        ▼
      RETURN  [CONTINUE]
        POI    │
              │
┌─────────────┘
│
▼
┌───────────────────────────────────┐
│ 2. CONCURRENCY CONTROL            │
│ (Max 3 parallel, wait queue)      │
│ _acquireSlot() → Block if full    │
└────────────┬──────────────────────┘
             │
             ▼
┌───────────────────────────────────┐
│ 3. PARALLEL API CALLS (Stage 1)  │
│                                   │
│ ┌──────────────────────────────┐  │
│ │ A. DE Wikipedia Extract      │  │  PARALLEL
│ │    (image + description)     │  │
│ └──────────────────────────────┘  │
│ ┌──────────────────────────────┐  │
│ │ B. Wikimedia Commons (Geo)   │  │
│ │    (10km radius, 15 results) │  │
│ └──────────────────────────────┘  │
│ ┌──────────────────────────────┐  │
│ │ C. Wikidata SPARQL           │  │
│ │    (P18, P154, P94)          │  │
│ └──────────────────────────────┘  │
└────────────┬──────────────────────┘
             │
             ▼
┌───────────────────────────────────┐
│ 4. MERGE RESULTS                  │
│ Priority: Wiki > Wikimedia > WD   │
└────────────┬──────────────────────┘
             │
             ▼
┌─────────────────────────────────────────┐
│ 5. FALLBACK CHAIN (7 Sources)          │
│ IF image == null:                       │
│ ├─ [1] OSM Tags (from repo load)       │
│ ├─ [2] DE Wikipedia (done in Stage 1)  │
│ ├─ [3] Wikimedia Geo (done in Stage 1) │
│ ├─ [4] Wikimedia Titel-Suche           │
│ │      (Umlaut-Normalisierung)         │
│ ├─ [5] Wikimedia Kategorie-Suche       │
│ ├─ [6] EN Wikipedia (image only)       │
│ └─ [7] Wikidata (done in Stage 1)      │
└────────────┬────────────────────────────┘
             │
     ┌───────▼───────┐
     │ Image found?  │
     └───┬────────┬──┘
         │        │
     YES │        │ NO
         │        └─────────────────┐
         │                          │
         ▼                          ▼
┌────────────────┐      ┌──────────────────────┐
│ 6. PRE-CACHE   │      │ 6b. SESSION TRACKING │
│ Image (v1.7.9) │      │ _sessionAttemptedW.. │
│ Disk-Cache     │      │ Prevent re-attempt   │
└────────┬───────┘      └──────────┬───────────┘
         │                         │
         └────────────┬────────────┘
                      │
                      ▼
        ┌───────────────────────────────┐
        │ 7. CACHE IF IMAGE EXISTS      │
        │ (Hive 30 days, hasImage only) │
        └────────────┬──────────────────┘
                     │
                     ▼
        ┌───────────────────────────────┐
        │ 8. APPLY ENRICHMENT TO POI    │
        │ Mark: isEnriched = true       │
        │ Add tags: unesco, historic    │
        └────────────┬──────────────────┘
                     │
                     ▼
        ┌───────────────────────────────┐
        │ 9. RELEASE CONCURRENCY SLOT   │
        │ _releaseSlot() → Unblock next │
        └────────────┬──────────────────┘
                     │
                     ▼
                RETURN enrichedPOI
```

### 7 Bildquellen (Fallback-Chain)

| # | Quelle | Typ | Priorität | Retry | Timing |
|---|--------|-----|-----------|-------|--------|
| **1** | OSM Tags (`image`, `wikimedia_commons`) | Direct URLs | Höchste | Nein | Bei POI-Laden (poi_repo.dart) |
| **2** | DE Wikipedia `pageimages` | Wikipedia API | Hoch | 3x | Stage 1: parallel, 0ms |
| **3** | Wikimedia Commons Geo-Suche | 10km Radius, 15 Results | Hoch | 3x | Stage 1 oder 3, 200ms delay |
| **4** | Wikimedia Commons Titel-Suche | Varianten (Umlaute, Präfixe) | Mittel | 3x | Stage 3, 200ms per variant |
| **5** | Wikimedia Commons Kategorie | Category-based | Mittel | 3x | Stage 3, nach Titel |
| **6** | EN Wikipedia Fallback | Nur wenn DE leer | Mittel-Hoch | 3x | Stage 1 (falls DE leer) |
| **7** | Wikidata SPARQL (P18, P154, P94) | Image, Logo, Wappen | Niedrig | 3x | Stage 1: parallel, 0ms |

**Fallback-Logik:**

```dart
// Pseudo-Code
enrichment = DE_Wikipedia ∪ Wikimedia_Geo ∪ Wikidata
if (enrichment.hasImage) return enrichment;

// Fallback-Chain
enrichment ∪= Wikimedia_Titel_Search (mit Varianten)
if (enrichment.hasImage) return enrichment;

enrichment ∪= Wikimedia_Category_Search
if (enrichment.hasImage) return enrichment;

enrichment ∪= EN_Wikipedia (nur Bild, falls DE leer)
if (enrichment.hasImage) return enrichment;

// Kein Bild gefunden
if (!enrichment.hasImage) {
  _sessionAttemptedWithoutPhoto.add(poi.id);
  return enrichment;  // Ohne isEnriched=true!
}
```

**Code-Referenz:**
- OSM Tags: `poi_repo.dart:_extractPOIsFromOverpass()`
- Wikipedia: `poi_enrichment_service.dart:_fetchWikipediaInfo()`
- Wikimedia: `poi_enrichment_service.dart:_searchWikimediaCommons()`
- Wikidata: `poi_enrichment_service.dart:_fetchWikidataInfo()`

### Batch-Enrichment (v1.7.3, Enhanced v1.7.9)

**2-Stufen-UI-Update:**

```
enrichPOIsBatch(pois, onPartialResult?)
        │
        ▼
┌─────────────────────────────────┐
│ STAGE 1: CACHE FILTERING        │
│ Load all from Hive cache        │
│ Sort: cached / uncached         │
└────────────┬────────────────────┘
             │
    onPartialResult?(cached)  ◄── UI sieht Cache-Bilder SOFORT
             │
             ▼
┌─────────────────────────────────┐
│ STAGE 2: WIKIPEDIA BATCH        │
│ (up to 50 titles, 1 request)    │
│ Multi-Title Query optimization  │
└────────────┬────────────────────┘
             │
    onPartialResult?(wiki)    ◄── UI sieht Wikipedia ~1-2s
             │
             ▼
┌──────────────────────────────────┐
│ STAGE 3: WIKIMEDIA FALLBACK      │
│ (sub-batching für rate limits)   │
│                                  │
│ Wikipedia-POIs ohne Bild:        │
│ ├─ Group: 5-POI sub-batches      │
│ ├─ Delay: 500ms zwischen batches │
│ ├─ Geo-search per POI            │
│ └─ Limit: 15 POIs (war 5)        │
│                                  │
│ POIs ohne Wikipedia:             │
│ ├─ Group: 5-POI sub-batches      │
│ ├─ Delay: 500ms zwischen batches │
│ ├─ Geo-search per POI            │
│ └─ Store attempted set           │
└────────────┬─────────────────────┘
             │
    onPartialResult?(wikimedia) ◄── UI sieht Wikimedia ~2-5s
             │
             ▼
┌──────────────────────────────────┐
│ FINAL: SESSION TRACKING          │
│ POIs ohne Bild NICHT als         │
│ isEnriched markieren!            │
│ → Retry bei App-Restart          │
└────────────┬─────────────────────┘
             │
             ▼
        RETURN results map
```

**Performance:**

| Version | Zeit für 20 POIs | API-Calls | Bild-Trefferquote |
|---------|------------------|-----------|-------------------|
| v1.3.6 | 60+ Sek | ~160 | ~60% |
| v1.3.7 | 21+ Sek | ~80 | ~85% |
| v1.7.3 | ~3 Sek | ~4 | ~85% |
| v1.7.9 | ~2 Sek | ~4-8 | ~98% |

**Verbesserungen:**
- **7x schneller** durch Wikipedia Multi-Title-Query (v1.7.3)
- **2-Stufen-UI**: Cache → Wiki → Wikimedia (v1.7.9)
- **Fallback-Limit**: 5 → 15 POIs (v1.7.9)
- **Image Pre-Caching**: Disk-Cache für instant Display (v1.7.9)

### Retry-Strategie - Exponential Backoff

```dart
_requestWithRetry(url, params) {
  for (attempt = 0; attempt < 3; attempt++) {
    try {
      response = _dio.get(url, params)

      if (statusCode == 200)
        return response;  ✓ Success

      if (statusCode == 429) {  ⚠️ Rate-Limit
        log("[Enrichment] ⚠️ Rate-Limit (429)!");
        await Future.delayed(Duration(seconds: 5));
        continue;  // Doesn't count as attempt!
      }

      log("Unexpected: $statusCode");
      return null;  ✗ Fail

    } catch (DioException e) {
      if (attempt == 2)
        return null;  ✗ Final failure

      delay = 500ms × (attempt + 1);
      // Attempt 0: 500ms
      // Attempt 1: 1000ms
      // Attempt 2: 1500ms

      await Future.delayed(delay);
      continue;  ↺ Retry
    }
  }
  return null;
}
```

**Key Points:**
- **HTTP 429**: Wartet 5s, zählt NICHT als Attempt
- **Timeout/Connection**: Exponential Backoff (500ms → 1s → 1.5s)
- **Unexpected Status**: Sofortiger Fail ohne Retry
- **Max 3 Attempts** pro API-Endpunkt

### Concurrency-Control

```dart
// Static Pool Configuration
static int _maxConcurrentEnrichments = 3;
static int _activeEnrichments = 0;
static final List<Completer<void>> _waitQueue = [];
static final Set<String> _enrichingPOIs = {};

enrichPOI(poi) async {
  // 1. Check if already enriching
  if (_enrichingPOIs.contains(poi.id)) {
    // Wait on existing Completer (max 30s)
    final completer = _enrichmentCompleters[poi.id];
    await completer?.future.timeout(Duration(seconds: 30));
    return cachedOrOriginal;
  }

  // 2. Acquire slot (blocks if 3 running)
  await _acquireSlot();
  _enrichingPOIs.add(poi.id);

  // 3. Create Completer for other waiters
  final completer = Completer<void>();
  _enrichmentCompleters[poi.id] = completer;

  try {
    // [DO ENRICHMENT]
    return enrichedPOI;
  } finally {
    // 4. Release slot
    _enrichingPOIs.remove(poi.id);
    _enrichmentCompleters.remove(poi.id);
    completer.complete();
    _releaseSlot();
  }
}

_acquireSlot() async {
  if (_activeEnrichments < 3) {
    _activeEnrichments++;
    return;
  }

  // Queue: Wait for slot
  final completer = Completer<void>();
  _waitQueue.add(completer);
  await completer.future;  ◄── BLOCKS HERE
  _activeEnrichments++;
}

_releaseSlot() {
  _activeEnrichments--;

  // Unblock next waiter
  if (_waitQueue.isNotEmpty) {
    final next = _waitQueue.removeAt(0);
    next.complete();  ◄── Unblocks _acquireSlot()
  }
}
```

**Benefit:**
- **Max 3 concurrent** = Optimal zwischen Performance und Rate-Limiting
- **Wait-Queue**: Fairness, keine POI-Verhungerung
- **Duplicate-Protection**: `_enrichingPOIs` Set verhindert Doppel-Enrichment

### Rate-Limit-Handling

```dart
// API Call Delays
static const Duration _apiCallDelay = Duration(milliseconds: 200);

// Applied after:
// - Wikimedia Geo-Search
// - Wikimedia Titel-Suche (per Variante)
// - Between sub-batches (500ms)
// - Wikimedia Category-Search

// HTTP 429 Detection
if (response.statusCode == 429) {
  log("[Enrichment] ⚠️ Rate-Limit (429)!");
  await Future.delayed(Duration(seconds: 5));
  // Retry (doesn't count as attempt)
}

// Sub-Batching Strategy (v1.7.9)
final subBatches = poisToEnrich.splitIntoChunks(5);
for (final batch in subBatches) {
  await Future.wait(batch.map((poi) => _enrichPOI(poi)));
  if (batch != subBatches.last) {
    await Future.delayed(Duration(milliseconds: 500));
  }
}
```

### Session-Set Duplicate-Prevention (v1.7.9)

**Problem (v1.5.3):**
- POIs ohne Bild wurden als `isEnriched=true` gecacht
- → 30 Tage Cache = nie wieder versucht
- → Hohe False-Negative-Rate

**Lösung (v1.7.9):**

```dart
static final Set<String> _sessionAttemptedWithoutPhoto = {};

enrichPOIsBatch(pois) {
  for (poi in unenrichedPOIs) {
    // Skip if already attempted in this session
    if (_sessionAttemptedWithoutPhoto.contains(poi.id)) {
      continue;
    }

    final enrichment = await _fetchEnrichment(poi);

    if (!enrichment.hasImage) {
      // Mark as attempted, but DON'T cache
      _sessionAttemptedWithoutPhoto.add(poi.id);
      // isEnriched bleibt FALSE → Retry bei App-Restart
    } else {
      // Cache nur mit Bild
      await cacheService.cacheEnrichedPOI(enrichedPOI);
      poi = poi.copyWith(isEnriched: true);
    }
  }
}

// App Lifecycle: Set wird bei Restart geleert
// → Fresh attempts on next session
```

### Image Pre-Caching (v1.7.9)

```dart
_prefetchImage(String imageUrl) async {
  try {
    await DefaultCacheManager().getSingleFile(
      imageUrl,
      headers: {'User-Agent': '...'},
    ).timeout(Duration(seconds: 10));

    log('[Enrichment] ✓ Image pre-cached: $imageUrl');
  } catch (e) {
    // Silent fail - UI handles it gracefully
    log('[Enrichment] ⚠️ Pre-cache failed: $e');
  }
}

// Called after successful enrichment
if (enrichedPOI.imageUrl != null) {
  unawaited(_prefetchImage(enrichedPOI.imageUrl!));
}
```

**Benefit:**
- **Instant Display**: Bild ist bereits im Disk-Cache
- **Keine Spinner** nach Enrichment-Abschluss
- **Smooth UX**: Data ready → UI sieht Bild sofort

### Race-Condition-Fix (v1.5.1)

**Problem:**

```dart
// VORHER (FEHLERHAFT):
final updatedPOIs = List<POI>.from(state.pois);  // Snapshot bei T0
// ... async await (andere Enrichments ändern state hier)
await enrichmentService.enrichPOI(poi);          // T0 + 1000ms
state = state.copyWith(pois: updatedPOIs);      // Überschreibt ALLE Änderungen seit T0!
```

**Lösung:**

```dart
// NACHHER (KORREKT):
_updatePOIInState(String poiId, POI enrichedPOI) {
  // Liest AKTUELLEN State (nicht alte Kopie)
  final currentPOIs = state.pois;
  final currentIndex = currentPOIs.indexWhere((p) => p.id == poiId);

  if (currentIndex == -1) return;

  // Atomares Update nur dieses einen POIs
  final updatedPOIs = List<POI>.from(currentPOIs);
  updatedPOIs[currentIndex] = enrichedPOI;

  state = state.copyWith(pois: updatedPOIs);
}
```

**Best Practice:**
- **Nie alte State-Kopien** nach `await` verwenden
- **Atomar aktualisieren**: Ein POI zur Zeit
- **Aktuellen State lesen** unmittelbar vor Update

---

## 4. AI Chat Assistant Agent

**Datei:** [lib/data/services/ai_service.dart](../lib/data/services/ai_service.dart)

### Context-Building

**TripContext Struktur (v1.7.2):**

```dart
class TripContext {
  final AppRoute? route;
  final List<POI> stops;

  // NEU: Standort-Informationen
  final double? userLatitude;
  final double? userLongitude;
  final String? userLocationName;

  bool get hasUserLocation =>
      userLatitude != null && userLongitude != null;
}
```

**Context wird an Backend gesendet:**

```dart
final contextData = <String, dynamic>{};

if (context.hasRoute) {
  contextData['route'] = {
    'distance': context.route!.distanceKm,
    'duration': context.route!.durationMinutes,
    'start': context.route!.startAddress,
    'end': context.route!.endAddress,
  };
}

if (context.stops.isNotEmpty) {
  contextData['stops'] = context.stops.map((poi) => {
    'name': poi.name,
    'category': poi.category.toString(),
    'location': {'lat': poi.latitude, 'lng': poi.longitude},
  }).toList();
}

if (context.hasUserLocation) {
  contextData['userLocation'] = {
    'lat': context.userLatitude,
    'lng': context.userLongitude,
    'name': context.userLocationName,
  };
}
```

### Keyword→Kategorie-Mapping (v1.7.9 - gefixt)

**Kategorien-Zuordnung:**

| Anfrage | POICategory Werte |
|---------|-------------------|
| "sehenswürdigkeiten", "kultur" | `museum`, `monument`, `castle`, `viewpoint`, `unesco` |
| "natur", "park", "wandern" | `nature`, `park`, `lake`, `coast` |
| "restaurant", "essen", "cafe" | `restaurant` |
| "hotel", "unterkunft" | `hotel` |
| "strand", "küste", "meer" | `coast` |
| "aktivität", "sport", "freizeit" | `activity` |
| "stadt", "urban" | `city` |
| "kirche", "kloster" | `church` |
| "see", "wasser" | `lake` |
| "aussicht", "panorama" | `viewpoint` |
| "unesco", "welterbe" | `unesco` |
| Unspezifisch | Alle Kategorien |

**Code:**

```dart
List<POICategory> _getCategoriesFromQuery(String query) {
  final q = query.toLowerCase();

  if (q.contains('sehenswürdigkeiten') || q.contains('kultur')) {
    return [POICategory.museum, POICategory.monument,
            POICategory.castle, POICategory.viewpoint,
            POICategory.unesco];
  }

  if (q.contains('natur') || q.contains('park') || q.contains('wandern')) {
    return [POICategory.nature, POICategory.park,
            POICategory.lake, POICategory.coast];
  }

  if (q.contains('restaurant') || q.contains('essen')) {
    return [POICategory.restaurant];
  }

  // ... weitere Mappings

  return [];  // Alle Kategorien
}
```

**Wichtig (v1.7.9 Fix):**
- Keine ungültigen IDs mehr (z.B. "cultural", "shopping")
- Nur valide `POICategory` enum Werte
- Fallback auf alle Kategorien bei Unsicherheit

### Location-Based POI Search

**Workflow:**

```
ChatScreen.initState()
    ↓
_initializeLocation()
    ├─ Geolocator.getCurrentPosition()
    ├─ _currentLocation: LatLng
    └─ _currentLocationName: String (via Nominatim)
    ↓
User: "POIs in meiner Nähe"
    ↓
_handleLocationBasedQuery(query)
    ├─ _isLocationBasedQuery() → true
    ├─ Kategorien extrahieren: _getCategoriesFromQuery()
    └─ POIRepository.loadPOIsInRadius(
         center: _currentLocation,
         radiusKm: _searchRadius,  // 10-100km einstellbar
         categoryFilter: categories,
       )
    ↓
Sortiere POIs nach Distanz
    ↓
Zeige POI-Karten im Chat
    ├─ Bild (CachedNetworkImage)
    ├─ Name + Beschreibung
    ├─ Distanz-Badge
    └─ Pfeil-Icon
    ↓
[OPTIONAL] Hintergrund-Enrichment (v1.7.7)
    └─ Batch-Enrichment für POIs ohne Bilder
       └─ Bilder erscheinen inkrementell nach 1-3 Sek
```

**Radius-Einstellung:**

```dart
// State
double _searchRadius = 30.0;  // Default 30km

// Slider Dialog
void _showRadiusSliderDialog() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Such-Radius'),
      content: StatefulBuilder(
        builder: (context, setState) => Column(
          children: [
            Slider(
              value: _searchRadius,
              min: 10.0,
              max: 100.0,
              divisions: 18,
              label: '${_searchRadius.round()} km',
              onChanged: (value) => setState(() => _searchRadius = value),
            ),
            // Quick-Select: 15, 30, 50, 100 km
          ],
        ),
      ),
    ),
  );
}
```

### Hintergrund-Enrichment (v1.7.7)

**Problem:** POIs im Chat zeigten nur Kategorie-Icons, keine Bilder.

**Lösung:**

```dart
_handleLocationBasedQuery(String query) async {
  final pois = await poiRepo.loadPOIsInRadius(...);

  // 1. Sofort POI-Karten anzeigen (mit Icons)
  setState(() {
    _messages.add({
      'content': headerText,
      'isUser': false,
      'type': ChatMessageType.poiList,
      'pois': sortedPOIs,
    });
  });

  // 2. Hintergrund-Enrichment starten
  final messageIndex = _messages.length - 1;
  final poisToEnrich = sortedPOIs
      .where((p) => p.imageUrl == null && !p.isEnriched)
      .take(10)
      .toList();

  if (poisToEnrich.isNotEmpty) {
    final enrichmentService = ref.read(poiEnrichmentServiceProvider);
    final enrichedMap = await enrichmentService.enrichPOIsBatch(poisToEnrich);

    // 3. Message aktualisieren mit Bildern
    if (mounted && messageIndex < _messages.length) {
      final updatedPOIs = sortedPOIs
          .map((p) => enrichedMap[p.id] ?? p)
          .toList();

      setState(() {
        _messages[messageIndex] = {
          ..._messages[messageIndex],
          'pois': updatedPOIs,
        };
      });
    }
  }
}
```

**Timeline:**
- **0ms**: POI-Karten mit Kategorie-Icons angezeigt
- **1-2s**: Wikipedia-Bilder erscheinen
- **2-5s**: Wikimedia-Fallback-Bilder erscheinen

### POI-Navigation

```dart
Widget _buildPOICard(POI poi, ColorScheme colorScheme) {
  return Card(
    child: InkWell(
      onTap: () => _navigateToPOI(poi),
      child: Row(
        children: [
          // Bild oder Placeholder
          CachedNetworkImage(
            imageUrl: poi.imageUrl ?? '',
            placeholder: (context, url) => Icon(poi.categoryIcon),
            errorWidget: (context, url, error) => Icon(poi.categoryIcon),
            width: 80,
            height: 80,
            fit: BoxFit.cover,
          ),
          // Name + Beschreibung
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(poi.name, style: TextStyle(fontWeight: FontWeight.bold)),
                if (poi.shortDescription != null)
                  Text(poi.shortDescription!, maxLines: 2),
              ],
            ),
          ),
          // Distanz Badge
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('${poi.distanceKm?.toStringAsFixed(1)} km'),
          ),
          Icon(Icons.chevron_right),
        ],
      ),
    ),
  );
}

void _navigateToPOI(POI poi) {
  // 1. POI zu State hinzufügen
  ref.read(pOIStateNotifierProvider.notifier).addPOI(poi);

  // 2. Enrichen falls kein Bild
  if (poi.imageUrl == null) {
    ref.read(pOIStateNotifierProvider.notifier).enrichPOI(poi.id);
  }

  // 3. Navigation
  context.push('/poi/${poi.id}');
}
```

---

## 5. Route Session Manager

**Datei:** [lib/features/map/providers/route_session_provider.dart](../lib/features/map/providers/route_session_provider.dart)

### Lifecycle

**State-Definition:**

```dart
@freezed
class RouteSessionState with _$RouteSessionState {
  const factory RouteSessionState({
    @Default(false) bool isActive,
    @Default(false) bool isLoading,
    @Default(false) bool poisLoaded,
    @Default(false) bool weatherLoaded,
  }) = _RouteSessionState;

  const RouteSessionState._();

  bool get isReady => isActive && poisLoaded && weatherLoaded;
}
```

**Workflow:**

```
startRoute(AppRoute route)
    ↓
state = RouteSessionState(isActive: true, isLoading: true)
    ↓
    ┌──────────┴──────────┐
    │                     │
    ↓ PARALLEL            ↓ PARALLEL
_loadPOIs(route)     _loadWeather(route)
    │                     │
    ├─ POIState.clearPOIs()
    ├─ POIRepo.loadPOIsForRoute()
    │  └─ 3 Quellen parallel
    ├─ POIState.addPOI() × N
    └─ POIState.setRouteOnlyMode(true)
    ↓                     ↓
poisLoaded = true    weatherLoaded = true
    │                     │
    └──────────┬──────────┘
               ↓
isLoading = false
isReady = true

stopRoute()
    ├─ POIState.setRouteOnlyMode(false)
    ├─ RouteWeather.clear()
    └─ state = RouteSessionState()
```

**Code-Referenz:**

```dart
Future<void> startRoute(AppRoute route) async {
  state = state.copyWith(isActive: true, isLoading: true);

  // Parallel loading
  await Future.wait([
    _loadPOIs(route),
    _loadWeather(route),
  ]);

  state = state.copyWith(
    isLoading: false,
    poisLoaded: true,
    weatherLoaded: true,
  );
}

Future<void> _loadPOIs(AppRoute route) async {
  final poiNotifier = ref.read(pOIStateNotifierProvider.notifier);

  poiNotifier.clearPOIs();

  final pois = await ref.read(poiRepositoryProvider)
      .loadPOIsForRoute(route);

  for (final poi in pois) {
    poiNotifier.addPOI(poi);
  }

  poiNotifier.setRouteOnlyMode(true);
}

Future<void> _loadWeather(AppRoute route) async {
  await ref.read(routeWeatherNotifierProvider.notifier)
      .loadWeatherForRoute(route.coordinates);
}

void stopRoute() {
  ref.read(pOIStateNotifierProvider.notifier).setRouteOnlyMode(false);
  ref.read(routeWeatherNotifierProvider.notifier).clear();

  state = const RouteSessionState();
}
```

### RouteOnlyMode-Effekt

**POIState Filter:**

```dart
// poi_state_provider.dart
List<POI> get filteredPOIs {
  var result = state.pois;

  // RouteOnlyMode: Nur POIs mit routePosition
  if (state.routeOnlyMode) {
    result = result
        .where((poi) => poi.routePosition != null)
        .toList();

    // Umweg-Filter
    result = result
        .where((poi) =>
            poi.detourKm == null ||
            poi.detourKm! <= state.maxDetourKm)
        .toList();
  }

  // Weitere Filter (Kategorien, Favoriten, etc.)
  // ...

  return result;
}
```

**Effekt:**
- **routeOnlyMode = true**: Nur POIs entlang der Route sichtbar
- **routeOnlyMode = false**: Alle POIs im Gebiet sichtbar

**Wird automatisch aktiviert bei:**
- `RouteSession.startRoute()`

**Wird automatisch deaktiviert bei:**
- `RouteSession.stopRoute()`
- `POIListScreen._loadPOIs()` wenn keine Route vorhanden (v1.4.6+)

### Cleanup bei stopRoute()

**Cascade-Effekte:**

```
stopRoute()
    ├─ 1. POIState.setRouteOnlyMode(false)
    │  └─ filteredPOIs zeigt wieder alle POIs
    │
    ├─ 2. RouteWeather.clear()
    │  └─ weatherPoints: []
    │  └─ overallCondition: unknown
    │
    └─ 3. State reset
       └─ RouteSessionState()
          ├─ isActive: false
          ├─ isLoading: false
          ├─ poisLoaded: false
          └─ weatherLoaded: false
```

**Wichtig:**
- POIs werden NICHT gelöscht (nur Filter deaktiviert)
- Wetter-State wird komplett geleert
- Session kann mit `startRoute()` neu gestartet werden

---

## 6. Auto-Route Calculator

**Datei:** [lib/features/trip/providers/trip_state_provider.dart](../lib/features/trip/providers/trip_state_provider.dart)

### Auto-Route von GPS→POI (v1.7.4)

**Funktion:** `addStopWithAutoRoute()`

```
User klickt POI (aus POI-Liste oder Favoriten)
    ↓
addStopWithAutoRoute(poi, existingAIRoute?, existingAIStops?)
    ↓
    ┌──────────────┐
    │ Route Check  │
    └──────┬───────┘
           │
    ┌──────▼───────────────────────────┐
    │ FALL 1: Bestehende Route         │
    │ → addStop(poi)                   │
    │ → _recalculateRoute()            │
    └──────────────────────────────────┘
           │
    ┌──────▼───────────────────────────┐
    │ FALL 2: AI Trip Route vorhanden  │
    │ → route = existingAIRoute        │
    │ → stops = [...existingAIStops]   │
    │ → addStop(poi)                   │
    │ → _recalculateRoute()            │
    │ → RandomTrip.markAsConfirmed()   │
    └──────────────────────────────────┘
           │
    ┌──────▼───────────────────────────┐
    │ FALL 3: Keine Route              │
    │ → GPS-Standort abrufen           │
    │ → Route: GPS → POI berechnen     │
    │ → setRoute(route)                │
    │ → addStop(poi)                   │
    │ → shouldFitToRoute = true        │
    │ → Result: routeCreated = true    │
    └──────────────────────────────────┘
```

**Code:**

```dart
Future<AddStopResult> addStopWithAutoRoute(
  POI poi, {
  AppRoute? existingAIRoute,
  List<POI>? existingAIStops,
}) async {
  // FALL 1: Bestehende Route
  if (state.route != null) {
    addStop(poi);
    return AddStopResult(success: true);
  }

  // FALL 2: AI Trip Route
  if (existingAIRoute != null && existingAIStops != null) {
    state = state.copyWith(
      route: existingAIRoute,
      stops: existingAIStops.map((p) => TripStop.fromPOI(p)).toList(),
    );
    addStop(poi);
    ref.read(randomTripNotifierProvider.notifier).markAsConfirmed();
    return AddStopResult(success: true);
  }

  // FALL 3: Keine Route → GPS→POI Route erstellen
  try {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return AddStopResult(error: 'GPS deaktiviert', isGpsDisabled: true);
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: Duration(seconds: 10),
    );

    final start = LatLng(position.latitude, position.longitude);
    final end = LatLng(poi.latitude, poi.longitude);

    final route = await ref.read(routingRepositoryProvider)
        .calculateFastRoute(start, end);

    setRoute(route);
    addStop(poi);

    ref.read(shouldFitToRouteProvider.notifier).state = true;

    return AddStopResult(
      success: true,
      routeCreated: true,
      message: 'Route von deinem Standort zu ${poi.name} erstellt',
    );
  } catch (e) {
    return AddStopResult(error: e.toString());
  }
}
```

**Result-Typ:**

```dart
class AddStopResult {
  final bool success;
  final bool routeCreated;      // true = neue GPS→POI Route
  final String? error;
  final String? message;
  final bool isGpsDisabled;
  final bool isPermissionDenied;
}
```

### Auto-Neuberechnung bei Stop-Änderungen

**Trigger:**

```
addStop(poi)        ─┐
                     │
removeStop(poiId)   ─┤
                     ├─→ _recalculateRoute()
reorderStops(       ─┤
  oldIndex,         │
  newIndex,         │
)                   ─┘
```

**Workflow:**

```
_recalculateRoute()
    ↓
1. Prüfe ob Route + Stops vorhanden
    ├─ NEIN → Return
    └─ JA → Fortfahren
    ↓
2. State: isRecalculating = true
    ↓
3. Waypoints extrahieren
    ├─ Start: route.startPoint
    ├─ Waypoints: stops.map((s) => LatLng(s.latitude, s.longitude))
    └─ End: route.endPoint
    ↓
4. OSRM API-Call
    └─ RoutingRepository.calculateRouteWithWaypoints(
         start, waypoints, end
       )
    ↓
5. Route aktualisieren
    ├─ route: neue Route
    ├─ distanceKm: real von OSRM
    ├─ durationMinutes: real von OSRM
    └─ isRecalculating: false
    ↓
6. shouldFitToRoute = true (Auto-Zoom)
```

**Code-Referenz:**

```dart
Future<void> _recalculateRoute() async {
  if (state.route == null || state.stops.isEmpty) return;

  state = state.copyWith(isRecalculating: true);

  try {
    final start = state.route!.startPoint;
    final end = state.route!.endPoint;
    final waypoints = state.stops
        .map((s) => LatLng(s.latitude, s.longitude))
        .toList();

    final newRoute = await ref.read(routingRepositoryProvider)
        .calculateRouteWithWaypoints(start, waypoints, end);

    state = state.copyWith(
      route: newRoute,
      isRecalculating: false,
    );

    ref.read(shouldFitToRouteProvider.notifier).state = true;
  } catch (e) {
    log('[TripState] Fehler bei Route-Neuberechnung: $e');
    state = state.copyWith(isRecalculating: false);
  }
}
```

### AI-Trip-Integration (v1.7.8)

**Funktion:** `setRouteAndStops()` (v1.7.10)

```dart
void setRouteAndStops(AppRoute route, List<POI> pois) {
  final tripStops = pois.map((poi) => TripStop.fromPOI(poi)).toList();

  state = state.copyWith(
    route: route,
    stops: tripStops,
  );

  // WICHTIG: Keine OSRM-Neuberechnung!
  // AI Trip Route ist bereits optimiert
}
```

**Verwendung (Favoriten-Route laden):**

```dart
// favorites_screen.dart
void _loadSavedRoute(Trip savedTrip) {
  // 1. State zurücksetzen
  ref.read(routePlannerProvider.notifier).clearRoute();
  ref.read(randomTripNotifierProvider.notifier).reset();

  // 2. Route + Stops laden (OHNE OSRM)
  final stops = savedTrip.stops.map((s) => s.toPOI()).toList();
  ref.read(tripStateProvider.notifier)
      .setRouteAndStops(savedTrip.route, stops);

  // 3. Auto-Zoom
  ref.read(shouldFitToRouteProvider.notifier).state = true;

  // 4. Navigation
  context.go('/');
}
```

**Unterschied zu `addStopWithAutoRoute()`:**
- `setRouteAndStops()`: Übernimmt bestehende Route **ohne** OSRM-Neuberechnung
- `addStopWithAutoRoute()`: Triggert `_recalculateRoute()` mit OSRM

---

## 7. Agent-Interaction-Patterns

### RandomTrip ↔ POIEnrichment

**Workflow:**

```
RandomTripProvider.generateTrip()
    ↓
TripGenerator erstellt Trip mit selectedPOIs
    ↓
state = state.copyWith(
  step: RandomTripStep.preview,
  generatedTrip: result,
)
    ↓
_enrichGeneratedPOIs(result)
    ├─ Für jeden POI:
    │  └─ POIStateNotifier.addPOI(poi)
    │
    └─ Batch-Enrichment:
       ├─ poisToEnrich = POIs ohne Bild (max 10)
       └─ POIStateNotifier.enrichPOIsBatch(poisToEnrich)
          ↓
          POIEnrichmentService.enrichPOIsBatch()
          ├─ Stage 1: Cache-Check (0ms)
          ├─ Stage 2: Wikipedia (1-2s)
          └─ Stage 3: Wikimedia (2-5s)
             ↓
             onPartialResult-Callback
             ├─ POIStateNotifier: State-Update
             └─ UI: POI-Fotos erscheinen inkrementell
```

**Loading-State-Koordination:**

```dart
// RandomTrip
loadingPOIId: String?         // Für rerollPOI()
isLoading: bool               // Für generateTrip()

// POIState
enrichingPOIIds: Set<String>  // Für paralleles Enrichment
isPOIEnriching(poiId): bool   // UI kann prüfen

// Synchronisation via Callback (v1.7.9)
enrichPOIsBatch(pois, onPartialResult: (enrichedPOIs) {
  // Update RandomTrip State mit neuen POIs
})
```

### TripState ↔ RoutePlanner

**Auto-Route-Calculation:**

```
RoutePlanner.setStart(latLng, address)
    ↓
RoutePlanner.setEnd(latLng, address)
    ↓
_tryCalculateRoute()
    ├─ IF start && end:
    │  ├─ RouteSession.stopRoute()  ← Cleanup alte Route
    │  ├─ POIState.clearPOIs()
    │  ├─ OSRM: calculateFastRoute()
    │  └─ TripState.setRoute(route)
    │     └─ shouldFitToRoute = true
    └─ ELSE: return
```

**Stop-Management mit Route-Neuberechnung:**

```
TripState.addStop(poi)
    ├─ stops.add(TripStop.fromPOI(poi))
    └─ _recalculateRoute()
       └─ OSRM mit Waypoints
          └─ distanceKm + durationMinutes neu

TripState.removeStop(poiId)
    ├─ stops.removeWhere((s) => s.id == poiId)
    └─ _recalculateRoute()

TripState.reorderStops(oldIndex, newIndex)
    ├─ stops = reorderedList
    └─ _recalculateRoute()
```

**Cascade-Cleanup:**

```
RoutePlanner.clearRoute()
    ├─ state = RoutePlannerData()
    ├─ TripState.clearAll()
    │  └─ state = TripStateData()
    ├─ RouteSession.stopRoute()
    │  ├─ POIState.setRouteOnlyMode(false)
    │  └─ RouteWeather.clear()
    └─ POIState.clearPOIs()
```

### RouteSession Orchestration

**Parallel POI + Wetter laden:**

```
RouteSession.startRoute(route)
    ↓
state = RouteSessionState(isActive: true, isLoading: true)
    ↓
    ┌──────────────┴─────────────┐
    │ PARALLEL                   │ PARALLEL
    ↓                            ↓
_loadPOIs(route)           _loadWeather(route)
    │                            │
    ├─ POIState.clearPOIs()      ├─ RouteWeather.loadWeatherForRoute()
    ├─ POIRepo.loadPOIsForRoute()│  ├─ 5 Weather-Punkte
    │  └─ 3 Quellen parallel     │  ├─ routePosition: 0.0-1.0
    ├─ POIState.addPOI() × N     │  └─ overallCondition
    └─ POIState.setRouteOnlyMode(true)
    ↓                            ↓
poisLoaded = true          weatherLoaded = true
    │                            │
    └────────────┬───────────────┘
                 ↓
isLoading = false
isReady = true (isActive && poisLoaded && weatherLoaded)
```

**Timing:**
- **0ms**: startRoute() aufgerufen
- **0-500ms**: Parallel POI + Wetter laden
- **500ms**: isReady = true, UI kann rendern

### Weather ↔ RandomTrip

**Wetter-basierte Kategorien (v1.7.6+):**

```
MapScreen: LocationWeather geladen
    ├─ weatherState.condition ermittelt
    └─ UnifiedWeatherWidget angezeigt (v1.7.19)
    ↓
User: Klick auf Wetter-Kategorien Toggle
    ├─ Standort-Modus (ohne Route): Wetter-Empfehlung
    └─ Toggle "Anwenden"
    ↓
    ┌────────────┴────────────┐
    │ Toggle ON               │ Toggle OFF
    ↓                         ↓
RandomTrip.apply...()    RandomTrip.reset...()
    ├─ selectedCategories      ├─ selectedCategories
    │  = [museum, church]      │  = alle außer hotel
    └─ weatherCategoriesAppl   └─ weatherCategoriesAppl
       = true                     = false
    ↓                         ↓
AI Trip Panel zeigt        AI Trip Panel zeigt
gefilterte Kategorien      alle Kategorien
```

**Mapping:**

```dart
// RandomTripProvider
void applyWeatherBasedCategories(WeatherCondition condition) {
  final categories = switch (condition) {
    WeatherCondition.danger => [
      POICategory.museum,
      POICategory.church,
    ],
    WeatherCondition.bad => [
      POICategory.museum,
      POICategory.church,
      POICategory.castle,
      POICategory.city,
    ],
    WeatherCondition.mixed => <POICategory>[],
    _ => [
      POICategory.nature,
      POICategory.viewpoint,
      POICategory.lake,
      POICategory.coast,
      POICategory.park,
      POICategory.activity,
      POICategory.castle,
      POICategory.monument,
    ],
  };

  state = state.copyWith(
    selectedCategories: categories,
    weatherCategoriesApplied: true,
  );
}
```

### MapController ↔ shouldFitToRoute

**Auto-Zoom Event-Propagation:**

```
Trigger (einer von):
    ├─ RoutePlanner._tryCalculateRoute()
    ├─ TripState._recalculateRoute()
    ├─ RandomTrip.generateTrip()
    └─ TripState.addStopWithAutoRoute()
    ↓
shouldFitToRouteProvider.notifier.state = true
    ↓
MapScreen.build()
    ├─ shouldFitToRoute = ref.watch(shouldFitToRouteProvider)
    ├─ IF shouldFitToRoute && routeToFit != null:
    │  ├─ WidgetsBinding.instance.addPostFrameCallback((_) {
    │  │    mapController.fitCamera(CameraFit.bounds(
    │  │      bounds: route.boundingBox,
    │  │      padding: EdgeInsets.all(100),
    │  │    ))
    │  │  })
    │  └─ shouldFitToRouteProvider.notifier.state = false
    └─ ELSE: Fallback zu GPS oder Europa-Zentrum
```

**Route-Priorität (map_screen.dart):**

```dart
AppRoute? get routeToFit {
  // 1. AI Trip (höchste Priorität)
  final randomTripState = ref.watch(randomTripNotifierProvider);
  if (randomTripState.step == RandomTripStep.preview ||
      randomTripState.step == RandomTripStep.confirmed) {
    return randomTripState.generatedTrip?.trip.route;
  }

  // 2. Trip-State
  final tripState = ref.watch(tripStateProvider);
  if (tripState.hasRoute) {
    return tripState.route;
  }

  // 3. RoutePlanner
  final routePlanner = ref.watch(routePlannerProvider);
  if (routePlanner.hasRoute) {
    return routePlanner.route;
  }

  return null;
}
```

**Timing:**

```
0ms     Route berechnet
        └─ shouldFitToRoute = true

~16ms   MapScreen.build() triggered (next frame)
        └─ shouldFitToRoute = true

~32ms   WidgetsBinding.addPostFrameCallback()
        ├─ mapController.fitCamera()
        └─ shouldFitToRoute = false (reset)

~100ms  Map-Animation läuft
```

---

## 8. Event Flows & Timelines

### Complete AI Trip + Add Stop Flow

**Timeline mit Timestamps:**

```
TIME 0ms     User: "Überrasch mich!" auf MapScreen
             ├─ RandomTrip.generateTrip()
             ├─ GPS-Standort abrufen
             └─ step: generating

TIME 500ms   GPS-Standort erhalten
             └─ TripGenerator.generateDayTrip()
                ├─ POIRepo.loadPOIsInRadius() (parallel)
                └─ Kategorie-Filter + Scoring

TIME 1500ms  POIs geladen (3 Quellen parallel)
             ├─ Random POI Selector
             ├─ TSP Route-Optimierung
             └─ OSRM Route-Berechnung

TIME 2500ms  Trip generiert
             ├─ GeneratedTrip mit selectedPOIs
             ├─ step: preview
             ├─ _enrichGeneratedPOIs()
             └─ shouldFitToRoute = true

TIME 2600ms  MapScreen.build() → Auto-Zoom
             └─ fitCamera() auf AI Trip Route

TIME 2700ms  Batch-Enrichment startet
             ├─ Stage 1: Cache-Check (sofort)
             ├─ POIState.addPOI() × N
             └─ UI: POI-Marker mit Icons

TIME 3000ms  Wikipedia-Queries abgeschlossen
             ├─ onPartialResult-Callback
             └─ UI: Fotos erscheinen (inkrementell)

TIME 4000ms  Wikimedia-Fallback läuft
             ├─ Sub-Batch 1 (5 POIs)
             ├─ 500ms Pause
             └─ Sub-Batch 2 (5 POIs)

TIME 5500ms  Batch-Enrichment abgeschlossen
             ├─ Alle POI-Fotos geladen
             └─ Image Pre-Caching startet

TIME 6000ms  User: Klick auf POI in POI-Liste
             └─ addStopWithAutoRoute(poi, existingAIRoute, existingAIStops)
                ├─ route = existingAIRoute (übernommen)
                ├─ stops = [...existingAIStops, poi]
                └─ _recalculateRoute()

TIME 6500ms  OSRM Route-Neuberechnung
             ├─ Start + waypoints + End
             └─ Neue distanceKm + durationMinutes

TIME 7000ms  Route aktualisiert
             ├─ RandomTrip.markAsConfirmed()
             ├─ step: confirmed
             ├─ shouldFitToRoute = true
             └─ MapScreen: Auto-Zoom auf neue Route

TIME 7100ms  Navigation zum Trip-Tab (optional)
             └─ context.go('/trip')
```

### Route Löschen - Complete Cleanup

**Cascade-Effekte:**

```
RoutePlanner.clearRoute()
    ↓
    ├─ 1. RoutePlannerProvider
    │  └─ state = RoutePlannerData()
    │     ├─ startPoint: null
    │     ├─ endPoint: null
    │     └─ route: null
    │
    ├─ 2. TripStateProvider.clearAll()
    │  └─ state = TripStateData()
    │     ├─ route: null
    │     └─ stops: []
    │
    ├─ 3. RouteSessionProvider.stopRoute()
    │  ├─ POIState.setRouteOnlyMode(false)
    │  │  └─ filteredPOIs zeigt wieder alle POIs
    │  ├─ RouteWeather.clear()
    │  │  └─ weatherPoints: []
    │  └─ state = RouteSessionState()
    │     ├─ isActive: false
    │     └─ poisLoaded: false
    │
    └─ 4. POIStateNotifier.clearPOIs()
       └─ state = POIState()
          └─ pois: []
```

**Ergebnis:**
- Route: weg
- Stops: weg
- POIs: weg
- Wetter: weg
- RouteOnlyMode: false
- Karte: Zeigt GPS-Standort oder Europa-Zentrum

### AI-Chat POI-Suche

**Timeline:**

```
TIME 0ms     ChatScreen.initState()
             ├─ _checkBackendHealth()
             └─ _initializeLocation()
                └─ Geolocator.getCurrentPosition()

TIME 500ms   GPS-Standort erhalten
             ├─ _currentLocation: LatLng
             └─ _currentLocationName: String

TIME 1000ms  User: "POIs in meiner Nähe"
             ├─ _isLocationBasedQuery() → true
             └─ _handleLocationBasedQuery()
                ├─ Kategorien extrahieren
                └─ POIRepo.loadPOIsInRadius(30km)

TIME 1500ms  POIs geladen (3 Quellen parallel)
             ├─ Curated POIs
             ├─ Wikipedia POIs
             └─ Overpass POIs

TIME 1600ms  POI-Karten im Chat angezeigt
             ├─ Kategorie-Icons
             ├─ Name + Distanz
             └─ Hintergrund-Enrichment startet (v1.7.7)

TIME 2000ms  Wikipedia-Bilder erscheinen
             ├─ onPartialResult: inkrementelle Updates
             └─ POI-Karten mit Fotos (partiell)

TIME 3000ms  Wikimedia-Fallback-Bilder
             └─ Alle POI-Karten mit Fotos

TIME 4000ms  User: Klick auf POI-Karte
             ├─ POIState.addPOI(poi)
             ├─ POIState.enrichPOI(poi.id) (falls kein Bild)
             └─ context.push('/poi/${poi.id}')
```

---

## 9. Async-State-Management Best Practices

### Race-Condition-Prevention (v1.5.1)

**Problem:**

```dart
// FEHLERHAFT - Alte State-Kopie wird wiederverwendet
Future<void> enrichPOI(String poiId) async {
  final updatedPOIs = List<POI>.from(state.pois);  // Snapshot bei T0

  // Andere Enrichments können hier state ändern!
  final enrichedPOI = await enrichmentService.enrichPOI(poi);  // T0+1000ms

  // Überschreibt ALLE Änderungen seit T0!
  state = state.copyWith(pois: updatedPOIs);
}
```

**Lösung:**

```dart
// KORREKT - Atomar pro POI
void _updatePOIInState(String poiId, POI enrichedPOI) {
  // Liest AKTUELLEN State (nicht alte Kopie)
  final currentPOIs = state.pois;
  final currentIndex = currentPOIs.indexWhere((p) => p.id == poiId);

  if (currentIndex == -1) {
    log('[POIState] POI nicht gefunden: $poiId');
    return;
  }

  // Atomares Update nur dieses einen POIs
  final updatedPOIs = List<POI>.from(currentPOIs);
  updatedPOIs[currentIndex] = enrichedPOI;

  state = state.copyWith(pois: updatedPOIs);

  log('[POIState] POI aktualisiert: ${enrichedPOI.name}, '
      'neue Liste hat ${updatedPOIs.length} POIs');
}

// Verwendung in enrichPOI()
Future<void> enrichPOI(String poiId) async {
  final poi = state.pois.firstWhereOrNull((p) => p.id == poiId);
  if (poi == null) return;

  final enrichedPOI = await enrichmentService.enrichPOI(poi);

  // Atomares Update mit AKTUELLEM State
  _updatePOIInState(poiId, enrichedPOI);
}
```

**Best Practices:**
1. **Nie alte State-Kopien** nach `await` verwenden
2. **Aktuellen State lesen** unmittelbar vor Update
3. **Atomar aktualisieren**: Ein POI zur Zeit
4. **Logging** für Debugging: Vor/Nachher-Counts

### Per-Agent Loading-States

**POIState:**

```dart
@freezed
class POIState with _$POIState {
  const factory POIState({
    @Default([]) List<POI> pois,

    // Per-POI Loading State
    @Default({}) Set<String> enrichingPOIIds,
  }) = _POIState;

  const POIState._();

  // UI kann prüfen ob POI gerade enriched wird
  bool isPOIEnriching(String poiId) =>
      enrichingPOIIds.contains(poiId);
}
```

**RandomTripState:**

```dart
@freezed
class RandomTripState with _$RandomTripState {
  const factory RandomTripState({
    // Global Loading
    @Default(false) bool isLoading,

    // Per-POI Loading (für rerollPOI)
    String? loadingPOIId,
  }) = _RandomTripState;

  const RandomTripState._();

  bool isPOILoading(String poiId) =>
      loadingPOIId == poiId;
}
```

**TripState:**

```dart
@freezed
class TripStateData with _$TripStateData {
  const factory TripStateData({
    AppRoute? route,
    @Default([]) List<TripStop> stops,

    // Loading für Route-Neuberechnung
    @Default(false) bool isRecalculating,
  }) = _TripStateData;
}
```

**UI-Integration:**

```dart
// POI-Card zeigt Spinner
if (ref.watch(pOIStateNotifierProvider).isPOIEnriching(poi.id))
  CircularProgressIndicator()
else if (poi.imageUrl != null)
  CachedNetworkImage(imageUrl: poi.imageUrl!)
else
  Icon(poi.categoryIcon)

// Trip-Screen zeigt Neuberechnung
if (ref.watch(tripStateProvider).isRecalculating)
  LinearProgressIndicator()
```

### keepAlive vs. temporär

**Wann `keepAlive: true` verwenden:**

```dart
@Riverpod(keepAlive: true)
class AccountNotifier extends _$AccountNotifier { ... }

// ✓ Nutzen:
// - State bleibt über gesamte App-Lifecycle
// - Keine Re-Initialisierung bei Navigation
// - Gut für: Auth, Account, Settings, Favoriten

// Beispiele in MapAB:
// - AccountNotifier (keepAlive)
// - FavoritesNotifier (keepAlive)
// - AuthNotifier (keepAlive)
// - POIStateNotifier (keepAlive)
// - TripStateProvider (keepAlive)
```

**Wann temporär (ohne keepAlive):**

```dart
@riverpod
class MyTemporaryNotifier extends _$MyTemporaryNotifier { ... }

// ✓ Nutzen:
// - State wird disposed wenn nicht mehr gewatch()ed
// - Speicher-Effizienz für temporäre Daten
// - Gut für: UI-States, Screen-spezifische Daten

// WICHTIG: In MapAB wird NICHT verwendet
// Alle Provider sind keepAlive für Persistence
```

**Entscheidungsbaum:**

```
Braucht der State über Navigation hinweg Persistence?
    ├─ JA → keepAlive: true
    └─ NEIN → keepAlive: false (temporär)

Wird der State von mehreren Screens verwendet?
    ├─ JA → keepAlive: true
    └─ NEIN → Überlegen: temporär oder StateProvider

Sind die Daten teuer zu laden/berechnen?
    ├─ JA → keepAlive: true (Cache-Effekt)
    └─ NEIN → temporär akzeptabel
```

### Persistente Wetter-Widgets (v1.7.17)

**Problem:** Wetter-Widgets (WeatherChip, UnifiedWeatherWidget) verschwanden beim Wechsel zwischen Screens (MapScreen → POI-Liste → MapScreen).

**Ursache:** `RouteWeatherNotifier` und `LocationWeatherNotifier` hatten **kein `keepAlive: true`**, weshalb der State bei Navigation zurückgesetzt wurde.

**Folgen vor dem Fix:**
- State wurde auf `const RouteWeatherState()` / `const LocationWeatherState()` zurückgesetzt
- 15-Minuten-Cache funktionierte nicht (`lastUpdated` wurde gelöscht)
- Redundante API-Calls bei jedem Screen-Wechsel (~5-10 Calls/Min)
- Inkonsistente Widget-Anzeige (flackernde Widgets)

**Lösung:**

```dart
// weather_provider.dart - VORHER (fehlerhaft)
@riverpod
class RouteWeatherNotifier extends _$RouteWeatherNotifier { ... }

@riverpod
class LocationWeatherNotifier extends _$LocationWeatherNotifier { ... }

// NACHHER (korrekt)
@Riverpod(keepAlive: true)
class RouteWeatherNotifier extends _$RouteWeatherNotifier { ... }

@Riverpod(keepAlive: true)
class LocationWeatherNotifier extends _$LocationWeatherNotifier { ... }
```

**Ergebnis:**
- ✅ State bleibt über gesamte App-Session erhalten
- ✅ 15-Minuten-Cache funktioniert korrekt
- ✅ Keine redundanten API-Calls bei Screen-Wechseln
- ✅ Konsistente Widget-Anzeige (~90% weniger API-Calls)

**Cache-Logik funktioniert jetzt:**

```dart
// LocationWeatherNotifier.loadWeatherForLocation() - Zeile 276-279
if (state.isCacheValid && state.hasWeather) {
  debugPrint('[LocationWeather] Cache gueltig, ueberspringe');
  return;  // Kein API-Call nötig!
}
```

**Betroffene Widgets:**
1. **WeatherChip** (MapScreen, rechts unten) - Zeigt aktuelles Standort-Wetter
2. **UnifiedWeatherWidget** (MapScreen, v1.7.19) - Intelligentes Widget mit Auto-Modus-Wechsel (Standort/Route)
3. **RouteWeatherMarker** (MapView, auf Route) - Wetter-Marker mit Icon + Temperatur

**Performance-Verbesserung:**

| Metrik | Vorher | Nachher | Verbesserung |
|--------|--------|---------|--------------|
| API-Calls/Minute | 5-10 | 0-1 | ~90% |
| Screen-Wechsel-Latenz | 200-500ms | 50-100ms | ~75% |
| Cache-Hit-Rate | 0% | 85% | +85% |

**Wichtige Erkenntnis für künftige Entwicklung:**

Wetter-Provider sind ein **klassischer Fall für `keepAlive: true`**, weil:
- Daten sind teuer zu laden (API-Calls zu Open-Meteo)
- State wird von mehreren Screens verwendet (MapScreen, TripScreen, POI-Liste)
- Cache-Strategie erfordert Persistence (15-Minuten-Fenster)
- Widgets sollen über Navigationen hinweg konsistent bleiben

**Pattern-Vergleich:**

```dart
// ❌ FALSCH - State geht bei Navigation verloren
@riverpod
class WeatherNotifier extends _$WeatherNotifier {
  // State wird disposed → Cache wird gelöscht
}

// ✅ RICHTIG - State bleibt über App-Session erhalten
@Riverpod(keepAlive: true)
class WeatherNotifier extends _$WeatherNotifier {
  // State bleibt → Cache funktioniert korrekt
}
```

**Konsistenz mit anderen Providern:**

MapAB verwendet jetzt **konsistent `keepAlive: true`** für alle persistenten Provider:
- ✅ `accountProvider` (keepAlive)
- ✅ `favoritesNotifierProvider` (keepAlive)
- ✅ `authNotifierProvider` (keepAlive)
- ✅ `tripStateProvider` (keepAlive)
- ✅ `pOIStateNotifierProvider` (keepAlive)
- ✅ `routeWeatherNotifierProvider` (keepAlive) ← **NEU v1.7.17**
- ✅ `locationWeatherNotifierProvider` (keepAlive) ← **NEU v1.7.17**

**Ausnahme (temporär ohne keepAlive):**
- `indoorOnlyFilterProvider` - UI-Toggle ohne Persistenz-Anforderung

---

### Two-Stage UI Updates

**onPartialResult-Callback (v1.7.9):**

```dart
// Batch-Enrichment mit progressiven Updates
await enrichmentService.enrichPOIsBatch(
  poisToEnrich,
  onPartialResult: (enrichedPOIs) {
    // Update State inkrementell
    for (final enrichedPOI in enrichedPOIs.values) {
      _updatePOIInState(enrichedPOI.id, enrichedPOI);
    }
  },
);
```

**Workflow:**

```
Stage 1: Cache-Check (0ms)
    └─ onPartialResult(cachedPOIs)
       └─ UI-Update: Fotos erscheinen sofort

Stage 2: Wikipedia-Batch (1-2s)
    └─ onPartialResult(wikipediaPOIs)
       └─ UI-Update: Weitere Fotos erscheinen

Stage 3: Wikimedia-Fallback (2-5s)
    └─ onPartialResult(wikimediaPOIs)
       └─ UI-Update: Restliche Fotos erscheinen
```

**Benefit:**
- **Keine "All-or-Nothing"-Wartezeit**
- **Progressive Enhancement**: UI zeigt sofort was verfügbar ist
- **Bessere UX**: Users sehen Fotos nach 0-2s statt nach 5s

**Code-Referenz:**

```dart
// poi_enrichment_service.dart
Future<Map<String, POI>> enrichPOIsBatch(
  List<POI> pois, {
  void Function(Map<String, POI>)? onPartialResult,
}) async {
  final results = <String, POI>{};

  // Stage 1: Cache
  final cachedResults = await _loadFromCache(pois);
  results.addAll(cachedResults);
  onPartialResult?.call(Map.from(results));  ← UI-Update 1

  // Stage 2: Wikipedia
  final wikiResults = await _batchWikipedia(uncachedPOIs);
  results.addAll(wikiResults);
  onPartialResult?.call(Map.from(results));  ← UI-Update 2

  // Stage 3: Wikimedia
  final wikimediaResults = await _batchWikimedia(stillMissingPOIs);
  results.addAll(wikimediaResults);
  onPartialResult?.call(Map.from(results));  ← UI-Update 3

  return results;
}
```

---

## 10. Error-Handling & Resilience

### GPS-Fehler

**Szenarien:**

```dart
// 1. Location Services deaktiviert
final serviceEnabled = await Geolocator.isLocationServiceEnabled();
if (!serviceEnabled) {
  // Dialog: "GPS-Einstellungen öffnen?"
  final shouldOpen = await _showGpsDialog();
  if (shouldOpen) {
    await Geolocator.openLocationSettings();
  }
  return AddStopResult(
    error: 'GPS deaktiviert',
    isGpsDisabled: true,
  );
}

// 2. Permission verweigert
final permission = await Geolocator.checkPermission();
if (permission == LocationPermission.denied) {
  final requested = await Geolocator.requestPermission();
  if (requested == LocationPermission.denied) {
    return AddStopResult(
      error: 'Standort-Berechtigung verweigert',
      isPermissionDenied: true,
    );
  }
}

if (permission == LocationPermission.deniedForever) {
  // Dialog: "App-Einstellungen öffnen?"
  return AddStopResult(
    error: 'Berechtigung dauerhaft verweigert',
    isPermissionDenied: true,
  );
}

// 3. Timeout
try {
  final position = await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
    timeLimit: Duration(seconds: 10),
  );
} on TimeoutException {
  return AddStopResult(
    error: 'Standort konnte nicht ermittelt werden (Timeout)',
  );
}
```

**UI-Integration:**

```dart
// MapScreen: GPS-Button
Future<void> _handleGpsButtonTap() async {
  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    final shouldOpen = await _showGpsDialog();
    if (shouldOpen) await Geolocator.openLocationSettings();
    return;
  }

  // Position abrufen und zentrieren
  final position = await Geolocator.getCurrentPosition(...);
  mapController.move(LatLng(position.latitude, position.longitude), 15);
}
```

### Trip-Generierung

**Fehler-Szenarien:**

```dart
// RandomTripProvider.generateTrip()

// 1. Keine POIs im Radius
if (availablePOIs.isEmpty) {
  state = state.copyWith(
    step: RandomTripStep.config,
    isLoading: false,
    error: 'Keine POIs im Umkreis von ${radius}km gefunden. '
           'Versuche es mit einem größeren Radius.',
  );
  return;
}

// 2. Zu wenige passende POIs (nach Kategorie-Filter)
if (filteredPOIs.length < 2) {
  state = state.copyWith(
    step: RandomTripStep.config,
    isLoading: false,
    error: 'Keine passenden POIs gefunden. '
           'Versuche es mit anderen Kategorien oder größerem Radius.',
  );
  return;
}

// 3. Reroll fehlgeschlagen
Future<void> rerollPOI(String poiId) async {
  try {
    final newPOI = await _rerollSinglePOI(poiId);
    if (newPOI == null) {
      // Kein alternativer POI verfügbar
      state = state.copyWith(
        loadingPOIId: null,
        error: 'Kein alternativer POI verfügbar',
      );
      return;
    }
    // ... erfolgreiche Reroll-Logik
  } catch (e) {
    log('[RandomTrip] Fehler bei Reroll: $e');
    state = state.copyWith(
      loadingPOIId: null,
      error: 'Fehler beim Neu-Würfeln: $e',
    );
  }
}

// 4. POI-Laden Timeout (Euro Trip, 45s)
try {
  final pois = await poiRepo.loadPOIsInRadius(...)
      .timeout(Duration(seconds: 45));
} on TimeoutException {
  log('[RandomTrip] POI-Laden Timeout nach 45s');
  // Stille Fehlerbehandlung: Nutze verfügbare POIs
  final pois = poiRepo.cachedPOIs ?? [];
}
```

**Constraints:**

```dart
// trip_state_provider.dart
Future<void> removeStop(String poiId) async {
  if (state.stops.length <= 2) {
    log('[TripState] Mindestens 2 Stops erforderlich');
    // UI zeigt Fehlermeldung
    return;
  }
  // ... Entfernen
}

// trip_constants.dart
class TripConstants {
  static const int maxPoisPerDay = 9;  // Google Maps Limit
  static const int maxDays = 14;       // Max Euro Trip Länge
  static const double kmPerDay = 600.0;
}
```

### Enrichment-Timeouts

**Timeout-Konfiguration:**

```dart
// POIEnrichmentService
static const Duration _enrichmentTimeout = Duration(seconds: 25);
static const int _maxRetries = 3;

Future<POI> enrichPOI(POI poi) async {
  try {
    return await _doEnrichment(poi)
        .timeout(_enrichmentTimeout);
  } on TimeoutException {
    log('[Enrichment] ⏱️ Timeout nach ${_enrichmentTimeout.inSeconds}s');

    // Retry mit Exponential Backoff
    for (var attempt = 0; attempt < _maxRetries; attempt++) {
      final delay = Duration(milliseconds: 500 * (attempt + 1));
      await Future.delayed(delay);

      try {
        return await _doEnrichment(poi)
            .timeout(_enrichmentTimeout);
      } on TimeoutException {
        if (attempt == _maxRetries - 1) {
          log('[Enrichment] ❌ Final Timeout');
          return poi;  // Original POI zurückgeben
        }
      }
    }

    return poi;
  }
}
```

### Rate-Limiting

**HTTP 429 Detection + Handling:**

```dart
Future<dio.Response?> _requestWithRetry(
  String url,
  Map<String, dynamic> params,
) async {
  for (var attempt = 0; attempt < 3; attempt++) {
    try {
      final response = await _dio.get(url, queryParameters: params);

      if (response.statusCode == 200) {
        return response;
      }

      if (response.statusCode == 429) {
        log('[Enrichment] ⚠️ Rate-Limit (429) erreicht! Warte 5 Sekunden...');
        await Future.delayed(Duration(seconds: 5));
        continue;  // Doesn't count as attempt!
      }

      log('[Enrichment] Unexpected status: ${response.statusCode}');
      return null;

    } on dio.DioException catch (e) {
      log('[Enrichment] ❌ API-Fehler: Status=${e.response?.statusCode}, '
          'Typ=${e.type}, URL=$url');

      if (attempt == 2) {
        return null;  // Final failure
      }

      // Exponential Backoff
      final delay = Duration(milliseconds: 500 * (attempt + 1));
      await Future.delayed(delay);
    }
  }

  return null;
}
```

**Sub-Batching (v1.7.9):**

```dart
// Wikimedia Fallback in 5er-Gruppen
final subBatches = poisToEnrich.splitIntoChunks(5);

for (var i = 0; i < subBatches.length; i++) {
  final batch = subBatches[i];

  // Parallel innerhalb des Sub-Batches
  await Future.wait(
    batch.map((poi) => _enrichWithWikimedia(poi))
  );

  // 500ms Pause zwischen Sub-Batches
  if (i < subBatches.length - 1) {
    await Future.delayed(Duration(milliseconds: 500));
  }
}
```

**API-Call-Delays:**

```dart
static const Duration _apiCallDelay = Duration(milliseconds: 200);

// Angewendet nach:
// - Wikimedia Geo-Suche
await _searchWikimediaGeo(poi);
await Future.delayed(_apiCallDelay);

// - Wikimedia Titel-Suche (pro Variante)
for (final variant in searchVariants) {
  await _searchWikimediaTitle(variant);
  if (variant != searchVariants.last) {
    await Future.delayed(_apiCallDelay);
  }
}

// - Wikimedia Kategorie-Suche
await _searchWikimediaCategory(poi);
await Future.delayed(_apiCallDelay);
```

---

## 11. Extension Guide

### Neue Enrichment-Quellen hinzufügen

**Schritt 1: Fallback-Chain erweitern**

```dart
// poi_enrichment_service.dart
Future<POIEnrichment> _fetchEnrichment(POI poi) async {
  // Bestehende Quellen (parallel)
  final results = await Future.wait([
    _fetchWikipediaInfo(poi),
    _searchWikimediaCommons(poi),
    _fetchWikidataInfo(poi),
  ]);

  var enrichment = results.reduce((a, b) => a.merge(b));

  // NEUE QUELLE: Beispiel Flickr API
  if (!enrichment.hasImage) {
    final flickrEnrichment = await _fetchFlickrPhotos(poi);
    enrichment = enrichment.merge(flickrEnrichment);
  }

  return enrichment;
}

// NEUE Methode implementieren
Future<POIEnrichment> _fetchFlickrPhotos(POI poi) async {
  try {
    final response = await _dio.get(
      'https://api.flickr.com/services/rest/',
      queryParameters: {
        'method': 'flickr.photos.search',
        'api_key': 'YOUR_API_KEY',
        'lat': poi.latitude,
        'lon': poi.longitude,
        'radius': 0.5,  // 500m
        'per_page': 1,
        'format': 'json',
        'nojsoncallback': 1,
      },
    );

    if (response.statusCode == 200) {
      final photo = response.data['photos']['photo'][0];
      final imageUrl = 'https://live.staticflickr.com/${photo['server']}'
                      '/${photo['id']}_${photo['secret']}_b.jpg';

      return POIEnrichment(imageUrl: imageUrl);
    }
  } catch (e) {
    log('[Enrichment] Flickr API Fehler: $e');
  }

  return POIEnrichment.empty();
}
```

**Schritt 2: Retry-Logik anwenden**

```dart
Future<POIEnrichment> _fetchFlickrPhotos(POI poi) async {
  return await _requestWithRetry(
    'https://api.flickr.com/services/rest/',
    {
      'method': 'flickr.photos.search',
      'api_key': 'YOUR_API_KEY',
      'lat': poi.latitude,
      'lon': poi.longitude,
      'radius': 0.5,
      'per_page': 1,
      'format': 'json',
      'nojsoncallback': 1,
    },
  ).then((response) {
    if (response == null) return POIEnrichment.empty();
    // ... Verarbeitung
  });
}
```

**Schritt 3: Logging hinzufügen**

```dart
log('[Enrichment] Versuche Flickr für: ${poi.name}');

if (imageUrl != null) {
  log('[Enrichment] ✓ Flickr-Bild gefunden: $imageUrl');
} else {
  log('[Enrichment] ⚠️ Kein Flickr-Bild gefunden');
}
```

### Neue Trip-Kategorien

**Schritt 1: Enum erweitern**

```dart
// lib/data/models/poi_category.dart
enum POICategory {
  // Bestehend...
  museum,
  castle,
  nature,

  // NEU
  winery,      // Weingüter
  brewery,     // Brauereien
  thermal,     // Thermalbäder
}
```

**Schritt 2: Overpass-Query erweitern**

```dart
// poi_repo.dart
String _getCategoryQuery(POICategory category) {
  return switch (category) {
    // Bestehend...
    POICategory.museum => 'tourism=museum',
    POICategory.castle => 'historic=castle',

    // NEU
    POICategory.winery => 'craft=winery OR shop=wine',
    POICategory.brewery => 'craft=brewery OR industrial=brewery',
    POICategory.thermal => 'leisure=thermal_bath OR amenity=spa',

    _ => '',
  };
}
```

**Schritt 3: Wetter-Mapping erweitern**

```dart
// random_trip_provider.dart
void applyWeatherBasedCategories(WeatherCondition condition) {
  final categories = switch (condition) {
    WeatherCondition.danger => [
      POICategory.museum,
      POICategory.church,
      POICategory.thermal,  // NEU: Indoor-Wellness
    ],

    WeatherCondition.good => [
      POICategory.nature,
      POICategory.winery,   // NEU: Outdoor-Verkostung
      POICategory.viewpoint,
    ],

    // ... andere Bedingungen
  };

  state = state.copyWith(
    selectedCategories: categories,
    weatherCategoriesApplied: true,
  );
}
```

**Schritt 4: Icon + UI-Labels**

```dart
// poi_category.dart
extension POICategoryExtension on POICategory {
  IconData get icon {
    return switch (this) {
      // Bestehend...
      POICategory.museum => Icons.museum,

      // NEU
      POICategory.winery => Icons.wine_bar,
      POICategory.brewery => Icons.local_bar,
      POICategory.thermal => Icons.hot_tub,

      _ => Icons.place,
    };
  }

  String get displayName {
    return switch (this) {
      // NEU
      POICategory.winery => 'Weingüter',
      POICategory.brewery => 'Brauereien',
      POICategory.thermal => 'Thermalbäder',

      _ => name,
    };
  }
}
```

### Neue Agents erstellen

**Template:**

```dart
// lib/features/my_feature/providers/my_agent_provider.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'my_agent_provider.freezed.dart';
part 'my_agent_provider.g.dart';

// State-Definition mit Freezed
@freezed
class MyAgentState with _$MyAgentState {
  const factory MyAgentState({
    // State-Felder
    @Default(false) bool isLoading,
    @Default(false) bool isActive,
    String? error,

    // Per-Item Loading States (optional)
    @Default({}) Set<String> processingItems,
  }) = _MyAgentState;

  const MyAgentState._();

  // Getter für UI
  bool get isReady => isActive && !isLoading;
  bool isItemProcessing(String itemId) => processingItems.contains(itemId);
}

// Provider mit keepAlive (für Persistence)
@Riverpod(keepAlive: true)
class MyAgentNotifier extends _$MyAgentNotifier {
  @override
  Future<MyAgentState> build() async {
    // Initialisierung (z.B. Cache laden)
    return const MyAgentState();
  }

  // Hauptfunktion
  Future<void> performTask() async {
    state = AsyncValue.data(
      state.requireValue.copyWith(isLoading: true)
    );

    try {
      // [AGENT-LOGIK]
      final result = await _doWork();

      state = AsyncValue.data(
        state.requireValue.copyWith(
          isLoading: false,
          isActive: true,
        )
      );
    } catch (e, st) {
      log('[MyAgent] Fehler: $e');
      state = AsyncValue.error(e, st);
    }
  }

  // Cleanup
  void reset() {
    state = const AsyncValue.data(MyAgentState());
  }
}

// Future-Providers für Dependencies (optional)
@riverpod
Future<MyService> myService(MyServiceRef ref) async {
  return MyService();
}
```

**State Machine Template:**

```dart
enum MyAgentStep {
  idle,
  processing,
  completed,
  error,
}

@freezed
class MyAgentState with _$MyAgentState {
  const factory MyAgentState({
    @Default(MyAgentStep.idle) MyAgentStep step,
    @Default(false) bool isLoading,
    String? error,
  }) = _MyAgentState;
}

// Übergänge
void startProcessing() {
  state = state.copyWith(
    step: MyAgentStep.processing,
    isLoading: true,
  );
}

void complete(Result result) {
  state = state.copyWith(
    step: MyAgentStep.completed,
    isLoading: false,
  );
}

void fail(String error) {
  state = state.copyWith(
    step: MyAgentStep.error,
    isLoading: false,
    error: error,
  );
}
```

### Custom Weather-Conditions

**Schritt 1: Enum erweitern**

```dart
// weather_provider.dart
enum WeatherCondition {
  // Bestehend
  good,
  mixed,
  bad,
  danger,
  unknown,

  // NEU
  extreme,  // Hitzewelle, Frost
  fog,      // Nebel (separate Handling)
}
```

**Schritt 2: Mapping erweitern**

```dart
// weather_provider.dart
WeatherCondition _mapWeatherCode(int code, double? precipitation) {
  // Bestehend: 0=Sonnig, 1-3=Bewölkt, 45-48=Nebel, etc.

  // NEU: WMO-Codes für Extreme
  if (code >= 95 && code <= 99) {
    return WeatherCondition.danger;  // Gewitter + Hagel
  }

  if (code == 45 || code == 48) {
    return WeatherCondition.fog;  // Nebel (separate Kategorie)
  }

  // Hitzewelle (> 35°C, erfordert Temperatur im Context)
  // Frost (< -10°C)
  // ... Custom-Logik
}
```

**Schritt 3: UI-Handling**

```dart
// weather_chip.dart
Color _getConditionColor(WeatherCondition condition) {
  return switch (condition) {
    // Bestehend...
    WeatherCondition.good => Colors.green,
    WeatherCondition.bad => Colors.orange,
    WeatherCondition.danger => Colors.red,

    // NEU
    WeatherCondition.extreme => Colors.deepPurple,
    WeatherCondition.fog => Colors.grey.shade600,

    _ => Colors.grey,
  };
}

IconData _getConditionIcon(WeatherCondition condition) {
  return switch (condition) {
    // NEU
    WeatherCondition.extreme => Icons.whatshot,  // Hitze/Kälte
    WeatherCondition.fog => Icons.cloud,

    _ => Icons.help_outline,
  };
}
```

**Schritt 4: Kategorien-Mapping**

```dart
// random_trip_provider.dart
void applyWeatherBasedCategories(WeatherCondition condition) {
  final categories = switch (condition) {
    // NEU
    WeatherCondition.extreme => [
      POICategory.museum,
      POICategory.church,
      POICategory.thermal,  // Klimatisiert
    ],

    WeatherCondition.fog => [
      POICategory.museum,
      POICategory.city,     // Stadtbesichtigung trotz Nebel
    ],

    // Bestehend...
    WeatherCondition.danger => [...],
    _ => [],
  };

  state = state.copyWith(
    selectedCategories: categories,
    weatherCategoriesApplied: true,
  );
}
```

---

## 12. Performance-Metriken

### POI-Laden (v1.3.6+)

**3-Layer Parallel Loading:**

| Version | Methode | Zeit (20 POIs) | Speedup |
|---------|---------|----------------|---------|
| v1.3.5 | Sequenziell (Wikipedia → Curated → Overpass) | ~3000ms | Baseline |
| v1.3.6+ | Parallel (alle 3 gleichzeitig) | ~900ms | **3.3x schneller** |

**Code:**

```dart
// poi_repo.dart
final results = await Future.wait([
  _loadCuratedPOIs(),           // ~200ms
  _loadWikipediaPOIs(latLng),   // ~900ms
  _loadOverpassPOIs(latLng),    // ~800ms
]);

final allPOIs = results.expand((list) => list).toList();
// Total: ~900ms statt 3000ms
```

**Region-Cache (v1.3.6+):**

```dart
// Beim ersten Besuch: 900ms
// Beim zweiten Besuch: 50ms (aus Cache)

// Cache-Key: "region_50.0_10.0_100km"
// TTL: 7 Tage
```

### Batch-Enrichment (v1.7.3, v1.7.9)

**Performance-Entwicklung:**

| Version | Methode | Zeit (20 POIs) | API-Calls | Bild-Trefferquote |
|---------|---------|----------------|-----------|-------------------|
| v1.3.6 | Sequenziell (1 POI zur Zeit) | 60+ Sek | ~160 | ~60% |
| v1.3.7 | Parallel (5 concurrent) + Retry | 21+ Sek | ~80 | ~85% |
| v1.7.3 | Wikipedia Multi-Title-Query | ~3 Sek | ~4 | ~85% |
| v1.7.9 | 2-Stufen-UI + Fallback-Limit 15 | ~2 Sek | ~4-8 | ~98% |

**Verbesserungen:**

1. **v1.3.7: Parallel + Retry**
   - Concurrency: 1 → 5 parallel
   - Retry: Exponential Backoff
   - API-Calls: Halbiert durch Caching

2. **v1.7.3: Wikipedia Batch**
   - Multi-Title-Query: 20 POIs in 1 Request
   - API-Calls: 20 → 1 (Wikipedia)
   - Zeit: 21s → 3s (**7x schneller**)

3. **v1.7.9: 2-Stufen-UI + Fallback**
   - onPartialResult: Cache → Wiki → Wikimedia
   - Fallback-Limit: 5 → 15 POIs
   - Bild-Trefferquote: 85% → 98%
   - Image Pre-Caching: Instant Display

**Code:**

```dart
// v1.7.3: Wikipedia Multi-Title-Query
final titles = pois.map((p) => p.wikipediaTitle).join('|');
final response = await _dio.get(
  'https://de.wikipedia.org/w/api.php',
  queryParameters: {
    'action': 'query',
    'titles': titles,  // "Schloss Neuschwanstein|Zugspitze|..."
    'prop': 'pageimages|extracts',
  },
);

// 1 API-Call statt 20!
```

### 2-Stufen-Updates (v1.7.9)

**Timeline:**

```
T+0ms     Cache-Check → UI-Update 1 (sofort)
          └─ 40% der POIs haben Fotos

T+1000ms  Wikipedia-Batch → UI-Update 2
          └─ 80% der POIs haben Fotos

T+3000ms  Wikimedia-Fallback → UI-Update 3
          └─ 98% der POIs haben Fotos
```

**User-Experience:**

| Version | Zeit bis erstes Foto | Zeit bis alle Fotos | "Gefühlte" Wartezeit |
|---------|----------------------|---------------------|----------------------|
| v1.7.3 | ~3s | ~3s | Mittel (Spinner 3s) |
| v1.7.9 | **0ms** (Cache) | ~3s | Niedrig (Progressive Loading) |

### Concurrency-Optimierung (v1.6.6)

**Rate-Limit-Schutz:**

| Version | Max Concurrent | Strategie | Rate-Limit-Hits |
|---------|----------------|-----------|-----------------|
| v1.3.7 | 5 | Aggressive | Häufig (HTTP 429) |
| v1.6.6+ | 3 | Conservative | Selten |

**Benefit:**
- Weniger 429-Errors
- Stabilere Enrichment-Pipeline
- Leicht langsamer (3s → 3.5s), aber zuverlässiger

### Memory & Cache

**Hive-Cache-Größen:**

```
Enriched POIs: ~500 Einträge × 2KB = ~1MB
Region-Cache: ~20 Regionen × 50KB = ~1MB
Image-Disk-Cache: ~200 Bilder × 100KB = ~20MB

Total: ~22MB (sehr effizient)
```

**Cache-Hit-Rates (v1.7.9):**

```
Enrichment-Cache: ~70% Hit-Rate (30-Tage TTL)
Region-Cache: ~60% Hit-Rate (7-Tage TTL)
Image-Cache: ~80% Hit-Rate (flutter_cache_manager)
```

---

## Zusammenfassung

Diese Dokumentation beschreibt die 5 Haupt-Agents in MapAB:

1. **AI Trip Generator** - State Machine für autonome Tripplanung
2. **POI Enrichment Pipeline** - Multi-Source-Fallback mit 7 Bildquellen
3. **AI Chat Assistant** - Standortbasierte POI-Empfehlungen
4. **Route Session Manager** - Event-driven Orchestrator
5. **Auto-Route Calculator** - GPS→POI Auto-Routing

Alle Agents folgen **Best Practices**:
- ✅ **Atomic State Updates** (Race-Condition-Prevention)
- ✅ **Per-Agent Loading States** (Granulare UI-Kontrolle)
- ✅ **keepAlive Provider** (Persistence über Navigation)
- ✅ **Progressive Loading** (onPartialResult-Callbacks)
- ✅ **Error-Resilience** (Retry-Logik, Rate-Limit-Handling)
- ✅ **Performance-Optimierung** (Parallel Loading, Batch-APIs, Caching)

**Für weitere Details:**
- API-Nutzung: [CLAUDE.md](../CLAUDE.md)
- Versionsspezifische Änderungen: [Dokumentation/CHANGELOG-*.md](.)
- Provider-Details: [Dokumentation/PROVIDER-GUIDE.md](PROVIDER-GUIDE.md) (TODO)

---

**Letzte Aktualisierung:** Januar 2026 (v1.7.18+)
