import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/categories.dart';
import '../../../core/utils/format_utils.dart';

/// POI-Karte für Liste
class POICard extends StatelessWidget {
  final String name;
  final POICategory category;
  final String? distance;
  final double rating;
  final int reviewCount;
  final bool isMustSee;
  final String? imageUrl;
  final VoidCallback onTap;
  final VoidCallback? onAddToTrip;
  final bool showWeatherWarning;
  final List<POIHighlight> highlights;

  const POICard({
    super.key,
    required this.name,
    required this.category,
    this.distance,
    required this.rating,
    required this.reviewCount,
    this.isMustSee = false,
    this.imageUrl,
    required this.onTap,
    this.onAddToTrip,
    this.showWeatherWarning = false,
    this.highlights = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bild-Header
            Stack(
              children: [
                // Bild oder Placeholder
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: imageUrl!,
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => _buildImagePlaceholder(),
                          errorWidget: (context, url, error) =>
                              _buildImagePlaceholder(),
                        )
                      : _buildImagePlaceholder(),
                ),

                // Highlight Badges (UNESCO, Must-See, Historic, Secret)
                if (highlights.isNotEmpty || isMustSee)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Row(
                      children: [
                        // UNESCO Badge
                        if (highlights.any((h) => h == POIHighlight.unesco))
                          _buildHighlightBadge(
                            POIHighlight.unesco.icon,
                            'UNESCO',
                            const Color(0xFF00CED1),
                          ),
                        // Must-See Badge
                        if (isMustSee || highlights.any((h) => h == POIHighlight.mustSee))
                          Padding(
                            padding: EdgeInsets.only(
                              left: highlights.any((h) => h == POIHighlight.unesco) ? 4 : 0,
                            ),
                            child: _buildHighlightBadge(
                              '⭐',
                              'Must-See',
                              Colors.orange,
                            ),
                          ),
                        // Secret/Geheimtipp Badge
                        if (highlights.any((h) => h == POIHighlight.secret))
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: _buildHighlightBadge(
                              '💎',
                              'Geheimtipp',
                              Colors.purple,
                            ),
                          ),
                      ],
                    ),
                  ),

                // Kategorie Badge
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      category.icon,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),

                // Wetter-Warnung
                if (showWeatherWarning)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.wb_cloudy,
                            color: Colors.orange.shade700,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Outdoor',
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  // Kategorie & Distanz
                  Row(
                    children: [
                      Text(
                        category.label,
                        style: TextStyle(
                          color: theme.textTheme.bodySmall?.color,
                          fontSize: 13,
                        ),
                      ),
                      if (distance != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: theme.hintColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.route,
                          size: 14,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          distance!,
                          style: TextStyle(
                            color: theme.textTheme.bodySmall?.color,
                            fontSize: 13,
                          ),
                        ),
                      ],
                      // Historic Badge inline
                      if (highlights.any((h) => h == POIHighlight.historic)) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.brown.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '🏛️ Historisch',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.brown.shade700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Bewertung & Add-Button
                  Row(
                    children: [
                      // Sterne
                      ...List.generate(5, (index) {
                        if (index < rating.floor()) {
                          return const Icon(Icons.star,
                              size: 16, color: Colors.amber);
                        } else if (index < rating) {
                          return const Icon(Icons.star_half,
                              size: 16, color: Colors.amber);
                        }
                        return Icon(Icons.star_border,
                            size: 16, color: isDark ? Colors.grey.shade600 : Colors.grey.shade300);
                      }),

                      const SizedBox(width: 6),

                      // Rating & Reviews
                      Text(
                        '${FormatUtils.formatRating(rating)} (${FormatUtils.formatNumber(reviewCount)})',
                        style: TextStyle(
                          color: theme.textTheme.bodySmall?.color,
                          fontSize: 12,
                        ),
                      ),

                      const Spacer(),

                      // Add-Button
                      if (onAddToTrip != null)
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          color: colorScheme.primary,
                          iconSize: 28,
                          onPressed: onAddToTrip,
                          tooltip: 'Zur Route hinzufügen',
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 140,
      width: double.infinity,
      color: Color(category.colorValue).withOpacity(0.2),
      child: Center(
        child: Text(
          category.icon,
          style: const TextStyle(fontSize: 48),
        ),
      ),
    );
  }

  Widget _buildHighlightBadge(String icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
