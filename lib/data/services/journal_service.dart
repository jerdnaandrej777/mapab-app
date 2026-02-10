import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/journal_entry.dart';
import '../repositories/journal_cloud_repo.dart';

/// Service fuer die Verwaltung von Reisetagebuch-Eintraegen
///
/// Hybrid-Architektur: Hive (lokal, offline) + Supabase (cloud, sync)
class JournalService {
  final JournalCloudRepo? cloudRepo;
  /// Rekursiver Deep-Cast: Hive Maps (Map<dynamic, dynamic>) sicher
  /// in Map<String, dynamic> konvertieren, inkl. verschachtelter Maps/Listen.
  static Map<String, dynamic> _deepCast(dynamic data) {
    if (data is! Map) {
      debugPrint('[Journal] _deepCast: Erwartet Map, erhalten ${data.runtimeType}');
      throw TypeError();
    }
    final map = <String, dynamic>{};
    for (final entry in data.entries) {
      final key = entry.key.toString();
      final value = entry.value;
      if (value is Map) {
        map[key] = _deepCast(value);
      } else if (value is List) {
        map[key] = value.map((e) => e is Map ? _deepCast(e) : e).toList();
      } else {
        map[key] = value;
      }
    }
    return map;
  }

  static const String _boxName = 'journals';
  static const String _entriesBoxName = 'journal_entries';
  late Box _journalsBox;
  late Box _entriesBox;
  final ImagePicker _imagePicker = ImagePicker();

  bool _isInitialized = false;

  /// Konstruktor mit optionalem Cloud-Repo
  JournalService({this.cloudRepo});

  /// Initialisiert den Service
  Future<void> init() async {
    if (_isInitialized) return;

    // Nutze pre-opened Boxen aus main.dart, Fallback auf lazy open
    if (Hive.isBoxOpen(_boxName)) {
      _journalsBox = Hive.box(_boxName);
    } else {
      debugPrint('[Journal] Box "$_boxName" nicht pre-opened, oeffne lazy');
      _journalsBox = await Hive.openBox(_boxName);
    }

    if (Hive.isBoxOpen(_entriesBoxName)) {
      _entriesBox = Hive.box(_entriesBoxName);
    } else {
      debugPrint(
          '[Journal] Box "$_entriesBoxName" nicht pre-opened, oeffne lazy');
      _entriesBox = await Hive.openBox(_entriesBoxName);
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
      if (data == null) {
        debugPrint('[Journal] Kein Journal-Metadaten fuer "$tripId" gefunden');
        return null;
      }

      final entries = await _getEntriesForTrip(tripId);
      final json = _deepCast(data);
      json['entries'] = entries.map((e) => e.toJson()).toList();

      final journal = TripJournal.fromJson(json);
      debugPrint('[Journal] Journal "$tripId" geladen: '
          '${entries.length} Eintraege, '
          'Name="${journal.tripName}"');
      return journal;
    } catch (e, stackTrace) {
      debugPrint('[Journal] Fehler beim Laden von Journal "$tripId": $e');
      debugPrint('[Journal] StackTrace: ${stackTrace.toString().split('\n').take(5).join('\n')}');
      // Rohdaten loggen
      try {
        final rawData = _journalsBox.get(tripId);
        debugPrint('[Journal] Rohdaten-Typ: ${rawData.runtimeType}');
      } catch (_) {}
      return null;
    }
  }

  /// Laedt alle Tagebuecher
  Future<List<TripJournal>> getAllJournals() async {
    await init();

    final journals = <TripJournal>[];
    int errorCount = 0;
    for (final key in _journalsBox.keys) {
      final journal = await getJournal(key as String);
      if (journal != null) {
        journals.add(journal);
      } else {
        errorCount++;
      }
    }

    if (errorCount > 0) {
      debugPrint('[Journal] getAllJournals: $errorCount von '
          '${_journalsBox.length} Journals konnten nicht geladen werden');
    }
    debugPrint('[Journal] ${journals.length} Tagebuecher geladen');

    journals.sort((a, b) => b.startDate.compareTo(a.startDate));
    return journals;
  }

