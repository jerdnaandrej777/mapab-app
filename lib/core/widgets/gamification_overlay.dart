import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/achievement.dart';
import '../../data/providers/gamification_provider.dart';
import '../l10n/l10n.dart';

/// Overlay-Widget fuer Gamification-Benachrichtigungen
/// Zeigt XP-Toasts, Level-Up-Dialoge und Achievement-Popups
class GamificationOverlay extends ConsumerStatefulWidget {
  final Widget child;

  const GamificationOverlay({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<GamificationOverlay> createState() => _GamificationOverlayState();
}

class _GamificationOverlayState extends ConsumerState<GamificationOverlay> {
  final List<_XpToastData> _activeToasts = [];

  @override
  void initState() {
    super.initState();
    // Initiale Event-Pruefung
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processEvents();
    });
  }

  void _processEvents() {
    final gamification = ref.read(gamificationNotifierProvider.notifier);

    while (gamification.hasEvents) {
      final event = gamification.consumeNextEvent();
      if (event == null) break;

      switch (event) {
        case XpEarnedEvent():
          _showXpToast(event.amount, event.reason);
        case LevelUpEvent():
          _showLevelUpDialog(event.newLevel);
        case AchievementUnlockedEvent():
          _showAchievementDialog(event.achievement);
      }
    }
  }

  void _showXpToast(int amount, String reason) {
    final toast = _XpToastData(amount: amount, reason: reason);
    setState(() {
      _activeToasts.add(toast);
    });

    // Auto-entfernen nach 2 Sekunden
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _activeToasts.remove(toast);
        });
      }
    });
  }

  void _showLevelUpDialog(int newLevel) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => _LevelUpDialog(newLevel: newLevel),
    );
  }

  void _showAchievementDialog(Achievement achievement) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => _AchievementDialog(achievement: achievement),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Auf neue Events reagieren
    ref.listen<GamificationState>(gamificationNotifierProvider, (_, state) {
      if (state.pendingEvents.isNotEmpty) {
        _processEvents();
      }
    });

    return Stack(
      children: [
        widget.child,

        // XP-Toasts oben rechts
        Positioned(
          top: MediaQuery.of(context).padding.top + 60,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: _activeToasts.map((toast) {
              return _XpToast(
                key: ValueKey(toast.hashCode),
                amount: toast.amount,
                reason: toast.reason,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _XpToastData {
  final int amount;
  final String reason;

  _XpToastData({required this.amount, required this.reason});
}

/// Animierter XP-Toast
class _XpToast extends StatefulWidget {
  final int amount;
  final String reason;

  const _XpToast({
    super.key,
    required this.amount,
    required this.reason,
  });

  @override
  State<_XpToast> createState() => _XpToastState();
}

class _XpToastState extends State<_XpToast> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 50, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_slideAnimation.value, 0),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.amber.shade700,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              '+${widget.amount} XP',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Level-Up Dialog
class _LevelUpDialog extends StatelessWidget {
  final int newLevel;

  const _LevelUpDialog({required this.newLevel});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animierte Icon-Zeile
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber.shade400, Colors.orange.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_upward,
                color: Colors.white,
                size: 40,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              context.l10n.gamificationLevelUp,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              context.l10n.gamificationNewLevel(newLevel),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Colors.amber.shade700,
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.l10n.gamificationContinue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Achievement Unlock Dialog
class _AchievementDialog extends StatelessWidget {
  final Achievement achievement;

  const _AchievementDialog({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final languageCode = Localizations.localeOf(context).languageCode;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Achievement Badge
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Color(achievement.tierColor).withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Color(achievement.tierColor),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(achievement.tierColor).withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  achievement.icon,
                  style: const TextStyle(fontSize: 48),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              context.l10n.gamificationAchievementUnlocked,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              achievement.getTitle(languageCode),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            Text(
              achievement.getDescription(languageCode),
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // XP Reward
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, color: Colors.amber.shade700, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    '+${achievement.xpReward} XP',
                    style: TextStyle(
                      color: Colors.amber.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.l10n.gamificationAwesome),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Achievement Card Widget (fuer ProfileScreen und Achievement-Liste)
class AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final bool isUnlocked;
  final double progress;
  final String progressText;

  const AchievementCard({
    super.key,
    required this.achievement,
    required this.isUnlocked,
    this.progress = 0.0,
    this.progressText = '',
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final languageCode = Localizations.localeOf(context).languageCode;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUnlocked
            ? Color(achievement.tierColor).withValues(alpha: isDark ? 0.2 : 0.1)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: isUnlocked
            ? Border.all(color: Color(achievement.tierColor), width: 2)
            : null,
      ),
      child: Row(
        children: [
          // Icon/Emoji
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isUnlocked
                  ? Color(achievement.tierColor).withValues(alpha: 0.3)
                  : colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isUnlocked
                  ? Text(achievement.icon, style: const TextStyle(fontSize: 24))
                  : Icon(
                      Icons.lock,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      size: 24,
                    ),
            ),
          ),

          const SizedBox(width: 12),

          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.getTitle(languageCode),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isUnlocked
                        ? colorScheme.onSurface
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  achievement.getDescription(languageCode),
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),

                // Progress Bar (wenn nicht freigeschaltet)
                if (!isUnlocked && progress > 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 4,
                            backgroundColor: colorScheme.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation(
                              Color(achievement.tierColor),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        progressText,
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // XP Reward Badge
          if (isUnlocked)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '+${achievement.xpReward}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade800,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
