import 'package:flutter/material.dart';
import '../../../core/constants/categories.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format_utils.dart';
import '../../map/widgets/weather_badge_unified.dart';

/// Trip-Stop Kachel für ReorderableListView
class TripStopTile extends StatelessWidget {
  final String name;
  final String icon;
  final int detourKm;
  final int durationMinutes;
  final int index;
  final VoidCallback onRemove;
  final VoidCallback onEdit;
  final VoidCallback? onTap;
  final WeatherCondition? weatherCondition;
  final bool isWeatherResilient;

  const TripStopTile({
    super.key,
    required this.name,
    required this.icon,
    required this.detourKm,
    required this.durationMinutes,
    required this.index,
    required this.onRemove,
    required this.onEdit,
    this.onTap,
    this.weatherCondition,
    this.isWeatherResilient = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
        children: [
          // Drag Handle
          Container(
            padding: const EdgeInsets.all(12),
            child: ReorderableDragStartListener(
              index: index,
              child: Icon(
                Icons.drag_handle,
                color: theme.hintColor,
              ),
            ),
          ),

          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? colorScheme.surfaceContainerHighest : AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(icon, style: const TextStyle(fontSize: 24)),
            ),
          ),

          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.route,
                          size: 14, color: theme.textTheme.bodySmall?.color),
                      const SizedBox(width: 4),
                      Text(
                        '+$detourKm km',
                        style: TextStyle(
                          color: theme.textTheme.bodySmall?.color,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.timer,
                          size: 14, color: theme.textTheme.bodySmall?.color),
                      const SizedBox(width: 4),
                      Text(
                        FormatUtils.formatDuration(durationMinutes),
                        style: TextStyle(
                          color: theme.textTheme.bodySmall?.color,
                          fontSize: 12,
                        ),
                      ),
                      if (weatherCondition != null &&
                          weatherCondition != WeatherCondition.unknown &&
                          weatherCondition != WeatherCondition.mixed) ...[
                        const SizedBox(width: 8),
                        WeatherBadgeUnified(
                          condition: weatherCondition!,
                          isWeatherResilient: isWeatherResilient,
                          size: WeatherBadgeSize.compact,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Actions
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: theme.textTheme.bodySmall?.color),
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  onEdit();
                  break;
                case 'remove':
                  onRemove();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 8),
                    Text('Bearbeiten'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'remove',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 20, color: Theme.of(context).colorScheme.error),
                    const SizedBox(width: 8),
                    Text('Entfernen', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}
