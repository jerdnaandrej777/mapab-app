import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../data/models/navigation_step.dart';
import '../../../data/models/route.dart';
import '../../../data/models/trip.dart';
import '../../../data/repositories/routing_repo.dart';
import '../services/route_matcher_service.dart';

part 'navigation_provider.g.dart';

/// Status der Navigation
enum NavigationStatus {
  /// Keine Navigation aktiv
  idle,

  /// Route wird berechnet
  loading,

  /// Navigation läuft
  navigating,

  /// Route wird neu berechnet (Abweichung)
  rerouting,

  /// Waypoint/POI erreicht
  arrivedAtWaypoint,

  /// Ziel erreicht
  arrivedAtDestination,

  /// Fehler
  error,
}

/// State für die laufende Navigation
class NavigationState {
  final NavigationStatus status;
  final NavigationRoute? route;
  final LatLng? currentPosition;
  final double? currentHeading;
  final double? currentSpeedKmh;

  // Aktuelles Manöver
  final NavigationStep? currentStep;
  final NavigationStep? nextStep;
  final int currentStepIndex;
  final int currentLegIndex;
  final double distanceToNextStepMeters;

  // Route-Fortschritt
  final double distanceToDestinationKm;
  final int etaMinutes;
  final double completedDistanceKm;
  final double progress; // 0.0 - 1.0

  // POI-Waypoints
  final List<TripStop> remainingStops;
  final TripStop? nextPOIStop;
  final double distanceToNextPOIMeters;
  final Set<String> visitedStopIds;

  // Sprachausgabe
  final bool isMuted;

  // Fehler
  final String? error;

  const NavigationState({
    this.status = NavigationStatus.idle,
    this.route,
    this.currentPosition,
    this.currentHeading,
    this.currentSpeedKmh,
    this.currentStep,
    this.nextStep,
    this.currentStepIndex = 0,
    this.currentLegIndex = 0,
    this.distanceToNextStepMeters = 0,
    this.distanceToDestinationKm = 0,
    this.etaMinutes = 0,
    this.completedDistanceKm = 0,
    this.progress = 0,
    this.remainingStops = const [],
    this.nextPOIStop,
    this.distanceToNextPOIMeters = 0,
    this.visitedStopIds = const {},
    this.isMuted = false,
    this.error,
  });

  NavigationState copyWith({
    NavigationStatus? status,
    NavigationRoute? route,
    LatLng? currentPosition,
    double? currentHeading,
    double? currentSpeedKmh,
    NavigationStep? currentStep,
    NavigationStep? nextStep,
    int? currentStepIndex,
    int? currentLegIndex,
    double? distanceToNextStepMeters,
    double? distanceToDestinationKm,
    int? etaMinutes,
    double? completedDistanceKm,
    double? progress,
    List<TripStop>? remainingStops,
    TripStop? nextPOIStop,
    double? distanceToNextPOIMeters,
    Set<String>? visitedStopIds,
    bool? isMuted,
    String? error,
  }) {
    return NavigationState(
      status: status ?? this.status,
      route: route ?? this.route,
      currentPosition: currentPosition ?? this.currentPosition,
      currentHeading: currentHeading ?? this.currentHeading,
      currentSpeedKmh: currentSpeedKmh ?? this.currentSpeedKmh,
      currentStep: currentStep ?? this.currentStep,
      nextStep: nextStep ?? this.nextStep,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      currentLegIndex: currentLegIndex ?? this.currentLegIndex,
      distanceToNextStepMeters:
          distanceToNextStepMeters ?? this.distanceToNextStepMeters,
      distanceToDestinationKm:
          distanceToDestinationKm ?? this.distanceToDestinationKm,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      completedDistanceKm: completedDistanceKm ?? this.completedDistanceKm,
      progress: progress ?? this.progress,
      remainingStops: remainingStops ?? this.remainingStops,
      nextPOIStop: nextPOIStop ?? this.nextPOIStop,
      distanceToNextPOIMeters:
          distanceToNextPOIMeters ?? this.distanceToNextPOIMeters,
      visitedStopIds: visitedStopIds ?? this.visitedStopIds,
      isMuted: isMuted ?? this.isMuted,
      error: error,
    );
  }

