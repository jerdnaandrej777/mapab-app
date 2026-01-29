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

  // Wikidata - Echte POI-Daten (Telefon, Website, etc.)
  static const String wikidataSparql =
      'https://query.wikidata.org/sparql';

  // Wikimedia Commons - Bilder
  static const String wikimediaCommons =
      'https://commons.wikimedia.org/w/api.php';

  // Open-Meteo - Wettervorhersagen
  static const String openMeteoForecast =
      'https://api.open-meteo.com/v1/forecast';

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
}
