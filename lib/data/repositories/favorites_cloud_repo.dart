import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/categories.dart';
import '../models/poi.dart';
import '../models/trip.dart';

/// Repository fuer Favoriten-Cloud-Synchronisation mit Supabase.
///
/// Verantwortlich fuer:
/// - Upload/Download von gespeicherten Routen (favorite_trips)
/// - Upload/Download von favorisierten POIs (favorite_pois)
/// - Bidirektionaler Sync: Hive (offline) ↔ Supabase (cloud)
class FavoritesCloudRepo {
  final SupabaseClient _supabase;

  FavoritesCloudRepo(this._supabase);

  String? get _currentUserId => _supabase.auth.currentUser?.id;

  // ============================================
  // TRIP OPERATIONS
  // ============================================

  /// Upload/Update Trip in der Cloud (UPSERT)
  Future<bool> uploadTrip(Trip trip) async {
    final userId = _currentUserId;
    if (userId == null) {
      debugPrint('[FavCloud] Not authenticated');
      return false;
    }

    try {
      await _supabase.from('favorite_trips').upsert({
        'user_id': userId,
        'trip_id': trip.id,
        'trip_name': trip.name,
        'trip_data': trip.toJson(),
        'trip_type': trip.type == TripType.eurotrip ? 'eurotrip' : 'daytrip',
        'distance_km': trip.route.distanceKm,
        'stop_count': trip.stops.length,
      });

      debugPrint('[FavCloud] Trip uploaded: ${trip.name}');
      return true;
    } catch (e) {
      debugPrint('[FavCloud] Upload trip failed: $e');
      return false;
    }
  }

  /// Loesche Trip aus der Cloud
  Future<bool> deleteTrip(String tripId) async {
    final userId = _currentUserId;
    if (userId == null) {
      debugPrint('[FavCloud] Not authenticated');
      return false;
    }

    try {
      await _supabase
          .from('favorite_trips')
          .delete()
          .eq('user_id', userId)
          .eq('trip_id', tripId);

      debugPrint('[FavCloud] Trip deleted: $tripId');
      return true;
    } catch (e) {
      debugPrint('[FavCloud] Delete trip failed: $e');
      return false;
    }
  }

  /// Lade alle Favoriten-Trips aus der Cloud
  Future<List<Trip>> fetchAllTrips() async {
    final userId = _currentUserId;
    if (userId == null) {
      debugPrint('[FavCloud] Not authenticated');
      return [];
    }

    try {
      final response = await _supabase.rpc(
        'get_user_favorite_trips',
        params: {'p_user_id': userId},
      );

      final list = response as List;
      final trips = <Trip>[];

      for (final row in list) {
        try {
          final tripData = row['trip_data'];
          if (tripData == null) continue;

          final json = Map<String, dynamic>.from(tripData as Map);
          trips.add(Trip.fromJson(json));
        } catch (e) {
          debugPrint('[FavCloud] Parse trip failed: $e');
        }
      }

      debugPrint('[FavCloud] Fetched ${trips.length} trips');
      return trips;
    } catch (e) {
      debugPrint('[FavCloud] Fetch trips failed: $e');
      return [];
    }
  }

  // ============================================
  // POI OPERATIONS
  // ============================================

  /// Upload/Update POI-Favorit in der Cloud (UPSERT)
  Future<bool> uploadPOI(POI poi) async {
    final userId = _currentUserId;
    if (userId == null) {
      debugPrint('[FavCloud] Not authenticated');
      return false;
    }

    try {
      await _supabase.from('favorite_pois').upsert({
        'user_id': userId,
        'poi_id': poi.id,
        'name': poi.name,
        'latitude': poi.latitude,
        'longitude': poi.longitude,
        'category_id': poi.categoryId,
        'image_url': poi.imageUrl,
      });

      debugPrint('[FavCloud] POI uploaded: ${poi.name}');
      return true;
    } catch (e) {
      debugPrint('[FavCloud] Upload POI failed: $e');
      return false;
    }
  }

  /// Loesche POI-Favorit aus der Cloud
  Future<bool> deletePOI(String poiId) async {
    final userId = _currentUserId;
    if (userId == null) {
      debugPrint('[FavCloud] Not authenticated');
      return false;
    }

    try {
      await _supabase
          .from('favorite_pois')
          .delete()
          .eq('user_id', userId)
          .eq('poi_id', poiId);

      debugPrint('[FavCloud] POI deleted: $poiId');
      return true;
    } catch (e) {
      debugPrint('[FavCloud] Delete POI failed: $e');
      return false;
    }
  }

  /// Lade alle Favoriten-POIs aus der Cloud
  Future<List<POI>> fetchAllPOIs() async {
    final userId = _currentUserId;
    if (userId == null) {
      debugPrint('[FavCloud] Not authenticated');
      return [];
    }

    try {
      final response = await _supabase.rpc(
        'get_user_favorite_pois',
        params: {'p_user_id': userId},
      );

      final list = response as List;
      final pois = <POI>[];

      for (final row in list) {
        try {
          final map = Map<String, dynamic>.from(row as Map);
          pois.add(POI(
            id: map['poi_id'] as String,
            name: map['name'] as String,
            latitude: (map['latitude'] as num).toDouble(),
            longitude: (map['longitude'] as num).toDouble(),
            categoryId: (map['category_id'] as String?) ?? 'attraction',
            imageUrl: map['image_url'] as String?,
          ));
        } catch (e) {
          debugPrint('[FavCloud] Parse POI failed: $e');
        }
      }

      debugPrint('[FavCloud] Fetched ${pois.length} POIs');
      return pois;
    } catch (e) {
      debugPrint('[FavCloud] Fetch POIs failed: $e');
      return [];
    }
  }

  // ============================================
  // BATCH OPERATIONS
  // ============================================

  /// Upload alle lokalen Trips zur Cloud (fuer Migration)
  Future<int> uploadAllTrips(List<Trip> trips) async {
    int uploaded = 0;
    for (final trip in trips) {
      final success = await uploadTrip(trip);
      if (success) uploaded++;
      // Rate-Limit-Schutz
      if (trips.length > 5) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
    debugPrint('[FavCloud] Batch uploaded $uploaded/${trips.length} trips');
    return uploaded;
  }

  /// Upload alle lokalen POIs zur Cloud (fuer Migration)
  Future<int> uploadAllPOIs(List<POI> pois) async {
    int uploaded = 0;
    for (final poi in pois) {
      final success = await uploadPOI(poi);
      if (success) uploaded++;
      if (pois.length > 10) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
    debugPrint('[FavCloud] Batch uploaded $uploaded/${pois.length} POIs');
    return uploaded;
  }
}
