# CHANGELOG v1.7.30 - GPS Auto-Detect & 600 km Tagesausflug-Limit & Export-Meldung entfernt

**Datum:** 01. Februar 2026
**Build:** 130
**Typ:** Feature & UX-Verbesserung
**Plattformen:** Android, iOS, Desktop

## Neue Features

### 1. Automatische GPS-Standort-Erkennung
- **Proaktive Erkennung**: Beim Öffnen des AI Trip Panels wird automatisch der GPS-Standort ermittelt
- **Intelligente Berechtigungsprüfung**:
  - GPS aktiv + Berechtigung erteilt → Standort wird direkt ermittelt (kein Dialog)
  - GPS aktiv + keine Berechtigung → System-Berechtigungs-Dialog wird angezeigt
  - GPS deaktiviert → Kein Dialog beim Panel-Öffnen (erst bei "Überrasch mich!")
- **Schnell-Modus Auto-Start**: Beim Map-Start wird der GPS-Standort auch als Startadresse im Schnell-Modus gesetzt
- **Neue Methode**: `tryAutoDetectLocation()` im `RandomTripNotifier` - silent GPS mit 5s Timeout
- **Race-Condition-Guard**: Wenn der User während der GPS-Erkennung manuell eine Adresse eingibt, wird die GPS-Erkennung abgebrochen

### 2. 600 km Tagesausflug-Limit
- **Routendistanz-Validierung**: Nach der OSRM-Routenberechnung wird geprüft, ob die Gesamtdistanz 600 km überschreitet
- **Automatische POI-Reduktion**: Bei Überschreitung wird iterativ der POI mit dem größten Umweg entfernt
- **Umweg-Algorithmus**: `_removeHighestDetourPOI()` berechnet per Luftlinie, welcher POI den größten Umweg verursacht
- **Warnung**: Wenn die Route trotz Reduktion (min. 2 POIs) > 600 km bleibt, wird eine SnackBar-Warnung angezeigt
- **Nur Tagesausflug**: Euro Trips sind nicht betroffen (haben eigene Tagesberechnung)

### 3. Export-Meldung entfernt
- **SnackBar "Tag X exportiert" entfernt**: Nach dem Google Maps Export erscheint kein Hinweis mehr
- **"Rückgängig"-Button entfernt**: `uncompleteDay()` wird nicht mehr über die UI angeboten
- **completeDay() bleibt aktiv**: Tag wird weiterhin korrekt als abgeschlossen markiert (Hive-Persistenz)

## Technische Details

### Neue/Geänderte Dateien

| Datei | Änderung |
|-------|----------|
| `lib/features/random_trip/providers/random_trip_provider.dart` | + `tryAutoDetectLocation()`, + `distanceWarning` Logik, + TripConstants Import |
| `lib/features/map/map_screen.dart` | + `_AITripPanel.initState()` + `_tryAutoDetectGPS()`, + Auto-Start in `_centerOnCurrentLocationSilent()`, + SnackBar für distanceWarning |
| `lib/features/trip/trip_screen.dart` | - SnackBar "Tag X exportiert" mit "Rückgängig"-Button entfernt |
| `lib/features/random_trip/providers/random_trip_state.dart` | + `distanceWarning` Feld (Freezed) |
| `lib/data/repositories/trip_generator_repo.dart` | + Distanz-Validierung in `generateDayTrip()`, + `_removeHighestDetourPOI()` Helper |
| `lib/core/constants/trip_constants.dart` | + `maxDayTripDistanceKm = 600.0` Konstante |

### GPS Auto-Detect Flow

```
AI Trip Panel öffnet
    ↓
initState() → _tryAutoDetectGPS()
    ↓
tryAutoDetectLocation() [silent, keine Dialoge]
    ↓
├── Services aktiv + Berechtigung OK → Position ermitteln → Startpunkt setzen
├── Services aktiv + Berechtigung fehlt → requestPermission() → nochmal versuchen
└── Services deaktiviert → nichts tun (Dialog erst bei Generate-Klick)
```

### 600 km Validierungs-Flow

```
generateDayTrip()
    ↓
OSRM Route berechnen
    ↓
route.distanceKm > 600?
    ↓
├── Ja → POI mit größtem Umweg entfernen → Route neu berechnen → Wiederholen
│         (bis < 600 km oder nur noch 2 POIs)
└── Nein → Trip erstellen
```

### Neue Konstante

```dart
// lib/core/constants/trip_constants.dart
static const double maxDayTripDistanceKm = 600.0;
```

### Neues State-Feld

```dart
// lib/features/random_trip/providers/random_trip_state.dart
String? distanceWarning,  // Warnung bei reduzierter Route
```

## Kompatibilität

- Keine Breaking Changes
- Bestehende Trips bleiben erhalten
- Euro Trip Persistenz (v1.7.28) funktioniert weiterhin

---

**Status:** Abgeschlossen
**Review:** Pending
**Deploy:** Pending
