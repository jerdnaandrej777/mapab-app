import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/categories.dart';
import '../models/route.dart';
import '../models/trip.dart';

part 'sharing_service.g.dart';

/// Sharing Service fuer Trip-Export und -Import
class SharingService {
  /// Erstellt einen teilbaren Link fuer einen Trip
  String generateShareLink(Trip trip) {
    final tripData = _encodeTrip(trip);
    return 'mapab://trip?data=$tripData';
  }

  /// Erstellt einen Deep Link fuer die App
  String generateDeepLink(Trip trip) {
    final tripData = _encodeTrip(trip);
    return 'https://mapab.app/trip/$tripData';
  }

  /// Kodiert Trip-Daten fuer Sharing
  String _encodeTrip(Trip trip) {
    final data = {
      'v': 2,
      'id': trip.id,
      'name': trip.name,
      'type': trip.type.name,
      'route': {
        'startLat': trip.route.start.latitude,
        'startLng': trip.route.start.longitude,
        'endLat': trip.route.end.latitude,
        'endLng': trip.route.end.longitude,
        'startAddress': trip.route.startAddress,
        'endAddress': trip.route.endAddress,
      },
      'stops': trip.stops
          .map((s) => {
                'id': s.poiId,
                'name': s.name,
                'lat': s.latitude,
                'lng': s.longitude,
                'cat': s.categoryId,
                'dur': s.plannedDurationMinutes,
              })
          .toList(),
      'days': trip.days,
      'startDate': trip.startDate?.toIso8601String(),
      'notes': trip.notes,
    };

    final jsonString = jsonEncode(data);
    final bytes = utf8.encode(jsonString);
    return base64UrlEncode(bytes);
  }

  /// Dekodiert Trip-Daten aus Share-Link.
  /// Unterstuetzt sowohl aktuelles Schema (v2) als auch Legacy-Keys
  /// `startAddr`/`endAddr` fuer Rueckwaertskompatibilitaet.
  Trip? decodeTrip(String encodedData) {
    try {
      final bytes = base64Url.decode(encodedData);
      final jsonString = utf8.decode(bytes);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      final routeData = data['route'] is Map<String, dynamic>
          ? data['route'] as Map<String, dynamic>
          : <String, dynamic>{};

      final stopsData = data['stops'] as List? ?? [];
      final stops = stopsData
          .whereType<Map>()
          .map((s) => TripStop(
                poiId: _readString(s['id']) ?? '',
                name: _readString(s['name']) ?? '',
                latitude: (_readDouble(s['lat']) ?? 0),
                longitude: (_readDouble(s['lng']) ?? 0),
                categoryId: _readString(s['cat']) ?? 'attraction',
                routePosition: 0,
                detourKm: 0,
                detourMinutes: 0,
                plannedDurationMinutes: (s['dur'] as int?) ?? 30,
                day: 1,
                isOvernightStop: false,
              ))
          .toList();

      final startLat = _readDouble(routeData['startLat']) ??
          (stops.isNotEmpty ? stops.first.latitude : 48.1351);
      final startLng = _readDouble(routeData['startLng']) ??
          (stops.isNotEmpty ? stops.first.longitude : 11.5820);
      final endLat = _readDouble(routeData['endLat']) ??
          (stops.isNotEmpty ? stops.last.latitude : 48.1351);
      final endLng = _readDouble(routeData['endLng']) ??
          (stops.isNotEmpty ? stops.last.longitude : 11.5820);

      final startAddress = _readString(routeData['startAddress']) ??
          _readString(routeData['startAddr']) ??
          _readString(data['startAddress']) ??
          _readString(data['startAddr']) ??
          'Start';
      final endAddress = _readString(routeData['endAddress']) ??
          _readString(routeData['endAddr']) ??
          _readString(data['endAddress']) ??
          _readString(data['endAddr']) ??
          'Ziel';

      final placeholderRoute = AppRoute(
        start: LatLng(startLat, startLng),
        end: LatLng(endLat, endLng),
        startAddress: startAddress,
        endAddress: endAddress,
        coordinates: const [],
        distanceKm: 0,
        durationMinutes: 0,
      );

      return Trip(
        id: _readString(data['id']) ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        name: _readString(data['name']) ?? 'Geteilter Trip',
        type: TripType.values.firstWhere(
          (t) => t.name == data['type'],
          orElse: () => TripType.daytrip,
        ),
        route: placeholderRoute,
        stops: stops,
        days: data['days'] as int? ?? 1,
        startDate: data['startDate'] != null
            ? DateTime.tryParse(data['startDate'])
            : null,
        notes: _readString(data['notes']),
        weatherCondition: null,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('[Sharing] Dekodierung fehlgeschlagen: $e');
      return null;
    }
  }

  /// Teilt Trip via System-Share-Dialog
  Future<void> shareTrip(Trip trip, {String? customMessage}) async {
    final link = generateDeepLink(trip);
    final message = customMessage ??
        '\u{1F5FA}\u{FE0F} Schau dir meinen Trip "${trip.name}" an!\n\n'
            '\u{1F4CD} ${trip.stops.length} Stopps\n'
            '\u{1F697} ${trip.totalDistanceKm.toStringAsFixed(0)} km\n\n'
            '$link';

    await Share.share(message, subject: 'MapAB Trip: ${trip.name}');
  }

  /// Kopiert Link in Zwischenablage
  Future<void> copyLinkToClipboard(Trip trip) async {
    final link = generateDeepLink(trip);
    await Clipboard.setData(ClipboardData(text: link));
  }

  /// Erstellt teilbaren Text fuer den Trip
  String generateShareText(Trip trip) {
    final buffer = StringBuffer();
    buffer.writeln('\u{1F5FA}\u{FE0F} ${trip.name}');
    buffer.writeln('');
    buffer.writeln('\u{1F4CD} Start: ${trip.route.startAddress}');
    buffer.writeln('\u{1F3C1} Ziel: ${trip.route.endAddress}');
    buffer.writeln('');

    buffer.writeln(
      '\u{1F4CA} ${trip.stops.length} Stopps | '
      '${trip.totalDistanceKm.toStringAsFixed(0)} km',
    );
    buffer.writeln('');

    buffer.writeln('\u{1F6E3}\u{FE0F} Route:');
    for (int i = 0; i < trip.stops.length; i++) {
      final stop = trip.stops[i];
      final emoji = _getCategoryEmoji(stop.categoryId);
      buffer.writeln('${i + 1}. $emoji ${stop.name}');
    }

    buffer.writeln('');
    buffer.writeln('Erstellt mit MapAB \u{1F697}');

    return buffer.toString();
  }

  /// Generiert QR-Code-Daten fuer den Trip
  String generateQRData(Trip trip) {
    final data = {
      'n': trip.name,
      's': trip.stops
          .map((s) => {
                'n': s.name,
                'la': s.latitude,
                'lo': s.longitude,
              })
          .toList(),
    };
    final jsonString = jsonEncode(data);
    return base64UrlEncode(utf8.encode(jsonString));
  }

  String _getCategoryEmoji(String categoryId) {
    switch (categoryId) {
      case 'castle':
        return '\u{1F3F0}';
      case 'nature':
        return '\u{1F332}';
      case 'museum':
        return '\u{1F3DB}\u{FE0F}';
      case 'viewpoint':
        return '\u{1F3D4}\u{FE0F}';
      case 'lake':
        return '\u{1F3DE}\u{FE0F}';
      case 'coast':
        return '\u{1F3D6}\u{FE0F}';
      case 'park':
        return '\u{1F333}';
      case 'city':
        return '\u{1F3D9}\u{FE0F}';
      case 'activity':
        return '\u{1F3BF}';
      case 'hotel':
        return '\u{1F3E8}';
      case 'restaurant':
        return '\u{1F37D}\u{FE0F}';
      case 'unesco':
        return '\u{1F30D}';
      case 'church':
        return '\u{26EA}';
      case 'monument':
        return '\u{1F5FF}';
      default:
        return '\u{1F4CD}';
    }
  }

  double? _readDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return null;
  }

