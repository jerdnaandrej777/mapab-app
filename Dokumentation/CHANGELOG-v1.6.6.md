# Changelog v1.6.6 - POI-Foto CORS & Rate-Limit Fix

**Datum:** 2026-01-28

## Problem

POI-Fotos wurden nicht angezeigt. Die POI-Cards zeigten nur Placeholder-Icons statt der echten Bilder.

## Ursachenanalyse

### 1. Wikidata SPARQL ohne `origin: '*'` Header

Der Wikidata SPARQL-Aufruf hatte keinen CORS-Parameter, während alle anderen API-Aufrufe (Wikipedia, Wikimedia Commons) korrekt `origin: '*'` verwendeten.

**Betroffener Code:** `poi_enrichment_service.dart`, Zeile 505-514

```dart
// VORHER (fehlerhaft):
final response = await _requestWithRetry(
  ApiEndpoints.wikidataSparql,
  {
    'query': query,
    'format': 'json',
  },
  options: Options(
    headers: {'Accept': 'application/sparql-results+json'},
  ),
);
```

### 2. Rate-Limiting ohne Handling

- 5 parallele Enrichments mit je bis zu 3 API-Calls = 15 gleichzeitige Requests
- Wikimedia Commons Limit: 200 Requests/Minute
- Bei vielen POIs wurden Requests stillschweigend blockiert (HTTP 429)
- Keine Erkennung oder Handling des Rate-Limits

### 3. Fehlende Fehler-Details

- Timeout-Fehler wurden nicht detailliert geloggt
- HTTP-Statuscodes wurden nicht ausgegeben
- Debugging war nahezu unmöglich

## Implementierte Fixes

### Fix 1: Wikidata `origin: '*'` Header

```dart
// NACHHER (korrekt):
final response = await _requestWithRetry(
  ApiEndpoints.wikidataSparql,
  {
    'query': query,
    'format': 'json',
    'origin': '*',  // NEU
  },
  options: Options(
    headers: {
      'Accept': 'application/sparql-results+json',
      'Origin': 'https://mapab.app',  // NEU
    },
  },
);
```

### Fix 2: Erweitertes Error-Logging mit Rate-Limit-Handling

```dart
Future<Response<dynamic>?> _requestWithRetry(...) async {
  for (int attempt = 0; attempt < _maxRetries; attempt++) {
    try {
      final response = await _dio.get(...);

      if (response.statusCode == 200) {
        return response;
      }

      debugPrint('[Enrichment] ⚠️ Unerwarteter Statuscode ${response.statusCode}');
      return null;

    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;

      // Rate-Limit spezifisch behandeln
      if (statusCode == 429) {
        debugPrint('[Enrichment] ⚠️ Rate-Limit (429) erreicht! Warte 5 Sekunden...');
        await Future.delayed(const Duration(seconds: 5));
        continue; // Zählt nicht als Versuch
      }

      // Detailliertes Logging
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        debugPrint('[Enrichment] ⏱️ Timeout bei Versuch ${attempt + 1}');
      } else {
        debugPrint('[Enrichment] ❌ API-Fehler: Status=$statusCode, Typ=${e.type}');
      }

      // ... Retry-Logik
    }
  }
  return null;
}
```

### Fix 3: Concurrency reduziert

```dart
// VORHER:
static const int _maxConcurrentEnrichments = 5;

// NACHHER:
static const int _maxConcurrentEnrichments = 3;
```

**Begründung:** Mit 3 statt 5 parallelen Enrichments:
- 3 × 3 API-Calls = 9 gleichzeitige Requests (statt 15)
- Mehr Puffer zum Wikimedia-Limit (200 Req/Min)

### Fix 4: API-Call-Delays

Neue Konstante:
```dart
static const Duration _apiCallDelay = Duration(milliseconds: 200);
```

Eingefügt vor Titel- und Kategorie-Suche in `_fetchWikimediaCommonsImage()`:
```dart
// Rate-Limit-Schutz: Kurze Pause zwischen API-Calls
await Future.delayed(_apiCallDelay);

// Methode 2: Titel-basierte Suche...
```

## Betroffene Dateien

| Datei | Änderung |
|-------|----------|
| `lib/data/services/poi_enrichment_service.dart` | Alle 4 Fixes |

## Neue Log-Meldungen

| Meldung | Bedeutung |
|---------|-----------|
| `[Enrichment] ⚠️ Rate-Limit (429) erreicht!` | API-Limit überschritten, warte 5 Sek |
| `[Enrichment] ⏱️ Timeout bei Versuch X` | Request-Timeout |
| `[Enrichment] ❌ API-Fehler: Status=X, Typ=Y, URL=Z` | Detaillierter API-Fehler |
| `[Enrichment] ⚠️ Unerwarteter Statuscode X` | Nicht-200 Response |

## Verifikation

1. **App starten** → POI-Liste öffnen
2. **Logs prüfen:**
   - `[Enrichment] Wikidata-Daten geladen` → Wikidata funktioniert
   - `[Enrichment] Wikimedia Geo-Bild gefunden` → Bilder werden geladen
   - Keine `429 Rate-Limit` Fehler
3. **POI-Cards prüfen** → Bilder werden angezeigt (statt Placeholder)

## Konfiguration nach Fix

| Parameter | Wert | Beschreibung |
|-----------|------|--------------|
| `_maxConcurrentEnrichments` | 3 | Max parallele Enrichments |
| `_enrichmentTimeout` | 25000ms | Request-Timeout |
| `_maxRetries` | 3 | Versuche bei Fehler |
| `_baseRetryDelay` | 500ms | Basis für Exponential Backoff |
| `_apiCallDelay` | 200ms | Pause zwischen API-Calls |

## Zusammenfassung

- **Wikidata CORS-Fix**: Fallback-Bilder von Wikidata funktionieren jetzt
- **Rate-Limit-Handling**: HTTP 429 wird erkannt und intelligent behandelt
- **Weniger Concurrency**: Reduziert Risiko von Rate-Limiting
- **Besseres Debugging**: Detaillierte Logs für Fehleranalyse
