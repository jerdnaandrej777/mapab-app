import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../services/auth_service.dart';
import '../../core/supabase/supabase_client.dart';

part 'auth_provider.g.dart';

/// Auth Status
enum AuthStatus {
  /// Wird geprüft (beim Start)
  loading,

  /// Nicht eingeloggt
  unauthenticated,

  /// Eingeloggt
  authenticated,

  /// Auth nicht verfügbar (Supabase nicht konfiguriert)
  unavailable,
}

/// App Auth State (eigene Klasse, nicht mit Supabase AuthState verwechseln)
@immutable
class AppAuthState {
  final AuthStatus status;
  final supa.User? user;
  final String? error;
  final bool isLoading;

  const AppAuthState({
    this.status = AuthStatus.loading,
    this.user,
    this.error,
    this.isLoading = false,
  });

  AppAuthState copyWith({
    AuthStatus? status,
    supa.User? user,
    String? error,
    bool? isLoading,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AppAuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      error: clearError ? null : (error ?? this.error),
      isLoading: isLoading ?? this.isLoading,
    );
  }

  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;
  bool get isAvailable => status != AuthStatus.unavailable;

  String? get userEmail => user?.email;
  String? get userId => user?.id;
  String get displayName {
    final metadata = user?.userMetadata;
    return metadata?['display_name'] as String? ??
        metadata?['username'] as String? ??
        user?.email?.split('@').first ??
        'User';
  }
}

/// Auth Notifier Provider
@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  late AuthService _authService;

  @override
  AppAuthState build() {
    _authService = ref.watch(authServiceProvider);

    // Prüfe ob Supabase verfügbar ist
    if (!_authService.isAvailable) {
      debugPrint('[AuthNotifier] Supabase nicht verfügbar - Offline-Modus');
      return const AppAuthState(status: AuthStatus.unavailable);
    }

    // Lausche auf Auth-Änderungen
    ref.listen(authStateChangesProvider, (previous, next) {
      next.whenData((supaAuthState) {
        _handleAuthStateChange(supaAuthState);
      });
    });

    // Initial State
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      return AppAuthState(status: AuthStatus.authenticated, user: currentUser);
    }

    return const AppAuthState(status: AuthStatus.unauthenticated);
  }

  /// Behandelt Auth State Änderungen von Supabase
  void _handleAuthStateChange(supa.AuthState supaAuthState) {
    debugPrint('[AuthNotifier] Auth State Change: ${supaAuthState.event}');

    switch (supaAuthState.event) {
      case supa.AuthChangeEvent.signedIn:
      case supa.AuthChangeEvent.tokenRefreshed:
      case supa.AuthChangeEvent.userUpdated:
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: supaAuthState.session?.user,
          clearError: true,
        );
        break;

      case supa.AuthChangeEvent.signedOut:
      // ignore: deprecated_member_use
      case supa.AuthChangeEvent.userDeleted:
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          clearUser: true,
        );
        break;

      case supa.AuthChangeEvent.passwordRecovery:
        // User hat Passwort-Reset Link geklickt
        debugPrint('[AuthNotifier] Passwort-Wiederherstellung aktiv');
        break;

      case supa.AuthChangeEvent.initialSession:
      case supa.AuthChangeEvent.mfaChallengeVerified:
        if (supaAuthState.session?.user != null) {
          state = state.copyWith(
            status: AuthStatus.authenticated,
            user: supaAuthState.session?.user,
          );
        }
        break;
    }
  }

  /// Login mit Email/Passwort
  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final user = await _authService.signIn(email: email, password: password);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        isLoading: false,
      );
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(error: e.message, isLoading: false);
      return false;
    } catch (e) {
      state = state.copyWith(error: 'Ein Fehler ist aufgetreten', isLoading: false);
      return false;
    }
  }

  /// Registrierung
  Future<bool> signUp({
    required String email,
    required String password,
    String? username,
    String? displayName,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final user = await _authService.signUp(
        email: email,
        password: password,
        username: username,
        displayName: displayName,
      );
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        isLoading: false,
      );
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(error: e.message, isLoading: false);
      return false;
    } catch (e) {
      state = state.copyWith(error: 'Ein Fehler ist aufgetreten', isLoading: false);
      return false;
    }
  }

  /// Logout
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);

    try {
      await _authService.signOut();
      state = const AppAuthState(status: AuthStatus.unauthenticated);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Passwort zurücksetzen
  Future<bool> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _authService.resetPassword(email);
      state = state.copyWith(isLoading: false);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(error: e.message, isLoading: false);
      return false;
    } catch (e) {
      state = state.copyWith(error: 'Ein Fehler ist aufgetreten', isLoading: false);
      return false;
    }
  }

  /// Fehler zurücksetzen
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}
