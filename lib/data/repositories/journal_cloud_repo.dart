import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/journal_entry.dart';
import '../models/journal_entry_dto.dart';

/// Repository für Journal-Cloud-Synchronisation mit Supabase
///
/// Verantwortlich für:
/// - Upload/Download von Journal-Einträgen
/// - Upload/Delete von Fotos zu Supabase Storage
/// - RPC-Aufrufe für Journal-Übersichten
class JournalCloudRepo {
  final SupabaseClient _supabase;
  static const String _bucketName = 'journal-photos';
  static const int _maxImageSize = 1920;
  static const int _imageQuality = 85;

  JournalCloudRepo(this._supabase);

  String? get _currentUserId => _supabase.auth.currentUser?.id;

  // ============================================
  // ENTRY OPERATIONS
  // ============================================

  /// Upload/Update Journal Entry (ohne Foto)
  Future<JournalEntryDTO?> uploadEntry({
    required JournalEntry entry,
    required String tripName,
  }) async {
    final userId = _currentUserId;
    if (userId == null) {
      debugPrint('[JournalCloudRepo] Not authenticated');
      return null;
    }

    try {
      final dto = JournalEntryDTO.fromModel(entry: entry, userId: userId);

      final response = await _supabase
          .from('journal_entries')
          .upsert({
            'id': dto.id,
            'user_id': dto.userId,
            'trip_id': dto.tripId,
            'trip_name': tripName,
            'poi_id': dto.poiId,
            'poi_name': dto.poiName,
            'note': dto.note,
            'latitude': dto.latitude,
            'longitude': dto.longitude,
            'day_number': dto.dayNumber,
            'has_photo': dto.hasPhoto,
            'photo_storage_path': dto.photoStoragePath,
            'synced_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      debugPrint('[JournalCloudRepo] Entry uploaded: ${entry.id}');
      return JournalEntryDTO.fromJson(response);
    } catch (e) {
      debugPrint('[JournalCloudRepo] Upload entry failed: $e');
      return null;
    }
  }

  /// Fetch alle Einträge eines Trips
  Future<List<JournalEntry>> fetchEntriesForTrip(String tripId) async {
    final userId = _currentUserId;
    if (userId == null) {
      debugPrint('[JournalCloudRepo] Not authenticated');
      return [];
    }

    try {
      final response = await _supabase.rpc('get_journal_entries_for_trip',
          params: {
            'p_user_id': userId,
            'p_trip_id': tripId,
          });

      final list = response as List;
      final entries = list.map((json) {
        return JournalEntryDTO.fromJson(json as Map<String, dynamic>)
            .toModel();
      }).toList();

      debugPrint(
          '[JournalCloudRepo] Fetched ${entries.length} entries for trip: $tripId');
      return entries;
    } catch (e) {
      debugPrint('[JournalCloudRepo] Fetch entries failed: $e');
      return [];
    }
  }

  /// Fetch alle Journals (Trip-Übersicht)
  Future<List<Map<String, dynamic>>> fetchAllJournals() async {
    final userId = _currentUserId;
    if (userId == null) {
      debugPrint('[JournalCloudRepo] Not authenticated');
      return [];
    }

    try {
      final response = await _supabase
          .rpc('get_user_journals', params: {'p_user_id': userId});

      final list = response as List;
      final journals = list
          .map((json) => Map<String, dynamic>.from(json as Map))
          .toList();

      debugPrint('[JournalCloudRepo] Fetched ${journals.length} journals');
      return journals;
    } catch (e) {
      debugPrint('[JournalCloudRepo] Fetch journals failed: $e');
      return [];
    }
  }

  /// Lösche Entry und zugehöriges Foto
  Future<bool> deleteEntry(String entryId) async {
    final userId = _currentUserId;
    if (userId == null) {
      debugPrint('[JournalCloudRepo] Not authenticated');
      return false;
    }

    try {
      // Hole Entry um photo_storage_path zu finden
      final entry = await _supabase
          .from('journal_entries')
          .select()
          .eq('id', entryId)
          .eq('user_id', userId)
          .maybeSingle();

      // Lösche Foto aus Storage falls vorhanden
      if (entry != null && entry['photo_storage_path'] != null) {
        final photoPath = _extractStoragePath(entry['photo_storage_path']);
        if (photoPath != null) {
          try {
            await _supabase.storage.from(_bucketName).remove([photoPath]);
            debugPrint('[JournalCloudRepo] Photo deleted: $photoPath');
          } catch (e) {
            debugPrint('[JournalCloudRepo] Photo delete failed: $e');
            // Continue with entry deletion even if photo delete fails
          }
        }
      }

      // Lösche Entry aus Datenbank
      await _supabase
          .from('journal_entries')
          .delete()
          .eq('id', entryId)
          .eq('user_id', userId);

      debugPrint('[JournalCloudRepo] Entry deleted: $entryId');
      return true;
    } catch (e) {
      debugPrint('[JournalCloudRepo] Delete entry failed: $e');
      return false;
    }
  }

  /// Lösche komplettes Journal (alle Entries eines Trips)
  Future<int> deleteJournal(String tripId) async {
    final userId = _currentUserId;
    if (userId == null) {
      debugPrint('[JournalCloudRepo] Not authenticated');
      return 0;
    }

    try {
      final deletedCount = await _supabase.rpc('delete_journal', params: {
        'p_user_id': userId,
        'p_trip_id': tripId,
      }) as int;

      debugPrint('[JournalCloudRepo] Journal deleted: $tripId ($deletedCount entries)');
      return deletedCount;
    } catch (e) {
      debugPrint('[JournalCloudRepo] Delete journal failed: $e');
      return 0;
    }
  }

  // ============================================
  // PHOTO OPERATIONS
  // ============================================

  /// Upload Foto zu Supabase Storage
  Future<String?> uploadPhoto({
    required String entryId,
    required String tripId,
    required File imageFile,
  }) async {
    final userId = _currentUserId;
    if (userId == null) {
      debugPrint('[JournalCloudRepo] Not authenticated');
      return null;
    }

    try {
      // Komprimiere Foto (1920px max, 85% Qualität)
      final compressed = await _compressImage(imageFile);

      // Storage path: journal-photos/{user_id}/{trip_id}/{entry_id}.jpg
      final storagePath = '$userId/$tripId/$entryId.jpg';

      // Upload zu Supabase Storage
      await _supabase.storage.from(_bucketName).uploadBinary(
            storagePath,
            compressed,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      debugPrint('[JournalCloudRepo] Photo uploaded: $storagePath');

      // Generiere Public URL (auch wenn Bucket privat ist, URL wird für RLS benötigt)
      final photoUrl =
          _supabase.storage.from(_bucketName).getPublicUrl(storagePath);

      // Update Entry mit photo path
      await _supabase.from('journal_entries').update({
        'has_photo': true,
        'photo_storage_path': photoUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', entryId).eq('user_id', userId);

      return photoUrl;
    } catch (e) {
      debugPrint('[JournalCloudRepo] Photo upload failed: $e');
      return null;
    }
  }

  /// Komprimiere Bild auf max 1920px und 85% Qualität
  Future<Uint8List> _compressImage(File imageFile) async {
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

  // ============================================
  // HELPER METHODS
  // ============================================

  /// Extrahiere Storage-Pfad aus vollständiger URL
  ///
  /// Von: https://supabase.co/storage/v1/object/public/journal-photos/user_id/trip_id/entry_id.jpg
  /// Zu: user_id/trip_id/entry_id.jpg
  String? _extractStoragePath(String photoUrl) {
    try {
      final uri = Uri.parse(photoUrl);
      final pathSegments = uri.pathSegments;

      // Format: /storage/v1/object/public/journal-photos/{user_id}/{trip_id}/{entry_id}.jpg
      // Wir brauchen: {user_id}/{trip_id}/{entry_id}.jpg
      final bucketIndex = pathSegments.indexOf(_bucketName);
      if (bucketIndex != -1 && bucketIndex < pathSegments.length - 1) {
        return pathSegments.skip(bucketIndex + 1).join('/');
      }

      return null;
    } catch (e) {
      debugPrint('[JournalCloudRepo] Extract storage path failed: $e');
      return null;
    }
  }

  /// Prüfe ob Cloud-Daten neuer sind als lokale
  Future<DateTime?> getLastSyncTime(String tripId) async {
    final userId = _currentUserId;
    if (userId == null) return null;

    try {
      final response = await _supabase
          .from('journal_entries')
          .select('updated_at')
          .eq('user_id', userId)
          .eq('trip_id', tripId)
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        return DateTime.parse(response['updated_at'] as String);
      }
      return null;
    } catch (e) {
      debugPrint('[JournalCloudRepo] Get last sync time failed: $e');
      return null;
    }
  }
}
