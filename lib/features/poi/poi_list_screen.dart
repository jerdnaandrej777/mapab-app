import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/categories.dart';
import '../../data/models/poi.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPOIs();
    });
  }

  Future<void> _loadPOIs() async {
    if (_isInitialized) return;
    _isInitialized = true;

    final poiNotifier = ref.read(pOIStateNotifierProvider.notifier);
    final tripState = ref.read(tripStateProvider);

    // Wenn eine Route vorhanden ist, POIs für Route laden
    if (tripState.hasRoute) {
      await poiNotifier.loadPOIsForRoute(tripState.route!);
      // Pre-Enrichment starten
      _preEnrichVisiblePOIs();
      return;
    }

    // Sonst: GPS-Position verwenden
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );

      await poiNotifier.loadPOIsInRadius(
        center: LatLng(position.latitude, position.longitude),
        radiusKm: 50,
      );
    } catch (e) {
      // Fallback: München als Zentrum
      debugPrint('[POIList] GPS nicht verfügbar, nutze München als Fallback');
      await poiNotifier.loadPOIsInRadius(
        center: const LatLng(48.1351, 11.5820),
        radiusKm: 50,
      );
    }

    // Pre-Enrichment für Top-POIs starten
    _preEnrichVisiblePOIs();
  }

  /// Pre-Enrichment für sichtbare POIs (Top 20 ohne Bilder)
  void _preEnrichVisiblePOIs() {
    final poiNotifier = ref.read(pOIStateNotifierProvider.notifier);
    final poiState = ref.read(pOIStateNotifierProvider);

    // Top 20 POIs ohne Bilder auswählen
    final poisToEnrich = poiState.filteredPOIs
        .where((poi) => !poi.isEnriched && poi.imageUrl == null)
        .take(20)
        .toList();

    if (poisToEnrich.isEmpty) {
      debugPrint('[POIList] Alle sichtbaren POIs bereits enriched');
      return;
    }

    debugPrint('[POIList] Pre-Enrichment für ${poisToEnrich.length} POIs starten');

    // Im Hintergrund enrichen (nicht blockierend)
    for (final poi in poisToEnrich) {
      unawaited(poiNotifier.enrichPOI(poi.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final poiState = ref.watch(pOIStateNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sehenswürdigkeiten'),
        actions: [
          if (poiState.hasActiveFilters)
            IconButton(
              icon: const Icon(Icons.filter_alt_off),
              tooltip: 'Filter zurücksetzen',
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
                ref.read(pOIStateNotifierProvider.notifier).setSearchQuery(value);
              },
              decoration: InputDecoration(
                hintText: 'POIs durchsuchen...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: poiState.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          ref.read(pOIStateNotifierProvider.notifier).setSearchQuery('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
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
                  label: 'Must-See',
                  icon: '⭐',
                  isSelected: poiState.mustSeeOnly,
                  onTap: () {
                    ref.read(pOIStateNotifierProvider.notifier).toggleMustSeeOnly();
                  },
                ),
                const SizedBox(width: 8),
                ...POICategory.values.take(6).map((cat) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _FilterChip(
                        label: cat.label,
                        icon: cat.icon,
                        isSelected: poiState.selectedCategories.contains(cat),
                        onTap: () {
                          final notifier = ref.read(pOIStateNotifierProvider.notifier);
                          final categories = Set<POICategory>.from(poiState.selectedCategories);
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
                    '${poiState.filteredCount} von ${poiState.totalCount} POIs',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  if (poiState.hasActiveFilters)
                    TextButton.icon(
                      onPressed: () {
                        ref.read(pOIStateNotifierProvider.notifier).resetFilters();
                      },
                      icon: const Icon(Icons.clear, size: 16),
                      label: const Text('Filter löschen'),
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

    // Loading
    if (poiState.isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Lade Sehenswürdigkeiten...'),
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
              label: const Text('Erneut versuchen'),
            ),
          ],
        ),
      );
    }

    // Keine POIs
    final pois = poiState.filteredPOIs;
    if (pois.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🗺️', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              poiState.hasActiveFilters
                  ? 'Keine POIs mit diesen Filtern gefunden'
                  : 'Keine POIs in der Nähe gefunden',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (poiState.hasActiveFilters)
              TextButton(
                onPressed: () {
                  ref.read(pOIStateNotifierProvider.notifier).resetFilters();
                },
                child: const Text('Filter zurücksetzen'),
              ),
          ],
        ),
      );
    }

    // POI-Liste
    return RefreshIndicator(
      onRefresh: () async {
        _isInitialized = false;
        await _loadPOIs();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: pois.length,
        itemBuilder: (context, index) {
          final poi = pois[index];
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
              onTap: () {
                ref.read(pOIStateNotifierProvider.notifier).selectPOI(poi);
                context.push('/poi/${poi.id}');
              },
              onAddToTrip: () {
                _addPOIToTrip(poi);
              },
            ),
          );
        },
      ),
    );
  }

  void _addPOIToTrip(POI poi) {
    final tripNotifier = ref.read(tripStateProvider.notifier);
    tripNotifier.addStop(poi);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${poi.name} zur Route hinzugefügt'),
        action: SnackBarAction(
          label: 'Rückgängig',
          onPressed: () {
            tripNotifier.removeStop(poi.id);
          },
        ),
      ),
    );
  }

  void _showFilterSheet() {
    final poiState = ref.read(pOIStateNotifierProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => POIFiltersSheet(
        selectedCategories: poiState.selectedCategories,
        mustSeeOnly: poiState.mustSeeOnly,
        maxDetour: poiState.maxDetourKm,
        onApply: (categories, mustSee, detour) {
          final notifier = ref.read(pOIStateNotifierProvider.notifier);
          notifier.setSelectedCategories(categories);
          if (mustSee != poiState.mustSeeOnly) {
            notifier.toggleMustSeeOnly();
          }
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outline.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
