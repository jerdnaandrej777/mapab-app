import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_planner/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'core/supabase/supabase_client.dart' show isAuthenticated, isSupabaseAvailable;
import 'core/widgets/gamification_overlay.dart';
import 'data/providers/settings_provider.dart';
import 'features/map/map_screen.dart';
import 'features/map/widgets/trip_mode_selector.dart';
import 'features/search/search_screen.dart';
import 'features/poi/poi_detail_screen.dart';
import 'features/trip/trip_screen.dart';
import 'features/random_trip/random_trip_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/account/login_screen.dart' as account_login;
import 'features/account/profile_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/auth/forgot_password_screen.dart';
import 'features/account/splash_screen.dart';
import 'features/favorites/favorites_screen.dart';
import 'features/navigation/navigation_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/journal/journal_screen.dart';
import 'features/sharing/qr_scanner_screen.dart';
import 'features/templates/trip_templates_screen.dart';
import 'features/social/gallery_screen.dart';
import 'features/social/trip_detail_public_screen.dart';
import 'features/admin/admin_screen.dart';
import 'features/leaderboard/leaderboard_screen.dart';
import 'features/challenges/challenges_screen.dart';

/// Haupt-App Widget
class TravelPlannerApp extends ConsumerWidget {
  const TravelPlannerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsNotifierProvider);
    final effectiveThemeMode = ref.watch(effectiveThemeModeProvider);

    // Wähle das richtige Dark Theme (normal oder OLED)
    final darkTheme = settings.isOledMode
        ? AppTheme.oledDarkTheme
        : AppTheme.darkTheme;

    // Bestimme ob Dark Mode aktiv ist
    final isDark = effectiveThemeMode == ThemeMode.dark ||
        (effectiveThemeMode == ThemeMode.system &&
            WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark);

    // System UI Overlay Style dynamisch anpassen
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: isDark ? AppTheme.darkSurfaceColor : AppTheme.surfaceColor,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );

    return MaterialApp.router(
      title: 'Travel Planner',
      debugShowCheckedModeBanner: false,

      // Lokalisierung
      locale: Locale(settings.language),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,

      // Theme mit Provider-Integration
      theme: AppTheme.lightTheme,
      darkTheme: darkTheme,
      themeMode: effectiveThemeMode,

      // Router
      routerConfig: _router,

      // Gamification Overlay für XP-Toasts und Achievement-Popups
      builder: (context, child) {
        return GamificationOverlay(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

/// GoRouter Konfiguration mit Account-Check
final _router = GoRouter(
  initialLocation: '/splash',
  debugLogDiagnostics: kDebugMode,

  // Auth-Guard: Geschützte Routen erfordern Login
  redirect: (context, state) {
    final path = state.uri.path;

    // Routen die Login erfordern
    const authRequired = ['/profile', '/favorites', '/settings'];

    // Prüfe ob die aktuelle Route Auth braucht
    final needsAuth = authRequired.any((route) => path.startsWith(route));

    if (needsAuth && isSupabaseAvailable && !isAuthenticated) {
      // Nicht eingeloggt → Redirect zu Login
      return '/login';
    }

    return null;
  },

  routes: [
    // Splash Screen (prüft Auth-Status)
    GoRoute(
      path: '/splash',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),

    // Onboarding (für neue User)
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),

    // Auth Screens
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      name: 'forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    // Legacy Login (lokales Profil)
    GoRoute(
      path: '/login-local',
      name: 'login-local',
      builder: (context, state) => const account_login.LoginScreen(),
    ),

    // Shell Route - nur noch MapScreen mit TripModeSelector
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        // Karte (Hauptscreen - einziger Tab)
        GoRoute(
          path: '/',
          name: 'map',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: MapScreen(),
          ),
        ),
      ],
    ),

    // Vollbild-Routen (ohne Bottom Navigation)
    GoRoute(
      path: '/search',
      name: 'search',
      builder: (context, state) {
        final isStart = state.uri.queryParameters['type'] == 'start';
        return SearchScreen(isStartLocation: isStart);
      },
    ),

    GoRoute(
      path: '/poi/:id',
      name: 'poi-detail',
      builder: (context, state) {
        final poiId = state.pathParameters['id']!;
        return POIDetailScreen(poiId: poiId);
      },
    ),

    // Trip-Screen (Push-Route fuer Google Maps Export)
    GoRoute(
      path: '/trip',
      name: 'trip',
      builder: (context, state) => const TripScreen(),
    ),

    // Navigation (Turn-by-Turn)
    GoRoute(
      path: '/navigation',
      name: 'navigation',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return NavigationScreen(
          route: extra['route'],
          stops: extra['stops'],
        );
      },
    ),

    // Zufalls-Trip Generator
    GoRoute(
      path: '/random-trip',
      name: 'random-trip',
      builder: (context, state) => const RandomTripScreen(),
    ),

    // Einstellungen
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsScreen(),
    ),

    // Profil
    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (context, state) => const ProfileScreen(),
    ),

    // Favoriten
    GoRoute(
      path: '/favorites',
      name: 'favorites',
      builder: (context, state) => const FavoritesScreen(),
    ),

    // Reisetagebuch
    GoRoute(
      path: '/journal/:tripId',
      name: 'journal',
      builder: (context, state) {
        final tripId = state.pathParameters['tripId']!;
        final tripName = state.uri.queryParameters['name'] ?? 'Reisetagebuch';
        return JournalScreen(tripId: tripId, tripName: tripName);
      },
    ),

    // QR-Code Scanner (Trip-Import)
    GoRoute(
      path: '/scan',
      name: 'scan',
      builder: (context, state) => const QRScannerScreen(),
    ),

    // Trip-Vorlagen
    GoRoute(
      path: '/templates',
      name: 'templates',
      builder: (context, state) => const TripTemplatesScreen(),
    ),

    // Trip-Galerie (Social Features)
    GoRoute(
      path: '/gallery',
      name: 'gallery',
      builder: (context, state) => const GalleryScreen(),
    ),

    // Oeffentlicher Trip Detail
    GoRoute(
      path: '/gallery/:tripId',
      name: 'gallery_detail',
      builder: (context, state) {
        final tripId = state.pathParameters['tripId']!;
        return TripDetailPublicScreen(tripId: tripId);
      },
    ),

    // Admin Dashboard
    GoRoute(
      path: '/admin',
      name: 'admin',
      builder: (context, state) => const AdminScreen(),
    ),

    // Leaderboard (Rangliste)
    GoRoute(
      path: '/leaderboard',
      name: 'leaderboard',
      builder: (context, state) => const LeaderboardScreen(),
    ),

    // Challenges (Herausforderungen)
    GoRoute(
      path: '/challenges',
      name: 'challenges',
      builder: (context, state) => const ChallengesScreen(),
    ),
  ],

  // Error Handler
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).pageNotFound,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(state.uri.toString()),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/'),
            child: Text(AppLocalizations.of(context).goToHome),
          ),
        ],
      ),
    ),
  ),
);

/// Main Shell mit TripModeSelector statt Bottom Navigation
class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Hauptinhalt (MapScreen)
          Positioned.fill(child: child),
          // TripModeSelector am unteren Rand
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: TripModeSelector(),
          ),
        ],
      ),
    );
  }
}
