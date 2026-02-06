import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/location_helper.dart';
import '../../../data/providers/journal_provider.dart';

/// Bottom Sheet zum Hinzufuegen eines neuen Tagebuch-Eintrags
class AddJournalEntrySheet extends ConsumerStatefulWidget {
  final String tripId;
  final String? poiId;
  final String? poiName;
  final int? dayNumber;

  const AddJournalEntrySheet({
    super.key,
    required this.tripId,
    this.poiId,
    this.poiName,
    this.dayNumber,
  });

  @override
  ConsumerState<AddJournalEntrySheet> createState() => _AddJournalEntrySheetState();
}

class _AddJournalEntrySheetState extends ConsumerState<AddJournalEntrySheet> {
  final _noteController = TextEditingController();
  bool _isLoading = false;
  bool _useLocation = true;
  LatLng? _currentLocation;
  String? _locationName;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadLocation() async {
    if (!_useLocation) return;

    try {
      final result = await LocationHelper.getCurrentPosition();
      if (result.isSuccess && mounted) {
        setState(() {
          _currentLocation = result.position;
        });
      }
    } catch (e) {
      // Standort konnte nicht geladen werden
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final journalState = ref.watch(journalNotifierProvider);

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
              l10n.journalNewEntry,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            // POI-Info (falls vorhanden)
            if (widget.poiName != null) ...[
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
                    widget.poiName!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: AppSpacing.xl),

            // Foto-Optionen
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
                    onTap: _isLoading ? null : () => _addPhotoEntry(fromCamera: true),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _PhotoOptionButton(
                    icon: Icons.photo_library,
                    label: l10n.journalGallery,
                    onTap: _isLoading ? null : () => _addPhotoEntry(fromCamera: false),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),

            // Notiz-Eingabe
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

            const SizedBox(height: AppSpacing.md),

            // Standort-Option
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.journalSaveLocation),
              subtitle: Text(
                _currentLocation != null
                    ? l10n.journalLocationAvailable
                    : l10n.journalLocationLoading,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              value: _useLocation,
              onChanged: (value) {
                setState(() {
                  _useLocation = value;
                });
                if (value && _currentLocation == null) {
                  _loadLocation();
                }
              },
            ),

            const SizedBox(height: AppSpacing.lg),

            // Nur Notiz speichern Button
            if (_noteController.text.isNotEmpty || true)
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _addTextEntry,
                icon: const Icon(Icons.note_add),
                label: Text(l10n.journalSaveNote),
              ),

            const SizedBox(height: AppSpacing.sm),

            // Loading Indicator
            if (_isLoading || journalState.isLoading)
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

  Future<void> _addPhotoEntry({required bool fromCamera}) async {
    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(journalNotifierProvider.notifier);
      final entry = fromCamera
          ? await notifier.addPhotoFromCamera(
              note: _noteController.text.isNotEmpty ? _noteController.text : null,
              poiId: widget.poiId,
              poiName: widget.poiName,
              latitude: _useLocation ? _currentLocation?.latitude : null,
              longitude: _useLocation ? _currentLocation?.longitude : null,
              locationName: _useLocation ? _locationName : null,
              dayNumber: widget.dayNumber,
            )
          : await notifier.addPhotoFromGallery(
              note: _noteController.text.isNotEmpty ? _noteController.text : null,
              poiId: widget.poiId,
              poiName: widget.poiName,
              latitude: _useLocation ? _currentLocation?.latitude : null,
              longitude: _useLocation ? _currentLocation?.longitude : null,
              locationName: _useLocation ? _locationName : null,
              dayNumber: widget.dayNumber,
            );

      if (entry != null && mounted) {
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addTextEntry() async {
    if (_noteController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.journalEnterNote)),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(journalNotifierProvider.notifier);
      final entry = await notifier.addTextEntry(
        note: _noteController.text,
        poiId: widget.poiId,
        poiName: widget.poiName,
        latitude: _useLocation ? _currentLocation?.latitude : null,
        longitude: _useLocation ? _currentLocation?.longitude : null,
        locationName: _useLocation ? _locationName : null,
        dayNumber: widget.dayNumber,
      );

      if (entry != null && mounted) {
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

/// Button fuer Foto-Optionen
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
