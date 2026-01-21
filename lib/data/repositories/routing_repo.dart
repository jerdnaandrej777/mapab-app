import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/constants/api_endpoints.dart';
import '../models/route.dart';

part 'routing_repo.g.dart';

/// Repository für Routenberechnung via OSRM und OpenRouteService
/// Übernommen von MapAB js/services/routing.js und routing-ors.js
class RoutingRepository {
  final Dio _dio;
  final String? _orsApiKey;

  RoutingRepository({
    Dio? dio,
    String? orsApiKey,
  })  : _dio = dio ??
            Dio(BaseOptions(
              headers: {'User-Agent': ApiConfig.userAgent},
              connectTimeout: const Duration(milliseconds: ApiConfig.routingTimeout),
              receiveTimeout: const Duration(milliseconds: ApiConfig.routingTimeout),
            )),
        _orsApiKey = orsApiKey;

  /// Berechnet schnelle Route via OSRM
  Future<AppRoute> calculateFastRoute({
    required LatLng start,
    required LatLng end,
    List<LatLng>? waypoints,
    required String startAddress,
    required String endAddress,
  }) async {
    // Koordinaten für OSRM vorbereiten (lng,lat Format)
    final coords = <String>[];
    coords.add('${start.longitude},${start.latitude}');

    if (waypoints != null) {
      for (final wp in waypoints) {
        coords.add('${wp.longitude},${wp.latitude}');
      }
    }

    coords.add('${end.longitude},${end.latitude}');

    final url =
        '${ApiEndpoints.osrmRoute}/${coords.join(';')}?overview=full&geometries=geojson';

    try {
      final response = await _dio.get(url);

      if (response.data['code'] != 'Ok') {
        throw RoutingException(
            'OSRM Fehler: ${response.data['message'] ?? 'Unbekannt'}');
      }

      final route = response.data['routes'][0];
      final geometry = route['geometry'];
      final coordinates = (geometry['coordinates'] as List)
          .map((c) => LatLng(c[1].toDouble(), c[0].toDouble()))
          .toList();

      return AppRoute(
        start: start,
        end: end,
        startAddress: startAddress,
        endAddress: endAddress,
        coordinates: coordinates,
        distanceKm: route['distance'] / 1000,
        durationMinutes: (route['duration'] / 60).round(),
        type: RouteType.fast,
        waypoints: waypoints ?? [],
        calculatedAt: DateTime.now(),
      );
    } on DioException catch (e) {
      throw RoutingException('Routenberechnung fehlgeschlagen: ${e.message}');
    }
  }

  /// Berechnet landschaftliche Route via OpenRouteService
  /// Vermeidet Autobahnen für schönere Strecken
  Future<AppRoute> calculateScenicRoute({
    required LatLng start,
    required LatLng end,
    List<LatLng>? waypoints,
    required String startAddress,
    required String endAddress,
  }) async {
    if (_orsApiKey == null || _orsApiKey!.isEmpty) {
      throw RoutingException(
          'OpenRouteService API-Key nicht konfiguriert. '
          'Registrieren Sie sich kostenlos unter https://openrouteservice.org');
    }

    // Koordinaten für ORS vorbereiten
    final coords = <List<double>>[];
    coords.add([start.longitude, start.latitude]);

    if (waypoints != null) {
      for (final wp in waypoints) {
        coords.add([wp.longitude, wp.latitude]);
      }
    }

    coords.add([end.longitude, end.latitude]);

    try {
      final response = await _dio.post(
        ApiEndpoints.orsRoute,
        options: Options(
          headers: {
            'Authorization': _orsApiKey,
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'coordinates': coords,
          'options': {
            'avoid_features': ['highways'], // Autobahnen vermeiden
          },
          'geometry': true,
          'instructions': false,
        },
      );

      final route = response.data['routes'][0];
      final summary = route['summary'];

      // GeoJSON Koordinaten parsen
      final geometry = route['geometry'];
      List<LatLng> coordinates;

      if (geometry is String) {
        // Encoded Polyline dekodieren
        coordinates = _decodePolyline(geometry);
      } else {
        // GeoJSON Format
        coordinates = (geometry['coordinates'] as List)
            .map((c) => LatLng(c[1].toDouble(), c[0].toDouble()))
            .toList();
      }

      return AppRoute(
        start: start,
        end: end,
        startAddress: startAddress,
        endAddress: endAddress,
        coordinates: coordinates,
        distanceKm: summary['distance'] / 1000,
        durationMinutes: (summary['duration'] / 60).round(),
        type: RouteType.scenic,
        waypoints: waypoints ?? [],
        calculatedAt: DateTime.now(),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw RoutingException('ORS API-Key ungültig oder Limit erreicht');
      }
      throw RoutingException('Scenic-Route fehlgeschlagen: ${e.message}');
    }
  }

  /// Berechnet beide Routen parallel
  Future<RouteComparison> calculateBothRoutes({
    required LatLng start,
    required LatLng end,
    List<LatLng>? waypoints,
    required String startAddress,
    required String endAddress,
  }) async {
    final results = await Future.wait([
      calculateFastRoute(
        start: start,
        end: end,
        waypoints: waypoints,
        startAddress: startAddress,
        endAddress: endAddress,
      ),
      // Scenic nur wenn API-Key vorhanden
      if (_orsApiKey != null && _orsApiKey!.isNotEmpty)
        calculateScenicRoute(
          start: start,
          end: end,
          waypoints: waypoints,
          startAddress: startAddress,
          endAddress: endAddress,
        ),
    ]);

    return RouteComparison(
      fastRoute: results[0],
      scenicRoute: results.length > 1 ? results[1] : null,
      activeType: RouteType.fast,
    );
  }

  /// Dekodiert Google Encoded Polyline
  List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int shift = 0;
      int result = 0;

      // Latitude
      int b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      lat += ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));

      // Longitude
      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      lng += ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return points;
  }
}

/// Routing Exception
class RoutingException implements Exception {
  final String message;
  RoutingException(this.message);

  @override
  String toString() => 'RoutingException: $message';
}

/// Riverpod Provider für RoutingRepository
@riverpod
RoutingRepository routingRepository(RoutingRepositoryRef ref) {
  // TODO: API-Key aus Umgebungsvariable oder sicherem Speicher laden
  const orsApiKey = String.fromEnvironment('ORS_API_KEY', defaultValue: '');
  return RoutingRepository(orsApiKey: orsApiKey.isNotEmpty ? orsApiKey : null);
}
