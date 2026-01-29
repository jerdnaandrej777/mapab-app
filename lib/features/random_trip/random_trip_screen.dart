import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import 'providers/random_trip_provider.dart';
import 'providers/random_trip_state.dart';
import 'widgets/category_selector.dart';
import 'widgets/days_selector.dart';
import 'widgets/hotel_suggestion_card.dart';
import 'widgets/radius_slider.dart';
import 'widgets/start_location_picker.dart';
import 'widgets/trip_preview_card.dart';

/// Hauptscreen für Zufalls-Tagesausflug und Euro Trip
class RandomTripScreen extends ConsumerWidget {
  const RandomTripScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(randomTripNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          state.mode == RandomTripMode.daytrip
              ? 'AI Tagesausflug'
              : 'AI Euro Trip',
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            ref.read(randomTripNotifierProvider.notifier).reset();
            context.pop();
          },
        ),
        actions: [
          if (state.step == RandomTripStep.preview)
            TextButton(
              onPressed: () {
                ref.read(randomTripNotifierProvider.notifier).backToConfig();
              },
              child: const Text('Bearbeiten'),
            ),
        ],
      ),
      body: switch (state.step) {
        RandomTripStep.config => _ConfigView(),
        RandomTripStep.generating => const _GeneratingView(),
        RandomTripStep.preview => _PreviewView(),
        RandomTripStep.confirmed => _ConfirmedView(),
      },
    );
  }
}

/// Konfigurations-Ansicht
class _ConfigView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(randomTripNotifierProvider);
    final notifier = ref.read(randomTripNotifierProvider.notifier);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mode Selector
                _ModeSelector(
                  selectedMode: state.mode,
                  onModeChanged: notifier.setMode,
                ),
                const SizedBox(height: 24),

                // Start Location
                const StartLocationPicker(),
                const SizedBox(height: 24),

                // Radius
                const RadiusSlider(),
                const SizedBox(height: 24),

                // Days Selector (nur fur Euro Trip)
                if (state.mode == RandomTripMode.eurotrip) ...[
                  const DaysSelector(),
                  const SizedBox(height: 24),
                ],

                // Categories
                const CategorySelector(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),

        // Generate Button
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: state.canGenerate
                    ? () => notifier.generateTrip()
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🎲', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(
                      state.mode == RandomTripMode.daytrip
                          ? 'Uberrasch mich!'
                          : 'Trip generieren',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Mode Selector (Tagesausflug / Euro Trip)
class _ModeSelector extends StatelessWidget {
  final RandomTripMode selectedMode;
  final Function(RandomTripMode) onModeChanged;

  const _ModeSelector({
    required this.selectedMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: RandomTripMode.values.map((mode) {
        final isSelected = mode == selectedMode;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: mode == RandomTripMode.daytrip ? 8 : 0,
            ),
            child: Material(
              color: isSelected
                  ? AppTheme.primaryColor.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => onModeChanged(mode),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : Colors.grey.withOpacity(0.2),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        mode.icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mode.label,
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected
                              ? AppTheme.primaryColor
                              : AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Generierungs-Ansicht (Loading)
class _GeneratingView extends StatelessWidget {
  const _GeneratingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation(AppTheme.primaryColor),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '🎲',
            style: TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 16),
          Text(
            'Trip wird generiert...',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'POIs laden, Route optimieren, Hotels suchen',
            style: TextStyle(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Vorschau-Ansicht
class _PreviewView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(randomTripNotifierProvider);
    final notifier = ref.read(randomTripNotifierProvider.notifier);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TripPreviewCard(),
                const SizedBox(height: 24),

                // Hotel-Vorschlage (fur Mehrtages-Trips)
                if (state.isMultiDay &&
                    state.hotelSuggestions.isNotEmpty) ...[
                  HotelSuggestionsSection(
                    suggestionsByDay: state.hotelSuggestions,
                    selectedHotels: state.selectedHotels,
                    onSelect: notifier.selectHotel,
                  ),
                ],
              ],
            ),
          ),
        ),

        // Action Buttons
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => notifier.regenerateTrip(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Neu'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => notifier.confirmTrip(),
                    icon: const Icon(Icons.check),
                    label: const Text('Trip speichern'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Bestatigungs-Ansicht
class _ConfirmedView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(randomTripNotifierProvider);
    final trip = state.generatedTrip?.trip;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                size: 64,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Trip gespeichert!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            if (trip != null)
              Text(
                trip.name,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    ref.read(randomTripNotifierProvider.notifier).reset();
                    context.pop();
                  },
                  icon: const Icon(Icons.home),
                  label: const Text('Zuruck'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    // Zur Trip-Ansicht navigieren
                    context.go('/trip');
                  },
                  icon: const Icon(Icons.route),
                  label: const Text('Trip anzeigen'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
