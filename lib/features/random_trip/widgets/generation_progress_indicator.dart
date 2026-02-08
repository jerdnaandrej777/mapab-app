import 'dart:async';

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

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final cardWidth = (maxWidth - 32).clamp(320.0, 560.0);

        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colorScheme.surface,
                colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
              ],
            ),
          ),
          child: Center(
            child: Container(
              width: cardWidth,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.30),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _DominantLoadingCluster(
                    progress: progress,
                    phase: phase,
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 18),
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
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 12,
                      backgroundColor:
                          colorScheme.primary.withValues(alpha: 0.18),
                      valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _FunLoadingTicker(
                    key: ValueKey(phase),
                    phase: phase,
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.22)),
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

class _FunLoadingTicker extends StatefulWidget {
  final GenerationPhase phase;

  const _FunLoadingTicker({
    super.key,
    required this.phase,
  });

  @override
  State<_FunLoadingTicker> createState() => _FunLoadingTickerState();
}

class _FunLoadingTickerState extends State<_FunLoadingTicker> {
  Timer? _timer;
  int _index = 0;

  List<String> get _messages {
    switch (widget.phase) {
      case GenerationPhase.calculatingRoute:
        return const [
          'Route wird intelligent berechnet...',
          'Schnellste Fahrstrecke wird gesucht...',
          'Tagesgrenzen werden geprüft...',
        ];
      case GenerationPhase.searchingPOIs:
        return const [
          'Spannende POIs werden gesammelt...',
          'Highlights in Reichweite werden priorisiert...',
          'Verfügbare Orte werden gefiltert...',
        ];
      case GenerationPhase.rankingWithAI:
        return const [
          'AI sortiert die besten Zwischenstopps...',
          'Route wird mit POIs sinnvoll kombiniert...',
          'Reihenfolge wird für dich optimiert...',
        ];
      case GenerationPhase.enrichingImages:
        return const [
          'Bilder und Details werden ergänzt...',
          'Infos für die Vorschau werden aufbereitet...',
          'Fast fertig...',
        ];
      case GenerationPhase.complete:
        return const ['Trip ist bereit.'];
      case GenerationPhase.idle:
        return const ['Bereit.'];
    }
  }

  @override
  void initState() {
    super.initState();
    _startTicker();
  }

  void _startTicker() {
    final messages = _messages;
    if (messages.length <= 1) return;
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      setState(() {
        _index = (_index + 1) % messages.length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final messages = _messages;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.2),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: Text(
        messages[_index],
        key: ValueKey('${widget.phase.name}-$_index'),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          color: colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
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

class _DominantLoadingCluster extends StatefulWidget {
  const _DominantLoadingCluster({
    required this.progress,
    required this.phase,
    required this.colorScheme,
  });

  final double progress;
  final GenerationPhase phase;
  final ColorScheme colorScheme;

  @override
  State<_DominantLoadingCluster> createState() =>
      _DominantLoadingClusterState();
}

class _DominantLoadingClusterState extends State<_DominantLoadingCluster>
    with TickerProviderStateMixin {
  late final AnimationController _clockController;
  late final AnimationController _diceController;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _clockController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _diceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _clockController.dispose();
    _diceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = widget.colorScheme;
    return SizedBox(
      height: 170,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _AnimatedProgressRing(
            progress: widget.progress,
            phase: widget.phase,
            colorScheme: cs,
          ),
          Positioned(
            left: 22,
            top: 30,
            child: AnimatedBuilder(
              animation: _clockController,
              builder: (context, _) {
                return Transform.rotate(
                  angle: _clockController.value * 6.28,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.schedule_rounded,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            right: 18,
            top: 48,
            child: AnimatedBuilder(
              animation: _diceController,
              builder: (context, _) {
                final t = (_diceController.value - 0.5) * 0.24;
                return Transform.rotate(
                  angle: t,
                  child: Transform.translate(
                    offset: Offset(0, -8 * _diceController.value),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: cs.tertiaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.casino_rounded,
                        color: cs.onTertiaryContainer,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: 4,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) {
                return Opacity(
                  opacity: 0.55 + (_pulseController.value * 0.45),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: cs.primary,
                    size: 24 + (_pulseController.value * 8),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
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
