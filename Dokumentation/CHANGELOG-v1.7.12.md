# Changelog v1.7.12 - Wetter-Marker auf der Route

**Release-Datum:** 30. Januar 2026

## Zusammenfassung

Diese Version zeigt Wetter-Icons mit Temperatur, Empfehlungen und Warnungen direkt auf der berechneten Route auf der Karte an. An 5 gleichverteilten Punkten entlang der Route erscheinen farbcodierte Marker, die auf einen Blick das Wetter entlang der Strecke zeigen. Bei Tap auf einen Marker öffnet sich ein Detail-Sheet mit Wind, Niederschlag und Empfehlung.

## Neues Feature

### Wetter-Marker auf der Route

**Vorher:** Das Routen-Wetter wurde nur als Overlay-Panel (WeatherBar) am oberen Bildschirmrand angezeigt. Auf der Karte selbst waren keine Wetter-Informationen entlang der Route sichtbar.

**Nachher:** 5 Wetter-Marker erscheinen direkt auf der Route auf der Karte. Jeder Marker zeigt:
- Wetter-Emoji (☀️/⛅/🌧️/⛈️ etc.)
- Aktuelle Temperatur (z.B. "22°C")
- Farbcodierter Hintergrund nach Wetterlage
- Warning-Badge (!) bei schlechtem Wetter oder Unwetter

**Tap-Interaktion:** Bei Klick auf einen Marker öffnet sich ein Bottom Sheet mit:
- Ort-Label ("Start", "Ziel" oder "Routenpunkt X von 5")
- Großes Wetter-Icon + Temperatur + Beschreibung
- Gefühlte Temperatur
- Wind, Niederschlag, Regenwahrscheinlichkeit
- Kontextbezogene Empfehlung:
  - ☀️ Gut: "Perfektes Wetter für Outdoor-Aktivitäten"
  - ⛅ Wechselhaft: "Wechselhaft - auf alles vorbereitet sein"
  - 🌧️ Schlecht: "Schlechtes Wetter - Indoor-Aktivitäten empfohlen" / "Schneefall - Vorsicht auf glatten Straßen"
  - ⛈️ Unwetter: "Unwetterwarnung! Vorsicht auf diesem Streckenabschnitt" / "Sturmwarnung! Starke Winde (X km/h)"

### Automatisches Wetter-Laden für alle Routentypen

**Vorher:** Routen-Wetter wurde nur geladen, wenn eine Route-Session gestartet wurde (`RouteSession.startRoute()`). Bei einfacher Routenberechnung oder AI Trip Preview fehlten die Wetterdaten.

**Nachher:** Wetter wird automatisch geladen bei:
- Normale Routenberechnung (Start/Ziel)
- AI Trip Preview (nach Generierung)
- Gespeicherte Route laden (aus Favoriten)

## Farbschema

| WeatherCondition | Hintergrund | Border | Text | Badge |
|------------------|-------------|--------|------|-------|
| good (Gut) | Grün shade50 | Grün shade300 | Grün shade800 | - |
| mixed (Wechselhaft) | Amber shade50 | Amber shade300 | Amber shade800 | - |
| bad (Schlecht) | Orange shade50 | Orange shade300 | Orange shade800 | Orange (!) |
| danger (Unwetter) | Rot shade50 | Rot shade300 | Rot shade800 | Rot (!) |

Dark Mode: Dunklere Varianten (shade900 bg, shade200 text) für besseren Kontrast.

## Betroffene Dateien

| Datei | Aktion | Beschreibung |
|-------|--------|--------------|
| `lib/features/map/widgets/route_weather_marker.dart` | NEU | RouteWeatherMarker Widget + showRouteWeatherDetail() Bottom Sheet |
| `lib/features/map/widgets/map_view.dart` | GEÄNDERT | Neuer MarkerLayer, routeWeatherNotifierProvider Watch, Wetter-Laden-Listener |

## Technische Details

### Layer-Reihenfolge in map_view.dart

```
1. TileLayer (Kartenkacheln)
2. PolylineLayer (Route)
3. MarkerLayer (Routen-Wetter-Marker) ← NEU
4. MarkerLayer (POI-Marker / AI Trip Stops)
5. MarkerLayer (Start-Marker)
6. MarkerLayer (Ziel-Marker)
7. MarkerLayer (Trip-Stops)
```

Wetter-Marker liegen über der Route-Linie, aber unter POI-Markern. So bleiben POIs immer interaktiv.

### Wetter-Laden-Listener

```dart
void _setupWeatherListeners() {
  // Normale Route
  ref.listenManual(routePlannerProvider, (previous, next) {
    if (next.hasRoute && previous?.route != next.route) {
      ref.read(routeWeatherNotifierProvider.notifier)
          .loadWeatherForRoute(next.route!.coordinates);
    }
  });

  // AI Trip Preview
  ref.listenManual(randomTripNotifierProvider, (previous, next) {
    if (next.step == RandomTripStep.preview &&
        previous?.step != RandomTripStep.preview) {
      final route = next.generatedTrip?.trip.route;
      if (route != null) {
        ref.read(routeWeatherNotifierProvider.notifier)
            .loadWeatherForRoute(route.coordinates);
      }
    }
  });

  // Trip State (gespeicherte Route laden)
  ref.listenManual(tripStateProvider, (previous, next) {
    if (next.hasRoute && previous?.route != next.route) {
      ref.read(routeWeatherNotifierProvider.notifier)
          .loadWeatherForRoute(next.route!.coordinates);
    }
  });
}
```

### Datenfluss

```
Route berechnet (beliebige Quelle)
       ↓
MapView Listener erkennt Routenänderung
       ↓
routeWeatherNotifierProvider.loadWeatherForRoute(coordinates)
       ↓
Open-Meteo API × 5 (mit 100ms Delay)
       ↓
RouteWeatherState.weatherPoints = [WeatherPoint × 5]
       ↓
MapView rebuild (ref.watch)
       ↓
MarkerLayer mit RouteWeatherMarker Widgets
       ↓
User tappt Marker → showRouteWeatherDetail (Bottom Sheet)
```

## Auswirkungen

- Keine Breaking Changes
- Keine API-Änderungen
- Keine Model-Änderungen
- Bestehende WeatherBar bleibt als Overlay-Panel erhalten
- Wetter-Marker ergänzen die bestehende Wetter-Anzeige visuell auf der Karte
- Automatisches Laden für alle Routentypen (vorher nur bei Route-Session)
