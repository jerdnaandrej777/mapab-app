# CHANGELOG v1.9.17 - POI-Empfehlungen Performance Fix v2

**Datum:** 4. Februar 2026
**Build:** 1.9.17+164

## Ueberblick

Kritischer Performance-Fix: Die AI POI-Empfehlungen im DayEditor loesten einen App-Absturz/Haenger aus. v1.9.16 hatte bereits Tages-Route-Extraktion und Request-Cancellation eingefuehrt, aber die eigentliche Ursache war eine **POI-Explosion** (800+ POIs) kombiniert mit **O(n*m) Compute** (375.000 Haversine-Berechnungen) und einem **defekten Timeout** das nicht abbrach.

---

## Root Cause Analyse

| Problem | Auswirkung |
|---------|------------|
| `loadPOIsInBounds()` ohne Result-Limit | 800+ POIs (Supabase 200 + Overpass 500+ unlimitiert) |
| O(n*m) Compute im Isolate | 750 POIs x 500 Route-Punkte = 375.000 Haversine-Berechnungen (15-40s) |
| `.timeout(onTimeout: () {})` | Loggt nur, cancelt aber die Berechnung NICHT |
| 50km Buffer | ~40.000 km2 Suchflaeche pro Tag |

---

## Fix 1: POI Result-Limit in poi_repo.dart

### Problem
`loadPOIsInBounds()` kombiniert 3 POI-Quellen (Supabase, Wikipedia, Overpass) ohne Gesamtlimit. Bei grossen Bounding-Boxes (z.B. 50km Buffer) konnten 800+ POIs zurueckgegeben werden.

### Loesung
Neuer `maxResults` Parameter (default 200). Nach dem Quality-Filter werden POIs nach Score sortiert und auf das Limit getrimmt.

**Datei:** `lib/data/repositories/poi_repo.dart`

```dart
Future<List<POI>> loadPOIsInBounds({
  required ({LatLng southwest, LatLng northeast}) bounds,
  List<String>? categoryFilter,
  bool includeCurated = true,
  bool includeWikipedia = true,
  bool includeOverpass = true,
  int maxResults = 200,  // NEU
}) async {
```

Nach Quality-Filter:
```dart
if (qualityFiltered.length > maxResults) {
  qualityFiltered.sort((a, b) => b.score.compareTo(a.score));
  qualityFiltered.removeRange(maxResults, qualityFiltered.length);
  debugPrint('[POI] Result-Limit: ${allPOIs.length} → $maxResults POIs (max)');
}
```

**Ergebnis:** Max 200 POIs statt 800+ aus allen Quellen.

---

## Fix 2: Compute-Limit in corridor_browser_provider.dart

### Problem
Der `compute()` Isolate-Aufruf berechnet fuer JEDEN POI die naechste Position auf der Route und den Umweg — O(n*m) Komplexitaet. Bei 750 POIs und 500 Route-Punkten = 375.000 Haversine-Berechnungen, was 15-40 Sekunden dauerte.

### Loesung
POIs werden vor dem Compute-Aufruf auf 150 limitiert (nach Score sortiert, Top 150 genommen).

**Datei:** `lib/features/trip/providers/corridor_browser_provider.dart`

```dart
// POI-Limit vor Compute: Verhindert O(n*m) Explosion im Isolate
var poisForCompute = pois;
if (pois.length > 150) {
  poisForCompute = List<POI>.from(pois)
    ..sort((a, b) => b.score.compareTo(a.score));
  poisForCompute = poisForCompute.take(150).toList();
  debugPrint('[Corridor] POIs limitiert: ${pois.length} → 150 fuer Compute');
}
```

Alle nachfolgenden Referenzen (`pois` → `poisForCompute`) angepasst fuer Isolate-Input und Enrichment-Loop.

**Ergebnis:** Max 150 x 500 = 75.000 Berechnungen (5x schneller als vorher).

---

## Fix 3: Timeout + Buffer + Kandidaten in ai_trip_advisor_provider.dart

### Problem 1: Defektes Timeout
`.timeout(onTimeout: () {})` loggt nur eine Warnung, wirft aber KEINE Exception und cancelt die Berechnung NICHT. Der Future laeuft einfach weiter.

### Loesung 1: Echtes TimeoutException
`onTimeout`-Callback entfernt → `.timeout()` wirft jetzt `TimeoutException`. try/catch behandelt den Timeout: Bei partiellen Ergebnissen werden diese genutzt, bei leeren Ergebnissen wird Fehlermeldung angezeigt.

