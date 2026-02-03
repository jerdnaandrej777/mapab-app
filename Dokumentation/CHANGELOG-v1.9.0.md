# CHANGELOG v1.9.0 - OSRM In-App Navigation mit Turn-by-Turn, GPS-Tracking & TTS

**Datum:** 3. Februar 2026
**Build:** 1.9.0+146

## Zusammenfassung

Vollwertige **In-App Turn-by-Turn Navigation** basierend auf OSRM mit kontinuierlichem GPS-Tracking, deutschen Sprachansagen (TTS), automatischem Rerouting bei Abweichung und POI-Waypoint-Erkennung. Kein externer Navigations-SDK noetig — alles Open Source.

---

## Feature 1: OSRM Navigation mit Abbiegehinweisen

### Beschreibung
Die bestehende OSRM-Integration wurde um `steps=true&annotations=distance,duration` erweitert. Das liefert detaillierte Manoever-Daten (Typ, Modifier, Strassenname, Bearing) fuer jeden Abbiegehinweis.

### Neue Dateien

**`lib/data/models/navigation_step.dart`** — Freezed-Datenmodelle:
- `NavigationStep`: Location, Distanz, Dauer, Instruktion, Bearing, Geometry
- `NavigationLeg`: Steps pro Routenabschnitt (Start→Waypoint→Ziel)
- `NavigationRoute`: Wrapper um AppRoute + Legs mit Helper-Methoden
- `ManeuverType`: 16 OSRM-Typen (turn, roundabout, merge, fork, onRamp, offRamp, etc.)
- `ManeuverModifier`: 8 Richtungen (left, right, sharpLeft, slightRight, uturn, straight, etc.)

**`lib/core/utils/navigation_instruction_generator.dart`** — Deutsche Instruktionen:
- `generate()`: "Rechts abbiegen auf Hauptstrasse"
- `generateShort()`: "Rechts" (fuer unmittelbare Ansagen)
- `generateWithDistance()`: "In 200 Metern rechts abbiegen"
- Kreisverkehr: "Im Kreisverkehr die zweite Ausfahrt nehmen"
- Auffahrt/Abfahrt: "Auf die Autobahn auffahren"

### Geaenderte Datei

**`lib/data/repositories/routing_repo.dart`** — Neue Methode `calculateNavigationRoute()`:
- OSRM-Request mit `steps=true&annotations=distance,duration`
- Parst `legs[].steps[].maneuver` → `NavigationStep`
- Generiert deutsche Instruktionen via `NavigationInstructionGenerator`
- Bestehende `calculateFastRoute()` bleibt unveraendert

---

## Feature 2: GPS-Tracking & Route-Matching

### Beschreibung
Kontinuierlicher GPS-Position-Stream mit Snap-to-Road, Off-Route-Erkennung und automatischem Rerouting.

### Neue Dateien

**`lib/features/navigation/services/route_matcher_service.dart`** — Snap-to-Road:
- `snapToRoute()` → `RouteMatchResult` (snappedPosition, nearestIndex, distanceFromRoute, progress)
- `isOffRoute()` mit konfigurierbarem Schwellwert (default 75m)
- `getDistanceAlongRoute()`, `getRemainingDistance()`
- `calculateBearing()` fuer Heading-Berechnung
- `distanceBetween()` (Haversine, public)
- Punkt-auf-Segment-Projektion fuer praezises Snapping

**`lib/features/navigation/providers/navigation_provider.dart`** — Kern-State-Machine:
- `NavigationStatus`: idle, loading, navigating, rerouting, arrivedAtWaypoint, arrivedAtDestination, error
- `NavigationState`: Position, Heading, Speed, currentStep, nextStep, Distanzen, ETA, POI-Tracking, Mute
- `startNavigation()`: NavigationRoute berechnen, GPS-Stream starten
- `_onPositionUpdate()`: Pro GPS-Tick: Snap, Step finden, Distanzen, POI-Naehe, Off-Route pruefen
- `_reroute()`: Neue Route ab aktueller Position mit verbleibenden Waypoints
- `stopNavigation()`, `toggleMute()`, `markStopVisited()`

