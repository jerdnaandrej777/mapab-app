import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/trip_constants.dart';
import '../../../data/models/trip.dart';
import '../providers/random_trip_provider.dart';
import 'day_tab_selector.dart';
import 'poi_reroll_button.dart';

/// Widget zur Vorschau des generierten Trips mit Karte
class TripPreviewCard extends ConsumerWidget {
  const TripPreviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(randomTripNotifierProvider);
    final notifier = ref.read(randomTripNotifierProvider.notifier);
    final trip = state.generatedTrip?.trip;
    final colorScheme = Theme.of(context).colorScheme;

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
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.primary,
                          ),
                        )
                      : const Icon(Icons.refresh),
                  tooltip: 'Neu generieren',
                ),
                // Bestätigen
                IconButton(
                  onPressed: () => notifier.confirmTrip(),
                  icon: const Icon(Icons.check_circle_outline),
                  color: colorScheme.primary,
                  tooltip: 'Trip bestätigen',
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Tages-Auswahl (nur bei Mehrtages-Trips)
        if (trip.actualDays > 1) ...[
          const DayTabSelector(),
          const SizedBox(height: 16),
        ],

        // Statistiken (bei Mehrtages-Trip: für ausgewählten Tag)
        _TripStatistics(
          trip: trip,
          selectedDay: state.selectedDay,
          isMultiDay: trip.actualDays > 1,
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

        // Stop-Liste (bei Mehrtages-Trip: nur ausgewählter Tag)
        _StopList(
          trip: trip,
          startAddress: state.startAddress!,
          loadingPOIId: state.loadingPOIId,
          canRemovePOI: state.canRemovePOI,
          onReroll: (poiId) => notifier.rerollPOI(poiId),
          onRemove: (poiId) => notifier.removePOI(poiId),
          selectedDay: trip.actualDays > 1 ? state.selectedDay : null,
        ),
      ],
    );
  }
}

class _TripStatistics extends StatelessWidget {
  final Trip trip;
  final int selectedDay;
  final bool isMultiDay;

  const _TripStatistics({
    required this.trip,
    required this.selectedDay,
    required this.isMultiDay,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Bei Mehrtages-Trip: Statistiken für ausgewählten Tag
    final stopsForDay = isMultiDay ? trip.getStopsForDay(selectedDay) : trip.stops;
    final stopCount = stopsForDay.length;

    // Warnung wenn Tag das Limit überschreitet
    final isOverLimit = stopCount > TripConstants.maxPoisPerDay;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isOverLimit
            ? Colors.orange.withOpacity(0.15)
            : colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: isOverLimit
            ? Border.all(color: Colors.orange, width: 1)
            : null,
      ),
      child: Column(
        children: [
          if (isOverLimit)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.warning_amber, color: Colors.orange, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Max ${TripConstants.maxPoisPerDay} Stops pro Tag (Google Maps Limit)',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                icon: Icons.place,
                value: '$stopCount',
                label: isMultiDay ? 'Stops (Tag $selectedDay)' : 'Stops',
                isWarning: isOverLimit,
              ),
              _StatItem(
                icon: Icons.straighten,
                value: isMultiDay
                    ? '~${trip.getDistanceForDay(selectedDay).toStringAsFixed(0)} km'
                    : trip.route.formattedDistance,
                label: 'Distanz',
              ),
              _StatItem(
                icon: Icons.calendar_today,
                value: '${trip.actualDays}',
                label: trip.actualDays == 1 ? 'Tag' : 'Tage',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final bool isWarning;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = isWarning ? Colors.orange.shade800 : colorScheme.onPrimaryContainer;

    return Column(
      children: [
        Icon(icon, color: textColor, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: textColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: textColor.withOpacity(0.7),
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
    final colorScheme = Theme.of(context).colorScheme;

    // Alle Punkte für Bounds
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
              color: colorScheme.primary,
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
                    color: colorScheme.primary,
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
  final String? loadingPOIId;
  final bool canRemovePOI;
  final Function(String) onReroll;
  final Function(String) onRemove;
  final int? selectedDay; // Null = alle Tage anzeigen

  const _StopList({
    required this.trip,
    required this.startAddress,
    required this.loadingPOIId,
    required this.canRemovePOI,
    required this.onReroll,
    required this.onRemove,
    this.selectedDay,
  });

  @override
  Widget build(BuildContext context) {
    // Stops basierend auf ausgewähltem Tag filtern
    final stops = selectedDay != null
        ? trip.getStopsForDay(selectedDay!)
        : trip.sortedStops;
    final colorScheme = Theme.of(context).colorScheme;
    final isMultiDay = trip.actualDays > 1;

    // Start-Label basierend auf Tag
    String startLabel;
    String endLabel;
    if (isMultiDay && selectedDay != null) {
      if (selectedDay == 1) {
        startLabel = 'Start (Tag 1)';
      } else {
        // Vorheriger Tag: letzter Stop
        final prevDayStops = trip.getStopsForDay(selectedDay! - 1);
        startLabel = prevDayStops.isNotEmpty
            ? 'Von: ${prevDayStops.last.name}'
            : 'Tag $selectedDay Start';
      }

      if (selectedDay == trip.actualDays) {
        endLabel = 'Zurück zum Start';
      } else {
        // Nächster Tag: erster Stop als Ziel
        final nextDayStops = trip.getStopsForDay(selectedDay! + 1);
        endLabel = nextDayStops.isNotEmpty
            ? 'Weiter nach: ${nextDayStops.first.name}'
            : 'Ende Tag $selectedDay';
      }
    } else {
      startLabel = 'Start';
      endLabel = 'Zurück zum Start';
    }

    return Column(
      children: [
        // Start
        _StopItem(
          icon: Icons.home,
          iconColor: Colors.green,
          title: startLabel,
          subtitle: isMultiDay && selectedDay != null && selectedDay != 1
              ? null
              : startAddress,
          isFirst: true,
        ),

        // Stops
        ...stops.asMap().entries.map((entry) {
          final stop = entry.value;
          final isThisPOILoading = loadingPOIId == stop.poiId;
          return _StopItem(
            icon: null,
            emoji: stop.categoryIcon,
            iconColor: colorScheme.primary,
            title: stop.name,
            subtitle: stop.detourKm != null
                ? '+${stop.detourKm!.toStringAsFixed(1)} km Umweg'
                : null,
            isOvernightStop: stop.isOvernightStop,
            trailing: POIActionButtons(
              poiId: stop.poiId,
              isLoading: isThisPOILoading,
              canDelete: canRemovePOI,
              onReroll: () => onReroll(stop.poiId),
              onDelete: () => onRemove(stop.poiId),
            ),
          );
        }),

        // Ende
        _StopItem(
          icon: selectedDay == trip.actualDays || !isMultiDay
              ? Icons.flag
              : Icons.arrow_forward,
          iconColor: selectedDay == trip.actualDays || !isMultiDay
              ? Colors.red
              : Colors.blue,
          title: endLabel,
          subtitle: selectedDay == trip.actualDays || !isMultiDay
              ? startAddress
              : null,
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
    final colorScheme = Theme.of(context).colorScheme;

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
                  color: colorScheme.primary.withOpacity(0.3),
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
                  color: colorScheme.primary.withOpacity(0.3),
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
                          color: Colors.purple.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '🏨 Übernachtung',
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
                      color: colorScheme.onSurfaceVariant,
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
