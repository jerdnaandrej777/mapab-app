import 'dart:math' show cos, pi;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/constants/api_config.dart' as backend_api;
import '../../core/constants/api_endpoints.dart';
import '../../core/utils/geo_utils.dart';
import '../models/trip.dart';

part 'hotel_service.g.dart';

/// Hotel search service.
///
/// Primary source: backend `/api/hotels/search` (Google Places).
/// Fallback: Overpass/OSM when backend is unavailable.
class HotelService {
  final Dio _overpassDio;
  final Dio? _backendDio;

  HotelService({Dio? overpassDio, Dio? backendDio})
      : _overpassDio =
            overpassDio ?? ApiConfig.createDio(profile: DioProfile.overpass),
        _backendDio = backendDio ??
            (backend_api.ApiConfig.isConfigured
                ? Dio(
                    BaseOptions(
                      baseUrl: backend_api.ApiConfig.backendBaseUrl,
                      connectTimeout: backend_api.ApiConfig.connectTimeout,
                      receiveTimeout: backend_api.ApiConfig.receiveTimeout,
                      headers: const {'Content-Type': 'application/json'},
                    ),
                  )
                : null);

  /// Searches hotels around a location.
  ///
  /// Radius is hard-clamped to <= 20km.
  Future<List<HotelSuggestion>> searchHotelsNearby({
    required LatLng location,
    double radiusKm = 10,
    int limit = 5,
    DateTime? checkInDate,
    DateTime? checkOutDate,
    String? language,
    int? dayIndex,
  }) async {
    final safeRadiusKm = radiusKm.clamp(1, 20).toDouble();
    final safeLimit = limit.clamp(1, 20);

    if (_backendDio != null) {
      try {
        final backendHotels = await _searchHotelsViaBackend(
          location: location,
          radiusKm: safeRadiusKm,
          limit: safeLimit,
          checkInDate: checkInDate,
          checkOutDate: checkOutDate,
          language: language,
          dayIndex: dayIndex,
        );
        if (backendHotels.isNotEmpty) {
          return backendHotels.take(safeLimit).toList();
        }
      } catch (e) {
        debugPrint('[HotelService] Backend hotel search failed, fallback: $e');
      }
    }

    final fallbackHotels = await _searchHotelsViaOverpass(
      location: location,
      radiusKm: safeRadiusKm,
      limit: safeLimit,
    );
    return fallbackHotels.take(safeLimit).toList();
  }

  Future<List<HotelSuggestion>> _searchHotelsViaBackend({
    required LatLng location,
    required double radiusKm,
    required int limit,
    DateTime? checkInDate,
    DateTime? checkOutDate,
    String? language,
    int? dayIndex,
  }) async {
    final dio = _backendDio;
    if (dio == null) return const [];

    final response = await dio.post(
      '/api/hotels/search',
      data: {
        'lat': location.latitude,
        'lng': location.longitude,
        'radiusKm': radiusKm,
        'limit': limit,
        if (checkInDate != null) 'checkInDate': _formatIsoDate(checkInDate),
        if (checkOutDate != null) 'checkOutDate': _formatIsoDate(checkOutDate),
        if (language != null && language.isNotEmpty) 'language': language,
        if (dayIndex != null) 'dayIndex': dayIndex,
      },
    );

    final payload = response.data;
    final rawHotels = switch (payload) {
      {'hotels': final List hotels} => hotels,
      List hotels => hotels,
      _ => const <dynamic>[],
    };

    final parsed = rawHotels
        .whereType<Map<String, dynamic>>()
        .map((raw) => _parseBackendHotel(raw, location))
        .toList();
    parsed.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    final filteredByReviews = _applyReviewThreshold(parsed);
    return filteredByReviews.take(limit).toList();
  }

  List<HotelSuggestion> _applyReviewThreshold(List<HotelSuggestion> hotels) {
    if (hotels.isEmpty) return hotels;

    final strict = hotels.where((hotel) {
      final count = hotel.reviewCount;
      if (count == null || count <= 0) return true;
      return count >= 10;
    }).toList();

    if (strict.isNotEmpty) return strict;

    return hotels
        .map((hotel) => hotel.copyWith(dataQuality: 'few_or_no_reviews'))
        .toList();
  }

