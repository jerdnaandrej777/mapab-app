import 'package:freezed_annotation/freezed_annotation.dart';
import '../../core/constants/categories.dart';

part 'trip_template.freezed.dart';
part 'trip_template.g.dart';

/// Vordefinierte Trip-Vorlage mit Empfehlungen
@freezed
class TripTemplate with _$TripTemplate {
  const TripTemplate._();

  const factory TripTemplate({
    /// Eindeutige ID
    required String id,

    /// Name der Vorlage (z.B. "Romantisches Wochenende")
    required String name,

    /// Beschreibung
    required String description,

    /// Emoji-Icon
    required String emoji,

    /// Empfohlene Anzahl Tage
    required int recommendedDays,

    /// Empfohlene POI-Kategorien
    required List<String> categories,

    /// Tags fuer Suche/Filter
    @Default([]) List<String> tags,

    /// Empfohlene Jahreszeit (optional)
    String? recommendedSeason,

    /// Zielgruppe
    @Default('alle') String targetAudience,

    /// Sortierreihenfolge
    @Default(0) int sortOrder,
  }) = _TripTemplate;

  factory TripTemplate.fromJson(Map<String, dynamic> json) =>
      _$TripTemplateFromJson(json);

  /// Konvertiert Kategorie-IDs zu POICategory-Objekten
  List<POICategory> get poiCategories => categories
      .map((id) => POICategory.values.firstWhere(
            (c) => c.id == id,
            orElse: () => POICategory.attraction,
          ))
      .toList();
}

/// Vordefinierte Templates (statisch, keine JSON-Datei noetig)
class TripTemplates {
  TripTemplates._();

