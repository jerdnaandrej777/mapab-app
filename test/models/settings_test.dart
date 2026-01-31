import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_planner/data/providers/settings_provider.dart';

void main() {
  group('AppSettings', () {
    test('Default-Werte sind korrekt', () {
      const settings = AppSettings();

      expect(settings.themeMode, AppThemeMode.system);
      expect(settings.autoSunsetDarkMode, isFalse);
      expect(settings.language, 'de');
      expect(settings.hapticFeedback, isTrue);
      expect(settings.soundEffects, isTrue);
      expect(settings.rememberMe, isFalse);
      expect(settings.savedEmail, isNull);
    });

    test('copyWith erstellt korrekte Kopie', () {
      const original = AppSettings();
      final modified = original.copyWith(
        themeMode: AppThemeMode.dark,
        language: 'en',
        hapticFeedback: false,
      );

      expect(modified.themeMode, AppThemeMode.dark);
      expect(modified.language, 'en');
      expect(modified.hapticFeedback, isFalse);
      // Unveränderte Werte bleiben
      expect(modified.soundEffects, isTrue);
      expect(modified.rememberMe, isFalse);
    });

    test('copyWith mit clearCredentials löscht Email', () {
      const settings = AppSettings(
        rememberMe: true,
        savedEmail: 'test@example.com',
      );
      final cleared = settings.copyWith(clearCredentials: true);

      expect(cleared.savedEmail, isNull);
    });

    test('hasStoredCredentials prüft rememberMe und savedEmail', () {
      const noCredentials = AppSettings();
      const withRememberMe = AppSettings(rememberMe: true);
      const withEmail = AppSettings(
        rememberMe: true,
        savedEmail: 'test@example.com',
      );

      expect(noCredentials.hasStoredCredentials, isFalse);
      expect(withRememberMe.hasStoredCredentials, isFalse);
      expect(withEmail.hasStoredCredentials, isTrue);
    });
  });

  group('AppThemeMode', () {
    test('flutterThemeMode gibt korrekten ThemeMode', () {
      const systemSettings = AppSettings(themeMode: AppThemeMode.system);
      const lightSettings = AppSettings(themeMode: AppThemeMode.light);
      const darkSettings = AppSettings(themeMode: AppThemeMode.dark);
      const oledSettings = AppSettings(themeMode: AppThemeMode.oled);

      expect(systemSettings.flutterThemeMode, ThemeMode.system);
      expect(lightSettings.flutterThemeMode, ThemeMode.light);
      expect(darkSettings.flutterThemeMode, ThemeMode.dark);
      expect(oledSettings.flutterThemeMode, ThemeMode.dark);
    });

    test('isOledMode erkennt OLED-Modus', () {
      const oled = AppSettings(themeMode: AppThemeMode.oled);
      const dark = AppSettings(themeMode: AppThemeMode.dark);

      expect(oled.isOledMode, isTrue);
      expect(dark.isOledMode, isFalse);
    });
  });

  group('AppSettings Serialization', () {
    test('toJson/fromJson Roundtrip', () {
      const original = AppSettings(
        themeMode: AppThemeMode.dark,
        autoSunsetDarkMode: true,
        sunsetLatitude: 52.52,
        sunsetLongitude: 13.405,
        language: 'en',
        hapticFeedback: false,
        soundEffects: false,
        rememberMe: true,
        savedEmail: 'test@example.com',
      );

      final json = original.toJson();
      final restored = AppSettings.fromJson(json);

      expect(restored.themeMode, original.themeMode);
      expect(restored.autoSunsetDarkMode, original.autoSunsetDarkMode);
      expect(restored.sunsetLatitude, original.sunsetLatitude);
      expect(restored.sunsetLongitude, original.sunsetLongitude);
      expect(restored.language, original.language);
      expect(restored.hapticFeedback, original.hapticFeedback);
      expect(restored.soundEffects, original.soundEffects);
      expect(restored.rememberMe, original.rememberMe);
      expect(restored.savedEmail, original.savedEmail);
    });

    test('fromJson mit fehlenden Feldern nutzt Defaults', () {
      final settings = AppSettings.fromJson({});

      expect(settings.themeMode, AppThemeMode.system);
      expect(settings.language, 'de');
      expect(settings.hapticFeedback, isTrue);
    });

    test('fromJson mit null-Werten nutzt Defaults', () {
      final settings = AppSettings.fromJson({
        'themeMode': null,
        'language': null,
        'hapticFeedback': null,
      });

      expect(settings.themeMode, AppThemeMode.system);
      expect(settings.language, 'de');
      expect(settings.hapticFeedback, isTrue);
    });
  });

  group('AppThemeMode Enum', () {
    test('Alle Modi haben Labels', () {
      for (final mode in AppThemeMode.values) {
        expect(mode.label.isNotEmpty, isTrue);
      }
    });

    test('Alle Modi haben Icons', () {
      for (final mode in AppThemeMode.values) {
        expect(mode.icon, isNotNull);
      }
    });

    test('4 Theme-Modi verfügbar', () {
      expect(AppThemeMode.values.length, 4);
    });
  });
}