  Future<List<HotelSuggestion>> _searchHotelsViaOverpass({
    required LatLng location,
    required double radiusKm,
    required int limit,
  }) async {
    final bounds = _createBoundsFromRadius(location, radiusKm);

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
      final response = await _overpassDio.post(
        ApiEndpoints.overpassApi,
        data: query,
        options: Options(contentType: 'application/x-www-form-urlencoded'),
      );

      final elements = response.data['elements'] as List?;
      if (elements == null || elements.isEmpty) return const [];

      final hotels = elements
          .whereType<Map<String, dynamic>>()
          .where((element) => element['tags']?['name'] != null)
          .map((element) => _parseOverpassHotel(element, location))
          .toList();

      hotels.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      return hotels.take(limit).toList();
    } on DioException catch (e) {
      throw HotelSearchException('Hotel search failed: ${e.message}');
    }
  }

  /// Searches hotels for each overnight location.
  ///
  /// `tripStartDate` is used for day-specific check-in/check-out dates.
  Future<List<List<HotelSuggestion>>> searchHotelsForMultipleLocations({
    required List<LatLng> locations,
    double radiusKm = 10,
    int limitPerLocation = 3,
    DateTime? tripStartDate,
    String? language,
  }) async {
    final results = <List<HotelSuggestion>>[];

    for (int i = 0; i < locations.length; i++) {
      final location = locations[i];
      final checkIn = tripStartDate?.add(Duration(days: i));
      final checkOut = checkIn?.add(const Duration(days: 1));

      try {
        final hotels = await searchHotelsNearby(
          location: location,
          radiusKm: radiusKm,
          limit: limitPerLocation,
          checkInDate: checkIn,
          checkOutDate: checkOut,
          language: language,
          dayIndex: i + 1,
        );
        results.add(hotels);
      } catch (_) {
        results.add(const []);
      }

      // Keep external API usage polite.
      await Future.delayed(const Duration(milliseconds: 250));
    }

    return results;
  }

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

  HotelSuggestion _parseBackendHotel(
    Map<String, dynamic> data,
    LatLng searchCenter,
  ) {
    final lat = (data['lat'] as num?)?.toDouble();
    final lng = (data['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) {
      throw HotelSearchException('Backend hotel has no coordinates');
    }

    final location = LatLng(lat, lng);
    final directDistance = GeoUtils.haversineDistance(searchCenter, location);
    final responseDistance = (data['distanceKm'] as num?)?.toDouble();

    return HotelSuggestion(
      id: (data['id'] as String?) ??
          (data['placeId'] as String?) ??
          'hotel-${lat.toStringAsFixed(5)}-${lng.toStringAsFixed(5)}',
      placeId: data['placeId'] as String?,
      name: (data['name'] as String?)?.trim().isNotEmpty == true
          ? data['name'] as String
          : 'Hotel',
      location: location,
      type: _hotelTypeFromString(data['type'] as String?),
      stars: (data['stars'] as num?)?.toInt(),
      website: data['website'] as String?,
      phone: data['phone'] as String?,
      email: data['email'] as String?,
      address: data['address'] as String?,
      distanceKm: responseDistance ?? directDistance,
      amenities:
          HotelAmenities.fromMap(data['amenities'] as Map<String, dynamic>?),
      checkInTime: data['checkInTime'] as String?,
      checkOutTime: data['checkOutTime'] as String?,
      description: data['description'] as String?,
      rating: (data['rating'] as num?)?.toDouble(),
      reviewCount: (data['reviewCount'] as num?)?.toInt(),
      highlights: ((data['highlights'] as List?) ?? const [])
          .whereType<String>()
          .where((text) => text.trim().isNotEmpty)
          .toList(),
      source: (data['source'] as String?) ?? 'backend',
      bookingUrl: data['bookingUrl'] as String?,
      dataQuality: (data['dataQuality'] as String?) ?? 'verified',
    );
  }

  HotelSuggestion _parseOverpassHotel(
    Map<String, dynamic> data,
    LatLng searchCenter,
  ) {
    final tags = data['tags'] as Map<String, dynamic>? ?? {};

    double lat;
    double lng;
    if (data['center'] != null) {
      lat = (data['center']['lat'] as num).toDouble();
      lng = (data['center']['lon'] as num).toDouble();
    } else {
      lat = (data['lat'] as num).toDouble();
      lng = (data['lon'] as num).toDouble();
    }

    final location = LatLng(lat, lng);
    final distance = GeoUtils.haversineDistance(searchCenter, location);

    return HotelSuggestion(
      id: 'hotel-${data['type']}-${data['id']}',
      name: tags['name'] ?? 'Hotel',
      location: location,
      type: _hotelTypeFromOsm(tags['tourism'] as String?),
      stars: int.tryParse((tags['stars'] ?? '').toString()),
      website: tags['website'] as String?,
      phone: tags['phone'] as String?,
      email: tags['email'] as String?,
      address: _buildAddress(tags),
      distanceKm: distance,
      amenities: HotelAmenities.fromOsmTags(tags),
      checkInTime: tags['check_in'] as String?,
      checkOutTime: tags['check_out'] as String?,
      description: tags['description'] as String? ?? tags['note'] as String?,
      highlights: const [],
      source: 'osm_overpass',
      dataQuality: 'limited',
    );
  }

  HotelType _hotelTypeFromOsm(String? tourism) {
    switch (tourism) {
      case 'hostel':
        return HotelType.hostel;
      case 'guest_house':
        return HotelType.guestHouse;
      case 'motel':
        return HotelType.motel;
      default:
        return HotelType.hotel;
    }
  }

  HotelType _hotelTypeFromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'hostel':
        return HotelType.hostel;
      case 'guest_house':
      case 'guesthouse':
        return HotelType.guestHouse;
      case 'motel':
        return HotelType.motel;
      default:
        return HotelType.hotel;
    }
  }

  String? _buildAddress(Map<String, dynamic> tags) {
    final parts = <String>[];
    if (tags['addr:street'] != null) {
      var street = '${tags['addr:street']}';
      if (tags['addr:housenumber'] != null) {
        street = '$street ${tags['addr:housenumber']}';
      }
      parts.add(street);
    }
    if (tags['addr:postcode'] != null) {
      parts.add('${tags['addr:postcode']}');
    }
    if (tags['addr:city'] != null) {
      parts.add('${tags['addr:city']}');
    }
    return parts.isEmpty ? null : parts.join(', ');
  }

  ({LatLng southwest, LatLng northeast}) _createBoundsFromRadius(
    LatLng center,
    double radiusKm,
  ) {
    const latDegreeKm = 111.0;
    final lngDegreeKm = 111.0 * cos(center.latitude * pi / 180);
    final latDelta = radiusKm / latDegreeKm;
    final lngDelta = radiusKm / lngDegreeKm;
    return (
      southwest:
          LatLng(center.latitude - latDelta, center.longitude - lngDelta),
      northeast:
          LatLng(center.latitude + latDelta, center.longitude + lngDelta),
    );
  }

  String _formatIsoDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

