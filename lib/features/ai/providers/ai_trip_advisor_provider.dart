import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:travel_planner/l10n/app_localizations.dart';
import '../../../core/constants/categories.dart';
import '../../../core/l10n/service_l10n.dart';
import '../../../core/utils/geo_utils.dart';
import '../../../data/models/poi.dart';
import '../../../data/models/trip.dart';
import '../../../data/models/route.dart';
import '../../../data/providers/settings_provider.dart';
import '../../../data/repositories/poi_repo.dart';
import '../../../data/repositories/poi_social_repo.dart';
import '../../../data/services/ai_service.dart';
import '../../../data/services/poi_enrichment_service.dart';
import '../../map/providers/weather_provider.dart';

part 'ai_trip_advisor_provider.g.dart';

/// Vorschlags-Typ
enum SuggestionType { weather, optimization, alternative, general }

/// Kandidat-POI mit Zuordnung zum naechsten Stop
class _StopCandidate {
  final POI poi;
  final String nearestStop;
  final double distanceKm;

  const _StopCandidate({
    required this.poi,
    required this.nearestStop,
    required this.distanceKm,
  });
}

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
  final List<String> highlights;
  final String? longDescription;
  final List<String> photoUrls;

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
    this.highlights = const [],
    this.longDescription,
    this.photoUrls = const [],
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

/// AI Trip Advisor - generiert Vorschlaege basierend auf Wetter + Route.
/// keepAlive: Empfehlungen bleiben bei Tageswechsel und Screen-Wechsel erhalten.
/// reset() wird bei neuem Trip oder manuell aufgerufen.
@Riverpod(keepAlive: true)
class AITripAdvisorNotifier extends _$AITripAdvisorNotifier {
  /// Request-ID fuer Cancellation: Nur die neueste Anfrage darf State setzen
  int _loadRequestId = 0;

  /// Gibt die aktuelle AppLocalizations basierend auf der eingestellten Sprache zurueck
  AppLocalizations get _l10n {
    final settings = ref.read(settingsNotifierProvider);
    return ServiceL10n.fromLanguageCode(settings.language);
  }

  @override
  AITripAdvisorState build() => const AITripAdvisorState();

