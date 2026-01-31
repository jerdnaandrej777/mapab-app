import 'package:flutter_test/flutter_test.dart';
import 'package:travel_planner/core/utils/scoring_utils.dart';
import 'package:travel_planner/core/constants/categories.dart';

void main() {
  group('ScoringUtils - getStarRating', () {
    test('Score 0 gibt 1 Stern', () {
      expect(ScoringUtils.getStarRating(0), 1.0);
    });

    test('Score 20 gibt 1 Stern', () {
      expect(ScoringUtils.getStarRating(20), 1.0);
    });

    test('Score 100 gibt 5 Sterne', () {
      expect(ScoringUtils.getStarRating(100), 5.0);
    });

    test('Score 60 gibt mittlere Bewertung', () {
      final rating = ScoringUtils.getStarRating(60);
      expect(rating, greaterThan(2.0));
      expect(rating, lessThan(4.0));
    });

    test('Score steigt monoton', () {
      double lastRating = 0;
      for (int score = 0; score <= 100; score += 10) {
        final rating = ScoringUtils.getStarRating(score);
        expect(rating, greaterThanOrEqualTo(lastRating));
        lastRating = rating;
      }
    });
  });

  group('ScoringUtils - getReviewCount', () {
    test('Kuratierte POIs haben mehr Reviews', () {
      final normal = ScoringUtils.getReviewCount(
        score: 50,
        isCurated: false,
        hasWikipedia: false,
      );
      final curated = ScoringUtils.getReviewCount(
        score: 50,
        isCurated: true,
        hasWikipedia: false,
      );
      expect(curated, greaterThan(normal));
    });

    test('Wikipedia-POIs haben mehr Reviews', () {
      final noWiki = ScoringUtils.getReviewCount(
        score: 50,
        isCurated: false,
        hasWikipedia: false,
      );
      final withWiki = ScoringUtils.getReviewCount(
        score: 50,
        isCurated: false,
        hasWikipedia: true,
      );
      expect(withWiki, greaterThan(noWiki));
    });

    test('Reviews sind mindestens 10', () {
      final count = ScoringUtils.getReviewCount(
        score: 0,
        isCurated: false,
        hasWikipedia: false,
      );
      expect(count, greaterThanOrEqualTo(10));
    });

    test('Reviews sind maximal 5000', () {
      final count = ScoringUtils.getReviewCount(
        score: 100,
        isCurated: true,
        hasWikipedia: true,
      );
      expect(count, lessThanOrEqualTo(5000));
    });
  });

  group('ScoringUtils - isMustSee', () {
    test('UNESCO ist immer Must-See', () {
      expect(
        ScoringUtils.isMustSee(
          score: 10,
          reviewCount: 10,
          isCurated: false,
          hasWikipedia: false,
          isUnesco: true,
        ),
        isTrue,
      );
    });

    test('Hoher Score mit Wikipedia ist Must-See', () {
      final score = 90;
      final reviewCount = ScoringUtils.getReviewCount(
        score: score,
        isCurated: false,
        hasWikipedia: true,
      );
      expect(
        ScoringUtils.isMustSee(
          score: score,
          reviewCount: reviewCount,
          isCurated: false,
          hasWikipedia: true,
          isUnesco: false,
        ),
        isTrue,
      );
    });

    test('Niedriger Score ist kein Must-See', () {
      expect(
        ScoringUtils.isMustSee(
          score: 20,
          reviewCount: 10,
          isCurated: false,
          hasWikipedia: false,
          isUnesco: false,
        ),
        isFalse,
      );
    });
  });

  group('ScoringUtils - calculateEffectiveScore', () {
    test('Umweg reduziert Score', () {
      final noDetour = ScoringUtils.calculateEffectiveScore(
        baseScore: 80,
        detourKm: 0,
        routePosition: 0.5,
        isMustSee: false,
      );
      final withDetour = ScoringUtils.calculateEffectiveScore(
        baseScore: 80,
        detourKm: 20,
        routePosition: 0.5,
        isMustSee: false,
      );
      expect(withDetour, lessThan(noDetour));
    });

    test('Must-See bekommt Bonus', () {
      final normal = ScoringUtils.calculateEffectiveScore(
        baseScore: 50,
        detourKm: 0,
        routePosition: 0.5,
        isMustSee: false,
      );
      final mustSee = ScoringUtils.calculateEffectiveScore(
        baseScore: 50,
        detourKm: 0,
        routePosition: 0.5,
        isMustSee: true,
      );
      expect(mustSee, greaterThan(normal));
    });

    test('Mitte der Route bekommt Positions-Bonus', () {
      final start = ScoringUtils.calculateEffectiveScore(
        baseScore: 50,
        detourKm: 0,
        routePosition: 0.05,
        isMustSee: false,
      );
      final middle = ScoringUtils.calculateEffectiveScore(
        baseScore: 50,
        detourKm: 0,
        routePosition: 0.5,
        isMustSee: false,
      );
      expect(middle, greaterThan(start));
    });

    test('Score bleibt zwischen 0 und 100', () {
      final high = ScoringUtils.calculateEffectiveScore(
        baseScore: 100,
        detourKm: 0,
        routePosition: 0.5,
        isMustSee: true,
      );
      final low = ScoringUtils.calculateEffectiveScore(
        baseScore: 0,
        detourKm: 100,
        routePosition: 0.0,
        isMustSee: false,
      );
      expect(high, lessThanOrEqualTo(100));
      expect(low, greaterThanOrEqualTo(0));
    });
  });

  group('ScoringUtils - adjustScoreForWeather', () {
    test('Indoor-POIs bekommen Bonus bei schlechtem Wetter', () {
      final normal = ScoringUtils.adjustScoreForWeather(
        score: 50,
        isIndoorPOI: true,
        weatherCondition: WeatherCondition.good,
      );
      final bad = ScoringUtils.adjustScoreForWeather(
        score: 50,
        isIndoorPOI: true,
        weatherCondition: WeatherCondition.bad,
      );
      expect(bad, greaterThan(normal));
    });

    test('Outdoor-POIs werden bei schlechtem Wetter abgewertet', () {
      final good = ScoringUtils.adjustScoreForWeather(
        score: 50,
        isIndoorPOI: false,
        weatherCondition: WeatherCondition.good,
      );
      final bad = ScoringUtils.adjustScoreForWeather(
        score: 50,
        isIndoorPOI: false,
        weatherCondition: WeatherCondition.bad,
      );
      expect(bad, lessThan(good));
    });

    test('Outdoor-POIs bekommen leichten Bonus bei gutem Wetter', () {
      final mixed = ScoringUtils.adjustScoreForWeather(
        score: 50,
        isIndoorPOI: false,
        weatherCondition: WeatherCondition.mixed,
      );
      final good = ScoringUtils.adjustScoreForWeather(
        score: 50,
        isIndoorPOI: false,
        weatherCondition: WeatherCondition.good,
      );
      expect(good, greaterThan(mixed));
    });
  });

  group('ScoringUtils - getScoringWeights', () {
    test('Scenic-Trip gewichtet Viewpoints hoch', () {
      final weights = ScoringUtils.getScoringWeights('scenic');
      expect(weights['viewpoint'], greaterThan(1.0));
    });

    test('Culture-Trip gewichtet Museen hoch', () {
      final weights = ScoringUtils.getScoringWeights('culture');
      expect(weights['museum'], greaterThan(1.0));
    });

    test('Unbekannter Trip-Typ hat leere Gewichtung', () {
      final weights = ScoringUtils.getScoringWeights('unknown');
      expect(weights, isEmpty);
    });
  });
}
