import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/categories.dart';
import '../../../core/l10n/l10n.dart';
import '../../../data/models/poi.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/repositories/social_repo.dart';
import '../../../shared/widgets/app_snackbar.dart';

class PublishPoiSheet extends ConsumerStatefulWidget {
  final POI poi;

  const PublishPoiSheet({
    super.key,
    required this.poi,
  });

  static Future<bool> show(BuildContext context, POI poi) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 1.0,
        minChildSize: 0.9,
        maxChildSize: 1.0,
        expand: false,
        builder: (_, __) => PublishPoiSheet(poi: poi),
      ),
    );
    return result ?? false;
  }

  @override
  ConsumerState<PublishPoiSheet> createState() => _PublishPoiSheetState();
}

class _PublishPoiSheetState extends ConsumerState<PublishPoiSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isPublishing = false;
  bool _isMustSee = false;
  final Set<POICategory> _selectedCategories = {};

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.poi.name;
    final baseCategory = widget.poi.category;
    if (baseCategory != null &&
        baseCategory != POICategory.hotel &&
        baseCategory != POICategory.restaurant) {
      _selectedCategories.add(baseCategory);
    }
    _isMustSee = widget.poi.isMustSee;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
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
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.public, color: colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'POI veroeffentlichen',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Teile diesen Ort mit der Community',
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
        Expanded(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text(widget.poi.categoryIcon,
                          style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.poi.name,
                          style: textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Titel',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 180,
                  validator: (value) {
                    if (value == null || value.trim().length < 3) {
                      return 'Bitte mindestens 3 Zeichen eingeben';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _contentController,
                  maxLines: 4,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    labelText: 'Beschreibung (optional)',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Must-See markieren'),
                  subtitle:
                      const Text('Wird in der Galerie als Highlight angezeigt'),
                  value: _isMustSee,
                  onChanged: (value) => setState(() => _isMustSee = value),
                ),
                const SizedBox(height: 12),
                Text(
                  context.l10n.publishTags,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: POICategory.values
                      .where((c) =>
                          c != POICategory.hotel && c != POICategory.restaurant)
                      .map((category) {
                    final isSelected = _selectedCategories.contains(category);
                    return FilterChip(
                      label: Text(
                        '#${category.id}',
                        style: TextStyle(
                          color: isSelected
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: colorScheme.primary,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedCategories.add(category);
                          } else {
                            _selectedCategories.remove(category);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isPublishing ? null : _publish,
                icon: _isPublishing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.publish),
                label: Text(
                  _isPublishing
                      ? context.l10n.publishPublishing
                      : context.l10n.publishButton,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = ref.read(authNotifierProvider);
    if (!auth.isAuthenticated) {
      AppSnackbar.showError(
        context,
        'Bitte zuerst einloggen, um POIs zu veroeffentlichen.',
      );
      return;
    }

    setState(() => _isPublishing = true);

    try {
      final repo = ref.read(socialRepositoryProvider);
      final result = await repo.publishPOI(
        poiId: widget.poi.id,
        title: _titleController.text.trim(),
        content: _contentController.text.trim().isEmpty
            ? null
            : _contentController.text.trim(),
        categories: _selectedCategories.map((e) => e.id).toList(),
        isMustSee: _isMustSee,
        coverPhotoPath: widget.poi.imageUrl,
      );

      if (!mounted) return;
      if (result == null) {
        throw Exception('POI konnte nicht veröffentlicht werden');
      }

      AppSnackbar.showSuccess(context, 'POI veroeffentlicht');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(context, 'Veröffentlichen fehlgeschlagen: $e');
      setState(() => _isPublishing = false);
    }
  }
}
