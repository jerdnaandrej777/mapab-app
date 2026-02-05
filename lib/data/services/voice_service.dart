import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:travel_planner/core/l10n/service_l10n.dart';
import 'package:travel_planner/l10n/app_localizations.dart';

part 'voice_service.g.dart';

/// Erkannte Sprachbefehle
enum VoiceCommand {
  nextStop,
  previousStop,
  currentLocation,
  timeToDestination,
  nearbyPOIs,
  addToTrip,
  startNavigation,
  stopNavigation,
  readDescription,
  unknown;

  /// Lokalisiertes Label fuer den Sprachbefehl
  String localizedLabel(AppLocalizations l10n) {
    switch (this) {
      case VoiceCommand.nextStop:
        return l10n.voiceCmdNextStop;
      case VoiceCommand.previousStop:
        return l10n.voiceCmdPreviousStop;
      case VoiceCommand.currentLocation:
        return l10n.voiceCmdLocation;
      case VoiceCommand.timeToDestination:
        return l10n.voiceCmdDuration;
      case VoiceCommand.nearbyPOIs:
        return l10n.voiceCmdNearby;
      case VoiceCommand.addToTrip:
        return l10n.voiceCmdAdd;
      case VoiceCommand.startNavigation:
        return l10n.voiceCmdStartNav;
      case VoiceCommand.stopNavigation:
        return l10n.voiceCmdStopNav;
      case VoiceCommand.readDescription:
        return l10n.voiceCmdDescribe;
      case VoiceCommand.unknown:
        return l10n.voiceCmdUnknown;
    }
  }
}

/// Sprach-Keywords fuer die Befehlserkennung pro Sprache
const _voiceKeywords = {
  'de': {
    'next': ['nächst', 'stopp', 'weiter'],
    'previous': ['vorher', 'zurück', 'letzt'],
    'location': ['wo bin ich', 'standort', 'position'],
    'duration': ['wie lange', 'ankunft', 'dauer'],
    'nearby': ['nähe', 'umgebung', 'sehenswürdigkeit'],
    'add': ['hinzufügen', 'route'],
    'navStart': ['navigation', 'start', 'navigier'],
    'navStop': ['navigation', 'stopp', 'beend', 'anhalten'],
    'describe': ['vorlesen', 'beschreibung', 'erzähl'],
  },
  'en': {
    'next': ['next', 'stop', 'continue'],
    'previous': ['previous', 'back', 'last'],
    'location': ['where am i', 'location', 'position'],
    'duration': ['how long', 'arrival', 'duration'],
    'nearby': ['nearby', 'around', 'sight'],
    'add': ['add', 'route'],
    'navStart': ['navigation', 'start', 'navigate'],
    'navStop': ['navigation', 'stop', 'end', 'halt'],
    'describe': ['read', 'description', 'tell'],
  },
  'fr': {
    'next': ['prochain', 'arrêt', 'suivant'],
    'previous': ['précédent', 'retour', 'dernier'],
    'location': ['où suis-je', 'position', 'emplacement'],
    'duration': ['combien de temps', 'arrivée', 'durée'],
    'nearby': ['proximité', 'alentour', 'curiosité'],
    'add': ['ajouter', 'itinéraire'],
    'navStart': ['navigation', 'démarrer', 'naviguer'],
    'navStop': ['navigation', 'arrêter', 'terminer'],
    'describe': ['lire', 'description', 'raconter'],
  },
  'it': {
    'next': ['prossimo', 'fermata', 'avanti'],
    'previous': ['precedente', 'indietro', 'ultimo'],
    'location': ['dove sono', 'posizione', 'luogo'],
    'duration': ['quanto manca', 'arrivo', 'durata'],
    'nearby': ['vicino', 'dintorni', 'attrazione'],
    'add': ['aggiungere', 'percorso'],
    'navStart': ['navigazione', 'inizia', 'naviga'],
    'navStop': ['navigazione', 'ferma', 'termina'],
    'describe': ['leggi', 'descrizione', 'racconta'],
  },
  'es': {
    'next': ['siguiente', 'parada', 'continuar'],
    'previous': ['anterior', 'atrás', 'último'],
    'location': ['dónde estoy', 'ubicación', 'posición'],
    'duration': ['cuánto falta', 'llegada', 'duración'],
    'nearby': ['cerca', 'alrededor', 'atracción'],
    'add': ['añadir', 'ruta'],
    'navStart': ['navegación', 'iniciar', 'navegar'],
    'navStop': ['navegación', 'detener', 'terminar'],
    'describe': ['leer', 'descripción', 'contar'],
  },
};