  /// Analysiert den Trip und generiert lokale Wetter-Vorschlaege
  /// (Ohne AI-Backend, rein regelbasiert)
  void analyzeTrip(Trip trip, RouteWeatherState routeWeather) {
    if (routeWeather.weatherPoints.isEmpty) return;

    final l10n = _l10n;
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
            .where((s) => s.category != null && !s.category!.isIndoor)
            .toList();

        if (outdoorStops.isNotEmpty) {
          final isDanger = dayWeather == WeatherCondition.danger;
          daySuggestions.add(AISuggestion(
            message: isDanger
                ? l10n.advisorDangerWeather(day, outdoorStops.length)
                : l10n.advisorBadWeather(
                    day, outdoorStops.length, stopsForDay.length),
            type: SuggestionType.weather,
            weather: dayWeather,
          ));

          // Einzelne Outdoor-POIs markieren
          for (final stop in outdoorStops) {
            daySuggestions.add(AISuggestion(
              message: l10n.advisorOutdoorAlternative(stop.name),
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

    final dayPosition = totalDays > 1 ? (day - 1) / (totalDays - 1) : 0.5;

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

  // _isIndoor entfernt - nutzt jetzt POICategory.isIndoor aus categories.dart

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
        if (targetDay != day)
          continue; // Nur Vorschlaege fuer den gewaehlten Tag

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

      debugPrint(
          '[AIAdvisor] ${suggestions.length} AI-Vorschlaege fuer Tag $day erhalten');
    } catch (e) {
      debugPrint('[AIAdvisor] AI-Vorschlaege fehlgeschlagen: $e');

      // Fallback auf regelbasierte Vorschlaege
      final l10n = _l10n;
      final fallbackSuggestions = <AISuggestion>[];
      final dayWeather = _getDayWeather(day, trip.actualDays, routeWeather);
      final stopsForDay = trip.getStopsForDay(day);

      if (dayWeather == WeatherCondition.bad ||
          dayWeather == WeatherCondition.danger) {
        final outdoorStops = stopsForDay
            .where((s) => s.category != null && !s.category!.isIndoor)
            .toList();

        for (final stop in outdoorStops) {
          fallbackSuggestions.add(AISuggestion(
            message: l10n.advisorOutdoorReplace(stop.name),
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
        error: l10n.advisorAiUnavailableSuggestions,
        lastUpdated: DateTime.now(),
      );
    }
  }

  /// Laedt Must-See POI-Empfehlungen im 15km Umkreis (max 3 Suchpunkte) via GPT-4o.
  /// Nur Supabase + kuratierte POIs (kein Wikipedia/Overpass → kein Crash).
  /// Nur beruemhte POIs (Score >= 50, Must-See/UNESCO bevorzugt).
  /// 1. Radius-Suche: Max 3 Punkte (Start, Mitte, Ende), nur Supabase+kuratiert
  /// 2. Merge + Filter: Nur Score >= 50, keine Hotels/Restaurants
  /// 3. Smart-Scoring: Must-See+40, UNESCO+20, kuratiert+15, Wetter, Naehe
  /// 4. GPT-4o: Top 8 Kandidaten → 3 Must-See Empfehlungen
  /// 5. Fallback: Regelbasiertes Ranking bei GPT-Fehler
  Future<void> loadSmartRecommendations({
    required int day,
    required Trip trip,
    required AppRoute route,
    required RouteWeatherState routeWeather,
    required Set<String> existingStopIds,
  }) async {
    // Request-ID fuer Cancellation: Alte laufende Requests werden ignoriert.
    // Kein isLoading-Guard: Neue Anfrage cancelled automatisch alte via requestId.
    // So kann ein manueller Klick einen Auto-Trigger sauber ersetzen.
    final requestId = ++_loadRequestId;
    state = state.copyWith(isLoading: true, error: null);
    final dayWeather = _getDayWeather(day, trip.actualDays, routeWeather);
    final isBadWeather = dayWeather == WeatherCondition.bad ||
        dayWeather == WeatherCondition.danger;
    debugPrint(
        '[AIAdvisor] Lade Empfehlungen fuer Tag $day (Wetter: ${dayWeather.label})...');

    final l10n = _l10n;

    try {
      // 1. Suchpunkte aufbauen: Route-Anker + Stops + Tagesziel
      // (Tagesstart bewusst nicht als Primär-Suchpunkt, um Start-Bias zu vermeiden).
      final stopsForDay = trip.getStopsForDay(day);
      final dayRoute = _extractDayRoute(day, trip, route);
      final searchLocations = _buildSearchLocations(
        day: day,
        trip: trip,
        route: route,
        stopsForDay: stopsForDay,
        dayRoute: dayRoute,
      );
      debugPrint(
          '[AIAdvisor] Suche Must-See POIs im 15km Umkreis von ${searchLocations.length} route-fokussierten Punkten...');

      if (searchLocations.isEmpty) {
        debugPrint('[AIAdvisor] Keine Suchpunkte fuer Tag $day');
        if (requestId == _loadRequestId) {
          state = state.copyWith(
            isLoading: false,
            error: l10n.advisorNoRecommendationsFound,
          );
        }
        return;
      }

      // 2. Parallele Radius-Suche (15km, max 3 Punkte, nur Supabase+kuratiert)
      final poiRepo = ref.read(poiRepositoryProvider);
      final searchResults =
          await _searchPOIsAroundStops(poiRepo, searchLocations);

      // Cancellation-Check
      if (requestId != _loadRequestId) {
        debugPrint(
            '[AIAdvisor] Request $requestId abgebrochen (neuer Request aktiv)');
        return;
      }

      // 3. Merge, Deduplizieren, Filtern
      var allCandidates = _mergeAndDeduplicate(searchResults, existingStopIds);
      debugPrint(
          '[AIAdvisor] ${allCandidates.length} einzigartige Kandidaten nach Deduplizierung');

      // 4. Route-Metriken berechnen (detourKm, routePosition)
      if (dayRoute.coordinates.length >= 2) {
        allCandidates = _enrichWithRouteMetrics(allCandidates, dayRoute);
        allCandidates =
            _filterForRouteAndDestinationFocus(allCandidates, dayRoute);
      }

      // Kandidaten-Limit: Max 25 vor Smart-Scoring (nur die besten)
      if (allCandidates.length > 25) {
        allCandidates.sort((a, b) {
          final aScore = _calculateSmartScore(a.poi, isBadWeather,
              distanceKm: a.distanceKm);
          final bScore = _calculateSmartScore(b.poi, isBadWeather,
              distanceKm: b.distanceKm);
          return bScore.compareTo(aScore);
        });
        allCandidates = allCandidates.take(25).toList();
        debugPrint(
            '[AIAdvisor] Kandidaten limitiert: -> 25 fuer Smart-Scoring');
      }

      if (allCandidates.isEmpty) {
        debugPrint(
            '[AIAdvisor] Keine Kandidaten in der Naehe der Stops gefunden');
        if (requestId == _loadRequestId) {
          state = state.copyWith(
            isLoading: false,
            error: l10n.advisorNoRecommendationsFound,
          );
        }
        return;
      }

      // 5. Wetter-gewichtete Sortierung: Must-See + Indoor-Bonus + Naehe-Bonus
      allCandidates.sort((a, b) {
        final aScore =
            _calculateSmartScore(a.poi, isBadWeather, distanceKm: a.distanceKm);
        final bScore =
            _calculateSmartScore(b.poi, isBadWeather, distanceKm: b.distanceKm);
        return bScore.compareTo(aScore);
      });

      final topCandidates = allCandidates.take(8).toList();

      debugPrint(
          '[AIAdvisor] ${topCandidates.length} Must-See Kandidaten ausgewaehlt (${allCandidates.length} gesamt, isBadWeather: $isBadWeather)');

      // Cancellation-Check vor GPT-Call
      if (requestId != _loadRequestId) {
        debugPrint(
            '[AIAdvisor] Request $requestId abgebrochen (neuer Request aktiv)');
        return;
      }

      // 6. GPT-4o Ranking versuchen (mit Stop-Zuordnung)
      List<AISuggestion> rankedSuggestions;
      try {
        rankedSuggestions = await _rankWithGPT(
          day: day,
          trip: trip,
          candidates: topCandidates,
          routeWeather: routeWeather,
        ).timeout(const Duration(seconds: 15));
        debugPrint(
            '[AIAdvisor] GPT-Ranking: ${rankedSuggestions.length} Empfehlungen');
      } catch (e) {
        // 7. Fallback: Regelbasiertes Ranking (bei Timeout oder GPT-Fehler)
        debugPrint('[AIAdvisor] GPT-Ranking fehlgeschlagen: $e');
        rankedSuggestions = _rankRuleBased(
          day: day,
          totalDays: trip.actualDays,
          candidates: topCandidates,
          routeWeather: routeWeather,
        );
        if (requestId == _loadRequestId) {
          state = state.copyWith(
            error: l10n.advisorAiUnavailableRecommendations,
          );
        }
      }

      // 7. Medien-/Text-Enrichment fuer die besten Vorschlaege.
      rankedSuggestions = await _enrichSuggestionsWithMedia(rankedSuggestions);

      // Cancellation-Check vor State-Update
      if (requestId != _loadRequestId) {
        debugPrint(
            '[AIAdvisor] Request $requestId abgebrochen (neuer Request aktiv)');
        return;
      }

      // State aktualisieren
      final updatedSuggestions =
          Map<int, List<AISuggestion>>.from(state.suggestionsPerDay);
      updatedSuggestions[day] = rankedSuggestions;

      final updatedPOIs = Map<int, List<POI>>.from(state.recommendedPOIsPerDay);
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
      if (requestId == _loadRequestId) {
        state = state.copyWith(
          isLoading: false,
          error: l10n.advisorErrorLoadingRecommendations,
        );
      }
    } finally {
      // Sicherheitsnetz: isLoading IMMER zuruecksetzen wenn dieser Request
      // der aktuelle ist (verhindert permanent haengenden Loading-State)
      if (requestId == _loadRequestId && state.isLoading) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  // ─── Helper-Methoden fuer Stop-Radius-Suche ───

  /// Bestimmt den Startpunkt eines Tages
  /// Tag 1: Route-Start, ab Tag 2: letzter Stop vom Vortag
  LatLng _getDayStartLocation(int day, Trip trip, AppRoute route) {
    if (day == 1) return route.start;
    final prevStops = trip.getStopsForDay(day - 1);
    if (prevStops.isNotEmpty) return prevStops.last.location;
    return route.start;
  }

  /// Baut route-zentrierte Suchpunkte:
  /// - Route-Anker in der zweiten Routenhaelfte
  /// - Stops des Tages (ausser Start-nahe)
  /// - Tagesziel (immer)
  /// Tagesstart wird bewusst nicht als Suchpunkt verwendet.
  List<({LatLng location, String label})> _buildSearchLocations({
    required int day,
    required Trip trip,
    required AppRoute route,
    required List<TripStop> stopsForDay,
    required AppRoute dayRoute,
  }) {
    final locations = <({LatLng location, String label})>[];
    final dayStart = _getDayStartLocation(day, trip, route);
    final dayEnd = trip.getDayEndLocation(day);
    final approxRouteKm = GeoUtils.calculateRouteLength(dayRoute.coordinates);
    final startExclusionKm = (approxRouteKm * 0.2).clamp(8.0, 30.0);

    // Route-Anker: Fokus auf Route-Mitte bis Ziel.
    final anchors =
        _buildRouteAnchors(dayRoute, const [0.55, 0.72, 0.86, 0.95]);
    for (final anchor in anchors) {
      final distToStart = GeoUtils.haversineDistance(dayStart, anchor);
      if (distToStart >= startExclusionKm) {
        locations.add((location: anchor, label: 'Route'));
      }
    }

    // Stops im selben Start-Ausschlussbereich filtern.
    for (final stop in stopsForDay) {
      final distToStart = GeoUtils.haversineDistance(dayStart, stop.location);
      if (distToStart >= startExclusionKm) {
        locations.add((location: stop.location, label: stop.name));
      }
    }

    // Tagesziel immer explizit einbeziehen.
    locations.add((location: dayEnd, label: 'Ziel'));

    // Deduplizieren (gerundet), Reihenfolge beibehalten.
    final deduped = <({LatLng location, String label})>[];
    final seen = <String>{};
    for (final entry in locations) {
      final key =
          '${entry.location.latitude.toStringAsFixed(4)}:${entry.location.longitude.toStringAsFixed(4)}';
      if (seen.add(key)) {
        deduped.add(entry);
      }
    }

    return deduped;
  }

  List<LatLng> _buildRouteAnchors(
    AppRoute route,
    List<double> progressPoints,
  ) {
    if (route.coordinates.length < 2) return const [];
    final anchors = <LatLng>[];
    for (final progress in progressPoints) {
      final p = progress.clamp(0.0, 1.0);
      final idx = (p * (route.coordinates.length - 1)).round();
      anchors.add(route.coordinates[idx]);
    }
    return anchors;
  }

  /// Fuehrt parallele Radius-Suchen (15km) um max 3 Suchpunkte durch.
  /// Verwendet NUR Supabase + kuratierte POIs (kein Wikipedia/Overpass-Fallback)
  /// um Crashes durch zu viele API-Calls zu vermeiden.
  Future<
      List<
          ({
            ({LatLng location, String label}) searchLocation,
            List<POI> pois
          })>> _searchPOIsAroundStops(
    POIRepository poiRepo,
    List<({LatLng location, String label})> searchLocations,
  ) async {
    const searchRadiusKm = 15.0;

    // Max 4 Suchpunkte: route-zentrierte Punkte plus Zielbereich.
    final limitedLocations = _limitSearchLocations(searchLocations, 4);
    debugPrint(
        '[AIAdvisor] ${limitedLocations.length} von ${searchLocations.length} Suchpunkten verwendet');

    final searchFutures = limitedLocations.map((loc) async {
      try {
        final pois = await poiRepo
            .loadPOIsInRadius(
              center: loc.location,
              radiusKm: searchRadiusKm,
              useCache: true,
              // NUR Supabase + kuratierte POIs - kein Wikipedia-Grid/Overpass
              // verhindert 100+ parallele API-Calls die zum Crash fuehren
              includeWikipedia: false,
              includeOverpass: false,
            )
            .timeout(const Duration(seconds: 8));
        debugPrint('[AIAdvisor] ${pois.length} POIs gefunden bei ${loc.label}');
        return (searchLocation: loc, pois: pois);
      } catch (e) {
        debugPrint(
            '[AIAdvisor] Radius-Suche fehlgeschlagen fuer ${loc.label}: $e');
        return (searchLocation: loc, pois: <POI>[]);
      }
    });

    return Future.wait(searchFutures);
  }

  /// Begrenzt Suchpunkte auf maxCount, priorisiert Zielbereich und Route.
  List<({LatLng location, String label})> _limitSearchLocations(
    List<({LatLng location, String label})> locations,
    int maxCount,
  ) {
    if (locations.length <= maxCount) return locations;

    final prioritized = <({LatLng location, String label})>[
      ...locations.where((l) => l.label == 'Ziel'),
      ...locations.where((l) => l.label == 'Route'),
      ...locations.where((l) => l.label != 'Ziel' && l.label != 'Route'),
    ];

    return prioritized.take(maxCount).toList();
  }

  /// Zusammenfuehren, Deduplizieren und Filtern der Radius-Ergebnisse
  /// NUR beruemhte/Must-See POIs behalten:
  /// - Hotels und Restaurants werden ausgeschlossen
  /// - Bereits vorhandene Stops werden ausgeschlossen
  /// - Nur POIs mit Score >= 50 (bekannte Sehenswuerdigkeiten)
  /// - Bevorzugt Must-See, UNESCO, kuratierte POIs
  /// - Bei Duplikaten: kuerzeste Distanz und zugehoeriger Stop bleiben
  List<_StopCandidate> _mergeAndDeduplicate(
    List<({({LatLng location, String label}) searchLocation, List<POI> pois})>
        searchResults,
    Set<String> existingStopIds,
  ) {
    final candidateMap = <String, _StopCandidate>{};

    for (final result in searchResults) {
      for (final poi in result.pois) {
        // Filter: Hotels, Restaurants, existierende Stops
        if (existingStopIds.contains(poi.id)) continue;
        if (poi.categoryId == 'hotel') continue;
        if (poi.categoryId == 'restaurant') continue;

        // NUR beruemhte POIs: Score >= 50 (bekannte Sehenswuerdigkeiten)
        if (poi.score < 50) continue;

        final distToSearchPoint = GeoUtils.haversineDistance(
          poi.location,
          result.searchLocation.location,
        );

        // Deduplizierung: Kuerzeste Distanz gewinnt
        if (!candidateMap.containsKey(poi.id) ||
            distToSearchPoint < candidateMap[poi.id]!.distanceKm) {
          candidateMap[poi.id] = _StopCandidate(
            poi: poi,
            nearestStop: result.searchLocation.label,
            distanceKm: distToSearchPoint,
          );
        }
      }
    }

    return candidateMap.values.toList();
  }

  /// Berechnet Route-Metriken (detourKm, routePosition) fuer Kandidaten
  List<_StopCandidate> _enrichWithRouteMetrics(
    List<_StopCandidate> candidates,
    AppRoute dayRoute,
  ) {
    return candidates.map((entry) {
      final routePos = GeoUtils.calculateRoutePosition(
        entry.poi.location,
        dayRoute.coordinates,
      );
      final detour = GeoUtils.calculateDetour(
        entry.poi.location,
        dayRoute.coordinates,
      );
      return _StopCandidate(
        poi: entry.poi.copyWith(
          routePosition: routePos,
          detourKm: detour,
        ),
        nearestStop: entry.nearestStop,
        distanceKm: entry.distanceKm,
      );
    }).toList();
  }

  // ─── Bestehende Helper-Methoden ───

  /// Extrahiert das Route-Segment fuer einen bestimmten Tag.
  /// Verhindert dass bei Multi-Day Trips die gesamte Route (tausende km)
  /// fuer Route-Metriken verwendet wird → kleinere Bounding-Box.
  AppRoute _extractDayRoute(int day, Trip trip, AppRoute fullRoute) {
    if (trip.actualDays <= 1) return fullRoute;

    final stopsForDay = trip.getStopsForDay(day);
    if (stopsForDay.isEmpty) return fullRoute;

    // Tages-Start bestimmen
    LatLng dayStart;
    if (day == 1) {
      dayStart = fullRoute.start;
    } else {
      final prevStops = trip.getStopsForDay(day - 1);
      dayStart =
          prevStops.isNotEmpty ? prevStops.last.location : fullRoute.start;
    }

    // Tages-Ende bestimmen
    LatLng dayEnd;
    if (day == trip.actualDays) {
      dayEnd = fullRoute.end;
    } else {
      dayEnd = stopsForDay.last.location;
    }

    // Naechste Punkte auf der Route finden
    final coords = fullRoute.coordinates;
    if (coords.length < 2) return fullRoute;

    int startIdx = 0;
    int endIdx = coords.length - 1;
    double minStartDist = double.infinity;
    double minEndDist = double.infinity;

    for (int i = 0; i < coords.length; i++) {
      final dStart = _sqDist(coords[i], dayStart);
      final dEnd = _sqDist(coords[i], dayEnd);
      if (dStart < minStartDist) {
        minStartDist = dStart;
        startIdx = i;
      }
      if (dEnd < minEndDist) {
        minEndDist = dEnd;
        endIdx = i;
      }
    }

    // Sicherstellen dass Start vor Ende liegt
    if (startIdx > endIdx) {
      final tmp = startIdx;
      startIdx = endIdx;
      endIdx = tmp;
    }

    final segCoords = coords.sublist(startIdx, endIdx + 1);
    if (segCoords.length < 2) return fullRoute;

    debugPrint('[AIAdvisor] Tag $day Route-Segment: '
        'Index $startIdx-$endIdx von ${coords.length}');

    return AppRoute(
      start: segCoords.first,
      end: segCoords.last,
      startAddress: '',
      endAddress: '',
      coordinates: segCoords,
      distanceKm: 0,
      durationMinutes: 0,
    );
  }

  /// Schnelle Quadrat-Distanz fuer Punkt-Vergleich (ohne sqrt)
  double _sqDist(LatLng a, LatLng b) {
    final dLat = a.latitude - b.latitude;
    final dLng = a.longitude - b.longitude;
    return dLat * dLat + dLng * dLng;
  }

  /// Berechnet einen gewichteten Score fuer POI-Kandidaten.
  /// Stark gewichtet auf Bekanntheit: Must-See und kuratierte POIs bevorzugt.
  double _calculateSmartScore(POI poi, bool isBadWeather,
      {double? distanceKm}) {
    double score = poi.score.toDouble();

    // Must-See Bonus (+40) - staerker gewichtet fuer beruemhte POIs
    if (poi.isMustSee) score += 40;

    // Kuratierte POIs Bonus (+15) - handverlesene Highlights
    if (poi.isCurated) score += 15;

    // UNESCO Bonus (+20)
    if (poi.isUnesco) score += 20;

    // Wetter-Bonus: Bei schlechtem Wetter Indoor bevorzugen (+20)
    if (isBadWeather && poi.category?.isWeatherResilient == true) {
      score += 20;
    }

    // Umweg-Penalty: Weiter entfernte POIs abwerten
    if (poi.detourKm != null) {
      score -= poi.detourKm! * 0.5;
    }

    // Route-Progress-Bonus: Zielbereich bevorzugen, Startbereich abwerten.
    final routePos = poi.routePosition;
    if (routePos != null) {
      if (routePos >= 0.85) {
        score += 24;
      } else if (routePos >= 0.65) {
        score += 14;
      } else if (routePos >= 0.45) {
        score += 6;
      } else if (routePos < 0.2) {
        score -= 24;
      }
    }

    // Naehe-Bonus: POIs nahe an Stops bevorzugen
    if (distanceKm != null) {
      if (distanceKm < 5) {
        score += 10;
      } else if (distanceKm < 10) {
        score += 5;
      }
    }

    return score;
  }

  /// GPT-4o Ranking der Kandidaten-POIs mit ortsspezifischem Kontext
  Future<List<AISuggestion>> _rankWithGPT({
    required int day,
    required Trip trip,
    required List<_StopCandidate> candidates,
    required RouteWeatherState routeWeather,
  }) async {
    final aiService = ref.read(aiServiceProvider);
    final dayWeather = _getDayWeather(day, trip.actualDays, routeWeather);
    final settings = ref.read(settingsNotifierProvider);
    final stopsForDay = trip.getStopsForDay(day);

    final request = AIPoiSuggestionRequest(
      mode: AIPoiSuggestionMode.dayEditor,
      language: settings.language,
      userContext: AIPoiSuggestionUserContext(
        weatherCondition: dayWeather,
        selectedDay: day,
        totalDays: trip.actualDays,
      ),
      tripContext: AIPoiSuggestionTripContext(
        routeStart: trip.route.startAddress,
        routeEnd: trip.route.endAddress,
        stops: stopsForDay
            .map(
              (s) => AIPoiSuggestionStop(
                id: s.poiId,
                name: s.name,
                categoryId: s.categoryId,
                day: s.day,
              ),
            )
            .toList(),
      ),
      constraints: AIPoiSuggestionConstraints(
        maxSuggestions: 8,
        allowSwap: true,
      ),
      candidates: candidates
          .map((c) => AIPoiSuggestionCandidate.fromPOI(c.poi))
          .toList(),
    );

    final response = await aiService.getPoiSuggestionsStructured(
      request: request,
    );

    if (response.suggestions.isEmpty) {
      throw const FormatException(
          'Keine strukturierten AI-Suggestions erhalten');
    }

    final byId = {for (final entry in candidates) entry.poi.id: entry};
    final suggestions = <AISuggestion>[];
    final l10n = _l10n;
    for (final structured in response.suggestions.take(8)) {
      final matchedEntry = byId[structured.poiId];
      if (matchedEntry == null) continue;
      final categoryLabel = matchedEntry.poi.category != null
          ? ServiceL10n.localizedCategoryLabel(l10n, matchedEntry.poi.category!)
          : matchedEntry.poi.categoryId;
      suggestions.add(
        AISuggestion(
          message:
              l10n.advisorPoiCategory(matchedEntry.poi.name, categoryLabel),
          type: SuggestionType.alternative,
          alternativePOI: matchedEntry.poi,
          weather: dayWeather,
          actionType: structured.action,
          targetPOIId:
              structured.action == 'swap' ? structured.targetPoiId : null,
          aiReasoning: structured.reason,
          relevanceScore: structured.relevance,
          highlights: structured.highlights,
          longDescription: structured.longDescription,
        ),
      );
    }

    if (suggestions.isEmpty) {
      throw const FormatException(
          'AI-Suggestions konnten keinen Kandidaten zugeordnet werden');
    }

    suggestions.sort(
      (a, b) => (b.relevanceScore ?? 0).compareTo(a.relevanceScore ?? 0),
    );
    return suggestions;
  }

  /// Parsed die GPT-Response und erstellt AISuggestion-Objekte
  List<AISuggestion> _parseGPTResponse({
    required String response,
    required List<_StopCandidate> candidates,
    required WeatherCondition dayWeather,
  }) {
    final l10n = _l10n;
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
      for (final item in parsed.take(3)) {
        final map = item as Map<String, dynamic>;
        final name = map['name'] as String? ?? '';
        final action = map['action'] as String? ?? 'add';
        final reasoning = map['reasoning'] as String? ?? '';
        final score = (map['score'] as num?)?.toDouble() ?? 0.5;
        final targetPOIId = map['targetPOIId'] as String?;

        // Kandidaten-POI anhand des Namens finden
        final matchedEntry = candidates.firstWhere(
          (entry) =>
              entry.poi.name.toLowerCase().contains(name.toLowerCase()) ||
              name.toLowerCase().contains(entry.poi.name.toLowerCase()),
          orElse: () => candidates.first,
        );

        final categoryLabel = matchedEntry.poi.category != null
            ? ServiceL10n.localizedCategoryLabel(
                l10n, matchedEntry.poi.category!)
            : matchedEntry.poi.categoryId;
        suggestions.add(AISuggestion(
          message:
              l10n.advisorPoiCategory(matchedEntry.poi.name, categoryLabel),
          type: SuggestionType.alternative,
          alternativePOI: matchedEntry.poi,
          weather: dayWeather,
          actionType: action,
          targetPOIId: action == 'swap' ? targetPOIId : null,
          aiReasoning: reasoning,
          relevanceScore: score,
        ));
      }

      // Nach Relevanz sortieren
      suggestions.sort(
          (a, b) => (b.relevanceScore ?? 0).compareTo(a.relevanceScore ?? 0));

      return suggestions;
    } catch (e) {
      debugPrint('[AIAdvisor] GPT-Response-Parsing fehlgeschlagen: $e');
      rethrow;
    }
  }

  Future<List<AISuggestion>> _enrichSuggestionsWithMedia(
    List<AISuggestion> suggestions,
  ) async {
    final actionable =
        suggestions.where((s) => s.alternativePOI != null).take(8).toList();
    if (actionable.isEmpty) return suggestions;

    Map<String, POI> enrichedMap = const {};
    try {
      final enrichmentService = ref.read(poiEnrichmentServiceProvider);
      final basePois = actionable.map((s) => s.alternativePOI!).toList();
      enrichedMap = await enrichmentService.enrichPOIsBatch(basePois);
    } catch (e) {
      debugPrint(
          '[AIAdvisor] Enrichment fuer AI-Suggestions fehlgeschlagen: $e');
    }

    final socialRepo = ref.read(poiSocialRepositoryProvider);
    final updated = <AISuggestion>[];
    for (final suggestion in suggestions) {
      final basePoi = suggestion.alternativePOI;
      if (basePoi == null) {
        updated.add(suggestion);
        continue;
      }

      final poi = enrichedMap[basePoi.id] ?? basePoi;
      final photoUrls = <String>{};
      if (poi.imageUrl != null && poi.imageUrl!.isNotEmpty) {
        photoUrls.add(poi.imageUrl!);
      }

      try {
        final photos = await socialRepo.loadPhotos(poi.id, limit: 3);
        for (final photo in photos) {
          final url = getStorageUrl(photo.storagePath);
          if (url.isNotEmpty) photoUrls.add(url);
        }
      } catch (e) {
        debugPrint(
            '[AIAdvisor] Social-Fotos fuer ${poi.id} nicht verfuegbar: $e');
      }

      final autoHighlights = _derivePoiHighlights(poi, suggestion.weather);
      final highlights = suggestion.highlights.isNotEmpty
          ? suggestion.highlights
          : autoHighlights;
      final longDescription = suggestion.longDescription != null &&
              suggestion.longDescription!.trim().isNotEmpty
          ? suggestion.longDescription!
          : (poi.description ??
              poi.wikidataDescription ??
              suggestion.aiReasoning ??
              suggestion.message);

      updated.add(
        AISuggestion(
          message: suggestion.message,
          type: suggestion.type,
          targetPOIId: suggestion.targetPOIId,
          alternativePOI: poi,
          weather: suggestion.weather,
          replacementPOIName: suggestion.replacementPOIName,
          actionType: suggestion.actionType,
          aiReasoning: suggestion.aiReasoning,
          relevanceScore: suggestion.relevanceScore,
          highlights: highlights,
          longDescription: longDescription,
          photoUrls: photoUrls.toList(),
        ),
      );
    }

    return updated;
  }

  List<String> _derivePoiHighlights(POI poi, WeatherCondition? weather) {
    final highlights = <String>[];
    if (poi.isMustSee) highlights.add('Must-See');
    if (poi.isUnesco) highlights.add('UNESCO');
    if (poi.isCurated) highlights.add('Kuratiert');
    if (poi.isHistoric) highlights.add('Historisch');
    if (weather != null &&
        (weather == WeatherCondition.bad ||
            weather == WeatherCondition.danger) &&
        (poi.category?.isWeatherResilient ?? false)) {
      highlights.add('Indoor geeignet');
    }
    return highlights;
  }

  /// Regelbasiertes Fallback-Ranking (ohne GPT)
  /// Beruecksichtigt Must-See, Wetter-Resilience, Umweg und Stop-Naehe
  List<AISuggestion> _rankRuleBased({
    required int day,
    required int totalDays,
    required List<_StopCandidate> candidates,
    required RouteWeatherState routeWeather,
  }) {
    final l10n = _l10n;
    final dayWeather = _getDayWeather(day, totalDays, routeWeather);
    final isBadWeather = dayWeather == WeatherCondition.bad ||
        dayWeather == WeatherCondition.danger;

    // Sortiere nach gewichtetem Smart-Score (mit Naehe-Bonus)
    final sorted = List<_StopCandidate>.from(candidates)
      ..sort((a, b) {
        final aScore =
            _calculateSmartScore(a.poi, isBadWeather, distanceKm: a.distanceKm);
        final bScore =
            _calculateSmartScore(b.poi, isBadWeather, distanceKm: b.distanceKm);
        return bScore.compareTo(aScore);
      });

    return sorted.take(8).map((entry) {
      final poi = entry.poi;
      final detourText = poi.detourKm != null
          ? ' (${poi.detourKm!.toStringAsFixed(1)} km Umweg)'
          : '';
      final mustSeeText = poi.isMustSee ? 'Must-See ' : '';
      final weatherText =
          isBadWeather && poi.category?.isWeatherResilient == true
              ? 'Indoor-Empfehlung'
              : 'Empfehlung';
      final locationText =
          '${entry.distanceKm.toStringAsFixed(1)}km von ${entry.nearestStop}';
      final categoryLabel = poi.category != null
          ? ServiceL10n.localizedCategoryLabel(l10n, poi.category!)
          : poi.categoryId;
      return AISuggestion(
        message: l10n.advisorPoiCategory(poi.name, categoryLabel),
        type: SuggestionType.alternative,
        alternativePOI: poi,
        weather: dayWeather,
        actionType: 'add',
        aiReasoning: '$mustSeeText$weatherText - $locationText$detourText',
        relevanceScore: _calculateSmartScore(poi, isBadWeather,
                distanceKm: entry.distanceKm) /
            140.0,
        highlights: _derivePoiHighlights(poi, dayWeather),
        longDescription: poi.description ??
            poi.wikidataDescription ??
            '$weatherText. $locationText$detourText',
      );
    }).toList();
  }

  /// Entfernt Start-nahe Treffer und priorisiert Kandidaten entlang Route/Ziel.
  List<_StopCandidate> _filterForRouteAndDestinationFocus(
    List<_StopCandidate> candidates,
    AppRoute dayRoute,
  ) {
    if (candidates.isEmpty || dayRoute.coordinates.length < 2)
      return candidates;

    final routeKm = GeoUtils.calculateRouteLength(dayRoute.coordinates);
    final startExclusionKm = (routeKm * 0.18).clamp(6.0, 25.0);
    final start = dayRoute.start;

    final filtered = candidates.where((entry) {
      final pos = entry.poi.routePosition ?? 0.0;
      final distToStart = GeoUtils.haversineDistance(start, entry.poi.location);
      final tooCloseToStart = distToStart < startExclusionKm || pos < 0.2;
      return !tooCloseToStart;
    }).toList();

    // Wenn der Filter zu aggressiv war, leicht lockern.
    if (filtered.length >= 3) return filtered;
    return candidates
        .where((entry) => (entry.poi.routePosition ?? 0.0) >= 0.1)
        .toList();
  }

  /// Zuruecksetzen
  void reset() {
    state = const AITripAdvisorState();
  }
}
