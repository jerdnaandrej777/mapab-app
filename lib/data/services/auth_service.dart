import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase/supabase_client.dart';

part 'auth_service.g.dart';

/// Exception für Auth-Fehler
class AuthException implements Exception {
  final String message;
  final String? code;

  AuthException(this.message, {this.code});

  @override
  String toString() => 'AuthException: $message${code != null ? ' ($code)' : ''}';

  /// Erstellt AuthException aus Supabase AuthException
  factory AuthException.fromSupabase(AuthApiException e) {
    String message;
    switch (e.statusCode) {
      case '400':
        message = 'Ungültige Anfrage';
        break;
      case '401':
        message = 'Ungültige Anmeldedaten';
        break;
      case '422':
        if (e.message.contains('already registered')) {
          message = 'Diese E-Mail ist bereits registriert';
        } else if (e.message.contains('invalid')) {
          message = 'Ungültige E-Mail oder Passwort';
        } else {
          message = 'Validierungsfehler: ${e.message}';
        }
        break;
      case '429':
        message = 'Zu viele Anfragen. Bitte warte einen Moment.';
        break;
      default:
        message = e.message;
    }
    return AuthException(message, code: e.statusCode);
  }
}

/// Auth Service für Supabase
class AuthService {
  final SupabaseClient? _client;

  AuthService(this._client);

  /// Supabase ist verfügbar
  bool get isAvailable => _client != null;

  /// Aktueller User
  User? get currentUser => _client?.auth.currentUser;

  /// Ist eingeloggt?
  bool get isLoggedIn => currentUser != null;

  /// Registrierung mit Email/Passwort
  Future<User?> signUp({
    required String email,
    required String password,
    String? username,
    String? displayName,
  }) async {
    if (_client == null) {
      throw AuthException('Supabase nicht verfügbar', code: 'NOT_AVAILABLE');
    }

    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          if (username != null) 'username': username,
          if (displayName != null) 'display_name': displayName,
        },
      );

      if (response.user == null) {
        throw AuthException('Registrierung fehlgeschlagen');
      }

      debugPrint('[Auth] ✓ Registrierung erfolgreich: ${response.user?.email}');
      return response.user;
    } on AuthApiException catch (e) {
      debugPrint('[Auth] ✗ Registrierung fehlgeschlagen: ${e.message}');
      throw AuthException.fromSupabase(e);
    } catch (e) {
      debugPrint('[Auth] ✗ Registrierung fehlgeschlagen: $e');
      throw AuthException('Ein unerwarteter Fehler ist aufgetreten');
    }
  }

  /// Login mit Email/Passwort
  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    if (_client == null) {
      throw AuthException('Supabase nicht verfügbar', code: 'NOT_AVAILABLE');
    }

    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw AuthException('Login fehlgeschlagen');
      }

      debugPrint('[Auth] ✓ Login erfolgreich: ${response.user?.email}');
      return response.user;
    } on AuthApiException catch (e) {
      debugPrint('[Auth] ✗ Login fehlgeschlagen: ${e.message}');
      throw AuthException.fromSupabase(e);
    } catch (e) {
      debugPrint('[Auth] ✗ Login fehlgeschlagen: $e');
      throw AuthException('Ein unerwarteter Fehler ist aufgetreten');
    }
  }

  /// Passwort-Reset anfordern
  Future<void> resetPassword(String email) async {
    if (_client == null) {
      throw AuthException('Supabase nicht verfügbar', code: 'NOT_AVAILABLE');
    }

    try {
      await _client.auth.resetPasswordForEmail(email);
      debugPrint('[Auth] ✓ Passwort-Reset E-Mail gesendet an: $email');
    } on AuthApiException catch (e) {
      debugPrint('[Auth] ✗ Passwort-Reset fehlgeschlagen: ${e.message}');
      throw AuthException.fromSupabase(e);
    } catch (e) {
      debugPrint('[Auth] ✗ Passwort-Reset fehlgeschlagen: $e');
      throw AuthException('Ein unerwarteter Fehler ist aufgetreten');
    }
  }

  /// Logout
  Future<void> signOut() async {
    if (_client == null) {
      debugPrint('[Auth] Logout nicht erforderlich - nicht eingeloggt');
      return;
    }

    try {
      await _client.auth.signOut();
      debugPrint('[Auth] ✓ Logout erfolgreich');
    } catch (e) {
      debugPrint('[Auth] ✗ Logout fehlgeschlagen: $e');
    }
  }

  /// Session erneuern
  Future<void> refreshSession() async {
    if (_client == null) return;

    try {
      await _client.auth.refreshSession();
      debugPrint('[Auth] ✓ Session erneuert');
    } catch (e) {
      debugPrint('[Auth] ✗ Session-Erneuerung fehlgeschlagen: $e');
    }
  }
}

/// Provider für Auth Service
@riverpod
AuthService authService(AuthServiceRef ref) {
  final client = ref.watch(supabaseProvider);
  return AuthService(client);
}
