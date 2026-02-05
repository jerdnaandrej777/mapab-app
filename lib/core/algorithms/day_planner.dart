import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../../data/models/poi.dart';
import '../../data/models/trip.dart';
import '../constants/trip_constants.dart';
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

    // Mehrtages-Trip: Distanz-basierte Cluster bilden
    final clusters = _clusterPOIsByDistance(pois, days, startLocation, returnToStart: returnToStart);

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
      // Letzter Tag: Rückkehr-Segment einrechnen wenn returnToStart
      final includeReturn = isLastDay && returnToStart;
      final distance = _routeOptimizer.calculateTotalDistance(
        pois: optimizedDayPois,
        startLocation: currentStartLocation,
        returnToStart: includeReturn,
      );

      final duration = _routeOptimizer.calculateEstimatedDuration(
        pois: optimizedDayPois,
        startLocation: currentStartLocation,
        returnToStart: includeReturn,
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

  /// Clustert POIs nach kumulativer Fahrdistanz in Tages-Gruppen
  ///
  /// POIs sind bereits in optimierter Reihenfolge (Nearest-Neighbor + 2-opt).
  /// Der Algorithmus iteriert durch die Liste und schneidet einen neuen Tag ab,
  /// wenn die projizierte Display-Distanz (Haversine × 1.35) 700km übersteigt.
  ///
  /// Garantien:
  /// - Mindestens 1 POI pro Tag
  /// - Maximal maxPoisPerDay (9) pro Tag
  /// - Display-Distanz pro Tag unter maxDisplayKmPerDay (700km)
  /// - Tagesanzahl wird dynamisch bestimmt (kann von [requestedDays] abweichen)
  List<List<POI>> _clusterPOIsByDistance(
    List<POI> pois,
    int requestedDays,
    LatLng startLocation, {
    bool returnToStart = true,
  }) {
    if (pois.isEmpty) return [];
    if (pois.length == 1) return [pois];

    final clusters = <List<POI>>[];
    var currentCluster = <POI>[];
    var currentDayKm = 0.0;
    var lastLocation = startLocation;

    for (int i = 0; i < pois.length; i++) {
      final poi = pois[i];
      final segmentKm = GeoUtils.haversineDistance(lastLocation, poi.location);
      final projectedDayKm = currentDayKm + segmentKm;

      // Entscheide ob neuer Tag beginnen soll
      bool shouldStartNewDay = false;

      if (currentCluster.isNotEmpty) {
        // Fall 1: Display-Distanz (Haversine × 1.35) würde 700km überschreiten
        final projectedDisplayKm = projectedDayKm * TripConstants.haversineToDisplayFactor;
        if (projectedDisplayKm > TripConstants.maxDisplayKmPerDay) {
          shouldStartNewDay = true;
        }
        // Fall 2: Google Maps Waypoint-Limit erreicht
        if (currentCluster.length >= TripConstants.maxPoisPerDay) {
          shouldStartNewDay = true;
        }
      }

      if (shouldStartNewDay) {
        clusters.add(currentCluster);
        currentCluster = <POI>[];
        // Neuer Tag: Distanz startet von letztem POI des vorherigen Tages
        currentDayKm = segmentKm;

        // Safety-Check: Wenn schon das Incoming-Segment allein >700km Display ist,
        // logge Warnung (unvermeidbar bei weit entfernten aufeinanderfolgenden POIs)
        if (segmentKm * TripConstants.haversineToDisplayFactor > TripConstants.maxDisplayKmPerDay) {
          debugPrint('[DayPlanner] ⚠️ Incoming-Segment ${(segmentKm * TripConstants.haversineToDisplayFactor).toStringAsFixed(0)}km Display > ${TripConstants.maxDisplayKmPerDay.toStringAsFixed(0)}km Limit (POI: ${poi.name})');
        }
      } else {
        currentDayKm = projectedDayKm;
      }

      currentCluster.add(poi);
      lastLocation = poi.location;
    }

    // Letzten Cluster hinzufuegen
    if (currentCluster.isNotEmpty) {
      clusters.add(currentCluster);
    }

    // Post-Processing: Zu kurze letzte Tage mit vorherigem Tag zusammenlegen
    _mergeShortDays(clusters, startLocation);

    // Post-Processing: Letzten Tag splitten wenn Rückkehr-Segment 700km sprengt
    if (returnToStart && clusters.length >= 2) {
      _splitLastDayIfOverLimit(clusters, startLocation);
    }

    // Post-Processing: Tage die einzeln >700km Display haben versuchen zu splitten
    _splitOverlimitDays(clusters, startLocation);

    debugPrint('[DayPlanner] Distanz-Clustering: $requestedDays angefragt → ${clusters.length} Tage');
    for (int i = 0; i < clusters.length; i++) {
      final clusterStart = i > 0 ? clusters[i - 1].last.location : startLocation;
      final km = _calculateClusterDistance(clusters[i], clusterStart);
      final isLast = i == clusters.length - 1;
      var displayKm = km * TripConstants.haversineToDisplayFactor;

      // Letzter Tag: Rückkehr-Segment einrechnen
      if (isLast && returnToStart && clusters[i].isNotEmpty) {
        final returnKm = GeoUtils.haversineDistance(clusters[i].last.location, startLocation);
        displayKm = (km + returnKm) * TripConstants.haversineToDisplayFactor;
      }

      debugPrint('[DayPlanner]   Tag ${i + 1}: ${clusters[i].length} POIs, ${km.toStringAsFixed(0)}km Haversine, ~${displayKm.toStringAsFixed(0)}km Display');
    }

    return clusters;
  }

  /// Mergt zu kurze Tage (< minKmPerDay) mit dem vorherigen Tag,
  /// solange das Google Maps Limit und das 700km Display-Limit eingehalten werden
  void _mergeShortDays(List<List<POI>> clusters, LatLng startLocation) {
    if (clusters.length < 2) return;

    var i = clusters.length - 1;
    while (i > 0) {
      final cluster = clusters[i];
      final prevCluster = clusters[i - 1];

      // Distanz dieses Tages berechnen
      final dayKm = _calculateClusterDistance(
        cluster,
        prevCluster.isNotEmpty ? prevCluster.last.location : startLocation,
      );

      // Wenn zu kurz und Merge moeglich (POI-Limit)
      if (dayKm < TripConstants.minKmPerDay &&
          prevCluster.length + cluster.length <= TripConstants.maxPoisPerDay) {
        // 700km-Guard: Prüfen ob kombinierter Tag das Display-Limit einhält
        final prevStart = i > 1
            ? clusters[i - 2].last.location
            : startLocation;
        final mergedCluster = [...prevCluster, ...cluster];
        final mergedKm = _calculateClusterDistance(mergedCluster, prevStart);
        final mergedDisplayKm = mergedKm * TripConstants.haversineToDisplayFactor;

        if (mergedDisplayKm > TripConstants.maxDisplayKmPerDay) {
          debugPrint('[DayPlanner] Merge verhindert: Tag ${i + 1} + Tag $i = ~${mergedDisplayKm.toStringAsFixed(0)}km Display > ${TripConstants.maxDisplayKmPerDay.toStringAsFixed(0)}km Limit');
          i--;
          continue;
        }

        clusters[i - 1] = mergedCluster;
        clusters.removeAt(i);
        debugPrint('[DayPlanner] Merge: Tag ${i + 1} (${dayKm.toStringAsFixed(0)}km) mit Tag $i zusammengelegt (~${mergedDisplayKm.toStringAsFixed(0)}km Display)');
      }
      i--;
    }
  }

  /// Splittet den letzten Tag wenn das Rückkehr-Segment die 700km sprengt.
  ///
  /// Berechnet die Gesamt-Display-Distanz des letzten Tages inkl. Rückkehr
  /// zum Startpunkt. Wenn > 700km, werden POIs in einen neuen Tag verschoben,
  /// bis der letzte Tag wieder unter dem Limit liegt.
  void _splitLastDayIfOverLimit(List<List<POI>> clusters, LatLng startLocation) {
    if (clusters.isEmpty) return;

    final lastIdx = clusters.length - 1;
    final lastCluster = clusters[lastIdx];
    if (lastCluster.length <= 1) return;

    // Start des letzten Tages = letzter POI des Vortages
    final lastDayStart = lastIdx > 0
        ? clusters[lastIdx - 1].last.location
        : startLocation;

    // Haversine-Distanz des letzten Tages + Rückkehr zum Start
    final dayKm = _calculateClusterDistance(lastCluster, lastDayStart);
    final returnKm = GeoUtils.haversineDistance(lastCluster.last.location, startLocation);
    final totalDisplayKm = (dayKm + returnKm) * TripConstants.haversineToDisplayFactor;

    if (totalDisplayKm <= TripConstants.maxDisplayKmPerDay) return;

    debugPrint('[DayPlanner] Letzter Tag ~${totalDisplayKm.toStringAsFixed(0)}km Display (inkl. Rückkehr) > ${TripConstants.maxDisplayKmPerDay.toStringAsFixed(0)}km Limit → Split');

    // POIs vom Anfang des letzten Tages in einen neuen vorletzten Tag verschieben,
    // bis der verbleibende letzte Tag + Rückkehr unter 700km liegt
    final newSecondToLast = <POI>[];
    final remainingLast = List<POI>.from(lastCluster);

    while (remainingLast.length > 1) {
      // Ersten POI aus dem letzten Tag nehmen
      newSecondToLast.add(remainingLast.removeAt(0));

      // Neue Display-Distanz des verbleibenden letzten Tages prüfen
      final newLastStart = newSecondToLast.last.location;
      final newLastKm = _calculateClusterDistance(remainingLast, newLastStart);
      final newReturnKm = GeoUtils.haversineDistance(remainingLast.last.location, startLocation);
      final newTotalDisplay = (newLastKm + newReturnKm) * TripConstants.haversineToDisplayFactor;

      if (newTotalDisplay <= TripConstants.maxDisplayKmPerDay) {
        debugPrint('[DayPlanner] Split: ${newSecondToLast.length} POIs → neuer Tag, letzter Tag ~${newTotalDisplay.toStringAsFixed(0)}km Display');
        break;
      }
    }

    if (newSecondToLast.isNotEmpty) {
      // Neuen vorletzten Tag einfügen, letzten Tag ersetzen
      clusters[lastIdx] = remainingLast;
      clusters.insert(lastIdx, newSecondToLast);
    }
  }

  /// Splittet Tage die trotz Clustering das 700km Display-Limit ueberschreiten.
  ///
  /// Dies kann passieren wenn:
  /// - Das Incoming-Segment allein schon >700km ist (weit entfernte POIs)
  /// - Mehrere Stops mit hoher Einzeldistanz sich aufaddieren
  ///
  /// Tage mit nur 1 POI koennen nicht weiter gesplittet werden.
  void _splitOverlimitDays(List<List<POI>> clusters, LatLng startLocation) {
    var i = 0;
    // v1.9.28: Absolute Obergrenze (50) statt relatives clusters.length*2
    // da clusters bei jedem Split wachsen koennen
    var maxIterations = min(clusters.length * 2, 50);
    while (i < clusters.length && maxIterations > 0) {
      maxIterations--;
      final cluster = clusters[i];
      if (cluster.length <= 1) {
        i++;
        continue;
      }

      final clusterStart = i > 0 ? clusters[i - 1].last.location : startLocation;
      final km = _calculateClusterDistance(cluster, clusterStart);
      final displayKm = km * TripConstants.haversineToDisplayFactor;

      if (displayKm <= TripConstants.maxDisplayKmPerDay) {
        i++;
        continue;
      }

      // Tag ueberschreitet 700km → versuche zu splitten
      // Finde den Split-Punkt: gehe durch POIs bis Display-Limit erreicht
      var splitKm = 0.0;
      var splitLocation = clusterStart;
      var splitIndex = 0;

      for (int j = 0; j < cluster.length; j++) {
        final segKm = GeoUtils.haversineDistance(splitLocation, cluster[j].location);
        final projDisplay = (splitKm + segKm) * TripConstants.haversineToDisplayFactor;
        if (projDisplay > TripConstants.maxDisplayKmPerDay && j > 0) {
          splitIndex = j;
          break;
        }
        splitKm += segKm;
        splitLocation = cluster[j].location;
        splitIndex = j + 1;
      }

      // Mindestens 1 POI in jedem Teil
      if (splitIndex <= 0) splitIndex = 1;
      if (splitIndex >= cluster.length) {
        // Kann nicht weiter gesplittet werden
        debugPrint('[DayPlanner] ⚠️ Tag ${i + 1} = ~${displayKm.toStringAsFixed(0)}km Display, kann nicht weiter gesplittet werden (${cluster.length} POIs)');
        i++;
        continue;
      }

      final firstPart = cluster.sublist(0, splitIndex);
      final secondPart = cluster.sublist(splitIndex);

      clusters[i] = firstPart;
      clusters.insert(i + 1, secondPart);

      debugPrint('[DayPlanner] Split Tag ${i + 1}: ~${displayKm.toStringAsFixed(0)}km → ${firstPart.length} + ${secondPart.length} POIs');
      // i bleibt gleich, um den ersten Teil nochmal zu pruefen
    }
  }

  /// Berechnet die kumulative Haversine-Distanz eines Clusters
  double _calculateClusterDistance(List<POI> cluster, LatLng startPoint) {
    if (cluster.isEmpty) return 0;
    double total = GeoUtils.haversineDistance(startPoint, cluster.first.location);
    for (int i = 0; i < cluster.length - 1; i++) {
      total += GeoUtils.haversineDistance(
        cluster[i].location,
        cluster[i + 1].location,
      );
    }
    return total;
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
  /// Berücksichtigt Google Maps Limit von 9 Waypoints
  static int estimatePoisPerDay({
    int hoursPerDay = 6,
    int avgVisitDurationMinutes = 45,
    int avgDrivingMinutesBetweenStops = 30,
  }) {
    final totalMinutes = hoursPerDay * 60;
    final minutesPerStop = avgVisitDurationMinutes + avgDrivingMinutesBetweenStops;
    return (totalMinutes / minutesPerStop)
        .floor()
        .clamp(TripConstants.minPoisPerDay, TripConstants.maxPoisPerDay);
  }

  /// Berechnet empfohlene Radius basierend auf Tagen
  /// Verwendet 600km pro Tag als Basis
  static double calculateRecommendedRadius(int days) {
    return TripConstants.calculateRadiusFromDays(days);
  }

  /// Berechnet die Anzahl der Tage basierend auf dem Radius
  static int calculateDaysFromRadius(double radiusKm) {
    return TripConstants.calculateDaysFromDistance(radiusKm);
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
