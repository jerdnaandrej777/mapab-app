# Changelog v1.10.25 (Build 208)

Datum: 2026-02-07

## Schwerpunkt
AI Euro Trip Stabilisierung mit hartem 700-km-Limit pro Tag, korrekter Tagesuebergabe und erweiterter Hotel-Engine.

## Highlights

### 1) 700-km-Hardlimit pro Tag
- Tagesdistanzen werden strikt validiert.
- Bei nicht einhaltbarem Limit wird die Generierung mit klarer Fehlermeldung abgebrochen.
- Validierung greift auch bei Day-Edits (`addPOI`, `removePOI`, `rerollPOI`).

### 2) Korrekte Tageskette
- Tag `N+1` startet exakt am Endpunkt von Tag `N`.
- Export/Navigation verwenden durchgaengig Tages-Start und Tages-Ende.
- A->B Trips behalten das echte Ziel als Routenende.

### 3) Hotel-Engine Upgrade (bis 20 km)
- Neuer Backend-Endpunkt: `POST /api/hotels/search` (Google Places + Details).
- Radius wird auf maximal 20 km geklemmt.
- Rich-Daten: Rating, Review-Count, Highlights, Amenities, Kontakt, Booking-Link.
- Bewertungsregel: bei vorhandenen Reviews bevorzugt/erlaubt ab `>= 10`; sonst transparenter Fallback.
- Mehrtagetrips erhalten deduplizierte Hotelvorschlaege pro Tag (wenn Alternativen verfuegbar).

### 4) Datumslogik und Persistenz
- Trip-Startdatum in Random Trip State/UI integriert.
- Booking-Links verwenden taggenaue Check-in/Check-out-Daten je Uebernachtung.
- ActiveTrip speichert und restauriert Hotelvorschlaege, Hotelauswahl und Startdatum.

## Wichtige Dateien
- `lib/core/algorithms/day_planner.dart`
- `lib/data/repositories/trip_generator_repo.dart`
- `lib/data/services/hotel_service.dart`
- `lib/data/models/trip.dart`
- `lib/features/trip/trip_screen.dart`
- `lib/features/trip/widgets/day_editor_overlay.dart`
- `lib/features/random_trip/widgets/hotel_suggestion_card.dart`
- `lib/features/random_trip/widgets/hotel_detail_sheet.dart`
- `backend/api/hotels/search.ts`
- `backend/lib/types.ts`

## Tests
- `test/algorithms/day_planner_test.dart`
- `test/models/trip_model_test.dart`
- `test/constants/trip_constants_test.dart`
- `test/services/hotel_service_test.dart`

