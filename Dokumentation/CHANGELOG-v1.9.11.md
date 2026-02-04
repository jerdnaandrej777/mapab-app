# CHANGELOG v1.9.11 - Tagesdistanz-Fix (max. 700km/Tag)

**Datum:** 3. Februar 2026
**Build:** 1.9.11+158

## Ueberblick

Kritischer Bugfix: Die Tagesdistanz-Anzeige im DayEditor zeigte fuer manche Tage ueber 5000 km an (z.B. ~5256 km fuer Tag 3 eines 7-Tage Deutschland→Spanien Trips). Ursache war eine Doppelzaehlung des Outgoing-Segments in `getDistanceForDay()`. Zusaetzlich wurden Safety-Mechanismen im DayPlanner und der Trip-Generierung verstaerkt.

---

## Fix 1: getDistanceForDay() Doppelzaehlung behoben

### Problem
`Trip.getDistanceForDay(dayNumber)` rechnete fuer jeden Tag ein "Outgoing-Segment" (Distanz zum ersten Stop des naechsten Tages) mit ein. Dieses Segment wurde aber auch als "Incoming-Segment" von Tag N+1 gezaehlt — eine Doppelzaehlung.

Bei langen Strecken (z.B. Deutschland→Spanien) konnte dieses Outgoing-Segment allein 2000+ km Haversine betragen, was × 1.35 zu ueber 5000 km Display-Distanz fuehrte.

Zusaetzlich nutzte der letzte Tag `route.start` statt `route.end` als Rueckkehr-Ziel.

### Loesung

**Vorher:**
```dart
// Segment zum Tagesziel (wie im Google Maps Export)
if (dayNumber == actualDays) {
  // Letzter Tag: zurueck zum Start
  total += _haversineDistance(prevLocation!, route.start);
} else {
  // Naechster Tag: erster Stop des Folgetages
  final nextDayStops = getStopsForDay(dayNumber + 1);
  if (nextDayStops.isNotEmpty) {
    total += _haversineDistance(prevLocation!, nextDayStops.first.location);
  }
}
```

**Nachher:**
```dart
// Nur letzter Tag: Rueckkehr-Segment zum Trip-Ziel einrechnen
if (dayNumber == actualDays) {
  total += _haversineDistance(prevLocation!, route.end);
}
```

### Auswirkung
- Kein Outgoing-Segment mehr fuer Tage 1 bis N-1
- Letzter Tag nutzt `route.end` (Reiseziel) statt `route.start`
- Konsistent mit DayPlanner-Semantik: Incoming-Segment gehoert zum empfangenden Tag

---

## Fix 2: DayPlanner _splitOverlimitDays() Safety-Split

### Problem
Trotz des distanzbasierten Clusterings im DayPlanner konnten einzelne Tage das 700km Display-Limit ueberschreiten, z.B. wenn:
- Das Incoming-Segment allein >700km ist (weit entfernte aufeinanderfolgende POIs)
- Mehrere Stops mit hoher Einzeldistanz sich aufaddieren

### Loesung
Neue Post-Processing Methode `_splitOverlimitDays()`:

```dart
void _splitOverlimitDays(List<List<POI>> clusters, LatLng startLocation) {
  // Iteriert durch alle Tage
  // Wenn Display-Distanz > 700km und > 1 POI:
  //   → Finde Split-Punkt (POI-Index wo 700km erreicht)
  //   → Teile Tag in zwei Teile
  //   → Pruefe den ersten Teil nochmal
  // Schutz gegen Endlosschleifen: max clusters.length * 2 Iterationen
}
```

Wird nach `_mergeShortDays()` und `_splitLastDayIfOverLimit()` aufgerufen.

### Safety-Logging
```
[DayPlanner] ⚠️ Incoming-Segment 850km Display > 700km Limit (POI: Sagrada Familia)
[DayPlanner] Split Tag 3: ~920km → 2 + 1 POIs
[DayPlanner] ⚠️ Tag 4 = ~780km Display, kann nicht weiter gesplittet werden (1 POIs)
```

---

## Fix 3: generateEuroTrip() 3-fach Post-Validierung

### Problem
Die Post-Validierung in `generateEuroTrip()` fuehrte nur einen einzigen Re-Split-Versuch durch. Bei hartnaekcigen Faellen (viele weit verteilte POIs) konnte ein Re-Split neue Tage erzeugen, die selbst wieder >700km waren.

### Loesung
Schleife mit bis zu 3 Versuchen:

```dart
for (int resplitAttempt = 0; resplitAttempt < 3; resplitAttempt++) {
  bool anyOverLimit = false;
  for (final day in tripDays) {
    if (day.distanceKm != null) {
      final displayKm = day.distanceKm! * TripConstants.haversineToDisplayFactor;
      if (displayKm > TripConstants.maxDisplayKmPerDay) {
        anyOverLimit = true;
        break;
      }
    }
  }
  if (!anyOverLimit) break;

  tripDays = _dayPlanner.planDays(
    pois: optimizedPOIs,
    startLocation: startLocation,
    days: actualDays + 1,
    returnToStart: !hasDestination,
  );
  actualDays = tripDays.length;
}
```

---

## Geaenderte Dateien

| Datei | Aenderung |
|-------|-----------|
| `lib/data/models/trip.dart` | `getDistanceForDay()`: Outgoing-Segment entfernt, `route.start` → `route.end` fuer letzten Tag |
| `lib/core/algorithms/day_planner.dart` | Neue `_splitOverlimitDays()` Methode + Safety-Logging bei Incoming-Segment >700km |
| `lib/data/repositories/trip_generator_repo.dart` | Post-Validierung als 3-fach Schleife statt einmaliger Check |

---

## Validierung
- `flutter analyze`: Keine neuen Fehler (8 vorbestehende Warnungen)
