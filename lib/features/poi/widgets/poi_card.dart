import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/categories.dart';
import '../../../core/utils/format_utils.dart';

/// POI-Karte für Liste
class POICard extends StatelessWidget {
  final String name;
  final POICategory category;
  final String distance;
  final double rating;
  final int reviewCount;
  final bool isMustSee;
  final String? imageUrl;
  final VoidCallback onTap;
  final VoidCallback? onAddToTrip;
  final bool showWeatherWarning;

  const POICard({
    super.key,
    required this.name,
    required this.category,
    required this.distance,
    required this.rating,
    required this.reviewCount,
    this.isMustSee = false,
    this.imageUrl,
    required this.onTap,
    this.onAddToTrip,
    this.showWeatherWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow,
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

                // Must-See Badge
                if (isMustSee)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Must-See',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Kategorie Badge
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.textHint,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.route,
                        size: 14,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        distance,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
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
                            size: 16, color: Colors.grey.shade300);
                      }),

                      const SizedBox(width: 6),

                      // Rating & Reviews
                      Text(
                        '${FormatUtils.formatRating(rating)} (${FormatUtils.formatNumber(reviewCount)})',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),

                      const Spacer(),

                      // Add-Button
                      if (onAddToTrip != null)
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          color: AppTheme.primaryColor,
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
}
