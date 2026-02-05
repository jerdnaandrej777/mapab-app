import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/l10n.dart';
import '../../../data/providers/active_trip_provider.dart';
import '../../random_trip/providers/random_trip_provider.dart';

/// Banner zum Fortsetzen eines aktiven mehrtägigen Euro Trips
class ActiveTripResumeBanner extends ConsumerWidget {
  final VoidCallback onRestore;

  const ActiveTripResumeBanner({super.key, required this.onRestore});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTripAsync = ref.watch(activeTripNotifierProvider);
    final hasGeneratedTrip = ref.watch(
      randomTripNotifierProvider.select((s) => s.generatedTrip != null),
    );

    // Nur anzeigen wenn kein Trip aktuell in Memory geladen
    if (hasGeneratedTrip) {
      return const SizedBox.shrink();
    }

    return activeTripAsync.when(
      data: (activeTrip) {
        if (activeTrip == null) return const SizedBox.shrink();
        if (activeTrip.allDaysCompleted) return const SizedBox.shrink();

        final trip = activeTrip.trip;
        final nextDay = activeTrip.nextUncompletedDay ?? 1;
        final completedCount = activeTrip.completedDays.length;
        final totalDays = trip.actualDays;
        final progress = totalDays > 0 ? completedCount / totalDays : 0.0;

        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final isDark = theme.brightness == Brightness.dark;

        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(
                        Icons.flight_outlined,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          context.l10n.activeTripTitle,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      // Schließen-Button (Verwerfen)
                      Semantics(
                        button: true,
                        label: context.l10n.activeTripDiscard,
                        child: InkWell(
                        onTap: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(context.l10n.activeTripDiscardTitle),
                              content: Text(
                                context.l10n.activeTripDiscardMessage(totalDays, completedCount),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: Text(context.l10n.cancel),
                                ),
                                FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: colorScheme.error,
                                  ),
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: Text(context.l10n.discard),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            ref.read(activeTripNotifierProvider.notifier).clear();
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.close,
                            size: 18,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Subtitle
                  Text(
                    context.l10n.activeTripDayPending(nextDay),
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      color: colorScheme.primary,
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.activeTripDaysCompleted(completedCount, totalDays),
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Fortsetzen Button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () async {
                        await ref
                            .read(randomTripNotifierProvider.notifier)
                            .restoreFromActiveTrip(activeTrip);
                        onRestore();
                      },
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: Text(context.l10n.resume),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
