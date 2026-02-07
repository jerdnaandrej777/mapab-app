import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:travel_planner/core/algorithms/random_poi_selector.dart';
import 'package:travel_planner/core/utils/geo_utils.dart';

import '../helpers/test_factories.dart';

void main() {
  group('RandomPOISelector.selectRandomPOIs - constrained mode', () {
    test('enforces maxSegmentKm for sequential picks', () {
      final selector = RandomPOISelector(random: Random(7));
      const start = LatLng(0, 0);
      final pois = [
        createPOI(id: 'near-1', latitude: 0, longitude: 0.8, score: 60),
        createPOI(id: 'near-2', latitude: 0, longitude: 1.6, score: 58),
        createPOI(id: 'far', latitude: 0, longitude: 8.0, score: 95),
      ];

      final selected = selector.selectRandomPOIs(
        pois: pois,
        startLocation: start,
        count: 3,
        maxSegmentKm: 150,
        currentAnchorLocation: start,
      );

      expect(selected.map((p) => p.id), isNot(contains('far')));
      if (selected.isNotEmpty) {
        var anchor = start;
        for (final poi in selected) {
          expect(GeoUtils.haversineDistance(anchor, poi.location),
              lessThanOrEqualTo(150));
          anchor = poi.location;
        }
      }
    });

    test('applies reachability-to-end guard', () {
      final selector = RandomPOISelector(random: Random(11));
      const start = LatLng(0, 0);
      const end = LatLng(0, 3.0);

      final pois = [
        createPOI(id: 'bad', latitude: 0, longitude: 0.6, score: 100),
        createPOI(id: 'ok-1', latitude: 0, longitude: 1.05, score: 50),
        createPOI(id: 'ok-2', latitude: 0, longitude: 2.05, score: 50),
      ];

      final selected = selector.selectRandomPOIs(
        pois: pois,
        startLocation: start,
        count: 2,
        maxSegmentKm: 120,
        tripEndLocation: end,
        currentAnchorLocation: start,
      );

      expect(selected.map((p) => p.id), isNot(contains('bad')));
      expect(selected, isNotEmpty);
    });

    test('respects remainingTripBudgetKm', () {
      final selector = RandomPOISelector(random: Random(19));
      const start = LatLng(0, 0);

      final pois = [
        createPOI(id: 'p1', latitude: 0, longitude: 0.5, score: 60),
        createPOI(id: 'p2', latitude: 0, longitude: 1.0, score: 60),
        createPOI(id: 'p3', latitude: 0, longitude: 1.5, score: 60),
      ];

      final selected = selector.selectRandomPOIs(
        pois: pois,
        startLocation: start,
        count: 3,
        maxSegmentKm: 120,
        remainingTripBudgetKm: 150,
        currentAnchorLocation: start,
      );

      var totalKm = 0.0;
      var anchor = start;
      for (final poi in selected) {
        totalKm += GeoUtils.haversineDistance(anchor, poi.location);
        anchor = poi.location;
      }

      expect(totalKm, lessThanOrEqualTo(150.0));
    });
  });
}
