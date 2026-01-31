import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../models/journal.dart';

part 'journal_provider.g.dart';

/// Journal Provider für Reisetagebuch-Verwaltung
@Riverpod(keepAlive: true)
class JournalNotifier extends _$JournalNotifier {
  late Box _journalBox;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  Map<String, TripJournal> build() {
    _journalBox = Hive.box('settings');
    return _loadJournals();
  }

  Map<String, TripJournal> _loadJournals() {
    final json = _journalBox.get('journals');
    if (json != null) {
      try {
        final map = Map<String, dynamic>.from(json);
        return map.map((key, value) =>
            MapEntry(key, TripJournal.fromJson(Map<String, dynamic>.from(value))));
      } catch (e) {
        debugPrint('[Journal] Laden fehlgeschlagen: $e');
      }
    }
    return {};
  }

  Future<void> _saveJournals() async {
    final json = state.map((key, value) => MapEntry(key, value.toJson()));
    await _journalBox.put('journals', json);
  }

  /// Holt oder erstellt Journal für einen Trip
  TripJournal getOrCreateJournal(String tripId, String tripName) {
    if (state.containsKey(tripId)) {
      return state[tripId]!;
    }

    final journal = TripJournal(
      tripId: tripId,
      tripName: tripName,
    );

    state = {...state, tripId: journal};
    _saveJournals();
    return journal;
  }

  /// Fügt einen neuen Eintrag hinzu
  Future<void> addEntry({
    required String tripId,
    required String tripName,
    String? poiId,
    String? poiName,
    double? latitude,
    double? longitude,
    String? title,
    String? content,
    List<String>? photoUrls,
    List<String>? localPhotoPaths,
    int? rating,
    String? mood,
  }) async {
    final journal = getOrCreateJournal(tripId, tripName);

    final entry = JournalEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      tripId: tripId,
      timestamp: DateTime.now(),
      poiId: poiId,
      poiName: poiName,
      latitude: latitude,
      longitude: longitude,
      title: title,
      content: content,
      photoUrls: photoUrls ?? [],
      localPhotoPaths: localPhotoPaths ?? [],
      rating: rating,
      mood: mood,
    );

    final updatedJournal = journal.copyWith(
      entries: [...journal.entries, entry],
    );

    state = {...state, tripId: updatedJournal};
    await _saveJournals();
  }

  /// Aktualisiert einen bestehenden Eintrag
  Future<void> updateEntry(String tripId, JournalEntry updatedEntry) async {
    final journal = state[tripId];
    if (journal == null) return;

    final updatedEntries = journal.entries.map((e) =>
        e.id == updatedEntry.id ? updatedEntry : e
    ).toList();

    final updatedJournal = journal.copyWith(entries: updatedEntries);
    state = {...state, tripId: updatedJournal};
    await _saveJournals();
  }

  /// Löscht einen Eintrag
  Future<void> deleteEntry(String tripId, String entryId) async {
    final journal = state[tripId];
    if (journal == null) return;

    final updatedEntries = journal.entries
        .where((e) => e.id != entryId)
        .toList();

    final updatedJournal = journal.copyWith(entries: updatedEntries);
    state = {...state, tripId: updatedJournal};
    await _saveJournals();
  }

  /// Setzt Cover-Foto für Journal
  Future<void> setCoverPhoto(String tripId, String photoUrl) async {
    final journal = state[tripId];
    if (journal == null) return;

    final updatedJournal = journal.copyWith(coverPhotoUrl: photoUrl);
    state = {...state, tripId: updatedJournal};
    await _saveJournals();
  }

  /// Setzt Tags für Journal
  Future<void> setTags(String tripId, List<String> tags) async {
    final journal = state[tripId];
    if (journal == null) return;

    final updatedJournal = journal.copyWith(tags: tags);
    state = {...state, tripId: updatedJournal};
    await _saveJournals();
  }

  /// Setzt Zusammenfassung für Journal
  Future<void> setSummary(String tripId, String summary) async {
    final journal = state[tripId];
    if (journal == null) return;

    final updatedJournal = journal.copyWith(summary: summary);
    state = {...state, tripId: updatedJournal};
    await _saveJournals();
  }

  /// Löscht gesamtes Journal
  Future<void> deleteJournal(String tripId) async {
    state = Map.from(state)..remove(tripId);
    await _saveJournals();
  }

  /// Wählt Foto aus Galerie
  Future<List<String>?> pickPhotosFromGallery({int maxImages = 5}) async {
    try {
      final images = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (images.isEmpty) return null;

      return images.take(maxImages).map((img) => img.path).toList();
    } catch (e) {
      debugPrint('[Journal] Foto-Auswahl fehlgeschlagen: $e');
      return null;
    }
  }

  /// Nimmt Foto mit Kamera auf
  Future<String?> takePhoto() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      return image?.path;
    } catch (e) {
      debugPrint('[Journal] Kamera-Fehler: $e');
      return null;
    }
  }

  /// Exportiert Journal als Text
  String exportAsText(String tripId) {
    final journal = state[tripId];
    if (journal == null) return '';

    final buffer = StringBuffer();
    buffer.writeln('# ${journal.tripName}');
    buffer.writeln('');

    if (journal.summary != null) {
      buffer.writeln(journal.summary);
      buffer.writeln('');
    }

    for (final dayEntry in journal.entriesByDay.entries) {
      buffer.writeln('## ${dayEntry.key}');
      buffer.writeln('');

      for (final entry in dayEntry.value) {
        if (entry.title != null) {
          buffer.writeln('### ${entry.formattedTime} - ${entry.title}');
        } else if (entry.poiName != null) {
          buffer.writeln('### ${entry.formattedTime} - ${entry.poiName}');
        } else {
          buffer.writeln('### ${entry.formattedTime}');
        }

        if (entry.content != null) {
          buffer.writeln(entry.content);
        }

        if (entry.rating != null) {
          buffer.writeln('Bewertung: ${'⭐' * entry.rating!}');
        }

        buffer.writeln('');
      }
    }

    if (journal.tags.isNotEmpty) {
      buffer.writeln('Tags: ${journal.tags.join(', ')}');
    }

    return buffer.toString();
  }
}
