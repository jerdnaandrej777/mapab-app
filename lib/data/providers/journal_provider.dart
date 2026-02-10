import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/journal_entry.dart';
import '../repositories/journal_cloud_repo.dart';
import '../services/journal_service.dart';
import 'gamification_provider.dart';

part 'journal_provider.g.dart';

/// Provider fuer den JournalService (mit optionalem CloudRepo)
@Riverpod(keepAlive: true)
JournalService journalService(Ref ref) {
  final supabase = Supabase.instance.client;
  final cloudRepo = supabase.auth.currentUser != null
      ? JournalCloudRepo(supabase)
      : null;

  return JournalService(cloudRepo: cloudRepo);
}

/// State fuer das aktive Tagebuch
class JournalState {
  final TripJournal? activeJournal;
  final List<TripJournal> allJournals;
  final bool isLoading;
  final bool isSyncing;
  final String? error;
  final int? selectedDay;

  const JournalState({
    this.activeJournal,
    this.allJournals = const [],
    this.isLoading = false,
    this.isSyncing = false,
    this.error,
    this.selectedDay,
  });

  JournalState copyWith({
    TripJournal? activeJournal,
    List<TripJournal>? allJournals,
    bool? isLoading,
    bool? isSyncing,
    String? error,
    int? selectedDay,
    bool clearActiveJournal = false,
    bool clearError = false,
  }) {
    return JournalState(
      activeJournal: clearActiveJournal ? null : (activeJournal ?? this.activeJournal),
      allJournals: allJournals ?? this.allJournals,
      isLoading: isLoading ?? this.isLoading,
      isSyncing: isSyncing ?? this.isSyncing,
      error: clearError ? null : (error ?? this.error),
      selectedDay: selectedDay ?? this.selectedDay,
    );
  }

  /// Eintraege fuer den aktuell ausgewaehlten Tag
  List<JournalEntry> get selectedDayEntries {
    if (activeJournal == null || selectedDay == null) return [];
    return activeJournal!.entriesForDay(selectedDay!);
  }

  /// Alle Eintraege des aktiven Tagebuchs
  List<JournalEntry> get allEntries {
    return activeJournal?.entries ?? [];
  }
}

/// Notifier fuer Reisetagebuch-Verwaltung
@Riverpod(keepAlive: true)
class JournalNotifier extends _$JournalNotifier {
  late JournalService _service;

  @override
  JournalState build() {
    _service = ref.watch(journalServiceProvider);
    _initService();
    return const JournalState();
  }

  Future<void> _initService() async {
    await _service.init();
    await loadAllJournals();
  }