/// Voice Service für Spracheingabe und -ausgabe
class VoiceService {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _isListening = false;
  bool _isInitialized = false;
  bool _ttsInitialized = false;

  String _languageCode = 'de';
  AppLocalizations? _l10n;

  bool get isListening => _isListening;
  bool get isAvailable => _isInitialized;

  /// Zugriff auf Lokalisierung (lazy-initialisiert falls noetig)
  AppLocalizations get l10n =>
      _l10n ?? ServiceL10n.fromLanguageCode(_languageCode);

  /// Setzt die Sprache fuer TTS und Spracherkennung
  Future<void> setLocale(String languageCode) async {
    _languageCode = languageCode;
    _l10n = ServiceL10n.fromLanguageCode(languageCode);

    // TTS-Sprache dynamisch setzen
    final ttsLocale = _ttsLocaleFor(languageCode);

    try {
      await _tts.setLanguage(ttsLocale);
    } catch (e) {
      debugPrint('[Voice] TTS-Sprache setzen fehlgeschlagen: $e');
    }
  }

  /// Gibt den TTS-Locale-String fuer einen Sprach-Code zurueck
  String _ttsLocaleFor(String languageCode) {
    return switch (languageCode) {
      'en' => 'en-US',
      'fr' => 'fr-FR',
      'it' => 'it-IT',
      'es' => 'es-ES',
      'de' || _ => 'de-DE',
    };
  }

  /// Gibt den STT-Locale-String fuer einen Sprach-Code zurueck
  String _sttLocaleFor(String languageCode) {
    return switch (languageCode) {
      'en' => 'en_US',
      'fr' => 'fr_FR',
      'it' => 'it_IT',
      'es' => 'es_ES',
      'de' || _ => 'de_DE',
    };
  }

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
      await _tts.setLanguage(_ttsLocaleFor(_languageCode));
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
      final sttLocale = _sttLocaleFor(_languageCode);

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
        localeId: sttLocale,
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

  /// Parst Text zu Sprachbefehl (sprachbewusst)
  VoiceCommand parseCommand(String text) {
    final lower = text.toLowerCase().trim();
    final keywords = _voiceKeywords[_languageCode] ?? _voiceKeywords['de']!;

    bool containsAny(List<String> words) {
      return words.any((w) => lower.contains(w));
    }

    // Navigation beenden (VOR navStart pruefen, da 'navigation' in beiden vorkommt)
    final navStopKw = keywords['navStop']!;
    if (_languageCode == 'de') {
      // Deutsch: spezielle Logik mit Kombination
      if (lower.contains('navigation') &&
              (lower.contains('stopp') || lower.contains('beend')) ||
          lower.contains('anhalten')) {
        return VoiceCommand.stopNavigation;
      }
    } else {
      // Andere Sprachen: mindestens 2 Keywords muessen matchen oder spezifisches Keyword
      if (navStopKw.length >= 2 &&
          lower.contains(navStopKw[0]) &&
          containsAny(navStopKw.sublist(1))) {
        return VoiceCommand.stopNavigation;
      }
    }

    // Navigation starten
    final navStartKw = keywords['navStart']!;
    if (_languageCode == 'de') {
      if (lower.contains('navigation') && lower.contains('start') ||
          lower.contains('navigier')) {
        return VoiceCommand.startNavigation;
      }
    } else {
      if (navStartKw.length >= 2 &&
          lower.contains(navStartKw[0]) &&
          containsAny(navStartKw.sublist(1))) {
        return VoiceCommand.startNavigation;
      }
      // Einzelnes spezifisches Keyword (z.B. 'naviguer', 'naviga')
      if (navStartKw.length >= 3 && lower.contains(navStartKw[2])) {
        return VoiceCommand.startNavigation;
      }
    }

    // Naechster Stopp
    final nextKw = keywords['next']!;
    if (_languageCode == 'de') {
      if (lower.contains('nächst') && lower.contains('stopp') ||
          lower.contains('weiter') ||
          lower.contains('next')) {
        return VoiceCommand.nextStop;
      }
    } else {
      if (containsAny(nextKw)) {
        return VoiceCommand.nextStop;
      }
    }

    // Vorheriger Stopp
    if (containsAny(keywords['previous']!)) {
      return VoiceCommand.previousStop;
    }

    // Aktueller Standort
    if (containsAny(keywords['location']!)) {
      return VoiceCommand.currentLocation;
    }

    // Zeit bis Ziel
    if (containsAny(keywords['duration']!)) {
      return VoiceCommand.timeToDestination;
    }

    // POIs in der Naehe
    if (containsAny(keywords['nearby']!)) {
      return VoiceCommand.nearbyPOIs;
    }

    // Zur Route hinzufuegen
    if (containsAny(keywords['add']!)) {
      return VoiceCommand.addToTrip;
    }

    // Beschreibung vorlesen
    if (containsAny(keywords['describe']!)) {
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
      buffer.write(' ${l10n.voiceCategory(category)}.');
    }

    if (distanceKm != null) {
      if (distanceKm < 1) {
        buffer.write(' ${l10n.voiceDistanceMeters((distanceKm * 1000).round())}.');
      } else {
        buffer.write(' ${l10n.voiceDistanceKm(distanceKm.toStringAsFixed(1))}.');
      }
    }

    if (description != null && description.isNotEmpty) {
      // Kuerze Beschreibung fuer Sprachausgabe
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
      durationText = l10n.voiceHours(hours);
      if (mins > 0) {
        durationText += ' ${l10n.voiceAndMinutes(mins)}';
      }
    } else {
      durationText = l10n.voiceMinutes(mins);
    }

    final stopsText = l10n.voiceStops(stopsCount);
    final text = l10n.voiceRouteLength(
      distanceKm.toStringAsFixed(0),
      durationText,
      stopsText,
    );

    await speak(text);
  }

