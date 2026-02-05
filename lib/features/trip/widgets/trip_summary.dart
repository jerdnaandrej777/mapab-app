import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format_utils.dart';

/// Trip-Zusammenfassung Widget
class TripSummary extends StatelessWidget {
  final double totalDistance;
  final int totalDuration;
  final int stopCount;
  final bool isRecalculating;

  const TripSummary({
    super.key,
    required this.totalDistance,
    required this.totalDuration,
    required this.stopCount,
    this.isRecalculating = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final onPrimary = colorScheme.onPrimary;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat(
                icon: Icons.straighten,
                value: FormatUtils.formatDistance(totalDistance),
                label: 'Gesamt',
                isLoading: isRecalculating,
                onPrimary: onPrimary,
              ),
              Container(
                width: 1,
                height: 40,
                color: onPrimary.withValues(alpha: 0.3),
              ),
              _buildStat(
                icon: Icons.timer,
                value: FormatUtils.formatDuration(totalDuration),
                label: 'Fahrzeit',
                isLoading: isRecalculating,
                onPrimary: onPrimary,
              ),
              Container(
                width: 1,
                height: 40,
                color: onPrimary.withValues(alpha: 0.3),
              ),
              _buildStat(
                icon: Icons.place,
                value: '$stopCount',
                label: 'Stops',
                isLoading: false,
                onPrimary: onPrimary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat({
    required IconData icon,
    required String value,
    required String label,
    required Color onPrimary,
    bool isLoading = false,
  }) {
    return Column(
      children: [
        isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(onPrimary),
                ),
              )
            : Icon(icon, color: onPrimary, size: 20),
        const SizedBox(height: 8),
        AnimatedOpacity(
          opacity: isLoading ? 0.5 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Text(
            value,
            style: TextStyle(
              color: onPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: onPrimary.withValues(alpha: 0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
