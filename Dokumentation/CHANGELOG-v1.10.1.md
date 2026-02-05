# CHANGELOG v1.10.1 - Galerie-Bugfix-Release

**Datum:** 5. Februar 2026
**Build:** 181

## Zusammenfassung

Bugfix-Release zur Behebung kritischer Fehler in der Trip-Galerie (Social Features).

## Bugfixes

### 1. Galerie-Ladefehler behoben

**Problem:** Die Trip-Galerie zeigte einen Fehler:
```
PostgrestException(message: Could not find the table 'public.public_trips'
in the schema cache, code: PGRST205, details: Not Found,
hint: Perhaps you meant the table 'public.trips')
```

**Ursache:** In `social_repo.dart` wurde der falsche Tabellenname `public_trips` verwendet, obwohl die Supabase-Tabelle `trips` heißt.

**Lösung:** Alle 4 Vorkommen von `.from('public_trips')` zu `.from('trips')` geändert:
- `loadFeaturedTrips()` - Zeile 74
- `loadUserTrips()` - Zeile 118
- `deletePublishedTrip()` - Zeile 240
- `loadMyPublishedTrips()` - Zeile 258

**Datei:** `lib/data/repositories/social_repo.dart`

### 2. Filter-Chip-Textfarben korrigiert

**Problem:** In der Galerie waren die Texte auf den Filter-Chips (Alle, Tagesausflug, Euro Trip) nicht sichtbar - nur der ausgewählte "Alle"-Chip zeigte Text.

**Ursache:** Die Standard-FilterChip-Farben im Material 3 Theme passten nicht zum App-Design.

**Lösung:** Explizite Textfarben für alle Chips gesetzt:
- Ausgewählt: `colorScheme.onPrimary` (weiß auf primärer Farbe)
- Nicht ausgewählt: `colorScheme.onSurface` (Standard-Textfarbe)

Zusätzlich wurden `selectedColor` und `backgroundColor` explizit gesetzt.

**Betroffene Widgets:**
- FilterChip für Trip-Typ-Filter (Hauptscreen)
- ChoiceChip für Trip-Typ-Filter (Filter-Sheet)
- FilterChip für Tags (#roadtrip, #natur, etc.)
- RadioListTile für Sortierung

**Datei:** `lib/features/social/gallery_screen.dart`

### 3. Galerie-Filter-Sheet auf Vollbild

**Verbesserung:** Das Filter-Sheet öffnet sich jetzt im Vollbild-Modus für bessere Bedienbarkeit:
- `initialChildSize: 1.0`
- `minChildSize: 0.9`
- `maxChildSize: 1.0`
- `useSafeArea: true`

## Technische Details

### Geänderte Dateien

| Datei | Änderung |
|-------|----------|
| `lib/data/repositories/social_repo.dart` | Tabellenname `public_trips` → `trips` |
| `lib/features/social/gallery_screen.dart` | Chip-Styling + Filter-Sheet-Vollbild |
| `pubspec.yaml` | Version 1.10.0+180 → 1.10.1+181 |

### Betroffene Features

- Trip-Galerie (Laden, Featured, User-Trips)
- Galerie-Filter (Trip-Typ, Tags, Sortierung)
- Eigene veröffentlichte Trips

## Migration

Keine Datenbank-Migration erforderlich. Die Tabelle `trips` existierte bereits in Supabase.

## Bekannte Einschränkungen

- Die RPC-Funktionen (`search_public_trips`, `get_public_trip`, etc.) müssen in Supabase korrekt eingerichtet sein
- Für die Galerie wird eine aktive Internetverbindung benötigt

---

**Vollständige Änderungsliste:** Siehe Git-Commit-History
