import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';
import '../models/trip.dart';

part 'sharing_service.g.dart';

/// Sharing Service für Trip-Export und -Import
class SharingService {
  /// Erstellt einen teilbaren Link für einen Trip
  String generateShareLink(Trip trip) {
    final tripData = _encodeTrip(trip);
    // Base64-kodierte Trip-Daten im URL-Format
    return 'mapab://trip?data=$tripData';
  }

  /// Erstellt einen Deep Link für die App
  String generateDeepLink(Trip trip) {
    final tripData = _encodeTrip(trip);
    return 'https://mapab.app/trip/$tripData';
  }

  /// Kodiert Trip-Daten für Sharing
  String _encodeTrip(Trip trip) {
    final data = {
      'id': trip.id,
      'name': trip.name,
      'type': trip.type.name,
      'route': trip.route != null ? {
        'startLat': trip.route!.start.latitude,
        'startLng': trip.route!.start.longitude,
        'endLat': trip.route!.end.latitude,
        'endLng': trip.route!.end.longitude,
        'startAddr': trip.route!.startAddress,
        'endAddr': trip.route!.endAddress,
      } : null,
      'stops': trip.stops.map((s) => {
        'id': s.poiId,
        'name': s.name,
        'lat': s.latitude,
        'lng': s.longitude,
        'cat': s.categoryId,
        'dur': s.plannedDurationMinutes,
      }).toList(),
      'days': trip.days,
      'startDate': trip.startDate?.toIso8601String(),
      'notes': trip.notes,
    };

    final jsonString = jsonEncode(data);
    final bytes = utf8.encode(jsonString);
    return base64UrlEncode(bytes);
  }

  /// Dekodiert Trip-Daten aus Share-Link
  Trip? decodeTrip(String encodedData) {
    try {
      final bytes = base64Url.decode(encodedData);
      final jsonString = utf8.decode(bytes);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      final stopsData = data['stops'] as List? ?? [];
      final stops = stopsData.map((s) => TripStop(
        poiId: s['id'] ?? '',
        name: s['name'] ?? '',
        latitude: (s['lat'] as num).toDouble(),
        longitude: (s['lng'] as num).toDouble(),
        categoryId: s['cat'] ?? 'attraction',
        routePosition: 0,
        detourKm: 0,
        detourMinutes: 0,
        plannedDurationMinutes: s['dur'] ?? 30,
        day: 1,
        isOvernightStop: false,
      )).toList();

      return Trip(
        id: data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: data['name'] ?? 'Geteilter Trip',
        type: TripType.values.firstWhere(
          (t) => t.name == data['type'],
          orElse: () => TripType.daytrip,
        ),
        route: null, // Route wird beim Öffnen neu berechnet
        stops: stops,
        days: data['days'] ?? 1,
        startDate: data['startDate'] != null
            ? DateTime.tryParse(data['startDate'])
            : null,
        notes: data['notes'],
        weatherCondition: null,
      );
    } catch (e) {
      print('[Sharing] Dekodierung fehlgeschlagen: $e');
      return null;
    }
  }

  /// Teilt Trip via System-Share-Dialog
  Future<void> shareTrip(Trip trip, {String? customMessage}) async {
    final link = generateDeepLink(trip);
    final message = customMessage ??
        '🗺️ Schau dir meinen Trip "${trip.name}" an!\n\n'
        '📍 ${trip.stops.length} Stopps\n'
        '🚗 ${trip.totalDistanceKm.toStringAsFixed(0)} km\n\n'
        '$link';

    await Share.share(message, subject: 'MapAB Trip: ${trip.name}');
  }

  /// Kopiert Link in Zwischenablage
  Future<void> copyLinkToClipboard(Trip trip) async {
    final link = generateDeepLink(trip);
    await Clipboard.setData(ClipboardData(text: link));
  }

  /// Erstellt teilbaren Text für den Trip
  String generateShareText(Trip trip) {
    final buffer = StringBuffer();
    buffer.writeln('🗺️ ${trip.name}');
    buffer.writeln('');

    if (trip.route != null) {
      buffer.writeln('📍 Start: ${trip.route!.startAddress ?? "Unbekannt"}');
      buffer.writeln('🏁 Ziel: ${trip.route!.endAddress ?? "Unbekannt"}');
      buffer.writeln('');
    }

    buffer.writeln('📊 ${trip.stops.length} Stopps | ${trip.totalDistanceKm.toStringAsFixed(0)} km');
    buffer.writeln('');

    buffer.writeln('🛣️ Route:');
    for (int i = 0; i < trip.stops.length; i++) {
      final stop = trip.stops[i];
      final emoji = _getCategoryEmoji(stop.categoryId);
      buffer.writeln('${i + 1}. $emoji ${stop.name}');
    }

    buffer.writeln('');
    buffer.writeln('Erstellt mit MapAB 🚗');

    return buffer.toString();
  }

  /// Generiert QR-Code-Daten für den Trip
  String generateQRData(Trip trip) {
    // Komprimierte Version für QR-Codes
    final data = {
      'n': trip.name,
      's': trip.stops.map((s) => {
        'n': s.name,
        'la': s.latitude,
        'lo': s.longitude,
      }).toList(),
    };
    final jsonString = jsonEncode(data);
    return base64UrlEncode(utf8.encode(jsonString));
  }

  String _getCategoryEmoji(String categoryId) {
    switch (categoryId) {
      case 'castle': return '🏰';
      case 'nature': return '🌲';
      case 'museum': return '🏛️';
      case 'viewpoint': return '🏔️';
      case 'lake': return '🏞️';
      case 'coast': return '🏖️';
      case 'park': return '🌳';
      case 'city': return '🏙️';
      case 'activity': return '🎿';
      case 'hotel': return '🏨';
      case 'restaurant': return '🍽️';
      case 'unesco': return '🌍';
      case 'church': return '⛪';
      case 'monument': return '🗿';
      default: return '📍';
    }
  }
}

/// Sharing Service Provider
@riverpod
SharingService sharingService(SharingServiceRef ref) {
  return SharingService();
}
