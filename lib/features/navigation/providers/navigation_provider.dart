import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:travel_planner/l10n/app_localizations.dart';
import '../../../core/utils/location_helper.dart';
import '../../../data/models/navigation_step.dart';
import '../../../data/models/route.dart';
import '../../../data/models/trip.dart';
import '../../../data/repositories/routing_repo.dart';
import '../services/navigation_foreground_service.dart';
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

  // Route-Snapping (fuer Interpolation)
  final LatLng? snappedPosition;
  final double? routeSegmentBearing;
  final int matchedRouteIndex;

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
    this.snappedPosition,
    this.routeSegmentBearing,
    this.matchedRouteIndex = 0,
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
    LatLng? snappedPosition,
    double? routeSegmentBearing,
    int? matchedRouteIndex,
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
      snappedPosition: snappedPosition ?? this.snappedPosition,
      routeSegmentBearing: routeSegmentBearing ?? this.routeSegmentBearing,
      matchedRouteIndex: matchedRouteIndex ?? this.matchedRouteIndex,
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
  static const int gpsDistanceFilter = 1; // Meter (haeufigere Updates fuer fluessigere Bewegung)
}

/// Navigation Provider - Kernlogik für Turn-by-Turn Navigation
@Riverpod(keepAlive: true)
class NavigationNotifier extends _$NavigationNotifier {
  StreamSubscription<Position>? _positionStream;
  final RouteMatcherService _routeMatcher = RouteMatcherService();
  DateTime? _lastRerouteTime;
  int _lastMatchedIndex = 0;
  AppLocalizations? _l10n;

