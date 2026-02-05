import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/journal_entry.dart';
import '../../data/providers/journal_provider.dart';
import 'widgets/journal_entry_card.dart';
import 'widgets/add_journal_entry_sheet.dart';

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
          if (journal != null && journal.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _showDeleteConfirmation(context),
              tooltip: l10n.delete,
            ),
        ],
      ),
      body: journalState.isLoading && journal == null
          ? const Center(child: CircularProgressIndicator())
          : journal == null || journal.isEmpty
              ? _buildEmptyState(context, colorScheme, l10n)
              : _buildJournalContent(context, journal, journalState, colorScheme, l10n),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEntrySheet(context),
        icon: const Icon(Icons.add_a_photo),
        label: Text(l10n.journalAddEntry),
      ),
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
    final daysWithEntries = journal.daysWithEntries;

    return CustomScrollView(
      slivers: [
        // Header mit Statistiken
        SliverToBoxAdapter(
          child: _buildHeader(context, journal, colorScheme, l10n),
        ),

        // Tagesweise Gruppierung
        if (daysWithEntries.isNotEmpty)
          ...daysWithEntries.expand((day) {
            final dayEntries = journal.entriesForDay(day);
            return [
              SliverToBoxAdapter(
                child: _buildDayHeader(context, day, dayEntries.length, colorScheme, l10n),
              ),
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
            ];
          }),

        // Eintraege ohne Tag
        if (journal.entries.any((e) => e.dayNumber == null)) ...[
          SliverToBoxAdapter(
            child: _buildDayHeader(
              context,
              null,
              journal.entries.where((e) => e.dayNumber == null).length,
              colorScheme,
              l10n,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final entries = journal.entries
                      .where((e) => e.dayNumber == null)
                      .toList();
                  final entry = entries[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: JournalEntryCard(
                      entry: entry,
                      onTap: () => _showEntryDetails(context, entry),
                      onDelete: () => _deleteEntry(entry.id),
                    ),
                  );
                },
                childCount: journal.entries
                    .where((e) => e.dayNumber == null)
                    .length,
              ),
            ),
          ),
        ],

        // Bottom Padding
        const SliverToBoxAdapter(
          child: SizedBox(height: 80),
        ),
      ],
    );
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
      ),
    );
  }

  void _showEntryDetails(BuildContext context, JournalEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _EntryDetailsSheet(entry: entry),
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

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.journalDeleteTitle),
        content: Text(l10n.journalDeleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(journalNotifierProvider.notifier).deleteJournal(widget.tripId);
      if (context.mounted) {
        context.pop();
      }
    }
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

/// Detail-Ansicht fuer einen Eintrag
class _EntryDetailsSheet extends ConsumerWidget {
  final JournalEntry entry;

  const _EntryDetailsSheet({required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
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
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          Text(
                            '${entry.formattedDate} ${entry.formattedTime}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.7),
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
