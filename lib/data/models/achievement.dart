/// Achievement-System fuer MapAB
/// Definiert alle verfuegbaren Achievements mit Bedingungen und XP-Belohnungen

/// XP-Konstanten fuer verschiedene Aktionen
class XPRewards {
  XPRewards._();

  // Trip-Aktionen
  static const int tripCreated = 50;
  static const int tripPublished = 100;
  static const int tripImported = 25;

  // POI-Aktionen
  static const int poiVisited = 10;
  static const int poiFavorited = 5;

  // Social-Aktionen
  static const int likeReceived = 5;
  static const int commentReceived = 10;

  // Journal-Aktionen
  static const int journalPhotoAdded = 5;
  static const int journalEntryAdded = 3;

  // Streak-Bonus
  static const int dailyStreakBonus = 10;
  static const int weeklyStreakBonus = 50;

  // Achievement-Unlock
  static const int achievementUnlocked = 25;
}

/// Achievement-Typ fuer Kategorisierung
enum AchievementCategory {
  trips,
  exploration,
  social,
  photography,
  special,
}

/// Achievement-Schwierigkeitsgrad
enum AchievementTier {
  bronze, // Einfach
  silver, // Mittel
  gold, // Schwer
  platinum, // Sehr schwer
}

/// Achievement-Definition
class Achievement {
  final String id;
  final String icon;
  final String titleDe;
  final String titleEn;
  final String descriptionDe;
  final String descriptionEn;
  final AchievementCategory category;
  final AchievementTier tier;
  final int xpReward;

  // Bedingungen (mindestens eine muss nicht-null sein)
  final int? requiredTrips;
  final int? requiredPois;
  final double? requiredKm;
  final int? requiredCountries;
  final int? requiredPhotos;
  final int? requiredPublishedTrips;
  final int? requiredLikesReceived;
  final int? requiredDayStreak;
  final int? requiredAchievements;
  final String? specialCondition; // Fuer besondere Bedingungen

  const Achievement({
    required this.id,
    required this.icon,
    required this.titleDe,
    required this.titleEn,
    required this.descriptionDe,
    required this.descriptionEn,
    required this.category,
    required this.tier,
    required this.xpReward,
    this.requiredTrips,
    this.requiredPois,
    this.requiredKm,
    this.requiredCountries,
    this.requiredPhotos,
    this.requiredPublishedTrips,
    this.requiredLikesReceived,
    this.requiredDayStreak,
    this.requiredAchievements,
    this.specialCondition,
  });

  /// Gibt den lokalisierten Titel zurueck
  String getTitle(String languageCode) {
    return languageCode == 'de' ? titleDe : titleEn;
  }

  /// Gibt die lokalisierte Beschreibung zurueck
  String getDescription(String languageCode) {
    return languageCode == 'de' ? descriptionDe : descriptionEn;
  }

  /// Tier-Farbe fuer UI
  int get tierColor {
    switch (tier) {
      case AchievementTier.bronze:
        return 0xFFCD7F32; // Bronze
      case AchievementTier.silver:
        return 0xFFC0C0C0; // Silber
      case AchievementTier.gold:
        return 0xFFFFD700; // Gold
      case AchievementTier.platinum:
        return 0xFFE5E4E2; // Platin
    }
  }
}

/// Alle verfuegbaren Achievements (21 total)
class Achievements {
  Achievements._();

  // ===== TRIP ACHIEVEMENTS (6) =====

  static const firstTrip = Achievement(
    id: 'first_trip',
    icon: '🎯',
    titleDe: 'Erste Reise',
    titleEn: 'First Trip',
    descriptionDe: 'Erstelle deinen ersten Trip',
    descriptionEn: 'Create your first trip',
    category: AchievementCategory.trips,
    tier: AchievementTier.bronze,
    xpReward: 50,
    requiredTrips: 1,
  );

  static const fiveTrips = Achievement(
    id: 'five_trips',
    icon: '🗺️',
    titleDe: 'Entdecker',
    titleEn: 'Explorer',
    descriptionDe: 'Erstelle 5 Trips',
    descriptionEn: 'Create 5 trips',
    category: AchievementCategory.trips,
    tier: AchievementTier.bronze,
    xpReward: 75,
    requiredTrips: 5,
  );

  static const tenTrips = Achievement(
    id: 'ten_trips',
    icon: '🧭',
    titleDe: 'Routenplaner',
    titleEn: 'Route Planner',
    descriptionDe: 'Erstelle 10 Trips',
    descriptionEn: 'Create 10 trips',
    category: AchievementCategory.trips,
    tier: AchievementTier.silver,
    xpReward: 100,
    requiredTrips: 10,
  );

