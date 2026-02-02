import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/categories.dart';
import '../../core/constants/trip_constants.dart';
import '../../data/models/route.dart';
import '../../data/providers/active_trip_provider.dart';
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
  bool _isPanelExpanded = false;

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
          // Panel zuklappen nach Generierung (Modus bleibt erhalten)
          setState(() => _isPanelExpanded = false);
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

    // Panel-Sichtbarkeits-Logik
    final isConfigStep = randomTripState.step == RandomTripStep.config;
    final isGenerating = randomTripState.step == RandomTripStep.generating;
    final hasGeneratedTrip = (randomTripState.step == RandomTripStep.preview ||
        randomTripState.step == RandomTripStep.confirmed) &&
        randomTripState.generatedTrip != null;

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        title: const Text('MapAB'),
        backgroundColor: colorScheme.surface,
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
          // Einstellungen-Button
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
            tooltip: 'Einstellungen',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Karte (Hintergrund)
          const MapView(),

          // Such-Header (kein SafeArea top nötig - AppBar übernimmt)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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

                  // === AKTIVER TRIP BANNER (Fortsetzen) ===
                  if (isConfigStep && !isGenerating)
                    _ActiveTripResumeBanner(
                      onRestore: () {
                        setState(() {
                          _planMode = MapPlanMode.aiEuroTrip;
                        });
                      },
                    ),

                  // === TRIP CONFIG PANEL (Konfigurationsphase) ===
                  if (isConfigStep && !isGenerating) ...[
                    const SizedBox(height: 12),
                    _TripConfigPanel(mode: _planMode),
                  ],

                  // === LOADING (Trip wird generiert) ===
                  if (isGenerating) ...[
                    const SizedBox(height: 12),
                    _GeneratingIndicator(),
                  ],

                  // === POST-GENERIERUNG: Aufklappbares Panel ===
                  if (hasGeneratedTrip) ...[
                    const SizedBox(height: 12),
                    _CollapsibleTripPanel(
                      isExpanded: _isPanelExpanded,
                      onToggle: () => setState(() => _isPanelExpanded = !_isPanelExpanded),
                      planMode: _planMode,
                      randomTripState: randomTripState,
                    ),
                  ],

                ],
              ),
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
  final bool bare;

  const _TripConfigPanel({required this.mode, this.bare = false});

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

  /// Stellt sicher, dass GPS bereit ist (Services + Berechtigungen)
  /// Gibt true zurück wenn GPS nutzbar ist
  Future<bool> _ensureGPSReady() async {
    // 1. Location Services prüfen
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
        // Nach Rückkehr aus Settings: erneut prüfen
        await Future.delayed(const Duration(milliseconds: 500));
        final nowEnabled = await Geolocator.isLocationServiceEnabled();
        if (!nowEnabled) return false;
      } else {
        return false;
      }
    }

    // 2. Berechtigungen prüfen
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          AppSnackbar.showError(context, 'GPS-Berechtigung wurde verweigert');
        }
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return false;
      final shouldOpen = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('GPS-Berechtigung verweigert'),
          content: const Text(
            'Die GPS-Berechtigung wurde dauerhaft verweigert. '
            'Bitte erlaube den Standortzugriff in den App-Einstellungen.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('App-Einstellungen'),
            ),
          ],
        ),
      ) ?? false;
      if (shouldOpen) {
        await Geolocator.openAppSettings();
      }
      return false;
    }

    return true;
  }

  /// Handelt GPS-Button-Klick mit Dialog
  Future<void> _handleGPSButtonTap() async {
    final gpsReady = await _ensureGPSReady();
    if (!gpsReady) return;

    // GPS bereit - Standort ermitteln
    final notifier = ref.read(randomTripNotifierProvider.notifier);
    await notifier.useCurrentLocation();
  }

  /// Handelt "Überrasch mich!" Klick - prüft GPS wenn kein Startpunkt
  Future<void> _handleGenerateTrip() async {
    final state = ref.read(randomTripNotifierProvider);
    final notifier = ref.read(randomTripNotifierProvider.notifier);

    // Prüfen ob ein aktiver Trip existiert, der überschrieben wird
    final activeTripData = ref.read(activeTripNotifierProvider).value;
    if (activeTripData != null && !activeTripData.allDaysCompleted) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Aktiver Trip vorhanden'),
          content: Text(
            'Du hast einen aktiven ${activeTripData.trip.actualDays}-Tage-Trip '
            'mit ${activeTripData.completedDays.length} abgeschlossenen Tagen. '
            'Ein neuer Trip überschreibt diesen.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Neuen Trip erstellen'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    // Wenn kein Startpunkt gesetzt, GPS sicherstellen
    if (!state.hasValidStart) {
      final gpsReady = await _ensureGPSReady();
      if (!gpsReady) return;

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

  /// Zeigt das Ziel-Eingabe BottomSheet an
  void _showDestinationSheet(
    BuildContext context,
    RandomTripState state,
    RandomTripNotifier notifier,
    ColorScheme colorScheme,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: _DestinationSheetContent(
            destinationController: _destinationController,
            destinationFocusNode: _destinationFocusNode,
            isSearching: _isSearchingDestination,
            suggestions: _destinationSuggestions,
            onSearch: _searchDestination,
            onSelect: (result) {
              _selectDestinationSuggestion(result);
              Navigator.pop(ctx);
            },
            onClear: () {
              notifier.clearDestination();
              _destinationController.clear();
              setState(() => _destinationSuggestions = []);
              Navigator.pop(ctx);
            },
            hasDestination: state.hasDestination,
          ),
        );
      },
    ).then((_) {
      // Rebuild parent um Button-Text zu aktualisieren
      if (mounted) setState(() {});
    });
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

    final content = Column(
            mainAxisSize: MainAxisSize.min,
            children: [
          // Wetter-Widget (v1.7.20 - innerhalb des Panels, nutzt eigenes margin)
          const UnifiedWeatherWidget(),

          // Startadresse (kompakt mit inline GPS-Button)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label + GPS-Button in einer Zeile
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Start',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    // Kompakter GPS-Button inline
                    InkWell(
                      onTap: state.isLoading ? null : _handleGPSButtonTap,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: state.useGPS && state.hasValidStart
                              ? colorScheme.primaryContainer
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: state.useGPS && state.hasValidStart
                                ? colorScheme.primary
                                : colorScheme.outline.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (state.isLoading && state.useGPS)
                              SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.primary,
                                ),
                              )
                            else
                              Icon(
                                Icons.my_location,
                                size: 13,
                                color: state.useGPS && state.hasValidStart
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                              ),
                            const SizedBox(width: 4),
                            Text(
                              state.useGPS && state.startAddress != null
                                  ? state.startAddress!
                                  : 'GPS',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: state.useGPS && state.hasValidStart
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
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
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Stadt oder Adresse...',
                          hintStyle: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                          prefixIcon: Icon(Icons.search, size: 18, color: colorScheme.onSurfaceVariant),
                          suffixIcon: _isSearching
                              ? const Padding(
                                  padding: EdgeInsets.all(10),
                                  child: SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              : _addressController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 16),
                                      onPressed: () {
                                        _addressController.clear();
                                        setState(() => _suggestions = []);
                                      },
                                    )
                                  : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  child: Row(
                                    children: [
                                      Icon(Icons.location_on, size: 14, color: colorScheme.primary),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          result.shortName ?? result.displayName,
                                          style: const TextStyle(fontSize: 12),
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
              ],
            ),
          ),

          Divider(height: 1, color: colorScheme.outline.withOpacity(0.2)),

          // Ziel-Eingabe (kompakt - öffnet BottomSheet)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: InkWell(
              onTap: () => _showDestinationSheet(context, state, notifier, colorScheme),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: state.hasDestination
                        ? colorScheme.primary
                        : colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.flag,
                      size: 16,
                      color: state.hasDestination
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.hasDestination
                            ? state.destinationAddress!
                            : 'Ziel hinzufuegen (optional)',
                        style: TextStyle(
                          fontSize: 13,
                          color: state.hasDestination
                              ? colorScheme.onSurface
                              : colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (state.hasDestination)
                      GestureDetector(
                        onTap: () {
                          notifier.clearDestination();
                          _destinationController.clear();
                          setState(() => _destinationSuggestions = []);
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Icon(Icons.close, size: 16, color: colorScheme.error),
                        ),
                      )
                    else
                      Icon(Icons.arrow_forward_ios, size: 14, color: colorScheme.onSurfaceVariant),
                  ],
                ),
              ),
            ),
          ),

          Divider(height: 1, color: colorScheme.outline.withOpacity(0.2)),

          // Radius Slider (kompakt)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: state.isLoading ? null : _handleGenerateTrip,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🎲', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    const Text(
                      'Überrasch mich!',
                      style: TextStyle(
                        fontSize: 14,
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
          );

    // bare-Modus: Nur Column-Inhalt ohne Container/Scroll
    if (widget.bare) {
      return content;
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
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: SingleChildScrollView(
          child: content,
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
    if (state.mode == RandomTripMode.eurotrip) {
      return _buildDaysSelector(context);
    }
    return _buildRadiusSlider(context);
  }

  /// Euro Trip: Tage-Auswahl als primärer Input
  Widget _buildDaysSelector(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentDays = state.days.clamp(
      TripConstants.euroTripMinDays,
      TripConstants.euroTripMaxDays,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  'Reisedauer',
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
                '$currentDays ${currentDays == 1 ? "Tag" : "Tage"}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            _getDaysDescription(currentDays),
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        SizedBox(
          height: 32,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: colorScheme.primary,
              inactiveTrackColor: colorScheme.primary.withOpacity(0.2),
              thumbColor: colorScheme.primary,
              overlayColor: colorScheme.primary.withOpacity(0.1),
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Slider(
              value: currentDays.toDouble(),
              min: TripConstants.euroTripMinDays.toDouble(),
              max: TripConstants.euroTripMaxDays.toDouble(),
              divisions: TripConstants.euroTripMaxDays - TripConstants.euroTripMinDays,
              onChanged: (value) => notifier.setEuroTripDays(value.round()),
            ),
          ),
        ),
        // Quick Select Tage
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: TripConstants.euroTripQuickSelectDays.map((days) {
            final isSelected = currentDays == days;
            return GestureDetector(
              onTap: () => notifier.setEuroTripDays(days),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected ? colorScheme.primary : colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Text(
                  '$days Tage',
                  style: TextStyle(
                    fontSize: 10,
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

  /// Tagestrip: Radius-Slider (unverändert)
  Widget _buildRadiusSlider(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const minRadius = 30.0;
    const maxRadius = 300.0;
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
        SizedBox(
          height: 32,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: colorScheme.primary,
              inactiveTrackColor: colorScheme.primary.withOpacity(0.2),
              thumbColor: colorScheme.primary,
              overlayColor: colorScheme.primary.withOpacity(0.1),
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Slider(
              value: currentRadius,
              min: minRadius,
              max: maxRadius,
              divisions: ((maxRadius - minRadius) / 10).round(),
              onChanged: (value) => notifier.setRadius(value),
            ),
          ),
        ),
        // Quick Select (kompakt)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [50.0, 100.0, 200.0, 300.0].map((value) {
            final isSelected = (currentRadius - value).abs() < 10;
            return GestureDetector(
              onTap: () => notifier.setRadius(value),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                    fontSize: 10,
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

  String _getDaysDescription(int days) {
    final radiusKm = (days * TripConstants.kmPerDay).round();
    if (days == 1) return 'Tagesausflug — ca. $radiusKm km';
    if (days == 2) return 'Wochenend-Trip — ca. $radiusKm km';
    if (days <= 4) return 'Kurzurlaub — ca. $radiusKm km';
    if (days <= 7) return 'Wochenreise — ca. $radiusKm km';
    return 'Epischer Euro Trip — ca. $radiusKm km';
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

/// Aufklappbares Trip-Panel nach Routenberechnung
/// Zeigt kompakte Info-Leiste (zugeklappt) oder volles Config-Panel (aufgeklappt)
class _CollapsibleTripPanel extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onToggle;
  final MapPlanMode planMode;
  final RandomTripState randomTripState;

  const _CollapsibleTripPanel({
    required this.isExpanded,
    required this.onToggle,
    required this.planMode,
    required this.randomTripState,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
      child: AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Kompakte Info-Leiste (immer sichtbar)
            _TripInfoBar(
              randomTripState: randomTripState,
              isExpanded: isExpanded,
              onToggle: onToggle,
            ),
            // Aufklappbarer Inhalt
            if (isExpanded) ...[
              Divider(height: 1, color: colorScheme.outline.withOpacity(0.2)),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                ),
                child: SingleChildScrollView(
                  child: _TripConfigPanel(mode: planMode, bare: true),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Kompakte Trip-Info-Leiste mit Route-Zusammenfassung
class _TripInfoBar extends StatelessWidget {
  final RandomTripState randomTripState;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _TripInfoBar({
    required this.randomTripState,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final stats = randomTripState.tripStats;
    final isEuroTrip = randomTripState.mode == RandomTripMode.eurotrip;

    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Route-Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isEuroTrip ? Icons.flight_outlined : Icons.route,
                size: 20,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            // Titel + Stats
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEuroTrip ? 'AI Euro Trip' : 'AI Tagestrip',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  if (stats != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      stats,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Auf/Zuklapp-Pfeil
            AnimatedRotation(
              turns: isExpanded ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.keyboard_arrow_down,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// BottomSheet-Inhalt für Ziel-Eingabe
class _DestinationSheetContent extends StatelessWidget {
  final TextEditingController destinationController;
  final FocusNode destinationFocusNode;
  final bool isSearching;
  final List<GeocodingResult> suggestions;
  final void Function(String) onSearch;
  final void Function(GeocodingResult) onSelect;
  final VoidCallback onClear;
  final bool hasDestination;

  const _DestinationSheetContent({
    required this.destinationController,
    required this.destinationFocusNode,
    required this.isSearching,
    required this.suggestions,
    required this.onSearch,
    required this.onSelect,
    required this.onClear,
    required this.hasDestination,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle-Bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colorScheme.outline.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Titel
            Row(
              children: [
                Icon(Icons.flag, size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Ziel (optional)',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                if (hasDestination)
                  TextButton.icon(
                    onPressed: onClear,
                    icon: Icon(Icons.close, size: 16, color: colorScheme.error),
                    label: Text('Entfernen', style: TextStyle(color: colorScheme.error, fontSize: 13)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Ziel-Adress-Eingabe
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasDestination
                      ? colorScheme.primary
                      : colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: TextField(
                controller: destinationController,
                focusNode: destinationFocusNode,
                autofocus: true,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Zielort eingeben...',
                  hintStyle: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
                  prefixIcon: Icon(Icons.search, size: 20, color: colorScheme.onSurfaceVariant),
                  suffixIcon: isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(10),
                          child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : destinationController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                destinationController.clear();
                                onSearch('');
                              },
                            )
                          : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  isDense: true,
                ),
                onChanged: onSearch,
              ),
            ),
            // Vorschläge
            if (suggestions.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: suggestions.length,
                  itemBuilder: (context, index) {
                    final result = suggestions[index];
                    return InkWell(
                      onTap: () => onSelect(result),
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
            const SizedBox(height: 8),
            // Hinweis-Text
            Text(
              hasDestination
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
    );
  }
}

/// Banner zum Fortsetzen eines aktiven mehrtägigen Euro Trips
class _ActiveTripResumeBanner extends ConsumerWidget {
  final VoidCallback onRestore;

  const _ActiveTripResumeBanner({required this.onRestore});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTripAsync = ref.watch(activeTripNotifierProvider);
    final randomTripState = ref.watch(randomTripNotifierProvider);

    // Nur anzeigen wenn kein Trip aktuell in Memory geladen
    if (randomTripState.generatedTrip != null) {
      return const SizedBox.shrink();
    }

    return activeTripAsync.when(
      data: (activeTrip) {
        if (activeTrip == null) return const SizedBox.shrink();
        if (activeTrip.allDaysCompleted) return const SizedBox.shrink();

        final trip = activeTrip.trip;
        final nextDay = activeTrip.nextUncompletedDay ?? 1;
        final completedCount = activeTrip.completedDays.length;
        final totalDays = trip.actualDays;
        final progress = totalDays > 0 ? completedCount / totalDays : 0.0;

        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final isDark = theme.brightness == Brightness.dark;

        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: colorScheme.primary.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(
                        Icons.flight_outlined,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Aktiver Euro Trip',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      // Schließen-Button (Verwerfen)
                      InkWell(
                        onTap: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Trip verwerfen?'),
                              content: Text(
                                'Dein $totalDays-Tage-Trip mit $completedCount '
                                'abgeschlossenen Tagen wird gelöscht.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Abbrechen'),
                                ),
                                FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: colorScheme.error,
                                  ),
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Verwerfen'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            ref.read(activeTripNotifierProvider.notifier).clear();
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.close,
                            size: 18,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Subtitle
                  Text(
                    'Tag $nextDay steht an',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      color: colorScheme.primary,
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$completedCount von $totalDays Tagen abgeschlossen',
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Fortsetzen Button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () async {
                        await ref
                            .read(randomTripNotifierProvider.notifier)
                            .restoreFromActiveTrip(activeTrip);
                        onRestore();
                      },
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: const Text('Fortsetzen'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

