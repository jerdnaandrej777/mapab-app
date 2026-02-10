# Changelog v1.10.57 - Journal-Persistenz, POI-Publish, Lade-Widget, DayEditor UX

**Datum:** 10. Februar 2026
**Build:** 241
**Typ:** Bugfix + UX-Verbesserung

---

## Zusammenfassung

5 Bugfixes und UX-Verbesserungen:
- Reisetagebuch-Eintraege verschwinden nicht mehr nach App-Neustart
- POIs behalten angereicherte Daten (Bilder, Beschreibungen) beim Veroeffentlichen
- Prozentanzeige im Lade-Widget nur noch einmal (im Ring)
- DayEditorOverlay: Einheitlicher Zurueck-Button statt Kreuz
- DayEditorOverlay: Aufklappbares Hoehenprofil wie im "Deine Route" Modal

---

## Fix 1: Reisetagebuch-Eintraege verschwinden

### Problem
Journal-Eintraege verschwanden nach App-Neustart. Hive speichert Maps als `Map<dynamic, dynamic>`, aber `Map<String, dynamic>.from()` scheitert bei verschachtelten Maps. Wenn `getJournal()` fehlschlug und null zurueckgab, setzte `_refreshActiveJournal()` das activeJournal auf null.

### Aenderungen

**journal_service.dart:**
- Neue `_deepCast()` Methode fuer rekursive Map-Konvertierung (`Map<dynamic, dynamic>` -> `Map<String, dynamic>`)
- 3 Stellen von `Map<String, dynamic>.from(data)` durch `_deepCast(data)` ersetzt (getJournal, deleteEntry, _getEntriesForTrip)

**journal_provider.dart:**
- Null-Guard in `_refreshActiveJournal()`: `activeJournal: journal ?? state.activeJournal` - vorheriger Wert bleibt bei Ladefehler erhalten

---

## Fix 2: POIs nach Veroeffentlichen ohne Bilder/Daten

### Problem
`_collectSourcePOIs()` in publish_trip_sheet.dart suchte POIs nur in 2 Quellen (tripState + randomTrip), aber nicht im globalen POI-State. Angereicherte Daten (imageUrl, description, tags) gingen beim Publish verloren.

### Aenderungen

**publish_trip_sheet.dart:**
- Import `poi_state_provider.dart` hinzugefuegt
- Dritte POI-Quelle in `_collectSourcePOIs()`: Globaler POI-State als Fallback fuer angereicherte Daten

---

## Fix 3: Prozent-Anzeige doppelt im Lade-Widget

### Problem
`generation_progress_indicator.dart` zeigte `$percent%` sowohl im `_AnimatedProgressRing` (Mitte des Kreises) als auch als grosser Text darunter.

### Aenderungen

**generation_progress_indicator.dart:**
- Doppelte Prozent-Anzeige (SizedBox + Text `$percent%`) aus `_buildMainContent()` entfernt
- Prozent bleibt elegant im Ring sichtbar

---

## Fix 4: Kreuz durch Zurueck-Button ersetzen

### Problem
DayEditorOverlay nutzte `Icons.close`, alle anderen Screens nutzen `Icons.arrow_back`.

### Aenderungen

**day_editor_overlay.dart:**
- `Icons.close` -> `Icons.arrow_back` in der AppBar

---

## Fix 5: Hoehenprofil im DayEditorOverlay

### Problem
Der DayEditor zeigte kein Hoehenprofil, obwohl das "Deine Route" Modal eines hat.

### Aenderungen

**day_editor_overlay.dart:**
- 3 neue Imports: `elevation_provider.dart`, `elevation_chart.dart`, `trip_statistics_card.dart`
- Neue State-Variable `_elevationExpanded` (default: zugeklappt)
- Elevation-Daten werden via `elevationNotifierProvider` geladen und gecacht
- Aufklappbares Hoehenprofil-Widget nach DayStats eingefuegt:
  - Kompakte Zeile mit Terrain-Icon, "Hoehenprofil", Anstieg/Abstieg Stats, Expand-Icon
  - AnimatedSize Container mit `ElevationChart(showHeader: false)` + `TripStatisticsCard`
  - Loading-Indikator waehrend Daten geladen werden
  - Gleiches Pattern wie in trip_screen.dart

---

## Geaenderte Dateien

| Datei | Aenderung |
|-------|-----------|
| `lib/data/services/journal_service.dart` | `_deepCast()` Helper, 3x Map-Konvertierung ersetzt |
| `lib/data/providers/journal_provider.dart` | Null-Guard in `_refreshActiveJournal()` |
| `lib/features/social/widgets/publish_trip_sheet.dart` | 3. POI-Quelle (globaler POI-State) |
| `lib/features/random_trip/widgets/generation_progress_indicator.dart` | Doppelte Prozent-Anzeige entfernt |
| `lib/features/trip/widgets/day_editor_overlay.dart` | Zurueck-Button + aufklappbares Hoehenprofil |
| `pubspec.yaml` | Version 1.10.57+241 |

---

## Verifizierung

- `flutter analyze` auf allen 5 Dateien: Keine Fehler/Warnings (nur pre-existing Info-Level Lints)
- Journal: Eintraege bleiben nach App-Neustart erhalten
- Publish: POI-Bilder/Beschreibungen in Galerie sichtbar
- Lade-Widget: Prozent nur einmal im Ring
- DayEditor: Zurueck-Pfeil statt Kreuz, aufklappbares Hoehenprofil
