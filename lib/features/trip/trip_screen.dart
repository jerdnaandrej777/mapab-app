import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../../core/algorithms/route_optimizer.dart';
import '../../core/constants/categories.dart';
import '../../core/l10n/l10n.dart';
import '../../core/utils/url_utils.dart';
import '../../core/constants/trip_constants.dart';
import '../../data/models/trip.dart';
import '../../data/providers/favorites_provider.dart';
import '../map/providers/map_controller_provider.dart';
import '../map/providers/route_planner_provider.dart';
import '../map/providers/weather_provider.dart';
import '../poi/providers/poi_state_provider.dart';
import '../random_trip/providers/random_trip_provider.dart';
import '../random_trip/providers/random_trip_state.dart';
import '../random_trip/widgets/generation_progress_indicator.dart';
import '../random_trip/widgets/trip_preview_card.dart';
import '../random_trip/widgets/hotel_suggestion_card.dart';
import 'providers/elevation_provider.dart';
import 'providers/trip_state_provider.dart';
import 'widgets/corridor_browser_sheet.dart';
import 'widgets/elevation_chart.dart';
import 'widgets/trip_statistics_card.dart';
import 'widgets/trip_stop_tile.dart';
import 'widgets/trip_summary.dart';
import '../social/widgets/publish_trip_sheet.dart';

/// Trip-Planungs-Screen - zeigt nur berechnete Routen an
class TripScreen extends ConsumerStatefulWidget {
  const TripScreen({super.key});

  @override
  ConsumerState<TripScreen> createState() => _TripScreenState();
}

class _TripScreenState extends ConsumerState<TripScreen> {
  bool _elevationExpanded = false;

