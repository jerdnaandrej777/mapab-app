# MapAB v1.2.7 - Favoriten-System & POI-Bilder Optimierung

## Release Date: 22.01.2026

---

## Zusammenfassung

Diese Version repariert das **gesamte Favoriten-System** und optimiert die **POI-Bild-Ladung**. Kritische Bugs wurden behoben, die das Speichern von Favoriten und das Anzeigen von POI-Fotos verhinderten.

**Highlights:**
- ❤️ POI-Favoriten funktionieren jetzt vollständig
- 💾 Route-Speichern-Button im Trip-Screen
- 🖼️ POI-Bilder laden automatisch in der Liste
- ☁️ Cloud-Sync für Favoriten integriert
- 🌙 Dark Mode Fixes für alle Favoriten-Screens

---

## Bug Fixes (8 kritische Bugs behoben)

### 1. LatLng Serialisierung gefixt
**Problem:** `LatLng` von `latlong2` Package hat keine `fromJson`/`toJson` Methoden. Beim Speichern von Routen als Favoriten crashte die App.

**Lösung:** Custom `JsonConverter` für LatLng erstellt:

```dart
// lib/data/models/route.dart

/// Konvertiert LatLng für JSON-Serialisierung (Freezed/JsonSerializable)
class LatLngConverter implements JsonConverter<LatLng, Map<String, dynamic>> {
  const LatLngConverter();

  @override
  LatLng fromJson(Map<String, dynamic> json) {
    return LatLng(
      (json['lat'] as num).toDouble(),
      (json['lng'] as num).toDouble(),
    );
  }

  @override
  Map<String, dynamic> toJson(LatLng latLng) {
    return {'lat': latLng.latitude, 'lng': latLng.longitude};
  }
}

/// Für Listen von LatLng (Route-Koordinaten)
class LatLngListConverter implements JsonConverter<List<LatLng>, List<dynamic>> { ... }

/// Für nullable LatLng-Felder
class NullableLatLngConverter implements JsonConverter<LatLng?, Map<String, dynamic>?> { ... }
```

**Anwendung in AppRoute:**
```dart
@freezed
class AppRoute with _$AppRoute {
  const factory AppRoute({
    @LatLngConverter() required LatLng start,
    @LatLngConverter() required LatLng end,
    @LatLngListConverter() required List<LatLng> coordinates,
    // ...
  }) = _AppRoute;
}
```

### 2. POI-Favorit-Button implementiert
**Problem:** Der Herz-Button im POI-Detail-Screen war nur ein `// TODO: Favorit toggle implementieren`.

**Lösung:** Vollständige Implementierung mit Toggle-Funktion:

```dart
// lib/features/poi/poi_detail_screen.dart
onPressed: () async {
  final notifier = ref.read(favoritesNotifierProvider.notifier);
  await notifier.togglePOI(poi);

  if (mounted) {
    final message = isFavorite
        ? '${poi.name} aus Favoriten entfernt'
        : '${poi.name} zu Favoriten hinzugefügt';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), /* ... Undo-Action */ ),
    );
  }
}
```

### 3. Dynamisches Favorit-Icon
**Problem:** Das Herz-Icon war immer `Icons.favorite_border`, egal ob der POI favorisiert war.

**Lösung:** Icon reagiert auf Favoriten-Status:

```dart
final isFavorite = ref.watch(isPOIFavoriteProvider(poi.id));

Icon(
  isFavorite ? Icons.favorite : Icons.favorite_border,
  color: isFavorite ? Colors.red : colorScheme.onSurface,
)
```

### 4. Route-Speichern-Button hinzugefügt
**Problem:** Es gab keine Möglichkeit, eine geplante Route als Favorit zu speichern.

**Lösung:** Bookmark-Button in TripScreen AppBar mit Benennungs-Dialog:

