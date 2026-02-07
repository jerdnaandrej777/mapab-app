import 'dart:math';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'challenge.freezed.dart';
part 'challenge.g.dart';

/// Challenge-Typen
enum ChallengeType {
  /// Besuche X POIs einer bestimmten Kategorie
  visitCategory('visit_category'),

  /// Besuche POI in einem bestimmten Land
  visitCountry('visit_country'),

  /// Schliesse X Trips ab
  completeTrips('complete_trips'),

  /// Mache X Reisefotos
  takePhotos('take_photos'),

  /// X Tage in Folge aktiv
  streak('streak'),

  /// Besuche POI bei bestimmtem Wetter
  weather('weather'),

  /// Teile X Trips
  social('social'),

  /// Entdecke X neue POIs
  discover('discover'),

  /// Reise X Kilometer
  distance('distance');

  final String value;
  const ChallengeType(this.value);

  static ChallengeType fromString(String value) {
    return ChallengeType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ChallengeType.visitCategory,
    );
  }
}

/// Challenge-Frequenz
enum ChallengeFrequency {
  /// Taeglich
  daily('daily'),

  /// Woechentlich
  weekly('weekly'),

  /// Monatlich
  monthly('monthly'),

  /// Permanent (kein Ablaufdatum)
  permanent('permanent');

  final String value;
  const ChallengeFrequency(this.value);

  static ChallengeFrequency fromString(String value) {
    return ChallengeFrequency.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ChallengeFrequency.weekly,
    );
  }
}

/// Challenge-Definition (Template)
@freezed
class ChallengeDefinition with _$ChallengeDefinition {
  const factory ChallengeDefinition({
    required String id,
    required ChallengeType type,
    required ChallengeFrequency frequency,
    required int targetCount,
    required int xpReward,
    String? categoryFilter,     // Fuer visitCategory
    String? countryFilter,      // Fuer visitCountry
    String? weatherFilter,      // Fuer weather (good/bad/rain)
    @Default(false) bool isFeatured,
  }) = _ChallengeDefinition;

  factory ChallengeDefinition.fromJson(Map<String, dynamic> json) =>
      _$ChallengeDefinitionFromJson(json);
}

/// Aktive Challenge eines Benutzers
@freezed
class UserChallenge with _$UserChallenge {
  const UserChallenge._();

  const factory UserChallenge({
    required String id,
    required String oderId,
    required ChallengeDefinition definition,
    required int currentProgress,
    required DateTime startedAt,
    DateTime? completedAt,
    DateTime? expiresAt,
  }) = _UserChallenge;

