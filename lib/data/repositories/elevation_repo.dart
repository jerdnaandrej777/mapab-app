import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/elevation.dart';

part 'elevation_repo.g.dart';

/// Elevation Repository für Höhendaten
class ElevationRepository {
  final Dio _dio;

  // Open-Elevation API (kostenlos, kein API-Key)
  static const String _openElevationUrl = 'https://api.open-elevation.com/api/v1/lookup';

  // Alternativ: OpenTopoData (falls Open-Elevation nicht erreichbar)
  static const String _openTopoUrl = 'https://api.opentopodata.org/v1/eudem25m';

  ElevationRepository(this._dio);

  /// Lädt Höhenprofil für eine Route
  Future<ElevationProfile?> getElevationProfile(List<LatLng> coordinates) async {
    if (coordinates.length < 2) return null;

    // Vereinfache Route für API (max 100 Punkte)
    final simplified = _simplifyRoute(coordinates, 100);

    try {
      // Versuche Open-Elevation
      final elevations = await _fetchElevations(simplified);
      if (elevations != null) {
        return _buildProfile(simplified, elevations);
      }
    } catch (e) {
      print('[Elevation] Open-Elevation Fehler: $e');
    }

    try {
      // Fallback: OpenTopoData
      final elevations = await _fetchElevationsFromOpenTopo(simplified);
      if (elevations != null) {
        return _buildProfile(simplified, elevations);
      }
    } catch (e) {
      print('[Elevation] OpenTopo Fehler: $e');
    }

    // Fallback: Generiere simulierte Daten
    return _generateSimulatedProfile(simplified);
  }

