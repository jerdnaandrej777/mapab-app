import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../core/l10n/l10n.dart';
import '../../core/utils/location_helper.dart';
import '../../data/models/poi.dart';
import '../../data/models/route.dart';
import '../../data/models/trip.dart';
import '../../data/repositories/geocoding_repo.dart';
import '../../shared/widgets/app_snackbar.dart';
import '../random_trip/providers/random_trip_provider.dart';
import '../random_trip/providers/random_trip_state.dart';
import '../random_trip/widgets/generation_progress_indicator.dart';
import '../trip/widgets/day_editor_overlay.dart';
import 'providers/app_ui_mode_provider.dart';
import 'providers/map_controller_provider.dart';
import 'providers/memory_point_provider.dart';
import 'providers/route_planner_provider.dart';
import 'providers/weather_provider.dart';
import '../trip/providers/trip_state_provider.dart';
import 'widgets/active_trip_resume_banner.dart';
import 'widgets/map_view.dart';
import 'widgets/trip_config_panel.dart';
import 'widgets/trip_info_bar.dart';

/// Hauptscreen mit Karte
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final List<ProviderSubscription<dynamic>> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    // Listener für Route-Änderungen (Auto-Zoom)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

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

      // Listener für neue Route-Berechnungen + Fehler (zusammengefuehrt)
      _subscriptions.add(
        ref.listenManual(routePlannerProvider, (previous, next) {
          // Wenn eine neue Route berechnet wurde, zoome die Karte darauf
          if (next.hasRoute && (previous?.route != next.route)) {
            _fitMapToRoute(next.route!);
          }
          // Fehler bei Routenberechnung anzeigen
          if (next.error != null && next.error != previous?.error && mounted) {
            AppSnackbar.showError(context, context.l10n.errorRouteCalculation);
          }
        }),
      );

      // Listener für AI Trip - wenn Trip generiert, Route auf Karte zoomen
      _subscriptions.add(
        ref.listenManual(randomTripNotifierProvider, (previous, next) {
          debugPrint(
              '[MapScreen] RandomTrip State changed: ${previous?.step} -> ${next.step}');
          if (next.step == RandomTripStep.preview &&
              previous?.step != RandomTripStep.preview) {
            // Trip wurde generiert - Route auf Karte zoomen
            final aiRoute = next.generatedTrip?.trip.route;
            debugPrint(
                '[MapScreen] AI Trip generated! Route: ${aiRoute != null}, POIs: ${next.generatedTrip?.selectedPOIs.length ?? 0}');
            debugPrint(
                '[MapScreen] Route coords: ${aiRoute?.coordinates.length ?? 0}');
            if (aiRoute != null && mounted) {
              _fitMapToRoute(aiRoute);
            }
            // Generierung abgeschlossen - UI aktualisieren
            if (mounted) setState(() {});
          }
          // Wenn Trip bestätigt wurde, ebenfalls Route zoomen
          if (next.step == RandomTripStep.confirmed &&
              previous?.step != RandomTripStep.confirmed) {
            final tripState = ref.read(tripStateProvider);
            if (tripState.hasRoute && mounted) {
              _fitMapToRoute(tripState.route!);
            }
          }
          // Fehler bei AI Trip anzeigen
          if (next.error != null && next.error != previous?.error && mounted) {
            AppSnackbar.showError(
                context, context.l10n.errorTripGeneration(next.error!));
          }
        }),
      );
    });
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.close();
    }
    _subscriptions.clear();
    super.dispose();
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

    debugPrint(
        '[Map] Route angezeigt: ${route.distanceKm.toStringAsFixed(0)} km');
  }

  @override
  Widget build(BuildContext context) {
    final routePlanner = ref.watch(routePlannerProvider);
    final randomTripState = ref.watch(randomTripNotifierProvider);
    final tripState = ref.watch(tripStateProvider);
    final mapRouteFocusMode = ref.watch(mapRouteFocusModeProvider);

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

    final pendingMapCenter = ref.watch(pendingMapCenterProvider);
    if (pendingMapCenter != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final controller = ref.read(mapControllerProvider);
        if (controller == null) return;
        controller.move(pendingMapCenter, 13.0);
        ref.read(pendingMapCenterProvider.notifier).state = null;
      });
    }

    final colorScheme = Theme.of(context).colorScheme;

    // Panel-Sichtbarkeits-Logik
    final isConfigStep = randomTripState.step == RandomTripStep.config;
    final isGenerating = randomTripState.step == RandomTripStep.generating;
    final hasGeneratedTrip = (randomTripState.step == RandomTripStep.preview ||
            randomTripState.step == RandomTripStep.confirmed) &&
        randomTripState.generatedTrip != null;
    final hasAnyRouteLoaded =
        routePlanner.hasRoute || tripState.hasRoute || hasGeneratedTrip;
    final activeRoute =
        _resolveActiveRoute(routePlanner, tripState, randomTripState);
    final activeStops = _resolveActiveStops(tripState, randomTripState);
    final memoryPoint = ref.watch(memoryPointProvider);

    if (mapRouteFocusMode && !hasAnyRouteLoaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(mapRouteFocusModeProvider.notifier).state = false;
      });
    }

    // Memory-Point aufraumen wenn anderer Modus aktiv wird
    if (memoryPoint != null && mapRouteFocusMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(memoryPointProvider.notifier).state = null;
      });
    }

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        title: Text(context.l10n.appName),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        actions: [
          // Galerie-Button
          IconButton(
            icon: const Icon(Icons.explore_outlined),
            onPressed: () => context.push('/gallery'),
            tooltip: context.l10n.galleryTitle,
          ),
          // Favoriten-Button
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () => context.push('/favorites'),
            tooltip: context.l10n.mapFavorites,
          ),
          // Reisetagebuch-Button
          IconButton(
            icon: const Icon(Icons.auto_stories_outlined),
            onPressed: () =>
                _openJournalFromMap(routePlanner, tripState, randomTripState),
            tooltip: context.l10n.journalTitle,
          ),
          // Profil-Button
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/profile'),
            tooltip: context.l10n.mapProfile,
          ),
          // Einstellungen-Button
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
            tooltip: context.l10n.mapSettings,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Karte (Hintergrund)
          const MapView(),

          // Such-Header (kein SafeArea top noetig - AppBar uebernimmt)
          if (!mapRouteFocusMode && memoryPoint == null)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // === AKTIVER TRIP BANNER (Fortsetzen) ===
                    if (isConfigStep && !isGenerating)
                      ActiveTripResumeBanner(
                        onRestore: () {
                          ref
                              .read(appUIModeNotifierProvider.notifier)
                              .setMode(MapPlanMode.aiEuroTrip);
                        },
                      ),

                    // === TRIP CONFIG PANEL (Konfigurationsphase) ===
                    if (isConfigStep && !isGenerating) ...[
                      const SizedBox(height: 12),
                      TripConfigPanel(
                        mode: ref.watch(appUIModeNotifierProvider),
                      ),
                    ],

                    // === POST-GENERIERUNG: Kompakte Info-Leiste ===
                    if (hasGeneratedTrip) ...[
                      const SizedBox(height: 12),
                      TripInfoBar(
                        randomTripState: randomTripState,
                        onEdit: () => _openDayEditor(),
                        onStartNavigation: () {
                          final trip = randomTripState.generatedTrip?.trip;
                          if (trip != null) {
                            context.push(
                              '/navigation',
                              extra: {
                                'route': trip.route,
                                'stops': trip.stops,
                              },
                            );
                          }
                        },
                        onClearRoute: () {
                          ref.read(randomTripNotifierProvider.notifier).reset();
                          ref.read(routePlannerProvider.notifier).clearRoute();
                          ref.read(tripStateProvider.notifier).clearAll();
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          // Lade-Widget auf gleicher Hoehe wie das AI-Trip-Konfigurationspanel
          if (isGenerating && !mapRouteFocusMode && memoryPoint == null)
            const SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 12),
                    GenerationProgressIndicator(panelMode: true),
                  ],
                ),
              ),
            ),
          if (mapRouteFocusMode && hasAnyRouteLoaded)
            Align(
              alignment: Alignment.bottomCenter,
              child: _RouteFocusFooter(
                onEditTrip: () {
                  ref.read(mapRouteFocusModeProvider.notifier).state = false;
                  context.go('/trip');
                },
                onStartNavigation: activeRoute == null
                    ? null
                    : () {
                        ref.read(mapRouteFocusModeProvider.notifier).state =
                            false;
                        context.push(
                          '/navigation',
                          extra: {
                            'route': activeRoute,
                            'stops': activeStops,
                          },
                        );
                      },
                onDeleteRoute: () {
                  ref.read(mapRouteFocusModeProvider.notifier).state = false;
                  ref.read(randomTripNotifierProvider.notifier).reset();
                  ref.read(routePlannerProvider.notifier).clearRoute();
                  ref.read(tripStateProvider.notifier).clearAll();
                },
              ),
            ),

          // Erinnerungspunkt-Footer (aus Reisetagebuch)
          if (memoryPoint != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: _MemoryPointFooter(
                memoryPoint: memoryPoint,
                onCancel: () {
                  ref.read(memoryPointProvider.notifier).state = null;
                },
                onRevisit: () => _handleRevisitMemoryPoint(memoryPoint),
              ),
            ),
        ],
      ),
    );
  }

  AppRoute? _resolveActiveRoute(
    RoutePlannerData routePlanner,
    TripStateData tripState,
    RandomTripState randomTripState,
  ) {
    if ((randomTripState.step == RandomTripStep.preview ||
            randomTripState.step == RandomTripStep.confirmed) &&
        randomTripState.generatedTrip != null) {
      return randomTripState.generatedTrip!.trip.route;
    }
    if (tripState.hasRoute) return tripState.route;
    if (routePlanner.hasRoute) return routePlanner.route;
    return null;
  }

  List<TripStop> _resolveActiveStops(
    TripStateData tripState,
    RandomTripState randomTripState,
  ) {
    if ((randomTripState.step == RandomTripStep.preview ||
            randomTripState.step == RandomTripStep.confirmed) &&
        randomTripState.generatedTrip != null) {
      return randomTripState.generatedTrip!.trip.stops;
    }

    return tripState.stops
        .asMap()
        .entries
        .map((e) => TripStop.fromPOI(e.value, order: e.key))
        .toList();
  }

  /// Zentriert die Karte still auf aktuelle GPS-Position (ohne UI-Feedback)
  /// Verwendet bei Tab-Wechsel wenn keine Route vorhanden
  Future<void> _centerOnCurrentLocationSilent() async {
    final result = await LocationHelper.getCurrentPosition(
      accuracy: LocationAccuracy.medium,
      timeLimit: const Duration(seconds: 5),
    );

    if (!result.isSuccess) {
      _showDefaultMapCenter();
      return;
    }

    if (!mounted) return;

    final location = result.position!;
    final mapController = ref.read(mapControllerProvider);
    if (mapController != null) {
      mapController.move(location, 12.0);
      debugPrint('[GPS] Karte auf Standort zentriert');
    }

    // Reverse Geocoding für Wetter-Widget
    String locationName = context.l10n.mapMyLocation;
    try {
      final geocodingRepo = ref.read(geocodingRepositoryProvider);
      final geocodeResult = await geocodingRepo.reverseGeocode(location);
      if (!mounted) return;
      if (geocodeResult != null) {
        locationName = geocodeResult.shortName ?? geocodeResult.displayName;
      }
    } catch (e) {
      debugPrint('[GPS] Reverse Geocoding fehlgeschlagen: $e');
    }

    if (!mounted) return;

    ref.read(locationWeatherNotifierProvider.notifier).loadWeatherForLocation(
          location,
          locationName: locationName,
        );
  }

  /// Zeigt Europa-Zentrum als Fallback
  void _showDefaultMapCenter() {
    final mapController = ref.read(mapControllerProvider);
    if (mapController != null) {
      mapController.move(const LatLng(50.0, 10.0), 6.0);
      debugPrint('[Map] Fallback: Europa-Zentrum angezeigt');
    }
  }

  /// Öffnet den Day Editor als Vollbild-Overlay
  void _openDayEditor() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const DayEditorOverlay(),
      ),
    );
  }

  /// Baut Route von GPS zum Erinnerungspunkt und navigiert zum TripScreen
  Future<void> _handleRevisitMemoryPoint(MemoryPointData memoryPoint) async {
    // Stale State zuruecksetzen
    ref.read(randomTripNotifierProvider.notifier).reset();
    ref.read(routePlannerProvider.notifier).clearRoute();
    ref.read(tripStateProvider.notifier).clearAll();

    // Synthetischen POI erstellen
    final poi = POI(
      id: 'memory-${memoryPoint.entryId}',
      name: memoryPoint.poiName ?? context.l10n.journalMemoryPoint,
      latitude: memoryPoint.location.latitude,
      longitude: memoryPoint.location.longitude,
      categoryId: 'attraction',
    );

    // Route berechnen von GPS zum Ziel
    final result = await ref
        .read(tripStateProvider.notifier)
        .addStopWithAutoRoute(poi);

    if (!mounted) return;

    if (result.success) {
      ref.read(memoryPointProvider.notifier).state = null;
      ref.read(shouldFitToRouteProvider.notifier).state = true;
      ref.read(mapRouteFocusModeProvider.notifier).state = true;
    } else if (result.isGpsDisabled) {
      await LocationHelper.showGpsDialog(context);
    } else {
      AppSnackbar.showError(
        context,
        result.error ?? context.l10n.errorRouteCalculation,
      );
    }
  }

  /// Oeffnet das Reisetagebuch direkt aus dem Map-Header.
  void _openJournalFromMap(
    RoutePlannerData routePlanner,
    TripStateData tripState,
    RandomTripState randomTripState,
  ) {
    String tripId;
    String tripName;

    // Nur bei einem echten AI Trip die Trip-ID nutzen,
    // sonst immer 'journal-home' damit Eintraege unabhaengig
    // vom Route-Status sichtbar bleiben.
    if ((randomTripState.step == RandomTripStep.preview ||
            randomTripState.step == RandomTripStep.confirmed) &&
        randomTripState.generatedTrip != null) {
      final trip = randomTripState.generatedTrip!.trip;
      tripId = trip.id;
      tripName = trip.name;
    } else {
      tripId = 'journal-home';
      tripName = context.l10n.journalTitle;
    }

    context.push('/journal/$tripId?name=${Uri.encodeComponent(tripName)}');
  }
}

