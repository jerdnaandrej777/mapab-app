import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/categories.dart';
import '../../../core/constants/trip_constants.dart';
import '../../../data/models/poi.dart';
import '../../../data/models/route.dart';
import '../../../data/models/trip.dart';
import '../../../data/models/weather.dart';
import '../../map/providers/weather_provider.dart';
import '../../poi/providers/poi_state_provider.dart';
import '../../random_trip/providers/random_trip_provider.dart';
import '../../random_trip/widgets/day_tab_selector.dart';
import '../../ai/providers/ai_trip_advisor_provider.dart';
import '../../ai/widgets/ai_suggestion_banner.dart';
import 'corridor_browser_sheet.dart';
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
  bool _isCorridorBrowserActive = false;
  int _lastAutoTriggeredDay = -1;

  @override
  Widget build(BuildContext context) {
    // Auto-Close Korridor-Browser bei Tageswechsel
    ref.listen<int>(
      randomTripNotifierProvider.select((s) => s.selectedDay),
      (previous, next) {
        if (previous != next && _isCorridorBrowserActive) {
          setState(() => _isCorridorBrowserActive = false);
        }
      },
    );
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

    // Wetter fuer den Tag (nutzt echte Vorhersage wenn verfuegbar)
    final dayWeather = _getDayWeather(
      selectedDay,
      trip.actualDays,
      routeWeather,
    );

    // Tages-Vorhersage fuer Detail-Anzeige
    final dayForecast = routeWeather.getDayForecast(selectedDay, trip.actualDays);

    // Outdoor-POIs zaehlen
    final outdoorCount = stopsForDay.where((s) {
      final cat = s.category;
      return cat != null && !cat.isIndoor;
    }).length;

    // Auto-Trigger AI-Empfehlungen bei schlechtem Wetter (einmalig pro Tag)
    if ((dayWeather == WeatherCondition.bad ||
            dayWeather == WeatherCondition.danger) &&
        outdoorCount > 0 &&
        _lastAutoTriggeredDay != selectedDay) {
      _lastAutoTriggeredDay = selectedDay;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(aITripAdvisorNotifierProvider.notifier).loadSmartRecommendations(
              day: selectedDay,
              trip: trip,
              route: trip.route,
              routeWeather: routeWeather,
              existingStopIds: trip.stops.map((s) => s.poiId).toSet(),
            );
      });
    }

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

          // Fixierter Bereich: Mini-Map + Stats (scrollt NICHT)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: DayMiniMap(
              key: ValueKey('$selectedDay-${stopsForDay.length}'),
              trip: trip,
              selectedDay: selectedDay,
              startLocation: startLocation,
              routeSegment: routeSegment,
              recommendedPOIs: ref
                  .watch(aITripAdvisorNotifierProvider)
                  .getRecommendedPOIsForDay(selectedDay),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _DayStats(
              stopsForDay: stopsForDay,
              selectedDay: selectedDay,
              isMultiDay: isMultiDay,
              trip: trip,
              dayForecast: dayForecast,
              dayWeather: dayWeather,
            ),
          ),
          const SizedBox(height: 8),

          // Wechselbarer Bereich: Normal-Modus oder Korridor-Browser
          if (_isCorridorBrowserActive)
            Expanded(
              child: CorridorBrowserContent(
                route: trip.route,
                existingStopIds:
                    trip.stops.map((s) => s.poiId).toSet(),
                onAddPOI: (poi) async {
                  final success = await ref
                      .read(randomTripNotifierProvider.notifier)
                      .addPOIToDay(poi, selectedDay);
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            '"${poi.name}" zu Tag $selectedDay hinzugefuegt'),
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                  return success;
                },
                onRemovePOI: (poi) async {
                  final success = await ref
                      .read(randomTripNotifierProvider.notifier)
                      .removePOIFromDay(poi.id, selectedDay);
                  return success;
                },
                onClose: () {
                  setState(() => _isCorridorBrowserActive = false);
                },
              ),
            )
          else
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  // AI Wetter-Banner
                  if (!_weatherBannerDismissed)
                    AISuggestionBanner(
                      dayWeather: dayWeather,
                      outdoorCount: outdoorCount,
                      totalCount: stopsForDay.length,
                      dayNumber: selectedDay,
                      onSuggestAlternatives: () {
                        ref
                            .read(aITripAdvisorNotifierProvider.notifier)
                            .loadSmartRecommendations(
                              day: selectedDay,
                              trip: trip,
                              route: trip.route,
                              routeWeather: routeWeather,
                              existingStopIds:
                                  trip.stops.map((s) => s.poiId).toSet(),
                            );
                      },
                      onDismiss: () {
                        setState(() => _weatherBannerDismissed = true);
                      },
                    ),

                  // AI-Vorschlaege / Empfehlungen-Button
                  _AISuggestionsSection(
                    dayNumber: selectedDay,
                    trip: trip,
                    onLoadRecommendations: () {
                      ref
                          .read(aITripAdvisorNotifierProvider.notifier)
                          .loadSmartRecommendations(
                            day: selectedDay,
                            trip: trip,
                            route: trip.route,
                            routeWeather: routeWeather,
                            existingStopIds:
                                trip.stops.map((s) => s.poiId).toSet(),
                          );
                    },
                  ),
                  const SizedBox(height: 4),

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

                  const SizedBox(height: 160), // Platz fuer Bottom Buttons
                ],
              ),
            ),
        ],
      ),
      // Bottom Action Buttons (ausgeblendet im Korridor-Browser-Modus)
      bottomNavigationBar: _isCorridorBrowserActive
          ? null
          : _BottomActions(
              trip: trip,
              selectedDay: selectedDay,
              startLocation: startLocation,
              startAddress: state.startAddress ?? '',
              isCompleted: state.isDayCompleted(selectedDay),
              onOpenCorridorBrowser: () {
                setState(() => _isCorridorBrowserActive = true);
              },
            ),
    );
  }

  WeatherCondition _getDayWeather(
    int selectedDay,
    int totalDays,
    RouteWeatherState routeWeather,
  ) {
    if (routeWeather.weatherPoints.isEmpty) return WeatherCondition.unknown;

    // Nutze echte Tages-Vorhersage wenn verfuegbar (Multi-Day Trips)
    if (routeWeather.hasForecast && totalDays > 1) {
      final forecastPerDay = routeWeather.getForecastPerDay(totalDays);
      return forecastPerDay[selectedDay] ?? routeWeather.overallCondition;
    }

    // Fallback: Position-basiertes Mapping (Tagesausflug)
    final dayPosition = totalDays > 1
        ? (selectedDay - 1) / (totalDays - 1)
        : 0.5;

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

}