enum HotelType {
  hotel('Hotel', '🏨'),
  hostel('Hostel', '🛏️'),
  guestHouse('Guest House', '🏠'),
  motel('Motel', '🏩');

  final String label;
  final String icon;

  const HotelType(this.label, this.icon);
}

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

  factory HotelAmenities.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const HotelAmenities();

    bool parseBool(dynamic value) {
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final normalized = value.toLowerCase();
        return normalized == 'true' || normalized == 'yes' || normalized == '1';
      }
      return false;
    }

    return HotelAmenities(
      wifi: parseBool(map['wifi']),
      parking: parseBool(map['parking']),
      breakfast: parseBool(map['breakfast']),
      restaurant: parseBool(map['restaurant']),
      pool: parseBool(map['pool']),
      spa: parseBool(map['spa']),
      airConditioning: parseBool(map['airConditioning']),
      petsAllowed: parseBool(map['petsAllowed']),
      wheelchairAccessible: parseBool(map['wheelchairAccessible']),
    );
  }

  factory HotelAmenities.fromOsmTags(Map<String, dynamic> tags) {
    return HotelAmenities(
      wifi: tags['internet_access'] == 'wlan' ||
          tags['internet_access'] == 'yes' ||
          tags['wifi'] == 'yes',
      parking: tags['parking'] != null ||
          tags['parking:fee'] != null ||
          tags['capacity:parking'] != null,
      breakfast: tags['breakfast'] == 'yes' || tags['breakfast'] == 'included',
      restaurant:
          tags['restaurant'] == 'yes' || tags['amenity'] == 'restaurant',
      pool:
          tags['swimming_pool'] == 'yes' || tags['leisure'] == 'swimming_pool',
      spa: tags['spa'] == 'yes' ||
          tags['leisure'] == 'spa' ||
          tags['wellness'] == 'yes',
      airConditioning: tags['air_conditioning'] == 'yes',
      petsAllowed: tags['pets'] == 'yes' || tags['dog'] == 'yes',
      wheelchairAccessible: tags['wheelchair'] == 'yes',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'wifi': wifi,
      'parking': parking,
      'breakfast': breakfast,
      'restaurant': restaurant,
      'pool': pool,
      'spa': spa,
      'airConditioning': airConditioning,
      'petsAllowed': petsAllowed,
      'wheelchairAccessible': wheelchairAccessible,
    };
  }

  List<({String icon, String label})> get availableAmenities {
    final list = <({String icon, String label})>[];
    if (wifi) list.add((icon: '📶', label: 'WLAN'));
    if (parking) list.add((icon: '🅿️', label: 'Parkplatz'));
    if (breakfast) list.add((icon: '🍳', label: 'Fruehstueck'));
    if (restaurant) list.add((icon: '🍽️', label: 'Restaurant'));
    if (pool) list.add((icon: '🏊', label: 'Pool'));
    if (spa) list.add((icon: '🧖', label: 'Spa'));
    if (airConditioning) list.add((icon: '❄️', label: 'Klimaanlage'));
    if (petsAllowed) list.add((icon: '🐕', label: 'Haustiere'));
    if (wheelchairAccessible) list.add((icon: '♿', label: 'Barrierefrei'));
    return list;
  }

  bool get hasAny =>
      wifi ||
      parking ||
      breakfast ||
      restaurant ||
      pool ||
      spa ||
      airConditioning ||
      petsAllowed ||
      wheelchairAccessible;
}

