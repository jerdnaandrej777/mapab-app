import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/random_trip_provider.dart';

/// Widget zur Auswahl der Reisedauer (Tage)
class DaysSelector extends ConsumerWidget {
  const DaysSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(randomTripNotifierProvider);
    final notifier = ref.read(randomTripNotifierProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reisedauer',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          _getDaysDescription(state.days),
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(7, (index) {
            final days = index + 1;
            final isSelected = state.days == days;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: index < 6 ? 6 : 0,
                ),
                child: _DayButton(
                  days: days,
                  isSelected: isSelected,
                  onTap: () => notifier.setDays(days),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        // Hotel-Vorschlage Toggle
        _HotelToggle(
          isEnabled: state.includeHotels,
          onChanged: (value) => notifier.toggleHotels(value),
        ),
      ],
    );
  }

  String _getDaysDescription(int days) {
    if (days == 1) return 'Tagesausflug ohne Ubernachtung';
    if (days == 2) return 'Wochenend-Trip mit 1 Ubernachtung';
    if (days <= 4) return 'Kurzurlaub mit ${days - 1} Ubernachtungen';
    return 'Ausgedehnter Trip mit ${days - 1} Ubernachtungen';
  }
}

class _DayButton extends StatelessWidget {
  final int days;
  final bool isSelected;
  final VoidCallback onTap;

  const _DayButton({
    required this.days,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? AppTheme.primaryColor
          : Colors.grey.withOpacity(0.1),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? AppTheme.primaryColor
                  : Colors.grey.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: [
              Text(
                '$days',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                days == 1 ? 'Tag' : 'Tage',
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected
                      ? Colors.white.withOpacity(0.8)
                      : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isEnabled
                  ? Colors.purple.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '🏨',
              style: const TextStyle(fontSize: 20),
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
                  'Ubernachtungs-Vorschlage fur jeden Tag',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isEnabled,
            onChanged: onChanged,
            activeColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }
}
