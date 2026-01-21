import 'package:latlong2/latlong.dart';
import '../../data/models/poi.dart';
import '../utils/geo_utils.dart';

/// Algorithmus zur Routen-Optimierung
/// Verwendet Nearest-Neighbor + 2-opt für TSP-ähnliche Optimierung
class RouteOptimizer {
  /// Optimiert die Reihenfolge der POIs für minimale Gesamtdistanz
  ///
  /// [pois] - Zu besuchende POIs
  /// [startLocation] - Startpunkt der Route
  /// [returnToStart] - Soll die Route zum Start zurückkehren?
  /// [maxIterations] - Maximale 2-opt Iterationen
  List<POI> optimizeRoute({
    required List<POI> pois,
    required LatLng startLocation,
    bool returnToStart = true,
    int maxIterations = 100,
  }) {
    if (pois.isEmpty) return [];
    if (pois.length == 1) return pois;

    // 1. Nearest-Neighbor für Startlösung
    var currentOrder = _nearestNeighbor(pois, startLocation);

    // 2. 2-opt Verbesserung
    currentOrder = _twoOptImprovement(
      currentOrder,
      startLocation,
      returnToStart,
      maxIterations,
    );

    return currentOrder;
  }

  /// Nearest-Neighbor Algorithmus (Greedy)
  /// Wählt immer den nächsten unbesuchten POI
  List<POI> _nearestNeighbor(List<POI> pois, LatLng startLocation) {
    final unvisited = List<POI>.from(pois);
    final ordered = <POI>[];
    var currentLocation = startLocation;

    while (unvisited.isNotEmpty) {
      // Finde nächsten unbesuchten POI
      POI? nearest;
      double minDistance = double.infinity;

      for (final poi in unvisited) {
        final distance = GeoUtils.haversineDistance(
          currentLocation,
          poi.location,
        );
        if (distance < minDistance) {
          minDistance = distance;
          nearest = poi;
        }
      }

      if (nearest != null) {
        ordered.add(nearest);
        currentLocation = nearest.location;
        unvisited.remove(nearest);
      }
    }

    return ordered;
  }

  /// 2-opt Verbesserung
  /// Tauscht Segmente um Gesamtdistanz zu reduzieren
  List<POI> _twoOptImprovement(
    List<POI> pois,
    LatLng startLocation,
    bool returnToStart,
    int maxIterations,
  ) {
    var current = List<POI>.from(pois);
    var improved = true;
    var iterations = 0;

    while (improved && iterations < maxIterations) {
      improved = false;
      iterations++;

      for (int i = 0; i < current.length - 1; i++) {
        for (int j = i + 2; j < current.length; j++) {
          // Prüfe ob Tausch Verbesserung bringt
          if (_improvesWith2Opt(current, i, j, startLocation, returnToStart)) {
            // Segment umkehren
            current = _swap2Opt(current, i, j);
            improved = true;
          }
        }
      }
    }

    return current;
  }

  /// Prüft ob 2-opt Tausch die Route verbessert
  bool _improvesWith2Opt(
    List<POI> route,
    int i,
    int j,
    LatLng start,
    bool returnToStart,
  ) {
    // Aktuelle Distanz
    final currentDist = _calculateSegmentDistance(route, i, j, start, returnToStart);

    // Distanz nach Tausch
    final swapped = _swap2Opt(route, i, j);
    final swappedDist = _calculateSegmentDistance(swapped, i, j, start, returnToStart);

    return swappedDist < currentDist;
  }

  /// Berechnet Distanz eines Segmentes
  double _calculateSegmentDistance(
    List<POI> route,
    int i,
    int j,
    LatLng start,
    bool returnToStart,
  ) {
    double distance = 0;

    // Start zum ersten POI
    if (i == 0) {
      distance += GeoUtils.haversineDistance(start, route[0].location);
    } else {
      distance += GeoUtils.haversineDistance(
        route[i - 1].location,
        route[i].location,
      );
    }

    // Segment i bis j
    for (int k = i; k < j; k++) {
      distance += GeoUtils.haversineDistance(
        route[k].location,
        route[k + 1].location,
      );
    }

    // Nach Segment
    if (j < route.length - 1) {
      distance += GeoUtils.haversineDistance(
        route[j].location,
        route[j + 1].location,
      );
    } else if (returnToStart) {
      distance += GeoUtils.haversineDistance(route[j].location, start);
    }

    return distance;
  }

