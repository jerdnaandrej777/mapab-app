import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/categories.dart';
import '../../../data/models/poi.dart';
import '../../../data/models/route.dart';
import '../../map/utils/poi_trip_helper.dart';
import '../../map/widgets/compact_poi_card.dart';
import '../../poi/providers/poi_state_provider.dart';
import '../providers/corridor_browser_provider.dart';

/// Bottom Sheet zum Entdecken von POIs entlang der Route (TripScreen: Vollbild)
class CorridorBrowserSheet extends ConsumerStatefulWidget {
  final AppRoute route;
  final Set<String> existingStopIds;
  final Future<bool> Function(POI poi)? onAddPOI;
  final Future<bool> Function(POI poi)? onRemovePOI;
  final double initialChildSize;

  const CorridorBrowserSheet({
    super.key,
    required this.route,
    required this.existingStopIds,
    this.onAddPOI,
    this.onRemovePOI,
    this.initialChildSize = 1.0,
  });

  /// Oeffnet den Korridor-Browser als Bottom Sheet
  static void show({
    required BuildContext context,
    required AppRoute route,
    Set<String> existingStopIds = const {},
    Future<bool> Function(POI poi)? onAddPOI,
    Future<bool> Function(POI poi)? onRemovePOI,
    double initialChildSize = 1.0,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CorridorBrowserSheet(
        route: route,
        existingStopIds: existingStopIds,
        onAddPOI: onAddPOI,
        onRemovePOI: onRemovePOI,
        initialChildSize: initialChildSize,
      ),
    );
  }

  @override
  ConsumerState<CorridorBrowserSheet> createState() =>
      _CorridorBrowserSheetState();
}

