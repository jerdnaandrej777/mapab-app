import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'core/supabase/supabase_client.dart';

/// Entry Point der Travel Planner App
void main() async {
  // Flutter-Bindings initialisieren
  WidgetsFlutterBinding.ensureInitialized();

  // System UI Overlay Style - wird dynamisch in TravelPlannerApp angepasst basierend auf Theme

  // Hive für lokale Datenbank initialisieren
  await Hive.initFlutter();

  // Hive Boxes öffnen
  await Future.wait([
    Hive.openBox('favorites'),
    Hive.openBox('savedRoutes'),
    Hive.openBox('settings'),
    Hive.openBox('cache'),
    Hive.openBox('user_accounts'), // Account-System
  ]);

  // Supabase initialisieren (falls konfiguriert)
  await initializeSupabase();

  // App starten mit Riverpod Provider
  runApp(
    const ProviderScope(
      child: TravelPlannerApp(),
    ),
  );
}
