import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase/supabase_client.dart';
import '../models/poi.dart';
import '../models/route.dart';
import '../models/trip.dart';

part 'sync_service.g.dart';

/// Sync-Fehler mit Kontext
class SyncError {
  final String operation;
  final String message;
  final DateTime timestamp;

  SyncError({
    required this.operation,
    required this.message,
  }) : timestamp = DateTime.now();

  @override
  String toString() => '[$operation] $message';
}

/// Service für Cloud-Synchronisation mit Supabase
class SyncService {
  final SupabaseClient? _client;

  SyncService(this._client);

  /// Letzter aufgetretener Fehler (für UI-Feedback)
  SyncError? _lastError;
  SyncError? get lastError => _lastError;

  /// Setzt den letzten Fehler zurück
  void clearLastError() => _lastError = null;

  /// Prüft ob Sync verfügbar ist
  bool get isAvailable => _client != null && isAuthenticated;

  /// Gibt die aktuelle User-ID zurück, oder null wenn nicht eingeloggt
  String? get _userId => currentUser?.id;

  // ============================================
  // TRIPS
  // ============================================

  /// Speichert Trip in der Cloud
  Future<String?> saveTrip({
    required String name,
    required AppRoute route,
    List<TripStop> stops = const [],
    bool isFavorite = false,
  }) async {
    if (!isAvailable) return null;
    final userId = _userId;
    if (userId == null) return null;

    debugPrint('[Sync] Speichere Trip: $name');

    try {
      final tripData = {
        'user_id': userId,
        'name': name,
        'start_lat': route.start.latitude,
        'start_lng': route.start.longitude,
        'start_address': route.startAddress,
        'end_lat': route.end.latitude,
        'end_lng': route.end.longitude,
        'end_address': route.endAddress,
        'distance_km': route.distanceKm,
        'duration_minutes': route.durationMinutes,
        'route_geometry': _encodeCoordinates(route.coordinates),
        'is_favorite': isFavorite,
      };

      final response = await _client!
          .from('trips')
          .insert(tripData)
          .select('id')
          .single();

      final tripId = response['id'] as String;

      // Stops speichern
      if (stops.isNotEmpty) {
        final stopsData = stops.asMap().entries.map((entry) => {
              'trip_id': tripId,
              'poi_id': entry.value.poiId,
              'name': entry.value.name,
              'latitude': entry.value.latitude,
              'longitude': entry.value.longitude,
              'category_id': entry.value.categoryId,
              'stop_order': entry.key,
            }).toList();

        await _client!.from('trip_stops').insert(stopsData);
      }

      debugPrint('[Sync] ✓ Trip gespeichert: $tripId');
      return tripId;
    } catch (e) {
      _lastError = SyncError(operation: 'saveTrip', message: '$e');
      debugPrint('[Sync] ✗ Fehler beim Speichern: $e');
      return null;
    }
  }

