import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/journal_entry.dart';

/// Service fuer die Verwaltung von Reisetagebuch-Eintraegen
class JournalService {
  static const String _boxName = 'journals';
  static const String _entriesBoxName = 'journal_entries';
  late Box<Map> _journalsBox;
  late Box<Map> _entriesBox;
  final ImagePicker _imagePicker = ImagePicker();

  bool _isInitialized = false;

  /// Initialisiert den Service
  Future<void> init() async {
    if (_isInitialized) return;

    // Nutze pre-opened Boxen aus main.dart, Fallback auf lazy open
    if (Hive.isBoxOpen(_boxName)) {
      _journalsBox = Hive.box<Map>(_boxName);
    } else {
      debugPrint('[Journal] Box "$_boxName" nicht pre-opened, oeffne lazy');
      _journalsBox = await Hive.openBox<Map>(_boxName);
    }

    if (Hive.isBoxOpen(_entriesBoxName)) {
      _entriesBox = Hive.box<Map>(_entriesBoxName);
    } else {
      debugPrint(
          '[Journal] Box "$_entriesBoxName" nicht pre-opened, oeffne lazy');
      _entriesBox = await Hive.openBox<Map>(_entriesBoxName);
    }

    _isInitialized = true;
    debugPrint('[Journal] Service initialisiert '
        '(journals: ${_journalsBox.length}, entries: ${_entriesBox.length})');
  }

  /// Erstellt ein neues Tagebuch fuer einen Trip
  Future<TripJournal> createJournal({
    required String tripId,
    required String tripName,
    DateTime? startDate,
  }) async {
    await init();

    final journal = TripJournal(
      tripId: tripId,
      tripName: tripName,
      startDate: startDate ?? DateTime.now(),
      entries: [],
    );

    await _journalsBox.put(tripId, journal.toJson());
    debugPrint('[Journal] Tagebuch erstellt: $tripName');
    return journal;
  }

  /// Laedt ein Tagebuch fuer einen Trip
  Future<TripJournal?> getJournal(String tripId) async {
    await init();

    try {
      final data = _journalsBox.get(tripId);
      if (data == null) return null;

      final entries = await _getEntriesForTrip(tripId);
      final json = Map<String, dynamic>.from(data);
      json['entries'] = entries.map((e) => e.toJson()).toList();

      return TripJournal.fromJson(json);
    } catch (e) {
      debugPrint('[Journal] Fehler beim Laden von Journal "$tripId": $e');
      return null;
    }
  }

  /// Laedt alle Tagebuecher
  Future<List<TripJournal>> getAllJournals() async {
    await init();

    final journals = <TripJournal>[];
    for (final key in _journalsBox.keys) {
      final journal = await getJournal(key as String);
      if (journal != null) {
        journals.add(journal);
      }
    }

    journals.sort((a, b) => b.startDate.compareTo(a.startDate));
    return journals;
  }

  /// Fuegt einen neuen Eintrag hinzu
  Future<JournalEntry> addEntry({
    required String tripId,
    String? poiId,
    String? poiName,
    String? note,
    double? latitude,
    double? longitude,
    String? locationName,
    int? dayNumber,
  }) async {
    await init();

    final entry = JournalEntry(
      id: const Uuid().v4(),
      tripId: tripId,
      poiId: poiId,
      poiName: poiName,
      createdAt: DateTime.now(),
      note: note,
      latitude: latitude,
      longitude: longitude,
      locationName: locationName,
      dayNumber: dayNumber,
    );

    await _entriesBox.put(entry.id, entry.toJson());
    debugPrint('[Journal] Eintrag hinzugefuegt: ${entry.id}');
    return entry;
  }

