# CHANGELOG v1.8.3 - Tag-Editor Fix: Folgetage bleiben bei POI-Aenderungen erhalten

**Datum:** 3. Februar 2026
**Build:** 1.8.3+145

## Zusammenfassung

Kritischer Fix fuer die **Tag-weise POI-Bearbeitung bei Mehrtages-Trips**: Wenn ein POI an einem bestimmten Tag per Reroll oder Delete geaendert wird, bleiben jetzt **alle anderen Tage vollstaendig erhalten**. Vorher wurden alle POIs global neu optimiert und auf Tage verteilt, was die gesamte Tagesstruktur zerstoerte.

---

## Fix 1: POI Reroll/Delete aendert nur den betroffenen Tag (KRITISCH)

### Problem
Bei einem mehrtaegigen Euro Trip (z.B. 3 Tage, 15+ POIs) fuehrte das Aendern eines einzelnen POIs dazu, dass:
- POIs zwischen Tagen verschoben wurden (Tag 1-POI landete auf Tag 3)
- Die Tagesstruktur komplett neu berechnet wurde
- Start-/Endpunkte der Folgetage nicht mehr stimmten
- Der Nutzer seine kuratierte Tagesplanung verlor

### Ursache
In `trip_generator_repo.dart` wurden bei `removePOI()` und `rerollPOI()` **alle POIs global** re-optimiert und dann via `_dayPlanner.planDays()` **alle Tage neu verteilt**:

```dart
// VORHER (fehlerhaft):
final optimizedPOIs = _routeOptimizer.optimizeRoute(
  pois: newSelectedPOIs,      // ALLE POIs (nicht nur betroffener Tag)
  startLocation: startLocation,
  returnToStart: true,
);
// Dann: planDays() verteilt ALLE POIs neu auf Tage
final tripDays = _dayPlanner.planDays(
  pois: optimizedPOIs,
  startLocation: startLocation,
  days: days,
);
```

### Loesung
Neue tag-beschraenkte Methoden in **`lib/data/repositories/trip_generator_repo.dart`**:

**Multi-Day Routing (days > 1):**
1. Tag des betroffenen POIs ermitteln
2. Nur die Stops dieses Tages modifizieren
3. Start-Punkt des Tages berechnen (letzter Stop vom Vortag)
4. Nur diesen Tag re-optimieren via `_routeOptimizer.optimizeRoute()`
5. Alle Stops zusammenfuehren (unveraenderte Tage + modifizierter Tag)
6. OSRM-Route neu berechnen

**Single-Day:** Bestehendes Verhalten beibehalten (globale Re-Optimierung).

#### Neue Methoden

**`_removePOIFromDay()`** — Entfernt POI nur aus dem betroffenen Tag:
```dart
Future<GeneratedTrip> _removePOIFromDay({
  required GeneratedTrip currentTrip,
  required String poiIdToRemove,
  required LatLng startLocation,
  required String startAddress,
}) async {
  final stopToRemove = currentTrip.trip.stops.firstWhere(
    (s) => s.poiId == poiIdToRemove,
  );
  final targetDay = stopToRemove.day;

  // Andere Tage unverändert beibehalten
  final otherDaysStops = currentTrip.trip.stops
      .where((s) => s.day != targetDay)
      .toList();

  // Nur diesen Tag modifizieren und re-optimieren
  final modifiedDayPOIs = dayStops
      .where((s) => s.poiId != poiIdToRemove)
      .map((s) => s.toPOI())
      .toList();

  final optimizedDayPOIs = _routeOptimizer.optimizeRoute(
    pois: modifiedDayPOIs,
    startLocation: dayStart,
    returnToStart: false,
  );

  // Zusammenfuehren und OSRM-Route neu berechnen
  return _rebuildRouteForDayEdit(
    allStops: [...otherDaysStops, ...newDayStops],
    ...
  );
}
```

