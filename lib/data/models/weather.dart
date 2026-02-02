import 'package:freezed_annotation/freezed_annotation.dart';
import '../../core/constants/categories.dart';

part 'weather.freezed.dart';
part 'weather.g.dart';

/// Wetter-Datenmodell
/// Übernommen von MapAB js/services/weather.js
@freezed
class Weather with _$Weather {
  const Weather._();

  const factory Weather({
    /// Koordinaten
    required double latitude,
    required double longitude,

    /// Aktuelle Temperatur (°C)
    required double temperature,

    /// Gefühlte Temperatur (°C)
    double? apparentTemperature,

    /// Wetter-Code (WMO)
    required int weatherCode,

    /// Niederschlag (mm)
    @Default(0) double precipitation,

    /// Niederschlagswahrscheinlichkeit (%)
    @Default(0) int precipitationProbability,

    /// Windgeschwindigkeit (km/h)
    @Default(0) double windSpeed,

    /// Wind-Böen (km/h)
    double? windGusts,

    /// Wolkendecke (%)
    @Default(0) int cloudCover,

    /// UV-Index
    double? uvIndex,

    /// Zeitstempel
    required DateTime timestamp,

    /// Tages-Vorhersage
    @Default([]) List<DailyForecast> dailyForecast,
  }) = _Weather;

  /// Erstellt Weather aus JSON
  factory Weather.fromJson(Map<String, dynamic> json) =>
      _$WeatherFromJson(json);

  /// Wetter-Zustand basierend auf Code
  WeatherCondition get condition {
    // WMO Weather Codes: https://open-meteo.com/en/docs
    // 0 = Klar, 1-3 = Leicht bewölkt, 45-48 = Nebel
    // 51-67 = Regen, 71-77 = Schnee, 80-82 = Schauer
    // 85-86 = Schneeschauer, 95-99 = Gewitter

    if (weatherCode == 0 || weatherCode == 1) {
      return WeatherCondition.good;
    } else if (weatherCode <= 3) {
      return WeatherCondition.mixed;
    } else if (weatherCode >= 45 && weatherCode <= 48) {
      // Nebel = schlecht fuer Outdoor (Aussichtspunkte, Wanderungen, Scenic Drives)
      return WeatherCondition.bad;
    } else if (weatherCode >= 95) {
      return WeatherCondition.danger;
    } else {
      return WeatherCondition.bad;
    }
  }

  /// Wetter-Icon basierend auf Code
  String get icon {
    if (weatherCode == 0) return '☀️';
    if (weatherCode == 1) return '🌤️';
    if (weatherCode == 2) return '⛅';
    if (weatherCode == 3) return '☁️';
    if (weatherCode >= 45 && weatherCode <= 48) return '🌫️';
    if (weatherCode >= 51 && weatherCode <= 57) return '🌧️';
    if (weatherCode >= 61 && weatherCode <= 67) return '🌧️';
    if (weatherCode >= 71 && weatherCode <= 77) return '🌨️';
    if (weatherCode >= 80 && weatherCode <= 82) return '🌦️';
    if (weatherCode >= 85 && weatherCode <= 86) return '🌨️';
    if (weatherCode >= 95) return '⛈️';
    return '❓';
  }

  /// Wetter-Beschreibung auf Deutsch
  String get description {
    switch (weatherCode) {
      case 0:
        return 'Klar';
      case 1:
        return 'Überwiegend klar';
      case 2:
        return 'Teilweise bewölkt';
      case 3:
        return 'Bewölkt';
      case 45:
      case 48:
        return 'Nebel';
      case 51:
      case 53:
      case 55:
        return 'Nieselregen';
      case 56:
      case 57:
        return 'Gefrierender Nieselregen';
      case 61:
      case 63:
      case 65:
        return 'Regen';
      case 66:
      case 67:
        return 'Gefrierender Regen';
      case 71:
      case 73:
      case 75:
        return 'Schneefall';
      case 77:
        return 'Schneegriesel';
      case 80:
      case 81:
      case 82:
        return 'Regenschauer';
      case 85:
      case 86:
        return 'Schneeschauer';
      case 95:
        return 'Gewitter';
      case 96:
      case 99:
        return 'Gewitter mit Hagel';
      default:
        return 'Unbekannt';
    }
  }

  /// Formatierte Temperatur
  String get formattedTemperature => '${temperature.round()}°C';

  /// Ist gutes Wetter für Outdoor-Aktivitäten
  bool get isGoodForOutdoor =>
      condition == WeatherCondition.good || condition == WeatherCondition.mixed;

  /// Warnung anzeigen
  bool get showWarning =>
      condition == WeatherCondition.bad || condition == WeatherCondition.danger;
}

/// Tages-Vorhersage
@freezed
class DailyForecast with _$DailyForecast {
  const DailyForecast._();

  const factory DailyForecast({
    /// Datum
    required DateTime date,

    /// Maximale Temperatur (°C)
    required double temperatureMax,

    /// Minimale Temperatur (°C)
    required double temperatureMin,

    /// Wetter-Code
    required int weatherCode,

    /// Niederschlagssumme (mm)
    @Default(0) double precipitationSum,

    /// Niederschlagswahrscheinlichkeit (%)
    @Default(0) int precipitationProbabilityMax,

    /// Maximale Windgeschwindigkeit (km/h)
    @Default(0) double windSpeedMax,

    /// UV-Index Maximum
    double? uvIndexMax,

    /// Sonnenaufgang
    DateTime? sunrise,

    /// Sonnenuntergang
    DateTime? sunset,
  }) = _DailyForecast;

  /// Erstellt DailyForecast aus JSON
  factory DailyForecast.fromJson(Map<String, dynamic> json) =>
      _$DailyForecastFromJson(json);

  /// Wetter-Zustand basierend auf Code
  WeatherCondition get condition {
    if (weatherCode == 0 || weatherCode == 1) return WeatherCondition.good;
    if (weatherCode <= 3) return WeatherCondition.mixed;
    if (weatherCode >= 45 && weatherCode <= 48) return WeatherCondition.bad;
    if (weatherCode >= 95) return WeatherCondition.danger;
    return WeatherCondition.bad;
  }

  /// Wetter-Icon
  String get icon {
    if (weatherCode == 0) return '☀️';
    if (weatherCode <= 3) return '⛅';
    if (weatherCode >= 45 && weatherCode <= 48) return '🌫️';
    if (weatherCode >= 51 && weatherCode <= 67) return '🌧️';
    if (weatherCode >= 71 && weatherCode <= 86) return '🌨️';
    if (weatherCode >= 95) return '⛈️';
    return '❓';
  }

  /// Formatierte Temperatur-Range
  String get temperatureRange =>
      '${temperatureMin.round()}° / ${temperatureMax.round()}°';

  /// Wochentag auf Deutsch
  String get weekday {
    const weekdays = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    return weekdays[date.weekday - 1];
  }
}
