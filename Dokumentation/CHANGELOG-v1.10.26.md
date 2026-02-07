# Changelog v1.10.26 (Build 209)

Datum: 2026-02-07

## Schwerpunkt
EuroTrip Stabilitaets-Rollout mit 700-km-gekoppelter POI-Selektion, Auto-Tagesreduktion und aktualisierten Download-Artefakten.

## Highlights

### 1) Constraint-basierte POI-Selektion
- POI-Kandidaten werden direkt gegen das Tages-/Trip-Budget geprueft.
- Segment-sichere Auswahl verhindert unloesbare Spruenge (z. B. 1900-km-Ausreisser).
- Endpunkt-Reachability pro Schritt reduziert Sackgassen in Mehrtagetrips.

### 2) Robustes Fallback-Verhalten
- Bei unmoeglichen Kombinationen wird die Tagesanzahl automatisch reduziert.
- Die Generierung liefert priorisiert eine berechenbare Route mit POIs statt hart abzubrechen.
- 700-km-Tagelimit bleibt als finaler Guard weiterhin strikt.

### 3) Release-Rollout aktualisiert
- App-Version erhoeht auf `1.10.26+209`.
- QR-Downloadseiten zeigen auf `v1.10.26/app-release.apk`.
- Release-Info und Dokumentation auf den neuen Stand angehoben.

## Wichtige Dateien
- `lib/core/algorithms/random_poi_selector.dart`
- `lib/data/repositories/trip_generator_repo.dart`
- `lib/features/random_trip/widgets/radius_slider.dart`
- `pubspec.yaml`
- `QR-CODE-DOWNLOAD.html`
- `qr-code-download.html`
- `docs/qr-code-download.html`
- `CLAUDE.md`

## Tests
- `test/algorithms/random_poi_selector_test.dart`
