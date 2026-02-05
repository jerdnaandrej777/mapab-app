import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_planner/shared/widgets/app_snackbar.dart';

void main() {
  group('AppSnackbar', () {
    Widget createTestApp({required Widget child}) {
      return MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: Scaffold(body: child),
      );
    }

    testWidgets('showError zeigt Fehler-Snackbar', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => AppSnackbar.showError(context, 'Test-Fehler'),
            child: const Text('Error'),
          ),
        ),
      ));

      await tester.tap(find.text('Error'));
      await tester.pump();

      expect(find.text('Test-Fehler'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('showSuccess zeigt Erfolgs-Snackbar', (tester) async {
      await tester.pumpWidget(createTestApp(
        child: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => AppSnackbar.showSuccess(context, 'Gespeichert'),
            child: const Text('Success'),
          ),
        ),
      ));

      await tester.tap(find.text('Success'));
      await tester.pump();

      expect(find.text('Gespeichert'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('showWarning zeigt Warn-Snackbar mit Theme-Farben',
        (tester) async {
      await tester.pumpWidget(createTestApp(
        child: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () =>
                AppSnackbar.showWarning(context, 'Warnung: Test'),
            child: const Text('Warn'),
          ),
        ),
      ));

      await tester.tap(find.text('Warn'));
      await tester.pump();

      expect(find.text('Warnung: Test'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber), findsOneWidget);

      // Verifiziere: Keine hart-codierten Colors.black87 mehr
      // (Theme-Farben werden stattdessen verwendet)
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      final colorScheme = ColorScheme.fromSeed(seedColor: Colors.blue);
      expect(snackBar.backgroundColor, colorScheme.tertiaryContainer);
    });

    testWidgets('showWarning benutzt tertiaryContainer statt amber',
        (tester) async {
      final customScheme = ColorScheme.fromSeed(
        seedColor: Colors.green,
        brightness: Brightness.dark,
      );

      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(colorScheme: customScheme),
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () =>
                  AppSnackbar.showWarning(context, 'Dark-Mode-Warnung'),
              child: const Text('Warn'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Warn'));
      await tester.pump();

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, customScheme.tertiaryContainer);
    });

    testWidgets('showError mit unmounted context crasht nicht',
        (tester) async {
      late BuildContext savedContext;

      await tester.pumpWidget(createTestApp(
        child: Builder(
          builder: (context) {
            savedContext = context;
            return const SizedBox();
          },
        ),
      ));

      // Neues Widget einsetzen (altes unmounted)
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));

      // Sollte nicht crashen
      AppSnackbar.showError(savedContext, 'Ignored');
    });
  });
}
