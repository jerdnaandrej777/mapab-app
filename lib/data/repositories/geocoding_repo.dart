import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/constants/api_endpoints.dart';
import '../models/route.dart';

part 'geocoding_repo.g.dart';

/// Repository für Geocoding-Operationen via Nominatim
/// Übernommen von MapAB js/services/geocoding.js
class GeocodingRepository {
  final Dio _dio;

  GeocodingRepository({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              headers: {'User-Agent': ApiConfig.userAgent},
              connectTimeout: const Duration(milliseconds: ApiConfig.defaultTimeout),
              receiveTimeout: const Duration(milliseconds: ApiConfig.defaultTimeout),
            ));

  /// Geocoding: Adresse → Koordinaten
  /// Gibt Liste von Ergebnissen zurück
  Future<List<GeocodingResult>> geocode(
    String query, {
    int limit = 5,
    String? countryCode,
  }) async {
    if (query.trim().isEmpty) return [];

    try {
      final response = await _dio.get(
        ApiEndpoints.nominatimSearch,
        queryParameters: {
          'q': query,
          'format': 'json',
          'addressdetails': 1,
          'limit': limit,
          'accept-language': 'de',
          if (countryCode != null) 'countrycodes': countryCode,
        },
      );

      if (response.data is! List) return [];

      return (response.data as List)
          .map((item) => _parseGeocodingResult(item))
          .toList();
    } on DioException catch (e) {
      throw GeocodingException('Geocoding fehlgeschlagen: ${e.message}');
    }
  }

  /// Reverse Geocoding: Koordinaten → Adresse
  Future<GeocodingResult?> reverseGeocode(LatLng location) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.nominatimReverse,
        queryParameters: {
          'lat': location.latitude,
          'lon': location.longitude,
          'format': 'json',
          'addressdetails': 1,
          'accept-language': 'de',
        },
      );

      if (response.data == null || response.data['error'] != null) {
        return null;
      }

      return _parseGeocodingResult(response.data);
    } on DioException catch (e) {
      throw GeocodingException('Reverse Geocoding fehlgeschlagen: ${e.message}');
    }
  }

  /// Autocomplete für Sucheingabe
  /// Verwendet Nominatim Search mit dedupe
  Future<List<AutocompleteSuggestion>> autocomplete(
    String query, {
    int limit = 5,
  }) async {
    if (query.trim().length < 2) return [];

    try {
      final response = await _dio.get(
        ApiEndpoints.nominatimSearch,
        queryParameters: {
          'q': query,
          'format': 'json',
          'addressdetails': 1,
          'limit': limit,
          'dedupe': 1,
          'accept-language': 'de',
        },
      );

      if (response.data is! List) return [];

      return (response.data as List)
          .map((item) => AutocompleteSuggestion(
                displayName: item['display_name'] ?? '',
                location: LatLng(
                  double.tryParse(item['lat']?.toString() ?? '') ?? 0,
                  double.tryParse(item['lon']?.toString() ?? '') ?? 0,
                ),
                icon: _getIconForType(item['type']),
                placeId: int.tryParse(item['place_id']?.toString() ?? ''),
              ))
          .toList();
    } on DioException {
      return [];
    }
  }

  /// Parst Nominatim-Antwort zu GeocodingResult
  GeocodingResult _parseGeocodingResult(Map<String, dynamic> data) {
    final address = data['address'] as Map<String, dynamic>?;

    // Kurzname ermitteln (Stadt > Ort > County)
    String? shortName;
    if (address != null) {
      shortName = address['city'] ??
          address['town'] ??
          address['village'] ??
          address['municipality'] ??
          address['county'];
    }

    return GeocodingResult(
      location: LatLng(
        double.tryParse(data['lat']?.toString() ?? '') ?? 0,
        double.tryParse(data['lon']?.toString() ?? '') ?? 0,
      ),
      displayName: data['display_name'] ?? '',
      shortName: shortName,
      type: data['type'],
      boundingBox: (data['boundingbox'] as List?)
          ?.map((e) => double.tryParse(e.toString()) ?? 0)
          .toList(),
      placeId: int.tryParse(data['place_id']?.toString() ?? ''),
    );
  }

  /// Icon für Typ ermitteln
  String _getIconForType(String? type) {
    switch (type) {
      case 'city':
      case 'town':
      case 'village':
        return '🏙️';
      case 'administrative':
        return '📍';
      case 'attraction':
      case 'tourism':
        return '🎡';
      case 'natural':
        return '🌲';
      case 'railway':
      case 'station':
        return '🚉';
      case 'aerodrome':
        return '✈️';
      default:
        return '📍';
    }
  }
}

/// Geocoding Exception
class GeocodingException implements Exception {
  final String message;
  GeocodingException(this.message);

  @override
  String toString() => 'GeocodingException: $message';
}

/// Riverpod Provider für GeocodingRepository
@riverpod
GeocodingRepository geocodingRepository(GeocodingRepositoryRef ref) {
  return GeocodingRepository();
}
