import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../data/models/route.dart';
import '../../../data/models/poi.dart';

part 'trip_state_provider.g.dart';

/// Trip-State für aktuelle Route und Stops
@riverpod
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
  }

  /// Entfernt einen Stop
  void removeStop(String poiId) {
    final newStops = state.stops.where((p) => p.id != poiId).toList();
    state = state.copyWith(stops: newStops);
  }

  /// Setzt alle Stops neu (z.B. nach Optimierung)
  void setStops(List<POI> stops) {
    state = state.copyWith(stops: stops);
  }

  /// Leert alle Stops
  void clearStops() {
    state = state.copyWith(stops: []);
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
  }
}

/// Trip-State-Datenmodell
class TripStateData {
  final AppRoute? route;
  final List<POI> stops;

  const TripStateData({
    this.route,
    this.stops = const [],
  });

  TripStateData copyWith({
    AppRoute? route,
    List<POI>? stops,
  }) {
    return TripStateData(
      route: route ?? this.route,
      stops: stops ?? this.stops,
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
