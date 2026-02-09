import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'app.dart';
import 'core/supabase/supabase_client.dart';
import 'data/services/poi_cache_service.dart';

/// Sentry DSN via --dart-define
const _sentryDsn = String.fromEnvironment('SENTRY_DSN', defaultValue: '');

/// Hive-Verschluesselungs-Key aus SecureStorage
const _hiveKeyStorageKey = 'mapab_hive_encryption_key';
const _hiveSecureStorage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
  iOptions: IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  ),
);

class _HiveBoxConfig {
  final String name;
  final bool encrypted;
  final bool allowUnencryptedFallback;

  const _HiveBoxConfig({
    required this.name,
    required this.encrypted,
    this.allowUnencryptedFallback = false,
  });
}

const _requiredHiveBoxes = <_HiveBoxConfig>[
  _HiveBoxConfig(
    name: 'favorites',
    encrypted: true,
    allowUnencryptedFallback: true,
  ),
  _HiveBoxConfig(
    name: 'savedRoutes',
    encrypted: true,
    allowUnencryptedFallback: true,
  ),
  _HiveBoxConfig(
    name: 'settings',
    encrypted: true,
    allowUnencryptedFallback: true,
  ),
  _HiveBoxConfig(name: 'cache', encrypted: false),
  _HiveBoxConfig(
    name: 'user_accounts',
    encrypted: true,
    allowUnencryptedFallback: true,
  ),
  _HiveBoxConfig(
    name: 'active_trip',
    encrypted: true,
    allowUnencryptedFallback: true,
  ),
];

/// Laedt oder generiert den Hive-Verschluesselungs-Key
Future<List<int>> _getHiveEncryptionKey() async {
  try {
    final stored = await _hiveSecureStorage.read(key: _hiveKeyStorageKey);
    if (stored != null && stored.isNotEmpty) {
      final decoded = base64Decode(stored);
      if (decoded.length == 32) {
        return decoded;
      }
      debugPrint('[Hive] Ungueltiger Key in SecureStorage, generiere neu.');
    }
  } catch (e) {
    debugPrint('[Hive] Fehler beim Lesen des Encryption-Keys: $e');
  }

  final key = Hive.generateSecureKey();
  try {
    await _hiveSecureStorage.write(
      key: _hiveKeyStorageKey,
      value: base64Encode(key),
    );
  } catch (e) {
    // Startup darf nicht hart scheitern, wenn SecureStorage nicht verfuegbar ist.
    debugPrint('[Hive] Fehler beim Speichern des Encryption-Keys: $e');
  }
  return key;
}

/// Entry Point der Travel Planner App
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (_sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = _sentryDsn;
        options.tracesSampleRate = kDebugMode ? 1.0 : 0.2;
        options.environment = kDebugMode ? 'debug' : 'production';
        options.sendDefaultPii = false;
      },
      appRunner: () async {
        await _bootstrapApp();
        _runApp();
      },
    );
  } else {
    debugPrint('[Sentry] Nicht konfiguriert - Crash-Reporting deaktiviert');
    await _bootstrapApp();
    _runApp();
  }
}

Future<void> _bootstrapApp() async {
  _addStartupBreadcrumb('hive_init', status: 'start');
  await Hive.initFlutter();
  _addStartupBreadcrumb('hive_init', status: 'ok');

  _addStartupBreadcrumb('secure_storage', status: 'start');
  final encryptionKey = await _getHiveEncryptionKey();
  final cipher = HiveAesCipher(encryptionKey);
  _addStartupBreadcrumb('secure_storage', status: 'ok');

  _addStartupBreadcrumb('hive_open', status: 'start');
  await _openRequiredHiveBoxes(cipher);
  _addStartupBreadcrumb('hive_open', status: 'ok');

  _addStartupBreadcrumb('supabase_init', status: 'start');
  try {
    await initializeSupabase();
    _addStartupBreadcrumb('supabase_init', status: 'ok');
  } catch (e, stack) {
    _addStartupBreadcrumb('supabase_init', status: 'error', detail: '$e');
    await _captureStartupException('supabase_init', e, stack);
  }

  _addStartupBreadcrumb('cache_migration', status: 'start');
  try {
    final cacheService = POICacheService();
    await cacheService.init();
    await cacheService.clearCachedPOIsWithoutImages();
    _addStartupBreadcrumb('cache_migration', status: 'ok');
  } catch (e, stack) {
    _addStartupBreadcrumb('cache_migration', status: 'error', detail: '$e');
    await _captureStartupException('cache_migration', e, stack);
  }
}