  bool get isNavigating => status == NavigationStatus.navigating;
  bool get isLoading => status == NavigationStatus.loading;
  bool get isRerouting => status == NavigationStatus.rerouting;
  bool get hasRoute => route != null;
  bool get hasPosition => currentPosition != null;
}

/// Schwellwerte für Navigation
class _NavThresholds {
  static const double offRouteMeters = 75;
  static const double waypointReachedMeters = 50;
  static const double poiApproachMeters = 500;
  static const double poiReachedMeters = 80;
  static const int rerouteDebounceMs = 5000;
  static const int gpsDistanceFilter = 10; // Meter
}

/// Navigation Provider - Kernlogik für Turn-by-Turn Navigation
@Riverpod(keepAlive: true)
class NavigationNotifier extends _$NavigationNotifier {
  StreamSubscription<Position>? _positionStream;
  final RouteMatcherService _routeMatcher = RouteMatcherService();
  DateTime? _lastRerouteTime;
  int _lastMatchedIndex = 0;

  @override
  NavigationState build() {
    ref.onDispose(() {
      _positionStream?.cancel();
    });
    return const NavigationState();
  }

  /// Startet die Navigation auf einer Route mit optionalen POI-Stops
  Future<void> startNavigation({
    required AppRoute baseRoute,
    List<TripStop>? stops,
  }) async {
    debugPrint('[Navigation] Starte Navigation: '
        '${baseRoute.startAddress} → ${baseRoute.endAddress}');

    state = state.copyWith(
      status: NavigationStatus.loading,
      remainingStops: stops ?? [],
      visitedStopIds: {},
    );

    try {
      // Navigationsroute mit Steps berechnen
      final routingRepo = ref.read(routingRepositoryProvider);
      final navRoute = await routingRepo.calculateNavigationRoute(
        start: baseRoute.start,
        end: baseRoute.end,
        waypoints: baseRoute.waypoints.isNotEmpty
            ? baseRoute.waypoints
            : stops
                ?.map((s) => LatLng(s.latitude, s.longitude))
                .toList(),
        startAddress: baseRoute.startAddress,
        endAddress: baseRoute.endAddress,
      );

      // Ersten Step setzen
      final firstStep = navRoute.allSteps.isNotEmpty
          ? navRoute.allSteps.first
          : null;
      final secondStep = navRoute.allSteps.length > 1
          ? navRoute.allSteps[1]
          : null;

      // Nächsten POI bestimmen
      final nextPOI = stops != null && stops.isNotEmpty ? stops.first : null;

      state = state.copyWith(
        status: NavigationStatus.navigating,
        route: navRoute,
        currentStep: firstStep,
        nextStep: secondStep,
        currentStepIndex: 0,
        currentLegIndex: 0,
        distanceToDestinationKm: navRoute.baseRoute.distanceKm,
        etaMinutes: navRoute.baseRoute.durationMinutes,
        nextPOIStop: nextPOI,
      );

      // GPS-Stream starten
      await _startPositionStream();

      debugPrint('[Navigation] Navigation gestartet: '
          '${navRoute.totalSteps} Steps, '
          '${navRoute.legs.length} Legs');
    } catch (e) {
      debugPrint('[Navigation] Fehler beim Start: $e');
      state = state.copyWith(
        status: NavigationStatus.error,
        error: 'Navigation konnte nicht gestartet werden: $e',
      );
    }
  }

  /// Stoppt die Navigation
  void stopNavigation() {
    debugPrint('[Navigation] Navigation gestoppt');
    _positionStream?.cancel();
    _positionStream = null;
    _lastMatchedIndex = 0;
    _lastRerouteTime = null;
    state = const NavigationState();
  }

  /// Schaltet Sprachausgabe ein/aus
  void toggleMute() {
    state = state.copyWith(isMuted: !state.isMuted);
  }

