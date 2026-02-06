import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/comment.dart';
import '../models/poi_photo.dart';
import '../models/poi_review.dart';
import '../repositories/poi_social_repo.dart';

part 'poi_social_provider.g.dart';

// ============================================
// POI SOCIAL STATE
// ============================================

/// State fuer POI Social Features (Fotos, Bewertungen, Kommentare)
class POISocialState {
  final POIStats? stats;
  final List<POIReview> reviews;
  final List<POIPhoto> photos;
  final List<Comment> comments;
  final bool isLoading;
  final bool isSubmitting;
  final String? error;

  const POISocialState({
    this.stats,
    this.reviews = const [],
    this.photos = const [],
    this.comments = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
  });

  POISocialState copyWith({
    POIStats? stats,
    List<POIReview>? reviews,
    List<POIPhoto>? photos,
    List<Comment>? comments,
    bool? isLoading,
    bool? isSubmitting,
    String? error,
  }) =>
      POISocialState(
        stats: stats ?? this.stats,
        reviews: reviews ?? this.reviews,
        photos: photos ?? this.photos,
        comments: comments ?? this.comments,
        isLoading: isLoading ?? this.isLoading,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        error: error,
      );

  /// Hat der aktuelle Benutzer bereits bewertet?
  bool get hasMyRating => stats?.hasMyRating ?? false;

  /// Durchschnittsbewertung
  double get avgRating => stats?.avgRating ?? 0.0;

  /// Anzahl Bewertungen
  int get reviewCount => stats?.reviewCount ?? 0;

  /// Anzahl Fotos
  int get photoCount => stats?.photoCount ?? 0;

  /// Anzahl Kommentare
  int get commentCount => stats?.commentCount ?? 0;
}

// ============================================
// POI SOCIAL NOTIFIER
// ============================================

/// Provider fuer POI Social Features
@riverpod
class POISocialNotifier extends _$POISocialNotifier {
  @override
  POISocialState build(String poiId) {
    return const POISocialState();
  }

  /// Laedt alle Social-Daten fuer einen POI
  Future<void> loadAll() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final repo = ref.read(poiSocialRepositoryProvider);

      final results = await Future.wait([
        repo.getStats(poiId),
        repo.loadReviews(poiId),
        repo.loadPhotos(poiId),
        repo.loadComments(
          targetType: CommentTargetType.poi,
          targetId: poiId,
        ),
      ]);

