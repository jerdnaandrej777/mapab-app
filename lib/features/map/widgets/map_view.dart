import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/utils/location_helper.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../providers/map_controller_provider.dart';
import '../providers/route_planner_provider.dart';
import '../providers/weather_provider.dart';
import '../../trip/providers/trip_state_provider.dart';
import '../../poi/providers/poi_state_provider.dart';
import '../../random_trip/providers/random_trip_provider.dart';
import '../../random_trip/providers/random_trip_state.dart';
import '../../../core/constants/categories.dart';
import '../../../core/l10n/l10n.dart';
import '../../../data/models/poi.dart';
import 'route_weather_marker.dart';
import 'weather_badge_unified.dart';

/// Maximale Anzahl Koordinaten für Polyline-Rendering (Performance)
const int _maxPolylinePoints = 2000;

/// Reduziert Koordinaten für flüssiges Karten-Rendering
/// Bei >2000 Punkten wird jeder n-te Punkt genommen (Anfang+Ende bleiben erhalten)
List<LatLng> _downsampleCoordinates(List<LatLng> coords) {
  if (coords.length <= _maxPolylinePoints) return coords;

  final step = coords.length / _maxPolylinePoints;
  final result = <LatLng>[coords.first];

  for (int i = 1; i < _maxPolylinePoints - 1; i++) {
    final index = (i * step).floor().clamp(1, coords.length - 2);
    result.add(coords[index]);
  }

  result.add(coords.last);
  debugPrint('[MapView] Route downsampled: ${coords.length} → ${result.length} Punkte');
  return result;
}

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
  final List<ProviderSubscription<dynamic>> _subscriptions = [];

  // Standard-Zentrum: Europa (Deutschland)
  static const _defaultCenter = LatLng(50.0, 10.0);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    // Register controller globally after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(mapControllerProvider.notifier).state = _mapController;
      _setupWeatherListeners();
    });
  }

  /// Wetter-Laden fuer alle Routentypen (v1.7.11)
  void _setupWeatherListeners() {
    // Normale Route
    _subscriptions.add(
      ref.listenManual(routePlannerProvider, (previous, next) {
        if (next.hasRoute && previous?.route != next.route) {
          ref.read(routeWeatherNotifierProvider.notifier)
              .loadWeatherForRoute(next.route!.coordinates);
        }
      }),
    );

    // AI Trip Preview + Auto-Zoom bei Tageswechsel (zusammengefuehrt)
    _subscriptions.add(
      ref.listenManual(randomTripNotifierProvider, (previous, next) {
        // Wetter laden bei Trip-Generierung
        if (next.step == RandomTripStep.preview &&
            previous?.step != RandomTripStep.preview) {
          final route = next.generatedTrip?.trip.route;
          if (route != null) {
            ref.read(routeWeatherNotifierProvider.notifier)
                .loadWeatherForRoute(route.coordinates);
          }
        }
        // Auto-Zoom bei Tageswechsel (v1.8.1)
        if (previous?.selectedDay != next.selectedDay &&
            next.generatedTrip != null &&
            next.generatedTrip!.trip.actualDays > 1 &&
            mounted) {
          _zoomToDaySegment(next);
        }
      }),
    );

    // Trip State (gespeicherte Route laden)
    _subscriptions.add(
      ref.listenManual(tripStateProvider, (previous, next) {
        if (next.hasRoute && previous?.route != next.route) {
          ref.read(routeWeatherNotifierProvider.notifier)
              .loadWeatherForRoute(next.route!.coordinates);
        }
      }),
    );
  }

  /// Zoomt die Karte auf das Routensegment des ausgewaehlten Tages
  void _zoomToDaySegment(RandomTripState state) {
    final trip = state.generatedTrip!.trip;
    final selectedDay = state.selectedDay;
    final stopsForDay = trip.getStopsForDay(selectedDay);
    if (stopsForDay.isEmpty) return;

    final allPoints = <LatLng>[];

    // Start-Punkt des Tages
    if (selectedDay == 1) {
      allPoints.add(trip.route.start);
    } else {
      final prevDayStops = trip.getStopsForDay(selectedDay - 1);
      if (prevDayStops.isNotEmpty) {
        allPoints.add(prevDayStops.last.location);
      }
    }

    // Alle Stop-Positionen des Tages
    for (final stop in stopsForDay) {
      allPoints.add(stop.location);
    }

    if (allPoints.length < 2) return;

    // Bounds berechnen
    double minLat = allPoints.first.latitude;
    double maxLat = allPoints.first.latitude;
    double minLng = allPoints.first.longitude;
    double maxLng = allPoints.first.longitude;

    for (final point in allPoints) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final bounds = LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(60),
      ),
    );

    debugPrint('[MapView] Auto-Zoom auf Tag $selectedDay (${stopsForDay.length} Stops)');
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.close();
    }
    _subscriptions.clear();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tripState = ref.watch(tripStateProvider);
    final routePlanner = ref.watch(routePlannerProvider);
    final poiState = ref.watch(pOIStateNotifierProvider);
    final randomTripState = ref.watch(randomTripNotifierProvider);
    final weatherState = ref.watch(locationWeatherNotifierProvider);
    final routeWeather = ref.watch(routeWeatherNotifierProvider);

    // AI Trip Preview Route und POIs
    final fullAIRoute = randomTripState.generatedTrip?.trip.route;
    final allAITripPOIs = randomTripState.generatedTrip?.selectedPOIs ?? [];
    final isAITripPreview = randomTripState.step == RandomTripStep.preview;
    final aiTrip = randomTripState.generatedTrip?.trip;
    final isMultiDay = aiTrip != null && aiTrip.actualDays > 1;
    final selectedDay = randomTripState.selectedDay;

    // Bei Mehrtages-Trips: Nur POIs des ausgewählten Tages anzeigen
    List<POI> aiTripPOIs;
    List<LatLng> aiRouteCoordinates;
    if (isMultiDay && fullAIRoute != null) {
      final stopsForDay = aiTrip.getStopsForDay(selectedDay);
      final dayPOIIds = stopsForDay.map((s) => s.poiId).toSet();
      aiTripPOIs = allAITripPOIs.where((p) => dayPOIIds.contains(p.id)).toList();

      // Route-Segment für den ausgewählten Tag extrahieren
      if (stopsForDay.isNotEmpty) {
        LatLng segStart;
        LatLng segEnd;
        if (selectedDay == 1) {
          segStart = fullAIRoute.start;
        } else {
          final prevDayStops = aiTrip.getStopsForDay(selectedDay - 1);
          segStart = prevDayStops.isNotEmpty
              ? prevDayStops.last.location
              : stopsForDay.first.location;
        }
        if (selectedDay == aiTrip.actualDays) {
          segEnd = fullAIRoute.end;
        } else {
          segEnd = stopsForDay.last.location;
        }
        aiRouteCoordinates = _extractRouteSegment(
          fullAIRoute.coordinates, segStart, segEnd,
        );
      } else {
        aiRouteCoordinates = fullAIRoute.coordinates;
      }
    } else {
      aiTripPOIs = allAITripPOIs;
      aiRouteCoordinates = fullAIRoute?.coordinates ?? [];
    }

    // Wetter-Zustand für POI-Marker-Badges
    final weatherCondition = weatherState.hasWeather ? weatherState.condition : null;

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

        // Route-Polyline (wenn Route vorhanden - inkl. AI Trip Preview)
        // WICHTIG: AI Trip Preview hat Priorität über andere Routen
        if (tripState.hasRoute || routePlanner.route != null || (isAITripPreview && aiRouteCoordinates.isNotEmpty))
          PolylineLayer(
            polylines: [
              Polyline(
                // AI Trip Preview hat Priorität, dann TripState, dann RoutePlanner
                // Bei Mehrtages-Trips: Nur Segment des ausgewählten Tages
                // v1.10.2: Downsampling für lange Routen (ANR-Fix)
                points: _downsampleCoordinates(
                  (isAITripPreview && aiRouteCoordinates.isNotEmpty)
                      ? aiRouteCoordinates
                      : (tripState.route?.coordinates ??
                          routePlanner.route?.coordinates ??
                          []),
                ),
                color: Theme.of(context).colorScheme.primary,
                strokeWidth: 5,
                borderColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                borderStrokeWidth: 2,
              ),
            ],
          ),

        // Routen-Wetter-Marker (v1.7.11) - 5 Punkte entlang der Route
        if (routeWeather.weatherPoints.isNotEmpty && !routeWeather.isLoading)
          MarkerLayer(
            markers: routeWeather.weatherPoints.asMap().entries.map((entry) {
              final index = entry.key;
              final point = entry.value;
              return Marker(
                point: point.location,
                width: 72,
                height: 36,
                child: RouteWeatherMarker(
                  weatherPoint: point,
                  isStart: index == 0,
                  isEnd: index == routeWeather.weatherPoints.length - 1,
                  onTap: () => showRouteWeatherDetail(
                    context,
                    weatherPoint: point,
                    index: index,
                    totalPoints: routeWeather.weatherPoints.length,
                  ),
                ),
              );
            }).toList(),
          ),

        // POI-Marker Layer (normale POIs, nicht während AI Trip Preview) - mit Wetter-Badges (v1.7.9)
        if (poiState.filteredPOIs.isNotEmpty && !isAITripPreview)
          MarkerLayer(
            markers: poiState.filteredPOIs.map((poi) {
              final markerSize = _selectedPOIId == poi.id ? 48.0 : (poi.isMustSee ? 40.0 : 32.0);
              return Marker(
                point: poi.location,
                width: markerSize + 8,
                height: markerSize + 8,
                child: POIMarker(
                  icon: poi.categoryIcon,
                  isHighlight: poi.isMustSee,
                  isSelected: _selectedPOIId == poi.id,
                  onTap: () => _onPOITap(poi),
                  weatherCondition: weatherCondition,
                  isIndoorPOI: poi.isIndoor,
                ),
              );
            }).toList(),
          ),

        // AI Trip Preview POIs als nummerierte Marker
        if (isAITripPreview && aiTripPOIs.isNotEmpty)
          MarkerLayer(
            markers: aiTripPOIs.asMap().entries.map((entry) {
              final index = entry.key;
              final poi = entry.value;
              // Tages-Wetter fuer Multi-Day-Trips
              WeatherCondition? markerWeather;
              if (isMultiDay && routeWeather.hasForecast) {
                final forecastPerDay = routeWeather.getForecastPerDay(aiTrip!.actualDays);
                markerWeather = forecastPerDay[selectedDay];
              } else {
                markerWeather = weatherCondition;
              }
              return Marker(
                point: poi.location,
                width: 44,
                height: 44,
                child: _AITripStopMarker(
                  number: index + 1,
                  icon: poi.categoryIcon,
                  onTap: () => _onPOITap(poi),
                  weatherCondition: markerWeather,
                  isWeatherResilient: poi.category?.isWeatherResilient ?? false,
                ),
              );
            }).toList(),
          ),

        // Start-Marker (für normale Route oder AI Trip)
        // Bei Mehrtages-Trips: Start des ausgewählten Tages anzeigen
        if (routePlanner.startLocation != null || (isAITripPreview && randomTripState.startLocation != null))
          MarkerLayer(
            markers: [
              Marker(
                point: () {
                  if (isAITripPreview && isMultiDay && selectedDay > 1) {
                    // Ab Tag 2: Letzter Stop des Vortages als Start
                    final prevDayStops = aiTrip!.getStopsForDay(selectedDay - 1);
                    if (prevDayStops.isNotEmpty) return prevDayStops.last.location;
                  }
                  if (isAITripPreview && randomTripState.startLocation != null) {
                    return randomTripState.startLocation!;
                  }
                  return routePlanner.startLocation!;
                }(),
                width: 24,
                height: 24,
                child: const StartMarker(),
              ),
            ],
          ),

        // Ziel-Marker (nur für normale Route, nicht AI Trip)
        if (routePlanner.endLocation != null && !isAITripPreview)
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

        // Trip-Stops Marker (für bestätigte Trips)
        if (tripState.hasStops && !isAITripPreview)
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

  /// Extrahiert das Polyline-Segment zwischen zwei Punkten
  List<LatLng> _extractRouteSegment(
    List<LatLng> fullCoordinates,
    LatLng startPoint,
    LatLng endPoint,
  ) {
    if (fullCoordinates.isEmpty) return fullCoordinates;

    int startIdx = _findNearestIndex(fullCoordinates, startPoint);
    int endIdx = _findNearestIndex(fullCoordinates, endPoint);

    if (startIdx > endIdx) {
      final temp = startIdx;
      startIdx = endIdx;
      endIdx = temp;
    }

    return fullCoordinates.sublist(startIdx, (endIdx + 1).clamp(0, fullCoordinates.length));
  }

  int _findNearestIndex(List<LatLng> coords, LatLng target) {
    int bestIdx = 0;
    double bestDist = double.infinity;
    for (int i = 0; i < coords.length; i++) {
      final dLat = coords[i].latitude - target.latitude;
      final dLng = coords[i].longitude - target.longitude;
      final dist = dLat * dLat + dLng * dLng;
      if (dist < bestDist) {
        bestDist = dist;
        bestIdx = i;
      }
    }
    return bestIdx;
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

    // Direkt zur POI-Detail-Seite navigieren
    ref.read(pOIStateNotifierProvider.notifier).selectPOI(poi);
    context.push('/poi/${poi.id}');
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
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
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
                        .withValues(alpha: 0.2),
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
                                color: colorScheme.tertiary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '⭐ Must-See',
                                style: TextStyle(
                                  color: colorScheme.onTertiary,
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
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
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
                    label: Text(context.l10n.mapDetails),
                  ),
                ),
                const SizedBox(width: 12),
                // Zur Route Button
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _addPOIToTripFromMap(poi);
                    },
                    icon: const Icon(Icons.add),
                    label: Text(context.l10n.mapAddToRoute),
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
              title: Text(context.l10n.mapSetAsStart),
              onTap: () {
                Navigator.pop(context);
                routePlanner.setStart(point, context.l10n.mapSelectedPoint);
              },
            ),
            ListTile(
              leading: const Icon(Icons.place, color: Colors.red),
              title: Text(context.l10n.mapSetAsDestination),
              onTap: () {
                Navigator.pop(context);
                routePlanner.setEnd(point, context.l10n.mapSelectedPoint);
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_location),
              title: Text(context.l10n.mapAddAsStop),
              onTap: () {
                Navigator.pop(context);
                final tripNotifier = ref.read(tripStateProvider.notifier);
                final tripState = ref.read(tripStateProvider);
                if (tripState.route == null) {
                  // Ohne Route kann kein Stopp hinzugefuegt werden
                  return;
                }
                final tempPOI = POI(
                  id: 'waypoint-${DateTime.now().millisecondsSinceEpoch}',
                  name: context.l10n.mapWaypoint,
                  latitude: point.latitude,
                  longitude: point.longitude,
                  categoryId: 'attraction',
                  score: 0,
                );
                tripNotifier.addStop(tempPOI);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// POI zur Route hinzufügen mit Auto-Route von GPS-Standort
  Future<void> _addPOIToTripFromMap(POI poi) async {
    final tripNotifier = ref.read(tripStateProvider.notifier);
    final result = await tripNotifier.addStopWithAutoRoute(poi);

    if (!mounted) return;

    if (result.success) {
      if (result.routeCreated) {
        // Route wurde erstellt - zum Trip-Tab navigieren
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.mapRouteCreated(poi.name)),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go('/trip');
      } else {
        // Stop zur bestehenden Route hinzugefügt
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.mapPoiAdded(poi.name)),
          ),
        );
      }
    } else if (result.isGpsDisabled) {
      // GPS deaktiviert - Dialog anzeigen
      final shouldOpen = await _showGpsDialog();
      if (shouldOpen) {
        await LocationHelper.openSettings();
      }
    } else {
      // Anderer Fehler
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? context.l10n.mapErrorAdding),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// GPS-Dialog anzeigen - nutzt zentralisierten LocationHelper (v1.9.29)
  Future<bool> _showGpsDialog() async {
    return LocationHelper.showGpsDialog(context);
  }
}

