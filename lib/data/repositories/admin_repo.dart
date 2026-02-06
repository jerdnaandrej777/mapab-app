import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/admin_notification.dart';

part 'admin_repo.g.dart';

/// Repository fuer Admin-Funktionen (Moderation, Benachrichtigungen)
class AdminRepository {
  final SupabaseClient _client;

  AdminRepository(this._client);

  String? get _currentUserId => _client.auth.currentUser?.id;

  // ============================================
  // ADMIN CHECK
  // ============================================

  /// Prueft ob der aktuelle Benutzer ein Admin ist
  Future<bool> isAdmin() async {
    if (_currentUserId == null) return false;

    try {
      final response = await _client.rpc('is_admin');
      return response as bool? ?? false;
    } catch (e) {
      debugPrint('[Admin] isAdmin check error: $e');
      return false;
    }
  }

  /// Laedt die Admin-Rolle des aktuellen Benutzers
  Future<String?> getAdminRole() async {
    if (_currentUserId == null) return null;

    try {
      final response = await _client
          .from('admins')
          .select('role')
          .eq('user_id', _currentUserId!)
          .maybeSingle();

      return response?['role'] as String?;
    } catch (e) {
      debugPrint('[Admin] getAdminRole error: $e');
      return null;
    }
  }

  // ============================================
  // NOTIFICATIONS
  // ============================================

  /// Laedt Admin-Benachrichtigungen
  Future<List<AdminNotification>> getNotifications({
    bool unreadOnly = false,
    int limit = 50,
    int offset = 0,
  }) async {
    debugPrint('[Admin] Loading notifications (unreadOnly: $unreadOnly)');

    try {
      final response = await _client.rpc('admin_get_notifications', params: {
        'p_unread_only': unreadOnly,
        'p_limit': limit,
        'p_offset': offset,
      });

      final notifications = (response as List)
          .map((row) => AdminNotification.fromJson(row as Map<String, dynamic>))
          .toList();

      debugPrint('[Admin] Loaded ${notifications.length} notifications');
      return notifications;
    } catch (e) {
      debugPrint('[Admin] getNotifications error: $e');
      return [];
    }
  }

  /// Zaehlt ungelesene Benachrichtigungen
  Future<int> getUnreadCount() async {
    try {
      final response = await _client
          .from('admin_notifications')
          .select('id')
          .eq('is_read', false);

      return (response as List).length;
    } catch (e) {
      debugPrint('[Admin] getUnreadCount error: $e');
      return 0;
    }
  }

  /// Markiert eine Benachrichtigung als gelesen
  Future<bool> markNotificationRead(String notificationId) async {
    debugPrint('[Admin] Marking notification as read: $notificationId');

    try {
      final response = await _client.rpc('admin_mark_notification_read', params: {
        'p_notification_id': notificationId,
      });

      return response as bool? ?? false;
    } catch (e) {
      debugPrint('[Admin] markNotificationRead error: $e');
      return false;
    }
  }

  /// Markiert alle Benachrichtigungen als gelesen
  Future<int> markAllNotificationsRead() async {
    debugPrint('[Admin] Marking all notifications as read');

    try {
      final response = await _client.rpc('admin_mark_all_notifications_read');
      final count = response as int? ?? 0;
      debugPrint('[Admin] Marked $count notifications as read');
      return count;
    } catch (e) {
      debugPrint('[Admin] markAllNotificationsRead error: $e');
      return 0;
    }
  }

  // ============================================
  // CONTENT MODERATION
  // ============================================

  /// Laedt gemeldete Inhalte
  Future<List<FlaggedContent>> getFlaggedContent({
    String? contentType, // 'photo', 'review', 'comment' oder null fuer alle
    int limit = 50,
    int offset = 0,
  }) async {
    debugPrint('[Admin] Loading flagged content (type: $contentType)');

    try {
      final response = await _client.rpc('admin_get_flagged_content', params: {
        'p_content_type': contentType,
        'p_limit': limit,
        'p_offset': offset,
      });

      final content = (response as List)
          .map((row) => FlaggedContent.fromJson(row as Map<String, dynamic>))
          .toList();

      debugPrint('[Admin] Loaded ${content.length} flagged items');
      return content;
    } catch (e) {
      debugPrint('[Admin] getFlaggedContent error: $e');
      return [];
    }
  }

  /// Loescht Inhalt (Admin-only)
  Future<bool> deleteContent({
    required String contentType, // 'photo', 'review', 'comment'
    required String contentId,
  }) async {
    debugPrint('[Admin] Deleting $contentType: $contentId');

    try {
      final response = await _client.rpc('admin_delete_content', params: {
        'p_content_type': contentType,
        'p_content_id': contentId,
      });

      final success = response as bool? ?? false;
      if (success) {
        debugPrint('[Admin] Content deleted successfully');
      }
      return success;
    } catch (e) {
      debugPrint('[Admin] deleteContent error: $e');
      return false;
    }
  }

  /// Entfernt Flagging von Inhalt (approve)
  Future<bool> approveContent({
    required String contentType, // 'photo', 'review', 'comment'
    required String contentId,
  }) async {
    debugPrint('[Admin] Approving $contentType: $contentId');

    try {
      String table;
      switch (contentType) {
        case 'photo':
          table = 'poi_photos';
          break;
        case 'review':
          table = 'poi_reviews';
          break;
        case 'comment':
          table = 'comments';
          break;
        default:
          return false;
      }

      await _client
          .from(table)
          .update({'is_flagged': false})
          .eq('id', contentId);

      debugPrint('[Admin] Content approved');
      return true;
    } catch (e) {
      debugPrint('[Admin] approveContent error: $e');
      return false;
    }
  }

  // ============================================
  // STATISTICS
  // ============================================

  /// Laedt Admin-Dashboard-Statistiken
  Future<Map<String, int>> getDashboardStats() async {
    debugPrint('[Admin] Loading dashboard stats');

    try {
      final results = await Future.wait([
        _client.from('admin_notifications').select('id').eq('is_read', false),
        _client.from('poi_photos').select('id').eq('is_flagged', true),
        _client.from('poi_reviews').select('id').eq('is_flagged', true),
        _client.from('comments').select('id').eq('is_flagged', true),
        _client.from('poi_photos').select('id'),
        _client.from('poi_reviews').select('id'),
        _client.from('comments').select('id'),
      ]);

      return {
        'unreadNotifications': (results[0] as List).length,
        'flaggedPhotos': (results[1] as List).length,
        'flaggedReviews': (results[2] as List).length,
        'flaggedComments': (results[3] as List).length,
        'totalPhotos': (results[4] as List).length,
        'totalReviews': (results[5] as List).length,
        'totalComments': (results[6] as List).length,
      };
    } catch (e) {
      debugPrint('[Admin] getDashboardStats error: $e');
      return {
        'unreadNotifications': 0,
        'flaggedPhotos': 0,
        'flaggedReviews': 0,
        'flaggedComments': 0,
        'totalPhotos': 0,
        'totalReviews': 0,
        'totalComments': 0,
      };
    }
  }
}

@riverpod
AdminRepository adminRepository(AdminRepositoryRef ref) {
  return AdminRepository(Supabase.instance.client);
}