class HotelSuggestion {
  final String id;
  final String? placeId;
  final String name;
  final LatLng location;
  final HotelType type;
  final int? stars;
  final String? website;
  final String? phone;
  final String? email;
  final String? address;
  final double distanceKm;
  final HotelAmenities amenities;
  final String? checkInTime;
  final String? checkOutTime;
  final String? description;
  final double? rating;
  final int? reviewCount;
  final List<String> highlights;
  final String source;
  final String? bookingUrl;
  final String dataQuality;

  const HotelSuggestion({
    required this.id,
    this.placeId,
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
    this.rating,
    this.reviewCount,
    this.highlights = const [],
    this.source = 'unknown',
    this.bookingUrl,
    this.dataQuality = 'limited',
  });

  HotelSuggestion copyWith({
    String? id,
    String? placeId,
    String? name,
    LatLng? location,
    HotelType? type,
    int? stars,
    String? website,
    String? phone,
    String? email,
    String? address,
    double? distanceKm,
    HotelAmenities? amenities,
    String? checkInTime,
    String? checkOutTime,
    String? description,
    double? rating,
    int? reviewCount,
    List<String>? highlights,
    String? source,
    String? bookingUrl,
    String? dataQuality,
  }) {
    return HotelSuggestion(
      id: id ?? this.id,
      placeId: placeId ?? this.placeId,
      name: name ?? this.name,
      location: location ?? this.location,
      type: type ?? this.type,
      stars: stars ?? this.stars,
      website: website ?? this.website,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      distanceKm: distanceKm ?? this.distanceKm,
      amenities: amenities ?? this.amenities,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      description: description ?? this.description,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      highlights: highlights ?? this.highlights,
      source: source ?? this.source,
      bookingUrl: bookingUrl ?? this.bookingUrl,
      dataQuality: dataQuality ?? this.dataQuality,
    );
  }

