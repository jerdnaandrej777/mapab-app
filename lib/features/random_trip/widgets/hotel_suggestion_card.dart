import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/hotel_service.dart';
import 'hotel_detail_sheet.dart';

/// Widget zur Anzeige von Hotel-Vorschlägen
class HotelSuggestionCard extends StatelessWidget {
  final int dayNumber;
  final List<HotelSuggestion> suggestions;
  final HotelSuggestion? selectedHotel;
  final Function(HotelSuggestion) onSelect;
  final DateTime? tripDate;

  const HotelSuggestionCard({
    super.key,
    required this.dayNumber,
    required this.suggestions,
    this.selectedHotel,
    required this.onSelect,
    this.tripDate,
  });

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.orange),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Keine Hotels fur Tag $dayNumber gefunden',
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
        Row(
          children: [
            const Text('🏨', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              'Ubernachtung Tag $dayNumber',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isSelected
            ? AppTheme.primaryColor.withOpacity(0.1)
            : Colors.grey.withOpacity(0.05),
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
                    ? AppTheme.primaryColor
                    : Colors.grey.withOpacity(0.2),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // Radio
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : Colors.grey.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                // Content
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
                      Row(
                        children: [
                          Text(
                            hotel.typeDisplay,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            hotel.formattedDistance,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      if (hotel.address != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          hotel.address!,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                // Info-Button für Details
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onInfoTap,
                  icon: const Icon(Icons.info_outline, size: 22),
                  tooltip: 'Details anzeigen',
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  color: AppTheme.primaryColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Liste aller Hotel-Vorschläge für einen Mehrtages-Trip
class HotelSuggestionsSection extends StatelessWidget {
  final List<List<HotelSuggestion>> suggestionsByDay;
  final Map<int, HotelSuggestion> selectedHotels;
  final Function(int, HotelSuggestion) onSelect;

  const HotelSuggestionsSection({
    super.key,
    required this.suggestionsByDay,
    required this.selectedHotels,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hotel-Vorschlage',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Basierend auf OpenStreetMap-Daten',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        ...suggestionsByDay.asMap().entries.map((entry) {
          final dayIndex = entry.key;
          final suggestions = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: HotelSuggestionCard(
              dayNumber: dayIndex + 1,
              suggestions: suggestions,
              selectedHotel: selectedHotels[dayIndex],
              onSelect: (hotel) => onSelect(dayIndex, hotel),
            ),
          );
        }),
      ],
    );
  }
}
