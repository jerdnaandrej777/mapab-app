import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../core/l10n/l10n.dart';
import '../../data/models/poi.dart';
import '../../data/models/public_trip.dart';
import '../../data/models/route.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/gallery_provider.dart';
import '../../data/services/sharing_service.dart';
import '../../shared/widgets/app_snackbar.dart';
import '../map/providers/map_controller_provider.dart';
import '../poi/providers/poi_state_provider.dart';
import '../poi/widgets/poi_comments_section.dart';
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
      trailing: null,
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
        child: Row(
          children: [
            // Import Button
            Expanded(
              child: FilledButton.icon(
                onPressed: trip.isImportedByMe ? null : () => _importTrip(trip),
                icon: Icon(
                  trip.isImportedByMe ? Icons.check : Icons.download,
                ),
                label: Text(
                  trip.isImportedByMe ? 'Importiert' : 'In Favoriten',
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
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.qr_code_2,
                        size: 120,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'QR-Code',
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 12,
                        ),
                      ),
                    ],
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
    final tripData = await ref
        .read(tripDetailNotifierProvider(widget.tripId).notifier)
        .importTrip();

    if (!mounted) return;

    if (tripData != null) {
      AppSnackbar.showSuccess(context, context.l10n.galleryImportSuccess);
    } else {
      AppSnackbar.showError(context, context.l10n.galleryImportError);
    }
  }

  void _showOnMap(PublicTrip trip) {
    final tripData = trip.tripData;
    if (tripData == null) {
      AppSnackbar.showError(context, context.l10n.galleryMapNoData);
      return;
    }

    try {
      // Route-Daten extrahieren
      final routeData = tripData['route'] as Map<String, dynamic>?;
      if (routeData == null) {
        AppSnackbar.showError(context, context.l10n.galleryMapNoData);
        return;
      }

      // Koordinaten parsen
      final coordsList = routeData['coordinates'] as List<dynamic>? ?? [];
      final coordinates = coordsList.map((c) {
        final map = c as Map<String, dynamic>;
        return LatLng(
          (map['lat'] as num).toDouble(),
          (map['lng'] as num).toDouble(),
        );
      }).toList();

      if (coordinates.isEmpty) {
        AppSnackbar.showError(context, context.l10n.galleryMapNoData);
        return;
      }

      // AppRoute erstellen
      final route = AppRoute(
        start: coordinates.first,
        end: coordinates.last,
        startAddress: trip.tripName,
        endAddress: trip.tripName,
        coordinates: coordinates,
        distanceKm: trip.distanceKm ?? 0,
        durationMinutes: ((trip.durationHours ?? 0) * 60).round(),
      );

      // Stops parsen
      final stopsData = tripData['stops'] as List<dynamic>? ?? [];
      final stops = stopsData
          .map(_normalizeTripStop)
          .whereType<Map<String, dynamic>>()
          .map(_poiFromStop)
          .whereType<POI>()
          .toList();

      // In tripStateProvider laden
      ref.read(tripStateProvider.notifier).setRouteAndStops(route, stops);

      // Flag setzen für Auto-Zoom
      ref.read(shouldFitToRouteProvider.notifier).state = true;

      debugPrint(
          '[TripDetail] Route auf Karte geladen: ${route.distanceKm.toStringAsFixed(1)} km, ${stops.length} Stops');

      // Zur Karte navigieren
      context.go('/');
    } catch (e) {
      debugPrint('[TripDetail] Fehler beim Anzeigen auf Karte: $e');
      AppSnackbar.showError(context, context.l10n.galleryMapError);
    }
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

    final poiId =
        (map['poiId'] ?? map['poi_id'] ?? map['id'])?.toString().trim();
    if (poiId == null || poiId.isEmpty) return null;

    final latitude = _asDouble(map['latitude'] ?? map['lat']);
    final longitude = _asDouble(map['longitude'] ?? map['lng'] ?? map['lon']);
    final categoryId = (map['categoryId'] ??
            map['category_id'] ??
            map['category'] ??
            'attraction')
        .toString();
    final tags = ((map['tags'] as List?) ?? const [])
        .map((e) => e.toString())
        .where((e) => e.isNotEmpty)
        .toList();
    final highlights = ((map['highlights'] as List?) ?? const [])
        .map((e) => e.toString().trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toList();
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
    return (stop['categoryId'] ?? 'attraction').toString();
  }

  bool _stopIsMustSee(Map<String, dynamic> stop) {
    return _asBool(stop['isMustSee']) || _stopTags(stop).contains('unesco');
  }

  List<String> _stopTags(Map<String, dynamic> stop) {
    final tags = stop['tags'] as List?;
    if (tags == null) return const <String>[];
    return tags.map((e) => e.toString()).toList();
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
    return double.tryParse(value.toString());
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
