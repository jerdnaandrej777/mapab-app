import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:travel_planner/core/algorithms/random_poi_selector.dart';
import 'package:travel_planner/core/constants/categories.dart';
import 'package:travel_planner/data/models/poi.dart';
import 'package:travel_planner/data/models/route.dart';
import 'package:travel_planner/data/models/trip.dart';
import 'package:travel_planner/data/repositories/poi_repo.dart';
import 'package:travel_planner/data/repositories/routing_repo.dart';
import 'package:travel_planner/data/repositories/trip_generator_repo.dart';

class _FakePOIRepository extends POIRepository {
  _FakePOIRepository(this._pois);

  final List<POI> _pois;
  int radiusCalls = 0;
  int boundsCalls = 0;

  @override
  Future<List<POI>> loadPOIsInRadius({
    required LatLng center,
    required double radiusKm,
    List<String>? categoryFilter,
    int minScore = minimumPOIScore,
    bool includeCurated = true,
    bool includeWikipedia = true,
    bool includeOverpass = true,
    bool useCache = true,
    bool isFallbackAttempt = false,
  }) async {
    radiusCalls++;
    return _pois;
  }

  @override
  Future<List<POI>> loadPOIsInBounds({
    required ({LatLng southwest, LatLng northeast}) bounds,
    List<String>? categoryFilter,
    int minScore = minimumPOIScore,
    bool includeCurated = true,
    bool includeWikipedia = true,
    bool includeOverpass = true,
    int maxResults = 200,
    bool isFallbackAttempt = false,
  }) async {
    boundsCalls++;
    return _pois;
  }
}

class _SplitPOIRepository extends POIRepository {
  _SplitPOIRepository({
    this.radiusPOIs = const [],
    this.boundsPOIs = const [],
  });

  final List<POI> radiusPOIs;
  final List<POI> boundsPOIs;
  int radiusCalls = 0;
  int boundsCalls = 0;

  @override
  Future<List<POI>> loadPOIsInRadius({
    required LatLng center,
    required double radiusKm,
    List<String>? categoryFilter,
    int minScore = minimumPOIScore,
    bool includeCurated = true,
    bool includeWikipedia = true,
    bool includeOverpass = true,
    bool useCache = true,
    bool isFallbackAttempt = false,
  }) async {
    radiusCalls++;
    return radiusPOIs;
  }

  @override
  Future<List<POI>> loadPOIsInBounds({
    required ({LatLng southwest, LatLng northeast}) bounds,
    List<String>? categoryFilter,
    int minScore = minimumPOIScore,
    bool includeCurated = true,
    bool includeWikipedia = true,
    bool includeOverpass = true,
    int maxResults = 200,
    bool isFallbackAttempt = false,
  }) async {
    boundsCalls++;
    return boundsPOIs;
  }
}

class _SequencedRadiusPOIRepository extends POIRepository {
  _SequencedRadiusPOIRepository(this._radiusResponses);

  final List<List<POI>> _radiusResponses;
  int radiusCalls = 0;

  @override
  Future<List<POI>> loadPOIsInRadius({
    required LatLng center,
    required double radiusKm,
    List<String>? categoryFilter,
    int minScore = minimumPOIScore,
    bool includeCurated = true,
    bool includeWikipedia = true,
    bool includeOverpass = true,
    bool useCache = true,
    bool isFallbackAttempt = false,
  }) async {
    radiusCalls++;
    if (_radiusResponses.isEmpty) return const [];
    final idx = (radiusCalls - 1).clamp(0, _radiusResponses.length - 1);
    return _radiusResponses[idx];
  }

  @override
  Future<List<POI>> loadPOIsInBounds({
    required ({LatLng southwest, LatLng northeast}) bounds,
    List<String>? categoryFilter,
    int minScore = minimumPOIScore,
    bool includeCurated = true,
    bool includeWikipedia = true,
    bool includeOverpass = true,
    int maxResults = 200,
    bool isFallbackAttempt = false,
  }) async {
    return const [];
  }
}

class _FakeRoutingRepository extends RoutingRepository {
  _FakeRoutingRepository({this.failWhenWaypoints = false});

  final bool failWhenWaypoints;