  static final List<TripTemplate> all = [
    // Romantik & Paare
    const TripTemplate(
      id: 'romantic-weekend',
      name: 'Romantisches Wochenende',
      description: 'Burgen, Seen und malerische Aussichtspunkte fuer Verliebte',
      emoji: '💕',
      recommendedDays: 2,
      categories: ['castle', 'lake', 'viewpoint', 'restaurant'],
      tags: ['paare', 'romantik', 'wochenende'],
      targetAudience: 'paare',
      sortOrder: 1,
    ),

    // Kultur & Geschichte
    const TripTemplate(
      id: 'culture-tour',
      name: 'Kulturreise',
      description: 'Museen, UNESCO-Staetten und historische Monumente',
      emoji: '🏛️',
      recommendedDays: 3,
      categories: ['museum', 'unesco', 'monument', 'church', 'city'],
      tags: ['kultur', 'geschichte', 'bildung'],
      targetAudience: 'alle',
      sortOrder: 2,
    ),

    // Natur & Outdoor
    const TripTemplate(
      id: 'nature-escape',
      name: 'Natur-Auszeit',
      description: 'Parks, Seen und atemberaubende Naturlandschaften',
      emoji: '🌲',
      recommendedDays: 4,
      categories: ['nature', 'park', 'lake', 'viewpoint'],
      tags: ['natur', 'wandern', 'outdoor', 'erholung'],
      recommendedSeason: 'fruehling-herbst',
      targetAudience: 'alle',
      sortOrder: 3,
    ),

    // Familie
    const TripTemplate(
      id: 'family-fun',
      name: 'Familienspass',
      description: 'Freizeitparks, Zoos und kinderfreundliche Aktivitaeten',
      emoji: '👨‍👩‍👧‍👦',
      recommendedDays: 3,
      categories: ['activity', 'park', 'nature', 'museum'],
      tags: ['familie', 'kinder', 'spass', 'erlebnis'],
      targetAudience: 'familien',
      sortOrder: 4,
    ),

    // Staedtetrip
    const TripTemplate(
      id: 'city-hopping',
      name: 'Staedtetrip',
      description: 'Erkunde europaeische Staedte und ihre Highlights',
      emoji: '🏙️',
      recommendedDays: 5,
      categories: ['city', 'museum', 'restaurant', 'monument', 'church'],
      tags: ['stadt', 'urban', 'sightseeing'],
      targetAudience: 'alle',
      sortOrder: 5,
    ),

    // Abenteuer
    const TripTemplate(
      id: 'adventure-trip',
      name: 'Abenteuer-Trip',
      description: 'Aktivitaeten, Freizeitparks und aufregende Erlebnisse',
      emoji: '🎢',
      recommendedDays: 4,
      categories: ['activity', 'nature', 'viewpoint'],
      tags: ['abenteuer', 'action', 'sport', 'erlebnis'],
      targetAudience: 'abenteurer',
      sortOrder: 6,
    ),

    // Strand & Kueste
    const TripTemplate(
      id: 'beach-vibes',
      name: 'Strand & Kueste',
      description: 'Strande, Kuestenorte und maritimes Flair',
      emoji: '🏖️',
      recommendedDays: 5,
      categories: ['coast', 'lake', 'nature', 'restaurant'],
      tags: ['strand', 'meer', 'kueste', 'sommer'],
      recommendedSeason: 'sommer',
      targetAudience: 'alle',
      sortOrder: 7,
    ),

    // Burgen & Schloesser
    const TripTemplate(
      id: 'castle-tour',
      name: 'Burgen & Schloesser',
      description: 'Majestaetische Burgen und historische Schloesser',
      emoji: '🏰',
      recommendedDays: 3,
      categories: ['castle', 'museum', 'park', 'restaurant'],
      tags: ['burgen', 'schloesser', 'geschichte', 'mittelalter'],
      targetAudience: 'alle',
      sortOrder: 8,
    ),

    // Entspannung
    const TripTemplate(
      id: 'wellness-retreat',
      name: 'Wellness & Entspannung',
      description: 'Ruhige Orte, Seen und erholsame Natur',
      emoji: '🧘',
      recommendedDays: 2,
      categories: ['lake', 'nature', 'park', 'hotel'],
      tags: ['wellness', 'entspannung', 'ruhe', 'erholung'],
      targetAudience: 'alle',
      sortOrder: 9,
    ),

    // Kulinarik
    const TripTemplate(
      id: 'foodie-tour',
      name: 'Kulinarische Reise',
      description: 'Restaurants, Weingegenden und regionale Spezialitaeten',
      emoji: '🍷',
      recommendedDays: 3,
      categories: ['restaurant', 'city', 'nature', 'viewpoint'],
      tags: ['essen', 'wein', 'kulinarik', 'genuss'],
      targetAudience: 'feinschmecker',
      sortOrder: 10,
    ),

    // Fotografie
    const TripTemplate(
      id: 'photo-tour',
      name: 'Foto-Tour',
      description: 'Fotogene Orte, Aussichtspunkte und Instagram-Spots',
      emoji: '📸',
      recommendedDays: 4,
      categories: ['viewpoint', 'castle', 'nature', 'lake', 'coast'],
      tags: ['fotografie', 'instagram', 'bilder', 'landschaft'],
      targetAudience: 'fotografen',
      sortOrder: 11,
    ),

    // Schneller Trip
    const TripTemplate(
      id: 'quick-escape',
      name: 'Schneller Tagesausflug',
      description: 'Perfekt fuer einen spontanen Tag unterwegs',
      emoji: '⚡',
      recommendedDays: 1,
      categories: ['viewpoint', 'nature', 'castle', 'lake'],
      tags: ['tagesausflug', 'spontan', 'kurz'],
      targetAudience: 'alle',
      sortOrder: 0,
    ),
  ];

  /// Templates nach Zielgruppe filtern
  static List<TripTemplate> forAudience(String audience) {
    if (audience == 'alle') return all;
    return all.where((t) => t.targetAudience == audience || t.targetAudience == 'alle').toList();
  }

  /// Template nach ID finden
  static TripTemplate? findById(String id) {
    try {
      return all.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }
}
