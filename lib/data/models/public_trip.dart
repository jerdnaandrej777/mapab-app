import 'package:freezed_annotation/freezed_annotation.dart';

part 'public_trip.freezed.dart';
part 'public_trip.g.dart';

/// Oeffentlich geteilter Trip in der Galerie
@freezed
class PublicTrip with _$PublicTrip {
  const PublicTrip._();

  const factory PublicTrip({
    required String id,
    required String userId,
    required String tripName,
    String? description,
    required String tripType,
    String? thumbnailUrl,
    @Default([]) List<String> tags,
    String? region,
    String? countryCode,
    double? distanceKm,
    double? durationHours,
    @Default(0) int stopCount,
    @Default(1) int dayCount,
    @Default(0) int likesCount,
    @Default(0) int viewsCount,
    @Default(0) int importsCount,
    @Default(false) bool isFeatured,
    required DateTime createdAt,

    // Author Info (aus Join)
    String? authorName,
    String? authorAvatar,
    int? authorTotalTrips,

    // User-spezifische Flags
    @Default(false) bool isLikedByMe,
    @Default(false) bool isImportedByMe,

    // Vollstaendige Trip-Daten (nur bei Detail-Ansicht)
    Map<String, dynamic>? tripData,
  }) = _PublicTrip;

  factory PublicTrip.fromJson(Map<String, dynamic> json) =>
      _$PublicTripFromJson(json);

  /// Formatierte Distanz
  String get formattedDistance {
    if (distanceKm == null) return '';
    if (distanceKm! < 1) return '${(distanceKm! * 1000).round()} m';
    return '${distanceKm!.round()} km';
  }

  /// Formatierte Dauer
  String get formattedDuration {
    if (durationHours == null) return '';
    final hours = durationHours!.floor();
    final minutes = ((durationHours! - hours) * 60).round();
    if (hours == 0) return '$minutes min';
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}min';
  }

  /// Ist Tagestrip
  bool get isDayTrip => tripType == 'daytrip';

  /// Ist Euro Trip
  bool get isEuroTrip => tripType == 'eurotrip';

  /// Hat Author-Info
  bool get hasAuthorInfo => authorName != null && authorName!.isNotEmpty;

  /// Kurze Statistik-Zeile
  String get statsLine {
    final parts = <String>[];
    if (stopCount > 0) parts.add('$stopCount Stops');
    if (formattedDistance.isNotEmpty) parts.add(formattedDistance);
    if (dayCount > 1) parts.add('$dayCount Tage');
    return parts.join(' \u2022 ');
  }
}

/// User-Profil (oeffentliche Daten)
@freezed
class UserProfile with _$UserProfile {
  const UserProfile._();

  const factory UserProfile({
    required String id,
    String? displayName,
    String? avatarUrl,
    String? bio,
    @Default(0) double totalKm,
    @Default(0) int totalTrips,
    @Default(0) int totalPois,
    @Default(0) int totalLikesReceived,
    required DateTime createdAt,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);

  /// Hat Display Name
  bool get hasDisplayName => displayName != null && displayName!.isNotEmpty;

  /// Anzeigename oder Fallback
  String get displayNameOrDefault => displayName ?? 'Anonymer Reisender';

  /// Formatierte Gesamt-Distanz
  String get formattedTotalKm {
    if (totalKm < 1000) return '${totalKm.round()} km';
    return '${(totalKm / 1000).toStringAsFixed(1)}k km';
  }
}

/// Filter/Sortier-Optionen fuer Galerie
enum GallerySortBy {
  popular('Beliebt'),
  recent('Neueste'),
  likes('Meiste Likes');

  final String label;
  const GallerySortBy(this.label);
}

/// Trip-Typ Filter
enum GalleryTripTypeFilter {
  all('Alle'),
  daytrip('Tagesausflug'),
  eurotrip('Euro Trip');

  final String label;
  const GalleryTripTypeFilter(this.label);
}
