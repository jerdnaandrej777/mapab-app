# CHANGELOG v1.8.0 - Wettervorhersage, AI-Vorschlaege & Korridor-POI-Browser

**Datum:** 2. Februar 2026
**Build:** 1.8.0+142

## Zusammenfassung

Drei grosse neue Features fuer mehrtaegige Trips: **Tages-spezifische Wettervorhersage** (echte 7-Tage-Vorhersage statt nur aktuelles Wetter), **AI-gestuetzte Indoor/Outdoor-Vorschlaege** (GPT-4o schlaegt Alternativen bei schlechtem Wetter vor) und ein **Korridor-POI-Browser** zum Entdecken und Hinzufuegen weiterer POIs entlang der Route.

---

## Feature 1: Tages-spezifische Wettervorhersage

### Problem
`loadWeatherForRoute()` rief `getCurrentWeather()` auf und zeigte nur das aktuelle Wetter. Bei einem 5-Tage-Trip zeigte Tag 5 das HEUTIGE Wetter am Zielpunkt, nicht die Vorhersage fuer Tag 5.

### Loesung

**WeatherPoint erweitert** (`weather_provider.dart:12`):
```dart
class WeatherPoint {
  // ... bestehend ...
  final List<DailyForecast>? dailyForecast;  // NEU: 7-Tage-Vorhersage
  final int? dayNumber;                       // NEU: Welcher Reisetag (1-basiert)
}
```

**Neue Methode `loadWeatherForRouteWithForecast()`** (`weather_provider.dart:287`):
- Ruft `getWeatherWithForecast()` statt `getCurrentWeather()` auf
- Speichert `dailyForecast` in jedem WeatherPoint
- Rate-Limiting: 100ms zwischen API-Calls

**Neue Methoden in `RouteWeatherState`:**
- `getDayForecast(int day, int totalDays)` - Holt DailyForecast fuer einen bestimmten Tag
- `getForecastPerDay(int totalDays)` - Map<int, WeatherCondition> aus echten Vorhersage-Daten
- `getForecastPerDayAsStrings(int totalDays)` - Formatierte Strings fuer AI-Kontext

**DayEditorOverlay** (`day_editor_overlay.dart:79`):
- `_getDayWeather()` nutzt `getForecastPerDay()` bei Multi-Day-Trips mit Vorhersage
- Fallback auf positionsbasiertes Mapping wenn keine Vorhersage vorhanden

**DayStats** (`day_editor_overlay.dart:290`):
- Neuer StatChip zeigt Tagesvorhersage-Icon + Temperatur-Range
- z.B.: "Mo 12°/18°" oder Wetter-Icon mit Min/Max

**EditablePOICard Wetter-Badges** (`editable_poi_card.dart:107`):
- Outdoor + Regen: Orange Badge "Regen"
- Outdoor + Unwetter: Rotes Badge "Unwetter"
- Indoor + Regen: Gruenes Badge "Empfohlen"
- Outdoor + Sonne: Gruenes Badge "Ideal"

### Aufruf-Kette
1. `confirmTrip()` in `random_trip_provider.dart` ruft `loadWeatherForRouteWithForecast()` auf
2. Forecast-Tage = Trip-Tage (max 7, Open-Meteo Limit)
3. DayEditorOverlay liest `routeWeather.getForecastPerDay()` fuer tagesgenaues Wetter

---

## Feature 2: AI-gestuetzte Indoor/Outdoor-Vorschlaege

### Problem
`AISuggestionBanner` hatte "Indoor-Alternativen vorschlagen" Button, aber `onSuggestAlternatives` war ein TODO. Der `AITripAdvisorNotifier` arbeitete nur regelbasiert.

### Loesung

**`AISuggestion` erweitert** (`ai_trip_advisor_provider.dart:17`):
```dart
class AISuggestion {
  // ... bestehend ...
  final String? replacementPOIName;  // NEU: Name des vorgeschlagenen Indoor-POI
  final String? actionType;          // NEU: "swap", "remove", "reorder"
}
```

**Neue Methode `suggestAlternativesForDay()`** (`ai_trip_advisor_provider.dart:175`):
- Empfaengt Tag, Trip, Wetter-State und verfuegbare POIs
- Erstellt Wetter-Strings aus `getForecastPerDayAsStrings()` oder `getWeatherPerDayAsStrings()`
- Ruft `AIService.optimizeTrip()` auf (GPT-4o ueber Backend-Proxy)
- Konvertiert AI-Response zu AISuggestion-Objekten
- Filtert Vorschlaege fuer den Ziel-Tag
- Graceful Fallback auf regelbasierte Vorschlaege wenn Backend nicht erreichbar

**DayEditorOverlay Integration** (`day_editor_overlay.dart:156`):
- `onSuggestAlternatives` Button verbunden mit `suggestAlternativesForDay()`
- Neue `_AISuggestionsSection` (Zeile 413) zeigt Vorschlaege an:
  - Wetter-Vorschlaege (Cloud-Icon, tertiaere Farbe)
  - Alternativen-Vorschlaege (Swap-Icon, primaere Farbe)
  - Allgemeine Vorschlaege (Gluehbirnen-Icon)
- Loading-State waehrend AI antwortet
- Error-Handling bei Backend-Fehler

---

## Feature 3: Korridor-POI-Browser

### Problem
Nach Routenberechnung konnte man keine weiteren POIs entlang der Route entdecken und hinzufuegen.

### Loesung

