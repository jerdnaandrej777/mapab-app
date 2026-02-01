import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/constants/categories.dart'; // Enthält WeatherCondition
import '../../../data/repositories/geocoding_repo.dart';
import '../../../data/repositories/trip_generator_repo.dart';
import '../../../data/services/hotel_service.dart';
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

  @override
  RandomTripState build() {
    _tripGenerator = ref.watch(tripGeneratorRepositoryProvider);
    _geocodingRepo = ref.watch(geocodingRepositoryProvider);
    return const RandomTripState();
  }

  /// Setzt den Trip-Modus (Tagesausflug/Euro Trip)
  void setMode(RandomTripMode mode) {
    state = state.copyWith(
      mode: mode,
      days: mode == RandomTripMode.daytrip ? 1 : 3,
      radiusKm: mode == RandomTripMode.daytrip ? 100 : 1000,
    );
  }

  /// Setzt den Radius
  void setRadius(double radiusKm) {
    state = state.copyWith(radiusKm: radiusKm);
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
        debugPrint('[RandomTrip] Schlechtes Wetter - wetter-resistente Kategorien');
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
      selectedCategories: POICategory.values
          .where((c) => c != POICategory.hotel)
          .toList(),
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
      // Location Services Check
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[RandomTrip] Location Services deaktiviert');
        state = state.copyWith(
          isLoading: false,
          error: 'Bitte aktiviere die Ortungsdienste in den Einstellungen',
        );
        return;
      }

      // Berechtigungen prüfen
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Standort-Berechtigung verweigert');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Standort-Berechtigung dauerhaft verweigert. '
          'Bitte in den Einstellungen aktivieren.',
        );
      }

      // Position abrufen
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );

      debugPrint('[RandomTrip] Position erhalten: ${position.latitude}, ${position.longitude}');

      final location = LatLng(position.latitude, position.longitude);

      // Adresse ermitteln
      final result = await _geocodingRepo.reverseGeocode(location);
      final address = result?.shortName ?? result?.displayName ?? 'Mein Standort';

      state = state.copyWith(
        startLocation: location,
        startAddress: address,
        useGPS: true,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('[RandomTrip] GPS-Fehler: $e');

      state = state.copyWith(
        isLoading: false,
        error: 'Standort konnte nicht ermittelt werden: ${e.toString()}',
      );
    }
  }

  /// Generiert den Trip
  /// Wenn kein Startpunkt gesetzt ist, wird automatisch GPS-Standort abgefragt
  Future<void> generateTrip() async {
    // Wenn kein Startpunkt gesetzt ist, automatisch GPS-Standort abfragen
    if (!state.hasValidStart) {
      await useCurrentLocation();

      // Prüfen ob GPS erfolgreich war
      if (!state.hasValidStart) {
        state = state.copyWith(
          error: 'Bitte gib einen Startpunkt ein oder aktiviere GPS',
        );
        return;
      }
    }

    state = state.copyWith(
      step: RandomTripStep.generating,
      isLoading: true,
      error: null,
    );

    try {
      GeneratedTrip result;

      if (state.mode == RandomTripMode.daytrip) {
        result = await _tripGenerator.generateDayTrip(
          startLocation: state.startLocation!,
          startAddress: state.startAddress!,
          radiusKm: state.radiusKm,
          categories: state.selectedCategories,
          poiCount: (state.radiusKm / 20).clamp(3, 8).round(),
          destinationLocation: state.destinationLocation,
          destinationAddress: state.destinationAddress,
        );
      } else {
        // Euro Trip: Radius übergeben, Tage werden automatisch berechnet
        debugPrint('[RandomTrip] Euro Trip starten: ${state.radiusKm}km, Start: ${state.startAddress}${state.hasDestination ? ', Ziel: ${state.destinationAddress}' : ' (Rundreise)'}');
        result = await _tripGenerator.generateEuroTrip(
          startLocation: state.startLocation!,
          startAddress: state.startAddress!,
          radiusKm: state.radiusKm,
          categories: state.selectedCategories,
          includeHotels: state.includeHotels,
          destinationLocation: state.destinationLocation,
          destinationAddress: state.destinationAddress,
        );
        debugPrint('[RandomTrip] Euro Trip generiert! POIs: ${result.selectedPOIs.length}, Route: ${result.trip.route.distanceKm.toStringAsFixed(0)}km');
      }

      debugPrint('[RandomTrip] Trip erfolgreich! Setze step auf preview...');
      state = state.copyWith(
        generatedTrip: result,
        hotelSuggestions: result.hotelSuggestions ?? [],
        step: RandomTripStep.preview,
        isLoading: false,
      );
      debugPrint('[RandomTrip] State aktualisiert: step=${state.step}, generatedTrip=${state.generatedTrip != null}');

      // v1.6.9: POIs enrichen für Foto-Anzeige in der Preview
      _enrichGeneratedPOIs(result);
    } on TripGenerationException catch (e) {
      state = state.copyWith(
        step: RandomTripStep.config,
        isLoading: false,
        error: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        step: RandomTripStep.config,
        isLoading: false,
        error: 'Trip-Generierung fehlgeschlagen: $e',
      );
    }
  }

  /// Würfelt den gesamten Trip neu
  Future<void> regenerateTrip() async {
    await generateTrip();
  }

  /// Würfelt einen einzelnen POI neu
  Future<void> rerollPOI(String poiId) async {
    if (state.generatedTrip == null) return;

    state = state.copyWith(
      isLoading: true,
      loadingPOIId: poiId,
    );

    try {
      final result = await _tripGenerator.rerollPOI(
        currentTrip: state.generatedTrip!,
        poiIdToReroll: poiId,
        startLocation: state.startLocation!,
        startAddress: state.startAddress!,
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
    if (state.generatedTrip == null) return;

    // Prüfen ob genug POIs übrig bleiben
    if (state.generatedTrip!.selectedPOIs.length <= 2) {
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
        currentTrip: state.generatedTrip!,
        poiIdToRemove: poiId,
        startLocation: state.startLocation!,
        startAddress: state.startAddress!,
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

    // Routen-Wetter laden fuer die bestaetigte Route
    final routeCoords = generatedTrip.trip.route.coordinates;
    if (routeCoords.isNotEmpty) {
      ref.read(routeWeatherNotifierProvider.notifier)
          .loadWeatherForRoute(routeCoords);
      debugPrint('[RandomTrip] Routen-Wetter wird geladen (${routeCoords.length} Punkte)');
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

  /// Setzt den State zurück
  void reset() {
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
  }

  /// Setzt den Abschluss-Status eines Tages zurück
  void uncompleteDay(int dayNumber) {
    final updatedDays = Set<int>.from(state.completedDays)..remove(dayNumber);
    state = state.copyWith(completedDays: updatedDays);
  }

  /// Prüft ob alle Tage abgeschlossen sind
  bool get allDaysCompleted {
    final totalDays = state.generatedTrip?.trip.actualDays ?? 1;
    return state.completedDays.length >= totalDays;
  }

  /// v1.6.9: Enriched die generierten POIs für Foto-Anzeige
  /// Wird nach Trip-Generierung aufgerufen
  void _enrichGeneratedPOIs(GeneratedTrip result) {
    final poiNotifier = ref.read(pOIStateNotifierProvider.notifier);

    // POIs zum State hinzufuegen
    for (final poi in result.selectedPOIs) {
      poiNotifier.addPOI(poi);
    }

    // v1.7.9: Batch-Enrichment statt Einzel-Calls (7x schneller)
    final poisToEnrich = result.selectedPOIs
        .where((p) => p.imageUrl == null)
        .toList();

    if (poisToEnrich.isNotEmpty) {
      debugPrint('[RandomTrip] Batch-Enrichment für ${poisToEnrich.length} POIs');
      poiNotifier.enrichPOIsBatch(poisToEnrich);
    }
  }
}
