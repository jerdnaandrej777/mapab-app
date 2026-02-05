import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../l10n/l10n.dart';

// Re-exportiere haeufig genutzte Geolocator-Typen,
// damit Konsumenten nur location_helper.dart importieren muessen.
export 'package:geolocator/geolocator.dart'
    show LocationAccuracy, LocationPermission;

/// Ergebnis einer GPS-Positions-Abfrage
class LocationResult {
  final LatLng? position;
  final String? error;
  final String? message;

  const LocationResult._({this.position, this.error, this.message});

  factory LocationResult.success(LatLng pos) =>
      LocationResult._(position: pos);

  factory LocationResult.failure(String error, String message) =>
      LocationResult._(error: error, message: message);

  bool get isSuccess => position != null;
  bool get isGpsDisabled => error == 'gps_disabled';
  bool get isPermissionDenied =>
      error == 'permission_denied' || error == 'permission_denied_forever';
}

/// Zentraler Helper fuer GPS-Abfragen.
/// Konsolidiert die duplizierte GPS-Logik aus 7+ Dateien.
class LocationHelper {
  LocationHelper._();

  /// Prueft ob GPS verfuegbar ist und holt die aktuelle Position.
  /// Fordert Berechtigung an falls noetig.
  static Future<LocationResult> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration timeLimit = const Duration(seconds: 10),
  }) async {
    try {
      // GPS-Service pruefen
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[GPS] Ortungsdienste deaktiviert');
        return LocationResult.failure(
          'gps_disabled',
          'GPS ist deaktiviert. Bitte aktiviere die Ortungsdienste.',
        );
      }

      // Berechtigung pruefen und ggf. anfordern
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('[GPS] Berechtigung verweigert');
          return LocationResult.failure(
            'permission_denied',
            'GPS-Berechtigung wurde verweigert.',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('[GPS] Berechtigung dauerhaft verweigert');
        return LocationResult.failure(
          'permission_denied_forever',
          'GPS-Berechtigung wurde dauerhaft verweigert. '
              'Bitte in den Einstellungen aktivieren.',
        );
      }

      // Position abrufen
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: accuracy,
        timeLimit: timeLimit,
      );

      final latLng = LatLng(position.latitude, position.longitude);
      debugPrint('[GPS] Position: ${position.latitude}, ${position.longitude}');
      return LocationResult.success(latLng);
    } catch (e) {
      debugPrint('[GPS] Fehler: $e');
      return LocationResult.failure(
        'gps_error',
        'GPS-Position konnte nicht ermittelt werden: $e',
      );
    }
  }

  /// Prueft nur ob GPS-Service aktiviert ist (ohne Position abzufragen).
  static Future<bool> isServiceEnabled() async {
    return Geolocator.isLocationServiceEnabled();
  }

  /// Oeffnet die Geraete-GPS-Einstellungen.
  static Future<bool> openSettings() async {
    return Geolocator.openLocationSettings();
  }

  /// Oeffnet die App-Einstellungen (fuer dauerhaft verweigerte Berechtigungen).
  static Future<bool> openAppSettings() async {
    return Geolocator.openAppSettings();
  }

  /// Prueft Berechtigungen und fordert sie ggf. an.
  /// Gibt die aktuelle LocationPermission zurueck.
  static Future<LocationPermission> checkAndRequestPermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission;
  }

  /// Zeigt einen Dialog wenn GPS deaktiviert ist.
  /// Nutzt lokalisierte Strings aus ARB-Dateien.
  /// Gibt true zurueck wenn der Benutzer "Einstellungen oeffnen" waehlt.
  static Future<bool> showGpsDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(context.l10n.gpsDisabledTitle),
            content: Text(context.l10n.gpsDisabledMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(context.l10n.no),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(context.l10n.openSettings),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// Zeigt GPS-Dialog und oeffnet Einstellungen wenn bestaetigt.
  /// Convenience-Methode die showGpsDialog + openSettings kombiniert.
  static Future<void> showGpsDialogAndOpenSettings(BuildContext context) async {
    final shouldOpen = await showGpsDialog(context);
    if (shouldOpen) {
      await openSettings();
    }
  }
}
