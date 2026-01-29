import 'dart:async';
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

  /// Merged zwei POIEnrichmentData Objekte
  POIEnrichmentData merge(POIEnrichmentData other) {
    return POIEnrichmentData(
      imageUrl: imageUrl ?? other.imageUrl,
      thumbnailUrl: thumbnailUrl ?? other.thumbnailUrl,
      description: description ?? other.description,
      wikidataId: wikidataId ?? other.wikidataId,
      isUnesco: isUnesco || other.isUnesco,
      isHistoric: isHistoric || other.isHistoric,
      foundedYear: foundedYear ?? other.foundedYear,
      architectureStyle: architectureStyle ?? other.architectureStyle,
      additionalImages: [...additionalImages, ...other.additionalImages],
    );
  }
}

/// Service zur Anreicherung von POIs mit Wikipedia, Wikimedia Commons und Wikidata
/// OPTIMIERT v1.3.7: Parallele API-Calls, Retry-Logik, Concurrency-Limits
class POIEnrichmentService {
  final Dio _dio;
  final POICacheService? _cacheService;

  /// Concurrency-Limit: Max 3 gleichzeitige Enrichments (reduziert von 5 für Rate-Limit-Schutz)
  static const int _maxConcurrentEnrichments = 3;
  static int _activeEnrichments = 0;
  static final List<Completer<void>> _waitQueue = [];

  /// Timeout für Enrichment-Requests (länger als default)
  static const int _enrichmentTimeout = 25000; // 25 Sekunden

  /// Retry-Konfiguration
  static const int _maxRetries = 3;
  static const Duration _baseRetryDelay = Duration(milliseconds: 500);

  /// Minimale Pause zwischen API-Calls (Rate-Limit-Schutz)
  static const Duration _apiCallDelay = Duration(milliseconds: 200);

  /// Set für aktuell laufende Enrichments (verhindert Doppel-Requests)
  static final Set<String> _enrichingPOIs = {};

  /// Completer-Map für wartende Enrichment-Requests (Race Condition Fix)
  static final Map<String, Completer<POI>> _enrichmentCompleters = {};

  POIEnrichmentService({Dio? dio, POICacheService? cacheService})
      : _dio = dio ??
            Dio(BaseOptions(
              headers: {'User-Agent': ApiConfig.userAgent},
              connectTimeout: const Duration(milliseconds: _enrichmentTimeout),
              receiveTimeout: const Duration(milliseconds: _enrichmentTimeout),
            )),
        _cacheService = cacheService;

  /// FIX v1.5.3: Setzt alle static States zurück (für Clean Start nach Hot-Reload)
  static void resetStaticState() {
    debugPrint('[Enrichment] Static State wird zurückgesetzt');
    _activeEnrichments = 0;
    _waitQueue.clear();
    _enrichingPOIs.clear();
    _enrichmentCompleters.clear();
  }

  /// Prüft ob ein POI gerade enriched wird
  bool isEnriching(String poiId) => _enrichingPOIs.contains(poiId);

  /// Wartet auf freien Slot im Concurrency-Pool
  Future<void> _acquireSlot() async {
    if (_activeEnrichments < _maxConcurrentEnrichments) {
      _activeEnrichments++;
      return;
    }

    final completer = Completer<void>();
    _waitQueue.add(completer);
    await completer.future;
    _activeEnrichments++;
  }

  /// Gibt Slot im Concurrency-Pool frei
  void _releaseSlot() {
    _activeEnrichments--;
    if (_waitQueue.isNotEmpty) {
      final next = _waitQueue.removeAt(0);
      next.complete();
    }
  }

