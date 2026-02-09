import 'package:flutter_test/flutter_test.dart';
import 'package:travel_planner/data/models/journal_entry.dart';

void main() {
  group('TripJournal grouping', () {
    TripJournal buildJournal() {
      return TripJournal(
        tripId: 'trip-1',
        tripName: 'Test Trip',
        startDate: DateTime(2025, 1, 1),
        entries: [
          JournalEntry(
            id: 'e1',
            tripId: 'trip-1',
            createdAt: DateTime(2025, 12, 10, 8, 30),
            note: 'Dec',
          ),
          JournalEntry(
            id: 'e2',
            tripId: 'trip-1',
            createdAt: DateTime(2025, 12, 1, 14, 0),
            note: 'Dec older',
          ),
          JournalEntry(
            id: 'e3',
            tripId: 'trip-1',
            createdAt: DateTime(2025, 11, 20, 9, 15),
            note: 'Nov',
          ),
          JournalEntry(
            id: 'e4',
            tripId: 'trip-1',
            createdAt: DateTime(2024, 5, 1, 7, 0),
            note: '2024',
          ),
        ],
      );
    }

    test('entriesByMonth groups entries and sorts each month descending', () {
      final journal = buildJournal();
      final byMonth = journal.entriesByMonth;

      expect(byMonth.length, 3);

      final december = DateTime(2025, 12);
      final decemberEntries = byMonth[december];
      expect(decemberEntries, isNotNull);
      expect(decemberEntries!.length, 2);
      expect(decemberEntries.first.id, 'e1');
      expect(decemberEntries.last.id, 'e2');
    });

    test('entriesByYear groups entries and sorts each year descending', () {
      final journal = buildJournal();
      final byYear = journal.entriesByYear;

      expect(byYear.length, 2);
      expect(byYear[2025]!.map((e) => e.id).toList(), ['e1', 'e2', 'e3']);
      expect(byYear[2024]!.map((e) => e.id).toList(), ['e4']);
    });

    test('monthsWithEntries and yearsWithEntries are returned descending', () {
      final journal = buildJournal();

      expect(
        journal.monthsWithEntries,
        [DateTime(2025, 12), DateTime(2025, 11), DateTime(2024, 5)],
      );
      expect(journal.yearsWithEntries, [2025, 2024]);
    });
  });
}
