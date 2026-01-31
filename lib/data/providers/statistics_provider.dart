import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/statistics.dart';

part 'statistics_provider.g.dart';

/// Statistics Provider für Reise-Statistiken und Achievements
@Riverpod(keepAlive: true)
class StatisticsNotifier extends _$StatisticsNotifier {
  late Box _box;

  @override
  TravelStatistics build() {
    _box = Hive.box('settings');
    return _loadStatistics();
  }

  TravelStatistics _loadStatistics() {
    final json = _box.get('travelStatistics');
    if (json != null) {
      try {
        return TravelStatistics.fromJson(Map<String, dynamic>.from(json));
      } catch (e) {
        debugPrint('[Statistics] Laden fehlgeschlagen: $e');
      }
    }
    return const TravelStatistics();
  }

  Future<void> _saveStatistics() async {
    await _box.put('travelStatistics', state.toJson());
  }

  /// Registriert einen abgeschlossenen Trip
  Future<List<Achievement>> recordTrip({
    required double distanceKm,
    required List<String> visitedPoiIds,
    required Map<String, int> categoryVisits,
    required List<String> regions,
    required int durationMinutes,
  }) async {
    final newUnlocked = <Achievement>[];

    // Distanz aktualisieren
    final newTotalDistance = state.totalDistanceKm + distanceKm;
    final newLongestTrip = distanceKm > state.longestTripKm
        ? distanceKm
        : state.longestTripKm;

    // Besuche aktualisieren
    final newTotalVisits = state.totalPoisVisited + visitedPoiIds.length;
    final existingUnique = Set<String>.from(
      _box.get('visitedPoiIds', defaultValue: <String>[]) as List,
    );
    existingUnique.addAll(visitedPoiIds);
    await _box.put('visitedPoiIds', existingUnique.toList());

    // Kategorien aktualisieren
    final newCategoryVisits = Map<String, int>.from(state.visitsByCategory);
    for (final entry in categoryVisits.entries) {
      newCategoryVisits[entry.key] =
          (newCategoryVisits[entry.key] ?? 0) + entry.value;
    }

    // Regionen aktualisieren
    final newRegionVisits = Map<String, int>.from(state.visitsByRegion);
    for (final region in regions) {
      newRegionVisits[region] = (newRegionVisits[region] ?? 0) + 1;
    }

    // Länder extrahieren (z.B. "DE-BY" -> "DE")
    final countries = regions
        .map((r) => r.split('-').first)
        .toSet()
        .toList();
    final newCountries = {...state.visitedCountries, ...countries}.toList();

    // Streak berechnen
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int newStreak = state.currentStreak;

    if (state.lastTripDate != null) {
      final lastTrip = DateTime(
        state.lastTripDate!.year,
        state.lastTripDate!.month,
        state.lastTripDate!.day,
      );
      final daysDiff = today.difference(lastTrip).inDays;

      if (daysDiff == 1) {
        newStreak++;
      } else if (daysDiff > 1) {
        newStreak = 1;
      }
      // Wenn daysDiff == 0, Streak bleibt gleich
    } else {
      newStreak = 1;
    }

    final newLongestStreak = newStreak > state.longestStreak
        ? newStreak
        : state.longestStreak;

    // Trip-Zähler
    final newTotalTrips = state.totalTrips + 1;
    final tripYear = now.year;
    final tripMonth = now.month;
    final currentYear = DateTime.now().year;
    final currentMonth = DateTime.now().month;

    int newTripsThisYear = state.tripsThisYear;
    int newTripsThisMonth = state.tripsThisMonth;

    if (tripYear == currentYear) newTripsThisYear++;
    if (tripYear == currentYear && tripMonth == currentMonth) newTripsThisMonth++;

    // Durchschnitte berechnen
    final newAvgTrip = newTotalDistance / newTotalTrips;
    final newTotalMinutes = state.totalTripMinutes + durationMinutes;
    final newAvgMinutes = newTotalMinutes ~/ newTotalTrips;

    // XP vergeben
    int xpEarned = 0;
    xpEarned += (distanceKm / 10).round();  // 1 XP pro 10 km
    xpEarned += visitedPoiIds.length * 5;   // 5 XP pro POI
    xpEarned += newStreak * 2;              // Streak-Bonus

    final newTotalXp = state.totalXp + xpEarned;
    final newLevel = Achievements.levelFromXp(newTotalXp);
    final xpForNext = Achievements.xpForLevel(newLevel);
    final xpInCurrentLevel = newTotalXp - _totalXpForLevel(newLevel - 1);
    final xpToNext = xpForNext - xpInCurrentLevel;

    // State aktualisieren
    state = state.copyWith(
      totalDistanceKm: newTotalDistance,
      longestTripKm: newLongestTrip,
      averageTripKm: newAvgTrip,
      totalPoisVisited: newTotalVisits,
      uniquePoisVisited: existingUnique.length,
      totalTrips: newTotalTrips,
      tripsThisYear: newTripsThisYear,
      tripsThisMonth: newTripsThisMonth,
      visitsByCategory: newCategoryVisits,
      visitsByRegion: newRegionVisits,
      visitedCountries: newCountries,
      totalTripMinutes: newTotalMinutes,
      averageTripMinutes: newAvgMinutes,
      currentStreak: newStreak,
      longestStreak: newLongestStreak,
      lastTripDate: now,
      level: newLevel,
      totalXp: newTotalXp,
      xpToNextLevel: xpToNext,
      lastUpdated: now,
    );

    // Achievements prüfen
    newUnlocked.addAll(await _checkAchievements());

    await _saveStatistics();
    return newUnlocked;
  }

