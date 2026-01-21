import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/constants/categories.dart';
import '../../../data/models/poi.dart';
import '../../../data/models/route.dart';
import '../../../data/repositories/poi_repo.dart';
import '../../../data/services/poi_enrichment_service.dart';

part 'poi_state_provider.freezed.dart';
part 'poi_state_provider.g.dart';

/// State für POI-Verwaltung
@freezed
class POIState with _$POIState {
  const POIState._();

  const factory POIState({
    /// Alle geladenen POIs
    @Default([]) List<POI> pois,

    /// Aktuell ausgewählter POI (für Detail-Ansicht)
    POI? selectedPOI,

    /// Laden-Status
    @Default(false) bool isLoading,

    /// Enrichment läuft
    @Default(false) bool isEnriching,

    /// Fehlermeldung
    String? error,

    /// Letzte Lade-Position (für Caching)
    LatLng? lastLoadedCenter,

    /// Letzter Lade-Radius (für Caching)
    double? lastLoadedRadius,

    /// Filter: Ausgewählte Kategorien
    @Default({}) Set<POICategory> selectedCategories,

    /// Filter: Nur Must-See
    @Default(false) bool mustSeeOnly,

    /// Filter: Maximaler Umweg in km
    @Default(45.0) double maxDetourKm,

    /// Filter: Suchtext
    @Default('') String searchQuery,
  }) = _POIState;

  /// Gefilterte POIs basierend auf aktuellen Filtern
  List<POI> get filteredPOIs {
    var result = pois;

    // Kategorie-Filter
    if (selectedCategories.isNotEmpty) {
      result = result
          .where((poi) => selectedCategories
              .any((cat) => cat.id == poi.categoryId))
          .toList();
    }

    // Must-See Filter
    if (mustSeeOnly) {
      result = result.where((poi) => poi.isMustSee).toList();
    }

    // Umweg-Filter (nur wenn routePosition vorhanden)
    result = result
        .where((poi) =>
            poi.detourKm == null || poi.detourKm! <= maxDetourKm)
        .toList();

    // Suchtext-Filter
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      result = result
          .where((poi) =>
              poi.name.toLowerCase().contains(query) ||
              poi.categoryLabel.toLowerCase().contains(query) ||
              (poi.description?.toLowerCase().contains(query) ?? false))
          .toList();
    }

    return result;
  }

  /// Anzahl der POIs nach Filter
  int get filteredCount => filteredPOIs.length;

  /// Anzahl aller geladenen POIs
  int get totalCount => pois.length;

  /// Hat aktive Filter
  bool get hasActiveFilters =>
      selectedCategories.isNotEmpty ||
      mustSeeOnly ||
      maxDetourKm < 45 ||
      searchQuery.isNotEmpty;
}

/// POI State Notifier mit keepAlive
@Riverpod(keepAlive: true)
class POIStateNotifier extends _$POIStateNotifier {
  @override
  POIState build() {
    return const POIState();
  }

