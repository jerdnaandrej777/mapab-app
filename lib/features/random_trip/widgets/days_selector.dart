import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/trip_constants.dart';
import '../providers/random_trip_provider.dart';

class DaysSelector extends ConsumerWidget {
  const DaysSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(randomTripNotifierProvider);
    final notifier = ref.read(randomTripNotifierProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;
    final calculatedDays = state.calculatedDays;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
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
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Max ${TripConstants.maxPoisPerDay} Stops pro Tag',
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
        if (calculatedDays > 1) ...[
          _TripStartDatePicker(
            selectedDate: state.tripStartDate ?? DateTime.now(),
            onChanged: notifier.setTripStartDate,
          ),
          const SizedBox(height: 12),
          _HotelToggle(
            isEnabled: state.includeHotels,
            onChanged: notifier.toggleHotels,
          ),
        ],
      ],
    );
  }

  String _getDaysDescription(int days) {
    if (days == 1) return 'Tagesausflug ohne Uebernachtung';
    if (days == 2) return 'Wochenend-Trip mit 1 Uebernachtung';
    if (days <= 4) return 'Kurzurlaub mit ${days - 1} Uebernachtungen';
    if (days <= 7) return 'Ausgedehnter Trip mit ${days - 1} Uebernachtungen';
    return 'Euro Trip mit ${days - 1} Uebernachtungen';
  }
}

class _TripStartDatePicker extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onChanged;

  const _TripStartDatePicker({
    required this.selectedDate,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final formatted = DateFormat('dd.MM.yyyy').format(selectedDate);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_available_outlined),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Trip-Startdatum',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  formatted,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(now.year, now.month, now.day),
                lastDate: DateTime(now.year + 3),
              );
              if (picked != null) {
                onChanged(picked);
              }
            },
            child: const Text('Waehlen'),
          ),
        ],
      ),
    );
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
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isEnabled
                  ? colorScheme.primary.withValues(alpha: 0.15)
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.hotel_outlined),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hotels vorschlagen',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  'Uebernachtungs-Vorschlaege je Tag (bis 20 km)',
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
