# CLAUDE.md - MapAB Flutter App

Diese Datei bietet Orientierung für Claude Code bei der Arbeit mit diesem Flutter-Projekt.

## Projektübersicht

Flutter-basierte mobile App für interaktive Routenplanung und POI-Entdeckung in Europa.
Basiert auf dem Konzept der MapAB Web-App (`../Mobi/`).

## Tech Stack

- **Flutter**: 3.24.5+
- **State Management**: Riverpod 2.x mit Code-Generierung
- **Routing**: GoRouter mit Bottom Navigation
- **Karte**: flutter_map mit MapLibre
- **HTTP**: Dio mit Cache
- **Lokale Daten**: Hive (Favoriten, Settings, Account)
- **Models**: Freezed für immutable Klassen
- **AI**: OpenAI GPT-4o Integration

## Entwicklung

```bash
# Dependencies installieren
flutter pub get

# Code-Generierung (nach Model-Änderungen)
flutter pub run build_runner build --delete-conflicting-outputs

# Watch-Mode für kontinuierliche Generierung
flutter pub run build_runner watch

# App starten
flutter run

# Release Build
flutter build apk
```

## Architektur

### Schichten

```
┌─────────────────────────────────────┐
│           UI (features/)            │  Screens, Widgets
├─────────────────────────────────────┤
│         Providers (Riverpod)        │  State Management
├─────────────────────────────────────┤
│      Services & Repositories        │  Business Logic
├─────────────────────────────────────┤
│            Models (data/)           │  Datenstrukturen
├─────────────────────────────────────┤
│          External APIs              │  Nominatim, OSRM, etc.
└─────────────────────────────────────┘
```

### Wichtige Dateien

| Datei | Beschreibung |
|-------|--------------|
| `lib/app.dart` | Main App mit GoRouter (inkl. `/profile`, `/favorites`) |
| `lib/features/map/map_screen.dart` | Hauptscreen mit AppBar (Profil + Favoriten Buttons) |
| `lib/features/account/profile_screen.dart` | Account-Profil mit Level, XP, Achievements |
| `lib/features/favorites/favorites_screen.dart` | Favoriten-Management (Routen + POIs) |
| `lib/features/ai_assistant/chat_screen.dart` | AI-Chat mit Trip-Generator Dialog |
| `lib/data/providers/favorites_provider.dart` | Favoriten State Management |
| `lib/data/providers/account_provider.dart` | Account State Management |
| `lib/data/services/ai_service.dart` | OpenAI GPT-4o Integration (Chat + Trip-Planning) |
| `lib/data/repositories/poi_repo.dart` | POI-Laden (3-Schichten: Curated → Wiki → Overpass) |
| `lib/data/repositories/weather_repo.dart` | Open-Meteo Wetter-API |
| `lib/data/services/hotel_service.dart` | Hotel-Suche mit Amenities & Booking.com |
| `lib/core/constants/api_keys.dart` | API-Keys (OpenAI, TomTom, etc.) |
| `assets/data/curated_pois.json` | 527 kuratierte POIs |

## API-Abhängigkeiten

| API | Zweck | Auth |
|-----|-------|------|
| Nominatim | Geocoding | - |
| OSRM | Fast Routing | - |
| OpenRouteService | Scenic Routing | API-Key |
| Overpass | POIs & Hotels | - |
| Wikipedia DE | Geosearch | - |
| Open-Meteo | Wetter | - |
| OpenAI | AI-Chat | API-Key |

## POI-Datenstruktur

### Kuratierte POIs (JSON)
```json
{
  "id": "de-1",
  "n": "Brandenburger Tor",
  "lat": 52.5163,
  "lng": 13.3777,
  "c": "monument",
  "r": 98,
  "tags": ["monument", "berlin"],
  "curated": true
}
```

Mapping:
- `n` = name
- `c` = category
- `r` = score (0-100)

