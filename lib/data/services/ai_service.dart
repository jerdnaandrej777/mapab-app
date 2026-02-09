import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../../core/constants/api_config.dart';
import '../../core/constants/categories.dart';
import '../models/poi.dart';
import '../models/route.dart';
import '../models/trip.dart';

part 'ai_service.g.dart';

/// Service für AI-Features via Backend-Proxy
/// Der API-Key ist sicher auf dem Server gespeichert
class AIService {
  final Dio _dio;
  static const String _build =
      String.fromEnvironment('APP_BUILD', defaultValue: 'unknown');
  final String _sessionId = DateTime.now().millisecondsSinceEpoch.toString();

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

  Map<String, dynamic> get _clientMeta => {
        'build': _build,
        'platform': defaultTargetPlatform.name,
        'sessionId': _sessionId,
      };

  Map<String, dynamic> _requireResponseMap(dynamic data,
      {required String endpoint}) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    throw AIException(
      'Ungueltige Antwort vom Backend ($endpoint).',
      code: 'BACKEND_RESPONSE_INVALID',
    );
  }

  String _requireNonEmptyString(
    Map<String, dynamic> data,
    String key, {
    required String endpoint,
  }) {
    final value = data[key];
    if (value is String && value.trim().isNotEmpty) return value;
    throw AIException(
      'Pflichtfeld "$key" fehlt in Backend-Antwort ($endpoint).',
      code: 'BACKEND_RESPONSE_INVALID',
      traceId: _extractTraceId(data),
    );
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return null;
  }

  String? _extractTraceId(dynamic payload) {
    if (payload is! Map) return null;
    final traceId = payload['traceId'];
    if (traceId is String && traceId.trim().isNotEmpty) {
      return traceId.trim();
    }
    return null;
  }

  String? _extractErrorCode(dynamic payload) {
    if (payload is! Map) return null;
    final directCode = payload['code'];
    if (directCode is String && directCode.trim().isNotEmpty) {
      return directCode.trim();
    }
    final error = payload['error'];
    if (error is Map) {
      final nestedCode = error['code'];
      if (nestedCode is String && nestedCode.trim().isNotEmpty) {
        return nestedCode.trim();
      }
    }
    return null;
  }

  String? _extractErrorMessage(dynamic payload) {
    if (payload is! Map) return null;
    final error = payload['error'];
    if (error is String && error.trim().isNotEmpty) {
      return error.trim();
    }
    if (error is Map) {
      final nestedMessage = error['message'];
      if (nestedMessage is String && nestedMessage.trim().isNotEmpty) {
        return nestedMessage.trim();
      }
    }
    final message = payload['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }
    return null;
  }

  void _addRequestBreadcrumb({
    required String stage,
    required String requestKind,
    String? traceId,
    String? errorCode,
  }) {
    Sentry.addBreadcrumb(
      Breadcrumb(
        category: 'ai.request',
        type: 'http',
        level: stage == 'error' ? SentryLevel.error : SentryLevel.info,
        message: '$stage:$requestKind',
        data: <String, dynamic>{
          'stage': stage,
          'requestKind': requestKind,
          'build': _build,
          if (traceId != null) 'traceId': traceId,
          if (errorCode != null) 'errorCode': errorCode,
        },
      ),
    );
  }

  /// Chatbot für natürlichsprachige Interaktion
  Future<String> chat({
    required String message,
    required TripContext context,
    List<ChatMessage>? history,
    String? language,
  }) async {
    debugPrint('[AI] Sende Chat-Anfrage an Backend...');
    _addRequestBreadcrumb(stage: 'start', requestKind: 'chat');

    try {
      final contextData = <String, dynamic>{};

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
            .map(
              (s) => {
                'name': s.name,
                'category': s.categoryId,
              },
            )
            .toList();
      }

      if (language != null) {
        contextData['responseLanguage'] = language;
      }

      if (context.overallWeather != null) {
        contextData['overallWeather'] = context.overallWeather;
      }

      if (context.dayWeather != null && context.dayWeather!.isNotEmpty) {
        contextData['dayWeather'] = context.dayWeather!.map(
          (k, v) => MapEntry(k.toString(), v),
        );
      }

      if (context.selectedDay != null) {
        contextData['selectedDay'] = context.selectedDay;
      }

      if (context.totalDays != null) {
        contextData['totalDays'] = context.totalDays;
      }

      if (context.preferredCategories != null &&
          context.preferredCategories!.isNotEmpty) {
        contextData['preferredCategories'] =
            context.preferredCategories!.toList();
      }

      final historyData = history
              ?.take(20)
              .map(
                (msg) => {
                  'role': msg.isUser ? 'user' : 'assistant',
                  'content': msg.content,
                },
              )
              .toList() ??
          [];

      final response = await _dio.post(
        ApiConfig.aiChatEndpoint,
        data: {
          'message': message,
          'context': contextData.isNotEmpty ? contextData : null,
          'history': historyData,
          'clientMeta': _clientMeta,
        },
      );

      debugPrint('[AI] Chat-Antwort erhalten, Status: ${response.statusCode}');

      final responseData = _requireResponseMap(
        response.data,
        endpoint: ApiConfig.aiChatEndpoint,
      );
      final responseMessage = _requireNonEmptyString(
        responseData,
        'message',
        endpoint: ApiConfig.aiChatEndpoint,
      );
      final tokensUsed = _asInt(responseData['tokensUsed']);
      final traceId = _extractTraceId(responseData);

      debugPrint('[AI] Tokens verwendet: $tokensUsed');
      _addRequestBreadcrumb(
        stage: 'end',
        requestKind: 'chat',
        traceId: traceId,
      );

      return responseMessage;
    } on DioException catch (e) {
      debugPrint('[AI] FEHLER: ${e.type}');
      debugPrint('[AI] Status-Code: ${e.response?.statusCode}');
      debugPrint('[AI] Response: ${e.response?.data}');
      try {
        _handleDioError(e);
      } on AIException catch (error) {
        _addRequestBreadcrumb(
          stage: 'error',
          requestKind: 'chat',
          traceId: error.traceId,
          errorCode: error.code,
        );
        rethrow;
      }
    } on AIException catch (e) {
      _addRequestBreadcrumb(
        stage: 'error',
        requestKind: 'chat',
        traceId: e.traceId,
        errorCode: e.code,
      );
      rethrow;
    } catch (e) {
      debugPrint('[AI] Unerwarteter Fehler: $e');
      _addRequestBreadcrumb(
        stage: 'error',
        requestKind: 'chat',
        errorCode: 'UNEXPECTED_ERROR',
      );
      throw AIException('Unerwarteter Fehler: $e', code: 'UNEXPECTED_ERROR');
    }
  }

  /// Generiert Trip-Plan via Backend
  Future<String> generateTripPlanText({
    required String destination,
    required int days,
    required List<String> interests,
    String? startLocation,
    String? language,
  }) async {
    debugPrint('[AI] Sende Trip-Plan-Anfrage an Backend...');
    debugPrint('[AI] Ziel: $destination, Tage: $days');
    _addRequestBreadcrumb(stage: 'start', requestKind: 'tripPlan');

    try {
      final response = await _dio.post(
        ApiConfig.aiTripPlanEndpoint,
        data: {
          'destination': destination,
          'startLocation': startLocation,
          'days': days,
          'interests': interests,
          if (language != null) 'language': language,
          'clientMeta': _clientMeta,
        },
      );

      debugPrint('[AI] Trip-Plan erhalten, Status: ${response.statusCode}');

      final responseData = _requireResponseMap(
        response.data,
        endpoint: ApiConfig.aiTripPlanEndpoint,
      );
      final plan = _requireNonEmptyString(
        responseData,
        'plan',
        endpoint: ApiConfig.aiTripPlanEndpoint,
      );
      final tokensUsed = _asInt(responseData['tokensUsed']);
      final traceId = _extractTraceId(responseData);

      debugPrint('[AI] Tokens verwendet: $tokensUsed');
      _addRequestBreadcrumb(
        stage: 'end',
        requestKind: 'tripPlan',
        traceId: traceId,
      );

      return plan;
    } on DioException catch (e) {
      debugPrint('[AI] FEHLER: ${e.type}');
      debugPrint('[AI] Status-Code: ${e.response?.statusCode}');
      debugPrint('[AI] Response: ${e.response?.data}');
      try {
        _handleDioError(e);
      } on AIException catch (error) {
        _addRequestBreadcrumb(
          stage: 'error',
          requestKind: 'tripPlan',
          traceId: error.traceId,
          errorCode: error.code,
        );
        rethrow;
      }
    } on AIException catch (e) {
      _addRequestBreadcrumb(
        stage: 'error',
        requestKind: 'tripPlan',
        traceId: e.traceId,
        errorCode: e.code,
      );
      rethrow;
    } catch (e) {
      debugPrint('[AI] Unerwarteter Fehler: $e');
      _addRequestBreadcrumb(
        stage: 'error',
        requestKind: 'tripPlan',
        errorCode: 'UNEXPECTED_ERROR',
      );
      throw AIException('Unerwarteter Fehler: $e', code: 'UNEXPECTED_ERROR');
    }
  }

  /// Generiert automatischen Reiseplan (strukturiert)
  /// Für Rückwärtskompatibilität - ruft intern generateTripPlanText auf
  Future<AITripPlan> generateTripPlan({
    required String destination,
    required int days,
    required List<String> interests,
    String? startLocation,
    String? language,
  }) async {
    // Hole Text-Plan vom Backend
    final planText = await generateTripPlanText(
      destination: destination,
      days: days,
      interests: interests,
      startLocation: startLocation,
      language: language,
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
    String? language,
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
      language: language,
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

  /// Optimiert einen Trip basierend auf Wetter und POI-Kategorien
  /// Gibt strukturierte Vorschläge zurück
  Future<AITripOptimization> optimizeTrip({
    required Trip trip,
    required Map<int, String> dayWeather,
    required List<POI> availablePOIs,
    String? language,
  }) async {
    debugPrint('[AI] Sende Trip-Optimierung an Backend...');

    // Erstelle Prompt für Optimierung
    final stopsInfo = trip.stops
        .map((s) => '${s.name} (${s.categoryId}, Tag ${s.day})')
        .join(', ');

    final weatherInfo =
        dayWeather.entries.map((e) => 'Tag ${e.key}: ${e.value}').join(', ');

    try {
      final response = await chat(
        message: '''
Optimiere meinen ${trip.actualDays}-Tage-Trip.

Aktuelle Stops: $stopsInfo
Wetter pro Tag: $weatherInfo
Route: ${trip.route.distanceKm.toStringAsFixed(0)} km

Prüfe:
1. Sind Outdoor-POIs an Tagen mit schlechtem Wetter?
2. Könnte die Reihenfolge optimiert werden?
3. Gibt es bessere Indoor-Alternativen bei Regen?

Antworte als JSON:
{
  "suggestions": [{"message": "...", "type": "weather|optimization", "dayNumber": 1}],
  "summary": "Zusammenfassung"
}
''',
        context: TripContext(
          route: trip.route,
          stops: availablePOIs,
          dayWeather: dayWeather,
          totalDays: trip.actualDays,
        ),
        language: language,
      );

      // JSON aus Antwort extrahieren
      try {
        final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
        if (jsonMatch != null) {
          final data = json.decode(jsonMatch.group(0)!) as Map<String, dynamic>;
          final suggestions = (data['suggestions'] as List?)
                  ?.map((s) => AIOptimizationSuggestion(
                        message: s['message'] ?? '',
                        type: s['type'] ?? 'general',
                        dayNumber: s['dayNumber'] as int?,
                      ))
                  .toList() ??
              [];
          return AITripOptimization(
            suggestions: suggestions,
            summary: data['summary'] ?? '',
          );
        }
      } catch (e) {
        debugPrint('[AI] Konnte Optimierung nicht parsen: $e');
      }

      return AITripOptimization(
        suggestions: [],
        summary: response,
      );
    } catch (e) {
      debugPrint('[AI] Trip-Optimierung fehlgeschlagen: $e');
      rethrow;
    }
  }

  /// Strukturierte AI-POI-Vorschlaege fuer Day-Editor und Chat
  Future<AIPoiSuggestionResponse> getPoiSuggestionsStructured({
    required AIPoiSuggestionRequest request,
  }) async {
    debugPrint('[AI] Sende strukturierte POI-Suggestions an Backend...');
    _addRequestBreadcrumb(stage: 'start', requestKind: 'nearby');

    try {
      final response = await _dio.post(
        ApiConfig.aiPoiSuggestionsEndpoint,
        data: {
          ...request.toJson(),
          'clientMeta': _clientMeta,
        },
      );

      final data = _requireResponseMap(
        response.data,
        endpoint: ApiConfig.aiPoiSuggestionsEndpoint,
      );

      final parsed = AIPoiSuggestionResponse.fromJson(data);
      final traceId = _extractTraceId(data);

      debugPrint(
        '[AI] Strukturierte POI-Suggestions erhalten: ${parsed.suggestions.length} '
        '(Quelle: ${parsed.source ?? "unknown"})',
      );
      _addRequestBreadcrumb(
        stage: 'end',
        requestKind: 'nearby',
        traceId: traceId,
      );
      return parsed;
    } on DioException catch (e) {
      debugPrint(
          '[AI] Strukturierte POI-Suggestions Fehler: ${e.response?.data}');
      try {
        _handleDioError(e);
      } on AIException catch (error) {
        _addRequestBreadcrumb(
          stage: 'error',
          requestKind: 'nearby',
          traceId: error.traceId,
          errorCode: error.code,
        );
        rethrow;
      }
    } on AIException catch (e) {
      _addRequestBreadcrumb(
        stage: 'error',
        requestKind: 'nearby',
        traceId: e.traceId,
        errorCode: e.code,
      );
      rethrow;
    } catch (e) {
      debugPrint('[AI] Strukturierte POI-Suggestions unerwarteter Fehler: $e');
      _addRequestBreadcrumb(
        stage: 'error',
        requestKind: 'nearby',
        errorCode: 'UNEXPECTED_ERROR',
      );
      throw AIException(
        'POI-Suggestions konnten nicht geladen werden: $e',
        code: 'UNEXPECTED_ERROR',
      );
    }
  }

  /// Health-Check für Backend
  Future<bool> checkHealth() async {
    if (!ApiConfig.isConfigured) {
      debugPrint(
          '[AI] Backend nicht konfiguriert (BACKEND_URL fehlt in --dart-define)');
      return false;
    }

    try {
      final response = await _dio.get(ApiConfig.healthEndpoint);
      final data = _requireResponseMap(
        response.data,
        endpoint: ApiConfig.healthEndpoint,
      );
      return response.statusCode == 200 && data['status'] == 'ok';
    } catch (e) {
      debugPrint('[AI] Backend Health-Check fehlgeschlagen: $e');
      return false;
    }
  }

  /// Behandelt Dio-Fehler
  Never _handleDioError(DioException e) {
    final statusCode = e.response?.statusCode;
    final errorData = e.response?.data;
    final traceId = _extractTraceId(errorData);
    final errorCode = _extractErrorCode(errorData);
    final errorMessage = _extractErrorMessage(errorData);

    switch (statusCode) {
      case 400:
        throw AIException(
          'Ungueltige Anfrage: ${errorMessage ?? "Bitte pruefe deine Eingabe"}',
          code: errorCode ?? 'VALIDATION_ERROR',
          traceId: traceId,
        );
      case 429:
        throw AIException(
          'Tageslimit erreicht. Bitte versuche es spaeter erneut. ${errorMessage ?? ""}'
              .trim(),
          code: errorCode ?? 'RATE_LIMITED',
          traceId: traceId,
        );
      case 500:
        if (errorCode == 'AI_CONFIG_ERROR') {
          throw AIException(
            'AI-Service ist nicht konfiguriert. Bitte kontaktiere den Support.',
            code: 'AI_CONFIG_ERROR',
            traceId: traceId,
          );
        }
        throw AIException(
          'Server-Fehler: ${errorMessage ?? "Bitte versuche es spaeter erneut"}',
          isRetryable: true,
          code: errorCode ?? 'SERVER_ERROR',
          traceId: traceId,
        );
      case 503:
        throw AIException(
          'AI-Service voruebergehend nicht verfuegbar. Bitte warte kurz.',
          isRetryable: true,
          code: errorCode ?? 'SERVICE_UNAVAILABLE',
          traceId: traceId,
        );
      default:
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          throw AIException(
            'Zeitueberschreitung. Bitte pruefe deine Internetverbindung.',
            isRetryable: true,
            code: 'TIMEOUT',
            traceId: traceId,
          );
        }
        if (e.type == DioExceptionType.connectionError) {
          throw AIException(
            'Keine Verbindung zum Server. Bitte pruefe deine Internetverbindung.',
            isRetryable: true,
            code: 'CONNECTION_ERROR',
            traceId: traceId,
          );
        }
        throw AIException(
          'Verbindungsfehler: ${e.message ?? "Unbekannter Fehler"}',
          code: errorCode ?? 'NETWORK_ERROR',
          traceId: traceId,
        );
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

  // Standort-Informationen (für standortbasierte Empfehlungen)
  final double? userLatitude;
  final double? userLongitude;
  final String? userLocationName;

  // Wetter-Informationen (v1.8.0 - für AI Trip Advisor)
  final String? overallWeather;
  final Map<int, String>? dayWeather;
  final int? selectedDay;
  final int? totalDays;
  final Set<String>? preferredCategories;

  TripContext({
    this.route,
    this.stops = const [],
    this.userLatitude,
    this.userLongitude,
    this.userLocationName,
    this.overallWeather,
    this.dayWeather,
    this.selectedDay,
    this.totalDays,
    this.preferredCategories,
  });

  /// Hat der Kontext Standort-Informationen?
  bool get hasUserLocation => userLatitude != null && userLongitude != null;

  /// Hat der Kontext Wetter-Informationen?
  bool get hasWeatherInfo => overallWeather != null || dayWeather != null;
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

/// AI Exception mit optionalem Retry-Hinweis
class AIException implements Exception {
  final String message;

  /// Ob der Fehler voruebergehend ist und ein Retry sinnvoll waere
  final bool isRetryable;
  final String code;
  final String? traceId;

  AIException(
    this.message, {
    this.isRetryable = false,
    this.code = 'UNKNOWN_ERROR',
    this.traceId,
  });

  @override
  String toString() =>
      'AIException(code: $code, traceId: ${traceId ?? "n/a"}, message: $message)';
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

/// AI Trip-Optimierungsergebnis (v1.8.0)
class AITripOptimization {
  final List<AIOptimizationSuggestion> suggestions;
  final String summary;

  AITripOptimization({
    required this.suggestions,
    required this.summary,
  });
}

/// Einzelner Optimierungsvorschlag
class AIOptimizationSuggestion {
  final String message;
  final String type; // weather, optimization, alternative, general
  final int? dayNumber;

  AIOptimizationSuggestion({
    required this.message,
    required this.type,
    this.dayNumber,
  });
}

enum AIPoiSuggestionMode { dayEditor, chatNearby }

class AIPoiSuggestionRequest {
  final AIPoiSuggestionMode mode;
  final String? language;
  final AIPoiSuggestionUserContext? userContext;
  final AIPoiSuggestionTripContext? tripContext;
  final AIPoiSuggestionConstraints? constraints;
  final List<AIPoiSuggestionCandidate> candidates;

  AIPoiSuggestionRequest({
    required this.mode,
    this.language,
    this.userContext,
    this.tripContext,
    this.constraints,
    required this.candidates,
  });

  Map<String, dynamic> toJson() => {
        'mode': mode == AIPoiSuggestionMode.dayEditor
            ? 'day_editor'
            : 'chat_nearby',
        if (language != null) 'language': language,
        if (userContext != null) 'userContext': userContext!.toJson(),
        if (tripContext != null) 'tripContext': tripContext!.toJson(),
        if (constraints != null) 'constraints': constraints!.toJson(),
        'candidates': candidates.map((c) => c.toJson()).toList(),
      };
}

class AIPoiSuggestionUserContext {
  final double? lat;
  final double? lng;
  final String? locationName;
  final WeatherCondition? weatherCondition;
  final int? selectedDay;
  final int? totalDays;

  AIPoiSuggestionUserContext({
    this.lat,
    this.lng,
    this.locationName,
    this.weatherCondition,
    this.selectedDay,
    this.totalDays,
  });

  Map<String, dynamic> toJson() => {
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        if (locationName != null) 'locationName': locationName,
        if (weatherCondition != null)
          'weatherCondition': switch (weatherCondition!) {
            WeatherCondition.good => 'good',
            WeatherCondition.mixed => 'mixed',
            WeatherCondition.bad => 'bad',
            WeatherCondition.danger => 'danger',
            WeatherCondition.unknown => 'unknown',
          },
        if (selectedDay != null) 'selectedDay': selectedDay,
        if (totalDays != null) 'totalDays': totalDays,
      };
}

class AIPoiSuggestionTripContext {
  final String? routeStart;
  final String? routeEnd;
  final List<AIPoiSuggestionStop> stops;

  AIPoiSuggestionTripContext({
    this.routeStart,
    this.routeEnd,
    this.stops = const [],
  });

  Map<String, dynamic> toJson() => {
        if (routeStart != null) 'routeStart': routeStart,
        if (routeEnd != null) 'routeEnd': routeEnd,
        if (stops.isNotEmpty) 'stops': stops.map((s) => s.toJson()).toList(),
      };
}

class AIPoiSuggestionStop {
  final String id;
  final String name;
  final String? categoryId;
  final int? day;

  AIPoiSuggestionStop({
    required this.id,
    required this.name,
    this.categoryId,
    this.day,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (categoryId != null) 'categoryId': categoryId,
        if (day != null) 'day': day,
      };
}

class AIPoiSuggestionConstraints {
  final int? maxSuggestions;
  final bool? allowSwap;

  AIPoiSuggestionConstraints({this.maxSuggestions, this.allowSwap});

  Map<String, dynamic> toJson() => {
        if (maxSuggestions != null) 'maxSuggestions': maxSuggestions,
        if (allowSwap != null) 'allowSwap': allowSwap,
      };
}

class AIPoiSuggestionCandidate {
  final String id;
  final String name;
  final String categoryId;
  final double lat;
  final double lng;
  final double score;
  final bool isMustSee;
  final bool isCurated;
  final bool isUnesco;
  final bool isIndoor;
  final double? detourKm;
  final double? routePosition;
  final String? imageUrl;
  final String? shortDescription;
  final List<String>? tags;

  AIPoiSuggestionCandidate({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.lat,
    required this.lng,
    required this.score,
    required this.isMustSee,
    required this.isCurated,
    required this.isUnesco,
    required this.isIndoor,
    this.detourKm,
    this.routePosition,
    this.imageUrl,
    this.shortDescription,
    this.tags,
  });

  factory AIPoiSuggestionCandidate.fromPOI(POI poi) {
    return AIPoiSuggestionCandidate(
      id: poi.id,
      name: poi.name,
      categoryId: poi.categoryId,
      lat: poi.latitude,
      lng: poi.longitude,
      score: poi.score.toDouble(),
      isMustSee: poi.isMustSee,
      isCurated: poi.isCurated,
      isUnesco: poi.isUnesco,
      isIndoor: poi.isIndoor,
      detourKm: poi.detourKm,
      routePosition: poi.routePosition,
      imageUrl: poi.imageUrl,
      shortDescription: poi.shortDescription,
      tags: poi.tags,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'categoryId': categoryId,
        'lat': lat,
        'lng': lng,
        'score': score,
        'isMustSee': isMustSee,
        'isCurated': isCurated,
        'isUnesco': isUnesco,
        'isIndoor': isIndoor,
        if (detourKm != null) 'detourKm': detourKm,
        if (routePosition != null) 'routePosition': routePosition,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (shortDescription != null) 'shortDescription': shortDescription,
        if (tags != null) 'tags': tags,
      };
}

class AIPoiSuggestion {
  final String poiId;
  final String action;
  final String? targetPoiId;
  final String reason;
  final double relevance;
  final List<String> highlights;
  final String longDescription;

  AIPoiSuggestion({
    required this.poiId,
    required this.action,
    this.targetPoiId,
    required this.reason,
    required this.relevance,
    this.highlights = const [],
    required this.longDescription,
  });

  factory AIPoiSuggestion.fromJson(Map<String, dynamic> json) {
    return AIPoiSuggestion(
      poiId: (json['poiId'] ?? '').toString(),
      action: (json['action'] ?? 'add').toString(),
      targetPoiId: json['targetPoiId']?.toString(),
      reason: (json['reason'] ?? '').toString(),
      relevance:
          ((json['relevance'] as num?)?.toDouble() ?? 0.5).clamp(0.0, 1.0),
      highlights: ((json['highlights'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      longDescription: (json['longDescription'] ?? '').toString(),
    );
  }
}

class AIPoiSuggestionResponse {
  final String summary;
  final List<AIPoiSuggestion> suggestions;
  final String? source;
  final int? tokensUsed;
  final String? traceId;

  AIPoiSuggestionResponse({
    required this.summary,
    required this.suggestions,
    this.source,
    this.tokensUsed,
    this.traceId,
  });

  factory AIPoiSuggestionResponse.fromJson(Map<String, dynamic> json) {
    final rawSuggestions = (json['suggestions'] as List?) ?? const [];
    return AIPoiSuggestionResponse(
      summary: (json['summary'] ?? '').toString(),
      suggestions: rawSuggestions
          .whereType<Map>()
          .map((e) => AIPoiSuggestion.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      source: json['source']?.toString(),
      tokensUsed: (json['tokensUsed'] as num?)?.toInt(),
      traceId: json['traceId']?.toString(),
    );
  }
}

class AIPoiSuggestionBundle {
  final POI poi;
  final AIPoiSuggestion suggestion;
  final List<String> photoUrls;

  AIPoiSuggestionBundle({
    required this.poi,
    required this.suggestion,
    this.photoUrls = const [],
  });
}

/// Riverpod Provider für AIService
@riverpod
AIService aiService(AiServiceRef ref) {
  debugPrint(
      '[AI] AIService initialisiert (Backend-Proxy: ${ApiConfig.backendBaseUrl})');
  return AIService();
}