  /// Führt 2-opt Tausch durch (kehrt Segment um)
  List<POI> _swap2Opt(List<POI> route, int i, int j) {
    final result = <POI>[];

    // Vor dem Segment
    for (int k = 0; k <= i; k++) {
      result.add(route[k]);
    }

    // Segment umgekehrt
    for (int k = j; k > i; k--) {
      result.add(route[k]);
    }

    // Nach dem Segment
    for (int k = j + 1; k < route.length; k++) {
      result.add(route[k]);
    }

    return result;
  }

  /// Berechnet die Gesamtdistanz einer Route
  double calculateTotalDistance({
    required List<POI> pois,
    required LatLng startLocation,
    bool returnToStart = true,
  }) {
    if (pois.isEmpty) return 0;

    double total = 0;

    // Start zum ersten POI
    total += GeoUtils.haversineDistance(startLocation, pois.first.location);

    // Zwischen POIs
    for (int i = 0; i < pois.length - 1; i++) {
      total += GeoUtils.haversineDistance(
        pois[i].location,
        pois[i + 1].location,
      );
    }

    // Zurück zum Start
    if (returnToStart && pois.isNotEmpty) {
      total += GeoUtils.haversineDistance(pois.last.location, startLocation);
    }

    return total;
  }

  /// Berechnet geschätzte Fahrtdauer in Minuten
  /// Durchschnittsgeschwindigkeit: 60 km/h
  int calculateEstimatedDuration({
    required List<POI> pois,
    required LatLng startLocation,
    bool returnToStart = true,
    double avgSpeedKmh = 60,
  }) {
    final distanceKm = calculateTotalDistance(
      pois: pois,
      startLocation: startLocation,
      returnToStart: returnToStart,
    );

    return (distanceKm / avgSpeedKmh * 60).round();
  }

  /// Entfernt POIs, wenn Route zu lang wird
  /// Gibt optimierte Liste zurück
  List<POI> trimRouteToMaxDistance({
    required List<POI> pois,
    required LatLng startLocation,
    required double maxDistanceKm,
    bool returnToStart = true,
  }) {
    if (pois.isEmpty) return [];

    // Erst optimieren
    var optimized = optimizeRoute(
      pois: pois,
      startLocation: startLocation,
      returnToStart: returnToStart,
    );

    // Prüfen ob zu lang
    while (optimized.isNotEmpty) {
      final distance = calculateTotalDistance(
        pois: optimized,
        startLocation: startLocation,
        returnToStart: returnToStart,
      );

      if (distance <= maxDistanceKm) {
        return optimized;
      }

      // Letzten POI entfernen und neu optimieren
      optimized = optimized.sublist(0, optimized.length - 1);

      if (optimized.isNotEmpty) {
        optimized = optimizeRoute(
          pois: optimized,
          startLocation: startLocation,
          returnToStart: returnToStart,
        );
      }
    }

    return optimized;
  }
}

/// Erweiterung für Routen-Statistiken
class RouteStats {
  final double totalDistanceKm;
  final int estimatedDurationMinutes;
  final int poiCount;
  final double avgDistanceBetweenStops;

  RouteStats({
    required this.totalDistanceKm,
    required this.estimatedDurationMinutes,
    required this.poiCount,
    required this.avgDistanceBetweenStops,
  });

  factory RouteStats.calculate({
    required List<POI> pois,
    required LatLng startLocation,
    bool returnToStart = true,
  }) {
    final optimizer = RouteOptimizer();

    final distance = optimizer.calculateTotalDistance(
      pois: pois,
      startLocation: startLocation,
      returnToStart: returnToStart,
    );

    final duration = optimizer.calculateEstimatedDuration(
      pois: pois,
      startLocation: startLocation,
      returnToStart: returnToStart,
    );

    final segmentCount = returnToStart ? pois.length + 1 : pois.length;
    final avgDistance = segmentCount > 0 ? distance / segmentCount : 0.0;

    return RouteStats(
      totalDistanceKm: distance,
      estimatedDurationMinutes: duration,
      poiCount: pois.length,
      avgDistanceBetweenStops: avgDistance,
    );
  }
}
