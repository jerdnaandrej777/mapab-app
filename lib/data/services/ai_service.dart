import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/constants/api_config.dart';
import '../models/poi.dart';
import '../models/route.dart';
import '../models/trip.dart';

part 'ai_service.g.dart';

/// Service für AI-Features via Backend-Proxy
/// Der API-Key ist sicher auf dem Server gespeichert
class AIService {
  final Dio _dio;

  AIService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: ApiConfig.backendBaseUrl,
              connectTimeout: ApiConfig.connectTimeout,
              receiveTimeout: ApiConfig.receiveTimeout,
              headers: {
                'Content-Type': 'application/json',
              },
            ));

  /// Service ist jetzt immer "konfiguriert" da der Key im Backend liegt
  bool get isConfigured => true;

  /// Chatbot für natürlichsprachige Interaktion
  Future<String> chat({
    required String message,
    required TripContext context,
    List<ChatMessage>? history,
  }) async {
    debugPrint('[AI] Sende Chat-Anfrage an Backend...');

    try {
      // Kontext für Backend aufbereiten
      final contextData = <String, dynamic>{};

      // Standort-Informationen hinzufügen (NEU)
      if (context.hasUserLocation) {
        contextData['userLocation'] = {
          'lat': context.userLatitude,
          'lng': context.userLongitude,
          'name': context.userLocationName,
        };
      }

      if (context.route != null) {
        contextData['routeStart'] = context.route!.startAddress;
        contextData['routeEnd'] = context.route!.endAddress;
        contextData['distanceKm'] = context.route!.distanceKm;
        contextData['durationMinutes'] = context.route!.durationMinutes;
      }
      if (context.stops.isNotEmpty) {
        contextData['stops'] = context.stops
            .map((s) => {
                  'name': s.name,
                  'category': s.categoryId,
                })
            .toList();
      }

      // History für Backend aufbereiten
      final historyData = history
              ?.take(20)
              .map((msg) => {
                    'role': msg.isUser ? 'user' : 'assistant',
                    'content': msg.content,
                  })
              .toList() ??
          [];

      final response = await _dio.post(
        ApiConfig.aiChatEndpoint,
        data: {
          'message': message,
          'context': contextData.isNotEmpty ? contextData : null,
          'history': historyData,
        },
      );

      debugPrint('[AI] ✓ Chat-Antwort erhalten, Status: ${response.statusCode}');

      final responseMessage = response.data['message'] as String?;
      final tokensUsed = response.data['tokensUsed'] as int?;

      debugPrint('[AI] Tokens verwendet: $tokensUsed');

      return responseMessage ?? '';
    } on DioException catch (e) {
      debugPrint('[AI] ✗ FEHLER: ${e.type}');
      debugPrint('[AI] Status-Code: ${e.response?.statusCode}');
      debugPrint('[AI] Response: ${e.response?.data}');

      _handleDioError(e);
      rethrow; // Wird nie erreicht
    } catch (e) {
      debugPrint('[AI] ✗ Unerwarteter Fehler: $e');
      throw AIException('Unerwarteter Fehler: $e');
    }
  }

  /// Generiert Trip-Plan via Backend
  Future<String> generateTripPlanText({
    required String destination,
    required int days,
    required List<String> interests,
    String? startLocation,
  }) async {
    debugPrint('[AI] Sende Trip-Plan-Anfrage an Backend...');
    debugPrint('[AI] Ziel: $destination, Tage: $days');

    try {
      final response = await _dio.post(
        ApiConfig.aiTripPlanEndpoint,
        data: {
          'destination': destination,
          'startLocation': startLocation,
          'days': days,
          'interests': interests,
        },
      );

      debugPrint('[AI] ✓ Trip-Plan erhalten, Status: ${response.statusCode}');

      final plan = response.data['plan'] as String?;
      final tokensUsed = response.data['tokensUsed'] as int?;

      debugPrint('[AI] Tokens verwendet: $tokensUsed');

      return plan ?? '';
    } on DioException catch (e) {
      debugPrint('[AI] ✗ FEHLER: ${e.type}');
      debugPrint('[AI] Status-Code: ${e.response?.statusCode}');
      debugPrint('[AI] Response: ${e.response?.data}');

      _handleDioError(e);
      rethrow;
    } catch (e) {
      debugPrint('[AI] ✗ Unerwarteter Fehler: $e');
      throw AIException('Unerwarteter Fehler: $e');
    }
  }

  /// Generiert automatischen Reiseplan (strukturiert)
  /// Für Rückwärtskompatibilität - ruft intern generateTripPlanText auf
  Future<AITripPlan> generateTripPlan({
    required String destination,
    required int days,
    required List<String> interests,
    String? startLocation,
  }) async {
    // Hole Text-Plan vom Backend
    final planText = await generateTripPlanText(
      destination: destination,
      days: days,
      interests: interests,
      startLocation: startLocation,
    );

    // Parse in strukturiertes Format (vereinfacht)
    // Das Backend liefert formatierten Text, nicht JSON
    return AITripPlan(
      title: '$days Tage in $destination',
      description: planText,
      days: [
        AITripDay(
          title: 'Reiseplan',
          description: planText,
          stops: [],
        ),
      ],
      model: 'gpt-4o-mini',
      generatedAt: DateTime.now(),
    );
  }

  /// Holt personalisierte POI-Empfehlungen
  Future<List<AIRecommendation>> getRecommendations({
    required AppRoute route,
    required List<POI> availablePOIs,
    required UserPreferences preferences,
  }) async {
    // POI-Zusammenfassung erstellen
    final poiSummary = availablePOIs
        .take(30)
        .map((p) =>
            '${p.name} (${p.categoryLabel}, ${p.detourKm?.toStringAsFixed(1) ?? "?"} km Umweg)')
        .join(', ');

    // Via Chat-Endpoint anfragen
    final response = await chat(
      message: '''
Empfehle mir die 5 besten POIs für meine Route.
Bevorzugte Kategorien: ${preferences.preferredCategories.join(', ')}
Maximaler Umweg: ${preferences.maxDetourKm} km
Reisestil: ${preferences.travelStyle}

Verfügbare POIs: $poiSummary

Antworte als JSON-Array: [{"name": "POI-Name", "reason": "Begründung"}]
''',
      context: TripContext(route: route),
    );

    // JSON extrahieren und parsen
    try {
      // Versuche JSON aus der Antwort zu extrahieren
      final jsonMatch = RegExp(r'\[[\s\S]*?\]').firstMatch(response);
      if (jsonMatch != null) {
        final data = json.decode(jsonMatch.group(0)!) as List;
        return data
            .map((r) => AIRecommendation(
                  name: r['name'] ?? '',
                  reason: r['reason'] ?? '',
                ))
            .toList();
      }
    } catch (e) {
      debugPrint('[AI] Konnte Empfehlungen nicht parsen: $e');
    }

    return [];
  }

  /// Health-Check für Backend
  Future<bool> checkHealth() async {
    // Zuerst prüfen ob Backend-URL konfiguriert ist
    if (!ApiConfig.isConfigured) {
      debugPrint('[AI] Backend nicht konfiguriert (BACKEND_URL fehlt in --dart-define)');
      return false;
    }

    try {
      final response = await _dio.get(ApiConfig.healthEndpoint);
      return response.statusCode == 200 && response.data['status'] == 'ok';
    } catch (e) {
      debugPrint('[AI] Backend Health-Check fehlgeschlagen: $e');
      return false;
    }
  }

  /// Behandelt Dio-Fehler
  Never _handleDioError(DioException e) {
    final statusCode = e.response?.statusCode;
    final errorData = e.response?.data;
    final errorCode = errorData is Map ? errorData['code'] : null;
    final errorMessage = errorData is Map ? errorData['error'] : null;

    switch (statusCode) {
      case 400:
        throw AIException('Ungültige Anfrage: ${errorMessage ?? "Bitte überprüfe deine Eingabe"}');
      case 429:
        throw AIException(
            'Tageslimit erreicht. Bitte versuche es morgen wieder. '
            '(${errorMessage ?? ""})');
      case 500:
        if (errorCode == 'AI_CONFIG_ERROR') {
          throw AIException('AI-Service ist nicht konfiguriert. Bitte kontaktiere den Support.');
        }
        throw AIException('Server-Fehler: ${errorMessage ?? "Bitte versuche es später erneut"}');
      case 503:
        throw AIException('AI-Service vorübergehend nicht verfügbar. Bitte warte kurz.');
      default:
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          throw AIException('Zeitüberschreitung. Bitte prüfe deine Internetverbindung.');
        }
        if (e.type == DioExceptionType.connectionError) {
          throw AIException('Keine Verbindung zum Server. Bitte prüfe deine Internetverbindung.');
        }
        throw AIException('Verbindungsfehler: ${e.message ?? "Unbekannter Fehler"}');
    }
  }
}