**Schwellwerte:**
| Parameter | Wert |
|-----------|------|
| Off-Route | 75m |
| Waypoint erreicht | 50m |
| POI-Annaeherung | 500m |
| POI erreicht | 80m |
| Reroute-Debounce | 5000ms |
| GPS-Distanzfilter | 10m |
| Ankunft-Progress | 98% |

---

## Feature 3: TTS-Sprachansagen (Deutsch)

### Beschreibung
Automatische deutsche Sprachansagen basierend auf Distanz-Schwellen, mit Duplikat-Schutz und Mute-Option.

### Neue Datei

**`lib/features/navigation/providers/navigation_tts_provider.dart`**:
- 3 Distanz-Schwellen: far (500m), near (200m), immediate (50m)
- Manoever-Ansagen: "In 500 Metern rechts abbiegen auf Hauptstrasse"
- Rerouting: "Route wird neu berechnet"
- POI-Annaeherung (<300m): "In 200 Metern erreichen Sie [POI-Name]"
- POI erreicht: "[POI-Name] erreicht"
- Ziel erreicht: "Sie haben Ihr Ziel erreicht"
- Duplikat-Schutz pro Step + Level

### Geaenderte Datei

**`lib/data/services/voice_service.dart`** — 4 neue Methoden:
- `speakManeuver(instruction, distanceMeters)`
- `speakRerouting()`
- `speakPOIApproaching(poiName, distanceMeters)`
- `speakArrived(destinationName)`

---

## Feature 4: Vollbild-Navigation-UI

### Neue Dateien

**`lib/features/navigation/navigation_screen.dart`** — Haupt-Screen:
- FlutterMap mit Heading-Rotation (Karte dreht in Fahrtrichtung)
- Nutzer-Position als rotierender Navigations-Pfeil
- Route-Split: gefahrener Teil grau, verbleibend farbig
- POI-Marker: gruen (unbesucht) / grau (besucht) mit Check-Icon
- Ziel-Marker als roter Flag
- Rerouting-Overlay: "Route wird neu berechnet..."
- Loading-Overlay: "Navigation wird vorbereitet..."
- Uebersichts-Modus: Gesamte Route anzeigen vs. GPS-Tracking

**`lib/features/navigation/widgets/maneuver_banner.dart`** — Oberes Banner:
- Grosses Manoever-Icon (Material Icons: turn_right, u_turn, rotate_right, etc.)
- Distanz zum naechsten Manoever (gerundet auf 50m-Schritte)
- Instruktionstext (max 2 Zeilen)

**`lib/features/navigation/widgets/navigation_bottom_bar.dart`** — Untere Leiste:
- 3 Info-Items: Verbleibende Distanz, ETA (Uhrzeit), Aktuelle Geschwindigkeit
- 3 Buttons: Mute/Unmute, Uebersicht, Beenden (rot)
- SafeArea-Support

**`lib/features/navigation/widgets/poi_approach_card.dart`** — POI-Card:
- Erscheint bei POI-Waypoint < 500m
- Kategorie-Icon (15 Kategorien gemappt)
- POI-Name + formatierte Distanz
- "Besucht" Button + optional "Ueberspringen"

### Geaenderte Dateien

**`lib/app.dart`** — Neue GoRoute:
```
/navigation → NavigationScreen (route + stops als Extra)
```

**`lib/features/trip/trip_screen.dart`** — Neuer Button in beiden Modi:
- **Normale Route** (`_buildTripContent`): "Navigation starten" FilledButton.icon vor Google Maps Zeile, uebergibt `route` + `TripStop.fromPOI()` Stops
- **AI Trip Preview** (`_buildAITripPreview`): "Navigation starten" FilledButton.icon zwischen "POIs entlang der Route" und tagesweisem Export, uebergibt `trip.route` + `trip.stops` direkt

**`lib/features/map/map_screen.dart`** — "Navigation starten" auf MapScreen:
- `_TripInfoBar` um `onStartNavigation` Callback erweitert
- OutlinedButton "Navigation starten" unter "Trip bearbeiten" in der Post-Generierungs-Leiste
- Direkter Einstieg in Navigation vom MapScreen ohne Umweg ueber TripScreen