  // Cache: Step-Index → Route-Koordinaten-Index (einmal berechnet pro Route)
  List<int>? _stepRouteIndices;

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
    required AppLocalizations l10n,
    List<TripStop>? stops,
  }) async {
    _l10n = l10n;
    // Vorherige Navigation sauber stoppen (verhindert doppelte GPS-Streams)
    if (state.isNavigating || state.isRerouting || state.isLoading) {
      debugPrint('[Navigation] Vorherige Navigation wird gestoppt');
      stopNavigation();
    }

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
        l10n: l10n,
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

      // Step-Index-Cache aufbauen (einmalig, O(steps * coords))
      _buildStepRouteIndexCache(navRoute);

      // GPS-Stream starten
      await _startPositionStream();

      // Foreground Service fuer Hintergrund-Navigation starten
      await _startForegroundService(
        destinationName: baseRoute.endAddress,
        distanceKm: navRoute.baseRoute.distanceKm,
        etaMinutes: navRoute.baseRoute.durationMinutes,
      );

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
    _stepRouteIndices = null;
    state = const NavigationState();

    // Foreground Service stoppen
    _stopForegroundService();
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

  /// Fuegt einen POI als naechsten Waypoint waehrend der Navigation hinzu.
  /// Triggert Rerouting ueber aktuelle Position mit dem neuen Waypoint.
  Future<void> addWaypointDuringNavigation(TripStop stop) async {
    if (!state.isNavigating || state.currentPosition == null) return;

    debugPrint('[Navigation] Neuer Waypoint hinzugefuegt: ${stop.name}');

    // Stop als naechsten in die verbleibenden Stops einfuegen
    final updatedStops = [stop, ...state.remainingStops];

    state = state.copyWith(
      remainingStops: updatedStops,
      nextPOIStop: stop,
    );

    // Rerouting mit dem neuen Waypoint
    await _reroute(state.currentPosition!);
  }

  /// Startet den GPS-Position-Stream
  Future<void> _startPositionStream() async {
    _positionStream?.cancel();

    // GPS-Verfuegbarkeit pruefen
    final gpsCheck = await LocationHelper.getCurrentPosition();
    if (!gpsCheck.isSuccess) {
      debugPrint('[Navigation] GPS nicht verfuegbar: ${gpsCheck.error}');
      state = state.copyWith(
        error: gpsCheck.message ?? 'GPS nicht verfuegbar',
      );
      return;
    }

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
    // Nur bei aktiver Navigation verarbeiten
    if (state.status == NavigationStatus.idle ||
        state.status == NavigationStatus.error ||
        state.status == NavigationStatus.loading ||
        state.status == NavigationStatus.arrivedAtDestination) return;
    if (state.route == null) return;

    // Bei arrivedAtWaypoint nur Position updaten, keine Hauptlogik
    if (state.status == NavigationStatus.arrivedAtWaypoint) {
      final currentPos = LatLng(position.latitude, position.longitude);
      state = state.copyWith(
        currentPosition: currentPos,
        currentHeading: position.heading,
        currentSpeedKmh: position.speed * 3.6,
      );
      return;
    }

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

    // 4. Distanz zum naechsten Manoever berechnen (gecachter Index statt O(n) Suche)
    final distToNextStep = stepInfo != null
        ? _routeMatcher.getDistanceAlongRoute(
            routeCoords,
            matchResult.nearestIndex,
            stepInfo.nextStepRouteIndex ??
                (routeCoords.length - 1),
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

    // 8. Route-Segment-Bearing berechnen (fuer Interpolation bei niedrigem Speed)
    double? segmentBearing;
    if (matchResult.nearestIndex < routeCoords.length - 1) {
      segmentBearing = _routeMatcher.calculateBearing(
        routeCoords[matchResult.nearestIndex],
        routeCoords[matchResult.nearestIndex + 1],
      );
    }

    // 9. State aktualisieren
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
      snappedPosition: matchResult.snappedPosition,
      routeSegmentBearing: segmentBearing,
      matchedRouteIndex: matchResult.nearestIndex,
      status: NavigationStatus.navigating,
      error: null,
    );

    // 10. Foreground-Service-Benachrichtigung aktualisieren (alle ~30 Sekunden)
    _maybeUpdateForegroundNotification(remainingKm, eta);
  }

  int _lastNotificationUpdateSec = 0;

  void _maybeUpdateForegroundNotification(double remainingKm, int etaMinutes) {
    final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (nowSec - _lastNotificationUpdateSec < 30) return;
    _lastNotificationUpdateSec = nowSec;

    NavigationForegroundService.updateNotification(
      destinationName: state.route?.baseRoute.endAddress ?? 'Ziel',
      distanceKm: remainingKm,
      etaMinutes: etaMinutes,
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
    if (state.route == null) {
      debugPrint('[Navigation] Reroute abgebrochen: keine Route vorhanden');
      return;
    }
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
        l10n: _l10n!,
      );

      _lastMatchedIndex = 0;

      final firstStep = navRoute.allSteps.isNotEmpty
          ? navRoute.allSteps.first
          : null;

      // Step-Index-Cache neu aufbauen
      _buildStepRouteIndexCache(navRoute);

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

  /// Baut den Step-Route-Index-Cache auf (einmalig pro Route).
  /// Mappt jeden Navigation-Step auf seinen naechsten Route-Koordinaten-Index.
  void _buildStepRouteIndexCache(NavigationRoute navRoute) {
    final allSteps = navRoute.allSteps;
    final routeCoords = navRoute.baseRoute.coordinates;
    if (allSteps.isEmpty || routeCoords.isEmpty) {
      _stepRouteIndices = [];
      return;
    }

    _stepRouteIndices = List<int>.generate(allSteps.length, (i) {
      return _routeMatcher.findNearestIndex(routeCoords, allSteps[i].location);
    });
  }

  // ---------------------------------------------------------------------------
  // Foreground Service (Hintergrund-Navigation)
  // ---------------------------------------------------------------------------

  /// Startet den Foreground Service fuer Hintergrund-GPS-Tracking
  Future<void> _startForegroundService({
    required String destinationName,
    required double distanceKm,
    required int etaMinutes,
  }) async {
    try {
      final success = await NavigationForegroundService.startService(
        destinationName: destinationName,
        distanceKm: distanceKm,
        etaMinutes: etaMinutes,
      );
      if (success) {
        debugPrint('[Navigation] Foreground Service gestartet');
        // Callback fuer Hintergrund-GPS-Updates registrieren
        NavigationForegroundService.setDataCallback(_onBackgroundData);
      }
    } catch (e) {
      debugPrint('[Navigation] Foreground Service Fehler: $e');
      // Nicht kritisch - Navigation funktioniert weiterhin im Vordergrund
    }
  }

  /// Stoppt den Foreground Service
  Future<void> _stopForegroundService() async {
    try {
      NavigationForegroundService.removeDataCallback(_onBackgroundData);
      await NavigationForegroundService.stopService();
      debugPrint('[Navigation] Foreground Service gestoppt');
    } catch (e) {
      debugPrint('[Navigation] Foreground Service Stop-Fehler: $e');
    }
  }

  /// Callback fuer GPS-Updates vom Foreground Service (App im Hintergrund)
  void _onBackgroundData(Object data) {
    if (data is! Map<String, dynamic>) return;

    final type = data['type'] as String?;
    if (type == 'position') {
      final lat = data['latitude'] as double?;
      final lng = data['longitude'] as double?;
      final heading = data['heading'] as double?;
      final speed = data['speed'] as double?;

      if (lat != null && lng != null) {
        // GPS-Update als Position-Objekt verarbeiten
        final position = Position(
          latitude: lat,
          longitude: lng,
          heading: heading ?? 0,
          speed: speed ?? 0,
          accuracy: data['accuracy'] as double? ?? 0,
          altitude: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
          speedAccuracy: 0,
          timestamp: data['timestamp'] != null
              ? DateTime.fromMillisecondsSinceEpoch(data['timestamp'] as int)
              : DateTime.now(),
        );
        _onPositionUpdate(position);
      }
    } else if (type == 'error') {
      debugPrint('[Navigation] Hintergrund-Fehler: ${data['message']}');
    }
  }

  /// Findet den aktuellen Navigation-Step basierend auf Route-Index.
  /// Nutzt den gecachten Step-Index statt O(n*m) Neuberechnung.
  _StepInfo? _findCurrentStep(int routeIndex) {
    if (state.route == null) return null;

    final allSteps = state.route!.allSteps;
    if (allSteps.isEmpty) return null;

    final indices = _stepRouteIndices;
    if (indices == null || indices.length != allSteps.length) return null;

    // Finde den Step, dessen gecachter Route-Index am naechsten VOR/AUF uns liegt
    int bestStepIdx = 0;
    int bestDist = routeIndex + 1; // max moegliche Differenz

    for (int i = 0; i < allSteps.length; i++) {
      final stepRouteIdx = indices[i];
      if (stepRouteIdx <= routeIndex) {
        final diff = routeIndex - stepRouteIdx;
        if (diff < bestDist) {
          bestDist = diff;
          bestStepIdx = i;
        }
      }
    }

    // Der naechste significante Step nach dem aktuellen
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
      nextStepRouteIndex: nextStep != null && nextSignificantIdx < indices.length
          ? indices[nextSignificantIdx]
          : null,
    );
  }
}

class _StepInfo {
  final NavigationStep currentStep;
  final NavigationStep? nextStep;
  final int globalIndex;
  final LatLng nextStepLocation;
  final int? nextStepRouteIndex; // Gecachter Route-Index des naechsten Steps

  const _StepInfo({
    required this.currentStep,
    this.nextStep,
    required this.globalIndex,
    required this.nextStepLocation,
    this.nextStepRouteIndex,
  });
}
