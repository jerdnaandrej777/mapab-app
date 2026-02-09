import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/comment.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../l10n/app_localizations.dart';

/// Karte fuer einen einzelnen Kommentar
class CommentCard extends ConsumerStatefulWidget {
  final Comment comment;
  final VoidCallback? onReplyTap;
  final VoidCallback? onDeleteTap;
  final VoidCallback? onFlagTap;
  final FutureOr<void> Function(String commentId)? onDeleteCommentTap;
  final FutureOr<void> Function(String commentId)? onFlagCommentTap;
  final Future<List<Comment>> Function()? loadReplies;

  const CommentCard({
    super.key,
    required this.comment,
    this.onReplyTap,
    this.onDeleteTap,
    this.onFlagTap,
    this.onDeleteCommentTap,
    this.onFlagCommentTap,
    this.loadReplies,
  });

  @override
  ConsumerState<CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends ConsumerState<CommentCard> {
  bool _showReplies = false;
  bool _isLoadingReplies = false;
  List<Comment>? _replies;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authNotifierProvider);
    final isOwnComment = authState.user?.id == widget.comment.userId;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Avatar, Name, Zeit
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: colorScheme.primaryContainer,
                  backgroundImage: widget.comment.authorAvatar != null
                      ? NetworkImage(widget.comment.authorAvatar!)
                      : null,
                  child: widget.comment.authorAvatar == null
                      ? Text(
                          (widget.comment.authorName ?? 'A')
                              .substring(0, 1)
                              .toUpperCase(),
                          style: TextStyle(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.comment.authorName ?? l10n.anonymousUser,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.comment.timeAgo,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Kommentar-Text
                      Text(
                        widget.comment.content,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Actions: Antworten, Melden, Loeschen
            const SizedBox(height: 8),
            Row(
              children: [
                // Antworten-Button
                if (widget.onReplyTap != null && authState.isAuthenticated)
                  TextButton.icon(
                    onPressed: widget.onReplyTap,
                    icon: const Icon(Icons.reply, size: 18),
                    label: Text(l10n.commentReply),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                // Antworten anzeigen
                if (widget.comment.hasReplies ||
                    (widget.comment.replyCount > 0)) ...[
                  TextButton(
                    onPressed: _toggleReplies,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _showReplies ? Icons.expand_less : Icons.expand_more,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _showReplies
                              ? l10n.commentHideReplies
                              : l10n.commentShowReplies(
                                  widget.comment.replyCount),
                        ),
                      ],
                    ),
                  ),
                ],
                const Spacer(),
                // Melden
                if (!isOwnComment && widget.onFlagTap != null)
                  IconButton(
                    onPressed: widget.onFlagTap,
                    icon: Icon(Icons.flag_outlined,
                        size: 18, color: colorScheme.onSurfaceVariant),
                    tooltip: l10n.reportContent,
                    visualDensity: VisualDensity.compact,
                  ),
                // Loeschen
                if (isOwnComment && widget.onDeleteTap != null)
                  IconButton(
                    onPressed: widget.onDeleteTap,
                    icon: Icon(Icons.delete_outline,
                        size: 18, color: colorScheme.error),
                    tooltip: l10n.delete,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),

            // Antworten
            if (_showReplies) ...[
              const Divider(),
              if (_isLoadingReplies)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_replies != null && _replies!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 24),
                  child: Column(
                    children: _replies!
                        .map((reply) => _ReplyCard(
                              comment: reply,
                              onDeleteTap: widget.onDeleteCommentTap,
                              onFlagTap: widget.onFlagCommentTap,
                            ))
                        .toList(),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    l10n.poiNoComments,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _toggleReplies() async {
    if (_showReplies) {
      setState(() => _showReplies = false);
      return;
    }

    // Bereits geladen
    if (_replies != null) {
      setState(() => _showReplies = true);
      return;
    }

    // Laden
    if (widget.loadReplies == null) return;

    setState(() {
      _showReplies = true;
      _isLoadingReplies = true;
    });

    final replies = await widget.loadReplies!();

    if (mounted) {
      setState(() {
        _replies = replies;
        _isLoadingReplies = false;
      });
    }
  }
}

/// Kompakte Antwort-Karte
class _ReplyCard extends ConsumerWidget {
  final Comment comment;
  final FutureOr<void> Function(String commentId)? onDeleteTap;
  final FutureOr<void> Function(String commentId)? onFlagTap;

  const _ReplyCard({
    required this.comment,
    this.onDeleteTap,
    this.onFlagTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authNotifierProvider);
    final isOwnComment = authState.user?.id == comment.userId;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: colorScheme.secondaryContainer,
            backgroundImage: comment.authorAvatar != null
                ? NetworkImage(comment.authorAvatar!)
                : null,
            child: comment.authorAvatar == null
                ? Text(
                    (comment.authorName ?? 'A').substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSecondaryContainer,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.authorName ?? l10n.anonymousUser,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      comment.timeAgo,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  comment.content,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (isOwnComment && onDeleteTap != null)
            IconButton(
              onPressed: () {
                onDeleteTap!(comment.id);
              },
              icon: Icon(Icons.delete_outline,
                  size: 16, color: colorScheme.error),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          if (!isOwnComment && onFlagTap != null)
            IconButton(
              onPressed: () {
                onFlagTap!(comment.id);
              },
              icon: const Icon(Icons.flag_outlined, size: 16),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}
