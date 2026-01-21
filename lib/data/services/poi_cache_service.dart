import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/poi.dart';

part 'poi_cache_service.g.dart';

/// Cache-Eintrag für POI mit Timestamp
class CachedPOI {
  final POI poi;
  final DateTime cachedAt;

  CachedPOI({required this.poi, DateTime? cachedAt})
      : cachedAt = cachedAt ?? DateTime.now();

  /// Prüft ob Cache-Eintrag abgelaufen ist
  bool isExpired(Duration maxAge) {
    return DateTime.now().difference(cachedAt) > maxAge;
  }

  /// Konvertiert zu JSON für Hive-Speicherung
  Map<String, dynamic> toJson() => {
        'poi': poi.toJson(),
        'cachedAt': cachedAt.toIso8601String(),
      };

  /// Erstellt CachedPOI aus JSON
  factory CachedPOI.fromJson(Map<String, dynamic> json) {
    return CachedPOI(
      poi: POI.fromJson(json['poi'] as Map<String, dynamic>),
      cachedAt: DateTime.parse(json['cachedAt'] as String),
    );
  }
}

/// Service zur Caching von angereicherten POIs
class POICacheService {
  static const String _boxName = 'poi_cache';
  static const String _enrichedBoxName = 'enriched_pois';

  Box<String>? _box;
  Box<String>? _enrichedBox;

  /// Cache-Dauer für verschiedene Datentypen
  static const Duration poiCacheDuration = Duration(days: 7);
  static const Duration enrichmentCacheDuration = Duration(days: 30);

  /// Initialisiert den Cache
  Future<void> init() async {
    if (_box != null) return;

    _box = await Hive.openBox<String>(_boxName);
    _enrichedBox = await Hive.openBox<String>(_enrichedBoxName);
    debugPrint('[POICache] Initialisiert');
  }

  /// Speichert einen angereicherten POI
  Future<void> cacheEnrichedPOI(POI poi) async {
    await init();
    if (_enrichedBox == null) return;

    final cached = CachedPOI(poi: poi);
    await _enrichedBox!.put(poi.id, jsonEncode(cached.toJson()));
    debugPrint('[POICache] POI gecached: ${poi.name}');
  }

  /// Lädt einen gecachten angereicherten POI
  Future<POI?> getCachedEnrichedPOI(String poiId) async {
    await init();
    if (_enrichedBox == null) return null;

    final jsonStr = _enrichedBox!.get(poiId);
    if (jsonStr == null) return null;

    try {
      final cached = CachedPOI.fromJson(jsonDecode(jsonStr));

      // Prüfen ob abgelaufen
      if (cached.isExpired(enrichmentCacheDuration)) {
        await _enrichedBox!.delete(poiId);
        debugPrint('[POICache] Cache abgelaufen: $poiId');
        return null;
      }

      debugPrint('[POICache] Cache-Treffer: ${cached.poi.name}');
      return cached.poi;
    } catch (e) {
      debugPrint('[POICache] Fehler beim Laden: $e');
      await _enrichedBox!.delete(poiId);
      return null;
    }
  }

  /// Speichert mehrere POIs (für Bereichs-Cache)
  Future<void> cachePOIs(List<POI> pois, String regionKey) async {
    await init();
    if (_box == null) return;

    final cached = pois.map((poi) => CachedPOI(poi: poi)).toList();
    final jsonList = cached.map((c) => c.toJson()).toList();
    await _box!.put(regionKey, jsonEncode(jsonList));

    debugPrint('[POICache] ${pois.length} POIs für Region "$regionKey" gecached');
  }

  /// Lädt gecachte POIs für eine Region
  Future<List<POI>?> getCachedPOIs(String regionKey) async {
    await init();
    if (_box == null) return null;

    final jsonStr = _box!.get(regionKey);
    if (jsonStr == null) return null;

    try {
      final jsonList = jsonDecode(jsonStr) as List;
      final cachedList = jsonList
          .map((json) => CachedPOI.fromJson(json as Map<String, dynamic>))
          .toList();

      // Prüfen ob irgendein Eintrag abgelaufen ist
      if (cachedList.any((c) => c.isExpired(poiCacheDuration))) {
        await _box!.delete(regionKey);
        debugPrint('[POICache] Region-Cache abgelaufen: $regionKey');
        return null;
      }

      final pois = cachedList.map((c) => c.poi).toList();
      debugPrint('[POICache] ${pois.length} POIs aus Cache geladen: $regionKey');
      return pois;
    } catch (e) {
      debugPrint('[POICache] Fehler beim Laden der Region: $e');
      await _box!.delete(regionKey);
      return null;
    }
  }

  /// Erstellt einen Region-Key aus Koordinaten
  String createRegionKey(double lat, double lng, double radiusKm) {
    // Runde auf 1 Dezimalstelle für besseres Caching
    final roundedLat = (lat * 10).round() / 10;
    final roundedLng = (lng * 10).round() / 10;
    final roundedRadius = radiusKm.round();
    return 'region_${roundedLat}_${roundedLng}_${roundedRadius}km';
  }

  /// Prüft ob ein POI gecached ist
  Future<bool> isEnrichedCached(String poiId) async {
    await init();
    if (_enrichedBox == null) return false;
    return _enrichedBox!.containsKey(poiId);
  }

  /// Löscht abgelaufene Cache-Einträge
  Future<void> cleanExpiredCache() async {
    await init();

    int deletedCount = 0;

    // Enriched POIs bereinigen
    if (_enrichedBox != null) {
      final keysToDelete = <String>[];
      for (final key in _enrichedBox!.keys) {
        final jsonStr = _enrichedBox!.get(key);
        if (jsonStr != null) {
          try {
            final cached = CachedPOI.fromJson(jsonDecode(jsonStr));
            if (cached.isExpired(enrichmentCacheDuration)) {
              keysToDelete.add(key);
            }
          } catch (_) {
            keysToDelete.add(key);
          }
        }
      }
      for (final key in keysToDelete) {
        await _enrichedBox!.delete(key);
        deletedCount++;
      }
    }

    // Region-Cache bereinigen
    if (_box != null) {
      final keysToDelete = <String>[];
      for (final key in _box!.keys) {
        final jsonStr = _box!.get(key);
        if (jsonStr != null) {
          try {
            final jsonList = jsonDecode(jsonStr) as List;
            if (jsonList.isNotEmpty) {
              final cached = CachedPOI.fromJson(jsonList.first);
              if (cached.isExpired(poiCacheDuration)) {
                keysToDelete.add(key);
              }
            }
          } catch (_) {
            keysToDelete.add(key);
          }
        }
      }
      for (final key in keysToDelete) {
        await _box!.delete(key);
        deletedCount++;
      }
    }

    debugPrint('[POICache] $deletedCount abgelaufene Einträge gelöscht');
  }

  /// Löscht den gesamten Cache
  Future<void> clearAll() async {
    await init();
    await _box?.clear();
    await _enrichedBox?.clear();
    debugPrint('[POICache] Cache komplett gelöscht');
  }

  /// Gibt Cache-Statistiken zurück
  Future<Map<String, int>> getStats() async {
    await init();
    return {
      'regions': _box?.length ?? 0,
      'enrichedPOIs': _enrichedBox?.length ?? 0,
    };
  }
}

/// Riverpod Provider für POICacheService
@Riverpod(keepAlive: true)
POICacheService poiCacheService(PoiCacheServiceRef ref) {
  final service = POICacheService();
  // Auto-Init im Hintergrund
  service.init();
  return service;
}
