import 'package:flutter_test/flutter_test.dart';
import 'package:travel_planner/core/constants/categories.dart';
import 'package:travel_planner/data/models/poi.dart';
import 'package:travel_planner/data/services/ai_service.dart';

void main() {
  group('AIException', () {
    test('has message and default flags', () {
      final ex = AIException('Test error');
      expect(ex.message, 'Test error');
      expect(ex.isRetryable, isFalse);
      expect(ex.code, 'UNKNOWN_ERROR');
      expect(ex.traceId, isNull);
    });

    test('supports code and traceId', () {
      final ex = AIException(
        'Timeout',
        isRetryable: true,
        code: 'TIMEOUT',
        traceId: 'trace-123',
      );
      expect(ex.isRetryable, isTrue);
      expect(ex.code, 'TIMEOUT');
      expect(ex.traceId, 'trace-123');
    });

    test('toString includes key fields', () {
      final ex = AIException('Server error', code: 'SERVER_ERROR');
      expect(ex.toString(), contains('SERVER_ERROR'));
      expect(ex.toString(), contains('Server error'));
    });

    test('is Exception', () {
      final ex = AIException('Test');
      expect(ex, isA<Exception>());
    });
  });

  group('AIService config', () {
    test('isConfigured stays true with backend proxy', () {
      final service = AIService();
      expect(service.isConfigured, isTrue);
    });
  });

  group('TripContext', () {
    test('default context has no location', () {
      final ctx = TripContext();
      expect(ctx.hasUserLocation, isFalse);
      expect(ctx.hasWeatherInfo, isFalse);
      expect(ctx.stops, isEmpty);
    });

    test('hasUserLocation true with lat/lng', () {
      final ctx = TripContext(
        userLatitude: 48.0,
        userLongitude: 11.0,
        userLocationName: 'Munich',
      );
      expect(ctx.hasUserLocation, isTrue);
    });

    test('hasUserLocation false with only lat', () {
      final ctx = TripContext(userLatitude: 48.0);
      expect(ctx.hasUserLocation, isFalse);
    });

    test('hasWeatherInfo true with overallWeather', () {
      final ctx = TripContext(overallWeather: 'good');
      expect(ctx.hasWeatherInfo, isTrue);
    });

    test('hasWeatherInfo true with dayWeather', () {
      final ctx = TripContext(dayWeather: {1: 'bad', 2: 'good'});
      expect(ctx.hasWeatherInfo, isTrue);
    });
  });

  group('ChatMessage', () {
    test('has content and isUser', () {
      final msg = ChatMessage(content: 'Hello', isUser: true);
      expect(msg.content, 'Hello');
      expect(msg.isUser, isTrue);
      expect(msg.timestamp, isNotNull);
    });

    test('timestamp is auto-set', () {
      final before = DateTime.now();
      final msg = ChatMessage(content: 'Test', isUser: false);
      final after = DateTime.now();

      expect(msg.timestamp.isAfter(before.subtract(const Duration(seconds: 1))),
          isTrue);
      expect(msg.timestamp.isBefore(after.add(const Duration(seconds: 1))),
          isTrue);
    });

    test('custom timestamp is used', () {
      final custom = DateTime(2024, 1, 15);
      final msg = ChatMessage(content: 'Test', isUser: true, timestamp: custom);
      expect(msg.timestamp, custom);
    });
  });

  group('UserPreferences', () {
    test('defaults', () {
      final prefs = UserPreferences();
      expect(prefs.preferredCategories, isEmpty);
      expect(prefs.maxDetourKm, 45);
      expect(prefs.travelStyle, 'balanced');
    });

    test('toJson', () {
      final prefs = UserPreferences(
        preferredCategories: ['museum', 'castle'],
        maxDetourKm: 30,
        travelStyle: 'relaxed',
      );
      final json = prefs.toJson();
      expect(json['preferredCategories'], ['museum', 'castle']);
      expect(json['maxDetourKm'], 30);
      expect(json['travelStyle'], 'relaxed');
    });
  });

  group('AIPoiSuggestion models', () {
    test('AIPoiSuggestionRequest serializes chat_nearby', () {
      const poi = POI(
        id: 'poi-1',
        name: 'Test Castle',
        latitude: 48.1,
        longitude: 11.5,
        categoryId: 'castle',
        score: 88,
        tags: const ['unesco'],
      );

      final request = AIPoiSuggestionRequest(
        mode: AIPoiSuggestionMode.chatNearby,
        language: 'de',
        userContext: AIPoiSuggestionUserContext(
          lat: 48.1,
          lng: 11.5,
          locationName: 'Munich',
          weatherCondition: WeatherCondition.bad,
        ),
        constraints: AIPoiSuggestionConstraints(
          maxSuggestions: 8,
          allowSwap: false,
        ),
        candidates: [AIPoiSuggestionCandidate.fromPOI(poi)],
      );

      final json = request.toJson();
      expect(json['mode'], 'chat_nearby');
      expect(json['language'], 'de');
      expect(json['constraints']['maxSuggestions'], 8);
      expect(json['constraints']['allowSwap'], isFalse);
      expect((json['candidates'] as List).length, 1);
      expect((json['candidates'] as List).first['id'], 'poi-1');
    });

    test('AIPoiSuggestionResponse parses and clamps relevance', () {
      final response = AIPoiSuggestionResponse.fromJson({
        'summary': 'Top picks',
        'source': 'ai',
        'tokensUsed': 123,
        'traceId': 'trace-xyz',
        'suggestions': [
          {
            'poiId': 'poi-1',
            'action': 'add',
            'reason': 'Perfect fit',
            'relevance': 3.8,
            'highlights': ['Must-See', 'UNESCO'],
            'longDescription': 'Long description',
          },
        ],
      });

      expect(response.summary, 'Top picks');
      expect(response.source, 'ai');
      expect(response.tokensUsed, 123);
      expect(response.traceId, 'trace-xyz');
      expect(response.suggestions, hasLength(1));
      expect(response.suggestions.first.poiId, 'poi-1');
      expect(response.suggestions.first.relevance, 1.0);
      expect(response.suggestions.first.highlights, contains('UNESCO'));
    });
  });
}
