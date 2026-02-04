import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../core/algorithms/day_planner.dart';
import '../../core/algorithms/random_poi_selector.dart';
import '../../core/algorithms/route_optimizer.dart';
import '../../core/constants/categories.dart';
import '../../core/constants/trip_constants.dart';
import '../../core/utils/geo_utils.dart';
import '../../core/utils/scoring_utils.dart';
import '../models/poi.dart';
import '../models/trip.dart';
import '../services/hotel_service.dart';
import 'poi_repo.dart';
import 'routing_repo.dart';

part 'trip_generator_repo.g.dart';

/// Repository für die Generierung von Zufalls-Trips
/// Kombiniert POI-Auswahl, Route-Optimierung und Tagesplanung
class TripGeneratorRepository {
  final POIRepository _poiRepo;
  final RoutingRepository _routingRepo;
  final HotelService _hotelService;
  final RandomPOISelector _poiSelector;
  final RouteOptimizer _routeOptimizer;
  final DayPlanner _dayPlanner;
  final Uuid _uuid;

  TripGeneratorRepository({
    POIRepository? poiRepo,
    RoutingRepository? routingRepo,
    HotelService? hotelService,
    RandomPOISelector? poiSelector,
    RouteOptimizer? routeOptimizer,
    DayPlanner? dayPlanner,
  })  : _poiRepo = poiRepo ?? POIRepository(),
        _routingRepo = routingRepo ?? RoutingRepository(),
        _hotelService = hotelService ?? HotelService(),
        _poiSelector = poiSelector ?? RandomPOISelector(),
        _routeOptimizer = routeOptimizer ?? RouteOptimizer(),
        _dayPlanner = dayPlanner ?? DayPlanner(),
        _uuid = const Uuid();

  /// Generiert einen Tagesausflug
  ///
  /// [startLocation] - Startpunkt
  /// [startAddress] - Adresse des Startpunkts
  /// [radiusKm] - Suchradius für POIs (oder Korridor-Breite bei Ziel)
  /// [categories] - Bevorzugte Kategorien
  /// [poiCount] - Anzahl gewünschter POIs
  /// [destinationLocation] - Optionaler Zielpunkt (wenn null → Rundreise)
  /// [destinationAddress] - Optionale Zieladresse
  Future<GeneratedTrip> generateDayTrip({
    required LatLng startLocation,
    required String startAddress,
    double radiusKm = 100,
    List<POICategory> categories = const [],
    int poiCount = 5,
    LatLng? destinationLocation,
    String? destinationAddress,
    WeatherCondition? weatherCondition,
  }) async {
    final hasDestination = destinationLocation != null;
    final endLocation = destinationLocation ?? startLocation;
    final endAddress = destinationAddress ?? startAddress;

    // 1. POIs laden — Korridor oder Radius
    final categoryIds = categories.isNotEmpty
        ? categories.map((c) => c.id).toList()
        : null;

    List<POI> availablePOIs;
    if (hasDestination) {
      debugPrint('[TripGenerator] Tagestrip Korridor-Modus: $startAddress → $endAddress, ${radiusKm}km Breite');
      availablePOIs = await _loadPOIsAlongCorridor(
        start: startLocation,
        end: destinationLocation!,
        bufferKm: radiusKm,
        categoryFilter: categoryIds,
      );
    } else {
      availablePOIs = await _poiRepo.loadPOIsInRadius(
        center: startLocation,
        radiusKm: radiusKm,
        categoryFilter: categoryIds,
      );
    }

    // v1.9.13: Hotels sind fuer Tagesausfluege nicht relevant
    availablePOIs = availablePOIs.where((poi) => poi.categoryId != 'hotel').toList();

    if (availablePOIs.isEmpty) {
      throw TripGenerationException(
        hasDestination
            ? 'Keine POIs entlang der Route $startAddress → $endAddress gefunden'
            : 'Keine POIs im Umkreis von ${radiusKm}km gefunden',
      );
    }

    // 1b. Wetter-adjustierte Scores setzen (v1.9.9)
    if (weatherCondition != null &&
        weatherCondition != WeatherCondition.unknown &&
        weatherCondition != WeatherCondition.mixed) {
      availablePOIs = availablePOIs.map((poi) {
        final adjusted = ScoringUtils.adjustScoreForWeather(
          score: poi.effectiveScore ?? poi.score.toDouble(),
          isIndoorPOI: poi.category?.isWeatherResilient ?? false,
          weatherCondition: weatherCondition,
        );
        return poi.copyWith(effectiveScore: adjusted);
      }).toList();
    }

    // 2. Zufällige POIs auswählen
    final selectedPOIs = _poiSelector.selectRandomPOIs(
      pois: availablePOIs,
      startLocation: startLocation,
      count: poiCount,
      preferredCategories: categories,
    );

    if (selectedPOIs.isEmpty) {
      throw TripGenerationException('Keine passenden POIs gefunden');
    }

    // 3. Route optimieren
    final List<POI> optimizedPOIs;
    if (hasDestination) {
      // Richtungs-Optimierung: POIs vorwaerts entlang Start → Ziel
      optimizedPOIs = _routeOptimizer.optimizeDirectionalRoute(
        pois: selectedPOIs,
        startLocation: startLocation,
        endLocation: destinationLocation!,
      );
    } else {
      optimizedPOIs = _routeOptimizer.optimizeRoute(
        pois: selectedPOIs,
        startLocation: startLocation,
        returnToStart: true,
      );
    }

    // 4. Echte Route berechnen
    final waypoints = optimizedPOIs.map((p) => p.location).toList();
    final route = await _routingRepo.calculateFastRoute(
      start: startLocation,
      end: endLocation,
      waypoints: waypoints,
      startAddress: startAddress,
      endAddress: endAddress,
    );

    // 5. Trip erstellen
    final trip = Trip(
      id: _uuid.v4(),
      name: _generateTripName(optimizedPOIs),
      type: TripType.daytrip,
      route: route,
      stops: optimizedPOIs.asMap().entries.map((entry) {
        return TripStop.fromPOI(entry.value).copyWith(order: entry.key);
      }).toList(),
      days: 1,
      createdAt: DateTime.now(),
      preferredCategories: categories.map((c) => c.id).toList(),
    );

    return GeneratedTrip(
      trip: trip,
      availablePOIs: availablePOIs,
      selectedPOIs: optimizedPOIs,
    );
  }

