import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/journal_entry.dart';
import '../../../data/providers/journal_provider.dart';

/// Bottom Sheet zum Bearbeiten eines bestehenden Tagebuch-Eintrags
class EditJournalEntrySheet extends ConsumerStatefulWidget {
  final JournalEntry entry;

  const EditJournalEntrySheet({
    super.key,
    required this.entry,
  });

  @override
  ConsumerState<EditJournalEntrySheet> createState() =>
      _EditJournalEntrySheetState();
}

class _EditJournalEntrySheetState extends ConsumerState<EditJournalEntrySheet> {
  late final TextEditingController _noteController;
  bool _isLoading = false;
  String? _currentImagePath;
  bool _photoRemoved = false;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.entry.note ?? '');
    _currentImagePath = widget.entry.imagePath;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return DraggableScrollableSheet(
      initialChildSize: 1.0,
      minChildSize: 0.9,
      maxChildSize: 1.0,
      expand: false,
      builder: (context, scrollController) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Titel
              Text(
                l10n.journalEditEntry,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),

              // POI-Info
              if (widget.entry.poiName != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(
                      Icons.place,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      widget.entry.poiName!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.primary,
                          ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: AppSpacing.xl),

              // Aktuelles Foto / Foto-Optionen
              _buildPhotoSection(colorScheme, l10n),

              const SizedBox(height: AppSpacing.xl),

              // Notiz bearbeiten
              Text(
                l10n.journalAddNote,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _noteController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: l10n.journalNoteHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Speichern Button
              FilledButton.icon(
                onPressed: _isLoading ? null : _saveChanges,
                icon: const Icon(Icons.save),
                label: Text(l10n.journalSaveChanges),
              ),

              const SizedBox(height: AppSpacing.sm),

              // Loading Indicator
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSection(ColorScheme colorScheme, dynamic l10n) {
    final hasPhoto = !_photoRemoved && _currentImagePath != null;

    if (hasPhoto) {
      // Aktuelles Foto anzeigen mit Ersetzen/Entfernen Buttons
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Image.file(
              File(_currentImagePath!),
              fit: BoxFit.cover,
              width: double.infinity,
              height: 200,
              errorBuilder: (_, __, ___) => Container(
                height: 200,
                color: colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.broken_image,
                  size: 48,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : () => _replacePhoto(fromCamera: true),
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: Text(l10n.journalCamera),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : () => _replacePhoto(fromCamera: false),
                  icon: const Icon(Icons.photo_library, size: 18),
                  label: Text(l10n.journalGallery),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                onPressed: _isLoading ? null : _removePhoto,
                icon: Icon(
                  Icons.delete_outline,
                  color: colorScheme.error,
                ),
                tooltip: l10n.journalRemovePhoto,
              ),
            ],
          ),
        ],
      );
    }

    // Kein Foto — Optionen zum Hinzufuegen
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.journalAddPhoto,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _PhotoOptionButton(
                icon: Icons.camera_alt,
                label: l10n.journalCamera,
                onTap: _isLoading ? null : () => _replacePhoto(fromCamera: true),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _PhotoOptionButton(
                icon: Icons.photo_library,
                label: l10n.journalGallery,
                onTap: _isLoading ? null : () => _replacePhoto(fromCamera: false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _replacePhoto({required bool fromCamera}) async {
    final service = ref.read(journalServiceProvider);
    final newPath = await service.pickAndSavePhoto(
      widget.entry.tripId,
      fromCamera: fromCamera,
    );
    if (newPath != null && mounted) {
      setState(() {
        _currentImagePath = newPath;
        _photoRemoved = false;
      });
    }
  }

  void _removePhoto() {
    setState(() {
      _photoRemoved = true;
      _currentImagePath = null;
    });
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);

    try {
      final updatedEntry = widget.entry.copyWith(
        note: _noteController.text.isNotEmpty ? _noteController.text : null,
        imagePath: _photoRemoved ? null : _currentImagePath,
      );

      await ref
          .read(journalNotifierProvider.notifier)
          .updateEntry(updatedEntry);

      if (mounted) {
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

/// Button fuer Foto-Optionen (wiederverwendet aus AddJournalEntrySheet)
class _PhotoOptionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _PhotoOptionButton({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.primaryContainer.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.lg,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: colorScheme.primary,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