  /// Prüft und schaltet Achievements frei
  Future<List<Achievement>> _checkAchievements() async {
    final newUnlocked = <Achievement>[];
    final unlockedIds = Set<String>.from(state.unlockedAchievementIds);

    for (final achievement in Achievements.all) {
      if (unlockedIds.contains(achievement.id)) continue;

      final currentValue = _getAchievementProgress(achievement);
      if (currentValue >= achievement.targetValue) {
        unlockedIds.add(achievement.id);
        newUnlocked.add(achievement.copyWith(
          currentValue: currentValue,
          isUnlocked: true,
          unlockedAt: DateTime.now(),
        ));

        // XP für Achievement vergeben
        if (achievement.xpReward != null) {
          state = state.copyWith(
            totalXp: state.totalXp + achievement.xpReward!,
          );
        }
      }
    }

    if (newUnlocked.isNotEmpty) {
      state = state.copyWith(unlockedAchievementIds: unlockedIds.toList());
    }

    return newUnlocked;
  }

  /// Holt aktuellen Fortschritt für ein Achievement
  int _getAchievementProgress(Achievement achievement) {
    switch (achievement.id) {
      // Distanz
      case 'dist_100':
      case 'dist_1000':
      case 'dist_10000':
        return state.totalDistanceKm.round();

      // Besuche
      case 'visit_10':
      case 'visit_50':
      case 'visit_100':
        return state.uniquePoisVisited;

      // Kategorien
      case 'cat_castle_10':
        return state.visitsByCategory['castle'] ?? 0;
      case 'cat_nature_10':
        return state.visitsByCategory['nature'] ?? 0;
      case 'cat_museum_10':
        return state.visitsByCategory['museum'] ?? 0;
      case 'cat_unesco_5':
        return state.visitsByCategory['unesco'] ?? 0;

      // Regionen
      case 'region_5':
        return state.visitsByRegion.length;
      case 'country_3':
        return state.visitedCountries.length;

      // Serien
      case 'streak_7':
      case 'streak_30':
        return state.longestStreak;

      // Spezial
      case 'special_first':
        return state.totalTrips;
      case 'special_allcat':
        return state.visitsByCategory.length;

      default:
        return 0;
    }
  }

  int _totalXpForLevel(int level) {
    int total = 0;
    for (int i = 1; i <= level; i++) {
      total += Achievements.xpForLevel(i);
    }
    return total;
  }

  /// Holt alle Achievements mit aktuellem Fortschritt
  List<Achievement> getAllAchievements() {
    return Achievements.all.map((a) {
      final currentValue = _getAchievementProgress(a);
      final isUnlocked = state.unlockedAchievementIds.contains(a.id);
      return a.copyWith(
        currentValue: currentValue,
        isUnlocked: isUnlocked,
      );
    }).toList();
  }

  /// Holt nur freigeschaltete Achievements
  List<Achievement> getUnlockedAchievements() {
    return getAllAchievements().where((a) => a.isUnlocked).toList();
  }

  /// Holt Achievements in Arbeit (>0% aber <100%)
  List<Achievement> getInProgressAchievements() {
    return getAllAchievements()
        .where((a) => !a.isUnlocked && a.currentValue > 0)
        .toList();
  }

  /// Setzt Statistiken zurück
  Future<void> resetStatistics() async {
    state = const TravelStatistics();
    await _box.delete('visitedPoiIds');
    await _saveStatistics();
  }
}
