import 'package:flutter/material.dart';
import '../../../core/l10n/l10n.dart';
import '../../random_trip/providers/random_trip_state.dart';

/// Loading-Anzeige während Trip generiert wird
class GeneratingIndicator extends StatelessWidget {
  const GeneratingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation(colorScheme.primary),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '🎲',
            style: TextStyle(fontSize: 32),
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.tripInfoGenerating,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.tripInfoLoadingPois,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Kompakte Trip-Info-Leiste nach Generierung
/// Zeigt Route-Zusammenfassung mit "Bearbeiten" und "Löschen" Buttons
class TripInfoBar extends StatelessWidget {
  final RandomTripState randomTripState;
  final VoidCallback onEdit;
  final VoidCallback onClearRoute;
  final VoidCallback? onStartNavigation;

  const TripInfoBar({
    super.key,
    required this.randomTripState,
    required this.onEdit,
    required this.onClearRoute,
    this.onStartNavigation,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stats = randomTripState.tripStats;
    final isEuroTrip = randomTripState.mode == RandomTripMode.eurotrip;
    final trip = randomTripState.generatedTrip?.trip;
    final poisCount = randomTripState.generatedTrip?.selectedPOIs.length ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header-Zeile
            Row(
              children: [
                // Route-Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isEuroTrip ? Icons.flight_outlined : Icons.wb_sunny,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                // Titel + Stats
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEuroTrip ? context.l10n.tripInfoAiEuroTrip : context.l10n.tripInfoAiDayTrip,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      if (stats != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          stats,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Löschen-Button
                IconButton(
                  onPressed: onClearRoute,
                  icon: Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: colorScheme.error,
                  ),
                  tooltip: context.l10n.tripConfigDeleteRoute,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Kompakte Stats-Zeile
            if (trip != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MiniStat(
                    icon: Icons.place,
                    value: '$poisCount',
                    label: context.l10n.tripInfoStops,
                    color: colorScheme.primary,
                  ),
                  _MiniStat(
                    icon: Icons.straighten,
                    value: '${trip.route.distanceKm.toStringAsFixed(0)} km',
                    label: context.l10n.tripInfoDistance,
                    color: colorScheme.primary,
                  ),
                  if (trip.actualDays > 1)
                    _MiniStat(
                      icon: Icons.calendar_today,
                      value: '${trip.actualDays}',
                      label: context.l10n.tripInfoDaysLabel,
                      color: colorScheme.primary,
                    ),
                ],
              ),

            const SizedBox(height: 10),

            // Bearbeiten-Button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit, size: 18),
                label: Text(context.l10n.tripInfoEditTrip),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            // Navigation starten Button (v1.9.0)
            if (onStartNavigation != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onStartNavigation,
                  icon: const Icon(Icons.navigation, size: 18),
                  label: Text(context.l10n.tripInfoStartNavigation),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Mini-Statistik-Chip fuer TripInfoBar
class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _MiniStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