  /// Generiert einen Euro Trip (Mehrtages-Reise)
  ///
  /// [startLocation] - Startpunkt
  /// [startAddress] - Adresse des Startpunkts
  /// [radiusKm] - Such-Radius in km (oder Korridor-Breite bei Ziel)
  /// [categories] - Bevorzugte Kategorien
  /// [includeHotels] - Hotels vorschlagen
  /// [destinationLocation] - Optionaler Zielpunkt (wenn null → Rundreise)
  /// [destinationAddress] - Optionale Zieladresse
  Future<GeneratedTrip> generateEuroTrip({
    required LatLng startLocation,
    required String startAddress,
    double radiusKm = 1000,
    int? days,
    List<POICategory> categories = const [],
    bool includeHotels = true,
    LatLng? destinationLocation,
    String? destinationAddress,
    WeatherCondition? weatherCondition,
  }) async {
    final hasDestination = destinationLocation != null;
    final endLocation = destinationLocation ?? startLocation;
    final endAddress = destinationAddress ?? startAddress;

    // Tage: direkt übergeben oder aus Radius berechnen (Fallback)
    final effectiveDays = days ?? TripConstants.calculateDaysFromDistance(radiusKm);
    debugPrint('[TripGenerator] Euro Trip: $effectiveDays Tage (${radiusKm}km Suchradius)${hasDestination ? ' (Ziel: $endAddress)' : ' (Rundreise)'}');

    // POIs pro Tag (max 9 wegen Google Maps Limit)
    final poisPerDay = min(
      DayPlanner.estimatePoisPerDay(),
      TripConstants.maxPoisPerDay,
    );
    final totalPOIs = effectiveDays * poisPerDay;
    debugPrint('[TripGenerator] POIs: $poisPerDay pro Tag, $totalPOIs gesamt');

    // 1. POIs laden — Korridor oder Radius
    final categoryIds = categories.isNotEmpty
        ? categories.map((c) => c.id).toList()
        : null;

    List<POI> availablePOIs;
    if (hasDestination) {
      debugPrint('[TripGenerator] Euro Trip Korridor-Modus: $startAddress → $endAddress, ${radiusKm}km Breite');
      availablePOIs = await _loadPOIsAlongCorridor(
        start: startLocation,
        end: destinationLocation!,
        bufferKm: radiusKm,
        categoryFilter: categoryIds,
      ).timeout(
        const Duration(seconds: 45),
        onTimeout: () {
          debugPrint('[TripGenerator] ⚠️ Korridor POI-Laden Timeout nach 45s');
          return <POI>[];
        },
      );
    } else {
      availablePOIs = await _poiRepo.loadPOIsInRadius(
        center: startLocation,
        radiusKm: radiusKm,
        categoryFilter: categoryIds,
      ).timeout(
        const Duration(seconds: 45),
        onTimeout: () {
          debugPrint('[TripGenerator] ⚠️ POI-Laden Timeout nach 45s');
          return <POI>[];
        },
      );
    }

    debugPrint('[TripGenerator] ${availablePOIs.length} POIs gefunden');

    // v1.9.13: Hotels werden separat als Uebernachtungsstops behandelt, nicht als Sightseeing-POIs
    availablePOIs = availablePOIs.where((poi) => poi.categoryId != 'hotel').toList();

    if (availablePOIs.isEmpty) {
      throw TripGenerationException(
        hasDestination
            ? 'Keine POIs entlang der Route $startAddress → $endAddress gefunden'
            : 'Keine POIs im Umkreis von ${radiusKm}km gefunden. '
              'Versuche einen anderen Startpunkt oder kleineren Radius.',
      );
    }

    // 1b. Wetter-adjustierte Scores setzen (v1.9.9)
    if (weatherCondition != null &&
        weatherCondition != WeatherCondition.unknown &&
        weatherCondition != WeatherCondition.mixed) {
      availablePOIs = availablePOIs.map((poi) {
        final adjusted = ScoringUtils.adjustScoreForWeather(
          score: poi.effectiveScore ?? poi.score.toDouble(),
          isIndoorPOI: poi.category?.isWeatherResilient ?? false,
          weatherCondition: weatherCondition,
        );
        return poi.copyWith(effectiveScore: adjusted);
      }).toList();
    }

    // 2. Zufällige POIs auswählen
    final selectedPOIs = _poiSelector.selectRandomPOIs(
      pois: availablePOIs,
      startLocation: startLocation,
      count: totalPOIs,
      preferredCategories: categories,
      maxPerCategory: 3, // Mehr Diversität bei längeren Trips
    );

    if (selectedPOIs.isEmpty) {
      throw TripGenerationException('Keine passenden POIs gefunden');
    }

    // 3. Route optimieren (Richtungs-Optimierung bei A→B Trips)
    final List<POI> optimizedPOIs;
    if (hasDestination) {
      optimizedPOIs = _routeOptimizer.optimizeDirectionalRoute(
        pois: selectedPOIs,
        startLocation: startLocation,
        endLocation: destinationLocation!,
      );
      debugPrint('[TripGenerator] Directional optimization (A→B): ${optimizedPOIs.length} POIs');
    } else {
      optimizedPOIs = _routeOptimizer.optimizeRoute(
        pois: selectedPOIs,
        startLocation: startLocation,
        returnToStart: true,
      );
    }

    // 4. Auf Tage aufteilen
    debugPrint('[TripGenerator] Plane $effectiveDays Tage mit ${optimizedPOIs.length} POIs...');
    var tripDays = _dayPlanner.planDays(
      pois: optimizedPOIs,
      startLocation: startLocation,
      days: effectiveDays,
      returnToStart: !hasDestination,
    );
    // Tatsaechliche Tagesanzahl kann von angefragter abweichen (distanzbasiert)
    var actualDays = tripDays.length;
    if (actualDays != effectiveDays) {
      debugPrint('[TripGenerator] Tagesanzahl angepasst: $effectiveDays angefragt → $actualDays optimal');
    }
    debugPrint('[TripGenerator] TripDays: $actualDays, Stops gesamt: ${tripDays.fold(0, (sum, d) => sum + d.stops.length)}');

    // Post-Validierung: Kein Tag darf 700km Display-Distanz ueberschreiten
    // Wiederhole planDays mit mehr Tagen bis alle unter dem Limit sind (max 3 Versuche)
    for (int resplitAttempt = 0; resplitAttempt < 3; resplitAttempt++) {
      bool anyOverLimit = false;
      for (final day in tripDays) {
        if (day.distanceKm != null) {
          final displayKm = day.distanceKm! * TripConstants.haversineToDisplayFactor;
          if (displayKm > TripConstants.maxDisplayKmPerDay) {
            debugPrint('[TripGenerator] Post-Validierung Versuch $resplitAttempt: Tag ${day.dayNumber} = ~${displayKm.toStringAsFixed(0)}km Display > ${TripConstants.maxDisplayKmPerDay.toStringAsFixed(0)}km → Re-Split');
            anyOverLimit = true;
            break;
          }
        }
      }
      if (!anyOverLimit) break;

      tripDays = _dayPlanner.planDays(
        pois: optimizedPOIs,
        startLocation: startLocation,
        days: actualDays + 1,
        returnToStart: !hasDestination,
      );
      actualDays = tripDays.length;
      debugPrint('[TripGenerator] Re-Split Versuch $resplitAttempt: $actualDays Tage nach erneutem planDays()');
    }

    // 5. Hotels hinzufügen (optional)
    List<List<HotelSuggestion>> hotelSuggestions = [];
    if (includeHotels && actualDays > 1) {
      final overnightLocations = _dayPlanner.calculateOvernightLocations(
        tripDays: tripDays,
        startLocation: startLocation,
      );

      hotelSuggestions = await _hotelService.searchHotelsForMultipleLocations(
        locations: overnightLocations,
        radiusKm: 15,
        limitPerLocation: 3,
      );

      // Beste Hotels als Stops hinzufügen
      final hotelStops = hotelSuggestions
          .where((list) => list.isNotEmpty)
          .map((list) => _hotelService.convertToTripStops([list.first]).first)
          .toList();

      tripDays = _dayPlanner.addOvernightStops(
        tripDays: tripDays,
        hotelStops: hotelStops,
      );
    }

    // 6. Gesamtroute berechnen
    final allWaypoints = <LatLng>[];
    for (final day in tripDays) {
      for (final stop in day.stops) {
        allWaypoints.add(stop.location);
      }
    }

    debugPrint('[TripGenerator] Route berechnen mit ${allWaypoints.length} Waypoints...');

    final route = await _routingRepo.calculateFastRoute(
      start: startLocation,
      end: endLocation,
      waypoints: allWaypoints,
      startAddress: startAddress,
      endAddress: endAddress,
    );

    debugPrint('[TripGenerator] ✓ Route berechnet: ${route.distanceKm.toStringAsFixed(0)}km');

    // 7. Trip erstellen
    final allStops = tripDays.expand((day) => day.stops).toList();

    final trip = Trip(
      id: _uuid.v4(),
      name: _generateEuroTripName(tripDays),
      type: TripType.eurotrip,
      route: route,
      stops: allStops,
      days: actualDays,
      createdAt: DateTime.now(),
      preferredCategories: categories.map((c) => c.id).toList(),
    );

    return GeneratedTrip(
      trip: trip,
      availablePOIs: availablePOIs,
      selectedPOIs: optimizedPOIs,
      tripDays: tripDays,
      hotelSuggestions: hotelSuggestions,
    );
  }

