import 'dart:convert';
import 'dart:math' show cos;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/utils/geo_utils.dart';
import '../models/poi.dart';
import '../models/route.dart';

part 'poi_repo.g.dart';

/// Repository für POI-Laden mit 3-Schichten-System
/// Übernommen von MapAB js/services/poi-loader.js
class POIRepository {
  final Dio _dio;

  POIRepository({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              headers: {'User-Agent': ApiConfig.userAgent},
              connectTimeout: const Duration(milliseconds: ApiConfig.defaultTimeout),
              receiveTimeout: const Duration(milliseconds: ApiConfig.overpassTimeout),
            ));

  /// Lädt POIs in einem Radius um einen Punkt (für Zufalls-Trips)
  /// Verwendet das 3-Schichten-System ohne Routen-Berechnungen
  Future<List<POI>> loadPOIsInRadius({
    required LatLng center,
    required double radiusKm,
    List<String>? categoryFilter,
    bool includeCurated = true,
    bool includeWikipedia = true,
    bool includeOverpass = true,
  }) async {
    final allPOIs = <POI>[];
    final seenIds = <String>{};

    // Bounding Box aus Zentrum + Radius erstellen
    final bounds = _createBoundsFromRadius(center, radiusKm);

    // 1. Kuratierte POIs laden
    if (includeCurated) {
      debugPrint('[POI] Lade kuratierte POIs...');
      final curated = await loadCuratedPOIs(bounds);
      debugPrint('[POI] Kuratierte POIs: ${curated.length}');
      for (final poi in curated) {
        if (!seenIds.contains(poi.id)) {
          seenIds.add(poi.id);
          allPOIs.add(poi);
        }
      }
    }

    // 2. Wikipedia POIs laden (für größere Radien mehrere Anfragen)
    if (includeWikipedia) {
      debugPrint('[POI] Lade Wikipedia POIs für Radius ${radiusKm}km...');
      final wikipedia = await _loadWikipediaPOIsInRadius(center, radiusKm);
      debugPrint('[POI] Wikipedia POIs: ${wikipedia.length}');
      for (final poi in wikipedia) {
        if (!seenIds.contains(poi.id)) {
          seenIds.add(poi.id);
          allPOIs.add(poi);
        }
      }
    }

    // 3. Overpass POIs laden
    if (includeOverpass) {
      debugPrint('[POI] Lade Overpass POIs...');
      final overpass = await loadOverpassPOIs(bounds);
      debugPrint('[POI] Overpass POIs: ${overpass.length}');
      for (final poi in overpass) {
        if (!seenIds.contains(poi.id)) {
          seenIds.add(poi.id);
          allPOIs.add(poi);
        }
      }
    }

    // Nach Kategorien filtern (falls angegeben)
    var filteredPOIs = allPOIs;
    if (categoryFilter != null && categoryFilter.isNotEmpty) {
      filteredPOIs = allPOIs
          .where((poi) => categoryFilter.contains(poi.categoryId))
          .toList();
    }

    // Nach Distanz filtern (exakt im Radius)
    final result = filteredPOIs.where((poi) {
      final distance = GeoUtils.haversineDistance(center, poi.location);
      return distance <= radiusKm;
    }).toList();

    debugPrint('[POI] Gesamt nach Filter: ${result.length}');
    return result;
  }

  /// Erstellt Bounding Box aus Zentrum und Radius
  ({LatLng southwest, LatLng northeast}) _createBoundsFromRadius(
    LatLng center,
    double radiusKm,
  ) {
    // Ungefähre Umrechnung: 1 Grad Latitude ≈ 111 km
    // Longitude variiert mit Breitengrad
    const latDegreeKm = 111.0;
    final lngDegreeKm = 111.0 * cos(center.latitude * pi / 180);

    final latDelta = radiusKm / latDegreeKm;
    final lngDelta = radiusKm / lngDegreeKm;

    return (
      southwest: LatLng(center.latitude - latDelta, center.longitude - lngDelta),
      northeast: LatLng(center.latitude + latDelta, center.longitude + lngDelta),
    );
  }

