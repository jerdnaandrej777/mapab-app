# CHANGELOG v1.10.41

Datum: 2026-02-08
Build: 224

## Highlights
- Trip-Bearbeiten Footer auf zwei Hauptaktionen vereinfacht: `Weitere POIs hinzufügen` + `Fertig`.
- Neuer `Fertig`-Modal mit Übersichtskarte der aktuellen Route und den Kernmetriken (Stops, Distanz, Fahrzeit, Wetter).
- Aktionen wurden in den Übersichts-Modal verlagert: `Navigation starten`, `Route speichern` (Favoriten), `Veröffentlichen`, Google-Maps Export.
- Google-Maps-Button ist jetzt kontextsensitiv benannt: `Tagestrip in Google Maps` bei Tagestrip, `Tag in Google Maps` bei AI Euro Trip.

## Technische Aenderungen
- `lib/features/trip/widgets/day_editor_overlay.dart`
  - Footer-Layout im Edit-Modal auf 2 Buttons reduziert.
  - Neuer Ablauf `_showFinishOverviewModal(...)` mit Draggable Bottom Sheet.
  - Bestehende Save-/Publish-Callbacks im neuen Abschluss-Modal angebunden.
  - Modusabhängige Label-Logik für den Google-Maps-Button ergänzt.

## Tests / Validierung
- `flutter analyze lib/features/trip/widgets/day_editor_overlay.dart` (keine build-blockierenden Fehler)
- `flutter test test/widgets/day_mini_map_test.dart`

## Artefakte
- APK Release: `v1.10.41`
- Download: `https://github.com/jerdnaandrej777/mapab-app/releases/download/v1.10.41/app-release.apk`