  /// Entfernt einen einzelnen POI aus dem Trip
  Future<GeneratedTrip> removePOI({
    required GeneratedTrip currentTrip,
    required String poiIdToRemove,
    required LatLng startLocation,
    required String startAddress,
  }) async {
    // Prüfen ob genug POIs übrig bleiben (min 2)
    if (currentTrip.selectedPOIs.length <= 2) {
      throw TripGenerationException(
        'Mindestens 2 Stops müssen im Trip bleiben',
      );
    }

    // Multi-Day: Nur den betroffenen Tag modifizieren, andere Tage beibehalten
    if (currentTrip.trip.actualDays > 1) {
      return _removePOIFromDay(
        currentTrip: currentTrip,
        poiIdToRemove: poiIdToRemove,
        startLocation: startLocation,
        startAddress: startAddress,
      );
    }

    // Single-Day: Globale Re-Optimierung (bestehendes Verhalten)
    // POI aus der Liste entfernen
    final newSelectedPOIs = currentTrip.selectedPOIs
        .where((p) => p.id != poiIdToRemove)
        .toList();

    // Route neu optimieren
    final optimizedPOIs = _routeOptimizer.optimizeRoute(
      pois: newSelectedPOIs,
      startLocation: startLocation,
      returnToStart: true,
    );

    // Neue Route berechnen
    final waypoints = optimizedPOIs.map((p) => p.location).toList();
    final route = await _routingRepo.calculateFastRoute(
      start: startLocation,
      end: startLocation,
      waypoints: waypoints,
      startAddress: startAddress,
      endAddress: startAddress,
    );

    // Trip aktualisieren - bei Mehrtages-Trips Tagesplanung wiederholen
    final days = currentTrip.trip.actualDays;
    List<TripStop> newStops;
    int updatedDays = days;
    if (days > 1) {
      final tripDays = _dayPlanner.planDays(
        pois: optimizedPOIs,
        startLocation: startLocation,
        days: days,
        returnToStart: true,
      );
      updatedDays = tripDays.length;
      newStops = tripDays.expand((day) => day.stops).toList();
    } else {
      newStops = optimizedPOIs.asMap().entries.map((entry) {
        return TripStop.fromPOI(entry.value).copyWith(order: entry.key);
      }).toList();
    }

    final updatedTrip = currentTrip.trip.copyWith(
      name: _generateTripName(optimizedPOIs),
      route: route,
      stops: newStops,
      days: updatedDays,
      updatedAt: DateTime.now(),
    );

    return GeneratedTrip(
      trip: updatedTrip,
      availablePOIs: currentTrip.availablePOIs,
      selectedPOIs: optimizedPOIs,
    );
  }

