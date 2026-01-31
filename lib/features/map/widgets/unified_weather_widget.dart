import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/categories.dart';
import '../../random_trip/providers/random_trip_provider.dart';
import '../providers/route_session_provider.dart';
import '../providers/weather_provider.dart';
import 'weather_details_sheet.dart';

/// Provider für Collapsed-State des Weather Widgets (v1.7.19)
/// Persistiert über gesamte Session
final weatherWidgetCollapsedProvider = StateProvider<bool>((ref) => true);

/// Intelligentes Wetter-Widget (v1.7.19)
/// Wechselt automatisch zwischen Standort-Wetter und Route-Wetter
class UnifiedWeatherWidget extends ConsumerWidget {
  const UnifiedWeatherWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routeSession = ref.watch(routeSessionProvider);
    final locationWeather = ref.watch(locationWeatherNotifierProvider);
    final routeWeather = ref.watch(routeWeatherNotifierProvider);
    final isCollapsed = ref.watch(weatherWidgetCollapsedProvider);

    // Modus bestimmen: Route-Modus wenn Route vorhanden
    final bool hasRoute = routeSession.isReady;

    // Nicht anzeigen wenn keine Daten
    if (hasRoute) {
      if (routeWeather.weatherPoints.isEmpty && !routeWeather.isLoading) {
        return const SizedBox.shrink();
      }
    } else {
      if (!locationWeather.hasWeather && !locationWeather.isLoading) {
        return const SizedBox.shrink();
      }
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: hasRoute
            ? _getBackgroundColor(routeWeather.overallCondition, context)
            : _getBackgroundColor(
                locationWeather.hasWeather
                    ? locationWeather.weather!.condition
                    : WeatherCondition.unknown,
                context),
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
          // Header (tappable)
          InkWell(
            onTap: () {
              ref.read(weatherWidgetCollapsedProvider.notifier).state =
                  !isCollapsed;
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: hasRoute
                ? _RouteWeatherHeader(
                    weatherState: routeWeather,
                    isCollapsed: isCollapsed,
                  )
                : _LocationWeatherHeader(
                    weatherState: locationWeather,
                    isCollapsed: isCollapsed,
                  ),
          ),

          // Content (einklappbar)
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: hasRoute
                ? _RouteWeatherContent(weatherState: routeWeather)
                : _LocationWeatherContent(weatherState: locationWeather),
            crossFadeState: isCollapsed
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Color _getBackgroundColor(WeatherCondition condition, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isDark) {
      // Dark Mode: Subtilere Farben
      switch (condition) {
        case WeatherCondition.good:
          return Colors.green.withOpacity(0.15);
        case WeatherCondition.mixed:
          return Colors.amber.withOpacity(0.15);
        case WeatherCondition.bad:
          return Colors.orange.withOpacity(0.15);
        case WeatherCondition.danger:
          return Colors.red.withOpacity(0.15);
        case WeatherCondition.unknown:
          return colorScheme.surfaceContainerHighest;
      }
    } else {
      // Light Mode: Hellere Farben
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
          return colorScheme.surfaceContainerHighest;
      }
    }
  }
}

/// Standort-Wetter Header
class _LocationWeatherHeader extends StatelessWidget {
  final LocationWeatherState weatherState;
  final bool isCollapsed;

