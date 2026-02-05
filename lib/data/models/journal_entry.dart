import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:latlong2/latlong.dart';

part 'journal_entry.freezed.dart';
part 'journal_entry.g.dart';

/// Ein einzelner Tagebuch-Eintrag (Foto + Text)
@freezed
class JournalEntry with _$JournalEntry {
  const JournalEntry._();

  const factory JournalEntry({
    required String id,
    required String tripId,
    String? poiId,
    String? poiName,
    required DateTime createdAt,
    String? imagePath,
    String? imageUrl,
    String? note,
    double? latitude,
    double? longitude,
    String? locationName,
    int? dayNumber,
  }) = _JournalEntry;

  factory JournalEntry.fromJson(Map<String, dynamic> json) =>
      _$JournalEntryFromJson(json);

  /// Standort als LatLng (computed)
  LatLng? get location {
    if (latitude == null || longitude == null) return null;
    return LatLng(latitude!, longitude!);
  }

  /// Hat dieses Entry ein Bild
  bool get hasImage => imagePath != null || imageUrl != null;

  /// Hat dieses Entry eine Notiz
  bool get hasNote => note != null && note!.isNotEmpty;

  /// Hat dieses Entry einen Standort
  bool get hasLocation => latitude != null && longitude != null;

  /// Formatiertes Datum
  String get formattedDate {
    final day = createdAt.day.toString().padLeft(2, '0');
    final month = createdAt.month.toString().padLeft(2, '0');
    final year = createdAt.year;
    return '$day.$month.$year';
  }

  /// Formatierte Uhrzeit
  String get formattedTime {
    final hour = createdAt.hour.toString().padLeft(2, '0');
    final minute = createdAt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

/// Ein komplettes Reisetagebuch fuer einen Trip
@freezed
class TripJournal with _$TripJournal {
  const TripJournal._();

  const factory TripJournal({
    required String tripId,
    required String tripName,
    required DateTime startDate,
    DateTime? endDate,
    @Default([]) List<JournalEntry> entries,
  }) = _TripJournal;

  factory TripJournal.fromJson(Map<String, dynamic> json) =>
      _$TripJournalFromJson(json);

  /// Anzahl der Eintraege
  int get entryCount => entries.length;

  /// Anzahl der Fotos
  int get photoCount => entries.where((e) => e.hasImage).length;

  /// Eintraege fuer einen bestimmten Tag
  List<JournalEntry> entriesForDay(int dayNumber) {
    return entries.where((e) => e.dayNumber == dayNumber).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  /// Eintraege fuer einen bestimmten POI
  List<JournalEntry> entriesForPOI(String poiId) {
    return entries.where((e) => e.poiId == poiId).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  /// Alle Tage mit Eintraegen (sortiert)
  List<int> get daysWithEntries {
    final days = entries
        .where((e) => e.dayNumber != null)
        .map((e) => e.dayNumber!)
        .toSet()
        .toList();
    days.sort();
    return days;
  }

  /// Ist das Tagebuch leer
  bool get isEmpty => entries.isEmpty;

  /// Hat das Tagebuch Eintraege
  bool get isNotEmpty => entries.isNotEmpty;
}
