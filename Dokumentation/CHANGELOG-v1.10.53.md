# CHANGELOG v1.10.53

Datum: 09.02.2026
Build: 236

## Fokus
Stabiler Kartenfluss fuer veroeffentlichte Trips, schnellerer Zugriff auf das Reisetagebuch und konsistente POI-Listen-UI entlang der Route.

## Geaendert
- Public Trips aus der Galerie setzen vor dem Kartenwechsel alte Planungs-/AI-Zustaende zurueck und laden Route + POIs deterministisch in den Hauptkartenzustand.
- Starten von Public Trips bzw. einzelnen Public-POIs ab aktuellem Standort nutzt denselben bereinigten Zustand ohne UI-Kontext-Leaks.
- Der Map-Header hat ein eigenes Reisetagebuch-Icon fuer direkten Einstieg in `/journal/...`.
- Der Korridor-Browser verwendet jetzt groessere POI-Karten im Trip-Modal-Stil mit Bild-Caching und klareren Add/Remove-Aktionen.

## Behoben
- Falsche Footer-Buttons aus altem AI-Preview-Kontext erscheinen beim Oeffnen eines veroeffentlichten Trips auf der Karte nicht mehr.
- Hoehenprofil-Ladevorgaenge werden fuer identische Routen dedupliziert und loesen keine Request-Storms mehr aus.

## Technische Aenderungen
- `lib/features/social/trip_detail_public_screen.dart`
  - Reset von `routePlannerProvider` und `randomTripNotifierProvider` vor Public-Trip/POI-Map-Start.
  - Route-Fokus-Mode wird beim "Auf Karte"-Flow explizit aktiviert.
- `lib/features/map/map_screen.dart`
  - Neues Journal-Icon in der AppBar.
  - Neue Helper-Logik `_openJournalFromMap(...)` mit robusten Fallbacks fuer Trip-ID/Name.
- `lib/features/trip/providers/elevation_provider.dart`
  - Guard gegen doppelte `loadElevation()`-Requests fuer dieselbe Route waehrend `isLoading=true`.
- `lib/features/trip/widgets/corridor_browser_sheet.dart`
  - Neue `_CorridorPOICard` ersetzt kompakte Karten im Routen-POI-Flow.

## Betroffene Dateien
- `pubspec.yaml`
- `CHANGELOG.md`
- `README.md`
- `docs/README.md`
- `CLAUDE.md`
- `QR-CODE-README.md`
- `qr-code-download.html`
- `docs/qr-code-download.html`
- `docs/mapab-v1.10.53.apk`
- `lib/features/social/trip_detail_public_screen.dart`
- `lib/features/map/map_screen.dart`
- `lib/features/trip/providers/elevation_provider.dart`
- `lib/features/trip/widgets/corridor_browser_sheet.dart`
- `.github/workflows/ci.yml`
- `.github/workflows/ios-testflight.yml`

## QA
- `dart analyze lib/features/social/trip_detail_public_screen.dart lib/features/map/map_screen.dart lib/features/trip/providers/elevation_provider.dart lib/features/trip/widgets/corridor_browser_sheet.dart` erfolgreich (nur bestehende Info-Lints).
- `flutter test` erfolgreich (gesamte Suite).
