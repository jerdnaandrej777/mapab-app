import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/achievement.dart';
import '../models/user_account.dart';
import '../services/achievement_service.dart';
import 'account_provider.dart';

part 'gamification_provider.g.dart';

/// Event-Typen fuer Gamification-Benachrichtigungen
sealed class GamificationEvent {
  const GamificationEvent();
}

/// XP wurde verdient
class XpEarnedEvent extends GamificationEvent {
  final int amount;
  final String reason;

  const XpEarnedEvent({required this.amount, required this.reason});
}

/// Level-Up erreicht
class LevelUpEvent extends GamificationEvent {
  final int newLevel;
  final int previousLevel;

  const LevelUpEvent({required this.newLevel, required this.previousLevel});
}

/// Achievement freigeschaltet
class AchievementUnlockedEvent extends GamificationEvent {
  final Achievement achievement;

  const AchievementUnlockedEvent({required this.achievement});
}

/// State fuer Gamification-Events
class GamificationState {
  final List<GamificationEvent> pendingEvents;
  final int publishedTrips;
  final int likesReceived;
  final int photoCount;

  const GamificationState({
    this.pendingEvents = const [],
    this.publishedTrips = 0,
    this.likesReceived = 0,
    this.photoCount = 0,
  });

  GamificationState copyWith({
    List<GamificationEvent>? pendingEvents,
    int? publishedTrips,
    int? likesReceived,
    int? photoCount,
  }) {
    return GamificationState(
      pendingEvents: pendingEvents ?? this.pendingEvents,
      publishedTrips: publishedTrips ?? this.publishedTrips,
      likesReceived: likesReceived ?? this.likesReceived,
      photoCount: photoCount ?? this.photoCount,
    );
  }
}

/// Provider fuer Gamification-Events und Achievement-Tracking
@Riverpod(keepAlive: true)
class GamificationNotifier extends _$GamificationNotifier {
  @override
  GamificationState build() {
    return const GamificationState();
  }

  /// Vergibt XP und prueft automatisch auf neue Achievements
  Future<void> awardXp({
    required int amount,
    required String reason,
  }) async {
    final accountNotifier = ref.read(accountNotifierProvider.notifier);
    final account = ref.read(accountNotifierProvider).value;

    if (account == null) {
      debugPrint('[Gamification] Kein Account vorhanden');
      return;
    }

    final previousLevel = account.level;

    // XP hinzufuegen
    await accountNotifier.addXp(amount);

    // Aktuellen Account neu laden
    final updatedAccount = ref.read(accountNotifierProvider).value;
    if (updatedAccount == null) return;

    final events = <GamificationEvent>[];

    // XP-Event
    events.add(XpEarnedEvent(amount: amount, reason: reason));

    // Level-Up pruefen
    if (updatedAccount.level > previousLevel) {
      events.add(LevelUpEvent(
        newLevel: updatedAccount.level,
        previousLevel: previousLevel,
      ));
      debugPrint('[Gamification] Level Up! ${previousLevel} -> ${updatedAccount.level}');
    }

    // Achievements pruefen
    await _checkAndUnlockAchievements(updatedAccount, events);

    // Events zum State hinzufuegen
    state = state.copyWith(
      pendingEvents: [...state.pendingEvents, ...events],
    );
  }

  /// Prueft und schaltet Achievements frei
  Future<void> _checkAndUnlockAchievements(
    UserAccount account,
    List<GamificationEvent> events,
  ) async {
    final newlyUnlocked = AchievementService.checkAchievements(
      account: account,
      publishedTrips: state.publishedTrips,
      likesReceived: state.likesReceived,
      photoCount: state.photoCount,
    );

    if (newlyUnlocked.isEmpty) return;

    final accountNotifier = ref.read(accountNotifierProvider.notifier);

    for (final achievement in newlyUnlocked) {
      // Achievement freischalten
      await accountNotifier.unlockAchievement(achievement.id);

      // Bonus-XP fuer Achievement
      await accountNotifier.addXp(achievement.xpReward);

      // Event hinzufuegen
      events.add(AchievementUnlockedEvent(achievement: achievement));

      debugPrint('[Gamification] Achievement freigeschaltet: ${achievement.id} (+${achievement.xpReward} XP)');
    }
  }

