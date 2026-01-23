import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/route.dart';
import 'providers/map_controller_provider.dart';
import 'providers/route_planner_provider.dart';
import 'providers/route_session_provider.dart';
import 'widgets/map_view.dart';
import 'widgets/weather_bar.dart';

/// Hauptscreen mit Karte
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    // Listener für Route-Änderungen (Auto-Zoom)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listenManual(routePlannerProvider, (previous, next) {
        // Wenn eine neue Route berechnet wurde, zoome die Karte darauf
        if (next.hasRoute && (previous?.route != next.route)) {
          _fitMapToRoute(next.route!);
        }
      });
    });
  }

  /// Zoomt die Karte so, dass die gesamte Route sichtbar ist
  void _fitMapToRoute(AppRoute route) {
    final mapController = ref.read(mapControllerProvider);
    if (mapController == null || route.coordinates.isEmpty) return;

    // Berechne die Bounds der Route
    double minLat = route.coordinates.first.latitude;
    double maxLat = route.coordinates.first.latitude;
    double minLng = route.coordinates.first.longitude;
    double maxLng = route.coordinates.first.longitude;

    for (final point in route.coordinates) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    // Etwas Padding hinzufügen
    final bounds = LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );

    // Karte auf Bounds zoomen mit Animation
    mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(80),
      ),
    );

    debugPrint('[Map] Route angezeigt: ${route.distanceKm.toStringAsFixed(0)} km');
  }

  @override
  Widget build(BuildContext context) {
    final routePlanner = ref.watch(routePlannerProvider);
    final routeSession = ref.watch(routeSessionProvider);

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

                  // Route-Start-Button (wenn Route berechnet und Session nicht aktiv)
                  if (routePlanner.hasRoute && !routeSession.isActive && !routeSession.isLoading)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _RouteStartButton(
                        route: routePlanner.route!,
                        onStart: () => _startRoute(routePlanner.route!),
                      ),
                    ),

                  // Loading-Indikator (wenn Session startet)
                  if (routeSession.isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: _RouteLoadingIndicator(),
                    ),

                  // WeatherBar (wenn Route-Session aktiv und bereit)
                  if (routeSession.isReady)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: WeatherBar(),
                    ),

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

  /// Startet die Route-Session
  Future<void> _startRoute(AppRoute route) async {
    await ref.read(routeSessionProvider.notifier).startRoute(route);
  }
}

/// "Route Starten" Button mit Route-Informationen
class _RouteStartButton extends StatelessWidget {
  final AppRoute route;
  final VoidCallback onStart;

  const _RouteStartButton({
    required this.route,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onStart,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primary,
                colorScheme.primary.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Play-Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Route starten',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${route.distanceKm.toStringAsFixed(0)} km · ${_formatDuration(route.durationMinutes)}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              // Pfeil
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white.withOpacity(0.8),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return '${hours}h ${mins}min';
    }
    return '${mins} min';
  }
}

/// Loading-Indikator während POIs und Wetter geladen werden
class _RouteLoadingIndicator extends StatelessWidget {
  const _RouteLoadingIndicator();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Route wird vorbereitet...',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'POIs und Wetter werden geladen',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withOpacity(0.7),
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
