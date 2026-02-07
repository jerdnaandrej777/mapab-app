class PublicPoiPost {
  final String id;
  final String poiId;
  final String userId;
  final String title;
  final String? content;
  final List<String> categories;
  final bool isMustSee;
  final double? ratingAvg;
  final int ratingCount;
  final int voteScore;
  final int likesCount;
  final int commentCount;
  final int photoCount;
  final String? coverPhotoPath;
  final String? authorName;
  final String? authorAvatar;
  final bool isLikedByMe;
  final DateTime createdAt;

  const PublicPoiPost({
    required this.id,
    required this.poiId,
    required this.userId,
    required this.title,
    this.content,
    this.categories = const [],
    this.isMustSee = false,
    this.ratingAvg,
    this.ratingCount = 0,
    this.voteScore = 0,
    this.likesCount = 0,
    this.commentCount = 0,
    this.photoCount = 0,
    this.coverPhotoPath,
    this.authorName,
    this.authorAvatar,
    this.isLikedByMe = false,
    required this.createdAt,
  });

  factory PublicPoiPost.fromJson(Map<String, dynamic> json) {
    return PublicPoiPost(
      id: json['id'] as String,
      poiId: (json['poi_id'] ?? json['poiId']) as String,
      userId: (json['user_id'] ?? json['userId']) as String,
      title: (json['title'] ?? json['poi_name'] ?? 'POI') as String,
      content: (json['content'] ?? json['description']) as String?,
      categories: ((json['categories'] ?? json['tags']) as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      isMustSee: (json['is_must_see'] ?? json['isMustSee']) as bool? ?? false,
      ratingAvg: (json['rating_avg'] as num?)?.toDouble(),
      ratingCount: (json['rating_count'] ?? json['review_count']) as int? ?? 0,
      voteScore: (json['vote_score'] ?? json['votes']) as int? ?? 0,
      likesCount: (json['likes_count'] ?? json['likes']) as int? ?? 0,
      commentCount: (json['comment_count'] ?? json['comments']) as int? ?? 0,
      photoCount: (json['photo_count'] ?? json['photos']) as int? ?? 0,
      coverPhotoPath:
          (json['cover_photo_path'] ?? json['coverPhotoPath']) as String?,
      authorName: (json['author_name'] ?? json['display_name']) as String?,
      authorAvatar: (json['author_avatar'] ?? json['avatar_url']) as String?,
      isLikedByMe:
          (json['is_liked_by_me'] ?? json['isLikedByMe']) as bool? ?? false,
      createdAt: DateTime.parse(
        (json['created_at'] ?? json['createdAt']) as String,
      ),
    );
  }
}
