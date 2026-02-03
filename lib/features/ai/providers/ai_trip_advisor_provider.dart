import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/constants/categories.dart';
import '../../../data/models/poi.dart';
import '../../../data/models/trip.dart';
import '../../../data/models/route.dart';
import '../../../data/services/ai_service.dart';
import '../../map/providers/weather_provider.dart';
import '../../trip/providers/corridor_browser_provider.dart';

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
  final String? replacementPOIName;
  final String? actionType; // swap, remove, reorder, add
  final String? aiReasoning; // GPT-Begruendung
  final double? relevanceScore; // 0.0-1.0 Ranking

  const AISuggestion({
    required this.message,
    required this.type,
    this.targetPOIId,
    this.alternativePOI,
    this.weather,
    this.replacementPOIName,
    this.actionType,
    this.aiReasoning,
    this.relevanceScore,
  });
}

/// State fuer AI Trip Advisor
class AITripAdvisorState {
  final Map<int, List<AISuggestion>> suggestionsPerDay;
  final Map<int, List<POI>> recommendedPOIsPerDay;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  const AITripAdvisorState({
    this.suggestionsPerDay = const {},
    this.recommendedPOIsPerDay = const {},
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  AITripAdvisorState copyWith({
    Map<int, List<AISuggestion>>? suggestionsPerDay,
    Map<int, List<POI>>? recommendedPOIsPerDay,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) {
    return AITripAdvisorState(
      suggestionsPerDay: suggestionsPerDay ?? this.suggestionsPerDay,
      recommendedPOIsPerDay:
          recommendedPOIsPerDay ?? this.recommendedPOIsPerDay,
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

  List<POI> getRecommendedPOIsForDay(int day) {
    return recommendedPOIsPerDay[day] ?? [];
  }

  bool hasRecommendedPOIsForDay(int day) {
    return recommendedPOIsPerDay[day]?.isNotEmpty ?? false;
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

  /// AI-basierte Alternativen fuer einen bestimmten Tag vorschlagen
  /// Nutzt AIService.optimizeTrip() via GPT-4o Backend
  Future<void> suggestAlternativesForDay({
    required int day,
    required Trip trip,
    required RouteWeatherState routeWeather,
    required List<POI> availablePOIs,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    debugPrint('[AIAdvisor] Fordere AI-Alternativen fuer Tag $day an...');

    try {
      final aiService = ref.read(aiServiceProvider);

      // Wetter-Strings fuer AI erstellen
      final dayWeatherStrings = routeWeather.hasForecast
          ? routeWeather.getForecastPerDayAsStrings(trip.actualDays)
          : routeWeather.getWeatherPerDayAsStrings(trip.actualDays);

      final optimization = await aiService.optimizeTrip(
        trip: trip,
        dayWeather: dayWeatherStrings,
        availablePOIs: availablePOIs,
      );

      // AI-Vorschlaege in AISuggestion-Objekte umwandeln
      final suggestions = <AISuggestion>[];
      for (final suggestion in optimization.suggestions) {
        final targetDay = suggestion.dayNumber ?? day;
        if (targetDay != day) continue; // Nur Vorschlaege fuer den gewaehlten Tag

        suggestions.add(AISuggestion(
          message: suggestion.message,
          type: suggestion.type == 'weather'
              ? SuggestionType.weather
              : suggestion.type == 'alternative'
                  ? SuggestionType.alternative
                  : SuggestionType.optimization,
          weather: routeWeather.getForecastPerDay(trip.actualDays)[day],
          actionType: suggestion.type,
        ));
      }

      // Zusammenfassung als allgemeinen Vorschlag hinzufuegen
      if (optimization.summary.isNotEmpty && suggestions.isEmpty) {
        suggestions.add(AISuggestion(
          message: optimization.summary,
          type: SuggestionType.general,
        ));
      }

      // Bestehende Vorschlaege fuer den Tag ersetzen
      final updatedSuggestions =
          Map<int, List<AISuggestion>>.from(state.suggestionsPerDay);
      updatedSuggestions[day] = suggestions;

      state = state.copyWith(
        suggestionsPerDay: updatedSuggestions,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );

      debugPrint('[AIAdvisor] ${suggestions.length} AI-Vorschlaege fuer Tag $day erhalten');
    } catch (e) {
      debugPrint('[AIAdvisor] AI-Vorschlaege fehlgeschlagen: $e');

      // Fallback auf regelbasierte Vorschlaege
      final fallbackSuggestions = <AISuggestion>[];
      final dayWeather = _getDayWeather(day, trip.actualDays, routeWeather);
      final stopsForDay = trip.getStopsForDay(day);

      if (dayWeather == WeatherCondition.bad ||
          dayWeather == WeatherCondition.danger) {
        final outdoorStops = stopsForDay
            .where((s) => s.category != null && !_isIndoor(s.category!))
            .toList();

        for (final stop in outdoorStops) {
          fallbackSuggestions.add(AISuggestion(
            message:
                '${stop.name} ist eine Outdoor-Aktivitaet. Ersetze diesen Stop fuer eine Indoor-Alternative.',
            type: SuggestionType.alternative,
            targetPOIId: stop.poiId,
            weather: dayWeather,
            actionType: 'swap',
          ));
        }
      }

      final updatedSuggestions =
          Map<int, List<AISuggestion>>.from(state.suggestionsPerDay);
      updatedSuggestions[day] = fallbackSuggestions;

      state = state.copyWith(
        suggestionsPerDay: updatedSuggestions,
        isLoading: false,
        error: 'AI nicht erreichbar - zeige lokale Vorschlaege',
        lastUpdated: DateTime.now(),
      );
    }
  }

  /// Laedt POI-Empfehlungen entlang des Korridors und rankt sie via GPT-4o.
  /// Beruecksichtigt Wetter (Indoor bei Regen), Must-See-Attraktionen und Umgebung.
  /// 1. CorridorBrowserProvider: POIs im Korridor laden (alle Kategorien)
  /// 2. Smart-Filter: Wetter-Gewichtung + Must-See-Bonus + Score
  /// 3. GPT-4o Ranking mit Kontext (Wetter, aktuelle Stops, Umgebung)
  /// 4. Fallback: Regelbasiertes Ranking bei GPT-Fehler
  Future<void> loadSmartRecommendations({
    required int day,
    required Trip trip,
    required AppRoute route,
    required RouteWeatherState routeWeather,
    required Set<String> existingStopIds,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    final dayWeather = _getDayWeather(day, trip.actualDays, routeWeather);
    final isBadWeather = dayWeather == WeatherCondition.bad ||
        dayWeather == WeatherCondition.danger;
    debugPrint('[AIAdvisor] Lade Empfehlungen fuer Tag $day (Wetter: ${dayWeather.label})...');

    try {
      // 1. Corridor-POIs laden (alle Kategorien, 50km Buffer)
      final corridorNotifier =
          ref.read(corridorBrowserNotifierProvider.notifier);
      await corridorNotifier.loadCorridorPOIs(
        route: route,
        bufferKm: 50.0,
        existingStopIds: existingStopIds,
      );

      final corridorState = ref.read(corridorBrowserNotifierProvider);

      // 2. Smart-Filter: Alle POIs mit Mindest-Qualitaet, nicht im Trip
      final allCandidates = corridorState.corridorPOIs
          .where((poi) => !existingStopIds.contains(poi.id))
          .where((poi) => poi.score > 30)
          .toList();

      if (allCandidates.isEmpty) {
        debugPrint('[AIAdvisor] Keine Kandidaten im Korridor gefunden');
        state = state.copyWith(
          isLoading: false,
          error: 'Keine Empfehlungen entlang der Route gefunden',
        );
        return;
      }

      // 3. Wetter-gewichtete Sortierung: Must-See + Indoor-Bonus bei Regen
      allCandidates.sort((a, b) {
        final aScore = _calculateSmartScore(a, isBadWeather);
        final bScore = _calculateSmartScore(b, isBadWeather);
        return bScore.compareTo(aScore);
      });

      final topCandidates = allCandidates.take(15).toList();

      debugPrint(
          '[AIAdvisor] ${topCandidates.length} Kandidaten ausgewaehlt (${allCandidates.length} gesamt, isBadWeather: $isBadWeather)');

      // 4. GPT-4o Ranking versuchen
      List<AISuggestion> rankedSuggestions;
      try {
        rankedSuggestions = await _rankWithGPT(
          day: day,
          trip: trip,
          candidates: topCandidates,
          routeWeather: routeWeather,
        );
        debugPrint(
            '[AIAdvisor] GPT-Ranking: ${rankedSuggestions.length} Empfehlungen');
      } catch (e) {
        // 5. Fallback: Regelbasiertes Ranking
        debugPrint('[AIAdvisor] GPT-Ranking fehlgeschlagen: $e');
        rankedSuggestions = _rankRuleBased(
          day: day,
          totalDays: trip.actualDays,
          candidates: topCandidates,
          routeWeather: routeWeather,
        );
        state = state.copyWith(
          error: 'AI nicht erreichbar - zeige lokale Empfehlungen',
        );
      }

      // State aktualisieren
      final updatedSuggestions =
          Map<int, List<AISuggestion>>.from(state.suggestionsPerDay);
      updatedSuggestions[day] = rankedSuggestions;

      final updatedPOIs =
          Map<int, List<POI>>.from(state.recommendedPOIsPerDay);
      updatedPOIs[day] = rankedSuggestions
          .where((s) => s.alternativePOI != null)
          .map((s) => s.alternativePOI!)
          .toList();

      state = state.copyWith(
        suggestionsPerDay: updatedSuggestions,
        recommendedPOIsPerDay: updatedPOIs,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      debugPrint('[AIAdvisor] Fehler beim Laden der Empfehlungen: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Fehler beim Laden der Empfehlungen',
      );
    }
  }

  /// Berechnet einen gewichteten Score fuer POI-Kandidaten
  double _calculateSmartScore(POI poi, bool isBadWeather) {
    double score = poi.score.toDouble();

    // Must-See Bonus (+30)
    if (poi.isMustSee) score += 30;

    // Wetter-Bonus: Bei schlechtem Wetter Indoor bevorzugen (+20)
    if (isBadWeather && poi.category?.isWeatherResilient == true) {
      score += 20;
    }

    // Umweg-Penalty: Weiter entfernte POIs abwerten
    if (poi.detourKm != null) {
      score -= poi.detourKm! * 0.5;
    }

    return score;
  }

  /// GPT-4o Ranking der Kandidaten-POIs
  Future<List<AISuggestion>> _rankWithGPT({
    required int day,
    required Trip trip,
    required List<POI> candidates,
    required RouteWeatherState routeWeather,
  }) async {
    final aiService = ref.read(aiServiceProvider);
    final stopsForDay = trip.getStopsForDay(day);
    final dayWeather =
        _getDayWeather(day, trip.actualDays, routeWeather);

    // Wetter-Info
    final dayWeatherStrings = routeWeather.hasForecast
        ? routeWeather.getForecastPerDayAsStrings(trip.actualDays)
        : routeWeather.getWeatherPerDayAsStrings(trip.actualDays);
    final weatherInfo = dayWeatherStrings[day] ?? dayWeather.label;

    // Aktuelle Stops als Text
    final currentStopsText = stopsForDay
        .map((s) =>
            '${s.name} (${s.categoryId}, ${_isIndoor(s.category!) ? "indoor" : "outdoor"})')
        .join(', ');

    // Kandidaten als Text (mit Must-See Markierung)
    final candidatesText = candidates
        .map((p) {
          final mustSee = p.isMustSee ? ', MUST-SEE' : '';
          final indoor = p.category?.isWeatherResilient == true ? ', indoor' : ', outdoor';
          return '${p.name} (${p.categoryId}$indoor$mustSee, ${p.detourKm?.toStringAsFixed(1) ?? "?"}km Umweg, Score: ${p.score})';
        })
        .join(', ');

    // Outdoor-Stops identifizieren (fuer Swap-Vorschlaege bei schlechtem Wetter)
    final outdoorStops = stopsForDay
        .where((s) => s.category != null && !_isIndoor(s.category!))
        .toList();

    final isBadWeather = dayWeather == WeatherCondition.bad ||
        dayWeather == WeatherCondition.danger;

    final prompt = 'Wetter Tag $day: $weatherInfo\n'
        'Aktuelle Stops: $currentStopsText\n'
        '${isBadWeather ? 'Outdoor-Stops die ersetzt werden koennten: ${outdoorStops.map((s) => '${s.name} (${s.poiId})').join(', ')}\n' : ''}'
        'Kandidaten-POIs entlang der Route: $candidatesText\n\n'
        'Aufgabe: Waehle die besten 5 POIs als Empfehlungen fuer diesen Reisetag.\n'
        'Beruecksichtige: Wetter (Indoor bei Regen bevorzugen), Must-See-Attraktionen, Kategorie-Vielfalt, Umweg.\n'
        '${isBadWeather ? 'Bei schlechtem Wetter: Schlage Indoor-Alternativen vor und nutze "swap" um Outdoor-Stops zu ersetzen.\n' : 'Bei gutem Wetter: Empfehle die besten POIs zum Hinzufuegen.\n'}'
        'Antworte als JSON Array:\n'
        '[{"name": "...", "action": "add|swap", "targetPOIId": "...", "reasoning": "1 Satz", "score": 0.0-1.0}]';

    final response = await aiService.chat(
      message: prompt,
      context: TripContext(route: trip.route, stops: candidates),
    );

    // JSON aus der Response extrahieren
    return _parseGPTResponse(
      response: response,
      candidates: candidates,
      dayWeather: dayWeather,
    );
  }

  /// Parsed die GPT-Response und erstellt AISuggestion-Objekte
  List<AISuggestion> _parseGPTResponse({
    required String response,
    required List<POI> candidates,
    required WeatherCondition dayWeather,
  }) {
    try {
      // JSON-Array aus Response extrahieren
      final jsonStart = response.indexOf('[');
      final jsonEnd = response.lastIndexOf(']');
      if (jsonStart == -1 || jsonEnd == -1) {
        throw const FormatException('Kein JSON-Array in Response');
      }

      final jsonStr = response.substring(jsonStart, jsonEnd + 1);
      final List<dynamic> parsed =
          List<dynamic>.from(jsonDecode(jsonStr) as List);

      final suggestions = <AISuggestion>[];
      for (final item in parsed.take(5)) {
        final map = item as Map<String, dynamic>;
        final name = map['name'] as String? ?? '';
        final action = map['action'] as String? ?? 'add';
        final reasoning = map['reasoning'] as String? ?? '';
        final score = (map['score'] as num?)?.toDouble() ?? 0.5;
        final targetPOIId = map['targetPOIId'] as String?;

        // Kandidaten-POI anhand des Namens finden
        final matchedPOI = candidates.firstWhere(
          (p) => p.name.toLowerCase().contains(name.toLowerCase()) ||
              name.toLowerCase().contains(p.name.toLowerCase()),
          orElse: () => candidates.first,
        );

        suggestions.add(AISuggestion(
          message: '${matchedPOI.name} - ${matchedPOI.category?.label ?? matchedPOI.categoryId}',
          type: SuggestionType.alternative,
          alternativePOI: matchedPOI,
          weather: dayWeather,
          actionType: action,
          targetPOIId: action == 'swap' ? targetPOIId : null,
          aiReasoning: reasoning,
          relevanceScore: score,
        ));
      }

      // Nach Relevanz sortieren
      suggestions.sort((a, b) =>
          (b.relevanceScore ?? 0).compareTo(a.relevanceScore ?? 0));

      return suggestions;
    } catch (e) {
      debugPrint('[AIAdvisor] GPT-Response-Parsing fehlgeschlagen: $e');
      rethrow;
    }
  }

  /// Regelbasiertes Fallback-Ranking (ohne GPT)
  /// Beruecksichtigt Must-See, Wetter-Resilience und Umweg
  List<AISuggestion> _rankRuleBased({
    required int day,
    required int totalDays,
    required List<POI> candidates,
    required RouteWeatherState routeWeather,
  }) {
    final dayWeather = _getDayWeather(day, totalDays, routeWeather);
    final isBadWeather = dayWeather == WeatherCondition.bad ||
        dayWeather == WeatherCondition.danger;

    // Sortiere nach gewichtetem Smart-Score
    final sorted = List<POI>.from(candidates)
      ..sort((a, b) {
        final aScore = _calculateSmartScore(a, isBadWeather);
        final bScore = _calculateSmartScore(b, isBadWeather);
        return bScore.compareTo(aScore);
      });

    return sorted.take(5).map((poi) {
      final detourText = poi.detourKm != null
          ? ' (${poi.detourKm!.toStringAsFixed(1)} km Umweg)'
          : '';
      final mustSeeText = poi.isMustSee ? 'Must-See ' : '';
      final weatherText = isBadWeather && poi.category?.isWeatherResilient == true
          ? 'Indoor-Empfehlung'
          : 'Empfehlung';
      return AISuggestion(
        message:
            '${poi.name} - ${poi.category?.label ?? poi.categoryId}',
        type: SuggestionType.alternative,
        alternativePOI: poi,
        weather: dayWeather,
        actionType: 'add',
        aiReasoning: '$mustSeeText$weatherText entlang der Route$detourText',
        relevanceScore: _calculateSmartScore(poi, isBadWeather) / 130.0,
      );
    }).toList();
  }

  /// Zuruecksetzen
  void reset() {
    state = const AITripAdvisorState();
  }
}
