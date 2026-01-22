/// API-Konfiguration für Backend-Services
class ApiConfig {
  /// Backend-URL (Vercel)
  /// WICHTIG: Nach Deployment anpassen!
  /// Lokal: http://localhost:3000
  /// Produktion: https://mapab-backend.vercel.app
  static const String backendBaseUrl =
      String.fromEnvironment('BACKEND_URL', defaultValue: 'https://backend-gules-gamma-30.vercel.app');

  /// Timeout für API-Anfragen
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 60);

  /// Endpoints
  static const String aiChatEndpoint = '/api/ai/chat';
  static const String aiTripPlanEndpoint = '/api/ai/trip-plan';
  static const String healthEndpoint = '/api/health';
}
