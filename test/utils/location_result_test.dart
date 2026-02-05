import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:travel_planner/core/utils/location_helper.dart';

void main() {
  group('LocationResult.success', () {
    test('hat position und kein error', () {
      final result = LocationResult.success(const LatLng(48.1351, 11.5820));

      expect(result.position, isNotNull);
      expect(result.position!.latitude, 48.1351);
      expect(result.position!.longitude, 11.5820);
      expect(result.error, isNull);
      expect(result.message, isNull);
    });

    test('isSuccess ist true', () {
      final result = LocationResult.success(const LatLng(48.0, 11.0));
      expect(result.isSuccess, isTrue);
    });

    test('isGpsDisabled ist false', () {
      final result = LocationResult.success(const LatLng(48.0, 11.0));
      expect(result.isGpsDisabled, isFalse);
    });

    test('isPermissionDenied ist false', () {
      final result = LocationResult.success(const LatLng(48.0, 11.0));
      expect(result.isPermissionDenied, isFalse);
    });
  });

  group('LocationResult.failure', () {
    test('hat error und message aber keine position', () {
      final result = LocationResult.failure('gps_error', 'Test-Fehler');

      expect(result.position, isNull);
      expect(result.error, 'gps_error');
      expect(result.message, 'Test-Fehler');
    });

    test('isSuccess ist false', () {
      final result = LocationResult.failure('test', 'msg');
      expect(result.isSuccess, isFalse);
    });

    test('isGpsDisabled bei gps_disabled error', () {
      final result = LocationResult.failure('gps_disabled', 'GPS aus');
      expect(result.isGpsDisabled, isTrue);
    });

    test('isGpsDisabled false bei anderem error', () {
      final result = LocationResult.failure('gps_error', 'Fehler');
      expect(result.isGpsDisabled, isFalse);
    });

    test('isPermissionDenied bei permission_denied', () {
      final result =
          LocationResult.failure('permission_denied', 'Verweigert');
      expect(result.isPermissionDenied, isTrue);
    });

    test('isPermissionDenied bei permission_denied_forever', () {
      final result = LocationResult.failure(
          'permission_denied_forever', 'Dauerhaft verweigert');
      expect(result.isPermissionDenied, isTrue);
    });

    test('isPermissionDenied false bei anderem error', () {
      final result = LocationResult.failure('gps_error', 'Fehler');
      expect(result.isPermissionDenied, isFalse);
    });
  });
}
