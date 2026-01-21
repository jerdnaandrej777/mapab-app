import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../models/user_account.dart';

part 'account_provider.g.dart';

const _uuid = Uuid();

/// Provider für User Account Management
@riverpod
class AccountNotifier extends _$AccountNotifier {
  late Box _accountBox;

  @override
  Future<UserAccount?> build() async {
    // Hive Box öffnen
    _accountBox = await Hive.openBox('user_accounts');

    // Lade aktiven Account
    return await _loadActiveAccount();
  }

  /// Lädt den aktiven Account aus Hive
  Future<UserAccount?> _loadActiveAccount() async {
    try {
      final accountJson = _accountBox.get('active_account');
      if (accountJson == null) return null;

      final account = UserAccount.fromJson(Map<String, dynamic>.from(accountJson as Map));

      // Update lastLoginAt
      final updatedAccount = account.copyWith(lastLoginAt: DateTime.now());
      await _saveAccount(updatedAccount);

      return updatedAccount;
    } catch (e) {
      debugPrint('[Account] Fehler beim Laden: $e');
      return null;
    }
  }

  /// Speichert Account in Hive
  Future<void> _saveAccount(UserAccount account) async {
    await _accountBox.put('active_account', account.toJson());
  }

  /// Erstellt einen Gast-Account
  Future<void> createGuestAccount() async {
    final account = UserAccount(
      id: _uuid.v4(),
      username: 'guest_${DateTime.now().millisecondsSinceEpoch}',
      displayName: 'Gast',
      type: UserAccountType.local,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );

    await _saveAccount(account);
    state = AsyncValue.data(account);
  }

  /// Erstellt einen lokalen Account
  Future<void> createLocalAccount({
    required String username,
    required String displayName,
    String? email,
  }) async {
    // Validierung
    if (username.trim().isEmpty || displayName.trim().isEmpty) {
      throw Exception('Username und Display Name sind erforderlich');
    }

    final account = UserAccount(
      id: _uuid.v4(),
      username: username.trim(),
      displayName: displayName.trim(),
      email: email?.trim(),
      type: UserAccountType.local,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );

    await _saveAccount(account);
    state = AsyncValue.data(account);
  }

  /// Aktualisiert Account-Daten
  Future<void> updateAccount({
    String? displayName,
    String? email,
    String? avatarUrl,
  }) async {
    final current = state.value;
    if (current == null) return;

    final updated = current.copyWith(
      displayName: displayName ?? current.displayName,
      email: email ?? current.email,
      avatarUrl: avatarUrl ?? current.avatarUrl,
    );

    await _saveAccount(updated);
    state = AsyncValue.data(updated);
  }

  /// Fügt XP hinzu
  Future<void> addXp(int xp) async {
    final current = state.value;
    if (current == null) return;

    final newTotalXp = current.totalXp + xp;
    final newLevel = current.calculateLevel(newTotalXp);

    final updated = current.copyWith(
      totalXp: newTotalXp,
      level: newLevel,
    );

    await _saveAccount(updated);
    state = AsyncValue.data(updated);

    // Level-up Event
    if (newLevel > current.level) {
      debugPrint('[Account] Level Up! Neues Level: $newLevel');
    }
  }

  /// Schaltet Achievement frei
  Future<void> unlockAchievement(String achievementId) async {
    final current = state.value;
    if (current == null) return;

    if (current.unlockedAchievements.contains(achievementId)) {
      return; // Bereits freigeschaltet
    }

    final updated = current.copyWith(
      unlockedAchievements: [...current.unlockedAchievements, achievementId],
    );

    await _saveAccount(updated);
    state = AsyncValue.data(updated);

    debugPrint('[Account] Achievement freigeschaltet: $achievementId');
  }

  /// Fügt Favoriten-Trip hinzu
  Future<void> addFavoriteTrip(String tripId) async {
    final current = state.value;
    if (current == null) return;

    if (current.favoriteTripIds.contains(tripId)) return;

    final updated = current.copyWith(
      favoriteTripIds: [...current.favoriteTripIds, tripId],
    );

    await _saveAccount(updated);
    state = AsyncValue.data(updated);
  }

  /// Entfernt Favoriten-Trip
  Future<void> removeFavoriteTrip(String tripId) async {
    final current = state.value;
    if (current == null) return;

    final updated = current.copyWith(
      favoriteTripIds: current.favoriteTripIds.where((id) => id != tripId).toList(),
    );

    await _saveAccount(updated);
    state = AsyncValue.data(updated);
  }

  /// Aktualisiert Statistiken nach Trip
  Future<void> updateTripStatistics({
    required double kmTraveled,
    required int poisVisited,
  }) async {
    final current = state.value;
    if (current == null) return;

    final updated = current.copyWith(
      totalTripsCreated: current.totalTripsCreated + 1,
      totalKmTraveled: current.totalKmTraveled + kmTraveled,
      totalPoisVisited: current.totalPoisVisited + poisVisited,
    );

    await _saveAccount(updated);
    state = AsyncValue.data(updated);
  }

  /// Logout (Account aus Speicher entfernen)
  Future<void> logout() async {
    await _accountBox.delete('active_account');
    state = const AsyncValue.data(null);
  }

  /// Account löschen
  Future<void> deleteAccount() async {
    await _accountBox.clear();
    state = const AsyncValue.data(null);
  }
}

/// Helper Provider: Prüft ob User eingeloggt ist
@riverpod
bool isLoggedIn(IsLoggedInRef ref) {
  final account = ref.watch(accountNotifierProvider);
  return account.value != null;
}

/// Helper Provider: Gibt aktuellen Account zurück
@riverpod
UserAccount? currentAccount(CurrentAccountRef ref) {
  return ref.watch(accountNotifierProvider).value;
}
