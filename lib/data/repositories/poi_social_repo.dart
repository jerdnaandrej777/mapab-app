import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/supabase/supabase_config.dart';
import '../../core/supabase/supabase_client.dart' show isSupabaseAvailable;
import '../models/comment.dart';
import '../models/poi_photo.dart';
import '../models/poi_review.dart';

part 'poi_social_repo.g.dart';

/// Repository fuer POI Social Features (Fotos, Bewertungen, Kommentare)
class POISocialRepository {
  final SupabaseClient _client;
  static const _bucketName = 'poi-photos';
  static const _maxImageSize = 1920;
  static const _imageQuality = 85;

  POISocialRepository(this._client);

  String? get _currentUserId => _client.auth.currentUser?.id;

  // ============================================
  // PHOTOS
  // ============================================

  /// Laedt alle Fotos fuer einen POI
  Future<List<POIPhoto>> loadPhotos(String poiId,
      {int limit = 20, int offset = 0}) async {
    debugPrint('[POISocial] Loading photos for POI: $poiId');

    final response = await _client.rpc('get_poi_photos', params: {
      'p_poi_id': poiId,
      'p_limit': limit,
      'p_offset': offset,
    });

    final photos = (response as List)
        .map((row) => POIPhoto.fromJson(row as Map<String, dynamic>))
        .toList();

    debugPrint('[POISocial] Loaded ${photos.length} photos');
    return photos;
  }

