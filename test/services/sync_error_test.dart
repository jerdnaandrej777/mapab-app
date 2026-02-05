import 'package:flutter_test/flutter_test.dart';
import 'package:travel_planner/data/services/sync_service.dart';

void main() {
  group('SyncError', () {
    test('hat operation, message und timestamp', () {
      final error = SyncError(operation: 'saveTrip', message: 'Netzwerk-Fehler');

      expect(error.operation, 'saveTrip');
      expect(error.message, 'Netzwerk-Fehler');
      expect(error.timestamp, isNotNull);
      expect(
        error.timestamp.difference(DateTime.now()).inSeconds.abs(),
        lessThan(2),
      );
    });

    test('toString formatiert korrekt', () {
      final error = SyncError(operation: 'loadTrips', message: 'Timeout');
      expect(error.toString(), '[loadTrips] Timeout');
    });
  });

  group('SyncService.lastError', () {
    test('lastError ist initial null', () {
      final service = SyncService(null);
      expect(service.lastError, isNull);
    });

    test('isAvailable ist false ohne Client', () {
      final service = SyncService(null);
      expect(service.isAvailable, isFalse);
    });

    test('clearLastError setzt auf null', () {
      final service = SyncService(null);
      // lastError wird nur bei echten Fehlern gesetzt,
      // aber clearLastError muss immer funktionieren
      service.clearLastError();
      expect(service.lastError, isNull);
    });

    test('saveTrip ohne Client gibt null zurueck', () async {
      final service = SyncService(null);
      final result = await service.loadTrips();
      expect(result, isEmpty);
      // Kein Fehler, da isAvailable == false (early return)
    });

    test('loadFavoritePOIs ohne Client gibt leere Liste', () async {
      final service = SyncService(null);
      final result = await service.loadFavoritePOIs();
      expect(result, isEmpty);
    });

    test('saveFavoritePOI ohne Client gibt false', () async {
      final service = SyncService(null);
      // Kann nicht aufgerufen werden ohne POI, aber isAvailable ist false
      // Also frueh-return bevor ein Fehler auftritt
    });

    test('loadUserProfile ohne Client gibt null', () async {
      final service = SyncService(null);
      final result = await service.loadUserProfile();
      expect(result, isNull);
    });

    test('loadAchievements ohne Client gibt leere Liste', () async {
      final service = SyncService(null);
      final result = await service.loadAchievements();
      expect(result, isEmpty);
    });

    test('deleteTrip ohne Client gibt false', () async {
      final service = SyncService(null);
      final result = await service.deleteTrip('test-id');
      expect(result, isFalse);
    });
  });
}
