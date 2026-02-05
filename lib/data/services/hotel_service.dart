import 'dart:math' show cos, pi;
import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/utils/geo_utils.dart';
import '../models/trip.dart';

part 'hotel_service.g.dart';

/// Service für Hotel-Suche via Overpass API
/// Verwendet OpenStreetMap-Daten (kostenlos, DSGVO-konform)
class HotelService {
  final Dio _dio;

  HotelService({Dio? dio})
      : _dio = dio ?? ApiConfig.createDio(profile: DioProfile.overpass);

  /// Sucht Hotels in einem Radius um einen Punkt
  ///
  /// [location] - Zentrum der Suche
  /// [radiusKm] - Suchradius in Kilometern (Standard: 10km)
  /// [limit] - Maximale Anzahl Ergebnisse
  Future<List<HotelSuggestion>> searchHotelsNearby({
    required LatLng location,
    double radiusKm = 10,
    int limit = 5,
  }) async {
    // Bounding Box berechnen
    final bounds = _createBoundsFromRadius(location, radiusKm);

    // Overpass Query für Hotels, Hostels, Pensionen
    final query = '''
[out:json][timeout:15];
(
  node["tourism"="hotel"](${bounds.southwest.latitude},${bounds.southwest.longitude},${bounds.northeast.latitude},${bounds.northeast.longitude});
  node["tourism"="hostel"](${bounds.southwest.latitude},${bounds.southwest.longitude},${bounds.northeast.latitude},${bounds.northeast.longitude});
  node["tourism"="guest_house"](${bounds.southwest.latitude},${bounds.southwest.longitude},${bounds.northeast.latitude},${bounds.northeast.longitude});
  node["tourism"="motel"](${bounds.southwest.latitude},${bounds.southwest.longitude},${bounds.northeast.latitude},${bounds.northeast.longitude});
  way["tourism"="hotel"](${bounds.southwest.latitude},${bounds.southwest.longitude},${bounds.northeast.latitude},${bounds.northeast.longitude});
);
out center;
''';

    try {
      final response = await _dio.post(
        ApiEndpoints.overpassApi,
        data: query,
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
        ),
      );

      final elements = response.data['elements'] as List?;
      if (elements == null || elements.isEmpty) return [];

      // Parsen und nach Distanz sortieren
      final hotels = elements
          .where((e) => e['tags']?['name'] != null)
          .map((e) => _parseHotel(e, location))
          .toList();

      // Nach Distanz sortieren und limitieren
      hotels.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

      return hotels.take(limit).toList();
    } on DioException catch (e) {
      throw HotelSearchException('Hotel-Suche fehlgeschlagen: ${e.message}');
    }
  }

  /// Sucht Hotels für mehrere Übernachtungsorte
  Future<List<List<HotelSuggestion>>> searchHotelsForMultipleLocations({
    required List<LatLng> locations,
    double radiusKm = 10,
    int limitPerLocation = 3,
  }) async {
    final results = <List<HotelSuggestion>>[];

    for (final location in locations) {
      try {
        final hotels = await searchHotelsNearby(
          location: location,
          radiusKm: radiusKm,
          limit: limitPerLocation,
        );
        results.add(hotels);

        // Rate Limiting für Overpass API
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (_) {
        results.add([]);
      }
    }

    return results;
  }

  /// Konvertiert Hotel-Vorschläge zu TripStops
  List<TripStop> convertToTripStops(List<HotelSuggestion> hotels) {
    return hotels.map((hotel) {
      return TripStop(
        poiId: hotel.id,
        name: hotel.name,
        latitude: hotel.location.latitude,
        longitude: hotel.location.longitude,
        categoryId: 'hotel',
        isOvernightStop: true,
        detourKm: hotel.distanceKm,
      );
    }).toList();
  }

  /// Parst Overpass-Antwort zu HotelSuggestion
  HotelSuggestion _parseHotel(Map<String, dynamic> data, LatLng searchCenter) {
    final tags = data['tags'] as Map<String, dynamic>? ?? {};

    // Koordinaten ermitteln (Node vs Way)
    double lat, lng;
    if (data['center'] != null) {
      lat = (data['center']['lat'] as num).toDouble();
      lng = (data['center']['lon'] as num).toDouble();
    } else {
      lat = (data['lat'] as num).toDouble();
      lng = (data['lon'] as num).toDouble();
    }

    final location = LatLng(lat, lng);
    final distance = GeoUtils.haversineDistance(searchCenter, location);

    // Typ ermitteln
    HotelType type = HotelType.hotel;
    final tourism = tags['tourism'];
    if (tourism == 'hostel') {
      type = HotelType.hostel;
    } else if (tourism == 'guest_house') {
      type = HotelType.guestHouse;
    } else if (tourism == 'motel') {
      type = HotelType.motel;
    }

    // Sterne (falls verfügbar)
    int? stars;
    if (tags['stars'] != null) {
      stars = int.tryParse(tags['stars'].toString());
    }

    // Amenities aus Tags parsen
    final amenities = HotelAmenities.fromOsmTags(tags);

    // Check-in/out Zeiten
    String? checkInTime = tags['check_in'];
    String? checkOutTime = tags['check_out'];

    // Beschreibung (falls vorhanden)
    String? description = tags['description'] ?? tags['note'];

    return HotelSuggestion(
      id: 'hotel-${data['type']}-${data['id']}',
      name: tags['name'] ?? 'Unbekanntes Hotel',
      location: location,
      type: type,
      stars: stars,
      website: tags['website'],
      phone: tags['phone'],
      email: tags['email'],
      address: _buildAddress(tags),
      distanceKm: distance,
      amenities: amenities,
      checkInTime: checkInTime,
      checkOutTime: checkOutTime,
      description: description,
    );
  }

  /// Baut Adresse aus Tags
  String? _buildAddress(Map<String, dynamic> tags) {
    final parts = <String>[];

    if (tags['addr:street'] != null) {
      parts.add(tags['addr:street']);
      if (tags['addr:housenumber'] != null) {
        parts[0] = '${parts[0]} ${tags['addr:housenumber']}';
      }
    }

    if (tags['addr:postcode'] != null) {
      parts.add(tags['addr:postcode']);
    }

    if (tags['addr:city'] != null) {
      parts.add(tags['addr:city']);
    }

    return parts.isNotEmpty ? parts.join(', ') : null;
  }

  /// Erstellt Bounding Box aus Zentrum und Radius
  ({LatLng southwest, LatLng northeast}) _createBoundsFromRadius(
    LatLng center,
    double radiusKm,
  ) {
    const latDegreeKm = 111.0;
    final lngDegreeKm = 111.0 * cos(center.latitude * pi / 180);

    final latDelta = radiusKm / latDegreeKm;
    final lngDelta = radiusKm / lngDegreeKm;

    return (
      southwest: LatLng(center.latitude - latDelta, center.longitude - lngDelta),
      northeast: LatLng(center.latitude + latDelta, center.longitude + lngDelta),
    );
  }
}

