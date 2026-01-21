# MapAB Flutter App - Vollständige Feature-Dokumentation

Version: 1.0.0 (Januar 2026)

## Inhaltsverzeichnis

1. [Übersicht](#übersicht)
2. [Account-System](#account-system-neu)
3. [Dark Mode & Themes](#dark-mode--themes)
4. [Push-Benachrichtigungen](#push-benachrichtigungen)
5. [Echtzeit-Verkehrsdaten](#echtzeit-verkehrsdaten)
6. [Trip-Sharing & QR-Codes](#trip-sharing--qr-codes)
7. [KI-Personalisierung](#ki-personalisierung)
8. [Budget-Tracker](#budget-tracker)
9. [Höhenprofil](#höhenprofil)
10. [Reisetagebuch](#reisetagebuch)
11. [Barrierefreiheit](#barrierefreiheit)
12. [Gamification](#gamification)
13. [Sprachsteuerung](#sprachsteuerung)
14. [Services](#services)
15. [Emulator-Optimierungen](#emulator-optimierungen)

---

## Übersicht

Die MapAB Flutter App ist eine Cross-Platform Reiseplanungs-App für iOS, Android und Desktop mit 14 implementierten Haupt-Features.

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

## Account-System (NEU)

**Feature #14 - Januar 2026**

Local-First Account-Management mit Multi-Profilen, Gamification und Statistik-Tracking.

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

## Dark Mode & Themes

[... Rest der Dokumentation für andere Features ...]

---

## Kritische Fixes (Januar 2026)

### GPS-Fix in Random Trip

**Problem:** GPS funktionierte nicht im Android-Emulator, App crashte.

**Fix:**
- Location Services Check vor GPS-Zugriff hinzugefügt
- München-Fallback (48.1351, 11.5820) implementiert
- Strukturiertes Logging für Debugging

**Datei:** `lib/features/random_trip/providers/random_trip_provider.dart`

```dart
Future<void> useCurrentLocation() async {
  state = state.copyWith(isLoading: true, error: null);

  try {
    // NEU: Location Services Check
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('[RandomTrip] Location Services deaktiviert - verwende München');
      const munich = LatLng(48.1351, 11.5820);
      const name = 'München, Deutschland (Test-Standort)';

      state = state.copyWith(
        startLocation: munich,
        startAddress: name,
        useGPS: true,
        isLoading: false,
      );
      return;
    }

    // Bestehender Permission-Check
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    // GPS-Position abrufen
    final position = await Geolocator.getCurrentPosition();
    print('[RandomTrip] Position: ${position.latitude}, ${position.longitude}');

    // ... Reverse Geocoding ...

  } catch (e) {
    print('[RandomTrip] GPS-Fehler: $e');

    // NEU: München-Fallback bei Fehler
    const munich = LatLng(48.1351, 11.5820);
    const name = 'München, Deutschland (GPS nicht verfügbar)';

    state = state.copyWith(
      startLocation: munich,
      startAddress: name,
      useGPS: true,
      isLoading: false,
      error: 'Standort nicht verfügbar - nutze Test-Standort München',
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
