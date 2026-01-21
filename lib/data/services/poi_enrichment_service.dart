import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/constants/api_endpoints.dart';
import '../models/poi.dart';
import 'poi_cache_service.dart';

part 'poi_enrichment_service.g.dart';

/// Enrichment-Daten von externen APIs
class POIEnrichmentData {
  final String? imageUrl;
  final String? thumbnailUrl;
  final String? description;
  final String? wikidataId;
  final bool isUnesco;
  final bool isHistoric;
  final int? foundedYear;
  final String? architectureStyle;
  final List<String> additionalImages;

  const POIEnrichmentData({
    this.imageUrl,
    this.thumbnailUrl,
    this.description,
    this.wikidataId,
    this.isUnesco = false,
    this.isHistoric = false,
    this.foundedYear,
    this.architectureStyle,
    this.additionalImages = const [],
  });

  bool get hasImage => imageUrl != null;
  bool get hasDescription => description != null && description!.isNotEmpty;
  bool get isEmpty => !hasImage && !hasDescription;
}

/// Service zur Anreicherung von POIs mit Wikipedia, Wikimedia Commons und Wikidata
class POIEnrichmentService {
  final Dio _dio;
  final POICacheService? _cacheService;

  POIEnrichmentService({Dio? dio, POICacheService? cacheService})
      : _dio = dio ??
            Dio(BaseOptions(
              headers: {'User-Agent': ApiConfig.userAgent},
              connectTimeout: const Duration(milliseconds: ApiConfig.defaultTimeout),
              receiveTimeout: const Duration(milliseconds: ApiConfig.defaultTimeout),
            )),
        _cacheService = cacheService;

  /// Reichert einen POI mit externen Daten an
  /// Versucht nacheinander: Cache → Wikipedia Extracts → Wikimedia Commons → Wikidata
  Future<POI> enrichPOI(POI poi) async {
    debugPrint('[Enrichment] Starte Enrichment für: ${poi.name}');

    // 1. Zuerst Cache prüfen
    final cacheService = _cacheService;
    if (cacheService != null) {
      final cachedPOI = await cacheService.getCachedEnrichedPOI(poi.id);
      if (cachedPOI != null) {
        debugPrint('[Enrichment] Cache-Treffer für: ${poi.name}');
        return cachedPOI;
      }
    }

    POIEnrichmentData enrichment = const POIEnrichmentData();

    // 1. Wikipedia Extracts (Beschreibung + Hauptbild)
    if (poi.hasWikipedia && poi.wikipediaTitle != null) {
      final wikiData = await _fetchWikipediaExtract(poi.wikipediaTitle!);
      if (wikiData != null) {
        enrichment = POIEnrichmentData(
          imageUrl: wikiData['imageUrl'],
          thumbnailUrl: wikiData['thumbnailUrl'],
          description: wikiData['description'],
          wikidataId: wikiData['wikidataId'],
        );
        debugPrint('[Enrichment] Wikipedia-Daten geladen: ${enrichment.hasImage ? "Bild ✓" : "kein Bild"}, ${enrichment.hasDescription ? "Beschreibung ✓" : "keine Beschreibung"}');
      }
    }

    // 2. Wikimedia Commons Fallback (falls kein Bild)
    if (!enrichment.hasImage) {
      final commonsImage = await _fetchWikimediaCommonsImage(
        poi.latitude,
        poi.longitude,
        poi.name,
      );
      if (commonsImage != null) {
        enrichment = POIEnrichmentData(
          imageUrl: commonsImage,
          thumbnailUrl: enrichment.thumbnailUrl,
          description: enrichment.description,
          wikidataId: enrichment.wikidataId,
          isUnesco: enrichment.isUnesco,
          isHistoric: enrichment.isHistoric,
          foundedYear: enrichment.foundedYear,
          architectureStyle: enrichment.architectureStyle,
        );
        debugPrint('[Enrichment] Wikimedia Commons Bild gefunden');
      }
    }

    // 3. Wikidata für strukturierte Daten (falls Wikidata-ID vorhanden)
    if (enrichment.wikidataId != null) {
      final wikidataInfo = await _fetchWikidataInfo(enrichment.wikidataId!);
      if (wikidataInfo != null) {
        enrichment = POIEnrichmentData(
          imageUrl: enrichment.imageUrl ?? wikidataInfo['imageUrl'],
          thumbnailUrl: enrichment.thumbnailUrl,
          description: enrichment.description ?? wikidataInfo['description'],
          wikidataId: enrichment.wikidataId,
          isUnesco: wikidataInfo['isUnesco'] ?? false,
          isHistoric: wikidataInfo['isHistoric'] ?? false,
          foundedYear: wikidataInfo['foundedYear'],
          architectureStyle: wikidataInfo['architectureStyle'],
        );
        debugPrint('[Enrichment] Wikidata-Daten geladen: UNESCO=${enrichment.isUnesco}');
      }
    }

    // POI mit Enrichment-Daten aktualisieren
    final enrichedPOI = _applyEnrichment(poi, enrichment);

    // Im Cache speichern
    if (cacheService != null && !enrichment.isEmpty) {
      await cacheService.cacheEnrichedPOI(enrichedPOI);
    }

    return enrichedPOI;
  }

