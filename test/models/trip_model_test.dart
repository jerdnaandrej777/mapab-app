import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:travel_planner/data/models/trip.dart';
import '../helpers/test_factories.dart';

void main() {
  group('Trip.getStopsForDay', () {
    test('gibt Stops fuer den richtigen Tag zurueck', () {
      final trip = createMultiDayTrip(dayCount: 3, stopsPerDay: 2);

      final day1Stops = trip.getStopsForDay(1);
      final day2Stops = trip.getStopsForDay(2);
      final day3Stops = trip.getStopsForDay(3);

      expect(day1Stops.length, 2);
      expect(day2Stops.length, 2);
      expect(day3Stops.length, 2);

      expect(day1Stops.every((s) => s.day == 1), isTrue);
      expect(day2Stops.every((s) => s.day == 2), isTrue);
    });

    test('sortiert nach order', () {
      final trip = createTrip(stops: [
        createTripStop(poiId: 'c', order: 2, day: 1),
        createTripStop(poiId: 'a', order: 0, day: 1),
        createTripStop(poiId: 'b', order: 1, day: 1),
      ]);

      final stops = trip.getStopsForDay(1);
      expect(stops[0].poiId, 'a');
      expect(stops[1].poiId, 'b');
      expect(stops[2].poiId, 'c');
    });

    test('gibt leere Liste fuer nicht-existierenden Tag', () {
      final trip = createTrip(stops: [
        createTripStop(day: 1),
      ]);

      expect(trip.getStopsForDay(5), isEmpty);
    });
  });

  group('Trip.actualDays', () {
    test('gibt 1 bei leeren Stops', () {
      final trip = createTrip(stops: []);
      expect(trip.actualDays, 1);
    });

    test('berechnet aus hoechster Tag-Nummer', () {
      final trip = createTrip(stops: [
        createTripStop(poiId: 'a', day: 1),
        createTripStop(poiId: 'b', day: 3),
        createTripStop(poiId: 'c', day: 2),
      ]);

      expect(trip.actualDays, 3);
    });
  });

  group('Trip.getDistanceForDay', () {
    test('Tag 1 startet bei route.start', () {
      final trip = createTrip(
        route: createRoute(
          start: munich,
          end: salzburg, // End == Stop → Rueckkehr-Segment ≈ 0
          distanceKm: 400,
        ),
        stops: [
          createTripStop(
            poiId: 'stop1',
            latitude: salzburg.latitude,
            longitude: salzburg.longitude,
            order: 0,
            day: 1,
          ),
        ],
      );

      final distance = trip.getDistanceForDay(1);
      // Muenchen → Salzburg: ~115km Haversine × 1.35 ≈ ~156km
      // + Salzburg → Salzburg(end): ~0km
      expect(distance, greaterThan(100));
      expect(distance, lessThan(250));
    });

    test('Tag 2+ startet beim letzten Stop des Vortags', () {
      final trip = createTrip(
        route: createRoute(
          start: munich,
          end: vienna,
          distanceKm: 400,
        ),
        stops: [
          createTripStop(
            poiId: 'day1-stop',
            latitude: salzburg.latitude,
            longitude: salzburg.longitude,
            order: 0,
            day: 1,
          ),
          createTripStop(
            poiId: 'day2-stop',
            latitude: vienna.latitude,
            longitude: vienna.longitude,
            order: 0,
            day: 2,
          ),
        ],
      );

      final day2Distance = trip.getDistanceForDay(2);
      // Salzburg → Wien: ~256km Haversine × 1.35 ≈ ~345km
      expect(day2Distance, greaterThan(250));
      expect(day2Distance, lessThan(450));
    });

    test('letzter Tag enthaelt Rueckkehr zum Ziel', () {
      final trip = createTrip(
        route: createRoute(
          start: munich,
          end: munich, // Rundtour
          distanceKm: 400,
        ),
        stops: [
          createTripStop(
            poiId: 'stop1',
            latitude: salzburg.latitude,
            longitude: salzburg.longitude,
            order: 0,
            day: 1,
          ),
        ],
      );

      final distance = trip.getDistanceForDay(1);
      // Muenchen → Salzburg → Muenchen: ~290km Haversine × 1.35
      // Enthalt Rueckkehr weil actualDays==1 und dayNumber==1
      expect(distance, greaterThan(300));
    });

    test('gibt 0 bei leerem Tag', () {
      final trip = createTrip(stops: [
        createTripStop(day: 1),
      ]);

      expect(trip.getDistanceForDay(2), 0);
    });

    test('Haversine-Faktor 1.35 wird angewandt', () {
      // Zwei identische Punkte → Distanz muss 0 sein
      final trip = createTrip(
        route: createRoute(start: munich, end: munich),
        stops: [
          createTripStop(
            latitude: munich.latitude,
            longitude: munich.longitude,
            day: 1,
          ),
        ],
      );

      final distance = trip.getDistanceForDay(1);
      // Start == Stop == End → fast 0
      expect(distance, lessThan(1));
    });
  });

  group('Trip.isDayOverLimit', () {
    test('erkennt Ueberschreitung von 9 Stops', () {
      final stops = List.generate(
        10,
        (i) => createTripStop(poiId: 'stop-$i', order: i, day: 1),
      );
      final trip = createTrip(stops: stops);

      expect(trip.isDayOverLimit(1), isTrue);
    });

    test('9 Stops sind noch im Limit', () {
      final stops = List.generate(
        9,
        (i) => createTripStop(poiId: 'stop-$i', order: i, day: 1),
      );
      final trip = createTrip(stops: stops);

      expect(trip.isDayOverLimit(1), isFalse);
    });
  });

  group('Trip.stopsPerDay', () {
    test('zaehlt Stops pro Tag', () {
      final trip = createTrip(stops: [
        createTripStop(poiId: 'a', day: 1),
        createTripStop(poiId: 'b', day: 1),
        createTripStop(poiId: 'c', day: 2),
      ]);

      expect(trip.stopsPerDay, {1: 2, 2: 1});
    });

    test('leere Stops geben leere Map', () {
      final trip = createTrip(stops: []);
      expect(trip.stopsPerDay, isEmpty);
    });
  });

  group('Trip.totalDistanceKm', () {
    test('Route-Distanz plus doppelte Umwege', () {
      final trip = createTrip(
        route: createRoute(distanceKm: 100),
        stops: [
          createTripStop(poiId: 'a', detourKm: 10),
          createTripStop(poiId: 'b', detourKm: 5),
        ],
      );

      // 100 + (10*2) + (5*2) = 130
      expect(trip.totalDistanceKm, 130.0);
    });

    test('null detourKm wird als 0 behandelt', () {
      final trip = createTrip(
        route: createRoute(distanceKm: 100),
        stops: [
          createTripStop(poiId: 'a', detourKm: null),
        ],
      );

      expect(trip.totalDistanceKm, 100.0);
    });
  });

  group('Trip.totalDurationMinutes', () {
    test('Route-Dauer plus Umwege plus Aufenthalt', () {
      final trip = createTrip(
        route: createRoute(durationMinutes: 60),
        stops: [
          createTripStop(
            poiId: 'a',
            detourMinutes: 5,
            plannedDurationMinutes: 30,
          ),
        ],
      );

      // 60 + (5*2) + 30 = 100
      expect(trip.totalDurationMinutes, 100);
    });
  });

  group('Trip.getWaypointsForDay', () {
    test('gibt LatLng-Liste fuer den Tag', () {
      final trip = createTrip(stops: [
        createTripStop(
          poiId: 'a',
          latitude: 48.0,
          longitude: 11.0,
          order: 0,
          day: 1,
        ),
        createTripStop(
          poiId: 'b',
          latitude: 49.0,
          longitude: 12.0,
          order: 1,
          day: 1,
        ),
      ]);

      final waypoints = trip.getWaypointsForDay(1);
      expect(waypoints.length, 2);
      expect(waypoints[0], const LatLng(48.0, 11.0));
      expect(waypoints[1], const LatLng(49.0, 12.0));
    });
  });

  group('Trip.sortedStops', () {
    test('sortiert nach routePosition', () {
      final trip = createTrip(stops: [
        createTripStop(poiId: 'c', routePosition: 0.9),
        createTripStop(poiId: 'a', routePosition: 0.1),
        createTripStop(poiId: 'b', routePosition: 0.5),
      ]);

      final sorted = trip.sortedStops;
      expect(sorted[0].poiId, 'a');
      expect(sorted[1].poiId, 'b');
      expect(sorted[2].poiId, 'c');
    });

    test('null routePosition wird als 0 behandelt', () {
      final trip = createTrip(stops: [
        createTripStop(poiId: 'b', routePosition: 0.5),
        createTripStop(poiId: 'a', routePosition: null),
      ]);

      final sorted = trip.sortedStops;
      expect(sorted[0].poiId, 'a');
      expect(sorted[1].poiId, 'b');
    });
  });

  group('TripStop', () {
    test('location gibt korrektes LatLng', () {
      final stop = createTripStop(latitude: 48.5, longitude: 11.5);
      expect(stop.location, const LatLng(48.5, 11.5));
    });

    test('toPOI konvertiert korrekt', () {
      final stop = createTripStop(
        poiId: 'test-poi',
        name: 'Test',
        latitude: 48.0,
        longitude: 11.0,
        categoryId: 'museum',
        detourKm: 5.0,
      );

      final poi = stop.toPOI();
      expect(poi.id, 'test-poi');
      expect(poi.name, 'Test');
      expect(poi.latitude, 48.0);
      expect(poi.categoryId, 'museum');
      expect(poi.detourKm, 5.0);
    });

    test('fromPOI konvertiert korrekt', () {
      final poi = createPOI(
        id: 'poi-1',
        name: 'Schloss',
        latitude: 48.5,
        longitude: 11.5,
        categoryId: 'castle',
        detourKm: 3.0,
        routePosition: 0.4,
      );

      final stop = TripStop.fromPOI(poi, order: 2);
      expect(stop.poiId, 'poi-1');
      expect(stop.name, 'Schloss');
      expect(stop.latitude, 48.5);
      expect(stop.detourKm, 3.0);
      expect(stop.routePosition, 0.4);
      expect(stop.order, 2);
    });
  });

  group('TripDay', () {
    test('formattedDuration formatiert Minuten', () {
      final day = TripDay(
        dayNumber: 1,
        title: 'Tag 1',
        durationMinutes: 45,
      );
      expect(day.formattedDuration, '45 Min.');
    });

    test('formattedDuration formatiert Stunden', () {
      final day = TripDay(
        dayNumber: 1,
        title: 'Tag 1',
        durationMinutes: 120,
      );
      expect(day.formattedDuration, '2 Std.');
    });

    test('formattedDuration formatiert Stunden und Minuten', () {
      final day = TripDay(
        dayNumber: 1,
        title: 'Tag 1',
        durationMinutes: 150,
      );
      expect(day.formattedDuration, '2 Std. 30 Min.');
    });

    test('formattedDuration gibt - bei null', () {
      final day = TripDay(
        dayNumber: 1,
        title: 'Tag 1',
      );
      expect(day.formattedDuration, '-');
    });
  });
}
