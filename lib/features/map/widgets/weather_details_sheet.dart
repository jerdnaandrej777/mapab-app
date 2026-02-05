import 'package:flutter/material.dart';
import '../../../core/constants/categories.dart';
import '../../../core/l10n/l10n.dart';
import '../../../data/models/weather.dart';

/// Zeigt das Wetter-Details Bottom Sheet an (v1.7.6, v1.9.10: Vollbild)
void showWeatherDetailsSheet(
  BuildContext context, {
  required Weather weather,
  String? locationName,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => WeatherDetailsSheet(
        weather: weather,
        locationName: locationName,
        scrollController: scrollController,
      ),
    ),
  );
}

/// Wetter-Details Bottom Sheet (v1.7.6)
/// Zeigt aktuelles Wetter, 7-Tage-Vorhersage, UV-Index, Sonnenzeiten
class WeatherDetailsSheet extends StatelessWidget {
  final Weather weather;
  final String? locationName;
  final ScrollController? scrollController;

  const WeatherDetailsSheet({
    super.key,
    required this.weather,
    this.locationName,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header (fixiert oben)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (locationName != null)
                        Text(
                          locationName!,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      Text(
                        _formatDateTime(context, weather.timestamp),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Scrollbarer Inhalt
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                children: [
                  // Aktuelles Wetter
                  _buildCurrentWeather(context, colorScheme),

                  const Divider(height: 32),

                  // 7-Tage-Vorhersage
                  if (weather.dailyForecast.isNotEmpty)
                    _buildForecast(context, colorScheme),

                  // Zusatz-Infos (UV, Sonnenzeiten)
                  _buildExtraInfo(context, colorScheme),

                  // Empfehlung
                  _buildRecommendation(context, colorScheme),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentWeather(BuildContext context, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getConditionColor(weather.condition).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getConditionColor(weather.condition).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Icon groß
          Text(
            weather.icon,
            style: const TextStyle(fontSize: 56),
          ),
          const SizedBox(width: 16),
          // Temperatur und Beschreibung
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  weather.formattedTemperature,
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  weather.description,
                  style: TextStyle(
                    fontSize: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                // Zusatzinfos
                Row(
                  children: [
                    if (weather.apparentTemperature != null) ...[
                      Icon(
                        Icons.thermostat_outlined,
                        size: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        context.l10n.weatherFeelsLike('${weather.apparentTemperature!.round()}'),
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Icon(
                      Icons.air,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${weather.windSpeed.round()} km/h',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecast(BuildContext context, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            context.l10n.weatherForecast7Day,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: weather.dailyForecast.length,
            itemBuilder: (context, index) {
              final day = weather.dailyForecast[index];
              final isToday = index == 0;

              return Container(
                width: 64,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isToday
                      ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                      : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isToday ? context.l10n.weatherToday : day.weekday,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      day.icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${day.temperatureMax.round()}°',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      '${day.temperatureMin.round()}°',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const Divider(height: 32),
      ],
    );
  }

  Widget _buildExtraInfo(BuildContext context, ColorScheme colorScheme) {
    final today = weather.dailyForecast.isNotEmpty ? weather.dailyForecast.first : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Sonnenzeiten
          if (today?.sunrise != null && today?.sunset != null)
            Row(
              children: [
                Expanded(
                  child: _buildInfoTile(
                    icon: '🌅',
                    label: context.l10n.weatherSunrise,
                    value: _formatTime(today!.sunrise!),
                    colorScheme: colorScheme,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoTile(
                    icon: '🌇',
                    label: context.l10n.weatherSunset,
                    value: _formatTime(today.sunset!),
                    colorScheme: colorScheme,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12),
          // UV-Index und Niederschlag
          Row(
            children: [
              if (weather.uvIndex != null || today?.uvIndexMax != null)
                Expanded(
                  child: _buildInfoTile(
                    icon: '☀️',
                    label: context.l10n.weatherUvIndex,
                    value: _formatUVIndex(context, weather.uvIndex ?? today?.uvIndexMax ?? 0),
                    colorScheme: colorScheme,
                  ),
                ),
              if (weather.uvIndex != null || today?.uvIndexMax != null)
                const SizedBox(width: 12),
              Expanded(
                child: _buildInfoTile(
                  icon: '💧',
                  label: context.l10n.weatherPrecipitation,
                  value: '${weather.precipitationProbability}%',
                  colorScheme: colorScheme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required String icon,
    required String label,
    required String value,
    required ColorScheme colorScheme,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendation(BuildContext context, ColorScheme colorScheme) {
    final (icon, text, color) = _getRecommendation(context);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.weatherRecommendationToday,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color.withValues(alpha: 0.8),
                  ),
                ),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  (String, String, Color) _getRecommendation(BuildContext context) {
    switch (weather.condition) {
      case WeatherCondition.good:
        return (
          '☀️',
          context.l10n.weatherRecGood,
          Colors.green,
        );
      case WeatherCondition.mixed:
        return (
          '⛅',
          context.l10n.weatherRecMixed,
          Colors.amber,
        );
      case WeatherCondition.bad:
        return (
          '🏛️',
          context.l10n.weatherRecBad,
          Colors.orange,
        );
      case WeatherCondition.danger:
        return (
          '⚠️',
          context.l10n.weatherRecDanger,
          Colors.red,
        );
      case WeatherCondition.unknown:
        return (
          '❓',
          context.l10n.weatherRecUnknown,
          Colors.grey,
        );
    }
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

  String _formatDateTime(BuildContext context, DateTime dateTime) {
    final now = DateTime.now();
    if (dateTime.day == now.day &&
        dateTime.month == now.month &&
        dateTime.year == now.year) {
      return '${context.l10n.weatherToday}, ${_formatTime(dateTime)}';
    }
    return '${dateTime.day}.${dateTime.month}.${dateTime.year}, ${_formatTime(dateTime)}';
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatUVIndex(BuildContext context, double uvIndex) {
    final rounded = uvIndex.round();
    if (rounded <= 2) return context.l10n.weatherUvLow('$rounded');
    if (rounded <= 5) return context.l10n.weatherUvMedium('$rounded');
    if (rounded <= 7) return context.l10n.weatherUvHigh('$rounded');
    if (rounded <= 10) return context.l10n.weatherUvVeryHigh('$rounded');
    return context.l10n.weatherUvExtreme('$rounded');
  }
}
