import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/l10n.dart';
import '../providers/app_ui_mode_provider.dart';
import '../providers/map_controller_provider.dart';
import '../../random_trip/providers/random_trip_provider.dart';
import '../../random_trip/providers/random_trip_state.dart';

/// 2 große Buttons am unteren Bildschirmrand: AI Tagestrip / AI Euro Trip
/// Ersetzt die alte 4-Tab Bottom Navigation
class TripModeSelector extends ConsumerWidget {
  const TripModeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(appUIModeNotifierProvider);
    final randomTripState = ref.watch(randomTripNotifierProvider);
    final isRouteFocusMode = ref.watch(mapRouteFocusModeProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Ausblenden waehrend Generierung und sobald ein Trip generiert wurde
    final isGenerating = randomTripState.step == RandomTripStep.generating;
    final hasGeneratedTrip = (randomTripState.step == RandomTripStep.preview ||
            randomTripState.step == RandomTripStep.confirmed) &&
        randomTripState.generatedTrip != null;

    if (isGenerating || hasGeneratedTrip || isRouteFocusMode) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: _TripModeButton(
                  label: context.l10n.mapModeAiDayTrip,
                  icon: Icons.wb_sunny_outlined,
                  activeIcon: Icons.wb_sunny,
                  isSelected: currentMode == MapPlanMode.aiTagestrip,
                  onTap: () => _setMode(ref, MapPlanMode.aiTagestrip),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TripModeButton(
                  label: context.l10n.mapModeAiEuroTrip,
                  icon: Icons.flight_outlined,
                  activeIcon: Icons.flight,
                  isSelected: currentMode == MapPlanMode.aiEuroTrip,
                  onTap: () => _setMode(ref, MapPlanMode.aiEuroTrip),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _setMode(WidgetRef ref, MapPlanMode mode) {
    ref.read(appUIModeNotifierProvider.notifier).setMode(mode);
    // Synchronisiere mit RandomTripProvider
    final targetMode = mode == MapPlanMode.aiTagestrip
        ? RandomTripMode.daytrip
        : RandomTripMode.eurotrip;
    ref.read(randomTripNotifierProvider.notifier).setMode(targetMode);
  }
}

class _TripModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TripModeButton({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Material(
        color: isSelected
            ? colorScheme.primary
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        elevation: isSelected ? 2 : 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
