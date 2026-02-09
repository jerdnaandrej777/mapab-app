import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n/l10n.dart';
import '../../data/models/public_poi_post.dart';
import '../../data/providers/poi_gallery_provider.dart';
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
  int _selectedFeed = 0; // 0 = trips, 1 = pois

  @override
  void initState() {
    super.initState();

    // Initial laden
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(galleryNotifierProvider.notifier).loadGallery();
      ref.read(poiGalleryNotifierProvider.notifier).load();
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
      if (_selectedFeed == 0) {
        ref.read(galleryNotifierProvider.notifier).loadMore();
      } else {
        ref.read(poiGalleryNotifierProvider.notifier).loadMore();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(galleryNotifierProvider);
    final poiState = ref.watch(poiGalleryNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.galleryTitle),
        actions: [
          // Filter-Button
          if (_selectedFeed == 0)
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
          if (_selectedFeed == 0) {
            await ref.read(galleryNotifierProvider.notifier).loadGallery();
          } else {
            await ref.read(poiGalleryNotifierProvider.notifier).load();
          }
        },
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: SegmentedButton<int>(
                  segments: [
                    ButtonSegment<int>(
                      value: 0,
                      label: Text(context.l10n.profileTrips),
                      icon: const Icon(Icons.route),
                    ),
                    ButtonSegment<int>(
                      value: 1,
                      label: Text(context.l10n.profilePois),
                      icon: const Icon(Icons.place),
                    ),
                  ],
                  selected: {_selectedFeed},
                  onSelectionChanged: (value) {
                    if (value.isEmpty) return;
                    setState(() => _selectedFeed = value.first);
                  },
                ),
              ),
            ),
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
                    if (_selectedFeed == 0) {
                      ref.read(galleryNotifierProvider.notifier).search(query);
                    } else {
                      ref.read(poiGalleryNotifierProvider.notifier).setSearch(
                          query.trim().isEmpty ? null : query.trim());
                    }
                  },
                ),
              ),
            ),

            if (_selectedFeed == 1)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        label: Text(
                          context.l10n.poiOnlyMustSee,
                          style: TextStyle(
                            color: poiState.mustSeeOnly
                                ? colorScheme.onPrimary
                                : colorScheme.onSurface,
                          ),
                        ),
                        selected: poiState.mustSeeOnly,
                        selectedColor: colorScheme.primary,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        onSelected: (_) => ref
                            .read(poiGalleryNotifierProvider.notifier)
                            .toggleMustSee(),
                      ),
                      ChoiceChip(
                        label: Text(
                          'Top bewertet',
                          style: TextStyle(
                            color: poiState.sortBy == 'top_rated'
                                ? colorScheme.onPrimary
                                : colorScheme.onSurface,
                          ),
                        ),
                        selected: poiState.sortBy == 'top_rated',
                        selectedColor: colorScheme.primary,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        onSelected: (_) => ref
                            .read(poiGalleryNotifierProvider.notifier)
                            .setSort('top_rated'),
                      ),
                      ChoiceChip(
                        label: Text(
                          context.l10n.gallerySortRecent,
                          style: TextStyle(
                            color: poiState.sortBy == 'recent'
                                ? colorScheme.onPrimary
                                : colorScheme.onSurface,
                          ),
                        ),
                        selected: poiState.sortBy == 'recent',
                        selectedColor: colorScheme.primary,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        onSelected: (_) => ref
                            .read(poiGalleryNotifierProvider.notifier)
                            .setSort('recent'),
                      ),
                      ChoiceChip(
                        label: Text(
                          context.l10n.gallerySortPopular,
                          style: TextStyle(
                            color: poiState.sortBy == 'trending'
                                ? colorScheme.onPrimary
                                : colorScheme.onSurface,
                          ),
                        ),
                        selected: poiState.sortBy == 'trending',
                        selectedColor: colorScheme.primary,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        onSelected: (_) => ref
                            .read(poiGalleryNotifierProvider.notifier)
                            .setSort('trending'),
                      ),
                      ...const [
                        'nature',
                        'museum',
                        'viewpoint',
                        'city',
                        'attraction',
                      ].map((cat) {
                        final selected = poiState.categories.contains(cat);
                        return FilterChip(
                          label: Text(
                            cat,
                            style: TextStyle(
                              color: selected
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurface,
                            ),
                          ),
                          selected: selected,
                          selectedColor: colorScheme.primary,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          onSelected: (_) => ref
                              .read(poiGalleryNotifierProvider.notifier)
                              .toggleCategory(cat),
                        );
                      }),
                    ],
                  ),
                ),
              ),

            // Featured Section
            if (_selectedFeed == 0 &&
                state.featuredTrips.isNotEmpty &&
                !state.hasActiveFilters) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        context.l10n.galleryFeatured,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
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
            if (_selectedFeed == 0)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      Text(
                        context.l10n.galleryAllTrips,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
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
            if (_selectedFeed == 0)
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
            if (_selectedFeed == 0 && state.isLoading && state.trips.isEmpty)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
            if (_selectedFeed == 1 &&
                poiState.isLoading &&
                poiState.items.isEmpty)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),

            // Error
            if (_selectedFeed == 0 &&
                state.error != null &&
                state.trips.isEmpty)
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
                          ref
                              .read(galleryNotifierProvider.notifier)
                              .loadGallery();
                        },
                        child: Text(context.l10n.galleryRetry),
                      ),
                    ],
                  ),
                ),
              ),
            if (_selectedFeed == 1 &&
                poiState.error != null &&
                poiState.items.isEmpty)
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
                      Text(poiState.error!),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () {
                          ref.read(poiGalleryNotifierProvider.notifier).load();
                        },
                        child: Text(context.l10n.galleryRetry),
                      ),
                    ],
                  ),
                ),
              ),

            // Keine Ergebnisse
            if (_selectedFeed == 0 &&
                !state.isLoading &&
                state.trips.isEmpty &&
                state.error == null)
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
            if (_selectedFeed == 1 &&
                !poiState.isLoading &&
                poiState.items.isEmpty &&
                poiState.error == null)
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
                        context.l10n.poiNoResultsNearby,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),

            // Trip Grid
            if (_selectedFeed == 0 && state.trips.isNotEmpty)
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
            if (_selectedFeed == 1 && poiState.items.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final post = poiState.items[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _PublicPoiCard(
                          post: post,
                          onLike: () => ref
                              .read(poiGalleryNotifierProvider.notifier)
                              .toggleLike(post.id),
                          onVoteUp: () => ref
                              .read(poiGalleryNotifierProvider.notifier)
                              .vote(post.id, 1),
                          onVoteDown: () => ref
                              .read(poiGalleryNotifierProvider.notifier)
                              .vote(post.id, -1),
                          onOpen: () => context.push('/poi/${post.poiId}'),
                        ),
                      );
                    },
                    childCount: poiState.items.length,
                  ),
                ),
              ),

            // Loading More Indicator
            if ((_selectedFeed == 0 && state.isLoadingMore) ||
                (_selectedFeed == 1 && poiState.isLoadingMore))
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
                        ref
                            .read(galleryNotifierProvider.notifier)
                            .toggleTag(tag);
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

