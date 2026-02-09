import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:travel_planner/core/constants/categories.dart';
import 'package:travel_planner/data/models/route.dart';
import 'package:travel_planner/data/models/trip.dart';
import 'package:travel_planner/data/services/sharing_service.dart';

void main() {
  Trip buildTrip() {
    return Trip(
      id: 'trip-encoded',
      name: 'Encoded Trip',
      type: TripType.daytrip,
      route: const AppRoute(
        start: const LatLng(48.137, 11.575),
        end: const LatLng(47.376, 8.541),
        startAddress: 'Munich',
        endAddress: 'Zurich',
        coordinates: const [],
        distanceKm: 320,
        durationMinutes: 220,
      ),
      stops: const [
        TripStop(
          poiId: 'poi-1',
          name: 'Castle',
          latitude: 48.2,
          longitude: 11.6,
          categoryId: 'castle',
        ),
      ],
      createdAt: DateTime(2026, 2, 1),
    );
  }

  test('generatePublicTripLink uses /gallery path', () {
    expect(
      generatePublicTripLink('abc123'),
      'https://mapab.app/gallery/abc123',
    );
  });

  test('extractPublicTripIdFromLink parses /gallery links', () {
    expect(
      extractPublicTripIdFromLink('https://mapab.app/gallery/trip-42'),
      'trip-42',
    );
  });

  test('extractPublicTripIdFromLink keeps legacy /trip/{id} compatibility', () {
    expect(
      extractPublicTripIdFromLink(
        'https://mapab.app/trip/6f4e2f6d-52f2-4fa2-a0d3-7f2f640f9f22',
      ),
      '6f4e2f6d-52f2-4fa2-a0d3-7f2f640f9f22',
    );
  });

  test('extractPublicTripIdFromLink ignores encoded private trip payloads', () {
    final service = SharingService();
    final deepLink = service.generateDeepLink(buildTrip());

    expect(extractPublicTripIdFromLink(deepLink), isNull);
  });
}
