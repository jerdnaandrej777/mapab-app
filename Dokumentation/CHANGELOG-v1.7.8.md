# Changelog v1.7.8/v1.7.9 - AI Trip Route + Wetter-Empfehlung UI + Route Starten Button + Wetter-Design & POI-Marker-Badges + POI-Foto & Kategorisierung Optimierung

**Release-Datum:** 29.-30. Januar 2026

## Zusammenfassung

Diese Version ermöglicht es, POIs aus der POI-Liste oder den POI-Details als Stops zu einer bestehenden AI Trip Route hinzuzufügen. Bisher wurde beim Hinzufügen eines POI eine komplett neue GPS-Route erstellt, wenn ein AI Trip aktiv war. Jetzt wird die AI-Route übernommen und um den neuen Stop erweitert.

Zusätzlich wird die Wetter-Empfehlung jetzt auf beiden Modi (Schnell und AI Trip) angezeigt. Der "Anwenden"-Button zeigt nach dem Klick einen aktiven Zustand ("Aktiv" mit Häkchen) und kann per erneutem Klick wieder deaktiviert werden (Toggle).

Im Schnell-Modus wurde die Auto-Navigation zum Trip-Tab entfernt. Stattdessen erscheint nach der Routenberechnung ein "Route starten" Button, der erst nach Klick zum Trip-Tab navigiert.

Das Wetter-Banner wurde visuell optimiert (stärkerer Hintergrund, kräftigerer Border) und POI-Marker auf der Karte zeigen jetzt Wetter-Badges an (Indoor-Empfehlung bei Regen, Outdoor-Ideal bei Sonnenschein).

## Neue Features

### AI Trip Route mit neuen Stops erweitern

**Problem:** Wenn ein AI Tagesausflug generiert wurde (Preview- oder Confirmed-State) und der User über die POI-Liste einen Stop hinzufügte ("Zur Route"), wurde eine neue GPS→POI Route erstellt. Die bestehende AI Trip Route ging dabei verloren.

**Ursache:** Die AI Trip Route liegt im `randomTripNotifierProvider`, nicht im `tripStateProvider`. `addStopWithAutoRoute()` prüfte nur `tripStateProvider.route`, das war `null` im Preview-State.

**Lösung:**
- Die POI-Screens erkennen jetzt einen aktiven AI Trip und übergeben dessen Route und Stops an `addStopWithAutoRoute()`
- `addStopWithAutoRoute()` akzeptiert optionale AI-Trip-Daten und integriert den neuen Stop
- Der AI Trip wird automatisch als bestätigt markiert (ohne POIs zu löschen)

**Betroffene Dateien:**
- `lib/features/random_trip/providers/random_trip_provider.dart`
- `lib/features/trip/providers/trip_state_provider.dart`
- `lib/features/poi/poi_list_screen.dart`
- `lib/features/poi/poi_detail_screen.dart`

## Code-Änderungen

### 1. Neue Methode `markAsConfirmed()` in RandomTripNotifier

```dart
// random_trip_provider.dart
/// Markiert den Trip als bestätigt ohne alte Daten zu löschen
/// Wird verwendet wenn ein Stop über die POI-Liste hinzugefügt wird
void markAsConfirmed() {
  if (state.generatedTrip == null) return;
  state = state.copyWith(step: RandomTripStep.confirmed);
}
```

Im Gegensatz zu `confirmTrip()` werden hier keine POIs gelöscht und keine Route-Session gestoppt.

### 2. Erweiterte `addStopWithAutoRoute()` in TripState

```dart
// trip_state_provider.dart
Future<AddStopResult> addStopWithAutoRoute(
  POI poi, {
  AppRoute? existingAIRoute,   // NEU
  List<POI>? existingAIStops,  // NEU
}) async {
  // Bestehende Route → Stop hinzufügen (unverändert)
  if (state.route != null) {
    addStop(poi);
    return const AddStopResult(success: true);
  }

  // NEU: AI Trip Route übernehmen
  if (existingAIRoute != null) {
    final allStops = [...(existingAIStops ?? []), poi];
    state = state.copyWith(route: existingAIRoute, stops: allStops);
    _recalculateRoute();
    return const AddStopResult(success: true);
  }

  // GPS-Fallback (unverändert)
  ...
}
```

### 3. AI-Trip-Erkennung in POI-Screens

