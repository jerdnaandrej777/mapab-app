import 'package:freezed_annotation/freezed_annotation.dart';

part 'journal.freezed.dart';
part 'journal.g.dart';

/// Reisetagebuch-Eintrag
@freezed
class JournalEntry with _$JournalEntry {
  const factory JournalEntry({
    required String id,
    required String tripId,
    required DateTime timestamp,
    String? poiId,
    String? poiName,
    double? latitude,
    double? longitude,
    String? title,
    String? content,
    @Default([]) List<String> photoUrls,
    @Default([]) List<String> localPhotoPaths,
    int? rating,  // 1-5 Sterne
    String? mood,  // happy, neutral, tired, excited, etc.
    @Default({}) Map<String, dynamic> metadata,
  }) = _JournalEntry;

  const JournalEntry._();

  bool get hasPhotos => photoUrls.isNotEmpty || localPhotoPaths.isNotEmpty;
  bool get hasContent => content?.isNotEmpty == true;
  bool get hasLocation => latitude != null && longitude != null;

  /// Formatierter Zeitstempel
  String get formattedTime {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Formatiertes Datum
  String get formattedDate {
    final day = timestamp.day.toString().padLeft(2, '0');
    final month = timestamp.month.toString().padLeft(2, '0');
    final year = timestamp.year;
    return '$day.$month.$year';
  }

  /// Mood-Emoji
  String get moodEmoji {
    switch (mood) {
      case 'happy': return '😊';
      case 'excited': return '🤩';
      case 'relaxed': return '😌';
      case 'tired': return '😴';
      case 'hungry': return '🍽️';
      case 'amazed': return '🤯';
      case 'romantic': return '💕';
      case 'adventurous': return '🏔️';
      default: return '📝';
    }
  }

  factory JournalEntry.fromJson(Map<String, dynamic> json) =>
      _$JournalEntryFromJson(json);
}

/// Komplettes Reisetagebuch für einen Trip
@freezed
class TripJournal with _$TripJournal {
  const factory TripJournal({
    required String tripId,
    required String tripName,
    @Default([]) List<JournalEntry> entries,
    String? coverPhotoUrl,
    DateTime? startDate,
    DateTime? endDate,
    @Default([]) List<String> tags,
    String? summary,
  }) = _TripJournal;

  const TripJournal._();

  /// Sortierte Einträge nach Zeit
  List<JournalEntry> get sortedEntries {
    final sorted = List<JournalEntry>.from(entries);
    sorted.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return sorted;
  }

  /// Einträge gruppiert nach Tag
  Map<String, List<JournalEntry>> get entriesByDay {
    final result = <String, List<JournalEntry>>{};
    for (final entry in sortedEntries) {
      final key = entry.formattedDate;
      result.putIfAbsent(key, () => []).add(entry);
    }
    return result;
  }

  /// Alle Fotos
  List<String> get allPhotos {
    return entries
        .expand((e) => [...e.photoUrls, ...e.localPhotoPaths])
        .toList();
  }

  /// Anzahl der Tage
  int get durationDays {
    if (startDate == null || endDate == null) {
      if (entries.isEmpty) return 0;
      final first = sortedEntries.first.timestamp;
      final last = sortedEntries.last.timestamp;
      return last.difference(first).inDays + 1;
    }
    return endDate!.difference(startDate!).inDays + 1;
  }

  /// Durchschnittliche Bewertung
  double get averageRating {
    final rated = entries.where((e) => e.rating != null);
    if (rated.isEmpty) return 0;
    return rated.map((e) => e.rating!).reduce((a, b) => a + b) / rated.length;
  }

  factory TripJournal.fromJson(Map<String, dynamic> json) =>
      _$TripJournalFromJson(json);
}

/// Stimmungs-Optionen
class JournalMoods {
  static const List<String> all = [
    'happy',
    'excited',
    'relaxed',
    'tired',
    'hungry',
    'amazed',
    'romantic',
    'adventurous',
  ];

  static String emoji(String mood) {
    switch (mood) {
      case 'happy': return '😊';
      case 'excited': return '🤩';
      case 'relaxed': return '😌';
      case 'tired': return '😴';
      case 'hungry': return '🍽️';
      case 'amazed': return '🤯';
      case 'romantic': return '💕';
      case 'adventurous': return '🏔️';
      default: return '📝';
    }
  }

  static String label(String mood) {
    switch (mood) {
      case 'happy': return 'Fröhlich';
      case 'excited': return 'Aufgeregt';
      case 'relaxed': return 'Entspannt';
      case 'tired': return 'Müde';
      case 'hungry': return 'Hungrig';
      case 'amazed': return 'Begeistert';
      case 'romantic': return 'Romantisch';
      case 'adventurous': return 'Abenteuerlustig';
      default: return mood;
    }
  }
}