  /// Spricht naechsten Stopp
  Future<void> speakNextStop({
    required String stopName,
    required double distanceKm,
    required int minutesAway,
  }) async {
    final distanceText =
        '${l10n.voiceInKilometers(distanceKm.toStringAsFixed(1))}, '
        '${l10n.voiceMinutes(minutesAway)}';
    final text = l10n.voiceNextStop(stopName, distanceText);

    await speak(text);
  }

  /// Spricht Manoever-Ansage (Navigation)
  Future<void> speakManeuver({
    required String instruction,
    required double distanceMeters,
  }) async {
    String text;
    if (distanceMeters <= 50) {
      text = l10n.voiceManeuverNow(instruction);
    } else if (distanceMeters < 1000) {
      final rounded = (distanceMeters / 50).round() * 50;
      text = l10n.voiceManeuverInMeters(rounded, instruction);
    } else {
      final km = (distanceMeters / 1000).toStringAsFixed(1);
      text = l10n.voiceManeuverInKm(km, instruction);
    }
    await speak(text);
  }

  /// Spricht Rerouting-Ansage
  Future<void> speakRerouting() async {
    await speak(l10n.voiceRerouting);
  }

  /// Spricht POI-Annaeherung
  Future<void> speakPOIApproaching({
    required String poiName,
    required double distanceMeters,
  }) async {
    if (distanceMeters < 100) {
      await speak(l10n.voicePOIReached(poiName));
    } else {
      final rounded = (distanceMeters / 50).round() * 50;
      final distanceText = l10n.voiceInMeters(rounded);
      await speak(l10n.voicePOIApproaching(poiName, distanceText));
    }
  }

  /// Spricht Ziel-Erreicht-Ansage
  Future<void> speakArrived({String? destinationName}) async {
    if (destinationName != null && destinationName.isNotEmpty) {
      await speak(l10n.voiceArrivedAt(destinationName));
    } else {
      await speak(l10n.voiceArrived);
    }
  }

  /// Prueft verfuegbare Sprachen
  Future<List<String>> getAvailableLanguages() async {
    try {
      final languages = await _tts.getLanguages;
      return (languages as List).map((l) => l.toString()).toList();
    } catch (e) {
      return [_ttsLocaleFor(_languageCode)];
    }
  }

  /// Raeumt Ressourcen auf
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