  /// Laedt ein Foto hoch
  Future<POIPhoto?> uploadPhoto({
    required String poiId,
    required XFile imageFile,
    String? caption,
  }) async {
    if (_currentUserId == null) {
      throw Exception('Not authenticated');
    }

    debugPrint('[POISocial] Uploading photo for POI: $poiId');

    try {
      // Bild komprimieren
      final bytes = await _compressImage(imageFile);

      // Unique path generieren
      final fileId = const Uuid().v4();
      final storagePath = '$_currentUserId/$poiId/$fileId.jpg';

      // Upload zu Supabase Storage
      await _client.storage.from(_bucketName).uploadBinary(
            storagePath,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: false,
            ),
          );

      debugPrint('[POISocial] Uploaded to storage: $storagePath');

      // Metadaten in DB speichern via RPC
      final response = await _client.rpc('register_poi_photo', params: {
        'p_poi_id': poiId,
        'p_storage_path': storagePath,
        'p_thumbnail_path': null, // Thumbnail optional
        'p_caption': caption,
      });

      debugPrint('[POISocial] Photo registered in DB');
      return POIPhoto.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[POISocial] Photo upload error: $e');
      rethrow;
    }
  }

  /// Komprimiert ein Bild auf max 1920px und 85% Qualitaet
  Future<Uint8List> _compressImage(XFile imageFile) async {
    final originalBytes = await imageFile.readAsBytes();

    // Decode image
    final image = img.decodeImage(originalBytes);
    if (image == null) {
      throw Exception('Could not decode image');
    }

    // Resize if necessary
    img.Image resized;
    if (image.width > _maxImageSize || image.height > _maxImageSize) {
      if (image.width > image.height) {
        resized = img.copyResize(image, width: _maxImageSize);
      } else {
        resized = img.copyResize(image, height: _maxImageSize);
      }
    } else {
      resized = image;
    }

    // Encode as JPEG
    return Uint8List.fromList(img.encodeJpg(resized, quality: _imageQuality));
  }

  /// Loescht ein eigenes Foto
  Future<bool> deletePhoto(String photoId) async {
    if (_currentUserId == null) {
      throw Exception('Not authenticated');
    }

    debugPrint('[POISocial] Deleting photo: $photoId');

    try {
      // Hole Storage-Path
      final photo = await _client
          .from('poi_photos')
          .select('storage_path, poi_id, user_id')
          .eq('id', photoId)
          .single();

      // Nur eigene Fotos loeschen (oder Admin via RLS)
      if (photo['user_id'] != _currentUserId) {
        throw Exception('Not authorized to delete this photo');
      }

      // Aus Storage loeschen
      await _client.storage.from(_bucketName).remove([photo['storage_path']]);

      // Aus DB loeschen
      await _client.from('poi_photos').delete().eq('id', photoId);

      debugPrint('[POISocial] Photo deleted');
      return true;
    } catch (e) {
      debugPrint('[POISocial] Delete photo error: $e');
      return false;
    }
  }

  // ============================================
  // REVIEWS
  // ============================================

  /// Laedt POI-Statistiken inkl. eigener Bewertung
  Future<POIStats> getStats(String poiId) async {
    debugPrint('[POISocial] Loading stats for POI: $poiId');

    final response = await _client.rpc('get_poi_stats', params: {
      'p_poi_id': poiId,
    });

    final row = (response as List).firstOrNull;
    if (row == null) {
      return POIStats.empty(poiId);
    }

    return POIStats.fromJson({...row, 'poiId': poiId});
  }

  /// Laedt alle Bewertungen fuer einen POI
  Future<List<POIReview>> loadReviews(String poiId,
      {int limit = 20, int offset = 0}) async {
    debugPrint('[POISocial] Loading reviews for POI: $poiId');

    final response = await _client.rpc('get_poi_reviews', params: {
      'p_poi_id': poiId,
      'p_limit': limit,
      'p_offset': offset,
    });

    final reviews = (response as List)
        .map((row) => POIReview.fromJson(row as Map<String, dynamic>))
        .toList();

    debugPrint('[POISocial] Loaded ${reviews.length} reviews');
    return reviews;
  }

  /// Bewertung abgeben oder aktualisieren
  Future<POIReview?> submitReview({
    required String poiId,
    required int rating,
    String? reviewText,
    DateTime? visitDate,
  }) async {
    if (_currentUserId == null) {
      throw Exception('Not authenticated');
    }

    debugPrint(
        '[POISocial] Submitting review for POI: $poiId, rating: $rating');

    try {
      final response = await _client.rpc('submit_poi_review', params: {
        'p_poi_id': poiId,
        'p_rating': rating,
        'p_review_text': reviewText,
        'p_visit_date': visitDate?.toIso8601String().split('T').first,
      });

      debugPrint('[POISocial] Review submitted');
      return POIReview.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[POISocial] Submit review error: $e');
      rethrow;
    }
  }

  /// Eigene Bewertung loeschen
  Future<bool> deleteReview(String poiId) async {
    if (_currentUserId == null) {
      throw Exception('Not authenticated');
    }

    debugPrint('[POISocial] Deleting review for POI: $poiId');

    try {
      await _client
          .from('poi_reviews')
          .delete()
          .eq('poi_id', poiId)
          .eq('user_id', _currentUserId!);

      debugPrint('[POISocial] Review deleted');
      return true;
    } catch (e) {
      debugPrint('[POISocial] Delete review error: $e');
      return false;
    }
  }

  /// Bewertung als "Hilfreich" markieren (Toggle)
  Future<({int helpfulCount, bool isHelpfulByMe})?> voteReviewHelpful(
      String reviewId) async {
    if (_currentUserId == null) {
      throw Exception('Not authenticated');
    }

    debugPrint('[POISocial] Voting helpful for review: $reviewId');

    try {
      final response = await _client.rpc('vote_review_helpful', params: {
        'p_review_id': reviewId,
      });

      final row = (response as List).firstOrNull;
      if (row == null) return null;

      return (
        helpfulCount: row['helpful_count'] as int,
        isHelpfulByMe: row['is_helpful_by_me'] as bool,
      );
    } catch (e) {
      debugPrint('[POISocial] Vote helpful error: $e');
      return null;
    }
  }

  // ============================================
  // COMMENTS
  // ============================================

  /// Laedt Kommentare fuer ein Ziel (POI oder Trip)
  Future<List<Comment>> loadComments({
    required CommentTargetType targetType,
    required String targetId,
    int limit = 50,
    int offset = 0,
  }) async {
    debugPrint(
        '[POISocial] Loading comments for ${targetType.name}: $targetId');

    final response = await _client.rpc('get_comments', params: {
      'p_target_type': targetType.toJson(),
      'p_target_id': targetId,
      'p_limit': limit,
      'p_offset': offset,
    });

    final comments = (response as List)
        .map((row) => Comment.fromJson(row as Map<String, dynamic>))
        .toList();

    debugPrint('[POISocial] Loaded ${comments.length} comments');
    return comments;
  }

  /// Laedt Antworten zu einem Kommentar
  Future<List<Comment>> loadReplies(String parentId, {int limit = 50}) async {
    debugPrint('[POISocial] Loading replies for comment: $parentId');

    final response = await _client.rpc('get_comment_replies', params: {
      'p_parent_id': parentId,
      'p_limit': limit,
    });

    final replies = (response as List)
        .map((row) => Comment.fromJson(row as Map<String, dynamic>))
        .toList();

    debugPrint('[POISocial] Loaded ${replies.length} replies');
    return replies;
  }

  /// Kommentar hinzufuegen
  Future<Comment?> addComment({
    required CommentTargetType targetType,
    required String targetId,
    required String content,
    String? parentId,
  }) async {
    if (_currentUserId == null) {
      throw Exception('Not authenticated');
    }

    debugPrint('[POISocial] Adding comment to ${targetType.name}: $targetId');

    try {
      final response = await _client.rpc('add_comment', params: {
        'p_target_type': targetType.toJson(),
        'p_target_id': targetId,
        'p_content': content,
        'p_parent_id': parentId,
      });

      debugPrint('[POISocial] Comment added');
      return Comment.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[POISocial] Add comment error: $e');
      rethrow;
    }
  }

  /// Eigenen Kommentar loeschen
  Future<bool> deleteComment(String commentId) async {
    if (_currentUserId == null) {
      throw Exception('Not authenticated');
    }

    debugPrint('[POISocial] Deleting comment: $commentId');

    try {
      await _client
          .from('comments')
          .delete()
          .eq('id', commentId)
          .eq('user_id', _currentUserId!);

      debugPrint('[POISocial] Comment deleted');
      return true;
    } catch (e) {
      debugPrint('[POISocial] Delete comment error: $e');
      return false;
    }
  }

  // ============================================
  // FLAG CONTENT
  // ============================================

  /// Inhalt melden
  Future<bool> flagContent({
    required String contentType, // 'photo', 'review', 'comment'
    required String contentId,
    String? reason,
  }) async {
    if (_currentUserId == null) {
      throw Exception('Not authenticated');
    }

    debugPrint('[POISocial] Flagging $contentType: $contentId');

    try {
      await _client.rpc('flag_content', params: {
        'p_content_type': contentType,
        'p_content_id': contentId,
        'p_reason': reason,
      });

      debugPrint('[POISocial] Content flagged');
      return true;
    } catch (e) {
      debugPrint('[POISocial] Flag content error: $e');
      return false;
    }
  }
}

