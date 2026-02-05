import 'package:flutter_test/flutter_test.dart';
import 'package:travel_planner/core/constants/categories.dart';
import '../helpers/test_factories.dart';

void main() {
  group('WeatherCondition.fromWmoCode', () {
    test('Code 0 (klar) ist good', () {
      expect(WeatherCondition.fromWmoCode(0), WeatherCondition.good);
    });

    test('Code 1 (ueberwiegend klar) ist good', () {
      expect(WeatherCondition.fromWmoCode(1), WeatherCondition.good);
    });

    test('Code 2 (teilweise bewoelkt) ist mixed', () {
      expect(WeatherCondition.fromWmoCode(2), WeatherCondition.mixed);
    });

    test('Code 3 (bewoelkt) ist mixed', () {
      expect(WeatherCondition.fromWmoCode(3), WeatherCondition.mixed);
    });

    test('Nebel-Codes (45, 48) sind bad', () {
      expect(WeatherCondition.fromWmoCode(45), WeatherCondition.bad);
      expect(WeatherCondition.fromWmoCode(48), WeatherCondition.bad);
    });

    test('Nieselregen-Codes (51-57) sind bad', () {
      for (final code in [51, 53, 55, 56, 57]) {
        expect(WeatherCondition.fromWmoCode(code), WeatherCondition.bad,
            reason: 'WMO Code $code sollte bad sein');
      }
    });

    test('Regen-Codes (61-67) sind bad', () {
      for (final code in [61, 63, 65, 66, 67]) {
        expect(WeatherCondition.fromWmoCode(code), WeatherCondition.bad,
            reason: 'WMO Code $code sollte bad sein');
      }
    });

    test('Schnee-Codes (71-77) sind bad', () {
      for (final code in [71, 73, 75, 77]) {
        expect(WeatherCondition.fromWmoCode(code), WeatherCondition.bad,
            reason: 'WMO Code $code sollte bad sein');
      }
    });

    test('Schauer-Codes (80-82) sind bad', () {
      for (final code in [80, 81, 82]) {
        expect(WeatherCondition.fromWmoCode(code), WeatherCondition.bad,
            reason: 'WMO Code $code sollte bad sein');
      }
    });

    test('Schneeschauer-Codes (85-86) sind bad', () {
      for (final code in [85, 86]) {
        expect(WeatherCondition.fromWmoCode(code), WeatherCondition.bad,
            reason: 'WMO Code $code sollte bad sein');
      }
    });

    test('Gewitter-Codes (95, 96, 99) sind danger', () {
      for (final code in [95, 96, 99]) {
        expect(WeatherCondition.fromWmoCode(code), WeatherCondition.danger,
            reason: 'WMO Code $code sollte danger sein');
      }
    });
  });

  group('WeatherCondition Helpers', () {
    test('isSnowCode erkennt Schnee korrekt', () {
      expect(WeatherCondition.isSnowCode(71), isTrue);
      expect(WeatherCondition.isSnowCode(77), isTrue);
      expect(WeatherCondition.isSnowCode(85), isTrue);
      expect(WeatherCondition.isSnowCode(86), isTrue);
      expect(WeatherCondition.isSnowCode(61), isFalse);
      expect(WeatherCondition.isSnowCode(0), isFalse);
    });

    test('isRainCode erkennt Regen korrekt', () {
      expect(WeatherCondition.isRainCode(51), isTrue);
      expect(WeatherCondition.isRainCode(67), isTrue);
      expect(WeatherCondition.isRainCode(80), isTrue);
      expect(WeatherCondition.isRainCode(82), isTrue);
      expect(WeatherCondition.isRainCode(71), isFalse);
      expect(WeatherCondition.isRainCode(0), isFalse);
    });
  });

  group('Weather Model', () {
    test('condition delegiert an fromWmoCode', () {
      final sunny = createWeather(weatherCode: 0);
      expect(sunny.condition, WeatherCondition.good);

      final rain = createWeather(weatherCode: 61);
      expect(rain.condition, WeatherCondition.bad);

      final storm = createWeather(weatherCode: 95);
      expect(storm.condition, WeatherCondition.danger);
    });

    test('icon gibt korrektes Emoji', () {
      expect(createWeather(weatherCode: 0).icon, '☀️');
      expect(createWeather(weatherCode: 1).icon, '🌤️');
      expect(createWeather(weatherCode: 2).icon, '⛅');
      expect(createWeather(weatherCode: 3).icon, '☁️');
      expect(createWeather(weatherCode: 45).icon, '🌫️');
      expect(createWeather(weatherCode: 61).icon, '🌧️');
      expect(createWeather(weatherCode: 71).icon, '🌨️');
      expect(createWeather(weatherCode: 80).icon, '🌦️');
      expect(createWeather(weatherCode: 95).icon, '⛈️');
    });

    test('description gibt deutsche Beschreibung', () {
      expect(createWeather(weatherCode: 0).description, 'Klar');
      expect(createWeather(weatherCode: 3).description, 'Bewölkt');
      expect(createWeather(weatherCode: 45).description, 'Nebel');
      expect(createWeather(weatherCode: 61).description, 'Regen');
      expect(createWeather(weatherCode: 71).description, 'Schneefall');
      expect(createWeather(weatherCode: 95).description, 'Gewitter');
      expect(createWeather(weatherCode: 96).description, 'Gewitter mit Hagel');
      expect(createWeather(weatherCode: 999).description, 'Unbekannt');
    });

    test('formattedTemperature rundet korrekt', () {
      expect(createWeather(temperature: 20.4).formattedTemperature, '20°C');
      expect(createWeather(temperature: 20.6).formattedTemperature, '21°C');
      expect(createWeather(temperature: -5.3).formattedTemperature, '-5°C');
      expect(createWeather(temperature: 0.0).formattedTemperature, '0°C');
    });

    test('isGoodForOutdoor bei good und mixed', () {
      expect(createWeather(weatherCode: 0).isGoodForOutdoor, isTrue);
      expect(createWeather(weatherCode: 2).isGoodForOutdoor, isTrue);
      expect(createWeather(weatherCode: 61).isGoodForOutdoor, isFalse);
      expect(createWeather(weatherCode: 95).isGoodForOutdoor, isFalse);
    });

    test('showWarning bei bad und danger', () {
      expect(createWeather(weatherCode: 0).showWarning, isFalse);
      expect(createWeather(weatherCode: 2).showWarning, isFalse);
      expect(createWeather(weatherCode: 61).showWarning, isTrue);
      expect(createWeather(weatherCode: 95).showWarning, isTrue);
    });
  });

  group('DailyForecast Model', () {
    test('condition delegiert an fromWmoCode', () {
      final forecast = createDailyForecast(weatherCode: 61);
      expect(forecast.condition, WeatherCondition.bad);
    });

    test('icon gibt korrektes Emoji', () {
      expect(createDailyForecast(weatherCode: 0).icon, '☀️');
      expect(createDailyForecast(weatherCode: 2).icon, '⛅');
      expect(createDailyForecast(weatherCode: 61).icon, '🌧️');
      expect(createDailyForecast(weatherCode: 71).icon, '🌨️');
      expect(createDailyForecast(weatherCode: 95).icon, '⛈️');
    });

    test('temperatureRange formatiert korrekt', () {
      final forecast =
          createDailyForecast(temperatureMin: 12.3, temperatureMax: 24.7);
      expect(forecast.temperatureRange, '12° / 25°');
    });

    test('temperatureRange mit negativen Werten', () {
      final forecast =
          createDailyForecast(temperatureMin: -5.8, temperatureMax: 3.2);
      expect(forecast.temperatureRange, '-6° / 3°');
    });

    test('weekday gibt deutsche Abkuerzungen', () {
      // Montag = 2025-07-14
      expect(
        createDailyForecast(date: DateTime(2025, 7, 14)).weekday,
        'Mo',
      );
      // Sonntag = 2025-07-20
      expect(
        createDailyForecast(date: DateTime(2025, 7, 20)).weekday,
        'So',
      );
      // Mittwoch = 2025-07-16
      expect(
        createDailyForecast(date: DateTime(2025, 7, 16)).weekday,
        'Mi',
      );
    });
  });

  group('POICategory Weather Properties', () {
    test('Indoor-Kategorien sind korrekt', () {
      expect(POICategory.museum.isIndoor, isTrue);
      expect(POICategory.church.isIndoor, isTrue);
      expect(POICategory.restaurant.isIndoor, isTrue);
      expect(POICategory.hotel.isIndoor, isTrue);

      expect(POICategory.nature.isIndoor, isFalse);
      expect(POICategory.viewpoint.isIndoor, isFalse);
      expect(POICategory.park.isIndoor, isFalse);
    });

    test('Weather-resiliente Kategorien enthalten Indoor + Castle + Activity',
        () {
      final resilient = POICategory.weatherResilientCategories;
      expect(resilient, contains(POICategory.museum));
      expect(resilient, contains(POICategory.castle));
      expect(resilient, contains(POICategory.activity));
      expect(resilient, isNot(contains(POICategory.nature)));
      expect(resilient, isNot(contains(POICategory.viewpoint)));
    });
  });
}
