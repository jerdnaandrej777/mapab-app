# Changelog v1.5.3

**Release-Datum:** 25. Januar 2026

## Bugfixes

### POI-Liste zeigt jetzt alle POIs

**Problem:** Die POI-Liste zeigte oft nur 1 POI, obwohl mehr geladen wurden.

**Ursache:** Der `detourKm`-Filter wurde IMMER angewendet, nicht nur im Route-Modus. POIs mit hohem Umweg-Wert (> 45km) wurden herausgefiltert, auch wenn gar keine Route aktiv war.

**Lösung:**
- `detourKm`-Filter wird jetzt **nur bei aktivem `routeOnlyMode`** angewendet
- Default `maxDetourKm` von 45 auf **100 km** erhöht
- Debug-Logging für alle Filter-Schritte hinzugefügt

**Betroffene Datei:** `lib/features/poi/providers/poi_state_provider.dart`

### Fotos werden zuverlässiger geladen

**Problem:** POI-Fotos wurden oft nicht geladen, ohne dass ersichtlich war warum.

**Ursachen:**
1. POIs mit Beschreibung aber **ohne Bild** wurden gecacht → Bild wurde nie erneut gesucht (30 Tage Cache!)
2. Keine Failure-Logs wenn Wikimedia kein Bild fand
3. Static State konnte nach Hot-Reload in inkonsistentem Zustand sein

**Lösungen:**
- POIs werden nur gecacht **wenn Bild vorhanden** ist
- Failure-Logs hinzugefügt: `[Enrichment] ⚠️ Kein Wikimedia-Bild gefunden für: ...`
- `resetStaticState()` Methode hinzugefügt, wird bei Provider-Init aufgerufen

**Betroffene Datei:** `lib/data/services/poi_enrichment_service.dart`

## Technische Details

### Neue Debug-Logs

```
[POIState] Filter routeOnlyMode: 50 → 45
[POIState] Filter detourKm (<= 100.0 km): 45 → 42
[POIState] filteredPOIs: 50 → 42 (routeOnlyMode=true)
[Enrichment] Static State wird zurückgesetzt
[Enrichment] ⚠️ Kein Wikimedia-Bild gefunden für: Sehenswürdigkeit XY
[Enrichment] ⚠️ POI nicht gecacht (kein Bild): Sehenswürdigkeit XY
[Enrichment] POI mit Bild gecacht: Schloss Neuschwanstein
```

### Geänderte Dateien

| Datei | Änderung |
|-------|----------|
| `lib/features/poi/providers/poi_state_provider.dart` | Filter-Logik korrigiert, Debug-Logs |
| `lib/data/services/poi_enrichment_service.dart` | Cache-Logik, Failure-Logs, resetStaticState() |
| `pubspec.yaml` | Version 1.5.3 |

## Migration

Keine manuellen Schritte erforderlich. Die Änderungen sind abwärtskompatibel.

## Bekannte Einschränkungen

- Wikimedia findet nicht für jeden POI ein Bild (abhängig von verfügbaren Bildern in der Nähe)
- Bei sehr großen Routen (> 500km) können viele POIs den `detourKm`-Filter nicht passieren

---

**Vorherige Version:** [v1.5.2](CHANGELOG-v1.5.2.md)
