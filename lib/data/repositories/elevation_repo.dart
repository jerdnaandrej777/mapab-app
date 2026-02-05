import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/constants/api_endpoints.dart';
import '../models/elevation.dart';

part 'elevation_repo.g.dart';

/// Repository fuer Hoehendaten via Open-Meteo Elevation API.
///
/// Die API liefert Hoehen basierend auf Copernicus DEM (90m Aufloesung).
/// Max 100 Koordinaten pro Request, kostenlos, kein API-Key noetig.
class ElevationRepository {
  final Dio _dio;

  /// Max Koordinaten pro API-Request (Open-Meteo Limit)
  static const int _maxCoordsPerRequest = 100;

  /// Anzahl Sample-Punkte fuer das Hoehenprofil
  static const int _samplePoints = 80;

  ElevationRepository({Dio? dio})
      : _dio = dio ?? ApiConfig.createDio();

  /// Laedt das Hoehenprofil fuer eine Route.
  ///
  /// Sampelt [_samplePoints] gleichmaessig verteilte Punkte entlang der Route,
  /// ruft die Open-Meteo Elevation API auf und berechnet Anstieg/Abstieg.
  Future<ElevationProfile> getElevationProfile(
    List<LatLng> routeCoordinates,
  ) async {
    if (routeCoordinates.length < 2) {
      return const ElevationProfile(
        points: [],
        totalAscent: 0,
        totalDescent: 0,
        maxElevation: 0,
        minElevation: 0,
        totalDistanceKm: 0,
      );
    }

    // Kumulative Distanzen berechnen (einmal, in separatem Isolate bei langen Routen)
    final cumulativeKm = await _computeCumulativeDistances(routeCoordinates);
    final totalDistanceKm = cumulativeKm.last;

    // Punkte gleichmaessig entlang der Route samplen
    final sampleCount = math.min(_samplePoints, routeCoordinates.length);
    final sampledCoords = <LatLng>[];
    final sampledDistances = <double>[];

    // Immer Start und Ende einschliessen
    sampledCoords.add(routeCoordinates.first);
    sampledDistances.add(0.0);

    if (sampleCount > 2) {
      final step = totalDistanceKm / (sampleCount - 1);
      int routeIdx = 0;

      for (int i = 1; i < sampleCount - 1; i++) {
        final targetDist = step * i;

        // Naechsten Routenpunkt nach targetDist finden
        while (routeIdx < cumulativeKm.length - 1 &&
            cumulativeKm[routeIdx + 1] < targetDist) {
          routeIdx++;
        }

        // Zwischen zwei Routenpunkten interpolieren
        if (routeIdx < routeCoordinates.length - 1) {
          final segStart = cumulativeKm[routeIdx];
          final segEnd = cumulativeKm[routeIdx + 1];
          final segLen = segEnd - segStart;

          if (segLen > 0) {
            final t = (targetDist - segStart) / segLen;
            final lat = routeCoordinates[routeIdx].latitude +
                t * (routeCoordinates[routeIdx + 1].latitude -
                    routeCoordinates[routeIdx].latitude);
            final lng = routeCoordinates[routeIdx].longitude +
                t * (routeCoordinates[routeIdx + 1].longitude -
                    routeCoordinates[routeIdx].longitude);
            sampledCoords.add(LatLng(lat, lng));
          } else {
            sampledCoords.add(routeCoordinates[routeIdx]);
          }
        } else {
          sampledCoords.add(routeCoordinates.last);
        }
        sampledDistances.add(targetDist);
      }
    }

    sampledCoords.add(routeCoordinates.last);
    sampledDistances.add(totalDistanceKm);

    // Hoehendaten von Open-Meteo laden (max 100 pro Request)
    final elevations = await _fetchElevations(sampledCoords);

    debugPrint('[Elevation] ${sampledCoords.length} Punkte geladen, '
        '${totalDistanceKm.toStringAsFixed(1)} km Gesamtdistanz');

    return ElevationProfile.fromRawData(
      elevations: elevations,
      cumulativeDistancesKm: sampledDistances,
    );
  }