### POI Model (Dart)
```dart
POI(
  id: 'de-1',
  name: 'Brandenburger Tor',
  latitude: 52.5163,
  longitude: 13.3777,
  categoryId: 'monument',
  score: 98,
  // Berechnete Felder:
  routePosition: 0.45,      // 0 = Start, 1 = Ende
  detourKm: 12.0,
  detourMinutes: 15,
  effectiveScore: 87.0,     // Nach Umweg-Berechnung
)
```

## POI-Kategorien

### Indoor-Kategorien (für Wetter-Filter)
- `museum`
- `church`
- `restaurant`
- `hotel`

### Outdoor-Kategorien
- `castle`, `nature`, `viewpoint`, `lake`, `coast`, `park`, `city`, `activity`, `monument`, `attraction`

## Wetter-Logik

### WeatherCondition Enum
- `good` - Klar, sonnig
- `mixed` - Wechselhaft
- `bad` - Regen, Schnee
- `danger` - Gewitter, Sturm
- `unknown` - Keine Daten

### Scoring-Anpassung
```dart
// Bei schlechtem Wetter (bad/danger):
// Indoor-POIs: Score + 15
// Outdoor-POIs: Score - 10

// Bei gutem Wetter:
// Outdoor-POIs: Score + 5
```

## Hotel-Service

### HotelSuggestion
```dart
HotelSuggestion(
  name: 'Hotel Beispiel',
  type: HotelType.hotel,
  stars: 4,
  amenities: HotelAmenities(
    wifi: true,
    parking: true,
    breakfast: true,
  ),
  checkInTime: '14:00',
  checkOutTime: '11:00',
)
```

### Booking.com URL
```dart
hotel.getBookingUrl(checkIn: DateTime.now());
// => https://www.booking.com/searchresults.html?ss=Hotel+Name&checkin=2026-01-21&...
```

## Riverpod Provider

### Wichtige Provider
```dart
// POI Repository
final poiRepositoryProvider

// Weather Repository
final weatherRepositoryProvider

// Route Weather State
final routeWeatherNotifierProvider

// Indoor-Only Filter
final indoorOnlyFilterProvider

// Map Controller
final mapControllerProvider

// Hotel Service
final hotelServiceProvider

// AI Service
final aiServiceProvider

// Account State (Level, XP, Achievements)
final accountNotifierProvider

// Favoriten State (Routen + POIs)
final favoritesNotifierProvider

// Settings State (Dark Mode, OLED, Auto-Sunset)
final settingsNotifierProvider

// Route-Planner State (v1.2.2)
final routePlannerProvider

// Trip-State (v1.2.1+, keepAlive seit v1.2.3)
final tripStateProvider

// Random-Trip State (v1.2.3 - GPS Auto-Query)
final randomTripNotifierProvider
```

## Random-Trip Flow (v1.2.3) ⭐ NEU

### Problem (vor v1.2.3)
- `confirmTrip()` setzte nur den Schritt auf `confirmed`, übergab aber Route nicht an tripStateProvider
- Trip-Screen blieb leer nach AI-Trip-Generierung
- Startfeld war Pflicht - User musste manuell Adresse eingeben oder GPS klicken

### Lösung

#### 1. Automatische GPS-Abfrage in generateTrip()

```dart
// lib/features/random_trip/providers/random_trip_provider.dart
Future<void> generateTrip() async {
  // NEU: Wenn kein Startpunkt gesetzt, automatisch GPS abfragen
  if (!state.hasValidStart) {
    await useCurrentLocation();

    if (!state.hasValidStart) {
      state = state.copyWith(
        error: 'Bitte gib einen Startpunkt ein oder aktiviere GPS',
      );
      return;
    }
  }

  // ... Rest der Trip-Generierung
}
```

#### 2. canGenerate vereinfacht

```dart
// lib/features/random_trip/providers/random_trip_state.dart
// VORHER: bool get canGenerate => hasValidStart && !isLoading;
// NACHHER:
bool get canGenerate => !isLoading;  // Startpunkt ist optional
```

#### 3. confirmTrip() übergibt Route an TripStateProvider

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

#### 4. TripStateProvider mit keepAlive

