# Changelog v1.10.60 - Favoriten Bidirektionaler Cloud-Sync

**Datum:** 10. Februar 2026
**Build:** 244

## Uebersicht

Favoriten (gespeicherte Routen und POIs) werden jetzt bidirektional mit Supabase synchronisiert. Bei App-Start werden Cloud-Daten geladen und mit lokalen Hive-Daten gemergt. Neue Favoriten werden automatisch in die Cloud hochgeladen, Loeschungen werden ebenfalls gesynct.

**Kritischer Fix:** Der bisherige Route-Upload war seit v1.10.9 kaputt, weil Migration 006 die `trips`-Tabelle komplett neu aufgebaut hatte (neues Schema mit `trip_name`, `trip_data JSONB`), aber `syncService.saveTrip()` noch das alte Schema nutzte (`name`, `start_lat`, etc.). Dadurch wurden gespeicherte Routen nie erfolgreich in die Cloud uebertragen.

## Architektur

```
Favoriten-Operation (save/remove)
    |
    v
1. Hive Update (sofort, offline-faehig)
    |
    v
2. State Update (UI reagiert sofort)
    |
    v
3. Cloud-Sync (fire-and-forget, wenn authentifiziert)
    |--- uploadTrip() / deleteTrip()
    |--- uploadPOI() / deletePOI()


App-Start (wenn authentifiziert)
    |
    v
1. Hive laden (lokal)
    |
    v
2. Cloud laden (favorite_trips + favorite_pois)
    |
    v
3. Merge (Union-Strategie: lokal hat Vorrang bei Duplikaten)
    |
    v
4. Upload lokaler Daten die in Cloud fehlen
```

## Merge-Strategie

- **Trips:** Cloud-Trips die lokal fehlen → lokal hinzufuegen. Lokale Trips die in Cloud fehlen → hochladen. Gleiche trip_id → lokal behalten.
- **POIs:** Analog zu Trips.

## Neue Dateien

| Datei | Beschreibung |
|-------|-------------|
| `backend/supabase/migrations/012_favorite_trips.sql` | `favorite_trips` Tabelle, RLS, RPC Functions, Trigger |
| `lib/data/repositories/favorites_cloud_repo.dart` | Cloud-CRUD: uploadTrip/POI, deleteTrip/POI, fetchAllTrips/POIs, Batch-Upload |

## Geaenderte Dateien

| Datei | Aenderung |
|-------|-----------|
| `lib/data/providers/favorites_provider.dart` | FavoritesCloudRepo statt SyncService, bidirektionaler Sync in build(), isSyncing-Flag, syncFromCloud() public, removeRoute() synct Cloud-Deletion |
| `lib/features/favorites/favorites_screen.dart` | Cloud-Sync-Button + Sync-Indicator in AppBar (nur wenn authentifiziert) |
| `pubspec.yaml` | Version 1.10.60+244 |

## Supabase Migration 012

```sql
-- Dedizierte Tabelle fuer private gespeicherte Routen
CREATE TABLE favorite_trips (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id),
    trip_id TEXT NOT NULL,           -- App-internes Trip-ID
    trip_name TEXT NOT NULL,
    trip_data JSONB NOT NULL,        -- Komplettes Trip.toJson()
    trip_type VARCHAR(50),
    distance_km DECIMAL(10,2),
    stop_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    UNIQUE(user_id, trip_id)
);

-- RLS: Nur eigene Favoriten sichtbar
-- RPC: get_user_favorite_trips(), get_user_favorite_pois()
```

## Gefixte Bugs

1. **Route-Upload kaputt seit v1.10.9:** `syncService.saveTrip()` versuchte INSERT mit altem Schema (`name`, `start_lat`) in Tabelle die neues Schema hat (`trip_name`, `trip_data JSONB`). Neue dedizierte `favorite_trips` Tabelle loest das Problem.

2. **Route-Loeschung nicht gesynct:** `removeRoute()` loeschte nur aus Hive. Jetzt wird auch `FavoritesCloudRepo.deleteTrip()` aufgerufen.

3. **Kein Cloud-Download:** Favoriten wurden zu Supabase hochgeladen aber nie zurueck geladen. Bei Neuinstallation oder neuem Geraet waren alle Favoriten weg. Jetzt werden beim App-Start Cloud-Favoriten geladen und mit lokalen gemergt.