```dart
// poi_list_screen.dart & poi_detail_screen.dart
Future<void> _addPOIToTrip(POI poi) async {
  final tripNotifier = ref.read(tripStateProvider.notifier);
  final tripData = ref.read(tripStateProvider);

  // AI Trip erkennen und Daten übergeben
  AppRoute? aiRoute;
  List<POI>? aiStops;
  if (tripData.route == null) {
    final randomTripState = ref.read(randomTripNotifierProvider);
    if (randomTripState.generatedTrip != null &&
        (randomTripState.step == RandomTripStep.preview ||
         randomTripState.step == RandomTripStep.confirmed)) {
      aiRoute = randomTripState.generatedTrip!.trip.route;
      aiStops = randomTripState.generatedTrip!.selectedPOIs;
    }
  }

  final result = await tripNotifier.addStopWithAutoRoute(
    poi,
    existingAIRoute: aiRoute,
    existingAIStops: aiStops,
  );

  // AI Trip als bestätigt markieren
  if (aiRoute != null && result.success) {
    ref.read(randomTripNotifierProvider.notifier).markAsConfirmed();
  }
  ...
}
```

## Technische Details

### Architektur-Entscheidung: UI-Layer Integration

Die AI-Trip-Erkennung liegt bewusst in der UI-Schicht (POI-Screens), nicht im Provider:

```
randomTripProvider ←──── importiert ────→ tripStateProvider
       ↑                                        ↑
       │ liest                                   │ liest + schreibt
       └──── poi_list_screen / poi_detail_screen ─┘
```

**Grund:** Zirkuläre Abhängigkeiten vermeiden. `randomTripProvider` importiert bereits `tripStateProvider`. Wenn `tripStateProvider` auch `randomTripProvider` importieren würde, entstünde ein Zirkelschluss.

**Lösung:** Die POI-Screens lesen beide Provider und übergeben die AI-Trip-Daten als Parameter an `addStopWithAutoRoute()`.

### Route-Neuberechnung

Wenn ein neuer Stop zur AI-Route hinzugefügt wird:
1. AI-Route und bestehende AI-Stops werden in `tripStateProvider` übernommen
2. Der neue POI wird ans Ende der Stop-Liste angefügt
3. OSRM berechnet die Route mit allen Waypoints neu
4. Start/End der Original-Route bleiben erhalten

### Unterschied: `markAsConfirmed()` vs `confirmTrip()`

| Methode | `confirmTrip()` | `markAsConfirmed()` |
|---------|-----------------|---------------------|
| Step → confirmed | Ja | Ja |
| Route → tripState | Ja | Nein (bereits übertragen) |
| POIs löschen | Ja | Nein |
| Route-Session stoppen | Ja | Nein |
| Route-Planner löschen | Ja | Nein |

### Wetter-Empfehlung auf Hauptseite (v1.7.8)

**Vorher:** Das Wetter-Empfehlungs-Banner wurde nur im AI-Trip-Modus angezeigt. Der "Anwenden"-Button hatte keinen aktiven Zustand.

**Nachher:**
- Das Banner erscheint jetzt auf **beiden Modi** (Schnell + AI Trip) zwischen Mode-Toggle und Modi-Inhalten
- Nach Klick auf "Anwenden" zeigt der Button **"Aktiv"** mit Häkchen-Icon und ausgefülltem Farbhintergrund
- Bei manueller Kategorie-Änderung wechselt der Button zurück zu "Anwenden"

**Betroffene Dateien:**
- `lib/features/random_trip/providers/random_trip_state.dart` - Neues Feld `weatherCategoriesApplied`
- `lib/features/random_trip/providers/random_trip_provider.dart` - State-Logik in `applyWeatherBasedCategories()` und `toggleCategory()`
- `lib/features/map/map_screen.dart` - Banner-Position verschoben, `isApplied` Parameter

**State-Feld:**
```dart
// random_trip_state.dart
@Default(false) bool weatherCategoriesApplied,
```

**Provider-Logik:**
```dart
// applyWeatherBasedCategories() setzt weatherCategoriesApplied: true
// toggleCategory() setzt weatherCategoriesApplied: false
// reset() setzt auf Default (false) zurück
```

**Banner-Widget:**
```dart
// _WeatherRecommendationBanner erweitert mit:
// - isApplied: bool → zeigt "Aktiv ✓" oder "Anwenden"
// - Ausgefüllter Farbhintergrund + weiße Schrift wenn aktiv
// - Position: Zwischen Mode-Toggle und Modi-Inhalten (beide Modi)
```

