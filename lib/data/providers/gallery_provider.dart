import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/public_trip.dart';
import '../repositories/social_repo.dart';

part 'gallery_provider.g.dart';

/// State fuer die oeffentliche Trip-Galerie
class GalleryState {
  final List<PublicTrip> trips;
  final List<PublicTrip> featuredTrips;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final bool hasMore;

  // Filter
  final String? searchQuery;
  final List<String> selectedTags;
  final String? selectedCountry;
  final GalleryTripTypeFilter tripTypeFilter;
  final GallerySortBy sortBy;

  const GalleryState({
    this.trips = const [],
    this.featuredTrips = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.hasMore = true,
    this.searchQuery,
    this.selectedTags = const [],
    this.selectedCountry,
    this.tripTypeFilter = GalleryTripTypeFilter.all,
    this.sortBy = GallerySortBy.popular,
  });

  GalleryState copyWith({
    List<PublicTrip>? trips,
    List<PublicTrip>? featuredTrips,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool? hasMore,
    String? searchQuery,
    List<String>? selectedTags,
    String? selectedCountry,
    GalleryTripTypeFilter? tripTypeFilter,
    GallerySortBy? sortBy,
  }) {
    return GalleryState(
      trips: trips ?? this.trips,
      featuredTrips: featuredTrips ?? this.featuredTrips,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      hasMore: hasMore ?? this.hasMore,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedTags: selectedTags ?? this.selectedTags,
      selectedCountry: selectedCountry ?? this.selectedCountry,
      tripTypeFilter: tripTypeFilter ?? this.tripTypeFilter,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  /// Hat aktive Filter
  bool get hasActiveFilters =>
      searchQuery != null ||
      selectedTags.isNotEmpty ||
      selectedCountry != null ||
      tripTypeFilter != GalleryTripTypeFilter.all;

  /// Anzahl Trips
  int get tripCount => trips.length;
}

/// Provider fuer die Trip-Galerie
@Riverpod(keepAlive: true)
class GalleryNotifier extends _$GalleryNotifier {
  static const int _pageSize = 20;

  @override
  GalleryState build() {
    return const GalleryState();
  }

  /// Laedt initiale Galerie-Daten
  Future<void> loadGallery() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final repo = ref.read(socialRepositoryProvider);

      // Featured + Normal parallel laden
      final results = await Future.wait([
        repo.loadFeaturedTrips(limit: 5),
        repo.searchPublicTrips(
          query: state.searchQuery,
          tags: state.selectedTags.isEmpty ? null : state.selectedTags,
          countryCode: state.selectedCountry,
          tripType: state.tripTypeFilter,
          sortBy: state.sortBy,
          limit: _pageSize,
          offset: 0,
        ),
      ]);

      state = state.copyWith(
        isLoading: false,
        featuredTrips: results[0],
        trips: results[1],
        hasMore: results[1].length >= _pageSize,
      );

      debugPrint('[Gallery] Geladen: ${state.trips.length} Trips, '
          '${state.featuredTrips.length} Featured');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Fehler beim Laden: $e',
      );
      debugPrint('[Gallery] FEHLER: $e');
    }
  }

  /// Laedt mehr Trips (Pagination)
  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final repo = ref.read(socialRepositoryProvider);

      final moreTrips = await repo.searchPublicTrips(
        query: state.searchQuery,
        tags: state.selectedTags.isEmpty ? null : state.selectedTags,
        countryCode: state.selectedCountry,
        tripType: state.tripTypeFilter,
        sortBy: state.sortBy,
        limit: _pageSize,
        offset: state.trips.length,
      );

      state = state.copyWith(
        isLoadingMore: false,
        trips: [...state.trips, ...moreTrips],
        hasMore: moreTrips.length >= _pageSize,
      );

      debugPrint('[Gallery] Mehr geladen: +${moreTrips.length} Trips');
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
      debugPrint('[Gallery] Mehr laden FEHLER: $e');
    }
  }

  /// Suche ausfuehren
  Future<void> search(String query) async {
    final trimmed = query.trim();
    state = state.copyWith(
      searchQuery: trimmed.isEmpty ? null : trimmed,
      trips: [],
      hasMore: true,
    );
    await loadGallery();
  }

  /// Suche zuruecksetzen
  Future<void> clearSearch() async {
    state = state.copyWith(
      searchQuery: null,
      trips: [],
      hasMore: true,
    );
    await loadGallery();
  }

  /// Tag-Filter togglen
  Future<void> toggleTag(String tag) async {
    final newTags = List<String>.from(state.selectedTags);
    if (newTags.contains(tag)) {
      newTags.remove(tag);
    } else {
      newTags.add(tag);
    }

    state = state.copyWith(
      selectedTags: newTags,
      trips: [],
      hasMore: true,
    );
    await loadGallery();
  }

  /// Trip-Typ-Filter setzen
  Future<void> setTripTypeFilter(GalleryTripTypeFilter filter) async {
    state = state.copyWith(
      tripTypeFilter: filter,
      trips: [],
      hasMore: true,
    );
    await loadGallery();
  }

  /// Sortierung setzen
  Future<void> setSortBy(GallerySortBy sortBy) async {
    state = state.copyWith(
      sortBy: sortBy,
      trips: [],
      hasMore: true,
    );
    await loadGallery();
  }

  /// Land-Filter setzen
  Future<void> setCountryFilter(String? countryCode) async {
    state = state.copyWith(
      selectedCountry: countryCode,
      trips: [],
      hasMore: true,
    );
    await loadGallery();
  }

  /// Alle Filter zuruecksetzen
  Future<void> resetFilters() async {
    state = const GalleryState();
    await loadGallery();
  }

  /// Trip liken/unliken
  Future<void> toggleLike(String tripId) async {
    final tripIndex = state.trips.indexWhere((t) => t.id == tripId);
    if (tripIndex == -1) return;

    final trip = state.trips[tripIndex];
    final repo = ref.read(socialRepositoryProvider);

    // Optimistic Update
    final updatedTrip = trip.copyWith(
      isLikedByMe: !trip.isLikedByMe,
      likesCount: trip.isLikedByMe
          ? (trip.likesCount - 1).clamp(0, 999999)
          : trip.likesCount + 1,
    );

    final updatedTrips = List<PublicTrip>.from(state.trips);
    updatedTrips[tripIndex] = updatedTrip;
    state = state.copyWith(trips: updatedTrips);

    // API Call
    final success = trip.isLikedByMe
        ? await repo.unlikeTrip(tripId)
        : await repo.likeTrip(tripId);

    // Bei Fehler: Revert
    if (!success) {
      final revertedTrips = List<PublicTrip>.from(state.trips);
      revertedTrips[tripIndex] = trip;
      state = state.copyWith(trips: revertedTrips);
    }
  }
}

