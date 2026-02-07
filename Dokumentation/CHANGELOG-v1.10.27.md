# Changelog v1.10.27 (Build 210)

Datum: 2026-02-07

## Schwerpunkt
EuroTrip Routing-Stabilisierung bei sporadischen OSRM-400 Fehlern sowie strictere Korridorlogik entlang der direkten Start-Ziel-Route.

## Highlights

### 1) OSRM 400 robust abgefangen
- `RoutingRepository.calculateFastRoute()` sanitiziert Waypoints (ungueltige/duplizierte Punkte werden entfernt).
- Bei zu vielen Waypoints wird automatisch gedownsampelt.
- Bei HTTP 400 wird automatisch auf segmentierte Routing-Berechnung (Leg-fuer-Leg) gewechselt statt Trip-Abbruch.
- Fehlermeldungen enthalten nun Status/Serverdetails fuer bessere Diagnose.

### 2) Umweg-Logik korrigiert (nur entlang direkter Route)
- Korridor-POIs werden nicht mehr nur per Bounding-Box zugelassen.
- Neue harte Filterung nach tatsaechlicher Distanz zur direkten Route (`closestPointOnRoute <= bufferKm`).
- POI-Auswahl erzwingt Vorwaerts-Progress Richtung Ziel und verhindert Rueckspruenge.

### 3) Release-Artefakte aktualisiert
- App-Version auf `1.10.27+210`.
- QR-Downloadseiten zeigen auf `v1.10.27/app-release.apk`.
- CLAUDE-Dokumentation auf v1.10.27 erweitert.

## Wichtige Dateien
- `lib/data/repositories/routing_repo.dart`
- `lib/data/repositories/trip_generator_repo.dart`
- `lib/core/algorithms/random_poi_selector.dart`
- `test/algorithms/random_poi_selector_test.dart`
- `pubspec.yaml`
- `QR-CODE-DOWNLOAD.html`
- `docs/qr-code-download.html`
- `CLAUDE.md`

## Tests
- `flutter test test/algorithms/random_poi_selector_test.dart test/algorithms/day_planner_test.dart`