class _UnavailablePOISocialRepository extends POISocialRepository {
  _UnavailablePOISocialRepository()
      : super(SupabaseClient('https://offline.mapab.invalid', 'offline'));

  @override
  Future<List<POIPhoto>> loadPhotos(String poiId,
          {int limit = 20, int offset = 0}) async =>
      const [];

  @override
  Future<POIPhoto?> uploadPhoto({
    required String poiId,
    required XFile imageFile,
    String? caption,
  }) async =>
      null;

  @override
  Future<bool> deletePhoto(String photoId) async => false;

  @override
  Future<POIStats> getStats(String poiId) async => POIStats.empty(poiId);

  @override
  Future<List<POIReview>> loadReviews(String poiId,
          {int limit = 20, int offset = 0}) async =>
      const [];

  @override
  Future<POIReview?> submitReview({
    required String poiId,
    required int rating,
    String? reviewText,
    DateTime? visitDate,
  }) async =>
      null;

  @override
  Future<bool> deleteReview(String poiId) async => false;

  @override
  Future<({int helpfulCount, bool isHelpfulByMe})?> voteReviewHelpful(
    String reviewId,
  ) async =>
      null;

  @override
  Future<List<Comment>> loadComments({
    required CommentTargetType targetType,
    required String targetId,
    int limit = 50,
    int offset = 0,
  }) async =>
      const [];

  @override
  Future<List<Comment>> loadReplies(String parentId, {int limit = 50}) async =>
      const [];

  @override
  Future<Comment?> addComment({
    required CommentTargetType targetType,
    required String targetId,
    required String content,
    String? parentId,
  }) async =>
      null;

  @override
  Future<bool> deleteComment(String commentId) async => false;

  @override
  Future<bool> flagContent({
    required String contentType,
    required String contentId,
    String? reason,
  }) async =>
      false;
}

@riverpod
POISocialRepository poiSocialRepository(PoiSocialRepositoryRef ref) {
  if (!isSupabaseAvailable) {
    debugPrint(
      '[POISocial] Supabase nicht verfuegbar - verwende Offline-Repository',
    );
    return _UnavailablePOISocialRepository();
  }
  return POISocialRepository(Supabase.instance.client);
}

/// Hilfsfunktion fuer Storage-URLs
String getStorageUrl(String storagePath) {
  return '${SupabaseConfig.supabaseUrl}/storage/v1/object/public/poi-photos/$storagePath';
}
