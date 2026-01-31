import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/traffic.dart';
import '../../core/constants/api_keys.dart';

part 'traffic_repo.g.dart';

/// Traffic Repository für Verkehrsdaten
/// Verwendet TomTom Traffic API (kostenloser Tier verfügbar)
class TrafficRepository {
  final Dio _dio;

  // TomTom API Basis-URL
  static const String _baseUrl = 'https://api.tomtom.com/traffic';

  TrafficRepository(this._dio);

  /// Lädt Verkehrsdaten für eine Route
  Future<RouteTraffic?> getTrafficForRoute(List<LatLng> routeCoordinates) async {
    if (routeCoordinates.length < 2) return null;

    final apiKey = ApiKeys.tomtomApiKey;
    if (apiKey.isEmpty) {
      // Fallback: Simulierte Daten wenn kein API-Key
      return _generateSimulatedTraffic(routeCoordinates);
    }

    try {
      // Vereinfache Route für API (max 50 Punkte)
      final simplifiedRoute = _simplifyRoute(routeCoordinates, 50);

      // Route-Points als String formatieren
      final points = simplifiedRoute
          .map((p) => '${p.latitude},${p.longitude}')
          .join(':');

      final response = await _dio.get(
        '$_baseUrl/services/4/flowSegmentData/relative0/10/json',
        queryParameters: {
          'key': apiKey,
          'point': points,
          'unit': 'KMPH',
        },
      );

      if (response.statusCode == 200) {
        return _parseTrafficResponse(response.data, routeCoordinates);
      }
    } catch (e) {
      debugPrint('[Traffic] API-Fehler: $e');
      // Fallback zu simulierten Daten
      return _generateSimulatedTraffic(routeCoordinates);
    }

    return null;
  }

  /// Lädt Verkehrsvorfälle in einem Bereich
  Future<List<TrafficIncident>> getIncidents({
    required LatLng southwest,
    required LatLng northeast,
  }) async {
    final apiKey = ApiKeys.tomtomApiKey;
    if (apiKey.isEmpty) {
      return _generateSimulatedIncidents(southwest, northeast);
    }

    try {
      final response = await _dio.get(
        '$_baseUrl/services/5/incidentDetails',
        queryParameters: {
          'key': apiKey,
          'bbox': '${southwest.longitude},${southwest.latitude},'
              '${northeast.longitude},${northeast.latitude}',
          'fields': '{incidents{type,geometry{coordinates},properties{iconCategory,magnitudeOfDelay,events{description}}}}',
          'language': 'de-DE',
        },
      );

      if (response.statusCode == 200) {
        return _parseIncidentsResponse(response.data);
      }
    } catch (e) {
      debugPrint('[Traffic] Incidents-Fehler: $e');
    }

    return [];
  }

