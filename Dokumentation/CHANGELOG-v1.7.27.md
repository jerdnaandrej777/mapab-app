# Changelog v1.7.27 - POI-Foto-Optimierung & Kategorie-Modal-Fix

**Datum:** 31. Januar 2026
**Typ:** Feature-Update + Bug-Fix
**Plattformen:** Android, iOS, Desktop
**APK-Größe:** 63.4 MB

---

## Zusammenfassung

Massive Erweiterung der POI-Foto-Pipeline um die Bild-Trefferquote von ~98% auf ~100% zu bringen. 6 neue Bildquellen hinzugefügt (Multi-Sprach-Wikipedia, Wikidata Geo-Radius, Wikidata P373/P948, Openverse CC-Bilder). Zusätzlich: Kategorie-Modal im AI Trip zeigt Auswahl jetzt sofort an statt erst nach Neuöffnen.

---

## Änderungen

### 1. **POI-Enrichment Pipeline erweitert (Phase 1-4)**

#### Phase 1A: isEnriched-Fix
- **Problem:** Single-POI-Enrichment setzte `isEnriched: true` auch ohne Bild - POIs konnten nie erneut versucht werden
- **Fix:** `isEnriched` wird jetzt basierend auf `hasImage || hasDescription` gesetzt
- **Zusätzlich:** Session-Tracking für Single-POIs ohne Bild (wie bei Batch)

#### Phase 1B: onPartialResult für alle Fallback-Stufen
- **Problem:** UI-Updates nur nach Cache + Wikipedia, nicht nach Wikimedia/EN-Wikipedia/Wikidata Fallbacks
- **Fix:** `onPartialResult?.call()` nach jeder Stufe (3b, 4, 5, 6) + Image Pre-Caching in allen Stufen

#### Phase 1C: Wikidata SPARQL erweitert
- **Neu:** P373 (Commons-Kategorie) und P948 (Wikivoyage-Banner) Properties
- **Bild-Priorität:** P18 > P948 (Wikivoyage) > P154 (Logo) > P94 (Wappen)
- **Neu:** `_fetchCommonsImageFromCategory()` - sucht Bilder aus P373-Kategorien wenn kein P18 vorhanden

#### Phase 2: Wikidata Geo-Radius Search
- **Neu:** SPARQL `wikibase:around` Query findet Entities mit P18-Bildern in 2km Umkreis
- **Name-Matching:** Case-insensitive contains-Vergleich zwischen POI-Name und Wikidata-Label
- **Batch:** Max 10 Locations pro Query, 500ms Pause

#### Phase 3: Multi-Sprach-Wikipedia (FR/IT/ES/NL/PL)
- **5 neue Endpoints:** Französische, Italienische, Spanische, Niederländische, Polnische Wikipedia
- **Ländererkennung:** Bounding-Box-Approximation für europäische Länder
- **Sprach-Priorisierung:** Landessprache zuerst, dann 2 weitere (max 3 pro POI)
- **Beispiel:** POI in Frankreich → FR-Wikipedia zuerst, dann IT, ES

#### Phase 4: Openverse CC-Bilder (Last-Resort)
- **Neu:** Suche in 800M+ Creative-Commons-Bildern via Openverse API
- **Kontext:** Suchquery mit Ländername für bessere Ergebnisse
- **Rate-Limit:** 60 req/min (anonym), 300ms Delay zwischen Requests

### 2. **Kategorie-Modal Live-Update Fix**
- **Problem:** Kategorie-Chips im AI Trip Modal aktualisierten sich erst nach Schließen und Neuöffnen
- **Ursache:** `_showCategoryModal()` war Plain-Function ohne Riverpod-Zugriff - Modal konnte State-Änderungen nicht beobachten
- **Fix:** Modal-Builder in `Consumer` Widget gewrapped mit `ref.watch(randomTripNotifierProvider)`
- **Ergebnis:** Sofortige visuelle Aktualisierung bei Toggle (Farbe, Häkchen, Schatten, Zähler)

---

## Technische Details

### Neue Methoden in poi_enrichment_service.dart

