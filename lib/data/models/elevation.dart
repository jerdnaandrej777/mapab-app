import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:latlong2/latlong.dart';

part 'elevation.freezed.dart';
part 'elevation.g.dart';

/// Routing-Modus
enum RoutingMode {
  car('Auto', '🚗', 'driving'),
  bicycle('Fahrrad', '🚲', 'cycling'),
  walking('Wandern', '🥾', 'walking'),
  ebike('E-Bike', '⚡🚲', 'cycling');

  final String label;
  final String emoji;
  final String osrmProfile;
  const RoutingMode(this.label, this.emoji, this.osrmProfile);

  bool get needsElevation => this != RoutingMode.car;
}

/// Schwierigkeitsgrad für Wandern/Radfahren
enum RouteDifficulty {
  easy('Leicht', '🟢', 0),
  moderate('Moderat', '🟡', 1),
  difficult('Schwer', '🔴', 2),
  expert('Experte', '⚫', 3);

  final String label;
  final String emoji;
  final int level;
  const RouteDifficulty(this.label, this.emoji, this.level);
}

/// Einzelner Punkt mit Höhendaten
@freezed
class ElevationPoint with _$ElevationPoint {
  const factory ElevationPoint({
    required double latitude,
    required double longitude,
    required double elevation,  // Meter über NN
    required double distance,   // Kumulierte Distanz in km
  }) = _ElevationPoint;

  const ElevationPoint._();

  LatLng get location => LatLng(latitude, longitude);

  factory ElevationPoint.fromJson(Map<String, dynamic> json) =>
      _$ElevationPointFromJson(json);
}

/// Höhenprofil einer Route
@freezed
class ElevationProfile with _$ElevationProfile {
  const factory ElevationProfile({
    required List<ElevationPoint> points,
    required double minElevation,
    required double maxElevation,
    required double totalAscent,    // Gesamtanstieg in Metern
    required double totalDescent,   // Gesamtabstieg in Metern
    required double totalDistanceKm,
    required RouteDifficulty difficulty,
    DateTime? calculatedAt,
  }) = _ElevationProfile;

  const ElevationProfile._();

  /// Höhenunterschied
  double get elevationDifference => maxElevation - minElevation;

  /// Durchschnittliche Steigung in Prozent
  double get averageGradient {
    if (totalDistanceKm == 0) return 0;
    return (totalAscent / (totalDistanceKm * 1000)) * 100;
  }

  /// Geschätzte Dauer für Wandern (Minuten)
  int estimateWalkingDuration() {
    // DIN 33466: 4 km/h horizontal + 300m Anstieg pro Stunde
    final horizontalTime = totalDistanceKm / 4 * 60;
    final ascentTime = totalAscent / 300 * 60;
    return (horizontalTime + ascentTime * 0.5).round();  // Hälfte addieren
  }

  /// Geschätzte Dauer für Radfahren (Minuten)
  int estimateCyclingDuration({bool isEbike = false}) {
    // 15-20 km/h für normales Rad, 20-25 km/h für E-Bike
    final speed = isEbike ? 22 : 15;
    final baseTime = totalDistanceKm / speed * 60;
    // Anstieg verlangsamt
    final ascentPenalty = totalAscent / (isEbike ? 500 : 200) * 60;
    return (baseTime + ascentPenalty).round();
  }

  /// Geschätzte verbrannte Kalorien
  int estimateCalories({
    required RoutingMode mode,
    double weightKg = 75,
  }) {
    // MET-Werte (Metabolic Equivalent of Task)
    final met = switch (mode) {
      RoutingMode.walking => 4.0 + (averageGradient * 0.2),  // Wandern
      RoutingMode.bicycle => 6.0 + (averageGradient * 0.3),  // Radfahren
      RoutingMode.ebike => 4.0 + (averageGradient * 0.1),    // E-Bike
      RoutingMode.car => 1.5,                                  // Sitzen
    };

    final durationHours = switch (mode) {
      RoutingMode.walking => estimateWalkingDuration() / 60,
      RoutingMode.bicycle => estimateCyclingDuration() / 60,
      RoutingMode.ebike => estimateCyclingDuration(isEbike: true) / 60,
      RoutingMode.car => totalDistanceKm / 80,
    };

    // Formel: Kalorien = MET * Gewicht * Dauer
    return (met * weightKg * durationHours).round();
  }

  factory ElevationProfile.fromJson(Map<String, dynamic> json) =>
      _$ElevationProfileFromJson(json);
}

/// Segment mit Steigungsinformation
@freezed
class GradientSegment with _$GradientSegment {
  const factory GradientSegment({
    required double startDistance,  // km
    required double endDistance,    // km
    required double gradient,       // Prozent (positiv = Anstieg)
    required double startElevation,
    required double endElevation,
  }) = _GradientSegment;

  const GradientSegment._();

  double get length => endDistance - startDistance;

  bool get isUphill => gradient > 2;
  bool get isDownhill => gradient < -2;
  bool get isFlat => gradient.abs() <= 2;

  /// Farbe basierend auf Steigung
  int get colorValue {
    if (gradient > 15) return 0xFF8B0000;      // Dunkelrot
    if (gradient > 10) return 0xFFFF0000;      // Rot
    if (gradient > 5) return 0xFFFF8C00;       // Orange
    if (gradient > 2) return 0xFFFFD700;       // Gelb
    if (gradient > -2) return 0xFF32CD32;      // Grün
    if (gradient > -5) return 0xFF00CED1;      // Türkis
    if (gradient > -10) return 0xFF1E90FF;     // Blau
    return 0xFF00008B;                          // Dunkelblau
  }

  factory GradientSegment.fromJson(Map<String, dynamic> json) =>
      _$GradientSegmentFromJson(json);
}
