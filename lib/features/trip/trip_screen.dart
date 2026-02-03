import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/categories.dart';
import '../../core/constants/trip_constants.dart';
import '../../data/models/trip.dart';
import '../../data/providers/favorites_provider.dart';
import '../map/providers/map_controller_provider.dart';
import '../map/providers/route_planner_provider.dart';
import '../poi/providers/poi_state_provider.dart';
import '../random_trip/providers/random_trip_provider.dart';
import '../random_trip/providers/random_trip_state.dart';
import '../random_trip/widgets/trip_preview_card.dart';
import '../random_trip/widgets/hotel_suggestion_card.dart';
import 'providers/trip_state_provider.dart';
import 'widgets/corridor_browser_sheet.dart';
import 'widgets/trip_stop_tile.dart';
import 'widgets/trip_summary.dart';

/// Trip-Planungs-Screen - zeigt nur berechnete Routen an
class TripScreen extends ConsumerStatefulWidget {
  const TripScreen({super.key});

  @override
  ConsumerState<TripScreen> createState() => _TripScreenState();
}

class _TripScreenState extends ConsumerState<TripScreen> {

  @override
  Widget build(BuildContext context) {
    final tripState = ref.watch(tripStateProvider);
    final randomTripState = ref.watch(randomTripNotifierProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Prüfen ob Route vorhanden (von normaler Planung oder AI Trip)
    final hasRoute = tripState.hasRoute || randomTripState.step == RandomTripStep.preview;
    final isGenerating = randomTripState.step == RandomTripStep.generating;

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle(tripState, randomTripState)),
        actions: [
          // Speichern-Button (nur wenn Route vorhanden)
          if (tripState.hasRoute)
            IconButton(
              icon: const Icon(Icons.bookmark_add),
              tooltip: 'Route speichern',
              onPressed: () => _saveRoute(context, ref, tripState),
            ),
          if (hasRoute || tripState.hasStops)
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showMoreOptions(context, ref),
            ),
        ],
      ),
      body: isGenerating
          ? _buildGeneratingView(context, colorScheme)
          : hasRoute || tripState.hasStops
              ? _buildTripContent(context, ref, tripState, randomTripState, theme, colorScheme)
              : _buildConfigView(context, ref, theme, colorScheme),
    );
  }

  String _getTitle(TripStateData tripState, RandomTripState randomTripState) {
    if (randomTripState.step == RandomTripStep.generating) {
      return 'Trip wird generiert...';
    }
    if (randomTripState.step == RandomTripStep.preview) {
      return randomTripState.mode == RandomTripMode.daytrip
          ? 'AI Tagesausflug'
          : 'AI Euro Trip';
    }
    if (tripState.hasRoute || tripState.hasStops) {
      return 'Deine Route';
    }
    return 'Route planen';
  }

  /// Ansicht wenn keine Route vorhanden
  Widget _buildConfigView(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.route,
              size: 80,
              color: colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Keine Route vorhanden',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tippe auf die Karte, um Start und Ziel festzulegen',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.map),
              label: const Text('Zur Karte'),
            ),
          ],
        ),
      ),
    );
  }

  /// Generierungs-Ansicht (Loading)
  Widget _buildGeneratingView(BuildContext context, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation(colorScheme.primary),
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
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveRoute(BuildContext context, WidgetRef ref, TripStateData tripState) async {
    final route = tripState.route;
    if (route == null) return;

    // Dialog für Trip-Namen
    final nameController = TextEditingController(
      text: '${route.startAddress} → ${route.endAddress}',
    );

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Route speichern'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Name der Route',
            hintText: 'z.B. Wochenendausflug',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, nameController.text),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return;

    // Trip erstellen
    final trip = Trip(
      id: const Uuid().v4(),
      name: result,
      type: TripType.daytrip,
      route: route,
      stops: tripState.stops.map((poi) => TripStop.fromPOI(poi)).toList(),
      createdAt: DateTime.now(),
    );

    // In Favoriten speichern
    await ref.read(favoritesNotifierProvider.notifier).saveRoute(trip);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Route "$result" gespeichert'),
          duration: const Duration(seconds: 1),
          action: SnackBarAction(
            label: 'Anzeigen',
            onPressed: () => context.push('/favorites'),
          ),
        ),
      );
    }
  }

  /// Speichert einen AI Trip in die Favoriten
  Future<void> _saveAITrip(BuildContext context, WidgetRef ref, RandomTripState randomTripState) async {
    final generatedTrip = randomTripState.generatedTrip;
    if (generatedTrip == null) return;

    final trip = generatedTrip.trip;
    final route = trip.route;

    // Dialog für Trip-Namen
    final nameController = TextEditingController(
      text: '${route.startAddress} → ${route.endAddress}',
    );

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Route speichern'),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'Name der Route',
            hintText: randomTripState.mode == RandomTripMode.daytrip
                ? 'z.B. AI Tagesausflug'
                : 'z.B. AI Euro Trip',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, nameController.text),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return;

    // Trip mit korrektem Typ erstellen
    final savedTrip = Trip(
      id: const Uuid().v4(),
      name: result,
      type: randomTripState.mode == RandomTripMode.daytrip
          ? TripType.daytrip
          : TripType.eurotrip,
      route: route,
      stops: trip.stops,
      days: trip.actualDays,
      createdAt: DateTime.now(),
    );

    // In Favoriten speichern
    await ref.read(favoritesNotifierProvider.notifier).saveRoute(savedTrip);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Route "$result" gespeichert'),
          duration: const Duration(seconds: 1),
          action: SnackBarAction(
            label: 'Anzeigen',
            onPressed: () => context.push('/favorites'),
          ),
        ),
      );
    }
  }

  /// Öffnet die Route in Google Maps mit Start, Ziel und Waypoints
  Future<void> _openInGoogleMaps(BuildContext context, TripStateData tripState) async {
    final route = tripState.route;
    if (route == null) return;

    // Google Maps URL mit Waypoints
    final origin = '${route.start.latitude.toStringAsFixed(6)},${route.start.longitude.toStringAsFixed(6)}';
    final destination = '${route.end.latitude.toStringAsFixed(6)},${route.end.longitude.toStringAsFixed(6)}';

    var url = 'https://www.google.com/maps/dir/?api=1'
        '&origin=$origin'
        '&destination=$destination'
        '&travelmode=driving';

    // Waypoints hinzufügen (max 9 für Google Maps)
    if (tripState.stops.isNotEmpty) {
      final waypoints = tripState.stops
          .take(TripConstants.maxPoisPerDay)
          .map((poi) => '${poi.latitude.toStringAsFixed(6)},${poi.longitude.toStringAsFixed(6)}')
          .join('|');
      url += '&waypoints=$waypoints';
    }

    debugPrint('[GoogleMaps] Opening URL: $url');

    try {
      await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('[GoogleMaps] Error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google Maps konnte nicht geöffnet werden'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Öffnet einen bestimmten Tag in Google Maps (für Mehrtages-Trips)
  Future<void> _openDayInGoogleMaps(
    BuildContext context,
    Trip trip,
    int dayNumber,
    LatLng tripStartLocation,
    String startAddress,
  ) async {
    final stopsForDay = trip.getStopsForDay(dayNumber);
    if (stopsForDay.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Keine Stops für Tag $dayNumber')),
      );
      return;
    }

    // Start bestimmen: Tag 1 = Trip-Start, sonst letzter Stop vom Vortag
    LatLng origin;
    String originName;
    if (dayNumber == 1) {
      origin = tripStartLocation;
      originName = startAddress;
    } else {
      final prevDayStops = trip.getStopsForDay(dayNumber - 1);
      if (prevDayStops.isNotEmpty) {
        origin = prevDayStops.last.location;
        originName = prevDayStops.last.name;
      } else {
        origin = tripStartLocation;
        originName = startAddress;
      }
    }

    // Ziel bestimmen: letzter Tag = Trip-Start, sonst erster Stop vom Folgetag
    LatLng destination;
    String destinationName;
    if (dayNumber == trip.actualDays) {
      destination = tripStartLocation;
      destinationName = startAddress;
    } else {
      final nextDayStops = trip.getStopsForDay(dayNumber + 1);
      if (nextDayStops.isNotEmpty) {
        destination = nextDayStops.first.location;
        destinationName = nextDayStops.first.name;
      } else {
        destination = tripStartLocation;
        destinationName = startAddress;
      }
    }

    // Waypoints: Alle Stops des Tages (max 9)
    final waypoints = stopsForDay
        .take(TripConstants.maxPoisPerDay)
        .map((s) => '${s.location.latitude.toStringAsFixed(6)},${s.location.longitude.toStringAsFixed(6)}')
        .join('|');

    final originStr = '${origin.latitude.toStringAsFixed(6)},${origin.longitude.toStringAsFixed(6)}';
    final destinationStr = '${destination.latitude.toStringAsFixed(6)},${destination.longitude.toStringAsFixed(6)}';

    final url = 'https://www.google.com/maps/dir/?api=1'
        '&origin=$originStr'
        '&destination=$destinationStr'
        '&waypoints=$waypoints'
        '&travelmode=driving';

    debugPrint('[GoogleMaps] Tag $dayNumber: $originName -> $destinationName');
    debugPrint('[GoogleMaps] Opening URL: $url');

    try {
      await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );

      // Tag als abgeschlossen markieren
      ref.read(randomTripNotifierProvider.notifier).completeDay(dayNumber);

      // Prüfen ob alle Tage abgeschlossen sind
      final updatedState = ref.read(randomTripNotifierProvider);
      if (updatedState.completedDays.length >= trip.actualDays) {
        // Alle Tage exportiert
        if (context.mounted) {
          _showTripCompletedDialog(context, trip);
        }
      }
      // Kein Snackbar - DayTabSelector zeigt Häkchen für abgeschlossene Tage
    } catch (e) {
      debugPrint('[GoogleMaps] Error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google Maps konnte nicht geöffnet werden'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Zeigt Dialog wenn alle Tage eines mehrtägigen Trips exportiert wurden
  Future<void> _showTripCompletedDialog(BuildContext context, Trip trip) async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Trip abgeschlossen!'),
        content: Text(
          'Alle ${trip.actualDays} Tage wurden erfolgreich exportiert. '
          'Möchtest du den Trip in deinen Favoriten speichern?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'keep'),
            child: const Text('Behalten'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'save'),
            child: const Text('In Favoriten speichern'),
          ),
        ],
      ),
    );

    if (result == 'save' && context.mounted) {
      // Trip in Favoriten speichern und State aufräumen
      final randomTripState = ref.read(randomTripNotifierProvider);
      await _saveAITrip(context, ref, randomTripState);
      ref.read(randomTripNotifierProvider.notifier).reset();
      if (context.mounted) context.go('/');
    }
  }

  /// Teilt die Route über WhatsApp, Email, etc.
  Future<void> _shareRoute(BuildContext context, TripStateData tripState) async {
    final route = tripState.route;
    if (route == null) return;

    // Google Maps Link generieren
    final origin = '${route.start.latitude.toStringAsFixed(6)},${route.start.longitude.toStringAsFixed(6)}';
    final destination = '${route.end.latitude.toStringAsFixed(6)},${route.end.longitude.toStringAsFixed(6)}';
    var mapsUrl = 'https://www.google.com/maps/dir/?api=1'
        '&origin=$origin'
        '&destination=$destination'
        '&travelmode=driving';

    if (tripState.stops.isNotEmpty) {
      final waypoints = tripState.stops
          .take(10)
          .map((poi) => '${poi.latitude.toStringAsFixed(6)},${poi.longitude.toStringAsFixed(6)}')
          .join('|');
      mapsUrl += '&waypoints=$waypoints';
    }

    debugPrint('[GoogleMaps] Share URL: $mapsUrl');

    // Share-Text erstellen
    final stopNames = tripState.stops.map((s) => '• ${s.name}').join('\n');
    final shareText = '''
🗺️ Meine Route mit MapAB

📍 Start: ${route.startAddress ?? 'Unbekannt'}
🏁 Ziel: ${route.endAddress ?? 'Unbekannt'}
📏 Distanz: ${tripState.totalDistance.toStringAsFixed(1)} km
⏱️ Dauer: ${tripState.totalDuration} Min

${tripState.stops.isNotEmpty ? '📌 Stops:\n$stopNames\n' : ''}
🔗 In Google Maps öffnen:
$mapsUrl
''';

    try {
      await Share.share(shareText, subject: 'Meine Route');
    } catch (e) {
      debugPrint('[Share] Error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Route konnte nicht geteilt werden'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Widget _buildTripContent(
    BuildContext context,
    WidgetRef ref,
    TripStateData tripState,
    RandomTripState randomTripState,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    // Wenn AI Trip im Preview-Modus
    if (randomTripState.step == RandomTripStep.preview) {
      return _buildAITripPreview(context, ref, randomTripState, colorScheme);
    }

    final route = tripState.route;
    final stops = tripState.stops;

    return Column(
      children: [
        // Trip-Zusammenfassung
        TripSummary(
          totalDistance: tripState.totalDistance,
          totalDuration: tripState.totalDuration,
          stopCount: stops.length,
          isRecalculating: tripState.isRecalculating,
        ),

        const SizedBox(height: 8),

        // Stops-Liste
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: stops.length + 2, // +2 für Start & Ziel
            onReorder: (oldIndex, newIndex) {
              // Start und Ziel nicht verschieben
              if (oldIndex == 0 || oldIndex == stops.length + 1) return;
              if (newIndex == 0 || newIndex > stops.length) return;

              final adjustedOld = oldIndex - 1;
              var adjustedNew = newIndex - 1;
              if (newIndex > oldIndex) adjustedNew--;

              ref.read(tripStateProvider.notifier).reorderStops(adjustedOld, adjustedNew);
            },
            itemBuilder: (context, index) {
              // Start
              if (index == 0) {
                return _buildLocationTile(
                  context: context,
                  key: const ValueKey('start'),
                  icon: Icons.trip_origin,
                  iconColor: Colors.green,
                  title: route?.startAddress ?? 'Keine Route',
                  subtitle: 'Start',
                  isFirst: true,
                );
              }

              // Ziel
              if (index == stops.length + 1) {
                return _buildLocationTile(
                  context: context,
                  key: const ValueKey('end'),
                  icon: Icons.place,
                  iconColor: Colors.red,
                  title: route?.endAddress ?? 'Keine Route',
                  subtitle: 'Ziel',
                  isLast: true,
                );
              }

              // Stops
              final stop = stops[index - 1];
              return TripStopTile(
                key: ValueKey('stop-${stop.id}'),
                name: stop.name,
                icon: stop.category?.icon ?? '📍',
                detourKm: (stop.detourKm ?? 0).toInt(),
                durationMinutes: (stop.detourMinutes ?? 0).toInt(),
                index: index,
                onTap: () {
                  // v1.6.8: POI zum State hinzufügen bevor Navigation
                  // Ermöglicht POI-Details mit Foto für Trip-Stops
                  final poiNotifier = ref.read(pOIStateNotifierProvider.notifier);
                  poiNotifier.addPOI(stop);
                  // Enrichment triggern für Foto-Laden
                  if (stop.imageUrl == null) {
                    poiNotifier.enrichPOI(stop.id);
                  }
                  context.push('/poi/${stop.id}');
                },
                onRemove: () {
                  ref.read(tripStateProvider.notifier).removeStop(stop.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Stop entfernt')),
                  );
                },
                onEdit: () {
                  // v1.6.8: POI zum State hinzufügen bevor Navigation
                  ref.read(pOIStateNotifierProvider.notifier).addPOI(stop);
                  context.push('/poi/${stop.id}');
                },
              );
            },
          ),
        ),

        // Export-Buttons
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Auf Karte anzeigen Button (v1.7.0)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: route != null
                        ? () {
                            // Flag setzen für Auto-Zoom beim Tab-Wechsel
                            ref.read(shouldFitToRouteProvider.notifier).state = true;
                            context.go('/');
                          }
                        : null,
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Auf Karte anzeigen'),
                  ),
                ),
                // POIs entdecken Button
                if (route != null && route.coordinates.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => CorridorBrowserSheet.show(
                          context: context,
                          route: route,
                          existingStopIds: tripState.stops
                              .map((s) => s.id)
                              .toSet(),
                        ),
                        icon: const Icon(Icons.add_location_alt_rounded),
                        label: const Text('POIs entlang der Route'),
                      ),
                    ),
                  ),
                // In-App Navigation starten
                if (route != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => context.push(
                          '/navigation',
                          extra: {
                            'route': route,
                            'stops': tripState.stops
                                .asMap()
                                .entries
                                .map((e) => TripStop.fromPOI(e.value, order: e.key))
                                .toList(),
                          },
                        ),
                        icon: const Icon(Icons.navigation),
                        label: const Text('Navigation starten'),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: route != null
                            ? () => _openInGoogleMaps(context, tripState)
                            : null,
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Google Maps'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: route != null
                            ? () => _shareRoute(context, tripState)
                            : null,
                        icon: const Icon(Icons.share),
                        label: const Text('Route Teilen'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// AI Trip Preview-Ansicht
  Widget _buildAITripPreview(
    BuildContext context,
    WidgetRef ref,
    RandomTripState state,
    ColorScheme colorScheme,
  ) {
    final notifier = ref.read(randomTripNotifierProvider.notifier);
    final trip = state.generatedTrip?.trip;
    final isMultiDay = trip != null && trip.actualDays > 1;

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

                // Hotel-Vorschläge (für Mehrtages-Trips)
                if (state.isMultiDay && state.hotelSuggestions.isNotEmpty) ...[
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
            color: colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Auf Karte anzeigen Button (v1.7.0)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      // Flag setzen für Auto-Zoom beim Tab-Wechsel
                      ref.read(shouldFitToRouteProvider.notifier).state = true;
                      context.go('/');
                    },
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Auf Karte anzeigen'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // POIs entdecken Button
                if (trip != null && trip.route.coordinates.isNotEmpty)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => CorridorBrowserSheet.show(
                        context: context,
                        route: trip.route,
                        existingStopIds:
                            trip.stops.map((s) => s.poiId).toSet(),
                      ),
                      icon: const Icon(Icons.add_location_alt_rounded),
                      label: const Text('POIs entlang der Route'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                // In-App Navigation starten (v1.9.0)
                if (trip != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => context.push(
                          '/navigation',
                          extra: {
                            'route': trip.route,
                            'stops': trip.stops,
                          },
                        ),
                        icon: const Icon(Icons.navigation),
                        label: const Text('Navigation starten'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                // Tagesweiser Export (nur bei Mehrtages-Trips)
                if (isMultiDay) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: state.startLocation != null
                          ? () => _openDayInGoogleMaps(
                                context,
                                trip,
                                state.selectedDay,
                                state.startLocation!,
                                state.startAddress!,
                              )
                          : null,
                      icon: const Icon(Icons.map),
                      label: Text(
                        state.isDayCompleted(state.selectedDay)
                            ? 'Tag ${state.selectedDay} erneut exportieren'
                            : 'Tag ${state.selectedDay} in Google Maps',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: state.isDayCompleted(state.selectedDay)
                            ? colorScheme.surfaceContainerHighest
                            : colorScheme.primary,
                        foregroundColor: state.isDayCompleted(state.selectedDay)
                            ? colorScheme.onSurface
                            : colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Google Maps berechnet eine eigene Route durch die Stops',
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                ],

                // Standard-Buttons
                Row(
                  children: [
                    // Bearbeiten Button
                    OutlinedButton.icon(
                      onPressed: () => notifier.backToConfig(),
                      icon: const Icon(Icons.edit),
                      label: const Text('Bearbeiten'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Neu generieren Button
                    OutlinedButton.icon(
                      onPressed: () => notifier.regenerateTrip(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Neu'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Trip speichern Button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          notifier.confirmTrip();
                          await _saveAITrip(context, ref, state);
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Speichern'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationTile({
    required BuildContext context,
    required Key key,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      key: key,
      margin: EdgeInsets.only(
        bottom: isLast ? 0 : 8,
        top: isFirst ? 0 : 8,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMoreOptions(BuildContext context, WidgetRef ref) {
    final randomTripState = ref.read(randomTripNotifierProvider);

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.auto_fix_high),
              title: const Text('Route optimieren'),
              subtitle: const Text('Beste Reihenfolge berechnen'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Optimieren
              },
            ),
            ListTile(
              leading: const Icon(Icons.save),
              title: const Text('Route speichern'),
              onTap: () {
                Navigator.pop(context);
                final tripState = ref.read(tripStateProvider);
                final rtState = ref.read(randomTripNotifierProvider);
                if (rtState.step == RandomTripStep.preview ||
                    rtState.step == RandomTripStep.confirmed) {
                  _saveAITrip(context, ref, rtState);
                } else if (tripState.hasRoute) {
                  _saveRoute(context, ref, tripState);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Route teilen'),
              onTap: () {
                Navigator.pop(context);
                final tripState = ref.read(tripStateProvider);
                if (tripState.hasRoute) {
                  _shareRoute(context, tripState);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Alle Stops löschen',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _clearAllStops(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('Gesamte Route löschen',
                  style: TextStyle(color: Colors.red)),
              subtitle: const Text('Route und alle Stops löschen'),
              onTap: () {
                Navigator.pop(context);
                _clearEntireRoute(context, ref);
              },
            ),
            // Wenn AI Trip aktiv: Zurück zu Konfiguration
            if (randomTripState.step == RandomTripStep.preview)
              ListTile(
                leading: const Icon(Icons.arrow_back),
                title: const Text('Zurück zur Konfiguration'),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(randomTripNotifierProvider.notifier).backToConfig();
                },
              ),
          ],
        ),
      ),
    );
  }

  void _clearAllStops(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alle Stops löschen?'),
        content: const Text('Diese Aktion kann nicht rückgängig gemacht werden.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(tripStateProvider.notifier).clearStops();
            },
            child: const Text('Löschen', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _clearEntireRoute(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gesamte Route löschen?'),
        content: const Text(
          'Die Route und alle Stops werden gelöscht. '
          'Diese Aktion kann nicht rückgängig gemacht werden.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Route im Route-Planner löschen (löscht auch Trip-State)
              ref.read(routePlannerProvider.notifier).clearRoute();
              // AI Trip State zurücksetzen
              ref.read(randomTripNotifierProvider.notifier).reset();
              // Zur Karte navigieren
              context.go('/');
            },
            child: const Text('Löschen', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
