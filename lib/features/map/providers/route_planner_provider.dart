import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:latlong2/latlong.dart';
import '../../../data/models/route.dart';
import '../../../data/repositories/routing_repo.dart';
import '../../poi/providers/poi_state_provider.dart';
import '../../trip/providers/trip_state_provider.dart';
import 'route_session_provider.dart';

part 'route_planner_provider.g.dart';

/// Route-Planner State für Start/Ziel und Berechnung
@riverpod
class RoutePlanner extends _$RoutePlanner {
  @override
  RoutePlannerData build() {
    return const RoutePlannerData();
  }

  /// Setzt Startpunkt
  void setStart(LatLng location, String address) {
    state = state.copyWith(
      startLocation: location,
      startAddress: address,
    );
    _tryCalculateRoute();
  }

  /// Setzt Ziel
  void setEnd(LatLng location, String address) {
    state = state.copyWith(
      endLocation: location,
      endAddress: address,
    );
    _tryCalculateRoute();
  }

  /// Löscht Start
  void clearStart() {
    state = state.copyWith(
      startLocation: null,
      startAddress: null,
      route: null,
    );
  }

  /// Löscht Ziel
  void clearEnd() {
    state = state.copyWith(
      endLocation: null,
      endAddress: null,
      route: null,
    );
  }

  /// Löscht die gesamte Route (Start, Ziel, berechnete Route)
  void clearRoute() {
    state = const RoutePlannerData();
    // Auch im Trip-State löschen
    ref.read(tripStateProvider.notifier).clearAll();
    // Route-Session stoppen und POIs löschen
    ref.read(routeSessionProvider.notifier).stopRoute();
    ref.read(pOIStateNotifierProvider.notifier).clearPOIs();
    print('[RoutePlanner] Route, Session und POIs gelöscht');
  }

  /// Berechnet Route wenn Start UND Ziel gesetzt
  Future<void> _tryCalculateRoute() async {
    if (state.startLocation == null || state.endLocation == null) {
      return;
    }

    state = state.copyWith(isCalculating: true);

    // Alte Route-Session stoppen, POIs und Trip-Stops löschen
    ref.read(routeSessionProvider.notifier).stopRoute();
    ref.read(pOIStateNotifierProvider.notifier).clearPOIs();
    ref.read(tripStateProvider.notifier).clearStops();
    print('[RoutePlanner] Alte Route-Session, POIs und Trip-Stops gelöscht');

    try {
      final routingRepo = ref.read(routingRepositoryProvider);

      final route = await routingRepo.calculateFastRoute(
        start: state.startLocation!,
        end: state.endLocation!,
        startAddress: state.startAddress ?? 'Unbekannt',
        endAddress: state.endAddress ?? 'Unbekannt',
      );

      state = state.copyWith(
        route: route,
        isCalculating: false,
      );

      // Route in Trip-State schreiben
      ref.read(tripStateProvider.notifier).setRoute(route);
    } catch (e) {
      print('[RoutePlanner] Fehler bei Routenberechnung: $e');
      state = state.copyWith(
        isCalculating: false,
        error: e.toString(),
      );
    }
  }

  /// Manuelle Route-Neuberechnung
  Future<void> recalculateRoute() async {
    await _tryCalculateRoute();
  }
}

/// Route-Planner State Data
class RoutePlannerData {
  final LatLng? startLocation;
  final String? startAddress;
  final LatLng? endLocation;
  final String? endAddress;
  final AppRoute? route;
  final bool isCalculating;
  final String? error;

  const RoutePlannerData({
    this.startLocation,
    this.startAddress,
    this.endLocation,
    this.endAddress,
    this.route,
    this.isCalculating = false,
    this.error,
  });

  RoutePlannerData copyWith({
    LatLng? startLocation,
    String? startAddress,
    LatLng? endLocation,
    String? endAddress,
    AppRoute? route,
    bool? isCalculating,
    String? error,
  }) {
    return RoutePlannerData(
      startLocation: startLocation ?? this.startLocation,
      startAddress: startAddress ?? this.startAddress,
      endLocation: endLocation ?? this.endLocation,
      endAddress: endAddress ?? this.endAddress,
      route: route ?? this.route,
      isCalculating: isCalculating ?? this.isCalculating,
      error: error ?? this.error,
    );
  }

  bool get hasStart => startLocation != null;
  bool get hasEnd => endLocation != null;
  bool get hasRoute => route != null;
  bool get canCalculate => hasStart && hasEnd;
}
