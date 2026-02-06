# Changelog v1.10.21 - Trip-Foto-Upload

**Datum:** 6. Februar 2026
**Build:** 204

## Übersicht

Diese Version fügt die Möglichkeit hinzu, eigene Fotos zu veröffentlichten Trips hochzuladen - sowohl ein Cover-Bild beim Veröffentlichen als auch eine vollständige Foto-Galerie in der Trip-Detail-Ansicht.

## Neue Features

### Cover-Bild beim Veröffentlichen
- Beim Veröffentlichen eines Trips kann jetzt ein Cover-Bild hochgeladen werden
- Auswahl via Kamera oder Galerie
- Automatische Komprimierung auf max. 1920x1080px bei 85% Qualität
- Vorschau mit Entfernen-Button

### Trip-Foto-Galerie
- Horizontale Foto-Galerie in der Trip-Detail-Ansicht
- Nur eigene Trips: Upload-Button zum Hinzufügen weiterer Fotos
- Thumbnails mit Autor-Badge
- Vollbild-Viewer mit:
  - PageView zum Blättern zwischen Fotos
  - InteractiveViewer zum Zoomen
  - Autor-Info und Caption am unteren Rand
  - Löschen-Button für eigene Fotos

## Technische Details

### Neue Dateien

| Datei | Beschreibung |
|-------|--------------|
| `backend/supabase/migrations/008_trip_photos.sql` | DB-Schema: trip_photos Tabelle, RLS Policies, RPC Functions |
| `lib/data/models/trip_photo.dart` | Freezed Model für Trip-Fotos |
| `lib/features/social/widgets/trip_photo_gallery.dart` | Horizontale Galerie + Vollbild-Viewer |
| `lib/features/social/widgets/upload_trip_photo_sheet.dart` | Upload Bottom Sheet |

### Erweiterte Dateien

| Datei | Änderungen |
|-------|------------|
| `lib/data/repositories/social_repo.dart` | +loadTripPhotos(), +uploadTripPhoto(), +uploadTripCoverImage(), +deleteTripPhoto(), +_compressImage(), +getTripPhotoUrl() |
| `lib/features/social/widgets/publish_trip_sheet.dart` | +Cover-Bild-Auswahl Section |
| `lib/features/social/trip_detail_public_screen.dart` | +TripPhotoGallery Integration |

### Datenbank-Schema (Migration 008)

```sql
-- Trips-Tabelle erweitert
ALTER TABLE public.trips ADD COLUMN cover_image_path TEXT;

-- Neue Tabelle
CREATE TABLE public.trip_photos (
    id UUID PRIMARY KEY,
    trip_id UUID REFERENCES trips(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    storage_path TEXT NOT NULL,
    thumbnail_path TEXT,
    caption VARCHAR(500),
    display_order INTEGER DEFAULT 0,
    likes_count INTEGER DEFAULT 0,
    is_flagged BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- RPC Functions
- register_trip_photo()
- set_trip_cover_image()
- get_trip_photos()
- delete_trip_photo()
```

### Neue Lokalisierungs-Keys (6)

| Key | DE | EN |
|-----|----|----|
| `publishCoverImage` | Cover-Bild | Cover Image |
| `publishCoverImageHint` | Optional: Wähle ein Bild... | Optional: Choose an image... |
| `tripPhotos` | Fotos | Photos |
| `tripNoPhotos` | Noch keine Fotos | No photos yet |
| `tripAddFirstPhoto` | Erstes Foto hinzufügen | Add first photo |
| `tripPhotoUpload` | Foto hochladen | Upload Photo |

## Bugfixes

- `social_repo.dart`: SupabaseConfig.supabaseUrl statt _client.supabaseUrl (nicht verfügbar auf SupabaseClient)
- `trip_photo_gallery.dart`: Redundanter findAncestorWidgetOfExactType<State> Code entfernt

## Storage-Setup (manuell)

Nach Ausführen der Migration muss der Storage Bucket erstellt werden:

1. Supabase Dashboard → Storage → New Bucket
2. Name: `trip-photos`
3. Public bucket: ✅ aktiviert

## Abhängigkeiten

- Keine neuen Dependencies
- Nutzt bestehendes `image` Package für Komprimierung
- Nutzt bestehendes `image_picker` Package
