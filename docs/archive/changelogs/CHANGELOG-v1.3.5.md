# Changelog v1.3.5 - AI Trip & Remember Me

**Release-Datum:** 23. Januar 2026

## Neue Features

### 1. AI Trip Toggle auf der Karte

Der neue "AI Trip" Toggle ersetzt den bisherigen "Landschaft"-Button und bietet direkten Zugang zum AI Trip Generator.

#### Funktionsweise
- **Position:** Neben dem "Schnell"-Button in der Route-Toggle-Leiste
- **Icon:** `auto_awesome` (Sterne-Symbol)
- **Aktion:** Navigiert direkt zu `/random-trip`
- **Visual Feedback:** Button wird blau wenn geklickt, "Schnell" wird weiß

#### UI-Änderungen

```
Vorher:  [Schnell]  [Landschaft]  + 🎲 Zufalls-Trip FAB
Nachher: [Schnell]  [AI Trip]    (FAB entfernt)
```

**Entfernte Elemente:**
- ~~Zufalls-Trip FloatingActionButton~~ (links unten) - Funktion über Toggle verfügbar
- ~~Zoom-Buttons (+/-)~~ - Für saubereres Design entfernt

### 2. Automatische POI-Bereinigung

POIs werden automatisch gelöscht wenn eine neue Route berechnet wird.

#### Funktionsweise
- **Bei Schnell-Route:** Alte POIs werden vor Berechnung gelöscht
- **Bei AI Trip:** Alte POIs werden bei `confirmTrip()` gelöscht
- **Bei AI Chat Route:** Alte POIs werden vor Navigation gelöscht
- **Bei Route löschen:** Alle POIs werden entfernt

#### Betroffene Provider
| Provider | Methode | POI-Löschung |
|----------|---------|--------------|
| `routePlannerProvider` | `_tryCalculateRoute()` | ✅ |
| `routePlannerProvider` | `clearRoute()` | ✅ |
| `routeSessionProvider` | `_loadPOIs()` | ✅ |
| `randomTripProvider` | `confirmTrip()` | ✅ |
| `ChatScreen` | `_generateRandomTripFromLocation()` | ✅ |

### 3. Umbenennung: Random-Trip → AI Trip

Das gesamte "Zufalls-Trip" Feature wurde konsistent in "AI Trip" umbenannt:

| Vorher | Nachher |
|--------|---------|
| Zufalls-Tagesausflug | AI Tagesausflug |
| Euro Trip | AI Euro Trip |
| Zufalls-Trip | AI Trip |
| Mode-Icon 🚗 | Mode-Icon 🤖 |

### 4. Anmeldedaten merken (Remember Me)

Neue Checkbox im Login-Screen zum Speichern der Login-Credentials.

#### Funktionsweise
1. **Checkbox aktiviert** → Bei erfolgreichem Login werden E-Mail und Passwort gespeichert
2. **Nächster App-Start** → Felder werden automatisch ausgefüllt
3. **Checkbox deaktiviert** → Gespeicherte Credentials werden gelöscht

#### Sicherheit
- **Speicherort:** Hive Box "settings"
- **Encoding:** Base64 für Passwort (Obfuskation, keine Verschlüsselung)
- **Löschung:** Automatisch bei Deaktivierung der Checkbox

#### UI-Design

```
┌────────────────────────────────────────────┐
│  [✓] Anmeldedaten merken   Passwort vergessen?  │
└────────────────────────────────────────────┘
```

## Technische Änderungen

### Neue Settings-Felder

```dart
// lib/data/providers/settings_provider.dart

class AppSettings {
  // ... bestehende Felder ...

  // Remember Me Feature (NEU)
  final bool rememberMe;
  final String? savedEmail;
  final String? savedPasswordEncoded; // Base64-encoded
}
```

### Neue Settings-Methoden

```dart
// Credentials speichern
Future<void> saveCredentials(String email, String password)

// Credentials löschen
Future<void> clearCredentials()

// Remember Me aktivieren/deaktivieren
Future<void> setRememberMe(bool enabled)
```

### Neue AppSettings-Getter

```dart
// Passwort automatisch dekodieren
String? get savedPassword

// Prüfen ob Credentials vorhanden
bool get hasStoredCredentials
```

### Login-Screen Änderungen

