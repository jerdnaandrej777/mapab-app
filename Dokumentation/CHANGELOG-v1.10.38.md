# CHANGELOG v1.10.38

Datum: 2026-02-08
Build: 221

## Highlights
- AI Tagestrip nutzt jetzt mehrere Selektionsversuche statt nur einem Single-Pass und faengt instabile Kandidatensets robuster ab.
- Routing-Backoff ist zentralisiert und entfernt problematische Stops schrittweise, bevor ein Fehler geworfen wird.
- Single-POI-Rescue greift auf einen erweiterten Pool zu (`routingPOIs`, `constrainedPOIs`, `availablePOIs`).
- Single-Day Edit-Flow (`removePOI`, `addPOIToTrip`, `rerollPOI`) behaelt bei A->B Trips das echte Ziel statt Rundtrip-Reset.

## Technische Aenderungen
- `lib/data/repositories/trip_generator_repo.dart`
  - Neue Helper:
    - `_buildDayTripSelectionAttempts(...)`
    - `_optimizeDayTripPOIsForRoute(...)`
    - `_buildDayTripSinglePoiRescueCandidates(...)`
    - `_calculateDayTripRouteWithBackoff(...)`
    - `_resolveSingleDayEditEndPoints(...)`
  - `generateDayTrip(...)` auf Retry-basierten Routing-Flow umgestellt.
  - Verbesserte Debug-Logs pro Versuch inklusive Backoff-/Rescue-Signalen.
  - Single-Day-Rebuild fuer `removePOI(...)`, `addPOIToTrip(...)`, `rerollPOI(...)` auf echten Endpunkt korrigiert.
- `test/repositories/trip_generator_daytrip_test.dart`
  - Neue Tests:
    - Retry nach unroutbarem Erstversuch.
    - Single-POI-Rescue aus erweitertem Kandidatenpool.
    - Endpunkt-Erhalt bei Single-Day `removePOI`.
    - Endpunkt-Erhalt bei Single-Day `addPOIToTrip`.
    - Endpunkt-Erhalt bei Single-Day `rerollPOI`.

## Validierung
- `flutter test test/repositories/trip_generator_daytrip_test.dart`
- `flutter test test/algorithms/route_optimizer_test.dart test/models/trip_model_test.dart`

## Artefakte
- APK Release: `v1.10.38`
- Download: `https://github.com/jerdnaandrej777/mapab-app/releases/download/v1.10.38/app-release.apk`