  @override
  Future<AppRoute> calculateFastRoute({
    required LatLng start,
    required LatLng end,
    List<LatLng>? waypoints,
    required String startAddress,
    required String endAddress,
  }) async {
    final points = <LatLng>[start, ...?waypoints, end];
    if (failWhenWaypoints && (waypoints?.isNotEmpty ?? false)) {
      throw RoutingException('HTTP 400 - invalid waypoint set');
    }
    return AppRoute(
      start: start,
      end: end,
      startAddress: startAddress,
      endAddress: endAddress,
      coordinates: points,
      distanceKm: 42,
      durationMinutes: 50,
      type: RouteType.fast,
      waypoints: waypoints ?? const [],
      calculatedAt: DateTime.now(),
    );
  }
}

class _ProgrammableRoutingRepository extends RoutingRepository {
  _ProgrammableRoutingRepository({required this.shouldFail});

  final bool Function(
    List<LatLng> waypoints,
    int callCount,
    LatLng start,
    LatLng end,
  ) shouldFail;
  int callCount = 0;
  LatLng? lastEnd;

  @override
  Future<AppRoute> calculateFastRoute({
    required LatLng start,
    required LatLng end,
    List<LatLng>? waypoints,
    required String startAddress,
    required String endAddress,
  }) async {
    callCount++;
    final effectiveWaypoints = waypoints ?? const <LatLng>[];
    if (shouldFail(effectiveWaypoints, callCount, start, end)) {
      throw RoutingException('HTTP 400 - scripted failure #$callCount');
    }

    lastEnd = end;
    return AppRoute(
      start: start,
      end: end,
      startAddress: startAddress,
      endAddress: endAddress,
      coordinates: [start, ...effectiveWaypoints, end],
      distanceKm: 42,
      durationMinutes: 50,
      type: RouteType.fast,
      waypoints: effectiveWaypoints,
      calculatedAt: DateTime.now(),
    );
  }
}

class _ScriptedPOISelector extends RandomPOISelector {
  _ScriptedPOISelector({
    this.selections = const [],
    this.rerollResult,
  });

  final List<List<POI>> selections;
  final POI? rerollResult;
  int _selectionCall = 0;

  @override
  List<POI> selectRandomPOIs({
    required List<POI> pois,
    required LatLng startLocation,
    required int count,
    List<POICategory> preferredCategories = const [],
    int maxPerCategory = 2,
    double? maxSegmentKm,
    LatLng? tripEndLocation,
    double? remainingTripBudgetKm,
    LatLng? currentAnchorLocation,
    List<LatLng>? progressRouteCoordinates,
  }) {
    if (_selectionCall < selections.length) {
      return selections[_selectionCall++];
    }
    _selectionCall++;
    return super.selectRandomPOIs(
      pois: pois,
      startLocation: startLocation,
      count: count,
      preferredCategories: preferredCategories,
      maxPerCategory: maxPerCategory,
      maxSegmentKm: maxSegmentKm,
      tripEndLocation: tripEndLocation,
      remainingTripBudgetKm: remainingTripBudgetKm,
      currentAnchorLocation: currentAnchorLocation,
      progressRouteCoordinates: progressRouteCoordinates,
    );
  }

  @override
  POI? rerollSinglePOI({
    required List<POI> availablePOIs,
    required List<POI> currentSelection,
    required POI poiToReplace,
    required LatLng startLocation,
    List<POICategory> preferredCategories = const [],
    LatLng? previousLocation,
    LatLng? nextLocation,
    double? maxSegmentKm,
  }) {
    return rerollResult ??
        super.rerollSinglePOI(
          availablePOIs: availablePOIs,
          currentSelection: currentSelection,
          poiToReplace: poiToReplace,
          startLocation: startLocation,
          preferredCategories: preferredCategories,
          previousLocation: previousLocation,
          nextLocation: nextLocation,
          maxSegmentKm: maxSegmentKm,
        );
  }
}

class _CapturingPOISelector extends RandomPOISelector {
  _CapturingPOISelector();

  int? lastMaxPerCategory;

