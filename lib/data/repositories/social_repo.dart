import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../core/supabase/supabase_config.dart';
import '../models/public_poi_post.dart';
import '../models/public_trip.dart';
import '../models/trip.dart';
import '../models/trip_photo.dart';

part 'social_repo.g.dart';

/// Repository fuer Social Features (Oeffentliche Trip-Galerie)
///
/// Stellt Methoden bereit zum:
/// - Laden oeffentlicher Trips (Galerie, Featured, Suche)
/// - Veroeffentlichen eigener Trips
/// - Liken/Unliken von Trips
/// - Importieren von Trips in Favoriten
/// - User-Profile verwalten
class SocialRepository {
  final SupabaseClient _client;
  static const _tripPhotosBucket = 'trip-photos';
  static const _maxImageSize = 1920;
  static const _imageQuality = 85;

  SocialRepository(this._client);

  String? get _currentUserId => _client.auth.currentUser?.id;

  // ============================================
  // GALERIE-METHODEN
  // ============================================

  /// Laedt oeffentliche Trips mit Filtern und Sortierung
  Future<List<PublicTrip>> searchPublicTrips({
    String? query,
    List<String>? tags,
    String? countryCode,
    GalleryTripTypeFilter? tripType,
    GallerySortBy sortBy = GallerySortBy.popular,
    int limit = 20,
    int offset = 0,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      final response = await _client.rpc('search_public_trips', params: {
        'p_query': query,
        'p_tags': tags,
        'p_country_code': countryCode,
        'p_trip_type':
            tripType == GalleryTripTypeFilter.all ? null : tripType?.name,
        'p_sort_by': sortBy.name,
        'p_limit': limit,
        'p_offset': offset,
      });

      final rows = response as List<dynamic>;
      final trips = rows
          .map((row) => _parsePublicTripRow(row as Map<String, dynamic>))
          .toList();

      stopwatch.stop();
      debugPrint('[Social] Galerie geladen: ${trips.length} Trips in '
          '${stopwatch.elapsedMilliseconds}ms (query=$query, sort=$sortBy)');

      return trips;
    } catch (e) {
      stopwatch.stop();
      debugPrint(
          '[Social] Galerie FEHLER (${stopwatch.elapsedMilliseconds}ms): $e');
      rethrow;
    }
  }

  // ============================================
  // POI-GALERIE-METHODEN
  // ============================================

