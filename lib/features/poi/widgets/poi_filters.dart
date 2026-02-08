import 'package:flutter/material.dart';
import '../../../core/constants/categories.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/l10n/category_l10n.dart';

/// Filter-Sheet fuer POIs
class POIFiltersSheet extends StatefulWidget {
  final Set<POICategory> selectedCategories;
  final bool mustSeeOnly;
  final bool indoorOnly;
  final double maxDetour;
  final void Function(Set<POICategory>, bool, bool, double) onApply;

  const POIFiltersSheet({
    super.key,
    required this.selectedCategories,
    required this.mustSeeOnly,
    this.indoorOnly = false,
    required this.maxDetour,
    required this.onApply,
  });

  @override
  State<POIFiltersSheet> createState() => _POIFiltersSheetState();
}

class _POIFiltersSheetState extends State<POIFiltersSheet> {
  late Set<POICategory> _categories;
  late bool _mustSeeOnly;
  late bool _indoorOnly;
  late double _maxDetour;

  @override
  void initState() {
    super.initState();
    _categories = Set.from(widget.selectedCategories);
    _mustSeeOnly = widget.mustSeeOnly;
    _indoorOnly = widget.indoorOnly;
    _maxDetour = widget.maxDetour;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 1.0,
      minChildSize: 0.9,
      maxChildSize: 1.0,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.l10n.filterTitle,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    TextButton(
                      onPressed: _resetFilters,
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.primary,
                      ),
                      child: Text(context.l10n.reset),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Filter-Optionen
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Must-See Toggle
                    _buildSwitchTile(
                      colorScheme: colorScheme,
                      title: context.l10n.poiOnlyMustSee,
                      subtitle: context.l10n.poiShowOnlyHighlights,
                      icon: Icons.star,
                      value: _mustSeeOnly,
                      onChanged: (value) =>
                          setState(() => _mustSeeOnly = value),
                    ),

                    const SizedBox(height: 12),

                    // Indoor-Only Toggle (v1.9.9)
                    _buildSwitchTile(
                      colorScheme: colorScheme,
                      title: context.l10n.poiOnlyIndoor,
                      subtitle: context.l10n.weatherRecBad,
                      icon: Icons.roofing,
                      value: _indoorOnly,
                      onChanged: (value) => setState(() => _indoorOnly = value),
                    ),

                    const SizedBox(height: 24),

                    // Umweg-Slider
                    _buildSliderSection(colorScheme),

                    const SizedBox(height: 24),

                    // Kategorien
                    _buildCategoriesSection(colorScheme),
                  ],
                ),
              ),

              // Apply Button
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: colorScheme.outlineVariant
                              .withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          widget.onApply(
                            _categories,
                            _mustSeeOnly,
                            _indoorOnly,
                            _maxDetour,
                          );
                        },
                        child: Text(context.l10n.filterApply),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSwitchTile({
    required ColorScheme colorScheme,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: value
                  ? colorScheme.primary.withValues(alpha: 0.1)
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: value ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildSliderSection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.l10n.filterMaxDetour,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: colorScheme.onSurface,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '+${_maxDetour.round()} km',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.filterMaxDetourHint,
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 16),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: colorScheme.primary,
            inactiveTrackColor: colorScheme.primary.withValues(alpha: 0.2),
            thumbColor: colorScheme.primary,
            overlayColor: colorScheme.primary.withValues(alpha: 0.1),
          ),
          child: Slider(
            value: _maxDetour,
            min: 15,
            max: 80,
            divisions: 5,
            label: '+${_maxDetour.round()} km',
            onChanged: (value) => setState(() => _maxDetour = value),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('+15 km', style: TextStyle(color: colorScheme.outline)),
            Text('+80 km', style: TextStyle(color: colorScheme.outline)),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoriesSection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.filterCategoriesLabel,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _categories.isEmpty
              ? context.l10n.filterAllCategories
              : context.l10n.filterSelectedCount(_categories.length),
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: POICategory.values.map((category) {
            final isSelected = _categories.contains(category);
            return FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(category.icon),
                  const SizedBox(width: 6),
                  Text(
                    category.localizedLabel(context),
                    style: TextStyle(
                      color: isSelected
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurface,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
              selected: isSelected,
              backgroundColor:
                  colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _categories.add(category);
                  } else {
                    _categories.remove(category);
                  }
                });
              },
              selectedColor: colorScheme.primaryContainer,
              checkmarkColor: colorScheme.primary,
              side: BorderSide(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.outline.withValues(alpha: 0.35),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _resetFilters() {
    setState(() {
      _categories = {};
      _mustSeeOnly = false;
      _indoorOnly = false;
      _maxDetour = 45;
    });
  }
}
