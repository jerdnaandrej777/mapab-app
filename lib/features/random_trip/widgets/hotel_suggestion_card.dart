import 'package:flutter/material.dart';

import '../../../data/services/hotel_service.dart';
import 'hotel_detail_sheet.dart';

class HotelSuggestionCard extends StatelessWidget {
  final int dayNumber;
  final List<HotelSuggestion> suggestions;
  final HotelSuggestion? selectedHotel;
  final void Function(HotelSuggestion) onSelect;
  final DateTime? tripDate;
  final double radiusKm;

  const HotelSuggestionCard({
    super.key,
    required this.dayNumber,
    required this.suggestions,
    this.selectedHotel,
    required this.onSelect,
    this.tripDate,
    this.radiusKm = 20,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (suggestions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.orange),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Keine Hotels nach Tag $dayNumber im Umkreis von ${radiusKm.toStringAsFixed(0)} km gefunden.',
                style: const TextStyle(color: Colors.orange),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Uebernachtung nach Tag $dayNumber (bis ${radiusKm.toStringAsFixed(0)} km)',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 10),
        ...suggestions.map((hotel) {
          final isSelected = selectedHotel?.id == hotel.id;
          return _HotelItem(
            hotel: hotel,
            isSelected: isSelected,
            onTap: () => onSelect(hotel),
            onInfoTap: () => HotelDetailSheet.show(
              context,
              hotel: hotel,
              tripDate: tripDate,
            ),
          );
        }),
      ],
    );
  }
}

class _HotelItem extends StatelessWidget {
  final HotelSuggestion hotel;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onInfoTap;

  const _HotelItem({
    required this.hotel,
    required this.isSelected,
    required this.onTap,
    required this.onInfoTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final reviewText = hotel.reviewCount != null
        ? '${hotel.reviewCount} Bewertungen'
        : 'Keine Bewertungsdaten';
    final ratingText =
        hotel.rating != null ? '${hotel.rating!.toStringAsFixed(1)} / 5' : null;
    final qualityLabel = switch (hotel.dataQuality) {
      'verified' => 'Verifiziert',
      'few_or_no_reviews' => 'Wenige/keine Reviews',
      _ => 'Begrenzte Daten',
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isSelected
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.outline.withValues(alpha: 0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RadioDot(isSelected: isSelected),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              hotel.name,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (hotel.stars != null)
                            Text(
                              hotel.starsDisplay,
                              style: const TextStyle(fontSize: 12),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${hotel.typeDisplay}  ·  ${hotel.formattedDistance}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (ratingText != null)
                            Text(
                              'Rating: $ratingText',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          Text(
                            reviewText,
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          qualityLabel,
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                      if (hotel.highlights.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          hotel.highlights.first,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (hotel.amenities.hasAny) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: hotel.amenities.availableAmenities
                              .take(4)
                              .map((a) => Text(
                                    '${a.icon} ${a.label}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ))
                              .toList(),
                        ),
                      ],
                      if (hotel.address != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          hotel.address!,
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onInfoTap,
                  icon: const Icon(Icons.info_outline, size: 22),
                  tooltip: 'Details',
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  color: colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  final bool isSelected;

  const _RadioDot({required this.isSelected});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.outline.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: isSelected
          ? Center(
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primary,
                ),
              ),
            )
          : null,
    );
  }
}

class HotelSuggestionsSection extends StatelessWidget {
  final List<List<HotelSuggestion>> suggestionsByDay;
  final Map<int, HotelSuggestion> selectedHotels;
  final void Function(int, HotelSuggestion) onSelect;
  final DateTime? tripStartDate;
  final double radiusKm;

  const HotelSuggestionsSection({
    super.key,
    required this.suggestionsByDay,
    required this.selectedHotels,
    required this.onSelect,
    this.tripStartDate,
    this.radiusKm = 20,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hotel-Vorschlaege',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Datenquelle: Google Places (Fallback: OSM), Radius bis ${radiusKm.toStringAsFixed(0)} km',
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        ...suggestionsByDay.asMap().entries.map((entry) {
          final dayIndex = entry.key;
          final suggestions = entry.value;
          final tripDate = tripStartDate?.add(Duration(days: dayIndex));
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: HotelSuggestionCard(
              dayNumber: dayIndex + 1,
              suggestions: suggestions,
              selectedHotel: selectedHotels[dayIndex],
              onSelect: (hotel) => onSelect(dayIndex, hotel),
              tripDate: tripDate,
              radiusKm: radiusKm,
            ),
          );
        }),
      ],
    );
  }
}
