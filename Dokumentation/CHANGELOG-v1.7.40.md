# CHANGELOG v1.7.40 - Tagesweise Karten-Anzeige & Export-Fixes

**Datum:** 2. Februar 2026
**Build:** 1.7.40+140

## Zusammenfassung

Bei mehrtaegigen Euro Trips zeigt die Karte jetzt nur die Route und POIs des **ausgewaehlten Tages** statt der kompletten Route. Die stoerende "Tag exportiert" Snackbar wurde entfernt. Beim Google Maps Export erscheint ein Hinweis, dass Google Maps eine eigene Route berechnet.

---

## Aenderungen

### 1. Tagesweise Routen-Anzeige auf der Karte

**Problem:** Bei Auswahl eines Tages (z.B. Tag 2) im Trip Preview zeigte die Karte immer die komplette Route aller Tage. POI-Marker waren ueber alle Tage durchnummeriert (1-20).

**Loesung:**
- POIs werden nach ausgewaehltem Tag gefiltert (`trip.getStopsForDay(selectedDay)`)
- Route-Polyline zeigt nur das Segment des ausgewaehlten Tages
- POI-Nummerierung ist pro Tag (1, 2, 3... innerhalb des Tages)
- Start-Marker zeigt ab Tag 2 den letzten Stop des Vortages

**Algorithmus:** Neue Hilfsmethoden `_extractRouteSegment()` und `_findNearestIndex()` finden die naechsten Punkte auf der Polyline zum ersten/letzten Stop des Tages und extrahieren das Teilstueck.

### 2. Snackbar "Tag X exportiert" entfernt

**Problem:** Nach Google Maps Export erschien eine Snackbar "Tag 1 exportiert" mit "Rueckgaengig" Button, die haengen blieb und nur durch Klick auf "Rueckgaengig" entfernt werden konnte.

**Loesung:** Snackbar komplett entfernt. Visuelles Feedback erfolgt ueber:
- Haekchen im DayTabSelector fuer abgeschlossene Tage
- Button-Text aendert sich zu "Tag X erneut exportieren"

### 3. Google Maps Export Hinweis

**Problem:** Benutzer erwarteten, dass die Google Maps Route 1:1 der In-App-Route entspricht.

**Loesung:** Hinweistext "Google Maps berechnet eine eigene Route durch die Stops" unter dem Export-Button. Dies ist eine fundamentale Einschraenkung der Google Maps URL API - die Waypoints werden korrekt uebergeben, aber Google Maps berechnet immer eine eigene Route.

---

## Geaenderte Dateien

| Datei | Aenderungen |
|-------|-------------|
| `lib/features/map/widgets/map_view.dart` | POI-Filterung nach Tag, Route-Segment-Extraktion, Start-Marker pro Tag, 2 neue Hilfsmethoden |
| `lib/features/trip/trip_screen.dart` | Snackbar entfernt, Hinweistext bei Export hinzugefuegt |

---

## Neue Methoden (map_view.dart)

```dart
/// Extrahiert das Polyline-Segment zwischen zwei Punkten
List<LatLng> _extractRouteSegment(List<LatLng> fullCoordinates, LatLng startPoint, LatLng endPoint)

/// Findet den Index des naechsten Punktes auf der Polyline
int _findNearestIndex(List<LatLng> coords, LatLng target)
```

---

## Verifikation

1. Euro Trip (3+ Tage) generieren
2. Tag 1 auswaehlen → Karte zeigt nur Tag-1-Route und Tag-1-POIs (nummeriert 1, 2, 3...)
3. Tag 2 auswaehlen → Karte zeigt nur Tag-2-Route und Tag-2-POIs
4. Start-Marker bei Tag 2 liegt auf dem letzten Stop von Tag 1
5. Tag exportieren → keine Snackbar erscheint, Haekchen im Tab sichtbar
6. Hinweistext unter Export-Button lesbar
7. Eintages-Trip testen → Karte zeigt weiterhin komplette Route (Regression-Test)
