import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format_utils.dart';
import 'widgets/trip_stop_tile.dart';
import 'widgets/trip_summary.dart';

/// Trip-Planungs-Screen
class TripScreen extends ConsumerStatefulWidget {
  const TripScreen({super.key});

  @override
  ConsumerState<TripScreen> createState() => _TripScreenState();
}

class _TripScreenState extends ConsumerState<TripScreen> {
  // Demo-Daten für Stops
  final List<Map<String, dynamic>> _stops = [
    {'name': 'Schloss Neuschwanstein', 'icon': '🏰', 'detour': 12, 'duration': 120},
    {'name': 'Zugspitze', 'icon': '🏔️', 'detour': 25, 'duration': 180},
    {'name': 'Partnachklamm', 'icon': '🌲', 'detour': 8, 'duration': 90},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deine Route'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showMoreOptions,
          ),
        ],
      ),
      body: _stops.isEmpty ? _buildEmptyState() : _buildTripContent(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.route,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            'Noch keine Stops geplant',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Füge Sehenswürdigkeiten zu deiner Route hinzu',
            style: TextStyle(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Zu POI-Liste navigieren
            },
            icon: const Icon(Icons.add),
            label: const Text('Stops hinzufügen'),
          ),
        ],
      ),
    );
  }

  Widget _buildTripContent() {
    return Column(
      children: [
        // Trip-Zusammenfassung
        const TripSummary(
          totalDistance: 245,
          totalDuration: 420,
          stopCount: 3,
        ),

        const SizedBox(height: 8),

        // Stops-Liste
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _stops.length + 2, // +2 für Start & Ziel
            onReorder: _onReorderStops,
            itemBuilder: (context, index) {
              // Start
              if (index == 0) {
                return _buildLocationTile(
                  key: const ValueKey('start'),
                  icon: Icons.trip_origin,
                  iconColor: AppTheme.successColor,
                  title: 'München',
                  subtitle: 'Start',
                  isFirst: true,
                );
              }

              // Ziel
              if (index == _stops.length + 1) {
                return _buildLocationTile(
                  key: const ValueKey('end'),
                  icon: Icons.place,
                  iconColor: AppTheme.errorColor,
                  title: 'Innsbruck',
                  subtitle: 'Ziel',
                  isLast: true,
                );
              }

              // Stops
              final stop = _stops[index - 1];
              return TripStopTile(
                key: ValueKey('stop-$index'),
                name: stop['name'],
                icon: stop['icon'],
                detourKm: stop['detour'],
                durationMinutes: stop['duration'],
                index: index,
                onRemove: () => _removeStop(index - 1),
                onEdit: () => _editStop(index - 1),
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
                    onPressed: _exportToGoogleMaps,
                    icon: const Icon(Icons.map),
                    label: const Text('Google Maps'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _startNavigation,
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
    required Key key,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Container(
      key: key,
      margin: EdgeInsets.only(
        bottom: isLast ? 0 : 8,
        top: isFirst ? 0 : 8,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow,
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
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.edit, color: AppTheme.textHint, size: 20),
        ],
      ),
    );
  }

  void _onReorderStops(int oldIndex, int newIndex) {
    // Start und Ziel nicht verschieben
    if (oldIndex == 0 || oldIndex == _stops.length + 1) return;
    if (newIndex == 0 || newIndex > _stops.length) return;

    setState(() {
      final adjustedOld = oldIndex - 1;
      var adjustedNew = newIndex - 1;
      if (newIndex > oldIndex) adjustedNew--;

      final item = _stops.removeAt(adjustedOld);
      _stops.insert(adjustedNew, item);
    });
  }

  void _removeStop(int index) {
    setState(() {
      _stops.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Stop entfernt'),
        action: SnackBarAction(
          label: 'Rückgängig',
          onPressed: () {
            // TODO: Undo
          },
        ),
      ),
    );
  }

  void _editStop(int index) {
    // TODO: Stop bearbeiten
  }

  void _showMoreOptions() {
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
                _clearAllStops();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _clearAllStops() {
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
              setState(() => _stops.clear());
            },
            child: const Text('Löschen', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _exportToGoogleMaps() {
    // TODO: Google Maps Export implementieren
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export nach Google Maps...')),
    );
  }

  void _startNavigation() {
    // TODO: Navigation starten
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigation wird gestartet...')),
    );
  }
}
