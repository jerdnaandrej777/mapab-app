import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/categories.dart';
import '../../data/models/route.dart';
import '../../data/repositories/geocoding_repo.dart';
import '../../shared/widgets/app_snackbar.dart';
import '../random_trip/providers/random_trip_provider.dart';
import '../random_trip/providers/random_trip_state.dart';
import 'providers/map_controller_provider.dart';
import 'providers/route_planner_provider.dart';
import 'providers/route_session_provider.dart';
import 'providers/weather_provider.dart';
import '../trip/providers/trip_state_provider.dart';
import 'widgets/map_view.dart';
import 'widgets/unified_weather_widget.dart';

/// Planungs-Modus (AI Tagestrip oder AI Euro Trip)
enum MapPlanMode { aiTagestrip, aiEuroTrip }

/// Hauptscreen mit Karte
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  bool _isLoadingLocation = false;
  MapPlanMode _planMode = MapPlanMode.aiTagestrip;

  @override
  void initState() {
    super.initState();
    // Listener für Route-Änderungen (Auto-Zoom)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Wenn bereits eine Route existiert (z.B. von Trip-Screen kommend), zoome darauf
      // Sonst zentriere auf GPS-Standort
      final routePlanner = ref.read(routePlannerProvider);
      final tripState = ref.read(tripStateProvider);
      final randomTripState = ref.read(randomTripNotifierProvider);

      // Prüfe ob irgendeine Route vorhanden ist
      final hasAnyRoute = routePlanner.hasRoute ||
          tripState.hasRoute ||
          randomTripState.step == RandomTripStep.preview ||
          randomTripState.step == RandomTripStep.confirmed;

      if (hasAnyRoute) {
        // Kurze Verzögerung damit MapController bereit ist
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            // Bestimme welche Route (Priorität: AI Trip > Trip > RoutePlanner)
            AppRoute? routeToFit;
            if (randomTripState.step == RandomTripStep.preview ||
                randomTripState.step == RandomTripStep.confirmed) {
              routeToFit = randomTripState.generatedTrip?.trip.route;
            } else if (tripState.hasRoute) {
              routeToFit = tripState.route;
            } else if (routePlanner.hasRoute) {
              routeToFit = routePlanner.route;
            }
            if (routeToFit != null) {
              _fitMapToRoute(routeToFit);
            }
          }
        });
      } else {
        // Keine Route → zentriere auf GPS-Standort
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            _centerOnCurrentLocationSilent();
          }
        });
      }

      // Listener für neue Route-Berechnungen
      ref.listenManual(routePlannerProvider, (previous, next) {
        // Wenn eine neue Route berechnet wurde, zoome die Karte darauf
        if (next.hasRoute && (previous?.route != next.route)) {
          _fitMapToRoute(next.route!);
        }
      });

      // Listener für AI Trip - wenn Trip generiert, Route auf Karte zoomen
      ref.listenManual(randomTripNotifierProvider, (previous, next) {
        debugPrint('[MapScreen] RandomTrip State changed: ${previous?.step} -> ${next.step}');
        if (next.step == RandomTripStep.preview && previous?.step != RandomTripStep.preview) {
          // Trip wurde generiert - Route auf Karte zoomen
          final aiRoute = next.generatedTrip?.trip.route;
          debugPrint('[MapScreen] AI Trip generated! Route: ${aiRoute != null}, POIs: ${next.generatedTrip?.selectedPOIs.length ?? 0}');
          debugPrint('[MapScreen] Route coords: ${aiRoute?.coordinates.length ?? 0}');
          if (aiRoute != null && mounted) {
            _fitMapToRoute(aiRoute);
          }
          // Zu AI Tagestrip wechseln um Panel auszublenden
          setState(() => _planMode = MapPlanMode.aiTagestrip);
        }
        // Wenn Trip bestätigt wurde, ebenfalls Route zoomen
        if (next.step == RandomTripStep.confirmed && previous?.step != RandomTripStep.confirmed) {
          final tripState = ref.read(tripStateProvider);
          if (tripState.hasRoute && mounted) {
            _fitMapToRoute(tripState.route!);
          }
        }
        // Fehler bei AI Trip anzeigen
        if (next.error != null && next.error != previous?.error && mounted) {
          AppSnackbar.showError(context, 'Trip-Generierung fehlgeschlagen: ${next.error}');
        }
      });

      // Listener für Routenberechnung-Fehler
      ref.listenManual(routePlannerProvider, (previous, next) {
        if (next.error != null && next.error != previous?.error && mounted) {
          AppSnackbar.showError(context, 'Routenberechnung fehlgeschlagen. Bitte versuche es erneut.');
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
    final randomTripState = ref.watch(randomTripNotifierProvider);
    final tripState = ref.watch(tripStateProvider);

    // Auto-Zoom auf Route bei Tab-Wechsel (v1.7.0)
    final shouldFitToRoute = ref.watch(shouldFitToRouteProvider);
    if (shouldFitToRoute) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        // Prüfe ob MapController bereit ist
        final mapController = ref.read(mapControllerProvider);
        if (mapController == null) {
          debugPrint('[MapScreen] MapController noch nicht bereit, warte...');
          // Retry nach kurzer Verzögerung
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              // Triggere erneuten Build durch State-Änderung
              setState(() {});
            }
          });
          return;
        }

        // Bestimme welche Route angezeigt werden soll (Priorität: AI Trip > Trip > RoutePlanner)
        AppRoute? routeToFit;
        if (randomTripState.step == RandomTripStep.preview ||
            randomTripState.step == RandomTripStep.confirmed) {
          routeToFit = randomTripState.generatedTrip?.trip.route;
        } else if (tripState.hasRoute) {
          routeToFit = tripState.route;
        } else if (routePlanner.hasRoute) {
          routeToFit = routePlanner.route;
        }

        if (routeToFit != null) {
          debugPrint('[MapScreen] Auto-Zoom auf Route bei Tab-Wechsel');
          _fitMapToRoute(routeToFit);
        } else {
          // Keine Route vorhanden → auf GPS-Standort zentrieren
          debugPrint('[MapScreen] Keine Route - zentriere auf GPS-Standort');
          _centerOnCurrentLocationSilent();
        }
        // Flag zurücksetzen (nur wenn MapController bereit war)
        ref.read(shouldFitToRouteProvider.notifier).state = false;
      });
    }

    final colorScheme = Theme.of(context).colorScheme;

    // Zeige Trip Config Panel wenn noch kein Trip generiert wird
    final showTripConfigPanel = randomTripState.step == RandomTripStep.config;

    // Zeige Loading wenn Trip generiert wird
    final isGenerating = randomTripState.step == RandomTripStep.generating;

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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Mode-Toggle (AI Tagestrip / AI Euro Trip)
                  _ModeToggle(
                    selectedMode: _planMode,
                    onModeChanged: (mode) {
                      setState(() => _planMode = mode);
                      // Modus im RandomTripProvider synchronisieren
                      final targetMode = mode == MapPlanMode.aiTagestrip
                          ? RandomTripMode.daytrip
                          : RandomTripMode.eurotrip;
                      ref.read(randomTripNotifierProvider.notifier).setMode(targetMode);
                    },
                  ),

                  // === TRIP CONFIG PANEL (beide Modi) ===
                  if (showTripConfigPanel && !isGenerating) ...[
                    const SizedBox(height: 12),
                    _TripConfigPanel(mode: _planMode),
                  ],

                  // === LOADING (Trip wird generiert) ===
                  if (isGenerating) ...[
                    const SizedBox(height: 12),
                    _GeneratingIndicator(),
                  ],

                ],
              ),
            ),
          ),

          // Floating Action Button (rechts) - Settings
          if (!isGenerating && !showTripConfigPanel)
            Positioned(
              right: 16,
              bottom: 100,
              child: FloatingActionButton.small(
                heroTag: 'settings',
                onPressed: () => context.push('/settings'),
                backgroundColor: colorScheme.surface,
                foregroundColor: colorScheme.onSurface,
                child: const Icon(Icons.settings),
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
        debugPrint('[GPS] Location Services deaktiviert');
        final shouldOpenSettings = await _showGpsDialog();
        if (shouldOpenSettings) {
          await Geolocator.openLocationSettings();
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

        // Standort-Wetter laden (v1.7.6)
        ref.read(locationWeatherNotifierProvider.notifier).loadWeatherForLocation(
          location,
          locationName: 'Mein Standort',
        );
      }
    } catch (e) {
      debugPrint('[GPS] Fehler: $e');
      _showSnackBar('GPS-Position konnte nicht ermittelt werden.');
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  /// Zentriert die Karte still auf aktuelle GPS-Position (ohne UI-Feedback)
  /// Verwendet bei Tab-Wechsel wenn keine Route vorhanden
  Future<void> _centerOnCurrentLocationSilent() async {
    try {
      // Prüfe ob Location Services aktiviert sind
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[GPS] Location Services deaktiviert - zeige Europa-Zentrum');
        _showDefaultMapCenter();
        return;
      }

      // Prüfe Berechtigungen
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('[GPS] Berechtigung verweigert - zeige Europa-Zentrum');
          _showDefaultMapCenter();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('[GPS] Berechtigung dauerhaft verweigert - zeige Europa-Zentrum');
        _showDefaultMapCenter();
        return;
      }

      // Position abrufen (mit kürzerem Timeout)
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 5),
      );

      // Karte zur Position bewegen
      final mapController = ref.read(mapControllerProvider);
      final location = LatLng(position.latitude, position.longitude);
      if (mapController != null) {
        mapController.move(location, 12.0);
        debugPrint('[GPS] Karte auf Standort zentriert: ${position.latitude}, ${position.longitude}');
      }

      // Reverse Geocoding für Wetter-Widget
      String locationName = 'Mein Standort';
      try {
        final geocodingRepo = ref.read(geocodingRepositoryProvider);
        final result = await geocodingRepo.reverseGeocode(location);
        if (result != null) {
          locationName = result.shortName ?? result.displayName;
          debugPrint('[GPS] Reverse Geocoding für Wetter: $locationName');
        }
      } catch (e) {
        debugPrint('[GPS] Reverse Geocoding fehlgeschlagen: $e');
      }

      // Standort-Wetter laden mit Stadtnamen (v1.7.6)
      ref.read(locationWeatherNotifierProvider.notifier).loadWeatherForLocation(
        location,
        locationName: locationName,
      );
    } catch (e) {
      debugPrint('[GPS] Position nicht verfügbar: $e - zeige Europa-Zentrum');
      _showDefaultMapCenter();
    }
  }

  /// Zeigt Europa-Zentrum als Fallback
  void _showDefaultMapCenter() {
    final mapController = ref.read(mapControllerProvider);
    if (mapController != null) {
      mapController.move(const LatLng(50.0, 10.0), 6.0);
      debugPrint('[Map] Fallback: Europa-Zentrum angezeigt');
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

  /// Dialog anzeigen wenn GPS deaktiviert ist
  Future<bool> _showGpsDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('GPS deaktiviert'),
        content: const Text(
          'Die Ortungsdienste sind deaktiviert. Möchtest du die GPS-Einstellungen öffnen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Nein'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Einstellungen öffnen'),
          ),
        ],
      ),
    ) ?? false;
  }

  /// Startet die Route-Session
  Future<void> _startRoute(AppRoute route) async {
    await ref.read(routeSessionProvider.notifier).startRoute(route);
  }
}

