import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/categories.dart';
import '../../../core/l10n/l10n.dart';
import '../../../data/models/poi.dart';
import '../../../data/models/trip.dart';
import '../../../data/providers/gamification_provider.dart';
import '../../../data/repositories/social_repo.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../random_trip/providers/random_trip_provider.dart';
import '../../trip/providers/trip_state_provider.dart';

/// Sheet zum Veroeffentlichen eines Trips in der Galerie
class PublishTripSheet extends ConsumerStatefulWidget {
  final Trip trip;

  const PublishTripSheet({
    super.key,
    required this.trip,
  });

  /// Zeigt das Sheet und gibt zurueck ob veroeffentlicht wurde
  static Future<bool> show(BuildContext context, Trip trip) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 1.0,
        minChildSize: 0.9,
        maxChildSize: 1.0,
        expand: false,
        builder: (context, scrollController) => PublishTripSheet(trip: trip),
      ),
    );
    return result ?? false;
  }

  @override
  ConsumerState<PublishTripSheet> createState() => _PublishTripSheetState();
}

class _PublishTripSheetState extends ConsumerState<PublishTripSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imagePicker = ImagePicker();

  final List<String> _selectedTags = [];
  bool _isPublishing = false;
  XFile? _coverImage;

  // Verfuegbare Tags
  static const _availableTags = [
    'roadtrip',
    'natur',
    'kultur',
    'strand',
    'berge',
    'stadt',
    'familie',
    'romantik',
    'abenteuer',
    'fotografie',
    'wandern',
    'historisch',
    'entspannung',
    'kulinarik',
  ];

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.trip.name;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        // Handle
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outline.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),

        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.public,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.publishTitle,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      context.l10n.publishSubtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // Form
        Expanded(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Cover-Bild
                _buildCoverImageSection(colorScheme, textTheme),

                const SizedBox(height: 24),

                // Trip-Info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        widget.trip.type == TripType.eurotrip
                            ? Icons.flight
                            : Icons.directions_car,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.trip.type == TripType.eurotrip
                                  ? context.l10n.publishEuroTrip
                                  : context.l10n.publishDaytrip,
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${widget.trip.stopCount} Stops \u2022 '
                              '${widget.trip.route.formattedDistance} \u2022 '
                              '${widget.trip.actualDays} ${widget.trip.actualDays == 1 ? 'Tag' : 'Tage'}',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: context.l10n.publishTripName,
                    hintText: context.l10n.publishTripNameHint,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return context.l10n.publishTripNameRequired;
                    }
                    if (value.trim().length < 3) {
                      return context.l10n.publishTripNameMinLength;
                    }
                    return null;
                  },
                  maxLength: 100,
                ),

                const SizedBox(height: 16),

                // Beschreibung
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: context.l10n.publishDescription,
                    hintText: context.l10n.publishDescriptionHint,
                    border: const OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 4,
                  maxLength: 500,
                ),

                const SizedBox(height: 24),

                // Tags
                Text(
                  context.l10n.publishTags,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.publishTagsHelper,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableTags.map((tag) {
                    final isSelected = _selectedTags.contains(tag);
                    return FilterChip(
                      label: Text(
                        '#$tag',
                        style: TextStyle(
                          color: isSelected
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: colorScheme.primary,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      checkmarkColor: colorScheme.onPrimary,
                      side: BorderSide(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.outline.withValues(alpha: 0.5),
                      ),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            if (_selectedTags.length < 5) {
                              _selectedTags.add(tag);
                            }
                          } else {
                            _selectedTags.remove(tag);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                if (_selectedTags.length >= 5)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      context.l10n.publishMaxTags,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.error,
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                // Hinweis
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          context.l10n.publishInfo,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Publish Button
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isPublishing ? null : _publishTrip,
                icon: _isPublishing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.publish),
                label: Text(_isPublishing
                    ? context.l10n.publishPublishing
                    : context.l10n.publishButton),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _publishTrip() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isPublishing = true);

    try {
      final repo = ref.read(socialRepositoryProvider);
      final sourcePOIs = _collectSourcePOIs(widget.trip);

      // Erst Trip veroeffentlichen
      final publicTrip = await repo.publishTrip(
        trip: widget.trip,
        tripName: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        tags: _selectedTags.isEmpty ? null : _selectedTags,
        sourcePOIs: sourcePOIs.isEmpty ? null : sourcePOIs,
      );

      if (!mounted) return;

      if (publicTrip != null) {
        // Cover-Bild hochladen falls ausgewaehlt
        if (_coverImage != null) {
          await repo.uploadTripCoverImage(
            tripId: publicTrip.id,
            imageFile: _coverImage!,
          );
        }

        // XP fuer Trip-Veroeffentlichung vergeben
        await ref.read(gamificationNotifierProvider.notifier).onTripPublished();

        if (!mounted) return;
        AppSnackbar.showSuccess(context, context.l10n.publishSuccess);
        Navigator.pop(context, true);
      } else {
        throw Exception(context.l10n.publishError);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => _isPublishing = false);
      AppSnackbar.showError(context, '${context.l10n.publishError}: $e');
    }
  }

  List<POI> _collectSourcePOIs(Trip trip) {
    final stopIds = trip.stops.map((s) => s.poiId).toSet();
    if (stopIds.isEmpty) return const <POI>[];

    final byId = <String, POI>{};

    final currentTripStops = ref.read(tripStateProvider).stops;
    for (final poi in currentTripStops) {
      if (stopIds.contains(poi.id)) {
        byId[poi.id] = poi;
      }
    }

    final generatedStops =
        ref.read(randomTripNotifierProvider).generatedTrip?.selectedPOIs ??
            const <POI>[];
    for (final poi in generatedStops) {
      if (stopIds.contains(poi.id)) {
        byId.putIfAbsent(poi.id, () => poi);
      }
    }

    return byId.values.toList();
  }

  /// Cover-Bild-Auswahl Section
  Widget _buildCoverImageSection(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.publishCoverImage,
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          context.l10n.publishCoverImageHint,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),

        // Bild-Vorschau oder Auswahl-Buttons
        if (_coverImage != null)
          _buildCoverImagePreview(colorScheme)
        else
          _buildCoverImagePicker(colorScheme),
      ],
    );
  }

  /// Cover-Bild-Vorschau mit Entfernen-Button
  Widget _buildCoverImagePreview(ColorScheme colorScheme) {
    return Stack(
      children: [
        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: colorScheme.surfaceContainerHighest,
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.file(
            File(_coverImage!.path),
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: IconButton.filled(
            onPressed: () => setState(() => _coverImage = null),
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

  /// Cover-Bild-Auswahl-Buttons
  Widget _buildCoverImagePicker(ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: _ImagePickerButton(
            icon: Icons.camera_alt,
            label: context.l10n.photoFromCamera,
            onTap: () => _pickCoverImage(ImageSource.camera),
            colorScheme: colorScheme,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ImagePickerButton(
            icon: Icons.photo_library,
            label: context.l10n.photoFromGallery,
            onTap: () => _pickCoverImage(ImageSource.gallery),
            colorScheme: colorScheme,
          ),
        ),
      ],
    );
  }

  /// Cover-Bild auswaehlen
  Future<void> _pickCoverImage(ImageSource source) async {
    try {
      final image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() => _coverImage = image);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, context.l10n.errorGeneric);
      }
    }
  }
}

/// Button fuer Bildquelle-Auswahl
class _ImagePickerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _ImagePickerButton({
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
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 32,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
