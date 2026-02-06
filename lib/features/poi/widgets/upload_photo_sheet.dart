import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/providers/poi_social_provider.dart';
import '../../../l10n/app_localizations.dart';

/// Bottom Sheet zum Hochladen eines POI-Fotos
class UploadPhotoSheet extends ConsumerStatefulWidget {
  final String poiId;

  const UploadPhotoSheet({
    super.key,
    required this.poiId,
  });

  /// Zeigt das Sheet an und gibt true zurueck wenn erfolgreich hochgeladen
  static Future<bool?> show(BuildContext context, String poiId) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 1.0,
        minChildSize: 0.9,
        maxChildSize: 1.0,
        expand: false,
        builder: (context, scrollController) => UploadPhotoSheet(poiId: poiId),
      ),
    );
  }

  @override
  ConsumerState<UploadPhotoSheet> createState() => _UploadPhotoSheetState();
}

class _UploadPhotoSheetState extends ConsumerState<UploadPhotoSheet> {
  final _captionController = TextEditingController();
  final _imagePicker = ImagePicker();
  XFile? _selectedImage;
  bool _isUploading = false;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Row(
              children: [
                Icon(Icons.add_a_photo, color: colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  l10n.photoUpload,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Bild-Vorschau oder Auswahl-Buttons
            if (_selectedImage != null)
              _buildImagePreview(colorScheme, l10n)
            else
              _buildImageSelectionButtons(colorScheme, l10n),

            const SizedBox(height: 16),

            // Caption-Eingabe
            TextField(
              controller: _captionController,
              maxLength: 500,
              maxLines: 3,
              minLines: 1,
              decoration: InputDecoration(
                labelText: l10n.photoCaption,
                hintText: l10n.photoCaptionHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                counterText: '',
              ),
            ),

            const SizedBox(height: 24),

            // Upload-Button
            FilledButton.icon(
              onPressed: _selectedImage == null || _isUploading
                  ? null
                  : _uploadPhoto,
              icon: _isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.cloud_upload),
              label: Text(_isUploading ? l10n.photoUploading : l10n.photoUpload),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSelectionButtons(ColorScheme colorScheme, AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: _ImageSourceButton(
            icon: Icons.camera_alt,
            label: l10n.photoFromCamera,
            onTap: () => _pickImage(ImageSource.camera),
            colorScheme: colorScheme,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _ImageSourceButton(
            icon: Icons.photo_library,
            label: l10n.photoFromGallery,
            onTap: () => _pickImage(ImageSource.gallery),
            colorScheme: colorScheme,
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview(ColorScheme colorScheme, AppLocalizations l10n) {
    return Stack(
      children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: colorScheme.surfaceContainerHighest,
          ),
          clipBehavior: Clip.antiAlias,
          child: FutureBuilder<Widget>(
            future: _buildPreviewImage(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return snapshot.data!;
              }
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ),
        // Entfernen-Button
        Positioned(
          top: 8,
          right: 8,
          child: IconButton.filled(
            onPressed: () => setState(() => _selectedImage = null),
            icon: const Icon(Icons.close),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black54,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Future<Widget> _buildPreviewImage() async {
    if (_selectedImage == null) {
      return const SizedBox.shrink();
    }

    final bytes = await _selectedImage!.readAsBytes();
    return Image.memory(
      bytes,
      fit: BoxFit.cover,
      width: double.infinity,
      height: 200,
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorGeneric)),
        );
      }
    }
  }

  Future<void> _uploadPhoto() async {
    if (_selectedImage == null) return;

    setState(() => _isUploading = true);

    try {
      final caption = _captionController.text.trim();
      final success = await ref
          .read(pOISocialNotifierProvider(widget.poiId).notifier)
          .uploadPhoto(
            _selectedImage!,
            caption: caption.isEmpty ? null : caption,
          );

      if (mounted) {
        if (success) {
          Navigator.pop(context, true);
        } else {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.photoError)),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }
}

/// Button fuer Bildquelle-Auswahl (Kamera/Galerie)
class _ImageSourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _ImageSourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 48,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
