import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'core/supabase/supabase_client.dart';
import 'data/services/poi_cache_service.dart';

/// Entry Point der Travel Planner App
void main() async {
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

  // App starten mit Riverpod Provider
  runApp(
    const ProviderScope(
      child: TravelPlannerApp(),
    ),
  );
}
