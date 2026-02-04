import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/utils/geo_utils.dart';
import '../../../data/models/poi.dart';
import '../../../data/models/route.dart';
import '../../../data/models/trip.dart';
import '../../../data/repositories/poi_repo.dart';
import '../services/route_matcher_service.dart';
import 'navigation_provider.dart';

part 'navigation_poi_discovery_provider.g.dart';

/// Schwellwerte fuer Must-See POI Erkennung
class _DiscoveryThresholds {
  /// Korridor-Breite fuer POI-Suche (km)
  static const double corridorBufferKm = 5.0;

  /// Distanz ab der die Card erscheint (Meter)
  static const double cardShowDistanceM = 1000;

  /// Distanz ab der TTS ausgeloest wird (Meter)
  static const double ttsAnnounceDistanceM = 500;

  /// Max. Umweg der toleriert wird (km)
  static const double maxDetourKm = 5.0;
}

/// State fuer die Must-See POI Erkennung waehrend der Navigation
class NavigationPOIDiscoveryState {
  /// Alle Must-See POIs im Routen-Korridor (sortiert nach Route-Position)
  final List<POI> mustSeePOIs;

  /// Aktuell nahester Must-See POI (fuer Card-Anzeige)
  final POI? currentApproachingPOI;

  /// Distanz zum aktuell nahesten POI
  final double? distanceToApproachingPOI;

  /// POIs die der User ignoriert hat
  final Set<String> dismissedPOIIds;

  /// POIs die bereits per TTS angekuendigt wurden
  final Set<String> announcedPOIIds;

  /// POI-IDs die bereits Trip-Stops sind (werden nicht angezeigt)
  final Set<String> existingStopIds;

  final bool isLoading;

  const NavigationPOIDiscoveryState({
    this.mustSeePOIs = const [],
    this.currentApproachingPOI,
    this.distanceToApproachingPOI,
    this.dismissedPOIIds = const {},
    this.announcedPOIIds = const {},
    this.existingStopIds = const {},
    this.isLoading = false,
  });

