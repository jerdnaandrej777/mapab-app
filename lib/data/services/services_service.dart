import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/cost.dart';
import '../../core/constants/api_keys.dart';

part 'services_service.g.dart';

/// Service-Typ (Restaurant, Tankstelle, etc.)
enum ServiceType {
  restaurant('Restaurant', '🍽️', 'amenity=restaurant'),
  cafe('Café', '☕', 'amenity=cafe'),
  fastFood('Fast Food', '🍔', 'amenity=fast_food'),
  fuelStation('Tankstelle', '⛽', 'amenity=fuel'),
  evCharging('E-Ladestation', '🔌', 'amenity=charging_station'),
  parking('Parkplatz', '🅿️', 'amenity=parking'),
  restArea('Rastplatz', '🛑', 'highway=rest_area'),
  supermarket('Supermarkt', '🛒', 'shop=supermarket'),
  pharmacy('Apotheke', '💊', 'amenity=pharmacy'),
  atm('Geldautomat', '🏧', 'amenity=atm');

  final String label;
  final String emoji;
  final String osmTag;
  const ServiceType(this.label, this.emoji, this.osmTag);
}

/// Service-Punkt (Restaurant, Tankstelle, etc.)
class ServicePoint {
  final String id;
  final String name;
  final ServiceType type;
  final double latitude;
  final double longitude;
  final double? distanceKm;
  final bool? isOpen;
  final String? phone;
  final String? website;
  final String? openingHours;
  final Map<String, dynamic> tags;

  // Spezifische Felder
  final double? fuelPriceE5;
  final double? fuelPriceE10;
  final double? fuelPriceDiesel;
  final String? cuisine;  // Für Restaurants
  final int? capacity;    // Für Parkplätze
  final String? brand;

  ServicePoint({
    required this.id,
    required this.name,
    required this.type,
    required this.latitude,
    required this.longitude,
    this.distanceKm,
    this.isOpen,
    this.phone,
    this.website,
    this.openingHours,
    this.tags = const {},
    this.fuelPriceE5,
    this.fuelPriceE10,
    this.fuelPriceDiesel,
    this.cuisine,
    this.capacity,
    this.brand,
  });

  LatLng get location => LatLng(latitude, longitude);

  String get displayName => name.isNotEmpty ? name : type.label;

  /// Formatierter Benzinpreis
  String? get formattedFuelPrice {
    if (fuelPriceE10 != null) {
      return '${fuelPriceE10!.toStringAsFixed(3)} €/L';
    }
    return null;
  }
}

/// Services Service für Restaurants, Tankstellen, etc.
class ServicesService {
  final Dio _dio;

  // Overpass API für OSM-Daten
  static const String _overpassUrl = 'https://overpass-api.de/api/interpreter';

  // OpenChargeMap für E-Ladesäulen
  static const String _chargeMapUrl = 'https://api.openchargemap.io/v3/poi';

  ServicesService(this._dio);

  /// Lädt Services entlang einer Route
  Future<List<ServicePoint>> getServicesAlongRoute({
    required List<LatLng> routeCoordinates,
    required List<ServiceType> types,
    double corridorKm = 5,
  }) async {
    if (routeCoordinates.isEmpty || types.isEmpty) return [];

    final services = <ServicePoint>[];

    // Vereinfache Route für Abfrage
    final samplePoints = _sampleRoute(routeCoordinates, 10);

    for (final type in types) {
      final typeServices = await _loadServicesNearPoints(
        points: samplePoints,
        type: type,
        radiusKm: corridorKm,
      );
      services.addAll(typeServices);
    }

    // Deduplizierung nach ID
    final seen = <String>{};
    return services.where((s) => seen.add(s.id)).toList();
  }

  /// Lädt Services in der Nähe eines Punktes
  Future<List<ServicePoint>> getServicesNearby({
    required LatLng location,
    required List<ServiceType> types,
    double radiusKm = 5,
  }) async {
    final services = <ServicePoint>[];

    for (final type in types) {
      if (type == ServiceType.evCharging) {
        // E-Ladestationen von OpenChargeMap
        final evStations = await _loadEVChargers(location, radiusKm);
        services.addAll(evStations);
      } else {
        // Andere von OSM
        final osmServices = await _loadFromOsm(location, type, radiusKm);
        services.addAll(osmServices);
      }
    }

    // Sortiere nach Entfernung
    const distance = Distance();
    for (final service in services) {
      // Berechne Distanz inline
    }
    services.sort((a, b) => (a.distanceKm ?? 999).compareTo(b.distanceKm ?? 999));

    return services;
  }

