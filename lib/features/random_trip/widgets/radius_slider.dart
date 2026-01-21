import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/random_trip_provider.dart';
import '../providers/random_trip_state.dart';

/// Widget zur Auswahl des Such-Radius
class RadiusSlider extends ConsumerWidget {
  const RadiusSlider({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(randomTripNotifierProvider);
    final notifier = ref.read(randomTripNotifierProvider.notifier);

    // Min/Max basierend auf Modus
    final (minRadius, maxRadius) = state.mode == RandomTripMode.daytrip
        ? (30.0, 200.0)
        : (100.0, 800.0);

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
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${currentRadius.round()} km',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
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
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppTheme.primaryColor,
            inactiveTrackColor: AppTheme.primaryColor.withOpacity(0.2),
            thumbColor: AppTheme.primaryColor,
            overlayColor: AppTheme.primaryColor.withOpacity(0.1),
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 10,
            ),
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
          children: _getQuickSelectValues(state.mode).map((value) {
            final isSelected = (currentRadius - value).abs() < 10;
            return _QuickSelectButton(
              value: value,
              isSelected: isSelected,
              onTap: () => notifier.setRadius(value),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _getRadiusDescription(double radius, RandomTripMode mode) {
    if (mode == RandomTripMode.daytrip) {
      if (radius <= 50) return 'Kurzer Ausflug in der Nahe';
      if (radius <= 100) return 'Idealer Tagesausflug';
      if (radius <= 150) return 'Ausgedehnter Tagesausflug';
      return 'Langer Tagesausflug mit viel Fahrzeit';
    } else {
      if (radius <= 200) return 'Regionale Erkundung';
      if (radius <= 400) return 'Mehrere Bundeslander/Kantone';
      if (radius <= 600) return 'Lander-ubergreifend';
      return 'Grosser Euro Trip';
    }
  }

  List<double> _getQuickSelectValues(RandomTripMode mode) {
    if (mode == RandomTripMode.daytrip) {
      return [50, 100, 150, 200];
    }
    return [200, 400, 600, 800];
  }
}

class _QuickSelectButton extends StatelessWidget {
  final double value;
  final bool isSelected;
  final VoidCallback onTap;

  const _QuickSelectButton({
    required this.value,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? AppTheme.primaryColor.withOpacity(0.15)
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
                  ? AppTheme.primaryColor
                  : Colors.grey.withOpacity(0.3),
            ),
          ),
          child: Text(
            '${value.round()} km',
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
