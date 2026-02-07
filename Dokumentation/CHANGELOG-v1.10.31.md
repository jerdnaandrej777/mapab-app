# CHANGELOG v1.10.31

Datum: 8. Februar 2026
Build: 214

## Highlights
- Community-Ausbau der Galerie: Trips und POIs mit Social-Interaktionen.
- Dominantere Generierungs-UX mit klarerem Fortschrittsfokus im nicht-transparenten Modal.
- Stabilisierung der Random-Trip/POI-Logik (Start-Handling, Kategorien, Radius-Updates).

## Technische Aenderungen
- `lib/features/social/gallery_screen.dart`
  - Galerie auf Trip/POI-Ansicht erweitert.
- `lib/data/providers/poi_gallery_provider.dart`
  - Neuer Provider fuer POI-Community-Feed.
- `backend/supabase/migrations/011_poi_gallery_social.sql`
  - Erweiterte Social-Strukturen fuer POI-Galerie.
- `lib/features/random_trip/widgets/generation_progress_indicator.dart`
  - Praesentere Ladeanzeige mit Fortschrittsdarstellung.
- `lib/features/random_trip/widgets/start_location_picker.dart`
  - Startadresse robust optional mit konsistenter State-Logik.
- `lib/features/random_trip/widgets/radius_slider.dart`
  - Radius-/UI-Logik weiter auf aktuelle Produktvorgaben synchronisiert.

## Ergebnis
- Release v1.10.31 liefert die aktuellen UX- und Social-Erweiterungen in einem neuen APK-Build.
- QR-Downloadseiten und Release-Dokumentation zeigen konsistent auf den neuen GitHub-Tag.
