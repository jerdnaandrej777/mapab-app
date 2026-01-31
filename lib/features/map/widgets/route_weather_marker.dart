import 'package:flutter/material.dart';
import '../../../core/constants/categories.dart';
import '../../../data/models/weather.dart';
import '../providers/weather_provider.dart';

/// Wetter-Marker auf der Route (v1.7.11)
/// Zeigt Wetter-Icon + Temperatur an einem Routenpunkt
class RouteWeatherMarker extends StatelessWidget {
  final WeatherPoint weatherPoint;
  final bool isStart;
  final bool isEnd;
  final VoidCallback? onTap;

  const RouteWeatherMarker({
    super.key,
    required this.weatherPoint,
    this.isStart = false,
    this.isEnd = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final condition = weatherPoint.weather.condition;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Haupt-Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getBackgroundColor(condition, isDark),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _getBorderColor(condition),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  weatherPoint.weather.icon,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 3),
                Text(
                  weatherPoint.weather.formattedTemperature,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _getTextColor(condition, isDark),
                  ),
                ),
              ],
            ),
          ),
          // Warning-Badge bei bad/danger
          if (condition == WeatherCondition.bad ||
              condition == WeatherCondition.danger)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: condition == WeatherCondition.danger
                      ? Colors.red
                      : Colors.orange,
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.surface, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    '!',
                    style: TextStyle(
                      color: colorScheme.surface,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getBackgroundColor(WeatherCondition condition, bool isDark) {
    if (isDark) {
      switch (condition) {
        case WeatherCondition.good:
          return Colors.green.shade900.withOpacity(0.8);
        case WeatherCondition.mixed:
          return Colors.amber.shade900.withOpacity(0.8);
        case WeatherCondition.bad:
          return Colors.orange.shade900.withOpacity(0.8);
        case WeatherCondition.danger:
          return Colors.red.shade900.withOpacity(0.8);
        case WeatherCondition.unknown:
          return Colors.grey.shade800;
      }
    }
    switch (condition) {
      case WeatherCondition.good:
        return Colors.green.shade50;
      case WeatherCondition.mixed:
        return Colors.amber.shade50;
      case WeatherCondition.bad:
        return Colors.orange.shade50;
      case WeatherCondition.danger:
        return Colors.red.shade50;
      case WeatherCondition.unknown:
        return Colors.grey.shade100;
    }
  }

  Color _getBorderColor(WeatherCondition condition) {
    switch (condition) {
      case WeatherCondition.good:
        return Colors.green.shade300;
      case WeatherCondition.mixed:
        return Colors.amber.shade300;
      case WeatherCondition.bad:
        return Colors.orange.shade300;
      case WeatherCondition.danger:
        return Colors.red.shade300;
      case WeatherCondition.unknown:
        return Colors.grey.shade300;
    }
  }

  Color _getTextColor(WeatherCondition condition, bool isDark) {
    if (isDark) {
      switch (condition) {
        case WeatherCondition.good:
          return Colors.green.shade200;
        case WeatherCondition.mixed:
          return Colors.amber.shade200;
        case WeatherCondition.bad:
          return Colors.orange.shade200;
        case WeatherCondition.danger:
          return Colors.red.shade200;
        case WeatherCondition.unknown:
          return Colors.grey.shade300;
      }
    }
    switch (condition) {
      case WeatherCondition.good:
        return Colors.green.shade800;
      case WeatherCondition.mixed:
        return Colors.amber.shade800;
      case WeatherCondition.bad:
        return Colors.orange.shade800;
      case WeatherCondition.danger:
        return Colors.red.shade800;
      case WeatherCondition.unknown:
        return Colors.grey.shade700;
    }
  }
}

