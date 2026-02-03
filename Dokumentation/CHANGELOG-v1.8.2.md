# CHANGELOG v1.8.2 - Google Maps Export-Fix & Tag-Editor Kartenausschnitt

**Datum:** 2. Februar 2026
**Build:** 1.8.2+144

## Zusammenfassung

Kritischer Fix fuer den **Google Maps Export**: Tages-Stops werden jetzt in der optimierten Reihenfolge (`order`) exportiert statt in der Gesamt-Routen-Position (`routePosition`). Dadurch entfaellt die Zickzack-Route in Google Maps, die ~3x laengere Strecken verursachte (466km MapAB vs 1397km Google Maps). Zusaetzlich **aktualisiert die Mini-Map im Tag-Editor** jetzt korrekt bei Tageswechsel.

---

## Fix 1: Google Maps Export - Stops in falscher Reihenfolge (KRITISCH)

### Problem
Beim Export eines Tages an Google Maps zeigte MapAB 466 km, Google Maps aber 1397 km (~3x Differenz). Die Waypoints wurden in einer Zickzack-Reihenfolge an Google Maps gesendet.

### Ursache
`trip.dart:getStopsForDay()` nutzte `sortedStops`, das nach `routePosition` sortiert:
```dart
// VORHER (fehlerhaft):
List<TripStop> getStopsForDay(int dayNumber) {
  return sortedStops.where((s) => s.day == dayNumber).toList();
}
```

`routePosition` ist die Position auf der GESAMT-Route (0.0-1.0), nicht die optimierte Tages-Reihenfolge. Der DayPlanner setzt das `order`-Feld korrekt pro Tag (day_planner.dart:73-78), aber `getStopsForDay()` ignorierte `order` und sortierte stattdessen nach `routePosition`.

Google Maps besucht Waypoints in der gegebenen Reihenfolge → Zickzack-Route → 3x laengere Strecke.

### Loesung
**`lib/data/models/trip.dart`** - `getStopsForDay()` sortiert jetzt nach `order`:
```dart
// NACHHER (korrekt):
List<TripStop> getStopsForDay(int dayNumber) {
  final dayStops = stops.where((s) => s.day == dayNumber).toList();
  dayStops.sort((a, b) => a.order.compareTo(b.order));
  return dayStops;
}
```

### Auswirkung
- Google Maps Export: Stops in optimierter Reihenfolge → keine Zickzack-Routen mehr
- Tag-Editor: POI-Karten in korrekter Reihenfolge
- Mini-Map: Marker-Nummerierung stimmt mit Reihenfolge ueberein
- Trip-Screen: Tagesweiser Export funktioniert korrekt

---

## Fix 2: Distanz-Anzeige realistischer

### Problem
`getDistanceForDay()` zeigte nur die Haversine-Summe der Stops, ohne:
1. Das Segment zum Tagesziel (naechster Tag oder Rueckkehr zum Start)
2. Den Unterschied zwischen Luftlinie und echter Fahrstrecke (~35% mehr)

### Loesung
**`lib/data/models/trip.dart`** - `getDistanceForDay()` erweitert:
- Segment zum Tagesziel mitzaehlen (wie im Google Maps Export)
- Haversine mit Faktor 1.35 multiplizieren (≈ echte Fahrstrecke)
- Label zeigt "~X km" statt "X km"

```dart
double getDistanceForDay(int dayNumber) {
  // ... Stops + kumulative Haversine ...

  // Segment zum Tagesziel
  if (dayNumber == actualDays) {
    total += _haversineDistance(prevLocation!, route.start);
  } else {
    final nextDayStops = getStopsForDay(dayNumber + 1);
    if (nextDayStops.isNotEmpty) {
      total += _haversineDistance(prevLocation!, nextDayStops.first.location);
    }
  }

  // Haversine → geschaetzte Fahrstrecke
  return total * 1.35;
}
```

**`lib/features/trip/widgets/day_editor_overlay.dart`** - Distanz-Label:
```dart
// VORHER: '${trip.getDistanceForDay(selectedDay).toStringAsFixed(0)} km'
// NACHHER: '~${trip.getDistanceForDay(selectedDay).toStringAsFixed(0)} km'
```

---

## Fix 3: Tag-Editor Mini-Map aktualisiert nicht bei Tageswechsel

### Problem
Beim Wechsel zwischen Tagen im Day Editor blieb die Mini-Map auf dem vorherigen Tagesausschnitt.

### Ursache
`DayMiniMap` ist ein `StatelessWidget` mit `initialCameraFit`:
```dart
options: MapOptions(
  initialCameraFit: CameraFit.bounds(...),
)
```

`initialCameraFit` wird nur beim ersten Erstellen angewendet. Ohne Key erstellt Flutter das Widget nicht neu → Kamera bleibt auf altem Ausschnitt.

### Loesung
**`lib/features/trip/widgets/day_editor_overlay.dart`** - `ValueKey` auf DayMiniMap:
```dart
DayMiniMap(
  key: ValueKey(selectedDay),  // Erzwingt Neuerstellung bei Tageswechsel
  trip: trip,
  selectedDay: selectedDay,
  startLocation: startLocation,
  routeSegment: routeSegment,
),
```

---

## Geaenderte Dateien

| # | Datei | Aenderung |
|---|-------|-----------|
| 1 | `lib/data/models/trip.dart` | `getStopsForDay()`: Sort by `order` statt `routePosition` |
| 2 | `lib/data/models/trip.dart` | `getDistanceForDay()`: Destination-Segment + Faktor 1.35 + `_haversineDistance()` inline |
| 3 | `lib/features/trip/widgets/day_editor_overlay.dart` | Distanz-Label: "~X km" |
| 4 | `lib/features/trip/widgets/day_editor_overlay.dart` | `DayMiniMap` Key: `ValueKey(selectedDay)` |

---

## Verifizierung

1. **Trip generieren** (Euro Trip, 3+ Tage)
2. **Tag-Editor oeffnen** → zwischen Tagen wechseln → Mini-Map muss auf neuen Tag zoomen
3. **Distanz pruefen** → sollte naeher an Google Maps sein (nicht mehr 3x Differenz)
4. **Tag in Google Maps exportieren** → Route sollte keine Zickzack-Muster zeigen
