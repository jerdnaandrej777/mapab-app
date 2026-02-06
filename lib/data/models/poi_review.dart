import 'package:freezed_annotation/freezed_annotation.dart';

part 'poi_review.freezed.dart';
part 'poi_review.g.dart';

/// Benutzer-Bewertung fuer einen POI (1-5 Sterne + optionaler Text)
@freezed
class POIReview with _$POIReview {
  const POIReview._();

  const factory POIReview({
    required String id,
    required String poiId,
    required String userId,
    required int rating,
    String? reviewText,
    DateTime? visitDate,
    @Default(0) int helpfulCount,
    @Default(false) bool isHelpfulByMe,
    @Default(false) bool isFlagged,
    required DateTime createdAt,
    DateTime? updatedAt,
    // Joined data from user_profiles
    String? authorName,
    String? authorAvatar,
  }) = _POIReview;

  factory POIReview.fromJson(Map<String, dynamic> json) =>
      _$POIReviewFromJson(_convertKeys(json));

  /// Konvertiert snake_case Keys zu camelCase
  static Map<String, dynamic> _convertKeys(Map<String, dynamic> json) {
    return {
      'id': json['id'],
      'poiId': json['poi_id'] ?? json['poiId'],
      'userId': json['user_id'] ?? json['userId'],
      'rating': json['rating'],
      'reviewText': json['review_text'] ?? json['reviewText'],
      'visitDate': json['visit_date'] ?? json['visitDate'],
      'helpfulCount': json['helpful_count'] ?? json['helpfulCount'] ?? 0,
      'isHelpfulByMe':
          json['is_helpful_by_me'] ?? json['isHelpfulByMe'] ?? false,
      'isFlagged': json['is_flagged'] ?? json['isFlagged'] ?? false,
      'createdAt': json['created_at'] ?? json['createdAt'],
      'updatedAt': json['updated_at'] ?? json['updatedAt'],
      'authorName': json['author_name'] ?? json['authorName'],
      'authorAvatar': json['author_avatar'] ?? json['authorAvatar'],
    };
  }

  /// Hat die Bewertung einen Text?
  bool get hasReviewText => reviewText != null && reviewText!.isNotEmpty;

  /// Prueft ob die Bewertung vom aktuellen Benutzer ist
  bool isOwnedBy(String? currentUserId) => userId == currentUserId;

  /// Formatiertes Datum fuer Anzeige
  String? get formattedVisitDate {
    if (visitDate == null) return null;
    return '${visitDate!.day}.${visitDate!.month}.${visitDate!.year}';
  }
}

/// Aggregierte Statistiken fuer einen POI
@freezed
class POIStats with _$POIStats {
  const POIStats._();

  const factory POIStats({
    required String poiId,
    @Default(0.0) double avgRating,
    @Default(0) int reviewCount,
    @Default(0) int photoCount,
    @Default(0) int commentCount,
    // Eigene Bewertung des aktuellen Benutzers (falls vorhanden)
    int? myRating,
    String? myReviewText,
    String? myReviewId,
  }) = _POIStats;

  factory POIStats.fromJson(Map<String, dynamic> json) =>
      _$POIStatsFromJson(_convertKeys(json));

  /// Konvertiert snake_case Keys zu camelCase
  static Map<String, dynamic> _convertKeys(Map<String, dynamic> json) {
    return {
      'poiId': json['poi_id'] ?? json['poiId'] ?? '',
      'avgRating':
          (json['avg_rating'] ?? json['avgRating'] ?? 0).toDouble(),
      'reviewCount': json['review_count'] ?? json['reviewCount'] ?? 0,
      'photoCount': json['photo_count'] ?? json['photoCount'] ?? 0,
      'commentCount': json['comment_count'] ?? json['commentCount'] ?? 0,
      'myRating': json['my_rating'] ?? json['myRating'],
      'myReviewText': json['my_review_text'] ?? json['myReviewText'],
      'myReviewId': json['my_review_id'] ?? json['myReviewId'],
    };
  }

  /// Hat Bewertungen?
  bool get hasReviews => reviewCount > 0;

  /// Hat Fotos?
  bool get hasPhotos => photoCount > 0;

  /// Hat Kommentare?
  bool get hasComments => commentCount > 0;

  /// Hat der aktuelle Benutzer bereits bewertet?
  bool get hasMyRating => myRating != null;

  /// Gerundete Durchschnittsbewertung (z.B. 4.5)
  double get roundedRating => (avgRating * 2).round() / 2;

  /// Leere Statistiken (fuer neue POIs)
  static POIStats empty(String poiId) => POIStats(poiId: poiId);
}
