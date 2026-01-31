import 'dart:convert';
import 'dart:math' show cos, sqrt, min, max, pi;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/utils/geo_utils.dart';
import '../models/poi.dart';
import '../models/route.dart';
import '../services/poi_cache_service.dart';

part 'poi_repo.g.dart';

/// Mindest-Score für POIs (35 = ca. 1.75 Sterne)
/// POIs unter diesem Score werden herausgefiltert
/// HINWEIS: Wert gesenkt von 70 auf 35, um mehr POIs anzuzeigen
/// - Overpass/OSM POIs haben Score 40-60
/// - Wikipedia POIs haben Score 55-75
const int minimumPOIScore = 35;

/// Repository für POI-Laden mit 3-Schichten-System
/// Übernommen von MapAB js/services/poi-loader.js
/// OPTIMIERT: Mit Region-Cache für schnelleres Laden
class POIRepository {
  final Dio _dio;
  final POICacheService? _cacheService;

  POIRepository({Dio? dio, POICacheService? cacheService})
      : _dio = dio ??
            Dio(BaseOptions(
              headers: {'User-Agent': ApiConfig.userAgent},
              connectTimeout: const Duration(milliseconds: ApiConfig.defaultTimeout),
              receiveTimeout: const Duration(milliseconds: ApiConfig.overpassTimeout),
            )),
        _cacheService = cacheService;

