import 'package:travel_planner/l10n/app_localizations.dart';

import '../../data/models/navigation_step.dart';

/// Generiert lokalisierte Navigations-Instruktionen aus OSRM-Manöverdaten
class NavigationInstructionGenerator {
  const NavigationInstructionGenerator._();

  /// Generiert eine lokalisierte Instruktion für einen OSRM-Schritt
  static String generate({
    required ManeuverType type,
    required ManeuverModifier modifier,
    required String streetName,
    required AppLocalizations l10n,
    int? roundaboutExit,
  }) {
    final hasStreet = streetName.isNotEmpty;

    switch (type) {
      case ManeuverType.depart:
        if (hasStreet) {
          return l10n.navDepartOn(streetName);
        }
        return l10n.navDepart;

      case ManeuverType.arrive:
        if (hasStreet) {
          return l10n.navArriveAt(streetName);
        }
        return l10n.navArrive;

      case ManeuverType.turn:
        return _turnInstruction(modifier, streetName, l10n);

      case ManeuverType.newName:
        if (hasStreet) {
          return l10n.navContinueOn(streetName);
        }
        return l10n.navContinue;

      case ManeuverType.merge:
        final dir = _directionWord(modifier, l10n);
        if (hasStreet) {
          return '$dir${l10n.navMergeOn(streetName)}';
        }
        return '$dir${l10n.navMerge}';

      case ManeuverType.onRamp:
        final dir = _directionWord(modifier, l10n);
        if (hasStreet) {
          return '$dir${l10n.navOnRampOn(streetName)}';
        }
        return '$dir${l10n.navOnRamp}';

      case ManeuverType.offRamp:
        final dir = _directionWord(modifier, l10n);
        if (hasStreet) {
          return '$dir${l10n.navOffRampOn(streetName)}';
        }
        return '$dir${l10n.navOffRamp}';

      case ManeuverType.fork:
        return _forkInstruction(modifier, streetName, l10n);

      case ManeuverType.endOfRoad:
        return _endOfRoadInstruction(modifier, streetName, l10n);

      case ManeuverType.roundabout:
      case ManeuverType.rotary:
        return _roundaboutInstruction(roundaboutExit, streetName, l10n);

      case ManeuverType.roundaboutTurn:
        return _turnInstruction(modifier, streetName, l10n);

      case ManeuverType.exitRoundabout:
        if (hasStreet) {
          return l10n.navRoundaboutLeaveOn(streetName);
        }
        return l10n.navRoundaboutLeave;

      case ManeuverType.continueInstruction:
        if (modifier == ManeuverModifier.straight) {
          if (hasStreet) {
            return l10n.navStraightOn(streetName);
          }
          return l10n.navStraightContinue;
        }
        return _turnInstruction(modifier, streetName, l10n);

      case ManeuverType.notification:
        return streetName.isNotEmpty ? streetName : l10n.navContinue;

      case ManeuverType.unknown:
        if (hasStreet) {
          return l10n.navContinueOn(streetName);
        }
        return l10n.navContinue;
    }
  }

  /// Generiert eine verkürzte Instruktion (für TTS bei geringer Distanz)
  static String generateShort({
    required ManeuverType type,
    required ManeuverModifier modifier,
    required AppLocalizations l10n,
    int? roundaboutExit,
  }) {
    switch (type) {
      case ManeuverType.turn:
      case ManeuverType.roundaboutTurn:
      case ManeuverType.continueInstruction:
        return _shortTurnWord(modifier, l10n);

      case ManeuverType.roundabout:
      case ManeuverType.rotary:
        if (roundaboutExit != null) {
          return l10n.navExitShort(_ordinal(roundaboutExit, l10n));
        }
        return l10n.navRoundabout;

      case ManeuverType.arrive:
        return l10n.navArrive;

      case ManeuverType.fork:
        return modifier == ManeuverModifier.left ||
                modifier == ManeuverModifier.slightLeft ||
                modifier == ManeuverModifier.sharpLeft
            ? l10n.navKeepLeft
            : l10n.navKeepRight;

      case ManeuverType.merge:
        return l10n.navMerge;

      case ManeuverType.onRamp:
        return l10n.navOnRamp;

      case ManeuverType.offRamp:
        return l10n.navOffRamp;

      default:
        return l10n.navContinue;
    }
  }

  /// Generiert TTS-Ansage mit Distanz-Prefix
  static String generateWithDistance({
    required ManeuverType type,
    required ManeuverModifier modifier,
    required String streetName,
    required double distanceMeters,
    required AppLocalizations l10n,
    int? roundaboutExit,
  }) {
    final instruction = generate(
      type: type,
      modifier: modifier,
      streetName: streetName,
      l10n: l10n,
      roundaboutExit: roundaboutExit,
    );

    if (distanceMeters <= 50) {
      return l10n.navNow(instruction);
    }

    final distText = _formatDistance(distanceMeters, l10n);
    return l10n.navInDistance(distText, instruction);
  }

  // --- Private Helpers ---

