import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/constants/categories.dart';
import '../../../data/repositories/geocoding_repo.dart';
import '../../../data/repositories/trip_generator_repo.dart';
import '../../../data/services/hotel_service.dart';
import 'random_trip_state.dart';

part 'random_trip_provider.g.dart';

/// Notifier für Random Trip State Management
@riverpod
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
      radiusKm: mode == RandomTripMode.daytrip ? 100 : 300,
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
    state = state.copyWith(selectedCategories: current);
  }

  /// Setzt alle Kategorien
  void setCategories(List<POICategory> categories) {
    state = state.copyWith(selectedCategories: categories);
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

  /// Verwendet GPS-Position als Startpunkt
  Future<void> useCurrentLocation() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // NEU: Location Services Check hinzufügen
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('[RandomTrip] Location Services deaktiviert - verwende München');
        // Fallback: München als Test-Standort
        const munich = LatLng(48.1351, 11.5820);
        const name = 'München, Deutschland (Test-Standort)';

        state = state.copyWith(
          startLocation: munich,
          startAddress: name,
          useGPS: true,
          isLoading: false,
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

      print('[RandomTrip] Position erhalten: ${position.latitude}, ${position.longitude}');

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
      print('[RandomTrip] GPS-Fehler: $e');

      // NEU: München-Fallback bei Fehler (wie map_screen.dart)
      const munich = LatLng(48.1351, 11.5820);
      const name = 'München, Deutschland (GPS nicht verfügbar)';

      state = state.copyWith(
        startLocation: munich,
        startAddress: name,
        useGPS: true,
        isLoading: false,
        error: 'Standort nicht verfügbar - nutze Test-Standort München',
      );
    }
  }

  /// Generiert den Trip
  Future<void> generateTrip() async {
    if (!state.canGenerate) return;

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
        );
      } else {
        result = await _tripGenerator.generateEuroTrip(
          startLocation: state.startLocation!,
          startAddress: state.startAddress!,
          days: state.days,
          categories: state.selectedCategories,
          includeHotels: state.includeHotels,
        );
      }

      state = state.copyWith(
        generatedTrip: result,
        hotelSuggestions: result.hotelSuggestions ?? [],
        step: RandomTripStep.preview,
        isLoading: false,
      );
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

    state = state.copyWith(isLoading: true);

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
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'POI konnte nicht neu gewürfelt werden',
      );
    }
  }

  /// Wählt ein Hotel für einen Tag aus
  void selectHotel(int dayIndex, HotelSuggestion hotel) {
    final selected = Map<int, HotelSuggestion>.from(state.selectedHotels);
    selected[dayIndex] = hotel;
    state = state.copyWith(selectedHotels: selected);
  }

  /// Bestätigt den Trip
  void confirmTrip() {
    state = state.copyWith(step: RandomTripStep.confirmed);
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
}
