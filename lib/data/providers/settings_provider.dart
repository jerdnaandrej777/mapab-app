import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

part 'settings_provider.g.dart';

/// Theme Modus Einstellungen
enum AppThemeMode {
  system('System', Icons.brightness_auto),
  light('Hell', Icons.light_mode),
  dark('Dunkel', Icons.dark_mode),
  oled('OLED Schwarz', Icons.brightness_1);

  final String label;
  final IconData icon;
  const AppThemeMode(this.label, this.icon);
}

/// App-Einstellungen State
class AppSettings {
  final AppThemeMode themeMode;
  final bool autoSunsetDarkMode;
  final double sunsetLatitude;
  final double sunsetLongitude;
  final String language;
  final bool hapticFeedback;
  final bool soundEffects;
  // Remember Me Feature
  final bool rememberMe;
  final String? savedEmail;

  const AppSettings({
    this.themeMode = AppThemeMode.system,
    this.autoSunsetDarkMode = false,
    this.sunsetLatitude = 51.1657,  // Deutschland Mitte
    this.sunsetLongitude = 10.4515,
    this.language = 'de',
    this.hapticFeedback = true,
    this.soundEffects = true,
    this.rememberMe = false,
    this.savedEmail,
  });

  AppSettings copyWith({
    AppThemeMode? themeMode,
    bool? autoSunsetDarkMode,
    double? sunsetLatitude,
    double? sunsetLongitude,
    String? language,
    bool? hapticFeedback,
    bool? soundEffects,
    bool? rememberMe,
    String? savedEmail,
    bool clearCredentials = false,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      autoSunsetDarkMode: autoSunsetDarkMode ?? this.autoSunsetDarkMode,
      sunsetLatitude: sunsetLatitude ?? this.sunsetLatitude,
      sunsetLongitude: sunsetLongitude ?? this.sunsetLongitude,
      language: language ?? this.language,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      soundEffects: soundEffects ?? this.soundEffects,
      rememberMe: rememberMe ?? this.rememberMe,
      savedEmail: clearCredentials ? null : (savedEmail ?? this.savedEmail),
    );
  }

  /// Prüft ob gespeicherte Credentials vorhanden sind
  /// Hinweis: Passwort wird über flutter_secure_storage gespeichert, nicht im State
  bool get hasStoredCredentials => rememberMe && savedEmail != null;

  /// Konvertiert den aktuellen ThemeMode zu Flutter's ThemeMode
  ThemeMode get flutterThemeMode {
    switch (themeMode) {
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
      case AppThemeMode.oled:
        return ThemeMode.dark;
    }
  }

  /// Prüft ob OLED-Modus aktiv ist
  bool get isOledMode => themeMode == AppThemeMode.oled;

  /// Serialisiert zu Map für Hive
  Map<String, dynamic> toJson() => {
    'themeMode': themeMode.index,
    'autoSunsetDarkMode': autoSunsetDarkMode,
    'sunsetLatitude': sunsetLatitude,
    'sunsetLongitude': sunsetLongitude,
    'language': language,
    'hapticFeedback': hapticFeedback,
    'soundEffects': soundEffects,
    'rememberMe': rememberMe,
    'savedEmail': savedEmail,
    // Hinweis: Passwort wird NICHT in Hive gespeichert, sondern in flutter_secure_storage
  };

  /// Deserialisiert von Map
  factory AppSettings.fromJson(Map<dynamic, dynamic> json) {
    return AppSettings(
      themeMode: AppThemeMode.values[json['themeMode'] as int? ?? 0],
      autoSunsetDarkMode: json['autoSunsetDarkMode'] as bool? ?? false,
      sunsetLatitude: (json['sunsetLatitude'] as num?)?.toDouble() ?? 51.1657,
      sunsetLongitude: (json['sunsetLongitude'] as num?)?.toDouble() ?? 10.4515,
      language: json['language'] as String? ?? 'de',
      hapticFeedback: json['hapticFeedback'] as bool? ?? true,
      soundEffects: json['soundEffects'] as bool? ?? true,
      rememberMe: json['rememberMe'] as bool? ?? false,
      savedEmail: json['savedEmail'] as String?,
    );
  }
}