  String? _readString(dynamic value) {
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    return null;
  }
}

/// Oeffentlicher Link fuer geteilte Galerie-Trips.
String generatePublicTripLink(String tripId) {
  return 'https://mapab.app/gallery/$tripId';
}

/// Extrahiert eine Public-Trip-ID aus MapAB-Links.
///
/// Unterstuetzt:
/// - `https://mapab.app/gallery/{tripId}` (aktuell)
/// - `https://mapab.app/trip/{tripId}` (Legacy, falls kein Base64-Trip-Payload)
String? extractPublicTripIdFromLink(String link) {
  final uri = Uri.tryParse(link);
  if (uri == null || uri.host.toLowerCase() != 'mapab.app') {
    return null;
  }

  final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  if (segments.length != 2) {
    return null;
  }

  final prefix = segments[0].toLowerCase();
  final token = segments[1].trim();
  if (token.isEmpty) return null;

  if (prefix == 'gallery') {
    return token;
  }

  if (prefix == 'trip') {
    // Legacy-Pfad ist ambivalent: private Base64-Payload oder public tripId.
    if (_looksLikeEncodedTripPayload(token)) {
      return null;
    }
    return token;
  }

  return null;
}

bool _looksLikeEncodedTripPayload(String token) {
  try {
    final bytes = base64Url.decode(token);
    final jsonString = utf8.decode(bytes);
    final decoded = jsonDecode(jsonString);
    return decoded is Map &&
        decoded.containsKey('route') &&
        decoded.containsKey('stops');
  } catch (_) {
    return false;
  }
}

/// v1.10.23: Share fuer oeffentliche Trips aus der Galerie
Future<void> sharePublicTrip({
  required String tripId,
  required String tripName,
  String? description,
  int? stopCount,
  double? distanceKm,
}) async {
  final link = generatePublicTripLink(tripId);

  final buffer = StringBuffer();
  buffer.writeln('\u{1F5FA}\u{FE0F} $tripName');
  if (description != null && description.isNotEmpty) {
    buffer.writeln('');
    buffer.writeln(description);
  }
  buffer.writeln('');
  if (stopCount != null && distanceKm != null) {
    buffer.writeln(
      '\u{1F4CD} $stopCount Stopps '
      '\u{00B7} ${distanceKm.toStringAsFixed(0)} km',
    );
  }
  buffer.writeln('');
  buffer.writeln(link);

  await Share.share(buffer.toString(), subject: 'MapAB Trip: $tripName');
}

/// v1.10.23: Kopiert Deep Link fuer oeffentlichen Trip
Future<void> copyPublicTripLink(String tripId) async {
  final link = generatePublicTripLink(tripId);
  await Clipboard.setData(ClipboardData(text: link));
}

/// v1.10.23: Generiert QR-Daten fuer oeffentlichen Trip
String generatePublicTripQRData(String tripId) {
  return generatePublicTripLink(tripId);
}

/// Sharing Service Provider
@riverpod
SharingService sharingService(SharingServiceRef ref) {
  return SharingService();
}
