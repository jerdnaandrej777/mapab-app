# MapAB Flutter App - Vollständige Feature-Dokumentation

Version: 1.2.3 (21. Januar 2026)

## Inhaltsverzeichnis

1. [Übersicht](#übersicht)
2. [Neu in v1.2.3](#neu-in-v123) ⭐ AKTUELL
3. [Neu in v1.2.2](#neu-in-v122)
4. [Neu in v1.2.1](#neu-in-v121)
5. [Neu in v1.2.0](#neu-in-v120)
6. [Account-System](#account-system)
7. [Favoriten-Management](#favoriten-management)
8. [AI-Trip-Generator](#ai-trip-generator)
9. [Route-Planner Integration](#route-planner-integration)
10. [Dark Mode & Themes](#dark-mode--themes) ⭐ FIX v1.2.3
11. [Push-Benachrichtigungen](#push-benachrichtigungen)
11. [Echtzeit-Verkehrsdaten](#echtzeit-verkehrsdaten)
12. [Trip-Sharing & QR-Codes](#trip-sharing--qr-codes)
13. [KI-Personalisierung](#ki-personalisierung)
14. [Budget-Tracker](#budget-tracker)
15. [Höhenprofil](#höhenprofil)
16. [Reisetagebuch](#reisetagebuch)
17. [Barrierefreiheit](#barrierefreiheit)
18. [Gamification](#gamification)
19. [Sprachsteuerung](#sprachsteuerung)
20. [Services](#services)
21. [Emulator-Optimierungen](#emulator-optimierungen)

---

## Übersicht

Die MapAB Flutter App ist eine Cross-Platform Reiseplanungs-App für iOS, Android und Desktop mit 16 implementierten Haupt-Features.

### Download & Installation

**GitHub Release:** https://github.com/jerdnaandrej777/mapab-app/releases/tag/v1.2.3

**Direkter APK-Download:**
```
https://github.com/jerdnaandrej777/mapab-app/releases/download/v1.2.3/MapAB-v1.2.3.apk
```

**Installationsschritte:**
1. APK herunterladen (52 MB)
2. "Aus unbekannten Quellen installieren" erlauben
3. APK öffnen und Installation bestätigen
4. App öffnen und loslegen

---

## Neu in v1.2.3

**Release-Datum:** 21. Januar 2026

### 🐛 Haupt-Fix: Trip-Screen zeigt Route nach AI-Trip

**Problem:** Nach AI-Trip-Generierung blieb der Trip-Screen leer - "Noch keine Route geplant".

**Ursache:**
1. `confirmTrip()` setzte nur den State auf `confirmed`, übergab aber Route NICHT an `tripStateProvider`
2. `tripStateProvider` war `AutoDispose` - State ging bei Navigation verloren
3. Startfeld war Pflicht - User musste vor "Überrasch mich!" erst Adresse eingeben

**Lösung:**

#### 1. confirmTrip() übergibt Route + Stops

```dart
// lib/features/random_trip/providers/random_trip_provider.dart
void confirmTrip() {
  final generatedTrip = state.generatedTrip;
  if (generatedTrip == null) return;

  // NEU: Route und Stops an TripStateProvider übergeben
  final tripStateNotifier = ref.read(tripStateProvider.notifier);
  tripStateNotifier.setRoute(generatedTrip.trip.route);
  tripStateNotifier.setStops(generatedTrip.selectedPOIs);

  state = state.copyWith(step: RandomTripStep.confirmed);
}
```

#### 2. TripStateProvider mit keepAlive

```dart
// lib/features/trip/providers/trip_state_provider.dart
// VORHER: @riverpod (AutoDispose)
@Riverpod(keepAlive: true)  // State bleibt erhalten
class TripState extends _$TripState { ... }
```

#### 3. Automatische GPS-Abfrage

```dart
// lib/features/random_trip/providers/random_trip_provider.dart
Future<void> generateTrip() async {
  // NEU: Wenn kein Startpunkt, automatisch GPS abfragen
  if (!state.hasValidStart) {
    await useCurrentLocation();
    if (!state.hasValidStart) {
      state = state.copyWith(error: 'GPS konnte nicht abgefragt werden');
      return;
    }
  }
  // ... Trip generieren
}
```

#### 4. Startfeld optional

```dart
// lib/features/random_trip/providers/random_trip_state.dart
// VORHER: bool get canGenerate => hasValidStart && !isLoading;
bool get canGenerate => !isLoading;  // Startpunkt ist optional
```

### Geänderte Dateien

| Datei | Änderung |
|-------|----------|
| `random_trip_provider.dart` | Import tripStateProvider, generateTrip() mit Auto-GPS, confirmTrip() übergibt Route |
| `random_trip_state.dart` | canGenerate prüft nur isLoading |
| `trip_state_provider.dart` | @Riverpod(keepAlive: true) |
| `trip_state_provider.g.dart` | NotifierProvider statt AutoDisposeNotifierProvider |

### State-Flow

```
User klickt "Überrasch mich!" (ohne Startpunkt)
    ↓
generateTrip() → hasValidStart? NEIN → useCurrentLocation()
    ↓
GPS ermittelt (oder München-Fallback)
    ↓
Trip generiert (POIs + Route)
    ↓
User klickt "Bestätigen" → confirmTrip()
    ↓
tripStateProvider.setRoute(route) + setStops(pois)
    ↓
Navigation zu /trip → Route + Stops werden angezeigt ✅
```

### User Experience

**Vorher (v1.2.2):**
1. "Überrasch mich!" klicken → ❌ "Bitte Startpunkt eingeben"
2. Manuell Adresse eingeben oder GPS klicken
3. Trip generieren → Trip bestätigen
4. Trip-Screen öffnen → ❌ LEER

**Nachher (v1.2.3):**
1. "Überrasch mich!" klicken
2. GPS wird automatisch abgefragt ✅
3. Trip generieren → Trip bestätigen
4. Trip-Screen öffnen → ✅ Route + Stops sichtbar

### Test-Anleitung

1. **App starten**
2. **Random Trip öffnen** (Karte → "Überrasch mich!" oder Bottom Nav → Trip → Neu)
3. **OHNE Startpunkt** → "Trip generieren" klicken
4. ✅ GPS sollte automatisch abgefragt werden
5. ✅ Trip wird mit aktuellem Standort generiert
6. **"Bestätigen" klicken**
7. ✅ Trip-Screen zeigt Route mit Start, Ziel, Stops

---

### Dark Mode Fix - Vollständige Theme-Unterstützung

**Problem:** Bei aktivem Dark Mode wurde nur der Text weiß, alle Hintergrund-Flächen blieben weiß - Text war dadurch nicht mehr lesbar.

**Ursache:** Hart-codierte `Colors.white` und `AppTheme.textPrimary/textSecondary` in mehreren Komponenten.

#### Behobene Komponenten

| Komponente | Datei | Fix |
|------------|-------|-----|
| Bottom Navigation | `app.dart` | `theme.colorScheme.surface` |
| Navigation Items | `app.dart` | Dynamische Farben |
| System UI | `app.dart` | Dynamische Status-/Navigationsbar |
| AppBar | `map_screen.dart` | `colorScheme.surface` |
| FloatingActionButtons | `map_screen.dart` | `colorScheme.surface/onSurface` |
| SearchBar | `map_screen.dart` | Theme-basierte Farben |
| RouteToggle | `map_screen.dart` | Theme-basierte Farben |
| POI Cards | `poi_card.dart` | `colorScheme.surface/onSurface` |
| Trip Stop Tiles | `trip_stop_tile.dart` | `colorScheme.surface/onSurface` |

#### Code-Pattern (Best Practice)

```dart
// In jeder build() Methode:
final theme = Theme.of(context);
final colorScheme = theme.colorScheme;
final isDark = theme.brightness == Brightness.dark;

// Container-Farben:
color: colorScheme.surface,

// Text-Farben:
color: colorScheme.onSurface,           // Primär
color: theme.textTheme.bodySmall?.color, // Sekundär

// Schatten (Dark-aware):
BoxShadow(
  color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
  blurRadius: 10,
  offset: const Offset(0, 4),
)
```

#### Ergebnis

| Element | Light Mode | Dark Mode |
|---------|-----------|-----------|
| Hintergrund | Weiß (#FFFFFF) | Dunkelgrau (#1E293B) |
| Text | Dunkel (#1E293B) | Hell (#F1F5F9) |
| Schatten | Schwach (5% opacity) | Stärker (30% opacity) |
| System-Navigation | Weiß | Dunkelgrau |

#### Test-Anleitung

1. Settings öffnen (Zahnrad auf MapScreen)
2. Theme wählen: "Dunkel" oder "OLED Schwarz"
3. Alle Screens durchgehen - Text muss lesbar sein
4. Bottom Navigation: Dunkle Leiste mit hellen Icons

---

## Neu in v1.2.2

**Release-Datum:** 21. Januar 2026

### 🎯 Haupt-Feature: Route-Planner Integration

**Problem gelöst:** In v1.2.1 wurde der Trip-State Provider erstellt, aber Routen wurden nicht zum Trip-Screen weitergegeben.

#### Neue Komponenten

1. **Route-Planner Provider** (`lib/features/map/providers/route_planner_provider.dart`)
   - Verwaltet Start/Ziel Locations + Adressen
   - Berechnet Route automatisch wenn beide gesetzt
   - Schreibt berechnete Route zu trip_state_provider
   - Zeigt Loading-State während Berechnung

2. **SearchScreen Integration**
   - `_selectSuggestion()` schreibt zu route_planner_provider
   - Automatische Routenberechnung nach Ziel-Auswahl

3. **MapScreen Updates**
   - Zeigt Start/Ziel-Adressen in Suchleiste
   - Loading-Indikator "Route wird berechnet..."

### State-Flow

```
User wählt Start/Ziel (SearchScreen)
    ↓
routePlannerProvider.setStart() / setEnd()
    ↓
Automatische Routenberechnung
    ↓
tripStateProvider.setRoute(route) ← FIX
    ↓
TripScreen zeigt Route an ✅
```

### 🔧 Geänderte Dateien

| Datei | Änderung |
|-------|----------|
| `route_planner_provider.dart` | **NEU** - State-Brücke |
| `route_planner_provider.g.dart` | **NEU** - Code-Generation |
| `search_screen.dart` | Integration mit route_planner |
| `map_screen.dart` | Adressen-Anzeige + Loading |

### 📦 Build-Details

- **Version:** 1.2.2+3
- **Größe:** 52 MB
- **Build-Datum:** 21. Januar 2026

---

## Neu in v1.2.1

**Release-Datum:** 21. Januar 2026

### 🎯 Features

#### 1. Trip-State Provider
- Neuer `trip_state_provider.dart` für Route + Stops Verwaltung
- TripScreen nutzt jetzt Riverpod statt lokaler State
- Vorbereitung für Route-Anzeige (vollständig in v1.2.2)

#### 2. Settings-Button Repositioniert
- Settings-Button jetzt **über** dem GPS-Button
- Bessere Erreichbarkeit auf dem MapScreen

#### 3. AI-Trip-Dialog Text-Fix
- **Problem:** Weißer Text auf weißem Hintergrund im AI-Trip-Generator Dialog
- **Fix:** Alle Text-Labels auf `Colors.black87` / `Colors.black` gesetzt
- Betrifft: Tage-Slider Label, Interessen-Label

### 🐛 Bugfixes

- `category?.icon ?? '📍'` - Null-Safety für POI-Kategorie
- `(stop.detourKm ?? 0).toInt()` - Type-Conversion num → int

### 📦 Build-Details

- **Version:** 1.2.1+2
- **Größe:** 51.4 MB

---

## Neu in v1.2.0

**Release-Datum:** 21. Januar 2026

### 🎯 Haupt-Features

#### 1. Profil-Button in MapScreen
- ✅ **AppBar auf MapScreen** mit transparentem Hintergrund
- 👤 **Profil-Button** → Direkter Zugriff auf Account-System
- ❤️ **Favoriten-Button** → Favoriten-Management
- 🎨 **UI-Verbesserung** mit `extendBodyBehindAppBar`

#### 2. Favoriten-Management
- 📑 **Tab-View**: Routen | POIs
- 🗂️ **Kategorien**: Eigene Listen erstellen
- ❤️ **Quick-Actions**: Favorit hinzufügen/entfernen
- 🗑️ **Batch-Delete**: Alle löschen Funktion

#### 3. AI-Trip-Generator
- 🤖 **Automatische Routenplanung** via OpenAI GPT-4o
- 📅 **1-7 Tage Trips** mit flexiblen Parametern
- 🎯 **Interessen-Filter** (Kultur, Natur, Geschichte, Essen, etc.)
- 📝 **Formatierte Ausgabe** mit Tages-Breakdown

#### 4. AI-Chat Erweiterungen
- 💬 **Kontext-bewusst**: Route & Stops werden mitgesendet
- 🎯 **POI-Empfehlungen**: "Was gibt es auf meiner Route?"
- 🗺️ **Route-Optimierung**: Intelligente Vorschläge

### 🐛 Bugfixes
- ✅ **FavoritesScreen**: `startAddress`/`endAddress` statt `startName`/`endName`
- ✅ **Routing**: `/favorites` Route in `app.dart` registriert

### 📦 Build-Details
- **Größe**: 51.4 MB (Tree-shaking: 99.7% Icon-Reduktion)
- **Min SDK**: Android 21 (Lollipop)
- **Target SDK**: Android 34
- **Build-Zeit**: ~145s

### Tech-Stack

| Technologie | Version | Zweck |
|-------------|---------|-------|
| Flutter SDK | 3.24.5 | UI Framework |
| Dart | 3.0+ | Programmiersprache |
| Riverpod | 2.4.9 | State Management (mit Code-Generierung) |
| GoRouter | 13.0.0 | Navigation & Deep Links |
| Hive | 2.2.3 | Local NoSQL Storage |
| Freezed | 2.4.6 | Immutable Models & JSON Serialization |
| flutter_map | 6.1.0 | Kartenansicht |
| Geolocator | 11.1.0 | GPS & Location Services |

### Architektur

```
lib/
├── core/                      # Basis-Infrastruktur
│   ├── theme/                 # Themes, Dark Mode
│   ├── constants/             # API Keys, Endpoints
│   └── utils/                 # Helper-Funktionen
├── data/                      # Daten-Schicht
│   ├── models/                # Freezed Models
│   ├── providers/             # Riverpod State Providers
│   ├── repositories/          # API Repositories
│   └── services/              # Business Logic
└── features/                  # Feature-Module
    ├── account/               # Account-System
    ├── map/                   # Karte
    ├── poi/                   # POI-Listen
    ├── trip/                  # Trip-Planung
    ├── ai_assistant/          # KI-Chat
    └── ...
```

---

## Account-System

**Feature #14 - Januar 2026 | UI-Zugriff: v1.2.0**

Local-First Account-Management mit Multi-Profilen, Gamification und Statistik-Tracking.

### Zugriff (v1.2.0)

**MapScreen → AppBar → Profil-Icon (👤)**

```dart
// lib/features/map/map_screen.dart
IconButton(
  icon: const Icon(Icons.person_outline),
  onPressed: () => context.push('/profile'),
  tooltip: 'Profil',
)
```

### Features

- **Multi-Profile Support:** Mehrere Accounts pro Gerät (Familie, Arbeit, etc.)
- **Gast-Modus:** Sofort loslegen ohne Registrierung
- **Lokale Accounts:** Benutzername + Anzeigename (kein Cloud-Login erforderlich)
- **Gamification:** XP-System, Level 1-100, 21 Achievements
- **Statistiken:** Trips erstellt, POIs besucht, Km gefahren
- **Persistierung:** Hive-basiert, lokal gespeichert

### Dateien

```
lib/
├── data/
│   ├── models/
│   │   └── user_account.dart          # Freezed Account-Model
│   └── providers/
│       └── account_provider.dart      # Riverpod Account State
└── features/
    └── account/
        ├── login_screen.dart          # Login/Willkommens-Screen
        ├── profile_screen.dart        # Account-Details & Statistiken
        └── splash_screen.dart         # Initial Account-Check
```

### UserAccount Model

```dart
@freezed
class UserAccount with _$UserAccount {
  const factory UserAccount({
    required String id,              // UUID
    required String username,        // Benutzername (unique)
    required String displayName,     // Anzeigename
    String? email,                   // Optional
    String? avatarUrl,               // Optional
    @Default(UserAccountType.local) UserAccountType type,
    required DateTime createdAt,
    DateTime? lastLoginAt,

    // Verknüpfungen
    @Default([]) List<String> favoriteTripIds,
    @Default([]) List<String> favoritePoiIds,
    @Default([]) List<String> journalEntryIds,

    // Gamification
    @Default(0) int totalXp,
    @Default(1) int level,
    @Default([]) List<String> unlockedAchievements,

    // Statistiken
    @Default(0) int totalTripsCreated,
    @Default(0.0) double totalKmTraveled,
    @Default(0) int totalPoisVisited,

    String? preferencesId,           // Link zu UserPreferences
  }) = _UserAccount;

  factory UserAccount.fromJson(Map<String, dynamic> json) =>
      _$UserAccountFromJson(json);
}

enum UserAccountType {
  local,    // Lokal gespeichert (aktuell)
  google,   // Google Sign-In (geplant)
  apple,    // Apple Sign-In (geplant)
  firebase  // Firebase Auth (geplant)
}
```

### Helper Methods

```dart
extension UserAccountExtensions on UserAccount {
  // Ist Gast-Account?
  bool get isGuest => username.startsWith('guest_');

  // XP für nächstes Level
  int get xpToNextLevel => (level * 100) - (totalXp % (level * 100));

  // Level-Fortschritt (0.0 - 1.0)
  double get levelProgress {
    final xpForCurrentLevel = (level - 1) * 100;
    final xpForNextLevel = level * 100;
    final currentLevelXp = totalXp - xpForCurrentLevel;
    return currentLevelXp / (xpForNextLevel - xpForCurrentLevel);
  }

  // Level aus XP berechnen
  static int calculateLevel(int totalXp) {
    return (totalXp ~/ 100) + 1;
  }
}
```

### AccountNotifier Provider

```dart
@riverpod
class AccountNotifier extends _$AccountNotifier {
  late Box _accountBox;

  @override
  Future<UserAccount?> build() async {
    _accountBox = await Hive.openBox('user_accounts');
    return await _loadActiveAccount();
  }

  // Account laden
  Future<UserAccount?> _loadActiveAccount() async {
    final data = _accountBox.get('active_account');
    if (data == null) return null;
    return UserAccount.fromJson(Map<String, dynamic>.from(data));
  }

  // Gast-Account erstellen
  Future<void> createGuestAccount() async {
    final account = UserAccount(
      id: const Uuid().v4(),
      username: 'guest_${DateTime.now().millisecondsSinceEpoch}',
      displayName: 'Gast',
      type: UserAccountType.local,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );

    await _accountBox.put('active_account', account.toJson());
    state = AsyncValue.data(account);
  }

  // Lokales Profil erstellen
  Future<void> createLocalAccount({
    required String username,
    required String displayName,
    String? email,
  }) async {
    final account = UserAccount(
      id: const Uuid().v4(),
      username: username,
      displayName: displayName,
      email: email,
      type: UserAccountType.local,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );

    await _accountBox.put('active_account', account.toJson());
    state = AsyncValue.data(account);
  }

  // Account aktualisieren
  Future<void> updateAccount(UserAccount updatedAccount) async {
    await _accountBox.put('active_account', updatedAccount.toJson());
    state = AsyncValue.data(updatedAccount);
  }

  // XP hinzufügen
  Future<void> addXp(int xp) async {
    final account = state.value;
    if (account == null) return;

    final newTotalXp = account.totalXp + xp;
    final newLevel = UserAccountExtensions.calculateLevel(newTotalXp);

    final updated = account.copyWith(
      totalXp: newTotalXp,
      level: newLevel,
    );

    await updateAccount(updated);
  }

  // Achievement freischalten
  Future<void> unlockAchievement(String achievementId) async {
    final account = state.value;
    if (account == null) return;

    if (!account.unlockedAchievements.contains(achievementId)) {
      final updated = account.copyWith(
        unlockedAchievements: [...account.unlockedAchievements, achievementId],
      );
      await updateAccount(updated);
    }
  }

  // Favoriten-Trip hinzufügen
  Future<void> addFavoriteTrip(String tripId) async {
    final account = state.value;
    if (account == null) return;

    if (!account.favoriteTripIds.contains(tripId)) {
      final updated = account.copyWith(
        favoriteTripIds: [...account.favoriteTripIds, tripId],
      );
      await updateAccount(updated);
    }
  }

  // Statistiken aktualisieren
  Future<void> updateTripStatistics({
    int? tripsCreated,
    double? kmTraveled,
    int? poisVisited,
  }) async {
    final account = state.value;
    if (account == null) return;

    final updated = account.copyWith(
      totalTripsCreated: account.totalTripsCreated + (tripsCreated ?? 0),
      totalKmTraveled: account.totalKmTraveled + (kmTraveled ?? 0),
      totalPoisVisited: account.totalPoisVisited + (poisVisited ?? 0),
    );

    await updateAccount(updated);
  }

  // Logout
  Future<void> logout() async {
    await _accountBox.delete('active_account');
    state = const AsyncValue.data(null);
  }

  // Account löschen
  Future<void> deleteAccount() async {
    await _accountBox.clear();
    state = const AsyncValue.data(null);
  }
}
```

### Login Screen

```dart
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _continueAsGuest() async {
    setState(() => _isLoading = true);

    try {
      await ref.read(accountNotifierProvider.notifier).createGuestAccount();

      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showCreateAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lokales Profil erstellen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Benutzername',
                hintText: 'z.B. reisefan123',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _displayNameController,
              decoration: const InputDecoration(
                labelText: 'Anzeigename',
                hintText: 'z.B. Max Mustermann',
                prefixIcon: Icon(Icons.badge),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'E-Mail (optional)',
                hintText: 'z.B. max@example.com',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: _createLocalAccount,
            child: const Text('Erstellen'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.explore,
                size: 80,
                color: AppTheme.primaryColor,
              ),
            ),

            const SizedBox(height: 32),

            // Titel
            const Text(
              'Willkommen bei MapAB',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 48),

            // Gast-Modus Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _continueAsGuest,
                icon: const Icon(Icons.login),
                label: const Text('Als Gast fortfahren'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Lokales Profil erstellen
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _showCreateAccountDialog,
                icon: const Icon(Icons.person_add),
                label: const Text('Lokales Profil erstellen'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Profile Screen

Der Profile Screen zeigt:

1. **Header:** Avatar, Display Name, Username, E-Mail, Account-Typ
2. **Level & XP:** Progress Bar mit Level-Anzeige
3. **Statistiken:** Trips, POIs, Km in Cards
4. **Achievements:** Liste aller freigeschalteten Achievements
5. **Actions:** Profil bearbeiten, Ausloggen, Account löschen

```dart
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountAsync = ref.watch(accountNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditProfileDialog(context, ref),
          ),
        ],
      ),
      body: accountAsync.when(
        data: (account) {
          if (account == null) {
            return const Center(child: Text('Kein Account gefunden'));
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(account),
                const Divider(height: 1),
                _buildLevelSection(account),
                const Divider(height: 1),
                _buildStatisticsSection(account),
                const Divider(height: 1),
                _buildAchievementsSection(account),
                const Divider(height: 1),
                _buildActionsSection(context, ref, account),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Fehler: $error')),
      ),
    );
  }
}
```

### Splash Screen

Der Splash Screen prüft beim App-Start ob ein Account vorhanden ist:

```dart
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAccountAndNavigate();
  }

  Future<void> _checkAccountAndNavigate() async {
    // Warte 2 Sekunden für Splash-Animation
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Prüfe ob Account vorhanden
    final accountAsync = ref.read(accountNotifierProvider);

    accountAsync.when(
      data: (account) {
        if (account != null) {
          // Account vorhanden → Main Screen
          context.go('/');
        } else {
          // Kein Account → Login Screen
          context.go('/login');
        }
      },
      loading: () {
        // Warten bis geladen
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _checkAccountAndNavigate();
          }
        });
      },
      error: (_, __) {
        // Bei Fehler zum Login
        context.go('/login');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.explore,
                size: 100,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 32),

            // App Name
            const Text(
              'MapAB',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 48),

            // Loading Indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Integration in Navigation

In `lib/app.dart`:

```dart
final _router = GoRouter(
  initialLocation: '/',
  routes: [
    // Login Screen
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),

    // Profile Screen
    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (context, state) => const ProfileScreen(),
    ),

    // Weitere Routen...
  ],
);
```

### XP & Achievement System

**XP-Quellen:**
- Trip erstellt: +50 XP
- POI besucht: +10 XP
- Random Trip: +25 XP
- Hotel gebucht: +15 XP
- KI-Chat verwendet: +5 XP

**Level-System:**
- Level 1-100
- Pro Level: 100 XP erforderlich
- Level 1: 0-99 XP
- Level 2: 100-199 XP
- Level 100: 9900+ XP

**Achievements (21 gesamt):**
1. Erste Schritte (ersten Trip erstellen)
2. Explorer (10 POIs besuchen)
3. Weltenbummler (100 km reisen)
4. Road Warrior (1000 km reisen)
5. POI-Jäger (50 POIs besuchen)
6. Schloss-Fan (10 Schlösser besuchen)
7. Naturfreund (10 Natur-POIs besuchen)
8. Museums-Liebhaber (10 Museen besuchen)
9. Budget-Meister (5 Trips mit Budget planen)
10. Früh-Bucher (Hotel 30 Tage im Voraus buchen)
11. Spontan (Trip heute starten)
12. Wochenend-Warrior (5 Wochenend-Trips)
13. Langstrecke (Trip über 500 km)
14. Kurztrip-König (10 Trips unter 100 km)
15. Scenic-Fahrer (5 Scenic Routes fahren)
16. KI-Nutzer (10 KI-Chats führen)
17. Teilen ist Caring (5 Trips teilen)
18. Fotograf (50 Fotos im Journal)
19. Tagebuch-Schreiber (20 Journal-Einträge)
20. Barrierefreiheit (5 barrierefreie Trips)
21. MapAB-Veteran (Level 50 erreichen)

### Verwendung in anderen Features

```dart
// In Trip-Planung nach erfolgreicher Erstellung
final accountNotifier = ref.read(accountNotifierProvider.notifier);
await accountNotifier.addXp(50);
await accountNotifier.updateTripStatistics(tripsCreated: 1);
await accountNotifier.unlockAchievement('first_trip');

// In POI-Detail nach Besuch
await accountNotifier.addXp(10);
await accountNotifier.updateTripStatistics(poisVisited: 1);

// In Random Trip
await accountNotifier.addXp(25);
await accountNotifier.unlockAchievement('spontaneous');
```

---

## Favoriten-Management

**Feature #15 - v1.2.0 (21. Januar 2026)**

Vollständiges Favoriten-System mit Kategorisierung für Routen und POIs.

### Zugriff (v1.2.0)

**MapScreen → AppBar → Favoriten-Icon (❤️)**

```dart
// lib/features/map/map_screen.dart
IconButton(
  icon: const Icon(Icons.favorite_border),
  onPressed: () => context.push('/favorites'),
  tooltip: 'Favoriten',
)
```

### Features

- **Tab-View:** Routen | POIs
- **Kategorien:** Eigene Listen erstellen
- **Quick-Actions:** Favorit hinzufügen/entfernen
- **Batch-Delete:** Alle löschen Funktion
- **Persistierung:** Hive-basiert

### Dateien

```
lib/
├── data/
│   ├── models/
│   │   └── favorites.dart             # Freezed Favorites-Model
│   └── providers/
│       └── favorites_provider.dart    # Riverpod Favorites State
└── features/
    └── favorites/
        └── favorites_screen.dart      # UI: Tab-View & Listen
```

### Favorites Model

```dart
@freezed
class Favorites with _$Favorites {
  const factory Favorites({
    @Default([]) List<Trip> savedRoutes,
    @Default([]) List<POI> favoritePOIs,
  }) = _Favorites;
}
```

### FavoritesProvider

```dart
@riverpod
class FavoritesNotifier extends _$FavoritesNotifier {
  @override
  Future<Favorites> build() async {
    // Lade aus Hive
    return Favorites();
  }

  // Routen
  Future<void> saveRoute(Trip trip) async { ... }
  Future<void> removeRoute(String tripId) async { ... }

  // POIs
  Future<void> addPOI(POI poi) async { ... }
  Future<void> removePOI(String poiId) async { ... }

  // Bulk
  Future<void> clearAll() async { ... }
}
```

### UI-Komponenten

#### Routen-Tab

**Liste mit Karten:**
- Trip-Name
- Start → Ziel
- Distanz, Dauer, Stops
- Delete-Button (🗑️)
- Tap to Load

```dart
ListTile(
  leading: Icon(Icons.route, color: AppTheme.primaryColor),
  title: Text(trip.name),
  subtitle: Text('${trip.route.startAddress} → ${trip.route.endAddress}'),
  trailing: IconButton(
    icon: Icon(Icons.delete_outline),
    onPressed: () => _confirmRemoveRoute(trip),
  ),
  onTap: () => _loadRoute(trip),
)
```

#### POIs-Tab

**Grid-Layout:**
- POI-Bild (falls vorhanden)
- POI-Name
- Kategorie-Label
- Favorit-Button (❤️)

```dart
GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    childAspectRatio: 0.75,
  ),
  itemBuilder: (context, index) {
    final poi = pois[index];
    return _buildPOICard(poi);
  },
)
```

### Hive Storage

**Box:** `favorites`

```dart
final favoritesBox = await Hive.openBox('favorites');

// Speichern
await favoritesBox.put('data', favorites.toJson());

// Laden
final json = favoritesBox.get('data');
final favorites = Favorites.fromJson(json);
```

### Beispiel-Flow

```dart
// POI zu Favoriten hinzufügen
final favoritesNotifier = ref.read(favoritesNotifierProvider.notifier);
await favoritesNotifier.addPOI(poi);

// Toast-Benachrichtigung
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('${poi.name} zu Favoriten hinzugefügt')),
);

// Route speichern
await favoritesNotifier.saveRoute(currentTrip);

// Favoriten öffnen
context.push('/favorites');
```

---

## AI-Trip-Generator

**Feature #16 - v1.2.0 (21. Januar 2026)**

Automatische Routenplanung via OpenAI GPT-4o mit Interessen-basierten Vorschlägen.

### Zugriff (v1.2.0)

**Bottom Navigation → AI-Tab → Suggestion Chip "🤖 AI-Trip generieren"**

```dart
// lib/features/ai_assistant/chat_screen.dart
ChipSuggestion(
  label: '🤖 AI-Trip generieren',
  onTap: () => _showTripGeneratorDialog(),
)
```

### Features

- **1-7 Tage Trips:** Slider für Reisedauer
- **Ziel-Eingabe:** Flexible Stadt/Land-Auswahl
- **Interessen-Filter:** 7 Kategorien (Kultur, Natur, etc.)
- **Startpunkt (optional):** Automatische Distanz-Berechnung
- **Formatierte Ausgabe:** Tages-Breakdown mit POIs, Zeiten, Beschreibungen
- **Demo-Modus:** Fallback wenn kein API-Key

### Dateien

```
lib/
├── data/
│   └── services/
│       └── ai_service.dart            # OpenAI GPT-4o Integration
└── features/
    └── ai_assistant/
        └── chat_screen.dart           # UI: Dialog + Chat-Anzeige
```

### Trip-Generator Dialog

```dart
void _showTripGeneratorDialog() {
  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('🤖 AI-Trip generieren'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              // Ziel
              TextField(
                controller: destinationController,
                decoration: InputDecoration(
                  labelText: 'Wohin möchtest du reisen?',
                  hintText: 'z.B. Prag, Amsterdam, Rom',
                ),
              ),

              // Tage-Slider
              Slider(
                value: days,
                min: 1,
                max: 7,
                divisions: 6,
                label: '${days.round()} Tage',
                onChanged: (value) => setDialogState(() => days = value),
              ),

              // Interessen-Chips
              Wrap(
                spacing: 8,
                children: interests.map((interest) {
                  return FilterChip(
                    label: Text(interest),
                    selected: selectedInterests.contains(interest),
                    onSelected: (selected) {
                      setDialogState(() {
                        if (selected) {
                          selectedInterests.add(interest);
                        } else {
                          selectedInterests.remove(interest);
                        }
                      });
                    },
                  );
                }).toList(),
              ),

              // Startpunkt (optional)
              TextField(
                controller: startController,
                decoration: InputDecoration(
                  labelText: 'Startpunkt (optional)',
                  hintText: 'z.B. München',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _generateTrip(...);
            },
            child: const Text('Generieren'),
          ),
        ],
      ),
    ),
  );
}
```

### AI-Service Integration

```dart
Future<void> _generateTrip({
  required String destination,
  required int days,
  required List<String> interests,
  String? startLocation,
}) async {
  setState(() => _isLoading = true);

  try {
    final aiService = ref.read(aiServiceProvider);

    final response = await aiService.generateTripPlan(
      destination: destination,
      days: days,
      interests: interests,
      startLocation: startLocation,
    );

    setState(() {
      _messages.add({
        'content': response,
        'isUser': false,
        'isTrip': true, // Markiert als Trip-Plan
      });
      _isLoading = false;
    });
  } catch (e) {
    // Fallback: Demo-Modus
    final demoResponse = _generateDemoTrip(destination, days);
    setState(() {
      _messages.add({
        'content': demoResponse,
        'isUser': false,
        'isTrip': true,
      });
      _isLoading = false;
    });
  }
}
```

### Beispiel-Output

```
🗺️ AI-Trip-Plan: 3 Tage in Prag

Tag 1: Historisches Zentrum (8h)
───────────────────────────────
• 09:00 - 11:00 | Prager Burg
  📍 UNESCO Welterbe
  💰 250 CZK Eintritt
  ⏱️ 2 Stunden empfohlen

• 11:30 - 12:30 | Karlsbrücke
  📍 Gotische Brücke mit 30 Statuen
  💰 Kostenlos
  ⏱️ 1 Stunde

• 13:00 - 14:00 | Mittagspause
  🍽️ U Fleků (seit 1499)
  💰 €€ | Böhmische Küche

• 14:30 - 16:00 | Altstädter Ring
  📍 Astronomische Uhr + Rathaus
  💰 200 CZK
  ⏱️ 1.5 Stunden

Tag 2: Kleinseite & Vyšehrad (7h)
──────────────────────────────────
[...]

💡 Insider-Tipps:
• Prag Card: 3 Tage für €58 (spart ~€40)
• Öffentliche Verkehrsmittel: 24h-Ticket €5
• Beste Reisezeit: Mai-September

🏨 Hotel-Empfehlung:
• Zentrum, nähe Altstädter Ring
• Budget: €50-80/Nacht
• Tipp: Booking.com 2 Monate vorher

🚗 Anreise:
• Von München: 380 km (4h Auto)
• Alternativ: Flixbus ab €15

[Übernehmen-Button] 🚧 Coming Soon
```

### Demo-Modus

Falls kein OpenAI API-Key konfiguriert:

---

## Route-Planner Integration

**Feature #17 - v1.2.2 (21. Januar 2026)**

Vollständige Integration zwischen Route-Berechnung und Trip-Anzeige.

### Problem (v1.2.1)

Der `trip_state_provider` existierte, aber nichts schrieb Routen hinein. Das führte dazu, dass berechnete Routen nicht auf dem Trip-Screen erschienen.

**User-Feedback:** "Trip anzeigen funktioniert immernoch nicht, in deiner Route ist nichts drin."

### Lösung

Neuer `route_planner_provider` als Brücke zwischen SearchScreen und TripScreen.

### Dateien

```
lib/
├── features/
│   ├── map/
│   │   ├── map_screen.dart                    # UI mit Adressen-Anzeige
│   │   └── providers/
│   │       └── route_planner_provider.dart   # NEU: State-Brücke
│   ├── search/
│   │   └── search_screen.dart                # Schreibt zu route_planner
│   └── trip/
│       ├── trip_screen.dart                  # Liest von trip_state
│       └── providers/
│           └── trip_state_provider.dart      # Route + Stops State
```

### RoutePlannerProvider

```dart
@riverpod
class RoutePlanner extends _$RoutePlanner {
  @override
  RoutePlannerData build() {
    return const RoutePlannerData();
  }

  void setStart(LatLng location, String address) {
    state = state.copyWith(
      startLocation: location,
      startAddress: address,
    );
    _tryCalculateRoute();
  }

  void setEnd(LatLng location, String address) {
    state = state.copyWith(
      endLocation: location,
      endAddress: address,
    );
    _tryCalculateRoute();
  }

  Future<void> _tryCalculateRoute() async {
    if (state.startLocation == null || state.endLocation == null) {
      return;
    }

    state = state.copyWith(isCalculating: true);

    try {
      final routingRepo = ref.read(routingRepositoryProvider);

      final route = await routingRepo.calculateFastRoute(
        start: state.startLocation!,
        end: state.endLocation!,
        startAddress: state.startAddress ?? 'Unbekannt',
        endAddress: state.endAddress ?? 'Unbekannt',
      );

      state = state.copyWith(
        route: route,
        isCalculating: false,
      );

      // KEY: Route zu Trip-State schreiben
      ref.read(tripStateProvider.notifier).setRoute(route);
    } catch (e) {
      print('[RoutePlanner] Fehler: $e');
      state = state.copyWith(
        isCalculating: false,
        error: e.toString(),
      );
    }
  }

  void clear() {
    state = const RoutePlannerData();
  }
}

@freezed
class RoutePlannerData with _$RoutePlannerData {
  const factory RoutePlannerData({
    LatLng? startLocation,
    String? startAddress,
    LatLng? endLocation,
    String? endAddress,
    AppRoute? route,
    @Default(false) bool isCalculating,
    String? error,
  }) = _RoutePlannerData;
}
```

### TripStateProvider

```dart
@riverpod
class TripState extends _$TripState {
  @override
  TripStateData build() {
    return const TripStateData();
  }

  void setRoute(AppRoute route) {
    state = state.copyWith(route: route);
  }

  void addStop(POI poi) {
    final newStops = [...state.stops, poi];
    state = state.copyWith(stops: newStops);
  }

  void removeStop(String poiId) {
    final newStops = state.stops.where((p) => p.id != poiId).toList();
    state = state.copyWith(stops: newStops);
  }

  void reorderStops(int oldIndex, int newIndex) {
    final newStops = List<POI>.from(state.stops);
    final stop = newStops.removeAt(oldIndex);
    newStops.insert(newIndex, stop);
    state = state.copyWith(stops: newStops);
  }

  void clear() {
    state = const TripStateData();
  }
}

@freezed
class TripStateData with _$TripStateData {
  const factory TripStateData({
    AppRoute? route,
    @Default([]) List<POI> stops,
  }) = _TripStateData;

  bool get hasRoute => route != null;
  bool get hasStops => stops.isNotEmpty;
  double get totalDistance => route?.distanceKm ?? 0;
  int get totalDuration {
    final baseDuration = route?.durationMinutes ?? 0;
    final stopsDuration = stops.length * 45;
    return baseDuration + stopsDuration;
  }
}
```

### SearchScreen Integration

```dart
// lib/features/search/search_screen.dart
import '../map/providers/route_planner_provider.dart';

Future<void> _selectSuggestion(AutocompleteSuggestion suggestion) async {
  LatLng? location = suggestion.location;

  if (location == null && suggestion.placeId != null) {
    try {
      final geocodingRepo = ref.read(geocodingRepositoryProvider);
      final result = await geocodingRepo.geocode(suggestion.displayName);
      if (result.isNotEmpty) {
        location = result.first.location;
      }
    } catch (e) {
      debugPrint('[Search] Geocoding-Fehler: $e');
    }
  }

  if (location == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Standort nicht gefunden')),
    );
    return;
  }

  // In RoutePlanner State speichern
  final routePlanner = ref.read(routePlannerProvider.notifier);
  if (widget.isStartLocation) {
    routePlanner.setStart(location, suggestion.displayName);
  } else {
    routePlanner.setEnd(location, suggestion.displayName);
  }

  if (mounted) {
    context.pop();
  }
}
```

### MapScreen mit State-Anzeige

```dart
// lib/features/map/map_screen.dart
import 'providers/route_planner_provider.dart';

class MapScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routePlanner = ref.watch(routePlannerProvider);

    return Scaffold(
      appBar: AppBar(/* ... */),
      body: Stack(
        children: [
          const MapView(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _SearchBar(
                    startAddress: routePlanner.startAddress,
                    endAddress: routePlanner.endAddress,
                    isCalculating: routePlanner.isCalculating,
                    onStartTap: () => context.push('/search?type=start'),
                    onEndTap: () => context.push('/search?type=end'),
                  ),
                  // ...
                ],
              ),
            ),
          ),
          // FABs ...
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final String? startAddress;
  final String? endAddress;
  final bool isCalculating;
  final VoidCallback onStartTap;
  final VoidCallback onEndTap;

  const _SearchBar({
    this.startAddress,
    this.endAddress,
    this.isCalculating = false,
    required this.onStartTap,
    required this.onEndTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          _SearchField(
            icon: Icons.trip_origin,
            iconColor: AppTheme.successColor,
            hint: 'Startpunkt eingeben',
            value: startAddress,
            onTap: onStartTap,
          ),
          const Divider(height: 1, indent: 48),
          _SearchField(
            icon: Icons.place,
            iconColor: AppTheme.errorColor,
            hint: 'Ziel eingeben',
            value: endAddress,
            onTap: onEndTap,
          ),
          if (isCalculating)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Route wird berechnet...',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
```

### User Experience

**Vorher (v1.2.1):**
1. Start/Ziel eingeben
2. Route wird auf Karte gezeichnet ✅
3. Trip-Screen öffnen
4. **LEER** - "Noch keine Route geplant" ❌

**Nachher (v1.2.2):**
1. Start/Ziel eingeben
2. "Route wird berechnet..." Loading ✅
3. Route wird auf Karte gezeichnet ✅
4. Trip-Screen öffnen
5. **Route ist sichtbar!** ✅
   - Start: "München, Deutschland"
   - Ziel: "Berlin, Deutschland"
   - Entfernung: 585 km
   - Dauer: 5.5 Std

### Test-Anleitung

1. **App starten**
2. **Start eingeben:**
   - Suchleiste "Startpunkt eingeben" antippen
   - Stadt eingeben (z.B. "München")
   - Vorschlag auswählen
   - ✅ Adresse wird in Suchleiste angezeigt
3. **Ziel eingeben:**
   - Suchleiste "Ziel eingeben" antippen
   - Stadt eingeben (z.B. "Berlin")
   - Vorschlag auswählen
   - ✅ Loading-Indikator erscheint
   - ✅ Route wird auf Karte gezeichnet
4. **Trip-Screen öffnen:**
   - Bottom Navigation → "Trip"-Tab
   - ✅ Route ist sichtbar mit Start, Ziel, Entfernung, Dauer

---

```dart
String _generateDemoTrip(String destination, int days) {
  return '''
⚠️ Demo-Modus (kein API-Key konfiguriert)

🗺️ AI-Trip-Plan: $days Tage in $destination

Dies ist ein Beispiel-Trip. Für echte AI-generierte
Routen benötigst du einen OpenAI API-Key.

Konfiguriere den Key in:
lib/core/constants/api_keys.dart

Tag 1: Stadtbesichtigung
• Hauptsehenswürdigkeit A (2h)
• Mittagspause (1h)
• Museum B (2h)
• Altstadt erkunden (2h)

Tag 2: Umgebung
• Ausflug C (4h)
• Natur & Wandern (3h)
• Restaurant-Empfehlung (1h)

[...]
  ''';
}
```

### OpenAI API-Konfiguration

**Datei:** `lib/core/constants/api_keys.dart`

```dart
class ApiKeys {
  static const String openAiApiKey = 'sk-proj-...';
}
```

**Kosten-Schätzung:**
- Pro Trip-Generierung: ~1000 Tokens
- Kosten: ~$0.01-0.03 (GPT-4o)
- Empfehlung: $10 Guthaben = ~300-1000 Trips

---

## Dark Mode & Themes

**Feature #9 - Vollständig implementiert ab v1.2.3**

### Theme-Modi

| Modus | Beschreibung |
|-------|--------------|
| `system` | Folgt System-Einstellung (Default) |
| `light` | Heller Modus |
| `dark` | Dunkler Modus |
| `oled` | True Black (#000000) für AMOLED |

### Theme-Aktivierung

**Settings → Erscheinungsbild → Theme auswählen**

```dart
// lib/data/providers/settings_provider.dart
enum AppThemeMode {
  system('System', Icons.brightness_auto),
  light('Hell', Icons.light_mode),
  dark('Dunkel', Icons.dark_mode),
  oled('OLED Schwarz', Icons.brightness_1);
}
```

### Auto-Sunset Dark Mode

Automatischer Wechsel zu Dark Mode bei Sonnenuntergang:

```dart
// Aktivieren in Settings
setAutoSunsetDarkMode(true);

// Standort für Berechnung
setSunsetLocation(lat, lng);
```

### Theme-Farben (Referenz)

#### Light Theme
```dart
backgroundColor: Color(0xFFF8FAFC)  // Hellgrau
surfaceColor: Color(0xFFFFFFFF)     // Weiß
textPrimary: Color(0xFF1E293B)      // Dunkelgrau
textSecondary: Color(0xFF64748B)    // Grau
```

#### Dark Theme
```dart
darkBackgroundColor: Color(0xFF0F172A)  // Sehr dunkel
darkSurfaceColor: Color(0xFF1E293B)     // Dunkelgrau
darkTextPrimary: Color(0xFFF1F5F9)      // Fast weiß
darkTextSecondary: Color(0xFF94A3B8)    // Hellgrau
```

#### OLED Theme
```dart
oledBackgroundColor: Color(0xFF000000)  // True Black
oledSurfaceColor: Color(0xFF121212)     // Fast Black
oledCardColor: Color(0xFF1E1E1E)        // Dunkelgrau
```

### Korrekte Verwendung in Widgets

**RICHTIG:**
```dart
@override
Widget build(BuildContext context) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final isDark = theme.brightness == Brightness.dark;

  return Container(
    color: colorScheme.surface,
    child: Text(
      'Beispiel',
      style: TextStyle(color: colorScheme.onSurface),
    ),
  );
}
```

**FALSCH:**
```dart
// Niemals hart-codierte Farben!
Container(
  color: Colors.white,  // ❌
  child: Text(
    'Beispiel',
    style: TextStyle(color: AppTheme.textPrimary),  // ❌
  ),
)
```

### Geänderte Dateien (v1.2.3)

| Datei | Änderungen |
|-------|------------|
| `lib/app.dart` | Bottom Navigation, System UI |
| `lib/main.dart` | Statische UI-Einstellung entfernt |
| `lib/features/map/map_screen.dart` | AppBar, FABs, SearchBar, Toggle |
| `lib/features/poi/widgets/poi_card.dart` | Card-Farben, Text-Farben |
| `lib/features/trip/widgets/trip_stop_tile.dart` | Tile-Farben, Text-Farben |

---

## Kritische Fixes (Januar 2026)

### GPS-Handling in Random Trip (v1.2.3 Update)

**Verhalten:**
- Location Services Check vor GPS-Zugriff
- Bei deaktivierten Location Services: Fehler-Meldung an User
- Bei GPS-Fehler: Fehler-Meldung statt Fallback
- **NEU v1.2.3:** Automatische GPS-Abfrage wenn "Überrasch mich!" ohne Startpunkt geklickt wird

**Datei:** `lib/features/random_trip/providers/random_trip_provider.dart`

```dart
Future<void> useCurrentLocation() async {
  state = state.copyWith(isLoading: true, error: null);

  try {
    // Location Services Check
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('[RandomTrip] Location Services deaktiviert');
      state = state.copyWith(
        isLoading: false,
        error: 'Bitte aktiviere die Ortungsdienste in den Einstellungen',
      );
      return;
    }

    // Permission-Check
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Standort-Berechtigung verweigert');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Standort-Berechtigung dauerhaft verweigert');
    }

    // GPS-Position abrufen
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
      timeLimit: const Duration(seconds: 10),
    );
    print('[RandomTrip] Position: ${position.latitude}, ${position.longitude}');

    final location = LatLng(position.latitude, position.longitude);

    // Reverse Geocoding für Adresse
    final result = await _geocodingRepo.reverseGeocode(location);
    final address = result?.shortName ?? result?.displayName ?? 'Mein Standort';

    state = state.copyWith(
      startLocation: location,
      startAddress: address,
      useGPS: true,
      isLoading: false,
    );
  } catch (e) {
    print('[RandomTrip] GPS-Fehler: $e');
    state = state.copyWith(
      isLoading: false,
      error: 'Standort konnte nicht ermittelt werden: ${e.toString()}',
    );
  }
}
```

### AI Chat Demo-Modus entfernt

**Problem:** AI Chat zeigte Demo-Response obwohl OpenAI API-Key konfiguriert war.

**Fix:**
- Hart-codiertes `isConfigured = false` entfernt
- Integration mit `aiServiceProvider`
- Echte OpenAI API-Calls implementiert

**Datei:** `lib/features/ai_assistant/chat_screen.dart`

```dart
// ALT:
final isConfigured = false; // Demo: nicht konfiguriert

// NEU:
final aiService = ref.watch(aiServiceProvider);
final isConfigured = aiService.isConfigured;

// _sendMessage Methode geändert von void zu Future<void>
Future<void> _sendMessage(String text) async {
  // ... Validierung ...

  setState(() {
    _messages.add({'content': text, 'isUser': true, 'timestamp': DateTime.now()});
    _isLoading = true;
  });

  try {
    final aiService = ref.read(aiServiceProvider);

    if (!aiService.isConfigured) {
      // Fallback zu Demo
      setState(() {
        _messages.add({'content': _generateDemoResponse(text), 'isUser': false});
        _isLoading = false;
      });
      return;
    }

    // Echte API-Anfrage
    print('[Chat] Sende Anfrage an OpenAI...');
    final response = await aiService.chat(text);

    setState(() {
      _messages.add({'content': response, 'isUser': false, 'timestamp': DateTime.now()});
      _isLoading = false;
    });
  } catch (e) {
    print('[Chat] Fehler: $e');
    setState(() {
      _messages.add({
        'content': 'Entschuldigung, es gab einen Fehler. Bitte versuche es später erneut.',
        'isUser': false,
        'timestamp': DateTime.now()
      });
      _isLoading = false;
    });
  }
}
```

### PWA POI-Loading repariert

**Problem:** POIs wurden in der PWA nicht geladen wegen `lon` vs `lng` Inkonsistenz.

**Fixes:**

1. **curated-pois.js:** Alle 527 POIs von `"lon":` zu `"lng":` geändert
2. **poi-loader.js:** Fallback `p.lon || p.lng` entfernt, nur noch `p.lng`
3. **pois.js:** Legacy-POIs als LEGACY_POIS exportiert

---

## API-Keys Konfiguration

Erstelle `lib/core/constants/api_keys.dart`:

```dart
class ApiKeys {
  // Required für KI-Features
  static const openAiApiKey = 'sk-proj-...';  // OpenAI GPT-4o

  // Optional (Features funktionieren mit Fallbacks)
  static const tomtomApiKey = 'YOUR_KEY';        // TomTom Traffic API
  static const tankerkoenigApiKey = 'YOUR_KEY';  // Benzinpreise (nur DE)
  static const openChargeMapApiKey = 'YOUR_KEY'; // E-Ladestationen
}
```

---

## Code-Generierung

Nach Änderungen an Freezed/Riverpod-Klassen:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Oder Watch-Mode für Entwicklung:

```bash
flutter pub run build_runner watch
```

---

## Testing

### GPS-Fix testen

1. App im Android-Emulator starten
2. Random Trip öffnen
3. "Aktueller Standort" tippen
4. ✅ Erwartung: "München, Deutschland (Test-Standort)" wird angezeigt
5. ✅ Log: `[RandomTrip] Location Services deaktiviert - verwende München`

### AI Chat testen

1. AI Assistant öffnen
2. ✅ Erwartung: Kein Demo-Banner (da API-Key vorhanden)
3. Nachricht senden: "Empfiehl mir Burgen in Bayern"
4. ✅ Erwartung: Echte OpenAI-Antwort
5. ✅ Log: `[Chat] Sende Anfrage an OpenAI...`

### Account-System testen

1. App neu installieren (Clean Install)
2. ✅ Erwartung: Login Screen erscheint
3. "Als Gast fortfahren" tippen
4. ✅ Erwartung: Main Screen öffnet sich
5. Einstellungen → Profil öffnen
6. ✅ Erwartung: Gast-Account mit Level 1, 0 XP angezeigt
7. "Lokales Profil erstellen" → Username eingeben
8. ✅ Erwartung: Account erstellt, in Hive gespeichert
9. App neu starten
10. ✅ Erwartung: Direkt zum Main Screen (Auto-Login)

---

## Lizenz

MIT License - Copyright (c) 2026 MapAB Team
