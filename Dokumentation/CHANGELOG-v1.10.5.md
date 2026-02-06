# CHANGELOG v1.10.5 - AI Euro Trip Crash-Fix (Enrichment Safety)

**Datum:** 2026-02-05
**Build:** 186

## Zusammenfassung

Kritischer Bugfix für App-Abstürze beim AI Euro Trip. Das Problem war, dass die POI-Enrichment-Methode ohne `await` aufgerufen wurde, wodurch Exceptions bei 27+ POIs nicht gefangen wurden und zum Crash führten.

## Bugfixes

### 1. Fire-and-Forget Async ohne Fehlerbehandlung (KRITISCH)

**Problem:**
Die `_enrichGeneratedPOIs()` Methode wurde ohne `await` aufgerufen. Bei async-Funktionen ohne await werden Exceptions NICHT vom äußeren try-catch gefangen - sie "verschwinden" im Hintergrund und können die App crashen.

**Unterschied Tagestrip vs Euro Trip:**
- **Tagestrip:** 3-8 POIs → wenig Last, selten Probleme
- **Euro Trip:** 27+ POIs → viele parallele Callbacks, Race Conditions

**Ursache:**
```dart
// VORHER - Fire-and-forget ohne Fehlerbehandlung
try {
  // ... Trip-Generierung ...
  _enrichGeneratedPOIs(result);  // <-- OHNE await!
} catch (e) {
  // Exception von _enrichGeneratedPOIs wird NICHT gefangen!
}
```

**Lösung:**
Neuer sicherer Wrapper mit `runZonedGuarded`:
```dart
// NACHHER - Zone-basierte Fehlerbehandlung
_safeEnrichGeneratedPOIs(result);

void _safeEnrichGeneratedPOIs(GeneratedTrip result) {
  runZonedGuarded(
    () async {
      await _enrichGeneratedPOIs(result);
    },
    (error, stackTrace) {
      // Fehler loggen aber nicht crashen
      debugPrint('[RandomTrip] Zone-Fehler: $error');
    },
  );
}
```

**Datei:** `lib/features/random_trip/providers/random_trip_provider.dart`

---

### 2. Überlastung bei 27+ POIs (KRITISCH)

**Problem:**
Bei Euro Trips wurden alle 27+ POIs auf einmal enriched, was zu:
- Überlastung des Enrichment-Services
- Zu vielen parallelen `onPartialResult` Callbacks
- ConcurrentModificationException trotz v1.10.4 Fixes

**Lösung:**
Sub-Batching mit maximal 10 POIs pro Batch und 200ms Pause dazwischen:
```dart
// NACHHER - Sub-Batching für große POI-Sets
const maxBatchSize = 10;
if (poisToEnrich.length > maxBatchSize) {
  for (var i = 0; i < poisToEnrich.length; i += maxBatchSize) {
    final subBatch = poisToEnrich.sublist(i, end);
    await poiNotifier.enrichPOIsBatch(subBatch);

    // Pause zwischen Sub-Batches
    if (end < poisToEnrich.length) {
      await Future.delayed(Duration(milliseconds: 200));
    }
  }
}
```

**Datei:** `lib/features/random_trip/providers/random_trip_provider.dart`

---

## Technische Details

### Betroffene Dateien

| Datei | Änderungen |
|-------|------------|
| `lib/features/random_trip/providers/random_trip_provider.dart` | `_safeEnrichGeneratedPOIs()` Wrapper, Sub-Batching mit max 10 POIs |
| `pubspec.yaml` | Version 1.10.5+186 |

### Symptome vor dem Fix

- App stürzt ab beim Klicken auf "Überrasch mich!" im Euro Trip Modus
- Crash tritt besonders bei vielen POIs auf (> 20)
- Tagestrip funktioniert normal (weniger POIs)
- Sporadische Crashes beim Wiederherstellen eines gespeicherten Euro Trips

### Warum v1.10.4 nicht ausreichte

Die v1.10.4 Fixes (ConcurrentModificationException, Debouncer Race Condition) waren korrekt, aber sie behandelten nur die Symptome innerhalb des Enrichment-Services. Das eigentliche Problem war, dass Exceptions in der fire-and-forget async-Methode nicht abgefangen wurden.

### Verifikation

Nach dem Fix:
- AI Euro Trip kann ohne Absturz generiert werden
- POI-Bilder werden schrittweise geladen (Sub-Batches sichtbar im Log)
- Keine unkontrollierten Exceptions mehr
- Wiederherstellen eines gespeicherten Euro Trips funktioniert

---

## Upgrade-Hinweise

Keine manuellen Schritte erforderlich. Einfach die neue Version installieren.

## Vergleich: Tagestrip vs Euro Trip

| Aspekt | Tagestrip | Euro Trip |
|--------|-----------|-----------|
| POI-Anzahl | 3-8 | 9-27+ |
| Enrichment | 1 Batch | 3+ Sub-Batches |
| Crash-Risiko vor Fix | Gering | Hoch |
| Crash-Risiko nach Fix | Minimal | Minimal |