  static String _turnInstruction(
      ManeuverModifier modifier, String streetName, AppLocalizations l10n) {
    final hasStreet = streetName.isNotEmpty;

    switch (modifier) {
      case ManeuverModifier.uturn:
        return hasStreet ? l10n.navUturnOn(streetName) : l10n.navUturn;
      case ManeuverModifier.sharpRight:
        return hasStreet
            ? l10n.navSharpRightOn(streetName)
            : l10n.navSharpRight;
      case ManeuverModifier.right:
        return hasStreet ? l10n.navTurnRightOn(streetName) : l10n.navTurnRight;
      case ManeuverModifier.slightRight:
        return hasStreet
            ? l10n.navSlightRightOn(streetName)
            : l10n.navSlightRight;
      case ManeuverModifier.straight:
        return hasStreet ? l10n.navStraightOn(streetName) : l10n.navStraight;
      case ManeuverModifier.slightLeft:
        return hasStreet
            ? l10n.navSlightLeftOn(streetName)
            : l10n.navSlightLeft;
      case ManeuverModifier.left:
        return hasStreet ? l10n.navTurnLeftOn(streetName) : l10n.navTurnLeft;
      case ManeuverModifier.sharpLeft:
        return hasStreet
            ? l10n.navSharpLeftOn(streetName)
            : l10n.navSharpLeft;
      case ManeuverModifier.none:
        return hasStreet ? l10n.navTurnOn(streetName) : l10n.navTurn;
    }
  }

  static String _forkInstruction(
      ManeuverModifier modifier, String streetName, AppLocalizations l10n) {
    final hasStreet = streetName.isNotEmpty;

    switch (modifier) {
      case ManeuverModifier.left:
      case ManeuverModifier.slightLeft:
      case ManeuverModifier.sharpLeft:
        return hasStreet
            ? l10n.navForkLeftOn(streetName)
            : l10n.navForkLeft;
      case ManeuverModifier.right:
      case ManeuverModifier.slightRight:
      case ManeuverModifier.sharpRight:
        return hasStreet
            ? l10n.navForkRightOn(streetName)
            : l10n.navForkRight;
      default:
        return hasStreet
            ? l10n.navForkStraightOn(streetName)
            : l10n.navForkStraight;
    }
  }

  static String _endOfRoadInstruction(
      ManeuverModifier modifier, String streetName, AppLocalizations l10n) {
    final hasStreet = streetName.isNotEmpty;

    switch (modifier) {
      case ManeuverModifier.left:
      case ManeuverModifier.slightLeft:
      case ManeuverModifier.sharpLeft:
        return hasStreet
            ? l10n.navEndOfRoadLeftOn(streetName)
            : l10n.navEndOfRoadLeft;
      case ManeuverModifier.right:
      case ManeuverModifier.slightRight:
      case ManeuverModifier.sharpRight:
        return hasStreet
            ? l10n.navEndOfRoadRightOn(streetName)
            : l10n.navEndOfRoadRight;
      default:
        return hasStreet
            ? l10n.navEndOfRoadStraightOn(streetName)
            : l10n.navEndOfRoadStraight;
    }
  }

  static String _roundaboutInstruction(
      int? exit, String streetName, AppLocalizations l10n) {
    final hasStreet = streetName.isNotEmpty;

    if (exit != null && exit > 0) {
      final ordinal = _ordinal(exit, l10n);
      if (hasStreet) {
        return l10n.navRoundaboutExitOn(ordinal, streetName);
      }
      return l10n.navRoundaboutExit(ordinal);
    }
    if (hasStreet) {
      return l10n.navRoundaboutEnterOn(streetName);
    }
    return l10n.navRoundaboutEnter;
  }

  static String _shortTurnWord(
      ManeuverModifier modifier, AppLocalizations l10n) {
    switch (modifier) {
      case ManeuverModifier.uturn:
        return l10n.navUturn;
      case ManeuverModifier.sharpRight:
        return l10n.navSharpRightShort;
      case ManeuverModifier.right:
        return l10n.navRightShort;
      case ManeuverModifier.slightRight:
        return l10n.navSlightRightShort;
      case ManeuverModifier.straight:
        return l10n.navStraightShort;
      case ManeuverModifier.slightLeft:
        return l10n.navSlightLeftShort;
      case ManeuverModifier.left:
        return l10n.navLeftShort;
      case ManeuverModifier.sharpLeft:
        return l10n.navSharpLeftShort;
      case ManeuverModifier.none:
        return l10n.navContinue;
    }
  }

  static String _directionWord(
      ManeuverModifier modifier, AppLocalizations l10n) {
    switch (modifier) {
      case ManeuverModifier.left:
      case ManeuverModifier.slightLeft:
      case ManeuverModifier.sharpLeft:
        return l10n.navDirectionLeft;
      case ManeuverModifier.right:
      case ManeuverModifier.slightRight:
      case ManeuverModifier.sharpRight:
        return l10n.navDirectionRight;
      default:
        return '';
    }
  }

  static String _ordinal(int number, AppLocalizations l10n) {
    switch (number) {
      case 1:
        return l10n.navOrdinalFirst;
      case 2:
        return l10n.navOrdinalSecond;
      case 3:
        return l10n.navOrdinalThird;
      case 4:
        return l10n.navOrdinalFourth;
      case 5:
        return l10n.navOrdinalFifth;
      case 6:
        return l10n.navOrdinalSixth;
      case 7:
        return l10n.navOrdinalSeventh;
      case 8:
        return l10n.navOrdinalEighth;
      default:
        return '$number.';
    }
  }

  static String _formatDistance(double meters, AppLocalizations l10n) {
    if (meters < 100) {
      return l10n.navMeters('${meters.round()}');
    } else if (meters < 1000) {
      return l10n.navMeters('${(meters / 50).round() * 50}');
    } else {
      final km = meters / 1000;
      if (km < 10) {
        return l10n.navKilometers(km.toStringAsFixed(1));
      }
      return l10n.navKilometers('${km.round()}');
    }
  }
}
