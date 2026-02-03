import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart' as ll2;
import 'package:maplibre_gl/maplibre_gl.dart' as ml;
import '../../data/models/route.dart' hide LatLngConverter;
import '../../data/models/trip.dart';
import 'providers/navigation_provider.dart';
import 'providers/navigation_tts_provider.dart';
import 'utils/latlong_converter.dart';
import 'widgets/maneuver_banner.dart';
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

  @override
  void initState() {
    super.initState();

    // Navigation starten
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(navigationNotifierProvider.notifier).startNavigation(
            baseRoute: widget.route,
            stops: widget.stops,
          );
      // TTS Provider initialisieren (lauscht automatisch)
      ref.read(navigationTtsProvider);
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final navState = ref.watch(navigationNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // Karte auf Position zentrieren (3D)
    _updateMapPosition(navState);

    // Route-Linien aktualisieren
    _updateRouteSources(navState);

    // POI-Marker Farben aktualisieren
    _updatePOIMarkerColors(navState, colorScheme);

    // Ziel erreicht Dialog
    if (navState.status == NavigationStatus.arrivedAtDestination) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showArrivalDialog();
      });
    }

    return Scaffold(
      body: Stack(
        children: [
          // MapLibre 3D-Karte
          _buildMap(navState, colorScheme),

          // User-Position Marker (immer in Bildschirmmitte waehrend Navigation)
          if (!_isOverviewMode && navState.hasPosition)
            Center(
              child: _buildUserPositionMarker(colorScheme),
            ),

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

          // POI-Annaeherungs-Card
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
      rotateGesturesEnabled: true,
      tiltGesturesEnabled: true,
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
    if (_mapController == null || _poiCircles.isEmpty) return;

    for (final entry in _poiCircles.entries) {
      final isVisited = navState.visitedStopIds.contains(entry.key);
      final targetColor = isVisited
          ? _colorToHex(colorScheme.outline)
          : _colorToHex(colorScheme.secondary);

      try {
        _mapController!.updateCircle(
          entry.value,
          ml.CircleOptions(circleColor: targetColor),
        );
      } catch (_) {
        // Circle noch nicht bereit
      }
    }
  }

  // ---------------------------------------------------------------------------
  // User-Position Widget (zentriert, da Kamera GPS folgt)
  // ---------------------------------------------------------------------------

  Widget _buildUserPositionMarker(ColorScheme colorScheme) {
    return IgnorePointer(
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colorScheme.primary,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.4),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(
          Icons.navigation,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Kamera-Updates (3D-Perspektive)
  // ---------------------------------------------------------------------------

  void _updateMapPosition(NavigationState navState) {
    if (_isOverviewMode || !navState.hasPosition || _mapController == null) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _mapController == null) return;
      try {
        _mapController!.animateCamera(
          ml.CameraUpdate.newCameraPosition(
            ml.CameraPosition(
              target: LatLngConverter.toMapLibre(navState.currentPosition!),
              zoom: 16,
              tilt: 50,
              bearing: navState.currentHeading ?? 0,
            ),
          ),
          duration: const Duration(milliseconds: 500),
        );
      } catch (_) {
        // Controller nicht bereit
      }
    });
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
      if (!mounted || _mapController == null) return;

      try {
        // Gefahrener Teil (grau)
        final completedCoords = _getCompletedSegment(routeCoords, navState);
        _mapController!.setGeoJsonSource(
          _completedSourceId,
          completedCoords.length >= 2
              ? LatLngConverter.toGeoJsonLine(completedCoords)
              : LatLngConverter.emptyGeoJson,
        );

        // Verbleibender Teil (farbig)
        final remainingCoords = _getRemainingSegment(routeCoords, navState);
        _mapController!.setGeoJsonSource(
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

    if (_isOverviewMode && _mapController != null) {
      // Gesamte Route zeigen, flach (2D)
      final coords = widget.route.coordinates;
      if (coords.isNotEmpty) {
        final bounds = LatLngConverter.boundsFromCoords(coords);
        _mapController!.animateCamera(
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
          if (!mounted || _mapController == null) return;
          _mapController!.animateCamera(
            ml.CameraUpdate.bearingTo(0),
            duration: const Duration(milliseconds: 600),
          );
          _mapController!.animateCamera(
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
              context.pop();
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
              context.pop();
            },
            child: const Text('Fertig'),
          ),
        ],
      ),
    );
  }
}
