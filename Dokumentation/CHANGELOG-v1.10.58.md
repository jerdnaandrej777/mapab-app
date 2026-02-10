# Changelog v1.10.58 - DayEditor UX, Journal-Persistenz-Fix, PopupMenu

**Release-Datum:** 10. Februar 2026
**APK Build:** 242

## Highlights

- AI-Empfehlungen im DayEditor einklappbar (AnimatedSize-Toggle)
- MiniMap-POIs anklickbar mit Navigation zu POI-Details
- DayStats im TripSummary-Gradient-Design
- Journal-Persistenz tiefgreifend gefixt (Null-Guards, Background-Updates, Logging)
- PopupMenu bei Trip-Stops vereinfacht (nur "Entfernen")

---

## Aenderungen im Detail

### AI-Empfehlungen einklappbar

**Datei:** `lib/features/trip/widgets/day_editor_overlay.dart`

- Neues `_CollapsibleAISuggestions` Widget ersetzt `_AISuggestionsSection`
- AnimatedSize-Toggle analog zum Hoehenprofil-Pattern
- Header mit Icon `auto_awesome` + Titel + Anzahl-Badge + Expand/Collapse-Icon
- Default: zugeklappt, Loading-State zeigt Spinner im Header
- Ohne Empfehlungen: "Empfehlungen laden" Button (wie bisher)

### MiniMap-POIs anklickbar

**Dateien:** `lib/features/trip/widgets/day_mini_map.dart`, `lib/features/trip/widgets/day_editor_overlay.dart`

- Neuer `ValueChanged<TripStop>? onStopTap` Callback auf `DayMiniMap`
- GestureDetector um nummerierte POI-Marker gewickelt
- Tap navigiert zu POI-Details via `stop.toPOI()` + `context.push('/poi/${stop.poiId}')`
- Enrichment wird automatisch gestartet

### DayStats im Gradient-Design

**Datei:** `lib/features/trip/widgets/day_editor_overlay.dart`

- `_DayStats` Container mit LinearGradient (AppTheme.primaryColor -> AppTheme.primaryDark)
- Bei Warnungen (>9 Stops, >700km): orange Gradient statt blau
- `_StatChip` mit onPrimary (weisse) Farbe fuer Text und Icons
- Vertikale Divider zwischen Stats (1x40 in onPrimary.withValues(alpha: 0.3))
- Warnungs-Text in Colors.yellow.shade200
- BoxShadow mit primaryColor alpha 0.3 und blurRadius 12

### Journal-Persistenz-Fix

**Dateien:** `lib/data/providers/journal_provider.dart`, `lib/data/services/journal_service.dart`

**Provider-Fixes:**
- `_refreshActiveJournal()` ruft nicht mehr `loadAllJournals()` auf - stattdessen `_loadAllJournalsInBackground()`
- `setActiveJournal()` hat jetzt Null-Guard: `journal ?? state.activeJournal`
- `getOrCreateJournal()` prüft mit `hasEntriesForTrip()` ob Eintraege existieren bevor Journal-Metadaten neu erstellt werden
- Background-Update von allJournals in separatem Future (non-blocking)

**Service-Fixes:**
- Neue `hasEntriesForTrip()` Methode: Prueft tripId-Feld direkt ohne volles Parsing
- Robusterer `_deepCast()`: Expliziter Type-Check (`data is! Map`), key.toString() statt Map.from()-Cast
- `getJournal()`: Detailliertes Logging mit StackTrace (top 5 Frames) und Rohdaten-Typ bei Fehlern
- `_getEntriesForTrip()`: Error-Count + Rohdaten-Logging (Typ + Keys) fuer fehlerhafte Eintraege
- `getAllJournals()`: Error-Count Logging bei fehlgeschlagenen Journal-Ladungen

### PopupMenu vereinfacht

**Dateien:** `lib/features/trip/widgets/trip_stop_tile.dart`, `lib/features/trip/trip_screen.dart`

- "Bearbeiten" aus PopupMenu entfernt (redundant - onTap navigiert bereits zu POI-Details)
- `onEdit` Parameter aus TripStopTile entfernt
- `onEdit` Callback in trip_screen.dart entfernt
- PopupMenuButton bleibt mit 3-Punkte-Icon, nur "Entfernen" als Option

---

## Betroffene Dateien

| Datei | Aenderung |
|-------|-----------|
| `pubspec.yaml` | Version 1.10.58+242 |
| `lib/features/trip/widgets/day_editor_overlay.dart` | AI-Empfehlungen einklappbar, MiniMap onStopTap, DayStats Gradient |
| `lib/features/trip/widgets/day_mini_map.dart` | onStopTap Callback + GestureDetector |
| `lib/features/trip/widgets/trip_stop_tile.dart` | onEdit entfernt, PopupMenu nur "Entfernen" |
| `lib/features/trip/trip_screen.dart` | onEdit Callback entfernt |
| `lib/data/providers/journal_provider.dart` | Persistenz-Fixes: Background-Updates, Null-Guards |
| `lib/data/services/journal_service.dart` | hasEntriesForTrip(), robusterer _deepCast(), Fehler-Logging |
| `qr-code-download.html` | Version aktualisiert |
| `docs/qr-code-download.html` | Version aktualisiert |
| `CLAUDE.md` | Release-Notes aktualisiert |
