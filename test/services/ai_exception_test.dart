import 'package:flutter_test/flutter_test.dart';
import 'package:travel_planner/data/services/ai_service.dart';

void main() {
  group('AIException', () {
    test('hat message und isRetryable default false', () {
      final ex = AIException('Test-Fehler');
      expect(ex.message, 'Test-Fehler');
      expect(ex.isRetryable, isFalse);
    });

    test('isRetryable kann explizit gesetzt werden', () {
      final ex = AIException('Timeout', isRetryable: true);
      expect(ex.message, 'Timeout');
      expect(ex.isRetryable, isTrue);
    });

    test('toString formatiert korrekt', () {
      final ex = AIException('Server-Fehler');
      expect(ex.toString(), 'AIException: Server-Fehler');
    });

    test('ist eine Exception', () {
      final ex = AIException('Test');
      expect(ex, isA<Exception>());
    });

    test('nicht-retryable Fehler: Rate-Limit', () {
      // 429 Tageslimit ist nicht retryable (muss morgen erneut versucht werden)
      final ex = AIException('Tageslimit erreicht');
      expect(ex.isRetryable, isFalse);
    });

    test('retryable Fehler: Timeout', () {
      final ex = AIException('Zeitüberschreitung', isRetryable: true);
      expect(ex.isRetryable, isTrue);
    });

    test('retryable Fehler: 503 Service Unavailable', () {
      final ex = AIException('Vorübergehend nicht verfügbar', isRetryable: true);
      expect(ex.isRetryable, isTrue);
    });
  });

  group('AIService Konfiguration', () {
    test('isConfigured ist immer true (Backend-Proxy)', () {
      final service = AIService();
      expect(service.isConfigured, isTrue);
    });
  });

  group('TripContext', () {
    test('Standard-Kontext hat keine Location', () {
      final ctx = TripContext();
      expect(ctx.hasUserLocation, isFalse);
      expect(ctx.hasWeatherInfo, isFalse);
      expect(ctx.stops, isEmpty);
    });

    test('hasUserLocation ist true mit lat/lng', () {
      final ctx = TripContext(
        userLatitude: 48.0,
        userLongitude: 11.0,
        userLocationName: 'München',
      );
      expect(ctx.hasUserLocation, isTrue);
    });

    test('hasUserLocation ist false mit nur lat', () {
      final ctx = TripContext(userLatitude: 48.0);
      expect(ctx.hasUserLocation, isFalse);
    });

    test('hasWeatherInfo ist true mit overallWeather', () {
      final ctx = TripContext(overallWeather: 'good');
      expect(ctx.hasWeatherInfo, isTrue);
    });

    test('hasWeatherInfo ist true mit dayWeather', () {
      final ctx = TripContext(dayWeather: {1: 'bad', 2: 'good'});
      expect(ctx.hasWeatherInfo, isTrue);
    });
  });

  group('ChatMessage', () {
    test('hat content und isUser', () {
      final msg = ChatMessage(content: 'Hallo', isUser: true);
      expect(msg.content, 'Hallo');
      expect(msg.isUser, isTrue);
      expect(msg.timestamp, isNotNull);
    });

    test('timestamp wird automatisch gesetzt', () {
      final before = DateTime.now();
      final msg = ChatMessage(content: 'Test', isUser: false);
      final after = DateTime.now();

      expect(msg.timestamp.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
      expect(msg.timestamp.isBefore(after.add(const Duration(seconds: 1))), isTrue);
    });

    test('custom timestamp wird uebernommen', () {
      final custom = DateTime(2024, 1, 15);
      final msg = ChatMessage(content: 'Test', isUser: true, timestamp: custom);
      expect(msg.timestamp, custom);
    });
  });

  group('UserPreferences', () {
    test('Defaults', () {
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
}
