import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/categories.dart';
import '../../../data/models/weather.dart';
import '../providers/weather_provider.dart';

/// Kompakter Wetter-Chip für MapScreen (v1.7.6)
/// Zeigt aktuelles Wetter am GPS-Standort
/// Bei Tap: Öffnet Wetter-Details-Sheet
class WeatherChip extends ConsumerWidget {
  final VoidCallback? onTap;

  const WeatherChip({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherState = ref.watch(locationWeatherNotifierProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Nicht anzeigen wenn keine Daten
    if (!weatherState.hasWeather && !weatherState.isLoading) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _getBackgroundColor(weatherState, colorScheme),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: weatherState.isLoading
            ? _buildLoading(colorScheme)
            : _buildContent(weatherState, colorScheme),
      ),
    );
  }

  Widget _buildLoading(ColorScheme colorScheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '...',
          style: TextStyle(
            fontSize: 13,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildContent(LocationWeatherState weatherState, ColorScheme colorScheme) {
    final weather = weatherState.weather!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Wetter-Icon
        Text(
          weather.icon,
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(width: 4),
        // Temperatur
        Text(
          weather.formattedTemperature,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _getTextColor(weatherState),
          ),
        ),
        // Warnungs-Indikator
        if (weatherState.showWarning) ...[
          const SizedBox(width: 4),
          Icon(
            Icons.warning_amber_rounded,
            size: 14,
            color: weatherState.condition == WeatherCondition.danger
                ? Colors.red.shade700
                : Colors.orange.shade700,
          ),
        ],
        // Expand-Icon
        const SizedBox(width: 2),
        Icon(
          Icons.keyboard_arrow_down_rounded,
          size: 16,
          color: _getTextColor(weatherState).withValues(alpha: 0.7),
        ),
      ],
    );
  }

  Color _getBackgroundColor(LocationWeatherState weatherState, ColorScheme colorScheme) {
    if (weatherState.isLoading || !weatherState.hasWeather) {
      return colorScheme.surfaceContainerHighest;
    }

    switch (weatherState.condition) {
      case WeatherCondition.good:
        return Colors.green.shade50;
      case WeatherCondition.mixed:
        return Colors.amber.shade50;
      case WeatherCondition.bad:
        return Colors.orange.shade50;
      case WeatherCondition.danger:
        return Colors.red.shade50;
      case WeatherCondition.unknown:
        return colorScheme.surfaceContainerHighest;
    }
  }

  Color _getTextColor(LocationWeatherState weatherState) {
    switch (weatherState.condition) {
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
