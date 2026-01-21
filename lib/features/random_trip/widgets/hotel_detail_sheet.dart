import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/hotel_service.dart';

/// Bottom Sheet mit Hotel-Details
/// Zeigt Amenities, Check-in/out, Kontakt und Booking.com Link
class HotelDetailSheet extends StatelessWidget {
  final HotelSuggestion hotel;
  final DateTime? tripDate;

  const HotelDetailSheet({
    super.key,
    required this.hotel,
    this.tripDate,
  });

  /// Zeigt das Detail-Sheet modal an
  static Future<void> show(
    BuildContext context, {
    required HotelSuggestion hotel,
    DateTime? tripDate,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => HotelDetailSheet(
        hotel: hotel,
        tripDate: tripDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    if (hotel.amenities.hasAny) ...[
                      _buildAmenities(),
                      const SizedBox(height: 20),
                    ],
                    if (hotel.checkInOutDisplay != null) ...[
                      _buildCheckInOut(),
                      const SizedBox(height: 20),
                    ],
                    if (hotel.address != null) ...[
                      _buildAddress(),
                      const SizedBox(height: 20),
                    ],
                    if (hotel.hasContactInfo) ...[
                      _buildContact(),
                      const SizedBox(height: 20),
                    ],
                    if (hotel.description != null) ...[
                      _buildDescription(),
                      const SizedBox(height: 20),
                    ],
                    _buildBookingButton(context),
                    const SizedBox(height: 12),
                    _buildMapsButton(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              hotel.type.icon,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hotel.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        hotel.type.label,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      if (hotel.stars != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          hotel.starsDisplay,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_on,
                size: 16,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 4),
              Text(
                hotel.formattedDistance,
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAmenities() {
    final amenities = hotel.amenities.availableAmenities;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ausstattung',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: amenities.map((amenity) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(amenity.icon, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    amenity.label,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCheckInOut() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hotel.checkInTime != null)
                  Text(
                    'Check-in: ${hotel.checkInTime}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                if (hotel.checkOutTime != null)
                  Text(
                    'Check-out: ${hotel.checkOutTime}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddress() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.place, color: AppTheme.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            hotel.address!,
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildContact() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kontakt',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        if (hotel.phone != null)
          _ContactTile(
            icon: Icons.phone,
            label: hotel.phone!,
            onTap: () => _launchUrl('tel:${hotel.phone}'),
          ),
        if (hotel.email != null)
          _ContactTile(
            icon: Icons.email,
            label: hotel.email!,
            onTap: () => _launchUrl('mailto:${hotel.email}'),
          ),
        if (hotel.website != null)
          _ContactTile(
            icon: Icons.language,
            label: hotel.website!,
            onTap: () => _launchUrl(hotel.website!),
          ),
      ],
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Beschreibung',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          hotel.description!,
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildBookingButton(BuildContext context) {
    final checkIn = tripDate ?? DateTime.now().add(const Duration(days: 1));
    final bookingUrl = hotel.getBookingUrl(checkIn: checkIn);

    return ElevatedButton.icon(
      onPressed: () => _launchUrl(bookingUrl),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF003580), // Booking.com Blau
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      icon: const Icon(Icons.hotel),
      label: Column(
        children: [
          const Text(
            'Auf Booking.com ansehen',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          Text(
            'Verfugbarkeit fur ${_formatDate(checkIn)} prufen',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
          ),
        ],
      ),
    );
  }

  Widget _buildMapsButton() {
    return OutlinedButton.icon(
      onPressed: () => _launchUrl(hotel.googleMapsUrl),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      icon: const Icon(Icons.map),
      label: const Text('In Google Maps offnen'),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ContactTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  decoration: TextDecoration.underline,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
