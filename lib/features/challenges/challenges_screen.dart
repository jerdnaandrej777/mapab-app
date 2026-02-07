import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_planner/core/l10n/l10n.dart';
import 'package:travel_planner/data/models/challenge.dart';
import 'package:travel_planner/data/providers/challenges_provider.dart';

/// Challenges Screen - Wöchentliche Herausforderungen & Streak
class ChallengesScreen extends ConsumerStatefulWidget {
  const ChallengesScreen({super.key});

  @override
  ConsumerState<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends ConsumerState<ChallengesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(challengesNotifierProvider.notifier).loadChallenges();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.watch(challengesNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.challengesTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(challengesNotifierProvider.notifier).loadChallenges(),
            tooltip: context.l10n.refresh,
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(challengesNotifierProvider.notifier).loadChallenges(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Streak-Karte
                    _buildStreakCard(context, state.streak),

                    const SizedBox(height: 16),

                    // Wöchentliche Challenges Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            context.l10n.challengesWeekly,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          if (state.allWeeklyCompleted)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star,
                                      size: 16, color: Colors.amber),
                                  const SizedBox(width: 4),
                                  Text(
                                    '+${state.weeklyBonusXp} XP',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Wöchentliche Challenges
                    if (state.weeklyChallenges.isEmpty)
                      _buildEmptyState(context)
                    else
                      ...state.weeklyChallenges.map(
                        (challenge) => _buildChallengeCard(context, challenge),
                      ),

                    const SizedBox(height: 24),

                    // Abgeschlossene Challenges (nicht-wöchentlich)
                    if (state.completedChallenges
                        .where((c) =>
                            c.definition.frequency != ChallengeFrequency.weekly)
                        .isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          context.l10n.challengesCompleted,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...state.completedChallenges
                          .where((c) =>
                              c.definition.frequency !=
                              ChallengeFrequency.weekly)
                          .take(5)
                          .map((challenge) =>
                              _buildChallengeCard(context, challenge)),
                    ],

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStreakCard(BuildContext context, UserStreak streak) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: streak.currentStreak > 0
              ? [Colors.orange.shade400, Colors.deepOrange.shade400]
              : [colorScheme.surfaceContainerHighest, colorScheme.surfaceContainerHighest],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: streak.currentStreak > 0
            ? [
                BoxShadow(
                  color: Colors.orange.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Flammen-Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (streak.currentStreak > 0 ? Colors.white : colorScheme.surface)
                  .withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.local_fire_department,
              size: 40,
              color: streak.currentStreak > 0
                  ? Colors.white
                  : colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(width: 16),

          // Streak-Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.challengesCurrentStreak,
                  style: TextStyle(
                    fontSize: 14,
                    color: streak.currentStreak > 0
                        ? Colors.white.withValues(alpha: 0.8)
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.challengesStreakDays(streak.currentStreak),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: streak.currentStreak > 0
                        ? Colors.white
                        : colorScheme.onSurface,
                  ),
                ),
                if (streak.longestStreak > streak.currentStreak) ...[
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.challengesLongestStreak(streak.longestStreak),
                    style: TextStyle(
                      fontSize: 12,
                      color: streak.currentStreak > 0
                          ? Colors.white.withValues(alpha: 0.7)
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Status-Icon
          if (streak.isActiveToday)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: isDark ? 0.3 : 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.green, size: 24),
            )
          else if (streak.isAtRisk)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: isDark ? 0.3 : 0.2),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.warning_amber, color: Colors.amber, size: 24),
            ),
        ],
      ),
    );
  }

  Widget _buildChallengeCard(BuildContext context, UserChallenge challenge) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final def = challenge.definition;

    final isCompleted = challenge.isCompleted;
    final icon = _getChallengeIcon(def.type);
    final color = isCompleted ? Colors.green : _getChallengeColor(def.type);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted
              ? Colors.green.withValues(alpha: 0.5)
              : colorScheme.outline.withValues(alpha: 0.2),
          width: isCompleted ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),

            const SizedBox(width: 12),

            // Inhalt
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titel
                  Text(
                    _getChallengeTitle(context, def),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                      decoration:
                          isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Fortschritt
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: challenge.progress,
                            minHeight: 6,
                            backgroundColor:
                                colorScheme.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation(color),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${challenge.currentProgress}/${def.targetCount}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Zeit + XP
                  Row(
                    children: [
                      if (challenge.expiresAt != null && !isCompleted) ...[
                        Icon(
                          Icons.timer_outlined,
                          size: 12,
                          color: challenge.timeRemaining!.inHours < 24
                              ? Colors.orange
                              : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          challenge.formattedTimeRemaining,
                          style: TextStyle(
                            fontSize: 11,
                            color: challenge.timeRemaining!.inHours < 24
                                ? Colors.orange
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      const Icon(
                        Icons.star_outline,
                        size: 12,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '+${def.xpReward} XP',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.amber.shade700,
                        ),
                      ),
                      if (def.isFeatured) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            context.l10n.challengesFeatured,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.purple,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Abgeschlossen-Icon
            if (isCompleted)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 48,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.challengesEmpty,
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  IconData _getChallengeIcon(ChallengeType type) {
    switch (type) {
      case ChallengeType.visitCategory:
        return Icons.place;
      case ChallengeType.visitCountry:
        return Icons.public;
      case ChallengeType.completeTrips:
        return Icons.route;
      case ChallengeType.takePhotos:
        return Icons.photo_camera;
      case ChallengeType.streak:
        return Icons.local_fire_department;
      case ChallengeType.weather:
        return Icons.wb_sunny;
      case ChallengeType.social:
        return Icons.share;
      case ChallengeType.discover:
        return Icons.explore;
      case ChallengeType.distance:
        return Icons.straighten;
    }
  }

  Color _getChallengeColor(ChallengeType type) {
    switch (type) {
      case ChallengeType.visitCategory:
        return Colors.blue;
      case ChallengeType.visitCountry:
        return Colors.teal;
      case ChallengeType.completeTrips:
        return Colors.indigo;
      case ChallengeType.takePhotos:
        return Colors.pink;
      case ChallengeType.streak:
        return Colors.orange;
      case ChallengeType.weather:
        return Colors.amber;
      case ChallengeType.social:
        return Colors.purple;
      case ChallengeType.discover:
        return Colors.green;
      case ChallengeType.distance:
        return Colors.red;
    }
  }

  String _getChallengeTitle(BuildContext context, ChallengeDefinition def) {
    switch (def.type) {
      case ChallengeType.visitCategory:
        final category = def.categoryFilter ?? 'POI';
        return context.l10n.challengesVisitCategory(def.targetCount, category);
      case ChallengeType.visitCountry:
        final country = def.countryFilter ?? '';
        return context.l10n.challengesVisitCountry(country);
      case ChallengeType.completeTrips:
        return context.l10n.challengesCompleteTrips(def.targetCount);
      case ChallengeType.takePhotos:
        return context.l10n.challengesTakePhotos(def.targetCount);
      case ChallengeType.streak:
        return context.l10n.challengesStreak(def.targetCount);
      case ChallengeType.weather:
        return context.l10n.challengesWeather;
      case ChallengeType.social:
        return context.l10n.challengesShare(def.targetCount);
      case ChallengeType.discover:
        return context.l10n.challengesDiscover(def.targetCount);
      case ChallengeType.distance:
        return context.l10n.challengesDistance(def.targetCount);
    }
  }
}
