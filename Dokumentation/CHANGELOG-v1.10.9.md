# Changelog v1.10.9 - Social Features DB-Fix & Route-Speichern-Buttons

**Datum:** 6. Februar 2026
**Build:** 190

## Zusammenfassung

Diese Version behebt den Supabase-Datenbankfehler für die Trip-Galerie und fügt Route-Speichern-Buttons im DayEditor und während der Navigation hinzu.

## Neue Features

### 1. TripSaveHelper Utility-Klasse

Neue zentrale Utility-Klasse für konsistentes Route-Speichern in der gesamten App.

**Datei:** `lib/features/trip/utils/trip_save_helper.dart`

**Methoden:**
- `saveRoute()` - Speichert normale Route mit Dialog
- `saveAITrip()` - Speichert AI Trip mit korrektem Typ (daytrip/eurotrip)
- `saveRouteDirectly()` - Speichert Route direkt mit übergebenen Parametern

**Features:**
- Dialog für Trip-Namen mit Autocomplete (Start → Ziel)
- Automatische Typ-Erkennung (Daytrip vs Eurotrip)
- Snackbar mit "In Favoriten anzeigen" Button
- Konsistente Lokalisierung via `context.l10n`

### 2. Route-Speichern-Button im DayEditor

**Datei:** `lib/features/trip/widgets/day_editor_overlay.dart`

- Neuer Speichern-Button in der AppBar (vor dem Refresh-Button)
- Nutzt `TripSaveHelper.saveAITrip()` für AI Trips
- Sichtbar wenn ein AI Trip aktiv ist

### 3. Route-Speichern-Button in der Navigation

**Datei:** `lib/features/navigation/navigation_screen.dart`
**Widget:** `lib/features/navigation/widgets/navigation_bottom_bar.dart`

- Neuer `onSave` Callback in `NavigationBottomBar`
- Bookmark-Icon Button zwischen Voice und Overview
- Nutzt `TripSaveHelper.saveRouteDirectly()` mit aktueller Route und Stops
- Tooltip: "Route speichern"

## Bugfixes

### Supabase Social Features DB-Fix

**Problem:** Die Trip-Galerie zeigte den Fehler "Could not find the table 'public.public_trips'" und "column is_hidden does not exist".

**Ursache:** Eine alte/unvollständige `trips` Tabelle existierte ohne die erforderlichen Spalten.

**Lösung:** Neue Migration `006_social_features_reset.sql`:

1. **Löscht alle alten Objekte:**
   - RPC Functions (search_public_trips, like_trip, etc.)
   - Tabellen (trip_imports, trip_likes, trips, public_trips, user_profiles)

2. **Erstellt vollständige Struktur:**
   - `user_profiles` - Benutzerprofile mit Statistiken
   - `trips` - Öffentliche Trips mit allen Spalten (inkl. is_hidden)
   - `trip_likes` - Like-Zuordnungen
   - `trip_imports` - Import-Zuordnungen

3. **Erstellt alle Indexes** für optimierte Abfragen

4. **Row Level Security Policies** für alle Tabellen

5. **RPC Functions:**
   - `search_public_trips()` - Trip-Suche mit Filtern
   - `like_trip()` / `unlike_trip()` - Like-Funktionen
   - `publish_trip()` - Trip veröffentlichen
   - `import_trip()` - Trip importieren
   - `get_public_trip()` - Trip-Details laden
   - `upsert_user_profile()` - Profil erstellen/aktualisieren
   - `increment_trip_views()` - View-Counter

### Client-Code Fix

**Datei:** `lib/data/repositories/social_repo.dart`

Bereits in v1.10.1 gefixt: Tabellenname von `public_trips` zu `trips` an 4 Stellen geändert.

## Geänderte Dateien

| Datei | Änderung |
|-------|----------|
| `lib/features/trip/utils/trip_save_helper.dart` | NEU: Utility-Klasse |
| `lib/features/trip/widgets/day_editor_overlay.dart` | Speichern-Button in AppBar |
| `lib/features/navigation/navigation_screen.dart` | _saveRoute() Methode + onSave Callback |
| `lib/features/navigation/widgets/navigation_bottom_bar.dart` | onSave Parameter + Button |
| `backend/supabase/migrations/006_social_features_reset.sql` | NEU: Vollständige DB-Migration |
| `CLAUDE.md` | Dokumentation aktualisiert |

## Installation

### Supabase Migration ausführen

1. Öffne den **Supabase SQL Editor**
2. Kopiere den Inhalt von `backend/supabase/migrations/006_social_features_reset.sql`
3. Füge ihn in den SQL Editor ein
4. Klicke auf **Run**

Das Script löscht alle alten Tabellen und erstellt die vollständige Social-Struktur neu.

## Technische Details

### TripSaveHelper Pattern

```dart
// Normale Route speichern
await TripSaveHelper.saveRoute(context, ref, tripState);

// AI Trip speichern
await TripSaveHelper.saveAITrip(context, ref, randomTripState);

// Route direkt speichern (mit Parametern)
await TripSaveHelper.saveRouteDirectly(
  context,
  ref,
  route: route,
  stops: stops,
  type: TripType.daytrip,
  days: 1,
);
```

### NavigationBottomBar onSave

```dart
NavigationBottomBar(
  // ... andere Parameter
  onSave: () async {
    await TripSaveHelper.saveRouteDirectly(
      context,
      ref,
      route: route,
      stops: stops,
    );
  },
)
```
