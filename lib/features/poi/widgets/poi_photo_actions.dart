import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/poi_social_provider.dart';
import '../../../l10n/app_localizations.dart';
import 'poi_photo_gallery.dart';
import 'upload_photo_sheet.dart';

class POIPhotoActions extends ConsumerWidget {
  const POIPhotoActions({
    super.key,
    required this.poiId,
    this.compact = false,
  });

  final String poiId;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final social = ref.watch(pOISocialNotifierProvider(poiId));
    final auth = ref.watch(authNotifierProvider);

    final label = '${social.photoCount}';
    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => _openGallery(context),
            icon: const Icon(Icons.photo_library_outlined, size: 18),
            tooltip: l10n.poiPhotos,
          ),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          if (auth.isAuthenticated)
            IconButton(
              onPressed: () => _openUpload(context),
              icon: const Icon(Icons.add_a_photo_outlined, size: 18),
              tooltip: l10n.photoUpload,
            ),
        ],
      );
    }

    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: () => _openGallery(context),
          icon: const Icon(Icons.photo_library_outlined),
          label: Text('${l10n.poiPhotos} ($label)'),
        ),
        const SizedBox(width: 8),
        if (auth.isAuthenticated)
          FilledButton.tonalIcon(
            onPressed: () => _openUpload(context),
            icon: const Icon(Icons.add_a_photo_outlined),
            label: Text(l10n.photoUpload),
          ),
      ],
    );
  }

  void _openGallery(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: POIPhotoGallery(poiId: poiId),
        ),
      ),
    );
  }

  void _openUpload(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => UploadPhotoSheet(poiId: poiId),
    );
  }
}