  /// Lädt Wikipedia POIs für größeren Radius (mehrere Anfragen)
  Future<List<POI>> _loadWikipediaPOIsInRadius(
    LatLng center,
    double radiusKm,
  ) async {
    final allPOIs = <POI>[];
    final seenIds = <String>{};

    // Wikipedia API hat 10km Limit - für größere Radien Grid verwenden
    if (radiusKm <= 10) {
      final pois = await _loadWikipediaPOIsAtPoint(center, radiusKm * 1000);
      return pois;
    }

    // Grid-basierte Abfrage für größere Radien
    final gridSize = 15.0; // km pro Grid-Zelle
    final cellsPerSide = (radiusKm * 2 / gridSize).ceil();

    for (int i = 0; i < cellsPerSide && allPOIs.length < 200; i++) {
      for (int j = 0; j < cellsPerSide && allPOIs.length < 200; j++) {
        final offsetLat = (i - cellsPerSide / 2) * gridSize / 111.0;
        final offsetLng = (j - cellsPerSide / 2) * gridSize /
            (111.0 * cos(center.latitude * pi / 180));

        final gridCenter = LatLng(
          center.latitude + offsetLat,
          center.longitude + offsetLng,
        );

        // Nur wenn Gridpunkt im Radius
        if (GeoUtils.haversineDistance(center, gridCenter) <= radiusKm) {
          try {
            final pois = await _loadWikipediaPOIsAtPoint(gridCenter, 10000);
            for (final poi in pois) {
              if (!seenIds.contains(poi.id)) {
                seenIds.add(poi.id);
                allPOIs.add(poi);
              }
            }
          } catch (_) {
            // Grid-Punkt fehlgeschlagen - weiter
          }

          // Rate Limiting
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }
    }

    return allPOIs;
  }

  /// Lädt Wikipedia POIs an einem Punkt
  Future<List<POI>> _loadWikipediaPOIsAtPoint(
    LatLng center,
    double radiusMeters,
  ) async {
    final clampedRadius = radiusMeters.clamp(1.0, 10000.0);

    try {
      final response = await _dio.get(
        ApiEndpoints.wikipediaGeoSearch,
        queryParameters: {
          'action': 'query',
          'list': 'geosearch',
          'gscoord': '${center.latitude}|${center.longitude}',
          'gsradius': clampedRadius.round(),
          'gslimit': 50,
          'format': 'json',
        },
      );

      final geosearch = response.data['query']?['geosearch'] as List?;
      if (geosearch == null) return [];

      return geosearch.map((item) => _parseWikipediaPOI(item)).toList();
    } on DioException catch (e) {
      debugPrint('[POI] FEHLER Wikipedia: ${e.message}');
      return [];
    }
  }

  /// Lädt alle POIs für eine Route (3 Schichten)
  /// 1. Kuratierte POIs (schnell, qualitativ)
  /// 2. Wikipedia-Artikel (mittel, informativ)
  /// 3. Overpass/OSM (langsam, vollständig)
  Future<List<POI>> loadAllPOIs(
    AppRoute route, {
    double bufferKm = 50,
    bool includeCurated = true,
    bool includeWikipedia = true,
    bool includeOverpass = true,
  }) async {
    final allPOIs = <POI>[];
    final seenIds = <String>{};

    // Bounding Box für die Route berechnen
    final bounds = GeoUtils.calculateBounds(route.coordinates);
    final expandedBounds = GeoUtils.expandBounds(bounds, 0.2);

    // 1. Kuratierte POIs laden
    if (includeCurated) {
      final curated = await loadCuratedPOIs(expandedBounds);
      for (final poi in curated) {
        if (!seenIds.contains(poi.id)) {
          seenIds.add(poi.id);
          allPOIs.add(poi);
        }
      }
    }

    // 2. Wikipedia POIs laden
    if (includeWikipedia) {
      final wikipedia = await loadWikipediaPOIs(expandedBounds);
      for (final poi in wikipedia) {
        if (!seenIds.contains(poi.id)) {
          seenIds.add(poi.id);
          allPOIs.add(poi);
        }
      }
    }

    // 3. Overpass POIs laden
    if (includeOverpass) {
      final overpass = await loadOverpassPOIs(expandedBounds);
      for (final poi in overpass) {
        if (!seenIds.contains(poi.id)) {
          seenIds.add(poi.id);
          allPOIs.add(poi);
        }
      }
    }

    // Routen-bezogene Daten berechnen
    return _calculateRouteData(allPOIs, route);
  }

  /// Lädt kuratierte POIs aus lokaler JSON-Datei
  Future<List<POI>> loadCuratedPOIs(
    ({LatLng southwest, LatLng northeast}) bounds,
  ) async {
    try {
      final jsonString =
          await rootBundle.loadString('assets/data/curated_pois.json');
      final jsonData = json.decode(jsonString) as List;

      return jsonData
          .map((item) => _parseCuratedPOI(item))
          .where((poi) => _isInBounds(poi.location, bounds))
          .toList();
    } catch (e) {
      debugPrint('[POI] FEHLER Curated: $e');
      return [];
    }
  }

  /// Lädt POIs aus Wikipedia Geosearch API
  Future<List<POI>> loadWikipediaPOIs(
    ({LatLng southwest, LatLng northeast}) bounds,
  ) async {
    final center = LatLng(
      (bounds.southwest.latitude + bounds.northeast.latitude) / 2,
      (bounds.southwest.longitude + bounds.northeast.longitude) / 2,
    );

    // Radius berechnen (max 10km für Wikipedia API)
    final radius = GeoUtils.haversineDistance(bounds.southwest, bounds.northeast) / 2;
    final clampedRadius = radius.clamp(1.0, 10.0) * 1000; // In Metern

    try {
      final response = await _dio.get(
        ApiEndpoints.wikipediaGeoSearch,
        queryParameters: {
          'action': 'query',
          'list': 'geosearch',
          'gscoord': '${center.latitude}|${center.longitude}',
          'gsradius': clampedRadius.round(),
          'gslimit': 50,
          'format': 'json',
        },
      );

      final geosearch = response.data['query']?['geosearch'] as List?;
      if (geosearch == null) return [];

      return geosearch.map((item) => _parseWikipediaPOI(item)).toList();
    } on DioException catch (e) {
      debugPrint('[POI] FEHLER Wikipedia (bounds): ${e.message}');
      return [];
    }
  }

  /// Lädt POIs aus Overpass API (OpenStreetMap)
  Future<List<POI>> loadOverpassPOIs(
    ({LatLng southwest, LatLng northeast}) bounds,
  ) async {
    // Overpass QL Query für touristische POIs
    final query = '''
[out:json][timeout:25];
(
  node["tourism"="attraction"](${bounds.southwest.latitude},${bounds.southwest.longitude},${bounds.northeast.latitude},${bounds.northeast.longitude});
  node["tourism"="viewpoint"](${bounds.southwest.latitude},${bounds.southwest.longitude},${bounds.northeast.latitude},${bounds.northeast.longitude});
  node["historic"="castle"](${bounds.southwest.latitude},${bounds.southwest.longitude},${bounds.northeast.latitude},${bounds.northeast.longitude});
  node["historic"="monument"](${bounds.southwest.latitude},${bounds.southwest.longitude},${bounds.northeast.latitude},${bounds.northeast.longitude});
  node["natural"="peak"](${bounds.southwest.latitude},${bounds.southwest.longitude},${bounds.northeast.latitude},${bounds.northeast.longitude});
  way["tourism"="attraction"](${bounds.southwest.latitude},${bounds.southwest.longitude},${bounds.northeast.latitude},${bounds.northeast.longitude});
  way["historic"="castle"](${bounds.southwest.latitude},${bounds.southwest.longitude},${bounds.northeast.latitude},${bounds.northeast.longitude});
);
out center;
''';

    try {
      final response = await _dio.post(
        ApiEndpoints.overpassApi,
        data: query,
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
        ),
      );

      final elements = response.data['elements'] as List?;
      if (elements == null) return [];

      return elements
          .where((e) => e['tags']?['name'] != null)
          .map((e) => _parseOverpassPOI(e))
          .toList();
    } on DioException catch (e) {
      debugPrint('[POI] FEHLER Overpass: ${e.message}');
      return [];
    }
  }

