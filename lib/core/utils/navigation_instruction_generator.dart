import '../../data/models/navigation_step.dart';

/// Generiert deutsche Navigations-Instruktionen aus OSRM-Manöverdaten
class NavigationInstructionGenerator {
  const NavigationInstructionGenerator._();

  /// Generiert eine deutsche Instruktion für einen OSRM-Schritt
  static String generate({
    required ManeuverType type,
    required ManeuverModifier modifier,
    required String streetName,
    int? roundaboutExit,
  }) {
    final hasStreet = streetName.isNotEmpty;

    switch (type) {
      case ManeuverType.depart:
        if (hasStreet) {
          return 'Fahre los auf $streetName';
        }
        return 'Fahre los';

      case ManeuverType.arrive:
        if (hasStreet) {
          return 'Ziel erreicht: $streetName';
        }
        return 'Sie haben Ihr Ziel erreicht';

      case ManeuverType.turn:
        return _turnInstruction(modifier, streetName);

      case ManeuverType.newName:
        if (hasStreet) {
          return 'Weiter auf $streetName';
        }
        return 'Weiterfahren';

      case ManeuverType.merge:
        final dir = _directionWord(modifier);
        if (hasStreet) {
          return '${dir}Einfädeln auf $streetName';
        }
        return '${dir}Einfädeln';

      case ManeuverType.onRamp:
        final dir = _directionWord(modifier);
        if (hasStreet) {
          return '${dir}Auffahrt nehmen auf $streetName';
        }
        return '${dir}Auffahrt nehmen';

      case ManeuverType.offRamp:
        final dir = _directionWord(modifier);
        if (hasStreet) {
          return '${dir}Abfahrt nehmen auf $streetName';
        }
        return '${dir}Abfahrt nehmen';

      case ManeuverType.fork:
        return _forkInstruction(modifier, streetName);

      case ManeuverType.endOfRoad:
        return _endOfRoadInstruction(modifier, streetName);

      case ManeuverType.roundabout:
      case ManeuverType.rotary:
        return _roundaboutInstruction(roundaboutExit, streetName);

      case ManeuverType.roundaboutTurn:
        return _turnInstruction(modifier, streetName);

      case ManeuverType.exitRoundabout:
        if (hasStreet) {
          return 'Kreisverkehr verlassen auf $streetName';
        }
        return 'Kreisverkehr verlassen';

      case ManeuverType.continueInstruction:
        if (modifier == ManeuverModifier.straight) {
          if (hasStreet) {
            return 'Geradeaus weiter auf $streetName';
          }
          return 'Geradeaus weiterfahren';
        }
        return _turnInstruction(modifier, streetName);

      case ManeuverType.notification:
        return streetName.isNotEmpty ? streetName : 'Weiterfahren';

      case ManeuverType.unknown:
        if (hasStreet) {
          return 'Weiter auf $streetName';
        }
        return 'Weiterfahren';
    }
  }

  /// Generiert eine verkürzte Instruktion (für TTS bei geringer Distanz)
  static String generateShort({
    required ManeuverType type,
    required ManeuverModifier modifier,
    int? roundaboutExit,
  }) {
    switch (type) {
      case ManeuverType.turn:
      case ManeuverType.roundaboutTurn:
      case ManeuverType.continueInstruction:
        return _shortTurnWord(modifier);

      case ManeuverType.roundabout:
      case ManeuverType.rotary:
        if (roundaboutExit != null) {
          return '${_ordinal(roundaboutExit)} Ausfahrt';
        }
        return 'Kreisverkehr';

      case ManeuverType.arrive:
        return 'Ziel erreicht';

      case ManeuverType.fork:
        return modifier == ManeuverModifier.left ||
                modifier == ManeuverModifier.slightLeft ||
                modifier == ManeuverModifier.sharpLeft
            ? 'Links halten'
            : 'Rechts halten';

      case ManeuverType.merge:
        return 'Einfädeln';

      case ManeuverType.onRamp:
        return 'Auffahrt';

      case ManeuverType.offRamp:
        return 'Abfahrt';

      default:
        return 'Weiter';
    }
  }

  /// Generiert TTS-Ansage mit Distanz-Prefix
  static String generateWithDistance({
    required ManeuverType type,
    required ManeuverModifier modifier,
    required String streetName,
    required double distanceMeters,
    int? roundaboutExit,
  }) {
    final instruction = generate(
      type: type,
      modifier: modifier,
      streetName: streetName,
      roundaboutExit: roundaboutExit,
    );

    if (distanceMeters <= 50) {
      return 'Jetzt $instruction';
    }

    final distText = _formatDistance(distanceMeters);
    return 'In $distText $instruction';
  }

  // --- Private Helpers ---

