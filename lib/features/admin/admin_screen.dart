import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/l10n.dart';
import '../../data/models/admin_notification.dart';
import '../../data/providers/admin_provider.dart';

/// Admin-Dashboard mit Benachrichtigungen und Moderation
class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Admin-Status initialisieren und Dashboard laden
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminNotifierProvider.notifier).initialize();
      ref.read(adminNotifierProvider.notifier).loadDashboard();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final adminState = ref.watch(adminNotifierProvider);

    // Wenn nicht Admin, zurueck navigieren
    if (!adminState.isAdmin && !adminState.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.pop();
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.adminDashboard),
        actions: [
          // Statistiken-Button
          IconButton(
            onPressed: () => _showStatsDialog(context, adminState),
            icon: const Icon(Icons.analytics_outlined),
            tooltip: l10n.adminStats,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: Badge(
                isLabelVisible: adminState.unreadCount > 0,
                label: Text('${adminState.unreadCount}'),
                child: const Icon(Icons.notifications_outlined),
              ),
              text: l10n.adminNotifications,
            ),
            Tab(
              icon: Badge(
                isLabelVisible: adminState.flaggedCount > 0,
                label: Text('${adminState.flaggedCount}'),
                backgroundColor: colorScheme.error,
                child: const Icon(Icons.flag_outlined),
              ),
              text: l10n.adminModeration,
            ),
          ],
        ),
      ),
      body: adminState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _NotificationsTab(
                  notifications: adminState.notifications,
                  onMarkRead: (id) => ref
                      .read(adminNotifierProvider.notifier)
                      .markNotificationRead(id),
                  onMarkAllRead: () => ref
                      .read(adminNotifierProvider.notifier)
                      .markAllNotificationsRead(),
                ),
                _ModerationTab(
                  flaggedContent: adminState.flaggedContent,
                  onDelete: (type, id) => _handleDelete(context, type, id),
                  onApprove: (type, id) => _handleApprove(context, type, id),
                ),
              ],
            ),
    );
  }

  Future<void> _handleDelete(
    BuildContext context,
    String contentType,
    String contentId,
  ) async {
    final l10n = context.l10n;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.adminDelete),
        content: Text(l10n.adminDeleteConfirm),
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

    if (confirmed == true && mounted) {
      final success = await ref.read(adminNotifierProvider.notifier).deleteContent(
        contentType: contentType,
        contentId: contentId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? l10n.adminDeleteSuccess : l10n.adminDeleteError),
          ),
        );
      }
    }
  }

  Future<void> _handleApprove(
    BuildContext context,
    String contentType,
    String contentId,
  ) async {
    final l10n = context.l10n;

    final success = await ref.read(adminNotifierProvider.notifier).approveContent(
      contentType: contentType,
      contentId: contentId,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? l10n.adminApproveSuccess : l10n.adminApproveError),
        ),
      );
    }
  }

  void _showStatsDialog(BuildContext context, AdminState adminState) {
    final l10n = context.l10n;
    final stats = adminState.stats;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.adminStats),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatRow(
              icon: Icons.photo_outlined,
              label: l10n.poiPhotos,
              value: '${stats['totalPhotos'] ?? 0}',
              flagged: stats['flaggedPhotos'] ?? 0,
            ),
            const SizedBox(height: 8),
            _StatRow(
              icon: Icons.star_outline,
              label: l10n.poiReviews,
              value: '${stats['totalReviews'] ?? 0}',
              flagged: stats['flaggedReviews'] ?? 0,
            ),
            const SizedBox(height: 8),
            _StatRow(
              icon: Icons.comment_outlined,
              label: l10n.poiComments,
              value: '${stats['totalComments'] ?? 0}',
              flagged: stats['flaggedComments'] ?? 0,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final int flagged;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    this.flagged = 0,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(child: Text(label)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        if (flagged > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$flagged',
              style: TextStyle(
                color: colorScheme.error,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Tab fuer Admin-Benachrichtigungen
class _NotificationsTab extends StatelessWidget {
  final List<AdminNotification> notifications;
  final void Function(String) onMarkRead;
  final VoidCallback onMarkAllRead;

  const _NotificationsTab({
    required this.notifications,
    required this.onMarkRead,
    required this.onMarkAllRead,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 64,
              color: colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.adminNoNotifications,
              style: TextStyle(color: colorScheme.outline),
            ),
          ],
        ),
      );
    }

    final hasUnread = notifications.any((n) => !n.isRead);

    return Column(
      children: [
        if (hasUnread)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextButton.icon(
              onPressed: onMarkAllRead,
              icon: const Icon(Icons.done_all),
              label: Text(l10n.adminMarkAllRead),
            ),
          ),
        Expanded(
          child: ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _NotificationCard(
                notification: notification,
                onTap: () {
                  if (!notification.isRead) {
                    onMarkRead(notification.id);
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AdminNotification notification;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    IconData icon;
    String title;
    Color iconColor;

    switch (notification.type) {
      case AdminNotificationType.newPhoto:
        icon = Icons.photo_camera;
        title = l10n.adminNotificationNewPhoto;
        iconColor = Colors.blue;
        break;
      case AdminNotificationType.newReview:
        icon = Icons.star;
        title = l10n.adminNotificationNewReview;
        iconColor = Colors.amber;
        break;
      case AdminNotificationType.newComment:
        icon = Icons.comment;
        title = l10n.adminNotificationNewComment;
        iconColor = Colors.green;
        break;
      case AdminNotificationType.flaggedContent:
        icon = Icons.flag;
        title = l10n.adminNotificationFlagged;
        iconColor = colorScheme.error;
        break;
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: iconColor.withValues(alpha: 0.1),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (notification.userName != null)
            Text(notification.userName!),
          Text(
            notification.timeAgo,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.outline,
            ),
          ),
        ],
      ),
      trailing: notification.isRead
          ? null
          : Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
      onTap: onTap,
    );
  }
}

/// Tab fuer Moderation gemeldeter Inhalte
class _ModerationTab extends StatelessWidget {
  final List<FlaggedContent> flaggedContent;
  final void Function(String type, String id) onDelete;
  final void Function(String type, String id) onApprove;

  const _ModerationTab({
    required this.flaggedContent,
    required this.onDelete,
    required this.onApprove,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    if (flaggedContent.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.verified_outlined,
              size: 64,
              color: colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.adminNoFlagged,
              style: TextStyle(color: colorScheme.outline),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: flaggedContent.length,
      itemBuilder: (context, index) {
        final content = flaggedContent[index];
        return _FlaggedContentCard(
          content: content,
          onDelete: () => onDelete(
            content.contentType.name,
            content.contentId,
          ),
          onApprove: () => onApprove(
            content.contentType.name,
            content.contentId,
          ),
        );
      },
    );
  }
}

class _FlaggedContentCard extends StatelessWidget {
  final FlaggedContent content;
  final VoidCallback onDelete;
  final VoidCallback onApprove;

  const _FlaggedContentCard({
    required this.content,
    required this.onDelete,
    required this.onApprove,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    IconData icon;
    String typeLabel;

    switch (content.contentType) {
      case ContentType.photo:
        icon = Icons.photo;
        typeLabel = l10n.poiPhotos;
        break;
      case ContentType.review:
        icon = Icons.star;
        typeLabel = l10n.poiReviews;
        break;
      case ContentType.comment:
        icon = Icons.comment;
        typeLabel = l10n.poiComments;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: colorScheme.error),
                const SizedBox(width: 8),
                Text(
                  typeLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.error,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.flag,
                  size: 16,
                  color: colorScheme.error,
                ),
              ],
            ),
            if (content.userName != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 16,
                    color: colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    content.userName!,
                    style: TextStyle(color: colorScheme.outline),
                  ),
                ],
              ),
            ],
            if (content.contentPreview != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  content.contentPreview!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.check),
                  label: Text(l10n.adminApprove),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: onDelete,
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.error,
                  ),
                  icon: const Icon(Icons.delete_outline),
                  label: Text(l10n.adminDelete),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
