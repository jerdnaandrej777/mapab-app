import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';

part 'supabase_client.g.dart';

/// Initialisiert Supabase
Future<void> initializeSupabase() async {
  if (SupabaseConfig.supabaseUrl.isEmpty || SupabaseConfig.supabaseAnonKey.isEmpty) {
    debugPrint('[Supabase] ⚠️ Supabase nicht konfiguriert - Offline-Modus');
    debugPrint('[Supabase] Konfiguriere URL und Anon-Key in supabase_config.dart');
    return;
  }

  try {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
      debug: kDebugMode,
    );
    debugPrint('[Supabase] ✓ Erfolgreich initialisiert');
  } catch (e) {
    debugPrint('[Supabase] ✗ Initialisierung fehlgeschlagen: $e');
  }
}

/// Prüft ob Supabase verfügbar ist
bool get isSupabaseAvailable {
  if (SupabaseConfig.supabaseUrl.isEmpty || SupabaseConfig.supabaseAnonKey.isEmpty) {
    return false;
  }
  try {
    Supabase.instance;
    return true;
  } catch (e) {
    return false;
  }
}

/// Prüft ob ein User eingeloggt ist
bool get isAuthenticated {
  if (!isSupabaseAvailable) return false;
  return Supabase.instance.client.auth.currentUser != null;
}

/// Aktueller User (null wenn nicht eingeloggt)
User? get currentUser {
  if (!isSupabaseAvailable) return null;
  return Supabase.instance.client.auth.currentUser;
}

/// Provider für Supabase Client
@riverpod
SupabaseClient? supabase(SupabaseRef ref) {
  if (!isSupabaseAvailable) return null;
  return Supabase.instance.client;
}

/// Provider für Auth State Änderungen
@riverpod
Stream<AuthState> authStateChanges(AuthStateChangesRef ref) {
  if (!isSupabaseAvailable) return const Stream.empty();
  return Supabase.instance.client.auth.onAuthStateChange;
}

/// Provider für aktuellen User
@riverpod
User? currentUserProvider(CurrentUserProviderRef ref) {
  if (!isSupabaseAvailable) return null;

  // Lausche auf Auth-Änderungen
  ref.watch(authStateChangesProvider);

  return Supabase.instance.client.auth.currentUser;
}
