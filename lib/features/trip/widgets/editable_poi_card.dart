import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/categories.dart';
import '../../../data/models/poi.dart';
import '../../../data/models/trip.dart';
import '../../map/widgets/weather_badge_unified.dart';
import '../../poi/providers/poi_state_provider.dart';
import '../../random_trip/widgets/poi_reroll_button.dart';

/// Bearbeitbare POI-Karte für den Day Editor
/// Zeigt POI-Bild, Name, Kategorie, Umweg-Info und Wetter-Badge
/// Mit Delete/Reroll Buttons und Navigation zu POI-Details
class EditablePOICard extends ConsumerWidget {
  final TripStop stop;
  final POI? poiFromState;
  final bool isLoading;
  final bool canDelete;
  final VoidCallback onReroll;
  final VoidCallback onDelete;
  final WeatherCondition? dayWeather;

  static const double _cardHeight = 96.0;

  const EditablePOICard({
    super.key,
    required this.stop,
    this.poiFromState,
    required this.isLoading,
    required this.canDelete,
    required this.onReroll,
    required this.onDelete,
    this.dayWeather,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final category = poiFromState?.category ?? stop.category;
    final isWeatherResilient = category?.isWeatherResilient ?? false;
    final hasBadWeather = dayWeather == WeatherCondition.bad ||
        dayWeather == WeatherCondition.danger;
    final showWeatherWarning = !isWeatherResilient && hasBadWeather;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: showWeatherWarning
              ? Colors.orange.withOpacity(0.5)
              : colorScheme.outline.withOpacity(0.15),
          width: showWeatherWarning ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => _navigateToPOI(context, ref),
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: _cardHeight,
          child: Row(
            children: [
              // POI-Bild
              _buildImage(colorScheme, category),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Name
                      Text(
                        stop.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Kategorie + Wetter-Badge
                      Row(
                        children: [
                          Text(
                            stop.categoryIcon,
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              category?.label ?? stop.categoryId,
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurface.withOpacity(0.6),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (dayWeather != null &&
                              dayWeather != WeatherCondition.unknown &&
                              dayWeather != WeatherCondition.mixed) ...[
                            const SizedBox(width: 6),
                            WeatherBadgeUnified.fromCategory(
                              condition: dayWeather!,
                              category: category,
                              size: WeatherBadgeSize.inline,
                            ),
                          ],
                        ],
                      ),
                      if (stop.detourKm != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '+${stop.detourKm!.toStringAsFixed(1)} km Umweg',
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Action Buttons
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: POIActionButtons(
                  poiId: stop.poiId,
                  isLoading: isLoading,
                  canDelete: canDelete,
                  onReroll: onReroll,
                  onDelete: onDelete,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(ColorScheme colorScheme, POICategory? category) {
    final imageUrl = poiFromState?.imageUrl ?? stop.imageUrl;
    final cat = category ?? POICategory.attraction;

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(12),
        bottomLeft: Radius.circular(12),
      ),
      child: SizedBox(
        width: 80,
        height: _cardHeight,
        child: imageUrl != null
            ? CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    _buildPlaceholder(colorScheme, cat),
                errorWidget: (context, url, error) =>
                    _buildPlaceholder(colorScheme, cat),
              )
            : _buildPlaceholder(colorScheme, cat),
      ),
    );
  }

  Widget _buildPlaceholder(ColorScheme colorScheme, POICategory cat) {
    return Container(
      color: Color(cat.colorValue).withOpacity(0.2),
      child: Center(
        child: Text(
          cat.icon,
          style: const TextStyle(fontSize: 28),
        ),
      ),
    );
  }

  void _navigateToPOI(BuildContext context, WidgetRef ref) {
    final poiNotifier = ref.read(pOIStateNotifierProvider.notifier);
    if (poiFromState == null) {
      final poi = stop.toPOI();
      poiNotifier.addPOI(poi);
    }
    context.push('/poi/${stop.poiId}');
  }

}
