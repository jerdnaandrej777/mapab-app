import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Button zum Neu-Würfeln eines einzelnen POIs
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
              color: AppTheme.primaryColor.withOpacity(0.3),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(AppTheme.primaryColor),
                  ),
                )
              : const Icon(
                  Icons.casino,
                  size: 16,
                  color: AppTheme.primaryColor,
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
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onReroll,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
        foregroundColor: AppTheme.primaryColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: AppTheme.primaryColor.withOpacity(0.3),
          ),
        ),
      ),
      icon: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(AppTheme.primaryColor),
              ),
            )
          : const Icon(Icons.refresh),
      label: const Text('Neu wurfeln'),
    );
  }
}