  /// Lädt POIs in einem Radius um einen Punkt (für Zufalls-Trips)
  /// Verwendet das 3-Schichten-System ohne Routen-Berechnungen
  /// OPTIMIERT: Paralleles Laden aller 3 Schichten + Region-Cache
  Future<List<POI>> loadPOIsInRadius({
    required LatLng center,
    required double radiusKm,
    List<String>? categoryFilter,
    bool includeCurated = true,
    bool includeWikipedia = true,
    bool includeOverpass = true,
    bool useCache = true,
  }) async {
    // OPTIMIERUNG: Zuerst im Cache schauen
    if (useCache && _cacheService != null) {
      final regionKey = _cacheService!.createRegionKey(
        center.latitude,
        center.longitude,
        radiusKm,
      );
      final cachedPOIs = await _cacheService!.getCachedPOIs(regionKey);
      if (cachedPOIs != null && cachedPOIs.isNotEmpty) {
        debugPrint('[POI] Cache-Treffer: ${cachedPOIs.length} POIs für Region $regionKey');
        // Nach Kategorien filtern (falls angegeben)
        if (categoryFilter != null && categoryFilter.isNotEmpty) {
          return cachedPOIs
              .where((poi) => categoryFilter.contains(poi.categoryId))
              .toList();
        }
        return cachedPOIs;
      }
    }

    final allPOIs = <POI>[];
    final seenIds = <String>{};

    // Bounding Box aus Zentrum + Radius erstellen
    final bounds = _createBoundsFromRadius(center, radiusKm);

    debugPrint('[POI] Starte paralleles Laden für Radius ${radiusKm}km...');
    final stopwatch = Stopwatch()..start();

    // OPTIMIERUNG: Alle 3 Schichten parallel laden
    // FIX v1.3.8: Besseres Error Tracking
    final futures = <Future<List<POI>>>[];
    final sourceErrors = <String>[];
    int sourceCount = 0;

    if (includeCurated) {
      sourceCount++;
      futures.add(loadCuratedPOIs(bounds).catchError((e) {
        sourceErrors.add('Kuratiert: $e');
        debugPrint('[POI] Curated-Fehler: $e');
        return <POI>[];
      }));
    }

    if (includeWikipedia) {
      sourceCount++;
      futures.add(_loadWikipediaPOIsInRadius(center, radiusKm).catchError((e) {
        sourceErrors.add('Wikipedia: $e');
        debugPrint('[POI] Wikipedia-Fehler: $e');
        return <POI>[];
      }));
    }

    if (includeOverpass) {
      sourceCount++;
      futures.add(loadOverpassPOIs(bounds).catchError((e) {
        sourceErrors.add('Overpass: $e');
        debugPrint('[POI] Overpass-Fehler: $e');
        return <POI>[];
      }));
    }

    // Parallel warten
    final results = await Future.wait(futures);

    // Ergebnisse zusammenführen (Duplikate vermeiden)
    for (final poiList in results) {
      for (final poi in poiList) {
        if (!seenIds.contains(poi.id)) {
          seenIds.add(poi.id);
          allPOIs.add(poi);
        }
      }
    }

    stopwatch.stop();

    // FIX v1.3.8: Warnung bei teilweisen/vollständigen Fehlern
    if (sourceErrors.isNotEmpty) {
      if (sourceErrors.length == sourceCount) {
        debugPrint('[POI] ⚠️ ALLE Quellen fehlgeschlagen: ${sourceErrors.join(", ")}');
      } else {
        debugPrint('[POI] ⚠️ Teilweise Fehler (${sourceErrors.length}/$sourceCount): ${sourceErrors.join(", ")}');
      }
    }

    debugPrint('[POI] Parallel geladen in ${stopwatch.elapsedMilliseconds}ms: ${allPOIs.length} POIs von ${sourceCount - sourceErrors.length}/$sourceCount Quellen');

    // Nach Distanz filtern (exakt im Radius)
    final distanceFiltered = allPOIs.where((poi) {
      final distance = GeoUtils.haversineDistance(center, poi.location);
      return distance <= radiusKm;
    }).toList();

    // v1.3.9: Qualitätsfilter - nur POIs mit >= 3.5 Sternen (Score >= 70)
    final qualityFiltered = distanceFiltered.where((poi) => poi.score >= minimumPOIScore).toList();
    debugPrint('[POI] Qualitätsfilter: ${distanceFiltered.length} → ${qualityFiltered.length} POIs (min. $minimumPOIScore Score)');

    // OPTIMIERUNG: Im Cache speichern (vor Kategorie-Filter)
    if (useCache && _cacheService != null && qualityFiltered.isNotEmpty) {
      final regionKey = _cacheService!.createRegionKey(
        center.latitude,
        center.longitude,
        radiusKm,
      );
      // Asynchron cachen ohne zu warten
      _cacheService!.cachePOIs(qualityFiltered, regionKey);
    }

    // Nach Kategorien filtern (falls angegeben)
    var result = qualityFiltered;
    if (categoryFilter != null && categoryFilter.isNotEmpty) {
      result = qualityFiltered
          .where((poi) => categoryFilter.contains(poi.categoryId))
          .toList();
    }

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
    // OPTIMIERUNG v1.6.2: Dynamische Grid-Size für große Radien
    // Maximal 36 Zellen (6x6) um Performance zu gewährleisten
    // Bei 600km war es vorher 80x80 = 6400 Zellen (10+ Minuten!)
    const maxCellsPerSide = 6;
    final gridSize = max((radiusKm * 2 / maxCellsPerSide), 15.0);
    final cellsPerSide = min((radiusKm * 2 / gridSize).ceil(), maxCellsPerSide);

    debugPrint('[POI] Wikipedia Grid: ${cellsPerSide}x$cellsPerSide Zellen, ${gridSize.toStringAsFixed(0)}km pro Zelle');

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
  /// OPTIMIERT: Paralleles Laden aller 3 Schichten
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

    debugPrint('[POI] Starte paralleles Laden für Route...');
    final stopwatch = Stopwatch()..start();

    // OPTIMIERUNG: Alle 3 Schichten parallel laden
    // FIX v1.3.8: Besseres Error Tracking
    final futures = <Future<List<POI>>>[];
    final sourceErrors = <String>[];
    int sourceCount = 0;

    if (includeCurated) {
      sourceCount++;
      futures.add(loadCuratedPOIs(expandedBounds).catchError((e) {
        sourceErrors.add('Kuratiert: $e');
        debugPrint('[POI] Curated-Fehler: $e');
        return <POI>[];
      }));
    }

    if (includeWikipedia) {
      sourceCount++;
      futures.add(loadWikipediaPOIs(expandedBounds).catchError((e) {
        sourceErrors.add('Wikipedia: $e');
        debugPrint('[POI] Wikipedia-Fehler: $e');
        return <POI>[];
      }));
    }

    if (includeOverpass) {
      sourceCount++;
      futures.add(loadOverpassPOIs(expandedBounds).catchError((e) {
        sourceErrors.add('Overpass: $e');
        debugPrint('[POI] Overpass-Fehler: $e');
        return <POI>[];
      }));
    }

    // Parallel warten
    final results = await Future.wait(futures);

    // Ergebnisse zusammenführen (Duplikate vermeiden)
    for (final poiList in results) {
      for (final poi in poiList) {
        if (!seenIds.contains(poi.id)) {
          seenIds.add(poi.id);
          allPOIs.add(poi);
        }
      }
    }

    stopwatch.stop();

    // FIX v1.3.8: Warnung bei teilweisen/vollständigen Fehlern
    if (sourceErrors.isNotEmpty) {
      if (sourceErrors.length == sourceCount) {
        debugPrint('[POI] ⚠️ ALLE Quellen fehlgeschlagen: ${sourceErrors.join(", ")}');
      } else {
        debugPrint('[POI] ⚠️ Teilweise Fehler (${sourceErrors.length}/$sourceCount): ${sourceErrors.join(", ")}');
      }
    }

    debugPrint('[POI] Parallel geladen in ${stopwatch.elapsedMilliseconds}ms: ${allPOIs.length} POIs von ${sourceCount - sourceErrors.length}/$sourceCount Quellen');

    // v1.3.9: Qualitätsfilter - nur POIs mit >= 3.5 Sternen (Score >= 70)
    final qualityFiltered = allPOIs.where((poi) => poi.score >= minimumPOIScore).toList();
    debugPrint('[POI] Qualitätsfilter: ${allPOIs.length} → ${qualityFiltered.length} POIs (min. $minimumPOIScore Score)');

    // Routen-bezogene Daten berechnen
    return _calculateRouteData(qualityFiltered, route);
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
    // ERWEITERT v1.7.23: Seen, Strände, Hotels, Restaurants, Aktivitäten, Zoos, Inseln
    final bbox = '${bounds.southwest.latitude},${bounds.southwest.longitude},${bounds.northeast.latitude},${bounds.northeast.longitude}';
    final query = '''
[out:json][timeout:25];
(
  node["tourism"="attraction"]($bbox);
  node["tourism"="viewpoint"]($bbox);
  node["tourism"="museum"]($bbox);
  node["historic"="castle"]($bbox);
  node["historic"="monument"]($bbox);
  node["historic"="memorial"]["name"]($bbox);
  node["historic"="ruins"]["name"]($bbox);
  node["historic"="church"]["name"]($bbox);
  node["natural"="peak"]($bbox);
  node["natural"="waterfall"]["name"]($bbox);
  node["amenity"="place_of_worship"]["name"]["tourism"]($bbox);
  way["tourism"="attraction"]($bbox);
  way["tourism"="museum"]($bbox);
  way["historic"="castle"]($bbox);
  way["historic"="ruins"]["name"]($bbox);
  way["historic"="church"]["name"]($bbox);
  node["heritage"]["name"]($bbox);
  way["heritage"]["name"]($bbox);
  node["heritage:operator"="whc"]["name"]($bbox);
  way["heritage:operator"="whc"]["name"]($bbox);
  node["place"="city"]["name"]["population"]($bbox);
  node["place"="town"]["name"]["population"]($bbox);
  node["natural"="water"]["water"="lake"]["name"]($bbox);
  way["natural"="water"]["water"="lake"]["name"]($bbox);
  node["natural"="beach"]["name"]($bbox);
  way["natural"="beach"]["name"]($bbox);
  node["leisure"="beach_resort"]["name"]($bbox);
  way["leisure"="beach_resort"]["name"]($bbox);
  node["tourism"="hotel"]["name"]["stars"]($bbox);
  way["tourism"="hotel"]["name"]["stars"]($bbox);
  node["amenity"="restaurant"]["name"]["cuisine"]($bbox);
  node["tourism"="theme_park"]["name"]($bbox);
  way["tourism"="theme_park"]["name"]($bbox);
  node["leisure"="water_park"]["name"]($bbox);
  way["leisure"="water_park"]["name"]($bbox);
  node["leisure"="swimming_area"]["name"]($bbox);
  node["tourism"="zoo"]["name"]($bbox);
  way["tourism"="zoo"]["name"]($bbox);
  node["place"="island"]["name"]($bbox);
  way["place"="island"]["name"]($bbox);
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
  /// Verwendet Score-basiertes Matching mit Prioritäten (spezifischere Kategorien höher)
  String _inferCategoryFromTitle(String title) {
    final lowerTitle = title.toLowerCase();

    // Kategorie-Patterns mit Priorität (Tuple: keywords, priority)
    // Höhere Priorität = spezifischere Kategorie
    // v1.7.9: activity, hotel, restaurant Keywords hinzugefuegt
    const patterns = <String, (List<String>, int)>{
      'museum': (['museum', 'galerie', 'gallery', 'ausstellung', 'exhibition'], 100),
      'castle': (['schloss', 'burg', 'festung', 'castle', 'fortress', 'palast', 'palace', 'residenz'], 90),
      'activity': (['zoo', 'tierpark', 'aquarium', 'freizeitpark', 'theme park', 'therme', 'thermalbad', 'schwimmbad', 'stadion', 'arena', 'erlebnispark', 'kletterpark'], 85),
      'church': (['kirche', 'dom', 'kathedrale', 'kloster', 'abtei', 'chapel', 'church', 'cathedral', 'abbey', 'münster', 'basilika'], 85),
      'nature': (['nationalpark', 'naturpark', 'naturschutz', 'biosphäre', 'national park', 'nature reserve', 'wasserfall', 'waterfall'], 80),
      'lake': (['see', 'lake', 'teich', 'pond', 'stausee', 'reservoir', 'talsperre'], 75),
      'viewpoint': (['aussichtspunkt', 'viewpoint', 'aussichtsturm', 'gipfel', 'peak'], 70),
      'park': (['park', 'garten', 'garden', 'botanical'], 65),
      'monument': (['denkmal', 'monument', 'memorial', 'gedenkstätte', 'mahnmal', 'statue', 'ruine', 'ruins'], 60),
      'city': (['altstadt', 'old town', 'marktplatz', 'market square', 'rathaus', 'town hall'], 55),
      'coast': (['strand', 'beach', 'küste', 'coast', 'insel', 'island', 'hafen', 'harbor', 'port'], 50),
      'hotel': (['hotel', 'gasthof', 'pension', 'herberge', 'jugendherberge'], 40),
      'restaurant': (['restaurant', 'brauhaus', 'wirtshaus', 'biergarten'], 40),
    };

    String? bestCategory;
    int bestScore = 0;
    int bestPosition = title.length;

    for (final entry in patterns.entries) {
      final (keywords, priority) = entry.value;
      for (final keyword in keywords) {
        final position = lowerTitle.indexOf(keyword);
        if (position != -1) {
          // Score = Priorität + Bonus für frühere Position im Titel
          final positionBonus = ((title.length - position) / title.length * 20).round();
          final score = priority + positionBonus;

          // Beste Kategorie auswählen (höchster Score, bei Gleichstand frühere Position)
          if (score > bestScore || (score == bestScore && position < bestPosition)) {
            bestScore = score;
            bestCategory = entry.key;
            bestPosition = position;
          }
        }
      }
    }

    return bestCategory ?? 'attraction'; // Fallback
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
  /// OPTIMIERT v1.7.6: Extrahiert OSM image/wikimedia_commons/wikidata/wikipedia Tags
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

    // Kategorie aus Tags ableiten (v1.7.25: UNESCO, City, historic=church via Overpass)
    String category = 'attraction';
    final List<String> poiTags = [];

    // UNESCO zuerst pruefen (kann auch andere Kategorien haben)
    if (tags['heritage'] != null || tags['heritage:operator'] == 'whc') {
      category = 'unesco';
      poiTags.add('unesco');
    }

    // Spezifischere Kategorien ueberschreiben UNESCO-Default
    if (tags['historic'] == 'castle') {
      category = 'castle';
    } else if (tags['tourism'] == 'viewpoint' || tags['natural'] == 'peak') {
      category = 'viewpoint';
    } else if (tags['tourism'] == 'museum') {
      category = 'museum';
    } else if (tags['historic'] == 'monument' || tags['historic'] == 'memorial') {
      category = 'monument';
    } else if (tags['historic'] == 'ruins') {
      category = 'monument';
    } else if (tags['historic'] == 'church' || tags['amenity'] == 'place_of_worship') {
      category = 'church';
    } else if (tags['natural'] == 'waterfall') {
      category = 'nature';
    } else if (tags['leisure'] == 'park' || tags['leisure'] == 'garden') {
      category = 'park';
    } else if (tags['natural'] == 'water' && tags['water'] == 'lake') {
      category = 'lake';
    } else if (tags['natural'] == 'beach' || tags['leisure'] == 'beach_resort' || tags['place'] == 'island') {
      category = 'coast';
    } else if (tags['tourism'] == 'hotel') {
      category = 'hotel';
    } else if (tags['amenity'] == 'restaurant') {
      category = 'restaurant';
    } else if (tags['tourism'] == 'theme_park' || tags['tourism'] == 'zoo' ||
               tags['leisure'] == 'water_park' || tags['leisure'] == 'swimming_area') {
      category = 'activity';
    } else if (tags['place'] == 'city' || tags['place'] == 'town') {
      category = 'city';
    }

    // OSM Bild-Tags extrahieren
    final osmImageTag = tags['image'] as String?;
    final wikimediaCommonsTag = tags['wikimedia_commons'] as String?;
    final wikidataTag = tags['wikidata'] as String?;
    final wikipediaTag = tags['wikipedia'] as String?;

    // Bild-URL aus OSM-Tags ableiten (v1.7.9: URL-Validierung)
    String? imageUrl;
    if (osmImageTag != null && (osmImageTag.startsWith('http://') || osmImageTag.startsWith('https://'))) {
      imageUrl = osmImageTag;
    }
    if (imageUrl == null && wikimediaCommonsTag != null) {
      // wikimedia_commons Tag: "File:Name.jpg" → URL
      if (wikimediaCommonsTag.startsWith('File:')) {
        final filename = Uri.encodeComponent(
          wikimediaCommonsTag.replaceFirst('File:', ''),
        );
        imageUrl =
            'https://commons.wikimedia.org/wiki/Special:FilePath/$filename?width=800';
      }
    }

    // Wikipedia-Titel aus Tag parsen (Format: "de:Artikelname")
    String? wpTitle;
    if (wikipediaTag != null) {
      final parts = wikipediaTag.split(':');
      if (parts.length >= 2 && parts[0] == 'de') {
        wpTitle = parts.sublist(1).join(':');
      }
    }

    // Score anpassen: Cities nach Einwohnerzahl, UNESCO hoeher
    int score = 40;
    if (category == 'city') {
      final population = int.tryParse(tags['population']?.toString() ?? '');
      score = (population != null && population > 100000) ? 65 : 45;
    } else if (poiTags.contains('unesco')) {
      score = 70; // UNESCO-Welterbe hoeher bewerten
    }

    return POI(
      id: 'osm-${data['type']}-${data['id']}',
      name: tags['name'] ?? 'Unbekannt',
      latitude: lat,
      longitude: lng,
      categoryId: category,
      score: score,
      website: tags['website'],
      phone: tags['phone'],
      openingHours: tags['opening_hours'],
      imageUrl: imageUrl,
      wikidataId: wikidataTag,
      wikipediaTitle: wpTitle,
      hasWikipedia: wpTitle != null,
      hasWikidataData: tags['website'] != null || tags['phone'] != null || wikidataTag != null,
      tags: poiTags,
    );
  }
}

/// Riverpod Provider für POIRepository
/// OPTIMIERT: Mit Cache-Service für Region-Caching
@riverpod
POIRepository poiRepository(PoiRepositoryRef ref) {
  final cacheService = ref.watch(poiCacheServiceProvider);
  return POIRepository(cacheService: cacheService);
}
