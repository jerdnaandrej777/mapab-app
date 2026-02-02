import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/categories.dart';
import '../../../core/constants/trip_constants.dart';
import '../../../data/models/trip.dart';
import '../../map/providers/weather_provider.dart';
import '../../poi/providers/poi_state_provider.dart';
import '../../random_trip/providers/random_trip_provider.dart';
import '../../random_trip/widgets/day_tab_selector.dart';
import '../../ai/widgets/ai_suggestion_banner.dart';
import 'day_mini_map.dart';
import 'editable_poi_card.dart';

/// Vollbild-Overlay zum Bearbeiten von Trip-Tagen
/// Zeigt DayTabSelector, Mini-Map, POI-Liste mit Edit-Actions
class DayEditorOverlay extends ConsumerStatefulWidget {
  const DayEditorOverlay({super.key});

  @override
  ConsumerState<DayEditorOverlay> createState() => _DayEditorOverlayState();
}

class _DayEditorOverlayState extends ConsumerState<DayEditorOverlay> {
  bool _weatherBannerDismissed = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(randomTripNotifierProvider);
    final notifier = ref.read(randomTripNotifierProvider.notifier);
    final poiState = ref.watch(pOIStateNotifierProvider);
    final routeWeather = ref.watch(routeWeatherNotifierProvider);

    final trip = state.generatedTrip?.trip;

    if (trip == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Trip bearbeiten')),
        body: const Center(child: Text('Kein Trip vorhanden')),
      );
    }

    final isMultiDay = trip.actualDays > 1;
    final selectedDay = state.selectedDay;
    final stopsForDay = trip.getStopsForDay(selectedDay);
    final startLocation = state.startLocation!;

    // Route-Segment fuer den ausgewaehlten Tag
    final fullRoute = trip.route;
    List<LatLng> routeSegment = [];
    if (stopsForDay.isNotEmpty) {
      LatLng segStart;
      LatLng segEnd;
      if (selectedDay == 1) {
        segStart = fullRoute.start;
      } else {
        final prevDayStops = trip.getStopsForDay(selectedDay - 1);
        segStart = prevDayStops.isNotEmpty
            ? prevDayStops.last.location
            : stopsForDay.first.location;
      }
      if (selectedDay == trip.actualDays) {
        segEnd = fullRoute.end;
      } else {
        segEnd = stopsForDay.last.location;
      }
      routeSegment = extractRouteSegment(
        fullRoute.coordinates,
        segStart,
        segEnd,
      );
    }

    // Wetter fuer den Tag
    final dayWeather = _getDayWeather(
      selectedDay,
      trip.actualDays,
      routeWeather,
    );

    // Outdoor-POIs zaehlen
    final outdoorCount = stopsForDay.where((s) {
      final cat = s.category;
      return cat != null && !_isIndoorCategory(cat);
    }).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(isMultiDay
            ? 'Tag $selectedDay bearbeiten'
            : 'Trip bearbeiten'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Neu generieren
          IconButton(
            onPressed: state.isLoading
                ? null
                : () => notifier.regenerateTrip(),
            icon: state.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Neu generieren',
          ),
        ],
      ),
      body: Column(
        children: [
          // Tages-Tabs (nur bei Mehrtages-Trips)
          if (isMultiDay)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: const DayTabSelector(),
            ),

          // Scrollbarer Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Mini-Map
                DayMiniMap(
                  trip: trip,
                  selectedDay: selectedDay,
                  startLocation: startLocation,
                  routeSegment: routeSegment,
                ),
                const SizedBox(height: 12),

                // Statistiken
                _DayStats(
                  stopsForDay: stopsForDay,
                  selectedDay: selectedDay,
                  isMultiDay: isMultiDay,
                  trip: trip,
                ),
                const SizedBox(height: 8),

                // AI Wetter-Banner
                if (!_weatherBannerDismissed)
                  AISuggestionBanner(
                    dayWeather: dayWeather,
                    outdoorCount: outdoorCount,
                    totalCount: stopsForDay.length,
                    dayNumber: selectedDay,
                    onSuggestAlternatives: () {
                      // TODO: AI-Alternativen vorschlagen
                    },
                    onDismiss: () {
                      setState(() => _weatherBannerDismissed = true);
                    },
                  ),

                // POI-Liste
                ...stopsForDay.asMap().entries.map((entry) {
                  final stop = entry.value;
                  final poiFromState = poiState.pois
                      .where((p) => p.id == stop.poiId)
                      .firstOrNull;

                  return EditablePOICard(
                    stop: stop,
                    poiFromState: poiFromState,
                    isLoading: state.loadingPOIId == stop.poiId,
                    canDelete: state.canRemovePOI,
                    onReroll: () => notifier.rerollPOI(stop.poiId),
                    onDelete: () => notifier.removePOI(stop.poiId),
                    dayWeather: dayWeather,
                  );
                }),

                const SizedBox(height: 16),

                // Hinweis Google Maps
                if (stopsForDay.length > TripConstants.maxPoisPerDay)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber,
                            color: Colors.orange, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Max ${TripConstants.maxPoisPerDay} Stops pro Tag in Google Maps moeglich',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 80), // Platz fuer Bottom Buttons
              ],
            ),
          ),
        ],
      ),
      // Bottom Action Buttons
      bottomNavigationBar: _BottomActions(
        trip: trip,
        selectedDay: selectedDay,
        startLocation: startLocation,
        startAddress: state.startAddress ?? '',
        isCompleted: state.isDayCompleted(selectedDay),
      ),
    );
  }

  WeatherCondition _getDayWeather(
    int selectedDay,
    int totalDays,
    RouteWeatherState routeWeather,
  ) {
    if (routeWeather.weatherPoints.isEmpty) return WeatherCondition.unknown;

    // Position des Tages auf der Route (0.0 - 1.0)
    final dayPosition = totalDays > 1
        ? (selectedDay - 1) / (totalDays - 1)
        : 0.5;

    // Naechsten WeatherPoint finden
    WeatherCondition closest = routeWeather.overallCondition;
    double minDist = double.infinity;
    for (final wp in routeWeather.weatherPoints) {
      final dist = (wp.routePosition - dayPosition).abs();
      if (dist < minDist) {
        minDist = dist;
        closest = wp.weather.condition;
      }
    }
    return closest;
  }

  bool _isIndoorCategory(POICategory category) {
    const indoorCategories = {
      POICategory.museum,
      POICategory.church,
      POICategory.restaurant,
      POICategory.hotel,
    };
    return indoorCategories.contains(category);
  }
}