  /// Berechnet Routen-bezogene Daten für alle POIs
  List<POI> _calculateRouteData(List<POI> pois, AppRoute route) {
    return pois.map((poi) {
      final routePosition = GeoUtils.calculateRoutePosition(
        poi.location,
        route.coordinates,
      );

      final detourKm = GeoUtils.calculateDetour(
        poi.location,
        route.coordinates,
      );

      // Umweg in Minuten (geschätzt: 50 km/h Durchschnitt)
      final detourMinutes = (detourKm / 50 * 60).round();

      return poi.copyWith(
        routePosition: routePosition,
        detourKm: detourKm,
        detourMinutes: detourMinutes,
        effectiveScore: _calculateEffectiveScore(
          poi,
          detourKm,
          routePosition,
        ),
      );
    }).toList();
  }

  /// Berechnet den effektiven Score
  double _calculateEffectiveScore(POI poi, double detourKm, double routePosition) {
    double score = poi.score.toDouble();

    // Umweg-Abzug
    score -= (detourKm * 0.5).clamp(0, 30);

    // Positions-Bonus (Mitte der Route)
    if (routePosition >= 0.3 && routePosition <= 0.7) {
      score += 10;
    }

    // Must-See Bonus
    if (poi.isMustSee) {
      score += 15;
    }

    return score.clamp(0, 100);
  }

