import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_preferences.dart';

part 'preferences_provider.g.dart';

/// User Preferences Provider mit Lern-Algorithmus
@Riverpod(keepAlive: true)
class UserPreferencesNotifier extends _$UserPreferencesNotifier {
  late Box _box;

  @override
  UserPreferences build() {
    _box = Hive.box('settings');
    return _loadPreferences();
  }

  UserPreferences _loadPreferences() {
    final json = _box.get('userPreferences');
    if (json != null) {
      try {
        return UserPreferences.fromJson(Map<String, dynamic>.from(json));
      } catch (e) {
        debugPrint('[Preferences] Laden fehlgeschlagen: $e');
      }
    }
    return const UserPreferences();
  }

  Future<void> _savePreferences() async {
    await _box.put('userPreferences', state.toJson());
  }

  /// Setzt die bevorzugte Stimmung
  Future<void> setMood(TravelMood mood) async {
    state = state.copyWith(preferredMood: mood);
    await _savePreferences();
  }

  /// Aktualisiert Kategorie-Gewichtung
  Future<void> updateCategoryWeight(String categoryId, double weight) async {
    final newWeights = Map<String, double>.from(state.categoryWeights);
    newWeights[categoryId] = weight.clamp(0.0, 1.0);
    state = state.copyWith(categoryWeights: newWeights);
    await _savePreferences();
  }

  /// Setzt maximalen Umweg
  Future<void> setMaxDetour(int km) async {
    state = state.copyWith(maxDetourKm: km);
    await _savePreferences();
  }

  /// Setzt bevorzugte Aufenthaltsdauer
  Future<void> setStopDuration(int minutes) async {
    state = state.copyWith(preferredStopDuration: minutes);
    await _savePreferences();
  }

  /// Markiert POI als besucht
  Future<void> markAsVisited(String poiId) async {
    if (!state.visitedPoiIds.contains(poiId)) {
      state = state.copyWith(
        visitedPoiIds: [...state.visitedPoiIds, poiId],
      );
      await _savePreferences();
    }
  }

  /// Fügt POI zu Favoriten hinzu
  Future<void> addToFavorites(String poiId) async {
    if (!state.favoritePoiIds.contains(poiId)) {
      state = state.copyWith(
        favoritePoiIds: [...state.favoritePoiIds, poiId],
      );
      await _savePreferences();
    }
  }

  /// Entfernt POI aus Favoriten
  Future<void> removeFromFavorites(String poiId) async {
    state = state.copyWith(
      favoritePoiIds: state.favoritePoiIds.where((id) => id != poiId).toList(),
    );
    await _savePreferences();
  }

  /// Ignoriert einen POI (wird nicht mehr vorgeschlagen)
  Future<void> ignorePoi(String poiId) async {
    if (!state.ignoredPoiIds.contains(poiId)) {
      state = state.copyWith(
        ignoredPoiIds: [...state.ignoredPoiIds, poiId],
      );
      await _savePreferences();
    }
  }

  /// Setzt Barrierefreiheits-Einstellungen
  Future<void> setAccessibilityRequirements({
    bool? wheelchair,
    bool? noStairs,
  }) async {
    state = state.copyWith(
      requireWheelchairAccess: wheelchair ?? state.requireWheelchairAccess,
      avoidStairs: noStairs ?? state.avoidStairs,
    );
    await _savePreferences();
  }

  /// Setzt Budget-Präferenzen
  Future<void> setBudgetPreferences({
    int? dailyBudget,
    bool? preferFree,
  }) async {
    state = state.copyWith(
      dailyBudgetEur: dailyBudget ?? state.dailyBudgetEur,
      preferFreeAttractions: preferFree ?? state.preferFreeAttractions,
    );
    await _savePreferences();
  }

  /// Lernt aus Nutzer-Interaktion
  Future<void> learnFromEvent(PreferenceLearningEvent event) async {
    final weights = Map<String, double>.from(state.categoryWeights);
    final currentWeight = weights[event.categoryId] ?? 0.5;

    switch (event.eventType) {
      case 'visit':
        // Besuch erhöht Gewichtung leicht
        weights[event.categoryId] = (currentWeight + 0.05).clamp(0.0, 1.0);
        break;

      case 'favorite':
        // Favorit erhöht Gewichtung stark
        weights[event.categoryId] = (currentWeight + 0.15).clamp(0.0, 1.0);
        break;

      case 'skip':
        // Überspringen verringert Gewichtung
        weights[event.categoryId] = (currentWeight - 0.05).clamp(0.0, 1.0);
        break;

      case 'rate':
        // Bewertung passt Gewichtung an
        if (event.rating != null) {
          final adjustment = (event.rating! - 3) * 0.05;  // -0.1 bis +0.1
          weights[event.categoryId] = (currentWeight + adjustment).clamp(0.0, 1.0);
        }
        break;
    }

    state = state.copyWith(categoryWeights: weights);
    await _savePreferences();
  }

  /// Gibt personalisierte Kategorie-Empfehlungen
  List<String> getRecommendedCategories({int limit = 5}) {
    // Basis: aktuelle Gewichtungen
    final scores = <String, double>{};

    // Explizite Gewichtungen
    for (final entry in state.categoryWeights.entries) {
      scores[entry.key] = entry.value;
    }

    // Mood-basierte Empfehlungen
    if (state.preferredMood != null) {
      for (final cat in state.preferredMood!.preferredCategories) {
        scores[cat] = (scores[cat] ?? 0.5) + 0.2;
      }
    }

    // Indoor/Outdoor Balance
    final indoorCats = ['museum', 'church', 'restaurant'];
    final outdoorCats = ['nature', 'viewpoint', 'park', 'lake', 'coast'];

    for (final cat in indoorCats) {
      scores[cat] = (scores[cat] ?? 0.5) * (1 - state.indoorOutdoorBalance + 0.5);
    }
    for (final cat in outdoorCats) {
      scores[cat] = (scores[cat] ?? 0.5) * (state.indoorOutdoorBalance + 0.5);
    }

    // Sortieren und zurückgeben
    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(limit).map((e) => e.key).toList();
  }

  /// Setzt alle Präferenzen zurück
  Future<void> resetPreferences() async {
    state = const UserPreferences();
    await _savePreferences();
  }
}
