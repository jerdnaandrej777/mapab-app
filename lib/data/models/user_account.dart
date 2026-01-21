import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_account.freezed.dart';
part 'user_account.g.dart';

/// User Account Type
enum UserAccountType {
  local,
  google,
  apple,
  firebase,
}

/// User Account Model (Local-First)
@freezed
class UserAccount with _$UserAccount {
  const factory UserAccount({
    required String id,
    required String username,
    required String displayName,
    String? email,
    String? avatarUrl,
    @Default(UserAccountType.local) UserAccountType type,
    required DateTime createdAt,
    DateTime? lastLoginAt,

    // Verknüpfungen
    @Default([]) List<String> favoriteTripIds,
    @Default([]) List<String> favoritePoiIds,
    @Default([]) List<String> journalEntryIds,

    // Gamification
    @Default(0) int totalXp,
    @Default(1) int level,
    @Default([]) List<String> unlockedAchievements,

    // Präferenzen (Link zu UserPreferences)
    String? preferencesId,

    // Statistiken
    @Default(0) int totalTripsCreated,
    @Default(0.0) double totalKmTraveled,
    @Default(0) int totalPoisVisited,
  }) = _UserAccount;

  const UserAccount._();

  /// Prüft ob Account ein Gast-Account ist
  bool get isGuest => username.startsWith('guest_');

  /// Berechnet Level basierend auf XP
  /// 100 XP = Level 1, 300 XP = Level 2, etc.
  int calculateLevel(int xp) {
    return (xp / 100).floor() + 1;
  }

  /// XP bis zum nächsten Level
  int get xpToNextLevel {
    final nextLevelXp = level * 100;
    return nextLevelXp - totalXp;
  }

  /// Fortschritt zum nächsten Level (0.0 - 1.0)
  double get levelProgress {
    final currentLevelXp = (level - 1) * 100;
    final nextLevelXp = level * 100;
    final progress = (totalXp - currentLevelXp) / (nextLevelXp - currentLevelXp);
    return progress.clamp(0.0, 1.0);
  }

  factory UserAccount.fromJson(Map<String, dynamic> json) =>
      _$UserAccountFromJson(json);
}