/// Hotel-Typ
enum HotelType {
  hotel('Hotel', '🏨'),
  hostel('Hostel', '🛏️'),
  guestHouse('Pension', '🏠'),
  motel('Motel', '🏩');

  final String label;
  final String icon;

  const HotelType(this.label, this.icon);
}

/// Amenities (Hotel-Ausstattung)
class HotelAmenities {
  final bool wifi;
  final bool parking;
  final bool breakfast;
  final bool restaurant;
  final bool pool;
  final bool spa;
  final bool airConditioning;
  final bool petsAllowed;
  final bool wheelchairAccessible;

  const HotelAmenities({
    this.wifi = false,
    this.parking = false,
    this.breakfast = false,
    this.restaurant = false,
    this.pool = false,
    this.spa = false,
    this.airConditioning = false,
    this.petsAllowed = false,
    this.wheelchairAccessible = false,
  });

  /// Parst Amenities aus OSM-Tags
  factory HotelAmenities.fromOsmTags(Map<String, dynamic> tags) {
    return HotelAmenities(
      wifi: tags['internet_access'] == 'wlan' ||
          tags['internet_access'] == 'yes' ||
          tags['wifi'] == 'yes',
      parking: tags['parking'] != null ||
          tags['parking:fee'] != null ||
          tags['capacity:parking'] != null,
      breakfast: tags['breakfast'] == 'yes' ||
          tags['breakfast'] == 'included',
      restaurant: tags['restaurant'] == 'yes' ||
          tags['amenity'] == 'restaurant',
      pool: tags['swimming_pool'] == 'yes' ||
          tags['leisure'] == 'swimming_pool',
      spa: tags['spa'] == 'yes' ||
          tags['leisure'] == 'spa' ||
          tags['wellness'] == 'yes',
      airConditioning: tags['air_conditioning'] == 'yes',
      petsAllowed: tags['pets'] == 'yes' ||
          tags['dog'] == 'yes',
      wheelchairAccessible: tags['wheelchair'] == 'yes',
    );
  }