  /// Lädt Tankstellen mit Preisen (Tankerkönig API)
  Future<List<FuelPrice>> getFuelPrices({
    required LatLng location,
    double radiusKm = 10,
  }) async {
    final apiKey = ApiKeys.tankerkoenigApiKey;
    if (apiKey.isEmpty) {
      // Fallback: OSM Tankstellen ohne Preise
      final stations = await _loadFromOsm(location, ServiceType.fuelStation, radiusKm);
      return stations.map((s) => FuelPrice(
        stationId: s.id,
        stationName: s.name,
        latitude: s.latitude,
        longitude: s.longitude,
        e5Price: 0,
        e10Price: 0,
        dieselPrice: 0,
        isOpen: s.isOpen ?? true,
        brand: s.brand,
      )).toList();
    }

    try {
      final response = await _dio.get(
        'https://creativecommons.tankerkoenig.de/json/list.php',
        queryParameters: {
          'lat': location.latitude,
          'lng': location.longitude,
          'rad': radiusKm,
          'sort': 'price',
          'type': 'all',
          'apikey': apiKey,
        },
      );

      if (response.statusCode == 200 && response.data['ok'] == true) {
        final stations = response.data['stations'] as List? ?? [];
        return stations.map((s) => FuelPrice(
          stationId: s['id'] ?? '',
          stationName: s['name'] ?? 'Tankstelle',
          latitude: (s['lat'] as num).toDouble(),
          longitude: (s['lng'] as num).toDouble(),
          e5Price: (s['e5'] as num?)?.toDouble() ?? 0,
          e10Price: (s['e10'] as num?)?.toDouble() ?? 0,
          dieselPrice: (s['diesel'] as num?)?.toDouble() ?? 0,
          isOpen: s['isOpen'] == true,
          brand: s['brand'],
          address: '${s['street'] ?? ''} ${s['houseNumber'] ?? ''}, '
              '${s['postCode'] ?? ''} ${s['place'] ?? ''}',
          lastUpdated: DateTime.now(),
        )).toList();
      }
    } catch (e) {
      debugPrint('[Services] Tankerkönig-Fehler: $e');
    }

    return [];
  }

  /// Lädt E-Ladestationen von OpenChargeMap
  Future<List<ServicePoint>> _loadEVChargers(LatLng location, double radiusKm) async {
    final apiKey = ApiKeys.openChargeMapApiKey;

    try {
      final response = await _dio.get(
        _chargeMapUrl,
        queryParameters: {
          'latitude': location.latitude,
          'longitude': location.longitude,
          'distance': radiusKm,
          'distanceunit': 'km',
          'maxresults': 50,
          'compact': true,
          'verbose': false,
          if (apiKey.isNotEmpty) 'key': apiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as List? ?? [];
        return data.map((poi) {
          final address = poi['AddressInfo'] ?? {};
          final connections = poi['Connections'] as List? ?? [];

          return ServicePoint(
            id: 'ocm_${poi['ID']}',
            name: address['Title'] ?? 'E-Ladestation',
            type: ServiceType.evCharging,
            latitude: (address['Latitude'] as num).toDouble(),
            longitude: (address['Longitude'] as num).toDouble(),
            distanceKm: (address['Distance'] as num?)?.toDouble(),
            phone: address['ContactTelephone1'],
            website: address['RelatedURL'],
            tags: {
              'connections': connections.length,
              'powerKW': connections.isNotEmpty
                  ? connections.first['PowerKW']
                  : null,
            },
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('[Services] OpenChargeMap-Fehler: $e');
    }

    return [];
  }

  /// Lädt Services von OSM/Overpass
  Future<List<ServicePoint>> _loadFromOsm(
    LatLng location,
    ServiceType type,
    double radiusKm,
  ) async {
    final query = '''
[out:json][timeout:10];
(
  node[${type.osmTag}](around:${radiusKm * 1000},${location.latitude},${location.longitude});
  way[${type.osmTag}](around:${radiusKm * 1000},${location.latitude},${location.longitude});
);
out center tags;
''';

    try {
      final response = await _dio.post(
        _overpassUrl,
        data: query,
        options: Options(
          contentType: 'text/plain',
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

      if (response.statusCode == 200) {
        final elements = response.data['elements'] as List? ?? [];
        const distance = Distance();

        return elements.map((e) {
          final tags = Map<String, dynamic>.from(e['tags'] ?? {});
          final lat = (e['lat'] ?? e['center']?['lat'] as num?)?.toDouble() ?? 0;
          final lng = (e['lon'] ?? e['center']?['lon'] as num?)?.toDouble() ?? 0;

          return ServicePoint(
            id: 'osm_${e['id']}',
            name: tags['name'] ?? tags['brand'] ?? type.label,
            type: type,
            latitude: lat,
            longitude: lng,
            distanceKm: distance.as(LengthUnit.Kilometer, location, LatLng(lat, lng)),
            phone: tags['phone'] ?? tags['contact:phone'],
            website: tags['website'] ?? tags['contact:website'],
            openingHours: tags['opening_hours'],
            tags: tags,
            brand: tags['brand'],
            cuisine: tags['cuisine'],
            capacity: int.tryParse(tags['capacity']?.toString() ?? ''),
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('[Services] OSM-Fehler für $type: $e');
    }

    return [];
  }

  Future<List<ServicePoint>> _loadServicesNearPoints({
    required List<LatLng> points,
    required ServiceType type,
    required double radiusKm,
  }) async {
    final allServices = <ServicePoint>[];

    for (final point in points) {
      final services = await _loadFromOsm(point, type, radiusKm);
      allServices.addAll(services);
    }

    // Deduplizieren
    final seen = <String>{};
    return allServices.where((s) => seen.add(s.id)).toList();
  }

  List<LatLng> _sampleRoute(List<LatLng> route, int maxSamples) {
    if (route.length <= maxSamples) return route;
    final step = route.length ~/ maxSamples;
    return [
      for (int i = 0; i < route.length; i += step) route[i],
      route.last,
    ];
  }
}

/// Services Service Provider
@riverpod
ServicesService servicesService(ServicesServiceRef ref) {
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
  ));
  return ServicesService(dio);
}