  factory UserChallenge.fromJson(Map<String, dynamic> json) {
    final defJson = json['definition'] as Map<String, dynamic>? ?? json;
    return UserChallenge(
      id: json['id'] as String,
      oderId: json['user_id'] as String,
      definition: ChallengeDefinition(
        id: defJson['challenge_id'] as String? ?? json['challenge_id'] as String,
        type: ChallengeType.fromString(defJson['type'] as String? ?? 'visit_category'),
        frequency: ChallengeFrequency.fromString(defJson['frequency'] as String? ?? 'weekly'),
        targetCount: defJson['target_count'] as int? ?? json['target_count'] as int? ?? 5,
        xpReward: defJson['xp_reward'] as int? ?? json['xp_reward'] as int? ?? 100,
        categoryFilter: defJson['category_filter'] as String?,
        countryFilter: defJson['country_filter'] as String?,
        weatherFilter: defJson['weather_filter'] as String?,
        isFeatured: defJson['is_featured'] as bool? ?? false,
      ),
      currentProgress: json['current_progress'] as int? ?? 0,
      startedAt: DateTime.parse(json['started_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
    );
  }

  /// Fortschritt in Prozent (0.0 - 1.0)
  double get progress =>
      (currentProgress / definition.targetCount).clamp(0.0, 1.0);

  /// Ist abgeschlossen
  bool get isCompleted => completedAt != null;

  /// Ist abgelaufen
  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  /// Ist aktiv (nicht abgeschlossen und nicht abgelaufen)
  bool get isActive => !isCompleted && !isExpired;

  /// Verbleibende Zeit bis Ablauf
  Duration? get timeRemaining {
    if (expiresAt == null) return null;
    final remaining = expiresAt!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Formatierte verbleibende Zeit
  String get formattedTimeRemaining {
    final remaining = timeRemaining;
    if (remaining == null) return '';

    if (remaining.inDays > 0) {
      return '${remaining.inDays}d ${remaining.inHours % 24}h';
    } else if (remaining.inHours > 0) {
      return '${remaining.inHours}h ${remaining.inMinutes % 60}m';
    } else if (remaining.inMinutes > 0) {
      return '${remaining.inMinutes}m';
    } else {
      return '<1m';
    }
  }
}

/// Streak-Daten eines Benutzers
@freezed
class UserStreak with _$UserStreak {
  const UserStreak._();

  const factory UserStreak({
    required int currentStreak,
    required int longestStreak,
    DateTime? lastActivityDate,
  }) = _UserStreak;

  factory UserStreak.fromJson(Map<String, dynamic> json) => UserStreak(
    currentStreak: json['current_streak'] as int? ?? 0,
    longestStreak: json['longest_streak'] as int? ?? 0,
    lastActivityDate: json['last_activity_date'] != null
        ? DateTime.parse(json['last_activity_date'] as String)
        : null,
  );

  /// Ist Streak heute aktiv?
  bool get isActiveToday {
    if (lastActivityDate == null) return false;
    final today = DateTime.now();
    return lastActivityDate!.year == today.year &&
           lastActivityDate!.month == today.month &&
           lastActivityDate!.day == today.day;
  }

  /// Streak geht morgen verloren wenn nicht aktiviert
  bool get isAtRisk {
    if (lastActivityDate == null) return false;
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return lastActivityDate!.year == yesterday.year &&
           lastActivityDate!.month == yesterday.month &&
           lastActivityDate!.day == yesterday.day;
  }
}

/// Vordefinierte wöchentliche Challenges
class WeeklyChallenges {
  static final List<ChallengeDefinition> pool = [
    // Kategorie-Challenges
    const ChallengeDefinition(
      id: 'weekly_castles',
      type: ChallengeType.visitCategory,
      frequency: ChallengeFrequency.weekly,
      targetCount: 3,
      xpReward: 150,
      categoryFilter: 'castle',
    ),
    const ChallengeDefinition(
      id: 'weekly_museums',
      type: ChallengeType.visitCategory,
      frequency: ChallengeFrequency.weekly,
      targetCount: 5,
      xpReward: 200,
      categoryFilter: 'museum',
    ),
    const ChallengeDefinition(
      id: 'weekly_nature',
      type: ChallengeType.visitCategory,
      frequency: ChallengeFrequency.weekly,
      targetCount: 4,
      xpReward: 150,
      categoryFilter: 'nature',
    ),
    const ChallengeDefinition(
      id: 'weekly_viewpoints',
      type: ChallengeType.visitCategory,
      frequency: ChallengeFrequency.weekly,
      targetCount: 3,
      xpReward: 150,
      categoryFilter: 'viewpoint',
    ),
    const ChallengeDefinition(
      id: 'weekly_churches',
      type: ChallengeType.visitCategory,
      frequency: ChallengeFrequency.weekly,
      targetCount: 4,
      xpReward: 150,
      categoryFilter: 'church',
    ),
    const ChallengeDefinition(
      id: 'weekly_unesco',
      type: ChallengeType.visitCategory,
      frequency: ChallengeFrequency.weekly,
      targetCount: 2,
      xpReward: 250,
      categoryFilter: 'unesco',
      isFeatured: true,
    ),

    // Trip-Challenges
    const ChallengeDefinition(
      id: 'weekly_trips',
      type: ChallengeType.completeTrips,
      frequency: ChallengeFrequency.weekly,
      targetCount: 3,
      xpReward: 200,
    ),

    // Foto-Challenges
    const ChallengeDefinition(
      id: 'weekly_photos',
      type: ChallengeType.takePhotos,
      frequency: ChallengeFrequency.weekly,
      targetCount: 10,
      xpReward: 150,
    ),

    // Social-Challenges
    const ChallengeDefinition(
      id: 'weekly_share',
      type: ChallengeType.social,
      frequency: ChallengeFrequency.weekly,
      targetCount: 2,
      xpReward: 100,
    ),

    // Distanz-Challenges
    const ChallengeDefinition(
      id: 'weekly_distance',
      type: ChallengeType.distance,
      frequency: ChallengeFrequency.weekly,
      targetCount: 200,  // 200 km
      xpReward: 200,
    ),

    // Entdeckungs-Challenges
    const ChallengeDefinition(
      id: 'weekly_discover',
      type: ChallengeType.discover,
      frequency: ChallengeFrequency.weekly,
      targetCount: 10,
      xpReward: 150,
    ),
  ];

  /// Wählt 3 zufällige Challenges für die aktuelle Woche
  static List<ChallengeDefinition> getWeeklyChallenges() {
    final now = DateTime.now();
    // Seed basierend auf Kalenderwoche für deterministische Auswahl
    final weekNumber = (now.difference(DateTime(now.year, 1, 1)).inDays / 7).floor();
    final seed = now.year * 100 + weekNumber;

    final shuffled = List<ChallengeDefinition>.from(pool)
      ..shuffle(_SeededRandom(seed));

    return shuffled.take(3).toList();
  }

  /// Berechnet das Ablaufdatum (nächster Montag 00:00)
  static DateTime getWeeklyExpirationDate() {
    final now = DateTime.now();
    final daysUntilMonday = (DateTime.monday - now.weekday + 7) % 7;
    final nextMonday = DateTime(now.year, now.month, now.day + daysUntilMonday);
    return nextMonday;
  }
}

/// Seeded Random für deterministische Auswahl
class _SeededRandom implements Random {
  int _seed;

  _SeededRandom(this._seed);

  @override
  int nextInt(int max) {
    _seed = (_seed * 1103515245 + 12345) & 0x7FFFFFFF;
    return _seed % max;
  }

  @override
  double nextDouble() => nextInt(1 << 32) / (1 << 32);

  @override
  bool nextBool() => nextInt(2) == 0;
}
