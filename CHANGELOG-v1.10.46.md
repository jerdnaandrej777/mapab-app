# CHANGELOG v1.10.46

Datum: 2026-02-09
Build: 229

## Highlights
- Social-Flow stabilisiert: POI-Social wird beim Oeffnen der Detailseite deterministisch geladen.
- Reply-Moderation gefixt: Delete/Flag greift bei Replies auf die korrekte Reply-ID.
- Public-Profil Routing erweitert: neue oeffentliche Route `/profile/:userId`.
- Sharing/QR vereinheitlicht auf `https://mapab.app/gallery/{id}` mit Legacy-Unterstuetzung fuer `/trip/{id}`.
- Navigation-Lifecycle robuster gegen Resume/Stop-Races im Background-Flow.

## Technische Aenderungen
- `lib/app.dart`
  - Route `/profile/:userId` hinzugefuegt.
  - Auth-Guard so angepasst, dass nur privates `/profile` gesichert ist.
- `lib/features/social/public_profile_screen.dart`
  - Neue Public-Profile Ansicht mit Laden ueber `profileNotifierProvider(userId)`.
- `lib/features/poi/poi_detail_screen.dart`
  - Initiales Laden von POI-Social via `loadAll()` verankert.
- `lib/features/poi/widgets/comment_card.dart`
  - Reply-Callbacks auf ID-basierte Moderation umgestellt.
- `lib/features/sharing/qr_scanner_screen.dart`
  - Gallery-Links (`/gallery/{id}`) werden direkt erkannt und geoeffnet.
- `lib/data/services/sharing_service.dart`
  - Public-Link Generator/Parser fuer Gallery-Links + Legacy-Kompatibilitaet.
- `lib/features/social/trip_detail_public_screen.dart`
  - Echte QR-Anzeige via `qr_flutter` statt Platzhalter.
- `lib/features/navigation/providers/navigation_provider.dart`
  - Stabileres Lifecycle-Verhalten fuer Start/Stop im Navigationsfluss.

## Tests / Validierung
- `flutter test` (komplette Suite)
- Zusatzt tests:
  - `test/services/sharing_public_link_test.dart`
  - `test/features/navigation/models/navigation_launch_args_test.dart`

## Artefakte
- APK Release: `v1.10.46`
- Download: `https://github.com/jerdnaandrej777/mapab-app/releases/download/v1.10.46/app-release.apk`
