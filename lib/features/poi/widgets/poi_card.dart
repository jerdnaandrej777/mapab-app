import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/categories.dart';
import '../../../core/utils/format_utils.dart';
import '../../map/widgets/weather_bar.dart';

/// POI-Karte für Liste - Kompaktes horizontales Layout
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
  final WeatherCondition? weatherCondition;

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
    this.weatherCondition,
  });

  // Bildgröße: 88x88 für kompaktes, ausgewogenes Layout
  static const double _imageSize = 88.0;
  // Minimale Höhe der Card für konsistentes Layout
  static const double _minCardHeight = 96.0;

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
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        // FIX v1.5.5: Feste Höhe statt IntrinsicHeight für stabiles Layout
        // IntrinsicHeight + height: double.infinity verursachte Layout-Probleme
        child: SizedBox(
          height: _minCardHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Linke Seite: Quadratisches Bild
              _buildImage(colorScheme),

              // Rechte Seite: Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Oberer Bereich: Name & Kategorie
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name mit Kategorie-Icon
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                    height: 1.2,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                category.icon,
                                style: const TextStyle(fontSize: 20),
                              ),
                            ],
                          ),

                          const SizedBox(height: 4),

                          // Kategorie-Label & Distanz & Wetter-Badge
                          Row(
                            children: [
                              Text(
                                category.label,
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                              // Wetter-Badge anzeigen (v1.7.6)
                              if (weatherCondition != null) ...[
                                const SizedBox(width: 6),
                                WeatherBadge(
                                  overallCondition: weatherCondition!,
                                  isIndoorPOI: category.isIndoor,
                                ),
                              ],
                              if (distance != null) ...[
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
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
                                  size: 12,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  distance!,
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // Unterer Bereich: Rating & Badges
                      Row(
                        children: [
                          // Kompakte Sterne-Anzeige
                          _buildCompactRating(rating, isDark),

                          const SizedBox(width: 6),

                          Text(
                            '${FormatUtils.formatRating(rating)}',
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          Text(
                            ' (${FormatUtils.formatNumber(reviewCount)})',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),

                          const Spacer(),

                          // Add-Button
                          if (onAddToTrip != null)
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: onAddToTrip,
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primaryContainer.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Icon(
                                    Icons.add_rounded,
                                    color: colorScheme.primary,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Quadratisches Bild mit Badges
  Widget _buildImage(ColorScheme colorScheme) {
    return SizedBox(
      width: _imageSize,
      child: Stack(
        children: [
          // Bild
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(16),
            ),
            child: imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: imageUrl!,
                    width: _imageSize,
                    height: _minCardHeight,
                    fit: BoxFit.cover,
                    memCacheWidth: 176, // 2x für Retina
                    memCacheHeight: 176,
                    fadeInDuration: const Duration(milliseconds: 150),
                    fadeOutDuration: const Duration(milliseconds: 100),
                    placeholder: (context, url) => _buildImagePlaceholder(),
                    errorWidget: (context, url, error) => _buildImagePlaceholder(),
                  )
                : _buildImagePlaceholder(),
          ),

          // Highlight Badges (kompakt, nur Icons)
          if (_hasHighlights)
            Positioned(
              top: 6,
              left: 6,
              child: _buildCompactBadges(),
            ),

          // Wetter-Warnung
          if (showWeatherWarning)
            Positioned(
              bottom: 6,
              left: 6,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.wb_cloudy_rounded,
                  color: Colors.orange.shade700,
                  size: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool get _hasHighlights =>
      isMustSee ||
      highlights.any((h) =>
          h == POIHighlight.unesco ||
          h == POIHighlight.mustSee ||
          h == POIHighlight.secret);

  /// Kompakte Badges (nur Icons, übereinander)
  Widget _buildCompactBadges() {
    final badges = <Widget>[];

    // UNESCO
    if (highlights.any((h) => h == POIHighlight.unesco)) {
      badges.add(_buildIconBadge('🏛️', const Color(0xFF00CED1)));
    }

    // Must-See
    if (isMustSee || highlights.any((h) => h == POIHighlight.mustSee)) {
      badges.add(_buildIconBadge('⭐', Colors.orange));
    }

    // Geheimtipp
    if (highlights.any((h) => h == POIHighlight.secret)) {
      badges.add(_buildIconBadge('💎', Colors.purple));
    }

    if (badges.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: badges
          .map((badge) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: badge,
              ))
          .toList(),
    );
  }

  Widget _buildIconBadge(String icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        icon,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  /// Kompakte Rating-Anzeige mit gefülltem/leerem Stern
  Widget _buildCompactRating(double rating, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.star_rounded,
          size: 16,
          color: Colors.amber.shade600,
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: _imageSize,
      height: _minCardHeight,
      color: Color(category.colorValue).withOpacity(0.15),
      child: Center(
        child: Text(
          category.icon,
          style: const TextStyle(fontSize: 32),
        ),
      ),
    );
  }
}
