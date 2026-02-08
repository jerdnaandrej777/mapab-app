# CHANGELOG v1.10.35

Datum: 2026-02-08
Build: 218

## Highlights
- POI-Posts lassen sich wieder veroeffentlichen, auch wenn die neue RPC auf der Ziel-DB noch fehlt.
- Veroeffentlichte Trips persistieren jetzt reichhaltige Stop-Metadaten (Score, Tags, Highlights, Must-See, Bilder).
- POI-Vorschau in oeffentlichen Trips ist korrekt normalisiert und mit den richtigen POI-Details verlinkt.
- AI Tagestrip hat eine erweiterte Fallback-Strategie gegen "keine POIs gefunden".

## Technische Aenderungen
- `lib/data/repositories/social_repo.dart`
  - `publishTrip(...)` akzeptiert jetzt `sourcePOIs` und schreibt angereicherte Stop-Daten in `tripData`.
  - `publishPOI(...)` faengt `PGRST202` ab und nutzt `poi_posts` Direct-Insert als Fallback.
  - Sichere `Map<String, dynamic>`-Konvertierung bei Profil-Responses.
- `lib/features/social/widgets/publish_trip_sheet.dart`
  - Quelle fuer Publish-Stopdaten aus `tripStateProvider` und `randomTripNotifierProvider` zusammengefuehrt.
- `lib/features/social/trip_detail_public_screen.dart`
  - Robuste Stop-Normalisierung (`poiId`, `lat/lng`, Kategorie, Must-See, Tags).
  - POI-Mini-Tiles oeffnen jetzt den korrekten POI-Detailscreen.
  - "Auf Karte"-Import nutzt normalisierte Stops fuer stabile Route/POI-Generierung.
- `lib/features/poi/providers/poi_state_provider.dart`
  - `selectPOIById(...)` liefert `bool` statt Exception.
  - Neues `ensurePOIById(...)` laedt fehlende POIs on-demand nach.
- `lib/features/poi/poi_detail_screen.dart`
  - Detailscreen laedt POIs robust ueber `ensurePOIById(...)` und enriched nur bei Bedarf.
- `lib/data/repositories/supabase_poi_repo.dart`
  - Neues `getPOIById(...)` fuer direkte POI-Einzelabfrage.
- `lib/data/repositories/poi_repo.dart`
  - Neues `loadPOIById(...)` (Supabase + curated JSON Fallback).
  - `loadPOIsInRadius(...)` und `loadPOIsInBounds(...)` mit `minScore` parametrisierbar.
- `lib/data/repositories/trip_generator_repo.dart`
  - Mehrstufige Daytrip-POI-Fallbacks (strict/relaxed/rescue).
  - Groessere Endpoint-Radien, tolerantere Korridor-Constraints, Midpoint-Rescue.
- `test/repositories/trip_generator_daytrip_test.dart`
  - Fake-Repositories an neue `minScore`-Signaturen angepasst.

## Backend / Migration
- `supabase/migrations/20260208103000_poi_publish_rpc_fix.sql`
  - `publish_poi_post(...)` erstellt/aktualisiert.
  - `get_public_poi(...)` Rueckgabestruktur stabilisiert.
- `docs/guides/BACKEND-SETUP.md`
  - Hinweis auf erforderliche Social/POI-Migrationen (`011`, `012` bzw. CLI-Migration).

## Artefakte
- APK Release: `v1.10.35`
- Download: `https://github.com/jerdnaandrej777/mapab-app/releases/download/v1.10.35/app-release.apk`
