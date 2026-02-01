import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../core/algorithms/day_planner.dart';
import '../../core/algorithms/random_poi_selector.dart';
import '../../core/algorithms/route_optimizer.dart';
import '../../core/constants/categories.dart';
import '../../core/constants/trip_constants.dart';
import '../../core/utils/geo_utils.dart';
import '../models/poi.dart';
import '../models/trip.dart';
import '../services/hotel_service.dart';
import 'poi_repo.dart';
import 'routing_repo.dart';

part 'trip_generator_repo.g.dart';

/// Repository für die Generierung von Zufalls-Trips
/// Kombiniert POI-Auswahl, Route-Optimierung und Tagesplanung
class TripGeneratorRepository {
  final POIRepository _poiRepo;
  final RoutingRepository _routingRepo;
  final HotelService _hotelService;
  final RandomPOISelector _poiSelector;
  final RouteOptimizer _routeOptimizer;
  final DayPlanner _dayPlanner;
  final Uuid _uuid;

  TripGeneratorRepository({
    POIRepository? poiRepo,
    RoutingRepository? routingRepo,
    HotelService? hotelService,
    RandomPOISelector? poiSelector,
    RouteOptimizer? routeOptimizer,
    DayPlanner? dayPlanner,
  })  : _poiRepo = poiRepo ?? POIRepository(),
        _routingRepo = routingRepo ?? RoutingRepository(),
        _hotelService = hotelService ?? HotelService(),
        _poiSelector = poiSelector ?? RandomPOISelector(),
        _routeOptimizer = routeOptimizer ?? RouteOptimizer(),
        _dayPlanner = dayPlanner ?? DayPlanner(),
        _uuid = const Uuid();

  /// Generiert einen Tagesausflug
  ///
  /// [startLocation] - Startpunkt
  /// [startAddress] - Adresse des Startpunkts
  /// [radiusKm] - Suchradius für POIs (oder Korridor-Breite bei Ziel)
  /// [categories] - Bevorzugte Kategorien
  /// [poiCount] - Anzahl gewünschter POIs
  /// [destinationLocation] - Optionaler Zielpunkt (wenn null → Rundreise)
  /// [destinationAddress] - Optionale Zieladresse
  Future<GeneratedTrip> generateDayTrip({
    required LatLng startLocation,
    required String startAddress,
    double radiusKm = 100,
    List<POICategory> categories = const [],
    int poiCount = 5,
    LatLng? destinationLocation,
    String? destinationAddress,
  }) async {
    final hasDestination = destinationLocation != null;
    final endLocation = destinationLocation ?? startLocation;
    final endAddress = destinationAddress ?? startAddress;

    // 1. POIs laden — Korridor oder Radius
    final categoryIds = categories.isNotEmpty
        ? categories.map((c) => c.id).toList()
        : null;

    List<POI> availablePOIs;
    if (hasDestination) {
      debugPrint('[TripGenerator] Tagestrip Korridor-Modus: $startAddress → $endAddress, ${radiusKm}km Breite');
      availablePOIs = await _loadPOIsAlongCorridor(
        start: startLocation,
        end: destinationLocation!,
        bufferKm: radiusKm,
        categoryFilter: categoryIds,
      );
    } else {
      availablePOIs = await _poiRepo.loadPOIsInRadius(
        center: startLocation,
        radiusKm: radiusKm,
        categoryFilter: categoryIds,
      );
    }

    if (availablePOIs.isEmpty) {
      throw TripGenerationException(
        hasDestination
            ? 'Keine POIs entlang der Route $startAddress → $endAddress gefunden'
            : 'Keine POIs im Umkreis von ${radiusKm}km gefunden',
      );
    }

    // 2. Zufällige POIs auswählen
    final selectedPOIs = _poiSelector.selectRandomPOIs(
      pois: availablePOIs,
      startLocation: startLocation,
      count: poiCount,
      preferredCategories: categories,
    );

    if (selectedPOIs.isEmpty) {
      throw TripGenerationException('Keine passenden POIs gefunden');
    }

    // 3. Route optimieren
    final optimizedPOIs = _routeOptimizer.optimizeRoute(
      pois: selectedPOIs,
      startLocation: startLocation,
      returnToStart: !hasDestination,
    );

    // 4. Echte Route berechnen
    final waypoints = optimizedPOIs.map((p) => p.location).toList();
    final route = await _routingRepo.calculateFastRoute(
      start: startLocation,
      end: endLocation,
      waypoints: waypoints,
      startAddress: startAddress,
      endAddress: endAddress,
    );

    // 5. Trip erstellen
    final trip = Trip(
      id: _uuid.v4(),
      name: _generateTripName(optimizedPOIs),
      type: TripType.daytrip,
      route: route,
      stops: optimizedPOIs.asMap().entries.map((entry) {
        return TripStop.fromPOI(entry.value).copyWith(order: entry.key);
      }).toList(),
      days: 1,
      createdAt: DateTime.now(),
      preferredCategories: categories.map((c) => c.id).toList(),
    );

    return GeneratedTrip(
      trip: trip,
      availablePOIs: availablePOIs,
      selectedPOIs: optimizedPOIs,
    );
  }

