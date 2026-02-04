import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart' as ll2;
import 'package:maplibre_gl/maplibre_gl.dart' as ml;
import '../../data/models/route.dart' hide LatLngConverter;
import '../../data/models/trip.dart';
import 'providers/navigation_provider.dart';
import 'providers/navigation_poi_discovery_provider.dart';
import 'providers/navigation_tts_provider.dart';
import 'services/position_interpolator.dart';
import 'utils/latlong_converter.dart';
import 'widgets/maneuver_banner.dart';
import 'widgets/must_see_poi_card.dart';
import 'widgets/navigation_bottom_bar.dart';
import 'widgets/poi_approach_card.dart';

/// Tile-Style URL (OpenFreeMap - kostenlos, kein API-Key)
const _mapStyleUrl = 'https://tiles.openfreemap.org/styles/liberty';

/// Flutter Color -> CSS Hex-String (ohne Alpha)
String _colorToHex(Color color) {
  final r = (color.r * 255).round();
  final g = (color.g * 255).round();
  final b = (color.b * 255).round();
  return '#${r.toRadixString(16).padLeft(2, '0')}'
      '${g.toRadixString(16).padLeft(2, '0')}'
      '${b.toRadixString(16).padLeft(2, '0')}';
}

/// Vollbild-Navigationsansicht mit Turn-by-Turn Anweisungen und 3D-Perspektive
class NavigationScreen extends ConsumerStatefulWidget {
  final AppRoute route;
  final List<TripStop>? stops;

  const NavigationScreen({
    super.key,
    required this.route,
    this.stops,
  });