  /// Laedt alle Tagebuecher
  Future<void> loadAllJournals() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final journals = await _service.getAllJournals();
      state = state.copyWith(
        allJournals: journals,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('[Journal] Fehler beim Laden aller Tagebuecher: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Fehler beim Laden der Tagebuecher: $e',
      );
    }
  }

  /// Erstellt ein neues Tagebuch oder laedt ein existierendes
  Future<TripJournal?> getOrCreateJournal({
    required String tripId,
    required String tripName,
    DateTime? startDate,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      var journal = await _service.getJournal(tripId);
      if (journal == null) {
        // Pruefen ob Eintraege existieren bevor ein neues Journal erstellt wird
        final existingEntries = await _service.hasEntriesForTrip(tripId);
        if (existingEntries) {
          // Eintraege vorhanden aber Journal-Metadaten kaputt -> nur Metadaten neu erstellen
          debugPrint('[Journal] Metadaten fuer "$tripId" fehlen, '
              'aber Eintraege existieren - erstelle Metadaten neu');
        }
        journal = await _service.createJournal(
          tripId: tripId,
          tripName: tripName,
          startDate: startDate,
        );
        // Nochmal laden um Eintraege mitzubekommen
        journal = await _service.getJournal(tripId) ?? journal;
      }
      state = state.copyWith(
        activeJournal: journal,
        isLoading: false,
      );
      // allJournals im Hintergrund aktualisieren (non-blocking)
      _loadAllJournalsInBackground();
      return journal;
    } catch (e) {
      debugPrint('[Journal] Fehler in getOrCreateJournal: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Fehler beim Erstellen des Tagebuchs: $e',
      );
      return null;
    }
  }

  /// Setzt das aktive Tagebuch
  Future<void> setActiveJournal(String tripId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final journal = await _service.getJournal(tripId);
      // Null-Guard: bei Ladefehler vorherigen Wert beibehalten
      state = state.copyWith(
        activeJournal: journal ?? state.activeJournal,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('[Journal] Fehler in setActiveJournal: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Fehler beim Laden des Tagebuchs: $e',
      );
    }
  }

  /// Setzt den ausgewaehlten Tag
  void selectDay(int? dayNumber) {
    state = state.copyWith(selectedDay: dayNumber);
  }

  /// Fuegt einen Text-Eintrag hinzu
  Future<JournalEntry?> addTextEntry({
    required String note,
    String? poiId,
    String? poiName,
    double? latitude,
    double? longitude,
    String? locationName,
    int? dayNumber,
  }) async {
    if (state.activeJournal == null) return null;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final entry = await _service.addEntry(
        tripId: state.activeJournal!.tripId,
        poiId: poiId,
        poiName: poiName,
        note: note,
        latitude: latitude,
        longitude: longitude,
        locationName: locationName,
        dayNumber: dayNumber ?? state.selectedDay,
      );

      await _refreshActiveJournal();
      return entry;
    } catch (e) {
      debugPrint('[Journal] Fehler in addTextEntry: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Fehler beim Hinzufuegen des Eintrags: $e',
      );
      return null;
    }
  }

  /// Fuegt einen Foto-Eintrag hinzu (Kamera)
  Future<JournalEntry?> addPhotoFromCamera({
    String? note,
    String? poiId,
    String? poiName,
    double? latitude,
    double? longitude,
    String? locationName,
    int? dayNumber,
  }) async {
    return _addPhotoEntry(
      source: ImageSource.camera,
      note: note,
      poiId: poiId,
      poiName: poiName,
      latitude: latitude,
      longitude: longitude,
      locationName: locationName,
      dayNumber: dayNumber,
    );
  }

  /// Fuegt einen Foto-Eintrag hinzu (Galerie)
  Future<JournalEntry?> addPhotoFromGallery({
    String? note,
    String? poiId,
    String? poiName,
    double? latitude,
    double? longitude,
    String? locationName,
    int? dayNumber,
  }) async {
    return _addPhotoEntry(
      source: ImageSource.gallery,
      note: note,
      poiId: poiId,
      poiName: poiName,
      latitude: latitude,
      longitude: longitude,
      locationName: locationName,
      dayNumber: dayNumber,
    );
  }

  Future<JournalEntry?> _addPhotoEntry({
    required ImageSource source,
    String? note,
    String? poiId,
    String? poiName,
    double? latitude,
    double? longitude,
    String? locationName,
    int? dayNumber,
  }) async {
    if (state.activeJournal == null) return null;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final entry = await _service.addEntryWithPhoto(
        tripId: state.activeJournal!.tripId,
        source: source,
        poiId: poiId,
        poiName: poiName,
        note: note,
        latitude: latitude,
        longitude: longitude,
        locationName: locationName,
        dayNumber: dayNumber ?? state.selectedDay,
      );

      if (entry != null) {
        await _refreshActiveJournal();

        // XP fuer Foto-Eintrag vergeben
        await ref.read(gamificationNotifierProvider.notifier).onJournalPhotoAdded();
      } else {
        state = state.copyWith(isLoading: false);
      }
      return entry;
    } catch (e) {
      debugPrint('[Journal] Fehler in _addPhotoEntry: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Fehler beim Hinzufuegen des Fotos: $e',
      );
      return null;
    }
  }

  /// Aktualisiert einen Eintrag (z.B. Notiz aendern)
  Future<void> updateEntry(JournalEntry entry) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _service.updateEntry(entry);
      await _refreshActiveJournal();
    } catch (e) {
      debugPrint('[Journal] Fehler in updateEntry: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Fehler beim Aktualisieren: $e',
      );
    }
  }

  /// Loescht einen Eintrag
  Future<void> deleteEntry(String entryId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _service.deleteEntry(entryId);
      await _refreshActiveJournal();
    } catch (e) {
      debugPrint('[Journal] Fehler in deleteEntry: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Fehler beim Loeschen: $e',
      );
    }
  }

  /// Loescht ein komplettes Tagebuch
  Future<void> deleteJournal(String tripId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _service.deleteJournal(tripId);
      if (state.activeJournal?.tripId == tripId) {
        state = state.copyWith(clearActiveJournal: true);
      }
      await loadAllJournals();
    } catch (e) {
      debugPrint('[Journal] Fehler in deleteJournal: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Fehler beim Loeschen des Tagebuchs: $e',
      );
    }
  }

  /// Schliesst das aktive Tagebuch
  void closeActiveJournal() {
    state = state.copyWith(clearActiveJournal: true, selectedDay: null);
  }

  /// Aktualisiert nur das aktive Tagebuch (OHNE loadAllJournals)
  Future<void> _refreshActiveJournal() async {
    if (state.activeJournal == null) {
      state = state.copyWith(isLoading: false);
      return;
    }

    try {
      final journal = await _service.getJournal(state.activeJournal!.tripId);
      state = state.copyWith(
        activeJournal: journal ?? state.activeJournal,
        isLoading: false,
      );
      // allJournals im Hintergrund aktualisieren (non-blocking)
      _loadAllJournalsInBackground();
    } catch (e) {
      debugPrint('[Journal] Fehler in _refreshActiveJournal: $e');
      // Bei Fehler: vorherigen State beibehalten
      state = state.copyWith(isLoading: false);
    }
  }

  /// Laedt allJournals im Hintergrund ohne den UI-State zu blockieren
  void _loadAllJournalsInBackground() {
    Future(() async {
      try {
        final journals = await _service.getAllJournals();
        state = state.copyWith(allJournals: journals);
      } catch (e) {
        debugPrint('[Journal] Hintergrund-Laden fehlgeschlagen: $e');
        // Fehler im Hintergrund ignorieren - allJournals bleibt unveraendert
      }
    });
  }

  // ============================================
  // CLOUD SYNC METHODS
  // ============================================

  /// Sync Journal von Cloud (Manual Refresh)
  Future<void> syncFromCloud(String tripId) async {
    if (state.activeJournal == null) return;

    state = state.copyWith(isSyncing: true, clearError: true);
    try {
      await _service.syncJournalFromCloud(tripId);
      await _refreshActiveJournal();
    } catch (e) {
      debugPrint('[JournalNotifier] Cloud-Sync fehlgeschlagen: $e');
      state = state.copyWith(
        isSyncing: false,
        error: 'Cloud-Sync fehlgeschlagen: $e',
      );
    } finally {
      state = state.copyWith(isSyncing: false);
    }
  }

  /// Einmalige Migration aller lokalen Eintraege zur Cloud
  Future<void> migrateLocalToCloud() async {
    state = state.copyWith(isSyncing: true, clearError: true);
    try {
      await _service.migrateLocalToCloud();

      // Nach Migration: Alle Journals neu laden
      await loadAllJournals();

      // Aktives Journal aktualisieren falls vorhanden
      if (state.activeJournal != null) {
        await _refreshActiveJournal();
      }
    } catch (e) {
      debugPrint('[JournalNotifier] Migration fehlgeschlagen: $e');
      state = state.copyWith(
        isSyncing: false,
        error: 'Migration fehlgeschlagen: $e',
      );
    } finally {
      state = state.copyWith(isSyncing: false);
    }
  }
}
