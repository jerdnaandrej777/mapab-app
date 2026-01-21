import 'package:freezed_annotation/freezed_annotation.dart';

part 'statistics.freezed.dart';
part 'statistics.g.dart';

/// Achievement-Kategorie
enum AchievementCategory {
  distance('Distanz', '🛣️'),
  visits('Besuche', '📍'),
  categories('Kategorien', '🏷️'),
  regions('Regionen', '🗺️'),
  streaks('Serien', '🔥'),
  special('Spezial', '⭐');

  final String label;
  final String emoji;
  const AchievementCategory(this.label, this.emoji);
}

/// Achievement-Definition
@freezed
class Achievement with _$Achievement {
  const factory Achievement({
    required String id,
    required String title,
    required String description,
    required String emoji,
    required AchievementCategory category,
    required int targetValue,
    @Default(0) int currentValue,
    @Default(false) bool isUnlocked,
    DateTime? unlockedAt,
    int? xpReward,
  }) = _Achievement;

  const Achievement._();

  double get progress => (currentValue / targetValue).clamp(0.0, 1.0);
  int get progressPercent => (progress * 100).round();

  factory Achievement.fromJson(Map<String, dynamic> json) =>
      _$AchievementFromJson(json);
}

/// Reise-Statistiken
@freezed
class TravelStatistics with _$TravelStatistics {
  const factory TravelStatistics({
    // Distanz
    @Default(0) double totalDistanceKm,
    @Default(0) double longestTripKm,
    @Default(0) double averageTripKm,

    // Besuche
    @Default(0) int totalPoisVisited,
    @Default(0) int uniquePoisVisited,
    @Default(0) int totalTrips,
    @Default(0) int tripsThisYear,
    @Default(0) int tripsThisMonth,

    // Kategorien
    @Default({}) Map<String, int> visitsByCategory,

    // Regionen (Bundesländer/Länder)
    @Default({}) Map<String, int> visitsByRegion,
    @Default([]) List<String> visitedCountries,

    // Zeit
    @Default(0) int totalTripMinutes,
    @Default(0) int averageTripMinutes,

    // Favoriten
    @Default(0) int totalFavorites,
    @Default('') String mostVisitedCategory,

    // Serien
    @Default(0) int currentStreak,  // Tage in Folge mit Trip
    @Default(0) int longestStreak,
    DateTime? lastTripDate,

    // Level & XP
    @Default(1) int level,
    @Default(0) int totalXp,
    @Default(0) int xpToNextLevel,

    // Achievements
    @Default([]) List<String> unlockedAchievementIds,

    // Zeitstempel
    DateTime? lastUpdated,
  }) = _TravelStatistics;

  const TravelStatistics._();

  /// Level-Name basierend auf XP
  String get levelTitle {
    if (level >= 50) return 'Reise-Legende';
    if (level >= 40) return 'Weltenbummler';
    if (level >= 30) return 'Entdecker';
    if (level >= 20) return 'Abenteurer';
    if (level >= 10) return 'Reisender';
    if (level >= 5) return 'Tourist';
    return 'Anfänger';
  }

  /// Formatierte Gesamtdistanz
  String get formattedTotalDistance {
    if (totalDistanceKm >= 1000) {
      return '${(totalDistanceKm / 1000).toStringAsFixed(1)}k km';
    }
    return '${totalDistanceKm.round()} km';
  }