class _DayStats extends StatelessWidget {
  final List<TripStop> stopsForDay;
  final int selectedDay;
  final bool isMultiDay;
  final Trip trip;
  final DailyForecast? dayForecast;
  final WeatherCondition dayWeather;

  const _DayStats({
    required this.stopsForDay,
    required this.selectedDay,
    required this.isMultiDay,
    required this.trip,
    this.dayForecast,
    this.dayWeather = WeatherCondition.unknown,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final stopCount = stopsForDay.length;
    final isStopOverLimit = stopCount > TripConstants.maxPoisPerDay;
    final dayDistance = trip.getDistanceForDay(selectedDay);
    final isDistanceOverLimit = dayDistance > TripConstants.maxDisplayKmPerDay;
    final hasAnyWarning = isStopOverLimit || isDistanceOverLimit;

    // Geschaetzte Fahrzeit (~80 km/h Durchschnitt)
    final estimatedMinutes = (dayDistance / 80 * 60).round();
    String formattedTime;
    if (estimatedMinutes < 60) {
      formattedTime = '~$estimatedMinutes Min.';
    } else {
      final hours = estimatedMinutes ~/ 60;
      final mins = estimatedMinutes % 60;
      formattedTime = mins == 0 ? '~${hours}h' : '~${hours}h ${mins}m';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: hasAnyWarning
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
            isWarning: isStopOverLimit,
          ),
          _StatChip(
            icon: Icons.straighten,
            value: '~${dayDistance.toStringAsFixed(0)} km',
            label: 'Distanz',
            isWarning: isDistanceOverLimit,
          ),
          _StatChip(
            icon: Icons.access_time,
            value: formattedTime,
            label: 'Fahrzeit',
          ),
          // Wetter fuer den Tag (Vorhersage oder aktuell)
          if (dayForecast != null)
            _StatChip(
              icon: null,
              emojiIcon: dayForecast!.icon,
              value: dayForecast!.temperatureRange,
              label: dayForecast!.weekday,
            )
          else if (dayWeather != WeatherCondition.unknown)
            _StatChip(
              icon: null,
              emojiIcon: dayWeather.icon,
              value: dayWeather.label,
              label: 'Wetter',
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
  final IconData? icon;
  final String? emojiIcon;
  final String value;
  final String label;
  final bool isWarning;

  const _StatChip({
    this.icon,
    this.emojiIcon,
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
        if (emojiIcon != null)
          Text(emojiIcon!, style: const TextStyle(fontSize: 18))
        else if (icon != null)
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

/// Zeigt AI-generierte Vorschlaege fuer den ausgewaehlten Tag
/// Bei keinen Suggestions: "Empfehlungen laden" Button (wetterunabhaengig)
class _AISuggestionsSection extends ConsumerWidget {
  final int dayNumber;
  final Trip trip;
  final VoidCallback onLoadRecommendations;

  const _AISuggestionsSection({
    required this.dayNumber,
    required this.trip,
    required this.onLoadRecommendations,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final advisorState = ref.watch(aITripAdvisorNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // Loading-Zustand
    if (advisorState.isLoading) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Suche POI-Empfehlungen...',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    final suggestions = advisorState.getSuggestionsForDay(dayNumber);
    if (suggestions.isEmpty) {
      // "Empfehlungen laden" Button (wetterunabhaengig)
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: OutlinedButton.icon(
          onPressed: onLoadRecommendations,
          icon: Icon(Icons.auto_awesome, size: 18, color: colorScheme.primary),
          label: const Text('POI-Empfehlungen laden'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 40),
            side: BorderSide(color: colorScheme.primary.withOpacity(0.3)),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(Icons.auto_awesome, size: 16, color: colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                'AI-Empfehlungen',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),

        // Fehler-Hinweis wenn AI nicht erreichbar
        if (advisorState.error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              advisorState.error!,
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
        ...suggestions.map((suggestion) {
          // Actionable POI-Karte wenn alternativePOI vorhanden
          if (suggestion.alternativePOI != null) {
            return _AIRecommendedPOICard(
              poi: suggestion.alternativePOI!,
              reasoning: suggestion.aiReasoning ?? suggestion.message,
              actionType: suggestion.actionType ?? 'add',
              targetPOIId: suggestion.targetPOIId,
              dayNumber: dayNumber,
            );
          }

          // Text-Vorschlag (bestehend)
          final isWeather = suggestion.type == SuggestionType.weather;
          final isAlternative =
              suggestion.type == SuggestionType.alternative;

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 3),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isWeather
                  ? colorScheme.tertiaryContainer.withOpacity(0.3)
                  : isAlternative
                      ? colorScheme.primaryContainer.withOpacity(0.3)
                      : colorScheme.surfaceContainerHighest
                          .withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: colorScheme.outline.withOpacity(0.1),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isWeather
                      ? Icons.cloud
                      : isAlternative
                          ? Icons.swap_horiz_rounded
                          : Icons.lightbulb_outline,
                  size: 16,
                  color: isWeather
                      ? colorScheme.tertiary
                      : colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    suggestion.message,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

/// Actionable POI-Karte fuer AI-Empfehlungen
class _AIRecommendedPOICard extends ConsumerWidget {
  final POI poi;
  final String reasoning;
  final String actionType;
  final String? targetPOIId;
  final int dayNumber;

  const _AIRecommendedPOICard({
    required this.poi,
    required this.reasoning,
    required this.actionType,
    this.targetPOIId,
    required this.dayNumber,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // POI-Info-Zeile
          Row(
            children: [
              // Kategorie-Icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    poi.category?.icon ?? '📍',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Name + Kategorie
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      poi.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Text(
                          poi.category?.label ?? '',
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (poi.detourKm != null) ...[
                          Text(
                            ' • +${poi.detourKm!.toStringAsFixed(1)} km',
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Empfohlen',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Action-Button
              _buildActionButton(context, ref, colorScheme),
            ],
          ),
          // AI-Reasoning
          if (reasoning.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                reasoning,
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    WidgetRef ref,
    ColorScheme colorScheme,
  ) {
    final isSwap = actionType == 'swap' && targetPOIId != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => isSwap
            ? _handleSwap(context, ref)
            : _handleAdd(context, ref),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            isSwap ? Icons.swap_horiz_rounded : Icons.add_rounded,
            color: colorScheme.primary,
            size: 18,
          ),
        ),
      ),
    );
  }

  Future<void> _handleAdd(BuildContext context, WidgetRef ref) async {
    final success = await ref
        .read(randomTripNotifierProvider.notifier)
        .addPOIToDay(poi, dayNumber);
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${poi.name}" zu Tag $dayNumber hinzugefuegt'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleSwap(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(randomTripNotifierProvider.notifier);

    // 1. Alten POI entfernen
    await notifier.removePOI(targetPOIId!);

    // 2. Neuen POI hinzufuegen
    final success = await notifier.addPOIToDay(poi, dayNumber);
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${poi.name}" eingetauscht'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _BottomActions extends ConsumerWidget {
  final Trip trip;
  final int selectedDay;
  final LatLng startLocation;
  final String startAddress;
  final bool isCompleted;
  final VoidCallback onOpenCorridorBrowser;

  const _BottomActions({
    required this.trip,
    required this.selectedDay,
    required this.startLocation,
    required this.startAddress,
    required this.isCompleted,
    required this.onOpenCorridorBrowser,
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ebene 1: POIs hinzufuegen + Route Teilen
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onOpenCorridorBrowser,
                      icon: const Icon(Icons.add_location_alt_rounded, size: 18),
                      label: const Text('POIs hinzufuegen'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _shareDayRoute(context, ref),
                      icon: const Icon(Icons.share, size: 18),
                      label: const Text('Route Teilen'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Ebene 2: Navigation starten (dominant)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _startDayNavigation(context, ref),
                  icon: const Icon(Icons.navigation_rounded),
                  label: const Text('Navigation starten'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Ebene 3: Google Maps Export (tertiaer)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openDayInGoogleMaps(context, ref),
                  icon: Icon(
                    isCompleted ? Icons.check_circle : Icons.open_in_new,
                    size: 18,
                  ),
                  label: Text(
                    isCompleted
                        ? 'Tag $selectedDay erneut oeffnen'
                        : 'Tag $selectedDay in Google Maps',
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    foregroundColor: isCompleted ? Colors.green : null,
                    side: isCompleted
                        ? const BorderSide(color: Colors.green)
                        : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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

  void _startDayNavigation(BuildContext context, WidgetRef ref) {
    final stopsForDay = trip.getStopsForDay(selectedDay);
    if (stopsForDay.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Keine Stops fuer Tag $selectedDay')),
      );
      return;
    }

    // Start bestimmen (gleiche Logik wie Google Maps Export)
    LatLng origin;
    String originAddress;
    if (selectedDay == 1) {
      origin = startLocation;
      originAddress = startAddress;
    } else {
      final prevDayStops = trip.getStopsForDay(selectedDay - 1);
      if (prevDayStops.isNotEmpty) {
        origin = prevDayStops.last.location;
        originAddress = prevDayStops.last.name;
      } else {
        origin = startLocation;
        originAddress = startAddress;
      }
    }

    // Ziel bestimmen
    LatLng destination;
    String destinationAddress;
    if (selectedDay == trip.actualDays) {
      destination = startLocation;
      destinationAddress = startAddress;
    } else {
      final nextDayStops = trip.getStopsForDay(selectedDay + 1);
      if (nextDayStops.isNotEmpty) {
        destination = nextDayStops.first.location;
        destinationAddress = nextDayStops.first.name;
      } else {
        destination = startLocation;
        destinationAddress = startAddress;
      }
    }

    // Tages-Route erstellen (OSRM berechnet echte Route)
    final dayRoute = AppRoute(
      start: origin,
      end: destination,
      startAddress: originAddress,
      endAddress: destinationAddress,
      coordinates: [origin, destination],
      distanceKm: 0,
      durationMinutes: 0,
    );

    // Overlay schliessen und Navigation starten
    Navigator.pop(context);
    context.push('/navigation', extra: {
      'route': dayRoute,
      'stops': stopsForDay,
    });
  }

  Future<void> _shareDayRoute(BuildContext context, WidgetRef ref) async {
    final stopsForDay = trip.getStopsForDay(selectedDay);
    if (stopsForDay.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Keine Stops fuer Tag $selectedDay')),
      );
      return;
    }

    // Start bestimmen (gleiche Logik wie Google Maps Export)
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

    // Google Maps URL bauen
    final waypoints = stopsForDay
        .take(TripConstants.maxPoisPerDay)
        .map((s) =>
            '${s.location.latitude.toStringAsFixed(6)},${s.location.longitude.toStringAsFixed(6)}')
        .join('|');
    final originStr =
        '${origin.latitude.toStringAsFixed(6)},${origin.longitude.toStringAsFixed(6)}';
    final destinationStr =
        '${destination.latitude.toStringAsFixed(6)},${destination.longitude.toStringAsFixed(6)}';
    final mapsUrl = 'https://www.google.com/maps/dir/?api=1'
        '&origin=$originStr'
        '&destination=$destinationStr'
        '&waypoints=$waypoints'
        '&travelmode=driving';

    // Share-Text
    final stopNames = stopsForDay
        .asMap()
        .entries
        .map((e) => '${e.key + 1}. ${e.value.name}')
        .join('\n');
    final shareText = 'Meine Route - Tag $selectedDay mit MapAB\n\n'
        'Stops:\n$stopNames\n\n'
        'In Google Maps oeffnen:\n$mapsUrl';

    try {
      await Share.share(shareText, subject: 'MapAB Route - Tag $selectedDay');
      debugPrint('[Share] Tag $selectedDay Route geteilt');
    } catch (e) {
      debugPrint('[Share] Error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Route konnte nicht geteilt werden'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