```dart
// lib/features/trip/providers/trip_state_provider.dart
// VORHER: @riverpod (AutoDispose - State verloren bei Navigation)
// NACHHER:
@Riverpod(keepAlive: true)  // State bleibt erhalten
class TripState extends _$TripState { ... }
```

### State-Flow (v1.2.3)

```
┌─────────────────────────────────────────────────────┐
│     User klickt "Überrasch mich!" (ohne Start)      │
└──────────────────┬──────────────────────────────────┘
                   │
                   v
┌─────────────────────────────────────────────────────┐
│  generateTrip() prüft: hasValidStart? NEIN          │
│  → useCurrentLocation() wird automatisch aufgerufen │
└──────────────────┬──────────────────────────────────┘
                   │
                   v
┌─────────────────────────────────────────────────────┐
│  GPS-Position ermittelt (oder München-Fallback)     │
│  → state.startLocation + startAddress gesetzt       │
└──────────────────┬──────────────────────────────────┘
                   │
                   v
┌─────────────────────────────────────────────────────┐
│  Trip wird generiert (tripGeneratorRepository)      │
│  → POIs geladen, Route optimiert, Stops erstellt    │
└──────────────────┬──────────────────────────────────┘
                   │
                   v
┌─────────────────────────────────────────────────────┐
│  User klickt "Bestätigen"                           │
│  → confirmTrip() aufgerufen                         │
└──────────────────┬──────────────────────────────────┘
                   │
                   v
┌─────────────────────────────────────────────────────┐
│  tripStateProvider.setRoute(route)                  │
│  tripStateProvider.setStops(pois)                   │
│  → State wird persistent gespeichert (keepAlive)    │
└──────────────────┬──────────────────────────────────┘
                   │
                   v
┌─────────────────────────────────────────────────────┐
│  Navigation zu /trip                                │
│  → TripScreen zeigt Route + Stops ✅                │
└─────────────────────────────────────────────────────┘
```

### Geänderte Dateien

| Datei | Änderung |
|-------|----------|
| `random_trip_provider.dart` | Import + generateTrip() + confirmTrip() |
| `random_trip_state.dart` | canGenerate vereinfacht |
| `trip_state_provider.dart` | @Riverpod(keepAlive: true) |
| `trip_state_provider.g.dart` | NotifierProvider statt AutoDisposeNotifierProvider |

---

## Route-Planner Architektur (v1.2.2)

### State-Flow

```
┌─────────────────────────────────────────────────────┐
│              User wählt Standort                     │
│                 (SearchScreen)                       │
└──────────────────┬──────────────────────────────────┘
                   │
                   v
┌─────────────────────────────────────────────────────┐
│        routePlannerProvider.setStart() /             │
│        routePlannerProvider.setEnd()                 │
└──────────────────┬──────────────────────────────────┘
                   │
                   v
┌─────────────────────────────────────────────────────┐
│    routePlannerProvider._tryCalculateRoute()         │
│    (automatisch wenn beide gesetzt)                  │
└──────────────────┬──────────────────────────────────┘
                   │
                   v
┌─────────────────────────────────────────────────────┐
│      routingRepository.calculateFastRoute()          │
│      (OSRM API Call)                                 │
└──────────────────┬──────────────────────────────────┘
                   │
                   v
┌─────────────────────────────────────────────────────┐
│  tripStateProvider.setRoute(route) ← KEY CONNECTION  │
└──────────────────┬──────────────────────────────────┘
                   │
                   v
┌─────────────────────────────────────────────────────┐
│        TripScreen zeigt Route an ✅                  │
│        (Start, Ziel, Entfernung, Dauer)              │
└─────────────────────────────────────────────────────┘
```

### Provider-Dateien

| Datei | Beschreibung |
|-------|--------------|
| `lib/features/map/providers/route_planner_provider.dart` | Start/Ziel-Verwaltung + Auto-Berechnung |
| `lib/features/trip/providers/trip_state_provider.dart` | Trip-State für Anzeige (Route + Stops) |

### RoutePlannerData

