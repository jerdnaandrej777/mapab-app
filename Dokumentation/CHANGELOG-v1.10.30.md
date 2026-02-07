# CHANGELOG v1.10.30

Datum: 7. Februar 2026
Build: 213

## Highlights
- Hauptkarte zeigt bei AI-EuroTrip wieder die komplette berechnete Route statt nur
  eines Tagessegments.
- Fortschrittsanzeige bei Routen-/Trip-Generierung auf Prozent umgestellt (animiert)
  inkl. phasenbasierter Statusmeldungen.
- Day-Editor-Modal: unterster POI ist nicht mehr abgeschnitten dank dynamischem
  Bottom-Space unter Beruecksichtigung der SafeArea.

## Technische Aenderungen
- `lib/features/map/widgets/map_view.dart`
  - Vollroutenanzeige fuer AI-Trip auf der Hauptkarte.
- `lib/features/random_trip/random_trip_screen.dart`
  - Loading-View auf `GenerationProgressIndicator` umgestellt.
- `lib/features/map/widgets/trip_info_bar.dart`
  - Kompakte Prozent-Fortschrittsanzeige fuer Generierungszustand.
- `lib/features/random_trip/widgets/generation_progress_indicator.dart`
  - Animierter Tip-Ticker fuer bessere Warte-UX.
- `lib/features/trip/widgets/day_editor_overlay.dart`
  - Dynamischer Footer-Spacer, damit Listeneintraege voll sichtbar bleiben.

## Ergebnis
- Bessere Transparenz waehrend Berechnung (klare Prozentanzeige).
- Konsistente Kartendarstellung der gesamten Tour.
- Verbesserte Nutzbarkeit der POI-Liste im Day-Editor.