  /// Liste der verfügbaren Amenities mit Icons
  List<({String icon, String label})> get availableAmenities {
    final list = <({String icon, String label})>[];
    if (wifi) list.add((icon: '📶', label: 'WLAN'));
    if (parking) list.add((icon: '🅿️', label: 'Parkplatz'));
    if (breakfast) list.add((icon: '🍳', label: 'Frühstück'));
    if (restaurant) list.add((icon: '🍽️', label: 'Restaurant'));
    if (pool) list.add((icon: '🏊', label: 'Pool'));
    if (spa) list.add((icon: '🧖', label: 'Spa'));
    if (airConditioning) list.add((icon: '❄️', label: 'Klimaanlage'));
    if (petsAllowed) list.add((icon: '🐕', label: 'Haustiere'));
    if (wheelchairAccessible) list.add((icon: '♿', label: 'Barrierefrei'));
    return list;
  }

  /// Hat mindestens ein Amenity
  bool get hasAny =>
      wifi || parking || breakfast || restaurant || pool ||
      spa || airConditioning || petsAllowed || wheelchairAccessible;
}

/// Hotel-Vorschlag
class HotelSuggestion {
  final String id;
  final String name;
  final LatLng location;
  final HotelType type;
  final int? stars;
  final String? website;
  final String? phone;
  final String? email;
  final String? address;
  final double distanceKm;

  // Neue Felder für Amenities und Check-in/out
  final HotelAmenities amenities;
  final String? checkInTime;
  final String? checkOutTime;
  final String? description;

  HotelSuggestion({
    required this.id,
    required this.name,
    required this.location,
    required this.type,
    this.stars,
    this.website,
    this.phone,
    this.email,
    this.address,
    required this.distanceKm,
    this.amenities = const HotelAmenities(),
    this.checkInTime,
    this.checkOutTime,
    this.description,
  });

  /// Formatierte Distanz
  String get formattedDistance => '${distanceKm.toStringAsFixed(1)} km';

  /// Hat Kontaktdaten
  bool get hasContactInfo => website != null || phone != null || email != null;

  /// Sterne als String
  String get starsDisplay {
    if (stars == null) return '';
    return '⭐' * stars!;
  }

  /// Typ mit Icon
  String get typeDisplay => '${type.icon} ${type.label}';

  /// Check-in/out formatiert
  String? get checkInOutDisplay {
    if (checkInTime == null && checkOutTime == null) return null;
    final parts = <String>[];
    if (checkInTime != null) parts.add('Check-in: $checkInTime');
    if (checkOutTime != null) parts.add('Check-out: $checkOutTime');
    return parts.join(' · ');
  }

  /// Generiert Booking.com Such-URL mit Datum
  /// [checkIn] - Anreisedatum
  /// [checkOut] - Abreisedatum (optional, Standard: checkIn + 1 Tag)
  String getBookingUrl({
    required DateTime checkIn,
    DateTime? checkOut,
  }) {
    final checkout = checkOut ?? checkIn.add(const Duration(days: 1));

    // Datum formatieren (YYYY-MM-DD)
    String formatDate(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    // URL-kodierter Name
    final encodedName = Uri.encodeComponent(name);

    return 'https://www.booking.com/searchresults.html'
        '?ss=$encodedName'
        '&checkin=${formatDate(checkIn)}'
        '&checkout=${formatDate(checkout)}'
        '&latitude=${location.latitude}'
        '&longitude=${location.longitude}'
        '&radius=1'; // 1km Radius um die Koordinaten
  }

  /// Google Maps URL für Navigation
  String get googleMapsUrl =>
      'https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}';
}

/// Hotel-Suche Exception
class HotelSearchException implements Exception {
  final String message;
  HotelSearchException(this.message);

  @override
  String toString() => 'HotelSearchException: $message';
}

/// Riverpod Provider für HotelService
@riverpod
HotelService hotelService(HotelServiceRef ref) {
  return HotelService();
}
