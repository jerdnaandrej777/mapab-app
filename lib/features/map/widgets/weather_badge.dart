import 'package:flutter/material.dart';
import '../../../core/constants/categories.dart';

/// Kompakte Wetter-Anzeige für POI-Karten
class WeatherBadge extends StatelessWidget {
  final WeatherCondition overallCondition;
  final bool isIndoorPOI;

  const WeatherBadge({
    super.key,
    required this.overallCondition,
    required this.isIndoorPOI,
  });

  @override
  Widget build(BuildContext context) {
    final badge = _getBadge();
    if (badge == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badge.color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(badge.icon, style: const TextStyle(fontSize: 10)),
          const SizedBox(width: 2),
          Text(
            badge.text,
            style: const TextStyle(
              fontSize: 9,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  ({String icon, String text, Color color})? _getBadge() {
    // Bei schlechtem Wetter
    if (overallCondition == WeatherCondition.danger ||
        overallCondition == WeatherCondition.bad) {
      if (isIndoorPOI) {
        return (icon: '👍', text: 'Empfohlen', color: Colors.green);
      } else {
        if (overallCondition == WeatherCondition.danger) {
          return (icon: '⚠️', text: 'Unwetter', color: Colors.red);
        }
        return (icon: '🌧️', text: 'Regen', color: Colors.orange);
      }
    }

    // Bei gutem Wetter
    if (overallCondition == WeatherCondition.good && !isIndoorPOI) {
      return (icon: '🌞', text: 'Ideal', color: Colors.green);
    }

    return null;
  }
}
