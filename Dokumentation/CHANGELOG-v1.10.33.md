# CHANGELOG v1.10.33

Datum: 8. Februar 2026
Build: 216

## Highlights
- POI-Listen bereinigt: keine Foto-Upload-Buttons mehr in Listen/Overlays.
- POI-Veröffentlichung direkt über POI-Detailseite ergänzt.
- AI-Tagestrip stabilisiert: robustere Ziel-/Korridor-Logik und bessere Fehlerbehandlung bei Routing-Ausfällen.

## Technische Änderungen
- `lib/features/trip/widgets/editable_poi_card.dart`
  - Foto-Aktionen aus der POI-Liste entfernt.
- `lib/features/social/trip_detail_public_screen.dart`
  - POI-Mini-Listen ohne Upload-Aktionen.
- `lib/features/random_trip/widgets/poi_reroll_button.dart`
  - `POIActionButtons` API bereinigt (kein `onPhotos` mehr).
- `lib/features/social/widgets/publish_poi_sheet.dart` (neu)
  - Neues Publish-Sheet für POIs.
- `lib/features/poi/poi_detail_screen.dart`
  - Action „POI veröffentlichen“ mit Login-Check eingebaut.
- `lib/data/repositories/social_repo.dart`
  - `publishPOI(...)` ergänzt.
- `backend/supabase/migrations/012_poi_publish_rpc_fix.sql` (neu)
  - `publish_poi_post(...)` hinzugefügt.
  - `get_public_poi(...)` auf direkten Lookup korrigiert.
- `lib/features/map/widgets/trip_config_panel.dart`
  - Ziel-Reset beim Leeren des Feldes robuster gemacht.
- `lib/data/repositories/trip_generator_repo.dart`
  - Mindestdistanz-Guard für Ziel im Daytrip (`>= 3km`).
  - Korridor-POI-Laden mit geometrischem Fallback statt hartem Abbruch.
- `lib/features/random_trip/providers/random_trip_provider.dart`
  - Routing-Fehler benutzerfreundlich normalisiert.
- `test/repositories/trip_generator_daytrip_test.dart` (neu)
  - Tests für Zielnähe-Guard und Fehlernormalisierung.

## Ergebnis
- Weniger sporadische Tagestrip-Abbrüche bei Ziel/Korridor-Konstellationen.
- Klarere UX: Foto-Uploads nur auf POI-Detailseiten.
- POI-Community-Publishing über die Detailseite möglich.
