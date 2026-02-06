import 'package:flutter/foundation.dart';
import '../models/achievement.dart';
import '../models/user_account.dart';

/// Service fuer Achievement-Pruefung und -Freischaltung
class AchievementService {
  AchievementService._();

  /// Prueft alle Achievements und gibt die neu freigeschalteten zurueck
  static List<Achievement> checkAchievements({
    required UserAccount account,
    int? publishedTrips,
    int? likesReceived,
    int? photoCount,
  }) {
    final newlyUnlocked = <Achievement>[];

    for (final achievement in Achievements.all) {
      // Bereits freigeschaltet? Skip.
      if (account.unlockedAchievements.contains(achievement.id)) {
        continue;
      }

      // Pruefe ob Bedingung erfuellt
      if (_isAchievementUnlocked(
        achievement: achievement,
        account: account,
        publishedTrips: publishedTrips ?? 0,
        likesReceived: likesReceived ?? 0,
        photoCount: photoCount ?? 0,
      )) {
        newlyUnlocked.add(achievement);
        debugPrint('[Achievement] Neu freigeschaltet: ${achievement.id}');
      }
    }

    return newlyUnlocked;
  }

  /// Prueft ob ein einzelnes Achievement freigeschaltet werden sollte
  static bool _isAchievementUnlocked({
    required Achievement achievement,
    required UserAccount account,
    required int publishedTrips,
    required int likesReceived,
    required int photoCount,
  }) {
    // Trip-Achievements
    if (achievement.requiredTrips != null) {
      return account.totalTripsCreated >= achievement.requiredTrips!;
    }

    // POI-Achievements
    if (achievement.requiredPois != null) {
      return account.totalPoisVisited >= achievement.requiredPois!;
    }

    // Kilometer-Achievements
    if (achievement.requiredKm != null) {
      return account.totalKmTraveled >= achievement.requiredKm!;
    }

    // Veroeffentlichte Trips
    if (achievement.requiredPublishedTrips != null) {
      return publishedTrips >= achievement.requiredPublishedTrips!;
    }

    // Likes erhalten
    if (achievement.requiredLikesReceived != null) {
      return likesReceived >= achievement.requiredLikesReceived!;
    }

    // Fotos
    if (achievement.requiredPhotos != null) {
      return photoCount >= achievement.requiredPhotos!;
    }

    // Achievement-Hunter (10 andere Achievements)
    if (achievement.requiredAchievements != null) {
      // Zaehle nur ANDERE Achievements (nicht dieses selbst)
      final otherUnlocked = account.unlockedAchievements
          .where((id) => id != achievement.id)
          .length;
      return otherUnlocked >= achievement.requiredAchievements!;
    }

    return false;
  }

  /// Berechnet den Fortschritt fuer ein Achievement (0.0 - 1.0)
  static double getProgress({
    required Achievement achievement,
    required UserAccount account,
    int? publishedTrips,
    int? likesReceived,
    int? photoCount,
  }) {
    double current = 0;
    double required = 1;

    if (achievement.requiredTrips != null) {
      current = account.totalTripsCreated.toDouble();
      required = achievement.requiredTrips!.toDouble();
    } else if (achievement.requiredPois != null) {
      current = account.totalPoisVisited.toDouble();
      required = achievement.requiredPois!.toDouble();
    } else if (achievement.requiredKm != null) {
      current = account.totalKmTraveled;
      required = achievement.requiredKm!;
    } else if (achievement.requiredPublishedTrips != null) {
      current = (publishedTrips ?? 0).toDouble();
      required = achievement.requiredPublishedTrips!.toDouble();
    } else if (achievement.requiredLikesReceived != null) {
      current = (likesReceived ?? 0).toDouble();
      required = achievement.requiredLikesReceived!.toDouble();
    } else if (achievement.requiredPhotos != null) {
      current = (photoCount ?? 0).toDouble();
      required = achievement.requiredPhotos!.toDouble();
    } else if (achievement.requiredAchievements != null) {
      current = account.unlockedAchievements.length.toDouble();
      required = achievement.requiredAchievements!.toDouble();
    }

    return (current / required).clamp(0.0, 1.0);
  }

  /// Gibt einen formatierten Fortschrittstext zurueck
  static String getProgressText({
    required Achievement achievement,
    required UserAccount account,
    int? publishedTrips,
    int? likesReceived,
    int? photoCount,
    String languageCode = 'de',
  }) {
    if (achievement.requiredTrips != null) {
      return '${account.totalTripsCreated}/${achievement.requiredTrips}';
    } else if (achievement.requiredPois != null) {
      return '${account.totalPoisVisited}/${achievement.requiredPois}';
    } else if (achievement.requiredKm != null) {
      return '${account.totalKmTraveled.toStringAsFixed(0)}/${achievement.requiredKm!.toStringAsFixed(0)} km';
    } else if (achievement.requiredPublishedTrips != null) {
      return '${publishedTrips ?? 0}/${achievement.requiredPublishedTrips}';
    } else if (achievement.requiredLikesReceived != null) {
      return '${likesReceived ?? 0}/${achievement.requiredLikesReceived}';
    } else if (achievement.requiredPhotos != null) {
      return '${photoCount ?? 0}/${achievement.requiredPhotos}';
    } else if (achievement.requiredAchievements != null) {
      return '${account.unlockedAchievements.length}/${achievement.requiredAchievements}';
    }
    return '';
  }

  /// Berechnet die gesamte XP aus allen freigeschalteten Achievements
  static int calculateTotalAchievementXp(List<String> unlockedIds) {
    int total = 0;
    for (final id in unlockedIds) {
      final achievement = Achievements.findById(id);
      if (achievement != null) {
        total += achievement.xpReward;
      }
    }
    return total;
  }

  /// Gibt die naechsten erreichbaren Achievements zurueck (sortiert nach Fortschritt)
  static List<Achievement> getNextAchievements({
    required UserAccount account,
    int? publishedTrips,
    int? likesReceived,
    int? photoCount,
    int limit = 3,
  }) {
    final locked = Achievements.all
        .where((a) => !account.unlockedAchievements.contains(a.id))
        .toList();

    // Sortiere nach Fortschritt (hoechster zuerst)
    locked.sort((a, b) {
      final progressA = getProgress(
        achievement: a,
        account: account,
        publishedTrips: publishedTrips,
        likesReceived: likesReceived,
        photoCount: photoCount,
      );
      final progressB = getProgress(
        achievement: b,
        account: account,
        publishedTrips: publishedTrips,
        likesReceived: likesReceived,
        photoCount: photoCount,
      );
      return progressB.compareTo(progressA);
    });

    return locked.take(limit).toList();
  }
}
