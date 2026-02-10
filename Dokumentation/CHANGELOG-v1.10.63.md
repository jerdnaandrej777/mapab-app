# CHANGELOG v1.10.63

**Datum:** 10. Februar 2026
**Beschreibung:** POI-Publish Backend-Fix, Journal-Persistenz Race Condition behoben

---

## Zusammenfassung

POI-Veroeffentlichen schlug fehl weil die Supabase-Tabelle `poi_posts` nicht existierte. Neue idempotente Migration erstellt. Journal-Eintraege verschwanden durch eine Race Condition in `_loadAllJournalsInBackground()` - fire-and-forget ueberschrieb frische Daten mit veralteten. Beide Bugs behoben.

---

## Geaendert

### Backend: POI-Publish Migration (Supabase)

- **Neue idempotente Migration**: `20260210140000_poi_gallery_social.sql` erstellt alle fehlenden Tabellen (`poi_posts`, `poi_post_likes`, `poi_votes`, `user_reputation`) + View + 8 RPC Functions
- **PGRST205-Fehlerbehandlung**: `social_repo.dart` faengt jetzt auch fehlende Tabellen (PGRST205) ab und gibt eine klare Fehlermeldung mit Migrations-Hinweis statt kryptischem PostgrestException
- **Voraussetzung**: Migration muss manuell im Supabase SQL Editor ausgefuehrt werden

### Journal: Race Condition behoben

- **`_loadAllJournalsInBackground()` entfernt**: Fire-and-forget `Future` ueberschrieb `allJournals` mit veralteten Daten nach dem Hinzufuegen neuer Eintraege
- **`_updateAllJournalsWithActive()` neu**: Synchrone, atomare Aktualisierung der Journal-Liste ohne async Hintergrund-Laden
- **`clearSelectedDay` Parameter**: `JournalState.copyWith()` kann jetzt `selectedDay` korrekt auf null setzen (`closeActiveJournal()` funktionierte vorher nicht richtig)

---

## Betroffene Dateien

| Datei | Aenderung |
|-------|-----------|
| `pubspec.yaml` | Version 1.10.62+246 -> 1.10.63+247 |
| `supabase/migrations/20260210140000_poi_gallery_social.sql` | Neue idempotente Migration fuer poi_posts + Social Features |
| `lib/data/repositories/social_repo.dart` | PGRST205-Fehlerbehandlung im publishPOI() Fallback |
| `lib/data/providers/journal_provider.dart` | Race Condition Fix: `_loadAllJournalsInBackground()` -> `_updateAllJournalsWithActive()`, `clearSelectedDay` Parameter |

---

## Migrations-Anleitung

**POI-Publish aktivieren:**
1. Supabase Dashboard oeffnen -> SQL Editor
2. Inhalt von `supabase/migrations/20260210140000_poi_gallery_social.sql` einfuegen
3. Ausfuehren - erstellt 4 Tabellen, 1 View, 8 RPC Functions, Indexes + RLS Policies
4. Danach funktioniert POI-Veroeffentlichen ueber den Globe-Button auf der POI-Detailseite

---

## Fehlerbehebungen

| Bug | Ursache | Fix |
|-----|---------|-----|
| POI-Publish: "Could not find table poi_posts" (PGRST205) | Migration 011_poi_gallery_social.sql nie auf Supabase ausgefuehrt | Neue idempotente Migration + bessere Fehlerbehandlung |
| Journal-Eintraege verschwinden | `_loadAllJournalsInBackground()` ueberschreibt State mit veralteten Daten | Synchrone `_updateAllJournalsWithActive()` statt async Background-Load |
| `closeActiveJournal()` setzt selectedDay nicht zurueck | `copyWith(selectedDay: null)` wurde durch `??` ignoriert | Neuer `clearSelectedDay` Parameter |
