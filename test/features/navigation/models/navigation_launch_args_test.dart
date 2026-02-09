import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:travel_planner/data/models/route.dart';
import 'package:travel_planner/data/models/trip.dart';
import 'package:travel_planner/features/navigation/models/navigation_launch_args.dart';

void main() {
  AppRoute buildRoute() {
    return AppRoute(
      start: const LatLng(48.137, 11.575),
      end: const LatLng(47.376, 8.541),
      startAddress: 'Munich',
      endAddress: 'Zurich',
      coordinates: const [],
      distanceKm: 0,
      durationMinutes: 0,
    );
  }

  TripStop buildStop() {
    return const TripStop(
      poiId: 'poi-1',
      name: 'Test POI',
      latitude: 48.2,
      longitude: 11.6,
      categoryId: 'museum',
    );
  }

  test('fromExtra returns args for typed payload', () {
    final args =
        NavigationLaunchArgs(route: buildRoute(), stops: [buildStop()]);
    final parsed = NavigationLaunchArgs.fromExtra(args);

    expect(parsed, isNotNull);
    expect(parsed!.route.startAddress, 'Munich');
    expect(parsed.stops.length, 1);
  });

  test('fromExtra supports legacy map payload', () {
    final route = buildRoute();
    final stop = buildStop();

    final parsed = NavigationLaunchArgs.fromExtra(<String, dynamic>{
      'route': route,
      'stops': <TripStop>[stop],
    });

    expect(parsed, isNotNull);
    expect(parsed!.route.endAddress, 'Zurich');
    expect(parsed.stops.single.poiId, 'poi-1');
  });

  test('fromExtra rejects invalid payload', () {
    final parsed = NavigationLaunchArgs.fromExtra(<String, dynamic>{
      'route': 'invalid',
      'stops': const [],
    });

    expect(parsed, isNull);
  });
}
