import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/poi_social_provider.dart';
import '../../../l10n/app_localizations.dart';
import 'poi_rating_widget.dart';

/// Bottom Sheet zum Abgeben einer Bewertung
class SubmitReviewSheet extends ConsumerStatefulWidget {
  final String poiId;
  final String poiName;

  const SubmitReviewSheet({
    super.key,
    required this.poiId,
    required this.poiName,
  });

  /// Zeigt das Sheet an
  static Future<bool?> show(
    BuildContext context, {
    required String poiId,
    required String poiName,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => SubmitReviewSheet(
        poiId: poiId,
        poiName: poiName,
      ),
    );
  }

  @override
  ConsumerState<SubmitReviewSheet> createState() => _SubmitReviewSheetState();
}

class _SubmitReviewSheetState extends ConsumerState<SubmitReviewSheet> {
  final _reviewController = TextEditingController();
  int _rating = 0;
  DateTime? _visitDate;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadExistingReview();
  }

  void _loadExistingReview() {
    final socialState = ref.read(pOISocialNotifierProvider(widget.poiId));
    if (socialState.stats?.hasMyRating ?? false) {
      _rating = socialState.stats!.myRating!;
      if (socialState.stats!.myReviewText != null) {
        _reviewController.text = socialState.stats!.myReviewText!;
      }
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authNotifierProvider);
    final socialState = ref.watch(pOISocialNotifierProvider(widget.poiId));
    final hasExistingReview = socialState.stats?.hasMyRating ?? false;

    // Nicht eingeloggt
    if (!authState.isAuthenticated) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 48),
            const SizedBox(height: 16),
            Text(
              l10n.socialLoginRequired,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.ok),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasExistingReview ? l10n.reviewEdit : l10n.reviewSubmit,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.poiName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Sterne-Auswahl
            Text(
              l10n.reviewYourRating,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            Center(
              child: StarRatingSelector(
                rating: _rating,
                onRatingChanged: (rating) => setState(() => _rating = rating),
                size: 48,
              ),
            ),
            if (_rating == 0) ...[
              const SizedBox(height: 8),
              Text(
                l10n.socialRatingRequired,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.error,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),

            // Review-Text
            Text(
              l10n.reviewWriteOptional,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _reviewController,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: l10n.reviewPlaceholder,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Besuchsdatum
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: Text(l10n.reviewVisitDate),
              subtitle: Text(
                _visitDate != null
                    ? '${_visitDate!.day}.${_visitDate!.month}.${_visitDate!.year}'
                    : l10n.reviewVisitDateOptional,
              ),
              trailing: _visitDate != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _visitDate = null),
                    )
                  : null,
              onTap: _selectDate,
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                if (hasExistingReview) ...[
                  OutlinedButton(
                    onPressed: _isSubmitting ? null : _deleteReview,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.error,
                    ),
                    child: Text(l10n.reviewDelete),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: FilledButton(
                    onPressed: _rating == 0 || _isSubmitting ? null : _submitReview,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(hasExistingReview ? l10n.save : l10n.reviewSubmit),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _visitDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() => _visitDate = date);
    }
  }

  Future<void> _submitReview() async {
    if (_rating == 0) return;

    setState(() => _isSubmitting = true);

    final success = await ref.read(pOISocialNotifierProvider(widget.poiId).notifier).submitReview(
      rating: _rating,
      reviewText: _reviewController.text.trim().isEmpty ? null : _reviewController.text.trim(),
      visitDate: _visitDate,
    );

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.reviewSuccess)),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.reviewError),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _deleteReview() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.reviewDelete),
        content: Text(l10n.reviewDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);

    final success = await ref.read(pOISocialNotifierProvider(widget.poiId).notifier).deleteReview();

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (success) {
      Navigator.pop(context, true);
    }
  }
}
