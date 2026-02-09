# CHANGELOG v1.10.43

Datum: 2026-02-09
Build: 226

## Highlights
- Favoriten-Routen zeigen jetzt im Trip-Panel dieselben Kernaktionen wie berechnete AI-Routen (`Trip bearbeiten` + `Navigation starten`).
- Im Trip-Bearbeiten-Modal wurde der Footer-Button auf `POIs hinzufügen` umbenannt.
- Das durch `POIs hinzufügen` geoeffnete Modal wurde auf das Trip-Bearbeiten-UI-Design angeglichen (Vollbild-Stil + konsistente Modal-Sprache).
- AI-Assistent wurde gegen Crash-Pfade gehaertet (Sende-Guard, Lifecycle-Sicherheit, robustere Text-Normalisierung fuer lokale Intent-Erkennung).

## Technische Aenderungen
- `lib/features/map/widgets/trip_config_panel.dart`
  - Bei aktiver Route aus Favoriten jetzt 2-Button-Aktionszeile: `Trip bearbeiten` + `Navigation starten`.
- `lib/features/trip/widgets/day_editor_overlay.dart`
  - Footer-Label auf `POIs hinzufügen`.
  - `POIs hinzufügen` oeffnet den Korridor-Browser als Bottom-Sheet-Modal.
- `lib/features/trip/widgets/corridor_browser_sheet.dart`
  - Modal visuell auf Trip-Bearbeiten-Look vereinheitlicht (Handle/Rand/Radien).
- `lib/features/ai_assistant/chat_screen.dart`
  - `_isLoading`-Guard in `_sendMessage`.
  - Zusätzliche `mounted`-Checks in Async-/Scroll-Pfaden.
  - Normalisierung inkl. Umlaut-Mapping fuer stabilere Intent-/Kategorie-Erkennung.

## Tests / Validierung
- `flutter test test/services/ai_exception_test.dart test/widgets/day_mini_map_test.dart`
- `flutter analyze` auf geaenderte Dateien ohne neue Build-blockierende Fehler.

## Artefakte
- APK Release: `v1.10.43`
- Download: `https://github.com/jerdnaandrej777/mapab-app/releases/download/v1.10.43/app-release.apk`
