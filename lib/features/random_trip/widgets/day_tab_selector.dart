import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/trip_constants.dart';
import '../providers/random_trip_provider.dart';

/// Widget zur Auswahl des Tages bei Mehrtages-Trips
/// Zeigt horizontale Tabs mit Tagesinformationen
class DayTabSelector extends ConsumerWidget {
  const DayTabSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(randomTripNotifierProvider);
    final notifier = ref.read(randomTripNotifierProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    final trip = state.generatedTrip?.trip;
    if (trip == null) return const SizedBox.shrink();

    final totalDays = trip.actualDays;
    if (totalDays <= 1) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tagesauswahl',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                '${state.completedDays.length}/$totalDays exportiert',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 56,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: totalDays,
            itemBuilder: (context, index) {
              final dayNumber = index + 1;
              final isSelected = dayNumber == state.selectedDay;
              final isCompleted = state.completedDays.contains(dayNumber);
              final stopsForDay = trip.getStopsForDay(dayNumber);
              final isOverLimit = stopsForDay.length > TripConstants.maxPoisPerDay;

              return Padding(
                padding: EdgeInsets.only(
                  left: index == 0 ? 0 : 4,
                  right: index == totalDays - 1 ? 0 : 4,
                ),
                child: _DayTab(
                  dayNumber: dayNumber,
                  stopCount: stopsForDay.length,
                  isSelected: isSelected,
                  isCompleted: isCompleted,
                  isOverLimit: isOverLimit,
                  onTap: () => notifier.selectDay(dayNumber),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DayTab extends StatelessWidget {
  final int dayNumber;
  final int stopCount;
  final bool isSelected;
  final bool isCompleted;
  final bool isOverLimit;
  final VoidCallback onTap;

  const _DayTab({
    required this.dayNumber,
    required this.stopCount,
    required this.isSelected,
    required this.isCompleted,
    required this.isOverLimit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Color backgroundColor;
    Color borderColor;
    Color textColor;

    if (isSelected) {
      backgroundColor = colorScheme.primary;
      borderColor = colorScheme.primary;
      textColor = colorScheme.onPrimary;
    } else if (isCompleted) {
      backgroundColor = Colors.green.withOpacity(0.1);
      borderColor = Colors.green;
      textColor = Colors.green;
    } else {
      backgroundColor = colorScheme.surfaceContainerHighest;
      borderColor = colorScheme.outline.withOpacity(0.3);
      textColor = colorScheme.onSurface;
    }

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isCompleted && !isSelected)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(
                        Icons.check_circle,
                        size: 14,
                        color: textColor,
                      ),
                    ),
                  Text(
                    'Tag $dayNumber',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: textColor,
                    ),
                  ),
                  if (isOverLimit)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Icon(
                        Icons.warning_amber,
                        size: 14,
                        color: isSelected ? Colors.yellow : Colors.orange,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '$stopCount Stops',
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected
                      ? textColor.withOpacity(0.8)
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
