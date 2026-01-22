import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/categories.dart';
import '../../data/models/trip.dart';
import '../../data/providers/favorites_provider.dart';
import 'providers/trip_state_provider.dart';
import 'widgets/trip_stop_tile.dart';
import 'widgets/trip_summary.dart';

/// Trip-Planungs-Screen
class TripScreen extends ConsumerWidget {
  const TripScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripState = ref.watch(tripStateProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deine Route'),
        actions: [
          // Speichern-Button (nur wenn Route vorhanden)
          if (tripState.hasRoute)
            IconButton(
              icon: const Icon(Icons.bookmark_add),
              tooltip: 'Route speichern',
              onPressed: () => _saveRoute(context, ref, tripState),
            ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showMoreOptions(context, ref),
          ),
        ],
      ),
      body: !tripState.hasRoute && !tripState.hasStops
          ? _buildEmptyState(context, theme, colorScheme)
          : _buildTripContent(context, ref, tripState, theme, colorScheme),
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
          action: SnackBarAction(
            label: 'Anzeigen',
            onPressed: () => context.push('/favorites'),
          ),
        ),
      );
    }
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.route,
            size: 80,
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            'Noch keine Route geplant',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Berechne eine Route auf der Karte oder nutze den AI-Trip-Generator',
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
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.push('/assistant'),
            icon: const Text('🤖', style: TextStyle(fontSize: 18)),
            label: const Text('AI-Trip generieren'),
          ),
        ],
      ),
    );
  }

  Widget _buildTripContent(
    BuildContext context,
    WidgetRef ref,
    TripStateData tripState,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final route = tripState.route;
    final stops = tripState.stops;

    return Column(
      children: [
        // Trip-Zusammenfassung
        TripSummary(
          totalDistance: tripState.totalDistance,
          totalDuration: tripState.totalDuration,
          stopCount: stops.length,
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
                onRemove: () {
                  ref.read(tripStateProvider.notifier).removeStop(stop.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Stop entfernt')),
                  );
                },
                onEdit: () {
                  // TODO: Stop bearbeiten
                },
              );
            },
          ),
        ),

        // Export-Buttons
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Export nach Google Maps...')),
                      );
                    },
                    icon: const Icon(Icons.map),
                    label: const Text('Google Maps'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Navigation wird gestartet...')),
                      );
                    },
                    icon: const Icon(Icons.navigation),
                    label: const Text('Navigation'),
                  ),
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
                // TODO: Speichern
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Route teilen'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Teilen
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
}
