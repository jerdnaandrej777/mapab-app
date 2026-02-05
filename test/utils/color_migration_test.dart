import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests zur Verifizierung der withOpacity → withValues(alpha:) Migration.
/// Stellt sicher, dass die API-Migration identische Ergebnisse liefert.
void main() {
  group('Color.withValues(alpha:) Migration', () {
    test('withValues(alpha:) erzeugt gleichen Alpha-Wert', () {
      final color = Colors.blue;
      final result = color.withValues(alpha: 0.5);

      // Alpha sollte ~0.5 sein (0.0-1.0 Bereich)
      expect(result.a, closeTo(0.5, 0.01));
    });

    test('withValues(alpha: 0) ist vollstaendig transparent', () {
      final result = Colors.red.withValues(alpha: 0.0);
      expect(result.a, closeTo(0.0, 0.01));
    });

    test('withValues(alpha: 1) ist vollstaendig opak', () {
      final result = Colors.red.withValues(alpha: 1.0);
      expect(result.a, closeTo(1.0, 0.01));
    });

    test('RGB-Werte bleiben bei withValues(alpha:) erhalten', () {
      final original = const Color.fromARGB(255, 100, 150, 200);
      final result = original.withValues(alpha: 0.5);

      // RGB Komponenten (0.0-1.0) bleiben erhalten
      expect(result.r, closeTo(original.r, 0.01));
      expect(result.g, closeTo(original.g, 0.01));
      expect(result.b, closeTo(original.b, 0.01));
    });

    test('typische Opacity-Werte aus dem Projekt funktionieren', () {
      // Die haeufigsten Opacity-Werte in der Codebase
      final opacities = [0.05, 0.1, 0.15, 0.2, 0.3, 0.5, 0.7, 0.8, 0.9];

      for (final opacity in opacities) {
        final result = Colors.black.withValues(alpha: opacity);
        expect(result.a, closeTo(opacity, 0.01),
            reason: 'Alpha $opacity sollte erhalten bleiben');
      }
    });

    test('colorScheme.scrim mit withValues funktioniert fuer Overlays', () {
      final colorScheme = ColorScheme.fromSeed(seedColor: Colors.blue);
      final overlay = colorScheme.scrim.withValues(alpha: 0.54);

      expect(overlay.a, closeTo(0.54, 0.01));
    });
  });

  group('Theme-basierte Farben', () {
    test('tertiaryContainer existiert im ColorScheme', () {
      final scheme = ColorScheme.fromSeed(seedColor: Colors.blue);
      expect(scheme.tertiaryContainer, isNotNull);
      expect(scheme.onTertiaryContainer, isNotNull);
    });

    test('onInverseSurface existiert im ColorScheme', () {
      final scheme = ColorScheme.fromSeed(seedColor: Colors.blue);
      expect(scheme.onInverseSurface, isNotNull);
    });

    test('scrim existiert im ColorScheme', () {
      final scheme = ColorScheme.fromSeed(seedColor: Colors.blue);
      expect(scheme.scrim, isNotNull);
    });

    test('Dark-Mode ColorScheme hat alle benoetigten Farben', () {
      final scheme = ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
      );
      expect(scheme.tertiaryContainer, isNotNull);
      expect(scheme.onTertiaryContainer, isNotNull);
      expect(scheme.onInverseSurface, isNotNull);
      expect(scheme.scrim, isNotNull);
    });
  });
}