```dart
// lib/features/trip/trip_screen.dart
IconButton(
  icon: const Icon(Icons.bookmark_add),
  tooltip: 'Route speichern',
  onPressed: () => _saveRoute(context, ref, tripState),
)

Future<void> _saveRoute(...) async {
  // Dialog für Route-Namen
  final result = await showDialog<String>(...);

  // Trip erstellen und speichern
  final trip = Trip(
    id: const Uuid().v4(),
    name: result,
    type: TripType.daytrip,
    route: route,
    stops: tripState.stops.map((poi) => TripStop.fromPOI(poi)).toList(),
    createdAt: DateTime.now(),
  );

  await ref.read(favoritesNotifierProvider.notifier).saveRoute(trip);
}
```

### 5. Supabase-Sync in FavoritesProvider integriert
**Problem:** Favoriten wurden nur lokal gespeichert, nicht in der Cloud.

**Lösung:** Nach lokalem Speichern wird Cloud-Sync getriggert (wenn authentifiziert):

```dart
// lib/data/providers/favorites_provider.dart
Future<void> addPOI(POI poi) async {
  // ... lokales Speichern in Hive ...

  // Cloud-Sync (wenn authentifiziert)
  if (isAuthenticated) {
    final syncService = ref.read(syncServiceProvider);
    await syncService.saveFavoritePOI(poi);
  }
}

Future<void> saveRoute(Trip trip) async {
  // ... lokales Speichern ...

  if (isAuthenticated) {
    final syncService = ref.read(syncServiceProvider);
    await syncService.saveTrip(
      name: trip.name,
      route: trip.route,
      stops: trip.stops,
      isFavorite: true,
    );
  }
}
```

### 6. sharing_service.dart Fehler behoben
**Problem:** Nach build_runner waren Fehler in `sharing_service.dart`:
- `TripType` nicht importiert
- `route: null` nicht erlaubt (required field)
- `createdAt` fehlte

**Lösung:** Imports hinzugefügt und Placeholder-Route erstellt:

```dart
// Placeholder-Route für dekodierte Trips
final placeholderRoute = AppRoute(
  start: stops.isNotEmpty
      ? LatLng(stops.first.latitude, stops.first.longitude)
      : const LatLng(48.1351, 11.5820), // München Fallback
  end: stops.isNotEmpty
      ? LatLng(stops.last.latitude, stops.last.longitude)
      : const LatLng(48.1351, 11.5820),
  startAddress: data['startAddress'] ?? 'Start',
  endAddress: data['endAddress'] ?? 'Ziel',
  coordinates: [],
  distanceKm: 0,
  durationMinutes: 0,
);

return Trip(
  // ...
  route: placeholderRoute,
  createdAt: DateTime.now(),
);
```

---

## Optimierungen

### 1. Pre-Enrichment für POI-Bilder
**Problem:** POIs in der Liste zeigten keine Bilder, weil Enrichment erst bei Detail-Ansicht startete.

**Lösung:** Automatisches Pre-Enrichment für Top 20 POIs:

```dart
// lib/features/poi/poi_list_screen.dart
void _preEnrichVisiblePOIs() {
  final poiNotifier = ref.read(pOIStateNotifierProvider.notifier);
  final poiState = ref.read(pOIStateNotifierProvider);

  // Top 20 POIs ohne Bilder auswählen
  final poisToEnrich = poiState.filteredPOIs
      .where((poi) => !poi.isEnriched && poi.imageUrl == null)
      .take(20)
      .toList();

  // Im Hintergrund enrichen (nicht blockierend)
  for (final poi in poisToEnrich) {
    unawaited(poiNotifier.enrichPOI(poi.id));
  }
}
```

### 2. CachedNetworkImage in Favoriten-Screen
**Problem:** `Image.network()` ohne Caching verursachte langsames Laden und hohen Datenverbrauch.

**Lösung:** Ersetzt durch `CachedNetworkImage`:

```dart
// lib/features/favorites/favorites_screen.dart
CachedNetworkImage(
  imageUrl: poi.imageUrl!,
  fit: BoxFit.cover,
  placeholder: (context, url) => _buildPOIPlaceholder(poi.categoryIcon),
  errorWidget: (context, url, error) => _buildPOIPlaceholder(poi.categoryIcon),
)
```

### 3. Nicht-blockierendes Enrichment
**Problem:** `await notifier.enrichPOI()` blockierte die UI beim Öffnen des POI-Detail-Screens.

