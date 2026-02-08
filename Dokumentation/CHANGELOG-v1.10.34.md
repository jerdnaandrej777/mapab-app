# CHANGELOG v1.10.34

Datum: 2026-02-08
Build: 217

## Highlights
- AI Tagestrip: deutlich robustere POI-Erkennung mit mehrstufigen Fallbacks.
- Routenbau: stabilerer Abschluss durch Routing-Safety-Fallback (1-POI-Rescue).
- Loading UX: Fortschrittsanzeige laeuft sichtbar von 1% bis 100%.
- UI-Konsistenz: Lade-Widget auf gleicher Hoehe wie das AI-Tagestrip-Panel.

## Technische Aenderungen
- `lib/data/repositories/trip_generator_repo.dart`
  - Neue Daytrip-POI-Fallback-Kaskade (`_loadDayTripPOIsWithFallbacks`).
  - Endpoint-Radius-Fallback bei leerem Korridor (`_loadPOIsNearDayTripEndpoints`).
  - Fallback-POI-Auswahl (`_fallbackSelectPOIsForDayTrip`).
  - Routing-Safety-Fallback fuer instabile Waypoint-Sets.
- `lib/features/random_trip/providers/random_trip_provider.dart`
  - Kontinuierlicher Progress-Ticker mit phasenbasierten Obergrenzen.
  - Sauberes Start/Stop/Reset des Fortschritts in allen Erfolgs-/Fehlerpfaden.
- `lib/features/random_trip/widgets/generation_progress_indicator.dart`
  - Neuer `panelMode`, damit dieselbe Lade-Card in Panel-Layout nutzbar ist.
- `lib/features/map/map_screen.dart`
  - Generierungs-Overlay von Vollbild auf Panel-Position umgestellt.
- `test/repositories/trip_generator_daytrip_test.dart`
  - Regressionstest fuer Endpoint-Radius-Fallback hinzugefuegt.

## Artefakte
- APK Release: `v1.10.34`
- Download: `https://github.com/jerdnaandrej777/mapab-app/releases/download/v1.10.34/app-release.apk`
