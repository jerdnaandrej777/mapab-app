import 'package:freezed_annotation/freezed_annotation.dart';

part 'comment.freezed.dart';
part 'comment.g.dart';

/// Zieltyp fuer Kommentare
enum CommentTargetType {
  poi,
  trip;

  String toJson() => name;

  static CommentTargetType fromJson(String json) {
    switch (json.toLowerCase()) {
      case 'poi':
        return CommentTargetType.poi;
      case 'trip':
        return CommentTargetType.trip;
      default:
        return CommentTargetType.poi;
    }
  }
}

/// Kommentar zu einem POI oder Trip
@freezed
class Comment with _$Comment {
  const Comment._();

  const factory Comment({
    required String id,
    required String userId,
    required CommentTargetType targetType,
    required String targetId,
    String? parentId,
    required String content,
    @Default(0) int likesCount,
    @Default(false) bool isFlagged,
    required DateTime createdAt,
    DateTime? updatedAt,
    // Joined data from user_profiles
    String? authorName,
    String? authorAvatar,
    // Antworten (lazy loaded)
    @Default([]) List<Comment> replies,
    // Anzahl der Antworten (aus DB)
    @Default(0) int replyCount,
  }) = _Comment;

  factory Comment.fromJson(Map<String, dynamic> json) =>
      _$CommentFromJson(_convertKeys(json));

  /// Konvertiert snake_case Keys zu camelCase
  static Map<String, dynamic> _convertKeys(Map<String, dynamic> json) {
    return {
      'id': json['id'],
      'userId': json['user_id'] ?? json['userId'],
      'targetType': json['target_type'] ?? json['targetType'] ?? 'poi',
      'targetId': json['target_id'] ?? json['targetId'],
      'parentId': json['parent_id'] ?? json['parentId'],
      'content': json['content'],
      'likesCount': json['likes_count'] ?? json['likesCount'] ?? 0,
      'isFlagged': json['is_flagged'] ?? json['isFlagged'] ?? false,
      'createdAt': json['created_at'] ?? json['createdAt'],
      'updatedAt': json['updated_at'] ?? json['updatedAt'],
      'authorName': json['author_name'] ?? json['authorName'],
      'authorAvatar': json['author_avatar'] ?? json['authorAvatar'],
      'replies': json['replies'] ?? [],
      'replyCount': json['reply_count'] ?? json['replyCount'] ?? 0,
    };
  }

  /// Ist dies eine Antwort auf einen anderen Kommentar?
  bool get isReply => parentId != null;

  /// Hat dieser Kommentar Antworten?
  bool get hasReplies => replyCount > 0 || replies.isNotEmpty;

  /// Prueft ob der Kommentar vom aktuellen Benutzer ist
  bool isOwnedBy(String? currentUserId) => userId == currentUserId;

  /// Formatierte Zeit seit Erstellung (z.B. "vor 2 Stunden")
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return 'vor $years ${years == 1 ? 'Jahr' : 'Jahren'}';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return 'vor $months ${months == 1 ? 'Monat' : 'Monaten'}';
    } else if (difference.inDays > 0) {
      return 'vor ${difference.inDays} ${difference.inDays == 1 ? 'Tag' : 'Tagen'}';
    } else if (difference.inHours > 0) {
      return 'vor ${difference.inHours} ${difference.inHours == 1 ? 'Stunde' : 'Stunden'}';
    } else if (difference.inMinutes > 0) {
      return 'vor ${difference.inMinutes} ${difference.inMinutes == 1 ? 'Minute' : 'Minuten'}';
    } else {
      return 'gerade eben';
    }
  }

  /// Gekuerzter Content fuer Vorschau (max 100 Zeichen)
  String get preview {
    if (content.length <= 100) return content;
    return '${content.substring(0, 97)}...';
  }
}
