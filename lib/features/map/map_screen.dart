import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_theme.dart';
import 'providers/map_controller_provider.dart';
import 'providers/route_planner_provider.dart';
import 'widgets/map_view.dart';

/// Hauptscreen mit Karte
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  bool _isLoadingLocation = false;

  @override
  Widget build(BuildContext context) {
    final routePlanner = ref.watch(routePlannerProvider);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('MapAB'),
        backgroundColor: colorScheme.surface.withOpacity(0.9),
        elevation: 0,
        actions: [
          // Favoriten-Button
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () => context.push('/favorites'),
            tooltip: 'Favoriten',
          ),
          // Profil-Button
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/profile'),
            tooltip: 'Profil',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Karte (Hintergrund)
          const MapView(),

          // Such-Header
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Suchleiste
                  _SearchBar(
                    startAddress: routePlanner.startAddress,
                    endAddress: routePlanner.endAddress,
                    isCalculating: routePlanner.isCalculating,
                    onStartTap: () => context.push('/search?type=start'),
                    onEndTap: () => context.push('/search?type=end'),
                  ),

                  const SizedBox(height: 12),

                  // Route-Toggle (Fast/Scenic)
                  const _RouteToggle(),
                ],
              ),
            ),
          ),

          // Floating Action Buttons (rechts)
          Positioned(
            right: 16,
            bottom: 100,
            child: Column(
              children: [
                // Settings-Button
                FloatingActionButton.small(
                  heroTag: 'settings',
                  onPressed: () => context.push('/settings'),
                  backgroundColor: colorScheme.surface,
                  foregroundColor: colorScheme.onSurface,
                  child: const Icon(Icons.settings),
                ),
                const SizedBox(height: 8),
                // GPS-Button
                FloatingActionButton.small(
                  heroTag: 'gps',
                  onPressed: _centerOnLocation,
                  backgroundColor: colorScheme.surface,
                  foregroundColor: colorScheme.primary,
                  child: _isLoadingLocation
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location),
                ),
                const SizedBox(height: 8),
                // Zoom-Buttons
                FloatingActionButton.small(
                  heroTag: 'zoomIn',
                  onPressed: _zoomIn,
                  backgroundColor: colorScheme.surface,
                  foregroundColor: colorScheme.onSurface,
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 4),
                FloatingActionButton.small(
                  heroTag: 'zoomOut',
                  onPressed: _zoomOut,
                  backgroundColor: colorScheme.surface,
                  foregroundColor: colorScheme.onSurface,
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),

          // Zufalls-Trip Button (links unten)
          Positioned(
            left: 16,
            bottom: 100,
            child: FloatingActionButton.extended(
              heroTag: 'randomTrip',
              onPressed: () => context.push('/random-trip'),
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              icon: const Text('🎲', style: TextStyle(fontSize: 18)),
              label: const Text('Zufalls-Trip'),
            ),
          ),
        ],
      ),
    );
  }

  /// GPS-Position ermitteln und Karte zentrieren
  Future<void> _centerOnLocation() async {
    if (_isLoadingLocation) return;

    setState(() => _isLoadingLocation = true);

    try {
      // Prüfe ob Location Services aktiviert sind
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Im Emulator: Verwende München als Test-Standort
        debugPrint('[GPS] Location Services deaktiviert - verwende Test-Standort (München)');
        final mapController = ref.read(mapControllerProvider);
        if (mapController != null) {
          const testLocation = LatLng(48.1351, 11.5820); // München
          mapController.move(testLocation, 12.0);
          _showSnackBar('Test-Standort: München\n(Emulator hat kein GPS)', duration: 4);
        }
        return;
      }

      // Prüfe Berechtigungen
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar('GPS-Berechtigung wurde verweigert.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnackBar('GPS-Berechtigung dauerhaft verweigert. Bitte in Einstellungen aktivieren.');
        return;
      }

      // Position abrufen
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Karte zur Position bewegen
      final mapController = ref.read(mapControllerProvider);
      if (mapController != null) {
        final location = LatLng(position.latitude, position.longitude);
        mapController.move(location, 14.0);
        _showSnackBar('Position gefunden!');
      }
    } catch (e) {
      debugPrint('[GPS] Fehler: $e');

      // Fallback: Verwende München als Test-Standort
      final mapController = ref.read(mapControllerProvider);
      if (mapController != null) {
        const testLocation = LatLng(48.1351, 11.5820); // München
        mapController.move(testLocation, 12.0);
        _showSnackBar('Test-Standort: München\n(GPS nicht verfügbar)', duration: 4);
      }
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  void _showSnackBar(String message, {int duration = 2}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: duration),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _zoomIn() {
    final mapController = ref.read(mapControllerProvider);
    if (mapController != null) {
      final newZoom = (mapController.camera.zoom + 1).clamp(3.0, 18.0);
      mapController.move(mapController.camera.center, newZoom);
    }
  }

  void _zoomOut() {
    final mapController = ref.read(mapControllerProvider);
    if (mapController != null) {
      final newZoom = (mapController.camera.zoom - 1).clamp(3.0, 18.0);
      mapController.move(mapController.camera.center, newZoom);
    }
  }
}

/// Suchleiste Widget
class _SearchBar extends StatelessWidget {
  final String? startAddress;
  final String? endAddress;
  final bool isCalculating;
  final VoidCallback onStartTap;
  final VoidCallback onEndTap;

  const _SearchBar({
    this.startAddress,
    this.endAddress,
    this.isCalculating = false,
    required this.onStartTap,
    required this.onEndTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Start-Eingabe
          _SearchField(
            icon: Icons.trip_origin,
            iconColor: AppTheme.successColor,
            hint: 'Startpunkt eingeben',
            value: startAddress,
            onTap: onStartTap,
          ),

          Divider(height: 1, indent: 48, color: theme.dividerColor),

          // Ziel-Eingabe
          _SearchField(
            icon: Icons.place,
            iconColor: AppTheme.errorColor,
            hint: 'Ziel eingeben',
            value: endAddress,
            onTap: onEndTap,
          ),

          // Lade-Indikator wenn Route berechnet wird
          if (isCalculating)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Route wird berechnet...',
                    style: TextStyle(
                      color: theme.textTheme.bodySmall?.color,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Einzelnes Suchfeld
class _SearchField extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String hint;
  final String? value;
  final VoidCallback onTap;

  const _SearchField({
    required this.icon,
    required this.iconColor,
    required this.hint,
    this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value ?? hint,
                style: TextStyle(
                  color: value != null
                      ? colorScheme.onSurface
                      : theme.hintColor,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fast/Scenic Route Toggle
class _RouteToggle extends StatefulWidget {
  const _RouteToggle();

  @override
  State<_RouteToggle> createState() => _RouteToggleState();
}

class _RouteToggleState extends State<_RouteToggle> {
  bool _isFastRoute = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleButton(
            label: 'Schnell',
            icon: Icons.speed,
            isSelected: _isFastRoute,
            onTap: () => setState(() => _isFastRoute = true),
          ),
          _ToggleButton(
            label: 'Landschaft',
            icon: Icons.landscape,
            isSelected: !_isFastRoute,
            onTap: () => setState(() => _isFastRoute = false),
          ),
        ],
      ),
    );
  }
}

/// Toggle Button
class _ToggleButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? colorScheme.onPrimary : theme.textTheme.bodySmall?.color,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? colorScheme.onPrimary : theme.textTheme.bodySmall?.color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
