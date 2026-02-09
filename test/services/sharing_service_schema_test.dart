import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:travel_planner/core/constants/categories.dart';
import 'package:travel_planner/data/models/route.dart';
import 'package:travel_planner/data/models/trip.dart';
import 'package:travel_planner/data/services/sharing_service.dart';

void main() {
  Trip buildTrip() {
    return Trip(
      id: 'trip-1',
      name: 'Weekend',
      type: TripType.daytrip,
      route: AppRoute(
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

  test('encode/decode keeps route addresses (v2 schema)', () {
    final service = SharingService();
    final link = service.generateShareLink(buildTrip());
    final encoded = Uri.parse(link).queryParameters['data']!;

    final decoded = service.decodeTrip(encoded);

    expect(decoded, isNotNull);
    expect(decoded!.route.startAddress, 'Munich');
    expect(decoded.route.endAddress, 'Zurich');
  });

  test('decodeTrip supports legacy startAddr/endAddr keys', () {
    final service = SharingService();
    final legacy = <String, dynamic>{
      'id': 'legacy-trip',
      'name': 'Legacy',
      'type': 'daytrip',
      'route': <String, dynamic>{
        'startLat': 48.137,
        'startLng': 11.575,
        'endLat': 47.376,
        'endLng': 8.541,
        'startAddr': 'Legacy Start',
        'endAddr': 'Legacy End',
      },
      'stops': const [],
      'days': 1,
    };

    final encoded = base64UrlEncode(utf8.encode(jsonEncode(legacy)));
    final decoded = service.decodeTrip(encoded);

    expect(decoded, isNotNull);
    expect(decoded!.route.startAddress, 'Legacy Start');
    expect(decoded.route.endAddress, 'Legacy End');
  });
}