  static String _turnInstruction(ManeuverModifier modifier, String streetName) {
    final hasStreet = streetName.isNotEmpty;
    final suffix = hasStreet ? ' auf $streetName' : '';

    switch (modifier) {
      case ManeuverModifier.uturn:
        return 'Wenden$suffix';
      case ManeuverModifier.sharpRight:
        return 'Scharf rechts abbiegen$suffix';
      case ManeuverModifier.right:
        return 'Rechts abbiegen$suffix';
      case ManeuverModifier.slightRight:
        return 'Leicht rechts abbiegen$suffix';
      case ManeuverModifier.straight:
        return 'Geradeaus weiter$suffix';
      case ManeuverModifier.slightLeft:
        return 'Leicht links abbiegen$suffix';
      case ManeuverModifier.left:
        return 'Links abbiegen$suffix';
      case ManeuverModifier.sharpLeft:
        return 'Scharf links abbiegen$suffix';
      case ManeuverModifier.none:
        return 'Abbiegen$suffix';
    }
  }

  static String _forkInstruction(
      ManeuverModifier modifier, String streetName) {
    final hasStreet = streetName.isNotEmpty;
    final suffix = hasStreet ? ' auf $streetName' : '';

    switch (modifier) {
      case ManeuverModifier.left:
      case ManeuverModifier.slightLeft:
      case ManeuverModifier.sharpLeft:
        return 'An der Gabelung links halten$suffix';
      case ManeuverModifier.right:
      case ManeuverModifier.slightRight:
      case ManeuverModifier.sharpRight:
        return 'An der Gabelung rechts halten$suffix';
      default:
        return 'An der Gabelung weiterfahren$suffix';
    }
  }

  static String _endOfRoadInstruction(
      ManeuverModifier modifier, String streetName) {
    final hasStreet = streetName.isNotEmpty;
    final suffix = hasStreet ? ' auf $streetName' : '';

    switch (modifier) {
      case ManeuverModifier.left:
      case ManeuverModifier.slightLeft:
      case ManeuverModifier.sharpLeft:
        return 'Am Straßenende links abbiegen$suffix';
      case ManeuverModifier.right:
      case ManeuverModifier.slightRight:
      case ManeuverModifier.sharpRight:
        return 'Am Straßenende rechts abbiegen$suffix';
      default:
        return 'Am Straßenende weiterfahren$suffix';
    }
  }

  static String _roundaboutInstruction(int? exit, String streetName) {
    final hasStreet = streetName.isNotEmpty;
    final suffix = hasStreet ? ' auf $streetName' : '';

    if (exit != null && exit > 0) {
      return 'Im Kreisverkehr die ${_ordinal(exit)} Ausfahrt nehmen$suffix';
    }
    return 'In den Kreisverkehr einfahren$suffix';
  }

  static String _shortTurnWord(ManeuverModifier modifier) {
    switch (modifier) {
      case ManeuverModifier.uturn:
        return 'Wenden';
      case ManeuverModifier.sharpRight:
        return 'Scharf rechts';
      case ManeuverModifier.right:
        return 'Rechts';
      case ManeuverModifier.slightRight:
        return 'Leicht rechts';
      case ManeuverModifier.straight:
        return 'Geradeaus';
      case ManeuverModifier.slightLeft:
        return 'Leicht links';
      case ManeuverModifier.left:
        return 'Links';
      case ManeuverModifier.sharpLeft:
        return 'Scharf links';
      case ManeuverModifier.none:
        return 'Weiter';
    }
  }

  static String _directionWord(ManeuverModifier modifier) {
    switch (modifier) {
      case ManeuverModifier.left:
      case ManeuverModifier.slightLeft:
      case ManeuverModifier.sharpLeft:
        return 'Links ';
      case ManeuverModifier.right:
      case ManeuverModifier.slightRight:
      case ManeuverModifier.sharpRight:
        return 'Rechts ';
      default:
        return '';
    }
  }

  static String _ordinal(int number) {
    switch (number) {
      case 1:
        return 'erste';
      case 2:
        return 'zweite';
      case 3:
        return 'dritte';
      case 4:
        return 'vierte';
      case 5:
        return 'fünfte';
      case 6:
        return 'sechste';
      case 7:
        return 'siebte';
      case 8:
        return 'achte';
      default:
        return '${number}.';
    }
  }

  static String _formatDistance(double meters) {
    if (meters < 100) {
      return '${meters.round()} Metern';
    } else if (meters < 1000) {
      return '${(meters / 50).round() * 50} Metern';
    } else {
      final km = meters / 1000;
      if (km < 10) {
        return '${km.toStringAsFixed(1)} Kilometern';
      }
      return '${km.round()} Kilometern';
    }
  }
}
