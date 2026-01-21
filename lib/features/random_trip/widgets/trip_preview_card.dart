import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/trip.dart';
import '../providers/random_trip_provider.dart';
import 'poi_reroll_button.dart';

/// Widget zur Vorschau des generierten Trips mit Karte
class TripPreviewCard extends ConsumerWidget {
  const TripPreviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(randomTripNotifierProvider);
    final notifier = ref.read(randomTripNotifierProvider.notifier);
    final trip = state.generatedTrip?.trip;

    if (trip == null) {
      return const Center(child: Text('Kein Trip generiert'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header mit Aktionen
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Dein Trip',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Row(
              children: [
                // Neu generieren
                IconButton(
                  onPressed: state.isLoading
                      ? null
                      : () => notifier.regenerateTrip(),
                  icon: state.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  tooltip: 'Neu generieren',
                ),
                // Bestatigen
                IconButton(
                  onPressed: () => notifier.confirmTrip(),
                  icon: const Icon(Icons.check_circle_outline),
                  color: AppTheme.primaryColor,
                  tooltip: 'Trip bestatigen',
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Statistiken
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                icon: Icons.place,
                value: '${trip.stopCount}',
                label: 'Stops',
              ),
              _StatItem(
                icon: Icons.straighten,
                value: trip.route.formattedDistance,
                label: 'Distanz',
              ),
              _StatItem(
                icon: Icons.schedule,
                value: trip.formattedTotalDuration,
                label: 'Dauer',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Karte
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 200,
            child: _TripMap(trip: trip, startLocation: state.startLocation!),
          ),
        ),
        const SizedBox(height: 16),

        // Stop-Liste
        _StopList(
          trip: trip,
          startAddress: state.startAddress!,
          isLoading: state.isLoading,
          onReroll: (poiId) => notifier.rerollPOI(poiId),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _TripMap extends StatelessWidget {
  final Trip trip;
  final LatLng startLocation;

  const _TripMap({required this.trip, required this.startLocation});

  @override
  Widget build(BuildContext context) {
    // Alle Punkte fur Bounds
    final allPoints = [
      startLocation,
      ...trip.stops.map((s) => s.location),
    ];

    // Bounds berechnen
    final bounds = LatLngBounds.fromPoints(allPoints);

    return FlutterMap(
      options: MapOptions(
        initialCameraFit: CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(32),
        ),
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.none,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.travelplanner',
        ),
        // Route
        PolylineLayer(
          polylines: [
            Polyline(
              points: trip.route.coordinates,
              strokeWidth: 4,
              color: AppTheme.primaryColor,
            ),
          ],
        ),
        // Marker
        MarkerLayer(
          markers: [
            // Start
            Marker(
              point: startLocation,
              width: 40,
              height: 40,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.home,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            // Stops
            ...trip.sortedStops.asMap().entries.map((entry) {
              final stop = entry.value;
              return Marker(
                point: stop.location,
                width: 36,
                height: 36,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      stop.categoryIcon,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }
}

class _StopList extends StatelessWidget {
  final Trip trip;
  final String startAddress;
  final bool isLoading;
  final Function(String) onReroll;

  const _StopList({
    required this.trip,
    required this.startAddress,
    required this.isLoading,
    required this.onReroll,
  });

  @override
  Widget build(BuildContext context) {
    final stops = trip.sortedStops;

    return Column(
      children: [
        // Start
        _StopItem(
          icon: Icons.home,
          iconColor: Colors.green,
          title: 'Start',
          subtitle: startAddress,
          isFirst: true,
        ),

        // Stops
        ...stops.asMap().entries.map((entry) {
          final index = entry.key;
          final stop = entry.value;
          return _StopItem(
            icon: null,
            emoji: stop.categoryIcon,
            iconColor: AppTheme.primaryColor,
            title: stop.name,
            subtitle: stop.detourKm != null
                ? '+${stop.detourKm!.toStringAsFixed(1)} km Umweg'
                : null,
            isOvernightStop: stop.isOvernightStop,
            trailing: POIRerollButton(
              poiId: stop.poiId,
              isLoading: isLoading,
              onReroll: () => onReroll(stop.poiId),
            ),
          );
        }),

        // Zurück zum Start
        _StopItem(
          icon: Icons.flag,
          iconColor: Colors.red,
          title: 'Zuruck zum Start',
          subtitle: startAddress,
          isLast: true,
        ),
      ],
    );
  }
}

class _StopItem extends StatelessWidget {
  final IconData? icon;
  final String? emoji;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final bool isFirst;
  final bool isLast;
  final bool isOvernightStop;
  final Widget? trailing;

  const _StopItem({
    this.icon,
    this.emoji,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.isFirst = false,
    this.isLast = false,
    this.isOvernightStop = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline
        SizedBox(
          width: 40,
          child: Column(
            children: [
              if (!isFirst)
                Container(
                  width: 2,
                  height: 16,
                  color: AppTheme.primaryColor.withOpacity(0.3),
                ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: iconColor, width: 2),
                ),
                child: Center(
                  child: emoji != null
                      ? Text(emoji!, style: const TextStyle(fontSize: 14))
                      : Icon(icon, color: iconColor, size: 16),
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 16,
                  color: AppTheme.primaryColor.withOpacity(0.3),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (isOvernightStop)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '🏨 Ubernachtung',
                          style: TextStyle(fontSize: 10),
                        ),
                      ),
                    if (trailing != null) trailing!,
                  ],
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
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