```dart
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

### TripStateData

```dart
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
    final stopsDuration = stops.length * 45; // 45 Min pro Stop
    return baseDuration + stopsDuration;
  }
}
```

### Integration in SearchScreen

```dart
// lib/features/search/search_screen.dart
Future<void> _selectSuggestion(AutocompleteSuggestion suggestion) async {
  // ... Geocoding ...

  final routePlanner = ref.read(routePlannerProvider.notifier);
  if (widget.isStartLocation) {
    routePlanner.setStart(location, suggestion.displayName);
  } else {
    routePlanner.setEnd(location, suggestion.displayName);
  }

  context.pop();
}
```

### Integration in MapScreen

```dart
// lib/features/map/map_screen.dart
@override
Widget build(BuildContext context) {
  final routePlanner = ref.watch(routePlannerProvider);

  return Scaffold(
    body: Stack(
      children: [
        const MapView(),
        _SearchBar(
          startAddress: routePlanner.startAddress,     // NEU
          endAddress: routePlanner.endAddress,         // NEU
          isCalculating: routePlanner.isCalculating,   // NEU
          onStartTap: () => context.push('/search?type=start'),
          onEndTap: () => context.push('/search?type=end'),
        ),
        // ...
      ],
    ),
  );
}
```

## Konventionen

- **Sprache**: Deutsche UI-Labels, englischer Code
- **IDs**: `{land}-{nummer}` (z.B. `de-1`)
- **Dateien**: snake_case für Dart-Dateien
- **Klassen**: PascalCase
- **Provider**: camelCase mit `Provider` Suffix

## Debugging

### Debug-Logging aktiviert für:
- `[POI]` - POI-Laden
- `[Weather]` - Wetter-Laden
- `[AI]` - AI-Anfragen (inkl. API-Key Präfix)
- `[GPS]` - GPS-Funktionen

### AI-Fehler prüfen
Bei AI-Problemen zeigt das Logging:
- API-Key Präfix (erste 20 Zeichen)
- HTTP Status Code
- Detaillierte Fehlermeldung

## Android-Berechtigungen

In `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

## Bekannte Einschränkungen

1. **Wikipedia API**: 10km Radius-Limit pro Anfrage
2. **Overpass API**: Rate-Limiting, kann langsam sein
3. **OpenAI**: Benötigt aktives Guthaben
4. **GPS**: Nur mit HTTPS/Release Build zuverlässig

## Feature-Übersicht (Version 1.2.4)

### Kern-Features
- 🗺️ **Interaktive Karte** mit POI-Markern
- 📍 **POI-Entdeckung** (527+ kuratierte + Wikipedia + Overpass)
- 🚗 **Routenplanung** (Fast/Scenic mit Optimierung)
- 🌤️ **Wetter-Integration** (Indoor-Filter bei schlechtem Wetter)
- 🏨 **Hotel-Suche** mit Booking.com Links

### Account & Social (v1.2.0+)
- 👤 **Profil-System** mit Level & XP
- 🏆 **21 Achievements** (Bronze, Silber, Gold)
- ❤️ **Favoriten** mit Kategorien (Routen + POIs)
- 📊 **Statistiken** (Trips, KM, POIs besucht)

### AI-Features (v1.2.0+)
- 💬 **AI-Chat** mit OpenAI GPT-4o
- 🤖 **AI-Trip-Generator** (1-7 Tage, Interessen-basiert)
- 🎯 **Intelligente POI-Empfehlungen**
- 📝 **Formatierte Trip-Pläne** mit Tages-Breakdown

### UI-Verbesserungen (v1.2.1+)
- 🎨 **AppBar auf MapScreen** (Profil + Favoriten)
- 🌙 **Dark Mode** mit Auto-Sunset
- 🎯 **Transparente AppBar** mit `extendBodyBehindAppBar`
- 📱 **Bottom Navigation** (Karte, POIs, Trip, AI)
- ⚙️ **Settings-Button** über GPS-Button (v1.2.1)
- 🎯 **AI-Trip-Dialog** Text-Fix (v1.2.1)

