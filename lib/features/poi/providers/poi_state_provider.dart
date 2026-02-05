import 'dart:async';
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

    /// DEPRECATED: Globales Enrichment-Flag (für Rückwärtskompatibilität)
    /// Nutze stattdessen enrichingPOIIds
    @Default(false) bool isEnriching,

    /// OPTIMIERT v1.3.7: Per-POI Enrichment-Tracking
    @Default({}) Set<String> enrichingPOIIds,

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

    /// Filter: Maximaler Umweg in km (erhöht von 45 auf 100 für bessere Abdeckung)
    @Default(100.0) double maxDetourKm,

    /// Filter: Suchtext
    @Default('') String searchQuery,

    /// Nur POIs auf der Route anzeigen (mit routePosition)
    @Default(false) bool routeOnlyMode,

    /// Nur Indoor/wetter-resistente POIs anzeigen (bei schlechtem Wetter)
    @Default(false) bool indoorOnlyFilter,
  }) = _POIState;

  /// Prüft ob ein bestimmter POI gerade enriched wird
  bool isPOIEnriching(String poiId) => enrichingPOIIds.contains(poiId);

  /// Gefilterte POIs basierend auf aktuellen Filtern
  List<POI> get filteredPOIs {
    var result = pois;
    final initialCount = result.length;

    // Route-Only-Modus: Nur POIs mit routePosition (auf der Route)
    if (routeOnlyMode) {
      result = result.where((poi) => poi.routePosition != null).toList();
      debugPrint('[POIState] Filter routeOnlyMode: $initialCount → ${result.length}');
    }

    // Kategorie-Filter
    if (selectedCategories.isNotEmpty) {
      final beforeCount = result.length;
      result = result
          .where((poi) => selectedCategories
              .any((cat) => cat.id == poi.categoryId))
          .toList();
      debugPrint('[POIState] Filter Kategorien: $beforeCount → ${result.length}');
    }

    // Must-See Filter
    if (mustSeeOnly) {
      final beforeCount = result.length;
      result = result.where((poi) => poi.isMustSee).toList();
      debugPrint('[POIState] Filter mustSeeOnly: $beforeCount → ${result.length}');
    }

    // FIX v1.5.3: Umweg-Filter NUR wenn routeOnlyMode aktiv
    // Vorher wurde dieser Filter IMMER angewendet, was POIs ohne Route herausfilterte
    if (routeOnlyMode) {
      final beforeCount = result.length;
      result = result
          .where((poi) =>
              poi.detourKm == null || poi.detourKm! <= maxDetourKm)
          .toList();
      debugPrint('[POIState] Filter detourKm (<= $maxDetourKm km): $beforeCount → ${result.length}');
    }

    // Indoor-Only Filter (bei schlechtem Wetter)
    if (indoorOnlyFilter) {
      final beforeCount = result.length;
      result = result.where((poi) {
        final cat = POICategory.fromId(poi.categoryId);
        return cat?.isWeatherResilient ?? false;
      }).toList();
      debugPrint('[POIState] Filter indoorOnly: $beforeCount → ${result.length}');
    }

    // Suchtext-Filter
    if (searchQuery.isNotEmpty) {
      final beforeCount = result.length;
      final query = searchQuery.toLowerCase();
      result = result
          .where((poi) =>
              poi.name.toLowerCase().contains(query) ||
              poi.categoryLabel.toLowerCase().contains(query) ||
              (poi.description?.toLowerCase().contains(query) ?? false))
          .toList();
      debugPrint('[POIState] Filter Suche "$searchQuery": $beforeCount → ${result.length}');
    }

    debugPrint('[POIState] filteredPOIs: $initialCount → ${result.length} (routeOnlyMode=$routeOnlyMode)');
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
      maxDetourKm < 100 ||
      searchQuery.isNotEmpty ||
      routeOnlyMode;
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
    bool forceReload = false,
  }) async {
    debugPrint('[POIState] loadPOIsInRadius: center=$center, radius=$radiusKm, forceReload=$forceReload');
    debugPrint('[POIState] Aktueller State: ${state.pois.length} POIs, routeOnlyMode=${state.routeOnlyMode}');

    // Prüfen ob bereits für diese Position geladen
    // FIX v1.5.2: Auch neu laden wenn keine POIs vorhanden sind
    final hasEnoughPOIs = state.pois.isNotEmpty;
    if (!forceReload &&
        hasEnoughPOIs &&
        state.lastLoadedCenter != null &&
        state.lastLoadedRadius == radiusKm &&
        _isNearby(state.lastLoadedCenter!, center, 5)) {
      debugPrint('[POIState] POIs bereits für diese Position geladen (${state.pois.length} POIs)');
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
    debugPrint('[POIState] loadPOIsForRoute gestartet');
    state = state.copyWith(isLoading: true, error: null);

    try {
      final repo = ref.read(poiRepositoryProvider);
      final pois = await repo.loadAllPOIs(route);

      debugPrint('[POIState] ${pois.length} POIs von Repo erhalten');

      state = state.copyWith(
        pois: pois,
        isLoading: false,
      );

      debugPrint('[POIState] ${pois.length} POIs für Route geladen, routeOnlyMode=${state.routeOnlyMode}');
    } catch (e) {
      debugPrint('[POIState] Fehler beim Laden der Route-POIs: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Fehler beim Laden der Route-POIs: $e',
      );
    }
  }

  /// FIX v1.10.2: Pending Enrichments fuer Debouncing
  final Map<String, POI> _pendingEnrichments = {};
  Timer? _enrichmentDebouncer;

  /// Reichert mehrere POIs in einem Batch an (OPTIMIERT v1.7.3, v1.10.2 Debouncing)
  /// Nutzt Wikipedia Multi-Title-Query für bis zu 50 POIs gleichzeitig
  Future<void> enrichPOIsBatch(List<POI> pois) async {
    if (pois.isEmpty) return;

    // Nur nicht-enriched POIs filtern
    final unenrichedPOIs = pois.where((p) => !p.isEnriched).toList();
    if (unenrichedPOIs.isEmpty) {
      debugPrint('[POIState] Alle POIs bereits enriched');
      return;
    }

    debugPrint('[POIState] Batch-Enrichment für ${unenrichedPOIs.length} POIs');

    // Markiere alle als "in Arbeit"
    final newEnrichingIds = {...state.enrichingPOIIds, ...unenrichedPOIs.map((p) => p.id)};
    state = state.copyWith(
      isEnriching: true,
      enrichingPOIIds: newEnrichingIds,
    );

    try {
      final enrichmentService = ref.read(poiEnrichmentServiceProvider);

      // v1.10.2: Debounced Updates statt sofortiger State-Kopie bei jedem Callback
      final enrichedPOIs = await enrichmentService.enrichPOIsBatch(
        unenrichedPOIs,
        onPartialResult: (partialResults) {
          // Sammle Ergebnisse statt sofort zu updaten
          _pendingEnrichments.addAll(partialResults);

          // Debounce: Nur alle 300ms ein State-Update
          _enrichmentDebouncer?.cancel();
          _enrichmentDebouncer = Timer(const Duration(milliseconds: 300), () {
            _flushPendingEnrichments();
          });
        },
      );

      // Debouncer canceln und finale Ergebnisse flushen
      _enrichmentDebouncer?.cancel();
      _pendingEnrichments.addAll(enrichedPOIs);
      _flushPendingEnrichments();

      // Loading State entfernen - ALLE gesendeten POIs, nicht nur die mit Ergebnis
      final remainingEnrichingIds = Set<String>.from(state.enrichingPOIIds)
        ..removeAll(unenrichedPOIs.map((p) => p.id));

      state = state.copyWith(
        isEnriching: remainingEnrichingIds.isNotEmpty,
        enrichingPOIIds: remainingEnrichingIds,
      );

      debugPrint('[POIState] Batch-Enrichment abgeschlossen: ${enrichedPOIs.length} POIs aktualisiert');
    } catch (e) {
      // Cleanup bei Fehler
      _enrichmentDebouncer?.cancel();
      _pendingEnrichments.clear();

      // Loading State entfernen bei Fehler
      final remainingEnrichingIds = Set<String>.from(state.enrichingPOIIds)
        ..removeAll(unenrichedPOIs.map((p) => p.id));
      state = state.copyWith(
        isEnriching: remainingEnrichingIds.isNotEmpty,
        enrichingPOIIds: remainingEnrichingIds,
      );
      debugPrint('[POIState] Batch-Enrichment Fehler: $e');
    }
  }

  /// FIX v1.10.2: Flusht alle pending Enrichments in einem State-Update
  void _flushPendingEnrichments() {
    if (_pendingEnrichments.isEmpty) return;

    final currentPOIs = List<POI>.from(state.pois);
    final updatedIds = <String>{};

    for (final entry in _pendingEnrichments.entries) {
      final index = currentPOIs.indexWhere((p) => p.id == entry.key);
      if (index != -1) {
        currentPOIs[index] = entry.value;
        updatedIds.add(entry.key);
      }
    }

    // Enriching IDs entfernen
    final remainingIds = Set<String>.from(state.enrichingPOIIds)
      ..removeAll(updatedIds);

    state = state.copyWith(
      pois: currentPOIs,
      isEnriching: remainingIds.isNotEmpty,
      enrichingPOIIds: remainingIds,
    );

    debugPrint('[POIState] Flushed ${_pendingEnrichments.length} enriched POIs');
    _pendingEnrichments.clear();
  }

  /// Reichert einen einzelnen POI an (on-demand)
  /// OPTIMIERT v1.3.7: Per-POI Loading State, Doppel-Enrichment-Schutz
  /// FIX v1.5.1: Race Condition behoben - State wird atomar aktualisiert
  Future<void> enrichPOI(String poiId) async {
    final poiIndex = state.pois.indexWhere((p) => p.id == poiId);
    if (poiIndex == -1) return;

    final poi = state.pois[poiIndex];
    if (poi.isEnriched) {
      debugPrint('[POIState] POI bereits angereichert: ${poi.name}');
      return;
    }

    // Doppel-Enrichment verhindern
    if (state.enrichingPOIIds.contains(poiId)) {
      debugPrint('[POIState] POI wird bereits enriched: ${poi.name}');
      return;
    }

    // Per-POI Loading State setzen
    state = state.copyWith(
      isEnriching: true,
      enrichingPOIIds: {...state.enrichingPOIIds, poiId},
    );

    try {
      final enrichmentService = ref.read(poiEnrichmentServiceProvider);
      final enrichedPOI = await enrichmentService.enrichPOI(poi);

      // FIX v1.5.1: Race Condition - State ATOMAR aktualisieren
      // Lese den AKTUELLEN State und aktualisiere nur den einen POI
      // Dies verhindert, dass parallele Enrichments sich gegenseitig überschreiben
      // FIX v1.7.27: isEnriched wird jetzt vom Service gesetzt (basierend auf hasImage)
      // Vorher wurde hier IMMER isEnriched: true gesetzt, auch ohne Bild
      _updatePOIInState(poiId, enrichedPOI);

      debugPrint('[POIState] POI angereichert: ${poi.name}');
    } catch (e) {
      // Loading State entfernen auch bei Fehler
      final newEnrichingIds = Set<String>.from(state.enrichingPOIIds)..remove(poiId);
      state = state.copyWith(
        isEnriching: newEnrichingIds.isNotEmpty,
        enrichingPOIIds: newEnrichingIds,
      );
      debugPrint('[POIState] Enrichment-Fehler: $e');
    }
  }

  /// Aktualisiert einen einzelnen POI im State atomar
  /// FIX v1.5.1: Verhindert Race Conditions bei parallelen Updates
  void _updatePOIInState(String poiId, POI updatedPOI) {
    // WICHTIG: Lese den AKTUELLEN State (nicht eine alte Kopie)
    final currentPOIs = state.pois;
    final currentIndex = currentPOIs.indexWhere((p) => p.id == poiId);

    debugPrint('[POIState] _updatePOIInState: poiId=$poiId, currentIndex=$currentIndex, totalPOIs=${currentPOIs.length}');

    if (currentIndex == -1) {
      // POI nicht mehr in der Liste - nur Loading State entfernen
      debugPrint('[POIState] POI $poiId nicht mehr in Liste - nur Loading State entfernen');
      final newEnrichingIds = Set<String>.from(state.enrichingPOIIds)..remove(poiId);
      state = state.copyWith(
        isEnriching: newEnrichingIds.isNotEmpty,
        enrichingPOIIds: newEnrichingIds,
      );
      return;
    }

    // Neue Liste mit aktualisiertem POI erstellen
    final updatedPOIs = List<POI>.from(currentPOIs);
    updatedPOIs[currentIndex] = updatedPOI;

    // Loading State entfernen
    final newEnrichingIds = Set<String>.from(state.enrichingPOIIds)..remove(poiId);

    debugPrint('[POIState] POI aktualisiert: ${updatedPOI.name}, neue Liste hat ${updatedPOIs.length} POIs');

    state = state.copyWith(
      pois: updatedPOIs,
      isEnriching: newEnrichingIds.isNotEmpty,
      enrichingPOIIds: newEnrichingIds,
      // Auch selectedPOI aktualisieren wenn es der gleiche ist
      selectedPOI: state.selectedPOI?.id == poiId
          ? updatedPOI
          : state.selectedPOI,
    );

    debugPrint('[POIState] Nach Update: ${state.pois.length} POIs im State');
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
      maxDetourKm: 100.0,
      searchQuery: '',
      routeOnlyMode: false,
      indoorOnlyFilter: false,
    );
  }

  /// Route-Only-Modus setzen (nur POIs auf der Route anzeigen)
  void setRouteOnlyMode(bool enabled) {
    state = state.copyWith(routeOnlyMode: enabled);
    debugPrint('[POIState] Route-Only-Modus: $enabled');
  }

  /// Indoor-Only-Filter setzen (bei schlechtem Wetter)
  void setIndoorOnly(bool enabled) {
    state = state.copyWith(indoorOnlyFilter: enabled);
    debugPrint('[POIState] Indoor-Only-Filter: $enabled');
  }

  /// Alle POIs löschen
  void clearPOIs() {
    state = const POIState();
    debugPrint('[POIState] Alle POIs gelöscht');
  }

  /// Fügt einen einzelnen POI zum State hinzu (für Navigation von TripScreen)
  /// v1.6.8: Ermöglicht POI-Details-Anzeige für Trip-Stops
  void addPOI(POI poi) {
    final existingIndex = state.pois.indexWhere((p) => p.id == poi.id);
    if (existingIndex != -1) {
      // POI bereits vorhanden - aktualisieren
      final updatedPOIs = List<POI>.from(state.pois);
      updatedPOIs[existingIndex] = poi;
      state = state.copyWith(pois: updatedPOIs);
      debugPrint('[POIState] POI aktualisiert: ${poi.name}');
    } else {
      // POI hinzufügen
      state = state.copyWith(pois: [...state.pois, poi]);
      debugPrint('[POIState] POI hinzugefügt: ${poi.name}');
    }
  }

  /// FIX v1.10.2: Fügt mehrere POIs in einem Batch hinzu
  /// Verhindert 12+ einzelne State-Updates bei Euro Trip Generierung
  void addPOIsBatch(List<POI> pois) {
    if (pois.isEmpty) return;

    final updatedPOIs = List<POI>.from(state.pois);
    int added = 0;
    int updated = 0;

    for (final poi in pois) {
      final existingIndex = updatedPOIs.indexWhere((p) => p.id == poi.id);
      if (existingIndex != -1) {
        updatedPOIs[existingIndex] = poi;
        updated++;
      } else {
        updatedPOIs.add(poi);
        added++;
      }
    }

    // EIN State-Update statt N Updates
    state = state.copyWith(pois: updatedPOIs);
    debugPrint('[POIState] Batch: $added hinzugefügt, $updated aktualisiert (gesamt: ${updatedPOIs.length})');
  }

  /// Prüft ob ein POI gerade enriched wird (für UI)
  bool isPOIEnriching(String poiId) => state.enrichingPOIIds.contains(poiId);

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
