# Changelog v1.10.28 (Build 211)

Datum: 2026-02-07

## Schwerpunkt
Day-Editor Modal UX-Update fuer bessere mobile Bedienung bei langen POI-Listen.

## Highlights

### 1) Header vereinfacht
- Funktion "Route neu generieren" im Day-Editor Header entfernt.
- Fokus auf relevante Aktionen (Speichern / Veroeffentlichen).

### 2) Dynamischer Footer bei POI-Scroll
- Action-Footer klappt beim Scrollen der POI-Liste automatisch ein.
- Bei Scroll-Ende klappt der Footer automatisch wieder aus.
- Dadurch steht waehrend der Interaktion mehr Platz fuer die POI-Liste zur Verfuegung.

### 3) Moderne Motion
- Footer-Transition mit `AnimatedSwitcher` + Slide/Fade/Size.
- Dynamischer Listen-Abstand unten fuer eingeklappten/ausgeklappten Zustand.
- Smoothes Timing fuer Scroll-Stop-Reexpand.

### 4) Release-Artefakte aktualisiert
- App-Version auf `1.10.28+211`.
- QR-Downloadseiten zeigen auf `v1.10.28/app-release.apk`.
- CLAUDE-Dokumentation auf v1.10.28 erweitert.

## Wichtige Dateien
- `lib/features/trip/widgets/day_editor_overlay.dart`
- `pubspec.yaml`
- `QR-CODE-DOWNLOAD.html`
- `docs/qr-code-download.html`
- `CLAUDE.md`

## Tests
- `flutter test test/algorithms/random_poi_selector_test.dart`
