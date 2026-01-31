import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/cost.dart';
import '../../core/constants/api_keys.dart';

part 'cost_service.g.dart';

/// Cost Service für Kosten-Berechnung und Tankstellen
class CostService {
  final Dio _dio;

  // Tankerkönig API für deutsche Benzinpreise
  static const String _tankerkoenigUrl = 'https://creativecommons.tankerkoenig.de/json';

  CostService(this._dio);

  /// Berechnet Kraftstoffkosten für eine Route
  double calculateFuelCost({
    required double distanceKm,
    required VehicleType vehicle,
    double? customFuelPrice,
  }) {
    if (vehicle.isElectric) {
      // Elektro: kWh * Preis pro kWh
      final consumption = (distanceKm / 100) * vehicle.electricConsumptionKwh100km;
      final pricePerKwh = customFuelPrice ?? FuelType.electricity.defaultPricePerUnit;
      return consumption * pricePerKwh;
    } else {
      // Verbrenner: Liter * Preis pro Liter
      final consumption = (distanceKm / 100) * vehicle.fuelConsumptionL100km;
      final pricePerLiter = customFuelPrice ?? FuelType.e10.defaultPricePerUnit;
      return consumption * pricePerLiter;
    }
  }

  /// Schätzt Mautkosten für eine Route
  double estimateTollCost({
    required double distanceKm,
    required List<String> countries,
  }) {
    double total = 0;

    for (final country in countries) {
      switch (country.toLowerCase()) {
        case 'at':  // Österreich Vignette
          total += 11.50;  // 10-Tages-Vignette
          break;
        case 'ch':  // Schweiz Vignette
          total += 42.00;  // Jahresvignette
          break;
        case 'fr':  // Frankreich
          total += distanceKm * 0.09;  // ca. 9 Cent/km
          break;
        case 'it':  // Italien
          total += distanceKm * 0.07;  // ca. 7 Cent/km
          break;
        case 'es':  // Spanien
          total += distanceKm * 0.08;  // ca. 8 Cent/km
          break;
        case 'cz':  // Tschechien
          total += 14.00;  // 10-Tages-Vignette
          break;
        case 'si':  // Slowenien
          total += 15.00;  // 7-Tages-Vignette
          break;
        case 'hr':  // Kroatien
          total += distanceKm * 0.05;  // ca. 5 Cent/km
          break;
        // Deutschland: keine Autobahn-Maut für PKW
      }
    }

    return total;
  }

  /// Schätzt Parkkosten
  double estimateParkingCost({
    required int numberOfStops,
    required double avgParkingDurationHours,
    required bool isCityCenter,
  }) {
    // Durchschnittliche Parkkosten
    final hourlyRate = isCityCenter ? 3.50 : 1.50;
    return numberOfStops * avgParkingDurationHours * hourlyRate;
  }

  /// Schätzt Eintrittskosten basierend auf POI-Kategorien
  double estimateAdmissionCost({
    required Map<String, int> categoryCounts,
  }) {
    double total = 0;

    // Durchschnittliche Eintrittspreise nach Kategorie
    final avgPrices = {
      'castle': 12.0,
      'museum': 10.0,
      'church': 0.0,  // Meist kostenlos
      'park': 0.0,    // Meist kostenlos
      'nature': 0.0,
      'viewpoint': 0.0,
      'activity': 25.0,
      'unesco': 15.0,
      'monument': 5.0,
      'attraction': 20.0,
    };

    for (final entry in categoryCounts.entries) {
      final price = avgPrices[entry.key] ?? 5.0;
      total += price * entry.value;
    }

    return total;
  }

  /// Schätzt Essenskosten
  double estimateFoodCost({
    required int days,
    required int peopleCount,
    bool budgetConscious = false,
  }) {
    // Pro Person pro Tag
    final dailyCost = budgetConscious ? 25.0 : 45.0;
    return days * peopleCount * dailyCost;
  }

