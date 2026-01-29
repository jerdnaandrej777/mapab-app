import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

/// Provider für den globalen MapController
/// Ermöglicht Zugriff auf die Karte von anderen Widgets/Screens
final mapControllerProvider = StateProvider<MapController?>((ref) => null);

/// Provider für die aktuelle Kartenposition
final currentMapPositionProvider = StateProvider<LatLng?>((ref) => null);

/// Provider für die aktuelle Zoom-Stufe
final currentMapZoomProvider = StateProvider<double>((ref) => 6.0);

/// Provider der angibt, ob beim nächsten MapScreen-Anzeige auf die Route gezoomt werden soll
/// Wird auf true gesetzt nach Route-Berechnung und bei Tab-Wechsel zum Trip-Screen
final shouldFitToRouteProvider = StateProvider<bool>((ref) => false);

/// Extension für einfache Karten-Operationen
extension MapControllerExtension on MapController {
  /// Bewegt die Karte zu einer Position mit Animation
  void animatedMove(LatLng point, double zoom) {
    move(point, zoom);
  }

  /// Zentriert die Karte auf eine Position
  void centerOn(LatLng point) {
    move(point, camera.zoom);
  }

  /// Zoom In
  void zoomIn() {
    final newZoom = (camera.zoom + 1).clamp(3.0, 18.0);
    move(camera.center, newZoom);
  }

  /// Zoom Out
  void zoomOut() {
    final newZoom = (camera.zoom - 1).clamp(3.0, 18.0);
    move(camera.center, newZoom);
  }
}