class _PublicPoiCard extends StatelessWidget {
  const _PublicPoiCard({
    required this.post,
    required this.onLike,
    required this.onVoteUp,
    required this.onVoteDown,
    required this.onOpen,
  });

  final PublicPoiPost post;
  final VoidCallback onLike;
  final VoidCallback onVoteUp;
  final VoidCallback onVoteDown;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      post.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (post.isMustSee)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        context.l10n.poiOnlyMustSee,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              if (post.content != null && post.content!.isNotEmpty)
                Text(
                  post.content!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _chip('Rating ${post.ratingAvg?.toStringAsFixed(1) ?? '-'}'),
                  _chip('Votes ${post.voteScore}'),
                  _chip('Comments ${post.commentCount}'),
                  _chip('Photos ${post.photoCount}'),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    post.authorName ?? 'Community',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: onVoteDown,
                    icon: const Icon(Icons.arrow_downward_rounded),
                  ),
                  Text(
                    '${post.voteScore}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  IconButton(
                    onPressed: onVoteUp,
                    icon: const Icon(Icons.arrow_upward_rounded),
                  ),
                  IconButton(
                    onPressed: onLike,
                    icon: Icon(
                      post.isLikedByMe ? Icons.favorite : Icons.favorite_border,
                      color: post.isLikedByMe ? Colors.red : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
