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
    final categoryIds =
        categories.isNotEmpty ? categories.map((c) => c.id).toList() : null;

    List<POI> availablePOIs;
    if (hasDestination) {
      debugPrint(
          '[TripGenerator] Tagestrip Korridor-Modus: $startAddress → $endAddress, ${radiusKm}km Breite');
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
    availablePOIs =
        availablePOIs.where((poi) => poi.categoryId != 'hotel').toList();

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

    // 4. Radius als harte Distanzgrenze fuer Tagestrip anwenden.
    // Vorher wurde radiusKm nur fuer die POI-Suche genutzt.
    final constrainedPOIs = _routeOptimizer.trimRouteToMaxDistance(
      pois: optimizedPOIs,
      startLocation: startLocation,
      maxDistanceKm: radiusKm,
      returnToStart: !hasDestination,
    );

    if (constrainedPOIs.isEmpty) {
      throw TripGenerationException(
        'Keine Route innerhalb von ${radiusKm.round()}km moeglich. '
        'Bitte Distanz erhoehen oder Start/Ziel anpassen.',
      );
    }

    if (constrainedPOIs.length < optimizedPOIs.length) {
      debugPrint(
        '[TripGenerator] Tagestrip auf Distanzlimit gekuerzt: '
        '${optimizedPOIs.length} -> ${constrainedPOIs.length} POIs '
        '(max ${radiusKm.toStringAsFixed(0)}km)',
      );
    }

    // 5. Echte Route berechnen
    final waypoints = constrainedPOIs.map((p) => p.location).toList();
    final route = await _routingRepo.calculateFastRoute(
      start: startLocation,
      end: endLocation,
      waypoints: waypoints,
      startAddress: startAddress,
      endAddress: endAddress,
    );

    // 6. Trip erstellen
    final trip = Trip(
      id: _uuid.v4(),
      name: _generateTripName(constrainedPOIs),
      type: TripType.daytrip,
      route: route,
      stops: constrainedPOIs.asMap().entries.map((entry) {
        return TripStop.fromPOI(entry.value).copyWith(order: entry.key);
      }).toList(),
      days: 1,
      createdAt: DateTime.now(),
      preferredCategories: categories.map((c) => c.id).toList(),
    );

    return GeneratedTrip(
      trip: trip,
      availablePOIs: availablePOIs,
      selectedPOIs: constrainedPOIs,
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
    DateTime? tripStartDate,
  }) async {
    final hasDestination = destinationLocation != null;
    final endLocation = destinationLocation ?? startLocation;
    final endAddress = destinationAddress ?? startAddress;

    final effectiveDays =
        days ?? TripConstants.calculateDaysFromDistance(radiusKm);
    debugPrint(
        '[TripGenerator] ===============================================');
    debugPrint('[TripGenerator] EURO TRIP START');
    debugPrint('[TripGenerator] Tage: $effectiveDays, Radius: ${radiusKm}km');
    debugPrint(
        '[TripGenerator] Start: $startAddress (${startLocation.latitude}, ${startLocation.longitude})');
    debugPrint(
        '[TripGenerator] Modus: ${hasDestination ? 'A->B ($endAddress)' : 'Rundreise'}');
    debugPrint(
        '[TripGenerator] ===============================================');

    final poisPerDay = min(
      DayPlanner.estimatePoisPerDay(),
      TripConstants.maxPoisPerDay,
    );
    final totalPOIs = effectiveDays * poisPerDay;
    debugPrint('[TripGenerator] POIs: $poisPerDay pro Tag, $totalPOIs gesamt');

    final categoryIds =
        categories.isNotEmpty ? categories.map((c) => c.id).toList() : null;

    List<POI> availablePOIs;
    if (hasDestination) {
      debugPrint(
          '[TripGenerator] Euro Trip Korridor-Modus: $startAddress -> $endAddress, ${radiusKm}km Breite');
      availablePOIs = await _loadPOIsAlongCorridor(
        start: startLocation,
        end: destinationLocation!,
        bufferKm: radiusKm,
        categoryFilter: categoryIds,
      ).timeout(
        const Duration(seconds: 45),
        onTimeout: () {
          debugPrint(
              '[TripGenerator] [WARN] Korridor POI-Laden Timeout nach 45s');
          return <POI>[];
        },
      );
    } else {
      availablePOIs = await _poiRepo
          .loadPOIsInRadius(
        center: startLocation,
        radiusKm: radiusKm,
        categoryFilter: categoryIds,
      )
          .timeout(
        const Duration(seconds: 45),
        onTimeout: () {
          debugPrint('[TripGenerator] [WARN] POI-Laden Timeout nach 45s');
          return <POI>[];
        },
      );
    }

    debugPrint('[TripGenerator] ${availablePOIs.length} POIs gefunden');

    availablePOIs =
        availablePOIs.where((poi) => poi.categoryId != 'hotel').toList();

    if (availablePOIs.isEmpty) {
      throw TripGenerationException(
        hasDestination
            ? 'Keine POIs entlang der Route $startAddress -> $endAddress gefunden'
            : 'Keine POIs im Umkreis von ${radiusKm}km gefunden. '
                'Versuche einen anderen Startpunkt oder kleineren Radius.',
      );
    }

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

    debugPrint(
        '[TripGenerator] SCHRITT 2-4: Auswahl + Optimierung + Tagesplanung ($effectiveDays Tage, max $totalPOIs POIs)...');
    List<POI> selectedPOIs = const [];
    List<POI> optimizedPOIs = const [];
    List<TripDay> tripDays = const [];
    var actualDays = effectiveDays;
    List<DayLimitViolation> lastViolations = const [];

    const maxPlanningAttempts = 6;
    for (int attempt = 1; attempt <= maxPlanningAttempts; attempt++) {
      selectedPOIs = _poiSelector.selectRandomPOIs(
        pois: availablePOIs,
        startLocation: startLocation,
        count: totalPOIs,
        preferredCategories: categories,
        maxPerCategory: 3,
      );
      if (selectedPOIs.isEmpty) {
        continue;
      }

      if (hasDestination) {
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

      tripDays = _dayPlanner.planDays(
        pois: optimizedPOIs,
        startLocation: startLocation,
        days: effectiveDays,
        returnToStart: !hasDestination,
        endLocation: hasDestination ? endLocation : null,
      );
      actualDays = tripDays.length;

      lastViolations = _dayPlanner.validateDayLimits(
        tripDays: tripDays,
        tripStart: startLocation,
        returnToStart: !hasDestination,
        tripEnd: hasDestination ? endLocation : null,
      );
      if (lastViolations.isEmpty) {
        debugPrint(
            '[TripGenerator] SCHRITT 2-4 OK (Versuch $attempt): ${optimizedPOIs.length} POIs, $actualDays Tage');
        break;
      }

      debugPrint(
          '[TripGenerator] Versuch $attempt: ${lastViolations.length} Tageslimit-Verletzungen erkannt');
      for (final violation in lastViolations) {
        debugPrint(
            '[TripGenerator]   Tag ${violation.dayNumber}: ~${violation.displayKm.toStringAsFixed(0)}km (Grund: ${violation.reason})');
      }
    }

    if (selectedPOIs.isEmpty || optimizedPOIs.isEmpty || tripDays.isEmpty) {
      throw TripGenerationException('Keine passenden POIs gefunden');
    }

    if (lastViolations.isNotEmpty) {
      final first = lastViolations.first;
      throw TripGenerationException(
        'Tageslimit (700km) kann mit den verfuegbaren POIs nicht eingehalten werden. '
        'Problematisch: Tag ${first.dayNumber} (~${first.displayKm.toStringAsFixed(0)}km).',
      );
    }

    debugPrint(
        '[TripGenerator] SCHRITT 5: Hotel-Suche (${includeHotels && actualDays > 1 ? 'aktiv' : 'uebersprungen'})...');
    List<List<HotelSuggestion>> hotelSuggestions = [];
    if (includeHotels && actualDays > 1) {
      final overnightLocations = _dayPlanner.calculateOvernightLocations(
        tripDays: tripDays,
        startLocation: startLocation,
      );
      debugPrint(
          '[TripGenerator] ${overnightLocations.length} Uebernachtungsorte ermittelt');

      hotelSuggestions = await _hotelService.searchHotelsForMultipleLocations(
        locations: overnightLocations,
        radiusKm: 20,
        limitPerLocation: 5,
        tripStartDate: tripStartDate,
      );
      hotelSuggestions = _dedupeHotelsAcrossDays(hotelSuggestions);
      debugPrint(
          '[TripGenerator] Hotel-Suche abgeschlossen: ${hotelSuggestions.where((l) => l.isNotEmpty).length} Standorte mit Hotels');

      final hotelStops = hotelSuggestions
          .where((list) => list.isNotEmpty)
          .map((list) => _hotelService.convertToTripStops([list.first]).first)
          .toList();

      tripDays = _dayPlanner.addOvernightStops(
        tripDays: tripDays,
        hotelStops: hotelStops,
      );

      final postHotelViolations = _dayPlanner.validateDayLimits(
        tripDays: tripDays,
        tripStart: startLocation,
        returnToStart: !hasDestination,
        tripEnd: hasDestination ? endLocation : null,
      );
      if (postHotelViolations.isNotEmpty) {
        final first = postHotelViolations.first;
        throw TripGenerationException(
          'Tageslimit (700km) wird nach Hotel-Integration verletzt '
          '(Tag ${first.dayNumber}, ~${first.displayKm.toStringAsFixed(0)}km).',
        );
      }
    }
    debugPrint('[TripGenerator] SCHRITT 5 OK');

    debugPrint('[TripGenerator] SCHRITT 6: OSRM Route-Berechnung...');
    final allWaypoints = <LatLng>[];
    for (final day in tripDays) {
      for (final stop in day.stops) {
        allWaypoints.add(stop.location);
      }
    }

    debugPrint('[TripGenerator] ${allWaypoints.length} Waypoints fuer OSRM...');

    final route = await _routingRepo.calculateFastRoute(
      start: startLocation,
      end: endLocation,
      waypoints: allWaypoints,
      startAddress: startAddress,
      endAddress: endAddress,
    );

    debugPrint(
        '[TripGenerator] SCHRITT 6 OK: ${route.distanceKm.toStringAsFixed(0)}km, ${route.coordinates.length} Koordinaten');

    debugPrint('[TripGenerator] SCHRITT 7: Trip-Objekt erstellen...');
    final allStops = tripDays.expand((day) => day.stops).toList();

    final trip = Trip(
      id: _uuid.v4(),
      name: _generateEuroTripName(tripDays),
      type: TripType.eurotrip,
      route: route,
      stops: allStops,
      days: actualDays,
      startDate: tripStartDate,
      createdAt: DateTime.now(),
      preferredCategories: categories.map((c) => c.id).toList(),
    );

    debugPrint(
        '[TripGenerator] SCHRITT 7 OK: Trip "${trip.name}" mit ${allStops.length} Stops erstellt');
    debugPrint(
        '[TripGenerator] ===============================================');
    debugPrint('[TripGenerator] EURO TRIP ERFOLGREICH ABGESCHLOSSEN');
    debugPrint(
        '[TripGenerator] ===============================================');

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
    final newSelectedPOIs =
        currentTrip.selectedPOIs.where((p) => p.id != poiIdToRemove).toList();

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

    final result = GeneratedTrip(
      trip: updatedTrip,
      availablePOIs: currentTrip.availablePOIs,
      selectedPOIs: optimizedPOIs,
    );
    _validateHardDayLimitOrThrow(
      trip: result.trip,
      tripStart: startLocation,
      contextLabel: 'remove_poi',
    );
    return result;
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

    final result = GeneratedTrip(
      trip: updatedTrip,
      availablePOIs: currentTrip.availablePOIs,
      selectedPOIs: optimizedPOIs,
    );
    _validateHardDayLimitOrThrow(
      trip: result.trip,
      tripStart: startLocation,
      contextLabel: 'add_poi',
    );
    return result;
  }

  /// Ersetzt den Uebernachtungs-Stop eines Tages mit einem ausgewaehlten Hotel.
  /// Tag-Index ist 0-basiert (Index 0 = Uebernachtung nach Tag 1).
  Future<GeneratedTrip> applySelectedHotelForDay({
    required GeneratedTrip currentTrip,
    required int dayIndex,
    required HotelSuggestion hotel,
    required LatLng startLocation,
    required String startAddress,
  }) async {
    final dayNumber = dayIndex + 1;
    final totalDays = currentTrip.trip.actualDays;
    if (dayNumber < 1 || dayNumber >= totalDays) {
      throw TripGenerationException(
        'Ungueltiger Hotel-Tag: $dayNumber von $totalDays',
      );
    }

    final otherStops =
        currentTrip.trip.stops.where((s) => s.day != dayNumber).toList();
    final dayStops = _normalizeDayStopsForHotelSelection(
      currentTrip.trip.getStopsForDay(dayNumber),
      dayNumber: dayNumber,
    );
    final hotelStop = _hotelService.convertToTripStops([hotel]).first.copyWith(
          day: dayNumber,
          order: dayStops.length,
          isOvernightStop: true,
        );

    final rebuilt = await _rebuildRouteForDayEdit(
      currentTrip: currentTrip,
      allStops: [...otherStops, ...dayStops, hotelStop],
      startLocation: startLocation,
      startAddress: startAddress,
    );

    _validateHardDayLimitOrThrow(
      trip: rebuilt.trip,
      tripStart: startLocation,
      contextLabel: 'select_hotel',
    );

    final existingSuggestions = currentTrip.hotelSuggestions ?? const [];
    final updatedSuggestions = List<List<HotelSuggestion>>.generate(
      existingSuggestions.length,
      (index) {
        final current = existingSuggestions[index];
        if (index != dayIndex) return current;
        final withoutSelected = current.where((h) => h.id != hotel.id).toList();
        return [hotel, ...withoutSelected];
      },
    );

    return GeneratedTrip(
      trip: rebuilt.trip,
      availablePOIs: rebuilt.availablePOIs,
      selectedPOIs: rebuilt.selectedPOIs,
      tripDays: _extractTripDaysFromTrip(rebuilt.trip),
      hotelSuggestions: updatedSuggestions,
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
    final poiToReplace =
        currentTrip.selectedPOIs.firstWhere((p) => p.id == poiIdToReroll);

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
        break;
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

      final newStops = optimizedPOIs.asMap().entries.map((entry) {
        return TripStop.fromPOI(entry.value).copyWith(order: entry.key);
      }).toList();

      final updatedTrip = currentTrip.trip.copyWith(
        route: route,
        stops: newStops,
        days: 1,
        updatedAt: DateTime.now(),
      );

      final result = GeneratedTrip(
        trip: updatedTrip,
        availablePOIs: currentTrip.availablePOIs,
        selectedPOIs: optimizedPOIs,
      );

      try {
        _validateHardDayLimitOrThrow(
          trip: result.trip,
          tripStart: startLocation,
          contextLabel: 'reroll_poi',
        );
        return result;
      } on TripGenerationException {
        if (attempt == maxRetries - 1) {
          rethrow;
        }
        continue;
      }
    }

    throw TripGenerationException(
        'Kein alternativer POI gefunden, der das Tageslimit einhaelt');
  }

  // ===== Multi-Day: Tag-beschraenkte POI-Bearbeitung =====

  /// Bestimmt den Start-Punkt eines Tages (letzter Stop des Vortages)
  LatLng _getDayStartLocation(Trip trip, int day, LatLng tripStart) {
    if (day <= 1) return tripStart;
    return trip.getDayStartLocation(day);
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
    final tripEnd = currentTrip.trip.route.end;
    final tripEndAddress = currentTrip.trip.route.endAddress;
    final route = await _routingRepo.calculateFastRoute(
      start: startLocation,
      end: tripEnd,
      waypoints: waypoints,
      startAddress: startAddress,
      endAddress: tripEndAddress,
    );

    // selectedPOIs aus geordneten Stops rekonstruieren
    final newSelectedPOIs = sortedStops
        .where((s) => !s.isOvernightStop && s.categoryId != 'hotel')
        .map((s) => s.toPOI())
        .toList();

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
    final dayPoiStops = currentTrip.trip
        .getStopsForDay(targetDay)
        .where((s) => !s.isOvernightStop && s.categoryId != 'hotel')
        .toList();
    if (dayPoiStops.where((s) => s.poiId != poiIdToRemove).isEmpty) {
      throw TripGenerationException(
        'Mindestens 1 Stop pro Tag erforderlich',
      );
    }

    debugPrint(
        '[TripGenerator] RemovePOI Tag $targetDay: Entferne ${stopToRemove.name}');

    // Andere Tage unverändert beibehalten
    final otherDaysStops =
        currentTrip.trip.stops.where((s) => s.day != targetDay).toList();

    // Modifizierter Tag: POI entfernen und Reihenfolge neu optimieren
    final modifiedDayPOIs = dayPoiStops
        .where((s) => s.poiId != poiIdToRemove)
        .map((s) => s.toPOI())
        .toList();

    final dayStart =
        _getDayStartLocation(currentTrip.trip, targetDay, startLocation);

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

    debugPrint(
        '[TripGenerator] RemovePOI Tag $targetDay: ${newDayStops.length} Stops verbleibend');

    // Alle Stops zusammenfuehren und Route neu berechnen
    final result = await _rebuildRouteForDayEdit(
      currentTrip: currentTrip,
      allStops: [...otherDaysStops, ...newDayStops],
      startLocation: startLocation,
      startAddress: startAddress,
    );

    _validateHardDayLimitOrThrow(
      trip: result.trip,
      tripStart: startLocation,
      contextLabel: 'remove_poi_day',
    );
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
    final otherDaysStops = trip.stops.where((s) => s.day != targetDay).toList();

    // Aktuelle Stops des Zieltages
    final dayStops = trip
        .getStopsForDay(targetDay)
        .where((s) => !s.isOvernightStop && s.categoryId != 'hotel')
        .toList();
    final dayStart = _getDayStartLocation(trip, targetDay, startLocation);

    debugPrint(
        '[TripGenerator] AddPOI Tag $targetDay: Fuege ${newPOI.name} hinzu');

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

    debugPrint(
        '[TripGenerator] AddPOI Tag $targetDay: ${newDayStops.length} Stops total');

    // Alle Stops zusammenfuehren und Route neu berechnen
    final result = await _rebuildRouteForDayEdit(
      currentTrip: currentTrip,
      allStops: [...otherDaysStops, ...newDayStops],
      startLocation: startLocation,
      startAddress: startAddress,
    );

    _validateHardDayLimitOrThrow(
      trip: result.trip,
      tripStart: startLocation,
      contextLabel: 'add_poi_day',
    );
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
    final dayAllStops = currentTrip.trip.getStopsForDay(targetDay);
    final dayStops = dayAllStops
        .where((s) => !s.isOvernightStop && s.categoryId != 'hotel')
        .toList();
    final dayStart =
        _getDayStartLocation(currentTrip.trip, targetDay, startLocation);

    debugPrint(
        '[TripGenerator] RerollPOI Tag $targetDay: Ersetze ${poiToReplace.name}');

    // Nachbar-Positionen innerhalb des Tages (nicht global)
    final dayStopIndex = dayStops.indexWhere((s) => s.poiId == poiIdToReroll);
    final previousLocation =
        dayStopIndex > 0 ? dayStops[dayStopIndex - 1].location : dayStart;

    LatLng nextLocation;
    if (dayStopIndex < dayStops.length - 1) {
      nextLocation = dayStops[dayStopIndex + 1].location;
    } else if (dayAllStops.isNotEmpty && dayAllStops.last.isOvernightStop) {
      nextLocation = dayAllStops.last.location;
    } else if (targetDay < currentTrip.trip.actualDays) {
      // Letzter Stop des Tages: Richtung naechster Tag
      final nextDayStops = currentTrip.trip.getStopsForDay(targetDay + 1);
      nextLocation =
          nextDayStops.isNotEmpty ? nextDayStops.first.location : startLocation;
    } else {
      // Letzter Stop des letzten Tages: Richtung finales Trip-Ziel
      nextLocation = currentTrip.trip.route.end;
    }

    final maxSegmentKm = TripConstants.maxKmPerDay / 2;
    final triedPOIIds = <String>{poiIdToReroll};
    const maxRetries = 3;

    // Andere Tage unverändert beibehalten
    final otherDaysStops =
        currentTrip.trip.stops.where((s) => s.day != targetDay).toList();

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
        break;
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

      try {
        _validateHardDayLimitOrThrow(
          trip: result.trip,
          tripStart: startLocation,
          contextLabel: 'reroll_poi_day',
        );
        return result;
      } on TripGenerationException {
        if (attempt == maxRetries - 1) {
          rethrow;
        }
        continue;
      }
    }

    throw TripGenerationException(
        'Kein alternativer POI gefunden, der das Tageslimit einhaelt');
  }

  List<List<HotelSuggestion>> _dedupeHotelsAcrossDays(
    List<List<HotelSuggestion>> hotelsByDay,
  ) {
    final usedPrimaryIds = <String>{};
    final deduped = <List<HotelSuggestion>>[];

    for (final hotels in hotelsByDay) {
      final seenForDay = <String>{};
      final uniqueForDay = <HotelSuggestion>[];
      for (final hotel in hotels) {
        final id = _hotelStableId(hotel);
        if (seenForDay.add(id)) {
          uniqueForDay.add(hotel);
        }
      }

      final preferred = uniqueForDay
          .where((hotel) => !usedPrimaryIds.contains(_hotelStableId(hotel)))
          .toList();
      final fallback = uniqueForDay
          .where((hotel) => usedPrimaryIds.contains(_hotelStableId(hotel)))
          .toList();
      final ordered = [...preferred, ...fallback];
      if (ordered.isNotEmpty) {
        usedPrimaryIds.add(_hotelStableId(ordered.first));
      }
      deduped.add(ordered);
    }

    return deduped;
  }

  String _hotelStableId(HotelSuggestion hotel) {
    if (hotel.placeId != null && hotel.placeId!.isNotEmpty) {
      return 'place:${hotel.placeId}';
    }
    return hotel.id;
  }

  bool _isRoundTripRoute(Trip trip, LatLng tripStart) {
    final endDistance = GeoUtils.haversineDistance(trip.route.end, tripStart);
    return endDistance <= 1.0;
  }

  List<TripDay> _extractTripDaysFromTrip(Trip trip) {
    final days = <TripDay>[];
    for (int day = 1; day <= trip.actualDays; day++) {
      final dayStops = trip.getStopsForDay(day);
      final overnight = dayStops.where((s) => s.isOvernightStop).lastOrNull;
      days.add(
        TripDay(
          dayNumber: day,
          title: 'Tag $day',
          stops: dayStops,
          overnightStop: overnight,
          distanceKm: trip.getDistanceForDay(day),
        ),
      );
    }
    return days;
  }

  void _validateHardDayLimitOrThrow({
    required Trip trip,
    required LatLng tripStart,
    required String contextLabel,
  }) {
    final tripDays = _extractTripDaysFromTrip(trip);
    final isRoundTrip = _isRoundTripRoute(trip, tripStart);
    final violations = _dayPlanner.validateDayLimits(
      tripDays: tripDays,
      tripStart: tripStart,
      returnToStart: isRoundTrip,
      tripEnd: isRoundTrip ? null : trip.route.end,
    );
    if (violations.isEmpty) {
      return;
    }

    final first = violations.first;
    throw TripGenerationException(
      'Tageslimit (700km) verletzt nach $contextLabel: '
      'Tag ${first.dayNumber} (~${first.displayKm.toStringAsFixed(0)}km).',
    );
  }

  List<TripStop> _normalizeDayStopsForHotelSelection(
    List<TripStop> dayStops, {
    required int dayNumber,
  }) {
    final baseStops = dayStops
        .where((stop) => !stop.isOvernightStop && stop.categoryId != 'hotel')
        .toList();
    return baseStops.asMap().entries.map((entry) {
      return entry.value.copyWith(
        day: dayNumber,
        order: entry.key,
        isOvernightStop: false,
      );
    }).toList();
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

    debugPrint(
        '[TripGenerator] Korridor-Bounds: SW(${bounds.southwest.latitude.toStringAsFixed(2)}, ${bounds.southwest.longitude.toStringAsFixed(2)}) → NE(${bounds.northeast.latitude.toStringAsFixed(2)}, ${bounds.northeast.longitude.toStringAsFixed(2)})');

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
      hotelSuggestions != null &&
      hotelSuggestions!.any((list) => list.isNotEmpty);
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
TripGeneratorRepository tripGeneratorRepository(
    TripGeneratorRepositoryRef ref) {
  return TripGeneratorRepository();
}