### Route-Planner Integration (v1.2.2)
- 🚗 **Automatische Routenberechnung** wenn Start + Ziel gesetzt
- 📍 **Adressen-Anzeige** in Suchleiste
- ⏳ **Loading-Indikator** während Berechnung
- 🎯 **Trip-Screen** zeigt berechnete Routen korrekt an

### Trip-Screen Fix (v1.2.3)
- 🐛 **Trip-Screen zeigt Route nach AI-Trip** - confirmTrip() übergibt Route an tripStateProvider
- 📍 **Automatische GPS-Abfrage** - Bei "Überrasch mich!" ohne Startpunkt wird GPS automatisch aktiviert
- ✅ **Startfeld optional** - canGenerate prüft nur noch isLoading
- 🔄 **keepAlive Provider** - TripStateProvider behält State beim Navigation
- 🌙 **Dark Mode vollständig** für alle Hauptkomponenten

### AI-Trip ohne Ziel (v1.2.4) ⭐ NEU
- 🎲 **Ziel optional** - AI-Trip-Dialog erlaubt leeres Ziel-Feld
- 📍 **GPS-Fallback** - Ohne Startpunkt wird automatisch GPS-Standort abgefragt
- 🎯 **Interessen-Mapping** - Gewählte Interessen werden zu POI-Kategorien gemappt
- 🚗 **Direkt zu Trip-Screen** - Bei leerem Ziel wird Random Route generiert und angezeigt
- 💬 **Hybrid-Modus** - Mit Ziel: AI-Text-Plan im Chat | Ohne Ziel: Random Route → Trip-Screen

## Navigation-Struktur

### Routen (GoRouter)
```dart
/                    → MapScreen (mit AppBar)
/pois               → POIListScreen
/poi/:id            → POIDetailScreen
/trip               → TripScreen
/assistant          → ChatScreen (AI)
/profile            → ProfileScreen ⭐ NEU v1.2.0
/favorites          → FavoritesScreen ⭐ NEU v1.2.0
/settings           → SettingsScreen
/search             → SearchScreen
/random-trip        → RandomTripScreen
/login              → LoginScreen
```

### Bottom Navigation Tabs
1. 🗺️ **Karte** - MapScreen (Default)
2. 📍 **POIs** - POI-Liste mit Filter
3. 🚗 **Trip** - Routenplanung
4. 🤖 **AI** - Chat-Assistent

### AppBar Actions (MapScreen)
- ❤️ **Favoriten-Button** → `/favorites`
- 👤 **Profil-Button** → `/profile`

## AI-Integration (v1.2.0)

### AI-Service Features
```dart
// Chat mit Kontext
aiService.chat(
  message: 'Welche Sehenswürdigkeiten gibt es?',
  context: TripContext(route: route, stops: stops),
  history: chatHistory,
);

// Trip-Generierung
aiService.generateTripPlan(
  destination: 'Prag',
  days: 3,
  interests: ['Kultur', 'Natur'],
  startLocation: 'München', // optional
);

// POI-Empfehlungen
aiService.getRecommendations(
  route: currentRoute,
  interests: ['Geschichte', 'Essen'],
);
```

### Trip-Generator Dialog (ChatScreen) - v1.2.4 Update

**Eingabefelder:**
- **Ziel (optional)**: TextField - Leer = Random Route um Startpunkt
- **Start (optional)**: TextField - Leer = GPS-Standort abfragen
- **Tage**: Slider (1-7 Tage)
- **Interessen**: FilterChips (Kultur, Natur, Geschichte, Essen, Nightlife, Shopping, Sport)

**Hybrid-Verhalten:**
| Start | Ziel | Ergebnis |
|-------|------|----------|
| leer | leer | GPS → Random Route → Trip-Screen |
| "Berlin" | leer | Geocode Berlin → Random Route → Trip-Screen |
| beliebig | "Prag" | AI-Text-Plan im Chat (wie bisher) |

