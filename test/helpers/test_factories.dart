import 'package:latlong2/latlong.dart';
import 'package:travel_planner/data/models/poi.dart';
import 'package:travel_planner/data/models/route.dart';
import 'package:travel_planner/data/models/trip.dart';
import 'package:travel_planner/data/models/weather.dart';
import 'package:travel_planner/core/constants/categories.dart';

/// Shared Test-Factories fuer wiederverwendbare Test-Daten.
/// Verwendung: import '../helpers/test_factories.dart';

// --- Bekannte Koordinaten ---
const munich = LatLng(48.1351, 11.5820);
const salzburg = LatLng(47.8095, 13.0550);
const vienna = LatLng(48.2082, 16.3738);
const berlin = LatLng(52.5200, 13.4050);
const zurich = LatLng(47.3769, 8.5417);
const prague = LatLng(50.0755, 14.4378);
const rome = LatLng(41.9028, 12.4964);

// --- POI Factory ---
POI createPOI({
  String id = 'test-1',
  String name = 'Test POI',
  double latitude = 48.1351,
  double longitude = 11.5820,
  String categoryId = 'castle',
  int score = 50,
  String? imageUrl,
  String? description,
  bool isCurated = false,
  bool hasWikipedia = false,
  List<String> tags = const [],
  int? foundedYear,
  double? detourKm,
  int? detourMinutes,
  double? routePosition,
}) {
  return POI(
    id: id,
    name: name,
    latitude: latitude,
    longitude: longitude,
    categoryId: categoryId,
    score: score,
    imageUrl: imageUrl,
    description: description,
    isCurated: isCurated,
    hasWikipedia: hasWikipedia,
    tags: tags,
    foundedYear: foundedYear,
    detourKm: detourKm,
    detourMinutes: detourMinutes,
    routePosition: routePosition,
  );
}

// --- TripStop Factory ---
TripStop createTripStop({
  String poiId = 'stop-1',
  String name = 'Test Stop',
  double latitude = 48.1351,
  double longitude = 11.5820,
  String categoryId = 'castle',
  double? routePosition,
  double? detourKm,
  int? detourMinutes,
  int plannedDurationMinutes = 30,
  int order = 0,
  int day = 1,
  bool isOvernightStop = false,
}) {
  return TripStop(
    poiId: poiId,
    name: name,
    latitude: latitude,
    longitude: longitude,
    categoryId: categoryId,
    routePosition: routePosition,
    detourKm: detourKm,
    detourMinutes: detourMinutes,
    plannedDurationMinutes: plannedDurationMinutes,
    order: order,
    day: day,
    isOvernightStop: isOvernightStop,
  );
}

// --- AppRoute Factory ---
AppRoute createRoute({
  LatLng? start,
  LatLng? end,
  String startAddress = 'Muenchen',
  String endAddress = 'Salzburg',
  List<LatLng>? coordinates,
  double distanceKm = 150.0,
  int durationMinutes = 90,
  List<LatLng> waypoints = const [],
}) {
  return AppRoute(
    start: start ?? munich,
    end: end ?? salzburg,
    startAddress: startAddress,
    endAddress: endAddress,
    coordinates: coordinates ?? [start ?? munich, end ?? salzburg],
    distanceKm: distanceKm,
    durationMinutes: durationMinutes,
    waypoints: waypoints,
  );
}

// --- Trip Factory ---
Trip createTrip({
  String id = 'trip-1',
  String name = 'Test Trip',
  TripType type = TripType.daytrip,
  AppRoute? route,
  List<TripStop> stops = const [],
  int days = 1,
  DateTime? createdAt,
}) {
  return Trip(
    id: id,
    name: name,
    type: type,
    route: route ?? createRoute(),
    stops: stops,
    days: days,
    createdAt: createdAt ?? DateTime(2025, 1, 1),
  );
}

// --- Weather Factory ---
Weather createWeather({
  double latitude = 48.1351,
  double longitude = 11.5820,
  double temperature = 20.0,
  double? apparentTemperature,
  int weatherCode = 0,
  double precipitation = 0,
  int precipitationProbability = 0,
  double windSpeed = 10,
  int cloudCover = 0,
  DateTime? timestamp,
  List<DailyForecast> dailyForecast = const [],
}) {
  return Weather(
    latitude: latitude,
    longitude: longitude,
    temperature: temperature,
    apparentTemperature: apparentTemperature,
    weatherCode: weatherCode,
    precipitation: precipitation,
    precipitationProbability: precipitationProbability,
    windSpeed: windSpeed,
    cloudCover: cloudCover,
    timestamp: timestamp ?? DateTime(2025, 7, 15, 12, 0),
    dailyForecast: dailyForecast,
  );
}

// --- DailyForecast Factory ---
DailyForecast createDailyForecast({
  DateTime? date,
  double temperatureMax = 25.0,
  double temperatureMin = 15.0,
  int weatherCode = 0,
  double precipitationSum = 0,
  int precipitationProbabilityMax = 0,
  double windSpeedMax = 15,
}) {
  return DailyForecast(
    date: date ?? DateTime(2025, 7, 15),
    temperatureMax: temperatureMax,
    temperatureMin: temperatureMin,
    weatherCode: weatherCode,
    precipitationSum: precipitationSum,
    precipitationProbabilityMax: precipitationProbabilityMax,
    windSpeedMax: windSpeedMax,
  );
}

/// Erstellt einen Multi-Day Trip mit Stops verteilt auf mehrere Tage.
/// [stopsPerDay] definiert die Anzahl Stops pro Tag.
Trip createMultiDayTrip({
  int dayCount = 3,
  int stopsPerDay = 3,
  LatLng? start,
  LatLng? end,
}) {
  final routeStart = start ?? munich;
  final routeEnd = end ?? vienna;
  final stops = <TripStop>[];

  // Lineare Interpolation zwischen Start und Ende
  for (int day = 1; day <= dayCount; day++) {
    for (int i = 0; i < stopsPerDay; i++) {
      final t = ((day - 1) * stopsPerDay + i) / (dayCount * stopsPerDay);
      final lat = routeStart.latitude +
          (routeEnd.latitude - routeStart.latitude) * t;
      final lng = routeStart.longitude +
          (routeEnd.longitude - routeStart.longitude) * t;
      stops.add(createTripStop(
        poiId: 'stop-d${day}-${i + 1}',
        name: 'Stop Tag $day #${i + 1}',
        latitude: lat,
        longitude: lng,
        order: i,
        day: day,
      ));
    }
  }

  return createTrip(
    id: 'multi-day-trip',
    name: 'Multi-Day Trip',
    type: TripType.eurotrip,
    route: createRoute(
      start: routeStart,
      end: routeEnd,
      distanceKm: 400,
      durationMinutes: 240,
    ),
    stops: stops,
    days: dayCount,
  );
}
