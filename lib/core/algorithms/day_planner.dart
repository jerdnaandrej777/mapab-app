import 'package:latlong2/latlong.dart';
import '../../data/models/poi.dart';
import '../../data/models/trip.dart';
import '../utils/geo_utils.dart';
import 'route_optimizer.dart';

/// Algorithmus zur Tagesaufteilung für Mehrtages-Trips
/// Verteilt POIs auf Tage und schlägt Übernachtungsorte vor
class DayPlanner {
  final RouteOptimizer _routeOptimizer;

  DayPlanner({RouteOptimizer? routeOptimizer})
      : _routeOptimizer = routeOptimizer ?? RouteOptimizer();

  /// Verteilt POIs auf mehrere Tage
  ///
  /// [pois] - Bereits optimierte POI-Liste
  /// [startLocation] - Startpunkt
  /// [days] - Anzahl der Tage
  /// [hoursPerDay] - Fahrzeit pro Tag (Standard: 6 Stunden)
  /// [returnToStart] - Soll am Ende zum Start zurückgekehrt werden?
  List<TripDay> planDays({
    required List<POI> pois,
    required LatLng startLocation,
    required int days,
    int hoursPerDay = 6,
    bool returnToStart = true,
  }) {
    if (pois.isEmpty || days <= 0) return [];

    // Nur 1 Tag - alle POIs in einen Tag
    if (days == 1) {
      return [
        TripDay(
          dayNumber: 1,
          title: 'Tag 1',
          stops: pois.map((poi) => TripStop.fromPOI(poi)).toList(),
          distanceKm: _routeOptimizer.calculateTotalDistance(
            pois: pois,
            startLocation: startLocation,
            returnToStart: returnToStart,
          ),
          durationMinutes: _routeOptimizer.calculateEstimatedDuration(
            pois: pois,
            startLocation: startLocation,
            returnToStart: returnToStart,
          ),
        ),
      ];
    }

    // Mehrtages-Trip: Geografische Cluster bilden
    final clusters = _clusterPOIsByGeography(pois, days);

    // Cluster zu TripDays konvertieren
    final tripDays = <TripDay>[];
    var currentStartLocation = startLocation;

    for (int i = 0; i < clusters.length; i++) {
      final dayPois = clusters[i];
      final isLastDay = i == clusters.length - 1;

      // Optimiere die Reihenfolge für diesen Tag
      final optimizedDayPois = _routeOptimizer.optimizeRoute(
        pois: dayPois,
        startLocation: currentStartLocation,
        returnToStart: isLastDay && returnToStart,
      );

      // Stops mit Tages-Nummer erstellen
      final stops = optimizedDayPois.asMap().entries.map((entry) {
        return TripStop.fromPOI(entry.value).copyWith(
          day: i + 1,
          order: entry.key,
        );
      }).toList();

      // Distanz und Dauer für diesen Tag berechnen
      final distance = _routeOptimizer.calculateTotalDistance(
        pois: optimizedDayPois,
        startLocation: currentStartLocation,
        returnToStart: false,
      );

      final duration = _routeOptimizer.calculateEstimatedDuration(
        pois: optimizedDayPois,
        startLocation: currentStartLocation,
        returnToStart: false,
      );

      // Titel generieren
      final title = _generateDayTitle(i + 1, optimizedDayPois, isLastDay);

      tripDays.add(TripDay(
        dayNumber: i + 1,
        title: title,
        stops: stops,
        distanceKm: distance,
        durationMinutes: duration,
      ));

      // Nächster Tag startet am letzten POI
      if (optimizedDayPois.isNotEmpty) {
        currentStartLocation = optimizedDayPois.last.location;
      }
    }

    return tripDays;
  }

  /// Clustert POIs geografisch in [days] Gruppen
  List<List<POI>> _clusterPOIsByGeography(List<POI> pois, int days) {
    if (pois.length <= days) {
      // Weniger POIs als Tage: jeder POI ein Tag
      return pois.map((p) => [p]).toList();
    }

    // Einfaches geografisches Clustering basierend auf Position in der Liste
    // Die Liste ist bereits durch RouteOptimizer sortiert
    final poisPerDay = (pois.length / days).ceil();
    final clusters = <List<POI>>[];

    for (int i = 0; i < days; i++) {
      final startIdx = i * poisPerDay;
      final endIdx = (startIdx + poisPerDay).clamp(0, pois.length);

      if (startIdx < pois.length) {
        clusters.add(pois.sublist(startIdx, endIdx));
      }
    }

    return clusters;
  }

