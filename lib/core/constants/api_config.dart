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

  /// Prüft ob Backend konfiguriert ist
  static bool get isConfigured => backendBaseUrl.isNotEmpty;

  /// Timeout für API-Anfragen
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 60);

  /// Endpoints
  static const String aiChatEndpoint = '/api/ai/chat';
  static const String aiTripPlanEndpoint = '/api/ai/trip-plan';
  static const String healthEndpoint = '/api/health';
}
