import 'dart:math';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/categories.dart';
import '../../core/constants/trip_constants.dart';
import 'poi.dart';
import 'route.dart';

part 'trip.freezed.dart';
part 'trip.g.dart';

// JSON Converter für Trip nested objects (top-level Funktionen)
Map<String, dynamic> _tripRouteToJson(AppRoute route) => route.toJson();
AppRoute _tripRouteFromJson(Map<String, dynamic> json) =>
    AppRoute.fromJson(json);

List<Map<String, dynamic>> _tripStopsToJson(List<TripStop> stops) =>
    stops.map((s) => s.toJson()).toList();
List<TripStop> _tripStopsFromJson(List<dynamic> json) =>
    json.map((e) => TripStop.fromJson(e as Map<String, dynamic>)).toList();

/// Trip (Reise) Datenmodell
/// Übernommen von MapAB Trip-Logik
@freezed
class Trip with _$Trip {
  const Trip._();

  const factory Trip({
    /// Eindeutige ID
    required String id,

    /// Trip-Name
    required String name,

    /// Trip-Typ
    required TripType type,

    /// Basis-Route (Start → Ziel) mit expliziter JSON-Konvertierung
    @JsonKey(toJson: _tripRouteToJson, fromJson: _tripRouteFromJson)
    required AppRoute route,

    /// Geplante Stops (POIs) mit expliziter JSON-Konvertierung
    @JsonKey(toJson: _tripStopsToJson, fromJson: _tripStopsFromJson)
    @Default([]) List<TripStop> stops,

    /// Anzahl Tage (für Mehrtages-Trips)
    @Default(1) int days,

    /// Geplantes Startdatum
    DateTime? startDate,

    /// Erstellt am
    required DateTime createdAt,

    /// Zuletzt geändert
    DateTime? updatedAt,

    /// Notizen
    String? notes,

    /// Wetter-Zustand bei Planung
    WeatherCondition? weatherCondition,

    /// Bevorzugte Kategorien
    @Default([]) List<String> preferredCategories,
  }) = _Trip;

  /// Erstellt Trip aus JSON
  factory Trip.fromJson(Map<String, dynamic> json) => _$TripFromJson(json);

  /// Gesamtdistanz inkl. Umwege
  double get totalDistanceKm {
    double total = route.distanceKm;
    for (final stop in stops) {
      total += (stop.detourKm ?? 0) * 2; // Hin und zurück
    }
    return total;
  }

  /// Gesamtdauer inkl. Stopps
  int get totalDurationMinutes {
    int total = route.durationMinutes;
    for (final stop in stops) {
      total += (stop.detourMinutes ?? 0) * 2;
      total += stop.plannedDurationMinutes;
    }
    return total;
  }

