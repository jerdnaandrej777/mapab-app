import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/comment.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/poi_social_provider.dart';
import '../../../data/repositories/poi_social_repo.dart';
import '../../../l10n/app_localizations.dart';
import 'comment_card.dart';

/// Kommentar-Sektion fuer POIs
class POICommentsSection extends ConsumerStatefulWidget {
  final String poiId;

  const POICommentsSection({
    super.key,
    required this.poiId,
  });

  @override
  ConsumerState<POICommentsSection> createState() => _POICommentsSectionState();
}

class _POICommentsSectionState extends ConsumerState<POICommentsSection> {
  final _commentController = TextEditingController();
  String? _replyToCommentId;
  String? _replyToAuthorName;

  @override
  void initState() {
    super.initState();
    // Initialen Ladeimpuls setzen, falls der umgebende Screen die Social-Daten
    // noch nicht geladen hat.
    Future.microtask(() {
      ref.read(pOISocialNotifierProvider(widget.poiId).notifier).loadComments();
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final socialState = ref.watch(pOISocialNotifierProvider(widget.poiId));
    final authState = ref.watch(authNotifierProvider);
    final comments = socialState.comments;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(Icons.comment_outlined, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              '${l10n.poiComments} (${comments.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Kommentar-Eingabe
        if (authState.isAuthenticated) ...[
          _buildCommentInput(
              context, l10n, colorScheme, socialState.isSubmitting),
          const SizedBox(height: 16),
        ],

        // Kommentar-Liste
        if (comments.isEmpty)
          _buildEmptyState(
              context, l10n, colorScheme, authState.isAuthenticated)
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: comments.length,
            itemBuilder: (context, index) {
              final comment = comments[index];
              return CommentCard(
                comment: comment,
                onReplyTap: () => _setReplyTo(comment),
                onDeleteTap: comment.isOwnedBy(authState.user?.id)
                    ? () => _deleteComment(comment.id)
                    : null,
                onFlagTap: !comment.isOwnedBy(authState.user?.id)
                    ? () => _flagComment(comment.id)
                    : null,
                onDeleteCommentTap: _deleteComment,
                onFlagCommentTap: _flagComment,
                loadReplies: () => _loadReplies(comment.id),
              );
            },
          ),
      ],
    );
  }

  Widget _buildCommentInput(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme colorScheme,
    bool isSubmitting,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Antwort-Hinweis
        if (_replyToCommentId != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.5),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(Icons.reply, size: 16, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${l10n.commentReplyTo} $_replyToAuthorName',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                        ),
                  ),
                ),
                IconButton(
                  onPressed: _cancelReply,
                  icon: const Icon(Icons.close, size: 16),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
        // Eingabefeld
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: _replyToCommentId != null
                ? const BorderRadius.vertical(bottom: Radius.circular(12))
                : BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  maxLines: 3,
                  minLines: 1,
                  maxLength: 2000,
                  decoration: InputDecoration(
                    hintText: l10n.commentPlaceholder,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(12),
                    counterText: '',
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 4, bottom: 4),
                child: IconButton(
                  onPressed: isSubmitting ? null : _submitComment,
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.send, color: colorScheme.primary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme colorScheme,
    bool isAuthenticated,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.poiNoComments,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              isAuthenticated
                  ? l10n.poiBeFirstComment
                  : l10n.socialLoginRequired,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _setReplyTo(Comment comment) {
    setState(() {
      _replyToCommentId = comment.id;
      _replyToAuthorName = comment.authorName ?? 'Anonym';
    });
    // Focus auf Eingabefeld
    FocusScope.of(context).requestFocus(FocusNode());
  }

  void _cancelReply() {
    setState(() {
      _replyToCommentId = null;
      _replyToAuthorName = null;
    });
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final success = await ref
        .read(pOISocialNotifierProvider(widget.poiId).notifier)
        .addComment(
          content,
          parentId: _replyToCommentId,
        );

    if (success && mounted) {
      _commentController.clear();
      _cancelReply();
    }
  }

  Future<void> _deleteComment(String commentId) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.commentDelete),
        content: Text(l10n.commentDeleteConfirm),
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

    if (confirmed == true) {
      await ref
          .read(pOISocialNotifierProvider(widget.poiId).notifier)
          .deleteComment(commentId);
    }
  }

  Future<void> _flagComment(String commentId) async {
    final l10n = AppLocalizations.of(context)!;
    final success = await ref
        .read(pOISocialNotifierProvider(widget.poiId).notifier)
        .flagContent(
          contentType: 'comment',
          contentId: commentId,
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? l10n.reportSuccess : l10n.errorGeneric),
        ),
      );
    }
  }

  Future<List<Comment>> _loadReplies(String parentId) async {
    return await ref
        .read(pOISocialNotifierProvider(widget.poiId).notifier)
        .loadReplies(parentId);
  }
}

