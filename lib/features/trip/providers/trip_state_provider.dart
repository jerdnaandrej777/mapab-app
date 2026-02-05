import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/utils/location_helper.dart';
import '../../../data/models/route.dart';
import '../../../data/models/poi.dart';
import '../../../data/repositories/routing_repo.dart';
import '../../map/providers/map_controller_provider.dart';

part 'trip_state_provider.g.dart';

/// Trip-State für aktuelle Route und Stops
/// keepAlive: true damit der State nicht verloren geht wenn zur Trip-Seite navigiert wird
@Riverpod(keepAlive: true)
class TripState extends _$TripState {
  @override
  TripStateData build() {
    return const TripStateData();
  }

  /// Setzt die aktuelle Route
  void setRoute(AppRoute route) {
    state = state.copyWith(route: route);
  }

  /// Fügt einen Stop hinzu
  void addStop(POI poi) {
    final newStops = [...state.stops, poi];
    state = state.copyWith(stops: newStops);
    _recalculateRoute();
  }

  /// Fügt einen Stop hinzu und erstellt automatisch eine Route wenn keine vorhanden
  /// GPS-Standort wird als Startpunkt verwendet, der POI als Ziel
  /// Gibt ein Result-Objekt zurück mit Status und optionaler Fehlermeldung
  ///
  /// Optional: [existingAIRoute] und [existingAIStops] können übergeben werden,
  /// wenn ein AI Trip aktiv ist. Die AI-Route wird dann übernommen und der neue
  /// Stop wird zu den bestehenden AI-Stops hinzugefügt.
  Future<AddStopResult> addStopWithAutoRoute(
    POI poi, {
    AppRoute? existingAIRoute,
    List<POI>? existingAIStops,
  }) async {
    // Wenn bereits eine Route existiert, einfach den Stop hinzufügen
    if (state.route != null) {
      addStop(poi);
      return const AddStopResult(success: true);
    }

    // AI Trip Route übernehmen wenn vorhanden
    if (existingAIRoute != null) {
      debugPrint('[TripState] AI Trip Route übernommen - füge neuen Stop hinzu');
      final allStops = <POI>[...(existingAIStops ?? <POI>[]), poi];
      state = state.copyWith(route: existingAIRoute, stops: allStops);
      _recalculateRoute();
      ref.read(shouldFitToRouteProvider.notifier).state = true;
      return const AddStopResult(success: true);
    }

    // Keine Route vorhanden - GPS-Standort als Start verwenden
    debugPrint('[TripState] Keine Route vorhanden - erstelle Route von GPS zu POI');

    try {
      final locationResult = await LocationHelper.getCurrentPosition();
      if (!locationResult.isSuccess) {
        return AddStopResult(
          success: false,
          error: locationResult.error ?? 'gps_error',
          message: locationResult.message,
        );
      }

      state = state.copyWith(isRecalculating: true);
      final startLocation = locationResult.position!;

      // Route berechnen von GPS-Standort zum POI
      final routingRepo = ref.read(routingRepositoryProvider);
      final route = await routingRepo.calculateFastRoute(
        start: startLocation,
        end: poi.location,
        startAddress: 'Mein Standort',
        endAddress: poi.name,
      );

      // Route setzen
      state = state.copyWith(
        route: route,
        stops: [],
        isRecalculating: false,
      );

      // Flag setzen, dass auf Route gezoomt werden soll
      ref.read(shouldFitToRouteProvider.notifier).state = true;

      debugPrint('[TripState] Route erstellt: ${route.distanceKm.toStringAsFixed(1)} km zum POI "${poi.name}"');

      return const AddStopResult(success: true, routeCreated: true);
    } catch (e) {
      debugPrint('[TripState] Fehler beim Erstellen der Route: $e');
      state = state.copyWith(isRecalculating: false);
      return AddStopResult(
        success: false,
        error: 'route_error',
        message: 'Fehler beim Erstellen der Route: $e',
      );
    }
  }

