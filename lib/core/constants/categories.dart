/// POI-Kategorien mit Icons und Farben
/// Übernommen von MapAB js/config/constants.js

enum POICategory {
  castle('castle', '🏰', 'Schlösser & Burgen', 0xFFB8860B),
  nature('nature', '🌲', 'Natur & Wälder', 0xFF228B22),
  museum('museum', '🏛️', 'Museen', 0xFF8B4513),
  viewpoint('viewpoint', '🏔️', 'Aussichtspunkte', 0xFF4169E1),
  lake('lake', '🏞️', 'Seen', 0xFF1E90FF),
  coast('coast', '🏖️', 'Küsten & Strände', 0xFFFFD700),
  park('park', '🌳', 'Parks & Nationalparks', 0xFF32CD32),
  city('city', '🏙️', 'Städte', 0xFF696969),
  activity('activity', '🎿', 'Aktivitäten', 0xFFFF6347),
  hotel('hotel', '🏨', 'Hotels', 0xFF9370DB),
  restaurant('restaurant', '🍽️', 'Restaurants', 0xFFFF8C00),
  unesco('unesco', '🌍', 'UNESCO-Welterbe', 0xFF00CED1),
  church('church', '⛪', 'Kirchen', 0xFFA0522D),
  monument('monument', '🗿', 'Monumente', 0xFF778899),
  attraction('attraction', '🎡', 'Attraktionen', 0xFFFF1493);

  final String id;
  final String icon;
  final String label;
  final int colorValue;

  const POICategory(this.id, this.icon, this.label, this.colorValue);