  const _LocationWeatherHeader({
    required this.weatherState,
    required this.isCollapsed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (weatherState.isLoading) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            const Expanded(child: Text('Wetter laden...')),
            _ExpandIcon(isCollapsed: isCollapsed, colorScheme: colorScheme),
          ],
        ),
      );
    }

    if (!weatherState.hasWeather) {
      return const SizedBox.shrink();
    }

    final weather = weatherState.weather!;
    final condition = weather.condition;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Icon
          Text(
            weather.icon,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 8),
          // Temperatur & Stadtname
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${weather.formattedTemperature} · ${weatherState.locationName ?? "Mein Standort"}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  weather.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Warnung-Icon bei schlechtem Wetter
          if (weatherState.showWarning) ...[
            Icon(
              condition == WeatherCondition.danger
                  ? Icons.warning_amber_rounded
                  : Icons.umbrella,
              size: 18,
              color: condition == WeatherCondition.danger
                  ? Colors.red.shade700
                  : Colors.orange.shade700,
            ),
            const SizedBox(width: 8),
          ],
          // Details-Button
          IconButton(
            onPressed: () {
              showWeatherDetailsSheet(
                context,
                weather: weather,
                locationName: weatherState.locationName,
              );
            },
            icon: Icon(
              Icons.info_outline,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
            visualDensity: VisualDensity.compact,
            tooltip: '7-Tage-Vorhersage',
          ),
          // Expand/Collapse Icon
          _ExpandIcon(isCollapsed: isCollapsed, colorScheme: colorScheme),
        ],
      ),
    );
  }
}

/// Route-Wetter Header
class _RouteWeatherHeader extends StatelessWidget {
  final RouteWeatherState weatherState;
  final bool isCollapsed;

