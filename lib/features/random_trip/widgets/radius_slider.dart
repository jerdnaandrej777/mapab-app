import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/trip_constants.dart';
import '../providers/random_trip_provider.dart';
import '../providers/random_trip_state.dart';

/// Widget zur Auswahl des Such-Radius (Tagestrip) oder der Reisedauer (Euro Trip)
class RadiusSlider extends ConsumerWidget {
  const RadiusSlider({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(randomTripNotifierProvider);
    final notifier = ref.read(randomTripNotifierProvider.notifier);

    if (state.mode == RandomTripMode.eurotrip) {
      return _buildDaysSelector(context, state, notifier);
    }
    return _buildRadiusSlider(context, state, notifier);
  }

  /// Euro Trip: Tage-Auswahl als primärer Input
  Widget _buildDaysSelector(
    BuildContext context,
    RandomTripState state,
    RandomTripNotifier notifier,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentDays = state.days.clamp(
      TripConstants.euroTripMinDays,
      TripConstants.euroTripMaxDays,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Reisedauer',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '$currentDays ${currentDays == 1 ? "Tag" : "Tage"}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _getDaysDescription(currentDays),
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: colorScheme.primary,
            inactiveTrackColor: colorScheme.primary.withValues(alpha: 0.2),
            thumbColor: colorScheme.primary,
            overlayColor: colorScheme.primary.withValues(alpha: 0.1),
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
          ),
          child: Slider(
            value: currentDays.toDouble(),
            min: TripConstants.euroTripMinDays.toDouble(),
            max: TripConstants.euroTripMaxDays.toDouble(),
            divisions:
                TripConstants.euroTripMaxDays - TripConstants.euroTripMinDays,
            onChanged: (value) => notifier.setEuroTripDays(value.round()),
          ),
        ),
        // Quick Select Tage
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: TripConstants.euroTripQuickSelectDays.map((days) {
            final isSelected = currentDays == days;
            return _QuickSelectButton(
              label: '$days Tage',
              isSelected: isSelected,
              onTap: () => notifier.setEuroTripDays(days),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Tagestrip: Radius-Slider (unverändert)
  Widget _buildRadiusSlider(
    BuildContext context,
    RandomTripState state,
    RandomTripNotifier notifier,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    const minRadius = 30.0;
    const maxRadius = 500.0;
    final currentRadius = state.radiusKm.clamp(minRadius, maxRadius);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Radius',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${currentRadius.round()} km',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _getRadiusDescription(currentRadius),
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: colorScheme.primary,
            inactiveTrackColor: colorScheme.primary.withValues(alpha: 0.2),
            thumbColor: colorScheme.primary,
            overlayColor: colorScheme.primary.withValues(alpha: 0.1),
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
          ),
          child: Slider(
            value: currentRadius,
            min: minRadius,
            max: maxRadius,
            divisions: ((maxRadius - minRadius) / 10).round(),
            onChanged: (value) => notifier.setRadius(value),
          ),
        ),
        // Quick Select Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: TripConstants.dayTripQuickSelectRadii.map((value) {
            final isSelected = (currentRadius - value).abs() < 50;
            return _QuickSelectButton(
              label: '${value.round()} km',
              isSelected: isSelected,
              onTap: () => notifier.setRadius(value),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _getRadiusDescription(double radius) {
    if (radius <= 50) return 'Kurzer Ausflug in der Nähe';
    if (radius <= 100) return 'Idealer Tagesausflug';
    if (radius <= 150) return 'Ausgedehnter Tagesausflug';
    if (radius <= 300) return 'Langer Tagesausflug mit viel Fahrzeit';
    if (radius <= 400) return 'Sehr weiter Tagesausflug';
    return 'Maximaler Suchraum (Route wird trotzdem hart begrenzt)';
  }

  String _getDaysDescription(int days) {
    final radiusKm = (days * TripConstants.kmPerDay).round();
    if (days == 1) {
      return 'POI-Suchraum bis $radiusKm km, Tagesroute bleibt <=700 km';
    }
    if (days == 2) {
      return 'Wochenend-Trip: Suchraum bis $radiusKm km, max. 700 km/Tag';
    }
    if (days <= 4) {
      return 'Kurzurlaub: Suchraum bis $radiusKm km, Route auf 700 km/Tag begrenzt';
    }
    if (days <= 7) {
      return 'Wochenreise: Suchraum bis $radiusKm km, Tageslimit 700 km';
    }
    return 'Euro Trip: Suchraum bis $radiusKm km, Hardlimit 700 km/Tag';
  }
}

class _QuickSelectButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _QuickSelectButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
