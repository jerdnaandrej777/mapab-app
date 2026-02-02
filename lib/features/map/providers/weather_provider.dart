import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/constants/categories.dart';
import '../../../data/models/weather.dart';
import '../../../data/repositories/weather_repo.dart';
import '../../poi/providers/poi_state_provider.dart';

part 'weather_provider.g.dart';

/// Wetter-Punkt auf der Route
class WeatherPoint {
  final LatLng location;
  final String? locationName;
  final Weather weather;
  final double routePosition; // 0.0 = Start, 1.0 = Ziel
  final int? hoursFromNow;
  final List<DailyForecast>? dailyForecast; // 7-Tage-Vorhersage
  final int? dayNumber; // Welcher Reisetag (1-basiert)

  WeatherPoint({
    required this.location,
    this.locationName,
    required this.weather,
    required this.routePosition,
    this.hoursFromNow,
    this.dailyForecast,
    this.dayNumber,
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

  /// Wetter pro Tag berechnen (v1.8.0)
  /// Ordnet jedem Tag den naechsten WeatherPoint zu
  Map<int, WeatherCondition> getWeatherPerDay(int totalDays) {
    final result = <int, WeatherCondition>{};
    if (weatherPoints.isEmpty || totalDays <= 0) return result;

    for (int day = 1; day <= totalDays; day++) {
      // Position des Tages auf der Route (0.0 - 1.0)
      final dayPosition = totalDays > 1
          ? (day - 1) / (totalDays - 1)
          : 0.5;

      // Naechsten WeatherPoint finden
      WeatherCondition closest = overallCondition;
      double minDist = double.infinity;
      for (final wp in weatherPoints) {
        final dist = (wp.routePosition - dayPosition).abs();
        if (dist < minDist) {
          minDist = dist;
          closest = wp.weather.condition;
        }
      }
      result[day] = closest;
    }

    return result;
  }

  /// Wetter als String-Map (fuer AI Service)
  Map<int, String> getWeatherPerDayAsStrings(int totalDays) {
    return getWeatherPerDay(totalDays).map(
      (day, condition) => MapEntry(day, condition.name),
    );
  }

  /// Hat Forecast-Daten (von loadWeatherForRouteWithForecast)
  bool get hasForecast =>
      weatherPoints.any((p) => p.dailyForecast != null && p.dailyForecast!.isNotEmpty);

  /// Vorhersage fuer einen bestimmten Reisetag (1-basiert)
  /// Tag 1 = heute (dailyForecast[0]), Tag 2 = morgen, etc.
  /// Findet den naechsten WeatherPoint fuer die Route-Position des Tages
  DailyForecast? getDayForecast(int day, int totalDays) {
    if (weatherPoints.isEmpty || day < 1) return null;

    // Position des Tages auf der Route
    final dayPosition = totalDays > 1 ? (day - 1) / (totalDays - 1) : 0.5;

    // Naechsten WeatherPoint mit Forecast finden
    WeatherPoint? closest;
    double minDist = double.infinity;
    for (final wp in weatherPoints) {
      if (wp.dailyForecast == null || wp.dailyForecast!.isEmpty) continue;
      final dist = (wp.routePosition - dayPosition).abs();
      if (dist < minDist) {
        minDist = dist;
        closest = wp;
      }
    }

    if (closest == null || closest.dailyForecast == null) return null;

    // Forecast-Index: Tag 1 = Index 0 (heute), Tag 2 = Index 1, etc.
    final forecastIndex = day - 1;
    if (forecastIndex >= closest.dailyForecast!.length) {
      return closest.dailyForecast!.last; // Letzter verfuegbarer Tag
    }
    return closest.dailyForecast![forecastIndex];
  }

  /// Vorhersage-Condition pro Tag aus den DailyForecast-Daten
  /// Nutzt echte Tages-Vorhersage statt aktuellem Wetter
  Map<int, WeatherCondition> getForecastPerDay(int totalDays) {
    if (!hasForecast) return getWeatherPerDay(totalDays); // Fallback

    final result = <int, WeatherCondition>{};
    for (int day = 1; day <= totalDays; day++) {
      final forecast = getDayForecast(day, totalDays);
      if (forecast != null) {
        result[day] = forecast.condition;
      } else {
        // Fallback auf Position-basiertes Mapping
        final dayCondition = getWeatherPerDay(1);
        result[day] = dayCondition[1] ?? overallCondition;
      }
    }
    return result;
  }

  /// Forecast als String-Map fuer AI Service (mit Temperatur)
  Map<int, String> getForecastPerDayAsStrings(int totalDays) {
    final result = <int, String>{};
    for (int day = 1; day <= totalDays; day++) {
      final forecast = getDayForecast(day, totalDays);
      if (forecast != null) {
        result[day] = '${forecast.condition.name} '
            '(${forecast.temperatureRange}, '
            '${forecast.precipitationProbabilityMax}% Regen)';
      } else {
        final condition = getWeatherPerDay(totalDays)[day];
        result[day] = condition?.name ?? 'unknown';
      }
    }
    return result;
  }
}

/// Provider für Routen-Wetter
@Riverpod(keepAlive: true)
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

  /// Laedt Wetter mit 7-Tage-Vorhersage fuer Punkte entlang der Route
  /// Fuer mehrtaegige Trips: Jeder Tag erhaelt echte Tagesvorhersage
  Future<void> loadWeatherForRouteWithForecast(
    List<LatLng> routeCoords, {
    int forecastDays = 7,
  }) async {
    if (routeCoords.isEmpty) {
      state = const RouteWeatherState();
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final weatherRepo = ref.read(weatherRepositoryProvider);

      // 5 Punkte gleichmaessig auf der Route verteilen
      final points = <WeatherPoint>[];
      final step = (routeCoords.length / 5).floor().clamp(1, routeCoords.length);

      for (int i = 0; i < 5 && i * step < routeCoords.length; i++) {
        final index = i * step;
        final location = routeCoords[index];
        final routePosition = index / (routeCoords.length - 1);

        try {
          // Wetter MIT Vorhersage laden statt nur aktuell
          final weather = await weatherRepo.getWeatherWithForecast(
            location,
            forecastDays: forecastDays,
          );

          points.add(WeatherPoint(
            location: location,
            weather: weather,
            routePosition: routePosition,
            dailyForecast: weather.dailyForecast,
          ));
        } catch (e) {
          debugPrint('[Weather] Forecast Punkt $i fehlgeschlagen: $e');
        }

        // Rate Limiting
        if (i < 4) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }

      final overallCondition = _calculateOverallCondition(points);

      state = RouteWeatherState(
        weatherPoints: points,
        overallCondition: overallCondition,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );

      debugPrint(
          '[Weather] ${points.length} Punkte mit Forecast geladen, Zustand: $overallCondition');
    } catch (e) {
      debugPrint('[Weather] Forecast Fehler: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Wetter-Vorhersage konnte nicht geladen werden',
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
/// Synchronisiert mit POIStateNotifier fuer konsistentes Filtern
@riverpod
class IndoorOnlyFilter extends _$IndoorOnlyFilter {
  @override
  bool build() => false;

  void toggle() {
    state = !state;
    _syncWithPOIState(state);
  }

  void setEnabled(bool enabled) {
    state = enabled;
    _syncWithPOIState(enabled);
  }

  void _syncWithPOIState(bool enabled) {
    try {
      ref.read(pOIStateNotifierProvider.notifier).setIndoorOnly(enabled);
    } catch (_) {
      // POIStateNotifier evtl. noch nicht initialisiert
    }
  }
}

/// State für Standort-Wetter (v1.7.6)
class LocationWeatherState {
  final Weather? weather;
  final String? locationName;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;
  final LatLng? lastLocation;

  const LocationWeatherState({
    this.weather,
    this.locationName,
    this.isLoading = false,
    this.error,
    this.lastUpdated,
    this.lastLocation,
  });

  LocationWeatherState copyWith({
    Weather? weather,
    String? locationName,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
    LatLng? lastLocation,
  }) {
    return LocationWeatherState(
      weather: weather ?? this.weather,
      locationName: locationName ?? this.locationName,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      lastLocation: lastLocation ?? this.lastLocation,
    );
  }

  /// Hat gueltige Wetterdaten
  bool get hasWeather => weather != null;

  /// Wetter-Zustand
  WeatherCondition get condition => weather?.condition ?? WeatherCondition.unknown;

  /// Ist das Wetter schlecht?
  bool get isBadWeather =>
      condition == WeatherCondition.bad || condition == WeatherCondition.danger;

  /// Soll eine Warnung angezeigt werden?
  bool get showWarning => weather?.showWarning ?? false;

  /// Cache noch gueltig (15 Minuten)
  bool get isCacheValid {
    if (lastUpdated == null) return false;
    return DateTime.now().difference(lastUpdated!).inMinutes < 15;
  }
}

/// Provider für Standort-Wetter (v1.7.6)
/// Zeigt Wetter am aktuellen GPS-Standort, auch ohne Route
@Riverpod(keepAlive: true)
class LocationWeatherNotifier extends _$LocationWeatherNotifier {
  @override
  LocationWeatherState build() {
    return const LocationWeatherState();
  }

  /// Lädt Wetter für den aktuellen Standort
  Future<void> loadWeatherForLocation(LatLng position, {String? locationName}) async {
    // Cache pruefen MIT Positions-Check
    if (state.isCacheValid && state.hasWeather && state.lastLocation != null) {
      final distKm = const Distance().as(
        LengthUnit.Kilometer,
        state.lastLocation!,
        position,
      );
      if (distKm < 5.0) {
        debugPrint('[LocationWeather] Cache gueltig (${distKm.toStringAsFixed(1)}km), ueberspringe');
        return;
      }
      debugPrint('[LocationWeather] Standort gewechselt (${distKm.toStringAsFixed(1)}km), lade neu');
    } else if (state.isCacheValid && state.hasWeather) {
      debugPrint('[LocationWeather] Cache gueltig, ueberspringe');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final weatherRepo = ref.read(weatherRepositoryProvider);

      // Wetter mit 7-Tage-Vorhersage laden
      final weather = await weatherRepo.getWeatherWithForecast(position);

      state = LocationWeatherState(
        weather: weather,
        locationName: locationName,
        isLoading: false,
        lastUpdated: DateTime.now(),
        lastLocation: position,
      );

      debugPrint('[LocationWeather] Wetter geladen: ${weather.description}, ${weather.formattedTemperature}');

      if (weather.showWarning) {
        debugPrint('[LocationWeather] WARNUNG: ${weather.condition.label}');
      }
    } catch (e) {
      debugPrint('[LocationWeather] Fehler: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Wetter konnte nicht geladen werden',
      );
    }
  }

  /// Aktualisiert das Wetter (erzwingt Neuladen)
  Future<void> refresh(LatLng position, {String? locationName}) async {
    state = state.copyWith(lastUpdated: null); // Cache invalidieren
    await loadWeatherForLocation(position, locationName: locationName);
  }

  /// Löscht die Wetter-Daten
  void clear() {
    state = const LocationWeatherState();
  }
}
