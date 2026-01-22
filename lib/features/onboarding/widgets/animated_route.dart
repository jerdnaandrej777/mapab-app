import 'package:flutter/material.dart';

/// Animierte Route mit POI-Markern für das Onboarding
/// Zeigt eine geschwungene Linie die sich zeichnet, mit erscheinenden Markern
class AnimatedRoute extends StatefulWidget {
  const AnimatedRoute({super.key});

  @override
  State<AnimatedRoute> createState() => _AnimatedRouteState();
}

class _AnimatedRouteState extends State<AnimatedRoute>
    with TickerProviderStateMixin {
  late AnimationController _pathController;
  late AnimationController _pulseController;

  late Animation<double> _pathAnimation;
  late Animation<double> _marker1Animation;
  late Animation<double> _marker2Animation;
  late Animation<double> _marker3Animation;

  @override
  void initState() {
    super.initState();

    // Haupt-Controller für Path und Marker
    _pathController = AnimationController(
      duration: const Duration(milliseconds: 3500),
      vsync: this,
    );

    // Pulse-Controller für die Marker-Ringe (endlos)
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    // Path zeichnet sich (0% - 60% der Zeit)
    _pathAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _pathController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
      ),
    );

    // Marker erscheinen gestaffelt mit Bounce
    _marker1Animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _pathController,
        curve: const Interval(0.25, 0.45, curve: Curves.elasticOut),
      ),
    );

    _marker2Animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _pathController,
        curve: const Interval(0.45, 0.65, curve: Curves.elasticOut),
      ),
    );

    _marker3Animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _pathController,
        curve: const Interval(0.65, 0.85, curve: Curves.elasticOut),
      ),
    );

    // Animation starten
    _pathController.forward();
  }

  @override
  void dispose() {
    _pathController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pathController, _pulseController]),
      builder: (context, child) {
        return CustomPaint(
          size: const Size(280, 280),
          painter: _RoutePainter(
            pathProgress: _pathAnimation.value,
            marker1Progress: _marker1Animation.value,
            marker2Progress: _marker2Animation.value,
            marker3Progress: _marker3Animation.value,
            pulseProgress: _pulseController.value,
            primaryColor: const Color(0xFF3B82F6),
            secondaryColor: const Color(0xFF06B6D4),
          ),
        );
      },
    );
  }
}

class _RoutePainter extends CustomPainter {
  final double pathProgress;
  final double marker1Progress;
  final double marker2Progress;
  final double marker3Progress;
  final double pulseProgress;
  final Color primaryColor;
  final Color secondaryColor;

  _RoutePainter({
    required this.pathProgress,
    required this.marker1Progress,
    required this.marker2Progress,
    required this.marker3Progress,
    required this.pulseProgress,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // POI-Positionen (relativ zur Größe)
    final poi1 = Offset(size.width * 0.2, size.height * 0.25);  // Schloss (oben links)
    final poi2 = Offset(size.width * 0.5, size.height * 0.5);   // Museum (mitte)
    final poi3 = Offset(size.width * 0.8, size.height * 0.75);  // See (unten rechts)

    // Route zeichnen
    _drawRoute(canvas, size, poi1, poi2, poi3);

    // Marker zeichnen
    _drawMarker(canvas, poi1, marker1Progress, Icons.castle, 'Schloss');
    _drawMarker(canvas, poi2, marker2Progress, Icons.museum, 'Museum');
    _drawMarker(canvas, poi3, marker3Progress, Icons.water, 'See');
  }

  void _drawRoute(Canvas canvas, Size size, Offset p1, Offset p2, Offset p3) {
    if (pathProgress <= 0) return;

    final path = Path();
    path.moveTo(p1.dx, p1.dy);

    // Kontrollpunkte für Bezier-Kurve
    final ctrl1 = Offset(p1.dx + 40, p1.dy + 60);
    final ctrl2 = Offset(p2.dx - 40, p2.dy - 40);
    path.cubicTo(ctrl1.dx, ctrl1.dy, ctrl2.dx, ctrl2.dy, p2.dx, p2.dy);

    final ctrl3 = Offset(p2.dx + 40, p2.dy + 40);
    final ctrl4 = Offset(p3.dx - 40, p3.dy - 60);
    path.cubicTo(ctrl3.dx, ctrl3.dy, ctrl4.dx, ctrl4.dy, p3.dx, p3.dy);

    // Path metrics für partielles Zeichnen
    final pathMetrics = path.computeMetrics().first;
    final extractPath = pathMetrics.extractPath(
      0,
      pathMetrics.length * pathProgress,
    );

    // Schatten/Glow
    final glowPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.3)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawPath(extractPath, glowPaint);

    // Hauptlinie
    final linePaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(extractPath, linePaint);

    // Gepunktete Linie obendrauf
    final dashPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Einfache gestrichelte Linie simulieren
    _drawDashedPath(canvas, extractPath, dashPaint);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      double distance = 0;
      while (distance < metric.length) {
        final extractPath = metric.extractPath(distance, distance + 8);
        canvas.drawPath(extractPath, paint);
        distance += 20;
      }
    }
  }

  void _drawMarker(
    Canvas canvas,
    Offset position,
    double progress,
    IconData icon,
    String label,
  ) {
    if (progress <= 0) return;

    final scale = progress;
    final opacity = progress;

    // Pulse-Ringe
    if (progress >= 1.0) {
      _drawPulseRing(canvas, position, pulseProgress, primaryColor);
      _drawPulseRing(canvas, position, (pulseProgress + 0.5) % 1.0, secondaryColor);
    }

    // Marker-Hintergrund (Kreis)
    final bgPaint = Paint()
      ..color = primaryColor.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    final markerRadius = 24.0 * scale;
    canvas.drawCircle(position, markerRadius, bgPaint);

    // Weißer innerer Kreis
    final innerPaint = Paint()
      ..color = Colors.white.withValues(alpha: opacity * 0.9)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(position, markerRadius * 0.7, innerPaint);

    // Icon simulieren mit Text (da Canvas keine Icons direkt kann)
    final iconPaint = Paint()
      ..color = primaryColor.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    // Kleiner Punkt als Icon-Ersatz
    canvas.drawCircle(position, 6 * scale, iconPaint);
  }

  void _drawPulseRing(Canvas canvas, Offset position, double progress, Color color) {
    final ringRadius = 24.0 + (progress * 40);
    final ringOpacity = (1 - progress) * 0.5;

    final ringPaint = Paint()
      ..color = color.withValues(alpha: ringOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(position, ringRadius, ringPaint);
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) {
    return pathProgress != oldDelegate.pathProgress ||
        marker1Progress != oldDelegate.marker1Progress ||
        marker2Progress != oldDelegate.marker2Progress ||
        marker3Progress != oldDelegate.marker3Progress ||
        pulseProgress != oldDelegate.pulseProgress;
  }
}
