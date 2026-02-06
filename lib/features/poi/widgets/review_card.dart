import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/poi_review.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../l10n/app_localizations.dart';

/// Karte fuer eine einzelne Bewertung
class ReviewCard extends ConsumerWidget {
  final POIReview review;
  final VoidCallback? onHelpfulTap;
  final VoidCallback? onDeleteTap;
  final VoidCallback? onFlagTap;

  const ReviewCard({
    super.key,
    required this.review,
    this.onHelpfulTap,
    this.onDeleteTap,
    this.onFlagTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authNotifierProvider);
    final isOwnReview = authState.user?.id == review.userId;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Avatar, Name, Rating
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: colorScheme.primaryContainer,
                  backgroundImage: review.authorAvatar != null
                      ? NetworkImage(review.authorAvatar!)
                      : null,
                  child: review.authorAvatar == null
                      ? Text(
                          (review.authorName ?? 'A').substring(0, 1).toUpperCase(),
                          style: TextStyle(color: colorScheme.onPrimaryContainer),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                // Name und Datum
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.authorName ?? l10n.anonymousUser,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (review.visitDate != null)
                        Text(
                          '${l10n.reviewVisitedOn} ${review.formattedVisitDate}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                    ],
                  ),
                ),
                // Sterne
                _buildStarRating(review.rating, colorScheme),
              ],
            ),

            // Review-Text
            if (review.hasReviewText) ...[
              const SizedBox(height: 12),
              Text(
                review.reviewText!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],

            // Footer: Hilfreich-Button, Melden, Loeschen
            const SizedBox(height: 12),
            Row(
              children: [
                // Hilfreich-Button
                _HelpfulButton(
                  count: review.helpfulCount,
                  isHelpful: review.isHelpfulByMe,
                  onTap: isOwnReview ? null : onHelpfulTap,
                ),
                const Spacer(),
                // Melden (nur fuer fremde Reviews)
                if (!isOwnReview && onFlagTap != null)
                  IconButton(
                    icon: const Icon(Icons.flag_outlined, size: 20),
                    onPressed: onFlagTap,
                    tooltip: l10n.reportContent,
                    visualDensity: VisualDensity.compact,
                  ),
                // Loeschen (nur fuer eigene Reviews)
                if (isOwnReview && onDeleteTap != null)
                  IconButton(
                    icon: Icon(Icons.delete_outline, size: 20, color: colorScheme.error),
                    onPressed: onDeleteTap,
                    tooltip: l10n.delete,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStarRating(int rating, ColorScheme colorScheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
          color: index < rating ? Colors.amber : colorScheme.outline,
          size: 18,
        );
      }),
    );
  }
}

/// Button fuer "Hilfreich"-Markierung
class _HelpfulButton extends StatelessWidget {
  final int count;
  final bool isHelpful;
  final VoidCallback? onTap;

  const _HelpfulButton({
    required this.count,
    required this.isHelpful,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isHelpful ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isHelpful ? Icons.thumb_up : Icons.thumb_up_outlined,
              size: 16,
              color: isHelpful ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              count > 0 ? '$count ${l10n.reviewHelpful}' : l10n.reviewHelpful,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isHelpful ? colorScheme.primary : colorScheme.onSurfaceVariant,
                    fontWeight: isHelpful ? FontWeight.bold : FontWeight.normal,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Liste aller Bewertungen
class ReviewsList extends ConsumerWidget {
  final String poiId;
  final List<POIReview> reviews;
  final Function(String reviewId) onHelpfulTap;
  final Function(String reviewId)? onDeleteTap;
  final Function(String reviewId)? onFlagTap;

  const ReviewsList({
    super.key,
    required this.poiId,
    required this.reviews,
    required this.onHelpfulTap,
    this.onDeleteTap,
    this.onFlagTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    if (reviews.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.rate_review_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.poiNoReviews,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: reviews.length,
      itemBuilder: (context, index) {
        final review = reviews[index];
        return ReviewCard(
          review: review,
          onHelpfulTap: () => onHelpfulTap(review.id),
          onDeleteTap: onDeleteTap != null ? () => onDeleteTap!(review.id) : null,
          onFlagTap: onFlagTap != null ? () => onFlagTap!(review.id) : null,
        );
      },
    );
  }
}
