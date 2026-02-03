import 'package:flutter/material.dart';
import '../../../data/models/trip.dart';
import '../../../core/constants/categories.dart';

/// Card die erscheint wenn ein POI-Waypoint nahe ist
class POIApproachCard extends StatelessWidget {
  final TripStop stop;
  final double distanceMeters;
  final VoidCallback onVisited;
  final VoidCallback? onSkip;

  const POIApproachCard({
    super.key,
    required this.stop,
    required this.distanceMeters,
    required this.onVisited,
    this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Kategorie-Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getCategoryIcon(stop.categoryId),
                color: colorScheme.onPrimaryContainer,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            // Name + Distanz
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    stop.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDistance(distanceMeters),
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Buttons
            if (onSkip != null)
              IconButton(
                onPressed: onSkip,
                icon: Icon(
                  Icons.skip_next,
                  color: colorScheme.onSurfaceVariant,
                ),
                tooltip: 'Überspringen',
              ),
            FilledButton.tonal(
              onPressed: onVisited,
              child: const Text('Besucht'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDistance(double meters) {
    if (meters < 100) {
      return '${meters.round()} m entfernt';
    } else if (meters < 1000) {
      return '${(meters / 50).round() * 50} m entfernt';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km entfernt';
    }
  }

  IconData _getCategoryIcon(String categoryId) {
    // Kategorie-Icons aus dem bestehenden System
    switch (categoryId) {
      case 'castle':
        return Icons.castle;
      case 'nature':
        return Icons.forest;
      case 'museum':
        return Icons.museum;
      case 'viewpoint':
        return Icons.landscape;
      case 'lake':
        return Icons.water;
      case 'coast':
        return Icons.beach_access;
      case 'park':
        return Icons.park;
      case 'city':
        return Icons.location_city;
      case 'activity':
        return Icons.attractions;
      case 'hotel':
        return Icons.hotel;
      case 'restaurant':
        return Icons.restaurant;
      case 'unesco':
        return Icons.account_balance;
      case 'church':
        return Icons.church;
      case 'monument':
        return Icons.account_balance;
      case 'attraction':
        return Icons.tour;
      default:
        return Icons.place;
    }
  }
}
