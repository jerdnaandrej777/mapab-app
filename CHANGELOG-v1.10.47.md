# CHANGELOG v1.10.47

Datum: 2026-02-09
Build: 230

## Highlights
- Tagesrouten-Segment im Day-Editor ist bei Rundreisen/letztem Tag stabilisiert und folgt wieder korrekt den Tages-POIs.
- POI-Deduplizierung wurde von rein ID-basiert auf semantisch + geographisch erweitert.
- Ladeanimationen fuer AI Tagestrip und Euro Trip getrennt und beruhigt; Progress bleibt strikt 1% bis 100%.
- CI-Gates erweitert (`flutter test`, `flutter analyze`, Backend Typecheck + Lint).

## Technische Aenderungen
- `lib/features/trip/widgets/day_mini_map.dart`
  - Neue Wegpunkt-basierte Segment-Extraktion mit vorwaerts laufender Index-Suche.
- `lib/features/trip/widgets/day_editor_overlay.dart`
  - Day-Editor und Abschluss-Uebersicht extrahieren Tagessegmente jetzt ueber geordnete Wegpunkte.
- `lib/data/repositories/trip_generator_repo.dart`
  - Neue semantische POI-Deduplizierung (ID/Wikidata/Name+Distanz) und Integration in Auswahl-/Edit-Flows.
- `lib/features/random_trip/providers/random_trip_provider.dart`
  - Progress-Flow gehaertet, damit Ladeanzeige kontrolliert bei 1 beginnt und bei 100 endet.
- `lib/features/random_trip/widgets/generation_progress_indicator.dart`
  - Animations-Redesign mit getrennten Visuals fuer Tagestrip und Euro Trip.
- `.github/workflows/ci.yml`
  - Neuer CI-Workflow fuer Flutter + Backend.

## Tests / Validierung
- `flutter test` (komplette Suite)
- Neue Tests:
  - `test/widgets/day_mini_map_test.dart`
  - `test/repositories/trip_generator_daytrip_test.dart`

## Artefakte
- APK Release: `v1.10.47`
- Download: `https://github.com/jerdnaandrej777/mapab-app/releases/download/v1.10.47/app-release.apk`