  /// Kategorie nach ID finden
  static POICategory? fromId(String id) {
    try {
      return POICategory.values.firstWhere((cat) => cat.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Nur Indoor-Kategorien (für Wetter-Filter)
  static List<POICategory> get indoorCategories => [
        POICategory.museum,
        POICategory.church,
        POICategory.restaurant,
        POICategory.hotel,
      ];

  /// Kategorien die auch bei schlechtem Wetter besucht werden koennen
  /// (haben signifikante Indoor-Anteile oder Ueberdachung)
  static List<POICategory> get weatherResilientCategories => [
        ...indoorCategories,
        POICategory.castle,   // Innenraeume, Ausstellungen, Fuehrungen
        POICategory.activity, // Aquarien, Hallenbaeder, Indoor-Parks
      ];

  /// Ist diese Kategorie Indoor?
  bool get isIndoor => indoorCategories.contains(this);

  /// Ist auch bei schlechtem Wetter empfehlenswert?
  bool get isWeatherResilient => weatherResilientCategories.contains(this);
}

/// Erlebnis-Level für Umweg-Filter
/// Übernommen von MapAB js/config/settings.js
class ExperienceLevel {
  final String label;
  final int detourKm;

  const ExperienceLevel({required this.label, required this.detourKm});

  static const List<ExperienceLevel> levels = [
    ExperienceLevel(label: '+15 km Umweg', detourKm: 15),
    ExperienceLevel(label: '+30 km Umweg', detourKm: 30),
    ExperienceLevel(label: '+45 km Umweg', detourKm: 45), // Default
    ExperienceLevel(label: '+60 km Umweg', detourKm: 60),
    ExperienceLevel(label: '+80 km Umweg', detourKm: 80),
  ];

  static const int defaultIndex = 2; // +45 km
}

/// Trip-Modi
enum TripType {
  daytrip('Tagesausflug', '30-200 km', 'Aktivitäts-Auswahl, Wetter-basiert'),
  eurotrip('Euro Trip', '200-800 km', 'Anderes Land, Hotel-Vorschläge'),
  multiday('Mehrtages-Trip', '2-7 Tage', 'Automatische Übernachtungs-Stops'),
  scenic('Scenic Route', 'variabel', 'Aussichtspunkte priorisiert');

  final String label;
  final String distance;
  final String description;

  const TripType(this.label, this.distance, this.description);
}

/// Wetter-Zustände
enum WeatherCondition {
  good('Gut', '☀️'),
  mixed('Wechselhaft', '⛅'),
  bad('Schlecht', '🌧️'),
  danger('Gefährlich', '⚠️'),
  unknown('Unbekannt', '❓');

  final String label;
  final String icon;

  const WeatherCondition(this.label, this.icon);

  /// Zentrales Mapping: WMO Weather Code → WeatherCondition
  /// https://open-meteo.com/en/docs (WMO Weather interpretation codes)
  static WeatherCondition fromWmoCode(int code) {
    if (code == 0 || code == 1) return WeatherCondition.good;
    if (code <= 3) return WeatherCondition.mixed;
    if (code >= 45 && code <= 48) return WeatherCondition.bad; // Nebel
    if (code >= 95) return WeatherCondition.danger; // Gewitter
    return WeatherCondition.bad; // Regen, Schnee, Schauer
  }

  /// Prueft ob ein WMO-Code Schnee bedeutet (71-77, 85-86)
  static bool isSnowCode(int code) =>
      (code >= 71 && code <= 77) || code == 85 || code == 86;

  /// Prueft ob ein WMO-Code Regen bedeutet (51-67, 80-82)
  static bool isRainCode(int code) =>
      (code >= 51 && code <= 67) || (code >= 80 && code <= 82);
}

/// Barrierefreiheits-Optionen
enum AccessibilityFeature {
  wheelchair('Rollstuhlgerecht', '♿', 'wheelchair'),
  noStairs('Ohne Treppen', '🚫🪜', 'no_stairs'),
  parking('Behindertenparkplatz', '🅿️♿', 'disabled_parking'),
  toilet('Behindertentoilette', '🚻♿', 'disabled_toilet'),
  elevator('Aufzug vorhanden', '🛗', 'elevator'),
  braille('Blindenschrift', '⠿', 'braille'),
  audioGuide('Audio-Guide', '🎧', 'audio_guide'),
  signLanguage('Gebärdensprache', '🤟', 'sign_language'),
  assistDogs('Assistenzhunde erlaubt', '🦮', 'assist_dogs');

  final String label;
  final String icon;
  final String osmKey;

  const AccessibilityFeature(this.label, this.icon, this.osmKey);
}

/// OSM Wheelchair-Werte
enum WheelchairAccessibility {
  yes('Vollständig zugänglich', '♿', 0xFF4CAF50),
  limited('Eingeschränkt zugänglich', '♿⚠️', 0xFFFFC107),
  no('Nicht zugänglich', '🚫♿', 0xFFF44336),
  unknown('Unbekannt', '❓', 0xFF9E9E9E);

  final String label;
  final String icon;
  final int colorValue;

  const WheelchairAccessibility(this.label, this.icon, this.colorValue);

  static WheelchairAccessibility fromOsmValue(String? value) {
    switch (value?.toLowerCase()) {
      case 'yes':
        return WheelchairAccessibility.yes;
      case 'limited':
        return WheelchairAccessibility.limited;
      case 'no':
        return WheelchairAccessibility.no;
      default:
        return WheelchairAccessibility.unknown;
    }
  }
}

/// POI-Highlights für besondere Auszeichnungen
enum POIHighlight {
  unesco('🌍', 'UNESCO-Welterbe', 0xFF00CED1),
  mustSee('⭐', 'Must-See', 0xFFFFD700),
  secret('💎', 'Geheimtipp', 0xFF9370DB),
  historic('🏛️', 'Historisch', 0xFFA0522D),
  familyFriendly('👨‍👩‍👧‍👦', 'Familienfreundlich', 0xFF4CAF50);

  final String icon;
  final String label;
  final int colorValue;

  const POIHighlight(this.icon, this.label, this.colorValue);
}

/// Barrierefreiheits-Filter-Einstellungen
class AccessibilityFilter {
  final bool requireWheelchair;
  final bool requireNoStairs;
  final bool requireParking;
  final bool requireToilet;
  final bool requireElevator;
  final bool showUnknown;  // POIs ohne Daten anzeigen

  const AccessibilityFilter({
    this.requireWheelchair = false,
    this.requireNoStairs = false,
    this.requireParking = false,
    this.requireToilet = false,
    this.requireElevator = false,
    this.showUnknown = true,
  });

  bool get hasAnyFilter =>
      requireWheelchair ||
      requireNoStairs ||
      requireParking ||
      requireToilet ||
      requireElevator;

  AccessibilityFilter copyWith({
    bool? requireWheelchair,
    bool? requireNoStairs,
    bool? requireParking,
    bool? requireToilet,
    bool? requireElevator,
    bool? showUnknown,
  }) {
    return AccessibilityFilter(
      requireWheelchair: requireWheelchair ?? this.requireWheelchair,
      requireNoStairs: requireNoStairs ?? this.requireNoStairs,
      requireParking: requireParking ?? this.requireParking,
      requireToilet: requireToilet ?? this.requireToilet,
      requireElevator: requireElevator ?? this.requireElevator,
      showUnknown: showUnknown ?? this.showUnknown,
    );
  }
}
