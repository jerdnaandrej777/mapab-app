import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'app.dart';
import 'core/supabase/supabase_client.dart';
import 'data/services/poi_cache_service.dart';

/// Sentry DSN via --dart-define
const _sentryDsn = String.fromEnvironment('SENTRY_DSN', defaultValue: '');

/// Entry Point der Travel Planner App
Future<void> main() async {
  // Flutter-Bindings initialisieren
  WidgetsFlutterBinding.ensureInitialized();

  // Hive für lokale Datenbank initialisieren
  await Hive.initFlutter();

  // Hive Boxes öffnen
  await Future.wait([
    Hive.openBox('favorites'),
    Hive.openBox('savedRoutes'),
    Hive.openBox('settings'),
    Hive.openBox('cache'),
    Hive.openBox('user_accounts'), // Account-System
    Hive.openBox('active_trip'), // Aktiver Trip für Mehrtages-Reisen
  ]);

  // Supabase initialisieren (falls konfiguriert)
  await initializeSupabase();

  // v1.6.0: Einmalige Cache-Migration - entferne POIs ohne Bilder aus altem Cache
  final cacheService = POICacheService();
  await cacheService.init();
  await cacheService.clearCachedPOIsWithoutImages();

  // App mit Sentry Crash-Reporting starten (falls DSN konfiguriert)
  if (_sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = _sentryDsn;
        options.tracesSampleRate = kDebugMode ? 1.0 : 0.2;
        options.environment = kDebugMode ? 'debug' : 'production';
        options.sendDefaultPii = false;
      },
      appRunner: () => _runApp(),
    );
  } else {
    debugPrint('[Sentry] Nicht konfiguriert - Crash-Reporting deaktiviert');
    _runApp();
  }
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
