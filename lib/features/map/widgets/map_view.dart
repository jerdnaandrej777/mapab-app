import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../providers/map_controller_provider.dart';

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
    // Unregister controller
    ref.read(mapControllerProvider.notifier).state = null;
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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

        // TODO: Route-Layer hinzufügen
        // PolylineLayer(...)

        // TODO: POI-Marker Layer hinzufügen
        // MarkerLayer(...)

        // TODO: Start/Ziel Marker
        // MarkerLayer(...)
      ],
    );
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    // TODO: POI-Popup schließen oder Marker setzen
  }

  void _onMapLongPress(TapPosition tapPosition, LatLng point) {
    // TODO: Kontextmenü anzeigen (Start/Ziel setzen)
    _showLocationMenu(context, point);
  }

  void _showLocationMenu(BuildContext context, LatLng point) {
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
                // TODO: Start setzen
              },
            ),
            ListTile(
              leading: const Icon(Icons.place, color: Colors.red),
              title: const Text('Als Ziel setzen'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Ziel setzen
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