  /// Schätzt Übernachtungskosten
  double estimateAccommodationCost({
    required int nights,
    required int roomCount,
    bool budgetConscious = false,
  }) {
    // Pro Zimmer pro Nacht
    final nightlyCost = budgetConscious ? 60.0 : 100.0;
    return nights * roomCount * nightlyCost;
  }

  /// Lädt günstigste Tankstellen im Umkreis
  Future<List<FuelPrice>> getNearbyFuelPrices({
    required LatLng location,
    double radiusKm = 10,
    FuelType sortBy = FuelType.e10,
  }) async {
    final apiKey = ApiKeys.tankerkoenigApiKey;
    if (apiKey.isEmpty) {
      // Simulierte Daten ohne API-Key
      return _generateSimulatedFuelPrices(location);
    }

    try {
      final response = await _dio.get(
        '$_tankerkoenigUrl/list.php',
        queryParameters: {
          'lat': location.latitude,
          'lng': location.longitude,
          'rad': radiusKm,
          'sort': 'price',
          'type': sortBy == FuelType.diesel ? 'diesel' : 'e10',
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
          address: '${s['street']} ${s['houseNumber']}, ${s['postCode']} ${s['place']}',
          lastUpdated: DateTime.now(),
        )).toList();
      }
    } catch (e) {
      debugPrint('[Cost] Tankstellen-Fehler: $e');
    }

    return [];
  }

  /// Erstellt komplette Kostenschätzung für einen Trip
  TripCosts estimateTripCosts({
    required String tripId,
    required double distanceKm,
    required int numberOfStops,
    required int days,
    required Map<String, int> categoryCounts,
    required VehicleType vehicle,
    List<String> countries = const ['de'],
    int peopleCount = 2,
    bool budgetConscious = false,
  }) {
    return TripCosts(
      tripId: tripId,
      estimatedFuelCost: calculateFuelCost(
        distanceKm: distanceKm,
        vehicle: vehicle,
      ),
      estimatedTollCost: estimateTollCost(
        distanceKm: distanceKm,
        countries: countries,
      ),
      estimatedParkingCost: estimateParkingCost(
        numberOfStops: numberOfStops,
        avgParkingDurationHours: 1.5,
        isCityCenter: categoryCounts.containsKey('city'),
      ),
      estimatedAdmissionCost: estimateAdmissionCost(
        categoryCounts: categoryCounts,
      ),
      estimatedFoodCost: estimateFoodCost(
        days: days,
        peopleCount: peopleCount,
        budgetConscious: budgetConscious,
      ),
      estimatedAccommodationCost: days > 1
          ? estimateAccommodationCost(
              nights: days - 1,
              roomCount: 1,
              budgetConscious: budgetConscious,
            )
          : 0,
      vehicleType: vehicle,
      lastUpdated: DateTime.now(),
    );
  }

  List<FuelPrice> _generateSimulatedFuelPrices(LatLng location) {
    // Simulierte Tankstellen für Demo-Zwecke
    return [
      FuelPrice(
        stationId: 'sim1',
        stationName: 'Aral',
        latitude: location.latitude + 0.01,
        longitude: location.longitude + 0.01,
        e5Price: 1.759,
        e10Price: 1.699,
        dieselPrice: 1.649,
        isOpen: true,
        brand: 'Aral',
        lastUpdated: DateTime.now(),
      ),
      FuelPrice(
        stationId: 'sim2',
        stationName: 'Shell',
        latitude: location.latitude - 0.01,
        longitude: location.longitude + 0.02,
        e5Price: 1.779,
        e10Price: 1.719,
        dieselPrice: 1.669,
        isOpen: true,
        brand: 'Shell',
        lastUpdated: DateTime.now(),
      ),
      FuelPrice(
        stationId: 'sim3',
        stationName: 'JET',
        latitude: location.latitude + 0.02,
        longitude: location.longitude - 0.01,
        e5Price: 1.729,
        e10Price: 1.679,
        dieselPrice: 1.629,
        isOpen: true,
        brand: 'JET',
        lastUpdated: DateTime.now(),
      ),
    ];
  }
}

/// Cost Service Provider
@riverpod
CostService costService(CostServiceRef ref) {
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));
  return CostService(dio);
}