  /// Generiert einen beschreibenden Titel für einen Tag
  String _generateDayTitle(int dayNumber, List<POI> pois, bool isLastDay) {
    if (pois.isEmpty) {
      return 'Tag $dayNumber';
    }

    // Highlights des Tages (Must-See oder höchster Score)
    final highlights = pois.where((p) => p.isMustSee).toList();
    final mainHighlight = highlights.isNotEmpty
        ? highlights.first
        : pois.reduce((a, b) => a.score > b.score ? a : b);

    final suffix = isLastDay ? ' (Rückreise)' : '';

    return 'Tag $dayNumber: ${mainHighlight.name}$suffix';
  }

  /// Berechnet optimale Übernachtungsorte
  /// Gibt die Koordinaten zurück, an denen Hotels gesucht werden sollten
  List<LatLng> calculateOvernightLocations({
    required List<TripDay> tripDays,
    required LatLng startLocation,
  }) {
    final locations = <LatLng>[];

    // Für jeden Tag außer dem letzten: Übernachtung am Ende
    for (int i = 0; i < tripDays.length - 1; i++) {
      final day = tripDays[i];

      if (day.stops.isNotEmpty) {
        // Übernachtung am letzten Stop des Tages
        final lastStop = day.stops.last;
        locations.add(lastStop.location);
      } else if (i == 0) {
        // Erster Tag ohne Stops: nahe Startpunkt
        locations.add(startLocation);
      } else if (locations.isNotEmpty) {
        // Kein Stop, aber vorherige Location verfügbar
        locations.add(locations.last);
      }
    }

    return locations;
  }

  /// Fügt Hotels als Übernachtungs-Stops zu den TripDays hinzu
  List<TripDay> addOvernightStops({
    required List<TripDay> tripDays,
    required List<TripStop> hotelStops,
  }) {
    if (hotelStops.isEmpty) return tripDays;

    return tripDays.asMap().entries.map((entry) {
      final dayIndex = entry.key;
      final day = entry.value;

      // Kein Hotel für den letzten Tag
      if (dayIndex >= hotelStops.length) {
        return day;
      }

      final hotelStop = hotelStops[dayIndex].copyWith(
        isOvernightStop: true,
        day: day.dayNumber,
        order: day.stops.length,
      );

      return day.copyWith(
        stops: [...day.stops, hotelStop],
        overnightStop: hotelStop,
      );
    }).toList();
  }

  /// Schätzt die optimale Anzahl von POIs pro Tag
  static int estimatePoisPerDay({
    int hoursPerDay = 6,
    int avgVisitDurationMinutes = 45,
    int avgDrivingMinutesBetweenStops = 30,
  }) {
    final totalMinutes = hoursPerDay * 60;
    final minutesPerStop = avgVisitDurationMinutes + avgDrivingMinutesBetweenStops;
    return (totalMinutes / minutesPerStop).floor().clamp(2, 8);
  }

  /// Berechnet empfohlene Radius basierend auf Tagen
  static double calculateRecommendedRadius(int days) {
    // Mehr Tage = größerer Radius
    switch (days) {
      case 1:
        return 100; // Tagesausflug
      case 2:
        return 200;
      case 3:
        return 300;
      case 4:
        return 400;
      case 5:
        return 500;
      case 6:
        return 600;
      case 7:
      default:
        return 700;
    }
  }
}

/// Ergebnis der Tagesplanung
class DayPlanResult {
  final List<TripDay> days;
  final double totalDistanceKm;
  final int totalDurationMinutes;
  final List<LatLng> overnightLocations;

  DayPlanResult({
    required this.days,
    required this.totalDistanceKm,
    required this.totalDurationMinutes,
    required this.overnightLocations,
  });

  int get totalStops => days.fold(0, (sum, day) => sum + day.stops.length);

  String get formattedTotalDistance => '${totalDistanceKm.toStringAsFixed(1)} km';

  String get formattedTotalDuration {
    final hours = totalDurationMinutes ~/ 60;
    final mins = totalDurationMinutes % 60;
    if (mins == 0) return '$hours Std.';
    return '$hours Std. $mins Min.';
  }
}