  /// Ruft Hoehendaten von der Open-Meteo Elevation API ab.
  /// Splittet automatisch in Batches von max 100 Koordinaten.
  Future<List<double>> _fetchElevations(List<LatLng> coords) async {
    if (coords.isEmpty) return [];

    final allElevations = <double>[];

    // In Batches aufteilen (API-Limit: 100 Koordinaten)
    for (int i = 0; i < coords.length; i += _maxCoordsPerRequest) {
      final batch = coords.sublist(
        i,
        math.min(i + _maxCoordsPerRequest, coords.length),
      );

      final latitudes = batch.map((c) => c.latitude.toStringAsFixed(4)).join(',');
      final longitudes = batch.map((c) => c.longitude.toStringAsFixed(4)).join(',');

      try {
        final response = await _dio.get(
          ApiEndpoints.openMeteoElevation,
          queryParameters: {
            'latitude': latitudes,
            'longitude': longitudes,
          },
        );

        final elevationData = response.data['elevation'] as List;
        allElevations.addAll(
          elevationData.map((e) => (e as num).toDouble()),
        );
      } on DioException catch (e) {
        debugPrint('[Elevation] API-Fehler: ${e.message}');
        // Bei Fehler: Nullen fuer diesen Batch einfuegen
        allElevations.addAll(List.filled(batch.length, 0.0));
      }

      // Rate-Limit zwischen Batches
      if (i + _maxCoordsPerRequest < coords.length) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }

    return allElevations;
  }

  /// Berechnet kumulative Distanzen entlang der Route.
  /// Bei langen Routen (>500 Punkte) wird compute() verwendet.
  Future<List<double>> _computeCumulativeDistances(
    List<LatLng> coords,
  ) async {
    if (coords.length > 500) {
      // In separatem Isolate berechnen um UI nicht zu blockieren
      return compute(
        _cumulativeDistancesIsolate,
        _CoordsData(
          lats: coords.map((c) => c.latitude).toList(),
          lngs: coords.map((c) => c.longitude).toList(),
        ),
      );
    }

    return _calculateCumulativeDistances(coords);
  }

  /// Kumulative Distanzen (Main-Thread-Version)
  static List<double> _calculateCumulativeDistances(List<LatLng> coords) {
    final distances = <double>[0.0];
    for (int i = 1; i < coords.length; i++) {
      final dist = _haversineRaw(
        coords[i - 1].latitude,
        coords[i - 1].longitude,
        coords[i].latitude,
        coords[i].longitude,
      );
      distances.add(distances.last + dist);
    }
    return distances;
  }

  /// Haversine-Distanz in km (raw, ohne LatLng-Import)
  static double _haversineRaw(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const r = 6371.0;
    const deg2rad = math.pi / 180;
    final dLat = (lat2 - lat1) * deg2rad;
    final dLng = (lng2 - lng1) * deg2rad;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * deg2rad) *
            math.cos(lat2 * deg2rad) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }
}

/// Daten-Container fuer Isolate (muss top-level oder static sein)
class _CoordsData {
  final List<double> lats;
  final List<double> lngs;

  _CoordsData({required this.lats, required this.lngs});
}

/// Isolate-Funktion fuer kumulative Distanzen
List<double> _cumulativeDistancesIsolate(_CoordsData data) {
  const r = 6371.0;
  const deg2rad = math.pi / 180;
  final distances = <double>[0.0];

  for (int i = 1; i < data.lats.length; i++) {
    final dLat = (data.lats[i] - data.lats[i - 1]) * deg2rad;
    final dLng = (data.lngs[i] - data.lngs[i - 1]) * deg2rad;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(data.lats[i - 1] * deg2rad) *
            math.cos(data.lats[i] * deg2rad) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final dist = r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    distances.add(distances.last + dist);
  }

  return distances;
}

/// Riverpod Provider fuer ElevationRepository
@riverpod
ElevationRepository elevationRepository(ElevationRepositoryRef ref) {
  return ElevationRepository();
}