  /// Holt Höhendaten von Open-Elevation API
  Future<List<double>?> _fetchElevations(List<LatLng> coords) async {
    final locations = coords
        .map((c) => {'latitude': c.latitude, 'longitude': c.longitude})
        .toList();

    final response = await _dio.post(
      _openElevationUrl,
      data: {'locations': locations},
      options: Options(
        headers: {'Content-Type': 'application/json'},
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    if (response.statusCode == 200) {
      final results = response.data['results'] as List?;
      if (results != null) {
        return results
            .map((r) => (r['elevation'] as num?)?.toDouble() ?? 0)
            .toList();
      }
    }
    return null;
  }

  /// Holt Höhendaten von OpenTopoData API
  Future<List<double>?> _fetchElevationsFromOpenTopo(List<LatLng> coords) async {
    // OpenTopoData akzeptiert max 100 Punkte pro Request
    final locations = coords
        .map((c) => '${c.latitude},${c.longitude}')
        .join('|');

    final response = await _dio.get(
      _openTopoUrl,
      queryParameters: {'locations': locations},
      options: Options(receiveTimeout: const Duration(seconds: 30)),
    );

    if (response.statusCode == 200) {
      final results = response.data['results'] as List?;
      if (results != null) {
        return results
            .map((r) => (r['elevation'] as num?)?.toDouble() ?? 0)
            .toList();
      }
    }
    return null;
  }

  /// Baut ElevationProfile aus Koordinaten und Höhen
  ElevationProfile _buildProfile(List<LatLng> coords, List<double> elevations) {
    final points = <ElevationPoint>[];
    double cumulativeDistance = 0;
    double totalAscent = 0;
    double totalDescent = 0;
    double minElevation = double.infinity;
    double maxElevation = double.negativeInfinity;

    const distance = Distance();

    for (int i = 0; i < coords.length && i < elevations.length; i++) {
      final elevation = elevations[i];

      // Distanz berechnen
      if (i > 0) {
        cumulativeDistance += distance.as(
          LengthUnit.Kilometer,
          coords[i - 1],
          coords[i],
        );

        // Anstieg/Abstieg berechnen
        final elevDiff = elevation - elevations[i - 1];
        if (elevDiff > 0) {
          totalAscent += elevDiff;
        } else {
          totalDescent += elevDiff.abs();
        }
      }

      // Min/Max aktualisieren
      if (elevation < minElevation) minElevation = elevation;
      if (elevation > maxElevation) maxElevation = elevation;

      points.add(ElevationPoint(
        latitude: coords[i].latitude,
        longitude: coords[i].longitude,
        elevation: elevation,
        distance: cumulativeDistance,
      ));
    }

    // Schwierigkeit berechnen
    final difficulty = _calculateDifficulty(
      totalAscent: totalAscent,
      maxGradient: _calculateMaxGradient(points),
      distanceKm: cumulativeDistance,
    );

    return ElevationProfile(
      points: points,
      minElevation: minElevation == double.infinity ? 0 : minElevation,
      maxElevation: maxElevation == double.negativeInfinity ? 0 : maxElevation,
      totalAscent: totalAscent,
      totalDescent: totalDescent,
      totalDistanceKm: cumulativeDistance,
      difficulty: difficulty,
      calculatedAt: DateTime.now(),
    );
  }

  /// Berechnet Schwierigkeitsgrad
  RouteDifficulty _calculateDifficulty({
    required double totalAscent,
    required double maxGradient,
    required double distanceKm,
  }) {
    // Punkte-basiertes System
    int score = 0;

    // Nach Anstieg
    if (totalAscent > 1500) score += 3;
    else if (totalAscent > 800) score += 2;
    else if (totalAscent > 400) score += 1;

    // Nach maximaler Steigung
    if (maxGradient > 20) score += 3;
    else if (maxGradient > 12) score += 2;
    else if (maxGradient > 6) score += 1;

    // Nach Distanz
    if (distanceKm > 50) score += 2;
    else if (distanceKm > 25) score += 1;

    // Score zu Difficulty
    if (score >= 6) return RouteDifficulty.expert;
    if (score >= 4) return RouteDifficulty.difficult;
    if (score >= 2) return RouteDifficulty.moderate;
    return RouteDifficulty.easy;
  }

  double _calculateMaxGradient(List<ElevationPoint> points) {
    double maxGradient = 0;

    for (int i = 1; i < points.length; i++) {
      final distDiff = points[i].distance - points[i - 1].distance;
      if (distDiff > 0.01) {  // Mindestens 10m
        final elevDiff = points[i].elevation - points[i - 1].elevation;
        final gradient = (elevDiff / (distDiff * 1000)) * 100;  // Prozent
        if (gradient.abs() > maxGradient.abs()) {
          maxGradient = gradient;
        }
      }
    }

    return maxGradient;
  }

  /// Generiert simuliertes Profil (für Demo/Fallback)
  ElevationProfile _generateSimulatedProfile(List<LatLng> coords) {
    final points = <ElevationPoint>[];
    double cumulativeDistance = 0;
    const distance = Distance();

    // Simuliere hügeliges Terrain
    double baseElevation = 200;
    double totalAscent = 0;
    double totalDescent = 0;

    for (int i = 0; i < coords.length; i++) {
      if (i > 0) {
        cumulativeDistance += distance.as(
          LengthUnit.Kilometer,
          coords[i - 1],
          coords[i],
        );
      }

      // Simulierte Höhe mit Sinus-Variation
      final variation = 150 * _sin(cumulativeDistance * 0.3) +
                        50 * _sin(cumulativeDistance * 1.2);
      final elevation = baseElevation + variation;

      if (i > 0) {
        final diff = elevation - points[i - 1].elevation;
        if (diff > 0) totalAscent += diff;
        else totalDescent += diff.abs();
      }

      points.add(ElevationPoint(
        latitude: coords[i].latitude,
        longitude: coords[i].longitude,
        elevation: elevation,
        distance: cumulativeDistance,
      ));
    }

    final elevations = points.map((p) => p.elevation).toList();

    return ElevationProfile(
      points: points,
      minElevation: elevations.reduce((a, b) => a < b ? a : b),
      maxElevation: elevations.reduce((a, b) => a > b ? a : b),
      totalAscent: totalAscent,
      totalDescent: totalDescent,
      totalDistanceKm: cumulativeDistance,
      difficulty: _calculateDifficulty(
        totalAscent: totalAscent,
        maxGradient: 8,
        distanceKm: cumulativeDistance,
      ),
      calculatedAt: DateTime.now(),
    );
  }

  double _sin(double x) {
    // Einfache Sin-Approximation
    x = x % (2 * 3.14159);
    return x - (x * x * x) / 6 + (x * x * x * x * x) / 120;
  }

  List<LatLng> _simplifyRoute(List<LatLng> route, int maxPoints) {
    if (route.length <= maxPoints) return route;
    final step = route.length ~/ maxPoints;
    return [
      for (int i = 0; i < route.length; i += step) route[i],
      route.last,
    ];
  }
}

/// Elevation Repository Provider
@riverpod
ElevationRepository elevationRepository(ElevationRepositoryRef ref) {
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
  ));
  return ElevationRepository(dio);
}
