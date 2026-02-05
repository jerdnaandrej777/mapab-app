import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n/l10n.dart';
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
  bool _hasNavigated = false;
  bool _initialDelayDone = false;

  @override
  void initState() {
    super.initState();
    _startInitialDelay();
  }

  Future<void> _startInitialDelay() async {
    // Kurze Verzögerung für Splash-Animation
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      setState(() => _initialDelayDone = true);
    }
  }

  void _navigateTo(String route) {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    debugPrint('[Splash] Navigiere zu: $route');
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    // Warte auf initiale Verzögerung
    if (!_initialDelayDone) {
      return _buildSplashUI();
    }

    // 0. Prüfe Onboarding
    final hasSeenOnboarding = ref.watch(onboardingNotifierProvider);
    if (!hasSeenOnboarding) {
      // Post-Frame, um Navigation nach Build durchzuführen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateTo('/onboarding');
      });
      return _buildSplashUI();
    }

    // 1. Prüfe Cloud-Auth (Supabase)
    final authState = ref.watch(authNotifierProvider);

    // Wenn Cloud-Auth noch lädt, warte
    if (authState.status == AuthStatus.loading) {
      return _buildSplashUI();
    }

    // Cloud-User eingeloggt → direkt zur Hauptseite
    if (authState.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateTo('/');
      });
      return _buildSplashUI();
    }

    // 2. Prüfe lokalen Account (Gast-Modus)
    final accountAsync = ref.watch(accountNotifierProvider);

    return accountAsync.when(
      data: (account) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (account != null) {
            debugPrint('[Splash] Lokaler Account: ${account.displayName}');
            _navigateTo('/');
          } else {
            debugPrint('[Splash] Kein Account → Login');
            _navigateTo('/login');
          }
        });
        return _buildSplashUI();
      },
      loading: () => _buildSplashUI(),
      error: (_, __) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          debugPrint('[Splash] Fehler → Login');
          _navigateTo('/login');
        });
        return _buildSplashUI();
      },
    );
  }

  Widget _buildSplashUI() {
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
                color: Colors.white.withValues(alpha: 0.2),
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
            Text(
              context.l10n.splashTagline,
              style: const TextStyle(
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
              context.l10n.authLoadingText,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
