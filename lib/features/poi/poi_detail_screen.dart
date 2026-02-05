import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/utils/location_helper.dart';
import '../../core/l10n/l10n.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/categories.dart';
import '../../core/utils/url_utils.dart';
import '../../data/models/poi.dart';
import '../../data/models/route.dart';
import '../../data/providers/favorites_provider.dart';
import '../random_trip/providers/random_trip_provider.dart';
import '../random_trip/providers/random_trip_state.dart';
import '../trip/providers/trip_state_provider.dart';
import 'providers/poi_state_provider.dart';

/// POI-Detail-Screen mit dynamischen Daten
class POIDetailScreen extends ConsumerStatefulWidget {
  final String poiId;

  const POIDetailScreen({super.key, required this.poiId});

  @override
  ConsumerState<POIDetailScreen> createState() => _POIDetailScreenState();
}

class _POIDetailScreenState extends ConsumerState<POIDetailScreen> {
  /// Optimistisches UI-Update für Favoriten-Button
  /// null = Provider-Wert nutzen, true/false = optimistischer Wert
  bool? _optimisticFavorite;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAndEnrichPOI();
    });
  }

  Future<void> _loadAndEnrichPOI() async {
    final notifier = ref.read(pOIStateNotifierProvider.notifier);

    // POI auswählen
    try {
      notifier.selectPOIById(widget.poiId);

      // FIX v1.6.7: Enrichment BLOCKIEREND warten
      // Vorher: unawaited → UI zeigte ungereichterten POI (ohne Foto/Highlights)
      // Nachher: await → UI zeigt Loading, dann vollständige Daten
      final state = ref.read(pOIStateNotifierProvider);
      if (state.selectedPOI != null && !state.selectedPOI!.isEnriched) {
        await notifier.enrichPOI(widget.poiId);
      }
    } catch (e) {
      debugPrint('[POIDetail] POI nicht gefunden: ${widget.poiId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final poiState = ref.watch(pOIStateNotifierProvider);
    final poi = poiState.selectedPOI;

    // Loading oder POI nicht gefunden
    if (poi == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: poiState.isLoading
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                    const SizedBox(height: 16),
                    Text(context.l10n.poiNotFound),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => context.pop(),
                      child: Text(context.l10n.back),
                    ),
                  ],
                ),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar mit Bild
          _buildSliverAppBar(poi, colorScheme),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name & Kategorie
                  _buildHeader(poi, theme, colorScheme),

                  const SizedBox(height: 16),

                  // Bewertung
                  _buildRatingSection(poi, theme, colorScheme),

                  const SizedBox(height: 24),

                  // Route-Info (wenn verfügbar)
                  if (poi.detourKm != null) ...[
                    _buildRouteInfoSection(poi, colorScheme),
                    const SizedBox(height: 24),
                  ],

                  // Beschreibung
                  _buildDescriptionSection(poi, theme, colorScheme),

                  const SizedBox(height: 24),

                  // Kontakt-Info
                  _buildContactSection(poi, theme, colorScheme),

                  const SizedBox(height: 100), // Space für FAB
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addToTrip(poi),
        icon: const Icon(Icons.add),
        label: Text(context.l10n.poiAddToRoute),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildSliverAppBar(POI poi, ColorScheme colorScheme) {
    // Favoriten-Status überwachen (Provider-Wert)
    final providerFavorite = ref.watch(isPOIFavoriteProvider(poi.id));
    // Effektiver Wert: Optimistischer Wert hat Priorität
    final isFavorite = _optimisticFavorite ?? providerFavorite;

    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.arrow_back, color: colorScheme.onSurface),
        ),
        onPressed: () => context.pop(),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : colorScheme.onSurface,
            ),
          ),
          onPressed: () async {
            // Sofortiges optimistisches UI-Update
            final newFavoriteState = !isFavorite;
            setState(() {
              _optimisticFavorite = newFavoriteState;
            });

            // Async Favoriten-Toggle
            final notifier = ref.read(favoritesNotifierProvider.notifier);
            await notifier.togglePOI(poi);

            // Nach dem Toggle: Optimistischen Wert zurücksetzen (Provider übernimmt)
            if (mounted) {
              setState(() {
                _optimisticFavorite = null;
              });
            }
          },
        ),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.share, color: colorScheme.onSurface),
          ),
          onPressed: () {
            final mapsUrl =
                'https://www.google.com/maps/search/?api=1&query=${poi.latitude},${poi.longitude}';
            Share.share(
              '${poi.name}\n$mapsUrl',
              subject: poi.name,
            );
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Bild oder Placeholder
            poi.imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: poi.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => _buildImagePlaceholder(poi),
                    errorWidget: (context, url, error) => _buildImagePlaceholder(poi),
                  )
                : _buildImagePlaceholder(poi),

            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.5),
                  ],
                ),
              ),
            ),

            // Enrichment Loading Indicator
            if (ref.watch(pOIStateNotifierProvider).isEnriching)
              Positioned(
                bottom: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      Text(context.l10n.poiLoadingDetails, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder(POI poi) {
    final category = poi.category ?? POICategory.attraction;
    return Container(
      color: Color(category.colorValue).withValues(alpha: 0.3),
      child: Center(
        child: Text(
          category.icon,
          style: const TextStyle(fontSize: 80),
        ),
      ),
    );
  }

  Widget _buildHeader(POI poi, ThemeData theme, ColorScheme colorScheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                poi.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    '${poi.categoryIcon} ${poi.categoryLabel}',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Highlight Badges
                  ...poi.highlights.take(2).map((h) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Color(h.colorValue),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(h.icon, style: const TextStyle(fontSize: 10)),
                              const SizedBox(width: 4),
                              Text(
                                h.label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
                ],
              ),
              // Gründungsjahr und Architekturstil
              if (poi.foundedYear != null || poi.architectureStyle != null) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    if (poi.foundedYear != null)
                      Chip(
                        label: Text(context.l10n.poiFoundedYear(poi.foundedYear!)),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.zero,
                        labelStyle: const TextStyle(fontSize: 12),
                      ),
                    if (poi.architectureStyle != null)
                      Chip(
                        label: Text(poi.architectureStyle!),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.zero,
                        labelStyle: const TextStyle(fontSize: 12),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRatingSection(POI poi, ThemeData theme, ColorScheme colorScheme) {
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Sterne
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: List.generate(5, (index) {
                  if (index < poi.starRating.floor()) {
                    return const Icon(Icons.star, size: 20, color: Colors.amber);
                  } else if (index < poi.starRating) {
                    return const Icon(Icons.star_half, size: 20, color: Colors.amber);
                  }
                  return Icon(Icons.star_border, size: 20,
                      color: isDark ? Colors.grey.shade600 : Colors.grey.shade300);
                }),
              ),
              const SizedBox(height: 4),
              Text(
                context.l10n.poiRating(poi.starRating.toStringAsFixed(1), poi.reviewCount),
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Verifiziert Badge
          if (poi.isCurated || poi.hasWikidataData)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified, size: 16, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    poi.isCurated ? context.l10n.poiCurated : context.l10n.poiVerified,
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRouteInfoSection(POI poi, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          _buildInfoItem(
            icon: Icons.route,
            label: context.l10n.poiDetour,
            value: '+${poi.detourKm!.toStringAsFixed(1)} km',
            colorScheme: colorScheme,
          ),
          Container(
            width: 1,
            height: 40,
            color: colorScheme.primary.withValues(alpha: 0.2),
          ),
          _buildInfoItem(
            icon: Icons.timer,
            label: context.l10n.poiTime,
            value: '+${poi.detourMinutes ?? 0} Min.',
            colorScheme: colorScheme,
          ),
          Container(
            width: 1,
            height: 40,
            color: colorScheme.primary.withValues(alpha: 0.2),
          ),
          _buildInfoItem(
            icon: Icons.place,
            label: context.l10n.poiPosition,
            value: '${((poi.routePosition ?? 0) * 100).round()}%',
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required ColorScheme colorScheme,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: colorScheme.primary, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection(POI poi, ThemeData theme, ColorScheme colorScheme) {
    final description = poi.description ?? poi.wikidataDescription;
    final hasDescription = description != null && description.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.poiAboutPlace,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        if (hasDescription)
          Text(
            description!,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          )
        else if (ref.watch(pOIStateNotifierProvider).isEnriching)
          Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 8),
              Text(
                context.l10n.poiDescriptionLoading,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          )
        else
          Text(
            context.l10n.poiNoDescription,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),

        // Wikipedia Link
        if (poi.hasWikipedia && poi.wikipediaTitle != null) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _openWikipedia(poi.wikipediaTitle!),
            icon: const Icon(Icons.open_in_new, size: 18),
            label: Text(context.l10n.poiMoreOnWikipedia),
          ),
        ],
      ],
    );
  }

  Widget _buildContactSection(POI poi, ThemeData theme, ColorScheme colorScheme) {
    final hasContact = poi.openingHours != null ||
        poi.phone != null ||
        poi.website != null ||
        poi.email != null;

    if (!hasContact) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.poiContactInfo,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        if (poi.openingHours != null)
          _buildContactTile(
            icon: Icons.access_time,
            title: context.l10n.poiOpeningHours,
            subtitle: poi.openingHours!,
            colorScheme: colorScheme,
          ),
        if (poi.phone != null)
          _buildContactTile(
            icon: Icons.phone,
            title: context.l10n.poiPhone,
            subtitle: poi.phone!,
            colorScheme: colorScheme,
            onTap: () => launchUrlSafe(Uri.parse('tel:${poi.phone}')),
          ),
        if (poi.website != null)
          _buildContactTile(
            icon: Icons.language,
            title: context.l10n.poiWebsite,
            subtitle: _formatWebsite(poi.website!),
            colorScheme: colorScheme,
            onTap: () => launchUrlSafe(Uri.parse(poi.website!)),
          ),
        if (poi.email != null)
          _buildContactTile(
            icon: Icons.email,
            title: context.l10n.poiEmailLabel,
            subtitle: poi.email!,
            colorScheme: colorScheme,
            onTap: () => launchUrlSafe(Uri.parse('mailto:${poi.email}')),
          ),
      ],
    );
  }

  Widget _buildContactTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required ColorScheme colorScheme,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: colorScheme.primary, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 12,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
      trailing: onTap != null
          ? Icon(Icons.open_in_new, size: 18, color: colorScheme.onSurfaceVariant)
          : null,
      onTap: onTap,
    );
  }

  String _formatWebsite(String url) {
    return url
        .replaceFirst(RegExp(r'^https?://'), '')
        .replaceFirst(RegExp(r'^www\.'), '')
        .replaceFirst(RegExp(r'/$'), '');
  }

  void _openWikipedia(String title) {
    final url = 'https://de.wikipedia.org/wiki/${Uri.encodeComponent(title)}';
    launchUrlSafe(Uri.parse(url));
  }

  Future<void> _addToTrip(POI poi) async {
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
      } else {
        // Stop zur bestehenden Route hinzugefügt
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.poiAddedToRoute(poi.name)),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
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

  /// GPS-Dialog anzeigen - nutzt zentralisierten LocationHelper (v1.9.29)
  Future<bool> _showGpsDialog() async {
    return LocationHelper.showGpsDialog(context);
  }
}