  /// Berechnet alternative Route bei Stau
  Future<List<LatLng>?> getAlternativeRoute({
    required LatLng start,
    required LatLng end,
    required List<LatLng> avoidCoordinates,
  }) async {
    final apiKey = ApiKeys.tomtomApiKey;
    if (apiKey.isEmpty) return null;

    try {
      // Bereich zum Vermeiden
      final avoidArea = avoidCoordinates.isNotEmpty
          ? _createAvoidArea(avoidCoordinates)
          : '';

      final response = await _dio.get(
        'https://api.tomtom.com/routing/1/calculateRoute/'
        '${start.latitude},${start.longitude}:${end.latitude},${end.longitude}/json',
        queryParameters: {
          'key': apiKey,
          'traffic': 'true',
          'travelMode': 'car',
          'routeType': 'fastest',
          if (avoidArea.isNotEmpty) 'avoid': avoidArea,
          'maxAlternatives': 2,
        },
      );

      if (response.statusCode == 200) {
        final routes = response.data['routes'] as List?;
        if (routes != null && routes.length > 1) {
          // Nimm die zweitbeste Route (erste Alternative)
          final altRoute = routes[1];
          final legs = altRoute['legs'] as List?;
          if (legs != null && legs.isNotEmpty) {
            final points = legs[0]['points'] as List?;
            if (points != null) {
              return points
                  .map((p) => LatLng(p['latitude'] as double, p['longitude'] as double))
                  .toList();
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[Traffic] Alternative Route Fehler: $e');
    }

    return null;
  }

  /// Parst TomTom Traffic Response
  RouteTraffic _parseTrafficResponse(
    Map<String, dynamic> data,
    List<LatLng> routeCoordinates,
  ) {
    final segments = <TrafficSegment>[];
    double totalDelay = 0;
    double totalSpeed = 0;

    final flowData = data['flowSegmentData'];
    if (flowData != null) {
      final currentSpeed = (flowData['currentSpeed'] as num?)?.toDouble() ?? 50;
      final freeFlowSpeed = (flowData['freeFlowSpeed'] as num?)?.toDouble() ?? 50;

      // Berechne Verzögerung
      final speedRatio = currentSpeed / freeFlowSpeed;
      final condition = _getConditionFromSpeedRatio(speedRatio);

      segments.add(TrafficSegment(
        coordinates: routeCoordinates,
        condition: condition,
        speedKmh: currentSpeed,
        freeFlowSpeedKmh: freeFlowSpeed,
        delaySeconds: _calculateDelay(routeCoordinates, currentSpeed, freeFlowSpeed),
        lengthKm: _calculateRouteLength(routeCoordinates),
      ));

      totalSpeed = currentSpeed;
      totalDelay = segments.first.delaySeconds / 60;
    }

    return RouteTraffic(
      segments: segments,
      totalDelayMinutes: totalDelay,
      averageSpeedKmh: totalSpeed,
      overallCondition: segments.isNotEmpty
          ? segments.first.condition
          : TrafficCondition.free,
      lastUpdated: DateTime.now(),
    );
  }

  /// Parst Incidents Response
  List<TrafficIncident> _parseIncidentsResponse(Map<String, dynamic> data) {
    final incidents = <TrafficIncident>[];

    final incidentsList = data['incidents'] as List?;
    if (incidentsList == null) return incidents;

    for (final incident in incidentsList) {
      try {
        final geometry = incident['geometry'];
        final coords = geometry?['coordinates'];
        if (coords == null) continue;

        final properties = incident['properties'] ?? {};
        final events = properties['events'] as List? ?? [];
        final description = events.isNotEmpty
            ? events.first['description'] ?? 'Verkehrsstörung'
            : 'Verkehrsstörung';

        incidents.add(TrafficIncident(
          id: incident['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
          type: _mapIncidentType(properties['iconCategory']),
          description: description,
          location: LatLng(coords[1] as double, coords[0] as double),
          severity: (properties['magnitudeOfDelay'] as num?)?.toDouble() ?? 0.5,
        ));
      } catch (e) {
        debugPrint('[Traffic] Incident parse error: $e');
      }
    }

    return incidents;
  }

  /// Generiert simulierte Verkehrsdaten (wenn kein API-Key)
  RouteTraffic _generateSimulatedTraffic(List<LatLng> routeCoordinates) {
    // Simuliere realistischen Verkehr basierend auf Tageszeit
    final hour = DateTime.now().hour;
    final isRushHour = (hour >= 7 && hour <= 9) || (hour >= 16 && hour <= 19);

    final condition = isRushHour
        ? TrafficCondition.moderate
        : TrafficCondition.free;

    final speedKmh = isRushHour ? 45.0 : 80.0;
    final freeFlowSpeed = 80.0;

    return RouteTraffic(
      segments: [
        TrafficSegment(
          coordinates: routeCoordinates,
          condition: condition,
          speedKmh: speedKmh,
          freeFlowSpeedKmh: freeFlowSpeed,
          delaySeconds: isRushHour ? 600 : 0,
          lengthKm: _calculateRouteLength(routeCoordinates),
        ),
      ],
      totalDelayMinutes: isRushHour ? 10 : 0,
      averageSpeedKmh: speedKmh,
      overallCondition: condition,
      lastUpdated: DateTime.now(),
    );
  }

  /// Generiert simulierte Vorfälle
  List<TrafficIncident> _generateSimulatedIncidents(LatLng sw, LatLng ne) {
    // Keine simulierten Vorfälle zurückgeben
    return [];
  }

  TrafficCondition _getConditionFromSpeedRatio(double ratio) {
    if (ratio >= 0.9) return TrafficCondition.free;
    if (ratio >= 0.7) return TrafficCondition.light;
    if (ratio >= 0.5) return TrafficCondition.moderate;
    if (ratio >= 0.25) return TrafficCondition.heavy;
    return TrafficCondition.blocked;
  }

  String _mapIncidentType(dynamic iconCategory) {
    switch (iconCategory) {
      case 1: case 2: case 3: return 'accident';
      case 6: case 7: return 'construction';
      case 8: case 9: return 'roadClosed';
      case 10: case 11: return 'event';
      default: return 'unknown';
    }
  }

  double _calculateDelay(List<LatLng> coords, double currentSpeed, double freeFlowSpeed) {
    if (currentSpeed >= freeFlowSpeed) return 0;
    final length = _calculateRouteLength(coords);
    final normalTime = (length / freeFlowSpeed) * 3600; // Sekunden
    final actualTime = (length / currentSpeed) * 3600;
    return actualTime - normalTime;
  }

  double _calculateRouteLength(List<LatLng> coords) {
    const distance = Distance();
    double total = 0;
    for (int i = 0; i < coords.length - 1; i++) {
      total += distance.as(LengthUnit.Kilometer, coords[i], coords[i + 1]);
    }
    return total;
  }

  List<LatLng> _simplifyRoute(List<LatLng> route, int maxPoints) {
    if (route.length <= maxPoints) return route;
    final step = route.length ~/ maxPoints;
    return [
      for (int i = 0; i < route.length; i += step) route[i],
      route.last,
    ];
  }

  String _createAvoidArea(List<LatLng> coords) {
    if (coords.isEmpty) return '';
    // Erstelle Bounding Box um zu vermeidende Punkte
    final lats = coords.map((c) => c.latitude);
    final lngs = coords.map((c) => c.longitude);
    return 'bbox:${lngs.reduce((a, b) => a < b ? a : b)},'
        '${lats.reduce((a, b) => a < b ? a : b)},'
        '${lngs.reduce((a, b) => a > b ? a : b)},'
        '${lats.reduce((a, b) => a > b ? a : b)}';
  }
}

/// Traffic Repository Provider
@riverpod
TrafficRepository trafficRepository(TrafficRepositoryRef ref) {
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));
  return TrafficRepository(dio);
}
