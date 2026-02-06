# Changelog v1.10.14 (Build 195)

## Trip-Galerie & Foto-Upload Fix

Dieses Release behebt den Trip-Galerie-Fehler und macht den POI-Foto-Upload-Button sichtbar.

### Bugfixes

#### Trip-Galerie FK-Fehler
- **Problem:** `PostgrestException: Could not find a relationship between 'trips' and 'user_profiles'`
- **Ursache:** `loadFeaturedTrips()` verwendete `.select('*, user_profiles!inner(...)'))` - PostgREST konnte den FK nicht finden, da `trips.user_id` auf `auth.users` verweist, nicht direkt auf `user_profiles`
- **Lösung:** `loadFeaturedTrips()` nutzt jetzt `_client.rpc('search_public_trips')` statt direkter Query

#### POI-Foto-Upload-Button nicht sichtbar
- **Problem:** Der "Foto hochladen" Button war nicht sichtbar auf der POI-Detail-Seite
- **Ursache:** `POIPhotoGallery` wurde ohne `onAddPhoto` Callback aufgerufen
- **Lösung:** `onAddPhoto` Callback in `poi_detail_screen.dart` implementiert

### Neue Dateien

| Datei | Beschreibung |
|-------|--------------|
| `lib/features/poi/widgets/upload_photo_sheet.dart` | Bottom Sheet für POI-Foto-Upload |

### Geänderte Dateien

| Datei | Änderung |
|-------|----------|
| `lib/data/repositories/social_repo.dart` | `loadFeaturedTrips()` nutzt RPC statt direkte Query |
| `lib/features/poi/poi_detail_screen.dart` | `onAddPhoto` Callback implementiert, import für `upload_photo_sheet.dart` |

### Upload-Sheet Features

- Kamera-Button für Live-Foto
- Galerie-Button für existierende Fotos
- Bildvorschau mit Entfernen-Button
- Caption-Eingabe (optional, max 500 Zeichen)
- Komprimierung auf max 1920px / 85% Qualität
- Upload-Fortschrittsanzeige

### Voraussetzungen

**WICHTIG:** Für die volle Funktionalität müssen folgende Schritte auf Supabase ausgeführt werden:

1. **Migration 006 ausführen** - Trip-Galerie Tabellen (`trips`, `user_profiles`, etc.)
2. **Migration 007 ausführen** - POI Social Features (`poi_photos`, `poi_reviews`, `comments`, etc.)
3. **Storage Bucket erstellen:** `poi-photos` (Public, max 5MB, JPEG/PNG/WebP)

---

**Build:** 195
**Version:** 1.10.14
**Datum:** 2026-02-06
