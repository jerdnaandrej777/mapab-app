# Changelog v1.5.7

**Datum:** 2026-01-26

## Mehrtägige Euro Trips mit tagesweisem Google Maps Export

Diese Version führt ein komplett überarbeitetes Euro Trip System ein, das mehrtägige Reisen mit dem Google Maps Waypoint-Limit von 9 Stops pro Tag kompatibel macht.

### Neue Features

#### Automatische Tagesberechnung
- **600km = 1 Tag**: Die Anzahl der Reisetage wird automatisch aus dem gewählten Radius berechnet
- Formel: `Tage = ceil(Radius / 600km)`, z.B. 1800km = 3 Tage
- Maximum: 14 Tage

#### Google Maps Waypoint-Limit
- **Max 9 POIs pro Tag**: Jeder Tag enthält maximal 9 Stops (Google Maps Limit)
- Überzählige POIs werden automatisch auf den nächsten Tag verschoben
- Warnungs-Anzeige wenn ein Tag das Limit überschreiten würde

#### Tagesweiser Export
- **DayTabSelector**: Neue horizontale Tab-Leiste zur Auswahl des Tages
- Zeigt Anzahl Stops pro Tag
- Checkmark-Icon für bereits exportierte Tage
- Warnung bei Tagen mit > 9 Stops

#### Tagesweiser Google Maps Export
- "Tag X in Google Maps" Button exportiert nur den ausgewählten Tag
- **Start**: Tag 1 = Trip-Start, ab Tag 2 = letzter Stop vom Vortag
- **Waypoints**: Alle Stops des ausgewählten Tages (max 9)
- **Ziel**: Letzter Tag = Trip-Start, sonst erster Stop vom Folgetag
- Exportierte Tage werden automatisch als "abgeschlossen" markiert

### Geänderte Komponenten

#### TripConstants (NEU)
```dart
class TripConstants {
  static const int maxPoisPerDay = 9;      // Google Maps Limit
  static const double kmPerDay = 600.0;    // 600km = 1 Tag
  static const int minDays = 1;
  static const int maxDays = 14;
}
```

#### Trip Model
Neue Helper-Methoden:
- `getStopsForDay(int dayNumber)`: Stops für einen Tag
- `getDistanceForDay(int dayNumber)`: Distanz für einen Tag
- `actualDays`: Tatsächliche Anzahl Tage
- `isDayOverLimit(int dayNumber)`: Prüft auf Limit-Überschreitung
- `stopsPerDay`: Map mit Stops pro Tag
- `getWaypointsForDay(int dayNumber)`: Waypoints für Google Maps

#### DayPlanner
- `estimatePoisPerDay()`: Jetzt max 9 statt 8
- `calculateRecommendedRadius()`: Verwendet 600km/Tag Formel
- `calculateDaysFromRadius()`: Neue Methode
- `_clusterPOIsByGeography()`: Beachtet 9-POI-Limit pro Cluster

#### TripGeneratorRepository
- `generateEuroTrip()`: Akzeptiert jetzt `radiusKm` statt `days`
- Tage werden automatisch aus Radius berechnet

#### RandomTripState
Neue Felder:
- `selectedDay`: Aktuell ausgewählter Tag (1-basiert)
- `completedDays`: Set der exportierten Tage

Neue Helper:
- `tripDays`, `isDayCompleted()`, `stopsForSelectedDay`
- `calculatedDays`: Aus Radius berechnete Tage

#### RandomTripProvider
Neue Methoden:
- `selectDay(int dayNumber)`: Tag auswählen
- `completeDay(int dayNumber)`: Tag als exportiert markieren
- `uncompleteDay(int dayNumber)`: Export rückgängig machen

### UI-Änderungen

#### RadiusSlider
- Bei Euro Trip: Zeigt berechnete Tage an (z.B. "3 Tage (1800 km)")
- Quick-Select Buttons zeigen Tage statt km

#### DaysSelector (Komplett überarbeitet)
- Zeigt jetzt Info-Box mit berechneten Tagen
- Manuelle Tagesauswahl entfernt (automatisch aus Radius)
- Hotel-Toggle nur bei Mehrtages-Trips sichtbar

#### TripPreviewCard
- DayTabSelector bei Mehrtages-Trips
- Statistiken für ausgewählten Tag
- Stop-Liste zeigt nur Stops des ausgewählten Tages
- Angepasste Start/End-Labels je nach Tag

#### TripScreen
- Neuer "Tag X in Google Maps" Button
- Button-Farbe ändert sich für bereits exportierte Tage

### Persistenz (vorbereitet)

#### ActiveTripService (NEU)
- Speichert aktiven Trip für spätere Fortsetzung
- Speichert completedDays und selectedDay
- Hive Box: `active_trip`

### Technische Details

#### Distanz-Tabelle (Euro Trip)
| Radius | Tage | POIs gesamt |
|--------|------|-------------|
| 600 km | 1 | 4-8 |
| 1200 km | 2 | 8-16 |
| 1800 km | 3 | 12-24 |
| 2400 km | 4 | 16-32 |
| 4200 km | 7 | 28-56 |

#### Quick-Select Werte (Euro Trip)
- 1 Tag = 600 km
- 2 Tage = 1200 km
- 4 Tage = 2400 km
- 7 Tage = 4200 km

### Migration Notes

Die Signatur von `generateEuroTrip()` hat sich geändert:
```dart
// ALT
generateEuroTrip(days: 3, ...)

// NEU
generateEuroTrip(radiusKm: 1800, ...)
```

### Bekannte Einschränkungen

1. Die Persistenz für aktive Trips (ActiveTripService) ist vorbereitet, aber noch nicht in den Provider integriert
2. Die Distanz pro Tag ist eine Approximation (Gesamtdistanz / Tage)
3. Bei sehr wenigen POIs im Radius kann die tatsächliche Tagesanzahl geringer sein als berechnet

---

**Nächste Schritte:**
- ActiveTripService in RandomTripProvider integrieren
- Fortschritts-Anzeige für Mehrtages-Trips
- Route-Visualisierung pro Tag auf der Karte
