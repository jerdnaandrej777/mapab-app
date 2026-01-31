import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/categories.dart';
import '../../core/theme/app_theme.dart';
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
import 'widgets/weather_chip.dart';
import 'widgets/weather_details_sheet.dart';
import 'widgets/unified_weather_widget.dart';

/// Planungs-Modus (Schnell oder AI Trip)
enum MapPlanMode { schnell, aiTrip }

/// Hauptscreen mit Karte
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  bool _isLoadingLocation = false;
  bool _isLoadingSchnellGps = false;
  MapPlanMode _planMode = MapPlanMode.schnell;

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
          // Zu Schnell-Modus wechseln um Panel auszublenden
          setState(() => _planMode = MapPlanMode.schnell);
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
    final routeSession = ref.watch(routeSessionProvider);
    final randomTripState = ref.watch(randomTripNotifierProvider);
    final tripState = ref.watch(tripStateProvider);
    final weatherState = ref.watch(locationWeatherNotifierProvider);

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

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Zeige AI Trip Panel nur wenn Modus aktiv UND kein Trip generiert
    final showAITripPanel = _planMode == MapPlanMode.aiTrip &&
        randomTripState.step == RandomTripStep.config;

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
                  // Mode-Toggle (Schnell / AI Trip)
                  _ModeToggle(
                    selectedMode: _planMode,
                    onModeChanged: (mode) {
                      setState(() => _planMode = mode);
                      _syncLocationBetweenModes(mode);
                    },
                  ),

                  // === SCHNELL-MODUS ===
                  if (_planMode == MapPlanMode.schnell && !isGenerating) ...[
                    const SizedBox(height: 12),
                    _SchnellModePanel(
                      routePlanner: routePlanner,
                      routeSession: routeSession,
                      randomTripState: randomTripState,
                      tripState: tripState,
                      isLoadingSchnellGps: _isLoadingSchnellGps,
                      onSchnellModeGPS: _handleSchnellModeGPS,
                      onStartRoute: () {
                        _startRoute(routePlanner.route!);
                        context.go('/trip');
                      },
                    ),
                  ],

                  // === AI TRIP MODUS ===
                  if (_planMode == MapPlanMode.aiTrip && !isGenerating) ...[
                    const SizedBox(height: 12),
                    // AI Trip Panel (enthält jetzt auch das Wetter-Widget v1.7.20)
                    const _AITripPanel(),
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

          // Floating Action Button (rechts) - nur im Schnell-Modus anzeigen
          if (_planMode == MapPlanMode.schnell)
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

  /// GPS-Button im Schnell-Modus: Setzt aktuellen Standort als Startpunkt
  Future<void> _handleSchnellModeGPS() async {
    if (_isLoadingSchnellGps) return;

    setState(() => _isLoadingSchnellGps = true);

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
          debugPrint('[GPS] Berechtigung verweigert');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('[GPS] Berechtigung dauerhaft verweigert');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('GPS-Berechtigung wurde dauerhaft verweigert. Bitte in den Einstellungen aktivieren.'),
            ),
          );
        }
        return;
      }

      // Position abrufen
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      debugPrint('[GPS] Position: ${position.latitude}, ${position.longitude}');

      // Reverse Geocoding durchführen
      final latLng = LatLng(position.latitude, position.longitude);
      String addressName = 'Mein Standort'; // Fallback
      try {
        final geocodingRepo = ref.read(geocodingRepositoryProvider);
        final result = await geocodingRepo.reverseGeocode(latLng);

        if (result != null) {
          // Priorität: Stadt > Kurzname > Display-Name
          addressName = result.shortName ?? result.displayName;
          debugPrint('[GPS] Reverse Geocoding: $addressName');
        }
      } catch (e) {
        debugPrint('[GPS] Reverse Geocoding fehlgeschlagen: $e');
        // Fallback auf "Mein Standort"
      }

      // Startpunkt setzen mit echtem Stadtnamen
      ref.read(routePlannerProvider.notifier).setStart(latLng, addressName);

      // Karte zentrieren
      final mapController = ref.read(mapControllerProvider);
      if (mapController != null) {
        mapController.move(latLng, 15);
      }
    } catch (e) {
      debugPrint('[GPS] Fehler: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('GPS-Fehler: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingSchnellGps = false);
      }
    }
  }

  /// Synchronisiert Standort zwischen Modi beim Wechsel
  void _syncLocationBetweenModes(MapPlanMode newMode) {
    if (newMode == MapPlanMode.schnell) {
      // Wechsel zu Schnell-Modus: AI Trip Startpunkt → RoutePlanner übertragen
      final randomTripState = ref.read(randomTripNotifierProvider);
      if (randomTripState.hasValidStart) {
        final routePlanner = ref.read(routePlannerProvider);
        // Nur übertragen wenn RoutePlanner noch keinen Start hat
        if (!routePlanner.hasStart &&
            randomTripState.startLocation != null &&
            randomTripState.startAddress != null) {
          ref.read(routePlannerProvider.notifier).setStart(
            randomTripState.startLocation!,
            randomTripState.startAddress!,
          );
          debugPrint('[MapScreen] Startpunkt von AI Trip → Schnell-Modus übertragen');
        }
      }
    } else if (newMode == MapPlanMode.aiTrip) {
      // Wechsel zu AI Trip Modus: RoutePlanner Startpunkt → AI Trip übertragen
      final routePlanner = ref.read(routePlannerProvider);
      if (routePlanner.hasStart) {
        final randomTripState = ref.read(randomTripNotifierProvider);
        // Nur übertragen wenn AI Trip noch keinen Start hat
        if (!randomTripState.hasValidStart &&
            routePlanner.startLocation != null &&
            routePlanner.startAddress != null) {
          ref.read(randomTripNotifierProvider.notifier).setStartLocation(
            routePlanner.startLocation!,
            routePlanner.startAddress!,
          );
          debugPrint('[MapScreen] Startpunkt von Schnell-Modus → AI Trip übertragen');
        }
      }
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
                  color: colorScheme.onPrimary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: colorScheme.onPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Route starten',
                      style: TextStyle(
                        color: colorScheme.onPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${route.distanceKm.toStringAsFixed(0)} km · ${_formatDuration(route.durationMinutes)}',
                      style: TextStyle(
                        color: colorScheme.onPrimary.withOpacity(0.85),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              // Pfeil
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: colorScheme.onPrimary.withOpacity(0.8),
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
  final VoidCallback? onStartClear;
  final VoidCallback? onEndClear;
  final VoidCallback? onGpsTap;
  final bool isLoadingGps;
  final bool showContainer; // Neu: Optional Container anzeigen

  const _SearchBar({
    this.startAddress,
    this.endAddress,
    this.isCalculating = false,
    required this.onStartTap,
    required this.onEndTap,
    this.onStartClear,
    this.onEndClear,
    this.onGpsTap,
    this.isLoadingGps = false,
    this.showContainer = true, // Default: Container anzeigen
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final content = Column(
        children: [
          // Start-Eingabe mit GPS-Button
          Row(
            children: [
              Expanded(
                child: _SearchField(
                  icon: Icons.trip_origin,
                  iconColor: AppTheme.successColor,
                  hint: 'Startpunkt eingeben',
                  value: startAddress,
                  onTap: onStartTap,
                  onClear: onStartClear,
                ),
              ),
              // GPS-Button
              if (onGpsTap != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: isLoadingGps ? null : onGpsTap,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: startAddress != null && startAddress!.contains('Standort')
                            ? colorScheme.primaryContainer
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: isLoadingGps
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.primary,
                              ),
                            )
                          : Icon(
                              Icons.my_location,
                              size: 20,
                              color: colorScheme.primary,
                            ),
                    ),
                  ),
                ),
            ],
          ),

          Divider(height: 1, indent: 48, color: theme.dividerColor),

          // Ziel-Eingabe
          _SearchField(
            icon: Icons.place,
            iconColor: AppTheme.errorColor,
            hint: 'Ziel eingeben',
            value: endAddress,
            onTap: onEndTap,
            onClear: onEndClear,
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
    );

    // Mit oder ohne Container
    if (showContainer) {
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
        child: content,
      );
    }

    // Ohne Container (für Panel-Integration)
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: content,
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
  final VoidCallback? onClear;

  const _SearchField({
    required this.icon,
    required this.iconColor,
    required this.hint,
    this.value,
    required this.onTap,
    this.onClear,
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
            // X-Button zum Löschen wenn Wert gesetzt
            if (value != null && onClear != null)
              GestureDetector(
                onTap: onClear,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.close,
                    size: 20,
                    color: colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Route löschen Button
class _RouteClearButton extends StatelessWidget {
  final VoidCallback onClear;

  const _RouteClearButton({required this.onClear});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

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
              label: 'Schnell',
              icon: Icons.speed,
              isSelected: selectedMode == MapPlanMode.schnell,
              onTap: () => onModeChanged(MapPlanMode.schnell),
            ),
          ),
          Expanded(
            child: _ModeButton(
              label: 'AI Trip',
              icon: Icons.auto_awesome,
              isSelected: selectedMode == MapPlanMode.aiTrip,
              onTap: () => onModeChanged(MapPlanMode.aiTrip),
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

/// Schnell-Modus Panel - scrollbares Container mit Wetter + Suchleiste (v1.7.21)
class _SchnellModePanel extends ConsumerWidget {
  final RoutePlannerData routePlanner;
  final RouteSessionState routeSession;
  final RandomTripState randomTripState;
  final TripStateData tripState;
  final bool isLoadingSchnellGps;
  final VoidCallback onSchnellModeGPS;
  final VoidCallback onStartRoute;

  const _SchnellModePanel({
    required this.routePlanner,
    required this.routeSession,
    required this.randomTripState,
    required this.tripState,
    required this.isLoadingSchnellGps,
    required this.onSchnellModeGPS,
    required this.onStartRoute,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

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
          maxHeight: MediaQuery.of(context).size.height * 0.65,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Wetter-Widget (nutzt eigenes margin: 12h, 8v)
              const UnifiedWeatherWidget(),

              // Divider nach Wetter-Widget
              Divider(height: 1, color: colorScheme.outline.withOpacity(0.2)),

              // Suchleiste
              Padding(
                padding: const EdgeInsets.all(12),
                child: _SearchBar(
                  startAddress: routePlanner.startAddress,
                  endAddress: routePlanner.endAddress,
                  isCalculating: routePlanner.isCalculating,
                  onStartTap: () => context.push('/search?type=start'),
                  onEndTap: () => context.push('/search?type=end'),
                  onStartClear: routePlanner.hasStart
                      ? () => ref.read(routePlannerProvider.notifier).clearStart()
                      : null,
                  onEndClear: routePlanner.hasEnd
                      ? () => ref.read(routePlannerProvider.notifier).clearEnd()
                      : null,
                  onGpsTap: onSchnellModeGPS,
                  isLoadingGps: isLoadingSchnellGps,
                  showContainer: false, // Kein eigenes Container, da in Panel integriert
                ),
              ),

              // Divider nach Suchleiste (nur wenn Buttons folgen)
              if (routePlanner.hasStart || routePlanner.hasEnd ||
                  randomTripState.step == RandomTripStep.preview ||
                  randomTripState.step == RandomTripStep.confirmed ||
                  tripState.hasRoute ||
                  routePlanner.hasRoute ||
                  routeSession.isLoading)
                Divider(height: 1, color: colorScheme.outline.withOpacity(0.2)),

              // Route löschen Button
              if (routePlanner.hasStart || routePlanner.hasEnd ||
                  randomTripState.step == RandomTripStep.preview ||
                  randomTripState.step == RandomTripStep.confirmed ||
                  tripState.hasRoute)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: _RouteClearButton(
                    onClear: () {
                      ref.read(routePlannerProvider.notifier).clearRoute();
                      ref.read(randomTripNotifierProvider.notifier).reset();
                      ref.read(tripStateProvider.notifier).clearAll();
                    },
                  ),
                ),

              // Route-Start-Button
              if (routePlanner.hasRoute && !routeSession.isActive && !routeSession.isLoading)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: _RouteStartButton(
                    route: routePlanner.route!,
                    onStart: onStartRoute,
                  ),
                ),

              // Loading-Indikator
              if (routeSession.isLoading)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: _RouteLoadingIndicator(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// AI Trip Panel - kompakte Konfiguration über der Karte
class _AITripPanel extends ConsumerStatefulWidget {
  const _AITripPanel();

  @override
  ConsumerState<_AITripPanel> createState() => _AITripPanelState();
}

class _AITripPanelState extends ConsumerState<_AITripPanel> {
  final _addressController = TextEditingController();
  final _focusNode = FocusNode();
  List<GeocodingResult> _suggestions = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _addressController.dispose();
    _focusNode.dispose();
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

    // Sync controller
    if (state.startAddress != null && _addressController.text.isEmpty) {
      _addressController.text = state.startAddress!;
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

          // AI Trip Type Selector (Tagesausflug / Euro Trip)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: RandomTripMode.values.map((mode) {
                final isSelected = mode == state.mode;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: mode == RandomTripMode.daytrip ? 6 : 0,
                      left: mode == RandomTripMode.eurotrip ? 6 : 0,
                    ),
                    child: Material(
                      color: isSelected
                          ? colorScheme.primaryContainer
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        onTap: () => notifier.setMode(mode),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.outline.withOpacity(0.2),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(mode.icon, style: const TextStyle(fontSize: 18)),
                              const SizedBox(width: 6),
                              Text(
                                mode == RandomTripMode.daytrip ? 'Tagestrip' : 'Euro Trip',
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  fontSize: 13,
                                  color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          Divider(height: 1, color: colorScheme.outline.withOpacity(0.2)),

          // Startadresse
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

/// Dauerhafte Anzeige der Route-Adressen
/// Zeigt Start/Ziel mit Icons, Distanz/Dauer wenn Route berechnet
class _RouteAddressBar extends StatelessWidget {
  final RoutePlannerData routePlanner;

  const _RouteAddressBar({required this.routePlanner});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Nur anzeigen wenn Start ODER Ziel gesetzt
    if (!routePlanner.hasStart && !routePlanner.hasEnd) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Start-Adresse
          if (routePlanner.hasStart)
            _AddressRow(
              icon: Icons.trip_origin,
              iconColor: Colors.green,
              label: 'Start',
              address: routePlanner.startAddress!,
            ),

          // Trennlinie wenn beide gesetzt
          if (routePlanner.hasStart && routePlanner.hasEnd)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Divider(
                height: 1,
                color: colorScheme.outline.withOpacity(0.2),
              ),
            ),

          // Ziel-Adresse
          if (routePlanner.hasEnd)
            _AddressRow(
              icon: Icons.location_on,
              iconColor: Colors.red,
              label: 'Ziel',
              address: routePlanner.endAddress!,
            ),

          // Distanz/Dauer wenn Route berechnet
          if (routePlanner.hasRoute)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(Icons.route, size: 14, color: colorScheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    '${routePlanner.route!.formattedDistance} • ${routePlanner.route!.formattedDuration}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurfaceVariant,
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

/// Einzelne Adress-Zeile (Start oder Ziel)
class _AddressRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String address;

  const _AddressRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                address,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
