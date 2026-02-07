import 'package:flutter_test/flutter_test.dart';
import 'package:travel_planner/core/constants/trip_constants.dart';

void main() {
  group('TripConstants', () {
    test('maxPoisPerDay ist 9 (Google Maps Limit)', () {
      expect(TripConstants.maxPoisPerDay, 9);
    });

    test('kmPerDay ist 600', () {
      expect(TripConstants.kmPerDay, 600.0);
    });
  });

  group('TripConstants - calculateDaysFromDistance', () {
    test('600 km = 1 Tag', () {
      expect(TripConstants.calculateDaysFromDistance(600), 1);
    });

    test('601 km = 2 Tage', () {
      expect(TripConstants.calculateDaysFromDistance(601), 2);
    });

    test('1800 km = 3 Tage', () {
      expect(TripConstants.calculateDaysFromDistance(1800), 3);
    });

    test('Minimaler Wert ist 1 Tag', () {
      expect(TripConstants.calculateDaysFromDistance(10), 1);
    });

    test('Maximaler Wert ist 14 Tage', () {
      expect(TripConstants.calculateDaysFromDistance(100000), 14);
    });
  });

  group('TripConstants - calculateRadiusFromDays', () {
    test('1 Tag = 600 km', () {
      expect(TripConstants.calculateRadiusFromDays(1), 600.0);
    });

    test('3 Tage = 1800 km', () {
      expect(TripConstants.calculateRadiusFromDays(3), 1800.0);
    });

    test('7 Tage = 4200 km', () {
      expect(TripConstants.calculateRadiusFromDays(7), 4200.0);
    });
  });

  group('TripConstants - Quick-Select Werte', () {
    test('Tagesausflug Quick-Select hat 4 Werte', () {
      expect(TripConstants.dayTripQuickSelectRadii.length, 4);
    });

    test('Euro Trip Quick-Select hat 4 Werte', () {
      expect(TripConstants.euroTripQuickSelectDays.length, 4);
    });

    test('Euro Trip Quick-Select sind aufsteigend', () {
      for (int i = 1; i < TripConstants.euroTripQuickSelectDays.length; i++) {
        expect(
          TripConstants.euroTripQuickSelectDays[i],
          greaterThan(TripConstants.euroTripQuickSelectDays[i - 1]),
        );
      }
    });

    test('Tagesausflug Quick-Select sind aufsteigend', () {
      for (int i = 1; i < TripConstants.dayTripQuickSelectRadii.length; i++) {
        expect(
          TripConstants.dayTripQuickSelectRadii[i],
          greaterThan(TripConstants.dayTripQuickSelectRadii[i - 1]),
        );
      }
    });
  });

  group('TripConstants - Distanz-Konvertierung', () {
    test('toDisplayKm und toHaversineKm sind konsistent', () {
      const haversine = 320.0;
      final display = TripConstants.toDisplayKm(haversine);
      final back = TripConstants.toHaversineKm(display);

      expect(display, closeTo(432.0, 0.001));
      expect(back, closeTo(haversine, 0.001));
    });

    test('isDisplayOverDayLimit erkennt >700km', () {
      expect(TripConstants.isDisplayOverDayLimit(701), isTrue);
      expect(TripConstants.isDisplayOverDayLimit(700), isFalse);
    });
  });
}