/// Route löschen Button
class _RouteClearButton extends StatelessWidget {
  final VoidCallback onClear;

  const _RouteClearButton({required this.onClear});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onClear,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.red.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: Colors.red.shade400,
                ),
                const SizedBox(width: 8),
                Text(
                  'Route löschen',
                  style: TextStyle(
                    color: Colors.red.shade400,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Mode-Toggle (Schnell / AI Trip)
class _ModeToggle extends StatelessWidget {
  final MapPlanMode selectedMode;
  final ValueChanged<MapPlanMode> onModeChanged;

  const _ModeToggle({
    required this.selectedMode,
    required this.onModeChanged,
  });

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
        children: [
          Expanded(
            child: _ModeButton(
              label: 'AI Tagestrip',
              icon: Icons.wb_sunny_outlined,
              isSelected: selectedMode == MapPlanMode.aiTagestrip,
              onTap: () => onModeChanged(MapPlanMode.aiTagestrip),
            ),
          ),
          Expanded(
            child: _ModeButton(
              label: 'AI Euro Trip',
              icon: Icons.flight_outlined,
              isSelected: selectedMode == MapPlanMode.aiEuroTrip,
              onTap: () => onModeChanged(MapPlanMode.aiEuroTrip),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mode Button
class _ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeButton({
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Trip Config Panel - vereint AI Tagestrip und AI Euro Trip
class _TripConfigPanel extends ConsumerStatefulWidget {
  final MapPlanMode mode;

  const _TripConfigPanel({required this.mode});

  @override
  ConsumerState<_TripConfigPanel> createState() => _TripConfigPanelState();
}

class _TripConfigPanelState extends ConsumerState<_TripConfigPanel> {
  final _addressController = TextEditingController();
  final _focusNode = FocusNode();
  List<GeocodingResult> _suggestions = [];
  bool _isSearching = false;

  // Ziel-Eingabe Controller
  final _destinationController = TextEditingController();
  final _destinationFocusNode = FocusNode();
  List<GeocodingResult> _destinationSuggestions = [];
  bool _isSearchingDestination = false;

  @override
  void dispose() {
    _addressController.dispose();
    _focusNode.dispose();
    _destinationController.dispose();
    _destinationFocusNode.dispose();
    super.dispose();
  }

  Future<void> _searchAddress(String query) async {
    if (query.length < 3) {
      setState(() => _suggestions = []);
      return;
    }

    setState(() => _isSearching = true);

    try {
      final geocodingRepo = ref.read(geocodingRepositoryProvider);
      final results = await geocodingRepo.geocode(query);
      setState(() {
        _suggestions = results.take(5).toList();
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _suggestions = [];
        _isSearching = false;
      });
    }
  }

  void _selectSuggestion(GeocodingResult result) {
    final notifier = ref.read(randomTripNotifierProvider.notifier);
    notifier.setStartLocation(result.location, result.shortName ?? result.displayName);
    _addressController.text = result.shortName ?? result.displayName;
    setState(() => _suggestions = []);
    _focusNode.unfocus();
  }

  /// Suche für Ziel-Adresse
  Future<void> _searchDestination(String query) async {
    if (query.length < 3) {
      setState(() => _destinationSuggestions = []);
      return;
    }

    setState(() => _isSearchingDestination = true);

    try {
      final geocodingRepo = ref.read(geocodingRepositoryProvider);
      final results = await geocodingRepo.geocode(query);
      setState(() {
        _destinationSuggestions = results.take(5).toList();
        _isSearchingDestination = false;
      });
    } catch (e) {
      setState(() {
        _destinationSuggestions = [];
        _isSearchingDestination = false;
      });
    }
  }

  void _selectDestinationSuggestion(GeocodingResult result) {
    final notifier = ref.read(randomTripNotifierProvider.notifier);
    notifier.setDestination(result.location, result.shortName ?? result.displayName);
    _destinationController.text = result.shortName ?? result.displayName;
    setState(() => _destinationSuggestions = []);
    _destinationFocusNode.unfocus();
  }

  /// Prüft GPS-Status und zeigt Dialog wenn deaktiviert
  Future<bool> _checkGPSAndShowDialog() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return false;
      final shouldOpen = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('GPS deaktiviert'),
          content: const Text(
            'Die Ortungsdienste sind deaktiviert. Möchtest du die GPS-Einstellungen öffnen?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Nein'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Einstellungen öffnen'),
            ),
          ],
        ),
      ) ?? false;
      if (shouldOpen) {
        await Geolocator.openLocationSettings();
      }
      return false;
    }
    return true;
  }

  /// Handelt GPS-Button-Klick mit Dialog
  Future<void> _handleGPSButtonTap() async {
    final gpsAvailable = await _checkGPSAndShowDialog();
    if (!gpsAvailable) return;

    // GPS verfügbar - Standort ermitteln
    final notifier = ref.read(randomTripNotifierProvider.notifier);
    await notifier.useCurrentLocation();
  }

  /// Handelt "Überrasch mich!" Klick - prüft GPS wenn kein Startpunkt
  Future<void> _handleGenerateTrip() async {
    final state = ref.read(randomTripNotifierProvider);
    final notifier = ref.read(randomTripNotifierProvider.notifier);

    // Wenn kein Startpunkt gesetzt, GPS-Dialog anzeigen
    if (!state.hasValidStart) {
      final gpsAvailable = await _checkGPSAndShowDialog();
      if (!gpsAvailable) return;

      // GPS-Standort ermitteln
      await notifier.useCurrentLocation();

      // Prüfen ob Standort jetzt gesetzt ist
      final newState = ref.read(randomTripNotifierProvider);
      if (!newState.hasValidStart) {
        // Standort konnte nicht ermittelt werden
        return;
      }
    }

    // Trip generieren
    notifier.generateTrip();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(randomTripNotifierProvider);
    final notifier = ref.read(randomTripNotifierProvider.notifier);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Sync controllers mit State
    if (state.startAddress != null && _addressController.text.isEmpty) {
      _addressController.text = state.startAddress!;
    }
    if (state.destinationAddress != null && _destinationController.text.isEmpty) {
      _destinationController.text = state.destinationAddress!;
    }

    // Modus mit Toggle synchronisieren
    final targetMode = widget.mode == MapPlanMode.aiTagestrip
        ? RandomTripMode.daytrip
        : RandomTripMode.eurotrip;
    if (state.mode != targetMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier.setMode(targetMode);
      });
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      // Scrollbar für lange Inhalte (aufgeklapptes Wetter-Widget)
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.65, // Max 65% der Bildschirmhöhe
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
          // Wetter-Widget (v1.7.20 - innerhalb des Panels, nutzt eigenes margin)
          const UnifiedWeatherWidget(),

          // Startadresse (Typ-Selector entfernt - wird extern via Toggle gesteuert)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Startpunkt',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Adress-Eingabe
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: state.hasValidStart && !state.useGPS
                          ? colorScheme.primary
                          : colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _addressController,
                        focusNode: _focusNode,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Stadt oder Adresse...',
                          hintStyle: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
                          prefixIcon: Icon(Icons.search, size: 20, color: colorScheme.onSurfaceVariant),
                          suffixIcon: _isSearching
                              ? const Padding(
                                  padding: EdgeInsets.all(10),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              : _addressController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        _addressController.clear();
                                        setState(() => _suggestions = []);
                                      },
                                    )
                                  : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          isDense: true,
                        ),
                        onChanged: _searchAddress,
                      ),
                      // Vorschläge
                      if (_suggestions.isNotEmpty)
                        Container(
                          constraints: const BoxConstraints(maxHeight: 150),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
                            ),
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _suggestions.length,
                            itemBuilder: (context, index) {
                              final result = _suggestions[index];
                              return InkWell(
                                onTap: () => _selectSuggestion(result),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  child: Row(
                                    children: [
                                      Icon(Icons.location_on, size: 16, color: colorScheme.primary),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          result.shortName ?? result.displayName,
                                          style: const TextStyle(fontSize: 13),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // GPS Button mit Dialog wenn GPS deaktiviert
                InkWell(
                  onTap: state.isLoading ? null : _handleGPSButtonTap,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: state.useGPS && state.hasValidStart
                          ? colorScheme.primaryContainer
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: state.useGPS && state.hasValidStart
                            ? colorScheme.primary
                            : colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (state.isLoading && state.useGPS)
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.primary,
                            ),
                          )
                        else
                          Icon(
                            Icons.my_location,
                            size: 14,
                            color: state.useGPS && state.hasValidStart
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                          ),
                        const SizedBox(width: 6),
                        Text(
                          state.useGPS && state.startAddress != null
                              ? state.startAddress!
                              : 'GPS-Standort',
                          style: TextStyle(
                            fontSize: 12,
                            color: state.useGPS && state.hasValidStart
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: colorScheme.outline.withOpacity(0.2)),

          // Ziel-Eingabe (optional)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.flag, size: 16, color: colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Ziel (optional)',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    if (state.hasDestination)
                      GestureDetector(
                        onTap: () {
                          notifier.clearDestination();
                          _destinationController.clear();
                          setState(() => _destinationSuggestions = []);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.close, size: 12, color: colorScheme.onErrorContainer),
                              const SizedBox(width: 4),
                              Text(
                                'Entfernen',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.onErrorContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                // Ziel-Adress-Eingabe
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: state.hasDestination
                          ? colorScheme.primary
                          : colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _destinationController,
                        focusNode: _destinationFocusNode,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Zielort eingeben...',
                          hintStyle: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
                          prefixIcon: Icon(Icons.search, size: 20, color: colorScheme.onSurfaceVariant),
                          suffixIcon: _isSearchingDestination
                              ? const Padding(
                                  padding: EdgeInsets.all(10),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              : _destinationController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        _destinationController.clear();
                                        notifier.clearDestination();
                                        setState(() => _destinationSuggestions = []);
                                      },
                                    )
                                  : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          isDense: true,
                        ),
                        onChanged: _searchDestination,
                      ),
                      // Vorschläge
                      if (_destinationSuggestions.isNotEmpty)
                        Container(
                          constraints: const BoxConstraints(maxHeight: 150),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
                            ),
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _destinationSuggestions.length,
                            itemBuilder: (context, index) {
                              final result = _destinationSuggestions[index];
                              return InkWell(
                                onTap: () => _selectDestinationSuggestion(result),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  child: Row(
                                    children: [
                                      Icon(Icons.flag, size: 16, color: colorScheme.primary),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          result.shortName ?? result.displayName,
                                          style: const TextStyle(fontSize: 13),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                // Hinweis-Text
                Text(
                  state.hasDestination
                      ? 'POIs entlang der Route'
                      : 'Ohne Ziel: Rundreise ab Start',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: colorScheme.outline.withOpacity(0.2)),

          // Radius Slider (kompakt)
          Padding(
            padding: const EdgeInsets.all(12),
            child: _CompactRadiusSlider(state: state, notifier: notifier),
          ),

          Divider(height: 1, color: colorScheme.outline.withOpacity(0.2)),

          // Kategorien (Modal-basiert, v1.7.20)
          _CompactCategorySelector(
            state: state,
            notifier: notifier,
          ),

          // Generate Button - prüft GPS wenn kein Startpunkt gesetzt
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: state.isLoading ? null : _handleGenerateTrip,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🎲', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    const Text(
                      'Überrasch mich!',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Route löschen Button (v1.7.25 - ins Panel verschoben, damit nicht abgeschnitten)
          if (state.step == RandomTripStep.preview ||
              state.step == RandomTripStep.confirmed ||
              ref.watch(tripStateProvider).hasRoute) ...[
            Divider(height: 1, color: colorScheme.outline.withOpacity(0.2)),
            Padding(
              padding: const EdgeInsets.all(12),
              child: _RouteClearButton(
                onClear: () {
                  ref.read(randomTripNotifierProvider.notifier).reset();
                  ref.read(routePlannerProvider.notifier).clearRoute();
                  ref.read(tripStateProvider.notifier).clearAll();
                },
              ),
            ),
          ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Kompakter Radius-Slider
class _CompactRadiusSlider extends StatelessWidget {
  final RandomTripState state;
  final RandomTripNotifier notifier;

  const _CompactRadiusSlider({
    required this.state,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final (minRadius, maxRadius) = state.mode == RandomTripMode.daytrip
        ? (30.0, 300.0)
        : (100.0, 5000.0);
    final currentRadius = state.radiusKm.clamp(minRadius, maxRadius);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.radar, size: 16, color: colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  'Radius',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${currentRadius.round()} km',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: colorScheme.primary,
            inactiveTrackColor: colorScheme.primary.withOpacity(0.2),
            thumbColor: colorScheme.primary,
            overlayColor: colorScheme.primary.withOpacity(0.1),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: currentRadius,
            min: minRadius,
            max: maxRadius,
            divisions: state.mode == RandomTripMode.daytrip
                ? ((maxRadius - minRadius) / 10).round()
                : ((maxRadius - minRadius) / 100).round(),
            onChanged: (value) => notifier.setRadius(value),
          ),
        ),
        // Quick Select
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: _getQuickSelectValues(state.mode).map((value) {
            final isSelected = (currentRadius - value).abs() < 10;
            return GestureDetector(
              onTap: () => notifier.setRadius(value),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected ? colorScheme.primary : colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Text(
                  '${value.round()} km',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  List<double> _getQuickSelectValues(RandomTripMode mode) {
    if (mode == RandomTripMode.daytrip) {
      return [50, 100, 200, 300];
    }
    return [500, 1000, 2500, 5000];
  }
}

/// Kompakte Kategorien-Auswahl mit Modal (v1.7.20)
class _CompactCategorySelector extends StatelessWidget {
  final RandomTripState state;
  final RandomTripNotifier notifier;

  const _CompactCategorySelector({
    required this.state,
    required this.notifier,
  });

  void _showCategoryModal(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tripCategories = POICategory.values
        .where((cat) => cat != POICategory.hotel && cat != POICategory.restaurant)
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // FIX v1.7.27: Consumer wrappen damit ref.watch() im Modal funktioniert
      // Vorher: Modal nutzte gefrorenen state-Snapshot, Kategorie-Auswahl
      // wurde erst nach Schliessen und Neuoeffnen sichtbar
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final liveState = ref.watch(randomTripNotifierProvider);
          final liveNotifier = ref.read(randomTripNotifierProvider.notifier);
          return Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
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
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.category, color: colorScheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'POI-Kategorien',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    if (liveState.selectedCategories.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          liveNotifier.setCategories([]);
                        },
                        child: const Text('Alle zurücksetzen'),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  liveState.selectedCategories.isEmpty
                      ? 'Alle Kategorien ausgewählt'
                      : '${liveState.selectedCategoryCount} von ${tripCategories.length} ausgewählt',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                // Kategorien Grid - KEINE maxHeight!
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tripCategories.map((category) {
                    final isSelected = liveState.selectedCategories.contains(category);
                    return Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        onTap: () => liveNotifier.toggleCategory(category),
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 100),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.outline.withOpacity(0.3),
                              width: isSelected ? 1.5 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: colorScheme.primary.withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(category.icon, style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 6),
                              if (isSelected) ...[
                                Icon(
                                  Icons.check,
                                  size: 16,
                                  color: colorScheme.onPrimary,
                                ),
                                const SizedBox(width: 2),
                              ],
                              Text(
                                category.label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                // Schließen Button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Fertig'),
                  ),
                ),
                // Safe area padding
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Header - öffnet Modal statt Inline-Expand
        InkWell(
          onTap: () => _showCategoryModal(context),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.category, size: 18, color: colorScheme.primary),
                const SizedBox(width: 10),
                Text(
                  'Kategorien',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.selectedCategories.isEmpty
                        ? 'Alle'
                        : '${state.selectedCategoryCount} ausgewählt',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                // Größerer, auffälligerer Button
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.tune,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Loading-Anzeige während Trip generiert wird
class _GeneratingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation(colorScheme.primary),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '🎲',
            style: TextStyle(fontSize: 32),
          ),
          const SizedBox(height: 12),
          Text(
            'Trip wird generiert...',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'POIs laden, Route optimieren',
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

