import 'dart:math' as math;
import '../constants/categories.dart';

/// Scoring-Utilities für POI-Bewertung
/// Übernommen von MapAB js/utils/scoring.js
class ScoringUtils {
  ScoringUtils._();

  /// Berechnet die Sterne-Bewertung (1.0 - 5.0) basierend auf dem Score
  static double getStarRating(int score) {
    // Score 0-100 auf 1-5 Sterne mappen
    // Score < 20 = 1 Stern, Score 100 = 5 Sterne
    if (score <= 20) return 1.0;
    if (score >= 100) return 5.0;

    // Lineare Interpolation
    return 1.0 + (score - 20) * 4.0 / 80.0;
  }

  /// Berechnet eine simulierte Bewertungsanzahl basierend auf Qualität
  /// Kuratierte POIs haben mehr Bewertungen
  static int getReviewCount({
    required int score,
    required bool isCurated,
    required bool hasWikipedia,
  }) {
    // Basis-Bewertungen
    int baseReviews = 10 + (score * 10);

    // Kuratierte POIs sind bekannter
    if (isCurated) {
      baseReviews = (baseReviews * 2.5).round();
    }

    // Wikipedia-Artikel = mehr Bekanntheit
    if (hasWikipedia) {
      baseReviews = (baseReviews * 1.5).round();
    }

    // Etwas Variation hinzufügen
    final variation = (score % 17) * 5;
    baseReviews += variation;

    return baseReviews.clamp(10, 5000);
  }

  /// Prüft ob ein POI ein "Must-See" / Highlight ist
  /// Übernommen von MapAB-Logik
  static bool isMustSee({
    required int score,
    required int reviewCount,
    required bool isCurated,
    required bool hasWikipedia,
    required bool isUnesco,
  }) {
    // UNESCO sind immer Highlights
    if (isUnesco) return true;

    final starRating = getStarRating(score);

    // 4+ Sterne mit hoher Bewertungsanzahl
    if (starRating >= 4.0) {
      if (isCurated && reviewCount >= 200) return true;
      if (hasWikipedia && reviewCount >= 100) return true;
      if (starRating >= 4.5 && reviewCount >= 50) return true;
    }

    return false;
  }

  /// Berechnet den effektiven Score unter Berücksichtigung des Umwegs
  static double calculateEffectiveScore({
    required int baseScore,
    required double detourKm,
    required double routePosition,
    required bool isMustSee,
  }) {
    double score = baseScore.toDouble();

    // Umweg-Abzug (bis zu -30 Punkte)
    final detourPenalty = math.min(detourKm * 0.5, 30);
    score -= detourPenalty;

    // Bonus für POIs in der Mitte der Route (ideal für Pausen)
    final positionBonus = _calculatePositionBonus(routePosition);
    score += positionBonus;

    // Must-See POIs bekommen Bonus
    if (isMustSee) {
      score += 15;
    }

    return score.clamp(0, 100);
  }

  /// Berechnet Positions-Bonus (Mitte der Route bevorzugt)
  static double _calculatePositionBonus(double routePosition) {
    // Optimale Position ist zwischen 30% und 70%
    if (routePosition >= 0.3 && routePosition <= 0.7) {
      return 10;
    } else if (routePosition >= 0.2 && routePosition <= 0.8) {
      return 5;
    }
    return 0;
  }

  /// Sortiert POIs nach effektivem Score
  static List<T> sortByEffectiveScore<T>(
    List<T> pois,
    double Function(T) getEffectiveScore,
  ) {
    final sorted = List<T>.from(pois);
    sorted.sort((a, b) =>
        getEffectiveScore(b).compareTo(getEffectiveScore(a)));
    return sorted;
  }

  /// Gewichtete Scoring-Faktoren für verschiedene Trip-Typen
  static Map<String, double> getScoringWeights(String tripType) {
    switch (tripType) {
      case 'scenic':
        return {
          'viewpoint': 1.5,
          'nature': 1.3,
          'lake': 1.2,
          'coast': 1.2,
          'park': 1.1,
        };
      case 'culture':
        return {
          'museum': 1.5,
          'castle': 1.3,
          'church': 1.2,
          'monument': 1.2,
          'unesco': 1.5,
        };
      case 'family':
        return {
          'attraction': 1.5,
          'activity': 1.3,
          'park': 1.2,
          'lake': 1.1,
        };
      default:
        return {}; // Keine Gewichtung
    }
  }

  /// Wendet Kategorie-Gewichtung auf Score an
  static double applyWeighting({
    required double score,
    required String category,
    required String tripType,
  }) {
    final weights = getScoringWeights(tripType);
    final weight = weights[category] ?? 1.0;
    return score * weight;
  }

  /// Passt den Score basierend auf Wetter-Bedingungen an
  /// Bei schlechtem Wetter: Indoor-POIs +15, Outdoor-POIs -10
  /// Übernommen von MapAB js/services/weather.js
  static double adjustScoreForWeather({
    required double score,
    required bool isIndoorPOI,
    required WeatherCondition weatherCondition,
  }) {
    // Nur bei schlechtem oder gefährlichem Wetter anpassen
    if (weatherCondition == WeatherCondition.bad ||
        weatherCondition == WeatherCondition.danger) {
      if (isIndoorPOI) {
        // Indoor-POIs sind bei schlechtem Wetter attraktiver
        return (score + 15).clamp(0, 100);
      } else {
        // Outdoor-POIs sind bei schlechtem Wetter weniger attraktiv
        return (score - 10).clamp(0, 100);
      }
    }

    // Bei gutem Wetter: Outdoor-POIs leicht bevorzugen
    if (weatherCondition == WeatherCondition.good && !isIndoorPOI) {
      return (score + 5).clamp(0, 100);
    }

    return score;
  }

  /// Berechnet finalen Score mit allen Faktoren
  static double calculateFinalScore({
    required int baseScore,
    required double detourKm,
    required double routePosition,
    required bool isMustSee,
    required bool isIndoorPOI,
    required WeatherCondition weatherCondition,
    String? tripType,
    String? category,
  }) {
    // 1. Basis-Score mit Umweg und Position
    double score = calculateEffectiveScore(
      baseScore: baseScore,
      detourKm: detourKm,
      routePosition: routePosition,
      isMustSee: isMustSee,
    );

    // 2. Trip-Typ Gewichtung
    if (tripType != null && category != null) {
      score = applyWeighting(
        score: score,
        category: category,
        tripType: tripType,
      );
    }

    // 3. Wetter-Anpassung
    score = adjustScoreForWeather(
      score: score,
      isIndoorPOI: isIndoorPOI,
      weatherCondition: weatherCondition,
    );

    return score.clamp(0, 100);
  }
}