  /// Generiert einen Euro Trip (Mehrtages-Reise)
  ///
  /// [startLocation] - Startpunkt
  /// [startAddress] - Adresse des Startpunkts
  /// [radiusKm] - Such-Radius in km (oder Korridor-Breite bei Ziel)
  /// [categories] - Bevorzugte Kategorien
  /// [includeHotels] - Hotels vorschlagen
  /// [destinationLocation] - Optionaler Zielpunkt (wenn null → Rundreise)
  /// [destinationAddress] - Optionale Zieladresse
  Future<GeneratedTrip> generateEuroTrip({
    required LatLng startLocation,
    required String startAddress,
    double radiusKm = 1000,
    List<POICategory> categories = const [],
    bool includeHotels = true,
    LatLng? destinationLocation,
    String? destinationAddress,
  }) async {
    final hasDestination = destinationLocation != null;
    final endLocation = destinationLocation ?? startLocation;
    final endAddress = destinationAddress ?? startAddress;

    // Tage basierend auf Radius berechnen (600km = 1 Tag)
    final days = TripConstants.calculateDaysFromDistance(radiusKm);
    debugPrint('[TripGenerator] Euro Trip: ${radiusKm}km -> $days Tage${hasDestination ? ' (Ziel: $endAddress)' : ' (Rundreise)'}');

    // POIs pro Tag (max 9 wegen Google Maps Limit)
    final poisPerDay = min(
      DayPlanner.estimatePoisPerDay(),
      TripConstants.maxPoisPerDay,
    );
    final totalPOIs = days * poisPerDay;
    debugPrint('[TripGenerator] POIs: $poisPerDay pro Tag, $totalPOIs gesamt');

    // 1. POIs laden — Korridor oder Radius
    final categoryIds = categories.isNotEmpty
        ? categories.map((c) => c.id).toList()
        : null;

    List<POI> availablePOIs;
    if (hasDestination) {
      debugPrint('[TripGenerator] Euro Trip Korridor-Modus: $startAddress → $endAddress, ${radiusKm}km Breite');
      availablePOIs = await _loadPOIsAlongCorridor(
        start: startLocation,
        end: destinationLocation!,
        bufferKm: radiusKm,
        categoryFilter: categoryIds,
      ).timeout(
        const Duration(seconds: 45),
        onTimeout: () {
          debugPrint('[TripGenerator] ⚠️ Korridor POI-Laden Timeout nach 45s');
          return <POI>[];
        },
      );
    } else {
      availablePOIs = await _poiRepo.loadPOIsInRadius(
        center: startLocation,
        radiusKm: radiusKm,
        categoryFilter: categoryIds,
      ).timeout(
        const Duration(seconds: 45),
        onTimeout: () {
          debugPrint('[TripGenerator] ⚠️ POI-Laden Timeout nach 45s');
          return <POI>[];
        },
      );
    }

    debugPrint('[TripGenerator] ${availablePOIs.length} POIs gefunden');

    if (availablePOIs.isEmpty) {
      throw TripGenerationException(
        hasDestination
            ? 'Keine POIs entlang der Route $startAddress → $endAddress gefunden'
            : 'Keine POIs im Umkreis von ${radiusKm}km gefunden. '
              'Versuche einen anderen Startpunkt oder kleineren Radius.',
      );
    }

    // 2. Zufällige POIs auswählen
    final selectedPOIs = _poiSelector.selectRandomPOIs(
      pois: availablePOIs,
      startLocation: startLocation,
      count: totalPOIs,
      preferredCategories: categories,
      maxPerCategory: 3, // Mehr Diversität bei längeren Trips
    );

    if (selectedPOIs.isEmpty) {
      throw TripGenerationException('Keine passenden POIs gefunden');
    }

    // 3. Route optimieren
    final optimizedPOIs = _routeOptimizer.optimizeRoute(
      pois: selectedPOIs,
      startLocation: startLocation,
      returnToStart: !hasDestination,
    );

    // 4. Auf Tage aufteilen
    debugPrint('[TripGenerator] Plane $days Tage mit ${optimizedPOIs.length} POIs...');
    var tripDays = _dayPlanner.planDays(
      pois: optimizedPOIs,
      startLocation: startLocation,
      days: days,
      returnToStart: !hasDestination,
    );
    debugPrint('[TripGenerator] TripDays: ${tripDays.length}, Stops gesamt: ${tripDays.fold(0, (sum, d) => sum + d.stops.length)}');

    // 5. Hotels hinzufügen (optional)
    List<List<HotelSuggestion>> hotelSuggestions = [];
    if (includeHotels && days > 1) {
      final overnightLocations = _dayPlanner.calculateOvernightLocations(
        tripDays: tripDays,
        startLocation: startLocation,
      );

      hotelSuggestions = await _hotelService.searchHotelsForMultipleLocations(
        locations: overnightLocations,
        radiusKm: 15,
        limitPerLocation: 3,
      );

      // Beste Hotels als Stops hinzufügen
      final hotelStops = hotelSuggestions
          .where((list) => list.isNotEmpty)
          .map((list) => _hotelService.convertToTripStops([list.first]).first)
          .toList();

      tripDays = _dayPlanner.addOvernightStops(
        tripDays: tripDays,
        hotelStops: hotelStops,
      );
    }

    // 6. Gesamtroute berechnen
    final allWaypoints = <LatLng>[];
    for (final day in tripDays) {
      for (final stop in day.stops) {
        allWaypoints.add(stop.location);
      }
    }

    debugPrint('[TripGenerator] Route berechnen mit ${allWaypoints.length} Waypoints...');

    final route = await _routingRepo.calculateFastRoute(
      start: startLocation,
      end: endLocation,
      waypoints: allWaypoints,
      startAddress: startAddress,
      endAddress: endAddress,
    );

    debugPrint('[TripGenerator] ✓ Route berechnet: ${route.distanceKm.toStringAsFixed(0)}km');

    // 7. Trip erstellen
    final allStops = tripDays.expand((day) => day.stops).toList();

    final trip = Trip(
      id: _uuid.v4(),
      name: _generateEuroTripName(tripDays),
      type: TripType.eurotrip,
      route: route,
      stops: allStops,
      days: days,
      createdAt: DateTime.now(),
      preferredCategories: categories.map((c) => c.id).toList(),
    );

    return GeneratedTrip(
      trip: trip,
      availablePOIs: availablePOIs,
      selectedPOIs: optimizedPOIs,
      tripDays: tripDays,
      hotelSuggestions: hotelSuggestions,
    );
  }

