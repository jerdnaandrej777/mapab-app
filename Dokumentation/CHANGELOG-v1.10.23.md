# Changelog v1.10.23 (Build 206)

**Datum:** 7. Februar 2026

## Gamification: Leaderboard & Challenges

Neues Gamification-System mit Rangliste und wöchentlichen Herausforderungen.

### Neue Features

#### 1. Leaderboard (Rangliste)
Globale Rangliste aller Benutzer mit verschiedenen Sortieroptionen.

**Features:**
- **4 Sortierkriterien:** XP, Kilometer, Trips, Likes
- **Eigene Position:** Immer sichtbar, auch wenn nicht in Top 100
- **Rang-Badges:** Gold/Silber/Bronze für Top 3
- **Streak-Anzeige:** Flammen-Icon bei aktiver Serie
- **Pagination:** Unendliches Scrollen für mehr Einträge

**UI-Elemente:**
- Tab-Leiste mit 4 Sortier-Optionen
- "Deine Position" Karte oben
- Listenansicht mit Avatar, Name, Level, XP
- Pull-to-Refresh

#### 2. Challenges & Streak-System
Wöchentliche Herausforderungen und tägliche Aktivitäts-Serie.

**Challenge-Typen (9):**
| Typ | Beschreibung | Beispiel |
|-----|--------------|----------|
| `visitCategory` | Besuche POIs einer Kategorie | "Besuche 3 Burgen" |
| `visitCountry` | Besuche POI in einem Land | "Besuche POI in Frankreich" |
| `completeTrips` | Schließe Trips ab | "Schließe 3 Trips ab" |
| `takePhotos` | Mache Reisefotos | "Mache 10 Fotos" |
| `streak` | Tage in Folge aktiv | "7 Tage in Folge aktiv" |
| `weather` | Besuche bei bestimmtem Wetter | "Besuche POI bei Regen" |
| `social` | Teile Trips | "Teile 2 Trips" |
| `discover` | Entdecke neue POIs | "Entdecke 10 neue POIs" |
| `distance` | Reise Kilometer | "Reise 200 km" |

**Streak-System:**
- Tägliche Aktivität erhöht Serie
- Verpasster Tag → Serie auf 1 zurückgesetzt
- Längste Serie wird gespeichert
- Warnung wenn Serie gefährdet (gelbes Icon)
- Bestätigung wenn heute aktiv (grünes Icon)

**Wöchentliche Challenges:**
- 3 neue Challenges jeden Montag
- Zufällige Auswahl aus Pool
- Fortschrittsbalken pro Challenge
- XP-Belohnung: 25-250 XP
- **Bonus:** +300 XP für alle 3 abgeschlossen
- Featured-Challenges mit "HIGHLIGHT" Badge

### Neue Dateien

#### Supabase-Migrationen
| Datei | Beschreibung |
|-------|--------------|
| `009_leaderboard.sql` | XP, Level, Streak-Felder in user_profiles, get_leaderboard RPC |
| `010_challenges.sql` | challenge_definitions, user_challenges, streak_history Tabellen |

#### Models
| Datei | Beschreibung |
|-------|--------------|
| `lib/data/models/challenge.dart` | Freezed-Model mit ChallengeType, ChallengeFrequency, UserChallenge, UserStreak |

#### Repositories
| Datei | Beschreibung |
|-------|--------------|
| `lib/data/repositories/leaderboard_repo.dart` | getLeaderboard(), getMyPosition() |

#### Providers
| Datei | Beschreibung |
|-------|--------------|
| `lib/data/providers/leaderboard_provider.dart` | LeaderboardNotifier mit Pagination |
| `lib/data/providers/challenges_provider.dart` | ChallengesNotifier mit Tracking-Methoden |

#### Screens
| Datei | Beschreibung |
|-------|--------------|
| `lib/features/leaderboard/leaderboard_screen.dart` | Ranglisten-UI |
| `lib/features/challenges/challenges_screen.dart` | Challenges-UI mit Streak-Karte |

### Geänderte Dateien

| Datei | Änderung |
|-------|----------|
| `lib/app.dart` | Routen `/leaderboard` und `/challenges` hinzugefügt |
| `lib/features/account/profile_screen.dart` | Zwei neue Buttons: "Rangliste" und "Herausforderungen" |

### Neue Routen

| Pfad | Screen | Beschreibung |
|------|--------|--------------|
| `/leaderboard` | LeaderboardScreen | Globale Rangliste |
| `/challenges` | ChallengesScreen | Wöchentliche Challenges |

### Lokalisierung

**Neue ARB-Keys (20+):**

| Key | DE | EN |
|-----|----|----|
| `leaderboardTitle` | Rangliste | Leaderboard |
| `leaderboardSortXp` | XP | XP |
| `leaderboardSortKm` | Kilometer | Kilometers |
| `leaderboardSortTrips` | Trips | Trips |
| `leaderboardSortLikes` | Likes | Likes |
| `leaderboardYourPosition` | Deine Position | Your Position |
| `leaderboardEmpty` | Noch keine Einträge | No entries yet |
| `leaderboardRank` | Platz {rank} | Rank {rank} |
| `challengesTitle` | Herausforderungen | Challenges |
| `challengesWeekly` | Wöchentliche Challenges | Weekly Challenges |
| `challengesCompleted` | Abgeschlossen | Completed |
| `challengesEmpty` | Neue Challenges jeden Montag! | New challenges every Monday! |
| `challengesFeatured` | HIGHLIGHT | FEATURED |
| `challengesCurrentStreak` | Aktuelle Serie | Current Streak |
| `challengesStreakDays` | {days} Tage | {days} Days |
| `challengesLongestStreak` | Rekord: {days} Tage | Record: {days} days |
| `challengesVisitCategory` | Besuche {count} {category} | Visit {count} {category} |
| `challengesCompleteTrips` | Schließe {count} Trips ab | Complete {count} trips |
| `challengesTakePhotos` | Mache {count} Reisefotos | Take {count} travel photos |
| `challengesShare` | Teile {count} Trips | Share {count} trips |
| `challengesDiscover` | Entdecke {count} neue POIs | Discover {count} new POIs |
| `challengesDistance` | Reise {km} Kilometer | Travel {km} kilometers |

**Alle 5 Sprachen:** DE, EN, FR, IT, ES

### Technische Details

**Supabase RPC-Funktionen:**
- `get_leaderboard(p_sort_by, p_limit, p_offset)` - Rangliste mit Sortierung
- `get_my_leaderboard_position(p_sort_by)` - Eigene Position
- `assign_weekly_challenges(p_user_id)` - Wöchentliche Challenges zuweisen
- `update_challenge_progress(p_user_id, p_challenge_id, p_increment)` - Fortschritt
- `update_user_streak(p_user_id)` - Streak aktualisieren

**XP-Belohnungen:**
| Aktion | XP |
|--------|-----|
| Tägliche Challenge | 25-30 |
| Wöchentliche Challenge | 100-250 |
| Streak 7 Tage | 100 |
| Streak 30 Tage | 500 |
| Streak 100 Tage | 2000 |
| Wochen-Bonus (alle 3) | 300 |

**Level-Berechnung:**
```
Level = floor(sqrt(totalXp / 100))
```

### Screenshots

**Leaderboard:**
- Tab-Leiste oben für Sortierung
- "Deine Position" Karte mit Highlight
- Rangliste mit Gold/Silber/Bronze Badges

**Challenges:**
- Streak-Karte mit Flammen-Gradient
- Wöchentliche Challenges mit Fortschrittsbalken
- XP-Anzeige und Timer bis Ablauf

---

*Generiert mit Claude Code*
