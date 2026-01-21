import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_preferences.freezed.dart';
part 'user_preferences.g.dart';

/// Reise-Stimmung
enum TravelMood {
  romantic('Romantisch', '💕', ['castle', 'viewpoint', 'lake', 'restaurant']),
  adventure('Abenteuer', '🏔️', ['activity', 'nature', 'viewpoint', 'park']),
  relaxed('Entspannt', '🧘', ['park', 'lake', 'coast', 'nature']),
  cultural('Kulturell', '🏛️', ['museum', 'church', 'monument', 'unesco']),
  family('Familie', '👨‍👩‍👧‍👦', ['park', 'activity', 'lake', 'museum']),
  foodie('Kulinarisch', '🍽️', ['restaurant', 'city', 'activity']);

  final String label;
  final String emoji;
  final List<String> preferredCategories;
  const TravelMood(this.label, this.emoji, this.preferredCategories);
}

/// Nutzer-Präferenzen für KI-Empfehlungen
@freezed
class UserPreferences with _$UserPreferences {
  const factory UserPreferences({
    // Bevorzugte Kategorien (gewichtet 0-1)
    @Default({}) Map<String, double> categoryWeights,

    // Bevorzugte Reise-Stimmung
    TravelMood? preferredMood,

    // Maximaler Umweg (km)
    @Default(45) int maxDetourKm,

    // Bevorzugte Aufenthaltsdauer pro POI (Minuten)
    @Default(30) int preferredStopDuration,

    // Indoor vs Outdoor Präferenz (0 = nur Indoor, 1 = nur Outdoor)
    @Default(0.5) double indoorOutdoorBalance,

    // Beliebtheits-Präferenz (0 = Geheimtipps, 1 = bekannte Highlights)
    @Default(0.7) double popularityPreference,

    // Besuchte POI-IDs (für "nicht erneut vorschlagen")
    @Default([]) List<String> visitedPoiIds,

    // Favorisierte POI-IDs
    @Default([]) List<String> favoritePoiIds,

    // Ignorierte POI-IDs
    @Default([]) List<String> ignoredPoiIds,

    // Letzte Trips (für Lernzwecke)
    @Default([]) List<String> recentTripIds,

    // Sprach-Präferenz für Beschreibungen
    @Default('de') String preferredLanguage,

    // Barrierefreiheits-Anforderungen
    @Default(false) bool requireWheelchairAccess,
    @Default(false) bool avoidStairs,

    // Budget-Präferenzen
    @Default(50) int dailyBudgetEur,
    @Default(false) bool preferFreeAttractions,
  }) = _UserPreferences;

  const UserPreferences._();

  /// Gibt die Top-Kategorien nach Gewichtung zurück
  List<String> get topCategories {
    final sorted = categoryWeights.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(5).map((e) => e.key).toList();
  }

  /// Berechnet Score-Boost für eine Kategorie
  double getCategoryBoost(String categoryId) {
    // Basis: explizite Gewichtung
    final explicit = categoryWeights[categoryId] ?? 0.5;

    // Mood-basierter Boost
    double moodBoost = 0;
    if (preferredMood != null &&
        preferredMood!.preferredCategories.contains(categoryId)) {
      moodBoost = 0.2;
    }

    return (explicit + moodBoost).clamp(0.0, 1.0);
  }

  /// Prüft ob POI bereits besucht wurde
  bool hasVisited(String poiId) => visitedPoiIds.contains(poiId);

  /// Prüft ob POI favorisiert ist
  bool isFavorite(String poiId) => favoritePoiIds.contains(poiId);

  /// Prüft ob POI ignoriert werden soll
  bool isIgnored(String poiId) => ignoredPoiIds.contains(poiId);

  factory UserPreferences.fromJson(Map<String, dynamic> json) =>
      _$UserPreferencesFromJson(json);
}

/// Lern-Event für Präferenz-Updates
@freezed
class PreferenceLearningEvent with _$PreferenceLearningEvent {
  const factory PreferenceLearningEvent({
    required String eventType,  // 'visit', 'favorite', 'skip', 'rate'
    required String poiId,
    required String categoryId,
    double? rating,
    int? durationMinutes,
    required DateTime timestamp,
  }) = _PreferenceLearningEvent;

  factory PreferenceLearningEvent.fromJson(Map<String, dynamic> json) =>
      _$PreferenceLearningEventFromJson(json);
}
