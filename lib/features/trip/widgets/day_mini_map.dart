import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../data/models/trip.dart';

/// Mini-Karte für den Day Editor, zeigt Route + POIs des ausgewählten Tages
/// Aktualisiert den Kartenausschnitt automatisch bei POI-Aenderungen (Reroll/Delete)
class DayMiniMap extends StatefulWidget {
  final Trip trip;
  final int selectedDay;
  final LatLng startLocation;
  final List<LatLng>? routeSegment;
  final VoidCallback? onMarkerTap;

  const DayMiniMap({
    super.key,
    required this.trip,
    required this.selectedDay,
    required this.startLocation,
    this.routeSegment,
    this.onMarkerTap,
  });

  @override
  State<DayMiniMap> createState() => _DayMiniMapState();
}

class _DayMiniMapState extends State<DayMiniMap> {
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
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.travelplanner.app',
                maxZoom: 19,
              ),
              // Route-Segment
              if (widget.routeSegment != null && widget.routeSegment!.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: widget.routeSegment!,
                      strokeWidth: 4,
                      color: colorScheme.primary,
                      borderColor: colorScheme.primary.withOpacity(0.3),
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
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  // POI-Marker mit Nummern
                  ...stopsForDay.asMap().entries.map((entry) {
                    final index = entry.key;
                    final stop = entry.value;
                    return Marker(
                      point: stop.location,
                      width: 36,
                      height: 36,
                      child: Container(
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
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
              color: colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 8),
            Text(
              'Keine Stops fuer diesen Tag',
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.5),
                fontSize: 13,
              ),
            ),
          ],
        ),
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
  if (fullRoute.isEmpty) return [];

  // Finde den nächsten Punkt auf der Route für Start und Ende
  int startIndex = _findClosestPointIndex(fullRoute, segStart);
  int endIndex = _findClosestPointIndex(fullRoute, segEnd);

  // Sicherstellen dass Start vor Ende liegt
  if (startIndex > endIndex) {
    final temp = startIndex;
    startIndex = endIndex;
    endIndex = temp;
  }

  // Segment extrahieren (inklusive Start und Ende)
  if (endIndex >= fullRoute.length) {
    endIndex = fullRoute.length - 1;
  }

  return fullRoute.sublist(startIndex, endIndex + 1);
}

int _findClosestPointIndex(List<LatLng> points, LatLng target) {
  int closestIndex = 0;
  double minDistance = double.infinity;

  for (int i = 0; i < points.length; i++) {
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
