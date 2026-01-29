# Changelog v1.6.0

**Datum:** 27.01.2026

## POI-Fotos Lazy-Loading - Alle Bilder werden jetzt geladen

### Problem

Nicht alle POI-Fotos wurden in der POI-Liste angezeigt. POIs ab Index 13 hatten keine Bilder, obwohl sie geladen wurden.

### Ursache

In `poi_list_screen.dart` gab es zwei harte Limits:

1. **Pre-Enrichment:** `.take(8)` - nur 8 POIs wurden vorab enriched
2. **On-Demand:** `index < 12` - nur POIs mit Index 0-11 wurden beim Rendern enriched

**Ergebnis:** POIs ab Index 13 wurden NIEMALS enriched und hatten daher keine Bilder.

### Lösung

1. **ScrollController + Lazy-Loading:** Bilder werden jetzt beim Scrollen geladen
2. **Index-Limit entfernt:** Alle POIs können jetzt Bilder laden
3. **Pre-Enrichment erhöht:** Von 8 auf 15 POIs initial
4. **Cache-Bereinigung:** Alte POIs ohne Bilder werden beim App-Start entfernt

## Neue Features

### Scroll-basiertes Lazy-Loading

POI-Bilder werden jetzt automatisch geladen, wenn der Benutzer durch die Liste scrollt:

- **Debounced Handler:** Alle 150ms wird geprüft, welche POIs sichtbar sind
- **Puffer-Zone:** 5 POIs vor und nach dem sichtbaren Bereich werden vorab geladen
- **Kein Index-Limit:** Alle POIs in der Liste können jetzt Bilder haben

### Cache-Migration

Beim App-Start werden alte gecachte POIs ohne Bilder automatisch entfernt:

```dart
// main.dart
final cacheService = POICacheService();
await cacheService.init();
await cacheService.clearCachedPOIsWithoutImages();
```

Dies behebt das Problem, dass POIs aus vor v1.5.3 ohne Bilder gecacht wurden.

## Geänderte Dateien

| Datei | Änderung |
|-------|----------|
| `lib/features/poi/poi_list_screen.dart` | ScrollController, Lazy-Loading, Index-Limit entfernt |
| `lib/data/services/poi_cache_service.dart` | Neue Methode `clearCachedPOIsWithoutImages()` |
| `lib/main.dart` | Cache-Migration beim App-Start |
| `pubspec.yaml` | Version 1.6.0 |

## Technische Details

### Neue Methoden in POIListScreen

```dart
/// Debounced Scroll-Handler für Lazy-Loading von POI-Bildern
void _onScroll() {
  _scrollDebounceTimer?.cancel();
  _scrollDebounceTimer = Timer(const Duration(milliseconds: 150), () {
    _enrichVisiblePOIs();
  });
}

/// Enriched POIs im sichtbaren Bereich + Puffer
void _enrichVisiblePOIs() {
  if (!_scrollController.hasClients) return;

  final poiState = ref.read(pOIStateNotifierProvider);
  final pois = poiState.filteredPOIs;
  if (pois.isEmpty) return;

  // Berechne sichtbaren Bereich (Card-Höhe ~108px inkl. Padding)
  const itemHeight = 108.0;
  final scrollPosition = _scrollController.position.pixels;
  final viewportHeight = _scrollController.position.viewportDimension;

  final firstVisible = (scrollPosition / itemHeight).floor();
  final lastVisible = ((scrollPosition + viewportHeight) / itemHeight).ceil();

  // Puffer: 5 Items vor und nach sichtbarem Bereich
  final startIndex = (firstVisible - 5).clamp(0, pois.length - 1);
  final endIndex = (lastVisible + 5).clamp(0, pois.length - 1);

  // Enrichment für alle POIs im Bereich
  for (int i = startIndex; i <= endIndex; i++) {
    final poi = pois[i];
    if (!poi.isEnriched &&
        poi.imageUrl == null &&
        !poiState.enrichingPOIIds.contains(poi.id)) {
      poiNotifier.enrichPOI(poi.id);
    }
  }
}
```

### Neue Methode in POICacheService

```dart
/// Löscht gecachte POIs ohne Bilder (Migration von vor v1.5.3)
Future<int> clearCachedPOIsWithoutImages() async {
  await init();
  if (_enrichedBox == null) return 0;

  int deletedCount = 0;
  final keysToDelete = <String>[];

  for (final key in _enrichedBox!.keys) {
    final jsonStr = _enrichedBox!.get(key);
    if (jsonStr != null) {
      try {
        final cached = CachedPOI.fromJson(jsonDecode(jsonStr));
        if (cached.poi.imageUrl == null) {
          keysToDelete.add(key);
        }
      } catch (_) {
        keysToDelete.add(key);
      }
    }
  }

  for (final key in keysToDelete) {
    await _enrichedBox!.delete(key);
    deletedCount++;
  }

  if (deletedCount > 0) {
    debugPrint('[POICache] $deletedCount POIs ohne Bilder aus Cache entfernt');
  }

  return deletedCount;
}
```

## Vergleich: Vorher vs. Nachher

| Aspekt | v1.5.9 | v1.6.0 |
|--------|--------|--------|
| Max. POIs mit Bildern | 12 | Unbegrenzt |
| Pre-Enrichment | 8 POIs | 15 POIs |
| Scroll-Laden | Nein | Ja (Lazy-Loading) |
| Index-Limit | `index < 12` | Keins |
| Cache-Migration | Nein | Ja (App-Start) |

## Debug-Logs

Neue Log-Präfixe zur Fehlersuche:

```
[POIList] Pre-Enrichment für 15 POIs starten
[POICache] 5 POIs ohne Bilder aus Cache entfernt
```
