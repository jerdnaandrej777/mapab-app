import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../providers/map_controller_provider.dart';
import '../providers/route_planner_provider.dart';
import '../../trip/providers/trip_state_provider.dart';
import '../../poi/providers/poi_state_provider.dart';
import '../../../data/models/poi.dart';

/// Karten-Widget mit MapLibre/flutter_map
class MapView extends ConsumerStatefulWidget {
  final LatLng? initialCenter;
  final double initialZoom;

  const MapView({
    super.key,
    this.initialCenter,
    this.initialZoom = 6,
  });

  @override
  ConsumerState<MapView> createState() => _MapViewState();
}

class _MapViewState extends ConsumerState<MapView> {
  late final MapController _mapController;
  String? _selectedPOIId;

  // Standard-Zentrum: Europa (Deutschland)
  static const _defaultCenter = LatLng(50.0, 10.0);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    // Register controller globally after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mapControllerProvider.notifier).state = _mapController;
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tripState = ref.watch(tripStateProvider);
    final routePlanner = ref.watch(routePlannerProvider);
    final poiState = ref.watch(pOIStateNotifierProvider);

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: widget.initialCenter ?? _defaultCenter,
        initialZoom: widget.initialZoom,
        minZoom: 3,
        maxZoom: 18,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
        onTap: _onMapTap,
        onLongPress: _onMapLongPress,
      ),
      children: [
        // Karten-Tiles (OpenStreetMap)
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.travelplanner.app',
          maxZoom: 19,
        ),

        // Route-Polyline (wenn Route vorhanden)
        if (tripState.hasRoute || routePlanner.route != null)
          PolylineLayer(
            polylines: [
              Polyline(
                points: tripState.route?.coordinates ??
                    routePlanner.route?.coordinates ??
                    [],
                color: Theme.of(context).colorScheme.primary,
                strokeWidth: 5,
                borderColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                borderStrokeWidth: 2,
              ),
            ],
          ),

        // POI-Marker Layer
        if (poiState.filteredPOIs.isNotEmpty)
          MarkerLayer(
            markers: poiState.filteredPOIs.map((poi) {
              return Marker(
                point: poi.location,
                width: _selectedPOIId == poi.id ? 48 : (poi.isMustSee ? 40 : 32),
                height: _selectedPOIId == poi.id ? 48 : (poi.isMustSee ? 40 : 32),
                child: POIMarker(
                  icon: poi.categoryIcon,
                  isHighlight: poi.isMustSee,
                  isSelected: _selectedPOIId == poi.id,
                  onTap: () => _onPOITap(poi),
                ),
              );
            }).toList(),
          ),

        // Start-Marker
        if (routePlanner.startLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point: routePlanner.startLocation!,
                width: 24,
                height: 24,
                child: const StartMarker(),
              ),
            ],
          ),

        // Ziel-Marker
        if (routePlanner.endLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point: routePlanner.endLocation!,
                width: 24,
                height: 24,
                child: const EndMarker(),
              ),
            ],
          ),

        // Trip-Stops Marker
        if (tripState.hasStops)
          MarkerLayer(
            markers: tripState.stops.asMap().entries.map((entry) {
              final index = entry.key;
              final poi = entry.value;
              return Marker(
                point: poi.location,
                width: 32,
                height: 32,
                child: StopMarker(
                  number: index + 1,
                  onTap: () => _onPOITap(poi),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    // POI-Auswahl zurücksetzen
    if (_selectedPOIId != null) {
      setState(() {
        _selectedPOIId = null;
      });
    }
  }

  void _onMapLongPress(TapPosition tapPosition, LatLng point) {
    _showLocationMenu(context, point);
  }

  void _onPOITap(POI poi) {
    setState(() {
      _selectedPOIId = poi.id;
    });

    // POI-Preview Sheet anzeigen
    _showPOIPreview(poi);
  }

  void _showPOIPreview(POI poi) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // POI Info Row
            Row(
              children: [
                // Icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Color(poi.category?.colorValue ?? 0xFF666666)
                        .withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      poi.categoryIcon,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Name & Category
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        poi.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            poi.categoryLabel,
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 14,
                            ),
                          ),
                          if (poi.isMustSee) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                '⭐ Must-See',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Beschreibung (wenn vorhanden)
            if (poi.shortDescription.isNotEmpty) ...[
              Text(
                poi.shortDescription,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
            ],

            // Detour Info (wenn verfügbar)
            if (poi.detourKm != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.route, size: 16, color: colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      '+${poi.detourKm!.toStringAsFixed(1)} km Umweg',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.timer, size: 16, color: colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      '+${poi.detourMinutes ?? 0} Min.',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                // Details Button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      ref.read(pOIStateNotifierProvider.notifier).selectPOI(poi);
                      context.push('/poi/${poi.id}');
                    },
                    icon: const Icon(Icons.info_outline),
                    label: const Text('Details'),
                  ),
                ),
                const SizedBox(width: 12),
                // Zur Route Button
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      ref.read(tripStateProvider.notifier).addStop(poi);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${poi.name} zur Route hinzugefügt'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Zur Route'),
                  ),
                ),
              ],
            ),

            // Safe Area padding
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  void _showLocationMenu(BuildContext context, LatLng point) {
    final routePlanner = ref.read(routePlannerProvider.notifier);

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.trip_origin, color: Colors.green),
              title: const Text('Als Start setzen'),
              onTap: () {
                Navigator.pop(context);
                routePlanner.setStart(point, 'Gewählter Punkt');
              },
            ),
            ListTile(
              leading: const Icon(Icons.place, color: Colors.red),
              title: const Text('Als Ziel setzen'),
              onTap: () {
                Navigator.pop(context);
                routePlanner.setEnd(point, 'Gewählter Punkt');
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_location),
              title: const Text('Als Stopp hinzufügen'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Stopp hinzufügen
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom Marker Widget für POIs
class POIMarker extends StatelessWidget {
  final String icon;
  final bool isHighlight;
  final bool isSelected;
  final VoidCallback? onTap;

  const POIMarker({
    super.key,
    required this.icon,
    this.isHighlight = false,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isSelected ? 48 : (isHighlight ? 40 : 32),
        height: isSelected ? 48 : (isHighlight ? 40 : 32),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blue
              : (isHighlight ? Colors.orange : Colors.white),
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.grey.shade300,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            icon,
            style: TextStyle(
              fontSize: isSelected ? 24 : (isHighlight ? 20 : 16),
            ),
          ),
        ),
      ),
    );
  }
}

/// Start-Marker Widget
class StartMarker extends StatelessWidget {
  const StartMarker({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.green,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }
}

/// Ziel-Marker Widget
class EndMarker extends StatelessWidget {
  const EndMarker({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }
}

/// Stop-Marker Widget mit Nummer
class StopMarker extends StatelessWidget {
  final int number;
  final VoidCallback? onTap;

  const StopMarker({
    super.key,
    required this.number,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
            ),
          ],
        ),
        child: Center(
          child: Text(
            '$number',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
