import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/public_poi_post.dart';
import '../repositories/social_repo.dart';

class POIGalleryState {
  final List<PublicPoiPost> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final String? searchQuery;
  final List<String> categories;
  final bool mustSeeOnly;
  final String sortBy;

  const POIGalleryState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.searchQuery,
    this.categories = const [],
    this.mustSeeOnly = false,
    this.sortBy = 'trending',
  });

  POIGalleryState copyWith({
    List<PublicPoiPost>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    String? searchQuery,
    List<String>? categories,
    bool? mustSeeOnly,
    String? sortBy,
  }) {
    return POIGalleryState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      categories: categories ?? this.categories,
      mustSeeOnly: mustSeeOnly ?? this.mustSeeOnly,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

class POIGalleryNotifier extends StateNotifier<POIGalleryState> {
  POIGalleryNotifier(this._read) : super(const POIGalleryState());

  final Ref _read;
  static const int _pageSize = 20;

  Future<void> load() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = _read.read(socialRepositoryProvider);
      final items = await repo.searchPublicPOIs(
        query: state.searchQuery,
        categories: state.categories.isEmpty ? null : state.categories,
        mustSeeOnly: state.mustSeeOnly ? true : null,
        sortBy: state.sortBy,
        limit: _pageSize,
        offset: 0,
      );
      state = state.copyWith(
        items: items,
        isLoading: false,
        hasMore: items.length >= _pageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '$e');
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final repo = _read.read(socialRepositoryProvider);
      final items = await repo.searchPublicPOIs(
        query: state.searchQuery,
        categories: state.categories.isEmpty ? null : state.categories,
        mustSeeOnly: state.mustSeeOnly ? true : null,
        sortBy: state.sortBy,
        limit: _pageSize,
        offset: state.items.length,
      );
      state = state.copyWith(
        items: [...state.items, ...items],
        isLoadingMore: false,
        hasMore: items.length >= _pageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: '$e');
    }
  }

  Future<void> setSearch(String? query) async {
    state = state.copyWith(searchQuery: query, hasMore: true);
    await load();
  }

  Future<void> setSort(String sortBy) async {
    state = state.copyWith(sortBy: sortBy, hasMore: true);
    await load();
  }

  Future<void> toggleMustSee() async {
    state = state.copyWith(mustSeeOnly: !state.mustSeeOnly, hasMore: true);
    await load();
  }

  Future<void> toggleCategory(String category) async {
    final next = [...state.categories];
    if (next.contains(category)) {
      next.remove(category);
    } else {
      next.add(category);
    }
    state = state.copyWith(categories: next, hasMore: true);
    await load();
  }

  Future<void> toggleLike(String postId) async {
    final index = state.items.indexWhere((e) => e.id == postId);
    if (index < 0) return;
    final current = state.items[index];
    final optimistic = current.isLikedByMe
        ? PublicPoiPost(
            id: current.id,
            poiId: current.poiId,
            userId: current.userId,
            title: current.title,
            content: current.content,
            categories: current.categories,
            isMustSee: current.isMustSee,
            ratingAvg: current.ratingAvg,
            ratingCount: current.ratingCount,
            voteScore: current.voteScore,
            likesCount: (current.likesCount - 1).clamp(0, 1 << 30),
            commentCount: current.commentCount,
            photoCount: current.photoCount,
            coverPhotoPath: current.coverPhotoPath,
            authorName: current.authorName,
            authorAvatar: current.authorAvatar,
            isLikedByMe: false,
            createdAt: current.createdAt,
          )
        : PublicPoiPost(
            id: current.id,
            poiId: current.poiId,
            userId: current.userId,
            title: current.title,
            content: current.content,
            categories: current.categories,
            isMustSee: current.isMustSee,
            ratingAvg: current.ratingAvg,
            ratingCount: current.ratingCount,
            voteScore: current.voteScore,
            likesCount: current.likesCount + 1,
            commentCount: current.commentCount,
            photoCount: current.photoCount,
            coverPhotoPath: current.coverPhotoPath,
            authorName: current.authorName,
            authorAvatar: current.authorAvatar,
            isLikedByMe: true,
            createdAt: current.createdAt,
          );

    final next = [...state.items];
    next[index] = optimistic;
    state = state.copyWith(items: next);

    final repo = _read.read(socialRepositoryProvider);
    final ok = current.isLikedByMe
        ? await repo.unlikePOIPost(postId)
        : await repo.likePOIPost(postId);
    if (!ok) {
      next[index] = current;
      state = state.copyWith(items: next);
    }
  }

  Future<void> vote(String postId, int value) async {
    final index = state.items.indexWhere((e) => e.id == postId);
    if (index < 0) return;

    final current = state.items[index];
    final optimistic = PublicPoiPost(
      id: current.id,
      poiId: current.poiId,
      userId: current.userId,
      title: current.title,
      content: current.content,
      categories: current.categories,
      isMustSee: current.isMustSee,
      ratingAvg: current.ratingAvg,
      ratingCount: current.ratingCount,
      voteScore: current.voteScore + value.clamp(-1, 1),
      likesCount: current.likesCount,
      commentCount: current.commentCount,
      photoCount: current.photoCount,
      coverPhotoPath: current.coverPhotoPath,
      authorName: current.authorName,
      authorAvatar: current.authorAvatar,
      isLikedByMe: current.isLikedByMe,
      createdAt: current.createdAt,
    );

    final next = [...state.items];
    next[index] = optimistic;
    state = state.copyWith(items: next);

    final repo = _read.read(socialRepositoryProvider);
    final score = await repo.votePOI(postId, voteValue: value);
    if (score == null) {
      next[index] = current;
      state = state.copyWith(items: next);
      return;
    }

    next[index] = PublicPoiPost(
      id: optimistic.id,
      poiId: optimistic.poiId,
      userId: optimistic.userId,
      title: optimistic.title,
      content: optimistic.content,
      categories: optimistic.categories,
      isMustSee: optimistic.isMustSee,
      ratingAvg: optimistic.ratingAvg,
      ratingCount: optimistic.ratingCount,
      voteScore: score,
      likesCount: optimistic.likesCount,
      commentCount: optimistic.commentCount,
      photoCount: optimistic.photoCount,
      coverPhotoPath: optimistic.coverPhotoPath,
      authorName: optimistic.authorName,
      authorAvatar: optimistic.authorAvatar,
      isLikedByMe: optimistic.isLikedByMe,
      createdAt: optimistic.createdAt,
    );
    state = state.copyWith(items: next);
  }
}

final poiGalleryNotifierProvider =
    StateNotifierProvider<POIGalleryNotifier, POIGalleryState>(
  (ref) => POIGalleryNotifier(ref),
);