  /// Top-Kategorie
  String get topCategory {
    if (visitsByCategory.isEmpty) return '';
    final sorted = visitsByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  factory TravelStatistics.fromJson(Map<String, dynamic> json) =>
      _$TravelStatisticsFromJson(json);
}

/// Vordefinierte Achievements
class Achievements {
  static List<Achievement> get all => [
    // Distanz
    const Achievement(
      id: 'dist_100',
      title: 'Erste Schritte',
      description: '100 km insgesamt gefahren',
      emoji: '🚗',
      category: AchievementCategory.distance,
      targetValue: 100,
      xpReward: 50,
    ),
    const Achievement(
      id: 'dist_1000',
      title: 'Straßen-Erkunder',
      description: '1.000 km insgesamt gefahren',
      emoji: '🛣️',
      category: AchievementCategory.distance,
      targetValue: 1000,
      xpReward: 200,
    ),
    const Achievement(
      id: 'dist_10000',
      title: 'Vielfahrer',
      description: '10.000 km insgesamt gefahren',
      emoji: '🌍',
      category: AchievementCategory.distance,
      targetValue: 10000,
      xpReward: 1000,
    ),

    // Besuche
    const Achievement(
      id: 'visit_10',
      title: 'Neugierig',
      description: '10 POIs besucht',
      emoji: '👀',
      category: AchievementCategory.visits,
      targetValue: 10,
      xpReward: 50,
    ),
    const Achievement(
      id: 'visit_50',
      title: 'Sammler',
      description: '50 POIs besucht',
      emoji: '📸',
      category: AchievementCategory.visits,
      targetValue: 50,
      xpReward: 150,
    ),
    const Achievement(
      id: 'visit_100',
      title: 'Entdecker',
      description: '100 POIs besucht',
      emoji: '🏆',
      category: AchievementCategory.visits,
      targetValue: 100,
      xpReward: 500,
    ),

    // Kategorien
    const Achievement(
      id: 'cat_castle_10',
      title: 'Burgherr',
      description: '10 Schlösser & Burgen besucht',
      emoji: '🏰',
      category: AchievementCategory.categories,
      targetValue: 10,
      xpReward: 100,
    ),
    const Achievement(
      id: 'cat_nature_10',
      title: 'Naturfreund',
      description: '10 Naturziele besucht',
      emoji: '🌲',
      category: AchievementCategory.categories,
      targetValue: 10,
      xpReward: 100,
    ),
    const Achievement(
      id: 'cat_museum_10',
      title: 'Kulturbanause',
      description: '10 Museen besucht',
      emoji: '🏛️',
      category: AchievementCategory.categories,
      targetValue: 10,
      xpReward: 100,
    ),
    const Achievement(
      id: 'cat_unesco_5',
      title: 'Welterbe-Kenner',
      description: '5 UNESCO-Welterbestätten besucht',
      emoji: '🌍',
      category: AchievementCategory.categories,
      targetValue: 5,
      xpReward: 250,
    ),

    // Regionen
    const Achievement(
      id: 'region_5',
      title: 'Regional-Erkunder',
      description: '5 verschiedene Bundesländer besucht',
      emoji: '🗺️',
      category: AchievementCategory.regions,
      targetValue: 5,
      xpReward: 150,
    ),
    const Achievement(
      id: 'country_3',
      title: 'Grenzgänger',
      description: '3 verschiedene Länder besucht',
      emoji: '🌐',
      category: AchievementCategory.regions,
      targetValue: 3,
      xpReward: 300,
    ),

    // Serien
    const Achievement(
      id: 'streak_7',
      title: 'Wochenreisender',
      description: '7 Tage in Folge einen Trip gemacht',
      emoji: '🔥',
      category: AchievementCategory.streaks,
      targetValue: 7,
      xpReward: 200,
    ),
    const Achievement(
      id: 'streak_30',
      title: 'Monatsreisender',
      description: '30 Tage in Folge einen Trip gemacht',
      emoji: '💪',
      category: AchievementCategory.streaks,
      targetValue: 30,
      xpReward: 1000,
    ),

    // Spezial
    const Achievement(
      id: 'special_first',
      title: 'Willkommen!',
      description: 'Ersten Trip abgeschlossen',
      emoji: '🎉',
      category: AchievementCategory.special,
      targetValue: 1,
      xpReward: 25,
    ),
    const Achievement(
      id: 'special_allcat',
      title: 'Allrounder',
      description: 'Alle POI-Kategorien besucht',
      emoji: '🌈',
      category: AchievementCategory.special,
      targetValue: 15,  // Anzahl Kategorien
      xpReward: 500,
    ),
  ];

  /// XP für nächstes Level berechnen
  static int xpForLevel(int level) {
    // Exponentielles Wachstum
    return (100 * (1.5 * level)).round();
  }

  /// Level aus XP berechnen
  static int levelFromXp(int totalXp) {
    int level = 1;
    int xpNeeded = 0;
    while (xpNeeded + xpForLevel(level) <= totalXp) {
      xpNeeded += xpForLevel(level);
      level++;
    }
    return level;
  }
}