class _CorridorBrowserSheetState extends ConsumerState<CorridorBrowserSheet> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: widget.initialChildSize,
      minChildSize: 0.4,
      maxChildSize: 1.0,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: widget.initialChildSize < 1.0
                ? const BorderRadius.vertical(top: Radius.circular(20))
                : null,
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag-Handle bei Partial-Height
              if (widget.initialChildSize < 1.0)
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 4),
                    width: 32,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              Expanded(
                child: CorridorBrowserContent(
                  route: widget.route,
                  existingStopIds: widget.existingStopIds,
                  onAddPOI: widget.onAddPOI,
                  onRemovePOI: widget.onRemovePOI,
                  onClose: () => Navigator.pop(context),
                  scrollController: scrollController,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Wiederverwendbarer Korridor-Browser Inhalt.
/// Wird inline im DayEditor und als Sheet-Inhalt im TripScreen genutzt.
class CorridorBrowserContent extends ConsumerStatefulWidget {
  final AppRoute route;
  final Set<String> existingStopIds;
  final Future<bool> Function(POI poi)? onAddPOI;
  final Future<bool> Function(POI poi)? onRemovePOI;
  final VoidCallback? onClose;
  final ScrollController? scrollController;

  const CorridorBrowserContent({
    super.key,
    required this.route,
    required this.existingStopIds,
    this.onAddPOI,
    this.onRemovePOI,
    this.onClose,
    this.scrollController,
  });

  @override
  ConsumerState<CorridorBrowserContent> createState() =>
      _CorridorBrowserContentState();
}

class _CorridorBrowserContentState
    extends ConsumerState<CorridorBrowserContent> {
  bool _initialLoadDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPOIs();
    });
  }

  void _loadPOIs() {
    if (_initialLoadDone) return;
    _initialLoadDone = true;
    ref.read(corridorBrowserNotifierProvider.notifier).loadCorridorPOIs(
          route: widget.route,
          existingStopIds: widget.existingStopIds,
        );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final state = ref.watch(corridorBrowserNotifierProvider);

    return Column(
      children: [
        // Header
        _buildHeader(colorScheme, state),

        Divider(
          height: 1,
          color: colorScheme.outline.withOpacity(0.15),
        ),

        // Buffer Slider
        _buildBufferSlider(colorScheme, state),

        // Kategorie-Filter
        _buildCategoryFilter(colorScheme, state),

        Divider(
          height: 1,
          color: colorScheme.outline.withOpacity(0.15),
        ),

        // POI-Liste
        Expanded(
          child: _buildPOIList(colorScheme, state),
        ),
      ],
    );
  }

  Widget _buildHeader(ColorScheme colorScheme, CorridorBrowserState state) {
    final totalCount = state.filteredPOIs.length;
    final newCount = state.newPOICount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      child: Row(
        children: [
          Icon(
            Icons.explore_rounded,
            color: colorScheme.primary,
            size: 22,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'POIs entlang der Route',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (!state.isLoading && totalCount > 0)
                  Text(
                    '$totalCount gefunden${newCount < totalCount ? ' ($newCount neu)' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: widget.onClose,
            icon: const Icon(Icons.close_rounded),
            style: IconButton.styleFrom(
              foregroundColor: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBufferSlider(
    ColorScheme colorScheme,
    CorridorBrowserState state,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label + Quick-Select
          Row(
            children: [
              Icon(
                Icons.width_normal_rounded,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                'Korridor: ${state.bufferKm.round()} km',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              // Quick-Select Buttons
              _QuickSelectChip(
                label: '20',
                isSelected: state.bufferKm == 20,
                onTap: () => _setBuffer(20),
              ),
              const SizedBox(width: 4),
              _QuickSelectChip(
                label: '50',
                isSelected: state.bufferKm == 50,
                onTap: () => _setBuffer(50),
              ),
              const SizedBox(width: 4),
              _QuickSelectChip(
                label: '100',
                isSelected: state.bufferKm == 100,
                onTap: () => _setBuffer(100),
              ),
            ],
          ),
          // Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: Slider(
              value: state.bufferKm,
              min: 10,
              max: 100,
              divisions: 18,
              onChanged: (value) {
                ref
                    .read(corridorBrowserNotifierProvider.notifier)
                    .setBufferKm(value, route: widget.route);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter(
    ColorScheme colorScheme,
    CorridorBrowserState state,
  ) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: POICategory.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final category = POICategory.values[index];
          final isSelected = state.selectedCategories.contains(category);

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                ref
                    .read(corridorBrowserNotifierProvider.notifier)
                    .toggleCategory(category);
              },
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: colorScheme.primary.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      category.icon,
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      category.label.split(' ').first,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPOIList(
    ColorScheme colorScheme,
    CorridorBrowserState state,
  ) {
    // Loading State
    if (state.isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Suche POIs im Korridor...',
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Error State
    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: colorScheme.error,
                size: 36,
              ),
              const SizedBox(height: 8),
              Text(
                state.error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: () {
                  ref
                      .read(corridorBrowserNotifierProvider.notifier)
                      .loadCorridorPOIs(
                        route: widget.route,
                        existingStopIds: widget.existingStopIds,
                      );
                },
                child: const Text('Erneut versuchen'),
              ),
            ],
          ),
        ),
      );
    }

    // Empty State
    final filteredPOIs = state.filteredPOIs;
    if (filteredPOIs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_off_rounded,
                color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                size: 40,
              ),
              const SizedBox(height: 8),
              Text(
                state.selectedCategories.isNotEmpty
                    ? 'Keine POIs in dieser Kategorie gefunden'
                    : 'Keine POIs im Korridor gefunden',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Versuche einen breiteren Korridor',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // POI-Liste
    return ListView.builder(
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      itemCount: filteredPOIs.length,
      itemBuilder: (context, index) {
        final poi = filteredPOIs[index];
        final isAdded = state.addedPOIIds.contains(poi.id);

        return CompactPOICard(
          name: poi.name,
          category: poi.category,
          detourKm: poi.detourKm != null
              ? '+${poi.detourKm!.toStringAsFixed(1)} km'
              : null,
          imageUrl: poi.imageUrl,
          isAdded: isAdded,
          onTap: () => _navigateToPOI(poi),
          onAdd: isAdded ? null : () => _addPOI(poi),
          onRemove: isAdded && widget.onRemovePOI != null
              ? () => _removePOI(poi)
              : null,
        );
      },
    );
  }

  void _setBuffer(double km) {
    ref
        .read(corridorBrowserNotifierProvider.notifier)
        .setBufferKm(km, route: widget.route);
  }

  Future<void> _addPOI(POI poi) async {
    if (widget.onAddPOI != null) {
      final success = await widget.onAddPOI!(poi);
      if (success && mounted) {
        ref
            .read(corridorBrowserNotifierProvider.notifier)
            .markAsAdded(poi.id);
      }
    } else {
      await POITripHelper.addPOIWithFeedback(
        ref: ref,
        context: context,
        poi: poi,
      );
      if (mounted) {
        ref
            .read(corridorBrowserNotifierProvider.notifier)
            .markAsAdded(poi.id);
      }
    }
  }

  Future<void> _removePOI(POI poi) async {
    if (widget.onRemovePOI == null || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Stop entfernen?'),
        content: Text('"${poi.name}" aus dem Trip entfernen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Entfernen'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final success = await widget.onRemovePOI!(poi);
    if (success && mounted) {
      ref
          .read(corridorBrowserNotifierProvider.notifier)
          .markAsRemoved(poi.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${poi.name}" entfernt'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mindestens 1 Stop pro Tag erforderlich'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _navigateToPOI(POI poi) {
    final poiNotifier = ref.read(pOIStateNotifierProvider.notifier);
    poiNotifier.addPOI(poi);
    if (poi.imageUrl == null) {
      poiNotifier.enrichPOI(poi.id);
    }
    context.push('/poi/${poi.id}');
  }
}

/// Quick-Select Chip fuer Korridor-Breite
class _QuickSelectChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _QuickSelectChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.surfaceContainerHighest.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${label}km',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? colorScheme.onPrimary
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