  @override
  List<POI> selectRandomPOIs({
    required List<POI> pois,
    required LatLng startLocation,
    required int count,
    List<POICategory> preferredCategories = const [],
    int maxPerCategory = 2,
    double? maxSegmentKm,
    LatLng? tripEndLocation,
    double? remainingTripBudgetKm,
    LatLng? currentAnchorLocation,
    List<LatLng>? progressRouteCoordinates,
  }) {
    lastMaxPerCategory = maxPerCategory;
    return super.selectRandomPOIs(
      pois: pois,
      startLocation: startLocation,
      count: count,
      preferredCategories: preferredCategories,
      maxPerCategory: maxPerCategory,
      maxSegmentKm: maxSegmentKm,
      tripEndLocation: tripEndLocation,
      remainingTripBudgetKm: remainingTripBudgetKm,
      currentAnchorLocation: currentAnchorLocation,
      progressRouteCoordinates: progressRouteCoordinates,
    );
  }
}

POI _buildPOI(
  String id,
  double lat,
  double lng, {
  int score = 80,
  POICategory category = POICategory.attraction,
}) {
  return POI(
    id: id,
    name: 'POI $id',
    latitude: lat,
    longitude: lng,
    categoryId: category.id,
    score: score,
  );
}

bool _hasCoordinate(
  List<LatLng> points,
  LatLng target, {
  double thresholdKm = 0.1,
}) {
  return points.any(
    (point) =>
        const Distance().as(LengthUnit.Kilometer, point, target) <= thresholdKm,
  );
}

GeneratedTrip _buildSingleDayGeneratedTrip({
  required LatLng start,
  required LatLng destination,
  required List<POI> selectedPOIs,
  List<POI>? availablePOIs,
}) {
  final route = AppRoute(
    start: start,
    end: destination,
    startAddress: 'Start',
    endAddress: 'Destination',
    coordinates: [start, ...selectedPOIs.map((p) => p.location), destination],
    distanceKm: 30,
    durationMinutes: 45,
    type: RouteType.fast,
    waypoints: selectedPOIs.map((p) => p.location).toList(),
    calculatedAt: DateTime.now(),
  );
  final trip = Trip(
    id: 'single-day-trip',
    name: 'Single Day',
    type: TripType.daytrip,
    route: route,
    stops: selectedPOIs.asMap().entries.map((entry) {
      return TripStop.fromPOI(entry.value).copyWith(order: entry.key);
    }).toList(),
    days: 1,
    createdAt: DateTime.now(),
  );
  return GeneratedTrip(
    trip: trip,
    availablePOIs: availablePOIs ?? selectedPOIs,
    selectedPOIs: selectedPOIs,
  );
}

