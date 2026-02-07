# CHANGELOG v1.10.29

Datum: 7. Februar 2026
Build: 212

## Highlights
- Favoriten-Status stabilisiert: Herz-Icon bleibt nach Toggle konsistent rot.
- Favoriten-Badge auf Kartenmarkern: Favorisierte POIs zeigen ein kleines Herz in
  Day-Mini-Map, Trip-Preview und Hauptkarte.
- Wetter-Sync bei Routen-Neuberechnung: Nach Generate/Reroll/Add/Remove/Hotel-
  Auswahl wird Wetter sofort fuer die aktuelle Route neu geladen.

## Technische Aenderungen
- `lib/data/providers/favorites_provider.dart`
  - `isPOIFavorite` und `isRouteSaved` reagieren jetzt direkt auf State-Aenderungen.
- `lib/features/random_trip/providers/random_trip_provider.dart`
  - Zentraler Wetter-Refresh `_refreshRouteWeatherForGeneratedTrip(...)`.
  - Trigger auf allen Recompute-Pfaden eingebaut.
- `lib/features/map/widgets/map_view.dart`
  - Veralteten Preview-Step-Wettertrigger entfernt, um doppelte/verzoegerte Updates
    zu vermeiden.
- `lib/features/trip/widgets/day_mini_map.dart`
  - Favoriten-Herz-Badge auf Tages-Stop-Markern.
- `lib/features/random_trip/widgets/trip_preview_card.dart`
  - Favoriten-Herz-Badge auf Preview-Markern.

## Ergebnis
- Karten-Wetter entspricht unmittelbar der zuletzt berechneten Route.
- Favoriten sind in Detailansicht und Kartenkacheln konsistent sichtbar.
