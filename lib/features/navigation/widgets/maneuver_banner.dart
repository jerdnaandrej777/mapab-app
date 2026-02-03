import 'package:flutter/material.dart';
import '../../../data/models/navigation_step.dart';

/// Banner oben im Navigations-Screen mit aktuellem Manöver
class ManeuverBanner extends StatelessWidget {
  final NavigationStep? currentStep;
  final NavigationStep? nextStep;
  final double distanceToNextStepMeters;

  const ManeuverBanner({
    super.key,
    required this.currentStep,
    this.nextStep,
    required this.distanceToNextStepMeters,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final step = nextStep ?? currentStep;

    if (step == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.primary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              // Manöver-Icon
              _ManeuverIcon(
                type: step.type,
                modifier: step.modifier,
                color: colorScheme.onPrimary,
              ),
              const SizedBox(width: 16),
              // Instruktion + Straße
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Distanz
                    Text(
                      _formatDistance(distanceToNextStepMeters),
                      style: TextStyle(
                        color: colorScheme.onPrimary,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Instruktion
                    Text(
                      step.instruction,
                      style: TextStyle(
                        color: colorScheme.onPrimary.withOpacity(0.9),
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
}

/// Icon für den Manöver-Typ
class _ManeuverIcon extends StatelessWidget {
  final ManeuverType type;
  final ManeuverModifier modifier;
  final Color color;

  const _ManeuverIcon({
    required this.type,
    required this.modifier,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        _getIcon(),
        color: color,
        size: 36,
      ),
    );
  }

  IconData _getIcon() {
    switch (type) {
      case ManeuverType.depart:
        return Icons.navigation;
      case ManeuverType.arrive:
        return Icons.flag;
      case ManeuverType.roundabout:
      case ManeuverType.rotary:
        return Icons.rotate_right;
      case ManeuverType.merge:
        return Icons.merge;
      case ManeuverType.onRamp:
        return Icons.trending_up;
      case ManeuverType.offRamp:
        return Icons.trending_down;
      case ManeuverType.fork:
        return Icons.fork_right;
      default:
        return _getDirectionIcon();
    }
  }

  IconData _getDirectionIcon() {
    switch (modifier) {
      case ManeuverModifier.uturn:
        return Icons.u_turn_right;
      case ManeuverModifier.sharpRight:
        return Icons.turn_sharp_right;
      case ManeuverModifier.right:
        return Icons.turn_right;
      case ManeuverModifier.slightRight:
        return Icons.turn_slight_right;
      case ManeuverModifier.straight:
        return Icons.arrow_upward;
      case ManeuverModifier.slightLeft:
        return Icons.turn_slight_left;
      case ManeuverModifier.left:
        return Icons.turn_left;
      case ManeuverModifier.sharpLeft:
        return Icons.turn_sharp_left;
      case ManeuverModifier.none:
        return Icons.arrow_upward;
    }
  }
}
