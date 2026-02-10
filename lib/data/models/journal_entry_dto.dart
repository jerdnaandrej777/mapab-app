import 'journal_entry.dart';

/// Data Transfer Object für Journal Entries zwischen Supabase und App
///
/// Mappt zwischen Supabase snake_case Spalten und Dart camelCase Models
class JournalEntryDTO {
  final String id;
  final String userId;
  final String tripId;
  final String tripName;
  final String? poiId;
  final String? poiName;
  final String? note;
  final double? latitude;
  final double? longitude;
  final int? dayNumber;
  final bool hasPhoto;
  final String? photoStoragePath;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? syncedAt;

  const JournalEntryDTO({
    required this.id,
    required this.userId,
    required this.tripId,
    required this.tripName,
    this.poiId,
    this.poiName,
    this.note,
    this.latitude,
    this.longitude,
    this.dayNumber,
    this.hasPhoto = false,
    this.photoStoragePath,
    required this.createdAt,
    required this.updatedAt,
    this.syncedAt,
  });

  /// Erstelle DTO aus Supabase JSON (snake_case)
  factory JournalEntryDTO.fromJson(Map<String, dynamic> json) {
    return JournalEntryDTO(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      tripId: json['trip_id'] as String,
      tripName: json['trip_name'] as String,
      poiId: json['poi_id'] as String?,
      poiName: json['poi_name'] as String?,
      note: json['note'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      dayNumber: json['day_number'] as int?,
      hasPhoto: json['has_photo'] as bool? ?? false,
      photoStoragePath: json['photo_storage_path'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      syncedAt: json['synced_at'] != null
          ? DateTime.parse(json['synced_at'] as String)
          : null,
    );
  }

  /// Konvertiere DTO zu Supabase JSON (snake_case)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'trip_id': tripId,
      'trip_name': tripName,
      'poi_id': poiId,
      'poi_name': poiName,
      'note': note,
      'latitude': latitude,
      'longitude': longitude,
      'day_number': dayNumber,
      'has_photo': hasPhoto,
      'photo_storage_path': photoStoragePath,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'synced_at': syncedAt?.toIso8601String(),
    };
  }

  /// Konvertiere DTO zu App-Model (JournalEntry)
  JournalEntry toModel() {
    return JournalEntry(
      id: id,
      tripId: tripId,
      poiId: poiId,
      poiName: poiName,
      createdAt: createdAt,
      imagePath: null, // Local path nicht von Cloud
      photoStoragePath: photoStoragePath,
      note: note,
      latitude: latitude,
      longitude: longitude,
      locationName: null, // Wird lokal gesetzt
      dayNumber: dayNumber,
      syncedAt: syncedAt,
      needsSync: false, // Von Cloud geladene Entries sind synced
    );
  }

  /// Erstelle DTO aus App-Model
  factory JournalEntryDTO.fromModel({
    required JournalEntry entry,
    required String userId,
  }) {
    return JournalEntryDTO(
      id: entry.id,
      userId: userId,
      tripId: entry.tripId,
      tripName: '', // Wird separat gesetzt
      poiId: entry.poiId,
      poiName: entry.poiName,
      note: entry.note,
      latitude: entry.latitude,
      longitude: entry.longitude,
      dayNumber: entry.dayNumber,
      hasPhoto: entry.hasImage,
      photoStoragePath: entry.photoStoragePath,
      createdAt: entry.createdAt,
      updatedAt: DateTime.now(),
      syncedAt: DateTime.now(),
    );
  }
}
