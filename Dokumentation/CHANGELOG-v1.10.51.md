# CHANGELOG v1.10.51

Datum: 09.02.2026
Build: 234

## Fokus
Social-Flow stabilisieren: Import aus Trip-Galerie und Starten ab Standort.

## Neue Funktionen
- Public Trips koennen direkt ab aktuellem Standort gestartet werden.
- POIs in der Public-Trip-Vorschau koennen direkt ab Standort gestartet werden.

## Behoben
- Import aus der Trip-Galerie speichert jetzt verlässlich in lokale Favoriten.
- Trip-Daten Parsing toleriert jetzt Legacy- und aktuelle Payload-Formate (`trip_data`, `tripData`, direkte Struktur).

## Technische Aenderungen
- `lib/features/social/trip_detail_public_screen.dart`:
  - Import-Flow speichert Public-Trip in `favoritesNotifierProvider`.
  - `startTripFromCurrentLocation` mit Connector-Route vom GPS-Standort zum Trip-Start.
  - `startPoiFromCurrentLocation` für POI-Karten in der Trip-Vorschau.
  - Robuste Koordinaten-/Kategorie-Normalisierung und Fallback-POI-ID-Generierung.
- `lib/data/providers/favorites_provider.dart`:
  - Unveraendert, aber jetzt korrekt durch Social-Import angesteuert.

## Betroffene Dateien
- `lib/features/social/trip_detail_public_screen.dart`
- `pubspec.yaml`
- `CHANGELOG.md`
- `README.md`
- `CLAUDE.md`
- `docs/README.md`
- `qr-code-download.html`
- `docs/qr-code-download.html`

## QA
- `dart analyze lib/features/social/trip_detail_public_screen.dart` erfolgreich (nur Info-Lints).
- `flutter test test/services/sharing_public_link_test.dart` erfolgreich.