/// State fuer einzelnen Trip-Detail
class TripDetailState {
  final PublicTrip? trip;
  final bool isLoading;
  final String? error;

  const TripDetailState({
    this.trip,
    this.isLoading = false,
    this.error,
  });

  TripDetailState copyWith({
    PublicTrip? trip,
    bool? isLoading,
    String? error,
  }) {
    return TripDetailState(
      trip: trip ?? this.trip,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Provider fuer Trip-Details
@riverpod
class TripDetailNotifier extends _$TripDetailNotifier {
  @override
  TripDetailState build(String tripId) {
    return const TripDetailState();
  }

  /// Laedt Trip-Details
  Future<void> loadTrip() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final repo = ref.read(socialRepositoryProvider);
      final trip = await repo.getPublicTrip(tripId);

      if (trip != null) {
        state = state.copyWith(isLoading: false, trip: trip);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Trip nicht gefunden',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Fehler beim Laden: $e',
      );
    }
  }

  /// Trip liken/unliken
  Future<void> toggleLike() async {
    final trip = state.trip;
    if (trip == null) return;

    final repo = ref.read(socialRepositoryProvider);

    // Optimistic Update
    state = state.copyWith(
      trip: trip.copyWith(
        isLikedByMe: !trip.isLikedByMe,
        likesCount: trip.isLikedByMe
            ? (trip.likesCount - 1).clamp(0, 999999)
            : trip.likesCount + 1,
      ),
    );

    // API Call
    final success = trip.isLikedByMe
        ? await repo.unlikeTrip(trip.id)
        : await repo.likeTrip(trip.id);

    // Bei Fehler: Revert
    if (!success) {
      state = state.copyWith(trip: trip);
    }
  }

  /// Trip importieren
  Future<Map<String, dynamic>?> importTrip() async {
    final trip = state.trip;
    if (trip == null) return null;

    final repo = ref.read(socialRepositoryProvider);
    final tripData = await repo.importTrip(trip.id);

    if (tripData != null) {
      state = state.copyWith(
        trip: trip.copyWith(isImportedByMe: true),
      );
    }

    return tripData;
  }

  Future<bool> updateTripMeta({
    required String tripName,
    String? description,
    List<String>? tags,
  }) async {
    final current = state.trip;
    if (current == null) return false;

    final repo = ref.read(socialRepositoryProvider);
    final updated = await repo.updatePublishedTrip(
      tripId: current.id,
      tripName: tripName,
      description: description,
      tags: tags,
    );

    if (updated == null) return false;
    state = state.copyWith(trip: updated);
    return true;
  }

  Future<bool> deleteTrip() async {
    final current = state.trip;
    if (current == null) return false;

    final repo = ref.read(socialRepositoryProvider);
    final ok = await repo.deletePublishedTrip(current.id);
    if (!ok) return false;

    state = state.copyWith(trip: null);
    return true;
  }
}

/// State fuer User-Profil
class ProfileState {
  final UserProfile? profile;
  final List<PublicTrip> trips;
  final bool isLoading;
  final String? error;