      state = state.copyWith(
        isLoading: false,
        stats: results[0] as POIStats,
        reviews: results[1] as List<POIReview>,
        photos: results[2] as List<POIPhoto>,
        comments: results[3] as List<Comment>,
      );
    } catch (e) {
      debugPrint('[POISocialProvider] loadAll error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Laedt nur Statistiken (fuer schnelle Anzeige)
  Future<void> loadStats() async {
    try {
      final repo = ref.read(poiSocialRepositoryProvider);
      final stats = await repo.getStats(poiId);
      state = state.copyWith(stats: stats);
    } catch (e) {
      debugPrint('[POISocialProvider] loadStats error: $e');
    }
  }

  /// Laedt nur Bewertungen
  Future<void> loadReviews() async {
    try {
      final repo = ref.read(poiSocialRepositoryProvider);
      final reviews = await repo.loadReviews(poiId);
      state = state.copyWith(reviews: reviews);
    } catch (e) {
      debugPrint('[POISocialProvider] loadReviews error: $e');
    }
  }

  /// Laedt nur Fotos
  Future<void> loadPhotos() async {
    try {
      final repo = ref.read(poiSocialRepositoryProvider);
      final photos = await repo.loadPhotos(poiId);
      state = state.copyWith(photos: photos);
    } catch (e) {
      debugPrint('[POISocialProvider] loadPhotos error: $e');
    }
  }

  /// Laedt nur Kommentare
  Future<void> loadComments() async {
    try {
      final repo = ref.read(poiSocialRepositoryProvider);
      final comments = await repo.loadComments(
        targetType: CommentTargetType.poi,
        targetId: poiId,
      );
      state = state.copyWith(comments: comments);
    } catch (e) {
      debugPrint('[POISocialProvider] loadComments error: $e');
    }
  }

  // ============================================
  // REVIEWS
  // ============================================

  /// Bewertung abgeben
  Future<bool> submitReview({
    required int rating,
    String? reviewText,
    DateTime? visitDate,
  }) async {
    if (state.isSubmitting) return false;

    state = state.copyWith(isSubmitting: true, error: null);

    try {
      final repo = ref.read(poiSocialRepositoryProvider);
      await repo.submitReview(
        poiId: poiId,
        rating: rating,
        reviewText: reviewText,
        visitDate: visitDate,
      );

      // Daten neu laden
      await loadAll();
      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      debugPrint('[POISocialProvider] submitReview error: $e');
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return false;
    }
  }

  /// Eigene Bewertung loeschen
  Future<bool> deleteReview() async {
    if (state.isSubmitting) return false;

    state = state.copyWith(isSubmitting: true);

    try {
      final repo = ref.read(poiSocialRepositoryProvider);
      final success = await repo.deleteReview(poiId);

      if (success) {
        await loadAll();
      }
      state = state.copyWith(isSubmitting: false);
      return success;
    } catch (e) {
      debugPrint('[POISocialProvider] deleteReview error: $e');
      state = state.copyWith(isSubmitting: false);
      return false;
    }
  }

  /// Bewertung als "Hilfreich" markieren
  Future<void> voteHelpful(String reviewId) async {
    try {
      final repo = ref.read(poiSocialRepositoryProvider);
      final result = await repo.voteReviewHelpful(reviewId);

      if (result != null) {
        // Optimistic update
        final updatedReviews = state.reviews.map((review) {
          if (review.id == reviewId) {
            return review.copyWith(
              helpfulCount: result.helpfulCount,
              isHelpfulByMe: result.isHelpfulByMe,
            );
          }
          return review;
        }).toList();

        state = state.copyWith(reviews: updatedReviews);
      }
    } catch (e) {
      debugPrint('[POISocialProvider] voteHelpful error: $e');
    }
  }

  // ============================================
  // PHOTOS
  // ============================================

  /// Foto hochladen
  Future<bool> uploadPhoto(XFile imageFile, {String? caption}) async {
    if (state.isSubmitting) return false;

    state = state.copyWith(isSubmitting: true, error: null);

    try {
      final repo = ref.read(poiSocialRepositoryProvider);
      await repo.uploadPhoto(
        poiId: poiId,
        imageFile: imageFile,
        caption: caption,
      );

      // Daten neu laden
      await loadAll();
      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      debugPrint('[POISocialProvider] uploadPhoto error: $e');
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return false;
    }
  }

  /// Foto loeschen
  Future<bool> deletePhoto(String photoId) async {
    try {
      final repo = ref.read(poiSocialRepositoryProvider);
      final success = await repo.deletePhoto(photoId);

      if (success) {
        // Optimistic update
        final updatedPhotos = state.photos.where((p) => p.id != photoId).toList();
        state = state.copyWith(
          photos: updatedPhotos,
          stats: state.stats?.copyWith(photoCount: updatedPhotos.length),
        );
      }
      return success;
    } catch (e) {
      debugPrint('[POISocialProvider] deletePhoto error: $e');
      return false;
    }
  }

  // ============================================
  // COMMENTS
  // ============================================

  /// Kommentar hinzufuegen
  Future<bool> addComment(String content, {String? parentId}) async {
    if (state.isSubmitting) return false;

    state = state.copyWith(isSubmitting: true, error: null);

    try {
      final repo = ref.read(poiSocialRepositoryProvider);
      final comment = await repo.addComment(
        targetType: CommentTargetType.poi,
        targetId: poiId,
        content: content,
        parentId: parentId,
      );

      if (comment != null) {
        if (parentId == null) {
          // Top-level Kommentar
          state = state.copyWith(
            isSubmitting: false,
            comments: [comment, ...state.comments],
            stats: state.stats?.copyWith(commentCount: (state.stats?.commentCount ?? 0) + 1),
          );
        } else {
          // Antwort - Kommentare neu laden
          await loadComments();
          state = state.copyWith(isSubmitting: false);
        }
        return true;
      }

      state = state.copyWith(isSubmitting: false);
      return false;
    } catch (e) {
      debugPrint('[POISocialProvider] addComment error: $e');
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return false;
    }
  }

  /// Kommentar loeschen
  Future<bool> deleteComment(String commentId) async {
    try {
      final repo = ref.read(poiSocialRepositoryProvider);
      final success = await repo.deleteComment(commentId);

      if (success) {
        // Optimistic update
        final updatedComments = state.comments.where((c) => c.id != commentId).toList();
        state = state.copyWith(
          comments: updatedComments,
          stats: state.stats?.copyWith(commentCount: updatedComments.length),
        );
      }
      return success;
    } catch (e) {
      debugPrint('[POISocialProvider] deleteComment error: $e');
      return false;
    }
  }

  /// Antworten fuer einen Kommentar laden
  Future<List<Comment>> loadReplies(String parentId) async {
    try {
      final repo = ref.read(poiSocialRepositoryProvider);
      return await repo.loadReplies(parentId);
    } catch (e) {
      debugPrint('[POISocialProvider] loadReplies error: $e');
      return [];
    }
  }

  // ============================================
  // FLAG CONTENT
  // ============================================

  /// Inhalt melden
  Future<bool> flagContent({
    required String contentType,
    required String contentId,
    String? reason,
  }) async {
    try {
      final repo = ref.read(poiSocialRepositoryProvider);
      return await repo.flagContent(
        contentType: contentType,
        contentId: contentId,
        reason: reason,
      );
    } catch (e) {
      debugPrint('[POISocialProvider] flagContent error: $e');
      return false;
    }
  }
}

// ============================================
// TRIP COMMENTS PROVIDER (fuer Trip-Detail-Seite)
// ============================================

/// State fuer Trip-Kommentare
class TripCommentsState {
  final List<Comment> comments;
  final bool isLoading;
  final bool isSubmitting;
  final String? error;

  const TripCommentsState({
    this.comments = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
  });

  TripCommentsState copyWith({
    List<Comment>? comments,
    bool? isLoading,
    bool? isSubmitting,
    String? error,
  }) =>
      TripCommentsState(
        comments: comments ?? this.comments,
        isLoading: isLoading ?? this.isLoading,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        error: error,
      );
}

/// Provider fuer Trip-Kommentare
@riverpod
class TripCommentsNotifier extends _$TripCommentsNotifier {
  @override
  TripCommentsState build(String tripId) {
    return const TripCommentsState();
  }

  /// Laedt Kommentare fuer einen Trip
  Future<void> loadComments() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final repo = ref.read(poiSocialRepositoryProvider);
      final comments = await repo.loadComments(
        targetType: CommentTargetType.trip,
        targetId: tripId,
      );

      state = state.copyWith(isLoading: false, comments: comments);
    } catch (e) {
      debugPrint('[TripCommentsProvider] loadComments error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Kommentar hinzufuegen
  Future<bool> addComment(String content, {String? parentId}) async {
    if (state.isSubmitting) return false;

    state = state.copyWith(isSubmitting: true, error: null);

    try {
      final repo = ref.read(poiSocialRepositoryProvider);
      final comment = await repo.addComment(
        targetType: CommentTargetType.trip,
        targetId: tripId,
        content: content,
        parentId: parentId,
      );

      if (comment != null) {
        if (parentId == null) {
          state = state.copyWith(
            isSubmitting: false,
            comments: [comment, ...state.comments],
          );
        } else {
          await loadComments();
          state = state.copyWith(isSubmitting: false);
        }
        return true;
      }

      state = state.copyWith(isSubmitting: false);
      return false;
    } catch (e) {
      debugPrint('[TripCommentsProvider] addComment error: $e');
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return false;
    }
  }

  /// Kommentar loeschen
  Future<bool> deleteComment(String commentId) async {
    try {
      final repo = ref.read(poiSocialRepositoryProvider);
      final success = await repo.deleteComment(commentId);

      if (success) {
        final updatedComments = state.comments.where((c) => c.id != commentId).toList();
        state = state.copyWith(comments: updatedComments);
      }
      return success;
    } catch (e) {
      debugPrint('[TripCommentsProvider] deleteComment error: $e');
      return false;
    }
  }

  /// Antworten laden
  Future<List<Comment>> loadReplies(String parentId) async {
    try {
      final repo = ref.read(poiSocialRepositoryProvider);
      return await repo.loadReplies(parentId);
    } catch (e) {
      debugPrint('[TripCommentsProvider] loadReplies error: $e');
      return [];
    }
  }
}
