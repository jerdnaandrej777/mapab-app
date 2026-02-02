import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/poi.dart';
import '../models/trip.dart';
import '../../features/random_trip/providers/random_trip_state.dart';

part 'active_trip_service.g.dart';

/// Service für die Persistenz von aktiven Trips
/// Speichert den aktuellen Trip-Zustand für spätere Fortsetzung
class ActiveTripService {
  static const String _boxName = 'active_trip';
  static const String _tripKey = 'current_trip';
  static const String _completedDaysKey = 'completed_days';
  static const String _selectedDayKey = 'selected_day';
  static const String _selectedPOIsKey = 'selected_pois_json';
  static const String _availablePOIsKey = 'available_pois_json';
  static const String _startLatKey = 'start_lat';
  static const String _startLngKey = 'start_lng';
  static const String _startAddressKey = 'start_address';
  static const String _modeKey = 'mode';
  static const String _daysKey = 'days';
  static const String _radiusKmKey = 'radius_km';
  static const String _destinationLatKey = 'destination_lat';
  static const String _destinationLngKey = 'destination_lng';
  static const String _destinationAddressKey = 'destination_address';

  Box? _box;

  /// Initialisiert die Hive Box
  Future<void> _ensureInitialized() async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox(_boxName);
    }
  }

  /// Speichert den aktuellen Trip mit Zustand
  Future<void> saveTrip({
    required Trip trip,
    required Set<int> completedDays,
    required int selectedDay,
    List<POI>? selectedPOIs,
    List<POI>? availablePOIs,
    LatLng? startLocation,
    String? startAddress,
    RandomTripMode mode = RandomTripMode.eurotrip,
    int days = 1,
    double radiusKm = 100,
    LatLng? destinationLocation,
    String? destinationAddress,
  }) async {
    try {
      await _ensureInitialized();

      // Trip als JSON speichern
      await _box!.put(_tripKey, jsonEncode(trip.toJson()));
      await _box!.put(_completedDaysKey, completedDays.toList());
      await _box!.put(_selectedDayKey, selectedDay);

      // POI-Listen speichern (falls vorhanden)
      if (selectedPOIs != null) {
        final poisJson = selectedPOIs
            .map((poi) => poi.toJson())
            .toList();
        await _box!.put(_selectedPOIsKey, jsonEncode(poisJson));
      }

      if (availablePOIs != null) {
        final poisJson = availablePOIs
            .map((poi) => poi.toJson())
            .toList();
        await _box!.put(_availablePOIsKey, jsonEncode(poisJson));
      }

      // Konfiguration speichern
      if (startLocation != null) {
        await _box!.put(_startLatKey, startLocation.latitude);
        await _box!.put(_startLngKey, startLocation.longitude);
      }
      if (startAddress != null) {
        await _box!.put(_startAddressKey, startAddress);
      }
      await _box!.put(_modeKey, mode.name);
      await _box!.put(_daysKey, days);
      await _box!.put(_radiusKmKey, radiusKm);

      if (destinationLocation != null) {
        await _box!.put(_destinationLatKey, destinationLocation.latitude);
        await _box!.put(_destinationLngKey, destinationLocation.longitude);
      }
      if (destinationAddress != null) {
        await _box!.put(_destinationAddressKey, destinationAddress);
      }

      debugPrint('[ActiveTrip] Trip gespeichert: ${trip.name}, Tag $selectedDay, ${completedDays.length} Tage abgeschlossen');
    } catch (e) {
      debugPrint('[ActiveTrip] Fehler beim Speichern: $e');
      rethrow;
    }
  }

  /// Lädt den gespeicherten Trip
  Future<ActiveTripData?> loadTrip() async {
    try {
      await _ensureInitialized();

      final tripJson = _box!.get(_tripKey) as String?;
      if (tripJson == null) {
        debugPrint('[ActiveTrip] Kein gespeicherter Trip gefunden');
        return null;
      }

      final trip = Trip.fromJson(jsonDecode(tripJson));
      final completedDays = (_box!.get(_completedDaysKey) as List<dynamic>?)
              ?.map((e) => e as int)
              .toSet() ??
          {};
      final selectedDay = _box!.get(_selectedDayKey) as int? ?? 1;

      // POIs laden
      List<POI> selectedPOIs = [];
      final selectedPOIsJson = _box!.get(_selectedPOIsKey) as String?;
      if (selectedPOIsJson != null) {
        final poisList = jsonDecode(selectedPOIsJson) as List<dynamic>;
        selectedPOIs = poisList
            .map((json) => POI.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      List<POI> availablePOIs = [];
      final availablePOIsJson = _box!.get(_availablePOIsKey) as String?;
      if (availablePOIsJson != null) {
        final poisList = jsonDecode(availablePOIsJson) as List<dynamic>;
        availablePOIs = poisList
            .map((json) => POI.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      // Konfiguration laden
      final startLat = _box!.get(_startLatKey) as double?;
      final startLng = _box!.get(_startLngKey) as double?;
      final startLocation = (startLat != null && startLng != null)
          ? LatLng(startLat, startLng)
          : null;
      final startAddress = _box!.get(_startAddressKey) as String?;

      final modeStr = _box!.get(_modeKey) as String?;
      final mode = modeStr == 'daytrip'
          ? RandomTripMode.daytrip
          : RandomTripMode.eurotrip;
      final days = _box!.get(_daysKey) as int? ?? 1;
      final radiusKm = _box!.get(_radiusKmKey) as double? ?? 100;

      final destLat = _box!.get(_destinationLatKey) as double?;
      final destLng = _box!.get(_destinationLngKey) as double?;
      final destinationLocation = (destLat != null && destLng != null)
          ? LatLng(destLat, destLng)
          : null;
      final destinationAddress = _box!.get(_destinationAddressKey) as String?;

      debugPrint('[ActiveTrip] Trip geladen: ${trip.name}, Tag $selectedDay, ${selectedPOIs.length} POIs');

      return ActiveTripData(
        trip: trip,
        completedDays: completedDays,
        selectedDay: selectedDay,
        selectedPOIs: selectedPOIs,
        availablePOIs: availablePOIs,
        startLocation: startLocation,
        startAddress: startAddress,
        mode: mode,
        days: days,
        radiusKm: radiusKm,
        destinationLocation: destinationLocation,
        destinationAddress: destinationAddress,
      );
    } catch (e) {
      debugPrint('[ActiveTrip] Fehler beim Laden: $e');
      // Bei korrupten Daten aufräumen
      await clearTrip();
      return null;
    }
  }

  /// Löscht den gespeicherten Trip
  Future<void> clearTrip() async {
    try {
      await _ensureInitialized();
      await _box!.clear();
      debugPrint('[ActiveTrip] Trip gelöscht');
    } catch (e) {
      debugPrint('[ActiveTrip] Fehler beim Löschen: $e');
    }
  }

  /// Prüft ob ein aktiver Trip vorhanden ist
  Future<bool> hasActiveTrip() async {
    try {
      await _ensureInitialized();
      return _box!.containsKey(_tripKey);
    } catch (e) {
      return false;
    }
  }

  /// Aktualisiert nur den ausgewählten Tag
  Future<void> updateSelectedDay(int day) async {
    try {
      await _ensureInitialized();
      await _box!.put(_selectedDayKey, day);
    } catch (e) {
      debugPrint('[ActiveTrip] Fehler beim Aktualisieren des Tages: $e');
    }
  }

  /// Fügt einen abgeschlossenen Tag hinzu
  Future<void> addCompletedDay(int day) async {
    try {
      await _ensureInitialized();
      final current = (_box!.get(_completedDaysKey) as List<dynamic>?)
              ?.map((e) => e as int)
              .toSet() ??
          {};
      current.add(day);
      await _box!.put(_completedDaysKey, current.toList());
    } catch (e) {
      debugPrint('[ActiveTrip] Fehler beim Hinzufügen des abgeschlossenen Tages: $e');
    }
  }
}

/// Datenklasse für geladene Trip-Daten
class ActiveTripData {
  final Trip trip;
  final Set<int> completedDays;
  final int selectedDay;
  final List<POI> selectedPOIs;
  final List<POI> availablePOIs;
  final LatLng? startLocation;
  final String? startAddress;
  final RandomTripMode mode;
  final int days;
  final double radiusKm;
  final LatLng? destinationLocation;
  final String? destinationAddress;

  ActiveTripData({
    required this.trip,
    required this.completedDays,
    required this.selectedDay,
    this.selectedPOIs = const [],
    this.availablePOIs = const [],
    this.startLocation,
    this.startAddress,
    this.mode = RandomTripMode.eurotrip,
    this.days = 1,
    this.radiusKm = 100,
    this.destinationLocation,
    this.destinationAddress,
  });

  /// Prüft ob alle Tage abgeschlossen sind
  bool get allDaysCompleted => completedDays.length >= trip.actualDays;

  /// Nächster nicht-abgeschlossener Tag
  int? get nextUncompletedDay {
    for (int i = 1; i <= trip.actualDays; i++) {
      if (!completedDays.contains(i)) return i;
    }
    return null;
  }
}

/// Provider für ActiveTripService
@riverpod
ActiveTripService activeTripService(ActiveTripServiceRef ref) {
  return ActiveTripService();
}
