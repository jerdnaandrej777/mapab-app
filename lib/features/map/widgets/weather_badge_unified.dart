import 'package:flutter/material.dart';
import '../../../core/constants/categories.dart';
import '../../../core/utils/weather_poi_utils.dart';

/// Groessen-Varianten fuer den Wetter-Badge
enum WeatherBadgeSize {
  /// Fuer Listen (CompactPOICard, Chat-POI-Karten): klein, horizontal
  compact,

  /// Fuer Karten im DayEditor (EditablePOICard, TripStopTile): mittel
  inline,

  /// Fuer Marker auf der Karte: minimaler farbiger Punkt
  mini,
}

/// Einheitliches Wetter-Badge-Widget fuer alle Screens.
/// Nutzt colorScheme statt hardcodierter Farben (Dark-Mode-kompatibel).
class WeatherBadgeUnified extends StatelessWidget {
  final WeatherCondition condition;
  final bool isWeatherResilient;
  final WeatherBadgeSize size;

  const WeatherBadgeUnified({
    super.key,
    required this.condition,
    required this.isWeatherResilient,
    this.size = WeatherBadgeSize.inline,
  });

  /// Factory aus POI-Kategorie
  factory WeatherBadgeUnified.fromCategory({
    Key? key,
    required WeatherCondition condition,
    required POICategory? category,
    WeatherBadgeSize size = WeatherBadgeSize.inline,
  }) {
    return WeatherBadgeUnified(
      key: key,
      condition: condition,
      isWeatherResilient: category?.isWeatherResilient ?? false,
      size: size,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final badgeInfo = WeatherPOIUtils.getBadgeRaw(
      isWeatherResilient: isWeatherResilient,
      condition: condition,
      colorScheme: colorScheme,
    );

    if (badgeInfo == null) return const SizedBox.shrink();

    return switch (size) {
      WeatherBadgeSize.compact => _buildCompact(badgeInfo),
      WeatherBadgeSize.inline => _buildInline(badgeInfo),
      WeatherBadgeSize.mini => _buildMini(badgeInfo),
    };
  }

  /// Compact: Icon + Text, kleine Schrift (fuer Listen)
  Widget _buildCompact(WeatherBadgeInfo info) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: info.bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(info.icon, style: const TextStyle(fontSize: 8)),
          const SizedBox(width: 2),
          Text(
            info.text,
            style: TextStyle(
              fontSize: 9,
              color: info.fgColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Inline: Icon + Text, mittlere Schrift (fuer Karten im Editor)
  Widget _buildInline(WeatherBadgeInfo info) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: info.bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(info.icon, style: const TextStyle(fontSize: 10)),
          const SizedBox(width: 2),
          Text(
            info.text,
            style: TextStyle(
              fontSize: 10,
              color: info.fgColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Mini: Nur farbiger Punkt (fuer Marker auf der Karte)
  Widget _buildMini(WeatherBadgeInfo info) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: info.bgColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: info.fgColor.withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
    );
  }
}
