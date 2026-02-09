# CHANGELOG v1.10.42

Datum: 2026-02-09
Build: 225

## Highlights
- AI-Assistent erkennt Restaurant-Anfragen zuverlaessiger und zeigt lokale Ergebnisse anhand des aktuellen Standorts.
- AI-POI-Karten haben jetzt eine direkte Aktion `Zur Route` fuer aktive oder neue Routenplanung.
- Chat erkennt Route/Trip-Planungsintents und oeffnet direkt den Routen-Generator.
- Bottom-up Modale in den betroffenen Flows wurden auf den POI-Kategorien-Standard (`1.0 / 0.9 / 1.0`) vereinheitlicht.

## Technische Aenderungen
- `lib/features/ai_assistant/chat_screen.dart`
  - Neue Intent-Helfer fuer Restaurant- und Route-Erkennung.
  - Restaurant-Fallback bei leeren Kategorie-Treffern.
  - Neue Chat-POI-Aktion `Zur Route` mit `addStopWithAutoRoute(...)`.
- `lib/features/trip/widgets/day_editor_overlay.dart`
  - Fertig-Uebersicht als Bottom Sheet auf Vollhoehenvertrag umgestellt.
- `lib/features/trip/widgets/corridor_browser_sheet.dart`
  - Draggable Bottom Sheet auf denselben Hoehenvertrag angeglichen.
- `lib/features/social/trip_detail_public_screen.dart`
  - Share-Bottom-Sheet auf denselben Hoehenvertrag angeglichen.

## Tests / Validierung
- `flutter test test/services/ai_exception_test.dart test/widgets/day_mini_map_test.dart`
- `flutter analyze` auf geaenderte Dateien ohne neue Build-blockierende Fehler.

## Artefakte
- APK Release: `v1.10.42`
- Download: `https://github.com/jerdnaandrej777/mapab-app/releases/download/v1.10.42/app-release.apk`
