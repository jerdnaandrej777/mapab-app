import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/constants/api_keys.dart';
import '../models/poi.dart';
import '../models/route.dart';
import '../models/trip.dart';

part 'ai_service.g.dart';

/// Service für AI-Features via OpenAI GPT
/// Implementiert gemäß Plan für personalisierte Empfehlungen und Chatbot
class AIService {
  final Dio _dio;
  final String? _apiKey;

  /// Modell für einfache Anfragen (kosteneffizient)
  static const String modelMini = 'gpt-4o-mini';

  /// Modell für komplexe Planungen
  static const String modelPro = 'gpt-4o';

  AIService({Dio? dio, String? apiKey})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: 'https://api.openai.com/v1',
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 60),
            )),
        _apiKey = apiKey;

  /// Prüft ob API-Key konfiguriert ist
  bool get isConfigured => _apiKey != null && _apiKey!.isNotEmpty;

  /// Holt personalisierte POI-Empfehlungen
  Future<List<AIRecommendation>> getRecommendations({
    required AppRoute route,
    required List<POI> availablePOIs,
    required UserPreferences preferences,
  }) async {
    _checkApiKey();

    // Nur relevante POI-Daten senden (Token-Limit beachten)
    final poiSummary = availablePOIs
        .take(50)
        .map((p) => '${p.name} (${p.categoryIcon} ${p.categoryLabel}, ${p.detourKm?.toStringAsFixed(1) ?? "?"} km Umweg)')
        .join('\n');

    final response = await _chat(
      model: modelMini,
      systemPrompt: '''
Du bist ein Reise-Experte für Europa.
Analysiere die Route und Präferenzen des Nutzers.
Empfehle die 5 besten POIs mit kurzer Begründung.
Antworte im JSON-Format:
{
  "recommendations": [
    {"name": "POI-Name", "reason": "Kurze Begründung (max 50 Wörter)"}
  ]
}
''',
      userMessage: '''
Route: ${route.startAddress} → ${route.endAddress} (${route.formattedDistance}, ${route.formattedDuration})

Präferenzen:
- Bevorzugte Kategorien: ${preferences.preferredCategories.join(', ')}
- Maximaler Umweg: ${preferences.maxDetourKm} km
- Reisestil: ${preferences.travelStyle}

Verfügbare POIs:
$poiSummary
''',
    );

    try {
      final data = json.decode(response);
      final recommendations = data['recommendations'] as List;
      return recommendations
          .map((r) => AIRecommendation(
                name: r['name'] ?? '',
                reason: r['reason'] ?? '',
              ))
          .toList();
    } catch (e) {
      throw AIException('Empfehlungen konnten nicht geparst werden: $e');
    }
  }

  /// Generiert automatischen Reiseplan
  Future<AITripPlan> generateTripPlan({
    required String destination,
    required int days,
    required List<String> interests,
    String? startLocation,
  }) async {
    _checkApiKey();

    final response = await _chat(
      model: modelPro, // Komplexere Aufgabe, besseres Modell
      systemPrompt: '''
Du bist ein professioneller Reiseplaner für Europa.
Erstelle einen detaillierten ${days}-Tage Reiseplan für $destination.
Berücksichtige die Interessen: ${interests.join(', ')}
${startLocation != null ? 'Startpunkt: $startLocation' : ''}

Antworte im JSON-Format:
{
  "title": "Titel des Trips",
  "description": "Kurze Beschreibung (2-3 Sätze)",
  "days": [
    {
      "title": "Tag 1: Thema",
      "description": "Tagesbeschreibung",
      "stops": [
        {"name": "Sehenswürdigkeit", "category": "castle|museum|nature|etc", "duration": "2h", "description": "Warum besuchen"}
      ]
    }
  ]
}

Wichtig:
- Pro Tag 3-5 Stops empfehlen
- Realistische Zeitangaben
- Logische Reihenfolge (geografisch sinnvoll)
- Mischung aus bekannten und Geheimtipps
''',
      userMessage: '''
Erstelle einen $days-Tage Reiseplan für $destination.
Interessen: ${interests.join(', ')}
${startLocation != null ? 'Ich starte von: $startLocation' : ''}
''',
    );

    try {
      final data = json.decode(response);
      return AITripPlan(
        title: data['title'] ?? '$days Tage in $destination',
        description: data['description'],
        days: (data['days'] as List)
            .map((d) => AITripDay(
                  title: d['title'] ?? '',
                  description: d['description'],
                  stops: (d['stops'] as List)
                      .map((s) => AITripStop(
                            name: s['name'] ?? '',
                            category: s['category'] ?? 'attraction',
                            duration: s['duration'],
                            description: s['description'],
                          ))
                      .toList(),
                ))
            .toList(),
        model: modelPro,
        generatedAt: DateTime.now(),
      );
    } catch (e) {
      throw AIException('Reiseplan konnte nicht geparst werden: $e');
    }
  }

  /// Chatbot für natürlichsprachige Interaktion
  Future<String> chat({
    required String message,
    required TripContext context,
    List<ChatMessage>? history,
  }) async {
    _checkApiKey();

    // Kontext-String aufbauen
    final contextInfo = StringBuffer();
    if (context.route != null) {
      contextInfo.writeln('Aktuelle Route: ${context.route!.startAddress} → ${context.route!.endAddress}');
      contextInfo.writeln('Distanz: ${context.route!.formattedDistance}, Dauer: ${context.route!.formattedDuration}');
    }
    if (context.stops.isNotEmpty) {
      contextInfo.writeln('Geplante Stops: ${context.stops.map((s) => s.name).join(', ')}');
    }

    // Chat-Historie aufbauen
    final messages = <Map<String, String>>[];

    // System-Nachricht
    messages.add({
      'role': 'system',
      'content': '''
Du bist ein freundlicher Reiseassistent für eine europäische Reiseplanungs-App.
Antworte auf Deutsch, kurz und hilfreich (max 150 Wörter).

Aktueller Kontext:
$contextInfo

Du kannst:
- Fragen zur aktuellen Route beantworten
- Tipps zu Sehenswürdigkeiten geben
- Bei der Reiseplanung helfen
- Alternativen vorschlagen
''',
    });

    // Historie hinzufügen
    if (history != null) {
      for (final msg in history.take(10)) {
        // Letzte 10 Nachrichten
        messages.add({
          'role': msg.isUser ? 'user' : 'assistant',
          'content': msg.content,
        });
      }
    }

    // Aktuelle Nachricht
    messages.add({
      'role': 'user',
      'content': message,
    });

    return await _chatWithMessages(model: modelMini, messages: messages);
  }

  /// Interne Chat-Methode mit System/User Prompts
  Future<String> _chat({
    required String model,
    required String systemPrompt,
    required String userMessage,
  }) async {
    return await _chatWithMessages(
      model: model,
      messages: [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userMessage},
      ],
    );
  }

  /// Interne Chat-Methode mit Message-Liste
  Future<String> _chatWithMessages({
    required String model,
    required List<Map<String, String>> messages,
  }) async {
    debugPrint('[AI] Sende Anfrage an OpenAI...');
    debugPrint('[AI] Modell: $model');
    debugPrint('[AI] API-Key Präfix: ${_apiKey?.substring(0, 20) ?? "NICHT GESETZT"}...');

    try {
      final response = await _dio.post(
        '/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': model,
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 1500,
        },
      );

      debugPrint('[AI] ✓ Antwort erhalten, Status: ${response.statusCode}');
      final content = response.data['choices'][0]['message']['content'];
      debugPrint('[AI] Antwort-Länge: ${content?.length ?? 0} Zeichen');
      return content ?? '';
    } on DioException catch (e) {
      debugPrint('[AI] ✗ FEHLER: ${e.type}');
      debugPrint('[AI] Status-Code: ${e.response?.statusCode}');
      debugPrint('[AI] Response: ${e.response?.data}');
      debugPrint('[AI] Message: ${e.message}');

      if (e.response?.statusCode == 401) {
        final errorBody = e.response?.data;
        debugPrint('[AI] 401 Error Details: $errorBody');
        throw AIException('Ungültiger API-Key. Bitte unter https://platform.openai.com/api-keys prüfen.');
      } else if (e.response?.statusCode == 429) {
        throw AIException('Rate-Limit erreicht. Bitte warte kurz.');
      } else if (e.response?.statusCode == 402) {
        throw AIException('Kein Guthaben. Bitte unter https://platform.openai.com/account/billing aufladen.');
      } else if (e.response?.statusCode == 403) {
        throw AIException('Zugriff verweigert. API-Key hat keine Berechtigung für dieses Modell.');
      }
      throw AIException('AI-Anfrage fehlgeschlagen: ${e.message ?? "Unbekannter Fehler"}');
    } catch (e) {
      debugPrint('[AI] ✗ Unerwarteter Fehler: $e');
      throw AIException('Unerwarteter Fehler: $e');
    }
  }

  /// Prüft API-Key
  void _checkApiKey() {
    if (!isConfigured) {
      throw AIException(
          'OpenAI API-Key nicht konfiguriert. '
          'Registrieren Sie sich unter https://platform.openai.com');
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
  final List<TripStop> stops;

  TripContext({this.route, this.stops = const []});
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

/// Riverpod Provider für AIService
@riverpod
AIService aiService(AiServiceRef ref) {
  const apiKey = ApiKeys.openAiApiKey;
  debugPrint('[AI] AIService initialisiert, API-Key konfiguriert: ${apiKey.isNotEmpty}');
  return AIService(apiKey: apiKey.isNotEmpty ? apiKey : null);
}