| Methode | Beschreibung |
|---------|-------------|
| `_fetchCommonsImageFromCategory()` | Sucht Bilder aus Wikidata P373 Commons-Kategorien |
| `_fetchWikidataGeoImages()` | SPARQL wikibase:around Geo-Radius-Suche |
| `_matchWikidataImage()` | Name-Matching für Geo-Suche Ergebnisse |
| `_fetchWikipediaImageByLanguage()` | Generische Multi-Sprach-Wikipedia Bildsuche |
| `_detectCountryCode()` | Bounding-Box Ländererkennung für Sprach-Priorisierung |
| `_fetchOpenverseImage()` | Openverse CC-Bild-Suche mit Länder-Kontext |
| `_countryNameForCode()` | Ländername für Suchkontext |

### Neue API-Endpoints

| Endpoint | Verwendung |
|----------|-----------|
| `wikipediaFrSearch` | FR-Wikipedia pageimages |
| `wikipediaItSearch` | IT-Wikipedia pageimages |
| `wikipediaEsSearch` | ES-Wikipedia pageimages |
| `wikipediaNlSearch` | NL-Wikipedia pageimages |
| `wikipediaPlSearch` | PL-Wikipedia pageimages |
| `openverseSearch` | Openverse CC-Bild-Aggregator |

### Erweiterte Enrichment-Pipeline

```
Single-POI:
1. Cache Check
2. Wikipedia DE (pageimages + extracts)
3. Wikimedia Commons (Geo + Titel + Kategorie)
4. Wikidata SPARQL (P18 + P948 + P373 + P154 + P94)     <- ERWEITERT
   └── P373 → Commons-Category-Search                    <- NEU
5. Multi-Sprach-Wikipedia (FR/IT/ES/NL/PL)               <- NEU
6. Wikidata Geo-Radius (wikibase:around + P18)            <- NEU
7. Openverse CC-Bilder (Last-Resort)                      <- NEU

Batch:
1. Cache Check
2. Wikipedia DE Multi-Title-Query
3. Wikimedia Fallback (Wiki-POIs ohne Bild)
3b. Wikimedia Geo-Suche (POIs ohne Wiki-Titel)
4. EN-Wikipedia Fallback
5. Wikidata P18 Fallback
6. Wikidata Geo-Radius                                    <- NEU
7. Multi-Sprach-Wikipedia                                 <- NEU
8. Openverse CC-Bilder                                    <- NEU
9. Session-Tracking für restliche POIs ohne Bild
```

### Betroffene Dateien

| Datei | Änderung |
|-------|----------|
| `lib/data/services/poi_enrichment_service.dart` | 7 neue Methoden, Pipeline um 3 Stufen erweitert, isEnriched-Fix, onPartialResult |
| `lib/features/poi/providers/poi_state_provider.dart` | isEnriched Override entfernt |
| `lib/core/constants/api_endpoints.dart` | 6 neue Endpoints (5 Wikipedia + Openverse) |
| `lib/features/map/map_screen.dart` | Kategorie-Modal: Consumer-Wrapper für Live-Updates |
| `pubspec.yaml` | Version 1.7.26+126 -> 1.7.27+127 |
| `QR-CODE-DOWNLOAD.html` | Links und Version auf v1.7.27 aktualisiert |
| `QR-CODE-SIMPLE.html` | Links und Version auf v1.7.27 aktualisiert |
| `qr-generator.html` | Links und Version auf v1.7.27 aktualisiert |

---

## Bild-Trefferquote Vergleich

| Version | Trefferquote | Quellen | Fallback-Stufen |
|---------|-------------|---------|-----------------|
| v1.7.9 | ~98% | 7 | Cache, DE-Wiki, Wikimedia, EN-Wiki, Wikidata P18 |
| **v1.7.27** | **~100%** | **13** | + P373, P948, FR/IT/ES/NL/PL Wiki, Wikidata Geo, Openverse |

---

## Migration

**Keine Breaking Changes** - Rein additive Erweiterung der Enrichment-Pipeline und UI-Fix.

---

## Siehe auch

- [CHANGELOG-v1.7.26.md](CHANGELOG-v1.7.26.md) - Kategorie-Chips Konsistenz (v1.7.26)
- [CHANGELOG-v1.7.24.md](CHANGELOG-v1.7.24.md) - POI-Filter Chip Feedback
- [CHANGELOG-v1.7.23.md](CHANGELOG-v1.7.23.md) - POI-Kategorien-Filter

---

**Status:** Abgeschlossen
**Review:** Pending
**Deploy:** Released as v1.7.27