  /// Führt einen Request mit Retry-Logik aus
  /// FIX v1.6.6: Erweitertes Logging mit Statuscode und Rate-Limit-Handling
  Future<Response<dynamic>?> _requestWithRetry(
    String url,
    Map<String, dynamic> queryParameters, {
    Options? options,
  }) async {
    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        final response = await _dio.get(
          url,
          queryParameters: queryParameters,
          options: options,
        );

        // Erfolgreiche Antwort prüfen
        if (response.statusCode == 200) {
          return response;
        }

        // Unerwarteter Statuscode loggen
        debugPrint('[Enrichment] ⚠️ Unerwarteter Statuscode ${response.statusCode} von $url');
        return null;

      } on DioException catch (e) {
        final statusCode = e.response?.statusCode;
        final isLastAttempt = attempt == _maxRetries - 1;

        // Rate-Limit spezifisch behandeln (zählt nicht als Versuch)
        if (statusCode == 429) {
          debugPrint('[Enrichment] ⚠️ Rate-Limit (429) erreicht! Warte 5 Sekunden...');
          await Future.delayed(const Duration(seconds: 5));
          continue;
        }

        // Detailliertes Logging bei Fehler
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          debugPrint('[Enrichment] ⏱️ Timeout bei Versuch ${attempt + 1}: $url');
        } else {
          debugPrint('[Enrichment] ❌ API-Fehler: Status=$statusCode, Typ=${e.type}, URL=$url');
        }

        if (isLastAttempt) {
          debugPrint('[Enrichment] ❌ Alle $_maxRetries Versuche fehlgeschlagen: ${e.message}');
          return null;
        }

