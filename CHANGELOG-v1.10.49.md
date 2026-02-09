# MapAB v1.10.49 - Release Notes

Datum: 2026-02-09
Build: 232

## Highlights

### 1) AI-Assistent Header-Einstieg entfernt
Der AppBar-Shortcut zum AI-Assistent wurde entfernt, da dieser Einstiegspfad in der Praxis zu Abstuerzen fuehrte.

### 2) Public Trip Detail: Owner Edit/Delete
Besitzer eines veroeffentlichten Trips koennen jetzt direkt im Public-Trip-Detail:
- Titel/Beschreibung/Tags bearbeiten
- den Trip loeschen

### 3) POI-Galerie: Owner Edit/Delete
Besitzer von veroeffentlichten POI-Posts koennen direkt in der Galerie:
- Titel/Beschreibung/Kategorien/Must-See bearbeiten
- den POI-Post loeschen

### 4) Repository-Haertung
Mutierende Social-Operationen sind jetzt owner-gebunden (`user_id`), damit kein fremder Inhalt bearbeitet oder geloescht werden kann.

## Technische Aenderungen
- `lib/features/map/map_screen.dart`
- `lib/features/social/trip_detail_public_screen.dart`
- `lib/features/social/gallery_screen.dart`
- `lib/data/providers/gallery_provider.dart`
- `lib/data/providers/poi_gallery_provider.dart`
- `lib/data/repositories/social_repo.dart`

## Qualitaet
- `flutter test` erfolgreich (komplette Suite).
