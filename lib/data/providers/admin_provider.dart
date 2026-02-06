import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/admin_notification.dart';
import '../repositories/admin_repo.dart';

part 'admin_provider.g.dart';

// ============================================
// ADMIN STATE
// ============================================

/// State fuer Admin-Dashboard
class AdminState {
  final bool isAdmin;
  final String? adminRole;
  final List<AdminNotification> notifications;
  final List<FlaggedContent> flaggedContent;
  final Map<String, int> stats;
  final bool isLoading;
  final String? error;

  const AdminState({
    this.isAdmin = false,
    this.adminRole,
    this.notifications = const [],
    this.flaggedContent = const [],
    this.stats = const {},
    this.isLoading = false,
    this.error,
  });

  AdminState copyWith({
    bool? isAdmin,
    String? adminRole,
    List<AdminNotification>? notifications,
    List<FlaggedContent>? flaggedContent,
    Map<String, int>? stats,
    bool? isLoading,
    String? error,
  }) =>
      AdminState(
        isAdmin: isAdmin ?? this.isAdmin,
        adminRole: adminRole ?? this.adminRole,
        notifications: notifications ?? this.notifications,
        flaggedContent: flaggedContent ?? this.flaggedContent,
        stats: stats ?? this.stats,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );

  /// Anzahl ungelesener Benachrichtigungen
  int get unreadCount => notifications.where((n) => !n.isRead).length;

  /// Anzahl gemeldeter Inhalte
  int get flaggedCount => flaggedContent.length;

  /// Ist Super-Admin?
  bool get isSuperAdmin => adminRole == 'super_admin';

  /// Ist mindestens Admin?
  bool get isFullAdmin => adminRole == 'admin' || adminRole == 'super_admin';
}

// ============================================
// ADMIN NOTIFIER
// ============================================

/// Provider fuer Admin-Funktionen
@Riverpod(keepAlive: true)
class AdminNotifier extends _$AdminNotifier {
  @override
  AdminState build() {
    return const AdminState();
  }

  /// Initialisiert Admin-Status
  Future<void> initialize() async {
    debugPrint('[AdminProvider] Initializing...');

    try {
      final repo = ref.read(adminRepositoryProvider);
      final isAdmin = await repo.isAdmin();

      if (isAdmin) {
        final role = await repo.getAdminRole();
        state = state.copyWith(isAdmin: true, adminRole: role);
        debugPrint('[AdminProvider] User is admin with role: $role');
      } else {
        state = state.copyWith(isAdmin: false, adminRole: null);
        debugPrint('[AdminProvider] User is not an admin');
      }
    } catch (e) {
      debugPrint('[AdminProvider] Initialize error: $e');
      state = state.copyWith(isAdmin: false, adminRole: null);
    }
  }

