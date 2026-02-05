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
              // Button-Zeile - alle Buttons gleichmäßig verteilt
              Row(
                children: [
                  // Mute/Unmute
                  Expanded(
                    child: _ActionButton(
                      icon: isMuted
                          ? Icons.volume_off
                          : Icons.volume_up,
                      label: isMuted ? context.l10n.navMuteOn : context.l10n.navMuteOff,
                      onTap: onToggleMute,
                      colorScheme: colorScheme,
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Sprachbefehl
                  if (onVoiceCommand != null) ...[
                    Expanded(
                      child: _ActionButton(
                        icon: isListening ? Icons.mic : Icons.mic_none,
                        label: isListening ? context.l10n.navVoiceListening : context.l10n.navVoice,
                        onTap: onVoiceCommand!,
                        colorScheme: colorScheme,
                        isActive: isListening,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  // Übersicht
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.map_outlined,
                      label: context.l10n.navOverview,
                      onTap: onOverview,
                      colorScheme: colorScheme,
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Navigation beenden
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onStop,
                      icon: const Icon(Icons.close, size: 18),
                      label: Text(context.l10n.navEnd),
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

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final bool isActive;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.colorScheme,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isActive) {
      return FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Flexible(
          child: Text(
            label,
            style: const TextStyle(fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      );
    }
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Flexible(
        child: Text(
          label,
          style: const TextStyle(fontSize: 11),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }
}
