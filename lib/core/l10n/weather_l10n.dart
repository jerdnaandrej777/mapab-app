import 'package:flutter/widgets.dart';
import 'l10n.dart';

/// Lokalisierte Wetter-Beschreibung basierend auf WMO Weather Code
/// Wird als Utility-Funktion bereitgestellt, da Freezed-Models
/// keinen BuildContext haben koennen.
String localizedWeatherDescription(BuildContext context, int weatherCode) {
  final l10n = context.l10n;
  switch (weatherCode) {
    case 0:
      return l10n.weatherClear;
    case 1:
      return l10n.weatherMostlyClear;
    case 2:
      return l10n.weatherPartlyCloudy;
    case 3:
      return l10n.weatherCloudy;
    case 45:
    case 48:
      return l10n.weatherFog;
    case 51:
    case 53:
    case 55:
      return l10n.weatherDrizzle;
    case 56:
    case 57:
      return l10n.weatherFreezingDrizzle;
    case 61:
    case 63:
    case 65:
      return l10n.weatherRain;
    case 66:
    case 67:
      return l10n.weatherFreezingRain;
    case 71:
    case 73:
    case 75:
      return l10n.weatherSnow;
    case 77:
      return l10n.weatherSnowGrains;
    case 80:
    case 81:
    case 82:
      return l10n.weatherRainShowers;
    case 85:
    case 86:
      return l10n.weatherSnowShowers;
    case 95:
      return l10n.weatherThunderstorm;
    case 96:
    case 99:
      return l10n.weatherThunderstormHail;
    default:
      return l10n.weatherUnknown;
  }
}

/// Lokalisierter Wochentag (Kurzform) basierend auf weekday (1=Montag)
String localizedWeekday(BuildContext context, int weekday) {
  final l10n = context.l10n;
  return switch (weekday) {
    1 => l10n.weekdayMon,
    2 => l10n.weekdayTue,
    3 => l10n.weekdayWed,
    4 => l10n.weekdayThu,
    5 => l10n.weekdayFri,
    6 => l10n.weekdaySat,
    7 => l10n.weekdaySun,
    _ => '?',
  };
}
