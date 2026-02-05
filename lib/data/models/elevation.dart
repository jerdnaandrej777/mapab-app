import 'dart:math' as math;

/// Einzelner Punkt im Hoehenprofil
class ElevationPoint {
  /// Kumulative Distanz vom Start in km
  final double distanceKm;

  /// Hoehe in Metern ueber NN
  final double elevation;

  const ElevationPoint({
    required this.distanceKm,
    required this.elevation,
  });
}

/// Hoehenprofil einer Route
class ElevationProfile {
  /// Alle Messpunkte (sortiert nach Distanz)
  final List<ElevationPoint> points;

  /// Gesamtanstieg in Metern
  final double totalAscent;

  /// Gesamtabstieg in Metern
  final double totalDescent;

  /// Hoechste Hoehe in Metern
  final double maxElevation;

  /// Niedrigste Hoehe in Metern
  final double minElevation;

  /// Gesamtdistanz in km
  final double totalDistanceKm;

  const ElevationProfile({
    required this.points,
    required this.totalAscent,
    required this.totalDescent,
    required this.maxElevation,
    required this.minElevation,
    required this.totalDistanceKm,
  });

  /// Erstellt ein ElevationProfile aus rohen Hoehendaten und kumulativen Distanzen.
  ///
  /// [elevations] - Hoehenwerte in Metern (gleiche Laenge wie [cumulativeDistancesKm])
  /// [cumulativeDistancesKm] - Kumulative Distanzen in km ab Start
  factory ElevationProfile.fromRawData({
    required List<double> elevations,
    required List<double> cumulativeDistancesKm,
  }) {
    assert(elevations.length == cumulativeDistancesKm.length);

    if (elevations.isEmpty) {
      return const ElevationProfile(
        points: [],
        totalAscent: 0,
        totalDescent: 0,
        maxElevation: 0,
        minElevation: 0,
        totalDistanceKm: 0,
      );
    }

    double ascent = 0;
    double descent = 0;
    double maxElev = elevations[0];
    double minElev = elevations[0];

    final points = <ElevationPoint>[];

    for (int i = 0; i < elevations.length; i++) {
      final elev = elevations[i];
      points.add(ElevationPoint(
        distanceKm: cumulativeDistancesKm[i],
        elevation: elev,
      ));

      maxElev = math.max(maxElev, elev);
      minElev = math.min(minElev, elev);

      if (i > 0) {
        final diff = elev - elevations[i - 1];
        if (diff > 0) {
          ascent += diff;
        } else {
          descent += diff.abs();
        }
      }
    }

    return ElevationProfile(
      points: points,
      totalAscent: ascent,
      totalDescent: descent,
      maxElevation: maxElev,
      minElevation: minElev,
      totalDistanceKm: cumulativeDistancesKm.last,
    );
  }

  /// Hoehenunterschied zwischen Start und Ziel
  double get elevationDifference =>
      points.isNotEmpty ? points.last.elevation - points.first.elevation : 0;

  /// Formatierter Gesamtanstieg
  String get formattedAscent => '${totalAscent.round()} m';

  /// Formatierter Gesamtabstieg
  String get formattedDescent => '${totalDescent.round()} m';

  /// Formatierte Maximalhoehe
  String get formattedMaxElevation => '${maxElevation.round()} m';

  /// Formatierte Minimalhoehe
  String get formattedMinElevation => '${minElevation.round()} m';

  /// Hoehe an einer bestimmten Distanz (km) interpoliert
  double? elevationAtDistance(double distanceKm) {
    if (points.isEmpty) return null;
    if (distanceKm <= points.first.distanceKm) return points.first.elevation;
    if (distanceKm >= points.last.distanceKm) return points.last.elevation;

    for (int i = 0; i < points.length - 1; i++) {
      if (distanceKm >= points[i].distanceKm &&
          distanceKm <= points[i + 1].distanceKm) {
        final segLen = points[i + 1].distanceKm - points[i].distanceKm;
        if (segLen == 0) return points[i].elevation;
        final t = (distanceKm - points[i].distanceKm) / segLen;
        return points[i].elevation + t * (points[i + 1].elevation - points[i].elevation);
      }
    }
    return null;
  }
}
