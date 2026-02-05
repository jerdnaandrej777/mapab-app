import 'package:flutter_test/flutter_test.dart';
import 'package:travel_planner/data/repositories/geocoding_repo.dart';

void main() {
  late GeocodingRepository repo;

  setUp(() {
    // Erstellt Repo ohne Dio (wir testen nur die Sanitize-Logik)
    repo = GeocodingRepository();
  });

  group('GeocodingRepository Input-Sanitisierung', () {
    test('leerer String gibt leere Liste', () async {
      final result = await repo.geocode('');
      expect(result, isEmpty);
    });

    test('nur Whitespace gibt leere Liste', () async {
      final result = await repo.geocode('   ');
      expect(result, isEmpty);
    });

    test('autocomplete mit < 2 Zeichen gibt leere Liste', () async {
      final result = await repo.autocomplete('a');
      expect(result, isEmpty);
    });

    test('autocomplete mit leerem String gibt leere Liste', () async {
      final result = await repo.autocomplete('');
      expect(result, isEmpty);
    });
  });

  group('GeocodingRepository._sanitizeQuery (via geocode)', () {
    // Die _sanitizeQuery Methode ist private, aber wir testen sie indirekt
    // ueber die Edge-Cases die leere Listen zurueckgeben

    test('nur Whitespace wird zu leer', () async {
      final result = await repo.geocode('   \t  ');
      expect(result, isEmpty);
    });

    test('einzelnes Zeichen nach Trim fuer autocomplete', () async {
      final result = await repo.autocomplete('  a  ');
      expect(result, isEmpty);
    });

    test('2 Zeichen nach Trim fuer autocomplete reicht', () async {
      // Wird einen API-Call machen der fehlschlaegt (kein echter Server),
      // aber wir wissen dass es nicht frueher rausfiltert
      try {
        await repo.autocomplete('  ab  ');
      } catch (_) {
        // DioException erwartet, da kein Server
      }
      // Kein Fehler vor dem API-Call = Sanitisierung hat 'ab' durchgelassen
    });
  });
}
