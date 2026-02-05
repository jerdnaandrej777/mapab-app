import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/utils/location_helper.dart';
import '../../../core/constants/categories.dart';
import '../../../core/constants/trip_constants.dart';
import '../../../data/models/route.dart';
import '../../../data/providers/active_trip_provider.dart';
import '../../../data/repositories/geocoding_repo.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../random_trip/providers/random_trip_provider.dart';
import '../../random_trip/providers/random_trip_state.dart';
import '../providers/app_ui_mode_provider.dart';
import '../providers/route_planner_provider.dart';
import '../../trip/providers/trip_state_provider.dart';
import 'unified_weather_widget.dart';

/// Trip Config Panel - vereint AI Tagestrip und AI Euro Trip
class TripConfigPanel extends ConsumerStatefulWidget {
  final MapPlanMode mode;
  final bool bare;

  const TripConfigPanel({super.key, required this.mode, this.bare = false});

  @override
  ConsumerState<TripConfigPanel> createState() => _TripConfigPanelState();
}

class _TripConfigPanelState extends ConsumerState<TripConfigPanel> {
  final _addressController = TextEditingController();
  final _focusNode = FocusNode();
  List<GeocodingResult> _suggestions = [];
  bool _isSearching = false;

  // Ziel-Eingabe Controller
  final _destinationController = TextEditingController();
  final _destinationFocusNode = FocusNode();
  List<GeocodingResult> _destinationSuggestions = [];
  bool _isSearchingDestination = false;

  @override
  void dispose() {
    _addressController.dispose();
    _focusNode.dispose();
    _destinationController.dispose();
    _destinationFocusNode.dispose();
    super.dispose();
  }

  Future<void> _searchAddress(String query) async {
    if (query.length < 3) {
      setState(() => _suggestions = []);
      return;
    }

    setState(() => _isSearching = true);

    try {
      final geocodingRepo = ref.read(geocodingRepositoryProvider);
      final results = await geocodingRepo.geocode(query);
      setState(() {
        _suggestions = results.take(5).toList();
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _suggestions = [];
        _isSearching = false;
      });
    }
  }

  void _selectSuggestion(GeocodingResult result) {
    final notifier = ref.read(randomTripNotifierProvider.notifier);
    notifier.setStartLocation(result.location, result.shortName ?? result.displayName);
    _addressController.text = result.shortName ?? result.displayName;
    setState(() => _suggestions = []);
    _focusNode.unfocus();
  }

  /// Suche für Ziel-Adresse
  Future<void> _searchDestination(String query) async {
    if (query.length < 3) {
      setState(() => _destinationSuggestions = []);
      return;
    }

    setState(() => _isSearchingDestination = true);

    try {
      final geocodingRepo = ref.read(geocodingRepositoryProvider);
      final results = await geocodingRepo.geocode(query);
      setState(() {
        _destinationSuggestions = results.take(5).toList();
        _isSearchingDestination = false;
      });
    } catch (e) {
      setState(() {
        _destinationSuggestions = [];
        _isSearchingDestination = false;
      });
    }
  }

  void _selectDestinationSuggestion(GeocodingResult result) {
    final notifier = ref.read(randomTripNotifierProvider.notifier);
    notifier.setDestination(result.location, result.shortName ?? result.displayName);
    _destinationController.text = result.shortName ?? result.displayName;
    setState(() => _destinationSuggestions = []);
    _destinationFocusNode.unfocus();
  }