  /// Prüft ob ein Punkt in den Bounds liegt
  bool _isInBounds(LatLng point, ({LatLng southwest, LatLng northeast}) bounds) {
    return point.latitude >= bounds.southwest.latitude &&
        point.latitude <= bounds.northeast.latitude &&
        point.longitude >= bounds.southwest.longitude &&
        point.longitude <= bounds.northeast.longitude;
  }

  /// Parst kuratiertes POI aus JSON
  POI _parseCuratedPOI(Map<String, dynamic> data) {
    return POI(
      id: data['id'] ?? 'curated-${data['n']?.hashCode}',
      name: data['n'] ?? data['name'] ?? 'Unbekannt',
      latitude: (data['lat'] as num).toDouble(),
      longitude: (data['lng'] as num).toDouble(),
      categoryId: data['c'] ?? data['category'] ?? 'attraction',
      score: data['r'] ?? data['score'] ?? 50,
      imageUrl: data['img'],
      description: data['desc'],
      isCurated: true,
      tags: (data['tags'] as List?)?.cast<String>() ?? [],
    );
  }

  /// Parst Wikipedia POI
  POI _parseWikipediaPOI(Map<String, dynamic> data) {
    final title = data['title'] ?? 'Unbekannt';
    return POI(
      id: 'wiki-${data['pageid']}',
      name: title,
      latitude: (data['lat'] as num).toDouble(),
      longitude: (data['lon'] as num).toDouble(),
      categoryId: _inferCategoryFromTitle(title),
      score: _inferScoreFromTitle(title),
      hasWikipedia: true,
      wikipediaTitle: title,
    );
  }

