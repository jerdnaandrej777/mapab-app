import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/constants/categories.dart';
import 'weather_badge_unified.dart';

/// Kompakte POI-Card fuer Inline-Panel-Anzeige (~64px Hoehe)
/// Verwendet in Schnell-Modus Phase 2 und AI Trip Phase 2
class CompactPOICard extends StatelessWidget {
  final String name;
  final POICategory? category;
  final String? detourKm;
  final String? imageUrl;
  final VoidCallback onTap;
  final VoidCallback? onAdd;
  final VoidCallback? onRemove;
  final bool isAdded;
  final WeatherCondition? weatherCondition;

  const CompactPOICard({
    super.key,
    required this.name,
    required this.category,
    this.detourKm,
    this.imageUrl,
    required this.onTap,
    this.onAdd,
    this.onRemove,
    this.isAdded = false,
    this.weatherCondition,
  });

  static const double _cardHeight = 64.0;
  static const double _imageSize = 56.0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          height: _cardHeight,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isAdded
                ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Bild
              _buildImage(colorScheme),
              const SizedBox(width: 10),

              // Name + Kategorie + Umweg
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Name
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    // Kategorie + Umweg
                    Row(
                      children: [
                        Text(
                          category?.icon ?? '📍',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            category?.label ?? 'Unbekannt',
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (weatherCondition != null &&
                            weatherCondition != WeatherCondition.unknown &&
                            weatherCondition != WeatherCondition.mixed) ...[
                          const SizedBox(width: 5),
                          WeatherBadgeUnified.fromCategory(
                            condition: weatherCondition!,
                            category: category,
                            size: WeatherBadgeSize.compact,
                          ),
                        ],
                        if (detourKm != null) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: Container(
                              width: 3,
                              height: 3,
                              decoration: BoxDecoration(
                                color: colorScheme.onSurfaceVariant,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.route_rounded,
                            size: 11,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            detourKm!,
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Add/Check/Remove Button
              if (onAdd != null || onRemove != null || isAdded) ...[
                const SizedBox(width: 6),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isAdded ? onRemove : onAdd,
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isAdded
                            ? (onRemove != null
                                ? colorScheme.errorContainer.withValues(alpha: 0.3)
                                : colorScheme.primary.withValues(alpha: 0.15))
                            : colorScheme.primaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        isAdded
                            ? (onRemove != null
                                ? Icons.remove_rounded
                                : Icons.check_rounded)
                            : Icons.add_rounded,
                        color: isAdded
                            ? (onRemove != null
                                ? colorScheme.error
                                : colorScheme.primary)
                            : colorScheme.primary,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(ColorScheme colorScheme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: _imageSize,
        height: _imageSize,
        child: imageUrl != null
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                width: _imageSize,
                height: _imageSize,
                fit: BoxFit.cover,
                memCacheWidth: 112,
                memCacheHeight: 112,
                fadeInDuration: const Duration(milliseconds: 150),
                fadeOutDuration: const Duration(milliseconds: 100),
                placeholder: (context, url) => _buildPlaceholder(),
                errorWidget: (context, url, error) => _buildPlaceholder(),
              )
            : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: _imageSize,
      height: _imageSize,
      color: Color(category?.colorValue ?? 0xFF9E9E9E).withValues(alpha: 0.15),
      child: Center(
        child: Text(
          category?.icon ?? '📍',
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
