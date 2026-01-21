import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/constants/categories.dart';
import '../../../data/models/weather.dart';
import '../../../data/repositories/weather_repo.dart';

part 'weather_provider.g.dart';

/// Wetter-Punkt auf der Route
class WeatherPoint {
  final LatLng location;
  final String? locationName;
  final Weather weather;
  final double routePosition; // 0.0 = Start, 1.0 = Ziel
  final int? hoursFromNow;

  WeatherPoint({
    required this.location,
    this.locationName,
    required this.weather,
    required this.routePosition,
    this.hoursFromNow,
  });
}

/// State für Routen-Wetter
class RouteWeatherState {
  final List<WeatherPoint> weatherPoints;
  final WeatherCondition overallCondition;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  const RouteWeatherState({
    this.weatherPoints = const [],
    this.overallCondition = WeatherCondition.unknown,
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  RouteWeatherState copyWith({
    List<WeatherPoint>? weatherPoints,
    WeatherCondition? overallCondition,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) {
    return RouteWeatherState(
      weatherPoints: weatherPoints ?? this.weatherPoints,
      overallCondition: overallCondition ?? this.overallCondition,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Durchschnittstemperatur
  double? get averageTemperature {
    if (weatherPoints.isEmpty) return null;
    final sum = weatherPoints.fold<double>(
      0,
      (sum, point) => sum + point.weather.temperature,
    );
    return sum / weatherPoints.length;
  }

  /// Temperaturbereich
  String? get temperatureRange {
    if (weatherPoints.isEmpty) return null;
    final temps = weatherPoints.map((p) => p.weather.temperature);
    final min = temps.reduce((a, b) => a < b ? a : b).round();
    final max = temps.reduce((a, b) => a > b ? a : b).round();
    return '$min° bis $max°';
  }

  /// Hat Unwetter
  bool get hasDanger =>
      weatherPoints.any((p) => p.weather.condition == WeatherCondition.danger);

  /// Hat schlechtes Wetter
  bool get hasBadWeather =>
      weatherPoints.any((p) => p.weather.condition == WeatherCondition.bad);

  /// Hat Schnee
  bool get hasSnow => weatherPoints.any((p) {
        final code = p.weather.weatherCode;
        return (code >= 71 && code <= 77) || code == 85 || code == 86;
      });

  /// Hat Regen
  bool get hasRain => weatherPoints.any((p) {
        final code = p.weather.weatherCode;
        return (code >= 51 && code <= 67) || (code >= 80 && code <= 82);
      });

  /// Maximale Windgeschwindigkeit
  double get maxWindSpeed {
    if (weatherPoints.isEmpty) return 0;
    return weatherPoints
        .map((p) => p.weather.windSpeed)
        .reduce((a, b) => a > b ? a : b);
  }
}

/// Provider für Routen-Wetter
@riverpod
class RouteWeatherNotifier extends _$RouteWeatherNotifier {
  @override
  RouteWeatherState build() {
    return const RouteWeatherState();
  }

  /// Lädt Wetter für Punkte entlang der Route
  Future<void> loadWeatherForRoute(List<LatLng> routeCoords) async {
    if (routeCoords.isEmpty) {
      state = const RouteWeatherState();
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final weatherRepo = ref.read(weatherRepositoryProvider);

      // 5 Punkte gleichmäßig auf der Route verteilen
      final points = <WeatherPoint>[];
      final step = (routeCoords.length / 5).floor().clamp(1, routeCoords.length);

      for (int i = 0; i < 5 && i * step < routeCoords.length; i++) {
        final index = i * step;
        final location = routeCoords[index];
        final routePosition = index / (routeCoords.length - 1);

        try {
          final weather = await weatherRepo.getCurrentWeather(location);

          points.add(WeatherPoint(
            location: location,
            weather: weather,
            routePosition: routePosition,
          ));
        } catch (e) {
          debugPrint('[Weather] Punkt $i fehlgeschlagen: $e');
        }

        // Rate Limiting
        if (i < 4) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }

      // Gesamtzustand berechnen
      final overallCondition = _calculateOverallCondition(points);

      state = RouteWeatherState(
        weatherPoints: points,
        overallCondition: overallCondition,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );

      debugPrint('[Weather] ${points.length} Punkte geladen, Zustand: $overallCondition');
    } catch (e) {
      debugPrint('[Weather] Fehler: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Wetter konnte nicht geladen werden',
      );
    }
  }

  /// Berechnet den Gesamtwetter-Zustand
  WeatherCondition _calculateOverallCondition(List<WeatherPoint> points) {
    if (points.isEmpty) return WeatherCondition.unknown;

    // Priorität: danger > bad > mixed > good
    if (points.any((p) => p.weather.condition == WeatherCondition.danger)) {
      return WeatherCondition.danger;
    }
    if (points.any((p) => p.weather.condition == WeatherCondition.bad)) {
      return WeatherCondition.bad;
    }
    if (points.any((p) => p.weather.condition == WeatherCondition.mixed)) {
      return WeatherCondition.mixed;
    }
    return WeatherCondition.good;
  }

  /// Löscht die Wetter-Daten
  void clear() {
    state = const RouteWeatherState();
  }
}

/// Provider für Indoor-Only Filter
@riverpod
class IndoorOnlyFilter extends _$IndoorOnlyFilter {
  @override
  bool build() => false;

  void toggle() {
    state = !state;
  }

  void setEnabled(bool enabled) {
    state = enabled;
  }
}
