import 'package:flutter/material.dart';

/// Bottom Bar im Navigations-Screen mit ETA, Distanz und Kontrollen
class NavigationBottomBar extends StatelessWidget {
  final double distanceToDestinationKm;
  final int etaMinutes;
  final double? currentSpeedKmh;
  final bool isMuted;
  final VoidCallback onToggleMute;
  final VoidCallback onStop;
  final VoidCallback onOverview;

  const NavigationBottomBar({
    super.key,
    required this.distanceToDestinationKm,
    required this.etaMinutes,
    this.currentSpeedKmh,
    required this.isMuted,
    required this.onToggleMute,
    required this.onStop,
    required this.onOverview,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Route-Info Zeile
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Verbleibende Distanz
                  _InfoItem(
                    label: 'Distanz',
                    value: _formatDistance(distanceToDestinationKm),
                    icon: Icons.straighten,
                    colorScheme: colorScheme,
                  ),
                  // Vertikaler Trenner
                  Container(
                    height: 32,
                    width: 1,
                    color: colorScheme.outlineVariant,
                  ),
                  // ETA
                  _InfoItem(
                    label: 'Ankunft',
                    value: _formatETA(etaMinutes),
                    icon: Icons.access_time,
                    colorScheme: colorScheme,
                  ),
                  // Vertikaler Trenner
                  Container(
                    height: 32,
                    width: 1,
                    color: colorScheme.outlineVariant,
                  ),
                  // Geschwindigkeit
                  _InfoItem(
                    label: 'Tempo',
                    value: currentSpeedKmh != null
                        ? '${currentSpeedKmh!.round()} km/h'
                        : '-- km/h',
                    icon: Icons.speed,
                    colorScheme: colorScheme,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Button-Zeile
              Row(
                children: [
                  // Mute/Unmute
                  _ActionButton(
                    icon: isMuted
                        ? Icons.volume_off
                        : Icons.volume_up,
                    label: isMuted ? 'Ton an' : 'Ton aus',
                    onTap: onToggleMute,
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(width: 8),
                  // Übersicht
                  _ActionButton(
                    icon: Icons.map_outlined,
                    label: 'Übersicht',
                    onTap: onOverview,
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(width: 8),
                  // Navigation beenden
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onStop,
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Beenden'),
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.error,
                        foregroundColor: colorScheme.onError,
                        minimumSize: const Size(0, 44),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDistance(double km) {
    if (km < 1) {
      return '${(km * 1000).round()} m';
    } else if (km < 100) {
      return '${km.toStringAsFixed(1)} km';
    }
    return '${km.round()} km';
  }

  String _formatETA(int minutes) {
    final now = DateTime.now().add(Duration(minutes: minutes));
    return '~${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}';
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final ColorScheme colorScheme;

  const _InfoItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }
}
