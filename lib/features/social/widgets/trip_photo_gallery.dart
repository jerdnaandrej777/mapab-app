import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../data/models/trip_photo.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/repositories/social_repo.dart';
import 'upload_trip_photo_sheet.dart';

/// Horizontale Foto-Galerie fuer Trip-Fotos
class TripPhotoGallery extends ConsumerStatefulWidget {
  final String tripId;
  final bool isOwnTrip;
  final double height;

  const TripPhotoGallery({
    super.key,
    required this.tripId,
    this.isOwnTrip = false,
    this.height = 200,
  });

  @override
  ConsumerState<TripPhotoGallery> createState() => _TripPhotoGalleryState();
}

class _TripPhotoGalleryState extends ConsumerState<TripPhotoGallery> {
  List<TripPhoto> _photos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    try {
      final repo = ref.read(socialRepositoryProvider);
      final photos = await repo.loadTripPhotos(widget.tripId);
      if (mounted) {
        setState(() {
          _photos = photos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final authState = ref.watch(authNotifierProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(Icons.photo_library, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              '${context.l10n.tripPhotos} (${_photos.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Spacer(),
            if (widget.isOwnTrip && authState.isAuthenticated)
              TextButton.icon(
                onPressed: () => _showUploadSheet(),
                icon: const Icon(Icons.add_a_photo, size: 18),
                label: Text(context.l10n.photoUpload),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Foto-Galerie oder Platzhalter
        if (_isLoading)
          SizedBox(
            height: widget.height,
            child: const Center(child: CircularProgressIndicator()),
          )
        else if (_photos.isEmpty)
          _buildEmptyState(context, colorScheme, authState.isAuthenticated)
        else
          SizedBox(
            height: widget.height,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _photos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final photo = _photos[index];
                return _PhotoThumbnail(
                  photo: photo,
                  onTap: () => _showPhotoDetail(context, _photos, index),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    ColorScheme colorScheme,
    bool isAuthenticated,
  ) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 48,
              color: colorScheme.outline,
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.tripNoPhotos,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            if (widget.isOwnTrip && isAuthenticated) ...[
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: () => _showUploadSheet(),
                icon: const Icon(Icons.add_a_photo),
                label: Text(context.l10n.tripAddFirstPhoto),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showUploadSheet() async {
    final success = await UploadTripPhotoSheet.show(context, widget.tripId);
    if (success == true) {
      _loadPhotos();
    }
  }

  void _showPhotoDetail(BuildContext context, List<TripPhoto> photos, int initialIndex) {
    showDialog(
      context: context,
      builder: (context) => _PhotoDetailDialog(
        tripId: widget.tripId,
        photos: photos,
        initialIndex: initialIndex,
        isOwnTrip: widget.isOwnTrip,
        onPhotoDeleted: () => _loadPhotos(),
      ),
    );
  }
}

/// Einzelnes Foto-Thumbnail
class _PhotoThumbnail extends StatelessWidget {
  final TripPhoto photo;
  final VoidCallback onTap;

  const _PhotoThumbnail({
    required this.photo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Foto-URL aus Repository holen
    String imageUrl = '';
    try {
      final scope = ProviderScope.containerOf(context);
      final socialRepo = scope.read(socialRepositoryProvider);
      imageUrl = socialRepo.getTripPhotoUrl(photo.storagePath);
    } catch (_) {
      // Fallback URL
      imageUrl = photo.storagePath;
    }

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 160,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: colorScheme.surfaceContainerHighest,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: colorScheme.errorContainer,
                  child: Icon(Icons.broken_image, color: colorScheme.error),
                ),
              ),
              // Autor-Badge unten
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
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
                  child: Text(
                    photo.authorName ?? 'Anonym',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Vollbild-Foto-Dialog mit Swipe
class _PhotoDetailDialog extends ConsumerStatefulWidget {
  final String tripId;
  final List<TripPhoto> photos;
  final int initialIndex;
  final bool isOwnTrip;
  final VoidCallback onPhotoDeleted;

  const _PhotoDetailDialog({
    required this.tripId,
    required this.photos,
    required this.initialIndex,
    required this.isOwnTrip,
    required this.onPhotoDeleted,
  });

  @override
  ConsumerState<_PhotoDetailDialog> createState() => _PhotoDetailDialogState();
}

class _PhotoDetailDialogState extends ConsumerState<_PhotoDetailDialog> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final authState = ref.watch(authNotifierProvider);
    final currentPhoto = widget.photos[_currentIndex];
    final isOwnPhoto = authState.user?.id == currentPhoto.userId;

    final repo = ref.read(socialRepositoryProvider);

    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          // Foto-PageView
          PageView.builder(
            controller: _pageController,
            itemCount: widget.photos.length,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (context, index) {
              final photo = widget.photos[index];
              final imageUrl = repo.getTripPhotoUrl(photo.storagePath);
              return InteractiveViewer(
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.contain,
                    placeholder: (_, __) => const CircularProgressIndicator(),
                    errorWidget: (_, __, ___) => const Icon(
                      Icons.broken_image,
                      color: Colors.white,
                      size: 64,
                    ),
                  ),
                ),
              );
            },
          ),

          // Schliessen-Button
          Positioned(
            top: 16,
            right: 16,
            child: SafeArea(
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                ),
              ),
            ),
          ),

          // Index-Anzeige
          Positioned(
            top: 16,
            left: 16,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentIndex + 1} / ${widget.photos.length}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),

          // Info-Bar unten
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Autor
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundImage: currentPhoto.authorAvatar != null
                              ? NetworkImage(currentPhoto.authorAvatar!)
                              : null,
                          child: currentPhoto.authorAvatar == null
                              ? Text(
                                  (currentPhoto.authorName ?? 'A').substring(0, 1).toUpperCase(),
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          currentPhoto.authorName ?? context.l10n.anonymousUser,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        // Loeschen (nur eigene Fotos)
                        if (isOwnPhoto)
                          IconButton(
                            onPressed: () => _deletePhoto(currentPhoto),
                            icon: Icon(Icons.delete, color: colorScheme.error),
                          ),
                      ],
                    ),
                    // Caption
                    if (currentPhoto.caption != null && currentPhoto.caption!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        currentPhoto.caption!,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePhoto(TripPhoto photo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.photoDelete),
        content: Text(context.l10n.photoDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final repo = ref.read(socialRepositoryProvider);
    final success = await repo.deleteTripPhoto(photo.id);

    if (success && mounted) {
      widget.onPhotoDeleted();
      Navigator.pop(context);
    }
  }
}
