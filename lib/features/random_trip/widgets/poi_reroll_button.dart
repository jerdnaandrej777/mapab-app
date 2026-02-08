import 'package:flutter/material.dart';

/// Kombiniertes Widget mit Delete und Reroll Buttons für einen POI
class POIActionButtons extends StatelessWidget {
  final String poiId;
  final bool isLoading;
  final bool canDelete;
  final VoidCallback onReroll;
  final VoidCallback onDelete;

  const POIActionButtons({
    super.key,
    required this.poiId,
    required this.isLoading,
    required this.canDelete,
    required this.onReroll,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Delete Button
        if (canDelete)
          _ActionButton(
            icon: Icons.delete_outline,
            color: colorScheme.error,
            isLoading: false,
            isDisabled: isLoading,
            onTap: onDelete,
            tooltip: 'Entfernen',
          ),
        if (canDelete) const SizedBox(width: 4),
        // Reroll Button
        _ActionButton(
          icon: Icons.casino,
          color: colorScheme.primary,
          isLoading: isLoading,
          isDisabled: isLoading,
          onTap: onReroll,
          tooltip: 'Neu würfeln',
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool isLoading;
  final bool isDisabled;
  final VoidCallback onTap;
  final String tooltip;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.isLoading,
    required this.isDisabled,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDisabled
                    ? color.withValues(alpha: 0.2)
                    : color.withValues(alpha: 0.3),
              ),
            ),
            child: isLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  )
                : Icon(
                    icon,
                    size: 16,
                    color: isDisabled ? color.withValues(alpha: 0.4) : color,
                  ),
          ),
        ),
      ),
    );
  }
}

/// Button zum Neu-Würfeln eines einzelnen POIs (Legacy - für Abwärtskompatibilität)
class POIRerollButton extends StatelessWidget {
  final String poiId;
  final bool isLoading;
  final VoidCallback onReroll;

  const POIRerollButton({
    super.key,
    required this.poiId,
    required this.isLoading,
    required this.onReroll,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onReroll,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.3),
            ),
          ),
          child: isLoading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                  ),
                )
              : Icon(
                  Icons.casino,
                  size: 16,
                  color: colorScheme.primary,
                ),
        ),
      ),
    );
  }
}

/// Großer Reroll-Button für den ganzen Trip
class TripRerollButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onReroll;

  const TripRerollButton({
    super.key,
    required this.isLoading,
    required this.onReroll,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ElevatedButton.icon(
      onPressed: isLoading ? null : onReroll,
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
      ),
      icon: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(colorScheme.primary),
              ),
            )
          : const Icon(Icons.refresh),
      label: const Text('Neu würfeln'),
    );
  }
}
