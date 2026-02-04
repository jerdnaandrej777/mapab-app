import 'package:flutter/material.dart';
import '../../../core/constants/categories.dart';
import 'weather_badge_unified.dart';

/// Kompakte Wetter-Anzeige fuer POI-Karten.
/// Delegiert an WeatherBadgeUnified (Dark-Mode-kompatibel).
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
    return WeatherBadgeUnified(
      condition: overallCondition,
      isWeatherResilient: isIndoorPOI,
      size: WeatherBadgeSize.inline,
    );
  }
}
