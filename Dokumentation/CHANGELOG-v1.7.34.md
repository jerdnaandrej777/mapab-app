# Changelog v1.7.34 - Mehrtägiger Google Maps Export Fix

**Datum:** 2. Februar 2026
**Typ:** Bug-Fix
**Plattformen:** Android, iOS, Desktop

---

## Zusammenfassung

Fix für den mehrtägigen Google Maps Export: Das `day`-Feld der TripStops ging bei POI-Entfernung, POI-Neuwürfeln und Favoriten-Speicherung verloren. Dadurch starteten Folgetage fälschlicherweise am Trip-Start statt am letzten Stop des Vortages.

---

## Änderungen

### 1. **removePOI() - Tagesplanung bei Mehrtages-Trips beibehalten**

- **Problem:** Nach dem Entfernen eines POIs aus einem Mehrtages-Trip wurden alle Stops mit `day: 1` neu erstellt
- **Ursache:** `TripStop.fromPOI(entry.value).copyWith(order: entry.key)` setzt `day` nicht (Default: 1)
- **Fix:** Bei Mehrtages-Trips (`actualDays > 1`) wird jetzt `_dayPlanner.planDays()` aufgerufen, um die Stops korrekt auf Tage zu verteilen
- **Ergebnis:** Tagesaufteilung bleibt nach POI-Entfernung erhalten

### 2. **rerollPOI() - Tagesplanung bei Mehrtages-Trips beibehalten**

- **Problem:** Identisch zu `removePOI()` - nach dem Neuwürfeln eines POIs wurden alle Stops auf Tag 1 gesetzt
- **Fix:** Gleiche Lösung wie bei `removePOI()` - `_dayPlanner.planDays()` für Mehrtages-Trips

### 3. **_saveToFavorites() - Stops mit day-Feld speichern**

- **Problem:** Beim Speichern eines AI Trips in Favoriten wurden Stops aus `selectedPOIs` (ohne `day`) statt aus `trip.stops` (mit `day`) erstellt
- **Ursache:** `generatedTrip.selectedPOIs.map((poi) => TripStop.fromPOI(poi))` erzeugt Stops mit `day: 1`
- **Fix:** Direkt `trip.stops` verwenden (die bereits korrekte `day`-Werte haben)
- **Ergebnis:** Gespeicherte Mehrtages-Trips behalten ihre Tagesaufteilung

---

## Technische Details

### Kernproblem

`TripStop.fromPOI()` setzt das `day`-Feld immer auf den Standardwert `1`:

```dart
factory TripStop.fromPOI(POI poi, {int order = 0}) {
  return TripStop(
    // ... andere Felder
    // day: fehlt → Default 1
  );
}
```

Wenn Stops nach einer Änderung komplett neu erstellt wurden, ging die Tagesaufteilung verloren. `trip.getStopsForDay(2)` gab dann eine leere Liste zurück, und der Google Maps Export für Tag 2+ startete am Trip-Start statt am letzten Stop des Vortages.

### Lösung für removePOI/rerollPOI

```dart
// Bei Mehrtages-Trips: Tagesplanung komplett wiederholen
final days = currentTrip.trip.actualDays;
List<TripStop> newStops;
if (days > 1) {
  final tripDays = _dayPlanner.planDays(
    pois: optimizedPOIs,
    startLocation: startLocation,
    days: days,
    returnToStart: true,
  );
  newStops = tripDays.expand((day) => day.stops).toList();
} else {
  // Einzeltag: Wie bisher
  newStops = optimizedPOIs.asMap().entries.map((entry) {
    return TripStop.fromPOI(entry.value).copyWith(order: entry.key);
  }).toList();
}
```

### Lösung für _saveToFavorites

```dart
// VORHER: Stops ohne day-Feld
stops: generatedTrip.selectedPOIs.map((poi) => TripStop.fromPOI(poi)).toList(),

// NACHHER: Stops direkt aus Trip (mit day-Feld)
stops: trip.stops,
```

### Betroffene Dateien

| Datei | Änderung |
|-------|----------|
| `lib/data/repositories/trip_generator_repo.dart` | `removePOI()` + `rerollPOI()` nutzen jetzt `_dayPlanner.planDays()` für Mehrtages-Trips |
| `lib/features/trip/trip_screen.dart` | `_saveToFavorites()` nutzt `trip.stops` statt `selectedPOIs` |
| `pubspec.yaml` | Version 1.7.27+127 -> 1.7.34+128 |
| `QR-CODE-DOWNLOAD.html` | Links und Version auf v1.7.34 aktualisiert |
| `CLAUDE.md` | Version, Changelog-Referenz und Fix-Dokumentation aktualisiert |

---

## Google Maps Export - Tagesweiser Ablauf

```
Tag 1: Origin = Trip-Start     → Waypoints Tag 1 → Destination = 1. Stop Tag 2
Tag 2: Origin = Letzter Stop Tag 1 → Waypoints Tag 2 → Destination = 1. Stop Tag 3
Tag 3: Origin = Letzter Stop Tag 2 → Waypoints Tag 3 → Destination = Trip-Start (Rückreise)
```

**Vorher (Bug):** Nach removePOI/rerollPOI hatten alle Stops `day: 1` → Tag 2/3 waren leer → Fallback auf Trip-Start

**Nachher (Fix):** Stops behalten korrekte `day`-Werte → Tagesweiser Export funktioniert korrekt

---

## Migration

**Keine Breaking Changes** - Rein internes Bug-Fix der Tagesplanung.

---

## Siehe auch

- [CHANGELOG-v1.7.27.md](CHANGELOG-v1.7.27.md) - POI-Foto-Optimierung & Kategorie-Modal-Fix
- [CHANGELOG-v1.5.7.md](CHANGELOG-v1.5.7.md) - Mehrtägige Euro Trips (Original-Feature)

---

**Status:** Abgeschlossen
**Review:** Pending
**Deploy:** Pending
