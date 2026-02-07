import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:travel_planner/data/services/hotel_service.dart';

void main() {
  group('HotelSuggestion', () {
    test('getBookingUrl nutzt uebergebenes Datum', () {
      final hotel = HotelSuggestion(
        id: 'h1',
        name: 'Test Hotel',
        location: const LatLng(48.137, 11.575),
        type: HotelType.hotel,
        distanceKm: 1.2,
      );

      final url = hotel.getBookingUrl(
        checkIn: DateTime(2026, 2, 15),
        checkOut: DateTime(2026, 2, 16),
      );

      expect(url, contains('checkin=2026-02-15'));
      expect(url, contains('checkout=2026-02-16'));
    });

    test('toJson/fromJson roundtrip', () {
      final original = HotelSuggestion(
        id: 'h2',
        placeId: 'place-123',
        name: 'Roundtrip Hotel',
        location: const LatLng(47.0, 11.0),
        type: HotelType.hostel,
        distanceKm: 2.5,
        rating: 4.4,
        reviewCount: 42,
        highlights: const ['Sauber', 'Ruhig'],
        amenities: const HotelAmenities(wifi: true, parking: true),
      );

      final decoded = HotelSuggestion.fromJson(original.toJson());
      expect(decoded.id, original.id);
      expect(decoded.placeId, original.placeId);
      expect(decoded.name, original.name);
      expect(decoded.rating, original.rating);
      expect(decoded.reviewCount, original.reviewCount);
      expect(decoded.highlights, original.highlights);
      expect(decoded.amenities.wifi, isTrue);
      expect(decoded.amenities.parking, isTrue);
    });
  });
}
