# Changelog v1.10.10 - Gamification-System (XP & Achievements)

**Datum:** 6. Februar 2026
**Build:** 191

## Zusammenfassung

Diese Version fuehrt ein vollstaendiges Gamification-System mit XP-Punkten, Leveln und 21 Achievements ein. Benutzer sammeln XP fuer verschiedene Aktionen und schalten Achievements frei.

## Neue Features

### 1. XP-System

**XP-Belohnungen fuer Aktionen:**

| Aktion | XP |
|--------|-----|
| Trip erstellt | +50 XP |
| Trip veroeffentlicht | +100 XP |
| Trip importiert | +25 XP |
| POI besucht | +10 XP |
| Like erhalten | +5 XP |
| Foto im Tagebuch | +5 XP |
| Tagebucheintrag | +3 XP |

**Level-System:**
- XP sammeln → Level aufsteigen
- Level-Up-Dialog mit Animation
- Fortschrittsbalken im Profil

### 2. Achievement-System

**21 Achievements in 5 Kategorien:**

| Kategorie | Anzahl | Beispiele |
|-----------|--------|-----------|
| Trips | 6 | Erste Reise, Entdecker, Reisemeister |
| Exploration | 5 | Kurzstrecke, Roadtripper, Weltenbummler |
| POIs | 4 | POI-Entdecker, Kulturkenner, POI-Meister |
| Social | 3 | Teilen ist Caring, Community-Beitrag, Beliebt |
| Photography | 2 | Fotograf, Foto-Sammler |
| Special | 1 | Achievement-Jaeger |

**4 Schwierigkeitsstufen (Tiers):**
- Bronze - Einfach
- Silber - Mittel
- Gold - Schwer
- Platin - Sehr schwer

### 3. Gamification-Overlay

**Automatische Benachrichtigungen:**
- **XP-Toast:** Animierter Toast oben rechts bei XP-Gewinn
- **Level-Up-Dialog:** Feier-Dialog beim Levelaufstieg
- **Achievement-Dialog:** Popup beim Freischalten eines Achievements

### 4. Profil-Screen Integration

- Achievements-Sektion mit freigeschalteten Achievements
- "Naechste Achievements" mit Fortschrittsbalken
- "Alle Achievements anzeigen" Modal
- Achievement-Karten mit Tier-Farben und XP-Anzeige

## Neue Dateien

| Datei | Beschreibung |
|-------|--------------|
| `lib/data/models/achievement.dart` | Achievement-Definitionen, XP-Konstanten, 21 Achievements |
| `lib/data/services/achievement_service.dart` | Unlock-Logik, Fortschrittsberechnung |
| `lib/data/providers/gamification_provider.dart` | XP-Vergabe, Event-Queue, Achievement-Pruefung |
| `lib/core/widgets/gamification_overlay.dart` | XP-Toast, Level-Up-Dialog, Achievement-Dialog, AchievementCard |

## Geaenderte Dateien

| Datei | Aenderung |
|-------|----------|
| `lib/app.dart` | GamificationOverlay als Builder im MaterialApp.router |
| `lib/data/providers/favorites_provider.dart` | XP bei Route-Speichern |
| `lib/features/social/widgets/publish_trip_sheet.dart` | XP bei Trip-Veroeffentlichung |
| `lib/data/providers/journal_provider.dart` | XP bei Foto-Hinzufuegen |
| `lib/features/account/profile_screen.dart` | Achievements-Sektion komplett ueberarbeitet |
| `lib/l10n/app_*.arb` | 15 neue Gamification-Strings (alle 5 Sprachen) |

## Lokalisierung

**15 neue ARB-Keys:**

```
gamificationLevelUp, gamificationNewLevel, gamificationContinue,
gamificationAchievementUnlocked, gamificationAwesome,
gamificationAllAchievements, gamificationNextAchievements,
profileXp, profileLevel, profileAchievements, profileNoAchievements,
profileTripsCreated, profilePoisVisited, profileKmTraveled
```

## Technische Details

### Event-System (Sealed Classes)

```dart
sealed class GamificationEvent {
  const GamificationEvent();
}

class XpEarnedEvent extends GamificationEvent {
  final int amount;
  final String reason;
}

class LevelUpEvent extends GamificationEvent {
  final int newLevel;
  final int previousLevel;
}

class AchievementUnlockedEvent extends GamificationEvent {
  final Achievement achievement;
}
```

### GamificationOverlay Integration

```dart
// In app.dart
return MaterialApp.router(
  // ...
  builder: (context, child) {
    return GamificationOverlay(
      child: child ?? const SizedBox.shrink(),
    );
  },
);
```

### XP vergeben

```dart
// Convenience-Methoden
await ref.read(gamificationNotifierProvider.notifier).onTripCreated();
await ref.read(gamificationNotifierProvider.notifier).onTripPublished();
await ref.read(gamificationNotifierProvider.notifier).onJournalPhotoAdded();

// Manuell
await ref.read(gamificationNotifierProvider.notifier).awardXp(
  amount: 50,
  reason: 'Eigener Grund',
);
```

### Achievement-Fortschritt abfragen

```dart
final progress = AchievementService.getProgress(
  achievement: achievement,
  account: account,
);

final progressText = AchievementService.getProgressText(
  achievement: achievement,
  account: account,
  languageCode: 'de',
);
```
