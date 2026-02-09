# CHANGELOG v1.10.48

Datum: 2026-02-09
Build: 231

## Highlights
- AI Assistant gegen haengende Zustande gehaertet: Timeouts und robuste Request-Finalisierung.
- Nearby-Erkennung fuer Restaurants und Hotels erweitert (Intent + Filter + Fallback).
- Vorschlags- und Demo-Texte im AI Chat von fehlerhaften Sonderzeichen bereinigt.
- Download-/Release-Dokumentation inklusive QR-Downloadseiten auf `v1.10.48` aktualisiert.

## Technische Aenderungen
- `lib/features/ai_assistant/chat_screen.dart`
  - Request-Lifecycle gehaertet (`TimeoutException`-Handling, stabile `_isLoading` Ruecksetzung, Request-Token-Finalisierung).
  - Neue Hotel-Intent-Erkennung und POI-Matcher (`_isHotelIntent`, `_matchesHotelPoi`).
  - Restaurant-/Hotel-Fallbacksuche in Nearby-Flow konsolidiert.
  - Suggestion-Chips und Demo-Responses textlich bereinigt.
- `pubspec.yaml`
  - Version erhoeht auf `1.10.48+231`.
- `README.md`, `docs/README.md`, `docs/FLUTTER-APP-DOKUMENTATION.md`, `CLAUDE.md`
  - Release-/Versionsangaben auf `v1.10.48` aktualisiert.
- `qr-code-download.html`, `docs/qr-code-download.html`
  - QR-Ziel und Download-Link auf `v1.10.48/app-release.apk` gesetzt.

## Tests / Validierung
- `flutter test` (komplette Suite): erfolgreich.
- `flutter build apk --release` mit `--dart-define` Parametern: erfolgreich.

## Artefakte
- APK Release: `v1.10.48`
- APK Datei: `build/app/outputs/flutter-apk/app-release.apk`
- Download: `https://github.com/jerdnaandrej777/mapab-app/releases/download/v1.10.48/app-release.apk`