  static const twentyFiveTrips = Achievement(
    id: 'twentyfive_trips',
    icon: '🏆',
    titleDe: 'Reiseprofi',
    titleEn: 'Travel Pro',
    descriptionDe: 'Erstelle 25 Trips',
    descriptionEn: 'Create 25 trips',
    category: AchievementCategory.trips,
    tier: AchievementTier.gold,
    xpReward: 200,
    requiredTrips: 25,
  );

  static const fiftyTrips = Achievement(
    id: 'fifty_trips',
    icon: '👑',
    titleDe: 'Reisemeister',
    titleEn: 'Travel Master',
    descriptionDe: 'Erstelle 50 Trips',
    descriptionEn: 'Create 50 trips',
    category: AchievementCategory.trips,
    tier: AchievementTier.platinum,
    xpReward: 500,
    requiredTrips: 50,
  );

  static const hundredTrips = Achievement(
    id: 'hundred_trips',
    icon: '🌟',
    titleDe: 'Legende',
    titleEn: 'Legend',
    descriptionDe: 'Erstelle 100 Trips',
    descriptionEn: 'Create 100 trips',
    category: AchievementCategory.trips,
    tier: AchievementTier.platinum,
    xpReward: 1000,
    requiredTrips: 100,
  );

  // ===== EXPLORATION ACHIEVEMENTS (5) =====

  static const hundredKm = Achievement(
    id: 'hundred_km',
    icon: '🚗',
    titleDe: 'Kurzstrecke',
    titleEn: 'Short Distance',
    descriptionDe: 'Lege 100 km zurueck',
    descriptionEn: 'Travel 100 km',
    category: AchievementCategory.exploration,
    tier: AchievementTier.bronze,
    xpReward: 50,
    requiredKm: 100,
  );

  static const fiveHundredKm = Achievement(
    id: 'fivehundred_km',
    icon: '🛣️',
    titleDe: 'Roadtripper',
    titleEn: 'Road Tripper',
    descriptionDe: 'Lege 500 km zurueck',
    descriptionEn: 'Travel 500 km',
    category: AchievementCategory.exploration,
    tier: AchievementTier.silver,
    xpReward: 100,
    requiredKm: 500,
  );

  static const thousandKm = Achievement(
    id: 'thousand_km',
    icon: '🏎️',
    titleDe: 'Langstreckenfahrer',
    titleEn: 'Long Distance Driver',
    descriptionDe: 'Lege 1.000 km zurueck',
    descriptionEn: 'Travel 1,000 km',
    category: AchievementCategory.exploration,
    tier: AchievementTier.gold,
    xpReward: 200,
    requiredKm: 1000,
  );

  static const fiveThousandKm = Achievement(
    id: 'fivethousand_km',
    icon: '✈️',
    titleDe: 'Weltenbummler',
    titleEn: 'Globetrotter',
    descriptionDe: 'Lege 5.000 km zurueck',
    descriptionEn: 'Travel 5,000 km',
    category: AchievementCategory.exploration,
    tier: AchievementTier.platinum,
    xpReward: 500,
    requiredKm: 5000,
  );

  static const tenThousandKm = Achievement(
    id: 'tenthousand_km',
    icon: '🌍',
    titleDe: 'Erdumrunder',
    titleEn: 'World Traveler',
    descriptionDe: 'Lege 10.000 km zurueck',
    descriptionEn: 'Travel 10,000 km',
    category: AchievementCategory.exploration,
    tier: AchievementTier.platinum,
    xpReward: 1000,
    requiredKm: 10000,
  );

  // ===== POI ACHIEVEMENTS (4) =====

  static const tenPois = Achievement(
    id: 'ten_pois',
    icon: '📍',
    titleDe: 'POI-Entdecker',
    titleEn: 'POI Explorer',
    descriptionDe: 'Besuche 10 POIs',
    descriptionEn: 'Visit 10 POIs',
    category: AchievementCategory.exploration,
    tier: AchievementTier.bronze,
    xpReward: 50,
    requiredPois: 10,
  );

  static const fiftyPois = Achievement(
    id: 'fifty_pois',
    icon: '🎪',
    titleDe: 'Sehenswuerdigkeiten-Fan',
    titleEn: 'Sightseeing Fan',
    descriptionDe: 'Besuche 50 POIs',
    descriptionEn: 'Visit 50 POIs',
    category: AchievementCategory.exploration,
    tier: AchievementTier.silver,
    xpReward: 100,
    requiredPois: 50,
  );

  static const hundredPois = Achievement(
    id: 'hundred_pois',
    icon: '🏛️',
    titleDe: 'Kulturkenner',
    titleEn: 'Culture Expert',
    descriptionDe: 'Besuche 100 POIs',
    descriptionEn: 'Visit 100 POIs',
    category: AchievementCategory.exploration,
    tier: AchievementTier.gold,
    xpReward: 200,
    requiredPois: 100,
  );

