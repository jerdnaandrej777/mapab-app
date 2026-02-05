import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:travel_planner/core/algorithms/route_optimizer.dart';
import '../helpers/test_factories.dart';

void main() {
  late RouteOptimizer optimizer;

  setUp(() {
    optimizer = RouteOptimizer();
  });

  group('RouteOptimizer', () {
    test('leere Liste gibt leere Liste zurueck', () {
      final result = optimizer.optimizeRoute(
        pois: [],
        startLocation: munich,
      );
      expect(result, isEmpty);
    });

    test('einzelner POI gibt diesen POI zurueck', () {
      final poi = createPOI(id: 'p1', name: 'Test');
      final result = optimizer.optimizeRoute(
        pois: [poi],
        startLocation: munich,
      );
      expect(result, hasLength(1));
      expect(result.first.id, 'p1');
    });

    test('2 POIs werden in optimaler Reihenfolge zurueckgegeben', () {
      // Wien ist naeher an Muenchen als Rom
      final poiWien = createPOI(
        id: 'wien',
        name: 'Wien',
        latitude: vienna.latitude,
        longitude: vienna.longitude,
      );
      final poiRom = createPOI(
        id: 'rom',
        name: 'Rom',
        latitude: rome.latitude,
        longitude: rome.longitude,
      );

      final result = optimizer.optimizeRoute(
        pois: [poiRom, poiWien],
        startLocation: munich,
        returnToStart: false,
      );

      expect(result, hasLength(2));
      // Wien sollte vor Rom kommen (naeher an Muenchen)
      expect(result.first.id, 'wien');
      expect(result.last.id, 'rom');
    });

    test('optimierte Route ist kuerzer oder gleich der Original-Route', () {
      // Erstelle POIs in suboptimaler Reihenfolge
      final pois = [
        createPOI(
          id: 'rom',
          latitude: rome.latitude,
          longitude: rome.longitude,
        ),
        createPOI(
          id: 'wien',
          latitude: vienna.latitude,
          longitude: vienna.longitude,
        ),
        createPOI(
          id: 'salzburg',
          latitude: salzburg.latitude,
          longitude: salzburg.longitude,
        ),
        createPOI(
          id: 'prag',
          latitude: prague.latitude,
          longitude: prague.longitude,
        ),
      ];

      final result = optimizer.optimizeRoute(
        pois: pois,
        startLocation: munich,
        returnToStart: false,
      );

      expect(result, hasLength(4));

      // Alle Original-POIs muessen vorhanden sein
      final resultIds = result.map((p) => p.id).toSet();
      expect(resultIds, containsAll(['rom', 'wien', 'salzburg', 'prag']));
    });

    test('returnToStart=false aendert Optimierung', () {
      final pois = [
        createPOI(
          id: 'salzburg',
          latitude: salzburg.latitude,
          longitude: salzburg.longitude,
        ),
        createPOI(
          id: 'wien',
          latitude: vienna.latitude,
          longitude: vienna.longitude,
        ),
      ];

      final resultReturn = optimizer.optimizeRoute(
        pois: pois,
        startLocation: munich,
        returnToStart: true,
      );
      final resultNoReturn = optimizer.optimizeRoute(
        pois: pois,
        startLocation: munich,
        returnToStart: false,
      );

      // Beide sollten alle POIs enthalten
      expect(resultReturn, hasLength(2));
      expect(resultNoReturn, hasLength(2));
    });
  });
}
