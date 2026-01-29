# Changelog v1.6.9 - POI-Fotos überall

**Datum:** 2026-01-29

## Überblick

Diese Version sorgt dafür, dass POI-Fotos in **allen Bereichen** der App geladen und angezeigt werden:

1. **Favoriten-Screen**: Auto-Enrichment beim Öffnen
2. **Trip-Screen**: Enrichment bei Klick auf Stops
3. **AI Trip Preview**: Fotos in der Stop-Liste + Navigation zu POI-Details
4. **TripStop Model**: Neue `toPOI()` Methode

---

## 1. Favoriten-Screen mit Auto-Enrichment

### Problem

POI-Fotos wurden im Favoriten-Screen nicht angezeigt, da das Enrichment nie getriggert wurde.

### Lösung

**Datei:** `lib/features/favorites/favorites_screen.dart`

**1. Enrichment-Tracking hinzugefügt:**

```dart
class _FavoritesScreenState extends ConsumerState<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<String> _enrichedPOIIds = {};  // NEU: Tracking

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // NEU: Enrichment für Favoriten-POIs nach erstem Frame starten
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _enrichFavoritePOIs();
    });
  }
```

**2. Auto-Enrichment Methode:**

```dart
/// Enriched alle Favoriten-POIs die noch kein Bild haben
Future<void> _enrichFavoritePOIs() async {
  final favoritesAsync = ref.read(favoritesNotifierProvider);
  final poiNotifier = ref.read(pOIStateNotifierProvider.notifier);

  favoritesAsync.whenData((favorites) {
    for (final poi in favorites.favoritePOIs) {
      // Nur enrichen wenn noch kein Bild und nicht bereits enriched
      if (poi.imageUrl == null && !_enrichedPOIIds.contains(poi.id)) {
        _enrichedPOIIds.add(poi.id);
        debugPrint('[Favorites] Enriching POI: ${poi.name}');
        poiNotifier.enrichPOI(poi.id);
      }
    }
  });
}
```

**3. POI-Card mit Bild und addPOI:**

```dart
Widget _buildPOICard(POI poi) {
  // Enrichment triggern wenn kein Bild vorhanden
  if (poi.imageUrl == null && !_enrichedPOIIds.contains(poi.id)) {
    _enrichedPOIIds.add(poi.id);
    ref.read(pOIStateNotifierProvider.notifier).enrichPOI(poi.id);
  }

  return Card(
    child: InkWell(
      onTap: () {
        // POI zum State hinzufügen für POI-Detail-Screen
        ref.read(pOIStateNotifierProvider.notifier).addPOI(poi);
        context.push('/poi/${poi.id}');
      },
      child: // ... CachedNetworkImage mit poi.imageUrl
    ),
  );
}
```

---

## 2. Trip-Screen Enrichment

### Problem

Beim Klick auf einen Stop unter "Deine Route" wurde zwar `addPOI()` aufgerufen (v1.6.8), aber das Enrichment für Fotos fehlte noch.

### Lösung

**Datei:** `lib/features/trip/trip_screen.dart`

```dart
// VORHER (v1.6.8):
onTap: () {
  ref.read(pOIStateNotifierProvider.notifier).addPOI(stop);
  context.push('/poi/${stop.id}');
},

// NACHHER (v1.6.9):
onTap: () {
  // v1.6.9: POI zum State hinzufügen bevor Navigation
  final poiNotifier = ref.read(pOIStateNotifierProvider.notifier);
  poiNotifier.addPOI(stop);
  // Enrichment triggern für Foto-Laden
  if (stop.imageUrl == null) {
    poiNotifier.enrichPOI(stop.id);
  }
  context.push('/poi/${stop.id}');
},
```

---

## 3. AI Trip Preview mit POI-Fotos

### Problem

In der `TripPreviewCard` wurden nur Emoji-Icons für POIs angezeigt, keine echten Fotos. Außerdem gab es keine Möglichkeit, zu den POI-Details zu navigieren.

### Lösung

**Datei:** `lib/features/random_trip/providers/random_trip_provider.dart`

**1. Auto-Enrichment nach Trip-Generierung:**

```dart
// In generateTrip() nach erfolgreichem Generieren:
print('[RandomTrip] State aktualisiert: step=${state.step}');

// v1.6.9: POIs enrichen für Foto-Anzeige in der Preview
_enrichGeneratedPOIs(result);

// Neue Methode:
void _enrichGeneratedPOIs(GeneratedTrip result) {
  final poiNotifier = ref.read(pOIStateNotifierProvider.notifier);

  // POIs zum State hinzufügen und enrichen
  for (final poi in result.selectedPOIs) {
    // POI zum State hinzufügen (für POI-Detail-Navigation)
    poiNotifier.addPOI(poi);

    // Enrichment triggern wenn noch kein Bild vorhanden
    if (poi.imageUrl == null) {
      print('[RandomTrip] Enriching POI: ${poi.name}');
      poiNotifier.enrichPOI(poi.id);
    }
  }
}
```

**Datei:** `lib/features/random_trip/widgets/trip_preview_card.dart`

**2. _StopList zu ConsumerWidget konvertiert:**

```dart
// VORHER:
class _StopList extends StatelessWidget {

// NACHHER:
class _StopList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // POI State für aktuelle Bilder abonnieren
    final poiState = ref.watch(pOIStateNotifierProvider);

    // ... für jeden Stop:
    final poiFromState = poiState.pois.where((p) => p.id == stop.poiId).firstOrNull;
    final imageUrl = poiFromState?.imageUrl ?? stop.imageUrl;
```

