import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/trip_constants.dart';
import '../providers/random_trip_provider.dart';
import '../providers/random_trip_state.dart';

/// Widget zur Auswahl des Such-Radius
class RadiusSlider extends ConsumerWidget {
  const RadiusSlider({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(randomTripNotifierProvider);
    final notifier = ref.read(randomTripNotifierProvider.notifier);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Min/Max basierend auf Modus
    final (minRadius, maxRadius) = state.mode == RandomTripMode.daytrip
        ? (30.0, 300.0)
        : (100.0, 5000.0);

    // Radius anpassen falls ausserhalb der Grenzen
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
                _formatRadiusDisplay(currentRadius, state.mode),
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
          _getRadiusDescription(currentRadius, state.mode),
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: colorScheme.primary,
            inactiveTrackColor: colorScheme.primary.withOpacity(0.2),
            thumbColor: colorScheme.primary,
            overlayColor: colorScheme.primary.withOpacity(0.1),
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 10,
            ),
          ),
          child: Slider(
            value: currentRadius,
            min: minRadius,
            max: maxRadius,
            divisions: state.mode == RandomTripMode.daytrip
                ? ((maxRadius - minRadius) / 10).round()
                : ((maxRadius - minRadius) / 100).round(),
            onChanged: (value) => notifier.setRadius(value),
          ),
        ),
        // Quick Select Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: _getQuickSelectValues(state.mode).map((value) {
            final isSelected = (currentRadius - value).abs() < 50;
            return _QuickSelectButton(
              value: value,
              isSelected: isSelected,
              isEuroTrip: state.mode == RandomTripMode.eurotrip,
              onTap: () => notifier.setRadius(value),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _getRadiusDescription(double radius, RandomTripMode mode) {
    if (mode == RandomTripMode.daytrip) {
      if (radius <= 50) return 'Kurzer Ausflug in der Nähe';
      if (radius <= 100) return 'Idealer Tagesausflug';
      if (radius <= 150) return 'Ausgedehnter Tagesausflug';
      if (radius <= 200) return 'Langer Tagesausflug mit viel Fahrzeit';
      return 'Sehr weiter Tagesausflug';
    } else {
      if (radius <= 300) return 'Regionale Erkundung';
      if (radius <= 600) return 'Mehrere Bundesländer/Kantone';
      if (radius <= 1000) return 'Länder-übergreifend';
      if (radius <= 2000) return 'Großer Euro Trip';
      if (radius <= 3500) return 'Kontinentale Reise';
      return 'Epischer Europa-Trip';
    }
  }

  List<double> _getQuickSelectValues(RandomTripMode mode) {
    if (mode == RandomTripMode.daytrip) {
      return TripConstants.dayTripQuickSelectRadii;
    }
    return TripConstants.euroTripQuickSelectRadii;
  }

  String _formatRadiusDisplay(double radius, RandomTripMode mode) {
    if (mode == RandomTripMode.eurotrip) {
      final days = TripConstants.calculateDaysFromDistance(radius);
      return '$days ${days == 1 ? 'Tag' : 'Tage'} (${radius.round()} km)';
    }
    return '${radius.round()} km';
  }
}

class _QuickSelectButton extends StatelessWidget {
  final double value;
  final bool isSelected;
  final bool isEuroTrip;
  final VoidCallback onTap;

  const _QuickSelectButton({
    required this.value,
    required this.isSelected,
    required this.onTap,
    this.isEuroTrip = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Label erstellen: Bei Euro Trip Tage anzeigen
    String label;
    if (isEuroTrip) {
      final days = TripConstants.calculateDaysFromDistance(value);
      label = '$days ${days == 1 ? 'Tag' : 'Tage'}';
    } else {
      label = '${value.round()} km';
    }

    return Material(
      color: isSelected
          ? colorScheme.primaryContainer
          : Colors.transparent,
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
                  : colorScheme.outline.withOpacity(0.3),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
