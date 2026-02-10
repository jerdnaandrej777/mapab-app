# CHANGELOG v1.10.59 - Journal Cloud Migration

**Datum:** 10. Februar 2026
**Build:** 243

## Uebersicht

Journal-Eintraege und Fotos werden jetzt sicher in Supabase Cloud gespeichert. Strikte Privatsphaere durch Row-Level-Security (RLS) - nur der eingeloggte User kann seine eigenen Daten sehen. Hybrid-Architektur: Hive (offline-first) + Supabase (Cloud-Backup) mit automatischem fire-and-forget Sync.

## Neue Dateien

### Backend
- **`backend/supabase/migrations/011_journal_entries.sql`**
  - journal_entries Tabelle mit RLS Policies (SELECT/INSERT/UPDATE/DELETE nur fuer Owner)
  - Performance-Indexes: user_trip, created_at DESC, day_number, photos
  - Trigger fuer automatisches updated_at
  - RPC Functions: get_user_journals (Trip-Uebersicht), get_journal_entries_for_trip, delete_journal
  - Storage Bucket Setup-Anleitung fuer journal-photos (privat)

### Flutter
- **`lib/data/repositories/journal_cloud_repo.dart`**
  - uploadEntry(): Upsert Journal Entry zu Supabase
  - uploadPhoto(): Foto komprimieren (1920px, 85% JPEG) und zu Storage hochladen
  - fetchEntriesForTrip(): Alle Eintraege eines Trips via RPC laden
  - fetchAllJournals(): Trip-Uebersicht mit Entry/Photo-Counts
  - deleteEntry(): Entry + zugehoeriges Foto aus Storage loeschen
  - deleteJournal(): Komplettes Journal (alle Entries eines Trips) via RPC loeschen
  - getLastSyncTime(): Letzter Sync-Zeitstempel fuer einen Trip

- **`lib/data/models/journal_entry_dto.dart`**
  - Data Transfer Object zwischen Supabase (snake_case) und Dart (camelCase)
  - fromJson(): Supabase Response -> DTO
  - toJson(): DTO -> Supabase Insert/Update
  - toModel(): DTO -> JournalEntry (App-Model)
  - fromModel(): JournalEntry -> DTO (fuer Upload)

- **`lib/features/journal/widgets/migration_dialog.dart`**
  - Einmaliger Dialog zum Hochladen lokaler Eintraege in die Cloud
  - Bestaetigung mit Info ueber Backup/Multi-Device/Auto-Sync
  - Loading-Dialog waehrend Migration
  - Erfolgs-Snackbar nach Abschluss

## Geaenderte Dateien

### Model
- **`lib/data/models/journal_entry.dart`**
  - Neue Felder: `photoStoragePath` (Cloud-URL), `syncedAt` (Sync-Timestamp), `needsSync` (Pending-Flag)
  - `photoUrl` Getter: Cloud-URL first, lokaler Pfad als Fallback
  - `isSynced` Getter: syncedAt != null && !needsSync

### Service
- **`lib/data/services/journal_service.dart`**
  - Neuer `cloudRepo` Parameter im Konstruktor (optional, fuer Cloud-Sync)
  - `addEntry()`: Setzt needsSync=true, ruft _syncEntryToCloud() fire-and-forget
  - `addEntryWithPhoto()`: Upload photo to cloud fire-and-forget
  - `updateEntry()`: Setzt needsSync=true, Sync fire-and-forget
  - `_syncEntryToCloud()`: Upload Entry, bei Erfolg syncedAt/needsSync updaten
  - `_uploadPhotoToCloud()`: Upload Foto, bei Erfolg photoStoragePath updaten
  - `_getEntryById()`: Helper fuer Entry-Lookup aus Hive
  - `syncJournalFromCloud()`: Cloud-Entries laden und mit lokalen mergen (Cloud wins)
  - `migrateLocalToCloud()`: Alle lokalen Entries + Fotos einmalig hochladen

### Provider
- **`lib/data/providers/journal_provider.dart`**
  - `journalServiceProvider`: Erstellt CloudRepo wenn User authentifiziert
  - `JournalState`: Neues `isSyncing` Feld
  - `JournalNotifier.syncFromCloud()`: Manueller Cloud-Sync
  - `JournalNotifier.migrateLocalToCloud()`: Migration-Trigger

### UI
- **`lib/features/journal/journal_screen.dart`**
  - Sync-Indicator (CircularProgressIndicator) in AppBar bei laufendem Sync
  - Cloud-Sync-Button (Icons.cloud_sync) in AppBar fuer manuellen Sync

## Architektur

```
Benutzer -> JournalNotifier -> JournalService
                                    |
                         +----------+----------+
                         |                     |
                    Hive (lokal)         JournalCloudRepo
                    (offline-first)      (Supabase Cloud)
                         |                     |
                    Sofort gespeichert    Fire-and-forget
                                          Sync im Background
```

### Sync-Strategie
- **Offline-first**: Immer zuerst lokal in Hive speichern
- **Fire-and-forget**: Cloud-Upload blockiert UI nicht
- **Cloud wins**: Bei Konflikten gewinnt der neuere Cloud-Eintrag (syncedAt)
- **needsSync Flag**: Markiert lokale Aenderungen die noch hochgeladen werden muessen

### Sicherheit
- RLS Policies: `auth.uid() = user_id` auf allen Operationen
- SECURITY DEFINER Functions: Zusaetzliche auth.uid()-Pruefung in RPCs
- Storage RLS: Ordnerstruktur `{user_id}/{trip_id}/{entry_id}.jpg`
- ON DELETE CASCADE: Automatische Bereinigung bei Account-Loeschung

## Betroffene Tests
- Bestehende Tests unveraendert (Cloud-Sync ist optional/fire-and-forget)
- Manuelle Tests empfohlen: Migration-Dialog, Sync-Button, Offline-Verhalten
