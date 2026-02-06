import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/categories.dart';
import '../../../core/l10n/l10n.dart';
import '../../../data/models/trip.dart';
import '../../../data/providers/gamification_provider.dart';
import '../../../data/repositories/social_repo.dart';
import '../../../shared/widgets/app_snackbar.dart';

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

  final List<String> _selectedTags = [];
  bool _isPublishing = false;

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
                label: Text(_isPublishing ? context.l10n.publishPublishing : context.l10n.publishButton),
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

      final publicTrip = await repo.publishTrip(
        trip: widget.trip,
        tripName: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        tags: _selectedTags.isEmpty ? null : _selectedTags,
      );

      if (!mounted) return;

      if (publicTrip != null) {
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
}