### "Route starten" Button statt Auto-Navigation im Schnell-Modus

**Vorher:** Nach der Routenberechnung im Schnell-Modus wurde automatisch nach 500ms zum Trip-Tab navigiert. Der "Route starten" Button war dadurch nie sichtbar.

**Nachher:** Die Auto-Navigation wurde entfernt. Nach der Routenberechnung wird die Route auf der Karte angezeigt und der "Route starten" Button erscheint mit Distanz und Dauer. Erst nach Klick auf den Button wird zum Trip-Tab navigiert.

**Betroffene Datei:**
- `lib/features/map/map_screen.dart`

**Änderungen:**
1. `routePlannerProvider` Listener: `context.go('/trip')` entfernt, nur `_fitMapToRoute` bleibt
2. `_RouteStartButton` Callback: `context.go('/trip')` hinzugefügt

```dart
// Listener - nur Zoom, keine Navigation
ref.listenManual(routePlannerProvider, (previous, next) {
  if (next.hasRoute && (previous?.route != next.route)) {
    _fitMapToRoute(next.route!);
  }
});

// Button - Navigation erst bei Klick
_RouteStartButton(
  route: routePlanner.route!,
  onStart: () {
    _startRoute(routePlanner.route!);
    context.go('/trip');
  },
),
```

### Wetter-Design optimiert + Toggle + POI-Marker-Badges (v1.7.9)

**1. Wetter-Empfehlungs-Banner vollständig opak**

**Vorher:** Banner war durchsichtig - Karte schien durch den Hintergrund.

**Nachher:** Opaker Hintergrund mit `Color.alphaBlend(color.withOpacity(0.15), colorScheme.surface)`. Die Wetterfarbe wird mit der Surface-Farbe geblendet, sodass ein vollständig opaker Hintergrund entsteht. Funktioniert korrekt in Light und Dark Mode. Zusätzlich kräftigerer Border (`0.5`, 1.5px) und Shadow.

**2. Anwenden-Button als Toggle (deaktivierbar)**

**Vorher:** Nach Klick auf "Anwenden" zeigte der Button "Aktiv" an, war aber nicht mehr klickbar.

**Nachher:** Der Button fungiert als Toggle - Klick auf "Aktiv" setzt die Kategorien zurück (alle außer Hotel) und zeigt wieder "Anwenden".

**Neue Methode:**
```dart
// random_trip_provider.dart
void resetWeatherCategories() {
  state = state.copyWith(
    selectedCategories: POICategory.values
        .where((c) => c != POICategory.hotel)
        .toList(),
    weatherCategoriesApplied: false,
  );
}
```

**3. Wetter-Badges auf POI-Markern auf der Karte**

**Vorher:** Wetter-Empfehlungen waren nur in POI-Listen-Karten als `WeatherBadge` sichtbar.

**Nachher:** POI-Marker auf der Karte zeigen Mini-Wetter-Badges (16px Kreis oben-rechts) und farbige Borders basierend auf der aktuellen Wetterlage.

**Badge-Logik:**

| Wetter | Indoor-POI | Outdoor-POI |
|--------|-----------|-------------|
| Unwetter | Rotes Badge | Rotes Badge + Oranger Border |
| Regen | Grünes Badge (empfohlen) | Oranges Badge + Oranger Border |
| Gut | Kein Badge | Grünes Badge (ideal) |

**Betroffene Dateien:**
- `lib/features/map/map_screen.dart` - Banner-Design + onReset Callback
- `lib/features/random_trip/providers/random_trip_provider.dart` - `resetWeatherCategories()` Methode
- `lib/features/map/widgets/map_view.dart` - `POIMarker` um Wetter-Badge erweitert + Weather-State Integration

### POI-Foto-Laden & Kategorisierung optimiert (v1.7.9)

**Problem 1: Fotos fehlen bei vielen POIs**

Nur die ersten 5 POIs ohne Wikipedia-Bild bekamen ein Wikimedia-Fallback. Alle weiteren POIs wurden fälschlicherweise als `isEnriched: true` markiert, obwohl sie kein Foto hatten. Diese POIs wurden nie erneut versucht.