class _DayStats extends StatelessWidget {
  final List<TripStop> stopsForDay;
  final int selectedDay;
  final bool isMultiDay;
  final Trip trip;

  const _DayStats({
    required this.stopsForDay,
    required this.selectedDay,
    required this.isMultiDay,
    required this.trip,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final stopCount = stopsForDay.length;
    final isOverLimit = stopCount > TripConstants.maxPoisPerDay;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isOverLimit
            ? Colors.orange.withOpacity(0.1)
            : colorScheme.primaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatChip(
            icon: Icons.place,
            value: '$stopCount',
            label: 'Stops',
            isWarning: isOverLimit,
          ),
          _StatChip(
            icon: Icons.straighten,
            value: '~${trip.getDistanceForDay(selectedDay).toStringAsFixed(0)} km',
            label: 'Distanz',
          ),
          if (isMultiDay)
            _StatChip(
              icon: Icons.calendar_today,
              value: '$selectedDay/${trip.actualDays}',
              label: 'Tag',
            ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final bool isWarning;

  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isWarning
        ? Colors.orange.shade700
        : colorScheme.onPrimaryContainer;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}

class _BottomActions extends ConsumerWidget {
  final Trip trip;
  final int selectedDay;
  final LatLng startLocation;
  final String startAddress;
  final bool isCompleted;

  const _BottomActions({
    required this.trip,
    required this.selectedDay,
    required this.startLocation,
    required this.startAddress,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              // Google Maps Export
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _openDayInGoogleMaps(context, ref),
                  icon: Icon(
                    isCompleted ? Icons.check_circle : Icons.navigation,
                    size: 20,
                  ),
                  label: Text(
                    isCompleted
                        ? 'Tag $selectedDay erneut oeffnen'
                        : 'Tag $selectedDay in Google Maps',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: isCompleted
                        ? Colors.green
                        : colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openDayInGoogleMaps(
      BuildContext context, WidgetRef ref) async {
    final stopsForDay = trip.getStopsForDay(selectedDay);
    if (stopsForDay.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Keine Stops fuer Tag $selectedDay')),
      );
      return;
    }

    // Start bestimmen
    LatLng origin;
    if (selectedDay == 1) {
      origin = startLocation;
    } else {
      final prevDayStops = trip.getStopsForDay(selectedDay - 1);
      origin = prevDayStops.isNotEmpty
          ? prevDayStops.last.location
          : startLocation;
    }

    // Ziel bestimmen
    LatLng destination;
    if (selectedDay == trip.actualDays) {
      destination = startLocation;
    } else {
      final nextDayStops = trip.getStopsForDay(selectedDay + 1);
      destination = nextDayStops.isNotEmpty
          ? nextDayStops.first.location
          : startLocation;
    }

    // Waypoints
    final waypoints = stopsForDay
        .take(TripConstants.maxPoisPerDay)
        .map((s) =>
            '${s.location.latitude.toStringAsFixed(6)},${s.location.longitude.toStringAsFixed(6)}')
        .join('|');

    final originStr =
        '${origin.latitude.toStringAsFixed(6)},${origin.longitude.toStringAsFixed(6)}';
    final destinationStr =
        '${destination.latitude.toStringAsFixed(6)},${destination.longitude.toStringAsFixed(6)}';

    final url = 'https://www.google.com/maps/dir/?api=1'
        '&origin=$originStr'
        '&destination=$destinationStr'
        '&waypoints=$waypoints'
        '&travelmode=driving';

    try {
      await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );

      ref.read(randomTripNotifierProvider.notifier).completeDay(selectedDay);

      // Prüfen ob alle Tage abgeschlossen
      final updatedState = ref.read(randomTripNotifierProvider);
      if (updatedState.completedDays.length >= trip.actualDays) {
        if (context.mounted) {
          _showTripCompletedDialog(context);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google Maps konnte nicht geoeffnet werden'),
          ),
        );
      }
    }
  }

  Future<void> _showTripCompletedDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Trip abgeschlossen!'),
        content: const Text(
          'Alle Tage wurden erfolgreich in Google Maps exportiert. '
          'Gute Reise!',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // DayEditor schliessen
            },
            child: const Text('Fertig'),
          ),
        ],
      ),
    );
  }
}
