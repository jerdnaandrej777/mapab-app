import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/random_trip_provider.dart';
import '../providers/random_trip_state.dart';

/// Fortschrittsanzeige fuer AI Trip Generierung.
///
/// Ziele:
/// - Prozentanzeige laeuft sichtbar von 1% bis 100%
/// - weniger visuelle Unruhe (keine Icon-Flut)
/// - unterschiedliche Animationen fuer Tagestrip und Euro Trip
class GenerationProgressIndicator extends ConsumerWidget {
  final bool compact;
  final bool panelMode;

  const GenerationProgressIndicator({
    super.key,
    this.compact = false,
    this.panelMode = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(randomTripNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    final phase = state.generationPhase;
    final progress = _normalizeProgress(state.generationProgress);
    final percent = _toPercent(progress);
    final mode = state.mode;

    final languageCode = Localizations.localeOf(context).languageCode;
    final message = phase.getLocalizedMessage(languageCode);

    if (compact) {
      return _buildCompact(
        context,
        colorScheme,
        mode,
        message,
        progress,
        percent,
      );
    }

    if (panelMode) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          final cardWidth = maxWidth.clamp(320.0, 560.0);
          return Align(
            alignment: Alignment.topCenter,
            child: Container(
              width: cardWidth,
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
              child: _buildMainContent(
                context: context,
                colorScheme: colorScheme,
                theme: theme,
                phase: phase,
                mode: mode,
                progress: progress,
                percent: percent,
                message: message,
              ),
            ),
          );
        },
      );
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
              child: _buildMainContent(
                context: context,
                colorScheme: colorScheme,
                theme: theme,
                phase: phase,
                mode: mode,
                progress: progress,
                percent: percent,
                message: message,
              ),
            ),
          ),
        );
      },
    );
  }

  double _normalizeProgress(double rawProgress) {
    final bounded = rawProgress.clamp(0.0, 1.0);
    if (bounded >= 1.0) return 1.0;
    if (bounded <= 0.0) return 0.01;
    return bounded < 0.01 ? 0.01 : bounded;
  }

  int _toPercent(double progress) {
    final value = (progress * 100).round();
    return value.clamp(1, 100);
  }

  Widget _buildMainContent({
    required BuildContext context,
    required ColorScheme colorScheme,
    required ThemeData theme,
    required GenerationPhase phase,
    required RandomTripMode mode,
    required double progress,
    required int percent,
    required String message,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ModeLoadingHero(
          progress: progress,
          percent: percent,
          mode: mode,
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 18),
        Text(
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 12,
            backgroundColor: colorScheme.primary.withValues(alpha: 0.18),
            valueColor: AlwaysStoppedAnimation(colorScheme.primary),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '$percent%',
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        _FunLoadingTicker(
          key: ValueKey('${mode.name}-${phase.name}'),
          phase: phase,
          mode: mode,
        ),
      ],
    );
  }

  Widget _buildCompact(
    BuildContext context,
    ColorScheme colorScheme,
    RandomTripMode mode,
    String message,
    double progress,
    int percent,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(
            mode == RandomTripMode.daytrip
                ? Icons.directions_car_rounded
                : Icons.flight_rounded,
            size: 18,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor:
                        colorScheme.primary.withValues(alpha: 0.18),
                    valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$percent%',
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
  final RandomTripMode mode;

  const _FunLoadingTicker({
    super.key,
    required this.phase,
    required this.mode,
  });

  @override
  State<_FunLoadingTicker> createState() => _FunLoadingTickerState();
}

class _FunLoadingTickerState extends State<_FunLoadingTicker> {
  Timer? _timer;
  int _index = 0;

  List<String> get _messages {
    final isEuro = widget.mode == RandomTripMode.eurotrip;

    switch (widget.phase) {
      case GenerationPhase.calculatingRoute:
        return isEuro
            ? const [
                'Etappen fuer den Euro Trip werden geplant...',
                'Lange Route wird in sinnvolle Abschnitte geteilt...',
              ]
            : const [
                'Route fuer den Tagestrip wird berechnet...',
                'Fahrzeit und Distanz werden abgestimmt...',
              ];
      case GenerationPhase.searchingPOIs:
        return isEuro
            ? const [
                'POIs entlang der Gesamtstrecke werden gesucht...',
                'Highlights pro Reisetag werden gesammelt...',
              ]
            : const [
                'Spannende POIs in deiner Reichweite werden gesucht...',
                'Tagestrip-Highlights werden gefiltert...',
              ];
      case GenerationPhase.rankingWithAI:
        return isEuro
            ? const [
                'AI verteilt Stops auf die Reisetage...',
                'Abfolge der Etappen wird optimiert...',
              ]
            : const [
                'AI sortiert die besten Zwischenstopps...',
                'Reihenfolge fuer den Tagestrip wird optimiert...',
              ];
      case GenerationPhase.enrichingImages:
        return const [
          'Bilder und Details werden vorbereitet...',
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
        key: ValueKey('${widget.mode.name}-${widget.phase.name}-$_index'),
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

class _ModeLoadingHero extends StatefulWidget {
  const _ModeLoadingHero({
    required this.progress,
    required this.percent,
    required this.mode,
    required this.colorScheme,
  });

  final double progress;
  final int percent;
  final RandomTripMode mode;
  final ColorScheme colorScheme;

  @override
  State<_ModeLoadingHero> createState() => _ModeLoadingHeroState();
}

class _ModeLoadingHeroState extends State<_ModeLoadingHero>
    with TickerProviderStateMixin {
  late final AnimationController _travelController;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _travelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _travelController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 170,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _AnimatedProgressRing(
            progress: widget.progress,
            percent: widget.percent,
            colorScheme: widget.colorScheme,
          ),
          if (widget.mode == RandomTripMode.daytrip)
            _buildDayTripAnimation(widget.colorScheme)
          else
            _buildEuroTripAnimation(widget.colorScheme),
        ],
      ),
    );
  }

  Widget _buildDayTripAnimation(ColorScheme colorScheme) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        width: 128,
        height: 52,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Positioned(
              left: 12,
              right: 12,
              bottom: 10,
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            AnimatedBuilder(
              animation:
                  Listenable.merge([_travelController, _pulseController]),
              builder: (context, _) {
                final t = Curves.easeInOut.transform(_travelController.value);
                final dx = -46 + (t * 92);
                final bob = math.sin(t * math.pi) * 3;
                final scale = 0.94 + (_pulseController.value * 0.10);

                return Transform.translate(
                  offset: Offset(dx, -bob),
                  child: Transform.scale(
                    scale: scale,
                    child: Icon(
                      Icons.directions_car_rounded,
                      size: 22,
                      color: colorScheme.primary,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEuroTripAnimation(ColorScheme colorScheme) {
    return SizedBox(
      width: 132,
      height: 132,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.20),
                width: 2,
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _travelController,
            builder: (context, _) {
              final angle =
                  (_travelController.value * 2 * math.pi) - (math.pi / 2);
              const radius = 44.0;
              final dx = math.cos(angle) * radius;
              final dy = math.sin(angle) * radius;

              return Transform.translate(
                offset: Offset(dx, dy),
                child: Transform.rotate(
                  angle: angle + (math.pi / 2),
                  child: Icon(
                    Icons.flight_rounded,
                    size: 22,
                    color: colorScheme.primary,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AnimatedProgressRing extends StatelessWidget {
  const _AnimatedProgressRing({
    required this.progress,
    required this.percent,
    required this.colorScheme,
  });

  final double progress;
  final int percent;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 104,
      height: 104,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: 1.0,
            strokeWidth: 8,
            backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation(
              colorScheme.primary.withValues(alpha: 0.1),
            ),
          ),
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 8,
            backgroundColor: Colors.transparent,
            valueColor: AlwaysStoppedAnimation(colorScheme.primary),
          ),
          Text(
            '$percent%',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