  /// Fuegt einen POI zu einem bestimmten Tag des Trips hinzu.
  /// Bei Multi-Day: Nur der Zieltag wird modifiziert, andere Tage bleiben erhalten.
  /// Bei Single-Day: POI wird angefuegt und global re-optimiert.
  Future<GeneratedTrip> addPOIToTrip({
    required GeneratedTrip currentTrip,
    required POI newPOI,
    required int targetDay,
    required LatLng startLocation,
    required String startAddress,
  }) async {
    // Multi-Day: Tag-beschraenkte Bearbeitung
    if (currentTrip.trip.actualDays > 1) {
      return _addPOIToDay(
        currentTrip: currentTrip,
        newPOI: newPOI,
        targetDay: targetDay,
        startLocation: startLocation,
        startAddress: startAddress,
      );
    }

    // Single-Day: Globale Re-Optimierung
    final newSelectedPOIs = [...currentTrip.selectedPOIs, newPOI];

    final optimizedPOIs = _routeOptimizer.optimizeRoute(
      pois: newSelectedPOIs,
      startLocation: startLocation,
      returnToStart: true,
    );

    final waypoints = optimizedPOIs.map((p) => p.location).toList();
    final route = await _routingRepo.calculateFastRoute(
      start: startLocation,
      end: startLocation,
      waypoints: waypoints,
      startAddress: startAddress,
      endAddress: startAddress,
    );

    final newStops = optimizedPOIs.asMap().entries.map((entry) {
      return TripStop.fromPOI(entry.value).copyWith(order: entry.key);
    }).toList();

    final updatedTrip = currentTrip.trip.copyWith(
      route: route,
      stops: newStops,
      updatedAt: DateTime.now(),
    );

    return GeneratedTrip(
      trip: updatedTrip,
      availablePOIs: currentTrip.availablePOIs,
      selectedPOIs: optimizedPOIs,
    );
  }