  static const fiveHundredPois = Achievement(
    id: 'fivehundred_pois',
    icon: '🌟',
    titleDe: 'POI-Meister',
    titleEn: 'POI Master',
    descriptionDe: 'Besuche 500 POIs',
    descriptionEn: 'Visit 500 POIs',
    category: AchievementCategory.exploration,
    tier: AchievementTier.platinum,
    xpReward: 500,
    requiredPois: 500,
  );

  // ===== SOCIAL ACHIEVEMENTS (3) =====

  static const firstPublishedTrip = Achievement(
    id: 'first_published',
    icon: '📤',
    titleDe: 'Teilen ist Caring',
    titleEn: 'Sharing is Caring',
    descriptionDe: 'Veroeffentliche deinen ersten Trip',
    descriptionEn: 'Publish your first trip',
    category: AchievementCategory.social,
    tier: AchievementTier.bronze,
    xpReward: 75,
    requiredPublishedTrips: 1,
  );

  static const fivePublishedTrips = Achievement(
    id: 'five_published',
    icon: '🌐',
    titleDe: 'Community-Beitrag',
    titleEn: 'Community Contributor',
    descriptionDe: 'Veroeffentliche 5 Trips',
    descriptionEn: 'Publish 5 trips',
    category: AchievementCategory.social,
    tier: AchievementTier.silver,
    xpReward: 150,
    requiredPublishedTrips: 5,
  );

  static const twentyFiveLikes = Achievement(
    id: 'twentyfive_likes',
    icon: '❤️',
    titleDe: 'Beliebt',
    titleEn: 'Popular',
    descriptionDe: 'Erhalte 25 Likes auf deine Trips',
    descriptionEn: 'Receive 25 likes on your trips',
    category: AchievementCategory.social,
    tier: AchievementTier.gold,
    xpReward: 200,
    requiredLikesReceived: 25,
  );

  // ===== PHOTOGRAPHY ACHIEVEMENTS (2) =====

  static const firstPhoto = Achievement(
    id: 'first_photo',
    icon: '📸',
    titleDe: 'Fotograf',
    titleEn: 'Photographer',
    descriptionDe: 'Fuege dein erstes Foto zum Tagebuch hinzu',
    descriptionEn: 'Add your first photo to the journal',
    category: AchievementCategory.photography,
    tier: AchievementTier.bronze,
    xpReward: 25,
    requiredPhotos: 1,
  );

  static const fiftyPhotos = Achievement(
    id: 'fifty_photos',
    icon: '🖼️',
    titleDe: 'Foto-Sammler',
    titleEn: 'Photo Collector',
    descriptionDe: 'Fuege 50 Fotos zum Tagebuch hinzu',
    descriptionEn: 'Add 50 photos to the journal',
    category: AchievementCategory.photography,
    tier: AchievementTier.gold,
    xpReward: 200,
    requiredPhotos: 50,
  );

  // ===== SPECIAL ACHIEVEMENT (1) =====

  static const achievementHunter = Achievement(
    id: 'achievement_hunter',
    icon: '🏅',
    titleDe: 'Achievement-Jaeger',
    titleEn: 'Achievement Hunter',
    descriptionDe: 'Schalte 10 Achievements frei',
    descriptionEn: 'Unlock 10 achievements',
    category: AchievementCategory.special,
    tier: AchievementTier.gold,
    xpReward: 250,
    requiredAchievements: 10,
  );

  /// Alle Achievements als Liste
  static const List<Achievement> all = [
    // Trips
    firstTrip,
    fiveTrips,
    tenTrips,
    twentyFiveTrips,
    fiftyTrips,
    hundredTrips,
    // Exploration
    hundredKm,
    fiveHundredKm,
    thousandKm,
    fiveThousandKm,
    tenThousandKm,
    // POIs
    tenPois,
    fiftyPois,
    hundredPois,
    fiveHundredPois,
    // Social
    firstPublishedTrip,
    fivePublishedTrips,
    twentyFiveLikes,
    // Photography
    firstPhoto,
    fiftyPhotos,
    // Special
    achievementHunter,
  ];

  /// Findet Achievement nach ID
  static Achievement? findById(String id) {
    try {
      return all.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Gibt Achievements nach Kategorie zurueck
  static List<Achievement> byCategory(AchievementCategory category) {
    return all.where((a) => a.category == category).toList();
  }

  /// Gibt Achievements nach Tier zurueck
  static List<Achievement> byTier(AchievementTier tier) {
    return all.where((a) => a.tier == tier).toList();
  }
}