  /// Lädt alle Trips des Users
  Future<List<Map<String, dynamic>>> loadTrips() async {
    if (!isAvailable) return [];
    final userId = _userId;
    if (userId == null) return [];

    debugPrint('[Sync] Lade Trips...');

    try {
      final response = await _client!
          .from('trips')
          .select('*, trip_stops(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      debugPrint('[Sync] ✓ ${response.length} Trips geladen');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      _lastError = SyncError(operation: 'loadTrips', message: '$e');
      debugPrint('[Sync] ✗ Fehler beim Laden: $e');
      return [];
    }
  }

  /// Markiert Trip als abgeschlossen
  Future<Map<String, dynamic>?> completeTrip(String tripId) async {
    if (!isAvailable) return null;

    debugPrint('[Sync] Schließe Trip ab: $tripId');

    try {
      final response = await _client!
          .rpc('complete_trip', params: {'p_trip_id': tripId})
          .single();

      debugPrint('[Sync] ✓ Trip abgeschlossen, XP: ${response['xp_earned']}');
      return Map<String, dynamic>.from(response);
    } catch (e) {
      _lastError = SyncError(operation: 'completeTrip', message: '$e');
      debugPrint('[Sync] ✗ Fehler: $e');
      return null;
    }
  }

  /// Löscht Trip
  Future<bool> deleteTrip(String tripId) async {
    if (!isAvailable) return false;

    try {
      await _client!.from('trips').delete().eq('id', tripId);
      debugPrint('[Sync] ✓ Trip gelöscht: $tripId');
      return true;
    } catch (e) {
      _lastError = SyncError(operation: 'deleteTrip', message: '$e');
      debugPrint('[Sync] ✗ Fehler: $e');
      return false;
    }
  }

  // ============================================
  // FAVORITE POIs
  // ============================================

  /// Speichert POI als Favorit
  Future<bool> saveFavoritePOI(POI poi) async {
    if (!isAvailable) return false;
    final userId = _userId;
    if (userId == null) return false;

    debugPrint('[Sync] Speichere Favorit: ${poi.name}');

    try {
      await _client!.from('favorite_pois').upsert({
        'user_id': userId,
        'poi_id': poi.id,
        'name': poi.name,
        'latitude': poi.latitude,
        'longitude': poi.longitude,
        'category_id': poi.categoryId,
        'image_url': poi.imageUrl,
      });

      debugPrint('[Sync] ✓ Favorit gespeichert');
      return true;
    } catch (e) {
      _lastError = SyncError(operation: 'saveFavoritePOI', message: '$e');
      debugPrint('[Sync] ✗ Fehler: $e');
      return false;
    }
  }

  /// Entfernt POI aus Favoriten
  Future<bool> removeFavoritePOI(String poiId) async {
    if (!isAvailable) return false;
    final userId = _userId;
    if (userId == null) return false;

    try {
      await _client!
          .from('favorite_pois')
          .delete()
          .eq('user_id', userId)
          .eq('poi_id', poiId);

      debugPrint('[Sync] ✓ Favorit entfernt: $poiId');
      return true;
    } catch (e) {
      _lastError = SyncError(operation: 'removeFavoritePOI', message: '$e');
      debugPrint('[Sync] ✗ Fehler: $e');
      return false;
    }
  }

  /// Lädt alle Favoriten-POIs
  Future<List<Map<String, dynamic>>> loadFavoritePOIs() async {
    if (!isAvailable) return [];
    final userId = _userId;
    if (userId == null) return [];

    debugPrint('[Sync] Lade Favoriten...');

    try {
      final response = await _client!
          .from('favorite_pois')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      debugPrint('[Sync] ✓ ${response.length} Favoriten geladen');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      _lastError = SyncError(operation: 'loadFavoritePOIs', message: '$e');
      debugPrint('[Sync] ✗ Fehler: $e');
      return [];
    }
  }

  // ============================================
  // USER PROFILE & STATS
  // ============================================

  /// Lädt User-Profil
  Future<Map<String, dynamic>?> loadUserProfile() async {
    if (!isAvailable) return null;
    final userId = _userId;
    if (userId == null) return null;

    try {
      final response = await _client!
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      return Map<String, dynamic>.from(response);
    } catch (e) {
      _lastError = SyncError(operation: 'loadUserProfile', message: '$e');
      debugPrint('[Sync] ✗ Profil laden fehlgeschlagen: $e');
      return null;
    }
  }

  /// Aktualisiert User-Profil
  Future<bool> updateUserProfile({
    String? username,
    String? displayName,
    String? avatarUrl,
  }) async {
    if (!isAvailable) return false;

    try {
      final updates = <String, dynamic>{};
      if (username != null) updates['username'] = username;
      if (displayName != null) updates['display_name'] = displayName;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

      final userId = _userId;
      if (userId == null) return false;

      if (updates.isNotEmpty) {
        await _client!
            .from('users')
            .update(updates)
            .eq('id', userId);
      }

      return true;
    } catch (e) {
      _lastError = SyncError(operation: 'updateUserProfile', message: '$e');
      debugPrint('[Sync] ✗ Profil-Update fehlgeschlagen: $e');
      return false;
    }
  }

  // ============================================
  // ACHIEVEMENTS
  // ============================================

  /// Lädt User-Achievements
  Future<List<Map<String, dynamic>>> loadAchievements() async {
    if (!isAvailable) return [];

    try {
      final userId = _userId;
      if (userId == null) return [];

      final response = await _client!
          .from('user_achievements')
          .select()
          .eq('user_id', userId);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      _lastError = SyncError(operation: 'loadAchievements', message: '$e');
      debugPrint('[Sync] ✗ Achievements laden fehlgeschlagen: $e');
      return [];
    }
  }

  // ============================================
  // HELPERS
  // ============================================

  /// Encodiert Koordinaten für Speicherung
  String _encodeCoordinates(List<LatLng> coordinates) {
    return coordinates.map((c) => '${c.latitude},${c.longitude}').join(';');
  }

  /// Decodiert Koordinaten
  List<LatLng> decodeCoordinates(String encoded) {
    if (encoded.isEmpty) return [];
    try {
      return encoded.split(';').where((s) => s.contains(',')).map((s) {
        final parts = s.split(',');
        return LatLng(double.parse(parts[0]), double.parse(parts[1]));
      }).toList();
    } catch (e) {
      debugPrint('[Sync] Fehler beim Dekodieren der Koordinaten: $e');
      return [];
    }
  }
}

/// Provider für Sync Service
@riverpod
SyncService syncService(SyncServiceRef ref) {
  final client = ref.watch(supabaseProvider);
  return SyncService(client);
}
