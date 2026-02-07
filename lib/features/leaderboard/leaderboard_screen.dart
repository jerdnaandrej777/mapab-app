import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_planner/core/l10n/l10n.dart';
import 'package:travel_planner/data/providers/leaderboard_provider.dart';
import 'package:travel_planner/data/repositories/leaderboard_repo.dart';

/// Leaderboard Screen - Rangliste der Benutzer
class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  @override
  void initState() {
    super.initState();
    // Lade Leaderboard beim Start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(leaderboardNotifierProvider.notifier).loadLeaderboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(leaderboardNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.leaderboardTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(leaderboardNotifierProvider.notifier).refresh(),
            tooltip: context.l10n.refresh,
          ),
        ],
      ),
      body: Column(
        children: [
          // Sortier-Tabs
          _buildSortTabs(context, state.sortBy, colorScheme),

          // Eigene Position (wenn nicht in Top 50)
          if (state.myPosition != null && !_isInTopEntries(state))
            _buildMyPositionCard(context, state.myPosition!, colorScheme),

          // Leaderboard-Liste
          Expanded(
            child: _buildLeaderboardList(context, state, colorScheme),
          ),
        ],
      ),
    );
  }

  Widget _buildSortTabs(BuildContext context, LeaderboardSortBy sortBy, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: LeaderboardSortBy.values.map((option) {
            final isSelected = option == sortBy;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(_getSortLabel(context, option)),
                selected: isSelected,
                onSelected: (_) {
                  ref.read(leaderboardNotifierProvider.notifier).setSortBy(option);
                },
                selectedColor: colorScheme.primaryContainer,
                labelStyle: TextStyle(
                  color: isSelected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _getSortLabel(BuildContext context, LeaderboardSortBy sortBy) {
    switch (sortBy) {
      case LeaderboardSortBy.xp:
        return context.l10n.leaderboardSortXp;
      case LeaderboardSortBy.km:
        return context.l10n.leaderboardSortKm;
      case LeaderboardSortBy.trips:
        return context.l10n.leaderboardSortTrips;
      case LeaderboardSortBy.likes:
        return context.l10n.leaderboardSortLikes;
    }
  }

  bool _isInTopEntries(LeaderboardState state) {
    if (state.myPosition == null) return false;
    return state.entries.any((e) => e.isCurrentUser);
  }

  Widget _buildMyPositionCard(BuildContext context, LeaderboardEntry entry, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary, width: 2),
      ),
      child: Row(
        children: [
          // Rang
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                '#${entry.rank}',
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.leaderboardYourPosition,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  entry.displayNameOrAnonymous,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Wert
          _buildValueBadge(context, entry, colorScheme),
        ],
      ),
    );
  }

  Widget _buildLeaderboardList(BuildContext context, LeaderboardState state, ColorScheme colorScheme) {
    if (state.isLoading && state.entries.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(context.l10n.errorGeneric),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => ref.read(leaderboardNotifierProvider.notifier).refresh(),
              child: Text(context.l10n.retry),
            ),
          ],
        ),
      );
    }

    if (state.entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.leaderboard_outlined, size: 48, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(context.l10n.leaderboardEmpty),
          ],
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification) {
          if (notification.metrics.extentAfter < 200) {
            ref.read(leaderboardNotifierProvider.notifier).loadMore();
          }
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: state.entries.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.entries.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final entry = state.entries[index];
          return _buildLeaderboardItem(context, entry, colorScheme);
        },
      ),
    );
  }

  Widget _buildLeaderboardItem(BuildContext context, LeaderboardEntry entry, ColorScheme colorScheme) {
    final isTop3 = entry.rank <= 3;
    final isCurrentUser = entry.isCurrentUser;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? colorScheme.primaryContainer.withValues(alpha: 0.3)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: isCurrentUser
            ? Border.all(color: colorScheme.primary, width: 2)
            : null,
      ),
      child: Row(
        children: [
          // Rang
          _buildRankBadge(entry.rank, isTop3, colorScheme),
          const SizedBox(width: 12),

          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: colorScheme.primary.withValues(alpha: 0.2),
            backgroundImage: entry.avatarUrl != null
                ? NetworkImage(entry.avatarUrl!)
                : null,
            child: entry.avatarUrl == null
                ? Icon(Icons.person, color: colorScheme.primary, size: 20)
                : null,
          ),
          const SizedBox(width: 12),

          // Name & Level
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.displayNameOrAnonymous,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.star, size: 14, color: Colors.amber.shade700),
                    const SizedBox(width: 4),
                    Text(
                      context.l10n.profileLevel(entry.level),
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (entry.currentStreak > 0) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.local_fire_department, size: 14, color: Colors.orange),
                      const SizedBox(width: 2),
                      Text(
                        '${entry.currentStreak}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Wert
          _buildValueBadge(context, entry, colorScheme),
        ],
      ),
    );
  }

  Widget _buildRankBadge(int rank, bool isTop3, ColorScheme colorScheme) {
    Color backgroundColor;
    Color textColor;
    IconData? icon;

    if (rank == 1) {
      backgroundColor = const Color(0xFFFFD700); // Gold
      textColor = Colors.black;
      icon = Icons.emoji_events;
    } else if (rank == 2) {
      backgroundColor = const Color(0xFFC0C0C0); // Silber
      textColor = Colors.black;
      icon = Icons.emoji_events;
    } else if (rank == 3) {
      backgroundColor = const Color(0xFFCD7F32); // Bronze
      textColor = Colors.white;
      icon = Icons.emoji_events;
    } else {
      backgroundColor = colorScheme.surfaceContainerHighest;
      textColor = colorScheme.onSurfaceVariant;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isTop3
            ? [
                BoxShadow(
                  color: backgroundColor.withValues(alpha: 0.5),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Center(
        child: isTop3 && icon != null
            ? Icon(icon, color: textColor, size: 20)
            : Text(
                '$rank',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
      ),
    );
  }

  Widget _buildValueBadge(BuildContext context, LeaderboardEntry entry, ColorScheme colorScheme) {
    final state = ref.watch(leaderboardNotifierProvider);
    String value;
    IconData icon;

    switch (state.sortBy) {
      case LeaderboardSortBy.xp:
        value = '${entry.totalXp}';
        icon = Icons.star;
      case LeaderboardSortBy.km:
        value = '${entry.totalKm.toStringAsFixed(0)} km';
        icon = Icons.route;
      case LeaderboardSortBy.trips:
        value = '${entry.totalTrips}';
        icon = Icons.map;
      case LeaderboardSortBy.likes:
        value = '${entry.totalLikesReceived}';
        icon = Icons.favorite;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
