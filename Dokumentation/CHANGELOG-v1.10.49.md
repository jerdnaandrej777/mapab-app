# CHANGELOG v1.10.49

Datum: 09.02.2026
Build: 232

## Fokus
Stabilitaet und Moderierbarkeit der Social-Features.

## Neue Funktionen
- Owner-Edit/Delete fuer veroeffentlichte Trips im Public-Detail.
- Owner-Edit/Delete fuer veroeffentlichte POI-Posts direkt in der Galerie.

## Technische Aenderungen
- Map-Header: AI-Assistent Button entfernt (Crash-Pfad umgangen).
- `SocialRepository` erweitert um:
  - `updatePublishedTrip(...)`
  - `updatePublishedPOI(...)`
  - `deletePublishedPOI(...)`
- Delete/Update Pfade gehaertet: mutierende Trip/POI-Operationen sind an `user_id` gebunden.
- `TripDetailNotifier` erweitert um:
  - `updateTripMeta(...)`
  - `deleteTrip()`
- `POIGalleryNotifier` erweitert um:
  - `updatePost(...)`
  - `deletePost(...)`

## Betroffene Dateien
- `lib/features/map/map_screen.dart`
- `lib/features/social/trip_detail_public_screen.dart`
- `lib/features/social/gallery_screen.dart`
- `lib/data/providers/gallery_provider.dart`
- `lib/data/providers/poi_gallery_provider.dart`
- `lib/data/repositories/social_repo.dart`

## QA
- `flutter test` komplett erfolgreich.
- Social-Owner-Flows manuell verifiziert:
  - Besitzer sieht Bearbeiten/Loeschen.
  - Nicht-Besitzer sieht keine Owner-Aktionen.