  /// Entfernt einen einzelnen POI aus dem Trip
  Future<GeneratedTrip> removePOI({
    required GeneratedTrip currentTrip,
    required String poiIdToRemove,
    required LatLng startLocation,
    required String startAddress,
  }) async {
    // Prüfen ob genug POIs übrig bleiben (min 2)
    if (currentTrip.selectedPOIs.length <= 2) {
      throw TripGenerationException(
        'Mindestens 2 Stops müssen im Trip bleiben',
      );
    }

    // POI aus der Liste entfernen
    final newSelectedPOIs = currentTrip.selectedPOIs
        .where((p) => p.id != poiIdToRemove)
        .toList();

    // Route neu optimieren
    final optimizedPOIs = _routeOptimizer.optimizeRoute(
      pois: newSelectedPOIs,
      startLocation: startLocation,
      returnToStart: true,
    );

    // Neue Route berechnen
    final waypoints = optimizedPOIs.map((p) => p.location).toList();
    final route = await _routingRepo.calculateFastRoute(
      start: startLocation,
      end: startLocation,
      waypoints: waypoints,
      startAddress: startAddress,
      endAddress: startAddress,
    );

    // Trip aktualisieren
    final updatedTrip = currentTrip.trip.copyWith(
      name: _generateTripName(optimizedPOIs),
      route: route,
      stops: optimizedPOIs.asMap().entries.map((entry) {
        return TripStop.fromPOI(entry.value).copyWith(order: entry.key);
      }).toList(),
      updatedAt: DateTime.now(),
    );

    return GeneratedTrip(
      trip: updatedTrip,
      availablePOIs: currentTrip.availablePOIs,
      selectedPOIs: optimizedPOIs,
    );
  }

