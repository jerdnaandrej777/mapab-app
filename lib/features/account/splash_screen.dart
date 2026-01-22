import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers/account_provider.dart';
import '../../data/providers/auth_provider.dart';
import '../onboarding/providers/onboarding_provider.dart';

/// Splash Screen mit Auth-Check
/// Prüft sowohl Cloud-Auth (Supabase) als auch lokale Accounts
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Warte kurz für Splash-Animation
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // 0. Prüfe ob Onboarding bereits gesehen wurde
    final hasSeenOnboarding = ref.read(onboardingNotifierProvider);

    if (!hasSeenOnboarding) {
      debugPrint('[Splash] Onboarding nicht gesehen → /onboarding');
      if (mounted) {
        context.go('/onboarding');
      }
      return;
    }

    // 1. Prüfe Cloud-Auth (Supabase) - hat Priorität
    final authState = ref.read(authNotifierProvider);

    // Warte kurz falls Auth noch lädt
    if (authState.status == AuthStatus.loading) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
    }

    // Erneut lesen nach potenziellem Laden
    final currentAuthState = ref.read(authNotifierProvider);

    // Cloud-User eingeloggt → direkt zur Hauptseite
    if (currentAuthState.isAuthenticated) {
      debugPrint('[Splash] Cloud-User eingeloggt: ${currentAuthState.userEmail}');
      if (mounted) {
        context.go('/');
      }
      return;
    }

    // 2. Prüfe lokalen Account (Gast-Modus)
    final accountAsync = ref.read(accountNotifierProvider);

    accountAsync.when(
      data: (account) {
        if (account != null) {
          // Lokaler Account vorhanden → Main Screen
          debugPrint('[Splash] Lokaler Account gefunden: ${account.displayName}');
          if (mounted) {
            context.go('/');
          }
        } else {
          // Kein Account → Login Screen
          debugPrint('[Splash] Kein Account gefunden → Login');
          if (mounted) {
            context.go('/login');
          }
        }
      },
      loading: () {
        // Warten bis geladen
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _checkAuthAndNavigate();
          }
        });
      },
      error: (_, __) {
        // Bei Fehler zum Login
        debugPrint('[Splash] Fehler beim Account-Laden → Login');
        if (mounted) {
          context.go('/login');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo/Icon
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.explore,
                size: 100,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 32),

            // App Name
            const Text(
              'MapAB',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),

            const SizedBox(height: 8),

            // Tagline
            const Text(
              'Dein AI-Reiseplaner',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
                letterSpacing: 1,
              ),
            ),

            const SizedBox(height: 48),

            // Loading Indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),

            const SizedBox(height: 16),

            // Status Text
            Text(
              'Lade...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
