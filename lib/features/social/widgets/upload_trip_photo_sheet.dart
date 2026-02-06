import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/l10n/l10n.dart';
import '../../../data/repositories/social_repo.dart';
import '../../../shared/widgets/app_snackbar.dart';

/// Bottom Sheet zum Hochladen eines Trip-Fotos
class UploadTripPhotoSheet extends ConsumerStatefulWidget {
  final String tripId;

  const UploadTripPhotoSheet({
    super.key,
    required this.tripId,
  });

  /// Zeigt das Sheet an und gibt true zurueck wenn erfolgreich hochgeladen
  static Future<bool?> show(BuildContext context, String tripId) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 1.0,
        minChildSize: 0.9,
        maxChildSize: 1.0,
        expand: false,
        builder: (context, scrollController) => UploadTripPhotoSheet(tripId: tripId),
      ),
    );
  }

  @override
  ConsumerState<UploadTripPhotoSheet> createState() => _UploadTripPhotoSheetState();
}

class _UploadTripPhotoSheetState extends ConsumerState<UploadTripPhotoSheet> {
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
                  context.l10n.tripPhotoUpload,
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
              _buildImagePreview(colorScheme)
            else
              _buildImageSelectionButtons(colorScheme),

            const SizedBox(height: 16),

            // Caption-Eingabe
            TextField(
              controller: _captionController,
              maxLength: 500,
              maxLines: 3,
              minLines: 1,
              decoration: InputDecoration(
                labelText: context.l10n.photoCaption,
                hintText: context.l10n.photoCaptionHint,
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
              label: Text(_isUploading ? context.l10n.photoUploading : context.l10n.photoUpload),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSelectionButtons(ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: _ImageSourceButton(
            icon: Icons.camera_alt,
            label: context.l10n.photoFromCamera,
            onTap: () => _pickImage(ImageSource.camera),
            colorScheme: colorScheme,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _ImageSourceButton(
            icon: Icons.photo_library,
            label: context.l10n.photoFromGallery,
            onTap: () => _pickImage(ImageSource.gallery),
            colorScheme: colorScheme,
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview(ColorScheme colorScheme) {
    return Stack(
      children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: colorScheme.surfaceContainerHighest,
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.file(
            File(_selectedImage!.path),
            fit: BoxFit.cover,
            width: double.infinity,
            height: 200,
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
        AppSnackbar.showError(context, context.l10n.errorGeneric);
      }
    }
  }

  Future<void> _uploadPhoto() async {
    if (_selectedImage == null) return;

    setState(() => _isUploading = true);

    try {
      final repo = ref.read(socialRepositoryProvider);
      final caption = _captionController.text.trim();

      final photo = await repo.uploadTripPhoto(
        tripId: widget.tripId,
        imageFile: _selectedImage!,
        caption: caption.isEmpty ? null : caption,
      );

      if (mounted) {
        if (photo != null) {
          Navigator.pop(context, true);
        } else {
          AppSnackbar.showError(context, context.l10n.photoError);
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, context.l10n.photoError);
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
