import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_config.dart';
import '../../../data/models/poi_photo.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/poi_social_provider.dart';
import '../../../data/repositories/poi_social_repo.dart';
import '../../../l10n/app_localizations.dart';

/// Horizontale Foto-Galerie fuer POI-Fotos
class POIPhotoGallery extends ConsumerWidget {
  final String poiId;
  final VoidCallback? onAddPhoto;
  final double height;

  const POIPhotoGallery({
    super.key,
    required this.poiId,
    this.onAddPhoto,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final socialState = ref.watch(pOISocialNotifierProvider(poiId));
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authNotifierProvider);

    final photos = socialState.photos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(Icons.photo_library, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              '${l10n.poiPhotos} (${photos.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Spacer(),
            if (authState.isAuthenticated && onAddPhoto != null)
              TextButton.icon(
                onPressed: onAddPhoto,
                icon: const Icon(Icons.add_a_photo, size: 18),
                label: Text(l10n.photoUpload),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Foto-Galerie oder Platzhalter
        if (photos.isEmpty)
          _buildEmptyState(context, l10n, colorScheme, authState.isAuthenticated)
        else
          SizedBox(
            height: height,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final photo = photos[index];
                return _PhotoThumbnail(
                  photo: photo,
                  onTap: () => _showPhotoDetail(context, ref, photos, index),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme colorScheme,
    bool isAuthenticated,
  ) {
    return Container(
      height: height,
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
              l10n.poiNoPhotos,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            if (isAuthenticated && onAddPhoto != null) ...[
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: onAddPhoto,
                icon: const Icon(Icons.add_a_photo),
                label: Text(l10n.poiBeFirstPhoto),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showPhotoDetail(BuildContext context, WidgetRef ref, List<POIPhoto> photos, int initialIndex) {
    showDialog(
      context: context,
      builder: (context) => _PhotoDetailDialog(
        poiId: poiId,
        photos: photos,
        initialIndex: initialIndex,
      ),
    );
  }
}

/// Einzelnes Foto-Thumbnail
class _PhotoThumbnail extends StatelessWidget {
  final POIPhoto photo;
  final VoidCallback onTap;

  const _PhotoThumbnail({
    required this.photo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
                imageUrl: getStorageUrl(photo.storagePath),
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
  final String poiId;
  final List<POIPhoto> photos;
  final int initialIndex;

  const _PhotoDetailDialog({
    required this.poiId,
    required this.photos,
    required this.initialIndex,
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
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authNotifierProvider);
    final currentPhoto = widget.photos[_currentIndex];
    final isOwnPhoto = authState.user?.id == currentPhoto.userId;

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
              return InteractiveViewer(
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: getStorageUrl(photo.storagePath),
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
                          currentPhoto.authorName ?? l10n.anonymousUser,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        // Loeschen oder Melden
                        if (isOwnPhoto)
                          IconButton(
                            onPressed: () => _deletePhoto(currentPhoto),
                            icon: Icon(Icons.delete, color: colorScheme.error),
                          )
                        else
                          IconButton(
                            onPressed: () => _flagPhoto(currentPhoto),
                            icon: const Icon(Icons.flag_outlined, color: Colors.white70),
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

  Future<void> _deletePhoto(POIPhoto photo) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.photoDelete),
        content: Text(l10n.photoDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final success = await ref.read(pOISocialNotifierProvider(widget.poiId).notifier).deletePhoto(photo.id);

    if (success && mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _flagPhoto(POIPhoto photo) async {
    final l10n = AppLocalizations.of(context)!;
    final success = await ref.read(pOISocialNotifierProvider(widget.poiId).notifier).flagContent(
      contentType: 'photo',
      contentId: photo.id,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? l10n.reportSuccess : l10n.errorGeneric),
        ),
      );
    }
  }
}
