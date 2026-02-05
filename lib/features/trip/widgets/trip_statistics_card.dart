import 'package:flutter/material.dart';
import '../../../data/models/elevation.dart';

/// Statistik-Karte fuer Trip-Hoehendaten.
///
/// Zeigt Gesamtanstieg, Gesamtabstieg, Max-Hoehe und Min-Hoehe
/// in einem kompakten 2x2 Grid.
class TripStatisticsCard extends StatelessWidget {
  final ElevationProfile profile;

  const TripStatisticsCard({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
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
          Row(
            children: [
              Icon(
                Icons.bar_chart_rounded,
                size: 18,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Hoehenstatistik',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  icon: Icons.arrow_upward,
                  iconColor: colorScheme.tertiary,
                  label: 'Anstieg',
                  value: profile.formattedAscent,
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
              Expanded(
                child: _StatItem(
                  icon: Icons.arrow_downward,
                  iconColor: colorScheme.error,
                  label: 'Abstieg',
                  value: profile.formattedDescent,
                ),
              ),
            ],
          ),
          Divider(
            height: 20,
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  icon: Icons.landscape,
                  iconColor: colorScheme.primary,
                  label: 'Hoechster Punkt',
                  value: profile.formattedMaxElevation,
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
              Expanded(
                child: _StatItem(
                  icon: Icons.water,
                  iconColor: colorScheme.secondary,
                  label: 'Tiefster Punkt',
                  value: profile.formattedMinElevation,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Einzelnes Statistik-Element
class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
