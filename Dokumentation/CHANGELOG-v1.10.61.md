# Changelog v1.10.61 - Journal editierbar, Erneut-besuchen-Flow

**Datum:** 10. Februar 2026
**Build:** 245

## Zusammenfassung

Tagebuch-Eintraege sind jetzt editierbar (Notiz aendern, Foto ersetzen/entfernen). Die Funktion "Tagebuch loeschen" wurde entfernt - nur einzelne Eintraege koennen geloescht werden. Der "Erneut besuchen"-Flow zeigt die Route jetzt auf der Karte mit Fokus-Footer statt direkt zum TripScreen zu navigieren.

## Aenderungen

### Neues Feature: Journal-Eintraege bearbeiten

- **EditJournalEntrySheet** (`lib/features/journal/widgets/edit_journal_entry_sheet.dart`): Neues Vollbild-Widget zum Bearbeiten bestehender Eintraege.
  - Pre-populated Notiz-TextField mit aktuellem Text
  - Aktuelles Foto mit Ersetzen (Kamera/Galerie) und Entfernen Buttons
  - Speichern via `journalNotifierProvider.updateEntry()` mit automatischem Cloud-Sync
- **Bearbeiten-Button** im `_EntryDetailsSheet`: Neuer Button neben "Auf Karte anzeigen" und "Details"
- **pickAndSavePhoto()** in `JournalService`: Wiederverwendbare Methode fuer Foto-Auswahl und Speicherung im App-Verzeichnis

### Tagebuch-Loeschung entfernt

- Delete-IconButton aus der Journal-AppBar entfernt
- `_showDeleteConfirmation()` Methode entfernt
- Einzelne Eintraege koennen weiterhin ueber die Entry-Card geloescht werden

### Erneut-besuchen-Flow verbessert

- `_handleRevisitMemoryPoint()` in `map_screen.dart`: Navigiert nicht mehr zu `/trip`, sondern aktiviert `mapRouteFocusModeProvider`
- Die Route wird auf der Karte angezeigt mit dem Fokus-Footer ("Trip bearbeiten", "Navigation starten", "Route loeschen")
- Benutzer bleibt auf der Karte und kann direkt die Navigation starten

### Lokalisierung

- 4 neue l10n-Keys in 5 Sprachen (DE/EN/FR/IT/ES):
  - `journalEditEntry`: "Eintrag bearbeiten"
  - `journalReplacePhoto`: "Foto ersetzen"
  - `journalRemovePhoto`: "Foto entfernen"
  - `journalSaveChanges`: "Aenderungen speichern"

## Geaenderte Dateien

| Datei | Aenderung |
|-------|-----------|
| `lib/features/journal/widgets/edit_journal_entry_sheet.dart` | NEU: Edit-Sheet Widget |
| `lib/features/journal/journal_screen.dart` | AppBar Delete-Button entfernt, Edit-Button in Details-Sheet |
| `lib/features/map/map_screen.dart` | Erneut-besuchen nutzt mapRouteFocusModeProvider |
| `lib/data/services/journal_service.dart` | pickAndSavePhoto() hinzugefuegt |
| `lib/l10n/app_de.arb` | 4 neue Keys |
| `lib/l10n/app_en.arb` | 4 neue Keys |
| `lib/l10n/app_fr.arb` | 4 neue Keys |
| `lib/l10n/app_it.arb` | 4 neue Keys |
| `lib/l10n/app_es.arb` | 4 neue Keys |
| `pubspec.yaml` | Version 1.10.61+245 |
