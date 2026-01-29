import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/trip_constants.dart';
import '../providers/random_trip_provider.dart';

/// Widget zur Anzeige der Reisedauer und Hotel-Optionen
/// Die Tage werden automatisch aus dem Radius berechnet (600km = 1 Tag)
class DaysSelector extends ConsumerWidget {
  const DaysSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(randomTripNotifierProvider);
    final notifier = ref.read(randomTripNotifierProvider.notifier);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Tage aus Radius berechnen
    final calculatedDays = TripConstants.calculateDaysFromDistance(state.radiusKm);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Info-Box mit berechneten Tagen
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${calculatedDays}T',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getDaysDescription(calculatedDays),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Max ${TripConstants.maxPoisPerDay} Stops pro Tag (Google Maps)',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Hotel-Vorschläge Toggle (nur bei Mehrtages-Trips)
        if (calculatedDays > 1)
          _HotelToggle(
            isEnabled: state.includeHotels,
            onChanged: (value) => notifier.toggleHotels(value),
          ),
      ],
    );
  }

  String _getDaysDescription(int days) {
    if (days == 1) return 'Tagesausflug ohne Übernachtung';
    if (days == 2) return 'Wochenend-Trip mit 1 Übernachtung';
    if (days <= 4) return 'Kurzurlaub mit ${days - 1} Übernachtungen';
    if (days <= 7) return 'Ausgedehnter Trip mit ${days - 1} Übernachtungen';
    return 'Epischer Euro Trip mit ${days - 1} Übernachtungen';
  }
}

class _HotelToggle extends StatelessWidget {
  final bool isEnabled;
  final ValueChanged<bool> onChanged;

  const _HotelToggle({
    required this.isEnabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isEnabled
                  ? Colors.purple.withOpacity(0.15)
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '🏨',
              style: TextStyle(fontSize: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hotels vorschlagen',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Übernachtungs-Vorschläge für jeden Tag',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isEnabled,
            onChanged: onChanged,
            activeColor: colorScheme.primary,
          ),
        ],
      ),
    );
  }
}
