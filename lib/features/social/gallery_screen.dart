import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n/l10n.dart';
import '../../data/models/public_trip.dart';
import '../../data/providers/gallery_provider.dart';
import 'widgets/public_trip_card.dart';

/// Oeffentliche Trip-Galerie
class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key});

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // Initial laden
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(galleryNotifierProvider.notifier).loadGallery();
    });

    // Infinite Scroll
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(galleryNotifierProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(galleryNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.galleryTitle),
        actions: [
          // Filter-Button
          IconButton(
            icon: Badge(
              isLabelVisible: state.hasActiveFilters,
              child: const Icon(Icons.filter_list),
            ),
            onPressed: () => _showFilterSheet(context, state),
            tooltip: context.l10n.galleryFilter,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(galleryNotifierProvider.notifier).loadGallery();
        },
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Suchleiste
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: context.l10n.gallerySearch,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: state.searchQuery != null
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              ref
                                  .read(galleryNotifierProvider.notifier)
                                  .clearSearch();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                  ),
                  onSubmitted: (query) {
                    ref.read(galleryNotifierProvider.notifier).search(query);
                  },
                ),
              ),
            ),

            // Featured Section
            if (state.featuredTrips.isNotEmpty && !state.hasActiveFilters) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        context.l10n.galleryFeatured,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 220,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: state.featuredTrips.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final trip = state.featuredTrips[index];
                      return FeaturedTripCard(
                        trip: trip,
                        onTap: () => _openTripDetail(trip),
                      );
                    },
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 16),
              ),
            ],

            // Sortierung Chips
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    Text(
                      context.l10n.galleryAllTrips,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Spacer(),
                    // Sortierung Dropdown
                    DropdownButton<GallerySortBy>(
                      value: state.sortBy,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.sort, size: 20),
                      items: GallerySortBy.values.map((sort) {
                        return DropdownMenuItem(
                          value: sort,
                          child: Text(sort.label),
                        );
                      }).toList(),
                      onChanged: (sort) {
                        if (sort != null) {
                          ref
                              .read(galleryNotifierProvider.notifier)
                              .setSortBy(sort);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Trip-Typ Filter Chips
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Wrap(
                  spacing: 8,
                  children: GalleryTripTypeFilter.values.map((filter) {
                    final isSelected = state.tripTypeFilter == filter;
                    return FilterChip(
                      label: Text(
                        filter.label,
                        style: TextStyle(
                          color: isSelected
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: colorScheme.primary,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      onSelected: (_) {
                        ref
                            .read(galleryNotifierProvider.notifier)
                            .setTripTypeFilter(filter);
                      },
                    );
                  }).toList(),
                ),
              ),
            ),

            // Loading
            if (state.isLoading && state.trips.isEmpty)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),

            // Error
            if (state.error != null && state.trips.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(state.error!),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () {
                          ref.read(galleryNotifierProvider.notifier).loadGallery();
                        },
                        child: Text(context.l10n.galleryRetry),
                      ),
                    ],
                  ),
                ),
              ),

            // Keine Ergebnisse
            if (!state.isLoading && state.trips.isEmpty && state.error == null)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 48,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        context.l10n.galleryNoTrips,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (state.hasActiveFilters) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            ref
                                .read(galleryNotifierProvider.notifier)
                                .resetFilters();
                          },
                          child: Text(context.l10n.galleryResetFilters),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

            // Trip Grid
            if (state.trips.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.7,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final trip = state.trips[index];
                      return PublicTripCard(
                        trip: trip,
                        onTap: () => _openTripDetail(trip),
                        onLike: () {
                          ref
                              .read(galleryNotifierProvider.notifier)
                              .toggleLike(trip.id);
                        },
                      );
                    },
                    childCount: state.trips.length,
                  ),
                ),
              ),

            // Loading More Indicator
            if (state.isLoadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),

            // Bottom Padding - genug Platz fuer System-Navigation
            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.of(context).padding.bottom + 100,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openTripDetail(PublicTrip trip) {
    context.push('/gallery/${trip.id}');
  }

  void _showFilterSheet(BuildContext context, GalleryState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 1.0,
        minChildSize: 0.9,
        maxChildSize: 1.0,
        expand: false,
        builder: (context, scrollController) => _FilterSheet(
          scrollController: scrollController,
        ),
      ),
    );
  }
}

/// Filter Bottom Sheet
class _FilterSheet extends ConsumerWidget {
  final ScrollController scrollController;

  const _FilterSheet({
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // State direkt aus dem Provider holen fuer sofortige Updates
    final state = ref.watch(galleryNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // Beliebte Tags (koennte spaeter aus API kommen)
    final popularTags = [
      'roadtrip',
      'natur',
      'kultur',
      'strand',
      'berge',
      'stadt',
      'familie',
      'romantik',
      'abenteuer',
      'fotografie',
    ];

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outline.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  context.l10n.galleryFilter,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                ),
                const Spacer(),
                if (state.hasActiveFilters)
                  TextButton(
                    onPressed: () {
                      ref.read(galleryNotifierProvider.notifier).resetFilters();
                      Navigator.pop(context);
                    },
                    child: Text(context.l10n.galleryFilterReset),
                  ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Content
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                // Trip-Typ
                Text(
                  context.l10n.galleryTripType,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: GalleryTripTypeFilter.values.map((filter) {
                    final isSelected = state.tripTypeFilter == filter;
                    return ChoiceChip(
                      label: Text(
                        filter.label,
                        style: TextStyle(
                          color: isSelected
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: colorScheme.primary,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      onSelected: (_) {
                        ref
                            .read(galleryNotifierProvider.notifier)
                            .setTripTypeFilter(filter);
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // Tags
                Text(
                  context.l10n.galleryTags,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: popularTags.map((tag) {
                    final isSelected = state.selectedTags.contains(tag);
                    return FilterChip(
                      label: Text(
                        '#$tag',
                        style: TextStyle(
                          color: isSelected
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: colorScheme.primary,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      onSelected: (_) {
                        ref.read(galleryNotifierProvider.notifier).toggleTag(tag);
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // Sortierung
                Text(
                  context.l10n.gallerySort,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                ),
                const SizedBox(height: 8),
                ...GallerySortBy.values.map((sort) {
                  return RadioListTile<GallerySortBy>(
                    title: Text(
                      sort.label,
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
                    value: sort,
                    groupValue: state.sortBy,
                    onChanged: (value) {
                      if (value != null) {
                        ref
                            .read(galleryNotifierProvider.notifier)
                            .setSortBy(value);
                      }
                    },
                    contentPadding: EdgeInsets.zero,
                  );
                }),
              ],
            ),
          ),

          // Apply Button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(context.l10n.apply),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
