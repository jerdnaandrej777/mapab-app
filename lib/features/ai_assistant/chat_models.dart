import '../../data/models/poi.dart';

sealed class ChatUiMessage {
  final String content;
  final bool isUser;

  const ChatUiMessage({
    required this.content,
    required this.isUser,
  });
}

class TextMessage extends ChatUiMessage {
  const TextMessage({
    required super.content,
    required super.isUser,
  });
}

class SystemMessage extends ChatUiMessage {
  final List<CopilotAction> actions;

  const SystemMessage({
    required super.content,
    this.actions = const [],
  }) : super(isUser: false);
}

class PoiListMessage extends ChatUiMessage {
  final List<POI> pois;
  final Map<String, AiPoiMeta> aiMeta;

  const PoiListMessage({
    required super.content,
    required this.pois,
    this.aiMeta = const {},
  }) : super(isUser: false);

  PoiListMessage copyWith({
    String? content,
    List<POI>? pois,
    Map<String, AiPoiMeta>? aiMeta,
  }) {
    return PoiListMessage(
      content: content ?? this.content,
      pois: pois ?? this.pois,
      aiMeta: aiMeta ?? this.aiMeta,
    );
  }
}

class AiPoiMeta {
  final String? reason;
  final List<String> highlights;
  final String? longDescription;
  final List<String> photoUrls;

  const AiPoiMeta({
    this.reason,
    this.highlights = const [],
    this.longDescription,
    this.photoUrls = const [],
  });

  AiPoiMeta copyWith({
    String? reason,
    List<String>? highlights,
    String? longDescription,
    List<String>? photoUrls,
  }) {
    return AiPoiMeta(
      reason: reason ?? this.reason,
      highlights: highlights ?? this.highlights,
      longDescription: longDescription ?? this.longDescription,
      photoUrls: photoUrls ?? this.photoUrls,
    );
  }

  factory AiPoiMeta.fromDynamic(dynamic raw) {
    if (raw is! Map) {
      return const AiPoiMeta();
    }

    final highlightsRaw = raw['highlights'];
    final photoUrlsRaw = raw['photoUrls'];

    return AiPoiMeta(
      reason: raw['reason']?.toString().trim().isNotEmpty == true
          ? raw['reason'].toString().trim()
          : null,
      highlights: highlightsRaw is List
          ? highlightsRaw
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList()
          : const [],
      longDescription:
          raw['longDescription']?.toString().trim().isNotEmpty == true
              ? raw['longDescription'].toString().trim()
              : null,
      photoUrls: photoUrlsRaw is List
          ? photoUrlsRaw
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList()
          : const [],
    );
  }
}

enum ChatRequestKind { chat, nearby, tripPlan, randomTrip }

class ChatRequestToken {
  final int id;
  final ChatRequestKind kind;

  const ChatRequestToken({
    required this.id,
    required this.kind,
  });
}

class CopilotAction {
  final String id;
  final String label;

  const CopilotAction({
    required this.id,
    required this.label,
  });
}
