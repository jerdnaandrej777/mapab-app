# CHANGELOG v1.10.4 - AI Euro Trip Crash-Fix

**Datum:** 2026-02-05
**Build:** 185

## Zusammenfassung

Kritische Bugfixes für Abstürze bei der AI Euro Trip Generierung. Zwei Race Conditions im POI-Enrichment-System wurden behoben.

## Bugfixes

### 1. ConcurrentModificationException in `_flushPendingEnrichments()` (KRITISCH)

**Problem:**
Die `_pendingEnrichments` Map wurde während der Iteration modifiziert, wenn `onPartialResult` gleichzeitig aufgerufen wurde. Dies führte zu einem sofortigen App-Crash.

**Ursache:**
```dart
// VORHER - Crash bei gleichzeitigem Callback
for (final entry in _pendingEnrichments.entries) {
  // ... onPartialResult könnte hier _pendingEnrichments.addAll() aufrufen
}
_pendingEnrichments.clear();
```

**Lösung:**
Die Map wird jetzt **kopiert und geleert BEVOR** die Iteration beginnt:
```dart
// NACHHER - Thread-safe
final enrichmentsToProcess = Map<String, POI>.from(_pendingEnrichments);
_pendingEnrichments.clear();
for (final entry in enrichmentsToProcess.entries) {
  // Sicher - enrichmentsToProcess wird nicht modifiziert
}
```

**Datei:** `lib/features/poi/providers/poi_state_provider.dart`

---

### 2. Debouncer Race Condition in `enrichPOIsBatch()` (KRITISCH)

**Problem:**
Der Debouncer-Timer konnte feuern nachdem `enrichPOIsBatch()` bereits beendet war, was zu:
- Doppelten State-Updates
- State-Inkonsistenzen
- Potentiellen Crashes führte

**Ursache:**
```dart
// VORHER - Timer könnte nach Batch-Ende noch feuern
_enrichmentDebouncer = Timer(Duration(milliseconds: 300), () {
  _flushPendingEnrichments(); // Könnte nach finalem Flush aufgerufen werden
});
// ... später ...
_enrichmentDebouncer?.cancel();
_flushPendingEnrichments(); // Finaler Flush
```

**Lösung:**
Ein `_enrichmentBatchActive` Flag verhindert jetzt Race Conditions:
```dart
// NACHHER - Flag-basierte Kontrolle
bool _enrichmentBatchActive = false;

// Im Callback:
if (!_enrichmentBatchActive) return; // Ignoriere nach Batch-Ende

// Am Batch-Ende:
_enrichmentBatchActive = false; // ZUERST deaktivieren
_enrichmentDebouncer?.cancel();
_flushPendingEnrichments(); // Dann finaler Flush
```

**Datei:** `lib/features/poi/providers/poi_state_provider.dart`

---

## Technische Details

### Betroffene Dateien

| Datei | Änderungen |
|-------|------------|
| `lib/features/poi/providers/poi_state_provider.dart` | `_enrichmentBatchActive` Flag, Map-Kopie vor Iteration |
| `pubspec.yaml` | Version 1.10.4+185 |

### Symptome vor dem Fix

- App stürzt ab beim Klicken auf "Überrasch mich!" (AI Euro Trip)
- Crash tritt besonders bei vielen POIs auf (> 10)
- Sporadisch: Crash beim Enrichment von POI-Bildern
- Fehlermeldung: `ConcurrentModificationException` oder State-Corruption

### Verifikation

Nach dem Fix:
- AI Euro Trip kann ohne Absturz generiert werden
- POI-Bilder werden korrekt im Hintergrund geladen
- Keine Race Conditions mehr zwischen UI und Enrichment

---

## Upgrade-Hinweise

Keine manuellen Schritte erforderlich. Einfach die neue Version installieren.
