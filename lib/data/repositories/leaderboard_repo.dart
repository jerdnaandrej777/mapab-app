import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Leaderboard-Eintrag
class LeaderboardEntry {
  final int rank;
  final String oderId;
  final String? displayName;
  final String? avatarUrl;
  final int totalXp;
  final int level;
  final double totalKm;
  final int totalTrips;
  final int totalPois;
  final int totalLikesReceived;
  final int currentStreak;
  final bool isCurrentUser;

  const LeaderboardEntry({
    required this.rank,
    required this.oderId,
    this.displayName,
    this.avatarUrl,
    required this.totalXp,
    required this.level,
    required this.totalKm,
    required this.totalTrips,
    required this.totalPois,
    required this.totalLikesReceived,
    required this.currentStreak,
    this.isCurrentUser = false,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: json['rank'] as int? ?? 0,
      oderId: json['user_id'] as String? ?? '',
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      totalXp: json['total_xp'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      totalKm: (json['total_km'] as num?)?.toDouble() ?? 0.0,
      totalTrips: json['total_trips'] as int? ?? 0,
      totalPois: json['total_pois'] as int? ?? 0,
      totalLikesReceived: json['total_likes_received'] as int? ?? 0,
      currentStreak: json['current_streak'] as int? ?? 0,
      isCurrentUser: json['is_current_user'] as bool? ?? false,
    );
  }

  /// Anzeigename mit Fallback
  String get displayNameOrAnonymous => displayName ?? 'Anonymer Reisender';
}

/// Sortieroptionen für das Leaderboard
enum LeaderboardSortBy {
  xp('xp', 'XP'),
  km('km', 'Kilometer'),
  trips('trips', 'Trips'),
  likes('likes', 'Likes');

  final String value;
  final String label;

  const LeaderboardSortBy(this.value, this.label);
}

/// Repository für Leaderboard-Daten
class LeaderboardRepository {
  final SupabaseClient _client;

  LeaderboardRepository(this._client);

  /// Lädt das Leaderboard
  Future<List<LeaderboardEntry>> getLeaderboard({
    LeaderboardSortBy sortBy = LeaderboardSortBy.xp,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final response = await _client.rpc(
        'get_leaderboard',
        params: {
          'p_sort_by': sortBy.value,
          'p_limit': limit,
          'p_offset': offset,
        },
      );

      if (response == null) {
        return [];
      }

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((json) => LeaderboardEntry.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[Leaderboard] Fehler beim Laden: $e');
      return [];
    }
  }

  /// Lädt die eigene Position im Leaderboard
  Future<LeaderboardEntry?> getMyPosition({
    LeaderboardSortBy sortBy = LeaderboardSortBy.xp,
  }) async {
    try {
      final response = await _client.rpc(
        'get_my_leaderboard_position',
        params: {
          'p_sort_by': sortBy.value,
        },
      );

      final responseList = response as List?;
      if (responseList == null || responseList.isEmpty) {
        return null;
      }

      final data = responseList.first as Map<String, dynamic>;
      return LeaderboardEntry.fromJson({
        ...data,
        'is_current_user': true,
      });
    } catch (e) {
      debugPrint('[Leaderboard] Fehler beim Laden der eigenen Position: $e');
      return null;
    }
  }

  /// Aktualisiert XP des Benutzers
  Future<bool> updateXp(int amount) async {
    try {
      await _client.rpc(
        'update_user_xp',
        params: {'p_xp_amount': amount},
      );
      return true;
    } catch (e) {
      debugPrint('[Leaderboard] Fehler beim XP-Update: $e');
      return false;
    }
  }

  /// Aktualisiert den Streak des Benutzers
  Future<bool> updateStreak() async {
    try {
      await _client.rpc('update_user_streak');
      return true;
    } catch (e) {
      debugPrint('[Leaderboard] Fehler beim Streak-Update: $e');
      return false;
    }
  }
}
