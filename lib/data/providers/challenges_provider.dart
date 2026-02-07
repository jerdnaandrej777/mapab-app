import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:travel_planner/data/models/challenge.dart';

part 'challenges_provider.g.dart';

/// State für das Challenges-System
class ChallengesState {
  final List<UserChallenge> activeChallenges;
  final List<UserChallenge> completedChallenges;
  final UserStreak streak;
  final bool isLoading;
  final String? error;

  const ChallengesState({
    this.activeChallenges = const [],
    this.completedChallenges = const [],
    this.streak = const UserStreak(currentStreak: 0, longestStreak: 0),
    this.isLoading = false,
    this.error,
  });

  ChallengesState copyWith({
    List<UserChallenge>? activeChallenges,
    List<UserChallenge>? completedChallenges,
    UserStreak? streak,
    bool? isLoading,
    String? error,
  }) {
    return ChallengesState(
      activeChallenges: activeChallenges ?? this.activeChallenges,
      completedChallenges: completedChallenges ?? this.completedChallenges,
      streak: streak ?? this.streak,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Wöchentliche Challenges (aktiv und abgeschlossen)
  List<UserChallenge> get weeklyChallenges =>
      [...activeChallenges, ...completedChallenges]
          .where((c) => c.definition.frequency == ChallengeFrequency.weekly)
          .toList();

  /// Anzahl abgeschlossener wöchentlicher Challenges
  int get completedWeeklyCount =>
      weeklyChallenges.where((c) => c.isCompleted).length;

  /// Bonus-XP für alle 3 wöchentlichen Challenges
  int get weeklyBonusXp => completedWeeklyCount >= 3 ? 300 : 0;

  /// Alle wöchentlichen Challenges abgeschlossen?
  bool get allWeeklyCompleted => completedWeeklyCount >= 3;
}

/// Challenges Provider
@Riverpod(keepAlive: true)
class ChallengesNotifier extends _$ChallengesNotifier {
  @override
  ChallengesState build() {
    return const ChallengesState();
  }

  /// Lädt Challenges und Streak für den aktuellen Benutzer
  Future<void> loadChallenges() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        debugPrint('[Challenges] Kein Benutzer eingeloggt');
        return;
      }

      state = state.copyWith(isLoading: true, error: null);

      // Wöchentliche Challenges zuweisen (falls noch nicht vorhanden)
      await supabase.rpc('assign_weekly_challenges', params: {
        'p_user_id': userId,
      });

      // Challenges laden
      final response = await supabase.rpc('get_user_challenges', params: {
        'p_user_id': userId,
      });

      final challenges = (response as List)
          .map((json) => UserChallenge.fromJson(json as Map<String, dynamic>))
          .toList();

      final active = challenges.where((c) => c.isActive).toList();
      final completed = challenges.where((c) => c.isCompleted).toList();

      // Streak laden
      final streakData = await supabase
          .from('user_profiles')
          .select('current_streak, longest_streak, last_activity_date')
          .eq('id', userId)
          .maybeSingle();

      final streak = streakData != null
          ? UserStreak.fromJson(streakData)
          : const UserStreak(currentStreak: 0, longestStreak: 0);

      state = state.copyWith(
        activeChallenges: active,
        completedChallenges: completed,
        streak: streak,
        isLoading: false,
      );

      debugPrint('[Challenges] ${active.length} aktiv, ${completed.length} abgeschlossen');
    } catch (e) {
      debugPrint('[Challenges] Fehler beim Laden: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Aktualisiert den Fortschritt einer Challenge
  Future<bool> updateProgress(String challengeId, {int increment = 1}) async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) return false;

      await supabase.rpc('update_challenge_progress', params: {
        'p_user_id': userId,
        'p_challenge_id': challengeId,
        'p_increment': increment,
      });

      // Challenges neu laden
      await loadChallenges();
      return true;
    } catch (e) {
      debugPrint('[Challenges] Fehler beim Aktualisieren: $e');
      return false;
    }
  }

  /// Aktualisiert den Streak des Benutzers
  Future<bool> updateStreak() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) return false;

      final response = await supabase.rpc('update_user_streak', params: {
        'p_user_id': userId,
      });

      if (response != null && (response as List).isNotEmpty) {
        final data = response.first as Map<String, dynamic>;
        state = state.copyWith(
          streak: UserStreak(
            currentStreak: data['current_streak'] as int? ?? 0,
            longestStreak: data['longest_streak'] as int? ?? 0,
            lastActivityDate: DateTime.now(),
          ),
        );

        final continued = data['streak_continued'] as bool? ?? false;
        debugPrint('[Challenges] Streak aktualisiert: ${state.streak.currentStreak} Tage (fortgesetzt: $continued)');
        return continued;
      }

      return false;
    } catch (e) {
      debugPrint('[Challenges] Fehler beim Streak-Update: $e');
      return false;
    }
  }

  /// Registriert einen POI-Besuch für Challenge-Tracking
  Future<void> trackPOIVisit(String categoryId) async {
    // Kategorie-Challenges aktualisieren
    for (final challenge in state.activeChallenges) {
      if (challenge.definition.type == ChallengeType.visitCategory) {
        if (challenge.definition.categoryFilter == null ||
            challenge.definition.categoryFilter == categoryId) {
          await updateProgress(challenge.definition.id);
        }
      } else if (challenge.definition.type == ChallengeType.discover) {
        await updateProgress(challenge.definition.id);
      }
    }

    // Streak aktualisieren
    await updateStreak();
  }

  /// Registriert einen Trip-Abschluss
  Future<void> trackTripCompleted(double distanceKm) async {
    for (final challenge in state.activeChallenges) {
      if (challenge.definition.type == ChallengeType.completeTrips) {
        await updateProgress(challenge.definition.id);
      } else if (challenge.definition.type == ChallengeType.distance) {
        await updateProgress(challenge.definition.id, increment: distanceKm.round());
      }
    }

    await updateStreak();
  }

  /// Registriert ein Foto
  Future<void> trackPhotoTaken() async {
    for (final challenge in state.activeChallenges) {
      if (challenge.definition.type == ChallengeType.takePhotos) {
        await updateProgress(challenge.definition.id);
      }
    }

    await updateStreak();
  }

  /// Registriert eine Social-Aktion (Teilen)
  Future<void> trackSocialShare() async {
    for (final challenge in state.activeChallenges) {
      if (challenge.definition.type == ChallengeType.social) {
        await updateProgress(challenge.definition.id);
      }
    }
  }
}
