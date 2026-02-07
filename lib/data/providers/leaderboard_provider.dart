import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:travel_planner/data/repositories/leaderboard_repo.dart';

part 'leaderboard_provider.g.dart';

/// State für das Leaderboard
class LeaderboardState {
  final List<LeaderboardEntry> entries;
  final LeaderboardEntry? myPosition;
  final LeaderboardSortBy sortBy;
  final bool isLoading;
  final String? error;
  final bool hasMore;

  const LeaderboardState({
    this.entries = const [],
    this.myPosition,
    this.sortBy = LeaderboardSortBy.xp,
    this.isLoading = false,
    this.error,
    this.hasMore = true,
  });

  LeaderboardState copyWith({
    List<LeaderboardEntry>? entries,
    LeaderboardEntry? myPosition,
    LeaderboardSortBy? sortBy,
    bool? isLoading,
    String? error,
    bool? hasMore,
  }) {
    return LeaderboardState(
      entries: entries ?? this.entries,
      myPosition: myPosition ?? this.myPosition,
      sortBy: sortBy ?? this.sortBy,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

/// Provider für Leaderboard-Daten
@Riverpod(keepAlive: true)
class LeaderboardNotifier extends _$LeaderboardNotifier {
  late LeaderboardRepository _repo;

  @override
  LeaderboardState build() {
    _repo = LeaderboardRepository(Supabase.instance.client);
    return const LeaderboardState();
  }

  /// Lädt das Leaderboard initial
  Future<void> loadLeaderboard({bool refresh = false}) async {
    if (state.isLoading) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
      entries: refresh ? [] : state.entries,
    );

    try {
      // Lade Leaderboard und eigene Position parallel
      final results = await Future.wait([
        _repo.getLeaderboard(
          sortBy: state.sortBy,
          limit: 50,
          offset: 0,
        ),
        _repo.getMyPosition(sortBy: state.sortBy),
      ]);

      final entries = results[0] as List<LeaderboardEntry>;
      final myPosition = results[1] as LeaderboardEntry?;

      state = state.copyWith(
        entries: entries,
        myPosition: myPosition,
        isLoading: false,
        hasMore: entries.length >= 50,
      );

      debugPrint('[Leaderboard] ${entries.length} Einträge geladen');
    } catch (e) {
      debugPrint('[Leaderboard] Fehler: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Lädt mehr Einträge (Pagination)
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      final newEntries = await _repo.getLeaderboard(
        sortBy: state.sortBy,
        limit: 50,
        offset: state.entries.length,
      );

      state = state.copyWith(
        entries: [...state.entries, ...newEntries],
        isLoading: false,
        hasMore: newEntries.length >= 50,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Ändert die Sortierung
  Future<void> setSortBy(LeaderboardSortBy sortBy) async {
    if (sortBy == state.sortBy) return;

    state = state.copyWith(sortBy: sortBy);
    await loadLeaderboard(refresh: true);
  }

  /// Aktualisiert die Daten
  Future<void> refresh() async {
    await loadLeaderboard(refresh: true);
  }
}
