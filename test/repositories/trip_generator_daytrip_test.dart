import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:travel_planner/core/constants/categories.dart';
import 'package:travel_planner/data/models/poi.dart';
import 'package:travel_planner/data/models/route.dart';
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
  });
}
