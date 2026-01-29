import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/trip.dart';

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
    List<dynamic>? selectedPOIs,
    List<dynamic>? availablePOIs,
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

      debugPrint('[ActiveTrip] Trip geladen: ${trip.name}, Tag $selectedDay');

      return ActiveTripData(
        trip: trip,
        completedDays: completedDays,
        selectedDay: selectedDay,
      );
    } catch (e) {
      debugPrint('[ActiveTrip] Fehler beim Laden: $e');
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

  ActiveTripData({
    required this.trip,
    required this.completedDays,
    required this.selectedDay,
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