  /// Entfernt einen Stop
  void removeStop(String poiId) {
    final newStops = state.stops.where((p) => p.id != poiId).toList();
    state = state.copyWith(stops: newStops);
    _recalculateRoute();
  }

  /// Setzt alle Stops neu (z.B. nach Optimierung)
  void setStops(List<POI> stops) {
    state = state.copyWith(stops: stops);
    _recalculateRoute();
  }

  /// Setzt Route und Stops gleichzeitig OHNE Route-Neuberechnung
  /// Wird verwendet beim Laden gespeicherter Routen aus Favoriten,
  /// da die Route bereits korrekt berechnet war
  void setRouteAndStops(AppRoute route, List<POI> stops) {
    state = state.copyWith(route: route, stops: stops);
  }

  /// Leert alle Stops
  void clearStops() {
    state = state.copyWith(stops: []);
    _recalculateRoute();
  }

  /// Leert Route und Stops
  void clearAll() {
    state = const TripStateData();
  }

  /// Verschiebt einen Stop
  void reorderStops(int oldIndex, int newIndex) {
    final newStops = List<POI>.from(state.stops);
    final stop = newStops.removeAt(oldIndex);
    newStops.insert(newIndex, stop);
    state = state.copyWith(stops: newStops);
    _recalculateRoute();
  }

  /// Berechnet die Route mit aktuellen Waypoints (Stops) neu
  Future<void> _recalculateRoute() async {
    // Nur neu berechnen wenn Route vorhanden
    if (state.route == null) return;

    state = state.copyWith(isRecalculating: true);

    try {
      final routingRepo = ref.read(routingRepositoryProvider);

      // Stops als Waypoints extrahieren
      final waypoints = state.stops.map((poi) => poi.location).toList();

      debugPrint('[TripState] Route neu berechnen mit ${waypoints.length} Waypoints');

      final newRoute = await routingRepo.calculateFastRoute(
        start: state.route!.start,
        end: state.route!.end,
        waypoints: waypoints,
        startAddress: state.route!.startAddress,
        endAddress: state.route!.endAddress,
      );

      state = state.copyWith(
        route: newRoute,
        isRecalculating: false,
      );

      debugPrint('[TripState] Route aktualisiert: ${newRoute.distanceKm.toStringAsFixed(1)} km, ${newRoute.durationMinutes} Min');
    } catch (e) {
      debugPrint('[TripState] Route-Neuberechnung fehlgeschlagen: $e');
      state = state.copyWith(isRecalculating: false);
    }
  }
}

/// Trip-State-Datenmodell
class TripStateData {
  final AppRoute? route;
  final List<POI> stops;
  final bool isRecalculating;

  const TripStateData({
    this.route,
    this.stops = const [],
    this.isRecalculating = false,
  });

  TripStateData copyWith({
    AppRoute? route,
    List<POI>? stops,
    bool? isRecalculating,
  }) {
    return TripStateData(
      route: route ?? this.route,
      stops: stops ?? this.stops,
      isRecalculating: isRecalculating ?? this.isRecalculating,
    );
  }

  /// Hat aktive Route
  bool get hasRoute => route != null;

  /// Hat Stops
  bool get hasStops => stops.isNotEmpty;

  /// Gesamtdistanz mit Stops
  double get totalDistance => route?.distanceKm ?? 0;

  /// Gesamtdauer inkl. Stops (geschätzt)
  int get totalDuration {
    final baseDuration = route?.durationMinutes ?? 0;
    final stopsDuration = stops.length * 45; // 45 Min pro Stop
    return baseDuration + stopsDuration;
  }
}

/// Ergebnis von addStopWithAutoRoute
class AddStopResult {
  final bool success;
  final bool routeCreated;
  final String? error;
  final String? message;

  const AddStopResult({
    required this.success,
    this.routeCreated = false,
    this.error,
    this.message,
  });

  bool get isGpsDisabled => error == 'gps_disabled';
  bool get isPermissionDenied =>
      error == 'permission_denied' || error == 'permission_denied_forever';
}