  @override
  ConsumerState<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends ConsumerState<NavigationScreen> {
  // MapLibre Controller (nullable - erst nach onMapCreated verfuegbar)
  ml.MapLibreMapController? _mapController;
  bool _isOverviewMode = false;
  bool _isStyleLoaded = false;
  bool _sourcesInitialized = false;

  // GeoJSON Source/Layer IDs
  static const _completedSourceId = 'completed-route-source';
  static const _completedLayerId = 'completed-route-layer';
  static const _remainingSourceId = 'remaining-route-source';
  static const _remainingLayerId = 'remaining-route-layer';

  // Marker-Referenzen fuer Updates
  final Map<String, ml.Circle> _poiCircles = {};
  ml.Circle? _userCircle;

  // Fluessige Positions-Interpolation
  final PositionInterpolator _interpolator = PositionInterpolator();
  StreamSubscription<InterpolatedPosition>? _interpolationSub;
  NavigationState? _lastNavState;

  // Verhindert mehrfache Anzeige des Ziel-Dialogs
  bool _arrivalDialogShown = false;

  @override
  void initState() {
    super.initState();

    // Interpolation-Stream abonnieren fuer fluessige Updates
    _interpolationSub = _interpolator.positionStream.listen(_onInterpolatedPosition);

    // Navigation starten
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(navigationNotifierProvider.notifier).startNavigation(
            baseRoute: widget.route,
            stops: widget.stops,
          );
      // TTS Provider initialisieren (lauscht automatisch)
      ref.read(navigationTtsProvider);

      // Must-See POI Discovery starten
      ref.read(navigationPOIDiscoveryNotifierProvider.notifier)
          .startDiscovery(widget.route, widget.stops ?? []);
    });
  }

  @override
  void dispose() {
    _interpolationSub?.cancel();
    _interpolator.dispose();
    _mapController?.dispose();
    // Alle Navigation-Provider sauber stoppen
    ref.read(navigationNotifierProvider.notifier).stopNavigation();
    ref.read(navigationTtsProvider.notifier).reset();
    ref.read(navigationPOIDiscoveryNotifierProvider.notifier).reset();
    super.dispose();
  }

  /// Wird ~60x pro Sekunde vom Interpolator aufgerufen
  void _onInterpolatedPosition(InterpolatedPosition interpolated) {
    if (!mounted || _isOverviewMode) return;
    // Controller lokal capturen - verhindert null-zwischen-check-und-nutzung Race
    final controller = _mapController;
    if (controller == null) return;

    // User-Circle fluessig bewegen
    final circle = _userCircle;
    if (circle != null) {
      try {
        controller.updateCircle(
          circle,
          ml.CircleOptions(
            geometry: LatLngConverter.toMapLibre(interpolated.position),
          ),
        );
      } catch (_) {}
    }

    // Kamera fluessig nachfuehren (kurze Animation fuer Uebergaenge)
    try {
      controller.animateCamera(
        ml.CameraUpdate.newCameraPosition(
          ml.CameraPosition(
            target: LatLngConverter.toMapLibre(interpolated.position),
            zoom: 16,
            tilt: 50,
            bearing: interpolated.bearing,
          ),
        ),
        duration: const Duration(milliseconds: 100),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final navState = ref.watch(navigationNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final discoveryState = ref.watch(navigationPOIDiscoveryNotifierProvider);

    // Interpolator mit neuem GPS-Update fuettern
    _feedInterpolator(navState);

    // Route-Linien aktualisieren
    _updateRouteSources(navState);

    // POI-Marker Farben aktualisieren
    _updatePOIMarkerColors(navState, colorScheme);

    // Ziel erreicht Dialog (nur einmal anzeigen)
    if (navState.status == NavigationStatus.arrivedAtDestination &&
        !_arrivalDialogShown) {
      _arrivalDialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showArrivalDialog();
      });
    }

    return Scaffold(
      body: Stack(
        children: [
          // MapLibre 3D-Karte
          _buildMap(navState, colorScheme),

          // Manoever-Banner (oben)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ManeuverBanner(
              currentStep: navState.currentStep,
              nextStep: navState.nextStep,
              distanceToNextStepMeters: navState.distanceToNextStepMeters,
            ),
          ),

          // Rerouting-Anzeige
          if (navState.isRerouting)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Route wird neu berechnet...',
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
                  ],
                ),
              ),
            ),

          // Must-See POI Discovery Card (ueber POI-Approach-Card)
          if (discoveryState.currentApproachingPOI != null &&
              discoveryState.distanceToApproachingPOI != null)
            Positioned(
              bottom: navState.status == NavigationStatus.arrivedAtWaypoint
                  ? 240 // ueber der POI-Approach-Card
                  : 160,
              left: 0,
              right: 0,
              child: MustSeePOICard(
                poi: discoveryState.currentApproachingPOI!,
                distanceMeters: discoveryState.distanceToApproachingPOI!,
                onAddStop: () {
                  final poi = discoveryState.currentApproachingPOI!;
                  final stop = TripStop(
                    poiId: poi.id,
                    name: poi.name,
                    latitude: poi.latitude,
                    longitude: poi.longitude,
                    categoryId: poi.categoryId,
                    order: 0,
                  );
                  ref
                      .read(navigationNotifierProvider.notifier)
                      .addWaypointDuringNavigation(stop);
                  ref
                      .read(navigationPOIDiscoveryNotifierProvider.notifier)
                      .dismissPOI(poi.id);
                },
                onDismiss: () {
                  ref
                      .read(navigationPOIDiscoveryNotifierProvider.notifier)
                      .dismissPOI(
                          discoveryState.currentApproachingPOI!.id);
                },
              ),
            ),

          // POI-Annaeherungs-Card (Trip-Stops)
          if (navState.nextPOIStop != null &&
              navState.distanceToNextPOIMeters < 500 &&
              navState.status == NavigationStatus.arrivedAtWaypoint)
            Positioned(
              bottom: 160,
              left: 0,
              right: 0,
              child: POIApproachCard(
                stop: navState.nextPOIStop!,
                distanceMeters: navState.distanceToNextPOIMeters,
                onVisited: () {
                  ref
                      .read(navigationNotifierProvider.notifier)
                      .markStopVisited(navState.nextPOIStop!.poiId);
                },
                onSkip: () {
                  ref
                      .read(navigationNotifierProvider.notifier)
                      .markStopVisited(navState.nextPOIStop!.poiId);
                },
              ),
            ),

          // Loading-Overlay
          if (navState.isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      'Navigation wird vorbereitet...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Bottom Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: NavigationBottomBar(
              distanceToDestinationKm: navState.distanceToDestinationKm,
              etaMinutes: navState.etaMinutes,
              currentSpeedKmh: navState.currentSpeedKmh,
              isMuted: navState.isMuted,
              onToggleMute: () {
                ref
                    .read(navigationNotifierProvider.notifier)
                    .toggleMute();
              },
              onStop: _stopNavigation,
              onOverview: _toggleOverview,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Map
  // ---------------------------------------------------------------------------

  Widget _buildMap(NavigationState navState, ColorScheme colorScheme) {
    final startPos = navState.currentPosition ?? widget.route.start;

    return ml.MapLibreMap(
      initialCameraPosition: ml.CameraPosition(
        target: LatLngConverter.toMapLibre(startPos),
        zoom: 16,
        tilt: 50,
        bearing: navState.currentHeading ?? 0,
      ),
      styleString: _mapStyleUrl,
      onMapCreated: _onMapCreated,
      onStyleLoadedCallback: () => _onStyleLoaded(colorScheme),
      compassEnabled: false,
      rotateGesturesEnabled: _isOverviewMode,
      tiltGesturesEnabled: false,
      zoomGesturesEnabled: true,
      scrollGesturesEnabled: true,
      trackCameraPosition: false,
      myLocationEnabled: false,
      attributionButtonPosition: ml.AttributionButtonPosition.bottomLeft,
    );
  }

  void _onMapCreated(ml.MapLibreMapController controller) {
    _mapController = controller;
  }

  Future<void> _onStyleLoaded(ColorScheme colorScheme) async {
    _isStyleLoaded = true;
    await _initSourcesAndLayers(colorScheme);
    await _initMarkers(colorScheme);

    // Initiale Route-Daten setzen
    final navState = ref.read(navigationNotifierProvider);
    _updateRouteSources(navState);
  }

  // ---------------------------------------------------------------------------
  // GeoJSON Sources + Line Layers (einmalig nach Style-Load)
  // ---------------------------------------------------------------------------

  Future<void> _initSourcesAndLayers(ColorScheme colorScheme) async {
    if (_sourcesInitialized || _mapController == null) return;
    _sourcesInitialized = true;

    final controller = _mapController!;

    try {
      // Verbleibende Route (farbig) - zuerst hinzufuegen (wird unten gezeichnet)
      await controller.addGeoJsonSource(
        _remainingSourceId,
        LatLngConverter.emptyGeoJson,
      );
      await controller.addLineLayer(
        _remainingSourceId,
        _remainingLayerId,
        ml.LineLayerProperties(
          lineColor: _colorToHex(colorScheme.primary),
          lineWidth: 6.0,
          lineOpacity: 1.0,
          lineJoin: 'round',
          lineCap: 'round',
        ),
      );

      // Gefahrener Teil (grau, halbtransparent) - darueber
      await controller.addGeoJsonSource(
        _completedSourceId,
        LatLngConverter.emptyGeoJson,
      );
      await controller.addLineLayer(
        _completedSourceId,
        _completedLayerId,
        ml.LineLayerProperties(
          lineColor: _colorToHex(colorScheme.outline),
          lineWidth: 5.0,
          lineOpacity: 0.4,
          lineJoin: 'round',
          lineCap: 'round',
        ),
      );
    } catch (e) {
      debugPrint('[Navigation] Fehler beim Initialisieren der Layers: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Marker (Native Circle-Annotations)
  // ---------------------------------------------------------------------------

  Future<void> _initMarkers(ColorScheme colorScheme) async {
    if (_mapController == null) return;
    final controller = _mapController!;

    try {
      // User-Position Marker (native, geo-positioniert)
      final startPos =
          ref.read(navigationNotifierProvider).currentPosition ??
              widget.route.start;
      _userCircle = await controller.addCircle(
        ml.CircleOptions(
          geometry: LatLngConverter.toMapLibre(startPos),
          circleRadius: 14,
          circleColor: _colorToHex(colorScheme.primary),
          circleStrokeWidth: 3,
          circleStrokeColor: '#FFFFFF',
        ),
      );

      // Ziel-Marker
      await controller.addCircle(
        ml.CircleOptions(
          geometry: LatLngConverter.toMapLibre(widget.route.end),
          circleRadius: 18,
          circleColor: _colorToHex(colorScheme.error),
          circleStrokeWidth: 2,
          circleStrokeColor: '#FFFFFF',
        ),
      );

      // POI-Stop Marker
      if (widget.stops != null) {
        for (final stop in widget.stops!) {
          final circle = await controller.addCircle(
            ml.CircleOptions(
              geometry: ml.LatLng(stop.latitude, stop.longitude),
              circleRadius: 16,
              circleColor: _colorToHex(colorScheme.secondary),
              circleStrokeWidth: 2,
              circleStrokeColor: '#FFFFFF',
            ),
          );
          _poiCircles[stop.poiId] = circle;
        }
      }
    } catch (e) {
      debugPrint('[Navigation] Fehler beim Erstellen der Marker: $e');
    }
  }

  void _updatePOIMarkerColors(
      NavigationState navState, ColorScheme colorScheme) {
    final controller = _mapController;
    if (controller == null || _poiCircles.isEmpty) return;

    for (final entry in _poiCircles.entries) {
      final isVisited = navState.visitedStopIds.contains(entry.key);
      final targetColor = isVisited
          ? _colorToHex(colorScheme.outline)
          : _colorToHex(colorScheme.secondary);

      try {
        controller.updateCircle(
          entry.value,
          ml.CircleOptions(circleColor: targetColor),
        );
      } catch (_) {
        // Circle noch nicht bereit
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Interpolator fuettern (ersetzt _updateUserCircle + _updateMapPosition)
  // ---------------------------------------------------------------------------

  void _feedInterpolator(NavigationState navState) {
    if (!navState.hasPosition || navState.route == null) return;

    // Nur bei echten Positions-Aenderungen den Interpolator fuettern
    if (_lastNavState?.currentPosition == navState.currentPosition &&
        _lastNavState?.currentHeading == navState.currentHeading) {
      return;
    }
    _lastNavState = navState;

    // Verwende snappedPosition (auf Route gesnappt) falls vorhanden
    final position = navState.snappedPosition ?? navState.currentPosition!;

    _interpolator.onGPSUpdate(
      position,
      navState.currentHeading ?? 0,
      navState.currentSpeedKmh ?? 0,
      navState.route!.baseRoute.coordinates,
      navState.matchedRouteIndex,
    );
  }

  // ---------------------------------------------------------------------------
  // Route-Linien Updates (GeoJSON)
  // ---------------------------------------------------------------------------

  void _updateRouteSources(NavigationState navState) {
    if (!_isStyleLoaded || _mapController == null) return;

    final routeCoords = navState.route?.baseRoute.coordinates ??
        widget.route.coordinates;

    if (routeCoords.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Controller lokal capturen - verhindert Race nach dispose
      final controller = _mapController;
      if (controller == null) return;

      try {
        // Gefahrener Teil (grau)
        final completedCoords = _getCompletedSegment(routeCoords, navState);
        controller.setGeoJsonSource(
          _completedSourceId,
          completedCoords.length >= 2
              ? LatLngConverter.toGeoJsonLine(completedCoords)
              : LatLngConverter.emptyGeoJson,
        );

        // Verbleibender Teil (farbig)
        final remainingCoords = _getRemainingSegment(routeCoords, navState);
        controller.setGeoJsonSource(
          _remainingSourceId,
          remainingCoords.length >= 2
              ? LatLngConverter.toGeoJsonLine(remainingCoords)
              : LatLngConverter.emptyGeoJson,
        );
      } catch (_) {
        // Sources noch nicht bereit
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Route-Segmente (unveraendert aus Originalversion)
  // ---------------------------------------------------------------------------

  /// Gibt den bereits gefahrenen Teil der Route zurueck
  List<ll2.LatLng> _getCompletedSegment(
      List<ll2.LatLng> coords, NavigationState navState) {
    final progress = navState.progress;
    final endIdx =
        (progress * coords.length).round().clamp(0, coords.length);
    if (endIdx <= 0) return [];
    return coords.sublist(0, endIdx);
  }

  /// Gibt den verbleibenden Teil der Route zurueck
  List<ll2.LatLng> _getRemainingSegment(
      List<ll2.LatLng> coords, NavigationState navState) {
    final progress = navState.progress;
    final startIdx =
        (progress * coords.length).round().clamp(0, coords.length - 1);
    return coords.sublist(startIdx);
  }

  // ---------------------------------------------------------------------------
  // Uebersicht-Modus
  // ---------------------------------------------------------------------------

  void _toggleOverview() {
    setState(() {
      _isOverviewMode = !_isOverviewMode;
    });

    if (_isOverviewMode) {
      _interpolator.pause();
    } else {
      _interpolator.resume();
    }

    // Controller lokal capturen
    final controller = _mapController;
    if (_isOverviewMode && controller != null) {
      // Gesamte Route zeigen, flach (2D)
      final coords = widget.route.coordinates;
      if (coords.length >= 2) {
        final bounds = LatLngConverter.boundsFromCoords(coords);
        controller.animateCamera(
          ml.CameraUpdate.newLatLngBounds(
            bounds,
            left: 60,
            top: 120,
            right: 60,
            bottom: 180,
          ),
          duration: const Duration(milliseconds: 800),
        );
        // Tilt und Bearing zuruecksetzen (2D Draufsicht)
        Future.delayed(const Duration(milliseconds: 100), () {
          if (!mounted) return;
          final ctrl = _mapController;
          if (ctrl == null) return;
          ctrl.animateCamera(
            ml.CameraUpdate.bearingTo(0),
            duration: const Duration(milliseconds: 600),
          );
          ctrl.animateCamera(
            ml.CameraUpdate.tiltTo(0),
            duration: const Duration(milliseconds: 600),
          );
        });
      }
    }
    // Beim Verlassen der Uebersicht stellt der naechste GPS-Tick
    // die 3D-Perspektive automatisch wieder her
  }

  // ---------------------------------------------------------------------------
  // Dialoge (unveraendert)
  // ---------------------------------------------------------------------------

  void _stopNavigation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Navigation beenden?'),
        content: const Text(
            'Möchtest du die Navigation wirklich beenden?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(navigationNotifierProvider.notifier).stopNavigation();
              ref.read(navigationTtsProvider.notifier).reset();
              ref.read(navigationPOIDiscoveryNotifierProvider.notifier).reset();
              if (context.mounted) {
                context.pop();
              }
            },
            child: const Text('Beenden'),
          ),
        ],
      ),
    );
  }

  void _showArrivalDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          Icons.flag,
          size: 48,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: const Text('Ziel erreicht!'),
        content: Text(
          'Du hast ${widget.route.endAddress} erreicht.',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(navigationNotifierProvider.notifier).stopNavigation();
              ref.read(navigationTtsProvider.notifier).reset();
              ref.read(navigationPOIDiscoveryNotifierProvider.notifier).reset();
              if (context.mounted) {
                context.pop();
              }
            },
            child: const Text('Fertig'),
          ),
        ],
      ),
    );
  }
}
