import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:travel_planner/l10n/app_localizations.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/utils/geo_utils.dart';
import '../../core/utils/navigation_instruction_generator.dart';
import '../models/navigation_step.dart';
import '../models/route.dart';

part 'routing_repo.g.dart';

/// Repository fÃ¼r Routenberechnung via OSRM und OpenRouteService
/// Ãœbernommen von MapAB js/services/routing.js und routing-ors.js
class RoutingRepository {
  final Dio _dio;
  final String? _orsApiKey;
  static const int _maxWaypointCount = 90;

  RoutingRepository({
    Dio? dio,
    String? orsApiKey,
  })  : _dio = dio ?? ApiConfig.createDio(profile: DioProfile.routing),
        _orsApiKey = orsApiKey;

  /// Berechnet schnelle Route via OSRM
  Future<AppRoute> calculateFastRoute({
    required LatLng start,
    required LatLng end,
    List<LatLng>? waypoints,
    required String startAddress,
    required String endAddress,
  }) async {
    final sanitizedWaypoints = _sanitizeWaypoints(
      start: start,
      end: end,
      waypoints: waypoints ?? const [],
    );
    final limitedWaypoints = sanitizedWaypoints.length > _maxWaypointCount
        ? _downsampleWaypoints(sanitizedWaypoints, _maxWaypointCount)
        : sanitizedWaypoints;

    try {
      return await _requestFastRoute(
        start: start,
        end: end,
        startAddress: startAddress,
        endAddress: endAddress,
        waypoints: limitedWaypoints,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 400 && limitedWaypoints.isNotEmpty) {
        debugPrint(
          '[Routing] OSRM 400 mit ${limitedWaypoints.length} Waypoints. '
          'Fallback auf segmentweise Berechnung.',
        );
        try {
          return await _calculateFastRouteBySegments(
            start: start,
            end: end,
            waypoints: limitedWaypoints,
            startAddress: startAddress,
            endAddress: endAddress,
          );
        } on DioException catch (segmentError) {
          throw RoutingException(
            'Routenberechnung fehlgeschlagen (segmentierter Fallback): '
            '${_extractDioError(segmentError)}',
          );
        }
      }

      throw RoutingException(
        'Routenberechnung fehlgeschlagen: ${_extractDioError(e)}',
      );
    }
  }

  Future<AppRoute> _requestFastRoute({
    required LatLng start,
    required LatLng end,
    required List<LatLng> waypoints,
    required String startAddress,
    required String endAddress,
  }) async {
    final coords = <String>[
      '${start.longitude},${start.latitude}',
      ...waypoints.map((wp) => '${wp.longitude},${wp.latitude}'),
      '${end.longitude},${end.latitude}',
    ];

    final url =
        '${ApiEndpoints.osrmRoute}/${coords.join(';')}?overview=full&geometries=geojson';

    final response = await _dio.get(url);

    if (response.data['code'] != 'Ok') {
      throw RoutingException(
        'OSRM Fehler: ${response.data['message'] ?? 'Unbekannt'}',
      );
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
      waypoints: waypoints,
      calculatedAt: DateTime.now(),
    );
  }

  Future<AppRoute> _calculateFastRouteBySegments({
    required LatLng start,
    required LatLng end,
    required List<LatLng> waypoints,
    required String startAddress,
    required String endAddress,
  }) async {
    final points = <LatLng>[start, ...waypoints, end];
    final mergedCoordinates = <LatLng>[];
    var totalDistanceKm = 0.0;
    var totalDurationMinutes = 0;

    for (var i = 0; i < points.length - 1; i++) {
      final leg = await _requestFastRoute(
        start: points[i],
        end: points[i + 1],
        waypoints: const [],
        startAddress: '',
        endAddress: '',
      );

      if (mergedCoordinates.isEmpty) {
        mergedCoordinates.addAll(leg.coordinates);
      } else {
        mergedCoordinates.addAll(leg.coordinates.skip(1));
      }

      totalDistanceKm += leg.distanceKm;
      totalDurationMinutes += leg.durationMinutes;
    }

    return AppRoute(
      start: start,
      end: end,
      startAddress: startAddress,
      endAddress: endAddress,
      coordinates: mergedCoordinates,
      distanceKm: totalDistanceKm,
      durationMinutes: totalDurationMinutes,
      type: RouteType.fast,
      waypoints: waypoints,
      calculatedAt: DateTime.now(),
    );
  }

  List<LatLng> _sanitizeWaypoints({
    required LatLng start,
    required LatLng end,
    required List<LatLng> waypoints,
  }) {
    final cleaned = <LatLng>[];
    LatLng previous = start;

    for (final wp in waypoints) {
      if (!_isValidLatLng(wp)) continue;
      if (_isNearSamePoint(previous, wp)) continue;
      if (_isNearSamePoint(end, wp)) continue;
      cleaned.add(wp);
      previous = wp;
    }

    return cleaned;
  }

  List<LatLng> _downsampleWaypoints(List<LatLng> waypoints, int maxCount) {
    if (waypoints.length <= maxCount) return waypoints;
    if (maxCount <= 1) return [waypoints.first];

    final reduced = <LatLng>[];
    final step = (waypoints.length - 1) / (maxCount - 1);
    for (int i = 0; i < maxCount; i++) {
      final index = (i * step).round().clamp(0, waypoints.length - 1);
      reduced.add(waypoints[index]);
    }
    return reduced;
  }

  bool _isValidLatLng(LatLng point) {
    return point.latitude.isFinite &&
        point.longitude.isFinite &&
        point.latitude >= -90 &&
        point.latitude <= 90 &&
        point.longitude >= -180 &&
        point.longitude <= 180;
  }