  /// Würfelt einen einzelnen POI neu
  /// Validiert 700km-Limit pro Tag und versucht bei Ueberschreitung andere POIs
  Future<GeneratedTrip> rerollPOI({
    required GeneratedTrip currentTrip,
    required String poiIdToReroll,
    required LatLng startLocation,
    required String startAddress,
    List<POICategory> categories = const [],
  }) async {
    final poiToReplace = currentTrip.selectedPOIs
        .firstWhere((p) => p.id == poiIdToReroll);

    // Multi-Day: Nur den betroffenen Tag modifizieren, andere Tage beibehalten
    if (currentTrip.trip.actualDays > 1) {
      return _rerollPOIForDay(
        currentTrip: currentTrip,
        poiToReplace: poiToReplace,
        poiIdToReroll: poiIdToReroll,
        startLocation: startLocation,
        startAddress: startAddress,
        categories: categories,
      );
    }

    // Single-Day: Globale Re-Optimierung (bestehendes Verhalten)
    // Nachbar-Positionen fuer Distanz-bewusste Auswahl ermitteln
    final currentIndex = currentTrip.selectedPOIs.indexOf(poiToReplace);
    final previousLocation = currentIndex > 0
        ? currentTrip.selectedPOIs[currentIndex - 1].location
        : startLocation;
    final nextLocation = currentIndex < currentTrip.selectedPOIs.length - 1
        ? currentTrip.selectedPOIs[currentIndex + 1].location
        : startLocation;

    // Max Segment = halbe Tagesbudget (ein Segment soll nicht den ganzen Tag verbrauchen)
    final maxSegmentKm = TripConstants.maxKmPerDay / 2;

    final triedPOIIds = <String>{poiIdToReroll};
    GeneratedTrip? lastResult;
    final days = currentTrip.trip.actualDays;
    const maxRetries = 3;

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      // POIs die bereits probiert wurden herausfiltern
      final filteredAvailable = currentTrip.availablePOIs
          .where((p) => !triedPOIIds.contains(p.id))
          .toList();

      // Neuen POI auswählen (Attempt 0: mit Distanz-Constraint, danach ohne)
      final newPOI = _poiSelector.rerollSinglePOI(
        availablePOIs: filteredAvailable,
        currentSelection: currentTrip.selectedPOIs,
        poiToReplace: poiToReplace,
        startLocation: startLocation,
        preferredCategories: categories,
        previousLocation: previousLocation,
        nextLocation: nextLocation,
        maxSegmentKm: attempt == 0 ? maxSegmentKm : null,
      );

      if (newPOI == null) {
        if (lastResult != null) {
          debugPrint('[TripGenerator] Reroll: Keine weiteren POIs verfuegbar, nutze letztes Ergebnis');
          return lastResult;
        }
        throw TripGenerationException('Kein alternativer POI verfügbar');
      }

      triedPOIIds.add(newPOI.id);

      // Neue POI-Liste erstellen
      final newSelectedPOIs = currentTrip.selectedPOIs.map((p) {
        return p.id == poiIdToReroll ? newPOI : p;
      }).toList();

      // Route neu optimieren
      final optimizedPOIs = _routeOptimizer.optimizeRoute(
        pois: newSelectedPOIs,
        startLocation: startLocation,
        returnToStart: true,
      );

      // Neue Route berechnen
      final waypoints = optimizedPOIs.map((p) => p.location).toList();
      final route = await _routingRepo.calculateFastRoute(
        start: startLocation,
        end: startLocation,
        waypoints: waypoints,
        startAddress: startAddress,
        endAddress: startAddress,
      );

      // Trip aktualisieren - bei Mehrtages-Trips Tagesplanung wiederholen
      List<TripStop> newStops;
      int updatedDays = days;
      if (days > 1) {
        final tripDays = _dayPlanner.planDays(
          pois: optimizedPOIs,
          startLocation: startLocation,
          days: days,
          returnToStart: true,
        );
        updatedDays = tripDays.length;
        newStops = tripDays.expand((day) => day.stops).toList();
      } else {
        newStops = optimizedPOIs.asMap().entries.map((entry) {
          return TripStop.fromPOI(entry.value).copyWith(order: entry.key);
        }).toList();
      }

      final updatedTrip = currentTrip.trip.copyWith(
        route: route,
        stops: newStops,
        days: updatedDays,
        updatedAt: DateTime.now(),
      );

      final result = GeneratedTrip(
        trip: updatedTrip,
        availablePOIs: currentTrip.availablePOIs,
        selectedPOIs: optimizedPOIs,
      );

      // 700km-Validierung: kein Tag darf maxDisplayKmPerDay ueberschreiten
      if (days > 1) {
        bool anyDayOverLimit = false;
        for (int d = 1; d <= updatedDays; d++) {
          final displayKm = updatedTrip.getDistanceForDay(d);
          if (displayKm > TripConstants.maxDisplayKmPerDay) {
            anyDayOverLimit = true;
            debugPrint('[TripGenerator] Reroll Versuch $attempt: Tag $d = ${displayKm.toStringAsFixed(0)}km > ${TripConstants.maxDisplayKmPerDay.toStringAsFixed(0)}km Limit');
            break;
          }
        }

        lastResult = result;

        if (!anyDayOverLimit) {
          debugPrint('[TripGenerator] Reroll Versuch $attempt: Alle Tage unter ${TripConstants.maxDisplayKmPerDay.toStringAsFixed(0)}km Limit');
          return result;
        }

        // Naechster Versuch mit anderem POI
        continue;
      }

      // Single-Day Trip: kein Tages-Check noetig
      return result;
    }

