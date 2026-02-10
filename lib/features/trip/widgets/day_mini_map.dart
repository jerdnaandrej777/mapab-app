import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../data/models/poi.dart';
import '../../../data/models/trip.dart';
import '../../../data/providers/favorites_provider.dart';

/// Mini-Karte für den Day Editor, zeigt Route + POIs des ausgewählten Tages
/// Aktualisiert den Kartenausschnitt automatisch bei POI-Aenderungen (Reroll/Delete)
/// Zeigt optional empfohlene POIs als halbtransparente Marker
class DayMiniMap extends ConsumerStatefulWidget {
  final Trip trip;
  final int selectedDay;
  final LatLng startLocation;
  final List<LatLng>? routeSegment;
  final List<POI> recommendedPOIs;
  final ValueChanged<POI>? onMarkerTap;
  final ValueChanged<TripStop>? onStopTap;
  final bool showTileLayer;

  const DayMiniMap({
    super.key,
    required this.trip,
    required this.selectedDay,
    required this.startLocation,
    this.routeSegment,
    this.recommendedPOIs = const [],
    this.onMarkerTap,
    this.onStopTap,
    this.showTileLayer = true,
  });

  @override
  ConsumerState<DayMiniMap> createState() => _DayMiniMapState();
}

class _DayMiniMapState extends ConsumerState<DayMiniMap> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant DayMiniMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Kartenausschnitt anpassen wenn Trip-Daten sich geaendert haben (Reroll/Delete)
    if (oldWidget.trip != widget.trip ||
        oldWidget.selectedDay != widget.selectedDay ||
        _routeSegmentChanged(oldWidget.routeSegment, widget.routeSegment)) {
      _refitCamera();
    }
  }

  bool _routeSegmentChanged(List<LatLng>? a, List<LatLng>? b) {
    if (a == null && b == null) return false;
    if (a == null || b == null) return true;
    if (a.length != b.length) return true;
    if (a.isNotEmpty && b.isNotEmpty) {
      if (a.first != b.first || a.last != b.last) return true;
    }
    return false;
  }

  List<LatLng> _collectAllPoints() {
    final allPoints = <LatLng>[widget.startLocation];
    final stopsForDay = widget.trip.getStopsForDay(widget.selectedDay);
    for (final stop in stopsForDay) {
      allPoints.add(stop.location);
    }
    if (widget.routeSegment != null && widget.routeSegment!.isNotEmpty) {
      allPoints.addAll(widget.routeSegment!);
    }
    // Empfohlene POIs einbeziehen (fuer korrektes Bounds-Fitting)
    for (final poi in widget.recommendedPOIs) {
      allPoints.add(poi.location);
    }
    return allPoints;
  }

  void _refitCamera() {
    final allPoints = _collectAllPoints();
    if (allPoints.length < 2) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: LatLngBounds.fromPoints(allPoints),
            padding: const EdgeInsets.all(40),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final favoriteIds =
        ref.watch(favoritePOIsProvider).map((poi) => poi.id).toSet();
    final stopsForDay = widget.trip.getStopsForDay(widget.selectedDay);
    final isMultiDay = widget.trip.actualDays > 1;

    // Punkte für Bounds berechnen
    final allPoints = _collectAllPoints();

    // Fallback wenn keine Punkte
    if (allPoints.length < 2) {
      return _buildEmptyState(colorScheme);
    }

    // Start-Punkt für diesen Tag
    LatLng dayStart;
    if (!isMultiDay || widget.selectedDay == 1) {
      dayStart = widget.startLocation;
    } else {
      final prevDayStops = widget.trip.getStopsForDay(widget.selectedDay - 1);
      dayStart = prevDayStops.isNotEmpty
          ? prevDayStops.last.location
          : widget.startLocation;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: RepaintBoundary(
        child: SizedBox(
          height: 180,
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCameraFit: CameraFit.bounds(
                bounds: LatLngBounds.fromPoints(allPoints),
                padding: const EdgeInsets.all(40),
              ),
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
              ),
            ),
            children: [
              if (widget.showTileLayer)
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.travelplanner.app',
                  maxZoom: 19,
                ),
              // Route-Segment
              if (widget.routeSegment != null &&
                  widget.routeSegment!.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: widget.routeSegment!,
                      strokeWidth: 4,
                      color: colorScheme.primary,
                      borderColor: colorScheme.primary.withValues(alpha: 0.3),
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
              // Marker
              MarkerLayer(
                markers: [
                  // Start-Marker
                  Marker(
                    point: dayStart,
                    width: 36,
                    height: 36,
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorScheme.tertiary,
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: colorScheme.surface, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.shadow.withValues(alpha: 0.2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.play_arrow,
                        color: colorScheme.onTertiary,
                        size: 18,
                      ),
                    ),
                  ),
                  // Empfohlene POIs (halbtransparent, Stern-Icon)
                  ...widget.recommendedPOIs.map((poi) {
                    return Marker(
                      point: poi.location,
                      width: 30,
                      height: 30,
                      child: GestureDetector(
                        onTap: () => widget.onMarkerTap?.call(poi),
                        child: Container(
                          decoration: BoxDecoration(
                            color: colorScheme.tertiary.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  colorScheme.tertiary.withValues(alpha: 0.8),
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            Icons.auto_awesome,
                            color: colorScheme.onTertiary,
                            size: 14,
                          ),
                        ),
                      ),
                    );
                  }),
                  // POI-Marker mit Nummern
                  ...stopsForDay.asMap().entries.map((entry) {
                    final index = entry.key;
                    final stop = entry.value;
                    final isFavorite = favoriteIds.contains(stop.poiId);
                    return Marker(
                      point: stop.location,
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () => widget.onStopTap?.call(stop),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              left: 2,
                              top: 2,
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: colorScheme.surface,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: colorScheme.shadow
                                          .withValues(alpha: 0.2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      color: colorScheme.onPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (isFavorite)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: _FavoriteBadge(colorScheme: colorScheme),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.map_outlined,
              size: 40,
              color: colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 8),
            Text(
              'Keine Stops fuer diesen Tag',
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteBadge extends StatelessWidget {
  final ColorScheme colorScheme;

  const _FavoriteBadge({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
        border: Border.all(color: colorScheme.surface, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 2,
          ),
        ],
      ),
      child: const Icon(
        Icons.favorite,
        size: 8,
        color: Colors.white,
      ),
    );
  }
}

/// Extrahiert ein Route-Segment zwischen zwei Punkten aus der Gesamt-Route
List<LatLng> extractRouteSegment(
  List<LatLng> fullRoute,
  LatLng segStart,
  LatLng segEnd,
) {
  return extractRouteSegmentThroughWaypoints(
    fullRoute,
    [segStart, segEnd],
  );
}

/// Extrahiert ein Segment entlang geordneter Wegpunkte.
/// Die Suchindizes laufen strikt vorwaerts, damit bei Rundreisen der
/// spaetere Route-Abschnitt gewaehlt wird.
List<LatLng> extractRouteSegmentThroughWaypoints(
  List<LatLng> fullRoute,
  List<LatLng> waypoints,
) {
  if (fullRoute.isEmpty || waypoints.isEmpty) return const [];

  final cleanedWaypoints = _dedupeConsecutiveWaypoints(waypoints);
  if (cleanedWaypoints.isEmpty) return const [];

  final indices = <int>[];
  var searchStartIndex = 0;
  for (final waypoint in cleanedWaypoints) {
    final index = _findClosestPointIndexFrom(
      fullRoute,
      waypoint,
      startIndex: searchStartIndex,
    );
    indices.add(index);
    searchStartIndex = index;
  }

  final startIndex = indices.first.clamp(0, fullRoute.length - 1);
  final endIndex = indices.last.clamp(startIndex, fullRoute.length - 1);
  return fullRoute.sublist(startIndex, endIndex + 1);
}

List<LatLng> _dedupeConsecutiveWaypoints(List<LatLng> waypoints) {
  if (waypoints.isEmpty) return const [];
  final result = <LatLng>[waypoints.first];
  for (int i = 1; i < waypoints.length; i++) {
    if (_haversineDistance(result.last, waypoints[i]) > 0.01) {
      result.add(waypoints[i]);
    }
  }
  return result;
}

int _findClosestPointIndexFrom(
  List<LatLng> points,
  LatLng target, {
  required int startIndex,
}) {
  if (points.isEmpty) return 0;
  final clampedStart = startIndex.clamp(0, points.length - 1);
  int closestIndex = 0;
  double minDistance = double.infinity;

  for (int i = clampedStart; i < points.length; i++) {
    final distance = _haversineDistance(points[i], target);
    if (distance < minDistance) {
      minDistance = distance;
      closestIndex = i;
    }
  }

  return closestIndex;
}

double _haversineDistance(LatLng a, LatLng b) {
  const R = 6371.0; // Erdradius in km
  final dLat = _toRadians(b.latitude - a.latitude);
  final dLon = _toRadians(b.longitude - a.longitude);
  final lat1 = _toRadians(a.latitude);
  final lat2 = _toRadians(b.latitude);

  final hav = sin(dLat / 2) * sin(dLat / 2) +
      sin(dLon / 2) * sin(dLon / 2) * cos(lat1) * cos(lat2);
  final c = 2 * atan2(sqrt(hav), sqrt(1 - hav));
  return R * c;
}

double _toRadians(double degree) => degree * pi / 180;