/// Secure Storage Instanz für Passwort-Speicherung
const _secureStorage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);
const _secureKeyPassword = 'mapab_saved_password';

/// Settings Provider mit Hive Persistenz
@Riverpod(keepAlive: true)
class SettingsNotifier extends _$SettingsNotifier {
  late Box _settingsBox;

  @override
  AppSettings build() {
    _settingsBox = Hive.box('settings');
    _migrateOldCredentials();
    return _loadSettings();
  }

  /// Migriert alte Base64-Passwörter aus Hive zu Secure Storage
  void _migrateOldCredentials() {
    try {
      final json = _settingsBox.get('appSettings');
      if (json != null) {
        final oldEncoded = json['savedPasswordEncoded'] as String?;
        if (oldEncoded != null) {
          // Altes Base64-Passwort dekodieren und in Secure Storage migrieren
          final password = utf8.decode(base64Decode(oldEncoded));
          _secureStorage.write(key: _secureKeyPassword, value: password);
          // Altes Passwort aus Hive entfernen
          final updatedJson = Map<String, dynamic>.from(json);
          updatedJson.remove('savedPasswordEncoded');
          _settingsBox.put('appSettings', updatedJson);
          debugPrint('[Settings] Alte Credentials zu Secure Storage migriert');
        }
      }
    } catch (e) {
      debugPrint('[Settings] Migration fehlgeschlagen: $e');
    }
  }

  AppSettings _loadSettings() {
    final json = _settingsBox.get('appSettings');
    if (json != null) {
      return AppSettings.fromJson(Map<String, dynamic>.from(json));
    }
    return const AppSettings();
  }

  Future<void> _saveSettings() async {
    await _settingsBox.put('appSettings', state.toJson());
  }

  /// Setzt den Theme-Modus
  Future<void> setThemeMode(AppThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _saveSettings();
  }

  /// Aktiviert/Deaktiviert automatischen Dark Mode bei Sonnenuntergang
  Future<void> setAutoSunsetDarkMode(bool enabled) async {
    state = state.copyWith(autoSunsetDarkMode: enabled);
    await _saveSettings();
  }

  /// Setzt den Standort für Sonnenuntergangs-Berechnung
  Future<void> setSunsetLocation(double lat, double lng) async {
    state = state.copyWith(sunsetLatitude: lat, sunsetLongitude: lng);
    await _saveSettings();
  }

  /// Setzt die Sprache
  Future<void> setLanguage(String lang) async {
    state = state.copyWith(language: lang);
    await _saveSettings();
  }

  /// Aktiviert/Deaktiviert haptisches Feedback
  Future<void> setHapticFeedback(bool enabled) async {
    state = state.copyWith(hapticFeedback: enabled);
    await _saveSettings();
  }

  /// Aktiviert/Deaktiviert Sound-Effekte
  Future<void> setSoundEffects(bool enabled) async {
    state = state.copyWith(soundEffects: enabled);
    await _saveSettings();
  }

  /// Aktiviert/Deaktiviert "Anmeldedaten merken"
  Future<void> setRememberMe(bool enabled) async {
    if (!enabled) {
      // Wenn deaktiviert, lösche gespeicherte Credentials
      state = state.copyWith(rememberMe: false, clearCredentials: true);
    } else {
      state = state.copyWith(rememberMe: true);
    }
    await _saveSettings();
  }

  /// Speichert Login-Credentials (Passwort in Secure Storage, Email in Hive)
  Future<void> saveCredentials(String email, String password) async {
    await _secureStorage.write(key: _secureKeyPassword, value: password);
    state = state.copyWith(
      rememberMe: true,
      savedEmail: email,
    );
    await _saveSettings();
    debugPrint('[Settings] Anmeldedaten gespeichert');
  }