Future<void> _openRequiredHiveBoxes(HiveAesCipher cipher) async {
  final failedBoxes = <String>[];

  for (final config in _requiredHiveBoxes) {
    final opened = await _openHiveBoxWithRecovery(
      config.name,
      cipher: config.encrypted ? cipher : null,
      allowUnencryptedFallback: config.allowUnencryptedFallback,
    );
    if (!opened) {
      failedBoxes.add(config.name);
    }
  }

  if (failedBoxes.isNotEmpty) {
    debugPrint('[Hive] Warnung: Einige Boxes konnten nicht geoeffnet werden: '
        '${failedBoxes.join(', ')}');
  }
}

Future<bool> _openHiveBoxWithRecovery(
  String name, {
  HiveCipher? cipher,
  bool allowUnencryptedFallback = false,
}) async {
  try {
    await Hive.openBox(name, encryptionCipher: cipher);
    return true;
  } catch (e, stack) {
    _addStartupBreadcrumb('hive_open', status: 'error', detail: '$name: $e');
    await _captureStartupException('hive_open:$name', e, stack);
  }

  await _resetHiveBox(name);

  try {
    await Hive.openBox(name, encryptionCipher: cipher);
    debugPrint('[Hive] Box nach Reset geoeffnet: $name');
    return true;
  } catch (e, stack) {
    _addStartupBreadcrumb(
      'hive_open',
      status: 'error',
      detail: '$name (after reset): $e',
    );
    await _captureStartupException('hive_open_reset:$name', e, stack);
  }

  if (cipher != null && allowUnencryptedFallback) {
    await _resetHiveBox(name);
    try {
      await Hive.openBox(name);
      debugPrint('[Hive] Box unverschluesselt als Fallback geoeffnet: $name');
      return true;
    } catch (e, stack) {
      _addStartupBreadcrumb(
        'hive_open',
        status: 'error',
        detail: '$name (unencrypted fallback): $e',
      );
      await _captureStartupException('hive_open_fallback:$name', e, stack);
    }
  }

  return false;
}

Future<void> _resetHiveBox(String name) async {
  try {
    if (Hive.isBoxOpen(name)) {
      await Hive.box(name).close();
    }
    await Hive.deleteBoxFromDisk(name);
  } catch (e) {
    debugPrint('[Hive] Reset von Box fehlgeschlagen ($name): $e');
  }
}

void _addStartupBreadcrumb(
  String phase, {
  required String status,
  String? detail,
}) {
  debugPrint('[Startup][$phase][$status] ${detail ?? ''}'.trim());
  if (_sentryDsn.isEmpty) return;

  Sentry.addBreadcrumb(
    Breadcrumb(
      category: 'startup',
      message: '$phase:$status',
      type: 'state',
      level: status == 'error' ? SentryLevel.error : SentryLevel.info,
      data: detail == null ? null : <String, dynamic>{'detail': detail},
    ),
  );
}

Future<void> _captureStartupException(
  String stage,
  Object error,
  StackTrace stackTrace,
) async {
  if (_sentryDsn.isEmpty) return;
  await Sentry.captureException(
    error,
    stackTrace: stackTrace,
    hint: Hint.withMap(<String, dynamic>{'startup_stage': stage}),
  );
}

/// Startet die App mit Error-Handling
void _runApp() {
  // Unbehandelte Flutter-Framework-Fehler abfangen
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    if (!kDebugMode && _sentryDsn.isNotEmpty) {
      Sentry.captureException(details.exception, stackTrace: details.stack);
    }
  };

  // Unbehandelte Dart-Fehler abfangen
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('[App] Unbehandelter Fehler: $error');
    if (!kDebugMode && _sentryDsn.isNotEmpty) {
      Sentry.captureException(error, stackTrace: stack);
    }
    return true;
  };

  // App starten mit Riverpod Provider
  runApp(
    const ProviderScope(
      child: TravelPlannerApp(),
    ),
  );
}