  /// Stellt sicher, dass GPS bereit ist (Services + Berechtigungen)
  /// Gibt true zurück wenn GPS nutzbar ist
  Future<bool> _ensureGPSReady() async {
    // 1. Location Services prüfen
    final serviceEnabled = await LocationHelper.isServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return false;
      final shouldOpen = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(context.l10n.gpsDisabledTitle),
          content: Text(
            context.l10n.gpsDisabledMessage,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.l10n.no),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(context.l10n.openSettings),
            ),
          ],
        ),
      ) ?? false;
      if (shouldOpen) {
        await LocationHelper.openSettings();
        await Future.delayed(const Duration(milliseconds: 500));
        final nowEnabled = await LocationHelper.isServiceEnabled();
        if (!nowEnabled) return false;
      } else {
        return false;
      }
    }

    // 2. Berechtigungen prüfen
    final permission = await LocationHelper.checkAndRequestPermission();
    if (permission == LocationPermission.denied) {
      if (mounted) {
        AppSnackbar.showError(context, context.l10n.gpsPermissionDenied);
      }
      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return false;
      final shouldOpen = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(context.l10n.gpsPermissionDeniedForeverTitle),
          content: Text(
            context.l10n.gpsPermissionDeniedForeverMessage,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(context.l10n.appSettingsButton),
            ),
          ],
        ),
      ) ?? false;
      if (shouldOpen) {
        await LocationHelper.openAppSettings();
      }
      return false;
    }

    return true;
  }

  /// Handelt GPS-Button-Klick mit Dialog
  Future<void> _handleGPSButtonTap() async {
    final gpsReady = await _ensureGPSReady();
    if (!gpsReady) return;

    // GPS bereit - Standort ermitteln
    final notifier = ref.read(randomTripNotifierProvider.notifier);
    await notifier.useCurrentLocation();
  }

  /// Handelt "Überrasch mich!" Klick - prüft GPS wenn kein Startpunkt
  Future<void> _handleGenerateTrip() async {
    final state = ref.read(randomTripNotifierProvider);
    final notifier = ref.read(randomTripNotifierProvider.notifier);

    // Prüfen ob ein aktiver Trip existiert, der überschrieben wird
    final activeTripData = ref.read(activeTripNotifierProvider).value;
    if (activeTripData != null && !activeTripData.allDaysCompleted) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(context.l10n.tripConfigActiveTripTitle),
          content: Text(
            context.l10n.tripConfigActiveTripMessage(
              activeTripData.trip.actualDays,
              activeTripData.completedDays.length,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(context.l10n.tripConfigCreateNewTrip),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    // Wenn kein Startpunkt gesetzt, GPS sicherstellen
    if (!state.hasValidStart) {
      final gpsReady = await _ensureGPSReady();
      if (!gpsReady) return;

      // GPS-Standort ermitteln
      await notifier.useCurrentLocation();

      // Prüfen ob Standort jetzt gesetzt ist
      final newState = ref.read(randomTripNotifierProvider);
      if (!newState.hasValidStart) {
        // Standort konnte nicht ermittelt werden
        return;
      }
    }

    // Trip generieren
    notifier.generateTrip();
  }

  /// Zeigt das Ziel-Eingabe BottomSheet an
  void _showDestinationSheet(
    BuildContext context,
    RandomTripState state,
    RandomTripNotifier notifier,
    ColorScheme colorScheme,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final keyboardHeight = MediaQuery.of(ctx).viewInsets.bottom;
        final screenHeight = MediaQuery.of(ctx).size.height;
        final sheetHeight = screenHeight * 0.5;

        return Padding(
          padding: EdgeInsets.only(bottom: keyboardHeight),
          child: SizedBox(
            height: sheetHeight,
            child: _DestinationSheetContent(
              destinationController: _destinationController,
              destinationFocusNode: _destinationFocusNode,
              isSearching: _isSearchingDestination,
              suggestions: _destinationSuggestions,
              onSearch: _searchDestination,
              onSelect: (result) {
                _selectDestinationSuggestion(result);
                Navigator.pop(ctx);
              },
              onClear: () {
                notifier.clearDestination();
                _destinationController.clear();
                setState(() => _destinationSuggestions = []);
                Navigator.pop(ctx);
              },
              hasDestination: state.hasDestination,
            ),
          ),
        );
      },
    ).then((_) {
      // Rebuild parent um Button-Text zu aktualisieren
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(randomTripNotifierProvider);
    final notifier = ref.read(randomTripNotifierProvider.notifier);
    final tripHasRoute = ref.watch(
      tripStateProvider.select((t) => t.hasRoute),
    );
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Sync controllers mit State
    if (state.startAddress != null && _addressController.text.isEmpty) {
      _addressController.text = state.startAddress!;
    }
    if (state.destinationAddress != null && _destinationController.text.isEmpty) {
      _destinationController.text = state.destinationAddress!;
    }

    // Modus mit Toggle synchronisieren
    final targetMode = widget.mode == MapPlanMode.aiTagestrip
        ? RandomTripMode.daytrip
        : RandomTripMode.eurotrip;
    if (state.mode != targetMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier.setMode(targetMode);
      });
    }

    final content = Column(
            mainAxisSize: MainAxisSize.min,
            children: [
          // Wetter-Widget (v1.7.20 - innerhalb des Panels, nutzt eigenes margin)
          const UnifiedWeatherWidget(),

          // Startadresse (kompakt mit inline GPS-Button)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label + GPS-Button in einer Zeile
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      context.l10n.start,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    // Kompakter GPS-Button inline
                    InkWell(
                      onTap: state.isLoading ? null : _handleGPSButtonTap,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: state.useGPS && state.hasValidStart
                              ? colorScheme.primaryContainer
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: state.useGPS && state.hasValidStart
                                ? colorScheme.primary
                                : colorScheme.outline.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (state.isLoading && state.useGPS)
                              SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.primary,
                                ),
                              )
                            else
                              Icon(
                                Icons.my_location,
                                size: 13,
                                color: state.useGPS && state.hasValidStart
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                              ),
                            const SizedBox(width: 4),
                            Text(
                              state.useGPS && state.startAddress != null
                                  ? state.startAddress!
                                  : 'GPS',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: state.useGPS && state.hasValidStart
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Adress-Eingabe
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: state.hasValidStart && !state.useGPS
                          ? colorScheme.primary
                          : colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _addressController,
                        focusNode: _focusNode,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Stadt oder Adresse...',
                          hintStyle: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                          prefixIcon: Icon(Icons.search, size: 18, color: colorScheme.onSurfaceVariant),
                          suffixIcon: _isSearching
                              ? const Padding(
                                  padding: EdgeInsets.all(10),
                                  child: SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              : _addressController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 16),
                                      onPressed: () {
                                        _addressController.clear();
                                        setState(() => _suggestions = []);
                                      },
                                    )
                                  : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          isDense: true,
                        ),
                        onChanged: _searchAddress,
                      ),
                      // Vorschläge
                      if (_suggestions.isNotEmpty)
                        Container(
                          constraints: const BoxConstraints(maxHeight: 150),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
                            ),
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _suggestions.length,
                            itemBuilder: (context, index) {
                              final result = _suggestions[index];
                              return InkWell(
                                onTap: () => _selectSuggestion(result),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  child: Row(
                                    children: [
                                      Icon(Icons.location_on, size: 14, color: colorScheme.primary),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          result.shortName ?? result.displayName,
                                          style: const TextStyle(fontSize: 12),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.2)),

          // Ziel-Eingabe (kompakt - öffnet BottomSheet)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: InkWell(
              onTap: () => _showDestinationSheet(context, state, notifier, colorScheme),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: state.hasDestination
                        ? colorScheme.primary
                        : colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.flag,
                      size: 16,
                      color: state.hasDestination
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.hasDestination
                            ? state.destinationAddress!
                            : 'Ziel hinzufuegen (optional)',
                        style: TextStyle(
                          fontSize: 13,
                          color: state.hasDestination
                              ? colorScheme.onSurface
                              : colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (state.hasDestination)
                      GestureDetector(
                        onTap: () {
                          notifier.clearDestination();
                          _destinationController.clear();
                          setState(() => _destinationSuggestions = []);
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Icon(Icons.close, size: 16, color: colorScheme.error),
                        ),
                      )
                    else
                      Icon(Icons.arrow_forward_ios, size: 14, color: colorScheme.onSurfaceVariant),
                  ],
                ),
              ),
            ),
          ),

          Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.2)),

          // Radius Slider (kompakt)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: _CompactRadiusSlider(state: state, notifier: notifier),
          ),

          Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.2)),

          // Kategorien (Modal-basiert, v1.7.20)
          _CompactCategorySelector(
            state: state,
            notifier: notifier,
          ),

          // Generate Button - prüft GPS wenn kein Startpunkt gesetzt
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: state.isLoading ? null : _handleGenerateTrip,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('🎲', style: TextStyle(fontSize: 16)),
                    SizedBox(width: 8),
                    Text(
                      'Überrasch mich!',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Route löschen Button (v1.7.25 - ins Panel verschoben, damit nicht abgeschnitten)
          if (state.step == RandomTripStep.preview ||
              state.step == RandomTripStep.confirmed ||
              tripHasRoute) ...[
            Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.2)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: RouteClearButton(
                onClear: () {
                  ref.read(randomTripNotifierProvider.notifier).reset();
                  ref.read(routePlannerProvider.notifier).clearRoute();
                  ref.read(tripStateProvider.notifier).clearAll();
                },
              ),
            ),
          ],
            ],
          );

    // bare-Modus: Nur Column-Inhalt ohne Container/Scroll
    if (widget.bare) {
      return content;
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: SingleChildScrollView(
          child: content,
        ),
      ),
    );
  }
}