  Future<List<PublicPoiPost>> searchPublicPOIs({
    String? query,
    List<String>? categories,
    bool? mustSeeOnly,
    String sortBy = 'trending',
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _client.rpc('search_public_pois', params: {
        'p_query': query,
        'p_categories': categories,
        'p_must_see_only': mustSeeOnly,
        'p_sort_by': sortBy,
        'p_limit': limit,
        'p_offset': offset,
      });

      final rows = response as List<dynamic>;
      return rows
          .map((row) => _parsePublicPoiRow(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[Social] POI-Galerie FEHLER: $e');
      return const [];
    }
  }

  Future<PublicPoiPost?> getPublicPOI(String postId) async {
    try {
      final response = await _client.rpc('get_public_poi', params: {
        'p_post_id': postId,
      });
      final rows = response as List<dynamic>;
      if (rows.isEmpty) return null;
      return _parsePublicPoiRow(rows.first as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[Social] Public-POI-Detail FEHLER: $e');
      return null;
    }
  }

  Future<bool> likePOIPost(String postId) async {
    try {
      final result = await _client.rpc('like_poi_post', params: {
        'p_post_id': postId,
      });
      return result as bool? ?? false;
    } catch (e) {
      debugPrint('[Social] POI Like FEHLER: $e');
      return false;
    }
  }

  Future<bool> unlikePOIPost(String postId) async {
    try {
      final result = await _client.rpc('unlike_poi_post', params: {
        'p_post_id': postId,
      });
      return result as bool? ?? false;
    } catch (e) {
      debugPrint('[Social] POI Unlike FEHLER: $e');
      return false;
    }
  }

  Future<int?> votePOI(String postId, {required int voteValue}) async {
    try {
      final result = await _client.rpc('vote_poi', params: {
        'p_post_id': postId,
        'p_vote': voteValue.clamp(-1, 1),
      });
      return result as int?;
    } catch (e) {
      debugPrint('[Social] POI Vote FEHLER: $e');
      return null;
    }
  }

  /// Laedt Featured Trips fuer die Startseite
  Future<List<PublicTrip>> loadFeaturedTrips({int limit = 5}) async {
    try {
      // Nutze search_public_trips mit featured-Filter statt direkter Query
      // um FK-Probleme zwischen trips und user_profiles zu vermeiden
      final response = await _client.rpc('search_public_trips', params: {
        'p_query': null,
        'p_tags': null,
        'p_country_code': null,
        'p_trip_type': null,
        'p_sort_by': 'recent',
        'p_limit': limit,
        'p_offset': 0,
      });

      final rows = response as List<dynamic>;
      // Filter nur featured Trips (RPC unterstuetzt kein featured-Filter direkt)
      final featuredRows = rows
          .where((row) => (row as Map<String, dynamic>)['is_featured'] == true)
          .toList();

      if (featuredRows.isNotEmpty) {
        return featuredRows
            .map((row) => _parsePublicTripRow(row as Map<String, dynamic>))
            .toList();
      }

      // Fallback: Wenn keine featured, nimm die neuesten
      return rows
          .take(limit)
          .map((row) => _parsePublicTripRow(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[Social] Featured FEHLER: $e');
      rethrow;
    }
  }

  /// Laedt Trip-Details mit vollstaendigen Daten
  Future<PublicTrip?> getPublicTrip(String tripId) async {
    try {
      final response = await _client.rpc('get_public_trip', params: {
        'p_trip_id': tripId,
      });

      final rows = response as List<dynamic>;
      if (rows.isEmpty) return null;

      // View zaehlen (fire-and-forget)
      unawaited(_incrementViews(tripId));

      return _parsePublicTripRow(rows.first as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[Social] Trip-Details FEHLER: $e');
      rethrow;
    }
  }

  /// Laedt Trips eines bestimmten Users
  Future<List<PublicTrip>> loadUserTrips(String userId,
      {int limit = 20}) async {
    try {
      final response = await _client
          .from('trips')
          .select()
          .eq('user_id', userId)
          .eq('is_hidden', false)
          .order('created_at', ascending: false)
          .limit(limit);

      final rows = response as List<dynamic>;
      return rows
          .map((row) => _parsePublicTripRow(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[Social] User-Trips FEHLER: $e');
      rethrow;
    }
  }

  // ============================================
  // INTERAKTION-METHODEN
  // ============================================

  /// Trip liken
  Future<bool> likeTrip(String tripId) async {
    try {
      final result = await _client.rpc('like_trip', params: {
        'p_trip_id': tripId,
      });
      debugPrint('[Social] Trip geliked: $tripId');
      return result as bool? ?? false;
    } catch (e) {
      debugPrint('[Social] Like FEHLER: $e');
      return false;
    }
  }

  /// Trip unliken
  Future<bool> unlikeTrip(String tripId) async {
    try {
      final result = await _client.rpc('unlike_trip', params: {
        'p_trip_id': tripId,
      });
      debugPrint('[Social] Trip unliked: $tripId');
      return result as bool? ?? false;
    } catch (e) {
      debugPrint('[Social] Unlike FEHLER: $e');
      return false;
    }
  }

  /// Trip importieren (gibt Trip-Daten zurueck)
  Future<Map<String, dynamic>?> importTrip(String tripId) async {
    try {
      final result = await _client.rpc('import_trip', params: {
        'p_trip_id': tripId,
      });
      debugPrint('[Social] Trip importiert: $tripId');
      return result as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('[Social] Import FEHLER: $e');
      return null;
    }
  }

  // ============================================
  // VEROEFFENTLICHUNGS-METHODEN
  // ============================================

  /// Trip veroeffentlichen
  Future<PublicTrip?> publishTrip({
    required Trip trip,
    required String tripName,
    String? description,
    List<String>? tags,
    String? region,
    String? countryCode,
    String? coverImagePath,
  }) async {
    try {
      // Trip zu JSON konvertieren
      final tripData = _tripToJson(trip);

      // Thumbnail aus erstem POI mit Bild
      String? thumbnailUrl;
      for (final stop in trip.stops) {
        if (stop.imageUrl != null) {
          thumbnailUrl = stop.imageUrl;
          break;
        }
      }

      final response = await _client.rpc('publish_trip', params: {
        'p_trip_name': tripName,
        'p_trip_type': trip.type.name,
        'p_trip_data': tripData,
        'p_description': description,
        'p_thumbnail_url': thumbnailUrl,
        'p_tags': tags ?? [],
        'p_region': region,
        'p_country_code': countryCode,
        'p_start_lat': trip.route.coordinates.isNotEmpty
            ? trip.route.coordinates.first.latitude
            : null,
        'p_start_lng': trip.route.coordinates.isNotEmpty
            ? trip.route.coordinates.first.longitude
            : null,
        'p_distance_km': trip.route.distanceKm,
        'p_duration_hours': trip.route.durationMinutes / 60,
        'p_stop_count': trip.stopCount,
        'p_day_count': trip.actualDays,
      });

      debugPrint('[Social] Trip veroeffentlicht: $tripName');
      return _parsePublicTripRow(response as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[Social] Veroeffentlichen FEHLER: $e');
      rethrow;
    }
  }

  /// Eigenen Trip loeschen
  Future<bool> deletePublishedTrip(String tripId) async {
    try {
      await _client.from('trips').delete().eq('id', tripId);
      debugPrint('[Social] Trip geloescht: $tripId');
      return true;
    } catch (e) {
      debugPrint('[Social] Loeschen FEHLER: $e');
      return false;
    }
  }

  /// Eigene veroeffentlichte Trips laden
  Future<List<PublicTrip>> loadMyPublishedTrips() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _client
          .from('trips')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final rows = response as List<dynamic>;
      return rows
          .map((row) => _parsePublicTripRow(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[Social] Meine Trips FEHLER: $e');
      rethrow;
    }
  }

  // ============================================
  // PROFIL-METHODEN
  // ============================================

  /// User-Profil laden
  Future<UserProfile?> loadUserProfile(String userId) async {
    try {
      final response = await _client
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return null;
      return _parseUserProfile(response as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[Social] Profil FEHLER: $e');
      return null;
    }
  }

  /// Eigenes Profil laden/erstellen
  Future<UserProfile?> loadOrCreateMyProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      // Versuche Profil zu laden
      var profile = await loadUserProfile(userId);
      if (profile != null) return profile;

      // Erstelle neues Profil
      final response = await _client.rpc('upsert_user_profile', params: {
        'p_display_name': null,
        'p_avatar_url': null,
        'p_bio': null,
      });

      return _parseUserProfile(response as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[Social] Profil laden/erstellen FEHLER: $e');
      return null;
    }
  }

  /// Profil aktualisieren
  Future<UserProfile?> updateProfile({
    String? displayName,
    String? avatarUrl,
    String? bio,
  }) async {
    try {
      final response = await _client.rpc('upsert_user_profile', params: {
        'p_display_name': displayName,
        'p_avatar_url': avatarUrl,
        'p_bio': bio,
      });

      debugPrint('[Social] Profil aktualisiert');
      return _parseUserProfile(response as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[Social] Profil aktualisieren FEHLER: $e');
      return null;
    }
  }

  // ============================================
  // TRIP-FOTO-METHODEN
  // ============================================

  /// Laedt alle Fotos fuer einen Trip
  Future<List<TripPhoto>> loadTripPhotos(String tripId,
      {int limit = 50, int offset = 0}) async {
    debugPrint('[Social] Loading photos for Trip: $tripId');

    try {
      final response = await _client.rpc('get_trip_photos', params: {
        'p_trip_id': tripId,
        'p_limit': limit,
        'p_offset': offset,
      });

      final photos = (response as List)
          .map((row) => TripPhoto.fromJson(row as Map<String, dynamic>))
          .toList();

      debugPrint('[Social] Loaded ${photos.length} trip photos');
      return photos;
    } catch (e) {
      debugPrint('[Social] Load trip photos FEHLER: $e');
      return [];
    }
  }

  /// Laedt ein Trip-Foto hoch
  Future<TripPhoto?> uploadTripPhoto({
    required String tripId,
    required XFile imageFile,
    String? caption,
    int displayOrder = 0,
  }) async {
    if (_currentUserId == null) {
      throw Exception('Not authenticated');
    }

    debugPrint('[Social] Uploading photo for Trip: $tripId');

    try {
      // Bild komprimieren
      final bytes = await _compressImage(imageFile);

      // Unique path generieren
      final fileId = const Uuid().v4();
      final storagePath = '$_currentUserId/$tripId/$fileId.jpg';

      // Upload zu Supabase Storage
      await _client.storage.from(_tripPhotosBucket).uploadBinary(
            storagePath,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: false,
            ),
          );

      debugPrint('[Social] Uploaded to storage: $storagePath');

      // Metadaten in DB speichern via RPC
      final response = await _client.rpc('register_trip_photo', params: {
        'p_trip_id': tripId,
        'p_storage_path': storagePath,
        'p_thumbnail_path': null,
        'p_caption': caption,
        'p_display_order': displayOrder,
      });

      debugPrint('[Social] Trip photo registered in DB');
      return TripPhoto.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[Social] Trip photo upload FEHLER: $e');
      rethrow;
    }
  }

  /// Cover-Bild fuer Trip hochladen und setzen
  Future<String?> uploadTripCoverImage({
    required String tripId,
    required XFile imageFile,
  }) async {
    if (_currentUserId == null) {
      throw Exception('Not authenticated');
    }

    debugPrint('[Social] Uploading cover image for Trip: $tripId');

    try {
      // Bild komprimieren
      final bytes = await _compressImage(imageFile);

      // Unique path generieren
      final fileId = const Uuid().v4();
      final storagePath = '$_currentUserId/$tripId/cover_$fileId.jpg';

      // Upload zu Supabase Storage
      await _client.storage.from(_tripPhotosBucket).uploadBinary(
            storagePath,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: false,
            ),
          );

      debugPrint('[Social] Cover image uploaded: $storagePath');

      // Cover-Pfad in DB setzen
      final success = await _client.rpc('set_trip_cover_image', params: {
        'p_trip_id': tripId,
        'p_storage_path': storagePath,
      });

      if (success == true) {
        debugPrint('[Social] Cover image set in DB');
        return storagePath;
      }
      return null;
    } catch (e) {
      debugPrint('[Social] Cover image upload FEHLER: $e');
      rethrow;
    }
  }

  /// Loescht ein eigenes Trip-Foto
  Future<bool> deleteTripPhoto(String photoId) async {
    if (_currentUserId == null) {
      throw Exception('Not authenticated');
    }

    debugPrint('[Social] Deleting trip photo: $photoId');

    try {
      // Hole Storage-Path
      final photo = await _client
          .from('trip_photos')
          .select('storage_path, user_id')
          .eq('id', photoId)
          .single();

      // Nur eigene Fotos loeschen
      if (photo['user_id'] != _currentUserId) {
        throw Exception('Not authorized to delete this photo');
      }

      // Aus Storage loeschen
      await _client.storage
          .from(_tripPhotosBucket)
          .remove([photo['storage_path']]);

      // Aus DB loeschen via RPC
      final result = await _client.rpc('delete_trip_photo', params: {
        'p_photo_id': photoId,
      });

      debugPrint('[Social] Trip photo deleted');
      return result as bool? ?? false;
    } catch (e) {
      debugPrint('[Social] Delete trip photo FEHLER: $e');
      return false;
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

  /// Generiert die oeffentliche URL fuer ein Trip-Foto
  String getTripPhotoUrl(String storagePath) {
    return '${SupabaseConfig.supabaseUrl}/storage/v1/object/public/$_tripPhotosBucket/$storagePath';
  }

  // ============================================
  // HELPER-METHODEN
  // ============================================

  Future<void> _incrementViews(String tripId) async {
    try {
      await _client.rpc('increment_trip_views', params: {
        'p_trip_id': tripId,
      });
    } catch (e) {
      // Ignorieren - Views sind nicht kritisch
    }
  }

  PublicTrip _parsePublicTripRow(Map<String, dynamic> row) {
    return PublicTrip(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      tripName: row['trip_name'] as String,
      description: row['description'] as String?,
      tripType: row['trip_type'] as String? ?? 'daytrip',
      thumbnailUrl: row['thumbnail_url'] as String?,
      tags: (row['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      region: row['region'] as String?,
      countryCode: row['country_code'] as String?,
      distanceKm: (row['distance_km'] as num?)?.toDouble(),
      durationHours: (row['duration_hours'] as num?)?.toDouble(),
      stopCount: row['stop_count'] as int? ?? 0,
      dayCount: row['day_count'] as int? ?? 1,
      likesCount: row['likes_count'] as int? ?? 0,
      viewsCount: row['views_count'] as int? ?? 0,
      importsCount: row['imports_count'] as int? ?? 0,
      isFeatured: row['is_featured'] as bool? ?? false,
      createdAt: DateTime.parse(row['created_at'] as String),
      authorName: row['author_name'] as String?,
      authorAvatar: row['author_avatar'] as String?,
      authorTotalTrips: row['author_total_trips'] as int?,
      isLikedByMe: row['is_liked_by_me'] as bool? ?? false,
      isImportedByMe: row['is_imported_by_me'] as bool? ?? false,
      tripData: row['trip_data'] as Map<String, dynamic>?,
    );
  }

  PublicTrip _parsePublicTripRowWithProfile(Map<String, dynamic> row) {
    final profile = row['user_profiles'] as Map<String, dynamic>?;
    return PublicTrip(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      tripName: row['trip_name'] as String,
      description: row['description'] as String?,
      tripType: row['trip_type'] as String? ?? 'daytrip',
      thumbnailUrl: row['thumbnail_url'] as String?,
      tags: (row['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      region: row['region'] as String?,
      countryCode: row['country_code'] as String?,
      distanceKm: (row['distance_km'] as num?)?.toDouble(),
      durationHours: (row['duration_hours'] as num?)?.toDouble(),
      stopCount: row['stop_count'] as int? ?? 0,
      dayCount: row['day_count'] as int? ?? 1,
      likesCount: row['likes_count'] as int? ?? 0,
      viewsCount: row['views_count'] as int? ?? 0,
      importsCount: row['imports_count'] as int? ?? 0,
      isFeatured: row['is_featured'] as bool? ?? false,
      createdAt: DateTime.parse(row['created_at'] as String),
      authorName: profile?['display_name'] as String?,
      authorAvatar: profile?['avatar_url'] as String?,
      isLikedByMe: false,
      isImportedByMe: false,
    );
  }

  UserProfile _parseUserProfile(Map<String, dynamic> row) {
    return UserProfile(
      id: row['id'] as String,
      displayName: row['display_name'] as String?,
      avatarUrl: row['avatar_url'] as String?,
      bio: row['bio'] as String?,
      totalKm: (row['total_km'] as num?)?.toDouble() ?? 0,
      totalTrips: row['total_trips'] as int? ?? 0,
      totalPois: row['total_pois'] as int? ?? 0,
      totalLikesReceived: row['total_likes_received'] as int? ?? 0,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  PublicPoiPost _parsePublicPoiRow(Map<String, dynamic> row) {
    return PublicPoiPost.fromJson(row);
  }

  Map<String, dynamic> _tripToJson(Trip trip) {
    return {
      'id': trip.id,
      'name': trip.name,
      'type': trip.type.name,
      'actualDays': trip.actualDays,
      'route': {
        'coordinates': trip.route.coordinates
            .map((c) => {'lat': c.latitude, 'lng': c.longitude})
            .toList(),
        'distanceKm': trip.route.distanceKm,
        'durationMinutes': trip.route.durationMinutes,
      },
      'stops': trip.stops.map((s) {
        return <String, dynamic>{
          'poiId': s.poiId,
          'name': s.name,
          'latitude': s.latitude,
          'longitude': s.longitude,
          'category': s.categoryId,
          'order': s.order,
          'day': s.day,
        };
      }).toList(),
    };
  }
}

/// Provider fuer SocialRepository
@riverpod
SocialRepository socialRepository(SocialRepositoryRef ref) {
  return SocialRepository(Supabase.instance.client);
}
