import 'package:flutter/material.dart';
import '../constants/categories.dart';
import '../../data/models/poi.dart';
import 'scoring_utils.dart';

/// Badge-Information fuer ein POI bei gegebenem Wetter
class WeatherBadgeInfo {
  final String text;
  final String icon;
  final Color bgColor;
  final Color fgColor;

  const WeatherBadgeInfo({
    required this.text,
    required this.icon,
    required this.bgColor,
    required this.fgColor,
  });
}

/// Zentralisierte Wetter-POI-Logik
/// Ersetzt verstreute Indoor-Check-Duplikate in editable_poi_card,
/// day_editor_overlay und ai_trip_advisor_provider.
class WeatherPOIUtils {
  WeatherPOIUtils._();

  /// Wetter-adjustierter Score fuer ein POI.
  /// Delegiert an ScoringUtils.adjustScoreForWeather().
  static double getWeatherAdjustedScore(POI poi, WeatherCondition condition) {
    final isWeatherResilient = poi.category?.isWeatherResilient ?? false;
    return ScoringUtils.adjustScoreForWeather(
      score: poi.effectiveScore ?? poi.score.toDouble(),
      isIndoorPOI: isWeatherResilient,
      weatherCondition: condition,
    );
  }

  /// Sortiert POIs nach Wetter-Relevanz.
  /// Bei schlechtem Wetter: Indoor/weather-resilient hoch.
  /// Bei gutem Wetter: Outdoor hoch.
  /// Behaelt die Originalreihenfolge bei mixed/unknown.
  static List<POI> sortByWeatherRelevance(
    List<POI> pois,
    WeatherCondition condition,
  ) {
    if (condition == WeatherCondition.unknown ||
        condition == WeatherCondition.mixed) {
      return pois;
    }

    final sorted = List<POI>.from(pois);
    sorted.sort((a, b) {
      final scoreA = getWeatherAdjustedScore(a, condition);
      final scoreB = getWeatherAdjustedScore(b, condition);
      return scoreB.compareTo(scoreA);
    });
    return sorted;
  }

  /// Badge-Info fuer ein POI bei gegebenem Wetter.
  /// Gibt null zurueck wenn kein Badge angezeigt werden soll.
  static WeatherBadgeInfo? getBadgeForPOI(
    POI poi,
    WeatherCondition condition,
    ColorScheme colorScheme,
  ) {
    final isWeatherResilient = poi.category?.isWeatherResilient ?? false;
    return getBadgeRaw(
      isWeatherResilient: isWeatherResilient,
      condition: condition,
      colorScheme: colorScheme,
    );
  }

  /// Badge-Info basierend auf rohen Parametern (ohne POI-Objekt).
  /// Kann direkt von Widgets genutzt werden die nur isWeatherResilient kennen.
  static WeatherBadgeInfo? getBadgeRaw({
    required bool isWeatherResilient,
    required WeatherCondition condition,
    required ColorScheme colorScheme,
  }) {
    // Schlechtes/Gefaehrliches Wetter
    if (condition == WeatherCondition.danger ||
        condition == WeatherCondition.bad) {
      if (isWeatherResilient) {
        return WeatherBadgeInfo(
          text: 'Empfohlen',
          icon: '\u{1F44D}',
          bgColor: colorScheme.primaryContainer,
          fgColor: colorScheme.onPrimaryContainer,
        );
      } else {
        if (condition == WeatherCondition.danger) {
          return WeatherBadgeInfo(
            text: 'Unwetter',
            icon: '\u{26A0}\u{FE0F}',
            bgColor: colorScheme.errorContainer,
            fgColor: colorScheme.onErrorContainer,
          );
        }
        return WeatherBadgeInfo(
          text: 'Regen',
          icon: '\u{1F327}\u{FE0F}',
          bgColor: colorScheme.tertiaryContainer,
          fgColor: colorScheme.onTertiaryContainer,
        );
      }
    }

    // Gutes Wetter - Outdoor hervorheben
    if (condition == WeatherCondition.good && !isWeatherResilient) {
      return WeatherBadgeInfo(
        text: 'Ideal',
        icon: '\u{1F31E}',
        bgColor: colorScheme.primaryContainer,
        fgColor: colorScheme.onPrimaryContainer,
      );
    }

    return null;
  }

  /// Ist dieses POI bei aktuellem Wetter "empfohlen"?
  static bool isWeatherRecommended(POI poi, WeatherCondition condition) {
    final isResilient = poi.category?.isWeatherResilient ?? false;

    if (condition == WeatherCondition.bad ||
        condition == WeatherCondition.danger) {
      return isResilient;
    }
    if (condition == WeatherCondition.good) {
      return !poi.isIndoor;
    }
    return false;
  }
}