  factory HotelSuggestion.fromJson(Map<String, dynamic> json) {
    return HotelSuggestion(
      id: json['id'] as String,
      placeId: json['placeId'] as String?,
      name: json['name'] as String,
      location: LatLng(
        (json['lat'] as num).toDouble(),
        (json['lng'] as num).toDouble(),
      ),
      type: HotelType.values.firstWhere(
        (t) => t.name == (json['type'] as String?),
        orElse: () => HotelType.hotel,
      ),
      stars: (json['stars'] as num?)?.toInt(),
      website: json['website'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      distanceKm: (json['distanceKm'] as num).toDouble(),
      amenities: HotelAmenities.fromMap(
        json['amenities'] as Map<String, dynamic>?,
      ),
      checkInTime: json['checkInTime'] as String?,
      checkOutTime: json['checkOutTime'] as String?,
      description: json['description'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      reviewCount: (json['reviewCount'] as num?)?.toInt(),
      highlights: ((json['highlights'] as List?) ?? const [])
          .whereType<String>()
          .toList(),
      source: (json['source'] as String?) ?? 'unknown',
      bookingUrl: json['bookingUrl'] as String?,
      dataQuality: (json['dataQuality'] as String?) ?? 'limited',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'placeId': placeId,
      'name': name,
      'lat': location.latitude,
      'lng': location.longitude,
      'type': type.name,
      'stars': stars,
      'website': website,
      'phone': phone,
      'email': email,
      'address': address,
      'distanceKm': distanceKm,
      'amenities': amenities.toJson(),
      'checkInTime': checkInTime,
      'checkOutTime': checkOutTime,
      'description': description,
      'rating': rating,
      'reviewCount': reviewCount,
      'highlights': highlights,
      'source': source,
      'bookingUrl': bookingUrl,
      'dataQuality': dataQuality,
    };
  }

  String get formattedDistance => '${distanceKm.toStringAsFixed(1)} km';
  bool get hasContactInfo => website != null || phone != null || email != null;
  String get starsDisplay => stars == null ? '' : '⭐' * stars!;
  String get typeDisplay => '${type.icon} ${type.label}';
  bool get hasEnoughReviews =>
      reviewCount == null || reviewCount == 0 || reviewCount! >= 10;

  String? get checkInOutDisplay {
    if (checkInTime == null && checkOutTime == null) return null;
    final parts = <String>[];
    if (checkInTime != null) parts.add('Check-in: $checkInTime');
    if (checkOutTime != null) parts.add('Check-out: $checkOutTime');
    return parts.join(' · ');
  }

  String getBookingUrl({
    required DateTime checkIn,
    DateTime? checkOut,
  }) {
    if (bookingUrl != null && bookingUrl!.isNotEmpty) {
      return bookingUrl!;
    }

    final checkout = checkOut ?? checkIn.add(const Duration(days: 1));
    String formatDate(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final encodedName = Uri.encodeComponent(name);

    return 'https://www.booking.com/searchresults.html'
        '?ss=$encodedName'
        '&checkin=${formatDate(checkIn)}'
        '&checkout=${formatDate(checkout)}'
        '&latitude=${location.latitude}'
        '&longitude=${location.longitude}'
        '&radius=1';
  }

  String get googleMapsUrl =>
      'https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}';
}

class HotelSearchException implements Exception {
  final String message;
  HotelSearchException(this.message);

  @override
  String toString() => 'HotelSearchException: $message';
}

@riverpod
HotelService hotelService(HotelServiceRef ref) {
  return HotelService();
}
