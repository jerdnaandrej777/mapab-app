# Changelog v1.10.65 - Journal-Persistenz Cloud-Restore

**Datum:** 10. Februar 2026
**Build:** 249

## Zusammenfassung

5 kritische Persistenz-Probleme im Reisetagebuch behoben. Journal-Eintraege verschwinden nicht mehr nach App-Neustart oder Update. Automatischer Cloud-Restore wenn lokale Hive-Daten verloren gehen.

## Problembeschreibung

Journal-Eintraege verschwanden nach App-Neustart oder Update. Ursachen:

1. **Hive-Box-Reset loescht ALLE Daten**: Bei Korruption der Hive-Box-Datei (z.B. nach Crash/ANR waehrend Schreibvorgang) wurde die gesamte Box geloescht und leer neu erstellt.
2. **Kein automatischer Cloud-Restore**: Beim App-Start wurden Journals ausschliesslich aus Hive geladen - nie aus der Cloud zurueckgeholt.
3. **Cloud-Sync fire-and-forget ohne Retry**: Fehlgeschlagene Cloud-Uploads wurden nur geloggt, nie erneut versucht.
4. **CloudRepo permanent null**: Wenn der User beim App-Start nicht eingeloggt war, blieb `cloudRepo` null fuer die gesamte Session.
5. **Kein Startup-Cloud-Sync**: `syncFromCloud()` wurde nie automatisch aufgerufen.

## Aenderungen

### Behoben

#### JournalService Cloud-Restore
- **`restoreAllFromCloud()`**: Neue Methode die alle Journals von Supabase holt und lokal in Hive wiederherstellt
- **`retryPendingSync()`**: Neue Methode die alle Eintraege mit `needsSync: true` erneut hochlaedt (inkl. Fotos)
- **`updateCloudRepo()`**: Neue Methode zum dynamischen Aktualisieren des Cloud-Repos nach Login/Logout
- **`isLocalEmpty` Getter**: Prueft ob Hive-Boxen leer sind (fuer Cloud-Restore-Entscheidung)

#### JournalProvider Startup-Sync
- **`_initService()`**: Prueft beim Start ob Hive leer ist und startet automatisch Cloud-Restore
- **Pending-Sync im Hintergrund**: Ungesynte Eintraege werden nach jedem Start nachtraeglich hochgeladen
- **Auth-State-Listener**: Nach Login wird `onAuthChanged()` aufgerufen, das Cloud-Restore/Sync triggert
- **Dynamisches CloudRepo**: `journalServiceProvider` beobachtet Auth-Aenderungen und aktiviert/deaktiviert CloudRepo

#### Cloud-Fallback in getOrCreateJournal
- Wenn ein Journal lokal nicht existiert, wird zuerst `syncJournalFromCloud()` versucht
- Cloud-Entries werden lokal gespeichert und Journal-Metadaten wiederhergestellt
- Erst wenn auch Cloud leer ist, wird ein neues leeres Journal erstellt

## Datenfluss vorher vs. nachher

```
VORHER:
  Eintrag erstellen -> Hive OK -> Cloud (fire-and-forget, kann fehlen)
  App Neustart      -> Hive lesen (kann leer sein nach Reset) -> Cloud restore? NEIN
  Nach Login        -> CloudRepo bleibt null -> NIE Cloud-Sync

NACHHER:
  Eintrag erstellen -> Hive OK -> Cloud (fire-and-forget + retry beim naechsten Start)
  App Neustart      -> Hive lesen -> leer? -> Cloud-Restore -> Pending-Sync
  Nach Login        -> CloudRepo aktiviert -> Cloud-Restore falls noetig -> Pending-Sync
```

## Betroffene Dateien

| Datei | Aenderung |
|-------|-----------|
| `lib/data/services/journal_service.dart` | `restoreAllFromCloud()`, `retryPendingSync()`, `updateCloudRepo()`, `isLocalEmpty`, `localEntryCount` |
| `lib/data/providers/journal_provider.dart` | Dynamisches CloudRepo mit Auth-Listener, Cloud-Restore in `_initService()`, `onAuthChanged()`, Cloud-Fallback in `getOrCreateJournal()` |
