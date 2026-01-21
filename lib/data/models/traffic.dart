import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:latlong2/latlong.dart';

part 'traffic.freezed.dart';
part 'traffic.g.dart';

/// Verkehrszustand
enum TrafficCondition {
  free('Frei', 0xFF4CAF50),      // Grün
  light('Leicht', 0xFF8BC34A),    // Hellgrün
  moderate('Moderat', 0xFFFFC107), // Gelb
  heavy('Dicht', 0xFFFF9800),     // Orange
  blocked('Stau', 0xFFF44336);    // Rot

  final String label;
  final int colorValue;
  const TrafficCondition(this.label, this.colorValue);
}

/// Verkehrs-Segment auf der Route
@freezed
class TrafficSegment with _$TrafficSegment {
  const factory TrafficSegment({
    required List<LatLng> coordinates,
    required TrafficCondition condition,
    required double speedKmh,
    required double freeFlowSpeedKmh,
    required double delaySeconds,
    required double lengthKm,
  }) = _TrafficSegment;

  const TrafficSegment._();

  /// Berechnet die Verzögerung in Minuten
  double get delayMinutes => delaySeconds / 60;

  /// Geschwindigkeit relativ zum Normalwert (0-1)
  double get speedRatio => freeFlowSpeedKmh > 0
      ? (speedKmh / freeFlowSpeedKmh).clamp(0.0, 1.0)
      : 1.0;

  factory TrafficSegment.fromJson(Map<String, dynamic> json) =>
      _$TrafficSegmentFromJson(json);
}

/// Verkehrs-Info für die gesamte Route
@freezed
class RouteTraffic with _$RouteTraffic {
  const factory RouteTraffic({
    required List<TrafficSegment> segments,
    required double totalDelayMinutes,
    required double averageSpeedKmh,
    required TrafficCondition overallCondition,
    required DateTime lastUpdated,
  }) = _RouteTraffic;

  const RouteTraffic._();

  /// Anzahl der Stau-Segmente
  int get congestionCount => segments
      .where((s) => s.condition == TrafficCondition.heavy ||
                    s.condition == TrafficCondition.blocked)
      .length;

  /// Hat Stau?
  bool get hasCongestion => congestionCount > 0;

  /// Formatierte Verzögerung
  String get formattedDelay {
    if (totalDelayMinutes < 1) return 'Keine Verzögerung';
    if (totalDelayMinutes < 60) return '+${totalDelayMinutes.round()} Min';
    final hours = (totalDelayMinutes / 60).floor();
    final mins = (totalDelayMinutes % 60).round();
    return '+${hours}h ${mins}min';
  }

  factory RouteTraffic.fromJson(Map<String, dynamic> json) =>
      _$RouteTrafficFromJson(json);
}

/// Verkehrs-Vorfall (Unfall, Baustelle, etc.)
@freezed
class TrafficIncident with _$TrafficIncident {
  const factory TrafficIncident({
    required String id,
    required String type,  // accident, construction, roadClosed, event
    required String description,
    required LatLng location,
    required double severity,  // 0-1
    DateTime? startTime,
    DateTime? endTime,
    double? lengthKm,
  }) = _TrafficIncident;

  const TrafficIncident._();

  /// Icon basierend auf Typ
  String get icon {
    switch (type) {
      case 'accident': return '🚗💥';
      case 'construction': return '🚧';
      case 'roadClosed': return '⛔';
      case 'event': return '🎪';
      default: return '⚠️';
    }
  }

  /// Typ-Label
  String get typeLabel {
    switch (type) {
      case 'accident': return 'Unfall';
      case 'construction': return 'Baustelle';
      case 'roadClosed': return 'Straße gesperrt';
      case 'event': return 'Veranstaltung';
      default: return 'Störung';
    }
  }

  factory TrafficIncident.fromJson(Map<String, dynamic> json) =>
      _$TrafficIncidentFromJson(json);
}
