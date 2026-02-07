import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/utils/location_helper.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/constants/categories.dart'; // Enthält WeatherCondition
import '../../../data/models/poi.dart';
import '../../../core/constants/trip_constants.dart';
import '../../../data/providers/active_trip_provider.dart';
import '../../../data/repositories/geocoding_repo.dart';
import '../../../data/repositories/trip_generator_repo.dart';
import '../../../data/services/active_trip_service.dart';
import '../../../data/services/hotel_service.dart';
import '../../map/providers/map_controller_provider.dart';
import '../../map/providers/route_planner_provider.dart';
import '../../map/providers/route_session_provider.dart';
import '../../map/providers/weather_provider.dart';
import '../../poi/providers/poi_state_provider.dart';
import '../../trip/providers/trip_state_provider.dart';
import 'random_trip_state.dart';

part 'random_trip_provider.g.dart';

/// Notifier für Random Trip State Management
/// keepAlive: true damit der State beim Wechsel zwischen Modi erhalten bleibt
@Riverpod(keepAlive: true)
class RandomTripNotifier extends _$RandomTripNotifier {
  late TripGeneratorRepository _tripGenerator;
  late GeocodingRepository _geocodingRepo;

  /// Atomares Lock um Race Conditions bei Doppel-Klick zu verhindern
  bool _isGenerating = false;

  /// Letzter explizit gewaehlter Radius fuer Tagestrips.
  /// Verhindert, dass beim Moduswechsel immer wieder auf 100km resetet wird.
  double _lastDayTripRadiusKm = 100;

  @override
  RandomTripState build() {
    _tripGenerator = ref.watch(tripGeneratorRepositoryProvider);
    _geocodingRepo = ref.watch(geocodingRepositoryProvider);
    return const RandomTripState();
  }

  /// Setzt den Trip-Modus (Tagesausflug/Euro Trip)
  void setMode(RandomTripMode mode) {
    final days =
        mode == RandomTripMode.daytrip ? 1 : TripConstants.euroTripDefaultDays;
    final nextRadius = mode == RandomTripMode.daytrip
        ? _lastDayTripRadiusKm
        : TripConstants.calculateRadiusFromDays(days);

    state = state.copyWith(
      mode: mode,
      days: days,
      radiusKm: nextRadius,
    );
  }

  /// Setzt den Radius (für Tagestrip)
  void setRadius(double radiusKm) {
    _lastDayTripRadiusKm = radiusKm;
    state = state.copyWith(radiusKm: radiusKm);
  }

  /// Setzt die Anzahl der Tage für Euro Trip und berechnet Radius automatisch
  void setEuroTripDays(int days) {
    final clampedDays = days.clamp(
      TripConstants.euroTripMinDays,
      TripConstants.euroTripMaxDays,
    );
    state = state.copyWith(
      days: clampedDays,
      radiusKm: TripConstants.calculateRadiusFromDays(clampedDays),
    );
  }

  /// Setzt die Anzahl der Tage
  void setDays(int days) {
    state = state.copyWith(days: days);
  }

  /// Schaltet Hotel-Vorschläge um
  void toggleHotels(bool include) {
    state = state.copyWith(includeHotels: include);
  }

  /// Schaltet eine Kategorie um
  void toggleCategory(POICategory category) {
    final current = List<POICategory>.from(state.selectedCategories);
    if (current.contains(category)) {
      current.remove(category);
    } else {
      current.add(category);
    }
    state = state.copyWith(
      selectedCategories: current,
      weatherCategoriesApplied: false,
    );
  }

  /// Setzt alle Kategorien
  void setCategories(List<POICategory> categories) {
    state = state.copyWith(selectedCategories: categories);
  }