/// Zeigt Detail-BottomSheet fuer einen Routen-Wetter-Punkt
void showRouteWeatherDetail(
  BuildContext context, {
  required WeatherPoint weatherPoint,
  required int index,
  required int totalPoints,
}) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final weather = weatherPoint.weather;
  final condition = weather.condition;

  // Label: Start, Ziel, oder Routenpunkt X
  final String label;
  if (index == 0) {
    label = 'Start';
  } else if (index == totalPoints - 1) {
    label = 'Ziel';
  } else {
    label = 'Routenpunkt ${index + 1} von $totalPoints';
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle Bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Label
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),

          // Wetter-Icon + Temperatur + Beschreibung
          Row(
            children: [
              Text(
                weather.icon,
                style: const TextStyle(fontSize: 40),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      weather.formattedTemperature,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      weather.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (weather.apparentTemperature != null)
                      Text(
                        'Gefuehlt ${weather.apparentTemperature!.round()}°C',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Details: Wind, Niederschlag, Regenwahrscheinlichkeit
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDetailItem(
                  icon: Icons.air,
                  value: '${weather.windSpeed.round()} km/h',
                  label: 'Wind',
                  colorScheme: colorScheme,
                ),
                _buildDetailItem(
                  icon: Icons.water_drop_outlined,
                  value: '${weather.precipitation} mm',
                  label: 'Niederschlag',
                  colorScheme: colorScheme,
                ),
                _buildDetailItem(
                  icon: Icons.umbrella,
                  value: '${weather.precipitationProbability}%',
                  label: 'Regenrisiko',
                  colorScheme: colorScheme,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Empfehlung
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getRecommendationBgColor(condition),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  _getRecommendationIcon(condition),
                  size: 20,
                  color: _getRecommendationIconColor(condition),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _getRecommendationText(condition, weather),
                    style: TextStyle(
                      fontSize: 13,
                      color: _getRecommendationTextColor(condition),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Safe Area padding
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    ),
  );
}

Widget _buildDetailItem({
  required IconData icon,
  required String value,
  required String label,
  required ColorScheme colorScheme,
}) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
      const SizedBox(height: 4),
      Text(
        value,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );
}

IconData _getRecommendationIcon(WeatherCondition condition) {
  switch (condition) {
    case WeatherCondition.good:
      return Icons.wb_sunny;
    case WeatherCondition.mixed:
      return Icons.cloud_queue;
    case WeatherCondition.bad:
      return Icons.umbrella;
    case WeatherCondition.danger:
      return Icons.warning_amber_rounded;
    case WeatherCondition.unknown:
      return Icons.help_outline;
  }
}

String _getRecommendationText(WeatherCondition condition, Weather weather) {
  switch (condition) {
    case WeatherCondition.good:
      return 'Perfektes Wetter fuer Outdoor-Aktivitaeten';
    case WeatherCondition.mixed:
      return 'Wechselhaft - auf alles vorbereitet sein';
    case WeatherCondition.bad:
      if (weather.weatherCode >= 71 && weather.weatherCode <= 77 ||
          weather.weatherCode == 85 ||
          weather.weatherCode == 86) {
        return 'Schneefall - Vorsicht auf glatten Strassen';
      }
      return 'Schlechtes Wetter - Indoor-Aktivitaeten empfohlen';
    case WeatherCondition.danger:
      if (weather.windSpeed > 60) {
        return 'Sturmwarnung! Starke Winde (${weather.windSpeed.round()} km/h)';
      }
      return 'Unwetterwarnung! Vorsicht auf diesem Streckenabschnitt';
    case WeatherCondition.unknown:
      return 'Keine Wetterdaten verfuegbar';
  }
}

Color _getRecommendationBgColor(WeatherCondition condition) {
  switch (condition) {
    case WeatherCondition.good:
      return Colors.green.shade50;
    case WeatherCondition.mixed:
      return Colors.amber.shade50;
    case WeatherCondition.bad:
      return Colors.orange.shade50;
    case WeatherCondition.danger:
      return Colors.red.shade50;
    case WeatherCondition.unknown:
      return Colors.grey.shade100;
  }
}

Color _getRecommendationIconColor(WeatherCondition condition) {
  switch (condition) {
    case WeatherCondition.good:
      return Colors.green;
    case WeatherCondition.mixed:
      return Colors.amber.shade700;
    case WeatherCondition.bad:
      return Colors.orange;
    case WeatherCondition.danger:
      return Colors.red;
    case WeatherCondition.unknown:
      return Colors.grey;
  }
}

Color _getRecommendationTextColor(WeatherCondition condition) {
  switch (condition) {
    case WeatherCondition.good:
      return Colors.green.shade800;
    case WeatherCondition.mixed:
      return Colors.amber.shade800;
    case WeatherCondition.bad:
      return Colors.orange.shade800;
    case WeatherCondition.danger:
      return Colors.red.shade800;
    case WeatherCondition.unknown:
      return Colors.grey.shade700;
  }
}
