/// API-Konfiguration für Backend-Services
/// WICHTIG: URLs werden via --dart-define beim Build übergeben!
class ApiConfig {
  /// Backend-URL (Vercel)
  /// Lokal: http://localhost:3000
  /// Produktion: Aus --dart-define BACKEND_URL
  static const String backendBaseUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: '',
  );

  /// Prüft ob Backend konfiguriert ist und die URL sicher ist
  static bool get isConfigured =>
      backendBaseUrl.isNotEmpty && _isValidBackendUrl;

  /// Prüft ob die Backend-URL sicher ist (HTTPS in Produktion)
  static bool get _isValidBackendUrl {
    if (backendBaseUrl.isEmpty) return false;
    final uri = Uri.tryParse(backendBaseUrl);
    if (uri == null) return false;
    // Erlaube HTTP nur fuer localhost (Entwicklung)
    if (uri.scheme == 'http') {
      return uri.host == 'localhost' || uri.host == '127.0.0.1';
    }
    return uri.scheme == 'https';
  }

  /// Timeout für API-Anfragen
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 60);

  /// Endpoints
  static const String aiChatEndpoint = '/api/ai/chat';
  static const String aiTripPlanEndpoint = '/api/ai/trip-plan';
  static const String healthEndpoint = '/api/health';
}
