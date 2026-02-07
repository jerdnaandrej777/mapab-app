import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/poi.dart';

/// Repository fuer POI-Operationen gegen Supabase PostGIS
///
/// Stellt Methoden bereit zum:
/// - Laden von POIs via PostGIS-Queries (Radius, Bounds)
/// - Hochladen von angereicherten POIs (Crowdsourced Enrichment)
class SupabasePOIRepository {
  final SupabaseClient _client;

  /// Max gleichzeitige Uploads
  static const int _maxConcurrentUploads = 10;

  SupabasePOIRepository(this._client);

  // ============================================
  // QUERY-METHODEN
  // ============================================

  /// Laedt POIs in einem Radius um einen Punkt
  /// Nutzt PostGIS ST_DWithin via RPC-Funktion
  Future<List<POI>> loadPOIsInRadius({
    required double latitude,
    required double longitude,
    required double radiusKm,
    List<String>? categoryFilter,
    int minScore = 35,
    int limit = 200,
  }) async {
    final stopwatch = Stopwatch()..start();
    final normalizedCategoryFilter = _normalizeCategoryFilter(categoryFilter);

    try {
      final response = await _client.rpc('search_pois_in_radius', params: {
        'p_lat': latitude,
        'p_lng': longitude,
        'p_radius_km': radiusKm,
        'p_category_ids': normalizedCategoryFilter,
        'p_min_score': minScore,
        'p_limit': limit,
      });

      final rows = response as List<dynamic>;
      final pois =
          rows.map((row) => _parsePOIRow(row as Map<String, dynamic>)).toList();

      stopwatch.stop();
      debugPrint(
          '[POI-Supabase] Radius-Query: ${pois.length} POIs in ${stopwatch.elapsedMilliseconds}ms '
          '(lat=$latitude, lng=$longitude, r=${radiusKm}km)');

      return pois;
    } catch (e) {
      stopwatch.stop();
      debugPrint(
          '[POI-Supabase] Radius-Query FEHLER (${stopwatch.elapsedMilliseconds}ms): $e');
      rethrow;
    }
  }

  /// Laedt POIs innerhalb einer Bounding Box
  /// Nutzt PostGIS ST_Within via RPC-Funktion
  Future<List<POI>> loadPOIsInBounds({
    required double swLat,
    required double swLng,
    required double neLat,
    required double neLng,
    List<String>? categoryFilter,
    int minScore = 35,
    int limit = 200,
  }) async {
    final stopwatch = Stopwatch()..start();
    final normalizedCategoryFilter = _normalizeCategoryFilter(categoryFilter);

    try {
      final response = await _client.rpc('search_pois_in_bounds', params: {
        'p_sw_lat': swLat,
        'p_sw_lng': swLng,
        'p_ne_lat': neLat,
        'p_ne_lng': neLng,
        'p_category_ids': normalizedCategoryFilter,
        'p_min_score': minScore,
        'p_limit': limit,
      });

      final rows = response as List<dynamic>;
      final pois =
          rows.map((row) => _parsePOIRow(row as Map<String, dynamic>)).toList();

      stopwatch.stop();
      debugPrint(
          '[POI-Supabase] Bounds-Query: ${pois.length} POIs in ${stopwatch.elapsedMilliseconds}ms');

      return pois;
    } catch (e) {
      stopwatch.stop();
      debugPrint(
          '[POI-Supabase] Bounds-Query FEHLER (${stopwatch.elapsedMilliseconds}ms): $e');
      rethrow;
    }
  }

  List<String>? _normalizeCategoryFilter(List<String>? categoryFilter) {
    if (categoryFilter == null || categoryFilter.isEmpty) return null;
    const alias = <String, String>{
      'parks': 'park',
      'nationalpark': 'park',
      'natur': 'nature',
      'seen': 'lake',
      'strand': 'coast',
      'kueste': 'coast',
      'küste': 'coast',
      'aussicht': 'viewpoint',
      'stadt': 'city',
      'schloss': 'castle',
      'burgen': 'castle',
      'kirchen': 'church',
      'denkmal': 'monument',
      'attraktionen': 'attraction',
      'hotels': 'hotel',
      'restaurants': 'restaurant',
    };
    final normalized = categoryFilter
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .map((e) => alias[e] ?? e)
        .toSet()
        .toList();
    return normalized.isEmpty ? null : normalized;
  }

  // ============================================
  // UPLOAD-METHODEN
  // ============================================