  bool _isNearSamePoint(LatLng a, LatLng b, {double thresholdKm = 0.05}) {
    return GeoUtils.haversineDistance(a, b) <= thresholdKm;
  }

  String _extractDioError(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    String? serverMessage;

    if (data is Map<String, dynamic>) {
      serverMessage = data['message']?.toString() ?? data['error']?.toString();
    } else if (data is String && data.trim().isNotEmpty) {
      serverMessage = data;
    }

    return [
      if (status != null) 'HTTP $status',
      if (serverMessage != null && serverMessage.isNotEmpty) serverMessage,
      if (e.message != null && e.message!.isNotEmpty) e.message!,
    ].join(' - ');
  }

  /// Berechnet Navigationsroute via OSRM mit Abbiegehinweisen
  /// Gibt NavigationRoute mit Steps und ManÃ¶vern zurÃ¼ck
  Future<NavigationRoute> calculateNavigationRoute({
    required LatLng start,
    required LatLng end,
    List<LatLng>? waypoints,
    required String startAddress,
    required String endAddress,
    required AppLocalizations l10n,
  }) async {
    // Koordinaten fÃ¼r OSRM vorbereiten (lng,lat Format)
    final coords = <String>[];
    coords.add('${start.longitude},${start.latitude}');

    if (waypoints != null) {
      for (final wp in waypoints) {
        coords.add('${wp.longitude},${wp.latitude}');
      }
    }

    coords.add('${end.longitude},${end.latitude}');

    final url = '${ApiEndpoints.osrmRoute}/${coords.join(';')}'
        '?overview=full&geometries=geojson&steps=true&annotations=distance,duration';

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

      // Legs und Steps parsen
      final legsData = route['legs'] as List;
      final legs = <NavigationLeg>[];

      for (final legData in legsData) {
        final stepsData = legData['steps'] as List? ?? [];
        final steps = <NavigationStep>[];

        for (final stepData in stepsData) {
          final maneuver = stepData['maneuver'] as Map<String, dynamic>? ?? {};
          final location = maneuver['location'] as List?;
          final stepGeometry = stepData['geometry'];

          // Step-Polyline parsen
          List<LatLng> stepCoords = [];
          if (stepGeometry != null && stepGeometry['coordinates'] != null) {
            stepCoords = (stepGeometry['coordinates'] as List)
                .map((c) => LatLng(c[1].toDouble(), c[0].toDouble()))
                .toList();
          }

          final type =
              ManeuverType.fromOsrm(maneuver['type']?.toString() ?? 'unknown');
          final modifier =
              ManeuverModifier.fromOsrm(maneuver['modifier']?.toString());
          final streetName = stepData['name']?.toString() ?? '';
          final roundaboutExit = maneuver['exit'] as int?;

          // Lokalisierte Instruktion generieren
          final instruction = NavigationInstructionGenerator.generate(
            type: type,
            modifier: modifier,
            streetName: streetName,
            l10n: l10n,
            roundaboutExit: roundaboutExit,
          );

          steps.add(NavigationStep(
            type: type,
            modifier: modifier,
            location: location != null && location.length >= 2
                ? LatLng(location[1].toDouble(), location[0].toDouble())
                : start,
            distanceMeters: (stepData['distance'] as num?)?.toDouble() ?? 0,
            durationSeconds: (stepData['duration'] as num?)?.toDouble() ?? 0,
            streetName: streetName,
            instruction: instruction,
            bearingBefore: (maneuver['bearing_before'] as num?)?.toInt() ?? 0,
            bearingAfter: (maneuver['bearing_after'] as num?)?.toInt() ?? 0,
            geometry: stepCoords,
            roundaboutExit: roundaboutExit,
          ));
        }

        legs.add(NavigationLeg(
          steps: steps,
          distanceMeters: (legData['distance'] as num?)?.toDouble() ?? 0,
          durationSeconds: (legData['duration'] as num?)?.toDouble() ?? 0,
          summary: legData['summary']?.toString() ?? '',
        ));
      }

      final baseRoute = AppRoute(
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

      debugPrint('[Navigation] Route berechnet: ${legs.length} Legs, '
          '${legs.fold<int>(0, (sum, l) => sum + l.steps.length)} Steps');

      return NavigationRoute(
        baseRoute: baseRoute,
        legs: legs,
      );
    } on DioException catch (e) {
      throw RoutingException('Navigationsroute fehlgeschlagen: ${e.message}');
    }
  }

  /// Berechnet landschaftliche Route via OpenRouteService
  /// Vermeidet Autobahnen fÃ¼r schÃ¶nere Strecken
  Future<AppRoute> calculateScenicRoute({
    required LatLng start,
    required LatLng end,
    List<LatLng>? waypoints,
    required String startAddress,
    required String endAddress,
  }) async {
    if (_orsApiKey == null || _orsApiKey!.isEmpty) {
      throw RoutingException('OpenRouteService API-Key nicht konfiguriert. '
          'Registrieren Sie sich kostenlos unter https://openrouteservice.org');
    }

    // Koordinaten fÃ¼r ORS vorbereiten
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
        throw RoutingException('ORS API-Key ungÃ¼ltig oder Limit erreicht');
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

/// Riverpod Provider fÃ¼r RoutingRepository
@riverpod
RoutingRepository routingRepository(RoutingRepositoryRef ref) {
  // ORS API-Key wird via --dart-define=ORS_API_KEY=... bereitgestellt
  const orsApiKey = String.fromEnvironment('ORS_API_KEY', defaultValue: '');
  return RoutingRepository(orsApiKey: orsApiKey.isNotEmpty ? orsApiKey : null);
}