  /// Fuegt einen Eintrag mit Foto hinzu
  Future<JournalEntry?> addEntryWithPhoto({
    required String tripId,
    required ImageSource source,
    String? poiId,
    String? poiName,
    String? note,
    double? latitude,
    double? longitude,
    String? locationName,
    int? dayNumber,
  }) async {
    await init();

    final XFile? pickedFile = await _imagePicker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (pickedFile == null) {
      debugPrint('[Journal] Foto-Auswahl abgebrochen');
      return null;
    }

    // Bild in App-Verzeichnis speichern
    final savedPath = await _saveImage(pickedFile, tripId);

    final entry = JournalEntry(
      id: const Uuid().v4(),
      tripId: tripId,
      poiId: poiId,
      poiName: poiName,
      createdAt: DateTime.now(),
      imagePath: savedPath,
      note: note,
      latitude: latitude,
      longitude: longitude,
      locationName: locationName,
      dayNumber: dayNumber,
    );

    await _entriesBox.put(entry.id, entry.toJson());
    debugPrint('[Journal] Eintrag mit Foto hinzugefuegt: ${entry.id}');
    return entry;
  }

  /// Aktualisiert einen Eintrag
  Future<JournalEntry> updateEntry(JournalEntry entry) async {
    await init();
    await _entriesBox.put(entry.id, entry.toJson());
    debugPrint('[Journal] Eintrag aktualisiert: ${entry.id}');
    return entry;
  }

  /// Loescht einen Eintrag
  Future<void> deleteEntry(String entryId) async {
    await init();

    final data = _entriesBox.get(entryId);
    if (data != null) {
      final json = Map<String, dynamic>.from(data);
      final imagePath = json['imagePath'] as String?;
      if (imagePath != null) {
        await _deleteImage(imagePath);
      }
    }

    await _entriesBox.delete(entryId);
    debugPrint('[Journal] Eintrag geloescht: $entryId');
  }

  /// Loescht ein komplettes Tagebuch
  Future<void> deleteJournal(String tripId) async {
    await init();

    // Alle Eintraege loeschen
    final entries = await _getEntriesForTrip(tripId);
    for (final entry in entries) {
      await deleteEntry(entry.id);
    }

    // Tagebuch loeschen
    await _journalsBox.delete(tripId);
    debugPrint('[Journal] Tagebuch geloescht: $tripId');
  }

  /// Hilfsmethode: Laedt alle Eintraege fuer einen Trip
  Future<List<JournalEntry>> _getEntriesForTrip(String tripId) async {
    final entries = <JournalEntry>[];

    for (final key in _entriesBox.keys) {
      try {
        final data = _entriesBox.get(key);
        if (data == null) continue;
        final json = Map<String, dynamic>.from(data);
        if (json['tripId'] == tripId) {
          entries.add(JournalEntry.fromJson(json));
        }
      } catch (e) {
        debugPrint('[Journal] Fehler beim Laden von Eintrag "$key": $e');
      }
    }

    entries.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return entries;
  }

  /// Speichert ein Bild im App-Verzeichnis
  Future<String> _saveImage(XFile pickedFile, String tripId) async {
    final appDir = await getApplicationDocumentsDirectory();
    final journalDir = Directory('${appDir.path}/journal/$tripId');

    if (!await journalDir.exists()) {
      await journalDir.create(recursive: true);
    }

    final fileName = '${const Uuid().v4()}.jpg';
    final savedPath = '${journalDir.path}/$fileName';

    await File(pickedFile.path).copy(savedPath);
    debugPrint('[Journal] Bild gespeichert: $savedPath');
    return savedPath;
  }

  /// Loescht ein gespeichertes Bild
  Future<void> _deleteImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('[Journal] Bild geloescht: $imagePath');
      }
    } catch (e) {
      debugPrint('[Journal] Fehler beim Loeschen: $e');
    }
  }

  /// Berechnet den Speicherbedarf aller Journal-Bilder
  Future<int> calculateStorageUsage() async {
    await init();

    int totalBytes = 0;
    final appDir = await getApplicationDocumentsDirectory();
    final journalDir = Directory('${appDir.path}/journal');

    if (await journalDir.exists()) {
      await for (final entity in journalDir.list(recursive: true)) {
        if (entity is File) {
          totalBytes += await entity.length();
        }
      }
    }

    return totalBytes;
  }
}
