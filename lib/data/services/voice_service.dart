import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'voice_service.g.dart';

/// Erkannte Sprachbefehle
enum VoiceCommand {
  nextStop('Nächster Stopp'),
  previousStop('Vorheriger Stopp'),
  currentLocation('Wo bin ich'),
  timeToDestination('Wie lange noch'),
  nearbyPOIs('Was ist in der Nähe'),
  addToTrip('Zur Route hinzufügen'),
  startNavigation('Navigation starten'),
  stopNavigation('Navigation beenden'),
  readDescription('Beschreibung vorlesen'),
  unknown('Unbekannt');

  final String label;
  const VoiceCommand(this.label);
}

/// Voice Service für Spracheingabe und -ausgabe
class VoiceService {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _isListening = false;
  bool _isInitialized = false;
  bool _ttsInitialized = false;

  bool get isListening => _isListening;
  bool get isAvailable => _isInitialized;

  /// Initialisiert den Voice Service
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _isInitialized = await _speechToText.initialize(
        onStatus: (status) => debugPrint('[Voice] Status: $status'),
        onError: (error) => debugPrint('[Voice] Error: $error'),
      );

      // TTS konfigurieren
      await _initializeTts();

      return _isInitialized;
    } catch (e) {
      debugPrint('[Voice] Initialisierung fehlgeschlagen: $e');
      return false;
    }
  }

  Future<void> _initializeTts() async {
    try {
      await _tts.setLanguage('de-DE');
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      _ttsInitialized = true;
    } catch (e) {
      debugPrint('[Voice] TTS-Initialisierung fehlgeschlagen: $e');
    }
  }

  /// Startet Spracherkennung
  Future<String?> listen({
    Duration timeout = const Duration(seconds: 10),
    void Function(String)? onPartialResult,
  }) async {
    if (!_isInitialized) {
      final success = await initialize();
      if (!success) return null;
    }

    if (_isListening) return null;

    String? result;
    _isListening = true;

    try {
      await _speechToText.listen(
        onResult: (speechResult) {
          if (speechResult.recognizedWords.isNotEmpty) {
            if (!speechResult.finalResult) {
              onPartialResult?.call(speechResult.recognizedWords);
            } else {
              result = speechResult.recognizedWords;
            }
          }
        },
        listenFor: timeout,
        pauseFor: const Duration(seconds: 3),
        localeId: 'de_DE',
        cancelOnError: true,
        partialResults: onPartialResult != null,
      );

      // Warte bis Ergebnis da ist oder Timeout
      await Future.delayed(timeout + const Duration(seconds: 1));
    } catch (e) {
      debugPrint('[Voice] Fehler beim Zuhören: $e');
    } finally {
      _isListening = false;
    }

    return result;
  }

  /// Stoppt Spracherkennung
  Future<void> stopListening() async {
    if (_isListening) {
      await _speechToText.stop();
      _isListening = false;
    }
  }

  /// Parst Text zu Sprachbefehl
  VoiceCommand parseCommand(String text) {
    final lower = text.toLowerCase().trim();

    // Nächster Stopp
    if (lower.contains('nächst') && lower.contains('stopp') ||
        lower.contains('weiter') ||
        lower.contains('next')) {
      return VoiceCommand.nextStop;
    }

    // Vorheriger Stopp
    if (lower.contains('vorher') || lower.contains('zurück') ||
        lower.contains('letzt')) {
      return VoiceCommand.previousStop;
    }

    // Aktueller Standort
    if (lower.contains('wo bin ich') || lower.contains('standort') ||
        lower.contains('position')) {
      return VoiceCommand.currentLocation;
    }

    // Zeit bis Ziel
    if (lower.contains('wie lange') || lower.contains('ankunft') ||
        lower.contains('dauer')) {
      return VoiceCommand.timeToDestination;
    }

    // POIs in der Nähe
    if (lower.contains('nähe') || lower.contains('umgebung') ||
        lower.contains('sehenswürdigkeit')) {
      return VoiceCommand.nearbyPOIs;
    }

    // Zur Route hinzufügen
    if (lower.contains('hinzufügen') || lower.contains('route') && lower.contains('add')) {
      return VoiceCommand.addToTrip;
    }

    // Navigation starten
    if (lower.contains('navigation') && lower.contains('start') ||
        lower.contains('navigier')) {
      return VoiceCommand.startNavigation;
    }

    // Navigation beenden
    if (lower.contains('navigation') && (lower.contains('stopp') || lower.contains('beend')) ||
        lower.contains('anhalten')) {
      return VoiceCommand.stopNavigation;
    }

    // Beschreibung vorlesen
    if (lower.contains('vorlesen') || lower.contains('beschreibung') ||
        lower.contains('erzähl')) {
      return VoiceCommand.readDescription;
    }

    return VoiceCommand.unknown;
  }

  /// Spricht Text
  Future<void> speak(String text) async {
    if (!_ttsInitialized) {
      await _initializeTts();
    }

    try {
      await _tts.speak(text);
    } catch (e) {
      debugPrint('[Voice] Sprechen fehlgeschlagen: $e');
    }
  }

  /// Stoppt Sprachausgabe
  Future<void> stopSpeaking() async {
    await _tts.stop();
  }

  /// Spricht POI-Beschreibung
  Future<void> speakPoiDescription({
    required String name,
    String? category,
    String? description,
    double? distanceKm,
  }) async {
    final buffer = StringBuffer();
    buffer.write('$name.');

    if (category != null) {
      buffer.write(' Kategorie: $category.');
    }

    if (distanceKm != null) {
      if (distanceKm < 1) {
        buffer.write(' ${(distanceKm * 1000).round()} Meter entfernt.');
      } else {
        buffer.write(' ${distanceKm.toStringAsFixed(1)} Kilometer entfernt.');
      }
    }

    if (description != null && description.isNotEmpty) {
      // Kürze Beschreibung für Sprachausgabe
      final shortDesc = description.length > 200
          ? '${description.substring(0, 200)}...'
          : description;
      buffer.write(' $shortDesc');
    }

    await speak(buffer.toString());
  }

  /// Spricht Route-Info
  Future<void> speakRouteInfo({
    required double distanceKm,
    required int durationMinutes,
    required int stopsCount,
  }) async {
    final hours = durationMinutes ~/ 60;
    final mins = durationMinutes % 60;

    String durationText;
    if (hours > 0) {
      durationText = '$hours Stunde${hours > 1 ? 'n' : ''}'
          '${mins > 0 ? ' und $mins Minuten' : ''}';
    } else {
      durationText = '$mins Minuten';
    }

    final text = 'Deine Route ist ${distanceKm.toStringAsFixed(0)} Kilometer lang, '
        'dauert etwa $durationText '
        'und hat $stopsCount Stopp${stopsCount > 1 ? 's' : ''}.';

    await speak(text);
  }

  /// Spricht nächsten Stopp
  Future<void> speakNextStop({
    required String stopName,
    required double distanceKm,
    required int minutesAway,
  }) async {
    final text = 'Nächster Stopp: $stopName. '
        '${distanceKm.toStringAsFixed(1)} Kilometer, '
        'etwa $minutesAway Minuten entfernt.';

    await speak(text);
  }

  /// Prüft verfügbare Sprachen
  Future<List<String>> getAvailableLanguages() async {
    try {
      final languages = await _tts.getLanguages;
      return (languages as List).map((l) => l.toString()).toList();
    } catch (e) {
      return ['de-DE'];
    }
  }

  /// Räumt Ressourcen auf
  void dispose() {
    _speechToText.cancel();
    _tts.stop();
  }
}

/// Voice Service Provider
@Riverpod(keepAlive: true)
VoiceService voiceService(VoiceServiceRef ref) {
  final service = VoiceService();
  ref.onDispose(() => service.dispose());
  return service;
}