**`lib/features/trip/widgets/day_editor_overlay.dart`** — "Navigation starten" im DayEditor:
- Neuer IconButton in `_BottomActions` zwischen "POIs entdecken" und "Tag in Google Maps"
- `_startDayNavigation()`: Tagesspezifische Navigation mit korrektem Start/Ziel pro Tag
- Tag 1: Start = Trip-Startort, ab Tag 2: Start = letzter Stop vom Vortag
- Letzter Tag: Ziel = Trip-Startort (Rueckfahrt), sonst erster Stop vom Folgetag
- Erstellt tagesspezifische AppRoute → OSRM berechnet echte Turn-by-Turn Route
- Schliesst Overlay und oeffnet NavigationScreen

---

## Feature 5: Android-Berechtigungen

### Geaenderte Datei

**`android/app/src/main/AndroidManifest.xml`** — 3 neue Permissions:
```xml
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />
```

---

## Alle neuen Dateien (11)

| # | Datei | Beschreibung |
|---|-------|-----------|
| 1 | `lib/data/models/navigation_step.dart` | Freezed: NavigationStep, Leg, Route, Enums |
| 2 | `lib/data/models/navigation_step.freezed.dart` | Generiert (build_runner) |
| 3 | `lib/data/models/navigation_step.g.dart` | Generiert (build_runner) |
| 4 | `lib/core/utils/navigation_instruction_generator.dart` | OSRM → Deutsche Instruktionen |
| 5 | `lib/features/navigation/services/route_matcher_service.dart` | Snap-to-Road + Haversine |
| 6 | `lib/features/navigation/providers/navigation_provider.dart` | GPS-Stream + State Machine |
| 7 | `lib/features/navigation/providers/navigation_provider.g.dart` | Generiert (build_runner) |
| 8 | `lib/features/navigation/providers/navigation_tts_provider.dart` | TTS-Ansagen-Steuerung |
| 9 | `lib/features/navigation/providers/navigation_tts_provider.g.dart` | Generiert (build_runner) |
| 10 | `lib/features/navigation/navigation_screen.dart` | Vollbild-Navigation-UI |
| 11 | `lib/features/navigation/widgets/maneuver_banner.dart` | Manoever-Banner (oben) |
| 12 | `lib/features/navigation/widgets/navigation_bottom_bar.dart` | ETA/Distanz/Controls (unten) |
| 13 | `lib/features/navigation/widgets/poi_approach_card.dart` | POI-Annaeherungs-Card |

## Alle geaenderten Dateien (7)

| # | Datei | Aenderung |
|---|-------|-----------|
| 1 | `lib/data/repositories/routing_repo.dart` | `calculateNavigationRoute()` mit steps=true |
| 2 | `lib/data/services/voice_service.dart` | 4 neue speakX() Methoden |
| 3 | `lib/app.dart` | GoRoute `/navigation` |
| 4 | `lib/features/trip/trip_screen.dart` | "Navigation starten" Button |
| 5 | `lib/features/map/map_screen.dart` | "Navigation starten" in TripInfoBar |
| 6 | `lib/features/trip/widgets/day_editor_overlay.dart` | "Navigation starten" im DayEditor (tagesspezifisch) |
| 7 | `android/app/src/main/AndroidManifest.xml` | Background Location + Foreground Service |

---

## Verifizierung

1. **Build Runner**: `flutter pub run build_runner build` → 30 Outputs, 0 Fehler
2. **Flutter Analyze**: 0 neue Fehler durch Navigation-Code
3. **OSRM API**: `steps=true` liefert Manoever-Daten korrekt
4. **GPS-Test**: Auf echtem Geraet (Emulator unzuverlaessig)
5. **TTS-Test**: Deutsche Ansagen mit flutter_tts 4.0.2
6. **UI-Test**: Dark Mode, verschiedene Bildschirmgroessen
7. **Rerouting-Test**: >75m von Route abweichen → automatische Neuberechnung

---

## Naechste Schritte (Phase 5 - noch nicht implementiert)

- Hintergrund-Navigation mit Android Foreground Service
- ~~Mehrtages-Trip Integration (Navigation pro Tag)~~ ✅ Implementiert: DayEditorOverlay mit tagesspezifischer Navigation
- Sprachbefehle via VoiceService.listen() + parseCommand()
