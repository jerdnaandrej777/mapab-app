import 'package:flutter_test/flutter_test.dart';
import 'package:travel_planner/core/utils/navigation_instruction_generator.dart';
import 'package:travel_planner/data/models/navigation_step.dart';

void main() {
  group('NavigationInstructionGenerator.generate', () {
    test('depart mit Strasse', () {
      final result = NavigationInstructionGenerator.generate(
        type: ManeuverType.depart,
        modifier: ManeuverModifier.none,
        streetName: 'Hauptstrasse',
      );
      expect(result, 'Fahre los auf Hauptstrasse');
    });

    test('depart ohne Strasse', () {
      final result = NavigationInstructionGenerator.generate(
        type: ManeuverType.depart,
        modifier: ManeuverModifier.none,
        streetName: '',
      );
      expect(result, 'Fahre los');
    });

    test('arrive mit Strasse', () {
      final result = NavigationInstructionGenerator.generate(
        type: ManeuverType.arrive,
        modifier: ManeuverModifier.none,
        streetName: 'Zielweg',
      );
      expect(result, 'Ziel erreicht: Zielweg');
    });

    test('arrive ohne Strasse', () {
      final result = NavigationInstructionGenerator.generate(
        type: ManeuverType.arrive,
        modifier: ManeuverModifier.none,
        streetName: '',
      );
      expect(result, 'Sie haben Ihr Ziel erreicht');
    });

    test('turn links', () {
      final result = NavigationInstructionGenerator.generate(
        type: ManeuverType.turn,
        modifier: ManeuverModifier.left,
        streetName: 'Bergweg',
      );
      expect(result, 'Links abbiegen auf Bergweg');
    });

    test('turn rechts ohne Strasse', () {
      final result = NavigationInstructionGenerator.generate(
        type: ManeuverType.turn,
        modifier: ManeuverModifier.right,
        streetName: '',
      );
      expect(result, 'Rechts abbiegen');
    });

    test('turn scharf links', () {
      final result = NavigationInstructionGenerator.generate(
        type: ManeuverType.turn,
        modifier: ManeuverModifier.sharpLeft,
        streetName: '',
      );
      expect(result, 'Scharf links abbiegen');
    });

    test('turn leicht rechts', () {
      final result = NavigationInstructionGenerator.generate(
        type: ManeuverType.turn,
        modifier: ManeuverModifier.slightRight,
        streetName: '',
      );
      expect(result, 'Leicht rechts abbiegen');
    });

    test('turn geradeaus', () {
      final result = NavigationInstructionGenerator.generate(
        type: ManeuverType.turn,
        modifier: ManeuverModifier.straight,
        streetName: '',
      );
      expect(result, 'Geradeaus weiter');
    });

    test('turn wenden', () {
      final result = NavigationInstructionGenerator.generate(
        type: ManeuverType.turn,
        modifier: ManeuverModifier.uturn,
        streetName: '',
      );
      expect(result, 'Wenden');
    });

    test('roundabout mit Exit', () {
      final result = NavigationInstructionGenerator.generate(
        type: ManeuverType.roundabout,
        modifier: ManeuverModifier.none,
        streetName: 'B2',
        roundaboutExit: 3,
      );
      expect(result, 'Im Kreisverkehr die dritte Ausfahrt nehmen auf B2');
    });

    test('roundabout ohne Exit', () {
      final result = NavigationInstructionGenerator.generate(
        type: ManeuverType.roundabout,
        modifier: ManeuverModifier.none,
        streetName: '',
      );
      expect(result, 'In den Kreisverkehr einfahren');
    });

    test('fork links', () {
      final result = NavigationInstructionGenerator.generate(
        type: ManeuverType.fork,
        modifier: ManeuverModifier.left,
        streetName: 'A8',
      );
      expect(result, 'An der Gabelung links halten auf A8');
    });

    test('fork rechts ohne Strasse', () {
      final result = NavigationInstructionGenerator.generate(
        type: ManeuverType.fork,
        modifier: ManeuverModifier.right,
        streetName: '',
      );
      expect(result, 'An der Gabelung rechts halten');
    });

    test('endOfRoad links', () {
      final result = NavigationInstructionGenerator.generate(
        type: ManeuverType.endOfRoad,
        modifier: ManeuverModifier.left,
        streetName: '',
      );
      expect(result, 'Am Straßenende links abbiegen');
    });

    test('merge mit Richtung', () {
      final result = NavigationInstructionGenerator.generate(
        type: ManeuverType.merge,
        modifier: ManeuverModifier.slightRight,
        streetName: 'A9',
      );
      expect(result, 'Rechts Einfädeln auf A9');
    });

    test('onRamp', () {
      final result = NavigationInstructionGenerator.generate(
        type: ManeuverType.onRamp,
        modifier: ManeuverModifier.right,
        streetName: 'A99',
      );
      expect(result, 'Rechts Auffahrt nehmen auf A99');
    });

    test('offRamp', () {
      final result = NavigationInstructionGenerator.generate(
        type: ManeuverType.offRamp,
        modifier: ManeuverModifier.left,
        streetName: '',
      );
      expect(result, 'Links Abfahrt nehmen');
    });

    test('continue straight', () {
      final result = NavigationInstructionGenerator.generate(
        type: ManeuverType.continueInstruction,
        modifier: ManeuverModifier.straight,
        streetName: 'B12',
      );
      expect(result, 'Geradeaus weiter auf B12');
    });

    test('continue nicht straight delegiert an turn', () {
      final result = NavigationInstructionGenerator.generate(
        type: ManeuverType.continueInstruction,
        modifier: ManeuverModifier.left,
        streetName: '',
      );
      expect(result, 'Links abbiegen');
    });

    test('exitRoundabout', () {
      final result = NavigationInstructionGenerator.generate(
        type: ManeuverType.exitRoundabout,
        modifier: ManeuverModifier.none,
        streetName: 'B1',
      );
      expect(result, 'Kreisverkehr verlassen auf B1');
    });

    test('newName', () {
      final result = NavigationInstructionGenerator.generate(
        type: ManeuverType.newName,
        modifier: ManeuverModifier.none,
        streetName: 'Marktplatz',
      );
      expect(result, 'Weiter auf Marktplatz');
    });
  });

  group('NavigationInstructionGenerator.generateShort', () {
    test('turn-Modifier geben kurze Woerter', () {
      expect(
        NavigationInstructionGenerator.generateShort(
          type: ManeuverType.turn,
          modifier: ManeuverModifier.left,
        ),
        'Links',
      );
      expect(
        NavigationInstructionGenerator.generateShort(
          type: ManeuverType.turn,
          modifier: ManeuverModifier.right,
        ),
        'Rechts',
      );
      expect(
        NavigationInstructionGenerator.generateShort(
          type: ManeuverType.turn,
          modifier: ManeuverModifier.uturn,
        ),
        'Wenden',
      );
      expect(
        NavigationInstructionGenerator.generateShort(
          type: ManeuverType.turn,
          modifier: ManeuverModifier.straight,
        ),
        'Geradeaus',
      );
    });

    test('roundabout mit Exit', () {
      expect(
        NavigationInstructionGenerator.generateShort(
          type: ManeuverType.roundabout,
          modifier: ManeuverModifier.none,
          roundaboutExit: 2,
        ),
        'zweite Ausfahrt',
      );
    });

    test('roundabout ohne Exit', () {
      expect(
        NavigationInstructionGenerator.generateShort(
          type: ManeuverType.roundabout,
          modifier: ManeuverModifier.none,
        ),
        'Kreisverkehr',
      );
    });

    test('arrive', () {
      expect(
        NavigationInstructionGenerator.generateShort(
          type: ManeuverType.arrive,
          modifier: ManeuverModifier.none,
        ),
        'Ziel erreicht',
      );
    });

    test('fork links', () {
      expect(
        NavigationInstructionGenerator.generateShort(
          type: ManeuverType.fork,
          modifier: ManeuverModifier.left,
        ),
        'Links halten',
      );
    });

    test('fork rechts', () {
      expect(
        NavigationInstructionGenerator.generateShort(
          type: ManeuverType.fork,
          modifier: ManeuverModifier.right,
        ),
        'Rechts halten',
      );
    });
  });

  group('NavigationInstructionGenerator.generateWithDistance', () {
    test('<= 50m sagt Jetzt', () {
      final result = NavigationInstructionGenerator.generateWithDistance(
        type: ManeuverType.turn,
        modifier: ManeuverModifier.left,
        streetName: '',
        distanceMeters: 30,
      );
      expect(result, 'Jetzt Links abbiegen');
    });

    test('> 50m sagt In X', () {
      final result = NavigationInstructionGenerator.generateWithDistance(
        type: ManeuverType.turn,
        modifier: ManeuverModifier.right,
        streetName: 'B1',
        distanceMeters: 200,
      );
      expect(result, startsWith('In 200 Metern'));
    });

    test('Kilometer-Formatierung bei > 1000m', () {
      final result = NavigationInstructionGenerator.generateWithDistance(
        type: ManeuverType.turn,
        modifier: ManeuverModifier.left,
        streetName: '',
        distanceMeters: 2500,
      );
      expect(result, contains('Kilometern'));
    });

    test('kleine Distanz < 100m wird direkt gerundet', () {
      final result = NavigationInstructionGenerator.generateWithDistance(
        type: ManeuverType.turn,
        modifier: ManeuverModifier.right,
        streetName: '',
        distanceMeters: 75,
      );
      expect(result, 'In 75 Metern Rechts abbiegen');
    });

    test('mittlere Distanz wird auf 50m gerundet', () {
      final result = NavigationInstructionGenerator.generateWithDistance(
        type: ManeuverType.turn,
        modifier: ManeuverModifier.right,
        streetName: '',
        distanceMeters: 320,
      );
      // 320 / 50 = 6.4 → round = 6 → 6*50 = 300
      expect(result, 'In 300 Metern Rechts abbiegen');
    });
  });

  group('ManeuverType.fromOsrm', () {
    test('erkennt bekannte OSRM-Strings', () {
      expect(ManeuverType.fromOsrm('turn'), ManeuverType.turn);
      expect(ManeuverType.fromOsrm('depart'), ManeuverType.depart);
      expect(ManeuverType.fromOsrm('arrive'), ManeuverType.arrive);
      expect(ManeuverType.fromOsrm('roundabout'), ManeuverType.roundabout);
      expect(ManeuverType.fromOsrm('fork'), ManeuverType.fork);
      expect(ManeuverType.fromOsrm('end of road'), ManeuverType.endOfRoad);
      expect(ManeuverType.fromOsrm('continue'),
          ManeuverType.continueInstruction);
    });

    test('gibt unknown fuer unbekannten String', () {
      expect(ManeuverType.fromOsrm('xyz'), ManeuverType.unknown);
    });
  });

  group('ManeuverModifier.fromOsrm', () {
    test('erkennt bekannte OSRM-Strings', () {
      expect(ManeuverModifier.fromOsrm('left'), ManeuverModifier.left);
      expect(ManeuverModifier.fromOsrm('right'), ManeuverModifier.right);
      expect(ManeuverModifier.fromOsrm('straight'), ManeuverModifier.straight);
      expect(ManeuverModifier.fromOsrm('sharp left'),
          ManeuverModifier.sharpLeft);
      expect(ManeuverModifier.fromOsrm('uturn'), ManeuverModifier.uturn);
    });

    test('null/leer gibt none', () {
      expect(ManeuverModifier.fromOsrm(null), ManeuverModifier.none);
      expect(ManeuverModifier.fromOsrm(''), ManeuverModifier.none);
    });

    test('unbekannter Wert gibt none', () {
      expect(ManeuverModifier.fromOsrm('xyz'), ManeuverModifier.none);
    });
  });

  group('Ordinal-Zahlen in Kreisverkehr', () {
    test('Exits 1-8 geben deutsche Ordinalzahlen', () {
      final expected = {
        1: 'erste',
        2: 'zweite',
        3: 'dritte',
        4: 'vierte',
        5: 'fünfte',
        6: 'sechste',
        7: 'siebte',
        8: 'achte',
      };

      for (final entry in expected.entries) {
        final result = NavigationInstructionGenerator.generate(
          type: ManeuverType.roundabout,
          modifier: ManeuverModifier.none,
          streetName: '',
          roundaboutExit: entry.key,
        );
        expect(result, contains(entry.value),
            reason: 'Exit ${entry.key} sollte "${entry.value}" enthalten');
      }
    });

    test('Exit > 8 verwendet Zahl mit Punkt', () {
      final result = NavigationInstructionGenerator.generate(
        type: ManeuverType.roundabout,
        modifier: ManeuverModifier.none,
        streetName: '',
        roundaboutExit: 9,
      );
      expect(result, contains('9.'));
    });
  });
}