```dart
// lib/features/auth/login_screen.dart

// Neuer State
bool _rememberMe = false;

// Beim Start: Credentials laden
void _loadSavedCredentials() {
  final settings = ref.read(settingsNotifierProvider);
  if (settings.hasStoredCredentials) {
    _emailController.text = settings.savedEmail ?? '';
    _passwordController.text = settings.savedPassword ?? '';
    _rememberMe = true;
  }
}

// Bei Login: Credentials speichern/löschen
if (_rememberMe) {
  await settingsNotifier.saveCredentials(email, password);
} else {
  await settingsNotifier.clearCredentials();
}
```

### AI Trip Toggle Änderungen

```dart
// lib/features/map/map_screen.dart

class _RouteToggleState extends State<_RouteToggle> {
  int _selectedIndex = 0; // 0 = Schnell, 1 = AI Trip

  // ...
  _ToggleButton(
    label: 'AI Trip',
    icon: Icons.auto_awesome,
    isSelected: _selectedIndex == 1,
    onTap: () {
      setState(() => _selectedIndex = 1);
      GoRouter.of(context).push('/random-trip');
    },
  ),
}
```

### POI-Bereinigung bei neuer Route

```dart
// lib/features/map/providers/route_planner_provider.dart

Future<void> _tryCalculateRoute() async {
  // ...
  // Alte Route-Session stoppen und POIs löschen
  ref.read(routeSessionProvider.notifier).stopRoute();
  ref.read(pOIStateNotifierProvider.notifier).clearPOIs();
  // ...
}

void clearRoute() {
  // ...
  ref.read(routeSessionProvider.notifier).stopRoute();
  ref.read(pOIStateNotifierProvider.notifier).clearPOIs();
}
```

### Mode Labels Änderungen

```dart
// lib/features/random_trip/providers/random_trip_state.dart

enum RandomTripMode {
  daytrip('AI Tagesausflug', '🤖'),  // War: 'Tagesausflug', '🚗'
  eurotrip('AI Euro Trip', '✈️');    // War: 'Euro Trip'
}
```

## Geänderte Dateien

| Datei | Änderung |
|-------|----------|
| `lib/data/providers/settings_provider.dart` | Remember Me State + Methoden |
| `lib/features/auth/login_screen.dart` | Checkbox + Auto-Fill Logik |
| `lib/features/map/map_screen.dart` | AI Trip Toggle, Zoom-Buttons + FAB entfernt |
| `lib/features/map/providers/route_planner_provider.dart` | POI-Löschung bei neuer Route |
| `lib/features/map/providers/route_session_provider.dart` | POI-Löschung vor Laden |
| `lib/features/random_trip/providers/random_trip_provider.dart` | POI-Löschung bei confirmTrip() |
| `lib/features/ai_assistant/chat_screen.dart` | POI-Löschung bei AI-Route |
| `lib/features/random_trip/random_trip_screen.dart` | AppBar-Titel aktualisiert |
| `lib/features/random_trip/providers/random_trip_state.dart` | Mode Labels + Icons |
| `pubspec.yaml` | Version 1.3.5+1 |

## Log-Prefixes

Neue Debug-Logs:

| Prefix | Nachricht |
|--------|-----------|
| `[Settings]` | "Anmeldedaten gespeichert für: {email}" |
| `[Settings]` | "Gespeicherte Anmeldedaten gelöscht" |
| `[Login]` | "Gespeicherte Anmeldedaten geladen" |
| `[RoutePlanner]` | "Alte Route-Session und POIs gelöscht" |
| `[RoutePlanner]` | "Route, Session und POIs gelöscht" |
| `[RouteSession]` | "Alte POIs gelöscht" |
| `[RandomTrip]` | "Alte POIs gelöscht" |
| `[AI-Chat]` | "Alte Route-Session und POIs gelöscht" |

## Migration

Keine Migrationsschritte erforderlich. Die neuen Settings-Felder haben Default-Werte:
- `rememberMe: false`
- `savedEmail: null`
- `savedPasswordEncoded: null`

## Bekannte Limitierungen

1. **Sicherheit:** Base64 ist keine echte Verschlüsselung. Für Produktionsumgebungen sollte `flutter_secure_storage` verwendet werden.
2. **Logout:** Bei Logout werden die Credentials NICHT automatisch gelöscht (Benutzer muss Checkbox deaktivieren).

## Download

**GitHub Release:** https://github.com/jerdnaandrej777/mapab-app/releases/tag/v1.3.5

**APK:** MapAB-v1.3.5.apk (57 MB)
