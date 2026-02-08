# CHANGELOG v1.10.40

Datum: 2026-02-08
Build: 223

## Highlights
- Modale wurden im Ziel-Scope visuell vereinheitlicht (Dialog/Bottom-Sheet/Chip-Kontraste in Light/Dark/OLED).
- Lesbarkeitsfix im AI-Assistenten: Quick-Radius-Filterchips sind im Such-Radius-Dialog klar lesbar (kein weiss-auf-weiss).
- Lesbarkeitsfix im Sehenswuerdigkeiten-Filter: Kategorie-Chips haben explizite Kontrastfarben und klare Zustandsdarstellung.
- Trip-Bearbeiten-Modal wurde aufgeraeumt: Header entschlackt, alle 6 Aktionen im priorisierten Sticky-Footer erhalten.

## Technische Aenderungen
- Theme / Design System:
  - `lib/core/theme/app_theme.dart`
    - Light Theme um `dialogTheme` + `bottomSheetTheme` erweitert.
    - `chipTheme` mit explizitem Label-Kontrast (`labelStyle`, `secondaryLabelStyle`) und angepasstem `selectedColor`.
    - Dark/OLED auf denselben Kontrastvertrag fuer Chips/Dialoge abgeglichen.
- AI-Assistent:
  - `lib/features/ai_assistant/chat_screen.dart`
    - `_showRadiusSliderDialog()` Quick-Select `ChoiceChip`s mit expliziten Styles (`backgroundColor`, `selectedColor`, `side`, `showCheckmark`, `checkmarkColor`, Label-Farben).
- Sehenswuerdigkeiten / POI-Filter:
  - `lib/features/poi/widgets/poi_filters.dart`
    - Kategorie-`FilterChip`s mit expliziten selected/unselected Text- und Flaechenfarben.
    - Modal-Header/Footer gestalterisch vereinheitlicht.
    - Primary-Action unten als `FilledButton`.
- Trip-Bearbeiten:
  - `lib/features/trip/widgets/day_editor_overlay.dart`
    - Save/Publish aus der AppBar entfernt.
    - `_BottomActions` um `onSaveToFavorites` + `onPublishTrip` erweitert.
    - Footer-Hierarchie: Navigation (primaer), Add/Share/Google Maps (sekundaer), Save/Publish (tertiaer).

## Tests / Validierung
- `flutter test test/services/ai_exception_test.dart test/widgets/day_mini_map_test.dart`
- Format/Analyse auf geaenderte Dateien ausgefuehrt (keine build-blockierenden Fehler).

## Artefakte
- APK Release: `v1.10.40`
- Download: `https://github.com/jerdnaandrej777/mapab-app/releases/download/v1.10.40/app-release.apk`
