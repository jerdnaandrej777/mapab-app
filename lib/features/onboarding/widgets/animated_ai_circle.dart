import 'package:flutter/material.dart';

/// Animierter AI-Kreis mit pulsierenden Ringen für das Onboarding
/// Inspiriert vom Referenzbild mit Glow-Effekt und konzentrischen Ringen
class AnimatedAICircle extends StatefulWidget {
  const AnimatedAICircle({super.key});

  @override
  State<AnimatedAICircle> createState() => _AnimatedAICircleState();
}

class _AnimatedAICircleState extends State<AnimatedAICircle>
    with TickerProviderStateMixin {
  late AnimationController _pulse1Controller;
  late AnimationController _pulse2Controller;
  late AnimationController _pulse3Controller;
  late AnimationController _glowController;
  late AnimationController _iconController;

  @override
  void initState() {
    super.initState();

    // Gestaffelte Pulse-Controller für mehrere Ringe
    _pulse1Controller = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat();

    _pulse2Controller = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();

    _pulse3Controller = AnimationController(
      duration: const Duration(milliseconds: 3500),
      vsync: this,
    )..repeat();

    // Glow-Controller (sanftes Pulsieren)
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    // Icon "Atmen" Animation
    _iconController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse1Controller.dispose();
    _pulse2Controller.dispose();
    _pulse3Controller.dispose();
    _glowController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF06B6D4);  // Cyan
    const secondaryColor = Color(0xFF3B82F6);  // Blue

    return SizedBox(
      width: 280,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Hintergrund-Glow
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              return Container(
                width: 200 + (_glowController.value * 20),
                height: 200 + (_glowController.value * 20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      primaryColor.withValues(alpha: 0.15 + (_glowController.value * 0.1)),
                      primaryColor.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              );
            },
          ),

          // Äußerster pulsierender Ring
          _buildPulseRing(
            controller: _pulse3Controller,
            baseSize: 220,
            maxExpand: 60,
            color: secondaryColor,
            strokeWidth: 1.5,
          ),

          // Mittlerer pulsierender Ring
          _buildPulseRing(
            controller: _pulse2Controller,
            baseSize: 180,
            maxExpand: 50,
            color: primaryColor,
            strokeWidth: 2,
          ),

          // Innerer pulsierender Ring
          _buildPulseRing(
            controller: _pulse1Controller,
            baseSize: 140,
            maxExpand: 40,
            color: primaryColor,
            strokeWidth: 2.5,
          ),

          // Statischer innerer Ring mit Gradient
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: primaryColor.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
          ),

          // Zentraler Kreis mit Glow
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              return Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      primaryColor.withValues(alpha: 0.4 + (_glowController.value * 0.2)),
                      primaryColor.withValues(alpha: 0.2),
                      primaryColor.withValues(alpha: 0.05),
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.4 + (_glowController.value * 0.2)),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              );
            },
          ),

          // AI-Icon (Smiley wie im Referenzbild)
          AnimatedBuilder(
            animation: _iconController,
            builder: (context, child) {
              final scale = 1.0 + (_iconController.value * 0.05);
              return Transform.scale(
                scale: scale,
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: CustomPaint(
                    painter: _SmileyPainter(
                      color: primaryColor,
                      smileProgress: _iconController.value,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPulseRing({
    required AnimationController controller,
    required double baseSize,
    required double maxExpand,
    required Color color,
    required double strokeWidth,
  }) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final progress = controller.value;
        final size = baseSize + (progress * maxExpand);
        final opacity = (1 - progress) * 0.6;

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withValues(alpha: opacity),
              width: strokeWidth * (1 - progress * 0.5),
            ),
          ),
        );
      },
    );
  }
}

/// Custom Painter für einen animierten Smiley
class _SmileyPainter extends CustomPainter {
  final Color color;
  final double smileProgress;

  _SmileyPainter({
    required this.color,
    required this.smileProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Lächeln (Bezier-Kurve)
    final smilePath = Path();
    final smileWidth = radius * 0.7;
    final smileHeight = radius * 0.15 + (smileProgress * radius * 0.1);

    smilePath.moveTo(center.dx - smileWidth / 2, center.dy + radius * 0.1);
    smilePath.quadraticBezierTo(
      center.dx,
      center.dy + radius * 0.1 + smileHeight,
      center.dx + smileWidth / 2,
      center.dy + radius * 0.1,
    );

    canvas.drawPath(smilePath, paint);

    // Augen (zwei kleine Punkte)
    final eyePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final eyeY = center.dy - radius * 0.15;
    final eyeSpacing = radius * 0.35;

    canvas.drawCircle(
      Offset(center.dx - eyeSpacing, eyeY),
      3,
      eyePaint,
    );
    canvas.drawCircle(
      Offset(center.dx + eyeSpacing, eyeY),
      3,
      eyePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SmileyPainter oldDelegate) {
    return smileProgress != oldDelegate.smileProgress;
  }
}
