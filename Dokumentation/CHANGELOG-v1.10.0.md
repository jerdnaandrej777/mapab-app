# CHANGELOG v1.10.0 - Social Features: Oeffentliche Trip-Galerie

**Release-Datum:** 5. Februar 2026
**Build:** 180

## Uebersicht

Einfuehrung der Social Features Phase 1: Oeffentliche Trip-Galerie mit Teilen, Liken und Importieren von Trips.

---

## Neue Features

### 1. Oeffentliche Trip-Galerie

**Screen:** `lib/features/social/gallery_screen.dart`

- **Featured-Section:** Horizontal scrollbare Auswahl hervorgehobener Trips
- **Trip-Grid:** 2-spaltige Galerie aller oeffentlichen Trips
- **Suche:** Volltextsuche nach Trip-Namen und Beschreibungen
- **Filter:** Trip-Typ (Alle/Tagestrip/Euro Trip), Tags, Sortierung
- **Infinite Scroll:** Automatisches Nachladen beim Scrollen
- **Pull-to-Refresh:** Galerie aktualisieren durch Herunterziehen

### 2. Trip-Detail-Ansicht

**Screen:** `lib/features/social/trip_detail_public_screen.dart`

- **Hero-Image:** Grosses Thumbnail mit Gradient-Overlay
- **Like-Funktion:** Trips liken/unliken mit Like-Counter
- **Trip-Statistiken:** Distanz, Stops, Tage, Likes, Views
- **Author-Section:** Profilbild, Name, Anzahl geteilter Trips
- **Tags:** Anzeige aller Trip-Tags
- **Import-Button:** Trip in eigene Favoriten importieren
- **Share-Button:** Trip teilen (Coming Soon)
- **Map-Button:** Trip auf Karte anzeigen (Coming Soon)

### 3. Trip Veroeffentlichen

**Widget:** `lib/features/social/widgets/publish_trip_sheet.dart`

- **Bottom Sheet UI:** Ziehbares Sheet mit Formular
- **Trip-Info:** Typ (Tagestrip/Euro Trip), Stops, Distanz, Dauer
- **Name-Eingabe:** Pflichtfeld mit Validierung (min. 3 Zeichen)
- **Beschreibung:** Optional, max. 500 Zeichen
- **Tag-Auswahl:** 14 vordefinierte Tags, max. 5 waehlbar
- **Info-Hinweis:** Erklaerung was veroeffentlicht wird
- **Loading-State:** Spinner waehrend Veroeffentlichung

### 4. Trip-Karten

**Widget:** `lib/features/social/widgets/public_trip_card.dart`

- **Kompakte Karte:** Thumbnail, Name, Statistiken, Author
- **Featured Badge:** Stern-Badge fuer hervorgehobene Trips
- **Trip-Typ Badge:** Tagestrip/Euro Trip Label
- **Like-Button:** Mit Like-Counter auf dem Thumbnail
- **Tag-Vorschau:** Erste 3 Tags als Chips

**Widget:** `FeaturedTripCard` - Breitere Karte fuer Featured-Section

---

## Backend: Supabase Schema

**Migration:** `backend/supabase/migrations/003_social_features.sql`

### Neue Tabellen

| Tabelle | Beschreibung |
|---------|--------------|
| `user_profiles` | Benutzerprofile mit display_name, avatar_url, bio |
| `public_trips` | Veroeffentlichte Trips mit trip_data JSONB |
| `trip_likes` | Like-Beziehungen (user_id, trip_id) |
| `trip_imports` | Import-Historie (user_id, trip_id) |

### RPC Funktionen

| Funktion | Beschreibung |
|----------|--------------|
| `publish_trip` | Trip veroeffentlichen mit Metadaten |
| `get_public_trip` | Einzelnen Trip mit Author-Info laden |
| `search_public_trips` | Trips suchen/filtern mit Pagination |
| `like_trip` | Trip liken (inkrementiert likes_count) |
| `unlike_trip` | Like entfernen (dekrementiert likes_count) |
| `import_trip` | Trip importieren und in trip_imports eintragen |

### RLS Policies

- `public_trips`: Jeder kann lesen, nur eigene erstellen/bearbeiten
- `trip_likes`: Eigene Likes erstellen/loeschen
- `trip_imports`: Eigene Imports erstellen
- `user_profiles`: Eigenes Profil bearbeiten

---

## Provider & Repository

### SocialRepository

**Datei:** `lib/data/repositories/social_repo.dart`

```dart
// Galerie laden
Future<List<PublicTrip>> searchPublicTrips({
  String? searchQuery,
  List<String>? tags,
  String? tripType,
  String sortBy,
  int limit,
  int offset,
});

// Trip veroeffentlichen
Future<PublicTrip?> publishTrip({
  required Trip trip,
  required String tripName,
  String? description,
  List<String>? tags,
});

// Like-Funktionen
Future<bool> likeTrip(String tripId);
Future<bool> unlikeTrip(String tripId);

// Import-Funktion
Future<Map<String, dynamic>?> importTrip(String tripId);
```

### GalleryProvider

**Datei:** `lib/data/providers/gallery_provider.dart`

```dart
@riverpod
class GalleryNotifier extends _$GalleryNotifier {
  Future<void> loadGallery();
  Future<void> loadMore();
  Future<void> search(String query);
  void clearSearch();
  void setSortBy(GallerySortBy sort);
  void setTripTypeFilter(GalleryTripTypeFilter filter);
  void toggleTag(String tag);
  void resetFilters();
  Future<void> toggleLike(String tripId);
}
```

### TripDetailProvider

**Datei:** `lib/data/providers/gallery_provider.dart`