        // Exponential Backoff
        final delay = _baseRetryDelay * (attempt + 1);
        debugPrint('[Enrichment] Retry ${attempt + 1}/$_maxRetries nach ${delay.inMilliseconds}ms');
        await Future.delayed(delay);
      }
    }
    return null;
  }

  /// Reichert einen POI mit externen Daten an
  /// OPTIMIERT: Parallele API-Calls, Retry-Logik, Concurrency-Limits
  /// FIX v1.3.8: Race Condition behoben - wartet auf laufendes Enrichment
  Future<POI> enrichPOI(POI poi) async {
    // Bei laufendem Enrichment auf Ergebnis warten statt ungereichertes POI zurückgeben
    if (_enrichingPOIs.contains(poi.id)) {
      debugPrint('[Enrichment] Warte auf laufendes Enrichment: ${poi.name}');
      final completer = _enrichmentCompleters[poi.id];
      if (completer != null) {
        try {
          return await completer.future.timeout(
            const Duration(seconds: 30),
            onTimeout: () => poi, // Bei Timeout das Original zurückgeben
          );
        } catch (e) {
          debugPrint('[Enrichment] Warten fehlgeschlagen: $e');
          return poi;
        }
      }
      // Fallback: Kurz warten und Cache prüfen
      await Future.delayed(const Duration(seconds: 2));
      if (_cacheService != null) {
        final cached = await _cacheService!.getCachedEnrichedPOI(poi.id);
        if (cached != null) return cached;
      }
      return poi;
    }

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

    // Auf freien Slot warten und POI als "in Arbeit" markieren
    await _acquireSlot();
    _enrichingPOIs.add(poi.id);

    // Completer für wartende Requests erstellen
    final completer = Completer<POI>();
    _enrichmentCompleters[poi.id] = completer;

    try {
      POIEnrichmentData enrichment = const POIEnrichmentData();

      // OPTIMIERUNG: Parallele API-Calls starten
      final futures = <Future<POIEnrichmentData?>>[];

      // 1. Wikipedia Extracts (Beschreibung + Hauptbild)
      if (poi.hasWikipedia && poi.wikipediaTitle != null) {
        futures.add(_fetchWikipediaEnrichment(poi.wikipediaTitle!));
      }

      // 2. Wikimedia Commons (parallel, nicht als Fallback)
      futures.add(_fetchWikimediaEnrichment(poi.latitude, poi.longitude, poi.name));

      // Alle parallelen Requests abwarten
      final results = await Future.wait(futures);

      // Ergebnisse zusammenführen (Wikipedia hat Priorität)
      for (final result in results) {
        if (result != null) {
          enrichment = enrichment.merge(result);
        }
      }

      debugPrint('[Enrichment] Parallel-Laden abgeschlossen: ${enrichment.hasImage ? "Bild ✓" : "kein Bild"}, ${enrichment.hasDescription ? "Beschreibung ✓" : "keine Beschreibung"}');

      // 3. EN-Wikipedia Fallback wenn kein Bild aus DE-Quellen
      // OPTIMIERT v1.7.6: Englische Wikipedia hat oft Bilder die in DE fehlen
      if (!enrichment.hasImage) {
        debugPrint('[Enrichment] Kein Bild aus DE-Quellen - versuche EN Wikipedia für: ${poi.name}');
        final enResult = await _fetchEnglishWikipediaImage(poi.name);
        if (enResult != null) {
          enrichment = enrichment.merge(enResult);
          debugPrint('[Enrichment] EN Wikipedia Bild gefunden: ${enResult.imageUrl}');
        }
      }

      // 4. Wikidata für strukturierte Daten und Fallback-Bild
      // OPTIMIERT v1.3.7: Wikidata auch ohne vorherige wikidataId versuchen (über POI-Name)
      String? wikidataIdToUse = enrichment.wikidataId;

      // Fallback: Wikidata-ID aus POI selbst nutzen
      if (wikidataIdToUse == null && poi.wikidataId != null) {
        wikidataIdToUse = poi.wikidataId;
      }

      if (wikidataIdToUse != null) {
        final wikidataInfo = await _fetchWikidataInfo(wikidataIdToUse);
        if (wikidataInfo != null) {
          // Wikidata-Bild als Fallback wenn kein anderes Bild vorhanden
          final wikidataImageUrl = wikidataInfo['imageUrl'] as String?;

          enrichment = POIEnrichmentData(
            imageUrl: enrichment.imageUrl ?? wikidataImageUrl,
            thumbnailUrl: enrichment.thumbnailUrl,
            description: enrichment.description ?? wikidataInfo['description'],
            wikidataId: wikidataIdToUse,
            isUnesco: wikidataInfo['isUnesco'] ?? false,
            isHistoric: wikidataInfo['isHistoric'] ?? false,
            foundedYear: wikidataInfo['foundedYear'],
            architectureStyle: wikidataInfo['architectureStyle'],
          );
          debugPrint('[Enrichment] Wikidata-Daten geladen: UNESCO=${enrichment.isUnesco}, Bild=${wikidataImageUrl != null}');
        }
      }

      // POI mit Enrichment-Daten aktualisieren
      final enrichedPOI = _applyEnrichment(poi, enrichment);

      // FIX v1.5.3: Im Cache speichern NUR wenn Bild vorhanden
      // Vorher wurden POIs mit Beschreibung aber ohne Bild gecacht,
      // wodurch das Bild nie erneut gesucht wurde (30 Tage Cache!)
      if (cacheService != null && enrichment.hasImage) {
        await cacheService.cacheEnrichedPOI(enrichedPOI);
        debugPrint('[Enrichment] POI mit Bild gecacht: ${poi.name}');
      } else if (!enrichment.hasImage) {
        debugPrint('[Enrichment] ⚠️ POI nicht gecacht (kein Bild): ${poi.name}');
      }

      // Wartende Requests benachrichtigen (Race Condition Fix)
      final pendingCompleter = _enrichmentCompleters[poi.id];
      if (pendingCompleter != null && !pendingCompleter.isCompleted) {
        pendingCompleter.complete(enrichedPOI);
      }

      return enrichedPOI;
    } catch (e) {
      // Bei Fehler den Completer mit Fehler auflösen
      final pendingCompleter = _enrichmentCompleters[poi.id];
      if (pendingCompleter != null && !pendingCompleter.isCompleted) {
        pendingCompleter.completeError(e);
      }
      rethrow;
    } finally {
      // Slot freigeben und POI aus "in Arbeit" entfernen
      _enrichingPOIs.remove(poi.id);
      _enrichmentCompleters.remove(poi.id);
      _releaseSlot();
    }
  }

  /// Lädt Wikipedia-Daten als POIEnrichmentData
  Future<POIEnrichmentData?> _fetchWikipediaEnrichment(String title) async {
    final data = await _fetchWikipediaExtract(title);
    if (data == null) return null;
    return POIEnrichmentData(
      imageUrl: data['imageUrl'],
      thumbnailUrl: data['thumbnailUrl'],
      description: data['description'],
      wikidataId: data['wikidataId'],
    );
  }

  /// Lädt Wikimedia-Daten als POIEnrichmentData
  Future<POIEnrichmentData?> _fetchWikimediaEnrichment(
    double lat,
    double lng,
    String name,
  ) async {
    final imageUrl = await _fetchWikimediaCommonsImage(lat, lng, name);
    if (imageUrl == null) return null;
    return POIEnrichmentData(imageUrl: imageUrl);
  }

  /// Lädt Wikipedia Extract (Intro-Text und Hauptbild)
  /// OPTIMIERT: Mit Retry-Logik
  Future<Map<String, dynamic>?> _fetchWikipediaExtract(String title) async {
    final response = await _requestWithRetry(
      ApiEndpoints.wikipediaGeoSearch,
      {
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

    if (response == null) return null;

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
  }

  /// Sucht Bilder in Wikimedia Commons per Geo-Suche
  /// OPTIMIERT v1.3.7: Größerer Radius (5000m), mehr Fallbacks, bessere Suche
  Future<String?> _fetchWikimediaCommonsImage(
    double lat,
    double lng,
    String name,
  ) async {
    // Methode 1: Geo-basierte Suche mit großem Radius
    final geoResponse = await _requestWithRetry(
      ApiEndpoints.wikimediaCommons,
      {
        'action': 'query',
        'generator': 'geosearch',
        'ggscoord': '$lat|$lng',
        'ggsradius': '10000', // OPTIMIERT: 10km Radius für mehr Treffer in ländlichen Gebieten
        'ggslimit': '15', // OPTIMIERT: Mehr Ergebnisse
        'prop': 'imageinfo',
        'iiprop': 'url|extmetadata',
        'iiurlwidth': '800',
        'format': 'json',
        'origin': '*',
      },
    );

    if (geoResponse != null) {
      final pages = geoResponse.data['query']?['pages'] as Map<String, dynamic>?;
      if (pages != null && pages.isNotEmpty) {
        // Bilder nach Relevanz filtern (Name im Titel bevorzugen)
        final sortedPages = pages.values.toList();
        sortedPages.sort((a, b) {
          final titleA = (a['title'] as String? ?? '').toLowerCase();
          final titleB = (b['title'] as String? ?? '').toLowerCase();
          final nameLower = name.toLowerCase();
          final containsA = titleA.contains(nameLower) ? 0 : 1;
          final containsB = titleB.contains(nameLower) ? 0 : 1;
          return containsA.compareTo(containsB);
        });

        for (final page in sortedPages) {
          final imageInfo = (page['imageinfo'] as List?)?.firstOrNull;
          if (imageInfo != null) {
            final url = imageInfo['thumburl'] ?? imageInfo['url'];
            if (url != null && _isValidImageUrl(url)) {
              debugPrint('[Enrichment] Wikimedia Geo-Bild gefunden: ${page['title']}');
              return url;
            }
          }
        }
      }
    }

    // Rate-Limit-Schutz: Kurze Pause zwischen API-Calls
    await Future.delayed(_apiCallDelay);

    // Methode 2: Titel-basierte Suche mit Suchvarianten
    // OPTIMIERT v1.7.6: Mehrere Varianten probieren (Umlaute, Präfix-Wörter)
    final searchVariants = _getSearchVariants(name);
    for (final variant in searchVariants) {
      final searchResponse = await _requestWithRetry(
        ApiEndpoints.wikimediaCommons,
        {
          'action': 'query',
          'generator': 'search',
          'gsrsearch': 'File:$variant',
          'gsrnamespace': '6', // File namespace
          'gsrlimit': '10',
          'prop': 'imageinfo',
          'iiprop': 'url',
          'iiurlwidth': '800',
          'format': 'json',
          'origin': '*',
        },
      );

      if (searchResponse != null) {
        final searchPages = searchResponse.data['query']?['pages'] as Map<String, dynamic>?;
        if (searchPages != null && searchPages.isNotEmpty) {
          for (final page in searchPages.values) {
            final imageInfo = (page['imageinfo'] as List?)?.firstOrNull;
            if (imageInfo != null) {
              final url = imageInfo['thumburl'] ?? imageInfo['url'];
              if (url != null && _isValidImageUrl(url)) {
                debugPrint('[Enrichment] Wikimedia Titel-Bild gefunden (Variante "$variant"): ${page['title']}');
                return url;
              }
            }
          }
        }
      }

      // Rate-Limit-Schutz zwischen Varianten
      if (variant != searchVariants.last) {
        await Future.delayed(_apiCallDelay);
      }
    }

    // Rate-Limit-Schutz: Kurze Pause zwischen API-Calls
    await Future.delayed(_apiCallDelay);

    // Methode 3: Kategorie-basierte Suche (z.B. "Category:Schloss Neuschwanstein")
    final cleanedName = _cleanSearchName(name);
    final categoryResponse = await _requestWithRetry(
      ApiEndpoints.wikimediaCommons,
      {
        'action': 'query',
        'generator': 'categorymembers',
        'gcmtitle': 'Category:$cleanedName',
        'gcmtype': 'file',
        'gcmlimit': '5',
        'prop': 'imageinfo',
        'iiprop': 'url',
        'iiurlwidth': '800',
        'format': 'json',
        'origin': '*',
      },
    );

    if (categoryResponse != null) {
      final catPages = categoryResponse.data['query']?['pages'] as Map<String, dynamic>?;
      if (catPages != null && catPages.isNotEmpty) {
        for (final page in catPages.values) {
          final imageInfo = (page['imageinfo'] as List?)?.firstOrNull;
          if (imageInfo != null) {
            final url = imageInfo['thumburl'] ?? imageInfo['url'];
            if (url != null && _isValidImageUrl(url)) {
              debugPrint('[Enrichment] Wikimedia Kategorie-Bild gefunden: ${page['title']}');
              return url;
            }
          }
        }
      }
    }

    // FIX v1.5.3: Failure-Log wenn kein Bild gefunden wurde
    debugPrint('[Enrichment] ⚠️ Kein Wikimedia-Bild gefunden für: $name (lat=$lat, lng=$lng)');
    debugPrint('[Enrichment] Versuchte Methoden: Geo-Suche (10km), Titel-Suche (${_getSearchVariants(name).length} Varianten), Kategorie-Suche');
    return null;
  }

  /// Bereinigt POI-Name für bessere Suchergebnisse
  /// OPTIMIERT v1.7.6: Auch nach Komma/Semikolon abschneiden
  String _cleanSearchName(String name) {
    return name
        .replaceAll(RegExp(r'\s*\(.*?\)\s*'), '') // Klammern entfernen
        .replaceAll(RegExp(r'\s*-\s*.*$'), '') // Alles nach Bindestrich entfernen
        .replaceAll(RegExp(r'[,;].*$'), '') // Alles nach Komma/Semikolon entfernen
        .trim();
  }

  /// Erzeugt alternative Suchvarianten für Wikimedia Commons Titel-Suche
  /// OPTIMIERT v1.7.6: Umlaute normalisieren, Präfix-Wörter entfernen
  List<String> _getSearchVariants(String name) {
    final primary = _cleanSearchName(name);
    final variants = <String>{primary};

    // Variante ohne Umlaute (Wikimedia hat oft englische Dateinamen)
    final noUmlauts = primary
        .replaceAll('ä', 'ae')
        .replaceAll('ö', 'oe')
        .replaceAll('ü', 'ue')
        .replaceAll('Ä', 'Ae')
        .replaceAll('Ö', 'Oe')
        .replaceAll('Ü', 'Ue')
        .replaceAll('ß', 'ss');
    if (noUmlauts != primary) variants.add(noUmlauts);

    // Variante ohne Präfix-Wörter (z.B. "Schloss Neuschwanstein" → "Neuschwanstein")
    final parts = primary.split(' ');
    if (parts.length > 1) {
      const prefixWords = [
        'schloss', 'burg', 'kloster', 'dom', 'kirche', 'stift',
        'rathaus', 'basilika', 'kapelle', 'abtei', 'palais',
      ];
      if (prefixWords.contains(parts.first.toLowerCase())) {
        variants.add(parts.sublist(1).join(' '));
      }
    }

    return variants.toList();
  }

  /// Fallback: Sucht Bild in englischer Wikipedia
  /// OPTIMIERT v1.7.6: Viele europäische POIs haben Bilder in EN Wikipedia aber nicht in DE
  Future<POIEnrichmentData?> _fetchEnglishWikipediaImage(String name) async {
    final cleanName = _cleanSearchName(name);
    final response = await _requestWithRetry(
      ApiEndpoints.wikipediaEnSearch,
      {
        'action': 'query',
        'titles': cleanName,
        'prop': 'pageimages|pageprops',
        'piprop': 'original|thumbnail',
        'pithumbsize': 400,
        'ppprop': 'wikibase_item',
        'format': 'json',
        'origin': '*',
      },
    );

    if (response == null) return null;

    final pages =
        response.data['query']?['pages'] as Map<String, dynamic>?;
    if (pages == null || pages.isEmpty) return null;

    final page = pages.values.first as Map<String, dynamic>;
    if (page['pageid'] == null) return null;

    final imageUrl = page['original']?['source'] as String?;
    if (imageUrl == null) return null; // Nur nützlich wenn Bild vorhanden

    debugPrint('[Enrichment] EN Wikipedia Treffer: $cleanName → Bild vorhanden');
    return POIEnrichmentData(
      imageUrl: imageUrl,
      thumbnailUrl: page['thumbnail']?['source'] as String?,
      wikidataId: page['pageprops']?['wikibase_item'] as String?,
    );
  }

  /// Lädt strukturierte Daten von Wikidata
  /// OPTIMIERT v1.3.7: Mehr Bild-Properties, bessere Fallbacks
  Future<Map<String, dynamic>?> _fetchWikidataInfo(String wikidataId) async {
    // SPARQL Query für relevante Eigenschaften
    // P18 = Bild, P154 = Logo, P94 = Wappen, P41 = Flagge
    // P1435 = Denkmalschutz-Status, P571 = Gründungsdatum, P149 = Architekturstil
    // P856 = Website, P1566 = GeoNames-ID
    final query = '''
SELECT ?image ?logo ?coatOfArms ?heritageStatus ?inception ?archStyle ?archStyleLabel ?website WHERE {
  BIND(wd:$wikidataId AS ?item)

  OPTIONAL { ?item wdt:P18 ?image. }
  OPTIONAL { ?item wdt:P154 ?logo. }
  OPTIONAL { ?item wdt:P94 ?coatOfArms. }
  OPTIONAL { ?item wdt:P1435 ?heritageStatus. }
  OPTIONAL { ?item wdt:P571 ?inception. }
  OPTIONAL { ?item wdt:P856 ?website. }
  OPTIONAL {
    ?item wdt:P149 ?archStyle.
    ?archStyle rdfs:label ?archStyleLabel.
    FILTER(LANG(?archStyleLabel) = "de")
  }
}
LIMIT 1
''';

    // FIX v1.6.6: origin Parameter für CORS-Unterstützung hinzugefügt
    final response = await _requestWithRetry(
      ApiEndpoints.wikidataSparql,
      {
        'query': query,
        'format': 'json',
        'origin': '*',
      },
      options: Options(
        headers: {
          'Accept': 'application/sparql-results+json',
          'Origin': 'https://mapab.app',
        },
      ),
    );

    if (response == null) return null;

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

    // Bild-URL: Priorität P18 > P154 (Logo) > P94 (Wappen)
    String? imageUrl = result['image']?['value'];
    if (imageUrl == null) {
      imageUrl = result['logo']?['value'];
    }
    if (imageUrl == null) {
      imageUrl = result['coatOfArms']?['value'];
    }

    // Wikimedia Commons URLs in Thumb-URLs umwandeln für bessere Performance
    if (imageUrl != null && imageUrl.contains('commons.wikimedia.org')) {
      imageUrl = _convertToThumbUrl(imageUrl, 800);
    }

    debugPrint('[Enrichment] Wikidata Bild-URL: $imageUrl');

    return {
      'imageUrl': imageUrl,
      'isUnesco': isUnesco,
      'isHistoric': heritageStatus != null,
      'foundedYear': foundedYear,
      'architectureStyle': result['archStyleLabel']?['value'],
      'website': result['website']?['value'],
    };
  }

  /// Konvertiert Wikimedia Commons URL zu Thumb-URL
  String _convertToThumbUrl(String url, int width) {
    // Format: https://commons.wikimedia.org/wiki/Special:FilePath/Filename.jpg
    // Zu: https://commons.wikimedia.org/wiki/Special:FilePath/Filename.jpg?width=800
    if (url.contains('Special:FilePath')) {
      return '$url?width=$width';
    }
    return url;
  }

  /// Lädt mehrere Bilder von Wikimedia Commons für eine Location
  /// OPTIMIERT: Mit Retry-Logik, größerer Radius
  Future<List<String>> fetchMultipleImages(
    double lat,
    double lng, {
    int limit = 5,
  }) async {
    final response = await _requestWithRetry(
      ApiEndpoints.wikimediaCommons,
      {
        'action': 'query',
        'generator': 'geosearch',
        'ggscoord': '$lat|$lng',
        'ggsradius': '2000', // OPTIMIERT: 2km Radius statt 1km
        'ggslimit': limit.toString(),
        'prop': 'imageinfo',
        'iiprop': 'url',
        'iiurlwidth': '800',
        'format': 'json',
        'origin': '*',
      },
    );

    if (response == null) return [];

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
  }

  /// Wendet Enrichment-Daten auf POI an
  /// OPTIMIERT v1.3.7: Alle verfügbaren Felder werden übertragen
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
      thumbnailUrl: poi.thumbnailUrl ?? enrichment.thumbnailUrl,
      description: poi.description ?? enrichment.description,
      wikidataId: poi.wikidataId ?? enrichment.wikidataId,
      foundedYear: poi.foundedYear ?? enrichment.foundedYear,
      architectureStyle: poi.architectureStyle ?? enrichment.architectureStyle,
      hasWikidataData: enrichment.wikidataId != null || poi.hasWikidataData,
      isEnriched: true,
      tags: updatedTags,
    );
  }

  /// Prüft ob URL ein gültiges Bild ist
  /// OPTIMIERT v1.3.7: Mehr Formate, Wikimedia-spezifische URLs
  bool _isValidImageUrl(String url) {
    final lower = url.toLowerCase();

    // Standard Bildformate
    if (lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.svg')) {
      return true;
    }

    // Wikimedia-spezifische URLs
    if (lower.contains('/thumb/') ||
        lower.contains('special:filepath') ||
        lower.contains('commons.wikimedia.org') ||
        lower.contains('upload.wikimedia.org')) {
      return true;
    }

    // URL-Parameter mit Bildformat
    if (lower.contains('?') &&
        (lower.contains('format=') || lower.contains('width='))) {
      return true;
    }

    return false;
  }

  /// Enriched mehrere POIs in einem Batch-Request (OPTIMIERT v1.7.3)
  /// Nutzt Wikipedia Multi-Title-Query für bis zu 50 Titel pro Request
  Future<Map<String, POI>> enrichPOIsBatch(List<POI> pois) async {
    if (pois.isEmpty) return {};

    debugPrint('[Enrichment] Batch-Request für ${pois.length} POIs');

    final results = <String, POI>{};
    final cacheService = _cacheService;

    // 1. Cache-Treffer zuerst prüfen
    final uncachedPOIs = <POI>[];
    for (final poi in pois) {
      if (cacheService != null) {
        final cached = await cacheService.getCachedEnrichedPOI(poi.id);
        if (cached != null) {
          results[poi.id] = cached;
          continue;
        }
      }
      uncachedPOIs.add(poi);
    }

    debugPrint('[Enrichment] ${results.length} Cache-Treffer, ${uncachedPOIs.length} zu laden');

    if (uncachedPOIs.isEmpty) return results;

    // 2. POIs mit Wikipedia-Titel sammeln (max 50)
    final poisWithWiki = uncachedPOIs
        .where((p) => p.wikipediaTitle != null && p.wikipediaTitle!.isNotEmpty)
        .take(50)
        .toList();

    // 3. Wikipedia Batch-Abfrage
    if (poisWithWiki.isNotEmpty) {
      final titles = poisWithWiki.map((p) => p.wikipediaTitle!).toList();
      final wikiResults = await _fetchWikipediaBatch(titles);

      // Ergebnisse zuordnen
      for (final poi in poisWithWiki) {
        final enrichment = wikiResults[poi.wikipediaTitle];
        if (enrichment != null) {
          final enrichedPOI = _applyEnrichment(poi, enrichment);
          results[poi.id] = enrichedPOI;

          // Im Cache speichern wenn Bild vorhanden
          if (cacheService != null && enrichment.hasImage) {
            await cacheService.cacheEnrichedPOI(enrichedPOI);
          }
        } else {
          // Kein Wikipedia-Ergebnis → einzelnes Enrichment versuchen
          results[poi.id] = poi;
        }
      }

      debugPrint('[Enrichment] Wikipedia-Batch: ${wikiResults.length} Ergebnisse');

      // 3b. Wikipedia-POIs MIT Beschreibung OHNE Bild: Wikimedia Fallback
      // OPTIMIERT v1.7.6: Viele Wikipedia-Artikel haben keine pageimage
      final poisWithWikiButNoImage = poisWithWiki
          .where((poi) {
            final result = results[poi.id];
            return result != null && result.imageUrl == null;
          })
          .take(5)
          .toList();

      if (poisWithWikiButNoImage.isNotEmpty) {
        debugPrint('[Enrichment] Wikimedia Fallback für ${poisWithWikiButNoImage.length} Wikipedia-POIs ohne Bild');

        final fallbackFutures = poisWithWikiButNoImage.map((poi) async {
          final imageUrl = await _fetchWikimediaCommonsImage(
            poi.latitude,
            poi.longitude,
            poi.name,
          );
          if (imageUrl != null) {
            final existingPOI = results[poi.id]!;
            results[poi.id] = existingPOI.copyWith(imageUrl: imageUrl);

            // Im Cache speichern
            if (cacheService != null) {
              await cacheService.cacheEnrichedPOI(results[poi.id]!);
            }
          }
        });

        await Future.wait(fallbackFutures);
      }
    }

    // 4. POIs ohne Wikipedia-Titel: Wikimedia Geo-Suche (parallel, max 5)
    final poisWithoutWiki = uncachedPOIs
        .where((p) => p.wikipediaTitle == null || p.wikipediaTitle!.isEmpty)
        .where((p) => !results.containsKey(p.id))
        .take(5)
        .toList();

    if (poisWithoutWiki.isNotEmpty) {
      debugPrint('[Enrichment] Wikimedia Geo-Suche für ${poisWithoutWiki.length} POIs ohne Wikipedia');

      final futures = poisWithoutWiki.map((poi) async {
        final imageUrl = await _fetchWikimediaCommonsImage(
          poi.latitude,
          poi.longitude,
          poi.name,
        );
        return MapEntry(poi.id, imageUrl != null
            ? _applyEnrichment(poi, POIEnrichmentData(imageUrl: imageUrl))
            : poi.copyWith(isEnriched: true));
      });

      final geoResults = await Future.wait(futures);
      for (final entry in geoResults) {
        results[entry.key] = entry.value;
      }
    }

    // 5. Restliche POIs als "enriched" markieren (ohne Bild)
    for (final poi in uncachedPOIs) {
      if (!results.containsKey(poi.id)) {
        results[poi.id] = poi.copyWith(isEnriched: true);
      }
    }

    debugPrint('[Enrichment] Batch abgeschlossen: ${results.length} POIs verarbeitet');
    return results;
  }

  /// Wikipedia Batch-Abfrage (bis zu 50 Titel pro Request)
  Future<Map<String, POIEnrichmentData>> _fetchWikipediaBatch(List<String> titles) async {
    if (titles.isEmpty) return {};

    final response = await _requestWithRetry(
      ApiEndpoints.wikipediaGeoSearch,
      {
        'action': 'query',
        'titles': titles.join('|'), // Pipe-separierte Titel
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

    if (response == null) return {};

    final pages = response.data['query']?['pages'] as Map<String, dynamic>?;
    if (pages == null || pages.isEmpty) return {};

    final results = <String, POIEnrichmentData>{};

    // Normalisierte Titel-Mapping aufbauen (Wikipedia kann Titel normalisieren)
    final normalized = response.data['query']?['normalized'] as List?;
    final titleMap = <String, String>{};
    if (normalized != null) {
      for (final n in normalized) {
        titleMap[n['to'] as String] = n['from'] as String;
      }
    }

    for (final page in pages.values) {
      if (page['pageid'] == null) continue;

      final title = page['title'] as String?;
      if (title == null) continue;

      // Original-Titel finden (falls normalisiert)
      final originalTitle = titleMap[title] ?? title;

      results[originalTitle] = POIEnrichmentData(
        imageUrl: page['original']?['source'],
        thumbnailUrl: page['thumbnail']?['source'],
        description: page['extract'],
        wikidataId: page['pageprops']?['wikibase_item'],
      );
    }

    return results;
  }
}

/// Riverpod Provider für POIEnrichmentService
@riverpod
POIEnrichmentService poiEnrichmentService(Ref ref) {
  // FIX v1.5.3: Static State bei Service-Erstellung zurücksetzen
  // Verhindert inkonsistente Zustände nach Hot-Reload
  POIEnrichmentService.resetStaticState();

  final cacheService = ref.watch(poiCacheServiceProvider);
  return POIEnrichmentService(cacheService: cacheService);
}
