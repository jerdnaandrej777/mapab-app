import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers/poi_social_provider.dart';
import '../../../l10n/app_localizations.dart';

/// Widget zur Anzeige der POI-Bewertung mit Sterne und "Bewerten"-Button
class POIRatingWidget extends ConsumerWidget {
  final String poiId;
  final bool compact;
  final VoidCallback? onTapRate;

  const POIRatingWidget({
    super.key,
    required this.poiId,
    this.compact = false,
    this.onTapRate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final socialState = ref.watch(pOISocialNotifierProvider(poiId));
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final avgRating = socialState.avgRating;
    final reviewCount = socialState.reviewCount;
    final hasMyRating = socialState.hasMyRating;

    if (compact) {
      return _buildCompact(context, avgRating, reviewCount, colorScheme);
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.star_rounded,
                  color: colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.poiRatingLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                if (reviewCount > 0) ...[
                  Text(
                    avgRating.toStringAsFixed(1),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '($reviewCount)',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            // Sterne-Anzeige
            Row(
              children: [
                _buildStarRating(avgRating, colorScheme),
                const Spacer(),
                FilledButton.tonalIcon(
                  onPressed: onTapRate,
                  icon: Icon(hasMyRating ? Icons.edit : Icons.rate_review),
                  label: Text(hasMyRating ? l10n.reviewEdit : l10n.reviewSubmit),
                ),
              ],
            ),
            if (reviewCount == 0) ...[
              const SizedBox(height: 8),
              Text(
                l10n.poiBeFirstReview,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompact(
    BuildContext context,
    double avgRating,
    int reviewCount,
    ColorScheme colorScheme,
  ) {
    return InkWell(
      onTap: onTapRate,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star_rounded,
              color: reviewCount > 0 ? Colors.amber : colorScheme.outline,
              size: 18,
            ),
            const SizedBox(width: 4),
            Text(
              reviewCount > 0 ? avgRating.toStringAsFixed(1) : '-',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(width: 2),
            Text(
              '($reviewCount)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStarRating(double rating, ColorScheme colorScheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        IconData icon;
        Color color;

        if (rating >= starValue) {
          icon = Icons.star_rounded;
          color = Colors.amber;
        } else if (rating >= starValue - 0.5) {
          icon = Icons.star_half_rounded;
          color = Colors.amber;
        } else {
          icon = Icons.star_outline_rounded;
          color = colorScheme.outline;
        }

        return Icon(icon, color: color, size: 28);
      }),
    );
  }
}

/// Widget fuer interaktive Sterne-Auswahl
class StarRatingSelector extends StatelessWidget {
  final int rating;
  final ValueChanged<int> onRatingChanged;
  final double size;

  const StarRatingSelector({
    super.key,
    required this.rating,
    required this.onRatingChanged,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        final isSelected = rating >= starValue;

        return GestureDetector(
          onTap: () => onRatingChanged(starValue),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
              color: isSelected ? Colors.amber : Theme.of(context).colorScheme.outline,
              size: size,
            ),
          ),
        );
      }),
    );
  }
}