class _RouteFocusFooter extends StatelessWidget {
  final VoidCallback onEditTrip;
  final VoidCallback? onStartNavigation;
  final VoidCallback onDeleteRoute;

  const _RouteFocusFooter({
    required this.onEditTrip,
    required this.onStartNavigation,
    required this.onDeleteRoute,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onEditTrip,
                icon: const Icon(Icons.edit_outlined),
                label: Text(context.l10n.tripInfoEditTrip),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onStartNavigation,
                icon: const Icon(Icons.navigation),
                label: Text(context.l10n.tripInfoStartNavigation),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onDeleteRoute,
                icon: const Icon(Icons.delete_outline),
                label: Text(context.l10n.tripConfigDeleteRoute),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.error,
                  side: BorderSide(
                      color: colorScheme.error.withValues(alpha: 0.6)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Footer fuer Erinnerungspunkt aus dem Reisetagebuch
class _MemoryPointFooter extends StatelessWidget {
  final MemoryPointData memoryPoint;
  final VoidCallback onCancel;
  final VoidCallback onRevisit;

  const _MemoryPointFooter({
    required this.memoryPoint,
    required this.onCancel,
    required this.onRevisit,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Info-Zeile
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.tertiaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.auto_stories,
                    size: 20,
                    color: colorScheme.onTertiaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        memoryPoint.poiName ?? l10n.journalMemoryPoint,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _formatDate(memoryPoint.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.close, size: 18),
                    label: Text(l10n.cancel),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onRevisit,
                    icon: const Icon(Icons.route, size: 18),
                    label: Text(l10n.journalRevisit),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    return '$day.$month.$year';
  }
}