**3. _StopItem erweitert mit Bild und Navigation:**

```dart
class _StopItem extends StatelessWidget {
  // Neue Parameter:
  final String? imageUrl;
  final POICategory? category;
  final String? poiId;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          // v1.6.9: POI-Bild statt nur Icon
          if (hasPOIImage && poiId != null)
            _buildPOIImage(colorScheme)
          else
            // Fallback: Emoji in Circle

          // ... Content

          // v1.6.9: Pfeil für Navigation
          if (onTap != null)
            Icon(Icons.chevron_right),
        ],
      ),
    );
  }

  Widget _buildPOIImage(ColorScheme colorScheme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 48,
        height: 48,
        child: imageUrl != null
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                placeholder: (ctx, url) => _buildImagePlaceholder(colorScheme),
                errorWidget: (ctx, url, error) => _buildImagePlaceholder(colorScheme),
              )
            : _buildImagePlaceholder(colorScheme),
      ),
    );
  }
}
```

**4. Navigation zu POI-Details:**

```dart
return _StopItem(
  // ... andere Parameter
  imageUrl: imageUrl,
  category: category,
  poiId: stop.poiId,
  onTap: () {
    // v1.6.9: Navigation zu POI-Details
    final poiNotifier = ref.read(pOIStateNotifierProvider.notifier);
    if (poiFromState == null) {
      // Konvertiere TripStop zu POI und füge hinzu
      final poi = stop.toPOI();
      poiNotifier.addPOI(poi);
    }
    context.push('/poi/${stop.poiId}');
  },
);
```

---

## 4. TripStop.toPOI() Methode

### Problem

Um von der AI Trip Preview zu den POI-Details zu navigieren, musste ein `TripStop` in ein `POI` konvertiert werden.

### Lösung

**Datei:** `lib/data/models/trip.dart`

```dart
@freezed
class TripStop with _$TripStop {
  const TripStop._();

  // ... bestehender Code

  /// Bild-URL (falls vorhanden - wird über POI-State gepflegt)
  String? get imageUrl => null;

  /// v1.6.9: Konvertiert TripStop zurück zu POI
  /// Nützlich für Navigation zu POI-Details
  POI toPOI() {
    return POI(
      id: poiId,
      name: name,
      latitude: latitude,
      longitude: longitude,
      categoryId: categoryId,
      routePosition: routePosition,
      detourKm: detourKm,
      detourMinutes: detourMinutes,
    );
  }
}
```

---

## Betroffene Dateien

| Datei | Änderung |
|-------|----------|
| `lib/features/favorites/favorites_screen.dart` | Auto-Enrichment, POI-Tracking, addPOI vor Navigation |
| `lib/features/trip/trip_screen.dart` | enrichPOI nach addPOI |
| `lib/features/random_trip/providers/random_trip_provider.dart` | `_enrichGeneratedPOIs()` Methode |
| `lib/features/random_trip/widgets/trip_preview_card.dart` | ConsumerWidget, POI-Bilder, Navigation |
| `lib/data/models/trip.dart` | `toPOI()` Methode |

---

## Verifikation

### Test 1: Favoriten-Screen
1. POIs zu Favoriten hinzufügen (verschiedene ohne Bilder)
2. Favoriten-Screen öffnen → POIs Tab
3. ✓ Fotos werden nach kurzer Zeit geladen (Enrichment läuft)
4. POI anklicken → Details öffnen sich mit Foto

### Test 2: Trip-Screen
1. Route mit Stops berechnen (Schnell-Modus oder AI Trip)
2. Trip-Screen öffnen → "Deine Route"
3. Stop anklicken
4. ✓ POI-Details werden mit Foto angezeigt
5. ✓ Loading-Indikator während Enrichment

### Test 3: AI Trip Preview
1. AI Trip generieren (Tagesausflug oder Euro Trip)
2. In der Preview: Stop-Liste anzeigen
3. ✓ Nach kurzer Zeit erscheinen Fotos für die POIs (48x48 Thumbnails)
4. ✓ Chevron-Pfeil zeigt Navigation an
5. Stop anklicken → POI-Details öffnen sich

### Test 4: TripStop.toPOI()
1. AI Trip generieren
2. Stop in Preview anklicken
3. ✓ Navigation funktioniert ohne Fehler
4. ✓ POI-Details werden korrekt angezeigt

---

## Zusammenfassung

| Bereich | Vorher | Nachher |
|---------|--------|---------|
| Favoriten-Screen | Keine Fotos | Auto-Enrichment + Fotos |
| Trip-Screen Stops | Nur addPOI | addPOI + enrichPOI |
| AI Trip Preview | Nur Emojis | 48x48 Thumbnails + Navigation |
| TripStop → POI | Nicht möglich | toPOI() Methode |

## Architektur-Entscheidungen

### Warum addPOI() + enrichPOI() statt nur Navigation?

Der POI-Detail-Screen erwartet den POI im `POIStateNotifier`. Ohne `addPOI()` wird der POI nicht gefunden. Ohne `enrichPOI()` fehlen Foto und Beschreibung.

### Warum ConsumerWidget für _StopList?

Um den aktuellen POI-State abzurufen und auf Änderungen (z.B. neues Bild nach Enrichment) zu reagieren.

### Warum toPOI() in TripStop?

TripStop enthält nur die notwendigsten Daten für die Route. Für die POI-Detail-Navigation wird ein vollständiges POI-Objekt benötigt.
