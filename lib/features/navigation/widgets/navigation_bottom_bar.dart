import 'package:flutter/material.dart';
import '../../../core/l10n/l10n.dart';

/// Bottom Bar im Navigations-Screen mit ETA, Distanz und Kontrollen
class NavigationBottomBar extends StatelessWidget {
  final double distanceToDestinationKm;
  final int etaMinutes;
  final double? currentSpeedKmh;
  final bool isMuted;
  final bool isListening;
  final VoidCallback onToggleMute;
  final VoidCallback onStop;
  final VoidCallback onOverview;
  final VoidCallback? onVoiceCommand;

  const NavigationBottomBar({
    super.key,
    required this.distanceToDestinationKm,
    required this.etaMinutes,
    this.currentSpeedKmh,
    required this.isMuted,
    this.isListening = false,
    required this.onToggleMute,
    required this.onStop,
    required this.onOverview,
    this.onVoiceCommand,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
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
                    label: context.l10n.navDistance,
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
                    label: context.l10n.navArrival,
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
                    label: context.l10n.navSpeed,
                    value: currentSpeedKmh != null
                        ? '${currentSpeedKmh!.round()} km/h'
                        : '-- km/h',
                    icon: Icons.speed,
                    colorScheme: colorScheme,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Button-Zeile - alle quadratischen Icon-Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Mute/Unmute
                  _IconActionButton(
                    icon: isMuted ? Icons.volume_off : Icons.volume_up,
                    tooltip: isMuted
                        ? context.l10n.navMuteOn
                        : context.l10n.navMuteOff,
                    onTap: onToggleMute,
                    colorScheme: colorScheme,
                  ),
                  // Sprachbefehl
                  if (onVoiceCommand != null)
                    _IconActionButton(
                      icon: isListening ? Icons.mic : Icons.mic_none,
                      tooltip: context.l10n.navVoice,
                      onTap: onVoiceCommand!,
                      colorScheme: colorScheme,
                      isActive: isListening,
                    ),
                  // Übersicht
                  _IconActionButton(
                    icon: Icons.map_outlined,
                    tooltip: context.l10n.navOverview,
                    onTap: onOverview,
                    colorScheme: colorScheme,
                  ),
                  // Navigation beenden - quadratisch rot
                  _IconActionButton(
                    icon: Icons.close,
                    tooltip: context.l10n.navEnd,
                    onTap: onStop,
                    colorScheme: colorScheme,
                    isError: true,
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
    return Semantics(
      label: '$label: $value',
      child: Column(
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
      ),
    );
  }
}

/// Kompakter Icon-Button für Navigations-Aktionen
class _IconActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final bool isActive;
  final bool isError;

  const _IconActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.colorScheme,
    this.isActive = false,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    final Color iconColor;

    if (isError) {
      bgColor = colorScheme.error;
      iconColor = colorScheme.onError;
    } else if (isActive) {
      bgColor = colorScheme.primary;
      iconColor = colorScheme.onPrimary;
    } else {
      bgColor = colorScheme.surfaceContainerHighest;
      iconColor = colorScheme.onSurfaceVariant;
    }

    return Tooltip(
      message: tooltip,
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 24,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}
