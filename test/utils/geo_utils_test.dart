import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:travel_planner/core/utils/geo_utils.dart';
import '../helpers/test_factories.dart';

void main() {
  group('GeoUtils.haversineDistance', () {
    test('gleicher Punkt ergibt 0 km', () {
      final distance = GeoUtils.haversineDistance(munich, munich);
      expect(distance, closeTo(0, 0.001));
    });

    test('Muenchen-Salzburg ca. 115-150 km', () {
      final distance = GeoUtils.haversineDistance(munich, salzburg);
      expect(distance, greaterThan(110));
      expect(distance, lessThan(160));
    });

    test('Muenchen-Berlin ca. 500 km', () {
      final distance = GeoUtils.haversineDistance(munich, berlin);
      expect(distance, greaterThan(450));
      expect(distance, lessThan(550));
    });

    test('Muenchen-Wien ca. 350 km', () {
      final distance = GeoUtils.haversineDistance(munich, vienna);
      expect(distance, greaterThan(300));
      expect(distance, lessThan(400));
    });

    test('Symmetrie: A→B == B→A', () {
      final ab = GeoUtils.haversineDistance(munich, berlin);
      final ba = GeoUtils.haversineDistance(berlin, munich);
      expect(ab, closeTo(ba, 0.001));
    });

    test('Dreiecksungleichung: A→C <= A→B + B→C', () {
      final ab = GeoUtils.haversineDistance(munich, salzburg);
      final bc = GeoUtils.haversineDistance(salzburg, vienna);
      final ac = GeoUtils.haversineDistance(munich, vienna);
      expect(ac, lessThanOrEqualTo(ab + bc + 0.001));
    });
  });

  group('GeoUtils.calculateRouteLength', () {
    test('Routenlaenge bei weniger als 2 Punkten ist 0', () {
      expect(GeoUtils.calculateRouteLength([]), 0);
      expect(GeoUtils.calculateRouteLength([munich]), 0);
    });

    test('Routenlaenge mit 2 Punkten entspricht Haversine-Distanz', () {
      final length = GeoUtils.calculateRouteLength([munich, salzburg]);
      final direct = GeoUtils.haversineDistance(munich, salzburg);
      expect(length, closeTo(direct, 0.001));
    });

    test('Routenlaenge mit Zwischenpunkt ist >= direkte Strecke', () {
      final viaZurich = GeoUtils.calculateRouteLength([munich, zurich, vienna]);
      final direct = GeoUtils.calculateRouteLength([munich, vienna]);
      expect(viaZurich, greaterThan(direct));
    });
  });

  group('GeoUtils.findClosestPointOnRoute', () {
    test('wirft bei leerer Route', () {
      expect(
        () => GeoUtils.findClosestPointOnRoute(munich, []),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Punkt auf der Route hat Distanz nahe 0', () {
      final route = [munich, salzburg, vienna];
      final result = GeoUtils.findClosestPointOnRoute(salzburg, route);
      expect(result.distance, lessThan(1)); // < 1 km
    });

    test('weit entfernter Punkt hat grosse Distanz', () {
      final route = [munich, salzburg];
      final result = GeoUtils.findClosestPointOnRoute(rome, route);
      expect(result.distance, greaterThan(300));
    });

    test('gibt korrekten Segment-Index zurueck', () {
      final route = [munich, salzburg, vienna];
      // Punkt nahe Salzburg → Segment 0 (Munich→Salzburg) oder 1 (Salzburg→Vienna)
      final nearSalzburg =
          const LatLng(47.85, 13.1); // leicht verschoben von Salzburg
      final result = GeoUtils.findClosestPointOnRoute(nearSalzburg, route);
      expect(result.segmentIndex, anyOf(0, 1));
      expect(result.distance, lessThan(10));
    });
  });

  group('GeoUtils.calculateRoutePosition', () {
    test('Startpunkt hat Position 0', () {
      final route = [munich, salzburg, vienna];
      final pos = GeoUtils.calculateRoutePosition(munich, route);
      expect(pos, closeTo(0.0, 0.05));
    });

    test('Endpunkt hat Position nahe 1', () {
      final route = [munich, salzburg, vienna];
      final pos = GeoUtils.calculateRoutePosition(vienna, route);
      expect(pos, closeTo(1.0, 0.05));
    });

    test('Mittelpunkt hat Position um 0.3-0.5', () {
      final route = [munich, salzburg, vienna];
      // Salzburg liegt ca. bei 30-40% der Route
      final pos = GeoUtils.calculateRoutePosition(salzburg, route);
      expect(pos, greaterThan(0.15));
      expect(pos, lessThan(0.60));
    });

    test('Position steigt monoton entlang der Route', () {
      final route = [munich, salzburg, vienna];
      final pos1 = GeoUtils.calculateRoutePosition(munich, route);
      final pos2 = GeoUtils.calculateRoutePosition(salzburg, route);
      final pos3 = GeoUtils.calculateRoutePosition(vienna, route);

      expect(pos2, greaterThan(pos1));
      expect(pos3, greaterThan(pos2));
    });

    test('bei weniger als 2 Koordinaten gibt 0 zurueck', () {
      expect(GeoUtils.calculateRoutePosition(munich, [munich]), 0);
      expect(GeoUtils.calculateRoutePosition(munich, []), 0);
    });
  });

  group('GeoUtils.calculateDetour', () {
    test('Punkt auf Route hat fast keinen Umweg', () {
      final route = [munich, salzburg, vienna];
      final detour = GeoUtils.calculateDetour(salzburg, route);
      expect(detour, lessThan(2)); // < 2 km (2× nahe 0)
    });

    test('weit entfernter Punkt hat grossen Umweg', () {
      final route = [munich, salzburg];
      final detour = GeoUtils.calculateDetour(rome, route);
      // Rom ist ~600km entfernt → Umweg > 1000km (2×)
      expect(detour, greaterThan(600));
    });

    test('Umweg ist immer positiv', () {
      final route = [munich, vienna];
      final detour = GeoUtils.calculateDetour(berlin, route);
      expect(detour, greaterThan(0));
    });
  });

  group('GeoUtils.calculateCentroid', () {
    test('wirft bei leerer Liste', () {
      expect(
        () => GeoUtils.calculateCentroid([]),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('einzelner Punkt gibt sich selbst zurueck', () {
      final centroid = GeoUtils.calculateCentroid([munich]);
      expect(centroid.latitude, munich.latitude);
      expect(centroid.longitude, munich.longitude);
    });

    test('zwei Punkte geben Mittelpunkt', () {
      final centroid = GeoUtils.calculateCentroid([
        const LatLng(48.0, 11.0),
        const LatLng(50.0, 13.0),
      ]);
      expect(centroid.latitude, closeTo(49.0, 0.001));
      expect(centroid.longitude, closeTo(12.0, 0.001));
    });
  });

  group('GeoUtils.calculateBounds', () {
    test('wirft bei leerer Liste', () {
      expect(
        () => GeoUtils.calculateBounds([]),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('einzelner Punkt hat identische SW und NE', () {
      final bounds = GeoUtils.calculateBounds([munich]);
      expect(bounds.southwest.latitude, munich.latitude);
      expect(bounds.northeast.latitude, munich.latitude);
    });

    test('Bounding Box umschliesst alle Punkte', () {
      final points = [munich, salzburg, vienna, berlin];
      final bounds = GeoUtils.calculateBounds(points);

      for (final p in points) {
        expect(p.latitude, greaterThanOrEqualTo(bounds.southwest.latitude));
        expect(p.latitude, lessThanOrEqualTo(bounds.northeast.latitude));
        expect(p.longitude, greaterThanOrEqualTo(bounds.southwest.longitude));
        expect(p.longitude, lessThanOrEqualTo(bounds.northeast.longitude));
      }
    });
  });

  group('GeoUtils.calculateBoundsWithBuffer', () {
    test('Buffer vergroessert die Bounding Box', () {
      final coords = [munich, salzburg];
      final noBuf = GeoUtils.calculateBounds(coords);
      final withBuf = GeoUtils.calculateBoundsWithBuffer(coords, 50);

      expect(withBuf.southwest.latitude, lessThan(noBuf.southwest.latitude));
      expect(withBuf.northeast.latitude, greaterThan(noBuf.northeast.latitude));
      expect(withBuf.southwest.longitude, lessThan(noBuf.southwest.longitude));
      expect(
          withBuf.northeast.longitude, greaterThan(noBuf.northeast.longitude));
    });

    test('wirft bei leeren Koordinaten', () {
      expect(
        () => GeoUtils.calculateBoundsWithBuffer([], 50),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('GeoUtils.expandBounds', () {
    test('Faktor 0 aendert Bounds nicht', () {
      final bounds = GeoUtils.calculateBounds([munich, vienna]);
      final expanded = GeoUtils.expandBounds(bounds, 0);

      expect(expanded.southwest.latitude, bounds.southwest.latitude);
      expect(expanded.northeast.latitude, bounds.northeast.latitude);
    });

    test('positiver Faktor vergroessert Bounds', () {
      final bounds = GeoUtils.calculateBounds([munich, vienna]);
      final expanded = GeoUtils.expandBounds(bounds, 0.5);

      expect(expanded.southwest.latitude, lessThan(bounds.southwest.latitude));
      expect(
          expanded.northeast.latitude, greaterThan(bounds.northeast.latitude));
    });
  });
}