/// AI-Empfehlung
class AIRecommendation {
  final String name;
  final String reason;

  AIRecommendation({required this.name, required this.reason});
}

/// User-Präferenzen für AI
class UserPreferences {
  final List<String> preferredCategories;
  final int maxDetourKm;
  final String travelStyle; // relaxed, balanced, intensive

  UserPreferences({
    this.preferredCategories = const [],
    this.maxDetourKm = 45,
    this.travelStyle = 'balanced',
  });

  Map<String, dynamic> toJson() => {
        'preferredCategories': preferredCategories,
        'maxDetourKm': maxDetourKm,
        'travelStyle': travelStyle,
      };
}

/// Trip-Kontext für Chatbot
class TripContext {
  final AppRoute? route;
  final List<POI> stops;

  // Standort-Informationen (NEU für standortbasierte Empfehlungen)
  final double? userLatitude;
  final double? userLongitude;
  final String? userLocationName;

  TripContext({
    this.route,
    this.stops = const [],
    this.userLatitude,
    this.userLongitude,
    this.userLocationName,
  });

  /// Hat der Kontext Standort-Informationen?
  bool get hasUserLocation => userLatitude != null && userLongitude != null;
}

/// Chat-Nachricht
class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.content,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// AI Exception
class AIException implements Exception {
  final String message;
  AIException(this.message);

  @override
  String toString() => 'AIException: $message';
}

/// Strukturierter Trip-Plan (für Rückwärtskompatibilität)
class AITripPlan {
  final String title;
  final String? description;
  final List<AITripDay> days;
  final String model;
  final DateTime generatedAt;

  AITripPlan({
    required this.title,
    this.description,
    required this.days,
    required this.model,
    required this.generatedAt,
  });
}

class AITripDay {
  final String title;
  final String? description;
  final List<AITripStop> stops;

  AITripDay({
    required this.title,
    this.description,
    required this.stops,
  });
}

class AITripStop {
  final String name;
  final String category;
  final String? duration;
  final String? description;

  AITripStop({
    required this.name,
    required this.category,
    this.duration,
    this.description,
  });
}

/// Riverpod Provider für AIService
@riverpod
AIService aiService(AiServiceRef ref) {
  debugPrint('[AI] AIService initialisiert (Backend-Proxy: ${ApiConfig.backendBaseUrl})');
  return AIService();
}
