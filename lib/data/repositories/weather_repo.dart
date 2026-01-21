import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/constants/api_endpoints.dart';
import '../models/weather.dart';

part 'weather_repo.g.dart';

/// Repository für Wetterdaten via Open-Meteo
/// Übernommen von MapAB js/services/weather.js
class WeatherRepository {
  final Dio _dio;

  WeatherRepository({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              headers: {'User-Agent': ApiConfig.userAgent},
              connectTimeout: const Duration(milliseconds: ApiConfig.defaultTimeout),
              receiveTimeout: const Duration(milliseconds: ApiConfig.defaultTimeout),
            ));

  /// Holt aktuelle Wetterdaten für eine Position
  Future<Weather> getCurrentWeather(LatLng location) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.openMeteoForecast,
        queryParameters: {
          'latitude': location.latitude,
          'longitude': location.longitude,
          'current': [
            'temperature_2m',
            'apparent_temperature',
            'weather_code',
            'precipitation',
            'wind_speed_10m',
            'wind_gusts_10m',
            'cloud_cover',
          ].join(','),
          'timezone': 'auto',
        },
      );

      final current = response.data['current'];

      return Weather(
        latitude: location.latitude,
        longitude: location.longitude,
        temperature: (current['temperature_2m'] as num).toDouble(),
        apparentTemperature: (current['apparent_temperature'] as num?)?.toDouble(),
        weatherCode: current['weather_code'] as int,
        precipitation: (current['precipitation'] as num?)?.toDouble() ?? 0,
        windSpeed: (current['wind_speed_10m'] as num?)?.toDouble() ?? 0,
        windGusts: (current['wind_gusts_10m'] as num?)?.toDouble(),
        cloudCover: (current['cloud_cover'] as num?)?.toInt() ?? 0,
        timestamp: DateTime.now(),
      );
    } on DioException catch (e) {
      throw WeatherException('Wetterdaten konnten nicht geladen werden: ${e.message}');
    }
  }

  /// Holt Wetter mit Tages-Vorhersage
  Future<Weather> getWeatherWithForecast(
    LatLng location, {
    int forecastDays = 7,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.openMeteoForecast,
        queryParameters: {
          'latitude': location.latitude,
          'longitude': location.longitude,
          'current': [
            'temperature_2m',
            'apparent_temperature',
            'weather_code',
            'precipitation',
            'precipitation_probability',
            'wind_speed_10m',
            'wind_gusts_10m',
            'cloud_cover',
            'uv_index',
          ].join(','),
          'daily': [
            'temperature_2m_max',
            'temperature_2m_min',
            'weather_code',
            'precipitation_sum',
            'precipitation_probability_max',
            'wind_speed_10m_max',
            'uv_index_max',
            'sunrise',
            'sunset',
          ].join(','),
          'forecast_days': forecastDays,
          'timezone': 'auto',
        },
      );

      final current = response.data['current'];
      final daily = response.data['daily'];

      // Tages-Vorhersagen parsen
      final forecasts = <DailyForecast>[];
      final dates = daily['time'] as List;

      for (int i = 0; i < dates.length; i++) {
        forecasts.add(DailyForecast(
          date: DateTime.parse(dates[i]),
          temperatureMax: (daily['temperature_2m_max'][i] as num).toDouble(),
          temperatureMin: (daily['temperature_2m_min'][i] as num).toDouble(),
          weatherCode: daily['weather_code'][i] as int,
          precipitationSum: (daily['precipitation_sum'][i] as num?)?.toDouble() ?? 0,
          precipitationProbabilityMax:
              (daily['precipitation_probability_max'][i] as num?)?.toInt() ?? 0,
          windSpeedMax: (daily['wind_speed_10m_max'][i] as num?)?.toDouble() ?? 0,
          uvIndexMax: (daily['uv_index_max'][i] as num?)?.toDouble(),
          sunrise: daily['sunrise'][i] != null
              ? DateTime.parse(daily['sunrise'][i])
              : null,
          sunset: daily['sunset'][i] != null
              ? DateTime.parse(daily['sunset'][i])
              : null,
        ));
      }

      return Weather(
        latitude: location.latitude,
        longitude: location.longitude,
        temperature: (current['temperature_2m'] as num).toDouble(),
        apparentTemperature: (current['apparent_temperature'] as num?)?.toDouble(),
        weatherCode: current['weather_code'] as int,
        precipitation: (current['precipitation'] as num?)?.toDouble() ?? 0,
        precipitationProbability:
            (current['precipitation_probability'] as num?)?.toInt() ?? 0,
        windSpeed: (current['wind_speed_10m'] as num?)?.toDouble() ?? 0,
        windGusts: (current['wind_gusts_10m'] as num?)?.toDouble(),
        cloudCover: (current['cloud_cover'] as num?)?.toInt() ?? 0,
        uvIndex: (current['uv_index'] as num?)?.toDouble(),
        timestamp: DateTime.now(),
        dailyForecast: forecasts,
      );
    } on DioException catch (e) {
      throw WeatherException('Wettervorhersage fehlgeschlagen: ${e.message}');
    }
  }

  /// Holt Wetter für mehrere Punkte entlang einer Route
  Future<List<Weather>> getWeatherAlongRoute(
    List<LatLng> routePoints, {
    int maxPoints = 5,
  }) async {
    // Punkte gleichmäßig entlang der Route auswählen
    final step = (routePoints.length / maxPoints).floor().clamp(1, routePoints.length);
    final selectedPoints = <LatLng>[];

    for (int i = 0; i < routePoints.length && selectedPoints.length < maxPoints; i += step) {
      selectedPoints.add(routePoints[i]);
    }

    // Wetter für alle Punkte parallel laden
    final weatherResults = await Future.wait(
      selectedPoints.map((point) => getCurrentWeather(point)),
    );

    return weatherResults;
  }
}

/// Weather Exception
class WeatherException implements Exception {
  final String message;
  WeatherException(this.message);

  @override
  String toString() => 'WeatherException: $message';
}

/// Riverpod Provider für WeatherRepository
@riverpod
WeatherRepository weatherRepository(WeatherRepositoryRef ref) {
  return WeatherRepository();
}