**Neuer `CorridorBrowserNotifier`** (`corridor_browser_provider.dart:68`):
```dart
@riverpod
class CorridorBrowserNotifier extends _$CorridorBrowserNotifier {
  Future<void> loadCorridorPOIs({required AppRoute route, required double bufferKm, ...})
  void setBufferKm(double km)
  void setCategories(Set<POICategory> cats)
  void toggleCategory(POICategory cat)
  void markAsAdded(String poiId)
  void reset()
}
```
- Nutzt `GeoUtils.calculateBoundsWithBuffer()` fuer Korridor-Berechnung
- Laedt POIs aus 3-Layer-Repository (kuratiert + Wikipedia + Overpass)
- Berechnet `routePosition` und `detourKm` fuer jeden POI
- Sortiert nach Position auf Route (Start → Ziel)
- Filtert bereits hinzugefuegte POIs aus

**Neues `CorridorBrowserSheet`** (`corridor_browser_sheet.dart`):
- DraggableScrollableSheet mit:
  - Header: "POIs entlang der Route" + Anzahl
  - Korridor-Breite Slider: 10-100km (Quick-Select: 20/50/100km)
  - Kategorie-Filter: Horizontale Chip-Liste
  - POI-Liste mit `CompactPOICard` (Add-Button / Haekchen)
  - Umweg-Distanz pro POI
- Statische `show()` Methode zum Oeffnen

**Neues `CompactPOICard`** (`compact_poi_card.dart`):
- 64px hohe kompakte POI-Karte
- Bild (56x56), Name, Kategorie, optionaler Umweg
- Add/Check-Button (animiert)

**Neuer `POITripHelper`** (`poi_trip_helper.dart`):
- Shared Utility fuer POI→Trip Hinzufuegen
- Erkennt aktive AI Trips und uebergibt deren Route/Stops
- `addPOIWithFeedback()` mit SnackBar-Rueckmeldung + GPS-Dialog

**Einstiegspunkte:**
1. **DayEditorOverlay** (Zeile 562): IconButton "POIs entdecken" in BottomActions
2. **TripScreen** (Zeile 660 + 764): OutlinedButton "POIs entlang der Route"
   - Sowohl bei normaler Route als auch bei AI Trip

---

## Geaenderte Dateien

| Datei | Aenderungen |
|-------|-------------|
| `lib/features/map/providers/weather_provider.dart` | WeatherPoint um dailyForecast/dayNumber erweitert, `loadWeatherForRouteWithForecast()`, `getDayForecast()`, `getForecastPerDay()`, `getForecastPerDayAsStrings()` |
| `lib/data/models/weather.dart` | DailyForecast.condition Getter |
| `lib/features/random_trip/providers/random_trip_provider.dart` | Aufruf von `loadWeatherForRouteWithForecast()` bei Multi-Day-Trips |
| `lib/features/trip/widgets/day_editor_overlay.dart` | Tages-Wetter-Anzeige, AI-Vorschlaege-Section, Korridor-Browser-Button |
| `lib/features/trip/widgets/editable_poi_card.dart` | Kontext-aware Wetter-Badges (Regen/Unwetter/Empfohlen/Ideal) |
| `lib/features/ai/providers/ai_trip_advisor_provider.dart` | `suggestAlternativesForDay()`, AISuggestion erweitert |
| `lib/features/ai/widgets/ai_suggestion_banner.dart` | onSuggestAlternatives verbunden |
| `lib/features/trip/trip_screen.dart` | "POIs entlang der Route" Buttons (Route + AI Trip) |

## Neue Dateien

| Datei | Beschreibung |
|-------|-------------|
| `lib/features/trip/providers/corridor_browser_provider.dart` | Riverpod Provider fuer Korridor-POI-Suche, Filter und State |
| `lib/features/trip/widgets/corridor_browser_sheet.dart` | Bottom Sheet UI mit Slider, Kategorie-Filter, POI-Liste |
| `lib/features/map/widgets/compact_poi_card.dart` | Kompakte 64px POI-Karte fuer Listen-Ansicht |
| `lib/features/map/utils/poi_trip_helper.dart` | Shared Utility fuer POI→Trip mit Feedback |

---

## Bugfixes im Build

Zwei Compile-Fehler wurden beim Release-Build gefunden und behoben:

1. **Nullable Trip-Zugriff** (`trip_screen.dart:784`): `trip` ist `Trip?` - fehlender Null-Check vor `.route`
2. **Named Parameter** (`weather_provider.dart:312`): `forecastDays` als positionales statt Named-Argument uebergeben

---

## Verifikation

1. **Tagesausflug**: Route berechnen → DayEditor zeigt Wetter-Badge pro POI
2. **3-Tage Euro Trip**: Trip generieren → Tag 1/2/3 zeigen unterschiedliches Tagesvorhersage-Wetter → AI Banner erscheint bei schlechtem Wetter → "Indoor-Alternativen vorschlagen" funktioniert
3. **Korridor-Browser**: Route vorhanden → TripScreen "POIs entlang der Route" → Sheet zeigt POIs nach Position sortiert → Slider aendert Korridor-Breite → POI hinzufuegen → Haekchen erscheint
4. **Dark Mode**: Alle neuen UI-Elemente mit `colorScheme` statt hart-codierten Farben

## Einschraenkungen

- Open-Meteo liefert max 16 Tage Vorhersage → Trips > 7 Tage zeigen nur 7 Tage Vorhersage
- AI Backend muss erreichbar sein fuer Feature 2 → Graceful Fallback auf regelbasierte Vorschlaege
- Korridor-POIs nutzen Region-Cache von `loadPOIsInBounds`