  /// Markiert einen POI-Stop als besucht und wechselt zum nächsten
  void markStopVisited(String stopId) {
    final updatedVisited = {...state.visitedStopIds, stopId};
    final remaining = state.remainingStops
        .where((s) => !updatedVisited.contains(s.poiId))
        .toList();
    final nextPOI = remaining.isNotEmpty ? remaining.first : null;

    state = state.copyWith(
      visitedStopIds: updatedVisited,
      remainingStops: remaining,
      nextPOIStop: nextPOI,
      status: NavigationStatus.navigating,
    );

    debugPrint('[Navigation] Stop besucht: $stopId, '
        '${remaining.length} verbleibend');
  }

  /// Startet den GPS-Position-Stream
  Future<void> _startPositionStream() async {
    _positionStream?.cancel();

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: _NavThresholds.gpsDistanceFilter,
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      _onPositionUpdate,
      onError: (error) {
        debugPrint('[Navigation] GPS-Fehler: $error');
        state = state.copyWith(
          error: 'GPS-Signal verloren',
        );
      },
    );
  }

  /// Hauptlogik: Wird bei jedem GPS-Update aufgerufen
  void _onPositionUpdate(Position position) {
    if (!state.isNavigating && !state.isRerouting) return;
    if (state.route == null) return;

    final currentPos = LatLng(position.latitude, position.longitude);
    final heading = position.heading;
    final speedKmh = position.speed * 3.6; // m/s → km/h
    final routeCoords = state.route!.baseRoute.coordinates;

    // 1. Position auf Route snappen
    final matchResult = _routeMatcher.snapToRoute(
      currentPos,
      routeCoords,
      searchStartIndex: _lastMatchedIndex,
      searchWindow: 100,
    );

    _lastMatchedIndex = matchResult.nearestIndex;

    // 2. Off-Route prüfen
    if (matchResult.isOffRoute(_NavThresholds.offRouteMeters)) {
      _handleOffRoute(currentPos);
      return;
    }

    // 3. Aktuellen Step bestimmen
    final stepInfo = _findCurrentStep(matchResult.nearestIndex);

    // 4. Distanz zum nächsten Manöver berechnen
    final distToNextStep = stepInfo != null
        ? _routeMatcher.getDistanceAlongRoute(
            routeCoords,
            matchResult.nearestIndex,
            _routeMatcher.findNearestIndex(
                routeCoords, stepInfo.nextStepLocation),
          )
        : 0.0;

    // 5. Verbleibende Distanz und ETA
    final remainingMeters =
        _routeMatcher.getRemainingDistance(routeCoords, matchResult.nearestIndex);
    final remainingKm = remainingMeters / 1000;
    final completedKm =
        state.route!.baseRoute.distanceKm - remainingKm;
    final eta = speedKmh > 5
        ? (remainingKm / speedKmh * 60).round()
        : state.etaMinutes;

    // 6. POI-Nähe prüfen
    double distToNextPOI = double.infinity;
    if (state.nextPOIStop != null) {
      final poiPos = LatLng(
        state.nextPOIStop!.latitude,
        state.nextPOIStop!.longitude,
      );
      distToNextPOI = _routeMatcher
          .distanceBetween(currentPos, poiPos);

      // POI erreicht?
      if (distToNextPOI < _NavThresholds.poiReachedMeters) {
        state = state.copyWith(
          status: NavigationStatus.arrivedAtWaypoint,
          currentPosition: currentPos,
          currentHeading: heading,
        );
        return;
      }
    }

    // 7. Ziel erreicht?
    if (matchResult.progress > 0.98 && remainingKm < 0.05) {
      state = state.copyWith(
        status: NavigationStatus.arrivedAtDestination,
        currentPosition: currentPos,
        currentHeading: heading,
        progress: 1.0,
      );
      _positionStream?.cancel();
      debugPrint('[Navigation] Ziel erreicht!');
      return;
    }

    // 8. State aktualisieren
    state = state.copyWith(
      currentPosition: currentPos,
      currentHeading: heading,
      currentSpeedKmh: speedKmh,
      currentStep: stepInfo?.currentStep,
      nextStep: stepInfo?.nextStep,
      currentStepIndex: stepInfo?.globalIndex ?? state.currentStepIndex,
      distanceToNextStepMeters: distToNextStep,
      distanceToDestinationKm: remainingKm,
      etaMinutes: eta,
      completedDistanceKm: completedKm,
      progress: matchResult.progress,
      distanceToNextPOIMeters: distToNextPOI,
      status: NavigationStatus.navigating,
      error: null,
    );
  }

  /// Behandelt Abweichung von der Route
  void _handleOffRoute(LatLng currentPos) {
    final now = DateTime.now();

    // Debounce: Nicht zu oft neu berechnen
    if (_lastRerouteTime != null &&
        now.difference(_lastRerouteTime!).inMilliseconds <
            _NavThresholds.rerouteDebounceMs) {
      return;
    }

    debugPrint('[Navigation] Off-Route erkannt, Neuberechnung...');
    _lastRerouteTime = now;
    _reroute(currentPos);
  }

  /// Berechnet Route neu ab aktueller Position
  Future<void> _reroute(LatLng fromPosition) async {
    state = state.copyWith(status: NavigationStatus.rerouting);

    try {
      final routingRepo = ref.read(routingRepositoryProvider);

      // Verbleibende Waypoints sammeln
      final remainingWaypoints = state.remainingStops
          .where((s) => !state.visitedStopIds.contains(s.poiId))
          .map((s) => LatLng(s.latitude, s.longitude))
          .toList();

      final navRoute = await routingRepo.calculateNavigationRoute(
        start: fromPosition,
        end: state.route!.baseRoute.end,
        waypoints:
            remainingWaypoints.isNotEmpty ? remainingWaypoints : null,
        startAddress: 'Aktuelle Position',
        endAddress: state.route!.baseRoute.endAddress,
      );

      _lastMatchedIndex = 0;

      final firstStep = navRoute.allSteps.isNotEmpty
          ? navRoute.allSteps.first
          : null;

      state = state.copyWith(
        status: NavigationStatus.navigating,
        route: navRoute,
        currentStep: firstStep,
        currentStepIndex: 0,
        currentLegIndex: 0,
        distanceToDestinationKm: navRoute.baseRoute.distanceKm,
        etaMinutes: navRoute.baseRoute.durationMinutes,
        error: null,
      );

      debugPrint('[Navigation] Route neu berechnet: '
          '${navRoute.totalSteps} Steps');
    } catch (e) {
      debugPrint('[Navigation] Rerouting fehlgeschlagen: $e');
      state = state.copyWith(
        status: NavigationStatus.navigating,
        error: 'Neuberechnung fehlgeschlagen',
      );
    }
  }

  /// Findet den aktuellen Navigation-Step basierend auf Route-Index
  _StepInfo? _findCurrentStep(int routeIndex) {
    if (state.route == null) return null;

    final allSteps = state.route!.allSteps;
    if (allSteps.isEmpty) return null;

    final routeCoords = state.route!.baseRoute.coordinates;

    // Finde den Step, dessen Start-Location am nächsten zum aktuellen Index ist
    int bestStepIdx = 0;
    double bestDist = double.infinity;

    for (int i = 0; i < allSteps.length; i++) {
      final stepIdx = _routeMatcher.findNearestIndex(
          routeCoords, allSteps[i].location);
      // Step muss vor uns oder auf unserem Level sein
      if (stepIdx <= routeIndex) {
        final diff = (routeIndex - stepIdx).toDouble();
        if (diff < bestDist) {
          bestDist = diff;
          bestStepIdx = i;
        }
      }
    }

    // Der nächste significante Step nach dem aktuellen
    int nextSignificantIdx = bestStepIdx + 1;
    while (nextSignificantIdx < allSteps.length &&
        !allSteps[nextSignificantIdx].isSignificant) {
      nextSignificantIdx++;
    }

    final nextStep = nextSignificantIdx < allSteps.length
        ? allSteps[nextSignificantIdx]
        : null;

    return _StepInfo(
      currentStep: allSteps[bestStepIdx],
      nextStep: nextStep,
      globalIndex: bestStepIdx,
      nextStepLocation:
          nextStep?.location ?? state.route!.baseRoute.end,
    );
  }
}

class _StepInfo {
  final NavigationStep currentStep;
  final NavigationStep? nextStep;
  final int globalIndex;
  final LatLng nextStepLocation;

  const _StepInfo({
    required this.currentStep,
    this.nextStep,
    required this.globalIndex,
    required this.nextStepLocation,
  });
}