  /// Ermittelt Kategorie basierend auf Keywords im Titel
  String _inferCategoryFromTitle(String title) {
    final lowerTitle = title.toLowerCase();

    // Kategorie-Patterns (Reihenfolge ist wichtig - spezifischere zuerst)
    const patterns = <String, List<String>>{
      'castle': ['schloss', 'burg', 'festung', 'castle', 'fortress', 'palast', 'palace', 'residenz'],
      'church': ['kirche', 'dom', 'kathedrale', 'kloster', 'abtei', 'chapel', 'church', 'cathedral', 'abbey', 'münster', 'basilika'],
      'museum': ['museum', 'galerie', 'gallery', 'ausstellung', 'exhibition'],
      'nature': ['nationalpark', 'naturpark', 'naturschutz', 'biosphäre', 'national park', 'nature reserve'],
      'lake': ['see', 'lake', 'teich', 'pond', 'stausee', 'reservoir', 'talsperre'],
      'viewpoint': ['aussichtspunkt', 'viewpoint', 'aussichtsturm', 'turm', 'tower', 'gipfel', 'peak', 'berg'],
      'park': ['park', 'garten', 'garden', 'botanical'],
      'monument': ['denkmal', 'monument', 'memorial', 'gedenkstätte', 'mahnmal', 'statue'],
      'city': ['altstadt', 'old town', 'stadt', 'city', 'marktplatz', 'market square', 'rathaus', 'town hall'],
      'coast': ['strand', 'beach', 'küste', 'coast', 'insel', 'island', 'hafen', 'harbor', 'port'],
    };

    for (final entry in patterns.entries) {
      for (final keyword in entry.value) {
        if (lowerTitle.contains(keyword)) {
          return entry.key;
        }
      }
    }

    return 'attraction'; // Fallback
  }

  /// Ermittelt Score basierend auf Keywords (bekannte Sehenswürdigkeiten höher)
  int _inferScoreFromTitle(String title) {
    final lowerTitle = title.toLowerCase();

    // Bekannte Keywords für hochwertige Sehenswürdigkeiten
    const highScoreKeywords = [
      'schloss', 'castle', 'dom', 'cathedral', 'nationalpark', 'unesco',
      'welterbe', 'heritage', 'museum', 'altstadt', 'old town'
    ];

    const mediumScoreKeywords = [
      'burg', 'kirche', 'church', 'kloster', 'abbey', 'park', 'garten',
      'denkmal', 'monument', 'turm', 'tower'
    ];

    for (final keyword in highScoreKeywords) {
      if (lowerTitle.contains(keyword)) {
        return 75; // Hoher Score
      }
    }

    for (final keyword in mediumScoreKeywords) {
      if (lowerTitle.contains(keyword)) {
        return 65; // Mittlerer Score
      }
    }

    return 55; // Basis-Score für Wikipedia-Artikel
  }

  /// Parst Overpass POI
  POI _parseOverpassPOI(Map<String, dynamic> data) {
    final tags = data['tags'] as Map<String, dynamic>? ?? {};

    // Koordinaten ermitteln (Node vs Way)
    double lat, lng;
    if (data['center'] != null) {
      lat = (data['center']['lat'] as num).toDouble();
      lng = (data['center']['lon'] as num).toDouble();
    } else {
      lat = (data['lat'] as num).toDouble();
      lng = (data['lon'] as num).toDouble();
    }

    // Kategorie aus Tags ableiten
    String category = 'attraction';
    if (tags['historic'] == 'castle') {
      category = 'castle';
    } else if (tags['tourism'] == 'viewpoint' || tags['natural'] == 'peak') {
      category = 'viewpoint';
    } else if (tags['tourism'] == 'museum') {
      category = 'museum';
    } else if (tags['historic'] == 'monument') {
      category = 'monument';
    } else if (tags['historic'] == 'church' || tags['amenity'] == 'place_of_worship') {
      category = 'church';
    }

    return POI(
      id: 'osm-${data['type']}-${data['id']}',
      name: tags['name'] ?? 'Unbekannt',
      latitude: lat,
      longitude: lng,
      categoryId: category,
      score: 40, // Niedrigerer Score für OSM-Daten
      website: tags['website'],
      phone: tags['phone'],
      openingHours: tags['opening_hours'],
      hasWikidataData: tags['website'] != null || tags['phone'] != null,
    );
  }
}

/// Riverpod Provider für POIRepository
@riverpod
POIRepository poiRepository(PoiRepositoryRef ref) {
  return POIRepository();
}