  /// Setzt Kategorien basierend auf Wetter-Bedingung (v1.7.6)
  /// Bei schlechtem Wetter: Indoor-Kategorien empfohlen
  /// Bei gutem Wetter: Outdoor-Kategorien empfohlen
  void applyWeatherBasedCategories(WeatherCondition condition) {
    List<POICategory> recommended;

    switch (condition) {
      case WeatherCondition.danger:
        // Nur Indoor-Kategorien bei Unwetter
        recommended = POICategory.indoorCategories;
        debugPrint('[RandomTrip] Unwetter erkannt - nur Indoor-Kategorien');
        break;

      case WeatherCondition.bad:
        // Indoor + wetter-resistente Kategorien (castle, activity haben Indoor-Teile)
        recommended = [
          ...POICategory.weatherResilientCategories,
          POICategory.city, // Staedte haben Ueberdachungen
        ];
        debugPrint(
            '[RandomTrip] Schlechtes Wetter - wetter-resistente Kategorien');
        break;

      case WeatherCondition.mixed:
        // Flexibel - alle Kategorien erlaubt
        recommended = [];
        debugPrint('[RandomTrip] Wechselhaftes Wetter - alle Kategorien');
        break;

      case WeatherCondition.good:
      case WeatherCondition.unknown:
      default:
        // Outdoor bevorzugt bei gutem Wetter
        recommended = [
          POICategory.nature,
          POICategory.viewpoint,
          POICategory.lake,
          POICategory.coast,
          POICategory.park,
          POICategory.activity,
          POICategory.castle,
          POICategory.monument,
        ];
        debugPrint('[RandomTrip] Gutes Wetter - Outdoor empfohlen');
        break;
    }

    state = state.copyWith(
      selectedCategories: recommended,
      weatherCategoriesApplied: true,
    );
  }

  /// Setzt Wetter-Kategorien zurück auf Default (alle außer Hotel)
  void resetWeatherCategories() {
    state = state.copyWith(
      selectedCategories:
          POICategory.values.where((c) => c != POICategory.hotel).toList(),
      weatherCategoriesApplied: false,
    );
    debugPrint('[RandomTrip] Wetter-Kategorien zurückgesetzt');
  }

  /// Setzt Startpunkt manuell
  void setStartLocation(LatLng location, String address) {
    state = state.copyWith(
      startLocation: location,
      startAddress: address,
      useGPS: false,
      error: null,
    );
  }

  /// Setzt Zielpunkt manuell (optional - wenn leer → Rundreise)
  void setDestination(LatLng location, String address) {
    state = state.copyWith(
      destinationLocation: location,
      destinationAddress: address,
      error: null,
    );
  }

  /// Löscht Zielpunkt (zurück zu Rundreise/Random)
  void clearDestination() {
    state = state.copyWith(
      destinationLocation: null,
      destinationAddress: null,
    );
  }

  /// Verwendet GPS-Position als Startpunkt
  Future<void> useCurrentLocation() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final locationResult = await LocationHelper.getCurrentPosition(
        timeLimit: const Duration(seconds: 15),
      );
      if (!locationResult.isSuccess) {
        state = state.copyWith(
          isLoading: false,
          error: locationResult.message,
        );
        return;
      }

      final location = locationResult.position!;

      // Adresse ermitteln
      final result = await _geocodingRepo.reverseGeocode(location);
      final address =
          result?.shortName ?? result?.displayName ?? 'Mein Standort';