  /// Lädt POIs in einem Radius um einen Punkt
  Future<void> loadPOIsInRadius({
    required LatLng center,
    required double radiusKm,
    List<String>? categoryFilter,
  }) async {
    // Prüfen ob bereits für diese Position geladen
    if (state.lastLoadedCenter != null &&
        state.lastLoadedRadius == radiusKm &&
        _isNearby(state.lastLoadedCenter!, center, 5)) {
      debugPrint('[POIState] POIs bereits für diese Position geladen');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final repo = ref.read(poiRepositoryProvider);
      final pois = await repo.loadPOIsInRadius(
        center: center,
        radiusKm: radiusKm,
        categoryFilter: categoryFilter,
      );

      state = state.copyWith(
        pois: pois,
        isLoading: false,
        lastLoadedCenter: center,
        lastLoadedRadius: radiusKm,
      );

      debugPrint('[POIState] ${pois.length} POIs geladen');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Fehler beim Laden der POIs: $e',
      );
      debugPrint('[POIState] Fehler: $e');
    }
  }

  /// Lädt POIs für eine Route
  Future<void> loadPOIsForRoute(AppRoute route) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final repo = ref.read(poiRepositoryProvider);
      final pois = await repo.loadAllPOIs(route);

      state = state.copyWith(
        pois: pois,
        isLoading: false,
      );

      debugPrint('[POIState] ${pois.length} POIs für Route geladen');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Fehler beim Laden der Route-POIs: $e',
      );
    }
  }

  /// Reichert einen einzelnen POI an (on-demand)
  Future<void> enrichPOI(String poiId) async {
    final poiIndex = state.pois.indexWhere((p) => p.id == poiId);
    if (poiIndex == -1) return;

    final poi = state.pois[poiIndex];
    if (poi.isEnriched) {
      debugPrint('[POIState] POI bereits angereichert: ${poi.name}');
      return;
    }

    state = state.copyWith(isEnriching: true);

    try {
      final enrichmentService = ref.read(poiEnrichmentServiceProvider);
      final enrichedPOI = await enrichmentService.enrichPOI(poi);

      // POI in Liste aktualisieren
      final updatedPOIs = List<POI>.from(state.pois);
      updatedPOIs[poiIndex] = enrichedPOI.copyWith(isEnriched: true);

      state = state.copyWith(
        pois: updatedPOIs,
        isEnriching: false,
        // Auch selectedPOI aktualisieren wenn es der gleiche ist
        selectedPOI: state.selectedPOI?.id == poiId
            ? enrichedPOI.copyWith(isEnriched: true)
            : state.selectedPOI,
      );

      debugPrint('[POIState] POI angereichert: ${poi.name}');
    } catch (e) {
      state = state.copyWith(isEnriching: false);
      debugPrint('[POIState] Enrichment-Fehler: $e');
    }
  }

  /// Wählt einen POI aus (für Detail-Ansicht)
  void selectPOI(POI? poi) {
    state = state.copyWith(selectedPOI: poi);
  }

  /// POI nach ID finden und auswählen
  void selectPOIById(String poiId) {
    final poi = state.pois.firstWhere(
      (p) => p.id == poiId,
      orElse: () => throw Exception('POI nicht gefunden'),
    );
    selectPOI(poi);
  }

  /// Filter: Kategorien setzen
  void setSelectedCategories(Set<POICategory> categories) {
    state = state.copyWith(selectedCategories: categories);
  }

  /// Filter: Must-See toggle
  void toggleMustSeeOnly() {
    state = state.copyWith(mustSeeOnly: !state.mustSeeOnly);
  }

  /// Filter: Maximaler Umweg setzen
  void setMaxDetour(double km) {
    state = state.copyWith(maxDetourKm: km);
  }

  /// Filter: Suchtext setzen
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Filter zurücksetzen
  void resetFilters() {
    state = state.copyWith(
      selectedCategories: {},
      mustSeeOnly: false,
      maxDetourKm: 45.0,
      searchQuery: '',
    );
  }

  /// Alle POIs löschen
  void clearPOIs() {
    state = const POIState();
  }

  /// Prüft ob zwei Punkte nahe beieinander sind
  bool _isNearby(LatLng a, LatLng b, double thresholdKm) {
    // Einfache Distanz-Berechnung
    final latDiff = (a.latitude - b.latitude).abs();
    final lngDiff = (a.longitude - b.longitude).abs();
    final approxKm = (latDiff + lngDiff) * 111; // Grobe Schätzung
    return approxKm < thresholdKm;
  }
}

/// Provider für den aktuell ausgewählten POI
@riverpod
POI? selectedPOI(SelectedPOIRef ref) {
  return ref.watch(pOIStateNotifierProvider).selectedPOI;
}

/// Provider für gefilterte POI-Liste
@riverpod
List<POI> filteredPOIs(FilteredPOIsRef ref) {
  return ref.watch(pOIStateNotifierProvider).filteredPOIs;
}

/// Provider für Lade-Status
@riverpod
bool poisLoading(PoisLoadingRef ref) {
  return ref.watch(pOIStateNotifierProvider).isLoading;
}
