# Social Owner Controls (v1.10.49)

Diese Anleitung beschreibt die neuen Owner-Rechte fuer Social-Inhalte.

## Ziel
Besitzer von veroeffentlichten Inhalten sollen ihre eigenen Eintraege direkt im Social-Flow bearbeiten und loeschen koennen.

## Abgedeckte Bereiche
- Public Trip Detail (`/gallery/:tripId`)
- POI-Feed in der Galerie

## Owner-Erkennung
- Ein Eintrag gilt als `own`, wenn `auth.user.id == content.userId`.
- Nur dann werden Owner-Aktionen im UI eingeblendet.

## Trip-Owner-Flow
Datei: `lib/features/social/trip_detail_public_screen.dart`

### Bearbeiten
- Action-Menue im `SliverAppBar` (`Trip bearbeiten`).
- Felder: Titel, Beschreibung, Tags.
- Speichern triggert `TripDetailNotifier.updateTripMeta(...)`.

### Loeschen
- Action-Menue im `SliverAppBar` (`Trip loeschen`).
- Sicherheitsdialog vor finalem Delete.
- Loeschen triggert `TripDetailNotifier.deleteTrip()`.

## POI-Owner-Flow
Datei: `lib/features/social/gallery_screen.dart`

### Bearbeiten
- Owner-Menue pro POI-Card (`Bearbeiten`).
- Felder: Titel, Beschreibung, Kategorien (CSV), Must-See.
- Speichern triggert `POIGalleryNotifier.updatePost(...)`.

### Loeschen
- Owner-Menue pro POI-Card (`Loeschen`).
- Sicherheitsdialog vor finalem Delete.
- Loeschen triggert `POIGalleryNotifier.deletePost(...)`.

## Backend-Schutz
Datei: `lib/data/repositories/social_repo.dart`

Mutierende Methoden sind owner-gebunden:
- `updatePublishedTrip(...)`
- `deletePublishedTrip(...)`
- `updatePublishedPOI(...)`
- `deletePublishedPOI(...)`

Alle relevanten Queries enthalten zusaetzlich einen `user_id`-Filter.

## UX-Hinweise
- Nicht-Besitzer sehen keine Bearbeiten/Loeschen Aktionen.
- Erfolgreiche Aktionen zeigen eine Success-Snackbar.
- Fehlerfaelle zeigen eine Error-Snackbar und rollen optimistische Updates zurueck.

## Regression-Checkliste
1. Besitzer kann eigenen Trip bearbeiten.
2. Besitzer kann eigenen Trip loeschen.
3. Besitzer kann eigenen POI-Post bearbeiten.
4. Besitzer kann eigenen POI-Post loeschen.
5. Nicht-Besitzer sieht keine Owner-Menues.
6. API-Fehler fuehren zu Rollback statt inkonsistentem UI-State.