**`_rerollPOIForDay()`** — Ersetzt POI nur innerhalb des betroffenen Tages:
- Nachbar-Positionen innerhalb des Tages (nicht global) fuer Distanz-Beschraenkung
- Bis zu 3 Versuche mit Distanz-Validierung pro Tag
- `nextLocation` beruecksichtigt den ersten Stop des Folgetages

**`_rebuildRouteForDayEdit()`** — Gemeinsamer Rebuild fuer beide Operationen:
- Sortiert alle Stops nach Tag + Order
- Berechnet OSRM-Route mit Waypoints in Tag-Reihenfolge
- Rekonstruiert `selectedPOIs` aus geordneten Stops

**`_getDayStartLocation()`** — Bestimmt den Start-Punkt eines Tages:
```dart
LatLng _getDayStartLocation(Trip trip, int day, LatLng tripStart) {
  if (day == 1) return tripStart;
  final prevStops = trip.getStopsForDay(day - 1);
  return prevStops.isNotEmpty ? prevStops.last.location : tripStart;
}
```

### Auswirkung
- Reroll/Delete auf Tag 1 → Tag 2 und 3 POIs bleiben identisch
- Tagesverbindungen (Start Tag N+1 = Ende Tag N) bleiben korrekt
- Nur der betroffene Tag wird re-optimiert → schnellere Bearbeitung
- Google Maps Export pro Tag bleibt konsistent

---

## Fix 2: Korrekte Tagesverbindungen nach Aenderungen

### Problem
Nach einem Reroll/Delete auf Tag 1 stimmte der Startpunkt von Tag 2 nicht mehr, weil die globale Neuverteilung die Tag-Zuordnung aenderte.

### Loesung
Da jetzt nur der betroffene Tag modifiziert wird, bleiben die Tagesverbindungen implizit korrekt:
- `trip.getStopsForDay(N-1).last.location` liefert immer den korrekten Start fuer Tag N
- Die Mini-Map im Tag-Editor zeigt das richtige Routen-Segment
- Der Google Maps Export nutzt die korrekten Start-/Endpunkte

---

## Fix 3: Schnellere Tag-Bearbeitung

### Vorher
- Alle POIs global re-optimiert (Nearest-Neighbor + 2-opt ueber alle Tage)
- `_dayPlanner.planDays()` mit Distanz-Clustering ueber alle POIs
- Mehrere Sekunden bei 20+ POIs

### Nachher
- Nur 3-9 POIs des betroffenen Tages re-optimiert
- Kein `planDays()` Aufruf noetig
- Deutlich schnellere Antwortzeit

---

## Geaenderte Dateien

| # | Datei | Aenderung |
|---|-------|-----------|
| 1 | `lib/data/repositories/trip_generator_repo.dart` | `removePOI()`: Multi-Day-Pfad delegiert an `_removePOIFromDay()` |
| 2 | `lib/data/repositories/trip_generator_repo.dart` | `rerollPOI()`: Multi-Day-Pfad delegiert an `_rerollPOIForDay()` |
| 3 | `lib/data/repositories/trip_generator_repo.dart` | Neue Methode `_removePOIFromDay()` |
| 4 | `lib/data/repositories/trip_generator_repo.dart` | Neue Methode `_rerollPOIForDay()` |
| 5 | `lib/data/repositories/trip_generator_repo.dart` | Neue Methode `_rebuildRouteForDayEdit()` |
| 6 | `lib/data/repositories/trip_generator_repo.dart` | Neue Methode `_getDayStartLocation()` |

---

## Verifizierung

1. **Mehrtaegigen Euro Trip generieren** (3+ Tage, 5+ POIs pro Tag)
2. **Tag 1 oeffnen**, einen POI reroleln → Tag 2/3 POIs muessen unveraendert sein
3. **Tag 2 oeffnen**, einen POI loeschen → Tag 1 und 3 POIs unveraendert
4. **Mini-Map pruefen**: Route-Segment fuer jeden Tag korrekt dargestellt
5. **Google Maps Export pruefen**: Start/Ziel-Adressen fuer jeden Tag konsistent
6. **Distanz-Anzeige pro Tag** plausibel
7. `flutter analyze` — keine neuen Fehler
