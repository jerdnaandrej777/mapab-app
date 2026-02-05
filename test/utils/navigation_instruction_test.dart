import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:travel_planner/core/utils/navigation_instruction_generator.dart';
import 'package:travel_planner/data/models/navigation_step.dart';
import 'package:travel_planner/l10n/app_localizations.dart';

void main() {
  // Deutsche Lokalisierung fuer Tests
  late AppLocalizations l10n;

  setUpAll(() {
    l10n = lookupAppLocalizations(const Locale('de'));
  });

  group('NavigationInstructionGenerator.generate', () {
    test('depart mit Strasse', () {
      final result = NavigationInstructionGenerator.generate(
        type: ManeuverType.depart,
        modifier: ManeuverModifier.none,
        streetName: 'Hauptstrasse',
        l10n: l10n,
      );
      expect(result, l10n.navDepartOn('Hauptstrasse'));
    });

    test('depart ohne Strasse', () {
      final result = NavigationInstructionGenerator.generate(
        type: ManeuverType.depart,
        modifier: ManeuverModifier.none,
        streetName: '',
        l10n: l10n,
      );
      expect(result, l10n.navDepart);
    });

    test('arrive mit Strasse', () {
      final result = NavigationInstructionGenerator.generate(
        type: ManeuverType.arrive,
        modifier: ManeuverModifier.none,
        streetName: 'Zielweg',
        l10n: l10n,
      );
      expect(result, l10n.navArriveAt('Zielweg'));
    });

    test('arrive ohne Strasse', () {
      final result = NavigationInstructionGenerator.generate(
        type: ManeuverType.arrive,
        modifier: ManeuverModifier.none,
        streetName: '',
        l10n: l10n,
      );
      expect(result, l10n.navArrive);
    });

    test('turn links', () {
      final result = NavigationInstructionGenerator.generate(
        type: ManeuverType.turn,
        modifier: ManeuverModifier.left,
        streetName: 'Bergweg',
        l10n: l10n,
      );
      expect(result, l10n.navTurnLeftOn('Bergweg'));
    });

    test('turn rechts ohne Strasse', () {
      final result = NavigationInstructionGenerator.generate(
        type: ManeuverType.turn,
        modifier: ManeuverModifier.right,
        streetName: '',
        l10n: l10n,
      );
      expect(result, l10n.navTurnRight);
    });

    test('turn scharf links', () {
      final result = NavigationInstructionGenerator.generate(
        type: ManeuverType.turn,
        modifier: ManeuverModifier.sharpLeft,
        streetName: '',
        l10n: l10n,
      );
      expect(result, l10n.navSharpLeft);
    });

    test('turn leicht rechts', () {
      final result = NavigationInstructionGenerator.generate(
        type: ManeuverType.turn,
        modifier: ManeuverModifier.slightRight,
        streetName: '',
        l10n: l10n,
      );
      expect(result, l10n.navSlightRight);
    });

    test('turn geradeaus', () {
      final result = NavigationInstructionGenerator.generate(
        type: ManeuverType.turn,
        modifier: ManeuverModifier.straight,
        streetName: '',
        l10n: l10n,
      );
      expect(result, l10n.navStraight);
    });

    test('turn wenden', () {
      final result = NavigationInstructionGenerator.generate(
        type: ManeuverType.turn,
        modifier: ManeuverModifier.uturn,
        streetName: '',
        l10n: l10n,
      );
      expect(result, l10n.navUturn);
    });

    test('roundabout mit Exit', () {
      final result = NavigationInstructionGenerator.generate(
        type: ManeuverType.roundabout,
        modifier: ManeuverModifier.none,
        streetName: 'B2',
        l10n: l10n,
        roundaboutExit: 3,
      );
      expect(result, l10n.navRoundaboutExitOn(l10n.navOrdinalThird, 'B2'));
    });

    test('roundabout ohne Exit', () {
      final result = NavigationInstructionGenerator.generate(
        type: ManeuverType.roundabout,
        modifier: ManeuverModifier.none,
        streetName: '',
        l10n: l10n,
      );
      expect(result, l10n.navRoundaboutEnter);
    });

    test('fork links', () {
      final result = NavigationInstructionGenerator.generate(
        type: ManeuverType.fork,
        modifier: ManeuverModifier.left,
        streetName: 'A8',
        l10n: l10n,
      );
      expect(result, l10n.navForkLeftOn('A8'));
    });

    test('fork rechts ohne Strasse', () {
      final result = NavigationInstructionGenerator.generate(
        type: ManeuverType.fork,
        modifier: ManeuverModifier.right,
        streetName: '',
        l10n: l10n,
      );
      expect(result, l10n.navForkRight);
    });

    test('endOfRoad links', () {
      final result = NavigationInstructionGenerator.generate(
        type: ManeuverType.endOfRoad,
        modifier: ManeuverModifier.left,
        streetName: '',
        l10n: l10n,
      );
      expect(result, l10n.navEndOfRoadLeft);
    });

    test('merge mit Richtung', () {
      final result = NavigationInstructionGenerator.generate(
        type: ManeuverType.merge,
        modifier: ManeuverModifier.slightRight,
        streetName: 'A9',
        l10n: l10n,
      );
      expect(result, '${l10n.navDirectionRight}${l10n.navMergeOn('A9')}');
    });

    test('onRamp', () {
      final result = NavigationInstructionGenerator.generate(
        type: ManeuverType.onRamp,
        modifier: ManeuverModifier.right,
        streetName: 'A99',
        l10n: l10n,
      );
      expect(result, '${l10n.navDirectionRight}${l10n.navOnRampOn('A99')}');
    });

    test('offRamp', () {
      final result = NavigationInstructionGenerator.generate(
        type: ManeuverType.offRamp,
        modifier: ManeuverModifier.left,
        streetName: '',
        l10n: l10n,
      );
      expect(result, '${l10n.navDirectionLeft}${l10n.navOffRamp}');
    });

    test('continue straight', () {
      final result = NavigationInstructionGenerator.generate(
        type: ManeuverType.continueInstruction,
        modifier: ManeuverModifier.straight,
        streetName: 'B12',
        l10n: l10n,
      );
      expect(result, l10n.navStraightOn('B12'));
    });

    test('continue nicht straight delegiert an turn', () {
      final result = NavigationInstructionGenerator.generate(
        type: ManeuverType.continueInstruction,
        modifier: ManeuverModifier.left,
        streetName: '',
        l10n: l10n,
      );
      expect(result, l10n.navTurnLeft);
    });

    test('exitRoundabout', () {
      final result = NavigationInstructionGenerator.generate(
        type: ManeuverType.exitRoundabout,
        modifier: ManeuverModifier.none,
        streetName: 'B1',
        l10n: l10n,
      );
      expect(result, l10n.navRoundaboutLeaveOn('B1'));
    });

    test('newName', () {
      final result = NavigationInstructionGenerator.generate(
        type: ManeuverType.newName,
        modifier: ManeuverModifier.none,
        streetName: 'Marktplatz',
        l10n: l10n,
      );
      expect(result, l10n.navContinueOn('Marktplatz'));
    });
  });

  group('NavigationInstructionGenerator.generateShort', () {
    test('turn-Modifier geben kurze Woerter', () {
      expect(
        NavigationInstructionGenerator.generateShort(
          type: ManeuverType.turn,
          modifier: ManeuverModifier.left,
          l10n: l10n,
        ),
        l10n.navLeftShort,
      );
      expect(
        NavigationInstructionGenerator.generateShort(
          type: ManeuverType.turn,
          modifier: ManeuverModifier.right,
          l10n: l10n,
        ),
        l10n.navRightShort,
      );
      expect(
        NavigationInstructionGenerator.generateShort(
          type: ManeuverType.turn,
          modifier: ManeuverModifier.uturn,
          l10n: l10n,
        ),
        l10n.navUturn,
      );
      expect(
        NavigationInstructionGenerator.generateShort(
          type: ManeuverType.turn,
          modifier: ManeuverModifier.straight,
          l10n: l10n,
        ),
        l10n.navStraightShort,
      );
    });

    test('roundabout mit Exit', () {
      expect(
        NavigationInstructionGenerator.generateShort(
          type: ManeuverType.roundabout,
          modifier: ManeuverModifier.none,
          l10n: l10n,
          roundaboutExit: 2,
        ),
        l10n.navExitShort(l10n.navOrdinalSecond),
      );
    });

    test('roundabout ohne Exit', () {
      expect(
        NavigationInstructionGenerator.generateShort(
          type: ManeuverType.roundabout,
          modifier: ManeuverModifier.none,
          l10n: l10n,
        ),
        l10n.navRoundabout,
      );
    });

    test('arrive', () {
      expect(
        NavigationInstructionGenerator.generateShort(
          type: ManeuverType.arrive,
          modifier: ManeuverModifier.none,
          l10n: l10n,
        ),
        l10n.navArrive,
      );
    });

    test('fork links', () {
      expect(
        NavigationInstructionGenerator.generateShort(
          type: ManeuverType.fork,
          modifier: ManeuverModifier.left,
          l10n: l10n,
        ),
        l10n.navKeepLeft,
      );
    });

    test('fork rechts', () {
      expect(
        NavigationInstructionGenerator.generateShort(
          type: ManeuverType.fork,
          modifier: ManeuverModifier.right,
          l10n: l10n,
        ),
        l10n.navKeepRight,
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
        l10n: l10n,
      );
      final instruction = NavigationInstructionGenerator.generate(
        type: ManeuverType.turn,
        modifier: ManeuverModifier.left,
        streetName: '',
        l10n: l10n,
      );
      expect(result, l10n.navNow(instruction));
    });

    test('> 50m sagt In X', () {
      final result = NavigationInstructionGenerator.generateWithDistance(
        type: ManeuverType.turn,
        modifier: ManeuverModifier.right,
        streetName: 'B1',
        distanceMeters: 200,
        l10n: l10n,
      );
      expect(result, contains(l10n.navMeters('200')));
    });

    test('Kilometer-Formatierung bei > 1000m', () {
      final result = NavigationInstructionGenerator.generateWithDistance(
        type: ManeuverType.turn,
        modifier: ManeuverModifier.left,
        streetName: '',
        distanceMeters: 2500,
        l10n: l10n,
      );
      expect(result, contains(l10n.navKilometers('2.5')));
    });

    test('kleine Distanz < 100m wird direkt gerundet', () {
      final result = NavigationInstructionGenerator.generateWithDistance(
        type: ManeuverType.turn,
        modifier: ManeuverModifier.right,
        streetName: '',
        distanceMeters: 75,
        l10n: l10n,
      );
      final instruction = NavigationInstructionGenerator.generate(
        type: ManeuverType.turn,
        modifier: ManeuverModifier.right,
        streetName: '',
        l10n: l10n,
      );
      expect(result, l10n.navInDistance(l10n.navMeters('75'), instruction));
    });

    test('mittlere Distanz wird auf 50m gerundet', () {
      final result = NavigationInstructionGenerator.generateWithDistance(
        type: ManeuverType.turn,
        modifier: ManeuverModifier.right,
        streetName: '',
        distanceMeters: 320,
        l10n: l10n,
      );
      final instruction = NavigationInstructionGenerator.generate(
        type: ManeuverType.turn,
        modifier: ManeuverModifier.right,
        streetName: '',
        l10n: l10n,
      );
      // 320 / 50 = 6.4 → round = 6 → 6*50 = 300
      expect(result, l10n.navInDistance(l10n.navMeters('300'), instruction));
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
    test('Exits 1-8 geben lokalisierte Ordinalzahlen', () {
      final expectedOrdinals = {
        1: l10n.navOrdinalFirst,
        2: l10n.navOrdinalSecond,
        3: l10n.navOrdinalThird,
        4: l10n.navOrdinalFourth,
        5: l10n.navOrdinalFifth,
        6: l10n.navOrdinalSixth,
        7: l10n.navOrdinalSeventh,
        8: l10n.navOrdinalEighth,
      };

      for (final entry in expectedOrdinals.entries) {
        final result = NavigationInstructionGenerator.generate(
          type: ManeuverType.roundabout,
          modifier: ManeuverModifier.none,
          streetName: '',
          l10n: l10n,
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
        l10n: l10n,
        roundaboutExit: 9,
      );
      expect(result, contains('9.'));
    });
  });
}
