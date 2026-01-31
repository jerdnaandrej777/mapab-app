import 'package:flutter_test/flutter_test.dart';
import 'package:travel_planner/data/models/poi.dart';

void main() {
  group('POI Model', () {
    POI createPOI({
      String id = 'test-1',
      String name = 'Test POI',
      double latitude = 48.1351,
      double longitude = 11.5820,
      String categoryId = 'castle',
      int score = 50,
      String? imageUrl,
      String? description,
      bool isCurated = false,
      bool hasWikipedia = false,
      List<String> tags = const [],
      int? foundedYear,
      double? detourKm,
    }) {
      return POI(
        id: id,
        name: name,
        latitude: latitude,
        longitude: longitude,
        categoryId: categoryId,
        score: score,
        imageUrl: imageUrl,
        description: description,
        isCurated: isCurated,
        hasWikipedia: hasWikipedia,
        tags: tags,
        foundedYear: foundedYear,
        detourKm: detourKm,
      );
    }

    test('location gibt korrektes LatLng zurück', () {
      final poi = createPOI(latitude: 48.1351, longitude: 11.5820);
      expect(poi.location.latitude, 48.1351);
      expect(poi.location.longitude, 11.5820);
    });

    test('categoryIcon gibt Fallback-Icon für unbekannte Kategorie', () {
      final poi = createPOI(categoryId: 'unknown_category');
      expect(poi.categoryIcon, '📍');
    });

    test('isUnesco erkennt UNESCO-Tag', () {
      final unescoPoI = createPOI(tags: ['unesco']);
      final normalPOI = createPOI(tags: ['historic']);

      expect(unescoPoI.isUnesco, isTrue);
      expect(normalPOI.isUnesco, isFalse);
    });

    test('isHistoric erkennt alte Gründungsjahre', () {
      final historicPOI = createPOI(foundedYear: 1200);
      final modernPOI = createPOI(foundedYear: 2020);
      final taggedPOI = createPOI(tags: ['historic']);
      final normalPOI = createPOI();

      expect(historicPOI.isHistoric, isTrue);
      expect(modernPOI.isHistoric, isFalse);
      expect(taggedPOI.isHistoric, isTrue);
      expect(normalPOI.isHistoric, isFalse);
    });

    test('isSecret erkennt Geheimtipps', () {
      final secretPOI = createPOI(
        score: 50,
        isCurated: false,
        hasWikipedia: false,
      );
      final taggedSecret = createPOI(tags: ['secret']);
      final curatedPOI = createPOI(
        score: 50,
        isCurated: true,
        hasWikipedia: false,
      );

      expect(secretPOI.isSecret, isTrue);
      expect(taggedSecret.isSecret, isTrue);
      expect(curatedPOI.isSecret, isFalse);
    });

    test('shortDescription kürzt auf 100 Zeichen', () {
      final longDesc = 'A' * 200;
      final poi = createPOI(description: longDesc);
      expect(poi.shortDescription.length, 100);
      expect(poi.shortDescription.endsWith('...'), isTrue);
    });

    test('shortDescription gibt vollständige kurze Beschreibung', () {
      final poi = createPOI(description: 'Kurze Beschreibung');
      expect(poi.shortDescription, 'Kurze Beschreibung');
    });

    test('shortDescription bevorzugt wikidataDescription', () {
      final poi = POI(
        id: 'test',
        name: 'Test',
        latitude: 0,
        longitude: 0,
        categoryId: 'castle',
        description: 'Normal',
        wikidataDescription: 'Wikidata',
      );
      expect(poi.shortDescription, 'Wikidata');
    });

    test('hasVerifiedContact prüft Wikidata-Daten', () {
      final withContact = POI(
        id: 'test',
        name: 'Test',
        latitude: 0,
        longitude: 0,
        categoryId: 'castle',
        hasWikidataData: true,
        phone: '+49123456',
      );
      final withoutData = POI(
        id: 'test',
        name: 'Test',
        latitude: 0,
        longitude: 0,
        categoryId: 'castle',
        hasWikidataData: false,
        phone: '+49123456',
      );

      expect(withContact.hasVerifiedContact, isTrue);
      expect(withoutData.hasVerifiedContact, isFalse);
    });
  });

  group('POI List Extensions', () {
    final pois = [
      POI(
        id: '1',
        name: 'Castle',
        latitude: 0,
        longitude: 0,
        categoryId: 'castle',
        score: 80,
        detourKm: 5,
      ),
      POI(
        id: '2',
        name: 'Museum',
        latitude: 0,
        longitude: 0,
        categoryId: 'museum',
        score: 60,
        detourKm: 15,
      ),
      POI(
        id: '3',
        name: 'Park',
        latitude: 0,
        longitude: 0,
        categoryId: 'park',
        score: 40,
        detourKm: 50,
      ),
    ];

    test('filterByMaxDetour filtert korrekt', () {
      final filtered = pois.filterByMaxDetour(10);
      expect(filtered.length, 1);
      expect(filtered.first.id, '1');
    });

    test('filterByMaxDetour inkludiert POIs ohne detourKm', () {
      final withNull = [
        ...pois,
        POI(
          id: '4',
          name: 'NoDetour',
          latitude: 0,
          longitude: 0,
          categoryId: 'nature',
        ),
      ];
      final filtered = withNull.filterByMaxDetour(10);
      expect(filtered.length, 2);
    });

    test('sortByEffectiveScore sortiert absteigend', () {
      final sorted = pois.sortByEffectiveScore();
      expect(sorted.first.score, 80);
      expect(sorted.last.score, 40);
    });

    test('sortByDetour sortiert aufsteigend', () {
      final sorted = pois.sortByDetour();
      expect(sorted.first.detourKm, 5);
      expect(sorted.last.detourKm, 50);
    });
  });
}