  @override
  Widget build(BuildContext context) {
    final tripState = ref.watch(tripStateProvider);
    final randomTripState = ref.watch(randomTripNotifierProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Prüfen ob Route vorhanden (von normaler Planung oder AI Trip)
    final hasRoute =
        tripState.hasRoute || randomTripState.step == RandomTripStep.preview;
    final isGenerating = randomTripState.step == RandomTripStep.generating;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        title: Text(_getTitle(context, tripState, randomTripState)),
        actions: [
          // Speichern-Button (normale Route oder AI Trip) - dominant
          if (tripState.hasRoute ||
              randomTripState.step == RandomTripStep.preview ||
              randomTripState.step == RandomTripStep.confirmed)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: FilledButton.tonalIcon(
                onPressed: () {
                  if (randomTripState.step == RandomTripStep.preview ||
                      randomTripState.step == RandomTripStep.confirmed) {
                    _saveAITrip(context, ref, randomTripState);
                  } else {
                    _saveRoute(context, ref, tripState);
                  }
                },
                icon: const Icon(Icons.bookmark_add, size: 18),
                label: Text(context.l10n.save),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          if (hasRoute || tripState.hasStops)
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showMoreOptions(context, ref),
            ),
        ],
      ),
      body: isGenerating
          ? _buildGeneratingView(context, colorScheme)
          : hasRoute || tripState.hasStops
              ? _buildTripContent(
                  context, ref, tripState, randomTripState, theme, colorScheme)
              : _buildConfigView(context, ref, theme, colorScheme),
    );
  }

  String _getTitle(BuildContext context, TripStateData tripState,
      RandomTripState randomTripState) {
    if (randomTripState.step == RandomTripStep.generating) {
      return context.l10n.tripInfoGenerating;
    }
    if (randomTripState.step == RandomTripStep.preview) {
      return randomTripState.mode == RandomTripMode.daytrip
          ? context.l10n.tripInfoAiDayTrip
          : context.l10n.tripInfoAiEuroTrip;
    }
    if (tripState.hasRoute || tripState.hasStops) {
      return context.l10n.tripYourRoute;
    }
    return context.l10n.tripRoutePlanning;
  }

  /// Ansicht wenn keine Route vorhanden
  Widget _buildConfigView(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.route,
              size: 80,
              color: colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.tripNoRoute,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.tripTapMap,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.map),
              label: Text(context.l10n.tripToMap),
            ),
          ],
        ),
      ),
    );
  }

  /// Generierungs-Ansicht (Loading)
  Widget _buildGeneratingView(BuildContext context, ColorScheme colorScheme) =>
      const GenerationProgressIndicator();

  Future<void> _saveRoute(
      BuildContext context, WidgetRef ref, TripStateData tripState) async {
    final route = tripState.route;
    if (route == null) return;

    // Dialog für Trip-Namen
    final nameController = TextEditingController(
      text: '${route.startAddress} → ${route.endAddress}',
    );

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.tripSaveRoute),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: context.l10n.tripRouteName,
            hintText: context.l10n.tripExampleDayTrip,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, nameController.text),
            child: Text(context.l10n.save),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return;

    // Trip erstellen
    final trip = Trip(
      id: const Uuid().v4(),
      name: result,
      type: TripType.daytrip,
      route: route,
      stops: tripState.stops.map((poi) => TripStop.fromPOI(poi)).toList(),
      createdAt: DateTime.now(),
    );

    // In Favoriten speichern
    await ref.read(favoritesNotifierProvider.notifier).saveRoute(trip);
  }

  /// Speichert einen AI Trip in die Favoriten
  Future<void> _saveAITrip(BuildContext context, WidgetRef ref,
      RandomTripState randomTripState) async {
    final generatedTrip = randomTripState.generatedTrip;
    if (generatedTrip == null) return;

    final trip = generatedTrip.trip;
    final route = trip.route;

    // Dialog für Trip-Namen
    final nameController = TextEditingController(
      text: '${route.startAddress} → ${route.endAddress}',
    );

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.tripSaveRoute),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: context.l10n.tripRouteName,
            hintText: randomTripState.mode == RandomTripMode.daytrip
                ? context.l10n.tripExampleAiDayTrip
                : context.l10n.tripExampleAiEuroTrip,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, nameController.text),
            child: Text(context.l10n.save),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return;

    // Trip mit korrektem Typ erstellen
    final savedTrip = Trip(
      id: const Uuid().v4(),
      name: result,
      type: randomTripState.mode == RandomTripMode.daytrip
          ? TripType.daytrip
          : TripType.eurotrip,
      route: route,
      stops: trip.stops,
      days: trip.actualDays,
      createdAt: DateTime.now(),
    );

    // In Favoriten speichern
    await ref.read(favoritesNotifierProvider.notifier).saveRoute(savedTrip);
  }

  /// Veröffentlicht einen Trip in der öffentlichen Galerie
  Future<void> _publishTrip(BuildContext context, Trip trip) async {
    final published = await PublishTripSheet.show(context, trip);
    if (!mounted || !published) {
      return;
    }

    ScaffoldMessenger.of(this.context).showSnackBar(
      SnackBar(
        content: Text(this.context.l10n.publishSuccess),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Öffnet einen bestimmten Tag in Google Maps (für Mehrtages-Trips)
  Future<void> _openDayInGoogleMaps(
    BuildContext context,
    Trip trip,
    int dayNumber,
    String startAddress,
  ) async {
    final stopsForDay = trip.getStopsForDay(dayNumber);
    if (stopsForDay.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.tripNoStopsForDay(dayNumber))),
      );
      return;
    }

    final origin = trip.getDayStartLocation(dayNumber);
    final originName = trip.getDayStartLabel(
      dayNumber,
      defaultStartAddress: startAddress,
    );
    final destination = trip.getDayEndLocation(dayNumber);
    final destinationName = trip.getDayEndLabel(
      dayNumber,
      defaultStartAddress: startAddress,
    );

    // Waypoints: Alle Stops des Tages (max 9)
    final waypointsList = stopsForDay
        .take(TripConstants.maxPoisPerDay)
        .map((s) => s.location)
        .toList();
    if (waypointsList.isNotEmpty) {
      final lastWaypoint = waypointsList.last;
      final sameAsDestination =
          (lastWaypoint.latitude - destination.latitude).abs() < 0.00001 &&
              (lastWaypoint.longitude - destination.longitude).abs() < 0.00001;
      if (sameAsDestination) {
        waypointsList.removeLast();
      }
    }
    final waypoints = waypointsList
        .map((p) =>
            '${p.latitude.toStringAsFixed(6)},${p.longitude.toStringAsFixed(6)}')
        .join('|');

    final originStr =
        '${origin.latitude.toStringAsFixed(6)},${origin.longitude.toStringAsFixed(6)}';
    final destinationStr =
        '${destination.latitude.toStringAsFixed(6)},${destination.longitude.toStringAsFixed(6)}';

    final url = 'https://www.google.com/maps/dir/?api=1'
        '&origin=$originStr'
        '&destination=$destinationStr'
        '${waypoints.isNotEmpty ? '&waypoints=$waypoints' : ''}'
        '&travelmode=driving';

    debugPrint('[GoogleMaps] Tag $dayNumber: $originName -> $destinationName');
    debugPrint('[GoogleMaps] Opening URL: $url');

    try {
      await launchUrlSafe(Uri.parse(url));

      // Tag als abgeschlossen markieren
      ref.read(randomTripNotifierProvider.notifier).completeDay(dayNumber);

      // Prüfen ob alle Tage abgeschlossen sind
      final updatedState = ref.read(randomTripNotifierProvider);
      if (updatedState.completedDays.length >= trip.actualDays) {
        // Alle Tage exportiert
        if (context.mounted) {
          _showTripCompletedDialog(context, trip);
        }
      }
      // Kein Snackbar - DayTabSelector zeigt Häkchen für abgeschlossene Tage
    } catch (e) {
      debugPrint('[GoogleMaps] Error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.tripGoogleMapsError),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Zeigt Dialog wenn alle Tage eines mehrtägigen Trips exportiert wurden
  Future<void> _showTripCompletedDialog(BuildContext context, Trip trip) async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.tripCompleted),
        content: Text(
          context.l10n.tripAllDaysExported(trip.actualDays),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'keep'),
            child: Text(context.l10n.tripKeep),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'save'),
            child: Text(context.l10n.tripSaveToFavorites),
          ),
        ],
      ),
    );

    if (result == 'save' && context.mounted) {
      // Trip in Favoriten speichern und State aufräumen
      final randomTripState = ref.read(randomTripNotifierProvider);
      await _saveAITrip(context, ref, randomTripState);
      ref.read(randomTripNotifierProvider.notifier).reset();
      if (context.mounted) context.go('/');
    }
  }

  /// Teilt die Route über WhatsApp, Email, etc.
  Future<void> _shareRoute(
      BuildContext context, TripStateData tripState) async {
    final route = tripState.route;
    if (route == null) return;

    // Google Maps Link generieren
    final origin =
        '${route.start.latitude.toStringAsFixed(6)},${route.start.longitude.toStringAsFixed(6)}';
    final destination =
        '${route.end.latitude.toStringAsFixed(6)},${route.end.longitude.toStringAsFixed(6)}';
    var mapsUrl = 'https://www.google.com/maps/dir/?api=1'
        '&origin=$origin'
        '&destination=$destination'
        '&travelmode=driving';

    if (tripState.stops.isNotEmpty) {
      final waypoints = tripState.stops
          .take(10)
          .map((poi) =>
              '${poi.latitude.toStringAsFixed(6)},${poi.longitude.toStringAsFixed(6)}')
          .join('|');
      mapsUrl += '&waypoints=$waypoints';
    }

    debugPrint('[GoogleMaps] Share URL: $mapsUrl');

    // Share-Text erstellen
    final stopNames = tripState.stops.map((s) => '• ${s.name}').join('\n');
    final shareText = '''
🗺️ Meine Route mit MapAB

📍 Start: ${route.startAddress}
🏁 Ziel: ${route.endAddress}
📏 Distanz: ${tripState.totalDistance.toStringAsFixed(1)} km
⏱️ Dauer: ${tripState.totalDuration} Min

${tripState.stops.isNotEmpty ? '📌 Stops:\n$stopNames\n' : ''}
🔗 In Google Maps öffnen:
$mapsUrl
''';

    try {
      await Share.share(shareText, subject: context.l10n.tripMyRoute);
    } catch (e) {
      debugPrint('[Share] Error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.tripShareError),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Widget _buildTripContent(
    BuildContext context,
    WidgetRef ref,
    TripStateData tripState,
    RandomTripState randomTripState,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    // Wenn AI Trip im Preview-Modus
    if (randomTripState.step == RandomTripStep.preview) {
      return _buildAITripPreview(context, ref, randomTripState, colorScheme);
    }

    final route = tripState.route;
    final stops = tripState.stops;

    // Hoehenprofil laden wenn Route vorhanden
    if (route != null && route.coordinates.length >= 2) {
      // Async laden ohne build zu blockieren (Provider cached intern)
      Future.microtask(() {
        ref
            .read(elevationNotifierProvider.notifier)
            .loadElevation(route.coordinates);
      });
    }

    // Hoehenprofil-State
    final elevationState = ref.watch(elevationNotifierProvider);

    // Wetter fuer Stop-Badges (nur benoetigte Properties selektieren)
    final routeOverallCondition = ref.watch(
      routeWeatherNotifierProvider.select((w) => w.overallCondition),
    );
    final locationCondition = ref.watch(
      locationWeatherNotifierProvider.select((w) => w.condition),
    );
    final tripWeatherCondition =
        routeOverallCondition != WeatherCondition.unknown
            ? routeOverallCondition
            : locationCondition;

    return Column(
      children: [
        // Trip-Zusammenfassung
        TripSummary(
          totalDistance: tripState.totalDistance,
          totalDuration: tripState.totalDuration,
          stopCount: stops.length,
          isRecalculating: tripState.isRecalculating,
        ),

        // Wetter-Hinweis (dezent unter Summary)
        if (tripWeatherCondition == WeatherCondition.bad ||
            tripWeatherCondition == WeatherCondition.danger)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  tripWeatherCondition == WeatherCondition.danger
                      ? Icons.warning_amber_rounded
                      : Icons.water_drop_rounded,
                  size: 14,
                  color: tripWeatherCondition == WeatherCondition.danger
                      ? colorScheme.error
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  tripWeatherCondition == WeatherCondition.danger
                      ? context.l10n.tripWeatherDangerHint
                      : context.l10n.tripWeatherBadHint,
                  style: TextStyle(
                    fontSize: 11,
                    color: tripWeatherCondition == WeatherCondition.danger
                        ? colorScheme.error
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 8),

        // Hoehenprofil (aufklappbar)
        if (elevationState.hasProfile) ...[
          InkWell(
            onTap: () =>
                setState(() => _elevationExpanded = !_elevationExpanded),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.terrain, size: 18, color: colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Höhenprofil',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_upward,
                      size: 12, color: colorScheme.tertiary),
                  const SizedBox(width: 2),
                  Text(
                    elevationState.profile!.formattedAscent,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.tertiary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_downward,
                      size: 12, color: colorScheme.error),
                  const SizedBox(width: 2),
                  Text(
                    elevationState.profile!.formattedDescent,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.error,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _elevationExpanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _elevationExpanded
                ? Column(
                    children: [
                      ElevationChart(
                        profile: elevationState.profile!,
                        showHeader: false,
                      ),
                      const SizedBox(height: 8),
                      TripStatisticsCard(
                          profile: elevationState.profile!),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 8),
        ] else if (elevationState.isLoading) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  context.l10n.tripElevationLoading,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],

        // Stops-Liste
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: stops.length + 2, // +2 für Start & Ziel
            onReorder: (oldIndex, newIndex) {
              // Start und Ziel nicht verschieben
              if (oldIndex == 0 || oldIndex == stops.length + 1) return;
              if (newIndex == 0 || newIndex > stops.length) return;

              final adjustedOld = oldIndex - 1;
              var adjustedNew = newIndex - 1;
              if (newIndex > oldIndex) adjustedNew--;

              ref
                  .read(tripStateProvider.notifier)
                  .reorderStops(adjustedOld, adjustedNew);
            },
            itemBuilder: (context, index) {
              // Start
              if (index == 0) {
                return _buildLocationTile(
                  context: context,
                  key: const ValueKey('start'),
                  icon: Icons.trip_origin,
                  iconColor: Colors.green,
                  title: route?.startAddress ?? context.l10n.tripNoRoute,
                  subtitle: context.l10n.tripStart,
                  isFirst: true,
                );
              }

              // Ziel
              if (index == stops.length + 1) {
                return _buildLocationTile(
                  context: context,
                  key: const ValueKey('end'),
                  icon: Icons.place,
                  iconColor: Colors.red,
                  title: route?.endAddress ?? context.l10n.tripNoRoute,
                  subtitle: context.l10n.tripDestination,
                  isLast: true,
                );
              }

              // Stops
              final stop = stops[index - 1];
              return TripStopTile(
                key: ValueKey('stop-${stop.id}'),
                name: stop.name,
                icon: stop.category?.icon ?? '📍',
                detourKm: (stop.detourKm ?? 0).toInt(),
                durationMinutes: (stop.detourMinutes ?? 0).toInt(),
                index: index,
                weatherCondition: tripWeatherCondition,
                isWeatherResilient: stop.category?.isWeatherResilient ?? false,
                onTap: () {
                  // v1.6.8: POI zum State hinzufügen bevor Navigation
                  // Ermöglicht POI-Details mit Foto für Trip-Stops
                  final poiNotifier =
                      ref.read(pOIStateNotifierProvider.notifier);
                  poiNotifier.addPOI(stop);
                  // Enrichment triggern für Foto-Laden
                  if (stop.imageUrl == null) {
                    poiNotifier.enrichPOI(stop.id);
                  }
                  context.push('/poi/${stop.id}');
                },
                onRemove: () {
                  ref.read(tripStateProvider.notifier).removeStop(stop.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.l10n.tripStopRemoved)),
                  );
                },
                onEdit: () {
                  // v1.6.8: POI zum State hinzufügen bevor Navigation
                  ref.read(pOIStateNotifierProvider.notifier).addPOI(stop);
                  context.push('/poi/${stop.id}');
                },
              );
            },
          ),
        ),

        // Export-Buttons
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Auf Karte anzeigen Button (v1.7.0)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: route != null
                        ? () {
                            // Flag setzen für Auto-Zoom beim Tab-Wechsel
                            ref.read(shouldFitToRouteProvider.notifier).state =
                                true;
                            ref.read(mapRouteFocusModeProvider.notifier).state =
                                true;
                            context.go('/');
                          }
                        : null,
                    icon: const Icon(Icons.map_outlined),
                    label: Text(context.l10n.showOnMap),
                  ),
                ),
                const SizedBox(height: 8),
                // POIs entdecken Button
                if (route != null && route.coordinates.isNotEmpty) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => CorridorBrowserSheet.show(
                        context: context,
                        route: route,
                        existingStopIds:
                            tripState.stops.map((s) => s.id).toSet(),
                      ),
                      icon: const Icon(Icons.add_location_alt_rounded),
                      label: Text(context.l10n.tripConfigPoisAlongRoute),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                // In-App Navigation starten
                if (route != null)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => context.push(
                        '/navigation',
                        extra: {
                          'route': route,
                          'stops': tripState.stops
                              .asMap()
                              .entries
                              .map((e) =>
                                  TripStop.fromPOI(e.value, order: e.key))
                              .toList(),
                        },
                      ),
                      icon: const Icon(Icons.navigation),
                      label: Text(context.l10n.tripInfoStartNavigation),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// AI Trip Preview-Ansicht
  Widget _buildAITripPreview(
    BuildContext context,
    WidgetRef ref,
    RandomTripState state,
    ColorScheme colorScheme,
  ) {
    final notifier = ref.read(randomTripNotifierProvider.notifier);
    final trip = state.generatedTrip?.trip;
    final isMultiDay = trip != null && trip.actualDays > 1;

    // Hoehenprofil fuer AI Trip laden
    if (trip != null && trip.route.coordinates.length >= 2) {
      Future.microtask(() {
        ref
            .read(elevationNotifierProvider.notifier)
            .loadElevation(trip.route.coordinates);
      });
    }
    final elevationState = ref.watch(elevationNotifierProvider);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TripPreviewCard(),
                const SizedBox(height: 16),

                // Hoehenprofil (wenn geladen)
                if (elevationState.hasProfile) ...[
                  ElevationChart(profile: elevationState.profile!),
                  const SizedBox(height: 8),
                  TripStatisticsCard(profile: elevationState.profile!),
                  const SizedBox(height: 16),
                ] else if (elevationState.isLoading)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation(colorScheme.primary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          context.l10n.tripElevationLoading,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Hotel-Vorschläge (für Mehrtages-Trips)
                if (state.isMultiDay && state.hotelSuggestions.isNotEmpty) ...[
                  HotelSuggestionsSection(
                    suggestionsByDay: state.hotelSuggestions,
                    selectedHotels: state.selectedHotels,
                    onSelect: notifier.selectHotel,
                    tripStartDate: state.tripStartDate ??
                        state.generatedTrip?.trip.startDate,
                    radiusKm: 20,
                  ),
                ],
              ],
            ),
          ),
        ),

        // Action Buttons
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Auf Karte anzeigen Button (v1.7.0)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      // Flag setzen für Auto-Zoom beim Tab-Wechsel
                      ref.read(shouldFitToRouteProvider.notifier).state = true;
                      ref.read(mapRouteFocusModeProvider.notifier).state = true;
                      context.go('/');
                    },
                    icon: const Icon(Icons.map_outlined),
                    label: Text(context.l10n.showOnMap),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // POIs entdecken Button
                if (trip != null && trip.route.coordinates.isNotEmpty)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => CorridorBrowserSheet.show(
                        context: context,
                        route: trip.route,
                        existingStopIds: trip.stops.map((s) => s.poiId).toSet(),
                      ),
                      icon: const Icon(Icons.add_location_alt_rounded),
                      label: Text(context.l10n.tripConfigPoisAlongRoute),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                // In-App Navigation starten (v1.9.0)
                if (trip != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => context.push(
                          '/navigation',
                          extra: {
                            'route': trip.route,
                            'stops': trip.stops,
                          },
                        ),
                        icon: const Icon(Icons.navigation),
                        label: Text(context.l10n.tripInfoStartNavigation),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                // Tagesweiser Export (nur bei Mehrtages-Trips)
                if (isMultiDay) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: state.startLocation != null
                          ? () => _openDayInGoogleMaps(
                                context,
                                trip,
                                state.selectedDay,
                                state.startAddress!,
                              )
                          : null,
                      icon: const Icon(Icons.map),
                      label: Text(
                        state.isDayCompleted(state.selectedDay)
                            ? context.l10n.tripReExportDay(state.selectedDay)
                            : context.l10n.tripExportDay(state.selectedDay),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: state.isDayCompleted(state.selectedDay)
                            ? colorScheme.surfaceContainerHighest
                            : colorScheme.primary,
                        foregroundColor: state.isDayCompleted(state.selectedDay)
                            ? colorScheme.onSurface
                            : colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.tripGoogleMapsHint,
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                ],

                // Standard-Buttons
                Row(
                  children: [
                    // Bearbeiten Button
                    OutlinedButton.icon(
                      onPressed: () => notifier.backToConfig(),
                      icon: const Icon(Icons.edit),
                      label: Text(context.l10n.edit),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Neu generieren Button
                    OutlinedButton.icon(
                      onPressed: () => notifier.regenerateTrip(),
                      icon: const Icon(Icons.refresh),
                      label: Text(context.l10n.tripNew),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Trip speichern Button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          notifier.confirmTrip();
                          await _saveAITrip(context, ref, state);
                        },
                        icon: const Icon(Icons.check),
                        label: Text(context.l10n.save),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationTile({
    required BuildContext context,
    required Key key,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      key: key,
      margin: EdgeInsets.only(
        bottom: isLast ? 0 : 8,
        top: isFirst ? 0 : 8,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
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

  void _showMoreOptions(BuildContext context, WidgetRef ref) {
    final randomTripState = ref.read(randomTripNotifierProvider);

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.auto_fix_high),
              title: Text(context.l10n.tripOptimizeRoute),
              subtitle: Text(context.l10n.tripOptimizeBestOrder),
              onTap: () {
                Navigator.pop(ctx);
                final tripState = ref.read(tripStateProvider);
                if (tripState.route == null || tripState.stops.length < 3) {
                  return;
                }
                final optimizer = RouteOptimizer();
                final optimized = optimizer.optimizeRoute(
                  pois: tripState.stops,
                  startLocation: tripState.route!.start,
                  returnToStart: false,
                );
                final tripNotifier = ref.read(tripStateProvider.notifier);
                tripNotifier.setStops(optimized);
              },
            ),
            ListTile(
              leading: const Icon(Icons.save),
              title: Text(context.l10n.tripSaveRoute),
              onTap: () {
                Navigator.pop(ctx);
                final tripState = ref.read(tripStateProvider);
                final rtState = ref.read(randomTripNotifierProvider);
                if (rtState.step == RandomTripStep.preview ||
                    rtState.step == RandomTripStep.confirmed) {
                  _saveAITrip(context, ref, rtState);
                } else if (tripState.hasRoute) {
                  _saveRoute(context, ref, tripState);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: Text(context.l10n.tripShareRoute),
              onTap: () {
                Navigator.pop(ctx);
                final tripState = ref.read(tripStateProvider);
                if (tripState.hasRoute) {
                  _shareRoute(context, tripState);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.public),
              title: Text(context.l10n.tripPublish),
              subtitle: Text(context.l10n.tripPublishDescription),
              onTap: () async {
                Navigator.pop(ctx);
                final tripState = ref.read(tripStateProvider);
                final rtState = ref.read(randomTripNotifierProvider);

                // Trip-Objekt erstellen
                Trip trip;
                if (rtState.step == RandomTripStep.preview ||
                    rtState.step == RandomTripStep.confirmed) {
                  // AI Trip
                  trip = rtState.generatedTrip!.trip;
                } else if (tripState.hasRoute) {
                  // Normale Route
                  trip = Trip(
                    id: const Uuid().v4(),
                    name:
                        '${tripState.route!.startAddress} → ${tripState.route!.endAddress}',
                    type: TripType.daytrip,
                    route: tripState.route!,
                    stops: tripState.stops
                        .map((poi) => TripStop.fromPOI(poi))
                        .toList(),
                    createdAt: DateTime.now(),
                  );
                } else {
                  return;
                }

                await _publishTrip(context, trip);
              },
            ),
            ListTile(
              leading: const Icon(Icons.auto_stories),
              title: Text(context.l10n.journalOpenJournal),
              subtitle: Text(context.l10n.journalTitle),
              onTap: () {
                Navigator.pop(ctx);
                _openJournal(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: Text(context.l10n.tripDeleteAllStops,
                  style: const TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _clearAllStops(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: Text(context.l10n.tripDeleteEntireRoute,
                  style: const TextStyle(color: Colors.red)),
              subtitle: Text(context.l10n.tripDeleteRouteAndStops),
              onTap: () {
                Navigator.pop(ctx);
                _clearEntireRoute(context, ref);
              },
            ),
            // Wenn AI Trip aktiv: Zurück zu Konfiguration
            if (randomTripState.step == RandomTripStep.preview)
              ListTile(
                leading: const Icon(Icons.arrow_back),
                title: Text(context.l10n.tripBackToConfig),
                onTap: () {
                  Navigator.pop(ctx);
                  ref.read(randomTripNotifierProvider.notifier).backToConfig();
                },
              ),
          ],
        ),
      ),
    );
  }

  void _clearAllStops(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.tripConfirmDeleteAllStops),
        content: Text(context.l10n.actionCannotBeUndone),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(tripStateProvider.notifier).clearStops();
            },
            child: Text(context.l10n.delete,
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _clearEntireRoute(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.tripConfirmDeleteEntireRoute),
        content: Text(context.l10n.tripDeleteEntireRouteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Route im Route-Planner löschen (löscht auch Trip-State)
              ref.read(routePlannerProvider.notifier).clearRoute();
              // AI Trip State zurücksetzen
              ref.read(randomTripNotifierProvider.notifier).reset();
              // Zur Karte navigieren
              context.go('/');
            },
            child: Text(context.l10n.delete,
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _openJournal(BuildContext context, WidgetRef ref) {
    final tripState = ref.read(tripStateProvider);
    final randomTripState = ref.read(randomTripNotifierProvider);

    // Trip-ID und Name bestimmen
    String tripId;
    String tripName;

    if (randomTripState.step == RandomTripStep.preview ||
        randomTripState.step == RandomTripStep.confirmed) {
      // AI Trip aktiv
      final trip = randomTripState.generatedTrip?.trip;
      tripId = trip?.id ?? const Uuid().v4();
      tripName = trip?.name ??
          (randomTripState.mode == RandomTripMode.daytrip
              ? context.l10n.tripInfoAiDayTrip
              : context.l10n.tripInfoAiEuroTrip);
    } else if (tripState.hasRoute) {
      // Normale Route
      tripId = tripState.route?.hashCode.toString() ?? const Uuid().v4();
      tripName = context.l10n.tripYourRoute;
    } else {
      return;
    }

    context.push('/journal/$tripId?name=${Uri.encodeComponent(tripName)}');
  }
}
