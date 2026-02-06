import 'package:freezed_annotation/freezed_annotation.dart';

part 'admin_notification.freezed.dart';
part 'admin_notification.g.dart';

/// Typ der Admin-Benachrichtigung
enum AdminNotificationType {
  newPhoto,
  newReview,
  newComment,
  flaggedContent;

  String toJson() {
    switch (this) {
      case AdminNotificationType.newPhoto:
        return 'new_photo';
      case AdminNotificationType.newReview:
        return 'new_review';
      case AdminNotificationType.newComment:
        return 'new_comment';
      case AdminNotificationType.flaggedContent:
        return 'flagged_content';
    }
  }

  static AdminNotificationType fromJson(String json) {
    switch (json) {
      case 'new_photo':
        return AdminNotificationType.newPhoto;
      case 'new_review':
        return AdminNotificationType.newReview;
      case 'new_comment':
        return AdminNotificationType.newComment;
      case 'flagged_content':
        return AdminNotificationType.flaggedContent;
      default:
        return AdminNotificationType.newComment;
    }
  }
}

/// Inhaltstyp fuer Moderation
enum ContentType {
  photo,
  review,
  comment;

  String toJson() => name;

  static ContentType fromJson(String json) {
    switch (json.toLowerCase()) {
      case 'photo':
        return ContentType.photo;
      case 'review':
        return ContentType.review;
      case 'comment':
        return ContentType.comment;
      default:
        return ContentType.comment;
    }
  }
}

/// Admin-Benachrichtigung fuer neue Inhalte oder gemeldete Inhalte
@freezed
class AdminNotification with _$AdminNotification {
  const AdminNotification._();

  const factory AdminNotification({
    required String id,
    required AdminNotificationType type,
    required ContentType contentType,
    required String contentId,
    String? userId,
    String? poiId,
    String? targetId,
    String? message,
    @Default(false) bool isRead,
    required DateTime createdAt,
    // Joined data from user_profiles
    String? userName,
    String? userAvatar,
  }) = _AdminNotification;

  factory AdminNotification.fromJson(Map<String, dynamic> json) =>
      _$AdminNotificationFromJson(_convertKeys(json));

  /// Konvertiert snake_case Keys zu camelCase
  static Map<String, dynamic> _convertKeys(Map<String, dynamic> json) {
    return {
      'id': json['id'],
      'type': json['type'],
      'contentType': json['content_type'] ?? json['contentType'],
      'contentId': json['content_id'] ?? json['contentId'],
      'userId': json['user_id'] ?? json['userId'],
      'poiId': json['poi_id'] ?? json['poiId'],
      'targetId': json['target_id'] ?? json['targetId'],
      'message': json['message'],
      'isRead': json['is_read'] ?? json['isRead'] ?? false,
      'createdAt': json['created_at'] ?? json['createdAt'],
      'userName': json['user_name'] ?? json['userName'],
      'userAvatar': json['user_avatar'] ?? json['userAvatar'],
    };
  }

  /// Icon fuer den Benachrichtigungstyp
  String get iconName {
    switch (type) {
      case AdminNotificationType.newPhoto:
        return 'photo_camera';
      case AdminNotificationType.newReview:
        return 'star';
      case AdminNotificationType.newComment:
        return 'comment';
      case AdminNotificationType.flaggedContent:
        return 'flag';
    }
  }

  /// Titel fuer die Benachrichtigung
  String get title {
    switch (type) {
      case AdminNotificationType.newPhoto:
        return 'Neues Foto';
      case AdminNotificationType.newReview:
        return 'Neue Bewertung';
      case AdminNotificationType.newComment:
        return 'Neuer Kommentar';
      case AdminNotificationType.flaggedContent:
        return 'Gemeldeter Inhalt';
    }
  }

  /// Ist dies eine kritische Benachrichtigung (gemeldet)?
  bool get isCritical => type == AdminNotificationType.flaggedContent;

  /// Zeit seit Erstellung
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return 'vor ${difference.inDays} ${difference.inDays == 1 ? 'Tag' : 'Tagen'}';
    } else if (difference.inHours > 0) {
      return 'vor ${difference.inHours} ${difference.inHours == 1 ? 'Stunde' : 'Stunden'}';
    } else if (difference.inMinutes > 0) {
      return 'vor ${difference.inMinutes} Min';
    } else {
      return 'gerade eben';
    }
  }
}

/// Gemeldeter Inhalt fuer Admin-Moderation
@freezed
class FlaggedContent with _$FlaggedContent {
  const FlaggedContent._();

  const factory FlaggedContent({
    required ContentType contentType,
    required String contentId,
    String? poiId,
    String? userId,
    String? userName,
    String? contentPreview,
    required DateTime createdAt,
  }) = _FlaggedContent;

  factory FlaggedContent.fromJson(Map<String, dynamic> json) =>
      _$FlaggedContentFromJson(_convertKeys(json));

  /// Konvertiert snake_case Keys zu camelCase
  static Map<String, dynamic> _convertKeys(Map<String, dynamic> json) {
    return {
      'contentType': json['content_type'] ?? json['contentType'],
      'contentId': json['content_id'] ?? json['contentId'],
      'poiId': json['poi_id'] ?? json['poiId'],
      'userId': json['user_id'] ?? json['userId'],
      'userName': json['user_name'] ?? json['userName'],
      'contentPreview': json['content_preview'] ?? json['contentPreview'],
      'createdAt': json['created_at'] ?? json['createdAt'],
    };
  }
}