void main() {
  group('TripGeneratorRepository daytrip stabilization', () {
    const start = LatLng(50.9375, 6.9603);
    const nearDestination = LatLng(50.9380, 6.9609); // << 3 km
    final samplePOI = POI(
      id: 'poi-1',
      name: 'Sample POI',
      latitude: 50.94,
      longitude: 6.97,
      categoryId: POICategory.attraction.id,
      score: 80,
    );

    test('uses roundtrip mode when destination is too close', () async {
      final poiRepo = _FakePOIRepository([samplePOI]);
      final routingRepo = _FakeRoutingRepository();
      final repo = TripGeneratorRepository(
        poiRepo: poiRepo,
        routingRepo: routingRepo,
      );

      final result = await repo.generateDayTrip(
        startLocation: start,
        startAddress: 'Koeln',
        destinationLocation: nearDestination,
        destinationAddress: 'Koeln Zentrum',
        radiusKm: 100,
        poiCount: 1,
      );

      expect(poiRepo.radiusCalls, greaterThan(0));
      expect(result.trip.route.end.latitude, closeTo(start.latitude, 0.00001));
      expect(
          result.trip.route.end.longitude, closeTo(start.longitude, 0.00001));
    });

    test('wraps routing failures into TripGenerationException', () async {
      final poiRepo = _FakePOIRepository([
        samplePOI,
        samplePOI.copyWith(
          id: 'poi-2',
          latitude: 50.98,
          longitude: 7.08,
          score: 70,
        ),
      ]);
      final routingRepo = _FakeRoutingRepository(failWhenWaypoints: true);
      final repo = TripGeneratorRepository(
        poiRepo: poiRepo,
        routingRepo: routingRepo,
      );

      expect(
        () => repo.generateDayTrip(
          startLocation: start,
          startAddress: 'Koeln',
          radiusKm: 120,
          poiCount: 2,
        ),
        throwsA(
          isA<TripGenerationException>().having(
            (e) => e.message,
            'message',
            contains(
                'Route konnte fuer die ausgewaehlten POIs nicht berechnet werden'),
          ),
        ),
      );
    });

    test('falls back to endpoint-radius POIs when corridor bounds are empty',
        () async {
      const destination = LatLng(51.0500, 7.1500);
      final poiRepo = _SplitPOIRepository(
        boundsPOIs: const [],
        radiusPOIs: [samplePOI],
      );
      final routingRepo = _FakeRoutingRepository();
      final repo = TripGeneratorRepository(
        poiRepo: poiRepo,
        routingRepo: routingRepo,
      );

      final result = await repo.generateDayTrip(
        startLocation: start,
        startAddress: 'Koeln',
        destinationLocation: destination,
        destinationAddress: 'Bergisch Gladbach',
        radiusKm: 120,
        poiCount: 1,
      );

      expect(poiRepo.boundsCalls, greaterThan(0));
      expect(poiRepo.radiusCalls, greaterThanOrEqualTo(2));
      expect(result.selectedPOIs, isNotEmpty);
      expect(result.trip.route.coordinates, isNotEmpty);
    });

    test(
        'continues fallback attempts when first POI batch is too small and merges candidates',
        () async {
      final firstSmallBatch = <POI>[
        _buildPOI('small-1', 50.9400, 6.9700, category: POICategory.castle),
      ];
      final secondLargerBatch = <POI>[
        _buildPOI('large-1', 50.9420, 6.9720, category: POICategory.castle),
        _buildPOI('large-2', 50.9440, 6.9740, category: POICategory.castle),
        _buildPOI('large-3', 50.9460, 6.9760, category: POICategory.castle),
        _buildPOI('large-4', 50.9480, 6.9780, category: POICategory.castle),
        _buildPOI('large-5', 50.9500, 6.9800, category: POICategory.castle),
      ];
      final poiRepo = _SequencedRadiusPOIRepository([
        firstSmallBatch,
        secondLargerBatch,
      ]);
      final routingRepo = _FakeRoutingRepository();
      final selector = _CapturingPOISelector();
      final repo = TripGeneratorRepository(
        poiRepo: poiRepo,
        routingRepo: routingRepo,
        poiSelector: selector,
      );

      final result = await repo.generateDayTrip(
        startLocation: start,
        startAddress: 'Koeln',
        radiusKm: 120,
        poiCount: 5,
        categories: const [POICategory.castle],
      );

      expect(poiRepo.radiusCalls, greaterThan(1));
      expect(result.availablePOIs.length, greaterThan(firstSmallBatch.length));
      expect(result.selectedPOIs.length, greaterThanOrEqualTo(2));
    });

    test(
        'uses dynamic maxPerCategory for daytrip selection with narrow categories',
        () async {
      final sameCategoryPool = List<POI>.generate(
        8,
        (index) => _buildPOI(
          'castle-$index',
          50.94 + (index * 0.002),
          6.97 + (index * 0.002),
          category: POICategory.castle,
          score: 90 - index,
        ),
      );
      final selector = _CapturingPOISelector();
      final repo = TripGeneratorRepository(
        poiRepo: _FakePOIRepository(sameCategoryPool),
        routingRepo: _FakeRoutingRepository(),
        poiSelector: selector,
      );

      await repo.generateDayTrip(
        startLocation: start,
        startAddress: 'Koeln',
        radiusKm: 150,
        poiCount: 6,
        categories: const [POICategory.castle],
      );

      expect(selector.lastMaxPerCategory, isNotNull);
      expect(selector.lastMaxPerCategory, greaterThan(2));
    });

    test('does not enforce radius hard-limit when destination is set',
        () async {
      const farDestination = LatLng(48.1351, 11.5820); // Muenchen
      final poiRepo = _FakePOIRepository([samplePOI]);
      final routingRepo = _FakeRoutingRepository();
      final repo = TripGeneratorRepository(
        poiRepo: poiRepo,
        routingRepo: routingRepo,
      );

      final result = await repo.generateDayTrip(
        startLocation: start,
        startAddress: 'Koeln',
        destinationLocation: farDestination,
        destinationAddress: 'Muenchen',
        radiusKm: 80,
        poiCount: 1,
      );

      expect(result.selectedPOIs, isNotEmpty);
      expect(
        result.trip.route.end.latitude,
        closeTo(farDestination.latitude, 0.00001),
      );
      expect(
        result.trip.route.end.longitude,
        closeTo(farDestination.longitude, 0.00001),
      );
    });

    test('retries daytrip generation when first selection remains unroutable',
        () async {
      final blockedPoi = _buildPOI('blocked', 50.9800, 7.2000, score: 30);
      final stablePoi = _buildPOI('stable', 50.9400, 6.9700, score: 95);
      final backupPoi = _buildPOI('backup', 50.9450, 6.9750, score: 90);
      final poiRepo = _FakePOIRepository([blockedPoi, stablePoi, backupPoi]);

      final routingRepo = _ProgrammableRoutingRepository(
        // Erste 4 Routing-Aufrufe scheitern komplett -> erster Versuch bricht.
        shouldFail: (_, callCount, __, ___) => callCount <= 4,
      );
      final selector = _ScriptedPOISelector(
        selections: [
          [blockedPoi], // Versuch A
        ],
      );
      final repo = TripGeneratorRepository(
        poiRepo: poiRepo,
        routingRepo: routingRepo,
        poiSelector: selector,
      );

      final result = await repo.generateDayTrip(
        startLocation: start,
        startAddress: 'Koeln',
        radiusKm: 120,
        poiCount: 1,
      );

      expect(routingRepo.callCount, greaterThanOrEqualTo(5));
      expect(result.selectedPOIs, isNotEmpty);
      expect(result.trip.route.coordinates, isNotEmpty);
    });

    test('single-POI rescue can recover from extended available pool',
        () async {
      final blockedA = _buildPOI('blocked-a', 50.9800, 7.1800);
      final blockedB = _buildPOI('blocked-b', 50.9900, 7.2200);
      final rescue = _buildPOI('rescue', 50.9420, 6.9750, score: 98);
      final poiRepo = _FakePOIRepository([blockedA, blockedB, rescue]);

      final routingRepo = _ProgrammableRoutingRepository(
        shouldFail: (waypoints, _, __, ___) =>
            _hasCoordinate(waypoints, blockedA.location) ||
            _hasCoordinate(waypoints, blockedB.location),
      );
      final selector = _ScriptedPOISelector(
        selections: [
          [blockedA, blockedB],
        ],
      );
      final repo = TripGeneratorRepository(
        poiRepo: poiRepo,
        routingRepo: routingRepo,
        poiSelector: selector,
      );

      final result = await repo.generateDayTrip(
        startLocation: start,
        startAddress: 'Koeln',
        radiusKm: 150,
        poiCount: 2,
      );

      expect(result.selectedPOIs.length, 1);
      expect(result.selectedPOIs.first.id, rescue.id);
    });

    test('dedupes semantically identical POIs with different ids', () async {
      final dupA = POI(
        id: 'altstadt-a',
        name: 'Luebecker Altstadt',
        latitude: 50.9400,
        longitude: 6.9700,
        categoryId: POICategory.unesco.id,
        score: 78,
      );
      final dupB = POI(
        id: 'altstadt-b',
        name: 'Altstadt Luebeck',
        latitude: 50.9401,
        longitude: 6.9701,
        categoryId: POICategory.unesco.id,
        score: 82,
      );
      final other = _buildPOI('other', 50.9520, 7.0050, score: 75);

      final selector = _ScriptedPOISelector(
        selections: [
          [dupA, dupB, other],
        ],
      );
      final repo = TripGeneratorRepository(
        poiRepo: _FakePOIRepository([dupA, dupB, other]),
        routingRepo: _FakeRoutingRepository(),
        poiSelector: selector,
      );

      final result = await repo.generateDayTrip(
        startLocation: start,
        startAddress: 'Koeln',
        radiusKm: 150,
        poiCount: 3,
      );

      final altstadtStops = result.selectedPOIs
          .where((poi) => poi.name.toLowerCase().contains('altstadt'))
          .toList();
      expect(altstadtStops.length, 1);
      expect(
        result.selectedPOIs.map((poi) => poi.id).toSet().length,
        result.selectedPOIs.length,
      );
    });

    test('keeps destination endpoint in single-day removePOI', () async {
      const destination = LatLng(50.9950, 7.1200);
      final p1 = _buildPOI('p1', 50.9450, 6.9800);
      final p2 = _buildPOI('p2', 50.9550, 7.0100);
      final p3 = _buildPOI('p3', 50.9700, 7.0600);
      final currentTrip = _buildSingleDayGeneratedTrip(
        start: start,
        destination: destination,
        selectedPOIs: [p1, p2, p3],
      );
      final routingRepo = _ProgrammableRoutingRepository(
          shouldFail: (_, __, ___, ____) => false);
      final repo = TripGeneratorRepository(
        poiRepo: _FakePOIRepository([p1, p2, p3]),
        routingRepo: routingRepo,
      );

      final result = await repo.removePOI(
        currentTrip: currentTrip,
        poiIdToRemove: p2.id,
        startLocation: start,
        startAddress: 'Koeln',
      );

      expect(result.trip.route.end.latitude,
          closeTo(destination.latitude, 0.00001));
      expect(result.trip.route.end.longitude,
          closeTo(destination.longitude, 0.00001));
      expect(routingRepo.lastEnd, isNotNull);
      expect(routingRepo.lastEnd!.latitude,
          closeTo(destination.latitude, 0.00001));
    });

    test('keeps destination endpoint in single-day addPOIToTrip', () async {
      const destination = LatLng(50.9950, 7.1200);
      final p1 = _buildPOI('p1', 50.9450, 6.9800);
      final p2 = _buildPOI('p2', 50.9550, 7.0100);
      final p3 = _buildPOI('p3', 50.9700, 7.0600);
      final currentTrip = _buildSingleDayGeneratedTrip(
        start: start,
        destination: destination,
        selectedPOIs: [p1, p2],
        availablePOIs: [p1, p2, p3],
      );
      final routingRepo = _ProgrammableRoutingRepository(
          shouldFail: (_, __, ___, ____) => false);
      final repo = TripGeneratorRepository(
        poiRepo: _FakePOIRepository([p1, p2, p3]),
        routingRepo: routingRepo,
      );

      final result = await repo.addPOIToTrip(
        currentTrip: currentTrip,
        newPOI: p3,
        targetDay: 1,
        startLocation: start,
        startAddress: 'Koeln',
      );

      expect(result.trip.route.end.latitude,
          closeTo(destination.latitude, 0.00001));
      expect(result.trip.route.end.longitude,
          closeTo(destination.longitude, 0.00001));
      expect(routingRepo.lastEnd!.longitude,
          closeTo(destination.longitude, 0.00001));
    });

    test('keeps destination endpoint in single-day rerollPOI', () async {
      const destination = LatLng(50.9950, 7.1200);
      final p1 = _buildPOI('p1', 50.9450, 6.9800);
      final p2 = _buildPOI('p2', 50.9550, 7.0100);
      final p3 = _buildPOI('p3', 50.9700, 7.0600);
      final replacement = _buildPOI('replacement', 50.9650, 7.0400, score: 99);
      final currentTrip = _buildSingleDayGeneratedTrip(
        start: start,
        destination: destination,
        selectedPOIs: [p1, p2, p3],
        availablePOIs: [p1, p2, p3, replacement],
      );
      final routingRepo = _ProgrammableRoutingRepository(
          shouldFail: (_, __, ___, ____) => false);
      final selector = _ScriptedPOISelector(rerollResult: replacement);
      final repo = TripGeneratorRepository(
        poiRepo: _FakePOIRepository([p1, p2, p3, replacement]),
        routingRepo: routingRepo,
        poiSelector: selector,
      );

      final result = await repo.rerollPOI(
        currentTrip: currentTrip,
        poiIdToReroll: p2.id,
        startLocation: start,
        startAddress: 'Koeln',
      );

      expect(result.trip.route.end.latitude,
          closeTo(destination.latitude, 0.00001));
      expect(result.trip.route.end.longitude,
          closeTo(destination.longitude, 0.00001));
      expect(
          result.selectedPOIs.any((poi) => poi.id == replacement.id), isTrue);
    });
  });
}