**Lösung:** Enrichment läuft im Hintergrund:

```dart
// lib/features/poi/poi_detail_screen.dart
if (state.selectedPOI != null && !state.selectedPOI!.isEnriched) {
  unawaited(notifier.enrichPOI(widget.poiId)); // Non-blocking!
}
```

---

## Dark Mode Fixes

### AppTheme.* → colorScheme.* Migration

**Problem:** Statische `AppTheme.*` Farben ignorierten den Dark Mode.

**Geänderte Dateien:**

| Datei | Fixes |
|-------|-------|
| `trip_screen.dart` | `AppTheme.textSecondary` → `colorScheme.onSurfaceVariant` |
| `trip_screen.dart` | `AppTheme.successColor` → `Colors.green` |
| `trip_screen.dart` | `AppTheme.errorColor` → `colorScheme.error` |
| `trip_screen.dart` | `AppTheme.cardShadow` → Dynamischer Schatten |
| `favorites_screen.dart` | Alle Farben auf `colorScheme.*` umgestellt |

**Beispiel-Fix:**
```dart
// VORHER (Dark Mode Bug)
color: AppTheme.textSecondary,
boxShadow: AppTheme.cardShadow,

// NACHHER (Dark Mode kompatibel)
color: colorScheme.onSurfaceVariant,
boxShadow: [
  BoxShadow(
    color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
    blurRadius: 4,
    offset: const Offset(0, 2),
  ),
],
```

---

## Geänderte Dateien

| Datei | Änderungen |
|-------|------------|
| `lib/data/models/route.dart` | 3 Custom JsonConverters für LatLng |
| `lib/data/models/route.g.dart` | Regeneriert mit neuen Converters |
| `lib/features/poi/poi_detail_screen.dart` | Favorit-Button + nicht-blockierendes Enrichment |
| `lib/features/trip/trip_screen.dart` | Route-Speichern-Button + Dark Mode Fixes |
| `lib/data/providers/favorites_provider.dart` | Supabase Cloud-Sync Integration |
| `lib/features/poi/poi_list_screen.dart` | Pre-Enrichment für POI-Bilder |
| `lib/features/favorites/favorites_screen.dart` | CachedNetworkImage + Dark Mode Fixes |
| `lib/data/services/sharing_service.dart` | Import-Fixes + Placeholder Route |

---

## Neue Dependencies

Keine neuen Dependencies. Bestehende genutzt:
- `cached_network_image` (bereits vorhanden)
- `uuid` (bereits vorhanden)

---

## Migration Guide

### Von v1.2.6 zu v1.2.7

Keine Breaking Changes. Nach Update:

1. **build_runner ausführen:**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

2. **Bestehende Favoriten bleiben erhalten** (Hive-Daten kompatibel)

3. **Cloud-Sync:** Wenn eingeloggt, werden neue Favoriten automatisch synchronisiert

---

## Verifikation (Checkliste)

### Favoriten testen:
- [ ] POI öffnen → Herz-Button klicken → Icon wird rot
- [ ] Erneut klicken → Icon wird grau
- [ ] Favoriten-Screen → POI erscheint/verschwindet
- [ ] App neu starten → Favoriten noch vorhanden

### Route-Speichern testen:
- [ ] Route planen (Start + Ziel)
- [ ] Trip-Screen → Bookmark-Button klicken
- [ ] Name eingeben → Speichern
- [ ] Favoriten-Screen → Route-Tab → Route erscheint

### Bilder testen:
- [ ] POI-Liste öffnen → Bilder laden nach kurzer Zeit
- [ ] POI-Detail öffnen → Bild erscheint ohne Lag
- [ ] Favoriten-Screen → Bilder werden gecacht

### Dark Mode testen:
- [ ] Trip-Screen im Dark Mode → Keine weißen Hintergründe
- [ ] Favoriten-Screen im Dark Mode → Kontrast OK

---

## Build Info

- **Version:** 1.2.7
- **Flutter:** 3.38.7
- **Dart:** 3.10.7
- **Min Android SDK:** 21 (Android 5.0)
- **Target Android SDK:** 34 (Android 14)
