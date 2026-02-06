import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../core/utils/location_helper.dart';
import '../../core/l10n/l10n.dart';
import '../../core/constants/categories.dart';
import '../../core/utils/weather_poi_utils.dart';
import '../../data/models/poi.dart';
import '../../data/models/route.dart';
import '../map/providers/weather_provider.dart';
import '../random_trip/providers/random_trip_provider.dart';
import '../random_trip/providers/random_trip_state.dart';
import '../trip/providers/trip_state_provider.dart';
import 'providers/poi_state_provider.dart';
import 'widgets/poi_card.dart';
import 'widgets/poi_filters.dart';

/// POI-Listen-Screen mit echten Daten
class POIListScreen extends ConsumerStatefulWidget {
  const POIListScreen({super.key});

  @override
  ConsumerState<POIListScreen> createState() => _POIListScreenState();
}

class _POIListScreenState extends ConsumerState<POIListScreen> {
  bool _isInitialized = false;
  late ScrollController _scrollController;
  Timer? _scrollDebounceTimer;
  bool _weatherSortActive = false;
  bool _weatherBannerDismissed = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPOIs();
    });
  }

  @override
  void dispose() {
    _scrollDebounceTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Debounced Scroll-Handler für Lazy-Loading von POI-Bildern
  void _onScroll() {
    _scrollDebounceTimer?.cancel();
    _scrollDebounceTimer = Timer(const Duration(milliseconds: 150), () {
      _enrichVisiblePOIs();
    });
  }

  /// Enriched POIs im sichtbaren Bereich + Puffer (OPTIMIERT v1.7.3: Batch-Request)
  void _enrichVisiblePOIs() {
    if (!_scrollController.hasClients) return;

    final poiState = ref.read(pOIStateNotifierProvider);
    final pois = poiState.filteredPOIs;
    if (pois.isEmpty) return;

    final poiNotifier = ref.read(pOIStateNotifierProvider.notifier);

    // Berechne sichtbaren Bereich (Card-Höhe ~108px inkl. Padding)
    const itemHeight = 108.0;
    final scrollPosition = _scrollController.position.pixels;
    final viewportHeight = _scrollController.position.viewportDimension;

    final firstVisible = (scrollPosition / itemHeight).floor();
    final lastVisible = ((scrollPosition + viewportHeight) / itemHeight).ceil();

    // Puffer: 10 Items vor und nach sichtbarem Bereich (erhöht für Batch)
    final startIndex = (firstVisible - 10).clamp(0, pois.length - 1);
    final endIndex = (lastVisible + 10).clamp(0, pois.length);

    // Sammle alle POIs im Bereich die Enrichment brauchen
    final poisToEnrich = <POI>[];
    for (int i = startIndex; i < endIndex && i < pois.length; i++) {
      final poi = pois[i];
      if (!poi.isEnriched &&
          poi.imageUrl == null &&
          !poiState.enrichingPOIIds.contains(poi.id)) {
        poisToEnrich.add(poi);
      }
    }

    // OPTIMIERT v1.7.3: Batch-Enrichment für alle POIs im Bereich
    if (poisToEnrich.isNotEmpty) {
      debugPrint('[POIList] Scroll-Batch für ${poisToEnrich.length} POIs');
      poiNotifier.enrichPOIsBatch(poisToEnrich);
    }
  }

  Future<void> _loadPOIs() async {
    if (_isInitialized) return;
    _isInitialized = true;

    final poiNotifier = ref.read(pOIStateNotifierProvider.notifier);
    final tripState = ref.read(tripStateProvider);

    debugPrint(
        '[POIList] _loadPOIs gestartet - hasRoute: ${tripState.hasRoute}');

    // Wenn eine Route vorhanden ist, POIs für Route laden
    if (tripState.hasRoute) {
      // FIX v1.5.2: RouteOnlyMode setzen für Route-POIs
      poiNotifier.setRouteOnlyMode(true);
      await poiNotifier.loadPOIsForRoute(tripState.route!);
      final state = ref.read(pOIStateNotifierProvider);
      debugPrint(
          '[POIList] Nach loadPOIsForRoute: ${state.pois.length} POIs geladen, ${state.filteredPOIs.length} nach Filter');
      // Pre-Enrichment starten
      _preEnrichVisiblePOIs();
      return;
    }

    // WICHTIG: Wenn keine Route vorhanden ist, routeOnlyMode deaktivieren
    // Sonst werden alle POIs herausgefiltert (da sie keine routePosition haben)
    // FIX v1.5.2: Auch alle anderen Filter zurücksetzen
    poiNotifier.resetFilters();
    debugPrint('[POIList] Keine Route vorhanden - alle Filter zurückgesetzt');

    // Sonst: GPS-Position verwenden
    try {
      final result = await LocationHelper.getCurrentPosition(
        accuracy: LocationAccuracy.medium,
      );

      if (!result.isSuccess) {
        if (!mounted) return;
        if (result.isGpsDisabled) {
          final openSettings = await _showGpsDialog();
          if (openSettings) await LocationHelper.openSettings();
        } else if (result.isPermissionDenied) {
          _showPermissionDeniedSnackBar();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message ?? 'GPS-Fehler'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      await poiNotifier.loadPOIsInRadius(
        center: result.position!,
        radiusKm: 50,
      );
    } catch (e) {
      debugPrint('[POIList] GPS-Fehler: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.gpsCouldNotDetermine),
          duration: const Duration(seconds: 3),
        ),
      );
    }

    // Pre-Enrichment für Top-POIs starten
    _preEnrichVisiblePOIs();
  }

  /// Pre-Enrichment für sichtbare POIs (OPTIMIERT v1.7.3: Batch-Request)
  /// Nutzt Wikipedia Multi-Title-Query für bis zu 50 POIs gleichzeitig
  void _preEnrichVisiblePOIs() {
    final poiNotifier = ref.read(pOIStateNotifierProvider.notifier);
    final poiState = ref.read(pOIStateNotifierProvider);

    // Nur POIs ohne Bilder und nicht bereits in Enrichment (bis zu 30)
    final poisToEnrich = poiState.filteredPOIs
        .where((poi) =>
            !poi.isEnriched &&
            poi.imageUrl == null &&
            !poiState.enrichingPOIIds.contains(poi.id))
        .take(50) // OPTIMIERT v1.7.9: Auf 50 erhoeht (Wikipedia Batch-Query Limit)
        .toList();

    if (poisToEnrich.isEmpty) {
      debugPrint(
          '[POIList] Alle sichtbaren POIs bereits enriched oder in Arbeit');
      return;
    }

    debugPrint(
        '[POIList] Batch-Enrichment für ${poisToEnrich.length} POIs starten');

    // OPTIMIERT v1.7.3: Batch-Enrichment nutzen statt einzelner Requests
    poiNotifier.enrichPOIsBatch(poisToEnrich);
  }

  /// Dialog anzeigen wenn GPS deaktiviert ist (v1.5.9)
  /// Nutzt zentralisierten LocationHelper.showGpsDialog (v1.9.29)
  Future<bool> _showGpsDialog() async {
    return LocationHelper.showGpsDialog(context);
  }

  /// SnackBar anzeigen wenn GPS-Berechtigung verweigert wurde
  void _showPermissionDeniedSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.poiGpsPermissionNeeded),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final poiState = ref.watch(pOIStateNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.poiTitle),
        actions: [
          if (poiState.hasActiveFilters)
            IconButton(
              icon: const Icon(Icons.filter_alt_off),
              tooltip: context.l10n.poiResetFilters,
              onPressed: () {
                ref.read(pOIStateNotifierProvider.notifier).resetFilters();
              },
            ),
          IconButton(
            icon: Badge(
              isLabelVisible: poiState.hasActiveFilters,
              child: const Icon(Icons.filter_list),
            ),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Suchleiste
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) {
                ref
                    .read(pOIStateNotifierProvider.notifier)
                    .setSearchQuery(value);
              },
              decoration: InputDecoration(
                hintText: context.l10n.poiSearchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: poiState.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          ref
                              .read(pOIStateNotifierProvider.notifier)
                              .setSearchQuery('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Quick Filter Chips
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FilterChip(
                  label: context.l10n.poiMustSee,
                  icon: '⭐',
                  isSelected: poiState.mustSeeOnly,
                  onTap: () {
                    ref
                        .read(pOIStateNotifierProvider.notifier)
                        .toggleMustSeeOnly();
                  },
                ),
                const SizedBox(width: 8),
                // Wetter-Tipp Chip (v1.9.9): Sortiert POIs nach Wetter-Relevanz
                _FilterChip(
                  label: context.l10n.poiWeatherTip,
                  icon: '\u{1F326}\u{FE0F}',
                  isSelected: _weatherSortActive,
                  onTap: () {
                    setState(() => _weatherSortActive = !_weatherSortActive);
                  },
                ),
                const SizedBox(width: 8),
                ...POICategory.values.map((cat) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _FilterChip(
                        label: cat.label,
                        icon: cat.icon,
                        isSelected: poiState.selectedCategories.contains(cat),
                        onTap: () {
                          final notifier =
                              ref.read(pOIStateNotifierProvider.notifier);
                          final categories = Set<POICategory>.from(
                              poiState.selectedCategories);
                          if (categories.contains(cat)) {
                            categories.remove(cat);
                          } else {
                            categories.add(cat);
                          }
                          notifier.setSelectedCategories(categories);
                        },
                      ),
                    )),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Status-Zeile
          if (poiState.totalCount > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text(
                    context.l10n.poiResultsCount(poiState.filteredCount, poiState.totalCount),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  if (poiState.hasActiveFilters)
                    TextButton.icon(
                      onPressed: () {
                        ref
                            .read(pOIStateNotifierProvider.notifier)
                            .resetFilters();
                      },
                      icon: const Icon(Icons.clear, size: 16),
                      label: Text(context.l10n.poiClearFilters),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        textStyle: theme.textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            ),

          // POI-Liste
          Expanded(
            child: _buildPOIList(poiState),
          ),
        ],
      ),
    );
  }

  Widget _buildPOIList(POIState poiState) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // Wetter-State fuer Badges und Sortierung (v1.7.6, erweitert v1.9.9)
    final routeWeather = ref.watch(routeWeatherNotifierProvider);
    final locationWeather = ref.watch(locationWeatherNotifierProvider);
    final hasRouteWeather = routeWeather.weatherPoints.isNotEmpty;
    final hasLocationWeather = locationWeather.hasWeather;
    final hasWeatherData = hasRouteWeather || hasLocationWeather;
    // Effektive Wetter-Condition: Route-Wetter hat Prioritaet, dann Location-Wetter
    final weatherCondition = hasRouteWeather
        ? routeWeather.overallCondition
        : (hasLocationWeather ? locationWeather.weather!.condition : null);

    // Loading
    if (poiState.isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(context.l10n.poiLoading),
          ],
        ),
      );
    }

    // Fehler
    if (poiState.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(
              poiState.error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.error),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                _isInitialized = false;
                _loadPOIs();
              },
              icon: const Icon(Icons.refresh),
              label: Text(context.l10n.retry),
            ),
          ],
        ),
      );
    }

    // Keine POIs
    var pois = poiState.filteredPOIs;

    // Wetter-Sortierung anwenden wenn aktiv (v1.9.9)
    if (_weatherSortActive && weatherCondition != null) {
      pois = WeatherPOIUtils.sortByWeatherRelevance(pois, weatherCondition);
    }

    if (pois.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🗺️', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              poiState.hasActiveFilters
                  ? context.l10n.poiNoResultsFilter
                  : context.l10n.poiNoResultsNearby,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (poiState.hasActiveFilters)
              TextButton(
                onPressed: () {
                  ref.read(pOIStateNotifierProvider.notifier).resetFilters();
                },
                child: Text(context.l10n.poiResetFilters),
              ),
          ],
        ),
      );
    }

    // Wetter-Kontext-Banner (v1.9.9): Dezenter Hinweis bei schlechtem Wetter
    final showWeatherBanner = hasWeatherData &&
        !_weatherBannerDismissed &&
        (weatherCondition == WeatherCondition.bad ||
         weatherCondition == WeatherCondition.danger);

    // POI-Liste OPTIMIERT: Mit cacheExtent und addAutomaticKeepAlives
    return Column(
      children: [
        if (showWeatherBanner)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: weatherCondition == WeatherCondition.danger
                    ? colorScheme.errorContainer.withValues(alpha: 0.5)
                    : colorScheme.tertiaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    weatherCondition == WeatherCondition.danger ? '\u{26A0}\u{FE0F}' : '\u{1F327}\u{FE0F}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      weatherCondition == WeatherCondition.danger
                          ? context.l10n.poiWeatherDangerBanner
                          : context.l10n.poiWeatherBadBanner,
                      style: TextStyle(
                        fontSize: 12,
                        color: weatherCondition == WeatherCondition.danger
                            ? colorScheme.onErrorContainer
                            : colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => setState(() => _weatherBannerDismissed = true),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        Expanded(child: RefreshIndicator(
      onRefresh: () async {
        _isInitialized = false;
        await _loadPOIs();
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: pois.length,
        // OPTIMIERUNG: Mehr Items im Speicher halten für flüssiges Scrollen
        cacheExtent: 500,
        // OPTIMIERUNG: Automatisches KeepAlive für sichtbare Items
        addAutomaticKeepAlives: true,
        // OPTIMIERUNG: Semantics deaktivieren für bessere Performance
        addSemanticIndexes: false,
        itemBuilder: (context, index) {
          final poi = pois[index];

          // v1.6.0: On-Demand Enrichment ohne Index-Limit
          // Scroll-Listener (_enrichVisiblePOIs) übernimmt das Lazy-Loading
          // Dieser Fallback fängt Edge-Cases ab (z.B. wenn User direkt zu einem POI springt)
          if (!poi.isEnriched &&
              poi.imageUrl == null &&
              !poiState.enrichingPOIIds.contains(poi.id)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                ref.read(pOIStateNotifierProvider.notifier).enrichPOI(poi.id);
              }
            });
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: POICard(
              name: poi.name,
              category: poi.category ?? POICategory.attraction,
              distance: poi.detourKm != null
                  ? '${poi.detourKm!.toStringAsFixed(1)} km Umweg'
                  : null,
              rating: poi.starRating,
              reviewCount: poi.reviewCount,
              isMustSee: poi.isMustSee,
              imageUrl: poi.imageUrl,
              highlights: poi.highlights,
              // Wetter-Badge anzeigen wenn Wetterdaten vorhanden (v1.7.6, v1.9.9: Location-Wetter Fallback)
              weatherCondition: hasWeatherData ? weatherCondition : null,
              onTap: () {
                // FIX v1.6.7: selectPOI hier entfernt - wird in POIDetailScreen via selectPOIById aufgerufen
                // Vorher: Doppel-Select mit veraltetem POI führte zu fehlenden Fotos/Highlights
                context.push('/poi/${poi.id}');
              },
              onAddToTrip: () {
                _addPOIToTrip(poi);
              },
            ),
          );
        },
      ),
    )),
      ],
    );
  }

  Future<void> _addPOIToTrip(POI poi) async {
    final tripNotifier = ref.read(tripStateProvider.notifier);
    final tripData = ref.read(tripStateProvider);

    // AI Trip erkennen und Daten übergeben
    AppRoute? aiRoute;
    List<POI>? aiStops;
    if (tripData.route == null) {
      final randomTripState = ref.read(randomTripNotifierProvider);
      if (randomTripState.generatedTrip != null &&
          (randomTripState.step == RandomTripStep.preview ||
           randomTripState.step == RandomTripStep.confirmed)) {
        aiRoute = randomTripState.generatedTrip!.trip.route;
        aiStops = randomTripState.generatedTrip!.selectedPOIs;
      }
    }

    final result = await tripNotifier.addStopWithAutoRoute(
      poi,
      existingAIRoute: aiRoute,
      existingAIStops: aiStops,
    );

    // AI Trip als bestätigt markieren
    if (aiRoute != null && result.success) {
      ref.read(randomTripNotifierProvider.notifier).markAsConfirmed();
    }

    if (!mounted) return;

    if (result.success) {
      if (result.routeCreated) {
        // Route wurde erstellt - zum Trip-Tab navigieren
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.poiRouteCreated(poi.name)),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go('/trip');
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
          content: Text(result.message ?? context.l10n.errorAddingToRoute),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showFilterSheet() {
    final poiState = ref.read(pOIStateNotifierProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => POIFiltersSheet(
        selectedCategories: poiState.selectedCategories,
        mustSeeOnly: poiState.mustSeeOnly,
        indoorOnly: poiState.indoorOnlyFilter,
        maxDetour: poiState.maxDetourKm,
        onApply: (categories, mustSee, indoorOnly, detour) {
          final notifier = ref.read(pOIStateNotifierProvider.notifier);
          notifier.setSelectedCategories(categories);
          if (mustSee != poiState.mustSeeOnly) {
            notifier.toggleMustSeeOnly();
          }
          notifier.setIndoorOnly(indoorOnly);
          notifier.setMaxDetour(detour);
          Navigator.pop(context);
        },
      ),
    );
  }
}

/// Filter Chip Widget
class _FilterChip extends StatelessWidget {
  final String label;
  final String icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
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
                  : colorScheme.outline.withValues(alpha: 0.3),
              width: isSelected ? 1.5 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(icon, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              if (isSelected) ...[
                Icon(
                  Icons.check,
                  size: 14,
                  color: colorScheme.onPrimary,
                ),
                const SizedBox(width: 2),
              ],
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
