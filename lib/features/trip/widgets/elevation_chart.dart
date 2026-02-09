import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../data/models/elevation.dart';

/// Hoehenprofil-Diagramm fuer eine Route.
///
/// Zeigt eine LineChart mit Gradient-Fill, Touch-Tooltips
/// und automatischer Achsen-Skalierung.
class ElevationChart extends StatelessWidget {
  final ElevationProfile profile;
  final double? highlightDistanceKm;
  final bool showHeader;

  const ElevationChart({
    super.key,
    required this.profile,
    this.highlightDistanceKm,
    this.showHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    if (profile.points.isEmpty) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final lineColor = colorScheme.primary;
    final gradientTop = lineColor.withValues(alpha: 0.4);
    final gradientBottom = lineColor.withValues(alpha: 0.05);
    final gridColor = colorScheme.outlineVariant.withValues(alpha: 0.3);
    final textColor = colorScheme.onSurfaceVariant;

    // Achsen-Bereiche berechnen
    final elevRange = profile.maxElevation - profile.minElevation;
    final padding = (elevRange * 0.1).clamp(10.0, 100.0);
    final minY = (profile.minElevation - padding).floorToDouble();
    final maxY = (profile.maxElevation + padding).ceilToDouble();

    // FlSpot-Daten erstellen
    final spots = profile.points
        .map((p) => FlSpot(p.distanceKm, p.elevation))
        .toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(0, 16, 16, 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (optional - ausblenden wenn extern angezeigt)
          if (showHeader)
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.terrain,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Hoehenprofil',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  // Kompakte Stats
                  _StatChip(
                    icon: Icons.arrow_upward,
                    label: profile.formattedAscent,
                    color: colorScheme.tertiary,
                  ),
                  const SizedBox(width: 8),
                  _StatChip(
                    icon: Icons.arrow_downward,
                    label: profile.formattedDescent,
                    color: colorScheme.error,
                  ),
                ],
              ),
            ),

          // Chart
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: profile.totalDistanceKm,
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: _calculateInterval(minY, maxY),
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: gridColor,
                    strokeWidth: 0.5,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: _calculateDistanceInterval(
                          profile.totalDistanceKm),
                      getTitlesWidget: (value, meta) {
                        if (value == meta.min || value == meta.max) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${value.round()} km',
                            style: TextStyle(
                              fontSize: 10,
                              color: textColor,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      interval: _calculateInterval(minY, maxY),
                      getTitlesWidget: (value, meta) {
                        if (value == meta.min || value == meta.max) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text(
                            '${value.round()} m',
                            style: TextStyle(
                              fontSize: 10,
                              color: textColor,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => colorScheme.inverseSurface,
                    getTooltipItems: (spots) => spots.map((spot) {
                      return LineTooltipItem(
                        '${spot.y.round()} m\n${spot.x.toStringAsFixed(1)} km',
                        TextStyle(
                          color: colorScheme.onInverseSurface,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.2,
                    color: lineColor,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [gradientTop, gradientBottom],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
              duration: const Duration(milliseconds: 300),
            ),
          ),
        ],
      ),
    );
  }

  /// Berechnet ein sinnvolles Intervall fuer die Hoehen-Achse
  double _calculateInterval(double min, double max) {
    final range = max - min;
    if (range <= 100) return 20;
    if (range <= 300) return 50;
    if (range <= 600) return 100;
    if (range <= 1500) return 250;
    return 500;
  }

  /// Berechnet ein sinnvolles Intervall fuer die Distanz-Achse
  double _calculateDistanceInterval(double totalKm) {
    if (totalKm <= 20) return 5;
    if (totalKm <= 50) return 10;
    if (totalKm <= 100) return 20;
    if (totalKm <= 300) return 50;
    if (totalKm <= 500) return 100;
    return 200;
  }
}

/// Kleiner Stat-Chip fuer Header (Anstieg/Abstieg)
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
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}
