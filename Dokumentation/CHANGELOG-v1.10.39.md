# CHANGELOG v1.10.39

Datum: 2026-02-08
Build: 222

## Highlights
- AI-Vorschlaege sind jetzt in allen AI-Flaechen klickbar wie normale POIs (Day-Editor, Day-Mini-Map, Hauptkarte, AI-Chat).
- Neuer strukturierter Backend-Endpoint `POST /api/ai/poi-suggestions` mit validierter JSON-Ausgabe und robustem Fallback.
- AI-Suggestions wurden auf bis zu 8 Vorschlaege erweitert und enthalten reichhaltigere Inhalte (longDescription, Highlights, Fotos).
- Medienanreicherung kombiniert Enrichment + Social-Fotos (inkl. klarer Fallback-Hinweise bei fehlenden Bildern).
- Routing-Luecken geschlossen: `'/ai-assistant'` und `'/pois'` sind als App-Routen verfuegbar.

## Technische Aenderungen
- Backend:
  - `backend/api/ai/poi-suggestions.ts` (neu): strukturierte AI-POI-Vorschlaege inkl. Fallback-Ranking.
  - `backend/lib/types.ts`: Request-/Response-Typen fuer strukturierte POI-Suggestions erweitert.
  - `backend/lib/openai.ts`: `TripContext` + Prompt-Building um Standort/Wetter/Tag/Sprache erweitert.
- Flutter Services/Provider:
  - `lib/core/constants/api_config.dart`: neuer Endpoint `aiPoiSuggestionsEndpoint`.
  - `lib/data/services/ai_service.dart`: neue Modelle + `getPoiSuggestionsStructured(...)`.
  - `lib/features/ai/providers/ai_trip_advisor_provider.dart`: strukturierter Suggestions-Flow, max 8 Vorschlaege, Mapping + Fallback.
  - `lib/data/services/poi_enrichment_service.dart`, `lib/data/providers/poi_social_provider.dart`: Foto-/Text-Anreicherung fuer AI-Vorschlaege.
- Flutter UI/Navigation:
  - `lib/features/trip/widgets/day_mini_map.dart`: `onMarkerTap` auf `ValueChanged<POI>?` vereinheitlicht.
  - `lib/features/trip/widgets/day_editor_overlay.dart`: AI-Karten oeffnen denselben POI-Detailflow.
  - `lib/features/map/widgets/map_view.dart`: AI-Overlay-Marker klickbar wie Standard-POIs.
  - `lib/features/ai_assistant/chat_screen.dart`: reichhaltige AI-POI-Cards, bis zu 8 Vorschlaege, CTA "Details"/"Auf Karte".
  - `lib/features/poi/providers/poi_state_provider.dart`: konsistenter Flow fuer Auswahl/Anreicherung bei AI-Taps.
  - `lib/app.dart`: Routen `'/ai-assistant'` und `'/pois'` hinzugefuegt.
- Lokalisierung:
  - `lib/l10n/app_{de,en,es,fr,it}.arb` um neue AI-Suggestion/Fallback-Strings erweitert.

## Tests / Validierung
- `flutter test test/services/ai_exception_test.dart test/widgets/day_mini_map_test.dart`
- Relevante Analyse auf geaenderte AI-/Map-/Trip-Dateien ohne Build-blockierende Fehler.

## Artefakte
- APK Release: `v1.10.39`
- Download: `https://github.com/jerdnaandrej777/mapab-app/releases/download/v1.10.39/app-release.apk`