  const ProfileState({
    this.profile,
    this.trips = const [],
    this.isLoading = false,
    this.error,
  });

  ProfileState copyWith({
    UserProfile? profile,
    List<PublicTrip>? trips,
    bool? isLoading,
    String? error,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      trips: trips ?? this.trips,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Provider fuer User-Profil
@riverpod
class ProfileNotifier extends _$ProfileNotifier {
  @override
  ProfileState build(String userId) {
    return const ProfileState();
  }

  /// Laedt Profil und Trips des Users
  Future<void> loadProfile() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final repo = ref.read(socialRepositoryProvider);

      final results = await Future.wait([
        repo.loadUserProfile(userId),
        repo.loadUserTrips(userId),
      ]);

      state = state.copyWith(
        isLoading: false,
        profile: results[0] as UserProfile?,
        trips: results[1] as List<PublicTrip>,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Fehler beim Laden: $e',
      );
    }
  }
}

/// Provider fuer eigenes Profil
@Riverpod(keepAlive: true)
class MyProfileNotifier extends _$MyProfileNotifier {
  @override
  ProfileState build() {
    return const ProfileState();
  }

  /// Laedt/erstellt eigenes Profil
  Future<void> loadMyProfile() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final repo = ref.read(socialRepositoryProvider);

      final profile = await repo.loadOrCreateMyProfile();
      final trips = await repo.loadMyPublishedTrips();

      state = state.copyWith(
        isLoading: false,
        profile: profile,
        trips: trips,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Fehler beim Laden: $e',
      );
    }
  }

  /// Profil aktualisieren
  Future<bool> updateProfile({
    String? displayName,
    String? bio,
  }) async {
    try {
      final repo = ref.read(socialRepositoryProvider);
      final profile = await repo.updateProfile(
        displayName: displayName,
        bio: bio,
      );

      if (profile != null) {
        state = state.copyWith(profile: profile);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[MyProfile] Update FEHLER: $e');
      return false;
    }
  }

  /// Trip aus Liste entfernen (nach Loeschen)
  void removeTripFromList(String tripId) {
    state = state.copyWith(
      trips: state.trips.where((t) => t.id != tripId).toList(),
    );
  }
}
