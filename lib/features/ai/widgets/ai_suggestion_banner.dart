import 'package:flutter/material.dart';
import '../../../core/constants/categories.dart';

/// Banner für AI-basierte Wetter-Vorschläge im Day Editor
/// Erscheint wenn das Wetter für den ausgewählten Tag schlecht ist
class AISuggestionBanner extends StatelessWidget {
  final WeatherCondition dayWeather;
  final int outdoorCount;
  final int totalCount;
  final int dayNumber;
  final VoidCallback? onSuggestAlternatives;
  final VoidCallback? onDismiss;

  const AISuggestionBanner({
    super.key,
    required this.dayWeather,
    required this.outdoorCount,
    required this.totalCount,
    required this.dayNumber,
    this.onSuggestAlternatives,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Nur anzeigen bei schlechtem Wetter UND Outdoor-POIs
    if (dayWeather != WeatherCondition.bad &&
        dayWeather != WeatherCondition.danger) {
      return const SizedBox.shrink();
    }
    if (outdoorCount == 0) return const SizedBox.shrink();

    final isDanger = dayWeather == WeatherCondition.danger;
    final bgColor =
        isDanger ? colorScheme.errorContainer : colorScheme.tertiaryContainer;
    final fgColor = isDanger
        ? colorScheme.onErrorContainer
        : colorScheme.onTertiaryContainer;
    final icon = isDanger ? Icons.warning_rounded : Icons.cloud;
    final weatherText = isDanger ? 'Unwetter' : 'Regen';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: fgColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: fgColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$weatherText auf Tag $dayNumber erwartet',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: fgColor,
                  ),
                ),
              ),
              if (onDismiss != null)
                GestureDetector(
                  onTap: onDismiss,
                  child: Icon(
                    Icons.close,
                    size: 18,
                    color: fgColor.withOpacity(0.6),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$outdoorCount von $totalCount Stops sind Outdoor-Aktivitaeten.',
            style: TextStyle(
              fontSize: 13,
              color: fgColor.withOpacity(0.8),
            ),
          ),
          if (onSuggestAlternatives != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: onSuggestAlternatives,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: const Text('Indoor-Alternativen vorschlagen'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
