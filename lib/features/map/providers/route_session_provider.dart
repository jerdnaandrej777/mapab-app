import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../data/models/route.dart';
import '../../poi/providers/poi_state_provider.dart';
import 'weather_provider.dart';

part 'route_session_provider.g.dart';

/// State für eine aktive Routen-Session
class RouteSessionState {
  /// Ist die Routen-Session aktiv
  final bool isActive;

  /// Laden POIs und Wetter
  final bool isLoading;

  /// Aktive Route
  final AppRoute? route;

  /// Fehlermeldung
  final String? error;

  /// POIs wurden geladen
  final bool poisLoaded;

  /// Wetter wurde geladen
  final bool weatherLoaded;

  const RouteSessionState({
    this.isActive = false,
    this.isLoading = false,
    this.route,
    this.error,
    this.poisLoaded = false,
    this.weatherLoaded = false,
  });

  RouteSessionState copyWith({
    bool? isActive,
    bool? isLoading,
    AppRoute? route,
    String? error,
    bool? poisLoaded,
    bool? weatherLoaded,
  }) {
    return RouteSessionState(
      isActive: isActive ?? this.isActive,
      isLoading: isLoading ?? this.isLoading,
      route: route ?? this.route,
      error: error,
      poisLoaded: poisLoaded ?? this.poisLoaded,
      weatherLoaded: weatherLoaded ?? this.weatherLoaded,
    );
  }

  /// Ist bereit zum Anzeigen (alles geladen)
  bool get isReady => isActive && poisLoaded && weatherLoaded && !isLoading;

  /// Hat eine Route
  bool get hasRoute => route != null;
}

/// Provider für Routen-Session Management
@Riverpod(keepAlive: true)
class RouteSession extends _$RouteSession {
  @override
  RouteSessionState build() {
    return const RouteSessionState();
  }

  /// Startet eine Routen-Session
  /// Lädt POIs entlang der Route und Wetter-Daten
  Future<void> startRoute(AppRoute route) async {
    debugPrint('[RouteSession] Starte Route: ${route.startAddress} → ${route.endAddress}');

    state = RouteSessionState(
      isActive: true,
      isLoading: true,
      route: route,
      poisLoaded: false,
      weatherLoaded: false,
    );

    try {
      // POIs und Wetter parallel laden
      final results = await Future.wait<bool>([
        _loadPOIs(route),
        _loadWeather(route),
      ], eagerError: false);

      final poisSuccess = results[0];
      final weatherSuccess = results[1];

      state = state.copyWith(
        isLoading: false,
        poisLoaded: poisSuccess,
        weatherLoaded: weatherSuccess,
        error: (!poisSuccess || !weatherSuccess)
            ? 'Einige Daten konnten nicht geladen werden'
            : null,
      );

      debugPrint('[RouteSession] Route gestartet - POIs: $poisSuccess, Wetter: $weatherSuccess');
    } catch (e) {
      debugPrint('[RouteSession] Fehler beim Starten: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Fehler beim Laden der Routen-Daten: $e',
      );
    }
  }

  /// Lädt POIs für die Route
  Future<bool> _loadPOIs(AppRoute route) async {
    try {
      final poiNotifier = ref.read(pOIStateNotifierProvider.notifier);

      // POIs für Route laden
      await poiNotifier.loadPOIsForRoute(route);

      // RouteOnlyMode aktivieren
      poiNotifier.setRouteOnlyMode(true);

      return true;
    } catch (e) {
      debugPrint('[RouteSession] POI-Laden fehlgeschlagen: $e');
      return false;
    }
  }

  /// Lädt Wetter für die Route
  Future<bool> _loadWeather(AppRoute route) async {
    try {
      final weatherNotifier = ref.read(routeWeatherNotifierProvider.notifier);
      await weatherNotifier.loadWeatherForRoute(route.coordinates);
      return true;
    } catch (e) {
      debugPrint('[RouteSession] Wetter-Laden fehlgeschlagen: $e');
      return false;
    }
  }

  /// Stoppt die aktive Routen-Session
  void stopRoute() {
    debugPrint('[RouteSession] Route gestoppt');

    // RouteOnlyMode deaktivieren
    ref.read(pOIStateNotifierProvider.notifier).setRouteOnlyMode(false);

    // Wetter-Daten löschen
    ref.read(routeWeatherNotifierProvider.notifier).clear();

    // State zurücksetzen
    state = const RouteSessionState();
  }

  /// Setzt nur den Fehler zurück
  void clearError() {
    state = state.copyWith(error: null);
  }
}