/// Route löschen Button
class RouteClearButton extends StatelessWidget {
  final VoidCallback onClear;

  const RouteClearButton({super.key, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: 'Route löschen',
      child: SizedBox(
        width: double.infinity,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onClear,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.red.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Route löschen',
                    style: TextStyle(
                      color: Colors.red.shade400,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Kompakter Radius-Slider
class _CompactRadiusSlider extends StatelessWidget {
  final RandomTripState state;
  final RandomTripNotifier notifier;

  const _CompactRadiusSlider({
    required this.state,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    if (state.mode == RandomTripMode.eurotrip) {
      return _buildDaysSelector(context);
    }
    return _buildRadiusSlider(context);
  }

  /// Euro Trip: Tage-Auswahl als primärer Input
  Widget _buildDaysSelector(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentDays = state.days.clamp(
      TripConstants.euroTripMinDays,
      TripConstants.euroTripMaxDays,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  context.l10n.travelDuration,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                context.l10n.formatDayCount(currentDays),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            _getDaysDescription(context, currentDays),
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        SizedBox(
          height: 32,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: colorScheme.primary,
              inactiveTrackColor: colorScheme.primary.withValues(alpha: 0.2),
              thumbColor: colorScheme.primary,
              overlayColor: colorScheme.primary.withValues(alpha: 0.1),
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Slider(
              value: currentDays.toDouble(),
              min: TripConstants.euroTripMinDays.toDouble(),
              max: TripConstants.euroTripMaxDays.toDouble(),
              divisions: TripConstants.euroTripMaxDays - TripConstants.euroTripMinDays,
              onChanged: (value) => notifier.setDays(value.round()),
              onChangeEnd: (value) => notifier.setEuroTripDays(value.round()),
            ),
          ),
        ),
        // Quick Select Tage
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: TripConstants.euroTripQuickSelectDays.map((days) {
            final isSelected = currentDays == days;
            return GestureDetector(
              onTap: () => notifier.setEuroTripDays(days),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected ? colorScheme.primary : colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  '$days Tage',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Tagestrip: Radius-Slider (unverändert)
  Widget _buildRadiusSlider(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const minRadius = 30.0;
    const maxRadius = 300.0;
    final currentRadius = state.radiusKm.clamp(minRadius, maxRadius);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.radar, size: 16, color: colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  context.l10n.radiusLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${currentRadius.round()} km',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
        SizedBox(
          height: 32,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: colorScheme.primary,
              inactiveTrackColor: colorScheme.primary.withValues(alpha: 0.2),
              thumbColor: colorScheme.primary,
              overlayColor: colorScheme.primary.withValues(alpha: 0.1),
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Slider(
              value: currentRadius,
              min: minRadius,
              max: maxRadius,
              divisions: ((maxRadius - minRadius) / 10).round(),
              onChanged: (value) => notifier.setRadius(value),
              onChangeEnd: (value) => notifier.setRadius(value),
            ),
          ),
        ),
        // Quick Select (kompakt)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [50.0, 100.0, 200.0, 300.0].map((value) {
            final isSelected = (currentRadius - value).abs() < 10;
            return GestureDetector(
              onTap: () => notifier.setRadius(value),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected ? colorScheme.primary : colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  '${value.round()} km',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _getDaysDescription(BuildContext context, int days) {
    final radiusKm = (days * TripConstants.kmPerDay).round();
    if (days == 1) return context.l10n.tripDescDayTrip(radiusKm);
    if (days == 2) return context.l10n.tripDescWeekend(radiusKm);
    if (days <= 4) return context.l10n.tripDescShortVacation(radiusKm);
    if (days <= 7) return context.l10n.tripDescWeekTrip(radiusKm);
    return context.l10n.tripDescEpic(radiusKm);
  }
}

/// Kompakte Kategorien-Auswahl mit Modal (v1.7.20)
class _CompactCategorySelector extends StatelessWidget {
  final RandomTripState state;
  final RandomTripNotifier notifier;

  const _CompactCategorySelector({
    required this.state,
    required this.notifier,
  });

  void _showCategoryModal(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tripCategories = POICategory.values
        .where((cat) => cat != POICategory.hotel && cat != POICategory.restaurant)
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // FIX v1.7.27: Consumer wrappen damit ref.watch() im Modal funktioniert
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final liveState = ref.watch(randomTripNotifierProvider);
          final liveNotifier = ref.read(randomTripNotifierProvider.notifier);
          return Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.category, color: colorScheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'POI-Kategorien',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    if (liveState.selectedCategories.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          liveNotifier.setCategories([]);
                        },
                        child: const Text('Alle zurücksetzen'),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  liveState.selectedCategories.isEmpty
                      ? 'Alle Kategorien ausgewählt'
                      : '${liveState.selectedCategoryCount} von ${tripCategories.length} ausgewählt',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                // Kategorien Grid
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tripCategories.map((category) {
                    final isSelected = liveState.selectedCategories.contains(category);
                    return Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        onTap: () => liveNotifier.toggleCategory(category),
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 100),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.outline.withValues(alpha: 0.3),
                              width: isSelected ? 1.5 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: colorScheme.primary.withValues(alpha: 0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(category.icon, style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 6),
                              if (isSelected) ...[
                                Icon(
                                  Icons.check,
                                  size: 16,
                                  color: colorScheme.onPrimary,
                                ),
                                const SizedBox(width: 2),
                              ],
                              Text(
                                category.label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                // Schließen Button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(context.l10n.done),
                  ),
                ),
                // Safe area padding
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Header - öffnet Modal statt Inline-Expand
        InkWell(
          onTap: () => _showCategoryModal(context),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.category, size: 18, color: colorScheme.primary),
                const SizedBox(width: 10),
                Text(
                  context.l10n.categoriesLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.selectedCategories.isEmpty
                        ? context.l10n.all
                        : context.l10n.selectedCount(state.selectedCategoryCount),
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                // Größerer, auffälligerer Button
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.tune,
                    size: 20,
                    color: colorScheme.primary,
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

/// BottomSheet-Inhalt für Ziel-Eingabe
class _DestinationSheetContent extends StatelessWidget {
  final TextEditingController destinationController;
  final FocusNode destinationFocusNode;
  final bool isSearching;
  final List<GeocodingResult> suggestions;
  final void Function(String) onSearch;
  final void Function(GeocodingResult) onSelect;
  final VoidCallback onClear;
  final bool hasDestination;

  const _DestinationSheetContent({
    required this.destinationController,
    required this.destinationFocusNode,
    required this.isSearching,
    required this.suggestions,
    required this.onSearch,
    required this.onSelect,
    required this.onClear,
    required this.hasDestination,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle-Bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Titel
            Row(
              children: [
                Icon(Icons.flag, size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  context.l10n.destinationOptional,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                if (hasDestination)
                  TextButton.icon(
                    onPressed: onClear,
                    icon: Icon(Icons.close, size: 16, color: colorScheme.error),
                    label: Text(context.l10n.remove, style: TextStyle(color: colorScheme.error, fontSize: 13)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Ziel-Adress-Eingabe
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasDestination
                      ? colorScheme.primary
                      : colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: TextField(
                controller: destinationController,
                focusNode: destinationFocusNode,
                autofocus: true,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: context.l10n.enterDestination,
                  hintStyle: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
                  prefixIcon: Icon(Icons.search, size: 20, color: colorScheme.onSurfaceVariant),
                  suffixIcon: isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(10),
                          child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : destinationController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                destinationController.clear();
                                onSearch('');
                              },
                            )
                          : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  isDense: true,
                ),
                onChanged: onSearch,
              ),
            ),
            // Vorschläge - füllt den restlichen Platz
            Expanded(
              child: suggestions.isNotEmpty
                  ? Container(
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
                      ),
                      child: ListView.builder(
                        itemCount: suggestions.length,
                        itemBuilder: (context, index) {
                          final result = suggestions[index];
                          return InkWell(
                            onTap: () => onSelect(result),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              child: Row(
                                children: [
                                  Icon(Icons.flag, size: 16, color: colorScheme.primary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      result.shortName ?? result.displayName,
                                      style: const TextStyle(fontSize: 13),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 8),
            // Hinweis-Text
            Text(
              hasDestination
                  ? 'POIs entlang der Route'
                  : 'Ohne Ziel: Rundreise ab Start',
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