  /// Aktualisiert die Social-Statistiken (fuer Achievement-Pruefung)
  void updateSocialStats({
    int? publishedTrips,
    int? likesReceived,
  }) {
    state = state.copyWith(
      publishedTrips: publishedTrips ?? state.publishedTrips,
      likesReceived: likesReceived ?? state.likesReceived,
    );
  }

  /// Aktualisiert die Foto-Anzahl (fuer Achievement-Pruefung)
  void updatePhotoCount(int count) {
    state = state.copyWith(photoCount: count);
  }

  /// Entfernt das naechste Event aus der Queue (nach Anzeige)
  GamificationEvent? consumeNextEvent() {
    if (state.pendingEvents.isEmpty) return null;

    final event = state.pendingEvents.first;
    state = state.copyWith(
      pendingEvents: state.pendingEvents.skip(1).toList(),
    );
    return event;
  }

  /// Prueft ob Events vorhanden sind
  bool get hasEvents => state.pendingEvents.isNotEmpty;

  /// Gibt alle ausstehenden Events zurueck
  List<GamificationEvent> get pendingEvents => state.pendingEvents;

  /// Loescht alle ausstehenden Events
  void clearEvents() {
    state = state.copyWith(pendingEvents: []);
  }

  // ===== Convenience-Methoden fuer haeufige XP-Vergaben =====

  /// XP fuer Trip-Erstellung
  Future<void> onTripCreated() async {
    await awardXp(
      amount: XPRewards.tripCreated,
      reason: 'Trip erstellt',
    );
  }

  /// XP fuer Trip-Veroeffentlichung
  Future<void> onTripPublished() async {
    state = state.copyWith(publishedTrips: state.publishedTrips + 1);
    await awardXp(
      amount: XPRewards.tripPublished,
      reason: 'Trip veroeffentlicht',
    );
  }

  /// XP fuer Trip-Import
  Future<void> onTripImported() async {
    await awardXp(
      amount: XPRewards.tripImported,
      reason: 'Trip importiert',
    );
  }

  /// XP fuer POI-Besuch
  Future<void> onPoiVisited() async {
    await awardXp(
      amount: XPRewards.poiVisited,
      reason: 'POI besucht',
    );
  }

  /// XP fuer erhaltenen Like
  Future<void> onLikeReceived() async {
    state = state.copyWith(likesReceived: state.likesReceived + 1);
    await awardXp(
      amount: XPRewards.likeReceived,
      reason: 'Like erhalten',
    );
  }

  /// XP fuer Journal-Foto
  Future<void> onJournalPhotoAdded() async {
    state = state.copyWith(photoCount: state.photoCount + 1);
    await awardXp(
      amount: XPRewards.journalPhotoAdded,
      reason: 'Foto hinzugefuegt',
    );
  }

  /// XP fuer Journal-Eintrag
  Future<void> onJournalEntryAdded() async {
    await awardXp(
      amount: XPRewards.journalEntryAdded,
      reason: 'Tagebucheintrag',
    );
  }

  /// Manuelles Achievement-Check triggern
  Future<void> checkAchievements() async {
    final account = ref.read(accountNotifierProvider).value;
    if (account == null) return;

    final events = <GamificationEvent>[];
    await _checkAndUnlockAchievements(account, events);

    if (events.isNotEmpty) {
      state = state.copyWith(
        pendingEvents: [...state.pendingEvents, ...events],
      );
    }
  }
}

/// Provider fuer die naechsten erreichbaren Achievements
@riverpod
List<Achievement> nextAchievements(NextAchievementsRef ref) {
  final account = ref.watch(accountNotifierProvider).value;
  final gamification = ref.watch(gamificationNotifierProvider);

  if (account == null) return [];

  return AchievementService.getNextAchievements(
    account: account,
    publishedTrips: gamification.publishedTrips,
    likesReceived: gamification.likesReceived,
    photoCount: gamification.photoCount,
    limit: 3,
  );
}

/// Provider fuer Achievement-Fortschritt
@riverpod
double achievementProgress(
  AchievementProgressRef ref,
  String achievementId,
) {
  final account = ref.watch(accountNotifierProvider).value;
  final gamification = ref.watch(gamificationNotifierProvider);

  if (account == null) return 0.0;

  final achievement = Achievements.findById(achievementId);
  if (achievement == null) return 0.0;

  return AchievementService.getProgress(
    achievement: achievement,
    account: account,
    publishedTrips: gamification.publishedTrips,
    likesReceived: gamification.likesReceived,
    photoCount: gamification.photoCount,
  );
}