      state = state.copyWith(
        startLocation: location,
        startAddress: address,
        useGPS: true,
        isLoading: false,
      );
    } on TimeoutException catch (_) {
      debugPrint('[RandomTrip] GPS-Timeout');
      state = state.copyWith(
        isLoading: false,
        error:
            'GPS-Standort konnte nicht rechtzeitig ermittelt werden. Bitte versuche es erneut oder gib eine Adresse ein.',
      );
    } catch (e) {
      debugPrint('[RandomTrip] GPS-Fehler: $e');

      // Spezifischere Fehlermeldung je nach Ausnahme-Typ
      final errorMsg = e.toString().contains('permission')
          ? 'GPS-Berechtigung verweigert. Bitte in den App-Einstellungen aktivieren.'
          : 'Standort konnte nicht ermittelt werden. Bitte gib eine Adresse manuell ein.';

      state = state.copyWith(
        isLoading: false,
        error: errorMsg,
      );
    }
  }

  /// Generiert den Trip
  /// Wenn kein Startpunkt gesetzt ist, wird automatisch GPS-Standort abgefragt
  Future<void> generateTrip() async {
    // Atomares Lock - pruefen UND setzen in einem Schritt (vor jeglichem State-Zugriff)
    if (_isGenerating) {
      debugPrint(
          '[RandomTrip] Trip-Generierung laeuft bereits (Lock), ignoriere');
      return;
    }
    _isGenerating = true;

    // Zusaetzlicher State-Check als Backup
    if (state.step == RandomTripStep.generating) {
      debugPrint(
          '[RandomTrip] Trip-Generierung laeuft bereits (State), ignoriere');
      _isGenerating = false;
      return;
    }

    // Step sofort auf generating setzen um Race Conditions zu verhindern
    // v1.10.23: Fortschritts-Tracking starten
    state = state.copyWith(
      step: RandomTripStep.generating,
      isLoading: true,
      error: null,
      completedDays: {},
      selectedDay: 1,
      generationPhase: GenerationPhase.calculatingRoute,
      generationProgress: GenerationPhase.calculatingRoute.baseProgress,
    );

    // Wenn kein Startpunkt gesetzt ist, automatisch GPS-Standort abfragen
    if (!state.hasValidStart) {
      await useCurrentLocation();

      // Prüfen ob GPS erfolgreich war
      if (!state.hasValidStart) {
        state = state.copyWith(
          step: RandomTripStep.config,
          isLoading: false,
          error: 'Bitte gib einen Startpunkt ein oder aktiviere GPS',
        );
        _isGenerating = false;
        return;
      }
    }

    // Startpunkt in lokale Variablen capturen (Null-Safety vor async Ops)
    final startLoc = state.startLocation;
    final startAddr = state.startAddress;
    if (startLoc == null || startAddr == null) {
      state = state.copyWith(
        step: RandomTripStep.config,
        isLoading: false,
        error: 'Startpunkt nicht verfuegbar. Bitte erneut eingeben.',
      );
      _isGenerating = false;
      return;
    }

    // Alten aktiven Trip löschen (neuer Trip ersetzt ihn)
    await ref.read(activeTripServiceProvider).clearTrip();
    try {
      ref.read(activeTripNotifierProvider.notifier).refresh();
    } catch (e) {
      debugPrint('[RandomTrip] ActiveTrip-Refresh fehlgeschlagen: $e');
    }

    try {
      GeneratedTrip result;

      // v1.10.23: Phase 2 - POIs suchen
      state = state.copyWith(
        generationPhase: GenerationPhase.searchingPOIs,
        generationProgress: GenerationPhase.searchingPOIs.baseProgress,
      );

      // Aktuelles Wetter fuer Score-Gewichtung
      final locationWeather = ref.read(locationWeatherNotifierProvider);
      final currentWeather =
          locationWeather.hasWeather ? locationWeather.condition : null;

      if (state.mode == RandomTripMode.daytrip) {
        result = await _tripGenerator.generateDayTrip(
          startLocation: startLoc,
          startAddress: startAddr,
          radiusKm: state.radiusKm,
          categories: state.selectedCategories,
          poiCount: (state.radiusKm / 20).clamp(3, 8).round(),
          destinationLocation: state.destinationLocation,
          destinationAddress: state.destinationAddress,
          weatherCondition: currentWeather,
        );
      } else {
        // v1.10.23: Phase 3 - AI-Ranking (bei Euro Trips komplexer)
        state = state.copyWith(
          generationPhase: GenerationPhase.rankingWithAI,
          generationProgress: GenerationPhase.rankingWithAI.baseProgress,
        );

        // Euro Trip: Tage direkt übergeben, Radius für POI-Suche
        debugPrint(
            '[RandomTrip] Euro Trip starten: ${state.days} Tage (${state.radiusKm}km), Start: $startAddr${state.hasDestination ? ', Ziel: ${state.destinationAddress}' : ' (Rundreise)'}');
        result = await _tripGenerator.generateEuroTrip(
          startLocation: startLoc,
          startAddress: startAddr,
          radiusKm: state.radiusKm,
          days: state.days,
          categories: state.selectedCategories,
          includeHotels: state.includeHotels,
          destinationLocation: state.destinationLocation,
          destinationAddress: state.destinationAddress,
          weatherCondition: currentWeather,
        );
        debugPrint(
            '[RandomTrip] Euro Trip generiert! ${state.days} Tage, POIs: ${result.selectedPOIs.length}, Route: ${result.trip.route.distanceKm.toStringAsFixed(0)}km');
      }

      debugPrint('[RandomTrip] Trip erfolgreich! Setze step auf preview...');

      // v1.10.23: Phase 4 - Bilder laden
      state = state.copyWith(
        generationPhase: GenerationPhase.enrichingImages,
        generationProgress: GenerationPhase.enrichingImages.baseProgress,
      );

      // v1.6.9: POIs enrichen für Foto-Anzeige in der Preview
      // FIX v1.10.5: Sicher aufrufen mit Zone-basierter Fehlerbehandlung
      // Bei async ohne await werden Exceptions nicht vom try-catch gefangen!
      _safeEnrichGeneratedPOIs(result);

      // v1.10.23: Phase 5 - Abgeschlossen
      state = state.copyWith(
        generatedTrip: result,
        hotelSuggestions: result.hotelSuggestions ?? [],
        step: RandomTripStep.preview,
        isLoading: false,
        generationPhase: GenerationPhase.complete,
        generationProgress: GenerationPhase.complete.baseProgress,
      );
      debugPrint(
          '[RandomTrip] State aktualisiert: step=${state.step}, generatedTrip=${state.generatedTrip != null}');
    } on TripGenerationException catch (e, stackTrace) {
      debugPrint('[RandomTrip] TripGenerationException: ${e.message}');
      debugPrint('[RandomTrip] StackTrace: $stackTrace');
      state = state.copyWith(
        step: RandomTripStep.config,
        isLoading: false,
        error: e.message,
        generationPhase: GenerationPhase.idle,
        generationProgress: 0.0,
      );
    } catch (e, stackTrace) {
      debugPrint('[RandomTrip] UNERWARTETER FEHLER: $e');
      debugPrint('[RandomTrip] Typ: ${e.runtimeType}');
      debugPrint('[RandomTrip] StackTrace: $stackTrace');
      state = state.copyWith(
        step: RandomTripStep.config,
        isLoading: false,
        error: 'Trip-Generierung fehlgeschlagen: $e',
        generationPhase: GenerationPhase.idle,
        generationProgress: 0.0,
      );
    } finally {
      // Lock immer zuruecksetzen, egal ob Erfolg oder Fehler
      _isGenerating = false;
    }
  }

  /// Würfelt den gesamten Trip neu
  Future<void> regenerateTrip() async {
    await generateTrip();
  }

  /// Würfelt einen einzelnen POI neu
  Future<void> rerollPOI(String poiId) async {
    final generatedTrip = state.generatedTrip;
    final startLoc = state.startLocation;
    if (generatedTrip == null || startLoc == null) return;

    state = state.copyWith(
      isLoading: true,
      loadingPOIId: poiId,
    );

    try {
      final result = await _tripGenerator.rerollPOI(
        currentTrip: generatedTrip,
        poiIdToReroll: poiId,
        startLocation: startLoc,
        startAddress: state.startAddress ?? '',
        categories: state.selectedCategories,
      );

      state = state.copyWith(
        generatedTrip: result,
        isLoading: false,
        loadingPOIId: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        loadingPOIId: null,
        error: 'POI konnte nicht neu gewürfelt werden',
      );
    }
  }

  /// Entfernt einen einzelnen POI aus dem Trip
  Future<void> removePOI(String poiId) async {
    final generatedTrip = state.generatedTrip;
    final startLoc = state.startLocation;
    if (generatedTrip == null || startLoc == null) return;

    // Prüfen ob genug POIs übrig bleiben
    if (generatedTrip.selectedPOIs.length <= 2) {
      state = state.copyWith(
        error: 'Mindestens 2 Stops müssen im Trip bleiben',
      );
      return;
    }

    state = state.copyWith(
      isLoading: true,
      loadingPOIId: poiId,
    );

    try {
      final result = await _tripGenerator.removePOI(
        currentTrip: generatedTrip,
        poiIdToRemove: poiId,
        startLocation: startLoc,
        startAddress: state.startAddress ?? '',
      );

      state = state.copyWith(
        generatedTrip: result,
        isLoading: false,
        loadingPOIId: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        loadingPOIId: null,
        error: 'POI konnte nicht entfernt werden: $e',
      );
    }
  }

  /// Wählt ein Hotel für einen Tag aus
  void selectHotel(int dayIndex, HotelSuggestion hotel) {
    final selected = Map<int, HotelSuggestion>.from(state.selectedHotels);
    selected[dayIndex] = hotel;
    state = state.copyWith(selectedHotels: selected);
  }

  /// Markiert den Trip als bestätigt ohne alte Daten zu löschen
  /// Wird verwendet wenn ein Stop über die POI-Liste hinzugefügt wird
  void markAsConfirmed() {
    if (state.generatedTrip == null) return;
    state = state.copyWith(step: RandomTripStep.confirmed);
  }

  /// Fuegt einen POI zu einem bestimmten Tag des AI Trips hinzu.
  /// Wird vom Korridor-Browser im DayEditor aufgerufen.
  Future<bool> addPOIToDay(POI poi, int dayNumber) async {
    final generatedTrip = state.generatedTrip;
    final startLoc = state.startLocation;
    if (generatedTrip == null || startLoc == null) return false;

    state = state.copyWith(isLoading: true);

    try {
      final result = await _tripGenerator.addPOIToTrip(
        currentTrip: generatedTrip,
        newPOI: poi,
        targetDay: dayNumber,
        startLocation: startLoc,
        startAddress: state.startAddress ?? '',
      );

      state = state.copyWith(
        generatedTrip: result,
        isLoading: false,
      );

      // POI enrichen fuer Foto-Anzeige
      final poiNotifier = ref.read(pOIStateNotifierProvider.notifier);
      poiNotifier.addPOI(poi);
      if (poi.imageUrl == null) {
        poiNotifier.enrichPOI(poi.id);
      }

      // TripStateProvider synchronisieren (fuer TripScreen/MapView)
      final tripStateNotifier = ref.read(tripStateProvider.notifier);
      tripStateNotifier.setRouteAndStops(
        result.trip.route,
        result.selectedPOIs,
      );

      // Aktiven Trip persistieren (bei Multi-Day)
      if (state.isMultiDay) {
        _persistActiveTrip();
      }

      debugPrint(
          '[RandomTrip] POI "${poi.name}" zu Tag $dayNumber hinzugefuegt');
      return true;
    } catch (e) {
      debugPrint('[RandomTrip] Fehler beim Hinzufuegen zu Tag $dayNumber: $e');
      final errorMsg = e is TripGenerationException
          ? 'Tageslimit (700km) wuerde ueberschritten'
          : 'POI konnte nicht hinzugefuegt werden: $e';
      state = state.copyWith(
        isLoading: false,
        error: errorMsg,
      );
      return false;
    }
  }

  /// Entfernt einen POI von einem bestimmten Tag.
  /// Wird vom Korridor-Browser im DayEditor aufgerufen.
  Future<bool> removePOIFromDay(String poiId, int dayNumber) async {
    final generatedTrip = state.generatedTrip;
    final startLoc = state.startLocation;
    if (generatedTrip == null || startLoc == null) return false;

    // Pruefen: Tag muss nach Entfernung mindestens 1 Stop haben
    final dayStops = generatedTrip.trip.getStopsForDay(dayNumber);
    if (dayStops.length <= 1) {
      state = state.copyWith(
        error: 'Mindestens 1 Stop pro Tag erforderlich',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, loadingPOIId: poiId);

    try {
      final result = await _tripGenerator.removePOI(
        currentTrip: generatedTrip,
        poiIdToRemove: poiId,
        startLocation: startLoc,
        startAddress: state.startAddress ?? '',
      );

      state = state.copyWith(
        generatedTrip: result,
        isLoading: false,
        loadingPOIId: null,
      );

      // TripStateProvider synchronisieren
      final tripStateNotifier = ref.read(tripStateProvider.notifier);
      tripStateNotifier.setRouteAndStops(
        result.trip.route,
        result.selectedPOIs,
      );

      // Aktiven Trip persistieren (bei Multi-Day)
      if (state.isMultiDay) {
        _persistActiveTrip();
      }

      debugPrint('[RandomTrip] POI "$poiId" von Tag $dayNumber entfernt');
      return true;
    } catch (e) {
      debugPrint('[RandomTrip] Fehler beim Entfernen von Tag $dayNumber: $e');
      state = state.copyWith(
        isLoading: false,
        loadingPOIId: null,
        error: 'POI konnte nicht entfernt werden: $e',
      );
      return false;
    }
  }

  /// Bestätigt den Trip und übergibt ihn an TripStateProvider
  void confirmTrip() {
    final generatedTrip = state.generatedTrip;
    if (generatedTrip == null) return;

    // Bestehende Route im Route-Planner löschen (überschreibt alte Route)
    final routePlannerNotifier = ref.read(routePlannerProvider.notifier);
    routePlannerNotifier.clearStart();
    routePlannerNotifier.clearEnd();

    // Alte Route-Session stoppen (löscht auch POIs)
    ref.read(routeSessionProvider.notifier).stopRoute();

    // Alte POIs löschen
    final poiNotifier = ref.read(pOIStateNotifierProvider.notifier);
    poiNotifier.clearPOIs();
    debugPrint('[RandomTrip] Alte POIs gelöscht');

    // Route und Stops an TripStateProvider übergeben
    final tripStateNotifier = ref.read(tripStateProvider.notifier);

    // Route setzen
    tripStateNotifier.setRoute(generatedTrip.trip.route);

    // Stops als POIs setzen (konvertieren von TripStop zu POI-ähnlichen Objekten)
    final stops = generatedTrip.selectedPOIs;
    tripStateNotifier.setStops(stops);

    state = state.copyWith(step: RandomTripStep.confirmed);

    // Mehrtägige Trips sofort persistieren
    if (state.isMultiDay) {
      _persistActiveTrip();
    }

    // Routen-Wetter laden fuer die bestaetigte Route
    // Bei Multi-Day: Vorhersage mit Tages-Forecast (max 7 Tage)
    final routeCoords = generatedTrip.trip.route.coordinates;
    if (routeCoords.isNotEmpty) {
      final tripDays = generatedTrip.trip.actualDays;
      if (tripDays > 1) {
        ref
            .read(routeWeatherNotifierProvider.notifier)
            .loadWeatherForRouteWithForecast(
              routeCoords,
              forecastDays: tripDays.clamp(2, 7),
            );
        debugPrint(
            '[RandomTrip] Routen-Wetter mit ${tripDays.clamp(2, 7)}-Tage-Forecast geladen');
      } else {
        ref
            .read(routeWeatherNotifierProvider.notifier)
            .loadWeatherForRoute(routeCoords);
        debugPrint(
            '[RandomTrip] Routen-Wetter wird geladen (${routeCoords.length} Punkte)');
      }
    }
  }

  /// Geht zurück zur Konfiguration
  void backToConfig() {
    state = state.copyWith(
      step: RandomTripStep.config,
      generatedTrip: null,
      error: null,
    );
  }

  /// Setzt den State zurück und löscht aktiven Trip
  void reset() {
    ref.read(activeTripServiceProvider).clearTrip();
    ref.read(activeTripNotifierProvider.notifier).refresh();
    state = const RandomTripState();
  }

  /// Löscht Fehler
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Wählt einen Tag aus (für tagesweisen Export)
  void selectDay(int dayNumber) {
    final maxDay = state.generatedTrip?.trip.actualDays ?? 1;
    final clampedDay = dayNumber.clamp(1, maxDay);
    state = state.copyWith(selectedDay: clampedDay);

    // Ausgewählten Tag in Hive aktualisieren
    if (state.isMultiDay) {
      ref.read(activeTripServiceProvider).updateSelectedDay(clampedDay);
    }
  }

  /// Markiert einen Tag als abgeschlossen/exportiert
  void completeDay(int dayNumber) {
    final updatedDays = Set<int>.from(state.completedDays)..add(dayNumber);
    state = state.copyWith(completedDays: updatedDays);

    // Automatisch zum nächsten Tag wechseln, falls vorhanden
    final maxDay = state.generatedTrip?.trip.actualDays ?? 1;
    if (dayNumber < maxDay) {
      state = state.copyWith(selectedDay: dayNumber + 1);
    }

    // Aktiven Trip persistieren (nur Mehrtages-Trips)
    if (state.isMultiDay && state.generatedTrip != null) {
      _persistActiveTrip();
    }
  }

  /// Setzt den Abschluss-Status eines Tages zurück
  void uncompleteDay(int dayNumber) {
    final updatedDays = Set<int>.from(state.completedDays)..remove(dayNumber);
    state = state.copyWith(completedDays: updatedDays);

    // Aktiven Trip aktualisieren
    if (state.isMultiDay && state.generatedTrip != null) {
      _persistActiveTrip();
    }
  }

  /// Prüft ob alle Tage abgeschlossen sind
  bool get allDaysCompleted {
    final totalDays = state.generatedTrip?.trip.actualDays ?? 1;
    return state.completedDays.length >= totalDays;
  }

  /// Persistiert den aktuellen State als aktiven Trip in Hive
  Future<void> _persistActiveTrip() async {
    final generatedTrip = state.generatedTrip;
    if (generatedTrip == null) return;

    try {
      await ref.read(activeTripServiceProvider).saveTrip(
            trip: generatedTrip.trip,
            completedDays: state.completedDays,
            selectedDay: state.selectedDay,
            selectedPOIs: generatedTrip.selectedPOIs,
            availablePOIs: generatedTrip.availablePOIs,
            startLocation: state.startLocation,
            startAddress: state.startAddress,
            mode: state.mode,
            days: state.days,
            radiusKm: state.radiusKm,
            destinationLocation: state.destinationLocation,
            destinationAddress: state.destinationAddress,
          );
      try {
        ref.read(activeTripNotifierProvider.notifier).refresh();
      } catch (e) {
        debugPrint('[RandomTrip] ActiveTrip-Refresh fehlgeschlagen: $e');
      }
    } catch (e) {
      debugPrint('[RandomTrip] Fehler beim Persistieren des aktiven Trips: $e');
    }
  }

  /// Stellt einen aktiven Trip aus Hive wieder her
  Future<void> restoreFromActiveTrip(ActiveTripData data) async {
    debugPrint('[RandomTrip] Aktiven Trip wiederherstellen: ${data.trip.name}');

    // GeneratedTrip rekonstruieren
    final generatedTrip = GeneratedTrip(
      trip: data.trip,
      selectedPOIs: data.selectedPOIs,
      availablePOIs: data.availablePOIs,
    );

    state = state.copyWith(
      step: RandomTripStep.confirmed,
      mode: data.mode,
      startLocation: data.startLocation,
      startAddress: data.startAddress,
      radiusKm: data.radiusKm,
      days: data.days,
      generatedTrip: generatedTrip,
      selectedDay: data.selectedDay,
      completedDays: data.completedDays,
      destinationLocation: data.destinationLocation,
      destinationAddress: data.destinationAddress,
      isLoading: false,
      error: null,
    );

    if (data.mode == RandomTripMode.daytrip) {
      _lastDayTripRadiusKm = data.radiusKm;
    }

    // Bestehende Routen-Daten aufräumen
    final routePlannerNotifier = ref.read(routePlannerProvider.notifier);
    routePlannerNotifier.clearStart();
    routePlannerNotifier.clearEnd();
    ref.read(routeSessionProvider.notifier).stopRoute();

    // Route und Stops an TripStateProvider übergeben
    final tripStateNotifier = ref.read(tripStateProvider.notifier);
    tripStateNotifier.setRouteAndStops(data.trip.route, data.selectedPOIs);

    // Auto-Zoom auf Route
    ref.read(shouldFitToRouteProvider.notifier).state = true;

    // POIs enrichen für Foto-Anzeige
    // FIX v1.10.5: Sicher aufrufen
    _safeEnrichGeneratedPOIs(generatedTrip);

    debugPrint('[RandomTrip] Trip wiederhergestellt: Tag ${data.selectedDay}, '
        '${data.completedDays.length}/${data.trip.actualDays} Tage abgeschlossen');
  }

  /// FIX v1.10.5: Sicherer Wrapper für Enrichment
  /// Fängt alle Exceptions ab und verhindert App-Crashes
  void _safeEnrichGeneratedPOIs(GeneratedTrip result) {
    // Zone-basierte Fehlerbehandlung für async ohne await
    runZonedGuarded(
      () async {
        await _enrichGeneratedPOIs(result);
      },
      (error, stackTrace) {
        // Fehler loggen aber nicht crashen
        debugPrint('[RandomTrip] Zone-Fehler beim Enrichment: $error');
        debugPrint('[RandomTrip] Zone-StackTrace: $stackTrace');
      },
    );
  }

  /// v1.6.9: Enriched die generierten POIs für Foto-Anzeige
  /// v1.10.2: FIX - Verwendet addPOIsBatch() statt Loop + await enrichPOIsBatch()
  /// v1.10.5: FIX - Batch-Limit für Euro Trips mit vielen POIs
  /// Wird nach Trip-Generierung aufgerufen
  Future<void> _enrichGeneratedPOIs(GeneratedTrip result) async {
    try {
      final poiNotifier = ref.read(pOIStateNotifierProvider.notifier);

      // FIX v1.10.2: EIN Batch-Update statt 12 einzelne addPOI() Aufrufe
      poiNotifier.addPOIsBatch(result.selectedPOIs);

      // Kurze Verzögerung damit UI rendern kann bevor Enrichment startet
      await Future.delayed(const Duration(milliseconds: 100));

      // v1.7.9: Batch-Enrichment statt Einzel-Calls (7x schneller)
      // v1.10.2: Jetzt awaited um Race Conditions zu verhindern
      final poisToEnrich =
          result.selectedPOIs.where((p) => p.imageUrl == null).toList();

      if (poisToEnrich.isEmpty) return;

      debugPrint(
          '[RandomTrip] Batch-Enrichment für ${poisToEnrich.length} POIs');

      // FIX v1.10.5: Bei Euro Trips mit vielen POIs in kleineren Sub-Batches enrichen
      // Verhindert Überlastung und ConcurrentModificationException
      const maxBatchSize = 10;
      if (poisToEnrich.length > maxBatchSize) {
        debugPrint(
            '[RandomTrip] Euro Trip: Sub-Batching mit max $maxBatchSize POIs pro Batch');
        for (var i = 0; i < poisToEnrich.length; i += maxBatchSize) {
          final end = (i + maxBatchSize).clamp(0, poisToEnrich.length);
          final subBatch = poisToEnrich.sublist(i, end);

          debugPrint(
              '[RandomTrip] Sub-Batch ${(i ~/ maxBatchSize) + 1}: ${subBatch.length} POIs');
          await poiNotifier.enrichPOIsBatch(subBatch);

          // Kurze Pause zwischen Sub-Batches für Stabilität
          if (end < poisToEnrich.length) {
            await Future.delayed(const Duration(milliseconds: 200));
          }
        }
      } else {
        // Tagestrip: Alle auf einmal (weniger als maxBatchSize POIs)
        await poiNotifier.enrichPOIsBatch(poisToEnrich);
      }
    } catch (e, stackTrace) {
      // Enrichment-Fehler sollten den Trip nicht blockieren
      debugPrint('[RandomTrip] Enrichment-Fehler (nicht kritisch): $e');
      debugPrint('[RandomTrip] Enrichment-StackTrace: $stackTrace');
    }
  }
}