    // Alle Versuche fehlgeschlagen: bestes Ergebnis zurueckgeben
    debugPrint('[TripGenerator] WARNING: ${TripConstants.maxDisplayKmPerDay.toStringAsFixed(0)}km Limit nach $maxRetries Versuchen nicht erreicht');
    return lastResult!;
  }

  // ===== Multi-Day: Tag-beschraenkte POI-Bearbeitung =====

  /// Bestimmt den Start-Punkt eines Tages (letzter Stop des Vortages)
  LatLng _getDayStartLocation(Trip trip, int day, LatLng tripStart) {
    if (day == 1) return tripStart;
    final prevStops = trip.getStopsForDay(day - 1);
    return prevStops.isNotEmpty ? prevStops.last.location : tripStart;
  }

  /// Baut Route und Trip nach einer Tag-Bearbeitung neu auf.
  /// Alle Stops werden in Tag/Order-Reihenfolge sortiert und OSRM-Route berechnet.
  /// Andere Tage bleiben vollstaendig erhalten.
  Future<GeneratedTrip> _rebuildRouteForDayEdit({
    required GeneratedTrip currentTrip,
    required List<TripStop> allStops,
    required LatLng startLocation,
    required String startAddress,
  }) async {
    // Stops sortieren nach Tag + Order
    final sortedStops = List<TripStop>.from(allStops);
    sortedStops.sort((a, b) {
      final dayCompare = a.day.compareTo(b.day);
      if (dayCompare != 0) return dayCompare;
      return a.order.compareTo(b.order);
    });

    // Waypoints in Tag-Reihenfolge fuer OSRM
    final waypoints = sortedStops.map((s) => s.location).toList();

    // OSRM-Route berechnen
    final route = await _routingRepo.calculateFastRoute(
      start: startLocation,
      end: startLocation,
      waypoints: waypoints,
      startAddress: startAddress,
      endAddress: startAddress,
    );

    // selectedPOIs aus geordneten Stops rekonstruieren
    final newSelectedPOIs = sortedStops.map((s) => s.toPOI()).toList();

    final updatedTrip = currentTrip.trip.copyWith(
      route: route,
      stops: sortedStops,
      updatedAt: DateTime.now(),
    );

    return GeneratedTrip(
      trip: updatedTrip,
      availablePOIs: currentTrip.availablePOIs,
      selectedPOIs: newSelectedPOIs,
    );
  }

  /// Entfernt einen POI nur aus dem betroffenen Tag (Multi-Day).
  /// Andere Tage bleiben vollstaendig erhalten.
  Future<GeneratedTrip> _removePOIFromDay({
    required GeneratedTrip currentTrip,
    required String poiIdToRemove,
    required LatLng startLocation,
    required String startAddress,
  }) async {
    // Tag des zu loeschenden POIs ermitteln
    final stopToRemove = currentTrip.trip.stops.firstWhere(
      (s) => s.poiId == poiIdToRemove,
      orElse: () => throw TripGenerationException('POI nicht im Trip gefunden'),
    );
    final targetDay = stopToRemove.day;

    // Pruefen: Tag muss nach Entfernung mindestens 1 Stop haben
    final dayStops = currentTrip.trip.getStopsForDay(targetDay);
    if (dayStops.length <= 1) {
      throw TripGenerationException(
        'Mindestens 1 Stop pro Tag erforderlich',
      );
    }

    debugPrint('[TripGenerator] RemovePOI Tag $targetDay: Entferne ${stopToRemove.name}');

    // Andere Tage unverändert beibehalten
    final otherDaysStops = currentTrip.trip.stops
        .where((s) => s.day != targetDay)
        .toList();

    // Modifizierter Tag: POI entfernen und Reihenfolge neu optimieren
    final modifiedDayPOIs = dayStops
        .where((s) => s.poiId != poiIdToRemove)
        .map((s) => s.toPOI())
        .toList();

    final dayStart = _getDayStartLocation(currentTrip.trip, targetDay, startLocation);

    final optimizedDayPOIs = _routeOptimizer.optimizeRoute(
      pois: modifiedDayPOIs,
      startLocation: dayStart,
      returnToStart: false,
    );

    // Neue Stops fuer diesen Tag mit korrekter Order
    final newDayStops = optimizedDayPOIs.asMap().entries.map((entry) {
      return TripStop.fromPOI(entry.value).copyWith(
        day: targetDay,
        order: entry.key,
      );
    }).toList();

    debugPrint('[TripGenerator] RemovePOI Tag $targetDay: ${newDayStops.length} Stops verbleibend');

    // Alle Stops zusammenfuehren und Route neu berechnen
    final result = await _rebuildRouteForDayEdit(
      currentTrip: currentTrip,
      allStops: [...otherDaysStops, ...newDayStops],
      startLocation: startLocation,
      startAddress: startAddress,
    );

    // Post-Validierung: Display-Distanz des modifizierten Tages prüfen
    final dayDisplayKm = result.trip.getDistanceForDay(targetDay);
    if (dayDisplayKm > TripConstants.maxDisplayKmPerDay) {
      debugPrint('[TripGenerator] ⚠️ WARNING: RemovePOI Tag $targetDay = ~${dayDisplayKm.toStringAsFixed(0)}km Display > ${TripConstants.maxDisplayKmPerDay.toStringAsFixed(0)}km Limit');
    }

    return result;
  }

  /// Fuegt einen POI zu einem bestimmten Tag hinzu (Multi-Day).
  /// Andere Tage bleiben vollstaendig erhalten.
  Future<GeneratedTrip> _addPOIToDay({
    required GeneratedTrip currentTrip,
    required POI newPOI,
    required int targetDay,
    required LatLng startLocation,
    required String startAddress,
  }) async {
    final trip = currentTrip.trip;

    // Alle Stops anderer Tage beibehalten
    final otherDaysStops = trip.stops
        .where((s) => s.day != targetDay)
        .toList();

    // Aktuelle Stops des Zieltages
    final dayStops = trip.getStopsForDay(targetDay);
    final dayStart = _getDayStartLocation(trip, targetDay, startLocation);

    debugPrint('[TripGenerator] AddPOI Tag $targetDay: Fuege ${newPOI.name} hinzu');

    // Alle Day-POIs inkl. neuem POI
    final allDayPOIs = [
      ...dayStops.map((s) => s.toPOI()),
      newPOI,
    ];

    // Tag re-optimieren (Nearest-Neighbor + 2-opt)
    final optimizedDayPOIs = _routeOptimizer.optimizeRoute(
      pois: allDayPOIs,
      startLocation: dayStart,
      returnToStart: false,
    );

    // Neue Stops fuer diesen Tag mit korrekter Order
    final newDayStops = optimizedDayPOIs.asMap().entries.map((entry) {
      return TripStop.fromPOI(entry.value).copyWith(
        day: targetDay,
        order: entry.key,
      );
    }).toList();

    debugPrint('[TripGenerator] AddPOI Tag $targetDay: ${newDayStops.length} Stops total');

    // Alle Stops zusammenfuehren und Route neu berechnen
    final result = await _rebuildRouteForDayEdit(
      currentTrip: currentTrip,
      allStops: [...otherDaysStops, ...newDayStops],
      startLocation: startLocation,
      startAddress: startAddress,
    );

    // Post-Validierung: Bei >700km Display-Distanz den POI ablehnen
    final dayDisplayKm = result.trip.getDistanceForDay(targetDay);
    if (dayDisplayKm > TripConstants.maxDisplayKmPerDay) {
      debugPrint('[TripGenerator] REJECTED: AddPOI Tag $targetDay = ~${dayDisplayKm.toStringAsFixed(0)}km Display > ${TripConstants.maxDisplayKmPerDay.toStringAsFixed(0)}km Limit');
      throw TripGenerationException(
        'Tag $targetDay wuerde ~${dayDisplayKm.toStringAsFixed(0)}km ueberschreiten (max ${TripConstants.maxDisplayKmPerDay.toStringAsFixed(0)}km)',
      );
    }

    return result;
  }

  /// Wuerfelt einen POI nur innerhalb des betroffenen Tages neu (Multi-Day).
  /// Andere Tage bleiben vollstaendig erhalten.
  Future<GeneratedTrip> _rerollPOIForDay({
    required GeneratedTrip currentTrip,
    required POI poiToReplace,
    required String poiIdToReroll,
    required LatLng startLocation,
    required String startAddress,
    List<POICategory> categories = const [],
  }) async {
    // Tag des zu ersetzenden POIs ermitteln
    final stopToReroll = currentTrip.trip.stops.firstWhere(
      (s) => s.poiId == poiIdToReroll,
    );
    final targetDay = stopToReroll.day;
    final dayStops = currentTrip.trip.getStopsForDay(targetDay);
    final dayStart = _getDayStartLocation(currentTrip.trip, targetDay, startLocation);

    debugPrint('[TripGenerator] RerollPOI Tag $targetDay: Ersetze ${poiToReplace.name}');

    // Nachbar-Positionen innerhalb des Tages (nicht global)
    final dayStopIndex = dayStops.indexWhere((s) => s.poiId == poiIdToReroll);
    final previousLocation = dayStopIndex > 0
        ? dayStops[dayStopIndex - 1].location
        : dayStart;

    LatLng nextLocation;
    if (dayStopIndex < dayStops.length - 1) {
      nextLocation = dayStops[dayStopIndex + 1].location;
    } else if (targetDay < currentTrip.trip.actualDays) {
      // Letzter Stop des Tages: Richtung naechster Tag
      final nextDayStops = currentTrip.trip.getStopsForDay(targetDay + 1);
      nextLocation = nextDayStops.isNotEmpty
          ? nextDayStops.first.location
          : startLocation;
    } else {
      // Letzter Stop des letzten Tages: Richtung Start (Rueckreise)
      nextLocation = startLocation;
    }

    final maxSegmentKm = TripConstants.maxKmPerDay / 2;
    final triedPOIIds = <String>{poiIdToReroll};
    GeneratedTrip? lastResult;
    const maxRetries = 3;

    // Andere Tage unverändert beibehalten
    final otherDaysStops = currentTrip.trip.stops
        .where((s) => s.day != targetDay)
        .toList();

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      // Verfuegbare POIs filtern (bereits probierte ausschliessen)
      final filteredAvailable = currentTrip.availablePOIs
          .where((p) => !triedPOIIds.contains(p.id))
          .toList();

      // Neuen POI auswaehlen (Tag-bewusste Distanz-Beschraenkung)
      final newPOI = _poiSelector.rerollSinglePOI(
        availablePOIs: filteredAvailable,
        currentSelection: currentTrip.selectedPOIs,
        poiToReplace: poiToReplace,
        startLocation: startLocation,
        preferredCategories: categories,
        previousLocation: previousLocation,
        nextLocation: nextLocation,
        maxSegmentKm: attempt == 0 ? maxSegmentKm : null,
      );

      if (newPOI == null) {
        if (lastResult != null) {
          debugPrint('[TripGenerator] Reroll Tag $targetDay: Keine weiteren POIs, nutze letztes Ergebnis');
          return lastResult;
        }
        throw TripGenerationException('Kein alternativer POI verfügbar');
      }

      triedPOIIds.add(newPOI.id);

      // POI nur in diesem Tag ersetzen
      final modifiedDayPOIs = dayStops.map((s) {
        return s.poiId == poiIdToReroll ? newPOI : s.toPOI();
      }).toList();

      // Nur diesen Tag re-optimieren
      final optimizedDayPOIs = _routeOptimizer.optimizeRoute(
        pois: modifiedDayPOIs,
        startLocation: dayStart,
        returnToStart: false,
      );

      // Neue Stops fuer diesen Tag
      final newDayStops = optimizedDayPOIs.asMap().entries.map((entry) {
        return TripStop.fromPOI(entry.value).copyWith(
          day: targetDay,
          order: entry.key,
        );
      }).toList();

      // Route neu berechnen
      final result = await _rebuildRouteForDayEdit(
        currentTrip: currentTrip,
        allStops: [...otherDaysStops, ...newDayStops],
        startLocation: startLocation,
        startAddress: startAddress,
      );

      // Tages-Distanz validieren
      final dayDisplayKm = result.trip.getDistanceForDay(targetDay);
      if (dayDisplayKm > TripConstants.maxDisplayKmPerDay) {
        debugPrint('[TripGenerator] Reroll Tag $targetDay Versuch $attempt: ${dayDisplayKm.toStringAsFixed(0)}km > ${TripConstants.maxDisplayKmPerDay.toStringAsFixed(0)}km Limit');
        lastResult = result;
        continue;
      }

      debugPrint('[TripGenerator] Reroll Tag $targetDay Versuch $attempt: ${dayDisplayKm.toStringAsFixed(0)}km OK');
      return result;
    }

    // Alle Versuche fehlgeschlagen: bestes Ergebnis zurueckgeben
    debugPrint('[TripGenerator] WARNING: Distanz-Limit nach $maxRetries Versuchen nicht erreicht (Tag $targetDay)');
    return lastResult!;
  }

  /// Lädt POIs entlang eines Korridors (Start→Ziel mit Buffer)
  /// Berechnet eine Direct-Route und sucht POIs in der Bounding Box
  Future<List<POI>> _loadPOIsAlongCorridor({
    required LatLng start,
    required LatLng end,
    required double bufferKm,
    List<String>? categoryFilter,
  }) async {
    // 1. Direct-Route berechnen (für genaue Korridor-Box)
    debugPrint('[TripGenerator] Berechne Direct-Route für Korridor...');
    final directRoute = await _routingRepo.calculateFastRoute(
      start: start,
      end: end,
      startAddress: '',
      endAddress: '',
    );

    // 2. Bounding Box entlang der Route mit Buffer
    final bounds = GeoUtils.calculateBoundsWithBuffer(
      directRoute.coordinates,
      bufferKm,
    );

    debugPrint('[TripGenerator] Korridor-Bounds: SW(${bounds.southwest.latitude.toStringAsFixed(2)}, ${bounds.southwest.longitude.toStringAsFixed(2)}) → NE(${bounds.northeast.latitude.toStringAsFixed(2)}, ${bounds.northeast.longitude.toStringAsFixed(2)})');

    // 3. POIs in der Box laden
    return await _poiRepo.loadPOIsInBounds(
      bounds: bounds,
      categoryFilter: categoryFilter,
    );
  }

  /// Generiert Trip-Namen basierend auf POIs
  String _generateTripName(List<POI> pois) {
    if (pois.isEmpty) return 'Tagesausflug';

    // Highlight finden (Must-See oder höchster Score)
    final highlight = pois.where((p) => p.isMustSee).firstOrNull ??
        pois.reduce((a, b) => a.score > b.score ? a : b);

    return 'Ausflug: ${highlight.name}';
  }

  /// Generiert Euro Trip-Namen
  String _generateEuroTripName(List<TripDay> days) {
    if (days.isEmpty) return 'Euro Trip';

    // Highlights aller Tage sammeln
    final highlights = <String>[];
    for (final day in days) {
      if (day.stops.isNotEmpty) {
        highlights.add(day.stops.first.name);
        if (highlights.length >= 2) break;
      }
    }

    if (highlights.isEmpty) return 'Euro Trip ${days.length} Tage';

    return '${days.length}-Tage-Trip: ${highlights.join(' → ')}';
  }
}

/// Ergebnis der Trip-Generierung
class GeneratedTrip {
  final Trip trip;
  final List<POI> availablePOIs;
  final List<POI> selectedPOIs;
  final List<TripDay>? tripDays;
  final List<List<HotelSuggestion>>? hotelSuggestions;

  GeneratedTrip({
    required this.trip,
    required this.availablePOIs,
    required this.selectedPOIs,
    this.tripDays,
    this.hotelSuggestions,
  });

  /// Ist Mehrtages-Trip
  bool get isMultiDay => trip.days > 1;

  /// Hat Hotel-Vorschläge
  bool get hasHotelSuggestions =>
      hotelSuggestions != null && hotelSuggestions!.any((list) => list.isNotEmpty);
}

/// Trip-Generierungs-Fehler
class TripGenerationException implements Exception {
  final String message;
  TripGenerationException(this.message);

  @override
  String toString() => 'TripGenerationException: $message';
}

/// Riverpod Provider für TripGeneratorRepository
@riverpod
TripGeneratorRepository tripGeneratorRepository(TripGeneratorRepositoryRef ref) {
  return TripGeneratorRepository();
}
