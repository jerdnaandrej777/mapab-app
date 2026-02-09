import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/constants/categories.dart';
import '../../core/l10n/l10n.dart';
import '../../core/utils/geo_utils.dart';
import '../../core/utils/location_helper.dart';
import '../../data/models/poi.dart';
import '../../data/models/public_trip.dart';
import '../../data/models/route.dart';
import '../../data/models/trip.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/favorites_provider.dart';
import '../../data/providers/gallery_provider.dart';
import '../../data/repositories/routing_repo.dart';
import '../../data/services/sharing_service.dart';
import '../../shared/widgets/app_snackbar.dart';
import '../map/providers/map_controller_provider.dart';
import '../map/providers/route_planner_provider.dart';
import '../poi/providers/poi_state_provider.dart';
import '../poi/widgets/poi_comments_section.dart';
import '../random_trip/providers/random_trip_provider.dart';
import '../trip/providers/trip_state_provider.dart';
import 'widgets/trip_photo_gallery.dart';

/// Detail-Ansicht fuer einen oeffentlichen Trip
class TripDetailPublicScreen extends ConsumerStatefulWidget {
  final String tripId;

  const TripDetailPublicScreen({
    super.key,
    required this.tripId,
  });

  @override
  ConsumerState<TripDetailPublicScreen> createState() =>
      _TripDetailPublicScreenState();
}

