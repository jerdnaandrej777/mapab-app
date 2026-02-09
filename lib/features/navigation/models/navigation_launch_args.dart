import '../../../data/models/route.dart';
import '../../../data/models/trip.dart';

/// Typisierte Start-Argumente fuer die Navigation.
///
/// Erlaubt weiterhin Legacy-`Map<String, dynamic>` Extras, damit bestehende
/// Aufrufer kompatibel bleiben.
class NavigationLaunchArgs {
  final AppRoute route;
  final List<TripStop> stops;

  const NavigationLaunchArgs({
    required this.route,
    List<TripStop>? stops,
  }) : stops = stops ?? const [];

  static NavigationLaunchArgs? fromExtra(Object? extra) {
    if (extra is NavigationLaunchArgs) {
      return extra;
    }

    if (extra is Map<String, dynamic>) {
      final route = extra['route'];
      final rawStops = extra['stops'];
      if (route is! AppRoute) return null;

      if (rawStops == null) {
        return NavigationLaunchArgs(route: route);
      }

      if (rawStops is List<TripStop>) {
        return NavigationLaunchArgs(route: route, stops: rawStops);
      }

      if (rawStops is List) {
        final stops = rawStops.whereType<TripStop>().toList();
        if (stops.length == rawStops.length) {
          return NavigationLaunchArgs(route: route, stops: stops);
        }
      }
    }

    return null;
  }
}
