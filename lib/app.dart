import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'core/supabase/supabase_client.dart' show isAuthenticated, isSupabaseAvailable;
import 'data/providers/settings_provider.dart';
import 'features/map/map_screen.dart';
import 'features/search/search_screen.dart';
import 'features/poi/poi_list_screen.dart';
import 'features/poi/poi_detail_screen.dart';
import 'features/trip/trip_screen.dart';
import 'features/ai_assistant/chat_screen.dart';
import 'features/random_trip/random_trip_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/account/login_screen.dart' as account_login;
import 'features/account/profile_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/auth/forgot_password_screen.dart';
import 'features/account/splash_screen.dart';
import 'features/favorites/favorites_screen.dart';
import 'features/onboarding/onboarding_screen.dart';

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

      // Theme mit Provider-Integration
      theme: AppTheme.lightTheme,
      darkTheme: darkTheme,
      themeMode: effectiveThemeMode,

      // Router
      routerConfig: _router,

      // Lokalisierung (für später)
      // localizationsDelegates: [...],
      // supportedLocales: [...],
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
    // Shell Route für Bottom Navigation
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        // Karte (Hauptscreen)
        GoRoute(
          path: '/',
          name: 'map',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: MapScreen(),
          ),
        ),

        // POI-Liste
        GoRoute(
          path: '/pois',
          name: 'pois',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: POIListScreen(),
          ),
        ),

        // Trip-Planung
        GoRoute(
          path: '/trip',
          name: 'trip',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: TripScreen(),
          ),
        ),

        // AI-Assistent
        GoRoute(
          path: '/assistant',
          name: 'assistant',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ChatScreen(),
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
            'Seite nicht gefunden',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(state.uri.toString()),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/'),
            child: const Text('Zur Startseite'),
          ),
        ],
      ),
    ),
  ),
);

/// Main Shell mit Bottom Navigation
class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: const MainBottomNavigation(),
    );
  }
}

/// Bottom Navigation Bar
class MainBottomNavigation extends StatelessWidget {
  const MainBottomNavigation({super.key});

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/pois')) return 1;
    if (location.startsWith('/trip')) return 2;
    if (location.startsWith('/assistant')) return 3;
    return 0; // Map ist default
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.map_outlined,
                activeIcon: Icons.map,
                label: 'Karte',
                isSelected: selectedIndex == 0,
                onTap: () => context.go('/'),
              ),
              _NavItem(
                icon: Icons.place_outlined,
                activeIcon: Icons.place,
                label: 'POIs',
                isSelected: selectedIndex == 1,
                onTap: () => context.go('/pois'),
              ),
              _NavItem(
                icon: Icons.route_outlined,
                activeIcon: Icons.route,
                label: 'Trip',
                isSelected: selectedIndex == 2,
                onTap: () => context.go('/trip'),
              ),
              _NavItem(
                icon: Icons.smart_toy_outlined,
                activeIcon: Icons.smart_toy,
                label: 'AI',
                isSelected: selectedIndex == 3,
                onTap: () => context.go('/assistant'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Navigation Item
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final color = isSelected
        ? colorScheme.primary
        : theme.textTheme.bodyMedium?.color ?? colorScheme.onSurface.withOpacity(0.6);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: isSelected
            ? BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