  /// Formatierte Gesamtdauer
  String get formattedTotalDuration {
    final minutes = totalDurationMinutes;
    if (minutes < 60) return '$minutes Min.';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) return '$hours Std.';
    return '$hours Std. $mins Min.';
  }

  /// Anzahl Stops
  int get stopCount => stops.length;

  /// Sortierte Stops nach Routen-Position
  List<TripStop> get sortedStops {
    final sorted = List<TripStop>.from(stops);
    sorted.sort((a, b) =>
        (a.routePosition ?? 0).compareTo(b.routePosition ?? 0));
    return sorted;
  }

  /// Alle Koordinaten für optimierte Route
  List<LatLng> get allWaypoints {
    return sortedStops
        .map((stop) => LatLng(stop.latitude, stop.longitude))
        .toList();
  }

  /// Gibt alle Stops für einen bestimmten Tag zurück (1-basiert)
  /// Sortiert nach `order` (optimierte Tages-Reihenfolge vom DayPlanner),
  /// NICHT nach `routePosition` (Gesamt-Route) — wichtig fuer Google Maps Export
  List<TripStop> getStopsForDay(int dayNumber) {
    final dayStops = stops.where((s) => s.day == dayNumber).toList();
    dayStops.sort((a, b) => a.order.compareTo(b.order));
    return dayStops;
  }

  /// Berechnet die geschaetzte Fahrdistanz fuer einen bestimmten Tag
  /// Haversine-Summe × Faktor 1.35 (≈ echte Fahrstrecke)
  ///
  /// Tagesdistanz = Anreise vom Vortags-letzten-Stop + Strecke zwischen Stops
  /// Nur letzter Tag: + Rueckkehr zum Ziel (route.end)
  /// Kein "Outgoing-Segment" zum Folgetag — das ist Incoming des naechsten Tages
  double getDistanceForDay(int dayNumber) {
    final dayStops = getStopsForDay(dayNumber);
    if (dayStops.isEmpty) return 0;

    double total = 0;
    LatLng? prevLocation;

    // Start des Tages bestimmen
    if (dayNumber == 1) {
      prevLocation = route.start;
    } else {
      final prevDayStops = getStopsForDay(dayNumber - 1);
      if (prevDayStops.isNotEmpty) {
        prevLocation = prevDayStops.last.location;
      }
    }

    if (prevLocation == null) {
      // Fallback: gleichmaessige Aufteilung
      return route.distanceKm / actualDays;
    }

    for (final stop in dayStops) {
      total += _haversineDistance(prevLocation!, stop.location);
      prevLocation = stop.location;
    }

    // Nur letzter Tag: Rueckkehr-Segment zum Trip-Ziel einrechnen
    if (dayNumber == actualDays) {
      total += _haversineDistance(prevLocation!, route.end);
    }

    // Haversine → geschaetzte Fahrstrecke (Faktor ~1.35)
    return total * 1.35;
  }

  /// Haversine-Distanz in km (inline, da Freezed kein GeoUtils-Import erlaubt)
  static double _haversineDistance(LatLng a, LatLng b) {
    const r = 6371.0;
    final dLat = (b.latitude - a.latitude) * (pi / 180);
    final dLon = (b.longitude - a.longitude) * (pi / 180);
    final lat1 = a.latitude * (pi / 180);
    final lat2 = b.latitude * (pi / 180);

    final hav = sin(dLat / 2) * sin(dLat / 2) +
        sin(dLon / 2) * sin(dLon / 2) * cos(lat1) * cos(lat2);
    final c = 2 * atan2(sqrt(hav), sqrt(1 - hav));
    return r * c;
  }

  /// Anzahl der tatsächlichen Tage (basierend auf Stop-Verteilung)
  int get actualDays {
    if (stops.isEmpty) return 1;
    return stops.map((s) => s.day).reduce(max);
  }

  /// Prüft ob ein Tag das POI-Limit überschreitet
  bool isDayOverLimit(int dayNumber) {
    return getStopsForDay(dayNumber).length > TripConstants.maxPoisPerDay;
  }

  /// Gibt die Anzahl der Stops pro Tag als Map zurück
  Map<int, int> get stopsPerDay {
    final result = <int, int>{};
    for (final stop in stops) {
      result[stop.day] = (result[stop.day] ?? 0) + 1;
    }
    return result;
  }

  /// Waypoints für einen bestimmten Tag
  List<LatLng> getWaypointsForDay(int dayNumber) {
    return getStopsForDay(dayNumber)
        .map((stop) => LatLng(stop.latitude, stop.longitude))
        .toList();
  }
}

/// Trip-Stop (einzelner Halt)
@freezed
class TripStop with _$TripStop {
  const TripStop._();

  const factory TripStop({
    /// POI-ID
    required String poiId,

    /// Name
    required String name,

    /// Koordinaten
    required double latitude,
    required double longitude,

    /// Kategorie
    required String categoryId,

    /// Position auf der Route (0-1)
    double? routePosition,

    /// Umweg in km
    double? detourKm,

    /// Umweg in Minuten
    int? detourMinutes,

    /// Geplante Aufenthaltsdauer in Minuten
    @Default(30) int plannedDurationMinutes,

    /// Reihenfolge (für Drag-and-Drop)
    @Default(0) int order,

    /// Tag des Trips (für Mehrtages-Trips)
    @Default(1) int day,

    /// Ist Übernachtungsstopp
    @Default(false) bool isOvernightStop,

    /// Notizen
    String? notes,
  }) = _TripStop;

  /// Erstellt TripStop aus JSON
  factory TripStop.fromJson(Map<String, dynamic> json) =>
      _$TripStopFromJson(json);

  /// Erstellt TripStop aus POI
  factory TripStop.fromPOI(POI poi, {int order = 0}) {
    return TripStop(
      poiId: poi.id,
      name: poi.name,
      latitude: poi.latitude,
      longitude: poi.longitude,
      categoryId: poi.categoryId,
      routePosition: poi.routePosition,
      detourKm: poi.detourKm,
      detourMinutes: poi.detourMinutes,
      order: order,
    );
  }