class _TripDetailPublicScreenState
    extends ConsumerState<TripDetailPublicScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tripDetailNotifierProvider(widget.tripId).notifier).loadTrip();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tripDetailNotifierProvider(widget.tripId));
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? _buildError(state.error!, colorScheme)
              : state.trip != null
                  ? _buildContent(state.trip!, colorScheme, textTheme)
                  : const SizedBox(),
      bottomNavigationBar:
          state.trip != null ? _buildBottomBar(state.trip!, colorScheme) : null,
    );
  }

  Widget _buildError(String error, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: colorScheme.error),
          const SizedBox(height: 16),
          Text(error),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              ref
                  .read(tripDetailNotifierProvider(widget.tripId).notifier)
                  .loadTrip();
            },
            child: Text(context.l10n.galleryRetry),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    PublicTrip trip,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final authState = ref.watch(authNotifierProvider);
    final isOwnTrip = authState.user?.id == trip.userId;

    return CustomScrollView(
      slivers: [
        // Hero Image + AppBar
        SliverAppBar(
          expandedHeight: 250,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                if (trip.thumbnailUrl != null)
                  CachedNetworkImage(
                    imageUrl: trip.thumbnailUrl!,
                    fit: BoxFit.cover,
                  )
                else
                  Container(
                    color: colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.map_outlined,
                      size: 64,
                      color:
                          colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ),
                // Gradient Overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            if (isOwnTrip)
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _editTrip(trip);
                  } else if (value == 'delete') {
                    _deleteTrip();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: Text('Trip bearbeiten'),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Trip loeschen'),
                  ),
                ],
              ),
            // Like Button
            IconButton(
              icon: Icon(
                trip.isLikedByMe ? Icons.favorite : Icons.favorite_border,
                color: trip.isLikedByMe ? Colors.redAccent : null,
              ),
              onPressed: () {
                ref
                    .read(tripDetailNotifierProvider(widget.tripId).notifier)
                    .toggleLike();
              },
            ),
            // Share Button
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => _shareTrip(trip),
            ),
          ],
        ),

        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titel + Badges
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        trip.tripName,
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (trip.isFeatured)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star,
                                size: 16, color: Colors.black87),
                            const SizedBox(width: 4),
                            Text(
                              context.l10n.galleryFeatured,
                              style: textTheme.labelSmall?.copyWith(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 8),

                // Statistiken
                Wrap(
                  spacing: 16,
                  children: [
                    _StatChip(
                      icon: Icons.route,
                      label: trip.formattedDistance,
                    ),
                    _StatChip(
                      icon: Icons.place,
                      label: '${trip.stopCount} Stops',
                    ),
                    if (trip.dayCount > 1)
                      _StatChip(
                        icon: Icons.calendar_today,
                        label: '${trip.dayCount} Tage',
                      ),
                    _StatChip(
                      icon: Icons.favorite,
                      label: '${trip.likesCount}',
                    ),
                    _StatChip(
                      icon: Icons.visibility,
                      label: '${trip.viewsCount}',
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Trip-Typ Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    trip.isEuroTrip
                        ? context.l10n.publishEuroTrip
                        : context.l10n.publishDaytrip,
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                // Beschreibung
                if (trip.description != null &&
                    trip.description!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    trip.description!,
                    style: textTheme.bodyMedium,
                  ),
                ],

                // Tags
                if (trip.tags.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: trip.tags.map((tag) {
                      return Chip(
                        label: Text('#$tag'),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 24),

                // Author Section
                if (trip.hasAuthorInfo) ...[
                  const Divider(),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () => _openAuthorProfile(trip.userId),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: colorScheme.primaryContainer,
                            backgroundImage: trip.authorAvatar != null
                                ? CachedNetworkImageProvider(trip.authorAvatar!)
                                : null,
                            child: trip.authorAvatar == null
                                ? Icon(
                                    Icons.person,
                                    color: colorScheme.onPrimaryContainer,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  trip.authorName!,
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (trip.authorTotalTrips != null)
                                  Text(
                                    '${trip.authorTotalTrips} Trips geteilt',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Region Info
                if (trip.region != null || trip.countryCode != null) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 18,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        [trip.region, trip.countryCode]
                            .where((e) => e != null)
                            .join(', '),
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Erstellt am
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Geteilt am ${_formatDate(trip.createdAt)}',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),

                // Foto-Galerie
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                _buildPoiPreviewSection(trip),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                _buildPhotoGallery(trip),

                // Kommentar-Sektion
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                TripCommentsSection(tripId: trip.id),
              ],
            ),
          ),
        ),

        // Bottom Padding
        const SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),
      ],
    );
  }

  /// Foto-Galerie mit Prüfung ob eigener Trip
  Widget _buildPhotoGallery(PublicTrip trip) {
    final authState = ref.watch(authNotifierProvider);
    final isOwnTrip = authState.user?.id == trip.userId;

    return TripPhotoGallery(
      tripId: trip.id,
      isOwnTrip: isOwnTrip,
    );
  }

  Widget _buildPoiPreviewSection(PublicTrip trip) {
    final stops = _extractTripStops(trip.tripData)
        .where((s) => _stopCategoryId(s) != 'hotel')
        .toList();
    if (stops.isEmpty) return const SizedBox.shrink();

    final byCategory = <String, List<Map<String, dynamic>>>{};
    for (final stop in stops) {
      final category = _stopCategoryId(stop);
      byCategory.putIfAbsent(category, () => []).add(stop);
    }

    final mustSee = stops.where(_stopIsMustSee).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'POI-Vorschau',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Nach Kategorien organisiert',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (mustSee.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Must-See',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          ...mustSee.take(3).map(_buildPoiMiniTile),
        ],
        const SizedBox(height: 12),
        ...byCategory.entries.map((entry) {
          return ExpansionTile(
            title: Text('${entry.key} (${entry.value.length})'),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            children: entry.value.take(6).map(_buildPoiMiniTile).toList(),
          );
        }),
      ],
    );
  }

  Widget _buildPoiMiniTile(Map<String, dynamic> stop) {
    final poiId = stop['poiId']?.toString();
    final name = (stop['name'] ?? 'POI').toString();
    final category = _stopCategoryId(stop);
    final score = _asDouble(stop['score']);
    final isMustSee = _stopIsMustSee(stop);

    final subtitleParts = <String>[category];
    if (score != null) {
      subtitleParts.add('Score ${score.toStringAsFixed(0)}');
    }
    final highlights = _stopHighlightLabels(stop);
    if (highlights.isNotEmpty) {
      subtitleParts.add(highlights.take(2).join(', '));
    }
    if (isMustSee) {
      subtitleParts.add('Must-See');
    }

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.place_outlined),
      title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        subtitleParts.join(' - '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.navigation_rounded),
        tooltip: 'Ab Standort starten',
        onPressed: _poiFromStop(stop) == null
            ? null
            : () => _startPoiFromCurrentLocation(stop),
      ),
      onTap: poiId == null ? null : () => _openPOIDetailFromStop(stop),
    );
  }

  Widget _buildBottomBar(PublicTrip trip, ColorScheme colorScheme) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // Import Button
                Expanded(
                  child: FilledButton.icon(
                    onPressed:
                        trip.isImportedByMe ? null : () => _importTrip(trip),
                    icon: Icon(
                      trip.isImportedByMe ? Icons.check : Icons.download,
                    ),
                    label: Text(
                      trip.isImportedByMe
                          ? 'Importiert'
                          : context.l10n.galleryImportToFavorites,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Auf Karte anzeigen
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showOnMap(trip),
                    icon: const Icon(Icons.map),
                    label: Text(context.l10n.galleryShowOnMap),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: () => _startTripFromCurrentLocation(trip),
                icon: const Icon(Icons.navigation_rounded),
                label: const Text('Ab Standort starten'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// v1.10.23: Zeigt Share-Optionen für den Trip
  void _shareTrip(PublicTrip trip) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 1.0,
        minChildSize: 0.9,
        maxChildSize: 1.0,
        expand: false,
        builder: (context, scrollController) {
          final colorScheme = Theme.of(context).colorScheme;
          return Container(
            padding: const EdgeInsets.all(16),
            child: ListView(
              controller: scrollController,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color:
                          colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Titel
                Text(
                  context.l10n.shareViaApp,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Share-Optionen
                ListTile(
                  leading:
                      Icon(Icons.share_outlined, color: colorScheme.primary),
                  title: Text(context.l10n.shareViaApp),
                  subtitle: Text(context.l10n.shareViaAppDesc),
                  onTap: () async {
                    Navigator.pop(context);
                    await sharePublicTrip(
                      tripId: trip.id,
                      tripName: trip.tripName,
                      description: trip.description,
                      stopCount: trip.stopCount,
                      distanceKm: trip.distanceKm,
                    );
                  },
                ),

                ListTile(
                  leading:
                      Icon(Icons.link_outlined, color: colorScheme.primary),
                  title: Text(context.l10n.copyLink),
                  subtitle: Text(context.l10n.copyLinkDesc),
                  onTap: () async {
                    Navigator.pop(context);
                    await copyPublicTripLink(trip.id);
                    if (mounted) {
                      AppSnackbar.showSuccess(context, context.l10n.linkCopied);
                    }
                  },
                ),

                ListTile(
                  leading:
                      Icon(Icons.qr_code_outlined, color: colorScheme.primary),
                  title: Text(context.l10n.showQrCode),
                  subtitle: Text(context.l10n.showQrCodeDesc),
                  onTap: () {
                    Navigator.pop(context);
                    _showQRCode(trip);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// v1.10.23: Zeigt QR-Code für den Trip
  void _showQRCode(PublicTrip trip) {
    final qrData = generatePublicTripQRData(trip.id);
    showDialog(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return AlertDialog(
          title: Text(trip.tripName, textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 180,
                  eyeStyle: QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: colorScheme.primary,
                  ),
                  dataModuleStyle: QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.qrCodeHint,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              SelectableText(
                qrData,
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: qrData));
                Navigator.pop(context);
                AppSnackbar.showSuccess(context, context.l10n.linkCopied);
              },
              child: Text(context.l10n.copyLink),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.close),
            ),
          ],
        );
      },
    );
  }

  void _openAuthorProfile(String userId) {
    context.push('/profile/$userId');
  }

  Future<void> _importTrip(PublicTrip trip) async {
    final importedTripData = await ref
        .read(tripDetailNotifierProvider(widget.tripId).notifier)
        .importTrip();

    if (!mounted) return;

    if (importedTripData == null) {
      AppSnackbar.showError(context, context.l10n.galleryImportError);
      return;
    }

    final resolvedTripData = _resolveTripData(
      trip: trip,
      importedTripData: importedTripData,
    );
    if (resolvedTripData == null) {
      AppSnackbar.showError(context, context.l10n.galleryImportError);
      return;
    }

    final parsedTrip = _extractRouteAndStopsFromTripData(
      trip: trip,
      tripData: resolvedTripData,
    );
    if (parsedTrip == null) {
      AppSnackbar.showError(context, context.l10n.galleryImportError);
      return;
    }

    final favoriteTrip = _buildFavoriteTrip(
      trip: trip,
      route: parsedTrip.route,
      stops: parsedTrip.stops,
      tripData: resolvedTripData,
    );

    await ref.read(favoritesNotifierProvider.notifier).saveRoute(favoriteTrip);
    if (!mounted) return;

    AppSnackbar.showSuccess(context, context.l10n.galleryImportSuccess);
  }

  void _showOnMap(PublicTrip trip) {
    final tripData = _resolveTripData(trip: trip);
    if (tripData == null) {
      AppSnackbar.showError(context, context.l10n.galleryMapNoData);
      return;
    }

    try {
      final parsedTrip = _extractRouteAndStopsFromTripData(
        trip: trip,
        tripData: tripData,
      );
      if (parsedTrip == null) {
        AppSnackbar.showError(context, context.l10n.galleryMapNoData);
        return;
      }

      final stops =
          parsedTrip.stops.map(_poiFromStop).whereType<POI>().toList();

      // Reset stale planning/AI state so gallery trip + POIs are rendered.
      ref.read(routePlannerProvider.notifier).clearRoute();
      ref.read(randomTripNotifierProvider.notifier).reset();

      // In tripStateProvider laden
      ref
          .read(tripStateProvider.notifier)
          .setRouteAndStops(parsedTrip.route, stops);

      // Flag setzen für Auto-Zoom
      ref.read(shouldFitToRouteProvider.notifier).state = true;
      ref.read(mapRouteFocusModeProvider.notifier).state = true;

      debugPrint(
          '[TripDetail] Route auf Karte geladen: ${parsedTrip.route.distanceKm.toStringAsFixed(1)} km, ${stops.length} Stops');

      // Zur Karte navigieren
      context.go('/');
    } catch (e) {
      debugPrint('[TripDetail] Fehler beim Anzeigen auf Karte: $e');
      AppSnackbar.showError(context, context.l10n.galleryMapError);
    }
  }

  Future<void> _startTripFromCurrentLocation(PublicTrip trip) async {
    final tripData = _resolveTripData(trip: trip);
    if (tripData == null) {
      AppSnackbar.showError(context, context.l10n.galleryMapNoData);
      return;
    }

    final parsedTrip = _extractRouteAndStopsFromTripData(
      trip: trip,
      tripData: tripData,
    );
    if (parsedTrip == null) {
      AppSnackbar.showError(context, context.l10n.galleryMapNoData);
      return;
    }

    final locationResult = await LocationHelper.getCurrentPosition();
    if (!mounted) return;

    if (!locationResult.isSuccess) {
      await _handleLocationFailure(locationResult);
      return;
    }

    final currentLocation = locationResult.position!;
    var routeToLoad = parsedTrip.route;

    final distanceToStart =
        GeoUtils.haversineDistance(currentLocation, parsedTrip.route.start);

    if (distanceToStart > 0.05) {
      try {
        final connectorRoute =
            await ref.read(routingRepositoryProvider).calculateFastRoute(
                  start: currentLocation,
                  end: parsedTrip.route.start,
                  startAddress: 'Mein Standort',
                  endAddress: parsedTrip.route.startAddress,
                );

        final mergedCoordinates = <LatLng>[...connectorRoute.coordinates];
        if (parsedTrip.route.coordinates.isNotEmpty) {
          final shouldSkipFirstPoint = mergedCoordinates.isNotEmpty &&
              GeoUtils.haversineDistance(
                    mergedCoordinates.last,
                    parsedTrip.route.coordinates.first,
                  ) <=
                  0.05;

          mergedCoordinates.addAll(
            shouldSkipFirstPoint
                ? parsedTrip.route.coordinates.skip(1)
                : parsedTrip.route.coordinates,
          );
        }

        routeToLoad = parsedTrip.route.copyWith(
          start: currentLocation,
          startAddress: 'Mein Standort',
          coordinates: mergedCoordinates,
          distanceKm: connectorRoute.distanceKm + parsedTrip.route.distanceKm,
          durationMinutes:
              connectorRoute.durationMinutes + parsedTrip.route.durationMinutes,
          calculatedAt: DateTime.now(),
        );
      } catch (e) {
        debugPrint('[TripDetail] Fehler beim Starten ab Standort: $e');
        if (mounted) {
          AppSnackbar.showError(context, context.l10n.galleryMapError);
        }
        return;
      }
    }

    final stops = parsedTrip.stops.map(_poiFromStop).whereType<POI>().toList();

    // Reset stale planning/AI state before opening a published trip.
    ref.read(routePlannerProvider.notifier).clearRoute();
    ref.read(randomTripNotifierProvider.notifier).reset();

    ref.read(tripStateProvider.notifier).setRouteAndStops(routeToLoad, stops);
    ref.read(shouldFitToRouteProvider.notifier).state = true;

    if (!mounted) return;
    context.go('/trip');
  }

  Future<void> _startPoiFromCurrentLocation(Map<String, dynamic> stop) async {
    final poi = _poiFromStop(stop);
    if (poi == null) {
      AppSnackbar.showError(context, context.l10n.galleryMapError);
      return;
    }

    ref.read(routePlannerProvider.notifier).clearRoute();
    ref.read(randomTripNotifierProvider.notifier).reset();
    final tripNotifier = ref.read(tripStateProvider.notifier);
    tripNotifier.clearAll();

    final result = await tripNotifier.addStopWithAutoRoute(poi);
    if (!mounted) return;

    if (result.success) {
      ref.read(shouldFitToRouteProvider.notifier).state = true;
      context.go('/trip');
      return;
    }

    if (result.isGpsDisabled || result.isPermissionDenied) {
      await _handleLocationFailure(
        LocationResult.failure(
          result.error ?? 'gps_error',
          result.message ?? 'Standort konnte nicht ermittelt werden.',
        ),
      );
      return;
    }

    AppSnackbar.showError(
        context, result.message ?? context.l10n.galleryMapError);
  }

  Future<void> _handleLocationFailure(LocationResult result) async {
    if (!mounted) return;

    if (result.isGpsDisabled) {
      final shouldOpenSettings = await LocationHelper.showGpsDialog(context);
      if (shouldOpenSettings) {
        await LocationHelper.openSettings();
      }
      return;
    }

    AppSnackbar.showError(
      context,
      result.message ?? 'Standort konnte nicht ermittelt werden.',
    );

    if (result.error == 'permission_denied_forever') {
      await LocationHelper.openAppSettings();
    }
  }

  Map<String, dynamic>? _resolveTripData({
    required PublicTrip trip,
    Map<String, dynamic>? importedTripData,
  }) {
    final candidates = <Map<String, dynamic>?>[
      importedTripData,
      trip.tripData,
    ];

    for (final candidate in candidates) {
      if (candidate == null) continue;

      if (candidate['trip_data'] is Map) {
        return Map<String, dynamic>.from(candidate['trip_data'] as Map);
      }
      if (candidate['tripData'] is Map) {
        return Map<String, dynamic>.from(candidate['tripData'] as Map);
      }
      if (candidate['route'] is Map || candidate['stops'] is List) {
        return Map<String, dynamic>.from(candidate);
      }
    }

    return null;
  }

  ({AppRoute route, List<Map<String, dynamic>> stops})?
      _extractRouteAndStopsFromTripData({
    required PublicTrip trip,
    required Map<String, dynamic> tripData,
  }) {
    final rawRouteData = tripData['route'];
    if (rawRouteData is! Map) return null;

    final routeData = Map<String, dynamic>.from(rawRouteData);
    final coordinates = _parseCoordinates(routeData['coordinates']);
    if (coordinates.isEmpty) return null;

    final waypoints = _parseCoordinates(routeData['waypoints']);
    final startAddress =
        (routeData['startAddress'] ?? routeData['start_address'] ?? '')
            .toString();
    final endAddress =
        (routeData['endAddress'] ?? routeData['end_address'] ?? '').toString();
    final distanceKm = _asDouble(
          routeData['distanceKm'] ?? routeData['distance_km'],
        ) ??
        trip.distanceKm ??
        GeoUtils.calculateRouteLength(coordinates);
    final durationMinutes = _asInt(
          routeData['durationMinutes'] ?? routeData['duration_minutes'],
        ) ??
        ((trip.durationHours ?? 0) * 60).round();

    final route = AppRoute(
      start: coordinates.first,
      end: coordinates.last,
      startAddress:
          startAddress.isEmpty ? '${trip.tripName} (Start)' : startAddress,
      endAddress: endAddress.isEmpty ? '${trip.tripName} (Ziel)' : endAddress,
      coordinates: coordinates,
      distanceKm: distanceKm,
      durationMinutes: durationMinutes < 0 ? 0 : durationMinutes,
      type: _parseRouteType(routeData['type']),
      waypoints: waypoints,
    );

    return (
      route: route,
      stops: _extractTripStops(tripData),
    );
  }

  Trip _buildFavoriteTrip({
    required PublicTrip trip,
    required AppRoute route,
    required List<Map<String, dynamic>> stops,
    required Map<String, dynamic> tripData,
  }) {
    final favoriteStops = <TripStop>[];
    for (var i = 0; i < stops.length; i++) {
      final parsedStop = _tripStopFromStop(
        stop: stops[i],
        fallbackOrder: i,
        routeCoordinates: route.coordinates,
      );
      if (parsedStop != null) {
        favoriteStops.add(parsedStop);
      }
    }

    final dayCountFromData = _asInt(tripData['actualDays']) ?? trip.dayCount;
    return Trip(
      id: trip.id,
      name: trip.tripName,
      type: _parseTripType(trip.tripType),
      route: route,
      stops: favoriteStops,
      days: dayCountFromData < 1 ? 1 : dayCountFromData,
      createdAt: DateTime.now(),
      notes: trip.description,
    );
  }

  TripStop? _tripStopFromStop({
    required Map<String, dynamic> stop,
    required int fallbackOrder,
    required List<LatLng> routeCoordinates,
  }) {
    final poi = _poiFromStop(stop);
    if (poi == null) return null;

    final routePosition = _asDouble(
          stop['routePosition'] ?? stop['route_position'],
        ) ??
        (routeCoordinates.length >= 2
            ? GeoUtils.calculateRoutePosition(poi.location, routeCoordinates)
            : null);

    return TripStop(
      poiId: poi.id,
      name: poi.name,
      latitude: poi.latitude,
      longitude: poi.longitude,
      categoryId: poi.categoryId,
      routePosition: routePosition,
      detourKm: _asDouble(stop['detourKm'] ?? stop['detour_km']),
      detourMinutes: _asInt(stop['detourMinutes'] ?? stop['detour_minutes']),
      plannedDurationMinutes: _asInt(
            stop['plannedDurationMinutes'] ??
                stop['planned_duration_minutes'] ??
                stop['durationMinutes'],
          ) ??
          30,
      order: _asInt(stop['order']) ?? fallbackOrder,
      day: (_asInt(stop['day']) ?? 1).clamp(1, 365),
      isOvernightStop:
          _asBool(stop['isOvernightStop'] ?? stop['is_overnight_stop']),
      notes: stop['notes']?.toString(),
    );
  }

  TripType _parseTripType(String rawType) {
    for (final type in TripType.values) {
      if (type.name == rawType) return type;
    }
    return TripType.daytrip;
  }

  RouteType _parseRouteType(dynamic rawType) {
    final normalized = rawType?.toString().trim().toLowerCase();
    return normalized == RouteType.scenic.name
        ? RouteType.scenic
        : RouteType.fast;
  }

  List<LatLng> _parseCoordinates(dynamic rawCoordinates) {
    final list = rawCoordinates as List?;
    if (list == null) return const <LatLng>[];

    return list.map(_parseLatLng).whereType<LatLng>().toList(growable: false);
  }

  LatLng? _parseLatLng(dynamic rawCoordinate) {
    if (rawCoordinate is Map) {
      final map = Map<String, dynamic>.from(rawCoordinate);
      final lat = _asDouble(map['lat'] ?? map['latitude']);
      final lng = _asDouble(map['lng'] ?? map['lon'] ?? map['longitude']);
      if (lat == null || lng == null) return null;
      return LatLng(lat, lng);
    }

    if (rawCoordinate is List && rawCoordinate.length >= 2) {
      final first = _asDouble(rawCoordinate[0]);
      final second = _asDouble(rawCoordinate[1]);
      if (first == null || second == null) return null;

      if (second.abs() <= 90 && first.abs() <= 180) {
        return LatLng(second, first); // [lng, lat]
      }
      if (first.abs() <= 90 && second.abs() <= 180) {
        return LatLng(first, second); // [lat, lng]
      }
    }

    return null;
  }

  List<Map<String, dynamic>> _extractTripStops(Map<String, dynamic>? tripData) {
    final dynamicStops = (tripData?['stops'] as List<dynamic>?) ?? const [];
    return dynamicStops
        .map(_normalizeTripStop)
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  Map<String, dynamic>? _normalizeTripStop(dynamic raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);

    final latitude = _asDouble(map['latitude'] ?? map['lat']);
    final longitude = _asDouble(map['longitude'] ?? map['lng'] ?? map['lon']);
    if (latitude == null || longitude == null) return null;

    final resolvedPoiId =
        (map['poiId'] ?? map['poi_id'] ?? map['id'])?.toString().trim();
    final poiId = (resolvedPoiId == null || resolvedPoiId.isEmpty)
        ? _fallbackPoiId(map: map, latitude: latitude, longitude: longitude)
        : resolvedPoiId;

    final categoryId = _normalizeCategoryId(
      map['categoryId'] ?? map['category_id'] ?? map['category'],
    );
    final tags = _asStringList(map['tags']);
    final highlights =
        _asStringList(map['highlights']).map((e) => e.toLowerCase()).toList();
    final tagsWithHighlights = <String>{...tags, ...highlights}.toList();
    final isMustSee = _asBool(map['isMustSee'] ?? map['is_must_see']) ||
        tagsWithHighlights.contains('unesco') ||
        tagsWithHighlights.contains('mustsee') ||
        tagsWithHighlights.contains('must_see');

    return <String, dynamic>{
      ...map,
      'poiId': poiId,
      'name': (map['name'] ?? map['title'] ?? 'POI').toString(),
      'latitude': latitude,
      'longitude': longitude,
      'categoryId': categoryId,
      'score': _asDouble(map['score']),
      'tags': tagsWithHighlights,
      'highlights': highlights,
      'isMustSee': isMustSee,
      'imageUrl': map['imageUrl'] ?? map['image_url'],
      'thumbnailUrl': map['thumbnailUrl'] ?? map['thumbnail_url'],
      'description': map['description'],
      'isCurated': _asBool(map['isCurated'] ?? map['is_curated']),
      'hasWikipedia': _asBool(map['hasWikipedia'] ?? map['has_wikipedia']),
    };
  }

  String _stopCategoryId(Map<String, dynamic> stop) {
    return _normalizeCategoryId(stop['categoryId']);
  }

  String _fallbackPoiId({
    required Map<String, dynamic> map,
    required double latitude,
    required double longitude,
  }) {
    final title = (map['name'] ?? map['title'] ?? 'poi')
        .toString()
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '-');
    return 'gallery-$title-${latitude.toStringAsFixed(5)}-${longitude.toStringAsFixed(5)}';
  }

  List<String> _asStringList(dynamic value) {
    if (value is List) {
      return value
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (value is String) {
      return value
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const <String>[];
  }

  String _normalizeCategoryId(dynamic rawCategory) {
    final normalized =
        (rawCategory ?? 'attraction').toString().trim().toLowerCase();
    if (normalized.isEmpty) return 'attraction';

    for (final category in POICategory.values) {
      final byId = category.id.toLowerCase() == normalized;
      final byName = category.name.toLowerCase() == normalized;
      final byLabel = category.label.toLowerCase() == normalized;
      if (byId || byName || byLabel) {
        return category.id;
      }
    }

    if (normalized.contains('restaurant')) return POICategory.restaurant.id;
    if (normalized.contains('hotel')) return POICategory.hotel.id;
    if (normalized.contains('stadt') || normalized.contains('city')) {
      return POICategory.city.id;
    }
    if (normalized.contains('museum')) return POICategory.museum.id;
    if (normalized.contains('unesco')) return POICategory.unesco.id;

    return POICategory.attraction.id;
  }

  bool _stopIsMustSee(Map<String, dynamic> stop) {
    return _asBool(stop['isMustSee']) || _stopTags(stop).contains('unesco');
  }

  List<String> _stopTags(Map<String, dynamic> stop) {
    return _asStringList(stop['tags']);
  }

  List<String> _stopHighlightLabels(Map<String, dynamic> stop) {
    final raw = stop['highlights'] as List?;
    if (raw == null) return const <String>[];
    return raw
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .map((e) {
      final normalized = e.toLowerCase();
      switch (normalized) {
        case 'must_see':
        case 'mustsee':
          return 'Must-See';
        case 'unesco':
          return 'UNESCO';
        case 'historic':
          return 'Historisch';
        case 'secret':
          return 'Geheimtipp';
        default:
          return e;
      }
    }).toList();
  }

  double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', '.'));
  }

  int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value.toString());
  }

  bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value == null) return false;
    final normalized = value.toString().toLowerCase();
    return normalized == 'true' || normalized == '1';
  }

  POI? _poiFromStop(Map<String, dynamic> stop) {
    final poiId = stop['poiId']?.toString();
    final latitude = _asDouble(stop['latitude']);
    final longitude = _asDouble(stop['longitude']);
    if (poiId == null || latitude == null || longitude == null) {
      return null;
    }

    return POI(
      id: poiId,
      name: (stop['name'] ?? 'Stop').toString(),
      latitude: latitude,
      longitude: longitude,
      categoryId: _stopCategoryId(stop),
      score: (_asDouble(stop['score']) ?? 50).round(),
      imageUrl: stop['imageUrl'] as String?,
      thumbnailUrl: stop['thumbnailUrl'] as String?,
      description: stop['description'] as String?,
      isCurated: _asBool(stop['isCurated']),
      hasWikipedia: _asBool(stop['hasWikipedia']),
      tags: _stopTags(stop),
    );
  }

  void _openPOIDetailFromStop(Map<String, dynamic> stop) {
    final poi = _poiFromStop(stop);
    if (poi != null) {
      ref.read(pOIStateNotifierProvider.notifier).addPOI(poi);
    }

    final poiId = stop['poiId']?.toString();
    if (poiId == null || poiId.isEmpty) return;
    context.push('/poi/$poiId');
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  Future<void> _editTrip(PublicTrip trip) async {
    final nameController = TextEditingController(text: trip.tripName);
    final descriptionController =
        TextEditingController(text: trip.description ?? '');
    final tagsController = TextEditingController(text: trip.tags.join(', '));

    final save = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Trip bearbeiten'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Titel'),
                maxLength: 80,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Beschreibung'),
                minLines: 2,
                maxLines: 5,
                maxLength: 400,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags (kommagetrennt)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty) return;
              Navigator.pop(context, true);
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );

    if (save != true || !mounted) return;

    final ok = await ref
        .read(tripDetailNotifierProvider(widget.tripId).notifier)
        .updateTripMeta(
          tripName: nameController.text.trim(),
          description: descriptionController.text.trim(),
          tags: _splitCsv(tagsController.text),
        );

    if (!mounted) return;
    if (ok) {
      AppSnackbar.showSuccess(context, 'Trip aktualisiert');
    } else {
      AppSnackbar.showError(context, 'Trip konnte nicht aktualisiert werden');
    }
  }

  Future<void> _deleteTrip() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Trip loeschen?'),
        content: const Text(
          'Dieser veroeffentlichte Trip wird dauerhaft geloescht.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Loeschen'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final ok = await ref
        .read(tripDetailNotifierProvider(widget.tripId).notifier)
        .deleteTrip();
    if (!mounted) return;
    if (ok) {
      AppSnackbar.showSuccess(context, 'Trip geloescht');
      context.pop();
    } else {
      AppSnackbar.showError(context, 'Trip konnte nicht geloescht werden');
    }
  }

  List<String> _splitCsv(String raw) {
    return raw
        .split(',')
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
  }
}

/// Statistik-Chip
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