/// Kommentar-Sektion fuer Trips (eigenstaendig)
class TripCommentsSection extends ConsumerStatefulWidget {
  final String tripId;

  const TripCommentsSection({
    super.key,
    required this.tripId,
  });

  @override
  ConsumerState<TripCommentsSection> createState() =>
      _TripCommentsSectionState();
}

class _TripCommentsSectionState extends ConsumerState<TripCommentsSection> {
  final _commentController = TextEditingController();
  String? _replyToCommentId;
  String? _replyToAuthorName;

  @override
  void initState() {
    super.initState();
    // Kommentare laden
    Future.microtask(() {
      ref
          .read(tripCommentsNotifierProvider(widget.tripId).notifier)
          .loadComments();
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final commentsState =
        ref.watch(tripCommentsNotifierProvider(widget.tripId));
    final authState = ref.watch(authNotifierProvider);
    final comments = commentsState.comments;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(Icons.comment_outlined, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              '${l10n.poiComments} (${comments.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Loading
        if (commentsState.isLoading)
          const Center(child: CircularProgressIndicator())
        else ...[
          // Kommentar-Eingabe
          if (authState.isAuthenticated) ...[
            _buildCommentInput(
                context, l10n, colorScheme, commentsState.isSubmitting),
            const SizedBox(height: 16),
          ],

          // Kommentar-Liste
          if (comments.isEmpty)
            _buildEmptyState(
                context, l10n, colorScheme, authState.isAuthenticated)
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: comments.length,
              itemBuilder: (context, index) {
                final comment = comments[index];
                return CommentCard(
                  comment: comment,
                  onReplyTap: () => _setReplyTo(comment),
                  onDeleteTap: comment.isOwnedBy(authState.user?.id)
                      ? () => _deleteComment(comment.id)
                      : null,
                  onFlagTap: !comment.isOwnedBy(authState.user?.id)
                      ? () => _flagComment(comment.id)
                      : null,
                  onDeleteCommentTap: _deleteComment,
                  onFlagCommentTap: _flagComment,
                  loadReplies: () => _loadReplies(comment.id),
                );
              },
            ),
        ],
      ],
    );
  }

  Widget _buildCommentInput(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme colorScheme,
    bool isSubmitting,
  ) {
    // Gleiche Implementierung wie POICommentsSection
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_replyToCommentId != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.5),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(Icons.reply, size: 16, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${l10n.commentReplyTo} $_replyToAuthorName',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                        ),
                  ),
                ),
                IconButton(
                  onPressed: _cancelReply,
                  icon: const Icon(Icons.close, size: 16),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: _replyToCommentId != null
                ? const BorderRadius.vertical(bottom: Radius.circular(12))
                : BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  maxLines: 3,
                  minLines: 1,
                  maxLength: 2000,
                  decoration: InputDecoration(
                    hintText: l10n.commentPlaceholder,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(12),
                    counterText: '',
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 4, bottom: 4),
                child: IconButton(
                  onPressed: isSubmitting ? null : _submitComment,
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.send, color: colorScheme.primary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme colorScheme,
    bool isAuthenticated,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.poiNoComments,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _setReplyTo(Comment comment) {
    setState(() {
      _replyToCommentId = comment.id;
      _replyToAuthorName = comment.authorName ?? 'Anonym';
    });
  }

  void _cancelReply() {
    setState(() {
      _replyToCommentId = null;
      _replyToAuthorName = null;
    });
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final success = await ref
        .read(tripCommentsNotifierProvider(widget.tripId).notifier)
        .addComment(
          content,
          parentId: _replyToCommentId,
        );

    if (success && mounted) {
      _commentController.clear();
      _cancelReply();
    }
  }

  Future<void> _deleteComment(String commentId) async {
    await ref
        .read(tripCommentsNotifierProvider(widget.tripId).notifier)
        .deleteComment(commentId);
  }

  Future<void> _flagComment(String commentId) async {
    final l10n = AppLocalizations.of(context)!;
    final repo = ref.read(poiSocialRepositoryProvider);
    final success = await repo.flagContent(
      contentType: 'comment',
      contentId: commentId,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? l10n.reportSuccess : l10n.errorGeneric),
        ),
      );
    }
  }

  Future<List<Comment>> _loadReplies(String parentId) async {
    return await ref
        .read(tripCommentsNotifierProvider(widget.tripId).notifier)
        .loadReplies(parentId);
  }
}