  /// Lädt Wikipedia Extract (Intro-Text und Hauptbild)
  Future<Map<String, dynamic>?> _fetchWikipediaExtract(String title) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.wikipediaGeoSearch,
        queryParameters: {
          'action': 'query',
          'titles': title,
          'prop': 'extracts|pageimages|pageprops',
          'exintro': 'true',
          'explaintext': 'true',
          'piprop': 'original|thumbnail',
          'pithumbsize': 400,
          'ppprop': 'wikibase_item',
          'format': 'json',
          'origin': '*',
        },
      );

      final pages = response.data['query']?['pages'] as Map<String, dynamic>?;
      if (pages == null || pages.isEmpty) return null;

      final page = pages.values.first as Map<String, dynamic>;
      if (page['pageid'] == null) return null;

      return {
        'description': page['extract'],
        'imageUrl': page['original']?['source'],
        'thumbnailUrl': page['thumbnail']?['source'],
        'wikidataId': page['pageprops']?['wikibase_item'],
      };
    } on DioException catch (e) {
      debugPrint('[Enrichment] Wikipedia Extract Fehler: ${e.message}');
      return null;
    }
  }

  /// Sucht Bilder in Wikimedia Commons per Geo-Suche
  Future<String?> _fetchWikimediaCommonsImage(
    double lat,
    double lng,
    String name,
  ) async {
    try {
      // Methode 1: Geo-basierte Suche
      final geoResponse = await _dio.get(
        ApiEndpoints.wikimediaCommons,
        queryParameters: {
          'action': 'query',
          'generator': 'geosearch',
          'ggscoord': '$lat|$lng',
          'ggsradius': '500', // 500m Radius
          'ggslimit': '5',
          'prop': 'imageinfo',
          'iiprop': 'url',
          'iiurlwidth': '800',
          'format': 'json',
          'origin': '*',
        },
      );

      final pages = geoResponse.data['query']?['pages'] as Map<String, dynamic>?;
      if (pages != null && pages.isNotEmpty) {
        for (final page in pages.values) {
          final imageInfo = (page['imageinfo'] as List?)?.firstOrNull;
          if (imageInfo != null) {
            final url = imageInfo['thumburl'] ?? imageInfo['url'];
            if (url != null && _isValidImageUrl(url)) {
              return url;
            }
          }
        }
      }

      // Methode 2: Titel-basierte Suche als Fallback
      final searchResponse = await _dio.get(
        ApiEndpoints.wikimediaCommons,
        queryParameters: {
          'action': 'query',
          'generator': 'search',
          'gsrsearch': 'File:$name',
          'gsrnamespace': '6', // File namespace
          'gsrlimit': '3',
          'prop': 'imageinfo',
          'iiprop': 'url',
          'iiurlwidth': '800',
          'format': 'json',
          'origin': '*',
        },
      );

      final searchPages = searchResponse.data['query']?['pages'] as Map<String, dynamic>?;
      if (searchPages != null && searchPages.isNotEmpty) {
        for (final page in searchPages.values) {
          final imageInfo = (page['imageinfo'] as List?)?.firstOrNull;
          if (imageInfo != null) {
            final url = imageInfo['thumburl'] ?? imageInfo['url'];
            if (url != null && _isValidImageUrl(url)) {
              return url;
            }
          }
        }
      }

      return null;
    } on DioException catch (e) {
      debugPrint('[Enrichment] Wikimedia Commons Fehler: ${e.message}');
      return null;
    }
  }

  /// Lädt strukturierte Daten von Wikidata
  Future<Map<String, dynamic>?> _fetchWikidataInfo(String wikidataId) async {
    try {
      // SPARQL Query für relevante Eigenschaften
      final query = '''
SELECT ?image ?heritageStatus ?inception ?archStyle ?archStyleLabel WHERE {
  BIND(wd:$wikidataId AS ?item)

  OPTIONAL { ?item wdt:P18 ?image. }
  OPTIONAL { ?item wdt:P1435 ?heritageStatus. }
  OPTIONAL { ?item wdt:P571 ?inception. }
  OPTIONAL {
    ?item wdt:P149 ?archStyle.
    ?archStyle rdfs:label ?archStyleLabel.
    FILTER(LANG(?archStyleLabel) = "de")
  }
}
LIMIT 1
''';

      final response = await _dio.get(
        ApiEndpoints.wikidataSparql,
        queryParameters: {
          'query': query,
          'format': 'json',
        },
        options: Options(
          headers: {'Accept': 'application/sparql-results+json'},
        ),
      );

      final bindings = response.data['results']?['bindings'] as List?;
      if (bindings == null || bindings.isEmpty) return null;

      final result = bindings.first as Map<String, dynamic>;

      // Prüfen auf UNESCO-Welterbe (P1435 = Q9259 oder ähnliche)
      final heritageStatus = result['heritageStatus']?['value'] as String?;
      final isUnesco = heritageStatus != null &&
          (heritageStatus.contains('Q9259') || // UNESCO-Welterbe
              heritageStatus.contains('Q54958') || // UNESCO-Welterbe (Teil)
              heritageStatus.contains('Q744913')); // Nationales Denkmal

      // Gründungsjahr extrahieren
      int? foundedYear;
      final inception = result['inception']?['value'] as String?;
      if (inception != null) {
        final match = RegExp(r'(\d{4})').firstMatch(inception);
        if (match != null) {
          foundedYear = int.tryParse(match.group(1)!);
        }
      }

      return {
        'imageUrl': result['image']?['value'],
        'isUnesco': isUnesco,
        'isHistoric': heritageStatus != null,
        'foundedYear': foundedYear,
        'architectureStyle': result['archStyleLabel']?['value'],
      };
    } on DioException catch (e) {
      debugPrint('[Enrichment] Wikidata Fehler: ${e.message}');
      return null;
    }
  }

  /// Lädt mehrere Bilder von Wikimedia Commons für eine Location
  Future<List<String>> fetchMultipleImages(
    double lat,
    double lng, {
    int limit = 5,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.wikimediaCommons,
        queryParameters: {
          'action': 'query',
          'generator': 'geosearch',
          'ggscoord': '$lat|$lng',
          'ggsradius': '1000', // 1km Radius
          'ggslimit': limit.toString(),
          'prop': 'imageinfo',
          'iiprop': 'url',
          'iiurlwidth': '800',
          'format': 'json',
          'origin': '*',
        },
      );

      final pages = response.data['query']?['pages'] as Map<String, dynamic>?;
      if (pages == null || pages.isEmpty) return [];

      final images = <String>[];
      for (final page in pages.values) {
        final imageInfo = (page['imageinfo'] as List?)?.firstOrNull;
        if (imageInfo != null) {
          final url = imageInfo['thumburl'] ?? imageInfo['url'];
          if (url != null && _isValidImageUrl(url)) {
            images.add(url);
          }
        }
      }
      return images;
    } on DioException catch (e) {
      debugPrint('[Enrichment] Mehrfach-Bilder Fehler: ${e.message}');
      return [];
    }
  }

  /// Wendet Enrichment-Daten auf POI an
  POI _applyEnrichment(POI poi, POIEnrichmentData enrichment) {
    // Tags aktualisieren basierend auf Enrichment
    final updatedTags = List<String>.from(poi.tags);
    if (enrichment.isUnesco && !updatedTags.contains('unesco')) {
      updatedTags.add('unesco');
    }
    if (enrichment.isHistoric && !updatedTags.contains('historic')) {
      updatedTags.add('historic');
    }

    return poi.copyWith(
      imageUrl: poi.imageUrl ?? enrichment.imageUrl,
      description: poi.description ?? enrichment.description,
      wikidataId: poi.wikidataId ?? enrichment.wikidataId,
      tags: updatedTags,
    );
  }

  /// Prüft ob URL ein gültiges Bild ist
  bool _isValidImageUrl(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.contains('/thumb/');
  }
}

/// Riverpod Provider für POIEnrichmentService
@riverpod
POIEnrichmentService poiEnrichmentService(Ref ref) {
  final cacheService = ref.watch(poiCacheServiceProvider);
  return POIEnrichmentService(cacheService: cacheService);
}
