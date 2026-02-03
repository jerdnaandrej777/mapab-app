import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:latlong2/latlong.dart';
import 'route.dart';

part 'navigation_step.freezed.dart';
part 'navigation_step.g.dart';

/// Typ eines OSRM-Manövers
enum ManeuverType {
  depart('depart'),
  arrive('arrive'),
  turn('turn'),
  newName('new name'),
  merge('merge'),
  onRamp('on ramp'),
  offRamp('off ramp'),
  fork('fork'),
  endOfRoad('end of road'),
  roundabout('roundabout'),
  rotary('rotary'),
  roundaboutTurn('roundabout turn'),
  exitRoundabout('exit roundabout'),
  notification('notification'),
  continueInstruction('continue'),
  unknown('unknown');

  final String osrmValue;
  const ManeuverType(this.osrmValue);

  /// Erstellt ManeuverType aus OSRM-String
  static ManeuverType fromOsrm(String value) {
    return ManeuverType.values.firstWhere(
      (e) => e.osrmValue == value,
      orElse: () => ManeuverType.unknown,
    );
  }
}

/// Richtungs-Modifikator eines Manövers
enum ManeuverModifier {
  uturn('uturn'),
  sharpRight('sharp right'),
  right('right'),
  slightRight('slight right'),
  straight('straight'),
  slightLeft('slight left'),
  left('left'),
  sharpLeft('sharp left'),
  none('');

  final String osrmValue;
  const ManeuverModifier(this.osrmValue);

  /// Erstellt ManeuverModifier aus OSRM-String
  static ManeuverModifier fromOsrm(String? value) {
    if (value == null || value.isEmpty) return ManeuverModifier.none;
    return ManeuverModifier.values.firstWhere(
      (e) => e.osrmValue == value,
      orElse: () => ManeuverModifier.none,
    );
  }
}

/// Ein einzelner Navigationsschritt (Manöver)
@freezed
class NavigationStep with _$NavigationStep {
  const NavigationStep._();

  const factory NavigationStep({
    /// Manöver-Typ (turn, depart, arrive, roundabout, etc.)
    required ManeuverType type,

    /// Richtungs-Modifikator (left, right, straight, etc.)
    @Default(ManeuverModifier.none) ManeuverModifier modifier,

    /// Position des Manövers
    @LatLngConverter() required LatLng location,

    /// Distanz dieses Schritts in Metern
    required double distanceMeters,

    /// Dauer dieses Schritts in Sekunden
    required double durationSeconds,

    /// Straßenname (z.B. "Hauptstraße")
    @Default('') String streetName,

    /// Generierte deutsche Instruktion
    required String instruction,

    /// Kompassrichtung vor dem Manöver (0-360)
    @Default(0) int bearingBefore,

    /// Kompassrichtung nach dem Manöver (0-360)
    @Default(0) int bearingAfter,

    /// Polyline-Koordinaten dieses Schritts
    @LatLngListConverter() @Default([]) List<LatLng> geometry,

    /// Kreisverkehr-Ausfahrt (nur bei roundabout/rotary)
    int? roundaboutExit,
  }) = _NavigationStep;

  /// Erstellt NavigationStep aus JSON
  factory NavigationStep.fromJson(Map<String, dynamic> json) =>
      _$NavigationStepFromJson(json);

  /// Formatierte Distanz
  String get formattedDistance {
    if (distanceMeters < 100) {
      return '${distanceMeters.round()} m';
    } else if (distanceMeters < 1000) {
      // Auf 50m runden
      return '${(distanceMeters / 50).round() * 50} m';
    } else {
      return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
    }
  }

  /// Ist ein bedeutsames Manöver (nicht nur "geradeaus weiter")
  bool get isSignificant =>
      type != ManeuverType.notification &&
      type != ManeuverType.newName &&
      !(type == ManeuverType.continueInstruction &&
          modifier == ManeuverModifier.straight);

  /// Ist das letzte Manöver (Ziel erreicht)
  bool get isArrival => type == ManeuverType.arrive;

  /// Ist das erste Manöver (Start)
  bool get isDeparture => type == ManeuverType.depart;
}

/// Ein Routen-Abschnitt (Leg) zwischen zwei Waypoints
@freezed
class NavigationLeg with _$NavigationLeg {
  const NavigationLeg._();

  const factory NavigationLeg({
    /// Alle Schritte in diesem Abschnitt
    required List<NavigationStep> steps,

    /// Gesamtdistanz in Metern
    required double distanceMeters,

    /// Gesamtdauer in Sekunden
    required double durationSeconds,

    /// Zusammenfassung (z.B. "A9, B2")
    @Default('') String summary,
  }) = _NavigationLeg;

  /// Erstellt NavigationLeg aus JSON
  factory NavigationLeg.fromJson(Map<String, dynamic> json) =>
      _$NavigationLegFromJson(json);

  /// Formatierte Distanz
  String get formattedDistance {
    final km = distanceMeters / 1000;
    if (km < 1) return '${distanceMeters.round()} m';
    return '${km.toStringAsFixed(1)} km';
  }

  /// Formatierte Dauer
  String get formattedDuration {
    final minutes = (durationSeconds / 60).round();
    if (minutes < 60) return '$minutes Min.';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) return '$hours Std.';
    return '$hours Std. $mins Min.';
  }

  /// Anzahl bedeutsamer Manöver
  int get significantStepCount => steps.where((s) => s.isSignificant).length;
}

/// Navigationsroute mit allen Legs und Steps
@freezed
class NavigationRoute with _$NavigationRoute {
  const NavigationRoute._();

  const factory NavigationRoute({
    /// Basis-Route (Koordinaten, Distanz, Dauer)
    required AppRoute baseRoute,

    /// Routen-Abschnitte (pro Waypoint-Segment ein Leg)
    required List<NavigationLeg> legs,
  }) = _NavigationRoute;

  /// Erstellt NavigationRoute aus JSON
  factory NavigationRoute.fromJson(Map<String, dynamic> json) =>
      _$NavigationRouteFromJson(json);

  /// Alle Schritte über alle Legs flachgelegt
  List<NavigationStep> get allSteps =>
      legs.expand((leg) => leg.steps).toList();

  /// Gesamtzahl Schritte
  int get totalSteps => allSteps.length;

  /// Gesamtzahl bedeutsamer Manöver
  int get totalSignificantSteps =>
      allSteps.where((s) => s.isSignificant).length;

  /// Findet Step an globalem Index (über alle Legs)
  ({int legIndex, int stepIndex, NavigationStep step})? getStepAt(
      int globalIndex) {
    int idx = 0;
    for (int l = 0; l < legs.length; l++) {
      for (int s = 0; s < legs[l].steps.length; s++) {
        if (idx == globalIndex) {
          return (legIndex: l, stepIndex: s, step: legs[l].steps[s]);
        }
        idx++;
      }
    }
    return null;
  }

  /// Nächster Step nach globalem Index
  NavigationStep? getNextStep(int globalIndex) {
    final result = getStepAt(globalIndex + 1);
    return result?.step;
  }
}
