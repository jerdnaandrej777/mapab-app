import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/elevation.dart';

/// Höhenprofil-Diagramm Widget
class ElevationChart extends StatelessWidget {
  final ElevationProfile profile;
  final double height;
  final bool showLabels;
  final bool interactive;
  final ValueChanged<double>? onPositionSelected;

  const ElevationChart({
    super.key,
    required this.profile,
    this.height = 150,
    this.showLabels = true,
    this.interactive = true,
    this.onPositionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          // Header mit Statistiken
          if (showLabels)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatChip(
                    icon: Icons.trending_up,
                    label: '${profile.totalAscent.round()}m',
                    color: Colors.green,
                  ),
                  _StatChip(
                    icon: Icons.trending_down,
                    label: '${profile.totalDescent.round()}m',
                    color: Colors.red,
                  ),
                  _StatChip(
                    icon: Icons.height,
                    label: '${profile.minElevation.round()}-${profile.maxElevation.round()}m',
                    color: Colors.blue,
                  ),
                  _DifficultyBadge(difficulty: profile.difficulty),
                ],
              ),
            ),

          // Chart
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 16, 8),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: _calculateInterval(
                      profile.maxElevation - profile.minElevation,
                    ),
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) => Text(
                          '${value.round()}m',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        getTitlesWidget: (value, meta) {
                          if (value == 0 || value == profile.totalDistanceKm) {
                            return Text(
                              '${value.toStringAsFixed(1)}km',
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: profile.totalDistanceKm,
                  minY: profile.minElevation - 50,
                  maxY: profile.maxElevation + 50,
                  lineTouchData: LineTouchData(
                    enabled: interactive,
                    touchCallback: (event, response) {
                      if (event is FlTapUpEvent &&
                          response?.lineBarSpots?.isNotEmpty == true) {
                        final spot = response!.lineBarSpots!.first;
                        onPositionSelected?.call(spot.x);
                      }
                    },
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (spots) => spots.map((spot) {
                        return LineTooltipItem(
                          '${spot.y.round()}m\n${spot.x.toStringAsFixed(1)}km',
                          TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: profile.points
                          .map((p) => FlSpot(p.distance, p.elevation))
                          .toList(),
                      isCurved: true,
                      curveSmoothness: 0.2,
                      color: AppTheme.primaryColor,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppTheme.primaryColor.withOpacity(0.4),
                            AppTheme.primaryColor.withOpacity(0.1),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _calculateInterval(double range) {
    if (range > 1000) return 500;
    if (range > 500) return 200;
    if (range > 200) return 100;
    if (range > 100) return 50;
    return 25;
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _DifficultyBadge extends StatelessWidget {
  final RouteDifficulty difficulty;

  const _DifficultyBadge({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _getColor().withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getColor(), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(difficulty.emoji, style: const TextStyle(fontSize: 10)),
          const SizedBox(width: 4),
          Text(
            difficulty.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: _getColor(),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor() {
    switch (difficulty) {
      case RouteDifficulty.easy:
        return Colors.green;
      case RouteDifficulty.moderate:
        return Colors.orange;
      case RouteDifficulty.difficult:
        return Colors.red;
      case RouteDifficulty.expert:
        return Colors.purple;
    }
  }
}

/// Kompaktes Höhenprofil für Kartenüberlagerung
class ElevationChartMini extends StatelessWidget {
  final ElevationProfile profile;
  final double width;
  final double height;

  const ElevationChartMini({
    super.key,
    required this.profile,
    this.width = 120,
    this.height = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '↑${profile.totalAscent.round()}m',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              Text(
                profile.difficulty.emoji,
                style: const TextStyle(fontSize: 10),
              ),
            ],
          ),
          Expanded(
            child: CustomPaint(
              size: Size(width - 8, height - 20),
              painter: _MiniElevationPainter(profile: profile),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniElevationPainter extends CustomPainter {
  final ElevationProfile profile;

  _MiniElevationPainter({required this.profile});

  @override
  void paint(Canvas canvas, Size size) {
    if (profile.points.isEmpty) return;

    final paint = Paint()
      ..color = AppTheme.primaryColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = AppTheme.primaryColor.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    final range = profile.maxElevation - profile.minElevation;
    final distRange = profile.totalDistanceKm;

    for (int i = 0; i < profile.points.length; i++) {
      final point = profile.points[i];
      final x = (point.distance / distRange) * size.width;
      final y = size.height - ((point.elevation - profile.minElevation) / range) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MiniElevationPainter oldDelegate) {
    return oldDelegate.profile != profile;
  }
}
