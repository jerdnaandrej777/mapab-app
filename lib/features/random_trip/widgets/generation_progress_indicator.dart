import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/random_trip_provider.dart';
import '../providers/random_trip_state.dart';

/// Fortschrittsanzeige für AI Trip Generierung
/// v1.10.23: Zeigt aktuelle Phase und Fortschritt
///
/// Verwendung:
/// ```dart
/// if (randomTripState.step == RandomTripStep.generating) {
///   GenerationProgressIndicator()
/// }
/// ```
class GenerationProgressIndicator extends ConsumerWidget {
  final bool compact;

  const GenerationProgressIndicator({
    super.key,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(randomTripNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    final phase = state.generationPhase;
    final progress = state.generationProgress;
    final languageCode = Localizations.localeOf(context).languageCode;
    final message = phase.getLocalizedMessage(languageCode);

    if (compact) {
      return _buildCompact(context, colorScheme, phase, progress, message);
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animierter Fortschrittsring
            _AnimatedProgressRing(
              progress: progress,
              phase: phase,
              colorScheme: colorScheme,
            ),

            const SizedBox(height: 24),

            // Phasen-Emoji und Nachricht
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  phase.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    message,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Linearer Fortschrittsbalken
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation(colorScheme.primary),
              ),
            ),

            const SizedBox(height: 8),

            // Prozent-Anzeige
            Text(
              '${(progress * 100).toInt()}%',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompact(
    BuildContext context,
    ColorScheme colorScheme,
    GenerationPhase phase,
    double progress,
    String message,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 3,
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            phase.emoji,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onPrimaryContainer,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(progress * 100).toInt()}%',
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

/// Animierter Fortschrittsring
class _AnimatedProgressRing extends StatefulWidget {
  final double progress;
  final GenerationPhase phase;
  final ColorScheme colorScheme;

  const _AnimatedProgressRing({
    required this.progress,
    required this.phase,
    required this.colorScheme,
  });

  @override
  State<_AnimatedProgressRing> createState() => _AnimatedProgressRingState();
}

class _AnimatedProgressRingState extends State<_AnimatedProgressRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Hintergrund-Ring
          CircularProgressIndicator(
            value: 1.0,
            strokeWidth: 8,
            backgroundColor: widget.colorScheme.primary.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation(
              widget.colorScheme.primary.withValues(alpha: 0.1),
            ),
          ),

          // Fortschritts-Ring
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: widget.progress),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return CircularProgressIndicator(
                value: value,
                strokeWidth: 8,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation(widget.colorScheme.primary),
              );
            },
          ),

          // Pulsierendes Emoji
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final scale = 1.0 + (0.1 * _controller.value);
              return Transform.scale(
                scale: scale,
                child: Text(
                  widget.phase.emoji,
                  style: const TextStyle(fontSize: 32),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