  NavigationPOIDiscoveryState copyWith({
    List<POI>? mustSeePOIs,
    POI? currentApproachingPOI,
    double? distanceToApproachingPOI,
    Set<String>? dismissedPOIIds,
    Set<String>? announcedPOIIds,
    Set<String>? existingStopIds,
    bool? isLoading,
    bool clearApproaching = false,
  }) {
    return NavigationPOIDiscoveryState(
      mustSeePOIs: mustSeePOIs ?? this.mustSeePOIs,
      currentApproachingPOI: clearApproaching
          ? null
          : (currentApproachingPOI ?? this.currentApproachingPOI),
      distanceToApproachingPOI: clearApproaching
          ? null
          : (distanceToApproachingPOI ?? this.distanceToApproachingPOI),
      dismissedPOIIds: dismissedPOIIds ?? this.dismissedPOIIds,
      announcedPOIIds: announcedPOIIds ?? this.announcedPOIIds,
      existingStopIds: existingStopIds ?? this.existingStopIds,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  /// Ob ein POI bereit fuer TTS-Ankuendigung ist
  bool shouldAnnouncePOI(String poiId) {
    return !announcedPOIIds.contains(poiId) &&
        !dismissedPOIIds.contains(poiId) &&
        !existingStopIds.contains(poiId);
  }
}

/// Provider der Must-See POIs entlang der Route erkennt und ankuendigt
@Riverpod(keepAlive: true)
class NavigationPOIDiscoveryNotifier
    extends _$NavigationPOIDiscoveryNotifier {
  final RouteMatcherService _routeMatcher = RouteMatcherService();

  @override
  NavigationPOIDiscoveryState build() {
    // NavigationState beobachten fuer Proximity-Updates
    ref.listen<NavigationState>(
      navigationNotifierProvider,
      (previous, next) => _onNavigationUpdate(next),
    );
    return const NavigationPOIDiscoveryState();
  }

  /// Startet die POI-Erkennung fuer eine Route
  Future<void> startDiscovery(
    AppRoute route,
    List<TripStop> existingStops,
  ) async {
    final stopIds = existingStops.map((s) => s.poiId).toSet();

    state = state.copyWith(
      isLoading: true,
      existingStopIds: stopIds,
      dismissedPOIIds: {},
      announcedPOIIds: {},
      clearApproaching: true,
    );

    try {
      final poiRepo = ref.read(poiRepositoryProvider);

      // Korridor-Bounds berechnen
      final bounds = GeoUtils.calculateBoundsWithBuffer(
        route.coordinates,
        _DiscoveryThresholds.corridorBufferKm,
      );

      debugPrint('[POI-Discovery] Lade Must-See POIs im '
          '${_DiscoveryThresholds.corridorBufferKm}km Korridor...');

      final allPOIs = await poiRepo.loadPOIsInBounds(bounds: bounds);

      // Nur Must-See POIs + nicht bereits im Trip
      final mustSeePOIs = allPOIs.where((poi) {
        if (!poi.isMustSee) return false;
        if (stopIds.contains(poi.id)) return false;
        return true;
      }).map((poi) {
        // Route-Position und Umweg berechnen
        final routePosition = GeoUtils.calculateRoutePosition(
          poi.location,
          route.coordinates,
        );
        final detourKm = GeoUtils.calculateDetour(
          poi.location,
          route.coordinates,
        );
        return poi.copyWith(
          routePosition: routePosition,
          detourKm: detourKm,
        );
      }).where((poi) {
        // Max Umweg filtern
        return (poi.detourKm ?? 999) <=
            _DiscoveryThresholds.maxDetourKm;
      }).toList();

      // Nach Route-Position sortieren
      mustSeePOIs.sort((a, b) =>
          (a.routePosition ?? 0).compareTo(b.routePosition ?? 0));

      debugPrint('[POI-Discovery] ${mustSeePOIs.length} Must-See POIs '
          'im Korridor gefunden');

      state = state.copyWith(
        mustSeePOIs: mustSeePOIs,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('[POI-Discovery] Fehler beim Laden: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  /// Wird bei jedem NavigationState-Update aufgerufen
  void _onNavigationUpdate(NavigationState navState) {
    if (!navState.isNavigating || !navState.hasPosition) return;
    if (state.mustSeePOIs.isEmpty) return;

    final currentPos = navState.snappedPosition ?? navState.currentPosition!;
    final currentProgress = navState.progress;

    // Finde den naehesten Must-See POI der VOR uns auf der Route liegt
    POI? closestPOI;
    double closestDistance = double.infinity;

    for (final poi in state.mustSeePOIs) {
      // Ueberspringe ignorierte, angekuendigte, und bereits besuchte
      if (state.dismissedPOIIds.contains(poi.id)) continue;
      if (state.existingStopIds.contains(poi.id)) continue;

      // Nur POIs die noch vor uns auf der Route liegen
      final poiProgress = poi.routePosition ?? 0;
      if (poiProgress < currentProgress - 0.01) continue; // schon vorbei

      // Distanz berechnen
      final dist = _routeMatcher.distanceBetween(
        currentPos,
        LatLng(poi.latitude, poi.longitude),
      );

      if (dist < closestDistance &&
          dist < _DiscoveryThresholds.cardShowDistanceM) {
        closestDistance = dist;
        closestPOI = poi;
      }
    }

    if (closestPOI != null) {
      state = state.copyWith(
        currentApproachingPOI: closestPOI,
        distanceToApproachingPOI: closestDistance,
      );
    } else if (state.currentApproachingPOI != null) {
      // Kein POI mehr in der Naehe → Card verstecken
      state = state.copyWith(clearApproaching: true);
    }
  }

  /// POI als ignoriert markieren (User hat "Ignorieren" gedrueckt)
  void dismissPOI(String poiId) {
    state = state.copyWith(
      dismissedPOIIds: {...state.dismissedPOIIds, poiId},
      clearApproaching: true,
    );
    debugPrint('[POI-Discovery] POI ignoriert: $poiId');
  }

  /// Markiert einen POI als per TTS angekuendigt
  void markAsAnnounced(String poiId) {
    state = state.copyWith(
      announcedPOIIds: {...state.announcedPOIIds, poiId},
    );
  }

  /// POI als neuen Stop hinzugefuegt
  void markAsAdded(String poiId) {
    state = state.copyWith(
      existingStopIds: {...state.existingStopIds, poiId},
      clearApproaching: true,
    );
    debugPrint('[POI-Discovery] POI zum Trip hinzugefuegt: $poiId');
  }

  /// Reset bei Navigation-Ende
  void reset() {
    state = const NavigationPOIDiscoveryState();
  }

  /// Schwellwert fuer TTS-Ankuendigung (wird vom TTS-Provider verwendet)
  static double get ttsThresholdMeters =>
      _DiscoveryThresholds.ttsAnnounceDistanceM;
}