  /// Würfelt einen einzelnen POI neu
  Future<GeneratedTrip> rerollPOI({
    required GeneratedTrip currentTrip,
    required String poiIdToReroll,
    required LatLng startLocation,
    required String startAddress,
    List<POICategory> categories = const [],
  }) async {
    final poiToReplace = currentTrip.selectedPOIs
        .firstWhere((p) => p.id == poiIdToReroll);

    // Neuen POI auswählen
    final newPOI = _poiSelector.rerollSinglePOI(
      availablePOIs: currentTrip.availablePOIs,
      currentSelection: currentTrip.selectedPOIs,
      poiToReplace: poiToReplace,
      startLocation: startLocation,
      preferredCategories: categories,
    );

    if (newPOI == null) {
      throw TripGenerationException('Kein alternativer POI verfügbar');
    }

    // Neue POI-Liste erstellen
    final newSelectedPOIs = currentTrip.selectedPOIs.map((p) {
      return p.id == poiIdToReroll ? newPOI : p;
    }).toList();

    // Route neu optimieren
    final optimizedPOIs = _routeOptimizer.optimizeRoute(
      pois: newSelectedPOIs,
      startLocation: startLocation,
      returnToStart: true,
    );

    // Neue Route berechnen
    final waypoints = optimizedPOIs.map((p) => p.location).toList();
    final route = await _routingRepo.calculateFastRoute(
      start: startLocation,
      end: startLocation,
      waypoints: waypoints,
      startAddress: startAddress,
      endAddress: startAddress,
    );

    // Trip aktualisieren
    final updatedTrip = currentTrip.trip.copyWith(
      route: route,
      stops: optimizedPOIs.asMap().entries.map((entry) {
        return TripStop.fromPOI(entry.value).copyWith(order: entry.key);
      }).toList(),
      updatedAt: DateTime.now(),
    );

    return GeneratedTrip(
      trip: updatedTrip,
      availablePOIs: currentTrip.availablePOIs,
      selectedPOIs: optimizedPOIs,
    );
  }

  /// Lädt POIs entlang eines Korridors (Start→Ziel mit Buffer)
  /// Berechnet eine Direct-Route und sucht POIs in der Bounding Box
  Future<List<POI>> _loadPOIsAlongCorridor({
    required LatLng start,
    required LatLng end,
    required double bufferKm,
    List<String>? categoryFilter,
  }) async {
    // 1. Direct-Route berechnen (für genaue Korridor-Box)
    debugPrint('[TripGenerator] Berechne Direct-Route für Korridor...');
    final directRoute = await _routingRepo.calculateFastRoute(
      start: start,
      end: end,
      startAddress: '',
      endAddress: '',
    );

    // 2. Bounding Box entlang der Route mit Buffer
    final bounds = GeoUtils.calculateBoundsWithBuffer(
      directRoute.coordinates,
      bufferKm,
    );

    debugPrint('[TripGenerator] Korridor-Bounds: SW(${bounds.southwest.latitude.toStringAsFixed(2)}, ${bounds.southwest.longitude.toStringAsFixed(2)}) → NE(${bounds.northeast.latitude.toStringAsFixed(2)}, ${bounds.northeast.longitude.toStringAsFixed(2)})');

    // 3. POIs in der Box laden
    return await _poiRepo.loadPOIsInBounds(
      bounds: bounds,
      categoryFilter: categoryFilter,
    );
  }

  /// Generiert Trip-Namen basierend auf POIs
  String _generateTripName(List<POI> pois) {
    if (pois.isEmpty) return 'Tagesausflug';

    // Highlight finden (Must-See oder höchster Score)
    final highlight = pois.where((p) => p.isMustSee).firstOrNull ??
        pois.reduce((a, b) => a.score > b.score ? a : b);

    return 'Ausflug: ${highlight.name}';
  }

  /// Generiert Euro Trip-Namen
  String _generateEuroTripName(List<TripDay> days) {
    if (days.isEmpty) return 'Euro Trip';

    // Highlights aller Tage sammeln
    final highlights = <String>[];
    for (final day in days) {
      if (day.stops.isNotEmpty) {
        highlights.add(day.stops.first.name);
        if (highlights.length >= 2) break;
      }
    }

    if (highlights.isEmpty) return 'Euro Trip ${days.length} Tage';

    return '${days.length}-Tage-Trip: ${highlights.join(' → ')}';
  }
}

/// Ergebnis der Trip-Generierung
class GeneratedTrip {
  final Trip trip;
  final List<POI> availablePOIs;
  final List<POI> selectedPOIs;
  final List<TripDay>? tripDays;
  final List<List<HotelSuggestion>>? hotelSuggestions;

  GeneratedTrip({
    required this.trip,
    required this.availablePOIs,
    required this.selectedPOIs,
    this.tripDays,
    this.hotelSuggestions,
  });

  /// Ist Mehrtages-Trip
  bool get isMultiDay => trip.days > 1;

  /// Hat Hotel-Vorschläge
  bool get hasHotelSuggestions =>
      hotelSuggestions != null && hotelSuggestions!.any((list) => list.isNotEmpty);
}

/// Trip-Generierungs-Fehler
class TripGenerationException implements Exception {
  final String message;
  TripGenerationException(this.message);

  @override
  String toString() => 'TripGenerationException: $message';
}

/// Riverpod Provider für TripGeneratorRepository
@riverpod
TripGeneratorRepository tripGeneratorRepository(TripGeneratorRepositoryRef ref) {
  return TripGeneratorRepository();
}
