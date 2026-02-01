import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

/// Geo-Utilities für Distanzberechnungen
/// Übernommen von MapAB js/utils/geo.js
class GeoUtils {
  GeoUtils._();

  /// Haversine-Formel zur Berechnung der Distanz zwischen zwei Punkten
  /// Gibt die Distanz in Kilometern zurück
  static double haversineDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371; // Radius der Erde in km

    final double lat1Rad = _toRadians(point1.latitude);
    final double lat2Rad = _toRadians(point2.latitude);
    final double deltaLat = _toRadians(point2.latitude - point1.latitude);
    final double deltaLng = _toRadians(point2.longitude - point1.longitude);

    final double a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(deltaLng / 2) *
            math.sin(deltaLng / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  /// Konvertiert Grad in Radiant
  static double _toRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  /// Findet den nächsten Punkt auf einer Route zu einem gegebenen Punkt
  /// Gibt den Index des nächsten Segments und die minimale Distanz zurück
  static ({int segmentIndex, double distance, LatLng closestPoint})
      findClosestPointOnRoute(LatLng point, List<LatLng> routeCoords) {
    if (routeCoords.isEmpty) {
      throw ArgumentError('Route coordinates cannot be empty');
    }

    double minDistance = double.infinity;
    int closestSegment = 0;
    LatLng closestPoint = routeCoords.first;

    for (int i = 0; i < routeCoords.length - 1; i++) {
      final result = _closestPointOnSegment(
        point,
        routeCoords[i],
        routeCoords[i + 1],
      );

      if (result.distance < minDistance) {
        minDistance = result.distance;
        closestSegment = i;
        closestPoint = result.point;
      }
    }

    return (
      segmentIndex: closestSegment,
      distance: minDistance,
      closestPoint: closestPoint,
    );
  }

  /// Findet den nächsten Punkt auf einem Liniensegment
  static ({LatLng point, double distance}) _closestPointOnSegment(
    LatLng point,
    LatLng segStart,
    LatLng segEnd,
  ) {
    final double dx = segEnd.longitude - segStart.longitude;
    final double dy = segEnd.latitude - segStart.latitude;

    if (dx == 0 && dy == 0) {
      // Segment ist ein Punkt
      return (point: segStart, distance: haversineDistance(point, segStart));
    }

    // Parameter t für die Projektion auf die Linie
    double t = ((point.longitude - segStart.longitude) * dx +
            (point.latitude - segStart.latitude) * dy) /
        (dx * dx + dy * dy);

    // Auf Segment begrenzen
    t = t.clamp(0.0, 1.0);

    // Nächster Punkt auf dem Segment
    final closestPoint = LatLng(
      segStart.latitude + t * dy,
      segStart.longitude + t * dx,
    );

    return (point: closestPoint, distance: haversineDistance(point, closestPoint));
  }

  /// Berechnet die Position eines Punktes auf der Route (0 = Start, 1 = Ende)
  static double calculateRoutePosition(LatLng point, List<LatLng> routeCoords) {
    if (routeCoords.length < 2) return 0;

    final closest = findClosestPointOnRoute(point, routeCoords);

    // Distanz bis zum nächsten Segment
    double distanceToSegment = 0;
    for (int i = 0; i < closest.segmentIndex; i++) {
      distanceToSegment += haversineDistance(routeCoords[i], routeCoords[i + 1]);
    }

    // Plus Distanz innerhalb des Segments
    distanceToSegment +=
        haversineDistance(routeCoords[closest.segmentIndex], closest.closestPoint);

    // Gesamtlänge der Route
    double totalDistance = 0;
    for (int i = 0; i < routeCoords.length - 1; i++) {
      totalDistance += haversineDistance(routeCoords[i], routeCoords[i + 1]);
    }

    return totalDistance > 0 ? distanceToSegment / totalDistance : 0;
  }

  /// Berechnet die Gesamtlänge einer Route in km
  static double calculateRouteLength(List<LatLng> routeCoords) {
    if (routeCoords.length < 2) return 0;

    double totalDistance = 0;
    for (int i = 0; i < routeCoords.length - 1; i++) {
      totalDistance += haversineDistance(routeCoords[i], routeCoords[i + 1]);
    }
    return totalDistance;
  }

  /// Berechnet den Umweg-Faktor für einen POI
  /// Gibt die zusätzlichen Kilometer zurück, wenn man den POI besucht
  static double calculateDetour(
    LatLng poiLocation,
    List<LatLng> routeCoords,
  ) {
    final closest = findClosestPointOnRoute(poiLocation, routeCoords);

    // Umweg = 2x Distanz zum POI (hin und zurück)
    // Vereinfachte Berechnung - in der Praxis würde man OSRM nutzen
    return closest.distance * 2;
  }

  /// Berechnet den Mittelpunkt zwischen mehreren Koordinaten
  static LatLng calculateCentroid(List<LatLng> points) {
    if (points.isEmpty) {
      throw ArgumentError('Points list cannot be empty');
    }

    double totalLat = 0;
    double totalLng = 0;

    for (final point in points) {
      totalLat += point.latitude;
      totalLng += point.longitude;
    }

    return LatLng(
      totalLat / points.length,
      totalLng / points.length,
    );
  }

  /// Berechnet die Bounding Box für eine Liste von Koordinaten
  static ({LatLng southwest, LatLng northeast}) calculateBounds(
    List<LatLng> points,
  ) {
    if (points.isEmpty) {
      throw ArgumentError('Points list cannot be empty');
    }

    double minLat = double.infinity;
    double maxLat = double.negativeInfinity;
    double minLng = double.infinity;
    double maxLng = double.negativeInfinity;

    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    return (
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  /// Berechnet Bounding Box entlang einer Route mit Buffer in km
  /// Für Korridor-basierte POI-Suche (Start→Ziel mit Puffer)
  static ({LatLng southwest, LatLng northeast}) calculateBoundsWithBuffer(
    List<LatLng> coordinates,
    double bufferKm,
  ) {
    if (coordinates.isEmpty) {
      throw ArgumentError('Coordinates list cannot be empty');
    }

    final baseBounds = calculateBounds(coordinates);

    // Buffer in Grad umrechnen
    const latDegreeKm = 111.0;
    final midLat = (baseBounds.southwest.latitude + baseBounds.northeast.latitude) / 2;
    final lngDegreeKm = 111.0 * math.cos(midLat * math.pi / 180);

    final latBuffer = bufferKm / latDegreeKm;
    final lngBuffer = bufferKm / lngDegreeKm;

    return (
      southwest: LatLng(
        baseBounds.southwest.latitude - latBuffer,
        baseBounds.southwest.longitude - lngBuffer,
      ),
      northeast: LatLng(
        baseBounds.northeast.latitude + latBuffer,
        baseBounds.northeast.longitude + lngBuffer,
      ),
    );
  }

  /// Erweitert eine Bounding Box um einen Prozentsatz
  static ({LatLng southwest, LatLng northeast}) expandBounds(
    ({LatLng southwest, LatLng northeast}) bounds,
    double factor,
  ) {
    final latDiff =
        (bounds.northeast.latitude - bounds.southwest.latitude) * factor;
    final lngDiff =
        (bounds.northeast.longitude - bounds.southwest.longitude) * factor;

    return (
      southwest: LatLng(
        bounds.southwest.latitude - latDiff,
        bounds.southwest.longitude - lngDiff,
      ),
      northeast: LatLng(
        bounds.northeast.latitude + latDiff,
        bounds.northeast.longitude + lngDiff,
      ),
    );
  }
}