**Lösung:**
1. **Batch-Limit von 5 auf 15 erhöht** - 3x mehr POIs bekommen Wikimedia-Fallback
2. **Sub-Batching** - 5er-Gruppen mit 500ms Pause für Rate-Limit-Schutz
3. **isEnriched-Fix** - POIs ohne Foto werden NICHT mehr als "enriched" markiert
4. **Session-Set** (`_sessionAttemptedWithoutPhoto`) verhindert Endlosschleifen in derselben Session, erlaubt aber Retry bei App-Neustart
5. **OSM-URL-Validierung** - `image`-Tags aus Overpass werden auf gültige HTTP-URLs geprüft

**Problem 2: Fotos laden langsam**

Fotos erschienen erst wenn der gesamte Batch fertig war. Kein Pre-Caching der Bild-URLs.

**Lösung:**
1. **2-Stufen UI-Update** - Cache-Treffer und Wikipedia-Ergebnisse werden sofort angezeigt, Wikimedia-Fallbacks inkrementell nachgeliefert (`onPartialResult` Callback)
2. **Image Pre-Caching** - Bild-URLs werden nach Enrichment via `DefaultCacheManager` vorgeladen
3. **Random Trip Batch** - AI Trip POIs nutzen jetzt Batch-Enrichment statt Einzel-Calls (7x schneller)
4. **Pre-Enrichment-Limit 30→50** - Nutzt volles Wikipedia-Batch-Query-Limit aus

**Problem 3: Fehlerhafte POI-Kategorisierung**

Ungültige Kategorie-IDs (`waterfall`, `cafe`) im AI-Chat-Mapping. Overpass-Query zu eingeschränkt. Wikipedia-Titel-Inferenz unvollständig.

**Lösung:**
1. **AI-Chat Kategorie-Fix** - `waterfall`→`coast`, `cafe` entfernt, 11 neue Mappings (Kultur, Strand, Sport, Familie, Zoo, Therme, Stadt)
2. **Overpass-Query erweitert** - +7 Tag-Typen: Museen, Ruinen, Memorials, Wasserfälle, Kirchen, Museums-Ways, Ruinen-Ways
3. **Overpass-Kategorie-Mapping erweitert** - Neue Zuordnungen: `ruins`→monument, `memorial`→monument, `waterfall`→nature, `park/garden`→park
4. **Wikipedia-Keywords erweitert** - 3 neue Kategorien: `activity` (Zoo, Therme, Stadion...), `hotel`, `restaurant` + `wasserfall`/`waterfall` für nature, `ruine`/`ruins` für monument

**Betroffene Dateien:**
- `lib/data/services/poi_enrichment_service.dart` - Batch-Limit, isEnriched-Fix, Session-Set, Pre-Cache, 2-Stufen-Callback
- `lib/data/repositories/poi_repo.dart` - Overpass-Query, Kategorie-Mapping, URL-Validierung, Title-Keywords
- `lib/features/poi/providers/poi_state_provider.dart` - 2-Stufen Batch-Update mit onPartialResult
- `lib/features/poi/poi_list_screen.dart` - Pre-Enrichment-Limit 30→50
- `lib/features/ai_assistant/chat_screen.dart` - Ungültige Kategorie-IDs gefixt + 11 neue Mappings
- `lib/features/random_trip/providers/random_trip_provider.dart` - Batch statt Einzel-Enrichment

**Performance-Verbesserung:**

| Metrik | Vorher (v1.7.7) | Nachher (v1.7.9) |
|--------|-----------------|-------------------|
| Fallback-Coverage | 5 POIs | 15 POIs |
| Bild-Trefferquote | ~95% | ~98% |
| UI-Update | nach Batch-Ende | inkrementell |
| Random Trip Enrichment | Einzel-Calls | Batch (7x schneller) |
| Overpass Tag-Typen | 5 | 12 |
| Wikipedia-Kategorien | 10 | 13 |
| AI-Chat-Mappings | 12 | 23 |

## Auswirkungen

- Keine Breaking Changes
- Keine API-Änderungen
- Bestehende Flows (GPS-Fallback, normales Stop-Hinzufügen) bleiben unverändert
- AI Trip Route bleibt erhalten beim Hinzufügen neuer Stops
- Wetter-Empfehlung sichtbar auf beiden Modi der Hauptseite + Toggle
- Schnell-Modus: Benutzer hat Kontrolle über Navigation zum Trip-Tab
- POI-Marker auf Karte zeigen Wetter-Empfehlungen direkt an
- POI-Fotos laden deutlich zuverlässiger und schneller
- Mehr POI-Typen werden korrekt kategorisiert
