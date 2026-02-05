import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/categories.dart';
import '../../../core/constants/trip_constants.dart';
import '../../../core/l10n/l10n.dart';
import '../../../data/models/trip.dart';
import '../../poi/providers/poi_state_provider.dart';
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
      return Center(child: Text(context.l10n.tripPreviewNoTrip));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header mit Aktionen
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.l10n.tripPreviewYourTrip,
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
                  tooltip: context.l10n.dayEditorRegenerate,
                ),
                // Bestätigen
                IconButton(
                  onPressed: () => notifier.confirmTrip(),
                  icon: const Icon(Icons.check_circle_outline),
                  color: colorScheme.primary,
                  tooltip: context.l10n.tripPreviewConfirm,
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
            ? Colors.orange.withValues(alpha: 0.15)
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
                    context.l10n.tripPreviewMaxStopsWarning(TripConstants.maxPoisPerDay),
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
                label: isMultiDay ? context.l10n.tripPreviewStopsDay(selectedDay) : context.l10n.tripSummaryStops,
                isWarning: isOverLimit,
              ),
              _StatItem(
                icon: Icons.straighten,
                value: isMultiDay
                    ? '~${trip.getDistanceForDay(selectedDay).toStringAsFixed(0)} km'
                    : trip.route.formattedDistance,
                label: context.l10n.tripInfoDistance,
              ),
              _StatItem(
                icon: Icons.calendar_today,
                value: '${trip.actualDays}',
                label: context.l10n.tripPreviewDayCount(trip.actualDays),
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
            color: textColor.withValues(alpha: 0.7),
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

class _StopList extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    // POI State für aktuelle Bilder abonnieren
    final poiState = ref.watch(pOIStateNotifierProvider);

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
        startLabel = context.l10n.tripPreviewStartDay1;
      } else {
        // Vorheriger Tag: letzter Stop
        final prevDayStops = trip.getStopsForDay(selectedDay! - 1);
        startLabel = prevDayStops.isNotEmpty
            ? 'Von: ${prevDayStops.last.name}'
            : context.l10n.tripPreviewDayStart('$selectedDay');
      }

      if (selectedDay == trip.actualDays) {
        endLabel = context.l10n.tripPreviewBackToStart;
      } else {
        // Nächster Tag: erster Stop als Ziel
        final nextDayStops = trip.getStopsForDay(selectedDay! + 1);
        endLabel = nextDayStops.isNotEmpty
            ? 'Weiter nach: ${nextDayStops.first.name}'
            : context.l10n.tripPreviewEndDay('$selectedDay');
      }
    } else {
      startLabel = context.l10n.weatherPointStart;
      endLabel = context.l10n.tripPreviewBackToStart;
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

          // v1.6.9: POI aus State holen für aktuelle Bilddaten
          final poiFromState = poiState.pois.where((p) => p.id == stop.poiId).firstOrNull;
          final imageUrl = poiFromState?.imageUrl ?? stop.imageUrl;
          final category = poiFromState?.category ?? stop.category;

          return _StopItem(
            icon: null,
            emoji: stop.categoryIcon,
            iconColor: colorScheme.primary,
            title: stop.name,
            subtitle: stop.detourKm != null
                ? context.l10n.tripPreviewDetour(stop.detourKm!.toStringAsFixed(1))
                : null,
            isOvernightStop: stop.isOvernightStop,
            imageUrl: imageUrl,
            category: category,
            poiId: stop.poiId,
            trailing: POIActionButtons(
              poiId: stop.poiId,
              isLoading: isThisPOILoading,
              canDelete: canRemovePOI,
              onReroll: () => onReroll(stop.poiId),
              onDelete: () => onRemove(stop.poiId),
            ),
            onTap: () {
              // v1.6.9: Navigation zu POI-Details
              // POI zum State hinzufügen falls nicht vorhanden
              final poiNotifier = ref.read(pOIStateNotifierProvider.notifier);
              if (poiFromState == null) {
                // Konvertiere TripStop zu POI und füge hinzu
                final poi = stop.toPOI();
                poiNotifier.addPOI(poi);
              }
              context.push('/poi/${stop.poiId}');
            },
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
  final String? imageUrl;
  final POICategory? category;
  final String? poiId;
  final VoidCallback? onTap;

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
    this.imageUrl,
    this.category,
    this.poiId,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasPOIImage = imageUrl != null || poiId != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline mit optionalem Bild
            SizedBox(
              width: hasPOIImage ? 56 : 40,
              child: Column(
                children: [
                  if (!isFirst)
                    Container(
                      width: 2,
                      height: hasPOIImage ? 8 : 16,
                      color: colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  // v1.6.9: POI-Bild statt nur Icon
                  if (hasPOIImage && poiId != null)
                    _buildPOIImage(colorScheme)
                  else
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.1),
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
                      height: hasPOIImage ? 8 : 16,
                      color: colorScheme.primary.withValues(alpha: 0.3),
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
                              color: Colors.purple.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '🏨 ${context.l10n.tripPreviewOvernight}',
                              style: const TextStyle(fontSize: 10),
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
            // v1.6.9: Pfeil für Navigation
            if (onTap != null)
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  /// v1.6.9: POI-Bild mit Fallback auf Kategorie-Icon
  Widget _buildPOIImage(ColorScheme colorScheme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 48,
        height: 48,
        child: imageUrl != null
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => _buildImagePlaceholder(colorScheme),
                errorWidget: (context, url, error) => _buildImagePlaceholder(colorScheme),
              )
            : _buildImagePlaceholder(colorScheme),
      ),
    );
  }

  Widget _buildImagePlaceholder(ColorScheme colorScheme) {
    final cat = category ?? POICategory.attraction;
    return Container(
      color: Color(cat.colorValue).withValues(alpha: 0.2),
      child: Center(
        child: Text(
          emoji ?? cat.icon,
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
