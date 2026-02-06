import 'package:freezed_annotation/freezed_annotation.dart';

part 'trip_photo.freezed.dart';
part 'trip_photo.g.dart';

/// Benutzer-hochgeladenes Foto fuer einen Trip
@freezed
class TripPhoto with _$TripPhoto {
  const TripPhoto._();

  const factory TripPhoto({
    required String id,
    required String tripId,
    required String userId,
    required String storagePath,
    String? thumbnailPath,
    String? caption,
    @Default(0) int displayOrder,
    @Default(0) int likesCount,
    @Default(false) bool isFlagged,
    required DateTime createdAt,
    // Joined data from user_profiles
    String? authorName,
    String? authorAvatar,
  }) = _TripPhoto;

  factory TripPhoto.fromJson(Map<String, dynamic> json) =>
      _$TripPhotoFromJson(_convertKeys(json));

  /// Konvertiert snake_case Keys zu camelCase
  static Map<String, dynamic> _convertKeys(Map<String, dynamic> json) {
    return {
      'id': json['id'],
      'tripId': json['trip_id'] ?? json['tripId'],
      'userId': json['user_id'] ?? json['userId'],
      'storagePath': json['storage_path'] ?? json['storagePath'],
      'thumbnailPath': json['thumbnail_path'] ?? json['thumbnailPath'],
      'caption': json['caption'],
      'displayOrder': json['display_order'] ?? json['displayOrder'] ?? 0,
      'likesCount': json['likes_count'] ?? json['likesCount'] ?? 0,
      'isFlagged': json['is_flagged'] ?? json['isFlagged'] ?? false,
      'createdAt': json['created_at'] ?? json['createdAt'],
      'authorName': json['author_name'] ?? json['authorName'],
      'authorAvatar': json['author_avatar'] ?? json['authorAvatar'],
    };
  }

  /// Vollstaendige Storage URL fuer das Bild
  String imageUrl(String supabaseUrl) =>
      '$supabaseUrl/storage/v1/object/public/trip-photos/$storagePath';

  /// Thumbnail URL (falls vorhanden)
  String? thumbnailUrl(String supabaseUrl) => thumbnailPath != null
      ? '$supabaseUrl/storage/v1/object/public/trip-photos/$thumbnailPath'
      : null;

  /// Prueft ob das Foto vom aktuellen Benutzer ist
  bool isOwnedBy(String? currentUserId) => userId == currentUserId;
}
