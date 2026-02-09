import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

/// Daten fuer einen Erinnerungspunkt aus dem Reisetagebuch
class MemoryPointData {
  final String entryId;
  final String tripId;
  final String tripName;
  final LatLng location;
  final String? poiName;
  final String? imagePath;
  final String? note;
  final DateTime createdAt;

  const MemoryPointData({
    required this.entryId,
    required this.tripId,
    required this.tripName,
    required this.location,
    this.poiName,
    this.imagePath,
    this.note,
    required this.createdAt,
  });
}

/// Provider fuer den aktiven Erinnerungspunkt auf der Karte.
/// Wird gesetzt wenn ein Journal-Eintrag "Auf Karte anzeigen" gedrueckt wird.
final memoryPointProvider = StateProvider<MemoryPointData?>((ref) => null);
