import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/utils/navigation_instruction_generator.dart';
import '../../../data/services/voice_service.dart';
import 'navigation_poi_discovery_provider.dart';
import 'navigation_provider.dart';

part 'navigation_tts_provider.g.dart';

/// Distanz-Schwellen für TTS-Ansagen
class _TtsThresholds {
  static const double farAnnounce = 500; // Meter
  static const double nearAnnounce = 200;
  static const double immediateAnnounce = 50;
  static const double poiApproachAnnounce = 300;
}

/// Provider der TTS-Ansagen basierend auf NavigationState steuert
@Riverpod(keepAlive: true)
class NavigationTts extends _$NavigationTts {
  int? _lastAnnouncedStepIndex;
  _AnnouncementLevel? _lastAnnouncementLevel;
  String? _lastAnnouncedPOI;
  bool _hasAnnouncedRerouting = false;
  bool _hasAnnouncedArrival = false;

  @override
  void build() {
    // NavigationState beobachten und TTS-Ansagen triggern
    ref.listen<NavigationState>(
      navigationNotifierProvider,
      (previous, next) => _onNavigationStateChanged(previous, next),
    );

    // Must-See POI Discovery beobachten
    ref.listen<NavigationPOIDiscoveryState>(
      navigationPOIDiscoveryNotifierProvider,
      (previous, next) => _onDiscoveryStateChanged(previous, next),
    );
  }

  void _onNavigationStateChanged(
      NavigationState? previous, NavigationState next) {
    // Navigation nicht aktiv - keine Ansagen
    if (next.status == NavigationStatus.idle) return;
    if (next.isMuted) return;

    final voiceService = ref.read(voiceServiceProvider);

    // Rerouting-Ansage
    if (next.isRerouting && !_hasAnnouncedRerouting) {
      _hasAnnouncedRerouting = true;
      voiceService.speakRerouting();
      debugPrint('[NavigationTTS] Rerouting angekündigt');
      return;
    }

    if (!next.isRerouting) {
      _hasAnnouncedRerouting = false;
    }

    // Ziel erreicht
    if (next.status == NavigationStatus.arrivedAtDestination &&
        !_hasAnnouncedArrival) {
      _hasAnnouncedArrival = true;
      voiceService.speakArrived(
        destinationName: next.route?.baseRoute.endAddress,
      );
      debugPrint('[NavigationTTS] Ziel erreicht angekündigt');
      return;
    }

    // POI-Waypoint erreicht
    if (next.status == NavigationStatus.arrivedAtWaypoint &&
        next.nextPOIStop != null) {
      final poiId = next.nextPOIStop!.poiId;
      if (_lastAnnouncedPOI != poiId) {
        _lastAnnouncedPOI = poiId;
        voiceService.speakPOIApproaching(
          poiName: next.nextPOIStop!.name,
          distanceMeters: 0,
        );
        debugPrint('[NavigationTTS] POI erreicht: ${next.nextPOIStop!.name}');
      }
      return;
    }

    // POI-Annäherung (< 300m)
    if (next.nextPOIStop != null &&
        next.distanceToNextPOIMeters < _TtsThresholds.poiApproachAnnounce &&
        next.distanceToNextPOIMeters > 50 &&
        _lastAnnouncedPOI != '${next.nextPOIStop!.poiId}_approaching') {
      _lastAnnouncedPOI = '${next.nextPOIStop!.poiId}_approaching';
      voiceService.speakPOIApproaching(
        poiName: next.nextPOIStop!.name,
        distanceMeters: next.distanceToNextPOIMeters,
      );
      debugPrint('[NavigationTTS] POI Annäherung: ${next.nextPOIStop!.name}');
      return;
    }

    if (!next.isNavigating) return;

    // Manöver-Ansagen
    _announceManeuver(next, voiceService);
  }

  /// Steuert Manöver-Ansagen basierend auf Distanz-Schwellen
  void _announceManeuver(NavigationState navState, VoiceService voiceService) {
    final step = navState.nextStep ?? navState.currentStep;
    if (step == null || step.isArrival) return;

    final distance = navState.distanceToNextStepMeters;
    final stepIndex = navState.currentStepIndex;

    // Welches Ansage-Level ist angemessen?
    _AnnouncementLevel? level;
    if (distance <= _TtsThresholds.immediateAnnounce) {
      level = _AnnouncementLevel.immediate;
    } else if (distance <= _TtsThresholds.nearAnnounce) {
      level = _AnnouncementLevel.near;
    } else if (distance <= _TtsThresholds.farAnnounce) {
      level = _AnnouncementLevel.far;
    }

    if (level == null) return;

    // Prüfen ob diese Kombination bereits angesagt wurde
    if (_lastAnnouncedStepIndex == stepIndex &&
        _lastAnnouncementLevel == level) {
      return;
    }

    // Nur ansagen wenn es ein signifikantes Manöver ist
    if (!step.isSignificant && level != _AnnouncementLevel.immediate) {
      return;
    }

    _lastAnnouncedStepIndex = stepIndex;
    _lastAnnouncementLevel = level;

    // Instruktion generieren
    final instruction = level == _AnnouncementLevel.immediate
        ? NavigationInstructionGenerator.generateShort(
            type: step.type,
            modifier: step.modifier,
            roundaboutExit: step.roundaboutExit,
          )
        : step.instruction;

    voiceService.speakManeuver(
      instruction: instruction,
      distanceMeters: distance,
    );

    debugPrint('[NavigationTTS] Ansage (${level.name}): $instruction '
        'in ${distance.round()}m');
  }

  /// Must-See POI Ankuendigung
  void _onDiscoveryStateChanged(
    NavigationPOIDiscoveryState? previous,
    NavigationPOIDiscoveryState next,
  ) {
    // Pruefen ob Navigation aktiv und nicht stummgeschaltet
    final navState = ref.read(navigationNotifierProvider);
    if (navState.isMuted || !navState.isNavigating) return;

    final poi = next.currentApproachingPOI;
    if (poi == null) return;

    final distance = next.distanceToApproachingPOI ?? double.infinity;

    // Nur ankuendigen wenn unter TTS-Schwelle und noch nicht angekuendigt
    if (distance > NavigationPOIDiscoveryNotifier.ttsThresholdMeters) return;
    if (!next.shouldAnnouncePOI(poi.id)) return;

    // Nicht waehrend aktiver Manoever-Ansage (check: sind wir < 200m vor einem Manoever?)
    if (navState.distanceToNextStepMeters < _TtsThresholds.nearAnnounce) return;

    final voiceService = ref.read(voiceServiceProvider);

    // Must-See Ankuendigung
    final rounded = (distance / 50).round() * 50;
    final text = 'In $rounded Metern befindet sich ${poi.name}, '
        'ein Must-See Highlight';
    voiceService.speak(text);

    // Als angekuendigt markieren
    ref
        .read(navigationPOIDiscoveryNotifierProvider.notifier)
        .markAsAnnounced(poi.id);

    debugPrint('[NavigationTTS] Must-See POI: ${poi.name} '
        'in ${distance.round()}m');
  }

  /// Setzt den TTS-State zurück (bei Navigation-Neustart)
  void reset() {
    _lastAnnouncedStepIndex = null;
    _lastAnnouncementLevel = null;
    _lastAnnouncedPOI = null;
    _hasAnnouncedRerouting = false;
    _hasAnnouncedArrival = false;
    // Laufende Sprachausgabe stoppen
    try {
      ref.read(voiceServiceProvider).stopSpeaking();
    } catch (_) {}
  }
}

enum _AnnouncementLevel { far, near, immediate }
