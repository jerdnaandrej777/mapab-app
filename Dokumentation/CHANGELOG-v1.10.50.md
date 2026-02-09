# CHANGELOG v1.10.50

Datum: 09.02.2026
Build: 233

## Fokus
Mehr POIs auf Tagesrouten und schnellere POI-Ladevorgaenge.

## Neue Funktionen
- Daytrip-Fallbacks mergen Treffer aus mehreren Versuchen, bis ein sinnvoller POI-Pool erreicht ist.
- Dynamisches Kategorie-Limit (`maxPerCategory`) verhindert Unterbelegung bei engen Kategorien.

## Technische Aenderungen
- `TripGeneratorRepository`:
  - Tagestrip-Pool mit Mindestziel und Timeout-gesicherten Fallback-Loads.
  - Dynamische Berechnung fuer `maxPerCategory` in Daytrip- und Eurotrip-Selektion.
  - Eurotrip-Pool wird bei zu kleiner Datenmenge durch Rescue-Lauf erweitert und dedupliziert.
- `POIRepository`:
  - Curated-Katalog wird lazy geladen und als Future gecacht.
  - `loadCuratedPOIs(...)` und `loadPOIById(...)` nutzen denselben In-Memory-Katalog.
- Request-Zielwerte:
  - Daytrip-/AI-POI-Count auf `4..9` angehoben.

## Betroffene Dateien
- `lib/data/repositories/trip_generator_repo.dart`
- `lib/data/repositories/poi_repo.dart`
- `lib/features/random_trip/providers/random_trip_provider.dart`
- `lib/features/random_trip/providers/random_trip_state.dart`
- `lib/features/ai_assistant/chat_screen.dart`
- `test/repositories/trip_generator_daytrip_test.dart`

## QA
- `flutter test test/repositories/trip_generator_daytrip_test.dart` erfolgreich.
- `flutter test` komplett erfolgreich.