  /// Koordinaten als LatLng
  LatLng get location => LatLng(latitude, longitude);

  /// Kategorie als Enum
  POICategory? get category => POICategory.fromId(categoryId);

  /// Kategorie-Icon
  String get categoryIcon => category?.icon ?? '📍';

  /// Bild-URL (falls vorhanden - wird über POI-State gepflegt)
  String? get imageUrl => null;

  /// v1.6.9: Konvertiert TripStop zurück zu POI
  /// Nützlich für Navigation zu POI-Details
  POI toPOI() {
    return POI(
      id: poiId,
      name: name,
      latitude: latitude,
      longitude: longitude,
      categoryId: categoryId,
      routePosition: routePosition,
      detourKm: detourKm,
      detourMinutes: detourMinutes,
    );
  }
}

// JSON Converter für TripDay nested objects (top-level Funktionen)
List<Map<String, dynamic>> _tripDayStopsToJson(List<TripStop> stops) =>
    stops.map((s) => s.toJson()).toList();
List<TripStop> _tripDayStopsFromJson(List<dynamic> json) =>
    json.map((e) => TripStop.fromJson(e as Map<String, dynamic>)).toList();

Map<String, dynamic>? _tripDayOvernightStopToJson(TripStop? stop) =>
    stop?.toJson();
TripStop? _tripDayOvernightStopFromJson(Map<String, dynamic>? json) =>
    json != null ? TripStop.fromJson(json) : null;

/// Tages-Aufteilung für Mehrtages-Trips
@freezed
class TripDay with _$TripDay {
  const TripDay._();

  const factory TripDay({
    /// Tag-Nummer (1-basiert)
    required int dayNumber,

    /// Titel (z.B. "Tag 1: München → Salzburg")
    required String title,

    /// Stops für diesen Tag mit expliziter JSON-Konvertierung
    @JsonKey(toJson: _tripDayStopsToJson, fromJson: _tripDayStopsFromJson)
    @Default([]) List<TripStop> stops,

    /// Übernachtungsort (letzter Stop) mit expliziter JSON-Konvertierung
    @JsonKey(
        toJson: _tripDayOvernightStopToJson,
        fromJson: _tripDayOvernightStopFromJson)
    TripStop? overnightStop,

    /// Distanz für diesen Tag
    double? distanceKm,

    /// Dauer für diesen Tag
    int? durationMinutes,
  }) = _TripDay;

  /// Erstellt TripDay aus JSON
  factory TripDay.fromJson(Map<String, dynamic> json) =>
      _$TripDayFromJson(json);

  /// Formatierte Dauer
  String get formattedDuration {
    if (durationMinutes == null) return '-';
    final mins = durationMinutes!;
    if (mins < 60) return '$mins Min.';
    final hours = mins ~/ 60;
    final rest = mins % 60;
    if (rest == 0) return '$hours Std.';
    return '$hours Std. $rest Min.';
  }
}

/// AI-generierter Reiseplan
@freezed
class AITripPlan with _$AITripPlan {
  const factory AITripPlan({
    /// Titel
    required String title,

    /// Beschreibung
    String? description,

    /// Tages-Aufteilung
    required List<AITripDay> days,

    /// Generiert von AI-Modell
    String? model,

    /// Generiert am
    required DateTime generatedAt,
  }) = _AITripPlan;

  factory AITripPlan.fromJson(Map<String, dynamic> json) =>
      _$AITripPlanFromJson(json);
}

/// AI-generierter Tagesplan
@freezed
class AITripDay with _$AITripDay {
  const factory AITripDay({
    /// Tag-Titel
    required String title,

    /// Empfohlene Stops
    required List<AITripStop> stops,

    /// Beschreibung/Tipps
    String? description,
  }) = _AITripDay;

  factory AITripDay.fromJson(Map<String, dynamic> json) =>
      _$AITripDayFromJson(json);
}

/// AI-empfohlener Stop
@freezed
class AITripStop with _$AITripStop {
  const factory AITripStop({
    /// Name
    required String name,

    /// Kategorie
    required String category,

    /// Empfohlene Dauer
    String? duration,

    /// Beschreibung/Grund
    String? description,

    /// Koordinaten (falls bekannt)
    double? latitude,
    double? longitude,
  }) = _AITripStop;

  factory AITripStop.fromJson(Map<String, dynamic> json) =>
      _$AITripStopFromJson(json);
}
