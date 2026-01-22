import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Animierte Cloud-Sync-Animation für das Onboarding
/// Zeigt ein Handy und eine Cloud mit animierter Datenübertragung
class AnimatedSync extends StatefulWidget {
  const AnimatedSync({super.key});

  @override
  State<AnimatedSync> createState() => _AnimatedSyncState();
}

class _AnimatedSyncState extends State<AnimatedSync>
    with TickerProviderStateMixin {
  late AnimationController _dataFlowController;
  late AnimationController _pulseController;
  late AnimationController _iconBounceController;

  @override
  void initState() {
    super.initState();

    // Datenfluss-Animation (Partikel bewegen sich)
    _dataFlowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    // Pulse für Icons
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    // Bounce für Icons
    _iconBounceController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _dataFlowController.dispose();
    _pulseController.dispose();
    _iconBounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF22C55E);  // Green
    const secondaryColor = Color(0xFF3B82F6);  // Blue

    return SizedBox(
      width: 280,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Hintergrund-Glow
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 260,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  gradient: RadialGradient(
                    colors: [
                      primaryColor.withValues(alpha: 0.1 + (_pulseController.value * 0.05)),
                      Colors.transparent,
                    ],
                  ),
                ),
              );
            },
          ),

          // Datenpartikel (animierte Punkte zwischen Icons)
          AnimatedBuilder(
            animation: _dataFlowController,
            builder: (context, child) {
              return CustomPaint(
                size: const Size(280, 200),
                painter: _DataFlowPainter(
                  progress: _dataFlowController.value,
                  color: primaryColor,
                ),
              );
            },
          ),

          // Phone-Icon (links)
          Positioned(
            left: 30,
            child: AnimatedBuilder(
              animation: _iconBounceController,
              builder: (context, child) {
                final bounce = math.sin(_iconBounceController.value * math.pi) * 5;
                return Transform.translate(
                  offset: Offset(0, bounce),
                  child: _buildIconContainer(
                    icon: Icons.phone_android,
                    color: secondaryColor,
                    size: 80,
                  ),
                );
              },
            ),
          ),

          // Sync-Pfeil-Animation in der Mitte
          AnimatedBuilder(
            animation: _dataFlowController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _dataFlowController.value * math.pi * 2,
                child: Icon(
                  Icons.sync,
                  size: 32,
                  color: primaryColor.withValues(alpha: 0.7),
                ),
              );
            },
          ),

          // Cloud-Icon (rechts)
          Positioned(
            right: 30,
            child: AnimatedBuilder(
              animation: _iconBounceController,
              builder: (context, child) {
                final bounce = math.sin((_iconBounceController.value + 0.5) * math.pi) * 5;
                return Transform.translate(
                  offset: Offset(0, bounce),
                  child: _buildIconContainer(
                    icon: Icons.cloud,
                    color: primaryColor,
                    size: 80,
                  ),
                );
              },
            ),
          ),

          // Checkmark Badge auf der Cloud
          Positioned(
            right: 25,
            top: 85,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale = 1.0 + (_pulseController.value * 0.1);
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconContainer({
    required IconData icon,
    required Color color,
    required double size,
  }) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withValues(alpha: 0.3 + (_pulseController.value * 0.2)),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.2 + (_pulseController.value * 0.1)),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Icon(
            icon,
            size: size * 0.5,
            color: color,
          ),
        );
      },
    );
  }
}

/// Custom Painter für animierte Datenpartikel
class _DataFlowPainter extends CustomPainter {
  final double progress;
  final Color color;

  _DataFlowPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Start- und Endpunkte (Phone zu Cloud)
    final startX = 80.0;
    final endX = size.width - 80;
    final y = center.dy;

    // Mehrere Partikel mit verschiedenen Phasen
    _drawParticle(canvas, startX, endX, y, progress, 0.0);
    _drawParticle(canvas, startX, endX, y, progress, 0.25);
    _drawParticle(canvas, startX, endX, y, progress, 0.5);
    _drawParticle(canvas, startX, endX, y, progress, 0.75);

    // Auch rückwärts (Cloud zu Phone)
    _drawParticle(canvas, endX, startX, y - 15, progress, 0.125);
    _drawParticle(canvas, endX, startX, y - 15, progress, 0.375);
    _drawParticle(canvas, endX, startX, y - 15, progress, 0.625);
    _drawParticle(canvas, endX, startX, y - 15, progress, 0.875);
  }

  void _drawParticle(
    Canvas canvas,
    double startX,
    double endX,
    double y,
    double globalProgress,
    double offset,
  ) {
    final particleProgress = (globalProgress + offset) % 1.0;
    final x = startX + (endX - startX) * particleProgress;

    // Fade in/out an den Enden
    var opacity = 1.0;
    if (particleProgress < 0.1) {
      opacity = particleProgress / 0.1;
    } else if (particleProgress > 0.9) {
      opacity = (1 - particleProgress) / 0.1;
    }

    final paint = Paint()
      ..color = color.withValues(alpha: opacity * 0.8)
      ..style = PaintingStyle.fill;

    // Partikel mit Schweif
    final particleSize = 4.0;
    canvas.drawCircle(Offset(x, y), particleSize, paint);

    // Schweif (kleinere Punkte dahinter)
    final direction = (endX > startX) ? -1 : 1;
    for (var i = 1; i <= 3; i++) {
      final trailPaint = Paint()
        ..color = color.withValues(alpha: opacity * 0.5 / i)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(x + (i * 8 * direction), y),
        particleSize - i,
        trailPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DataFlowPainter oldDelegate) {
    return progress != oldDelegate.progress;
  }
}
