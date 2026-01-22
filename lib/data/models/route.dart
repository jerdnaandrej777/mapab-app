import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:latlong2/latlong.dart';

part 'route.freezed.dart';
part 'route.g.dart';

/// Custom JSON-Konverter für LatLng (latlong2 hat kein eingebautes fromJson/toJson)
class LatLngConverter implements JsonConverter<LatLng, Map<String, dynamic>> {
  const LatLngConverter();

  @override
  LatLng fromJson(Map<String, dynamic> json) {
    return LatLng(
      (json['lat'] as num).toDouble(),
      (json['lng'] as num).toDouble(),
    );
  }

  @override
  Map<String, dynamic> toJson(LatLng latLng) {
    return {
      'lat': latLng.latitude,
      'lng': latLng.longitude,
    };
  }
}

/// Custom JSON-Konverter für List<LatLng>
class LatLngListConverter
    implements JsonConverter<List<LatLng>, List<dynamic>> {
  const LatLngListConverter();

  @override
  List<LatLng> fromJson(List<dynamic> json) {
    return json.map((e) {
      final map = e as Map<String, dynamic>;
      return LatLng(
        (map['lat'] as num).toDouble(),
        (map['lng'] as num).toDouble(),
      );
    }).toList();
  }

  @override
  List<dynamic> toJson(List<LatLng> list) {
    return list
        .map((latLng) => {
              'lat': latLng.latitude,
              'lng': latLng.longitude,
            })
        .toList();
  }
}

/// Routen-Datenmodell
/// Übernommen von MapAB Routing-Logik
@freezed
class AppRoute with _$AppRoute {
  const AppRoute._();

  const factory AppRoute({
    /// Start-Koordinaten
    @LatLngConverter() required LatLng start,

    /// Ziel-Koordinaten
    @LatLngConverter() required LatLng end,

    /// Start-Adresse (Display)
    required String startAddress,

    /// Ziel-Adresse (Display)
    required String endAddress,

    /// Routen-Koordinaten (Polyline)
    @LatLngListConverter() required List<LatLng> coordinates,

    /// Distanz in Kilometern
    required double distanceKm,

    /// Dauer in Minuten
    required int durationMinutes,

    /// Routen-Typ
    @Default(RouteType.fast) RouteType type,

    /// Waypoints (Zwischenstopps)
    @LatLngListConverter() @Default([]) List<LatLng> waypoints,

    /// OSRM Routen-Geometrie (für Export)
    String? geometry,

    /// Zeitstempel der Berechnung
    DateTime? calculatedAt,
  }) = _AppRoute;

  /// Erstellt Route aus JSON
  factory AppRoute.fromJson(Map<String, dynamic> json) =>
      _$AppRouteFromJson(json);

  /// Formatierte Distanz
  String get formattedDistance {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m';
    }
    return '${distanceKm.toStringAsFixed(1)} km';
  }

  /// Formatierte Dauer
  String get formattedDuration {
    if (durationMinutes < 60) {
      return '$durationMinutes Min.';
    }
    final hours = durationMinutes ~/ 60;
    final mins = durationMinutes % 60;
    if (mins == 0) return '$hours Std.';
    return '$hours Std. $mins Min.';
  }

  /// Hat Waypoints
  bool get hasWaypoints => waypoints.isNotEmpty;

  /// Gesamtanzahl Punkte (inkl. Start/End)
  int get totalPoints => waypoints.length + 2;
}

/// Routen-Typ
enum RouteType {
  fast('Schnell', 'Schnellste Route via Autobahn'),
  scenic('Landschaft', 'Landschaftlich schöne Route, Autobahn vermeiden');

  final String label;
  final String description;

  const RouteType(this.label, this.description);
}

/// Routen-Vergleich (Fast vs Scenic)
@freezed
class RouteComparison with _$RouteComparison {
  const RouteComparison._();

  const factory RouteComparison({
    /// Schnelle Route
    AppRoute? fastRoute,

    /// Scenic Route
    AppRoute? scenicRoute,

    /// Aktuell aktive Route
    @Default(RouteType.fast) RouteType activeType,
  }) = _RouteComparison;

  /// Aktive Route
  AppRoute? get activeRoute =>
      activeType == RouteType.fast ? fastRoute : scenicRoute;

  /// Distanz-Differenz in km
  double? get distanceDifference {
    if (fastRoute == null || scenicRoute == null) return null;
    return scenicRoute!.distanceKm - fastRoute!.distanceKm;
  }

  /// Zeit-Differenz in Minuten
  int? get timeDifference {
    if (fastRoute == null || scenicRoute == null) return null;
    return scenicRoute!.durationMinutes - fastRoute!.durationMinutes;
  }

  /// Sind beide Routen geladen
  bool get hasBothRoutes => fastRoute != null && scenicRoute != null;
}

/// Geocoding-Ergebnis
@freezed
class GeocodingResult with _$GeocodingResult {
  const factory GeocodingResult({
    /// Koordinaten
    @LatLngConverter() required LatLng location,

    /// Anzeige-Name
    required String displayName,

    /// Kurzer Name (Stadt/Ort)
    String? shortName,

    /// Typ (city, address, poi, etc.)
    String? type,

    /// Bounding Box
    List<double>? boundingBox,

    /// OSM Place ID
    int? placeId,
  }) = _GeocodingResult;

  factory GeocodingResult.fromJson(Map<String, dynamic> json) =>
      _$GeocodingResultFromJson(json);
}

/// Nullable LatLng Converter
class NullableLatLngConverter
    implements JsonConverter<LatLng?, Map<String, dynamic>?> {
  const NullableLatLngConverter();

  @override
  LatLng? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return LatLng(
      (json['lat'] as num).toDouble(),
      (json['lng'] as num).toDouble(),
    );
  }

  @override
  Map<String, dynamic>? toJson(LatLng? latLng) {
    if (latLng == null) return null;
    return {
      'lat': latLng.latitude,
      'lng': latLng.longitude,
    };
  }
}

/// Autocomplete-Vorschlag
@freezed
class AutocompleteSuggestion with _$AutocompleteSuggestion {
  const factory AutocompleteSuggestion({
    /// Anzeige-Name
    required String displayName,

    /// Koordinaten (falls verfügbar)
    @NullableLatLngConverter() LatLng? location,

    /// Icon basierend auf Typ
    String? icon,

    /// OSM Place ID
    int? placeId,
  }) = _AutocompleteSuggestion;

  factory AutocompleteSuggestion.fromJson(Map<String, dynamic> json) =>
      _$AutocompleteSuggestionFromJson(json);
}