```dart
@riverpod
class TripDetailNotifier extends _$TripDetailNotifier {
  Future<void> loadTrip();
  Future<void> toggleLike();
  Future<Map<String, dynamic>?> importTrip();
}
```

---

## Datenmodell

### PublicTrip

**Datei:** `lib/data/models/public_trip.dart`

```dart
@freezed
class PublicTrip with _$PublicTrip {
  final String id;
  final String tripName;
  final String? description;
  final String? thumbnailUrl;
  final List<String> tags;
  final int likesCount;
  final int viewsCount;
  final bool isFeatured;
  final bool isLikedByMe;
  final bool isImportedByMe;
  final Map<String, dynamic> tripData;

  // Author Info (nullable)
  final String? authorName;
  final String? authorAvatar;
  final int? authorTotalTrips;

  // Computed Properties
  bool get isEuroTrip;
  bool get hasAuthorInfo;
  int get stopCount;
  int get dayCount;
  String get formattedDistance;
  String get statsLine;
}
```

---

## Lokalisierung

### Neue ARB-Keys (26 Strings)

**Galerie:**
```json
"galleryTitle": "Trip-Galerie",
"gallerySearch": "Trips suchen...",
"galleryFeatured": "Empfohlen",
"galleryAllTrips": "Alle Trips",
"galleryFilter": "Filter",
"galleryFilterReset": "Zuruecksetzen",
"galleryTripType": "Trip-Typ",
"galleryTags": "Tags",
"gallerySort": "Sortierung",
"galleryNoTrips": "Keine Trips gefunden",
"galleryResetFilters": "Filter zuruecksetzen",
"galleryRetry": "Erneut versuchen",
"galleryShowOnMap": "Auf Karte",
"galleryShareComingSoon": "Teilen kommt bald!",
"galleryMapComingSoon": "Kartenansicht kommt bald!",
"galleryImportSuccess": "Trip erfolgreich importiert!",
"galleryImportError": "Import fehlgeschlagen"
```

**Veroeffentlichen:**
```json
"publishTitle": "Trip veroeffentlichen",
"publishSubtitle": "Teile deinen Trip mit der Community",
"publishEuroTrip": "Euro Trip",
"publishDaytrip": "Tagestrip",
"publishTripName": "Trip-Name",
"publishTripNameHint": "Gib deinem Trip einen Namen",
"publishTripNameRequired": "Bitte gib einen Namen ein",
"publishTripNameMinLength": "Name muss mindestens 3 Zeichen haben",
"publishDescription": "Beschreibung",
"publishDescriptionHint": "Was macht diesen Trip besonders?",
"publishTags": "Tags",
"publishTagsHelper": "Waehle bis zu 5 Tags",
"publishMaxTags": "Maximal 5 Tags erlaubt",
"publishInfo": "Dein Trip wird oeffentlich sichtbar sein. Andere Nutzer koennen ihn liken und importieren.",
"publishButton": "Veroeffentlichen",
"publishPublishing": "Wird veroeffentlicht...",
"publishSuccess": "Trip erfolgreich veroeffentlicht!",
"publishError": "Veroeffentlichung fehlgeschlagen"
```

---

## Navigation

### Neue Routes (GoRouter)

```dart
'/gallery'          → GalleryScreen
'/gallery/:id'      → TripDetailPublicScreen
'/profile/:userId'  → ProfileScreen (Author-Profil)
```

### Einstiegspunkte

1. **MapScreen:** Neuer "Galerie" Button in der AppBar
2. **TripScreen:** "Trip veroeffentlichen" im Menue
3. **FavoritesScreen:** "Trip teilen" Button bei gespeicherten Routen

---

## Betroffene Dateien

### Neue Dateien (8)
| Datei | Beschreibung |
|-------|--------------|
| `lib/features/social/gallery_screen.dart` | Galerie-Hauptscreen |
| `lib/features/social/trip_detail_public_screen.dart` | Trip-Detail |
| `lib/features/social/widgets/public_trip_card.dart` | Trip-Karte |
| `lib/features/social/widgets/publish_trip_sheet.dart` | Publish-Sheet |
| `lib/data/models/public_trip.dart` | PublicTrip Model |
| `lib/data/providers/gallery_provider.dart` | Galerie-Provider |
| `lib/data/repositories/social_repo.dart` | Social-Repository |
| `backend/supabase/migrations/003_social_features.sql` | DB-Migration |

### Geaenderte Dateien (5)
| Datei | Aenderung |
|-------|-----------|
| `lib/l10n/app_de.arb` | +26 Lokalisierungs-Keys |
| `lib/l10n/app_en.arb` | +26 englische Uebersetzungen |
| `lib/l10n/app_fr.arb` | +26 franzoesische Uebersetzungen |
| `lib/l10n/app_it.arb` | +26 italienische Uebersetzungen |
| `lib/l10n/app_es.arb` | +26 spanische Uebersetzungen |

---

## Verifikation

1. **Galerie oeffnen:** Trips werden geladen
2. **Suche testen:** Ergebnisse werden gefiltert
3. **Trip-Detail:** Statistiken, Author, Tags korrekt
4. **Like-Button:** Like-Counter aendert sich
5. **Import-Button:** Trip erscheint in Favoriten
6. **Trip veroeffentlichen:** Sheet oeffnet, Validierung, Erfolgsmeldung
7. **Lokalisierung:** Alle Sprachen getestet

---

## Statistik

| Metrik | Wert |
|--------|------|
| Neue Screens | 2 |
| Neue Widgets | 3 |
| Neue Provider | 2 |
| Neue ARB-Keys | 26 |
| Supabase-Tabellen | 4 |
| RPC-Funktionen | 6 |
| APK-Groesse | 117.9 MB |
