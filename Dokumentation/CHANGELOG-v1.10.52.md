# CHANGELOG v1.10.52

Datum: 09.02.2026
Build: 235

## Fokus
Kartenmodus fuer fertige Routen vereinheitlichen und UI-Konflikte im "Deine Route"-Flow entfernen.

## Geaendert
- "Auf Karte anzeigen" schaltet jetzt in einen fokussierten Kartenmodus.
- In diesem Modus werden AI-Buttons und Planungs-Overlays ausgeblendet.
- Neuer kompakter Karten-Footer mit nur drei Aktionen:
  - `Trip bearbeiten`
  - `Navigation starten`
  - `Route loeschen`
- Geladene Favoriten-Routen verwenden denselben Fokus-Flow inklusive Auto-Zoom.

## Behoben
- Buttons `Google Maps` und `Route teilen` im "Deine Route"-Modal entfernt, damit keine ueberlappenden/zu tiefe Action-Bereiche mehr auftreten.
- Besseres Verhalten beim Trip-zu-Karte-Wechsel durch konsistente Fokus-Logik.

## Technische Aenderungen
- `lib/features/map/providers/map_controller_provider.dart`
  - Neuer StateProvider `mapRouteFocusModeProvider`.
- `lib/features/map/map_screen.dart`
  - Fokus-UI eingefuehrt (nur Karte + Footer-Aktionen im Route-Fokus).
  - Header-/Config-/Info-Overlays und Loading im Fokusmodus ausgeblendet.
  - Route-/Stop-Aufloesung fuer Start-Navigation im Fokusmodus vereinheitlicht.
- `lib/features/map/widgets/trip_mode_selector.dart`
  - AI-Tagestrip/Euro-Trip Buttons werden im Fokusmodus ausgeblendet.
- `lib/features/trip/trip_screen.dart`
  - "Auf Karte anzeigen" aktiviert Route-Fokusmodus.
  - Google-Maps/Teilen-Aktionsreihe aus dem Modal entfernt.
- `lib/features/favorites/favorites_screen.dart`
  - Beim Laden einer gespeicherten Route wird ebenfalls Route-Fokusmodus aktiviert.

## Betroffene Dateien
- `pubspec.yaml`
- `CHANGELOG.md`
- `README.md`
- `docs/README.md`
- `CLAUDE.md`
- `qr-code-download.html`
- `docs/qr-code-download.html`
- `docs/mapab-v1.10.52.apk`

## QA
- `dart analyze lib/features/map/map_screen.dart lib/features/map/widgets/trip_mode_selector.dart lib/features/map/providers/map_controller_provider.dart lib/features/favorites/favorites_screen.dart lib/features/trip/trip_screen.dart` erfolgreich (nur bestehende Info-Lints).
- `flutter test` erfolgreich (gesamte Suite).
