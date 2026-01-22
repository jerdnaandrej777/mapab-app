import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'onboarding_provider.g.dart';

/// Provider für den Onboarding-Status
/// Speichert ob der User das Onboarding bereits gesehen hat
@Riverpod(keepAlive: true)
class OnboardingNotifier extends _$OnboardingNotifier {
  static const String _boxName = 'settings';
  static const String _key = 'hasSeenOnboarding';

  @override
  bool build() {
    // Prüfe ob Onboarding bereits gesehen wurde
    try {
      final box = Hive.box(_boxName);
      final hasSeenOnboarding = box.get(_key, defaultValue: false) as bool;
      debugPrint('[Onboarding] hasSeenOnboarding: $hasSeenOnboarding');
      return hasSeenOnboarding;
    } catch (e) {
      debugPrint('[Onboarding] Fehler beim Laden: $e');
      return false;
    }
  }

  /// Markiert das Onboarding als abgeschlossen
  Future<void> completeOnboarding() async {
    try {
      final box = Hive.box(_boxName);
      await box.put(_key, true);
      state = true;
      debugPrint('[Onboarding] Onboarding abgeschlossen');
    } catch (e) {
      debugPrint('[Onboarding] Fehler beim Speichern: $e');
    }
  }

  /// Setzt den Onboarding-Status zurück (für Debugging)
  Future<void> resetOnboarding() async {
    try {
      final box = Hive.box(_boxName);
      await box.put(_key, false);
      state = false;
      debugPrint('[Onboarding] Onboarding zurückgesetzt');
    } catch (e) {
      debugPrint('[Onboarding] Fehler beim Zurücksetzen: $e');
    }
  }
}
