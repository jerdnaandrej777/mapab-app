import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:travel_planner/data/models/poi.dart';
import 'package:travel_planner/data/models/trip.dart';
import 'package:travel_planner/data/providers/favorites_provider.dart';
import 'package:travel_planner/features/trip/widgets/day_mini_map.dart';

import '../helpers/test_factories.dart';

void main() {
  group('extractRouteSegmentThroughWaypoints', () {
    test('uses forward waypoint matching for roundtrip tail segments', () {
      const a = LatLng(53.5511, 9.9937);
      const b = LatLng(53.60, 10.05);
      const c = LatLng(53.65, 10.10);
      const d = LatLng(53.70, 10.15);
      const e = LatLng(53.75, 10.20);
      final fullRoute = [a, b, c, d, e, a];

      final segment = extractRouteSegmentThroughWaypoints(
        fullRoute,
        const [d, e, a],
      );

      expect(segment, [d, e, a]);
    });
  });

  group('DayMiniMap', () {
    testWidgets('recommended marker ist tappable und liefert den korrekten POI',
        (tester) async {
      final recommendedPoi = createPOI(
        id: 'rec-1',
        name: 'Recommended POI',
        latitude: 48.1372,
        longitude: 11.5756,
        categoryId: 'museum',
      );

      final trip = createTrip(
        stops: <TripStop>[
          createTripStop(
            poiId: 'stop-1',
            name: 'Stop',
            latitude: 48.136,
            longitude: 11.57,
            day: 1,
          ),
        ],
      );

      POI? tappedPoi;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            favoritePOIsProvider.overrideWith((ref) => const []),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: DayMiniMap(
                trip: trip,
                selectedDay: 1,
                startLocation: const LatLng(48.1351, 11.5820),
                recommendedPOIs: [recommendedPoi],
                onMarkerTap: (poi) => tappedPoi = poi,
                showTileLayer: false,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
      await tester.tap(find.byIcon(Icons.auto_awesome));
      await tester.pump();

      expect(tappedPoi?.id, 'rec-1');
    });
  });
}
