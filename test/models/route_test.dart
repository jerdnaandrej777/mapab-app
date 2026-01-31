import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:travel_planner/data/models/route.dart';

void main() {
  AppRoute createRoute({
    double distanceKm = 100,
    int durationMinutes = 60,
  }) {
    return AppRoute(
      start: const LatLng(48.1351, 11.5820),
      end: const LatLng(52.5200, 13.4050),
      startAddress: 'München',
      endAddress: 'Berlin',
      coordinates: const [
        LatLng(48.1351, 11.5820),
        LatLng(50.0, 12.0),
        LatLng(52.5200, 13.4050),
      ],
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
    );
  }

  group('AppRoute - formattedDistance', () {
    test('Zeigt Meter bei weniger als 1 km', () {
      final route = createRoute(distanceKm: 0.5);
      expect(route.formattedDistance, '500 m');
    });

    test('Zeigt km bei mehr als 1 km', () {
      final route = createRoute(distanceKm: 100);
      expect(route.formattedDistance, '100.0 km');
    });

    test('Zeigt eine Dezimalstelle', () {
      final route = createRoute(distanceKm: 42.7);
      expect(route.formattedDistance, '42.7 km');
    });
  });

  group('AppRoute - formattedDuration', () {
    test('Zeigt nur Minuten bei weniger als 1 Stunde', () {
      final route = createRoute(durationMinutes: 45);
      expect(route.formattedDuration, '45 Min.');
    });

    test('Zeigt Stunden und Minuten', () {
      final route = createRoute(durationMinutes: 90);
      expect(route.formattedDuration, '1 Std. 30 Min.');
    });

    test('Zeigt nur Stunden wenn Minuten 0', () {
      final route = createRoute(durationMinutes: 120);
      expect(route.formattedDuration, '2 Std.');
    });

    test('Große Dauern korrekt', () {
      final route = createRoute(durationMinutes: 375);
      expect(route.formattedDuration, '6 Std. 15 Min.');
    });
  });

  group('AppRoute - Properties', () {
    test('hasWaypoints erkennt leere Waypoints', () {
      final route = createRoute();
      expect(route.waypoints, isEmpty);
    });

    test('Start und End korrekt', () {
      final route = createRoute();
      expect(route.start.latitude, 48.1351);
      expect(route.end.latitude, 52.5200);
    });

    test('Adressen korrekt', () {
      final route = createRoute();
      expect(route.startAddress, 'München');
      expect(route.endAddress, 'Berlin');
    });
  });

  group('LatLngConverter', () {
    const converter = LatLngConverter();

    test('fromJson konvertiert korrekt', () {
      final latLng = converter.fromJson({'lat': 48.1351, 'lng': 11.5820});
      expect(latLng.latitude, 48.1351);
      expect(latLng.longitude, 11.5820);
    });

    test('toJson konvertiert korrekt', () {
      final json = converter.toJson(const LatLng(48.1351, 11.5820));
      expect(json['lat'], 48.1351);
      expect(json['lng'], 11.5820);
    });

    test('Roundtrip ist korrekt', () {
      const original = LatLng(48.1351, 11.5820);
      final json = converter.toJson(original);
      final restored = converter.fromJson(json);
      expect(restored.latitude, original.latitude);
      expect(restored.longitude, original.longitude);
    });
  });

  group('LatLngListConverter', () {
    const converter = LatLngListConverter();

    test('fromJson konvertiert Liste korrekt', () {
      final list = converter.fromJson([
        {'lat': 48.0, 'lng': 11.0},
        {'lat': 52.0, 'lng': 13.0},
      ]);
      expect(list.length, 2);
      expect(list[0].latitude, 48.0);
      expect(list[1].latitude, 52.0);
    });

    test('Leere Liste wird korrekt konvertiert', () {
      final list = converter.fromJson([]);
      expect(list, isEmpty);
    });

    test('Roundtrip ist korrekt', () {
      final original = [
        const LatLng(48.1351, 11.5820),
        const LatLng(52.5200, 13.4050),
      ];
      final json = converter.toJson(original);
      final restored = converter.fromJson(json);
      expect(restored.length, original.length);
      expect(restored[0].latitude, original[0].latitude);
      expect(restored[1].longitude, original[1].longitude);
    });
  });
}