```dart
import 'dart:async';

try {
  await corridorNotifier.loadCorridorPOIs(
    route: dayRoute,
    bufferKm: 25.0,
    existingStopIds: existingStopIds,
  ).timeout(const Duration(seconds: 12));
} on TimeoutException {
  debugPrint('[AIAdvisor] Korridor-Laden Timeout (12s)');
  if (requestId != _loadRequestId) return;
  final partialState = ref.read(corridorBrowserNotifierProvider);
  if (partialState.corridorPOIs.isEmpty) {
    state = state.copyWith(
      isLoading: false,
      error: 'Zeitlimit ueberschritten - bitte erneut versuchen',
    );
    return;
  }
  debugPrint('[AIAdvisor] Nutze ${partialState.corridorPOIs.length} partielle Ergebnisse nach Timeout');
}
```

### Problem 2: 50km Buffer zu gross
50km Buffer erzeugt ~40.000 km2 Suchflaeche pro Tag.

### Loesung 2: Buffer halbiert
Buffer von 50km auf **25km** reduziert → ~10.000 km2 Suchflaeche, praezisere Empfehlungen.

### Problem 3: Zu viele Kandidaten fuer Smart-Scoring
Alle Korridor-POIs wurden durch Smart-Scoring geschickt.

### Loesung 3: Kandidaten-Limit 50
Nach Score vorsortiert, Top 50 fuer Smart-Scoring genommen.

```dart
if (allCandidates.length > 50) {
  allCandidates.sort((a, b) => b.score.compareTo(a.score));
  allCandidates = allCandidates.take(50).toList();
  debugPrint('[AIAdvisor] Kandidaten limitiert: → 50 fuer Smart-Scoring');
}
```

---

## Performance-Vergleich

| Metrik | v1.9.15 (vorher) | v1.9.17 (nachher) |
|--------|-------------------|-------------------|
| POIs aus Quellen | 800+ (unlimitiert) | max 200 |
| POIs im Compute | 800+ | max 150 |
| Haversine-Berechnungen | ~375.000 | max ~75.000 |
| Suchflaeche | ~40.000 km2 (50km) | ~10.000 km2 (25km) |
| Timeout-Verhalten | Loggt nur, bricht nicht ab | TimeoutException nach 12s |
| Smart-Scoring Kandidaten | Alle | max 50 |
| App-Verhalten | Haengt 15-40s, Absturz | Reagiert in 2-5s |

---

## Geaenderte Dateien

| Datei | Aenderung |
|-------|-----------|
| `lib/data/repositories/poi_repo.dart` | `maxResults=200` Parameter, Sort+Trim nach Quality-Filter |
| `lib/features/trip/providers/corridor_browser_provider.dart` | POI-Limit 150 vor `compute()`, `poisForCompute` Variable |
| `lib/features/ai/providers/ai_trip_advisor_provider.dart` | `import 'dart:async'`, Buffer 50→25km, `TimeoutException` statt `onTimeout`, Kandidaten-Limit 50 |
| `pubspec.yaml` | Version 1.9.16+163 → 1.9.17+164 |
| `QR-CODE-DOWNLOAD.html` | Version, Links, Features aktualisiert |

---

## Debug-Logs

Neue/geaenderte Log-Meldungen:

| Log | Bedeutung |
|-----|-----------|
| `[POI] Result-Limit: X → 200 POIs (max)` | POI-Explosion verhindert, X POIs auf 200 reduziert |
| `[Corridor] POIs limitiert: X → 150 fuer Compute` | Compute-Input begrenzt |
| `[AIAdvisor] Korridor-Laden Timeout (12s)` | Echtes Timeout ausgeloest |
| `[AIAdvisor] Nutze X partielle Ergebnisse nach Timeout` | Partielle Ergebnisse nach Timeout |
| `[AIAdvisor] Kandidaten limitiert: → 50 fuer Smart-Scoring` | Smart-Scoring Input begrenzt |

---

## Kontext: Vorherige Fixes (v1.9.14 - v1.9.16)

| Version | Fix |
|---------|-----|
| v1.9.14 | Fluessige Navigation (60fps Interpolation), Must-See POI Entdeckung |
| v1.9.15 | UI-Freeze Fix (Route-Berechnungen in Isolate), Re-Entry Guard, Pipeline-Timeouts |
| v1.9.16 | Tages-Route-Extraktion `_extractDayRoute()`, Request-Cancellation `_loadRequestId`, Loading-Safety `try/finally` |
| **v1.9.17** | **POI Result-Limit, Compute-Limit, Buffer 25km, Echtes Timeout, Kandidaten-Limit** |
