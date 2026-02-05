import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/l10n/l10n.dart';
import 'models/onboarding_page_data.dart';
import 'providers/onboarding_provider.dart';
import 'widgets/animated_ai_circle.dart';
import 'widgets/animated_route.dart';
import 'widgets/animated_sync.dart';
import 'widgets/onboarding_page.dart';
import 'widgets/page_indicator.dart';

/// Haupt-Onboarding-Screen mit PageView
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Die drei Onboarding-Seiten
  late final List<OnboardingPageData> _pages;
  bool _pagesInitialized = false;

  @override
  void initState() {
    super.initState();

    // System UI anpassen (dunkle Status Bar)
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF0F172A),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_pagesInitialized) {
      _pagesInitialized = true;
      final l10n = context.l10n;
      _pages = [
        OnboardingPageData(
          title: l10n.onboardingTitle1,
          highlightWord: l10n.onboardingHighlight1,
          subtitle: l10n.onboardingSubtitle1,
          highlightColor: const Color(0xFF3B82F6),  // Blue
          animationBuilder: () => const AnimatedRoute(),
        ),
        OnboardingPageData(
          title: l10n.onboardingTitle2,
          highlightWord: l10n.onboardingHighlight2,
          subtitle: l10n.onboardingSubtitle2,
          highlightColor: const Color(0xFF06B6D4),  // Cyan
          animationBuilder: () => const AnimatedAICircle(),
        ),
        OnboardingPageData(
          title: l10n.onboardingTitle3,
          highlightWord: l10n.onboardingHighlight3,
          subtitle: l10n.onboardingSubtitle3,
          highlightColor: const Color(0xFF22C55E),  // Green
          animationBuilder: () => const AnimatedSync(),
        ),
      ];
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  void _completeOnboarding() async {
    // Onboarding als abgeschlossen markieren
    await ref.read(onboardingNotifierProvider.notifier).completeOnboarding();

    // Zur Login-Seite navigieren
    if (mounted) {
      context.go('/login');
    }
  }

  void _goToLogin() async {
    await ref.read(onboardingNotifierProvider.notifier).completeOnboarding();
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF0F172A);  // Immer dunkler Hintergrund

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header: Logo + Überspringen
            _buildHeader(),

            // PageView mit Seiten
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return OnboardingPage(data: _pages[index]);
                },
              ),
            ),

            // Page Indicator
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: PageIndicator(
                currentPage: _currentPage,
                pageCount: _pages.length,
              ),
            ),

            // Buttons
            _buildButtons(),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo/App-Name
          Text(
            'MapAB',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
              letterSpacing: 1,
            ),
          ),

          // Überspringen-Button
          TextButton(
            onPressed: _skipOnboarding,
            child: Text(
              context.l10n.skip,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    final isLastPage = _currentPage == _pages.length - 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Haupt-Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: isLastPage ? _completeOnboarding : _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                isLastPage ? context.l10n.onboardingStart : context.l10n.next,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Sekundär-Button (nur auf letzter Seite)
          if (isLastPage) ...[
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: _goToLogin,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  context.l10n.authExistingAccount,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
