import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n/l10n.dart';
import '../../data/models/trip_template.dart';
import '../../core/constants/categories.dart';
import '../random_trip/providers/random_trip_provider.dart';
import '../random_trip/providers/random_trip_state.dart';

/// Screen zur Auswahl von Trip-Vorlagen
class TripTemplatesScreen extends ConsumerStatefulWidget {
  const TripTemplatesScreen({super.key});

  @override
  ConsumerState<TripTemplatesScreen> createState() => _TripTemplatesScreenState();
}

class _TripTemplatesScreenState extends ConsumerState<TripTemplatesScreen> {
  String _selectedAudience = 'alle';

  List<(String, String, IconData)> _getAudiences(BuildContext context) => [
    ('alle', context.l10n.templatesAudienceAll, Icons.apps),
    ('paare', context.l10n.templatesAudienceCouples, Icons.favorite),
    ('familien', context.l10n.templatesAudienceFamilies, Icons.family_restroom),
    ('abenteurer', context.l10n.templatesAudienceAdventurers, Icons.hiking),
    ('feinschmecker', context.l10n.templatesAudienceFoodies, Icons.restaurant),
    ('fotografen', context.l10n.templatesAudiencePhotographers, Icons.camera_alt),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final templates = TripTemplates.forAudience(_selectedAudience);
    final audiences = _getAudiences(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.templatesTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: context.l10n.templatesScanQr,
            onPressed: () => context.push('/scan'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter-Chips
          SizedBox(
            height: 56,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: audiences.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final (id, label, icon) = audiences[index];
                final isSelected = _selectedAudience == id;
                return FilterChip(
                  selected: isSelected,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 16),
                      const SizedBox(width: 4),
                      Text(label),
                    ],
                  ),
                  onSelected: (_) => setState(() => _selectedAudience = id),
                );
              },
            ),
          ),

          // Template-Liste
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: templates.length,
              itemBuilder: (context, index) {
                final template = templates[index];
                return _TemplateCard(
                  template: template,
                  onTap: () => _selectTemplate(template),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _selectTemplate(TripTemplate template) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _TemplateDetailSheet(
        template: template,
        onStart: (days) {
          Navigator.pop(ctx);
          _startTripWithTemplate(template, days);
        },
      ),
    );
  }

  void _startTripWithTemplate(TripTemplate template, int days) {
    // Kategorien im RandomTripProvider setzen
    final notifier = ref.read(randomTripNotifierProvider.notifier);

    // Reset und Kategorien setzen
    notifier.reset();

    // Kategorien aus Template uebernehmen
    final categories = template.categories
        .map((id) => POICategory.values.firstWhere(
              (c) => c.id == id,
              orElse: () => POICategory.attraction,
            ))
        .toList();

    notifier.setCategories(categories);

    // Trip-Modus basierend auf Tagen setzen
    if (days > 1) {
      notifier.setMode(RandomTripMode.eurotrip);
      notifier.setEuroTripDays(days);
    } else {
      notifier.setMode(RandomTripMode.daytrip);
    }

    // Zur Karte navigieren (AI Trip Modus)
    context.go('/?mode=ai');
  }
}

/// Karte fuer eine einzelne Vorlage
class _TemplateCard extends StatelessWidget {
  final TripTemplate template;
  final VoidCallback onTap;

  const _TemplateCard({
    required this.template,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Emoji-Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    template.emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      template.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          context.l10n.templatesDays(template.recommendedDays),
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.place,
                          size: 14,
                          color: colorScheme.secondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          context.l10n.templatesCategories(template.categories.length),
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Pfeil
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Detail-Sheet fuer eine Vorlage
class _TemplateDetailSheet extends StatefulWidget {
  final TripTemplate template;
  final void Function(int days) onStart;

  const _TemplateDetailSheet({
    required this.template,
    required this.onStart,
  });

  @override
  State<_TemplateDetailSheet> createState() => _TemplateDetailSheetState();
}

class _TemplateDetailSheetState extends State<_TemplateDetailSheet> {
  late int _selectedDays;

  @override
  void initState() {
    super.initState();
    _selectedDays = widget.template.recommendedDays;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final template = widget.template;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Inhalt
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              template.emoji,
                              style: const TextStyle(fontSize: 40),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                template.name,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                template.description,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Kategorien
                    Text(
                      context.l10n.templatesIncludedCategories,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: template.poiCategories.map((cat) {
                        return Chip(
                          avatar: Text(cat.icon, style: const TextStyle(fontSize: 16)),
                          label: Text(cat.label),
                          backgroundColor: colorScheme.secondaryContainer,
                          labelStyle: TextStyle(
                            color: colorScheme.onSecondaryContainer,
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    // Reisedauer
                    Text(
                      context.l10n.templatesDuration,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: _selectedDays.toDouble(),
                            min: 1,
                            max: 14,
                            divisions: 13,
                            label: '$_selectedDays ${_selectedDays == 1 ? "Tag" : "Tage"}',
                            onChanged: (value) {
                              setState(() => _selectedDays = value.round());
                            },
                          ),
                        ),
                        Container(
                          width: 60,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$_selectedDays',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      context.l10n.templatesRecommended(
                        template.recommendedDays,
                        template.recommendedDays == 1
                            ? context.l10n.day
                            : context.l10n.days,
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),

                    if (template.recommendedSeason != null) ...[
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Icon(
                            Icons.wb_sunny,
                            size: 20,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            context.l10n.templatesBestSeason(_getLocalizedSeason(context, template.recommendedSeason!)),
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Start-Button
                    FilledButton.icon(
                      onPressed: () => widget.onStart(_selectedDays),
                      icon: const Icon(Icons.play_arrow),
                      label: Text(context.l10n.templatesStartPlanning),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getLocalizedSeason(BuildContext context, String season) {
    switch (season) {
      case 'fruehling':
        return context.l10n.seasonSpring;
      case 'sommer':
        return context.l10n.seasonSummer;
      case 'herbst':
        return context.l10n.seasonAutumn;
      case 'winter':
        return context.l10n.seasonWinter;
      case 'fruehling-herbst':
        return context.l10n.seasonSpringAutumn;
      case 'ganzjaehrig':
        return context.l10n.seasonYearRound;
      default:
        return season;
    }
  }
}
