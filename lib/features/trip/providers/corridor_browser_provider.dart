import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/constants/categories.dart';
import '../../../core/utils/geo_utils.dart';
import '../../../data/models/poi.dart';
import '../../../data/models/route.dart';
import '../../../data/repositories/poi_repo.dart';

part 'corridor_browser_provider.g.dart';

/// State fuer den Korridor-Browser
class CorridorBrowserState {
  final List<POI> corridorPOIs;
  final bool isLoading;
  final String? error;
  final double bufferKm;
  final Set<POICategory> selectedCategories;
  final Set<String> addedPOIIds; // Bereits zum Trip hinzugefuegte POIs

  const CorridorBrowserState({
    this.corridorPOIs = const [],
    this.isLoading = false,
    this.error,
    this.bufferKm = 30.0,
    this.selectedCategories = const {},
    this.addedPOIIds = const {},
  });

  CorridorBrowserState copyWith({
    List<POI>? corridorPOIs,
    bool? isLoading,
    String? error,
    double? bufferKm,
    Set<POICategory>? selectedCategories,
    Set<String>? addedPOIIds,
  }) {
    return CorridorBrowserState(
      corridorPOIs: corridorPOIs ?? this.corridorPOIs,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      bufferKm: bufferKm ?? this.bufferKm,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      addedPOIIds: addedPOIIds ?? this.addedPOIIds,
    );
  }

  /// Gefilterte POIs (Kategorie-Filter + bereits hinzugefuegte ausblenden)
  List<POI> get filteredPOIs {
    var result = corridorPOIs;

    // Kategorie-Filter
    if (selectedCategories.isNotEmpty) {
      result = result
          .where((poi) => selectedCategories.contains(poi.category))
          .toList();
    }

    return result;
  }

  /// Anzahl neuer POIs (nicht im Trip)
  int get newPOICount =>
      filteredPOIs.where((p) => !addedPOIIds.contains(p.id)).length;
}

/// Provider fuer den Korridor-POI-Browser
@riverpod
class CorridorBrowserNotifier extends _$CorridorBrowserNotifier {
  @override
  CorridorBrowserState build() => const CorridorBrowserState();

  /// Laedt POIs entlang des Korridors einer Route
  Future<void> loadCorridorPOIs({
    required AppRoute route,
    double? bufferKm,
    Set<String>? existingStopIds,
  }) async {
    final effectiveBuffer = bufferKm ?? state.bufferKm;
    state = state.copyWith(
      isLoading: true,
      error: null,
      bufferKm: effectiveBuffer,
      addedPOIIds: existingStopIds ?? state.addedPOIIds,
    );

    try {
      final poiRepo = ref.read(poiRepositoryProvider);

      // Korridor-Bounds berechnen (Route + Puffer)
      final bounds = GeoUtils.calculateBoundsWithBuffer(
        route.coordinates,
        effectiveBuffer,
      );

      debugPrint('[CorridorBrowser] Lade POIs im Korridor: '
          '${effectiveBuffer.toStringAsFixed(0)}km Puffer');

      // Kategorie-Filter (leere Liste = alle)
      final categoryFilter = state.selectedCategories.isNotEmpty
          ? state.selectedCategories.map((c) => c.name).toList()
          : null;

      // POIs im Korridor laden (3-Layer: Kuratiert + Wikipedia + Overpass)
      final pois = await poiRepo.loadPOIsInBounds(
        bounds: bounds,
        categoryFilter: categoryFilter,
      );

      // Routen-Position und Umweg berechnen
      final enrichedPOIs = pois.map((poi) {
        final routePosition = GeoUtils.calculateRoutePosition(
          poi.location,
          route.coordinates,
        );
        final detourKm = GeoUtils.calculateDetour(
          poi.location,
          route.coordinates,
        );
        return poi.copyWith(
          routePosition: routePosition,
          detourKm: detourKm,
        );
      }).toList();

      // Nach Position auf Route sortieren (Start → Ziel)
      enrichedPOIs.sort((a, b) =>
          (a.routePosition ?? 0).compareTo(b.routePosition ?? 0));

      debugPrint('[CorridorBrowser] ${enrichedPOIs.length} POIs im Korridor gefunden');

      state = state.copyWith(
        corridorPOIs: enrichedPOIs,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('[CorridorBrowser] Fehler: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'POIs konnten nicht geladen werden',
      );
    }
  }

  /// Korridor-Breite aendern und neu laden
  Future<void> setBufferKm(double km, {required AppRoute route}) async {
    state = state.copyWith(bufferKm: km);
    await loadCorridorPOIs(route: route, bufferKm: km);
  }

  /// Kategorie-Filter setzen und neu laden
  Future<void> setCategories(
    Set<POICategory> categories, {
    required AppRoute route,
  }) async {
    state = state.copyWith(selectedCategories: categories);
    await loadCorridorPOIs(route: route);
  }

  /// Einzelne Kategorie toggeln
  void toggleCategory(POICategory category) {
    final updated = Set<POICategory>.from(state.selectedCategories);
    if (updated.contains(category)) {
      updated.remove(category);
    } else {
      updated.add(category);
    }
    state = state.copyWith(selectedCategories: updated);
  }

  /// POI als hinzugefuegt markieren
  void markAsAdded(String poiId) {
    state = state.copyWith(
      addedPOIIds: {...state.addedPOIIds, poiId},
    );
  }

  /// Zuruecksetzen
  void reset() {
    state = const CorridorBrowserState();
  }
}
