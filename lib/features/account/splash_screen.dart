import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers/account_provider.dart';

/// Splash Screen mit Account-Check
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAccountAndNavigate();
  }

  Future<void> _checkAccountAndNavigate() async {
    // Warte kurz für Splash-Animation
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Prüfe ob Account vorhanden
    final accountAsync = ref.read(accountNotifierProvider);

    accountAsync.when(
      data: (account) {
        if (account != null) {
          // Account vorhanden → Main Screen
          context.go('/');
        } else {
          // Kein Account → Login Screen
          context.go('/login');
        }
      },
      loading: () {
        // Warten bis geladen
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _checkAccountAndNavigate();
          }
        });
      },
      error: (_, __) {
        // Bei Fehler zum Login
        context.go('/login');
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
          ],
        ),
      ),
    );
  }
}