/// Custom Marker Widget für POIs
class POIMarker extends StatelessWidget {
  final String icon;
  final bool isHighlight;
  final bool isSelected;
  final VoidCallback? onTap;
  final WeatherCondition? weatherCondition;
  final bool isIndoorPOI;

  const POIMarker({
    super.key,
    required this.icon,
    this.isHighlight = false,
    this.isSelected = false,
    this.onTap,
    this.weatherCondition,
    this.isIndoorPOI = false,
  });

  @override
  Widget build(BuildContext context) {
    final double size = isSelected ? 48 : (isHighlight ? 40 : 32);
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size + 8,
        height: size + 8,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.blue
                    : (isHighlight ? colorScheme.tertiary : colorScheme.surface),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _getMarkerBorderColor(colorScheme),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
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
            // Wetter-Badge oben-rechts
            if (weatherCondition != null && _shouldShowBadge())
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: _getBadgeColor(),
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.surface, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _getBadgeIcon(),
                      style: const TextStyle(fontSize: 8),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _shouldShowBadge() {
    if (weatherCondition == WeatherCondition.danger) return true;
    if (weatherCondition == WeatherCondition.bad) return true;
    if (weatherCondition == WeatherCondition.good && !isIndoorPOI) return true;
    return false;
  }

  Color _getBadgeColor() {
    if (weatherCondition == WeatherCondition.danger) return Colors.red;
    if (weatherCondition == WeatherCondition.bad) {
      return isIndoorPOI ? Colors.green : Colors.orange;
    }
    return Colors.green;
  }

  String _getBadgeIcon() {
    if (weatherCondition == WeatherCondition.danger) return '⚠️';
    if (weatherCondition == WeatherCondition.bad) {
      return isIndoorPOI ? '✓' : '!';
    }
    return '☀';
  }

  Color _getMarkerBorderColor(ColorScheme colorScheme) {
    if (isSelected) return colorScheme.surface;
    if (weatherCondition == WeatherCondition.danger) return Colors.red.shade300;
    if (weatherCondition == WeatherCondition.bad && !isIndoorPOI) {
      return Colors.orange.shade300;
    }
    return Colors.grey.shade300;
  }
}

/// Start-Marker Widget
class StartMarker extends StatelessWidget {
  const StartMarker({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.green,
        shape: BoxShape.circle,
        border: Border.all(color: colorScheme.surface, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
        border: Border.all(color: colorScheme.surface, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
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
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
          border: Border.all(color: colorScheme.surface, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 4,
            ),
          ],
        ),
        child: Center(
          child: Text(
            '$number',
            style: TextStyle(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

/// AI Trip Stop-Marker Widget mit Nummer und Icon
class _AITripStopMarker extends StatelessWidget {
  final int number;
  final String icon;
  final VoidCallback? onTap;
  final WeatherCondition? weatherCondition;
  final bool isWeatherResilient;

  const _AITripStopMarker({
    required this.number,
    required this.icon,
    this.onTap,
    this.weatherCondition,
    this.isWeatherResilient = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Haupt-Marker
            Positioned(
              left: 4,
              top: 4,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.surface, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    icon,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ),
            // Nummer-Badge (rechts oben)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: colorScheme.tertiary,
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.surface, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    '$number',
                    style: TextStyle(
                      color: colorScheme.onTertiary,
                      fontWeight: FontWeight.bold,
                      fontSize: 9,
                    ),
                  ),
                ),
              ),
            ),
            // Wetter-Badge (links unten)
            if (weatherCondition != null &&
                weatherCondition != WeatherCondition.unknown &&
                weatherCondition != WeatherCondition.mixed)
              Positioned(
                left: 0,
                bottom: 0,
                child: WeatherBadgeUnified(
                  condition: weatherCondition!,
                  isWeatherResilient: isWeatherResilient,
                  size: WeatherBadgeSize.mini,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
