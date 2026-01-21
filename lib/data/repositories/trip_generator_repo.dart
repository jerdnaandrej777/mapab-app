import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../core/algorithms/day_planner.dart';
import '../../core/algorithms/random_poi_selector.dart';
import '../../core/algorithms/route_optimizer.dart';
import '../../core/constants/categories.dart';
import '../models/poi.dart';
import '../models/route.dart';
import '../models/trip.dart';
import '../services/hotel_service.dart';
import 'poi_repo.dart';
import 'routing_repo.dart';
import 'geocoding_repo.dart';

part 'trip_generator_repo.g.dart';

/// Repository für die Generierung von Zufalls-Trips
/// Kombiniert POI-Auswahl, Route-Optimierung und Tagesplanung
class TripGeneratorRepository {
  final POIRepository _poiRepo;
  final RoutingRepository _routingRepo;
  final GeocodingRepository _geocodingRepo;
  final HotelService _hotelService;
  final RandomPOISelector _poiSelector;
  final RouteOptimizer _routeOptimizer;
  final DayPlanner _dayPlanner;
  final Uuid _uuid;

  TripGeneratorRepository({
    POIRepository? poiRepo,
    RoutingRepository? routingRepo,
    GeocodingRepository? geocodingRepo,
    HotelService? hotelService,
    RandomPOISelector? poiSelector,
    RouteOptimizer? routeOptimizer,
    DayPlanner? dayPlanner,
  })  : _poiRepo = poiRepo ?? POIRepository(),
        _routingRepo = routingRepo ?? RoutingRepository(),
        _geocodingRepo = geocodingRepo ?? GeocodingRepository(),
        _hotelService = hotelService ?? HotelService(),
        _poiSelector = poiSelector ?? RandomPOISelector(),
        _routeOptimizer = routeOptimizer ?? RouteOptimizer(),
        _dayPlanner = dayPlanner ?? DayPlanner(),
        _uuid = const Uuid();

  /// Generiert einen Tagesausflug
  ///
  /// [startLocation] - Startpunkt
  /// [startAddress] - Adresse des Startpunkts
  /// [radiusKm] - Suchradius für POIs
  /// [categories] - Bevorzugte Kategorien
  /// [poiCount] - Anzahl gewünschter POIs
  Future<GeneratedTrip> generateDayTrip({
    required LatLng startLocation,
    required String startAddress,
    double radiusKm = 100,
    List<POICategory> categories = const [],
    int poiCount = 5,
  }) async {
    // 1. POIs im Radius laden
    final categoryIds = categories.isNotEmpty
        ? categories.map((c) => c.id).toList()
        : null;

    final availablePOIs = await _poiRepo.loadPOIsInRadius(
      center: startLocation,
      radiusKm: radiusKm,
      categoryFilter: categoryIds,
    );

    if (availablePOIs.isEmpty) {
      throw TripGenerationException(
        'Keine POIs im Umkreis von ${radiusKm}km gefunden',
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
      returnToStart: true,
    );

    // 4. Echte Route berechnen
    final waypoints = optimizedPOIs.map((p) => p.location).toList();
    final route = await _routingRepo.calculateFastRoute(
      start: startLocation,
      end: startLocation,
      waypoints: waypoints,
      startAddress: startAddress,
      endAddress: startAddress,
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
  /// [days] - Anzahl der Reisetage
  /// [categories] - Bevorzugte Kategorien
  /// [includeHotels] - Hotels vorschlagen
  Future<GeneratedTrip> generateEuroTrip({
    required LatLng startLocation,
    required String startAddress,
    required int days,
    List<POICategory> categories = const [],
    bool includeHotels = true,
  }) async {
    // Radius basierend auf Tagen berechnen
    final radiusKm = DayPlanner.calculateRecommendedRadius(days);

    // POIs pro Tag schätzen
    final poisPerDay = DayPlanner.estimatePoisPerDay();
    final totalPOIs = days * poisPerDay;

    // 1. POIs im Radius laden
    final categoryIds = categories.isNotEmpty
        ? categories.map((c) => c.id).toList()
        : null;

    final availablePOIs = await _poiRepo.loadPOIsInRadius(
      center: startLocation,
      radiusKm: radiusKm,
      categoryFilter: categoryIds,
    );

    if (availablePOIs.isEmpty) {
      throw TripGenerationException(
        'Keine POIs im Umkreis von ${radiusKm}km gefunden',
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
      returnToStart: true,
    );

    // 4. Auf Tage aufteilen
    var tripDays = _dayPlanner.planDays(
      pois: optimizedPOIs,
      startLocation: startLocation,
      days: days,
      returnToStart: true,
    );

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

    final route = await _routingRepo.calculateFastRoute(
      start: startLocation,
      end: startLocation,
      waypoints: allWaypoints,
      startAddress: startAddress,
      endAddress: startAddress,
    );

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
