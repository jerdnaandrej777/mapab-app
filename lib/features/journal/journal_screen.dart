import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/location_helper.dart';
import '../../data/models/journal_entry.dart';
import '../../data/models/route.dart';
import '../../data/providers/journal_provider.dart';
import '../../data/repositories/geocoding_repo.dart';
import '../../data/repositories/routing_repo.dart';
import '../../shared/widgets/app_snackbar.dart';
import '../map/providers/map_controller_provider.dart';
import '../map/providers/route_planner_provider.dart';
import '../random_trip/providers/random_trip_provider.dart';
import '../trip/providers/trip_state_provider.dart';
import 'widgets/journal_entry_card.dart';
import 'widgets/add_journal_entry_sheet.dart';
import 'widgets/edit_journal_entry_sheet.dart';

enum _JournalPeriod { day, month, year }

/// Hauptscreen fuer ein Reisetagebuch
class JournalScreen extends ConsumerStatefulWidget {
  final String tripId;
  final String tripName;

  const JournalScreen({
    super.key,
    required this.tripId,
    required this.tripName,
  });

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  _JournalPeriod _period = _JournalPeriod.day;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadJournal();
    });
  }

  Future<void> _loadJournal() async {
    await ref.read(journalNotifierProvider.notifier).getOrCreateJournal(
          tripId: widget.tripId,
          tripName: widget.tripName,
        );
  }

  @override
  Widget build(BuildContext context) {
    final journalState = ref.watch(journalNotifierProvider);
    final journal = journalState.activeJournal;
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.journalTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          // Sync indicator
          if (journalState.isSyncing)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          // Manual sync button
          if (journal != null && !journalState.isSyncing)
            IconButton(
              icon: const Icon(Icons.cloud_sync),
              tooltip: 'Mit Cloud synchronisieren',
              onPressed: () => ref
                  .read(journalNotifierProvider.notifier)
                  .syncFromCloud(widget.tripId),
            ),
        ],
      ),
      body: journalState.isLoading && journal == null
          ? const Center(child: CircularProgressIndicator())
          : journal == null || journal.isEmpty
              ? _buildEmptyState(context, colorScheme, l10n)
              : _buildJournalContent(
                  context, journal, journalState, colorScheme, l10n),
      floatingActionButton: journal != null && journal.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _showAddEntrySheet(context),
              icon: const Icon(Icons.add_a_photo),
              label: Text(l10n.journalAddEntry),
            )
          : null,
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_stories_outlined,
              size: 80,
              color: colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.journalEmptyTitle,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.journalEmptySubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: () => _showAddEntrySheet(context),
              icon: const Icon(Icons.add_a_photo),
              label: Text(l10n.journalAddFirstEntry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJournalContent(
    BuildContext context,
    TripJournal journal,
    JournalState journalState,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    final bodySlivers = switch (_period) {
      _JournalPeriod.day =>
        _buildDaySlivers(context, journal, colorScheme, l10n),
      _JournalPeriod.month =>
        _buildMonthSlivers(context, journal, colorScheme, l10n),
      _JournalPeriod.year =>
        _buildYearSlivers(context, journal, colorScheme, l10n),
    };

    return CustomScrollView(
      slivers: [
        // Header mit Statistiken
        SliverToBoxAdapter(
          child: _buildHeader(context, journal, colorScheme, l10n),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: _buildPeriodSwitcher(context, colorScheme),
          ),
        ),
        ...bodySlivers,

        // Bottom Padding
        const SliverToBoxAdapter(
          child: SizedBox(height: 80),
        ),
      ],
    );
  }

  Widget _buildPeriodSwitcher(BuildContext context, ColorScheme colorScheme) {
    return SegmentedButton<_JournalPeriod>(
      segments: [
        ButtonSegment<_JournalPeriod>(
          value: _JournalPeriod.day,
          icon: const Icon(Icons.view_day_outlined),
          label: Text(_periodLabel(context, _JournalPeriod.day)),
        ),
        ButtonSegment<_JournalPeriod>(
          value: _JournalPeriod.month,
          icon: const Icon(Icons.calendar_view_month_outlined),
          label: Text(_periodLabel(context, _JournalPeriod.month)),
        ),
        ButtonSegment<_JournalPeriod>(
          value: _JournalPeriod.year,
          icon: const Icon(Icons.calendar_today_outlined),
          label: Text(_periodLabel(context, _JournalPeriod.year)),
        ),
      ],
      selected: {_period},
      onSelectionChanged: (selection) {
        if (selection.isEmpty) return;
        setState(() => _period = selection.first);
      },
      style: SegmentedButton.styleFrom(
        backgroundColor: colorScheme.surface,
        selectedBackgroundColor:
            colorScheme.primaryContainer.withValues(alpha: 0.5),
      ),
    );
  }

  String _periodLabel(BuildContext context, _JournalPeriod period) {
    final language = Localizations.localeOf(context).languageCode;
    switch (period) {
      case _JournalPeriod.day:
        return switch (language) {
          'en' => 'Day',
          'fr' => 'Jour',
          'it' => 'Giorno',
          'es' => 'Dia',
          _ => 'Tag',
        };
      case _JournalPeriod.month:
        return switch (language) {
          'en' => 'Month',
          'fr' => 'Mois',
          'it' => 'Mese',
          'es' => 'Mes',
          _ => 'Monat',
        };
      case _JournalPeriod.year:
        return switch (language) {
          'en' => 'Year',
          'fr' => 'Annee',
          'it' => 'Anno',
          'es' => 'Ano',
          _ => 'Jahr',
        };
    }
  }

  List<Widget> _buildDaySlivers(
    BuildContext context,
    TripJournal journal,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    final daysWithEntries = journal.daysWithEntries;
    final slivers = <Widget>[];

    if (daysWithEntries.isNotEmpty) {
      for (final day in daysWithEntries) {
        final dayEntries = journal.entriesForDay(day);
        slivers.add(
          SliverToBoxAdapter(
            child: _buildDayHeader(
              context,
              day,
              dayEntries.length,
              colorScheme,
              l10n,
            ),
          ),
        );
        slivers.add(
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final entry = dayEntries[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: JournalEntryCard(
                      entry: entry,
                      onTap: () => _showEntryDetails(context, entry),
                      onDelete: () => _deleteEntry(entry.id),
                    ),
                  );
                },
                childCount: dayEntries.length,
              ),
            ),
          ),
        );
      }
    }

    final unassigned =
        journal.entries.where((e) => e.dayNumber == null).toList();
    if (unassigned.isNotEmpty) {
      slivers.add(
        SliverToBoxAdapter(
          child: _buildDayHeader(
            context,
            null,
            unassigned.length,
            colorScheme,
            l10n,
          ),
        ),
      );
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final entry = unassigned[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: JournalEntryCard(
                    entry: entry,
                    onTap: () => _showEntryDetails(context, entry),
                    onDelete: () => _deleteEntry(entry.id),
                  ),
                );
              },
              childCount: unassigned.length,
            ),
          ),
        ),
      );
    }

    return slivers;
  }

  List<Widget> _buildMonthSlivers(
    BuildContext context,
    TripJournal journal,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    final months = journal.monthsWithEntries;
    if (months.isEmpty) return const [];

    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final month = months[index];
              final entries = journal.entriesByMonth[month] ?? const [];
              final photoCount = entries.where((e) => e.hasImage).length;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _TimelineOverviewCard(
                  icon: Icons.calendar_view_month_outlined,
                  title: _formatMonthYear(context, month),
                  subtitle:
                      '${entries.length} ${entries.length == 1 ? l10n.journalEntry : l10n.journalEntriesPlural}',
                  leadingValue: l10n.journalPhotos(photoCount),
                  trailingValue: l10n.journalEntries(entries.length),
                  colorScheme: colorScheme,
                  onTap: () => _showFilteredEntriesSheet(
                    context,
                    title: _formatMonthYear(context, month),
                    entries: entries,
                  ),
                ),
              );
            },
            childCount: months.length,
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildYearSlivers(
    BuildContext context,
    TripJournal journal,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    final years = journal.yearsWithEntries;
    if (years.isEmpty) return const [];

    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final year = years[index];
              final entries = journal.entriesByYear[year] ?? const [];
              final photoCount = entries.where((e) => e.hasImage).length;
              final activeMonths = entries
                  .map((e) => DateTime(e.createdAt.year, e.createdAt.month))
                  .toSet()
                  .length;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _YearOverviewCard(
                  year: year,
                  entries: entries,
                  photoCount: photoCount,
                  activeMonths: activeMonths,
                  l10n: l10n,
                  colorScheme: colorScheme,
                  onOpen: () => _showFilteredEntriesSheet(
                    context,
                    title: '$year',
                    entries: entries,
                  ),
                ),
              );
            },
            childCount: years.length,
          ),
        ),
      ),
    ];
  }

  String _formatMonthYear(BuildContext context, DateTime month) {
    final localizations = MaterialLocalizations.of(context);
    return localizations.formatMonthYear(month);
  }

  Widget _buildHeader(
    BuildContext context,
    TripJournal journal,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            journal.tripName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _StatChip(
                icon: Icons.photo_library_outlined,
                label: l10n.journalPhotos(journal.photoCount),
                colorScheme: colorScheme,
              ),
              const SizedBox(width: AppSpacing.sm),
              _StatChip(
                icon: Icons.edit_note,
                label: l10n.journalEntries(journal.entryCount),
                colorScheme: colorScheme,
              ),
              const SizedBox(width: AppSpacing.sm),
              _StatChip(
                icon: Icons.calendar_today_outlined,
                label: journal.daysWithEntries.length == 1
                    ? l10n.journalDay(1)
                    : l10n.journalDays(journal.daysWithEntries.length),
                colorScheme: colorScheme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayHeader(
    BuildContext context,
    int? day,
    int entryCount,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              day != null ? l10n.journalDayNumber(day) : l10n.journalOther,
              style: TextStyle(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '$entryCount ${entryCount == 1 ? l10n.journalEntry : l10n.journalEntriesPlural}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
          ),
        ],
      ),
    );
  }

  void _showAddEntrySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => AddJournalEntrySheet(
        tripId: widget.tripId,
        tripName: widget.tripName,
      ),
    );
  }

  void _showEntryDetails(BuildContext context, JournalEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _EntryDetailsSheet(
        entry: entry,
        onShowOnMap: entry.location == null
            ? null
            : () {
                Navigator.pop(context);
                _showLocationPreview(entry);
              },
        onOpenPoiDetails: entry.poiId == null
            ? null
            : () => this.context.push('/poi/${entry.poiId}'),
        onEdit: () => _showEditEntrySheet(entry),
      ),
    );
  }

  void _showLocationPreview(JournalEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _LocationPreviewSheet(
        entry: entry,
        onCancel: () => Navigator.pop(ctx),
        onRevisit: () {
          Navigator.pop(ctx);
          _showRoutePlanSheet(entry);
        },
      ),
    );
  }

  void _showRoutePlanSheet(JournalEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _RoutePlanSheet(
        entry: entry,
        onRouteCalculated: (route) {
          Navigator.pop(ctx);
          _navigateToMapWithRoute(route);
        },
      ),
    );
  }

  void _navigateToMapWithRoute(AppRoute route) {
    // Stale State zuruecksetzen
    ref.read(randomTripNotifierProvider.notifier).reset();
    ref.read(routePlannerProvider.notifier).clearRoute();
    ref.read(tripStateProvider.notifier).clearAll();

    // Berechnete Route setzen
    ref.read(tripStateProvider.notifier).setRouteAndStops(route, []);

    // Focus-Mode auf Karte aktivieren
    ref.read(shouldFitToRouteProvider.notifier).state = true;
    ref.read(mapRouteFocusModeProvider.notifier).state = true;

    // Zur Karte navigieren
    context.go('/');
  }

  void _showEditEntrySheet(JournalEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => EditJournalEntrySheet(entry: entry),
    );
  }

  Future<void> _deleteEntry(String entryId) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.journalDeleteEntryTitle),
        content: Text(l10n.journalDeleteEntryMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(journalNotifierProvider.notifier).deleteEntry(entryId);
    }
  }

  void _showFilteredEntriesSheet(
    BuildContext parentContext, {
    required String title,
    required List<JournalEntry> entries,
  }) {
    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 1.0,
        minChildSize: 0.9,
        maxChildSize: 1.0,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.lg),
              ),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: AppSpacing.sm),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: JournalEntryCard(
                          entry: entry,
                          onTap: () {
                            Navigator.pop(context);
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!mounted) return;
                              _showEntryDetails(parentContext, entry);
                            });
                          },
                          onDelete: () {
                            Navigator.pop(context);
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!mounted) return;
                              _deleteEntry(entry.id);
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Statistik-Chip
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme colorScheme;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineOverviewCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String leadingValue;
  final String trailingValue;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _TimelineOverviewCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.leadingValue,
    required this.trailingValue,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: isDark ? 0.28 : 0.08),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _MiniStatPill(
                    icon: Icons.photo_library_outlined,
                    label: leadingValue,
                    colorScheme: colorScheme,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniStatPill(
                    icon: Icons.edit_note,
                    label: trailingValue,
                    colorScheme: colorScheme,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _YearOverviewCard extends StatelessWidget {
  final int year;
  final List<JournalEntry> entries;
  final int photoCount;
  final int activeMonths;
  final AppLocalizations l10n;
  final ColorScheme colorScheme;
  final VoidCallback onOpen;

  const _YearOverviewCard({
    required this.year,
    required this.entries,
    required this.photoCount,
    required this.activeMonths,
    required this.l10n,
    required this.colorScheme,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: isDark ? 0.28 : 0.08),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart_rounded,
                    size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$year',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _MiniStatPill(
                    icon: Icons.photo_library_outlined,
                    label: l10n.journalPhotos(photoCount),
                    colorScheme: colorScheme,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniStatPill(
                    icon: Icons.edit_note,
                    label: l10n.journalEntries(entries.length),
                    colorScheme: colorScheme,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniStatPill(
                    icon: Icons.calendar_view_month,
                    label: '$activeMonths',
                    colorScheme: colorScheme,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme colorScheme;

  const _MiniStatPill({
    required this.icon,
    required this.label,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: colorScheme.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Detail-Ansicht fuer einen Eintrag
/// Modal mit Kartenvorschau eines Journal-Eintrags
class _LocationPreviewSheet extends StatefulWidget {
  final JournalEntry entry;
  final VoidCallback onCancel;
  final VoidCallback onRevisit;

  const _LocationPreviewSheet({
    required this.entry,
    required this.onCancel,
    required this.onRevisit,
  });

  @override
  State<_LocationPreviewSheet> createState() => _LocationPreviewSheetState();
}

class _LocationPreviewSheetState extends State<_LocationPreviewSheet> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final location = widget.entry.location!;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 1.0,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.lg),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: AppSpacing.sm),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Icon(Icons.place, color: colorScheme.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        widget.entry.poiName ??
                            context.l10n.journalMemoryPoint,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: widget.onCancel,
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Karte
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: location,
                        initialZoom: 14,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.pinchZoom |
                              InteractiveFlag.drag,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.travelplanner.app',
                          maxZoom: 19,
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: location,
                              width: 40,
                              height: 40,
                              child: Icon(
                                Icons.location_on,
                                color: colorScheme.primary,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Notiz-Preview
              if (widget.entry.hasNote)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Text(
                    widget.entry.note!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color:
                              colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

              // Buttons
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: widget.onCancel,
                          icon: const Icon(Icons.close, size: 18),
                          label: Text(context.l10n.cancel),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: widget.onRevisit,
                          icon: const Icon(Icons.route, size: 18),
                          label: Text(context.l10n.journalRevisit),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Modal zum Planen einer Route zum Journal-POI
class _RoutePlanSheet extends ConsumerStatefulWidget {
  final JournalEntry entry;
  final void Function(AppRoute route) onRouteCalculated;

  const _RoutePlanSheet({
    required this.entry,
    required this.onRouteCalculated,
  });

  @override
  ConsumerState<_RoutePlanSheet> createState() => _RoutePlanSheetState();
}

class _RoutePlanSheetState extends ConsumerState<_RoutePlanSheet> {
  bool _useGps = true;
  LatLng? _startLocation;
  String? _startAddress;
  final _addressController = TextEditingController();
  final _focusNode = FocusNode();
  List<GeocodingResult> _suggestions = [];
  bool _isSearching = false;
  bool _isCalculating = false;
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _addressController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    if (query.length < 3) {
      setState(() => _suggestions = []);
      return;
    }
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _searchAddress(query);
    });
  }

  Future<void> _searchAddress(String query) async {
    if (!mounted) return;
    setState(() => _isSearching = true);

    try {
      final geocodingRepo = ref.read(geocodingRepositoryProvider);
      final results = await geocodingRepo.geocode(query);
      if (!mounted) return;
      setState(() {
        _suggestions = results.take(5).toList();
        _isSearching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _suggestions = [];
        _isSearching = false;
      });
    }
  }

  void _selectSuggestion(GeocodingResult result) {
    _addressController.text = result.shortName ?? result.displayName;
    setState(() {
      _useGps = false;
      _startLocation = result.location;
      _startAddress = result.shortName ?? result.displayName;
      _suggestions = [];
    });
    _focusNode.unfocus();
  }

  Future<void> _calculateRoute() async {
    setState(() => _isCalculating = true);

    try {
      LatLng startLatLng;
      String startName;

      if (_useGps || _startLocation == null) {
        final result = await LocationHelper.getCurrentPosition();
        if (!mounted) return;
        if (result.position == null) {
          await LocationHelper.showGpsDialog(context);
          if (mounted) setState(() => _isCalculating = false);
          return;
        }
        startLatLng = result.position!;
        startName = context.l10n.journalCurrentLocation;
      } else {
        startLatLng = _startLocation!;
        startName = _startAddress ?? '';
      }

      final destination = widget.entry.location!;
      final destinationName =
          widget.entry.poiName ?? context.l10n.journalMemoryPoint;

      final routingRepo = ref.read(routingRepositoryProvider);
      final route = await routingRepo.calculateFastRoute(
        start: startLatLng,
        end: destination,
        startAddress: startName,
        endAddress: destinationName,
      );

      if (!mounted) return;
      widget.onRouteCalculated(route);
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(
        context,
        context.l10n.errorRouteCalculation,
      );
    } finally {
      if (mounted) setState(() => _isCalculating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.5,
      maxChildSize: 1.0,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.lg),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: AppSpacing.sm),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.l10n.journalPlanRoute,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    // Start-Sektion
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 16, color: colorScheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          context.l10n.journalStartPoint,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // GPS-Button
                    InkWell(
                      onTap: () {
                        setState(() {
                          _useGps = true;
                          _startLocation = null;
                          _startAddress = null;
                          _addressController.clear();
                          _suggestions = [];
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: _useGps
                              ? colorScheme.primaryContainer
                              : colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _useGps
                                ? colorScheme.primary
                                : colorScheme.outline
                                    .withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.my_location,
                              size: 18,
                              color: _useGps
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              context.l10n.journalCurrentLocation,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: _useGps
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const Spacer(),
                            if (_useGps)
                              Icon(
                                Icons.check_circle,
                                size: 18,
                                color: colorScheme.primary,
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Adress-Eingabe
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: !_useGps && _startLocation != null
                              ? colorScheme.primary
                              : colorScheme.outline
                                  .withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _addressController,
                            focusNode: _focusNode,
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: context.l10n.mapCityOrAddress,
                              hintStyle: TextStyle(
                                  fontSize: 13,
                                  color: colorScheme.onSurfaceVariant),
                              prefixIcon: Icon(Icons.search,
                                  size: 18,
                                  color: colorScheme.onSurfaceVariant),
                              suffixIcon: _isSearching
                                  ? const Padding(
                                      padding: EdgeInsets.all(10),
                                      child: SizedBox(
                                        width: 14,
                                        height: 14,
                                        child:
                                            CircularProgressIndicator(
                                                strokeWidth: 2),
                                      ),
                                    )
                                  : _addressController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(
                                              Icons.clear,
                                              size: 16),
                                          onPressed: () {
                                            _addressController.clear();
                                            setState(() {
                                              _suggestions = [];
                                              _useGps = true;
                                              _startLocation = null;
                                              _startAddress = null;
                                            });
                                          },
                                        )
                                      : null,
                              border: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                              isDense: true,
                            ),
                            onChanged: _onSearchChanged,
                          ),
                          if (_suggestions.isNotEmpty)
                            Container(
                              constraints:
                                  const BoxConstraints(maxHeight: 150),
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                      color: colorScheme.outline
                                          .withValues(alpha: 0.2)),
                                ),
                              ),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: _suggestions.length,
                                itemBuilder: (context, index) {
                                  final result = _suggestions[index];
                                  return InkWell(
                                    onTap: () =>
                                        _selectSuggestion(result),
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8),
                                      child: Row(
                                        children: [
                                          Icon(Icons.location_on,
                                              size: 14,
                                              color:
                                                  colorScheme.primary),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              result.shortName ??
                                                  result.displayName,
                                              style: const TextStyle(
                                                  fontSize: 12),
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Ziel-Sektion (read-only)
                    Row(
                      children: [
                        Icon(Icons.flag,
                            size: 16, color: colorScheme.error),
                        const SizedBox(width: 6),
                        Text(
                          context.l10n.journalDestination,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: colorScheme.outline
                              .withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.place,
                              size: 18, color: colorScheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.entry.poiName ??
                                  context.l10n.journalMemoryPoint,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Action-Button
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed:
                          _isCalculating ? null : _calculateRoute,
                      icon: _isCalculating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2),
                            )
                          : const Icon(Icons.route, size: 18),
                      label: Text(
                          context.l10n.journalCalculateRoute),
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
}

class _EntryDetailsSheet extends ConsumerWidget {
  final JournalEntry entry;
  final VoidCallback? onShowOnMap;
  final VoidCallback? onOpenPoiDetails;
  final VoidCallback? onEdit;

  const _EntryDetailsSheet({
    required this.entry,
    this.onShowOnMap,
    this.onOpenPoiDetails,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.lg),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: AppSpacing.sm),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (entry.poiName != null)
                            Text(
                              entry.poiName!,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          Text(
                            '${entry.formattedDate} ${entry.formattedTime}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurface
                                          .withValues(alpha: 0.7),
                                    ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ),
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      if (onEdit != null)
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            onEdit?.call();
                          },
                          icon: const Icon(Icons.edit_outlined),
                          label: Text(context.l10n.journalEditEntry),
                        ),
                      if (onShowOnMap != null)
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            onShowOnMap?.call();
                          },
                          icon: const Icon(Icons.map_outlined),
                          label: Text(context.l10n.showOnMap),
                        ),
                      if (onOpenPoiDetails != null)
                        FilledButton.tonalIcon(
                          onPressed: () {
                            Navigator.pop(context);
                            onOpenPoiDetails?.call();
                          },
                          icon: const Icon(Icons.place_outlined),
                          label: Text(context.l10n.details),
                        ),
                    ],
                  ),
                ),

              const Divider(height: 1),

              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    // Bild
                    if (entry.hasImage)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: entry.imagePath != null
                            ? Image.file(
                                File(entry.imagePath!),
                                fit: BoxFit.cover,
                              )
                            : Image.network(
                                entry.imageUrl!,
                                fit: BoxFit.cover,
                              ),
                      ),

                    // Notiz
                    if (entry.hasNote) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        entry.note!,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],

                    // Standort
                    if (entry.locationName != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 20,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            entry.locationName!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
