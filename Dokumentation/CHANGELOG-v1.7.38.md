# CHANGELOG v1.7.38 - Euro Trip Tage-Auswahl statt Radius

**Datum:** 2. Februar 2026
**Build:** 1.7.38+138

## Zusammenfassung

Euro Trip nutzt jetzt direkt die **Tagesanzahl (1-14)** als primaeren Input statt den Radius.
Der Datenfluss wurde umgekehrt: Benutzer waehlt Tage, Radius wird automatisch berechnet (Tage x 600 km).
Quick-Select Buttons zeigen Tage (2, 4, 7, 10) statt Kilometer.
Der Tagestrip-Modus bleibt komplett unveraendert (Radius-Slider wie bisher).

---

## Aenderung: Datenfluss umgekehrt

### Vorher (Radius -> Tage)

```
UI Slider (km) -> setRadius(km) -> state.radiusKm -> generateEuroTrip()
                                                    -> days = ceil(km / 600)
                                                    -> DayPlanner.planDays(days)
```

### Nachher (Tage -> Radius)

```
UI Slider (Tage) -> setEuroTripDays(days) -> state.days + state.radiusKm = days x 600
                                           -> generateEuroTrip(days: state.days)
                                           -> DayPlanner.planDays(days)
```

---

## Neue Konstanten

```dart
// trip_constants.dart
static const List<int> euroTripQuickSelectDays = [2, 4, 7, 10];
static const int euroTripMinDays = 1;
static const int euroTripMaxDays = 14;
static const int euroTripDefaultDays = 3;
```

Alte `euroTripQuickSelectRadii` entfernt (nicht mehr referenziert).

---

## Neue Provider-Methode

```dart
// random_trip_provider.dart
void setEuroTripDays(int days) {
  final clampedDays = days.clamp(
    TripConstants.euroTripMinDays,
    TripConstants.euroTripMaxDays,
  );
  state = state.copyWith(
    days: clampedDays,
    radiusKm: TripConstants.calculateRadiusFromDays(clampedDays),
  );
}
```

---

## UI-Aenderung: _CompactRadiusSlider (MapScreen)

### Vorher
- Einheitlicher Radius-Slider fuer beide Modi
- Euro Trip: 100-5000 km, Quick-Select: 500, 1000, 2500, 5000 km

### Nachher
- Bedingtes Rendering: Euro Trip -> Tage-Selector, Tagestrip -> Radius-Slider
- Euro Trip: 1-14 Tage, Quick-Select: 2, 4, 7, 10 Tage
- Header: Kalender-Icon + "Reisedauer" + Badge "X Tage"
- Sekundaere Info: "Kurzurlaub - ca. 1800 km Suchradius"

```dart
// VORHER
Slider(value: currentRadius, min: 100, max: 5000, ...)
onChanged: (value) => notifier.setRadius(value)

// NACHHER
Slider(value: currentDays.toDouble(), min: 1, max: 14, divisions: 13, ...)
onChanged: (value) => notifier.setEuroTripDays(value.round())
```

---

## State-Aenderung: calculatedDays

```dart
// VORHER - Aus Radius berechnet
int get calculatedDays => mode == RandomTripMode.eurotrip
    ? (radiusKm / 600).ceil().clamp(1, 14)
    : 1;

// NACHHER - Direkt aus State
int get calculatedDays => mode == RandomTripMode.eurotrip ? days : 1;
```

---

## Repository-Aenderung: generateEuroTrip()

```dart
// VORHER
Future<GeneratedTrip> generateEuroTrip({
  required LatLng startLocation,
  required String startAddress,
  double radiusKm = 1000,
  ...
}) async {
  final days = TripConstants.calculateDaysFromDistance(radiusKm);

// NACHHER
Future<GeneratedTrip> generateEuroTrip({
  required LatLng startLocation,
  required String startAddress,
  double radiusKm = 1000,
  int? days,  // NEU: optionaler Parameter, hat Vorrang
  ...
}) async {
  final effectiveDays = days ?? TripConstants.calculateDaysFromDistance(radiusKm);
```

---

## Geaenderte Dateien

| Datei | Aenderungen |
|-------|-------------|
| `lib/core/constants/trip_constants.dart` | Neue Konstanten: euroTripQuickSelectDays, euroTripMinDays/MaxDays/DefaultDays. Alte euroTripQuickSelectRadii entfernt |
| `lib/features/random_trip/providers/random_trip_state.dart` | calculatedDays liest state.days direkt statt Radius-Berechnung |
| `lib/features/random_trip/providers/random_trip_provider.dart` | Neue setEuroTripDays(), setMode() mit TripConstants, generateTrip() uebergibt days |
| `lib/data/repositories/trip_generator_repo.dart` | generateEuroTrip() mit optionalem days-Parameter, effectiveDays statt days |
| `lib/features/map/map_screen.dart` | _CompactRadiusSlider: Bedingtes Rendering Euro Trip (Tage) vs Tagestrip (Radius). Import TripConstants |
| `lib/features/random_trip/widgets/radius_slider.dart` | Selbe Umstellung: _buildDaysSelector() fuer Euro Trip, _QuickSelectButton vereinfacht |
| `lib/features/random_trip/widgets/days_selector.dart` | Nutzt state.calculatedDays statt TripConstants.calculateDaysFromDistance() |

---

## Was bleibt unveraendert

- **DayPlanner** (`day_planner.dart`) - bekommt schon `days` als Parameter
- **Google Maps Export** - arbeitet mit `day`-Feld auf TripStops
- **Trip/TripStop Models** - `days` und `day`-Feld bleiben gleich
- **removePOI/rerollPOI** - nutzen `actualDays` vom Trip
- **Tagestrip-Modus** - komplett unveraendert (1 Tag, Radius-Slider)
- **AI Chat Route Generation** - eigene Logik, nicht betroffen

---

## Verifikation

1. Euro Trip: Tage-Slider von 1-14 sichtbar
2. Quick-Select: 2, 4, 7, 10 Tage Buttons funktionieren
3. Sekundaere Info: "ca. X km Suchradius" wird angezeigt
4. Beschreibung wechselt: "Wochenend-Trip", "Kurzurlaub", "Wochenreise", etc.
5. Trip-Generierung: Korrekte Tagesanzahl bei POI-Verteilung
6. DayTabSelector: Zeigt richtige Anzahl Tabs
7. Google Maps Export: Tagesweiser Export funktioniert
8. Tagestrip-Modus: Unveraendert, Radius-Slider wie bisher
9. Legacy RandomTripScreen: Selbe Tage-Auswahl im Euro Trip
