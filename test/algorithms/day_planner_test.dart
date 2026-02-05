import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:travel_planner/core/algorithms/day_planner.dart';
import 'package:travel_planner/core/constants/trip_constants.dart';
import 'package:travel_planner/data/models/trip.dart';
import '../helpers/test_factories.dart';

void main() {
  late DayPlanner planner;

  setUp(() {
    planner = DayPlanner();
  });

  group('DayPlanner.planDays - Grundlagen', () {
    test('leere POIs geben leere Tage', () {
      final result = planner.planDays(
        pois: [],
        startLocation: munich,
        days: 3,
      );
      expect(result, isEmpty);
    });

    test('days <= 0 gibt leere Tage', () {
      final result = planner.planDays(
        pois: [createPOI()],
        startLocation: munich,
        days: 0,
      );
      expect(result, isEmpty);
    });

    test('1 Tag packt alle POIs in einen Tag', () {
      final pois = List.generate(5, (i) => createPOI(id: 'poi-$i'));
      final result = planner.planDays(
        pois: pois,
        startLocation: munich,
        days: 1,
      );

      expect(result.length, 1);
      expect(result[0].stops.length, 5);
      expect(result[0].dayNumber, 1);
    });

    test('1 Tag berechnet Distanz und Dauer', () {
      final result = planner.planDays(
        pois: [
          createPOI(
            id: 'sbg',
            latitude: salzburg.latitude,
            longitude: salzburg.longitude,
          ),
        ],
        startLocation: munich,
        days: 1,
      );

      expect(result[0].distanceKm, greaterThan(0));
      expect(result[0].durationMinutes, greaterThan(0));
    });
  });

  group('DayPlanner.planDays - Multi-Day', () {
    test('erstellt mehrere Tage fuer weit entfernte POIs', () {
      // POIs verteilt von Muenchen bis Rom (>800km)
      final pois = [
        createPOI(id: 'sbg', name: 'Salzburg',
            latitude: salzburg.latitude, longitude: salzburg.longitude),
        createPOI(id: 'vie', name: 'Wien',
            latitude: vienna.latitude, longitude: vienna.longitude),
        createPOI(id: 'zur', name: 'Zuerich',
            latitude: zurich.latitude, longitude: zurich.longitude),
        createPOI(id: 'pra', name: 'Prag',
            latitude: prague.latitude, longitude: prague.longitude),
        createPOI(id: 'ber', name: 'Berlin',
            latitude: berlin.latitude, longitude: berlin.longitude),
        createPOI(id: 'rom', name: 'Rom',
            latitude: rome.latitude, longitude: rome.longitude),
      ];

      final result = planner.planDays(
        pois: pois,
        startLocation: munich,
        days: 3,
      );

      // Mindestens 2 Tage wegen 700km-Limit
      expect(result.length, greaterThanOrEqualTo(2));

      // Alle POIs sind verteilt
      final totalStops = result.fold<int>(0, (sum, d) => sum + d.stops.length);
      expect(totalStops, pois.length);
    });

    test('jeder Tag hat dayNumber', () {
      final pois = List.generate(
        6,
        (i) => createPOI(
          id: 'poi-$i',
          latitude: 48.0 + i * 2.0,
          longitude: 11.0 + i * 1.0,
        ),
      );

      final result = planner.planDays(
        pois: pois,
        startLocation: munich,
        days: 3,
      );

      for (int i = 0; i < result.length; i++) {
        expect(result[i].dayNumber, i + 1);
      }
    });

    test('Stops haben korrekte day-Zuordnung', () {
      final pois = [
        createPOI(id: 'a', latitude: 48.0, longitude: 11.0),
        createPOI(id: 'b', latitude: 50.0, longitude: 13.0),
        createPOI(id: 'c', latitude: 52.0, longitude: 15.0),
        createPOI(id: 'd', latitude: 54.0, longitude: 17.0),
      ];

      final result = planner.planDays(
        pois: pois,
        startLocation: munich,
        days: 2,
      );

      for (final day in result) {
        for (final stop in day.stops) {
          expect(stop.day, day.dayNumber);
        }
      }
    });

    test('maximal 9 POIs pro Tag (Google Maps Limit)', () {
      final pois = List.generate(
        20,
        (i) => createPOI(
          id: 'poi-$i',
          // Nahe beieinander, damit nicht durch Distanz gesplittet wird
          latitude: 48.0 + i * 0.01,
          longitude: 11.0 + i * 0.01,
        ),
      );

      final result = planner.planDays(
        pois: pois,
        startLocation: munich,
        days: 3,
      );

      for (final day in result) {
        expect(day.stops.length, lessThanOrEqualTo(TripConstants.maxPoisPerDay),
            reason: 'Tag ${day.dayNumber} hat ${day.stops.length} Stops, max ${TripConstants.maxPoisPerDay}');
      }
    });

    test('generiert Titel mit Highlight-Name', () {
      final pois = [
        createPOI(id: 'a', name: 'Neuschwanstein', score: 90),
        createPOI(id: 'b', name: 'Kleiner Park', score: 30),
      ];

      final result = planner.planDays(
        pois: pois,
        startLocation: munich,
        days: 1,
      );

      expect(result[0].title, contains('Tag 1'));
    });
  });

  group('DayPlanner.estimatePoisPerDay', () {
    test('Standard: 6h bei 45min Besuch + 30min Fahrt = 4-5 POIs', () {
      final count = DayPlanner.estimatePoisPerDay();
      expect(count, greaterThanOrEqualTo(2));
      expect(count, lessThanOrEqualTo(9));
    });

    test('Minimum ist 2 POIs pro Tag', () {
      final count = DayPlanner.estimatePoisPerDay(
        hoursPerDay: 1,
        avgVisitDurationMinutes: 120,
      );
      expect(count, greaterThanOrEqualTo(TripConstants.minPoisPerDay));
    });

    test('Maximum ist 9 POIs pro Tag', () {
      final count = DayPlanner.estimatePoisPerDay(
        hoursPerDay: 16,
        avgVisitDurationMinutes: 10,
        avgDrivingMinutesBetweenStops: 5,
      );
      expect(count, lessThanOrEqualTo(TripConstants.maxPoisPerDay));
    });
  });

  group('DayPlanner.calculateRecommendedRadius', () {
    test('1 Tag = 600 km', () {
      expect(DayPlanner.calculateRecommendedRadius(1), 600.0);
    });

    test('7 Tage = 4200 km', () {
      expect(DayPlanner.calculateRecommendedRadius(7), 4200.0);
    });

    test('14 Tage = 8400 km', () {
      expect(DayPlanner.calculateRecommendedRadius(14), 8400.0);
    });
  });

  group('DayPlanner.calculateDaysFromRadius', () {
    test('600 km = 1 Tag', () {
      expect(DayPlanner.calculateDaysFromRadius(600), 1);
    });

    test('1200 km = 2 Tage', () {
      expect(DayPlanner.calculateDaysFromRadius(1200), 2);
    });

    test('Minimum ist 1 Tag', () {
      expect(DayPlanner.calculateDaysFromRadius(100), 1);
    });

    test('Maximum ist 14 Tage', () {
      expect(DayPlanner.calculateDaysFromRadius(50000), 14);
    });
  });

  group('DayPlanner.calculateOvernightLocations', () {
    test('gibt Locations fuer alle Tage ausser dem letzten', () {
      final days = [
        TripDay(
          dayNumber: 1,
          title: 'Tag 1',
          stops: [createTripStop(latitude: 48.0, longitude: 12.0)],
        ),
        TripDay(
          dayNumber: 2,
          title: 'Tag 2',
          stops: [createTripStop(latitude: 49.0, longitude: 13.0)],
        ),
        TripDay(
          dayNumber: 3,
          title: 'Tag 3',
          stops: [createTripStop(latitude: 50.0, longitude: 14.0)],
        ),
      ];

      final locations = planner.calculateOvernightLocations(
        tripDays: days,
        startLocation: munich,
      );

      // 3 Tage → 2 Uebernachtungen
      expect(locations.length, 2);
      expect(locations[0].latitude, 48.0);
      expect(locations[1].latitude, 49.0);
    });

    test('leere Stops im Tag 1 nutzt Startlocation', () {
      final days = [
        const TripDay(dayNumber: 1, title: 'Tag 1', stops: []),
        TripDay(
          dayNumber: 2,
          title: 'Tag 2',
          stops: [createTripStop()],
        ),
      ];

      final locations = planner.calculateOvernightLocations(
        tripDays: days,
        startLocation: munich,
      );

      expect(locations.length, 1);
      expect(locations[0].latitude, munich.latitude);
    });
  });

  group('DayPlanner.addOvernightStops', () {
    test('fuegt Hotels zu den richtigen Tagen hinzu', () {
      final days = [
        TripDay(
          dayNumber: 1,
          title: 'Tag 1',
          stops: [createTripStop(poiId: 'stop1')],
        ),
        TripDay(
          dayNumber: 2,
          title: 'Tag 2',
          stops: [createTripStop(poiId: 'stop2')],
        ),
      ];

      final hotels = [
        createTripStop(
          poiId: 'hotel1',
          name: 'Hotel Alpen',
          categoryId: 'hotel',
        ),
      ];

      final result = planner.addOvernightStops(
        tripDays: days,
        hotelStops: hotels,
      );

      // Tag 1 hat originalen Stop + Hotel
      expect(result[0].stops.length, 2);
      expect(result[0].stops.last.isOvernightStop, isTrue);
      expect(result[0].overnightStop, isNotNull);
      expect(result[0].overnightStop!.name, 'Hotel Alpen');

      // Tag 2 hat nur originalen Stop (kein Hotel)
      expect(result[1].stops.length, 1);
      expect(result[1].overnightStop, isNull);
    });

    test('leere Hotels aendert nichts', () {
      final days = [
        const TripDay(dayNumber: 1, title: 'Tag 1'),
      ];

      final result = planner.addOvernightStops(
        tripDays: days,
        hotelStops: [],
      );

      expect(result, days);
    });
  });

  group('DayPlanResult', () {
    test('totalStops zaehlt alle Stops', () {
      final result = DayPlanResult(
        days: [
          TripDay(
            dayNumber: 1,
            title: 'Tag 1',
            stops: [createTripStop(), createTripStop(poiId: 'b')],
          ),
          TripDay(
            dayNumber: 2,
            title: 'Tag 2',
            stops: [createTripStop(poiId: 'c')],
          ),
        ],
        totalDistanceKm: 500,
        totalDurationMinutes: 300,
        overnightLocations: [],
      );

      expect(result.totalStops, 3);
    });

    test('formattedTotalDistance formatiert korrekt', () {
      final result = DayPlanResult(
        days: [],
        totalDistanceKm: 123.456,
        totalDurationMinutes: 0,
        overnightLocations: [],
      );

      expect(result.formattedTotalDistance, '123.5 km');
    });

    test('formattedTotalDuration formatiert korrekt', () {
      expect(
        DayPlanResult(days: [], totalDistanceKm: 0,
            totalDurationMinutes: 150, overnightLocations: [])
            .formattedTotalDuration,
        '2 Std. 30 Min.',
      );
      expect(
        DayPlanResult(days: [], totalDistanceKm: 0,
            totalDurationMinutes: 120, overnightLocations: [])
            .formattedTotalDuration,
        '2 Std.',
      );
    });
  });
}