  /// Laedt Dashboard-Daten
  Future<void> loadDashboard() async {
    if (!state.isAdmin || state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final repo = ref.read(adminRepositoryProvider);

      final results = await Future.wait([
        repo.getNotifications(unreadOnly: false, limit: 50),
        repo.getFlaggedContent(limit: 50),
        repo.getDashboardStats(),
      ]);

      state = state.copyWith(
        isLoading: false,
        notifications: results[0] as List<AdminNotification>,
        flaggedContent: results[1] as List<FlaggedContent>,
        stats: results[2] as Map<String, int>,
      );
    } catch (e) {
      debugPrint('[AdminProvider] loadDashboard error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Laedt nur Benachrichtigungen
  Future<void> loadNotifications({bool unreadOnly = false}) async {
    if (!state.isAdmin) return;

    try {
      final repo = ref.read(adminRepositoryProvider);
      final notifications = await repo.getNotifications(unreadOnly: unreadOnly);
      state = state.copyWith(notifications: notifications);
    } catch (e) {
      debugPrint('[AdminProvider] loadNotifications error: $e');
    }
  }

  /// Laedt nur gemeldete Inhalte
  Future<void> loadFlaggedContent({String? contentType}) async {
    if (!state.isAdmin) return;

    try {
      final repo = ref.read(adminRepositoryProvider);
      final content = await repo.getFlaggedContent(contentType: contentType);
      state = state.copyWith(flaggedContent: content);
    } catch (e) {
      debugPrint('[AdminProvider] loadFlaggedContent error: $e');
    }
  }

  /// Markiert eine Benachrichtigung als gelesen
  Future<void> markNotificationRead(String notificationId) async {
    if (!state.isAdmin) return;

    try {
      final repo = ref.read(adminRepositoryProvider);
      final success = await repo.markNotificationRead(notificationId);

      if (success) {
        // Optimistic update
        final updated = state.notifications.map((n) {
          if (n.id == notificationId) {
            return n.copyWith(isRead: true);
          }
          return n;
        }).toList();
        state = state.copyWith(notifications: updated);
      }
    } catch (e) {
      debugPrint('[AdminProvider] markNotificationRead error: $e');
    }
  }

  /// Markiert alle Benachrichtigungen als gelesen
  Future<void> markAllNotificationsRead() async {
    if (!state.isAdmin) return;

    try {
      final repo = ref.read(adminRepositoryProvider);
      await repo.markAllNotificationsRead();

      // Optimistic update
      final updated = state.notifications.map((n) => n.copyWith(isRead: true)).toList();
      state = state.copyWith(notifications: updated);
    } catch (e) {
      debugPrint('[AdminProvider] markAllNotificationsRead error: $e');
    }
  }

  /// Loescht Inhalt
  Future<bool> deleteContent({
    required String contentType,
    required String contentId,
  }) async {
    if (!state.isAdmin) return false;

    try {
      final repo = ref.read(adminRepositoryProvider);
      final success = await repo.deleteContent(
        contentType: contentType,
        contentId: contentId,
      );

      if (success) {
        // Aus lokaler Liste entfernen
        final updatedFlagged = state.flaggedContent
            .where((c) => c.contentId != contentId)
            .toList();
        final updatedNotifications = state.notifications
            .where((n) => n.contentId != contentId)
            .toList();

        state = state.copyWith(
          flaggedContent: updatedFlagged,
          notifications: updatedNotifications,
        );
      }
      return success;
    } catch (e) {
      debugPrint('[AdminProvider] deleteContent error: $e');
      return false;
    }
  }

  /// Genehmigt gemeldeten Inhalt (entfernt Flag)
  Future<bool> approveContent({
    required String contentType,
    required String contentId,
  }) async {
    if (!state.isAdmin) return false;

    try {
      final repo = ref.read(adminRepositoryProvider);
      final success = await repo.approveContent(
        contentType: contentType,
        contentId: contentId,
      );

      if (success) {
        // Aus lokaler Liste entfernen
        final updated = state.flaggedContent
            .where((c) => c.contentId != contentId)
            .toList();
        state = state.copyWith(flaggedContent: updated);
      }
      return success;
    } catch (e) {
      debugPrint('[AdminProvider] approveContent error: $e');
      return false;
    }
  }

  /// Aktualisiert Statistiken
  Future<void> refreshStats() async {
    if (!state.isAdmin) return;

    try {
      final repo = ref.read(adminRepositoryProvider);
      final stats = await repo.getDashboardStats();
      state = state.copyWith(stats: stats);
    } catch (e) {
      debugPrint('[AdminProvider] refreshStats error: $e');
    }
  }

  /// Setzt Admin-Status zurueck (z.B. bei Logout)
  void reset() {
    state = const AdminState();
  }
}

// ============================================
// SIMPLE PROVIDERS
// ============================================

/// Provider zum Pruefen ob aktueller User Admin ist (cached)
@Riverpod(keepAlive: true)
Future<bool> isCurrentUserAdmin(IsCurrentUserAdminRef ref) async {
  final repo = ref.read(adminRepositoryProvider);
  return await repo.isAdmin();
}

/// Provider fuer Anzahl ungelesener Benachrichtigungen
@riverpod
Future<int> adminUnreadCount(AdminUnreadCountRef ref) async {
  final adminState = ref.watch(adminNotifierProvider);
  if (!adminState.isAdmin) return 0;

  final repo = ref.read(adminRepositoryProvider);
  return await repo.getUnreadCount();
}
