# Changelog v1.10.13 (Build 194)

## POI Social Features + Kommentare auf Trips

Dieses Release fügt umfassende Social Features für POIs hinzu und ermöglicht Kommentare auf öffentlichen Trips.

### Neue Features

#### POI-Foto-Upload
- Benutzer können eigene Fotos zu POIs hochladen
- Fotos werden in Supabase Storage gespeichert
- Horizontale Galerie mit Vollbild-Ansicht
- Caption/Bildunterschrift-Unterstützung

#### Bewertungssystem
- 1-5 Sterne-Bewertung für POIs
- Optionaler Bewertungstext
- Besuchsdatum erfassbar
- "Hilfreich"-Voting für Bewertungen anderer Nutzer
- Durchschnittsbewertung wird angezeigt

#### Kommentarfunktion
- Kommentare auf POIs
- Kommentare auf öffentliche Trips (Trip-Galerie)
- Antwort-Funktion (verschachtelte Kommentare)
- Melden-Funktion für unangemessene Inhalte

#### Admin-Dashboard
- Neuer Bildschirm unter `/admin`
- Zwei Tabs: Benachrichtigungen und Moderation
- Benachrichtigungen bei neuen Fotos, Bewertungen, Kommentaren
- Gemeldete Inhalte verwalten und löschen
- Admin-Button im Profil (nur für Admins sichtbar)
- Badge zeigt ungelesene Benachrichtigungen

### Neue Dateien

#### Backend (Migration)
- `backend/supabase/migrations/007_poi_user_content.sql` - POI Social Schema

#### Models
- `lib/data/models/poi_photo.dart` - Foto-Model (Freezed)
- `lib/data/models/poi_review.dart` - Review + Stats (Freezed)
- `lib/data/models/comment.dart` - Kommentar-Model (Freezed)
- `lib/data/models/admin_notification.dart` - Admin-Notification (Freezed)

#### Repositories
- `lib/data/repositories/poi_social_repo.dart` - POI Social Repository
- `lib/data/repositories/admin_repo.dart` - Admin Repository

#### Providers
- `lib/data/providers/poi_social_provider.dart` - POI Social State
- `lib/data/providers/admin_provider.dart` - Admin State

#### UI - POI Social
- `lib/features/poi/widgets/poi_rating_widget.dart` - Sterne + Button
- `lib/features/poi/widgets/submit_review_sheet.dart` - Bewertungs-Sheet
- `lib/features/poi/widgets/review_card.dart` - Review mit Hilfreich
- `lib/features/poi/widgets/poi_photo_gallery.dart` - Foto-Galerie
- `lib/features/poi/widgets/upload_photo_sheet.dart` - Upload-Sheet
- `lib/features/poi/widgets/poi_comments_section.dart` - Kommentare (POI + Trip)
- `lib/features/poi/widgets/comment_card.dart` - Kommentar-Karte

#### UI - Admin
- `lib/features/admin/admin_screen.dart` - Dashboard mit Tabs

### Geänderte Dateien

| Datei | Änderung |
|-------|----------|
| `lib/features/poi/poi_detail_screen.dart` | Social-Sektionen (Fotos, Rating, Reviews, Comments) |
| `lib/features/social/trip_detail_public_screen.dart` | Kommentar-Sektion |
| `lib/features/account/profile_screen.dart` | Admin-Button mit Badge |
| `lib/app.dart` | Admin-Route `/admin` |
| `lib/l10n/app_*.arb` | ~70 neue Lokalisierungs-Keys |

### Lokalisierung

70+ neue Strings in allen 5 Sprachen:
- Deutsch (DE)
- English (EN)
- Français (FR)
- Italiano (IT)
- Español (ES)

### Voraussetzungen

**WICHTIG:** Vor Verwendung der neuen Features müssen folgende Schritte ausgeführt werden:

1. **Migration 007 ausführen** im Supabase SQL Editor
2. **Storage Bucket erstellen**: `poi-photos` (Public, max 5MB, JPEG/PNG/WebP)
3. **Admin-Benutzer anlegen** in der `admins` Tabelle

### Technische Details

- Supabase Storage für Foto-Upload
- RPC Functions für atomare Operationen
- Row Level Security (RLS) für Datenschutz
- Freezed für immutable Models
- Riverpod für State Management

---

**Build:** 194
**Version:** 1.10.13
**Datum:** 2026-02-06
