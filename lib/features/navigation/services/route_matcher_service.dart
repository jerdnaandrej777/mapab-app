import 'dart:math';
import 'package:latlong2/latlong.dart';

/// Ergebnis eines Route-Matching-Vorgangs
class RouteMatchResult {
  /// Nächster Punkt auf der Route-Polyline
  final LatLng snappedPosition;

  /// Index des nächsten Punktes in der Koordinatenliste
  final int nearestIndex;

  /// Abstand vom GPS-Punkt zur Route in Metern
  final double distanceFromRouteMeters;

  /// Fortschritt auf der Route (0.0 = Start, 1.0 = Ziel)
  final double progress;

  const RouteMatchResult({
    required this.snappedPosition,
    required this.nearestIndex,
    required this.distanceFromRouteMeters,
    required this.progress,
  });

  /// Ist der Nutzer von der Route abgewichen
  bool isOffRoute(double thresholdMeters) =>
      distanceFromRouteMeters > thresholdMeters;
}

/// Service für Route-Matching: GPS-Position auf Route-Polyline snappen
class RouteMatcherService {
  /// Haversine-Konstante: Erdradius in Metern
  static const double _earthRadius = 6371000;

  /// Snappt eine GPS-Position auf die nächste Position der Route-Polyline
  ///
  /// [position] - Aktuelle GPS-Position
  /// [routeCoordinates] - Polyline der Route
  /// [searchStartIndex] - Optionaler Startindex für die Suche (Performance)
  /// [searchWindow] - Suchfenster um searchStartIndex (Default: gesamte Route)
  RouteMatchResult snapToRoute(
    LatLng position,
    List<LatLng> routeCoordinates, {
    int? searchStartIndex,
    int? searchWindow,
  }) {
    if (routeCoordinates.isEmpty) {
      return RouteMatchResult(
        snappedPosition: position,
        nearestIndex: 0,
        distanceFromRouteMeters: 0,
        progress: 0,
      );
    }

    // Suchbereich bestimmen
    int startIdx = 0;
    int endIdx = routeCoordinates.length;

    if (searchStartIndex != null && searchWindow != null) {
      startIdx = max(0, searchStartIndex - searchWindow);
      endIdx = min(routeCoordinates.length, searchStartIndex + searchWindow);
    }

    // Nächsten Punkt auf Polyline finden
    int bestIndex = startIdx;
    double bestDistance = double.infinity;
    LatLng bestPoint = routeCoordinates[startIdx];

    for (int i = startIdx; i < endIdx; i++) {
      // Punkt-zu-Segment-Distanz prüfen (für genaueres Snapping)
      if (i < endIdx - 1) {
        final projected = _projectOntoSegment(
          position,
          routeCoordinates[i],
          routeCoordinates[i + 1],
        );
        final dist = _haversineDistance(position, projected);
        if (dist < bestDistance) {
          bestDistance = dist;
          bestPoint = projected;
          bestIndex = i;
        }
      } else {
        final dist = _haversineDistance(position, routeCoordinates[i]);
        if (dist < bestDistance) {
          bestDistance = dist;
          bestPoint = routeCoordinates[i];
          bestIndex = i;
        }
      }
    }

    final progress = routeCoordinates.length > 1
        ? bestIndex / (routeCoordinates.length - 1)
        : 0.0;

    return RouteMatchResult(
      snappedPosition: bestPoint,
      nearestIndex: bestIndex,
      distanceFromRouteMeters: bestDistance,
      progress: progress,
    );
  }

  /// Prüft ob Position von der Route abgewichen ist
  bool isOffRoute(
    LatLng position,
    List<LatLng> routeCoordinates, {
    double thresholdMeters = 75,
    int? lastKnownIndex,
  }) {
    final result = snapToRoute(
      position,
      routeCoordinates,
      searchStartIndex: lastKnownIndex,
      searchWindow: 50,
    );
    return result.distanceFromRouteMeters > thresholdMeters;
  }

  /// Berechnet die Distanz entlang der Route zwischen zwei Indizes in Metern
  double getDistanceAlongRoute(
    List<LatLng> coordinates,
    int fromIndex,
    int toIndex,
  ) {
    if (fromIndex >= toIndex || coordinates.isEmpty) return 0;

    final from = fromIndex.clamp(0, coordinates.length - 1);
    final to = toIndex.clamp(0, coordinates.length - 1);

    double total = 0;
    for (int i = from; i < to; i++) {
      total += _haversineDistance(coordinates[i], coordinates[i + 1]);
    }
    return total;
  }

  /// Berechnet verbleibende Distanz ab Index bis Ende der Route in Metern
  double getRemainingDistance(List<LatLng> coordinates, int fromIndex) {
    return getDistanceAlongRoute(
        coordinates, fromIndex, coordinates.length - 1);
  }

  /// Findet den Index des nächsten Punktes in einer Liste zu einer Position
  int findNearestIndex(List<LatLng> coords, LatLng target) {
    int bestIdx = 0;
    double bestDist = double.infinity;
    for (int i = 0; i < coords.length; i++) {
      final dist = _haversineDistanceFast(coords[i], target);
      if (dist < bestDist) {
        bestDist = dist;
        bestIdx = i;
      }
    }
    return bestIdx;
  }

  /// Berechnet den Bearing (Kompassrichtung) zwischen zwei Punkten
  double calculateBearing(LatLng from, LatLng to) {
    final dLng = _toRadians(to.longitude - from.longitude);
    final lat1 = _toRadians(from.latitude);
    final lat2 = _toRadians(to.latitude);

    final y = sin(dLng) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLng);

    final bearing = atan2(y, x);
    return (_toDegrees(bearing) + 360) % 360;
  }

  /// Berechnet Haversine-Distanz zwischen zwei Punkten in Metern
  double distanceBetween(LatLng a, LatLng b) => _haversineDistance(a, b);

  // --- Private Helpers ---

  /// Projiziert einen Punkt auf das nächste Liniensegment
  LatLng _projectOntoSegment(LatLng point, LatLng segA, LatLng segB) {
    // Vereinfachte Projektion auf flacher Ebene (für kurze Distanzen ausreichend)
    final dx = segB.longitude - segA.longitude;
    final dy = segB.latitude - segA.latitude;

    if (dx == 0 && dy == 0) return segA;

    final t = ((point.longitude - segA.longitude) * dx +
            (point.latitude - segA.latitude) * dy) /
        (dx * dx + dy * dy);

    final clamped = t.clamp(0.0, 1.0);

    return LatLng(
      segA.latitude + clamped * dy,
      segA.longitude + clamped * dx,
    );
  }

  /// Haversine-Distanz in Metern
  double _haversineDistance(LatLng a, LatLng b) {
    final dLat = _toRadians(b.latitude - a.latitude);
    final dLng = _toRadians(b.longitude - a.longitude);

    final sinDLat = sin(dLat / 2);
    final sinDLng = sin(dLng / 2);

    final h = sinDLat * sinDLat +
        cos(_toRadians(a.latitude)) *
            cos(_toRadians(b.latitude)) *
            sinDLng *
            sinDLng;

    return 2 * _earthRadius * asin(sqrt(h));
  }

  /// Schnelle Distanzberechnung (quadriert, für Vergleiche)
  double _haversineDistanceFast(LatLng a, LatLng b) {
    final dLat = a.latitude - b.latitude;
    final dLng = a.longitude - b.longitude;
    return dLat * dLat + dLng * dLng;
  }

  double _toRadians(double degrees) => degrees * pi / 180;
  double _toDegrees(double radians) => radians * 180 / pi;
}
