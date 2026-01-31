# Changelog v1.7.8/v1.7.9 - AI Trip Route + Wetter-Empfehlung UI + Route Starten Button + Wetter-Design & POI-Marker-Badges

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

**1. Wetter-Empfehlungs-Banner sichtbarer gemacht**

**Vorher:** Banner war nahezu durchsichtig (`opacity: 0.1` Hintergrund, `0.3` Border).

**Nachher:** Stärkerer Hintergrund (`0.15`), kräftigerer Border (`0.5`, 1.5px), Shadow, größere Schrift.

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

## Auswirkungen

- Keine Breaking Changes
- Keine API-Änderungen
- Bestehende Flows (GPS-Fallback, normales Stop-Hinzufügen) bleiben unverändert
- AI Trip Route bleibt erhalten beim Hinzufügen neuer Stops
- Wetter-Empfehlung sichtbar auf beiden Modi der Hauptseite + Toggle
- Schnell-Modus: Benutzer hat Kontrolle über Navigation zum Trip-Tab
- POI-Marker auf Karte zeigen Wetter-Empfehlungen direkt an