  /// Laedt einen einzelnen angereicherten POI hoch (Upsert)
  Future<void> uploadEnrichedPOI(POI poi) async {
    try {
      await _client.rpc('upsert_poi', params: _poiToRpcParams(poi));
      debugPrint('[POI-Upload] Hochgeladen: ${poi.name} (${poi.id})');
    } catch (e) {
      debugPrint('[POI-Upload] FEHLER bei ${poi.name}: $e');
    }
  }

  /// Laedt mehrere angereicherte POIs hoch (Batch, max 10 concurrent)
  Future<void> uploadEnrichedPOIsBatch(List<POI> pois) async {
    if (pois.isEmpty) return;

    debugPrint('[POI-Upload] Batch-Upload: ${pois.length} POIs');
    final stopwatch = Stopwatch()..start();

    int success = 0;
    int errors = 0;

    // Semaphore fuer Concurrency-Limit
    final futures = <Future<void>>[];
    int active = 0;

    for (final poi in pois) {
      // Warten bis ein Slot frei wird
      while (active >= _maxConcurrentUploads) {
        await Future.any(futures);
      }

      active++;
      final future =
          _client.rpc('upsert_poi', params: _poiToRpcParams(poi)).then((_) {
        success++;
      }).catchError((e) {
        errors++;
        debugPrint('[POI-Upload] FEHLER bei ${poi.name}: $e');
      }).whenComplete(() {
        active--;
      });

      futures.add(future);
    }

    // Auf alle restlichen warten
    await Future.wait(futures);

    stopwatch.stop();
    debugPrint(
        '[POI-Upload] Batch fertig: $success OK, $errors Fehler in ${stopwatch.elapsedMilliseconds}ms');
  }

  // ============================================
  // MAPPING
  // ============================================

  /// Konvertiert eine Supabase-Row (snake_case) in ein POI-Objekt (camelCase)
  POI _parsePOIRow(Map<String, dynamic> row) {
    return POI(
      id: row['id'] as String,
      name: row['name'] as String,
      latitude: (row['latitude'] as num).toDouble(),
      longitude: (row['longitude'] as num).toDouble(),
      categoryId: row['category_id'] as String? ?? 'attraction',
      score: row['score'] as int? ?? 50,
      imageUrl: row['image_url'] as String?,
      thumbnailUrl: row['thumbnail_url'] as String?,
      description: row['description'] as String?,
      isCurated: row['is_curated'] as bool? ?? false,
      hasWikipedia: row['has_wikipedia'] as bool? ?? false,
      wikipediaTitle: row['wikipedia_title'] as String?,
      tags: (row['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      wikidataId: row['wikidata_id'] as String?,
      wikidataDescription: row['wikidata_description'] as String?,
      hasWikidataData: row['has_wikidata_data'] as bool? ?? false,
      phone: row['phone'] as String?,
      email: row['email'] as String?,
      website: row['website'] as String?,
      openingHours: row['opening_hours'] as String?,
      foundedYear: row['founded_year'] as int?,
      architectureStyle: row['architecture_style'] as String?,
      isEnriched: row['is_enriched'] as bool? ?? false,
    );
  }

  /// Konvertiert ein POI-Objekt in RPC-Parameter fuer upsert_poi
  Map<String, dynamic> _poiToRpcParams(POI poi) {
    // User-ID fuer contributed_by / enriched_by
    final userId = _client.auth.currentUser?.id;

    return {
      'p_id': poi.id,
      'p_name': poi.name,
      'p_latitude': poi.latitude,
      'p_longitude': poi.longitude,
      'p_category_id': poi.categoryId,
      'p_score': poi.score,
      'p_image_url': poi.imageUrl,
      'p_thumbnail_url': poi.thumbnailUrl,
      'p_description': poi.description ?? poi.wikidataDescription,
      'p_is_curated': poi.isCurated,
      'p_has_wikipedia': poi.hasWikipedia,
      'p_wikipedia_title': poi.wikipediaTitle,
      'p_tags': poi.tags,
      'p_wikidata_id': poi.wikidataId,
      'p_wikidata_description': poi.wikidataDescription,
      'p_has_wikidata_data': poi.hasWikidataData,
      'p_phone': poi.phone,
      'p_email': poi.email,
      'p_website': poi.website,
      'p_opening_hours': poi.openingHours,
      'p_founded_year': poi.foundedYear,
      'p_architecture_style': poi.architectureStyle,
      'p_is_enriched': poi.isEnriched,
      'p_source': poi.isCurated
          ? 'curated'
          : poi.hasWikipedia
              ? 'wikipedia'
              : poi.id.startsWith('osm-')
                  ? 'overpass'
                  : 'unknown',
      'p_contributed_by': userId,
    };
  }
}
