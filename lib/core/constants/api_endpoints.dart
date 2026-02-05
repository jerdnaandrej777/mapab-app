import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// API Endpoints für alle externen Services
/// Übernommen von MapAB JavaScript-Implementierung
class ApiEndpoints {
  ApiEndpoints._();

  // Nominatim - Geocoding & Autocomplete
  static const String nominatimSearch =
      'https://nominatim.openstreetmap.org/search';
  static const String nominatimReverse =
      'https://nominatim.openstreetmap.org/reverse';

  // OSRM - Schnelle Routenberechnung
  static const String osrmRoute =
      'https://router.project-osrm.org/route/v1/driving';

  // OpenRouteService - Scenic Routing (benötigt API-Key)
  static const String orsRoute =
      'https://api.openrouteservice.org/v2/directions/driving-car';
  static const String orsMatrix =
      'https://api.openrouteservice.org/v2/matrix/driving-car';

  // Overpass - OpenStreetMap POI-Abfragen
  static const String overpassApi =
      'https://overpass-api.de/api/interpreter';

  // Wikipedia - Georeferenzierte Artikel
  static const String wikipediaGeoSearch =
      'https://de.wikipedia.org/w/api.php';

  // Wikipedia EN - Fallback für Bilder wenn DE kein Ergebnis liefert
  static const String wikipediaEnSearch =
      'https://en.wikipedia.org/w/api.php';

  // Wikipedia Multi-Sprach-Fallbacks (v1.7.27 - europäische Sprachen)
  static const String wikipediaFrSearch =
      'https://fr.wikipedia.org/w/api.php';
  static const String wikipediaItSearch =
      'https://it.wikipedia.org/w/api.php';
  static const String wikipediaEsSearch =
      'https://es.wikipedia.org/w/api.php';
  static const String wikipediaNlSearch =
      'https://nl.wikipedia.org/w/api.php';
  static const String wikipediaPlSearch =
      'https://pl.wikipedia.org/w/api.php';

  // Wikidata - Echte POI-Daten (Telefon, Website, etc.)
  static const String wikidataSparql =
      'https://query.wikidata.org/sparql';

  // Wikimedia Commons - Bilder
  static const String wikimediaCommons =
      'https://commons.wikimedia.org/w/api.php';

  // Open-Meteo - Wettervorhersagen
  static const String openMeteoForecast =
      'https://api.open-meteo.com/v1/forecast';

  // Open-Meteo - Hoehendaten (Copernicus DEM, 90m Aufloesung)
  static const String openMeteoElevation =
      'https://api.open-meteo.com/v1/elevation';

  // Openverse - Creative Commons Bild-Aggregator (Last-Resort Fallback v1.7.27)
  static const String openverseSearch =
      'https://api.openverse.org/v1/images/';

  // OpenAI - AI Features
  static const String openAiChat =
      'https://api.openai.com/v1/chat/completions';
}

/// API Konfiguration
class ApiConfig {
  ApiConfig._();

  // Timeouts in Millisekunden
  static const int defaultTimeout = 15000;
  static const int routingTimeout = 30000;
  static const int overpassTimeout = 45000;

  // Rate Limiting
  static const int nominatimDelayMs = 1000; // 1 Request pro Sekunde
  static const int overpassDelayMs = 2000;

  // Cache Dauer in Minuten
  static const int geocodeCacheMinutes = 60;
  static const int routeCacheMinutes = 30;
  static const int poiCacheMinutes = 15;
  static const int weatherCacheMinutes = 15;

  // User Agent (wichtig für Nominatim)
  static const String userAgent = 'TravelPlannerApp/1.0 (Flutter)';

  /// Erstellt eine standard-konfigurierte Dio-Instanz mit Interceptors.
  /// [profile] bestimmt die Timeout-Konfiguration.
  static Dio createDio({DioProfile profile = DioProfile.standard}) {
    final (connect, receive) = switch (profile) {
      DioProfile.standard => (defaultTimeout, defaultTimeout),
      DioProfile.overpass => (defaultTimeout, overpassTimeout),
      DioProfile.routing => (routingTimeout, routingTimeout),
      DioProfile.enrichment => (25000, 25000),
    };

    final dio = Dio(BaseOptions(
      headers: {'User-Agent': userAgent},
      connectTimeout: Duration(milliseconds: connect),
      receiveTimeout: Duration(milliseconds: receive),
    ));

    // Debug-Logging nur im Development-Modus
    if (kDebugMode) {
      dio.interceptors.add(_DebugLogInterceptor());
    }

    // Retry bei HTTP 429 (Rate-Limit) mit Backoff
    dio.interceptors.add(_RateLimitRetryInterceptor());

    return dio;
  }
}

/// Interceptor fuer Debug-Logging aller HTTP-Requests
class _DebugLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final uri = options.uri;
    debugPrint('[HTTP] ${options.method} ${uri.host}${uri.path}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint('[HTTP] ${response.statusCode} ${response.requestOptions.uri.host} '
        '(${response.requestOptions.uri.path})');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('[HTTP] ERROR ${err.type.name}: '
        '${err.requestOptions.uri.host}${err.requestOptions.uri.path} '
        '- ${err.message}');
    handler.next(err);
  }
}

/// Interceptor fuer automatisches Retry bei HTTP 429 (Rate-Limit)
class _RateLimitRetryInterceptor extends Interceptor {
  static const _maxRetries = 2;
  static const _retryDelayMs = 3000;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 429) {
      final retryCount = err.requestOptions.extra['_retryCount'] ?? 0;
      if (retryCount < _maxRetries) {
        debugPrint('[HTTP] 429 Rate-Limit - Retry ${retryCount + 1}/$_maxRetries '
            'nach ${_retryDelayMs}ms');
        await Future.delayed(const Duration(milliseconds: _retryDelayMs));

        final options = err.requestOptions;
        options.extra['_retryCount'] = retryCount + 1;

        try {
          final response = await Dio().fetch(options);
          handler.resolve(response);
          return;
        } catch (e) {
          // Retry fehlgeschlagen - weiter mit Fehler
        }
      }
    }
    handler.next(err);
  }
}

/// Timeout-Profile fuer verschiedene API-Typen
enum DioProfile {
  standard,   // 15s - Geocoding, Wetter
  overpass,   // 15s connect, 45s receive - POI/Hotel Overpass-Queries
  routing,    // 30s - OSRM/ORS Routing
  enrichment, // 25s - Wikipedia/Wikimedia Enrichment
}
