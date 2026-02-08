import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import '../../../core/constants/categories.dart';
import '../../../core/utils/url_utils.dart';
import '../../../core/constants/trip_constants.dart';
import '../../../data/models/poi.dart';
import '../../../data/models/route.dart';
import '../../../data/models/trip.dart';
import '../../../data/models/weather.dart';
import '../../map/providers/weather_provider.dart';
import '../../poi/providers/poi_state_provider.dart';
import '../../random_trip/providers/random_trip_provider.dart';
import '../../random_trip/providers/random_trip_state.dart';
import '../../random_trip/widgets/day_tab_selector.dart';
import '../../ai/providers/ai_trip_advisor_provider.dart';
import '../../ai/widgets/ai_suggestion_banner.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/l10n/category_l10n.dart';
import '../utils/trip_save_helper.dart';
import 'corridor_browser_sheet.dart';
import 'day_mini_map.dart';
import 'editable_poi_card.dart';
import '../../social/widgets/publish_trip_sheet.dart';

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
  bool _isFooterCollapsed = false;
  Timer? _footerExpandTimer;

  void _collapseFooterWhileScrolling() {
    _footerExpandTimer?.cancel();
    if (_isFooterCollapsed) return;
    setState(() => _isFooterCollapsed = true);
  }

  void _expandFooterAfterScroll() {
    _footerExpandTimer?.cancel();
    _footerExpandTimer = Timer(const Duration(seconds: 1), () {
      if (!mounted || !_isFooterCollapsed) return;
      setState(() => _isFooterCollapsed = false);
    });
  }

  @override
  void dispose() {
    _footerExpandTimer?.cancel();
    super.dispose();
  }

  void _openRecommendedPoiDetail(POI poi) {
    final poiNotifier = ref.read(pOIStateNotifierProvider.notifier);
    poiNotifier.addPOI(poi);
    if (poi.imageUrl == null || !(poi.isEnriched)) {
      unawaited(poiNotifier.enrichPOI(poi.id));
    }
    context.push('/poi/${poi.id}');
  }

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
        appBar: AppBar(title: Text(context.l10n.dayEditorTitle)),
        body: Center(child: Text(context.l10n.dayEditorNoTrip)),
      );
    }

    final isMultiDay = trip.actualDays > 1;
    final selectedDay = state.selectedDay;
    final isEuroTripMode = state.mode == RandomTripMode.eurotrip;
    final stopsForDay = trip.getStopsForDay(selectedDay);
    final bottomSafeArea = MediaQuery.of(context).viewPadding.bottom;
    final footerSpacerHeight =
        _isFooterCollapsed ? 16.0 + bottomSafeArea : 120.0 + bottomSafeArea;
    final startLocation = state.startLocation;
    if (startLocation == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.dayEditorTitle)),
        body: Center(child: Text(context.l10n.dayEditorStartNotAvailable)),
      );
    }

    // Route-Segment fuer den ausgewaehlten Tag
    final fullRoute = trip.route;
    List<LatLng> routeSegment = [];
    if (stopsForDay.isNotEmpty) {
      final segStart = trip.getDayStartLocation(selectedDay);
      final segEnd = trip.getDayEndLocation(selectedDay);
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
    final dayForecast =
        routeWeather.getDayForecast(selectedDay, trip.actualDays);

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
        if (!mounted) return;
        ref
            .read(aITripAdvisorNotifierProvider.notifier)
            .loadSmartRecommendations(
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
            ? context.l10n.dayEditorEditDay(selectedDay)
            : context.l10n.dayEditorTitle),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
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
              onMarkerTap: _openRecommendedPoiDetail,
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
                existingStopIds: trip.stops.map((s) => s.poiId).toSet(),
                onAddPOI: (poi) async {
                  final success = await ref
                      .read(randomTripNotifierProvider.notifier)
                      .addPOIToDay(poi, selectedDay);
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            '"${poi.name}" ${context.l10n.dayEditorAddedToDay(selectedDay)}'),
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
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollUpdateNotification) {
                    final delta = notification.scrollDelta ?? 0;
                    if (delta.abs() > 0.2) {
                      _collapseFooterWhileScrolling();
                    }
                  } else if (notification is UserScrollNotification) {
                    if (notification.direction == ScrollDirection.idle) {
                      _expandFooterAfterScroll();
                    } else {
                      _collapseFooterWhileScrolling();
                    }
                  } else if (notification is ScrollEndNotification) {
                    _expandFooterAfterScroll();
                  }
                  return false;
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
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
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber,
                                color: Colors.orange, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                context.l10n.dayEditorMaxStops(
                                    TripConstants.maxPoisPerDay),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      height: footerSpacerHeight,
                    ), // Platz fuer Bottom Buttons + SafeArea (dynamisch)
                  ],
                ),
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
              isCollapsed: _isFooterCollapsed,
              isMultiDay: isMultiDay,
              isEuroTripMode: isEuroTripMode,
              dayForecast: dayForecast,
              dayWeather: dayWeather,
              onOpenCorridorBrowser: () {
                setState(() => _isCorridorBrowserActive = true);
              },
              onSaveToFavorites: state.isLoading
                  ? null
                  : () => TripSaveHelper.saveAITrip(context, ref, state),
              onPublishTrip: () {
                unawaited(() async {
                  final published = await PublishTripSheet.show(context, trip);
                  if (published && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.l10n.publishSuccess),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }());
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
    final dayPosition =
        totalDays > 1 ? (selectedDay - 1) / (totalDays - 1) : 0.5;

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
            ? Colors.orange.withValues(alpha: 0.1)
            : colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatChip(
            icon: Icons.place,
            value: '$stopCount',
            label: context.l10n.tripInfoStops,
            isWarning: isStopOverLimit,
          ),
          _StatChip(
            icon: Icons.straighten,
            value: '~${dayDistance.toStringAsFixed(0)} km',
            label: context.l10n.tripInfoDistance,
            isWarning: isDistanceOverLimit,
          ),
          _StatChip(
            icon: Icons.access_time,
            value: formattedTime,
            label: context.l10n.dayEditorDriveTime,
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
              label: context.l10n.dayEditorWeather,
            ),
          if (isMultiDay)
            _StatChip(
              icon: Icons.calendar_today,
              value: '$selectedDay/${trip.actualDays}',
              label: context.l10n.dayEditorDay,
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
    final color =
        isWarning ? Colors.orange.shade700 : colorScheme.onPrimaryContainer;

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
            color: color.withValues(alpha: 0.7),
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
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
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
              context.l10n.dayEditorSearchRecommendations,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
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
          label: Text(context.l10n.dayEditorLoadRecommendations),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 40),
            side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.3)),
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
                context.l10n.dayEditorAiRecommendations,
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
                color: colorScheme.onSurface.withValues(alpha: 0.5),
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
              highlights: suggestion.highlights,
              longDescription: suggestion.longDescription,
              photoUrls: suggestion.photoUrls,
            );
          }

          // Text-Vorschlag (bestehend)
          final isWeather = suggestion.type == SuggestionType.weather;
          final isAlternative = suggestion.type == SuggestionType.alternative;

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 3),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isWeather
                  ? colorScheme.tertiaryContainer.withValues(alpha: 0.3)
                  : isAlternative
                      ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                      : colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.1),
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
                  color: isWeather ? colorScheme.tertiary : colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    suggestion.message,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.8),
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
  final List<String> highlights;
  final String? longDescription;
  final List<String> photoUrls;

  const _AIRecommendedPOICard({
    required this.poi,
    required this.reasoning,
    required this.actionType,
    this.targetPOIId,
    required this.dayNumber,
    this.highlights = const [],
    this.longDescription,
    this.photoUrls = const [],
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final previewImage = photoUrls.isNotEmpty
        ? photoUrls.first
        : (poi.imageUrl ?? poi.thumbnailUrl);
    final hasPreviewImage = previewImage != null && previewImage.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openDetails(context, ref),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // POI-Info-Zeile
              Row(
                children: [
                  if (hasPreviewImage)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: CachedNetworkImage(
                          imageUrl: previewImage,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: colorScheme.surfaceContainerHighest,
                            child: Center(
                              child: Text(
                                poi.category?.icon ?? 'P',
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: colorScheme.surfaceContainerHighest,
                            child: Center(
                              child: Text(
                                poi.category?.icon ?? 'P',
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    // Kategorie-Icon
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color:
                            colorScheme.primaryContainer.withValues(alpha: 0.5),
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
                              poi.category?.localizedLabel(context) ?? '',
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
                                color: Colors.green.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                context.l10n.dayEditorRecommended,
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
              if (!hasPreviewImage)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    context.l10n.dayEditorNoPhotoFallbackHint,
                    style: TextStyle(
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              if (highlights.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: highlights.take(4).map((h) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.tertiaryContainer
                              .withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          h,
                          style: TextStyle(
                            fontSize: 10,
                            color: colorScheme.onTertiaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              if (longDescription != null && longDescription!.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    longDescription!,
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurface.withValues(alpha: 0.78),
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
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
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
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
        onTap: () =>
            isSwap ? _handleSwap(context, ref) : _handleAdd(context, ref),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.5),
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

  void _openDetails(BuildContext context, WidgetRef ref) {
    final poiNotifier = ref.read(pOIStateNotifierProvider.notifier);
    poiNotifier.addPOI(poi);
    if (poi.imageUrl == null || !poi.isEnriched) {
      unawaited(poiNotifier.enrichPOI(poi.id));
    }
    context.push('/poi/${poi.id}');
  }

  Future<void> _handleAdd(BuildContext context, WidgetRef ref) async {
    final success = await ref
        .read(randomTripNotifierProvider.notifier)
        .addPOIToDay(poi, dayNumber);
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '"${poi.name}" ${context.l10n.dayEditorAddedToDay(dayNumber)}'),
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
          content: Text(context.l10n.dayEditorSwapped(poi.name)),
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
  final bool isCollapsed;
  final bool isMultiDay;
  final bool isEuroTripMode;
  final DailyForecast? dayForecast;
  final WeatherCondition dayWeather;
  final VoidCallback onOpenCorridorBrowser;
  final VoidCallback? onSaveToFavorites;
  final VoidCallback? onPublishTrip;

  const _BottomActions({
    required this.trip,
    required this.selectedDay,
    required this.startLocation,
    required this.startAddress,
    required this.isCompleted,
    required this.isCollapsed,
    required this.isMultiDay,
    required this.isEuroTripMode,
    this.dayForecast,
    this.dayWeather = WeatherCondition.unknown,
    required this.onOpenCorridorBrowser,
    this.onSaveToFavorites,
    this.onPublishTrip,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fullContent = Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
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
              // Minimal-Footer: Weitere POIs + Fertig
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onOpenCorridorBrowser,
                      icon:
                          const Icon(Icons.add_location_alt_rounded, size: 18),
                      label: const Text('Weitere POIs hinzufügen'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _showFinishOverviewModal(context, ref),
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Fertig'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
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
    );

    return ClipRect(
      child: AnimatedSize(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        alignment: Alignment.bottomCenter,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          offset: isCollapsed ? const Offset(0, 1) : Offset.zero,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            opacity: isCollapsed ? 0 : 1,
            child: IgnorePointer(
              ignoring: isCollapsed,
              child: isCollapsed ? const SizedBox.shrink() : fullContent,
            ),
          ),
        ),
      ),
    );
  }

  void _showFinishOverviewModal(BuildContext context, WidgetRef ref) {
    final stopsForDay = trip.getStopsForDay(selectedDay);
    final origin = trip.getDayStartLocation(selectedDay);
    final destination = trip.getDayEndLocation(selectedDay);
    final mapsLabel = isEuroTripMode
        ? context.l10n.dayEditorDayInGoogleMaps(selectedDay)
        : 'Tagestrip in Google Maps';

    final routeSegment = extractRouteSegment(
      trip.route.coordinates,
      origin,
      destination,
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (modalContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.92,
          minChildSize: 0.65,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 8),
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                  child: Row(
                    children: [
                      Text(
                        'Übersicht',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(modalContext),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    children: [
                      DayMiniMap(
                        key: ValueKey(
                            'summary-$selectedDay-${stopsForDay.length}'),
                        trip: trip,
                        selectedDay: selectedDay,
                        startLocation: startLocation,
                        routeSegment: routeSegment,
                        recommendedPOIs: const [],
                        onMarkerTap: null,
                      ),
                      const SizedBox(height: 12),
                      _DayStats(
                        stopsForDay: stopsForDay,
                        selectedDay: selectedDay,
                        isMultiDay: isMultiDay,
                        trip: trip,
                        dayForecast: dayForecast,
                        dayWeather: dayWeather,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.pop(modalContext);
                            _startDayNavigation(context, ref);
                          },
                          icon: const Icon(Icons.navigation_rounded),
                          label: Text(context.l10n.tripInfoStartNavigation),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.tonalIcon(
                          onPressed: onSaveToFavorites == null
                              ? null
                              : () {
                                  Navigator.pop(modalContext);
                                  onSaveToFavorites?.call();
                                },
                          icon: const Icon(Icons.favorite_border_rounded),
                          label: const Text('Route speichern'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.tonalIcon(
                          onPressed: onPublishTrip == null
                              ? null
                              : () {
                                  Navigator.pop(modalContext);
                                  onPublishTrip?.call();
                                },
                          icon: const Icon(Icons.public),
                          label: Text(context.l10n.publishButton),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(modalContext);
                            _openDayInGoogleMaps(context, ref);
                          },
                          icon: Icon(
                            isCompleted
                                ? Icons.check_circle
                                : Icons.open_in_new,
                          ),
                          label: Text(mapsLabel),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openDayInGoogleMaps(BuildContext context, WidgetRef ref) async {
    final stopsForDay = trip.getStopsForDay(selectedDay);
    if (stopsForDay.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(context.l10n.dayEditorNoStopsForDay(selectedDay))),
      );
      return;
    }

    final origin = trip.getDayStartLocation(selectedDay);
    final destination = trip.getDayEndLocation(selectedDay);

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

    try {
      await launchUrlSafe(Uri.parse(url));

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
          SnackBar(
            content: Text(context.l10n.errorGoogleMapsNotOpened),
          ),
        );
      }
    }
  }

  Future<void> _showTripCompletedDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.dayEditorTripCompleted),
        content: Text(context.l10n.dayEditorAllDaysExported),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx); // Dialog schliessen
              // DayEditor sicher schliessen (context kann nach Dialog-Pop ungueltig sein)
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: Text(context.l10n.done),
          ),
        ],
      ),
    );
  }

  void _startDayNavigation(BuildContext context, WidgetRef ref) {
    final stopsForDay = trip.getStopsForDay(selectedDay);
    if (stopsForDay.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(context.l10n.dayEditorNoStopsForDay(selectedDay))),
      );
      return;
    }

    final origin = trip.getDayStartLocation(selectedDay);
    final originAddress = trip.getDayStartLabel(
      selectedDay,
      defaultStartAddress: startAddress,
    );
    final destination = trip.getDayEndLocation(selectedDay);
    final destinationAddress = trip.getDayEndLabel(
      selectedDay,
      defaultStartAddress: startAddress,
    );

    // Tages-Route erstellen (OSRM berechnet echte Route)
    final dayRoute = AppRoute(
      start: origin,
      end: destination,
      startAddress: originAddress,
      endAddress: destinationAddress,
      coordinates: [origin, destination],
      waypoints:
          stopsForDay.map((s) => LatLng(s.latitude, s.longitude)).toList(),
      distanceKm: 0,
      durationMinutes: 0,
    );

    // Overlay schliessen und Navigation starten
    Navigator.pop(context);
    if (context.mounted) {
      context.push('/navigation', extra: {
        'route': dayRoute,
        'stops': stopsForDay,
      });
    }
  }
}
