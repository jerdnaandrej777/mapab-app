import 'package:flutter/material.dart';
import '../../../data/models/poi.dart';

/// Card die erscheint wenn ein Must-See POI in der Naehe ist (nicht im Trip).
/// Goldene Akzentfarbe unterscheidet sie von der normalen POI-Approach-Card.
class MustSeePOICard extends StatefulWidget {
  final POI poi;
  final double distanceMeters;
  final VoidCallback onAddStop;
  final VoidCallback onDismiss;

  const MustSeePOICard({
    super.key,
    required this.poi,
    required this.distanceMeters,
    required this.onAddStop,
    required this.onDismiss,
  });

  @override
  State<MustSeePOICard> createState() => _MustSeePOICardState();
}

class _MustSeePOICardState extends State<MustSeePOICard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Goldene Akzentfarbe fuer Must-See Highlights
    const mustSeeColor = Color(0xFFD4A017);
    final mustSeeBg = const Color(0xFFFFF8E1);
    final mustSeeDark = colorScheme.brightness == Brightness.dark
        ? const Color(0xFF3E2C00)
        : mustSeeBg;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: mustSeeColor.withValues(alpha: 0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: mustSeeColor.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Must-See Header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: mustSeeDark,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14.5),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: mustSeeColor, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Must-See in der Nähe',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: mustSeeColor,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatDistance(widget.distanceMeters),
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Kategorie-Icon
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: mustSeeDark,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getCategoryMaterialIcon(widget.poi.categoryId),
                        color: mustSeeColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Name + Umweg
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.poi.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (widget.poi.detourKm != null &&
                              widget.poi.detourKm! > 0.1)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                '~${widget.poi.detourKm!.toStringAsFixed(1)} km Umweg',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Buttons
                    IconButton(
                      onPressed: widget.onDismiss,
                      icon: Icon(
                        Icons.close,
                        color: colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      tooltip: 'Ignorieren',
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                    const SizedBox(width: 4),
                    FilledButton.icon(
                      onPressed: widget.onAddStop,
                      icon: const Icon(Icons.add_location_alt, size: 18),
                      label: const Text('Halt'),
                      style: FilledButton.styleFrom(
                        backgroundColor: mustSeeColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                        textStyle: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDistance(double meters) {
    if (meters < 100) {
      return '${meters.round()} m';
    } else if (meters < 1000) {
      return '${(meters / 50).round() * 50} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  IconData _getCategoryMaterialIcon(String categoryId) {
    switch (categoryId) {
      case 'castle':
        return Icons.castle;
      case 'nature':
        return Icons.forest;
      case 'museum':
        return Icons.museum;
      case 'viewpoint':
        return Icons.landscape;
      case 'lake':
        return Icons.water;
      case 'coast':
        return Icons.beach_access;
      case 'park':
        return Icons.park;
      case 'city':
        return Icons.location_city;
      case 'activity':
        return Icons.attractions;
      case 'hotel':
        return Icons.hotel;
      case 'restaurant':
        return Icons.restaurant;
      case 'unesco':
        return Icons.account_balance;
      case 'church':
        return Icons.church;
      case 'monument':
        return Icons.account_balance;
      case 'attraction':
        return Icons.tour;
      default:
        return Icons.place;
    }
  }
}
