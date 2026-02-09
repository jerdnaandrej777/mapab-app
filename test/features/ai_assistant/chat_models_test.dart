import 'package:flutter_test/flutter_test.dart';
import 'package:travel_planner/features/ai_assistant/chat_models.dart';

void main() {
  group('AiPoiMeta.fromDynamic', () {
    test('returns empty meta for non-map payload', () {
      final meta = AiPoiMeta.fromDynamic('invalid');
      expect(meta.reason, isNull);
      expect(meta.highlights, isEmpty);
      expect(meta.longDescription, isNull);
      expect(meta.photoUrls, isEmpty);
    });

    test('parses and trims valid fields', () {
      final meta = AiPoiMeta.fromDynamic({
        'reason': '  Great for rain  ',
        'highlights': [' Indoor ', '', 'Top pick'],
        'longDescription': '  Detailed text ',
        'photoUrls': [' https://example.com/a.jpg ', '', 'x'],
      });

      expect(meta.reason, 'Great for rain');
      expect(meta.highlights, ['Indoor', 'Top pick']);
      expect(meta.longDescription, 'Detailed text');
      expect(meta.photoUrls, ['https://example.com/a.jpg', 'x']);
    });

    test('ignores malformed list fields', () {
      final meta = AiPoiMeta.fromDynamic({
        'reason': 'ok',
        'highlights': 'not-a-list',
        'photoUrls': 123,
      });

      expect(meta.reason, 'ok');
      expect(meta.highlights, isEmpty);
      expect(meta.photoUrls, isEmpty);
    });
  });

  group('Chat request token', () {
    test('stores id and kind', () {
      const token = ChatRequestToken(id: 7, kind: ChatRequestKind.nearby);
      expect(token.id, 7);
      expect(token.kind, ChatRequestKind.nearby);
    });
  });
}
