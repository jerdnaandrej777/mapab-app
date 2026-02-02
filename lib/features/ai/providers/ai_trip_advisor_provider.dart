import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/constants/categories.dart';
import '../../../data/models/poi.dart';
import '../../../data/models/trip.dart';
import '../../../data/models/weather.dart';
import '../../../data/services/ai_service.dart';
import '../../map/providers/weather_provider.dart';
import '../../random_trip/providers/random_trip_provider.dart';

part 'ai_trip_advisor_provider.g.dart';

/// Vorschlags-Typ
enum SuggestionType { weather, optimization, alternative, general }

/// AI-Vorschlag fuer einen Trip
class AISuggestion {
  final String message;
  final SuggestionType type;
  final String? targetPOIId;
  final POI? alternativePOI;
  final WeatherCondition? weather;

  const AISuggestion({
    required this.message,
    required this.type,
    this.targetPOIId,
    this.alternativePOI,
    this.weather,
  });
}

/// State fuer AI Trip Advisor
class AITripAdvisorState {
  final Map<int, List<AISuggestion>> suggestionsPerDay;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  const AITripAdvisorState({
    this.suggestionsPerDay = const {},
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  AITripAdvisorState copyWith({
    Map<int, List<AISuggestion>>? suggestionsPerDay,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) {
    return AITripAdvisorState(
      suggestionsPerDay: suggestionsPerDay ?? this.suggestionsPerDay,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  List<AISuggestion> getSuggestionsForDay(int day) {
    return suggestionsPerDay[day] ?? [];
  }

  bool hasSuggestionsForDay(int day) {
    return suggestionsPerDay[day]?.isNotEmpty ?? false;
  }
}

/// AI Trip Advisor - generiert Vorschlaege basierend auf Wetter + Route
@Riverpod(keepAlive: true)
class AITripAdvisorNotifier extends _$AITripAdvisorNotifier {
  @override
  AITripAdvisorState build() => const AITripAdvisorState();

  /// Analysiert den Trip und generiert lokale Wetter-Vorschlaege
  /// (Ohne AI-Backend, rein regelbasiert)
  void analyzeTrip(Trip trip, RouteWeatherState routeWeather) {
    if (routeWeather.weatherPoints.isEmpty) return;

    final suggestions = <int, List<AISuggestion>>{};
    final totalDays = trip.actualDays;

    for (int day = 1; day <= totalDays; day++) {
      final daySuggestions = <AISuggestion>[];
      final stopsForDay = trip.getStopsForDay(day);
      if (stopsForDay.isEmpty) continue;

      // Wetter fuer den Tag bestimmen
      final dayWeather = _getDayWeather(day, totalDays, routeWeather);

      if (dayWeather == WeatherCondition.bad ||
          dayWeather == WeatherCondition.danger) {
        // Outdoor-POIs zaehlen
        final outdoorStops = stopsForDay
            .where((s) => s.category != null && !_isIndoor(s.category!))
            .toList();

        if (outdoorStops.isNotEmpty) {
          final isDanger = dayWeather == WeatherCondition.danger;
          daySuggestions.add(AISuggestion(
            message: isDanger
                ? 'Unwetter auf Tag $day erwartet! ${outdoorStops.length} Outdoor-Stops sollten durch Indoor-Alternativen ersetzt werden.'
                : 'Regen auf Tag $day erwartet. ${outdoorStops.length} von ${stopsForDay.length} Stops sind Outdoor-Aktivitaeten.',
            type: SuggestionType.weather,
            weather: dayWeather,
          ));

          // Einzelne Outdoor-POIs markieren
          for (final stop in outdoorStops) {
            daySuggestions.add(AISuggestion(
              message:
                  '${stop.name} ist eine Outdoor-Aktivitaet - Alternative empfohlen',
              type: SuggestionType.alternative,
              targetPOIId: stop.poiId,
              weather: dayWeather,
            ));
          }
        }
      }

      if (daySuggestions.isNotEmpty) {
        suggestions[day] = daySuggestions;
      }
    }

    state = state.copyWith(
      suggestionsPerDay: suggestions,
      lastUpdated: DateTime.now(),
    );

    debugPrint(
        '[AIAdvisor] ${suggestions.length} Tage mit Vorschlaegen gefunden');
  }

  /// Wetter fuer einen bestimmten Tag bestimmen
  WeatherCondition _getDayWeather(
    int day,
    int totalDays,
    RouteWeatherState routeWeather,
  ) {
    if (routeWeather.weatherPoints.isEmpty) return WeatherCondition.unknown;

    final dayPosition =
        totalDays > 1 ? (day - 1) / (totalDays - 1) : 0.5;

    WeatherCondition closest = routeWeather.overallCondition;
    double minDist = double.infinity;
    for (final wp in routeWeather.weatherPoints) {
      final dist = (wp.routePosition - dayPosition).abs();
      if (dist < minDist) {
        minDist = dist;
        closest = wp.weather.condition;
      }
    }
    return closest;
  }

  bool _isIndoor(POICategory category) {
    const indoor = {
      POICategory.museum,
      POICategory.church,
      POICategory.restaurant,
      POICategory.hotel,
    };
    return indoor.contains(category);
  }

  /// Zuruecksetzen
  void reset() {
    state = const AITripAdvisorState();
  }
}