**Interessen → Kategorien Mapping:**
```dart
'Kultur' → ['museum', 'monument', 'unesco']
'Natur' → ['nature', 'park', 'lake', 'viewpoint']
'Geschichte' → ['castle', 'church', 'monument']
'Essen' → ['restaurant']
'Nightlife' → ['city']
'Shopping' → ['city']
'Sport' → ['activity']
```

## Vergleich mit Web-Version (Mobi/)

| Feature | Web (Mobi/) | Flutter App |
|---------|-------------|-------------|
| POI-Laden | 3-Schichten | 3-Schichten |
| Wetter | Open-Meteo + Polling | Open-Meteo |
| Hotels | Overpass + OSM | Overpass + OSM |
| AI-Chat | Nicht verfügbar | ✅ GPT-4o |
| AI-Trip-Gen | Nicht verfügbar | ✅ 1-7 Tage |
| Profil/Account | Nicht verfügbar | ✅ Level & XP |
| Favoriten | LocalStorage v2 | ✅ Hive mit Kategorien |
| Achievements | Nicht verfügbar | ✅ 21 Achievements |
| Dark Mode | Nicht verfügbar | ✅ Auto-Sunset |
| Karte | MapLibre GL JS | flutter_map |
| State | Vanilla JS | Riverpod |
| Plattform | Web (PWA) | iOS/Android/Desktop |

## Dark Mode Implementierung (v1.2.3)

### Theme-Provider

```dart
// Settings Provider mit Theme-Modus
@Riverpod(keepAlive: true)
class SettingsNotifier extends _$SettingsNotifier {
  Future<void> setThemeMode(AppThemeMode mode) async { ... }
}

// Effektiver Theme-Modus (berücksichtigt Auto-Sunset)
@riverpod
ThemeMode effectiveThemeMode(Ref ref) { ... }
```

### Korrekte Widget-Implementierung

**MUSS verwendet werden in allen Widgets mit Hintergrund/Text:**

```dart
@override
Widget build(BuildContext context) {
  // Theme-Variablen IMMER am Anfang
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final isDark = theme.brightness == Brightness.dark;

  return Container(
    decoration: BoxDecoration(
      // ✅ RICHTIG: Theme-Farbe
      color: colorScheme.surface,
      boxShadow: [
        BoxShadow(
          // ✅ RICHTIG: Stärkere Schatten im Dark Mode
          color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
          blurRadius: 10,
        ),
      ],
    ),
    child: Text(
      'Text',
      style: TextStyle(
        // ✅ RICHTIG: Theme-Textfarbe
        color: colorScheme.onSurface,
      ),
    ),
  );
}
```

### VERBOTEN (verursacht Dark Mode Bugs)

```dart
// ❌ NIEMALS hart-codierte Farben:
color: Colors.white,
color: Colors.black,

// ❌ NIEMALS statische AppTheme-Farben:
color: AppTheme.textPrimary,
color: AppTheme.textSecondary,
color: AppTheme.backgroundColor,

// ❌ NIEMALS statische Schatten:
boxShadow: AppTheme.cardShadow,
```

### Geänderte Dateien (Referenz)

| Datei | Fixes |
|-------|-------|
| `lib/app.dart` | Bottom Navigation, NavItems, System UI |
| `lib/main.dart` | Statische SystemUI entfernt |
| `lib/features/map/map_screen.dart` | AppBar, FABs, SearchBar, Toggle |
| `lib/features/poi/widgets/poi_card.dart` | Card, Badge, Texte |
| `lib/features/trip/widgets/trip_stop_tile.dart` | Tile, Icon-BG, Texte |

### Theme-Farben (Referenz)

```dart
// Light Mode (aus app_theme.dart)
surfaceColor: Color(0xFFFFFFFF)     // Weiß
textPrimary: Color(0xFF1E293B)      // Dunkelgrau

// Dark Mode
darkSurfaceColor: Color(0xFF1E293B) // Dunkelgrau
darkTextPrimary: Color(0xFFF1F5F9)  // Fast weiß

// OLED Mode
oledBackgroundColor: Color(0xFF000000) // True Black
```