  /// Löscht gespeicherte Credentials
  Future<void> clearCredentials() async {
    await _secureStorage.delete(key: _secureKeyPassword);
    state = state.copyWith(rememberMe: false, clearCredentials: true);
    await _saveSettings();
    debugPrint('[Settings] Gespeicherte Anmeldedaten gelöscht');
  }

  /// Liest das gespeicherte Passwort aus Secure Storage
  Future<String?> getSavedPassword() async {
    if (!state.hasStoredCredentials) return null;
    try {
      return await _secureStorage.read(key: _secureKeyPassword);
    } catch (e) {
      debugPrint('[Settings] Fehler beim Lesen des Passworts: $e');
      return null;
    }
  }

  /// Prüft ob Dark Mode basierend auf Sonnenuntergang aktiv sein sollte
  bool shouldUseDarkModeForSunset() {
    if (!state.autoSunsetDarkMode) return false;

    final now = DateTime.now();
    final sunset = _calculateSunset(now, state.sunsetLatitude, state.sunsetLongitude);
    final sunrise = _calculateSunrise(now, state.sunsetLatitude, state.sunsetLongitude);

    // Dark Mode zwischen Sonnenuntergang und Sonnenaufgang
    return now.isAfter(sunset) || now.isBefore(sunrise);
  }

  /// Berechnet ungefähre Sonnenuntergangszeit (vereinfacht)
  DateTime _calculateSunset(DateTime date, double lat, double lng) {
    // Vereinfachte Berechnung - im Winter früher, im Sommer später
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
    final baseHour = 18.0; // 18:00 als Basis
    final variation = 2.5 * _cos((dayOfYear - 172) * 2 * 3.14159 / 365);
    final hour = baseHour + variation;
    return DateTime(date.year, date.month, date.day, hour.floor(), ((hour % 1) * 60).floor());
  }

  /// Berechnet ungefähre Sonnenaufgangszeit (vereinfacht)
  DateTime _calculateSunrise(DateTime date, double lat, double lng) {
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
    final baseHour = 6.0; // 6:00 als Basis
    final variation = 2.5 * _cos((dayOfYear - 172) * 2 * 3.14159 / 365);
    final hour = baseHour - variation;
    return DateTime(date.year, date.month, date.day, hour.floor(), ((hour % 1) * 60).floor());
  }

  double _cos(double x) => (x >= 0 ? 1 : -1) * (1 - (x * x) / 2 + (x * x * x * x) / 24);
}

/// Aktueller effektiver ThemeMode (berücksichtigt Sonnenuntergang)
@riverpod
ThemeMode effectiveThemeMode(EffectiveThemeModeRef ref) {
  final settings = ref.watch(settingsNotifierProvider);
  final notifier = ref.read(settingsNotifierProvider.notifier);

  // Bei System-Modus die Platform-Einstellung verwenden
  if (settings.themeMode == AppThemeMode.system) {
    // Prüfe ob Auto-Sunset aktiv ist
    if (notifier.shouldUseDarkModeForSunset()) {
      return ThemeMode.dark;
    }
    return ThemeMode.system;
  }

  // Bei Auto-Sunset Einstellung
  if (settings.autoSunsetDarkMode &&
      settings.themeMode == AppThemeMode.light &&
      notifier.shouldUseDarkModeForSunset()) {
    return ThemeMode.dark;
  }

  return settings.flutterThemeMode;
}

/// Prüft ob aktuell Dark Mode aktiv ist (für UI-Anpassungen)
@riverpod
bool isDarkMode(IsDarkModeRef ref) {
  final settings = ref.watch(settingsNotifierProvider);
  final effectiveMode = ref.watch(effectiveThemeModeProvider);

  if (effectiveMode == ThemeMode.dark) return true;
  if (effectiveMode == ThemeMode.light) return false;

  // Bei System-Modus: Platform-Brightness prüfen
  final brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
  return brightness == Brightness.dark;
}
