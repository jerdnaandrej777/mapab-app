import 'package:freezed_annotation/freezed_annotation.dart';

part 'poi_photo.freezed.dart';
part 'poi_photo.g.dart';

/// Benutzer-hochgeladenes Foto fuer einen POI
@freezed
class POIPhoto with _$POIPhoto {
  const POIPhoto._();

  const factory POIPhoto({
    required String id,
    required String poiId,
    required String userId,
    required String storagePath,
    String? thumbnailPath,
    String? caption,
    @Default(0) int likesCount,
    @Default(false) bool isFlagged,
    required DateTime createdAt,
    // Joined data from user_profiles
    String? authorName,
    String? authorAvatar,
  }) = _POIPhoto;

  factory POIPhoto.fromJson(Map<String, dynamic> json) =>
      _$POIPhotoFromJson(_convertKeys(json));

  /// Konvertiert snake_case Keys zu camelCase
  static Map<String, dynamic> _convertKeys(Map<String, dynamic> json) {
    return {
      'id': json['id'],
      'poiId': json['poi_id'] ?? json['poiId'],
      'userId': json['user_id'] ?? json['userId'],
      'storagePath': json['storage_path'] ?? json['storagePath'],
      'thumbnailPath': json['thumbnail_path'] ?? json['thumbnailPath'],
      'caption': json['caption'],
      'likesCount': json['likes_count'] ?? json['likesCount'] ?? 0,
      'isFlagged': json['is_flagged'] ?? json['isFlagged'] ?? false,
      'createdAt': json['created_at'] ?? json['createdAt'],
      'authorName': json['author_name'] ?? json['authorName'],
      'authorAvatar': json['author_avatar'] ?? json['authorAvatar'],
    };
  }

  /// Vollstaendige Storage URL fuer das Bild
  /// WICHTIG: Ersetze [PROJECT_REF] mit deiner Supabase Project Reference
  String imageUrl(String supabaseUrl) =>
      '$supabaseUrl/storage/v1/object/public/poi-photos/$storagePath';

  /// Thumbnail URL (falls vorhanden)
  String? thumbnailUrl(String supabaseUrl) => thumbnailPath != null
      ? '$supabaseUrl/storage/v1/object/public/poi-photos/$thumbnailPath'
      : null;

  /// Prueft ob das Foto vom aktuellen Benutzer ist
  bool isOwnedBy(String? currentUserId) => userId == currentUserId;
}
