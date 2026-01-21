import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/categories.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/weather_provider.dart';

/// Wetter-Leiste für die Route
/// Zeigt 5 Punkte entlang der Route mit Wetter-Informationen
class WeatherBar extends ConsumerWidget {
  const WeatherBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherState = ref.watch(routeWeatherNotifierProvider);

    // Nicht anzeigen wenn keine Daten
    if (weatherState.weatherPoints.isEmpty && !weatherState.isLoading) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _getBackgroundColor(weatherState.overallCondition),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header mit Zusammenfassung
          _WeatherHeader(weatherState: weatherState),

          // Wetter-Punkte
          if (!weatherState.isLoading && weatherState.weatherPoints.isNotEmpty)
            _WeatherPoints(points: weatherState.weatherPoints),

          // Warnung bei schlechtem Wetter
          if (weatherState.hasDanger || weatherState.hasBadWeather)
            _WeatherAlert(weatherState: weatherState, ref: ref),
        ],
      ),
    );
  }

  Color _getBackgroundColor(WeatherCondition condition) {
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
}

class _WeatherHeader extends StatelessWidget {
  final RouteWeatherState weatherState;

  const _WeatherHeader({required this.weatherState});

  @override
  Widget build(BuildContext context) {
    if (weatherState.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text('Wetter laden...'),
          ],
        ),
      );
    }

    final condition = weatherState.overallCondition;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Icon
          Text(
            _getConditionIcon(condition),
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 8),
          // Beschreibung
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getConditionTitle(condition),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (weatherState.temperatureRange != null)
                  Text(
                    weatherState.temperatureRange!,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _getBadgeColor(condition),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _getBadgeText(condition),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getConditionIcon(WeatherCondition condition) {
    switch (condition) {
      case WeatherCondition.good:
        return '☀️';
      case WeatherCondition.mixed:
        return '⛅';
      case WeatherCondition.bad:
        return '🌧️';
      case WeatherCondition.danger:
        return '⚠️';
      case WeatherCondition.unknown:
        return '❓';
    }
  }

  String _getConditionTitle(WeatherCondition condition) {
    if (weatherState.hasSnow) return 'Winterwetter';
    if (weatherState.hasDanger) return 'Unwetter auf der Route';
    if (weatherState.hasRain) return 'Regen moglich';

    switch (condition) {
      case WeatherCondition.good:
        return 'Gutes Wetter';
      case WeatherCondition.mixed:
        return 'Wechselhaft';
      case WeatherCondition.bad:
        return 'Schlechtes Wetter';
      case WeatherCondition.danger:
        return 'Unwetterwarnung';
      case WeatherCondition.unknown:
        return 'Wetter unbekannt';
    }
  }

  String _getBadgeText(WeatherCondition condition) {
    if (weatherState.hasSnow) return 'Schnee';
    if (weatherState.hasRain) return 'Regen';

    switch (condition) {
      case WeatherCondition.good:
        return 'Perfekt';
      case WeatherCondition.mixed:
        return 'Wechselhaft';
      case WeatherCondition.bad:
        return 'Schlecht';
      case WeatherCondition.danger:
        return 'Unwetter';
      case WeatherCondition.unknown:
        return '';
    }
  }

  Color _getBadgeColor(WeatherCondition condition) {
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
}

class _WeatherPoints extends StatelessWidget {
  final List<WeatherPoint> points;

  const _WeatherPoints({required this.points});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (int i = 0; i < points.length; i++) ...[
            _WeatherPointItem(
              point: points[i],
              label: i == 0
                  ? 'Start'
                  : i == points.length - 1
                      ? 'Ziel'
                      : null,
            ),
            if (i < points.length - 1)
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getConditionColor(points[i].weather.condition),
                        _getConditionColor(points[i + 1].weather.condition),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Color _getConditionColor(WeatherCondition condition) {
    switch (condition) {
      case WeatherCondition.good:
        return Colors.green;
      case WeatherCondition.mixed:
        return Colors.amber;
      case WeatherCondition.bad:
        return Colors.orange;
      case WeatherCondition.danger:
        return Colors.red;
      case WeatherCondition.unknown:
        return Colors.grey;
    }
  }
}

class _WeatherPointItem extends StatelessWidget {
  final WeatherPoint point;
  final String? label;

  const _WeatherPointItem({
    required this.point,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null)
          Text(
            label!,
            style: TextStyle(
              fontSize: 9,
              color: AppTheme.textSecondary,
            ),
          ),
        Text(
          point.weather.icon,
          style: const TextStyle(fontSize: 20),
        ),
        Text(
          point.weather.formattedTemperature,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _WeatherAlert extends StatelessWidget {
  final RouteWeatherState weatherState;
  final WidgetRef ref;

  const _WeatherAlert({
    required this.weatherState,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final indoorOnly = ref.watch(indoorOnlyFilterProvider);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: weatherState.hasDanger
            ? Colors.red.shade100
            : Colors.orange.shade100,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                weatherState.hasDanger ? Icons.warning : Icons.umbrella,
                size: 18,
                color: weatherState.hasDanger ? Colors.red : Colors.orange,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getAlertText(),
                  style: TextStyle(
                    fontSize: 12,
                    color: weatherState.hasDanger
                        ? Colors.red.shade800
                        : Colors.orange.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Indoor-Filter Toggle
          InkWell(
            onTap: () {
              ref.read(indoorOnlyFilterProvider.notifier).toggle();
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: indoorOnly ? AppTheme.primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: indoorOnly
                      ? AppTheme.primaryColor
                      : Colors.grey.shade300,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    indoorOnly ? Icons.check_circle : Icons.home,
                    size: 16,
                    color: indoorOnly ? Colors.white : Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Nur Indoor-POIs',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: indoorOnly ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getAlertText() {
    if (weatherState.hasDanger) {
      final maxWind = weatherState.maxWindSpeed.round();
      if (maxWind > 60) {
        return 'Sturmwarnung! Starke Winde ($maxWind km/h) entlang der Route.';
      }
      return 'Unwetterwarnung! Fahrt verschieben empfohlen.';
    }
    if (weatherState.hasSnow) {
      return 'Winterwetter! Schnee/Glatte moglich.';
    }
    if (weatherState.hasRain) {
      return 'Regen erwartet. Indoor-Aktivitaten empfohlen.';
    }
    return 'Schlechtes Wetter auf der Route.';
  }
}

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