  const _RouteWeatherHeader({
    required this.weatherState,
    required this.isCollapsed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (weatherState.isLoading) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            const Expanded(child: Text('Wetter laden...')),
            _ExpandIcon(isCollapsed: isCollapsed, colorScheme: colorScheme),
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
            _getConditionIcon(condition, weatherState),
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 8),
          // Beschreibung
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getConditionTitle(condition, weatherState),
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
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _getBadgeColor(condition, weatherState),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _getBadgeText(condition, weatherState),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Expand/Collapse Icon
          _ExpandIcon(isCollapsed: isCollapsed, colorScheme: colorScheme),
        ],
      ),
    );
  }

  String _getConditionIcon(
      WeatherCondition condition, RouteWeatherState state) {
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

  String _getConditionTitle(
      WeatherCondition condition, RouteWeatherState state) {
    if (state.hasSnow) return 'Winterwetter';
    if (state.hasDanger) return 'Unwetter auf der Route';
    if (state.hasRain) return 'Regen möglich';

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

  String _getBadgeText(WeatherCondition condition, RouteWeatherState state) {
    if (state.hasSnow) return 'Schnee';
    if (state.hasRain) return 'Regen';

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

  Color _getBadgeColor(WeatherCondition condition, RouteWeatherState state) {
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

/// Standort-Wetter Content (erweitert)
class _LocationWeatherContent extends ConsumerWidget {
  final LocationWeatherState weatherState;

  const _LocationWeatherContent({required this.weatherState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!weatherState.hasWeather) {
      return const SizedBox.shrink();
    }

    final weather = weatherState.weather!;
    final condition = weather.condition;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Empfehlung
        Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getRecommendationText(condition),
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Wetter-Kategorien Toggle (AI Trip)
        _WeatherCategoryToggle(condition: condition),
      ],
    );
  }

  String _getRecommendationText(WeatherCondition condition) {
    switch (condition) {
      case WeatherCondition.good:
        return 'Heute ideal für Outdoor-POIs';
      case WeatherCondition.mixed:
        return 'Wechselhaft - flexibel planen';
      case WeatherCondition.bad:
        return 'Regen - Indoor-POIs empfohlen';
      case WeatherCondition.danger:
        return 'Unwetter - nur Indoor-POIs!';
      case WeatherCondition.unknown:
        return 'Wetter unbekannt';
    }
  }
}

/// Route-Wetter Content (erweitert)
class _RouteWeatherContent extends ConsumerWidget {
  final RouteWeatherState weatherState;

  const _RouteWeatherContent({required this.weatherState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Wetter-Punkte
        if (weatherState.weatherPoints.isNotEmpty)
          _WeatherPoints(points: weatherState.weatherPoints),

        // Warnung + Indoor-Filter bei schlechtem Wetter
        if (weatherState.hasDanger || weatherState.hasBadWeather)
          _RouteWeatherAlert(weatherState: weatherState),
      ],
    );
  }
}

/// Wetter-Kategorien Toggle für AI Trip
class _WeatherCategoryToggle extends ConsumerWidget {
  final WeatherCondition condition;

  const _WeatherCategoryToggle({required this.condition});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final randomTripState = ref.watch(randomTripNotifierProvider);
    final isApplied = randomTripState.weatherCategoriesApplied;
    final colorScheme = Theme.of(context).colorScheme;
    final (icon, text, color) = _getRecommendation();

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: InkWell(
        onTap: () {
          if (isApplied) {
            ref.read(randomTripNotifierProvider.notifier).resetWeatherCategories();
          } else {
            ref.read(randomTripNotifierProvider.notifier).applyWeatherBasedCategories(condition);
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Color.alphaBlend(
                color.withOpacity(0.15), colorScheme.surface),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.5), width: 1.5),
          ),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isApplied ? color : color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isApplied) ...[
                      const Icon(Icons.check, size: 13, color: Colors.white),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      isApplied ? 'Aktiv' : 'Anwenden',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isApplied ? Colors.white : color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  (String, String, Color) _getRecommendation() {
    switch (condition) {
      case WeatherCondition.good:
        return ('☀️', 'Heute ideal für Outdoor-POIs', Colors.green);
      case WeatherCondition.mixed:
        return ('⛅', 'Wechselhaft - flexibel planen', Colors.amber);
      case WeatherCondition.bad:
        return ('🌧️', 'Regen - Indoor-POIs empfohlen', Colors.orange);
      case WeatherCondition.danger:
        return ('⚠️', 'Unwetter - nur Indoor-POIs!', Colors.red);
      case WeatherCondition.unknown:
        return ('❓', 'Wetter unbekannt', Colors.grey);
    }
  }
}

/// Wetter-Punkte auf Route (5 Punkte)
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

/// Wetter-Punkt Item
class _WeatherPointItem extends StatelessWidget {
  final WeatherPoint point;
  final String? label;

  const _WeatherPointItem({
    required this.point,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null)
          Text(
            label!,
            style: TextStyle(
              fontSize: 9,
              color: colorScheme.onSurfaceVariant,
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

/// Route-Wetter Warnung mit Indoor-Filter
class _RouteWeatherAlert extends ConsumerWidget {
  final RouteWeatherState weatherState;

  const _RouteWeatherAlert({required this.weatherState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final indoorOnly = ref.watch(indoorOnlyFilterProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isDanger = weatherState.hasDanger;
    final bgColor = isDark
        ? (isDanger
            ? Colors.red.withOpacity(0.2)
            : Colors.orange.withOpacity(0.2))
        : (isDanger ? Colors.red.shade100 : Colors.orange.shade100);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                isDanger ? Icons.warning : Icons.umbrella,
                size: 18,
                color: isDanger ? Colors.red : Colors.orange,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getAlertText(),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? (isDanger ? Colors.red.shade200 : Colors.orange.shade200)
                        : (isDanger ? Colors.red.shade800 : Colors.orange.shade800),
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
                color: indoorOnly
                    ? (isDark ? Colors.blue.shade700 : Colors.blue)
                    : colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: indoorOnly
                      ? (isDark ? Colors.blue.shade700 : Colors.blue)
                      : colorScheme.outline,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    indoorOnly ? Icons.check_circle : Icons.home,
                    size: 16,
                    color: indoorOnly
                        ? Colors.white
                        : colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Nur Indoor-POIs',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: indoorOnly
                          ? Colors.white
                          : colorScheme.onSurface,
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
      return 'Winterwetter! Schnee/Glätte möglich.';
    }
    if (weatherState.hasRain) {
      return 'Regen erwartet. Indoor-Aktivitäten empfohlen.';
    }
    return 'Schlechtes Wetter auf der Route.';
  }
}

/// Expand/Collapse Icon
class _ExpandIcon extends StatelessWidget {
  final bool isCollapsed;
  final ColorScheme colorScheme;

  const _ExpandIcon({
    required this.isCollapsed,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedRotation(
      turns: isCollapsed ? 0 : 0.5,
      duration: const Duration(milliseconds: 200),
      child: Icon(
        Icons.expand_more,
        size: 20,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}