  /// Fuegt einen neuen Eintrag hinzu (local + cloud sync)
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
      needsSync: cloudRepo != null,
    );

    // 1. Save to Hive first (fast, offline-capable)
    await _entriesBox.put(entry.id, entry.toJson());
    debugPrint('[Journal] Eintrag hinzugefuegt: ${entry.id}');

    // 2. Sync to cloud (fire-and-forget)
    if (cloudRepo != null) {
      _syncEntryToCloud(entry);
    }

    return entry;
  }

  /// Fuegt einen Eintrag mit Foto hinzu (local + cloud sync)
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
      needsSync: cloudRepo != null,
    );

    // 1. Save to Hive first (fast, offline-capable)
    await _entriesBox.put(entry.id, entry.toJson());
    debugPrint('[Journal] Eintrag mit Foto hinzugefuegt: ${entry.id}');

    // 2. Upload photo to cloud (fire-and-forget)
    if (cloudRepo != null) {
      _uploadPhotoToCloud(entry.id, tripId, File(savedPath));
    }

    return entry;
  }

  /// Aktualisiert einen Eintrag (local + cloud sync)
  Future<JournalEntry> updateEntry(JournalEntry entry) async {
    await init();

    // Mark as needs sync
    final updatedEntry = entry.copyWith(needsSync: cloudRepo != null);

    await _entriesBox.put(updatedEntry.id, updatedEntry.toJson());
    debugPrint('[Journal] Eintrag aktualisiert: ${updatedEntry.id}');

    // Sync to cloud (fire-and-forget)
    if (cloudRepo != null) {
      _syncEntryToCloud(updatedEntry);
    }

    return updatedEntry;
  }

  /// Loescht einen Eintrag
  Future<void> deleteEntry(String entryId) async {
    await init();

    final data = _entriesBox.get(entryId);
    if (data != null) {
      final json = _deepCast(data);
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

  /// Prueeft ob Eintraege fuer einen Trip existieren (ohne voll zu parsen)
  Future<bool> hasEntriesForTrip(String tripId) async {
    await init();

    for (final key in _entriesBox.keys) {
      try {
        final data = _entriesBox.get(key);
        if (data == null) continue;
        // Nur tripId pruefen, nicht voll parsen
        if (data is Map && data['tripId'] == tripId) {
          return true;
        }
      } catch (e) {
        // Fehler ignorieren, weitersuchen
      }
    }
    return false;
  }

  /// Hilfsmethode: Laedt alle Eintraege fuer einen Trip
  Future<List<JournalEntry>> _getEntriesForTrip(String tripId) async {
    final entries = <JournalEntry>[];
    int errorCount = 0;

    for (final key in _entriesBox.keys) {
      try {
        final data = _entriesBox.get(key);
        if (data == null) continue;
        final json = _deepCast(data);
        if (json['tripId'] == tripId) {
          entries.add(JournalEntry.fromJson(json));
        }
      } catch (e) {
        errorCount++;
        debugPrint('[Journal] Fehler beim Laden von Eintrag "$key": $e');
        // Rohdaten loggen fuer Debugging
        try {
          final rawData = _entriesBox.get(key);
          debugPrint('[Journal] Rohdaten fuer "$key": '
              'type=${rawData.runtimeType}, keys=${rawData is Map ? rawData.keys.toList() : "N/A"}');
        } catch (_) {}
      }
    }

    if (errorCount > 0) {
      debugPrint('[Journal] $errorCount Eintraege konnten nicht geladen werden '
          '(Trip: $tripId, Gesamt geparst: ${entries.length})');
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

  /// Oeffnet ImagePicker und speichert Bild im App-Verzeichnis.
  /// Gibt den lokalen Pfad zurueck, oder null bei Abbruch.
  Future<String?> pickAndSavePhoto(String tripId, {required bool fromCamera}) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (pickedFile == null) return null;
    return _saveImage(pickedFile, tripId);
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

  // ============================================
  // CLOUD SYNC METHODS
  // ============================================

  /// Sync eines Eintrags zur Cloud (fire-and-forget)
  Future<void> _syncEntryToCloud(JournalEntry entry) async {
    try {
      // Hole Journal-Metadaten fuer tripName
      final journalData = _journalsBox.get(entry.tripId);
      if (journalData == null) {
        debugPrint('[Journal] Kein Journal fuer tripId ${entry.tripId} gefunden');
        return;
      }

      final journalJson = _deepCast(journalData);
      final tripName = journalJson['tripName'] as String? ?? 'Unknown Trip';

      // Upload entry to cloud
      final dto = await cloudRepo!.uploadEntry(
        entry: entry,
        tripName: tripName,
      );

      if (dto != null) {
        // Update local entry with sync timestamp
        final synced = entry.copyWith(
          syncedAt: dto.syncedAt,
          needsSync: false,
        );
        await _entriesBox.put(entry.id, synced.toJson());
        debugPrint('[Journal] Cloud-Sync erfolgreich: ${entry.id}');
      }
    } catch (e) {
      debugPrint('[Journal] Cloud-Sync fehlgeschlagen: $e');
      // Mark as needs sync
      final needsSync = entry.copyWith(needsSync: true);
      await _entriesBox.put(entry.id, needsSync.toJson());
    }
  }

  /// Upload eines Fotos zur Cloud (fire-and-forget)
  Future<void> _uploadPhotoToCloud(
    String entryId,
    String tripId,
    File imageFile,
  ) async {
    try {
      // First sync the entry metadata
      final entryData = _entriesBox.get(entryId);
      if (entryData == null) {
        debugPrint('[Journal] Entry $entryId nicht gefunden');
        return;
      }

      final entry = JournalEntry.fromJson(_deepCast(entryData));

      // Sync entry first (without photo)
      await _syncEntryToCloud(entry);

      // Then upload photo
      final photoUrl = await cloudRepo!.uploadPhoto(
        entryId: entryId,
        tripId: tripId,
        imageFile: imageFile,
      );

      if (photoUrl != null) {
        // Update entry with cloud photo URL
        final updated = entry.copyWith(
          photoStoragePath: photoUrl,
          syncedAt: DateTime.now(),
          needsSync: false,
        );
        await _entriesBox.put(entryId, updated.toJson());
        debugPrint('[Journal] Foto-Upload erfolgreich: $entryId');
      }
    } catch (e) {
      debugPrint('[Journal] Foto-Upload fehlgeschlagen: $e');
    }
  }

  /// Hilfsmethode: Hole Entry aus Hive
  Future<JournalEntry?> _getEntryById(String entryId) async {
    try {
      final data = _entriesBox.get(entryId);
      if (data == null) return null;
      return JournalEntry.fromJson(_deepCast(data));
    } catch (e) {
      debugPrint('[Journal] Fehler beim Laden von Entry $entryId: $e');
      return null;
    }
  }

  /// Sync Journal von Cloud (beim App-Start / Manual Refresh)
  Future<void> syncJournalFromCloud(String tripId) async {
    if (cloudRepo == null) return;

    try {
      debugPrint('[Journal] Starte Cloud-Sync fuer Trip $tripId...');
      final cloudEntries = await cloudRepo!.fetchEntriesForTrip(tripId);

      // Merge mit local (cloud wins bei Konflikten)
      for (final cloudEntry in cloudEntries) {
        final localEntry = await _getEntryById(cloudEntry.id);

        if (localEntry == null) {
          // Neuer entry von cloud
          await _entriesBox.put(cloudEntry.id, cloudEntry.toJson());
          debugPrint('[Journal] Neuer Entry von Cloud: ${cloudEntry.id}');
        } else if (cloudEntry.syncedAt != null &&
            (localEntry.syncedAt == null ||
                cloudEntry.syncedAt!.isAfter(localEntry.syncedAt!))) {
          // Cloud ist neuer
          await _entriesBox.put(cloudEntry.id, cloudEntry.toJson());
          debugPrint('[Journal] Entry von Cloud aktualisiert: ${cloudEntry.id}');
        }
      }

      debugPrint(
          '[Journal] Cloud-Sync abgeschlossen: ${cloudEntries.length} Eintraege');
    } catch (e) {
      debugPrint('[Journal] Cloud-Sync fehlgeschlagen: $e');
    }
  }

  /// Einmalige Migration: Upload aller lokalen Eintraege zur Cloud
  Future<void> migrateLocalToCloud() async {
    if (cloudRepo == null) {
      debugPrint('[Journal] Keine Cloud-Repo verfuegbar fuer Migration');
      return;
    }

    try {
      debugPrint('[Journal] Starte Migration aller lokalen Eintraege...');

      final allEntries = _entriesBox.values.toList();
      int migratedCount = 0;
      int errorCount = 0;

      for (final entryData in allEntries) {
        try {
          final entry = JournalEntry.fromJson(_deepCast(entryData));

          // Skip already synced
          if (entry.syncedAt != null && !entry.needsSync) {
            continue;
          }

          // Get journal metadata
          final journalData = _journalsBox.get(entry.tripId);
          if (journalData == null) continue;

          final journalJson = _deepCast(journalData);
          final tripName = journalJson['tripName'] as String? ?? 'Unknown Trip';

          // Upload entry
          await cloudRepo!.uploadEntry(
            entry: entry,
            tripName: tripName,
          );

          // Upload photo if exists
          if (entry.imagePath != null) {
            final file = File(entry.imagePath!);
            if (await file.exists()) {
              await cloudRepo!.uploadPhoto(
                entryId: entry.id,
                tripId: entry.tripId,
                imageFile: file,
              );
            }
          }

          migratedCount++;
          debugPrint('[Journal] Migriert: ${entry.id}');

          // Rate limit protection
          await Future.delayed(const Duration(milliseconds: 200));
        } catch (e) {
          errorCount++;
          debugPrint('[Journal] Migration fehlgeschlagen fuer Entry: $e');
        }
      }

      debugPrint(
          '[Journal] Migration abgeschlossen: $migratedCount erfolgreich, $errorCount Fehler');
    } catch (e) {
      debugPrint('[Journal] Migration fehlgeschlagen: $e');
    }
  }
}
