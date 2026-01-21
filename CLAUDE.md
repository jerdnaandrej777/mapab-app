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

## Feature-Übersicht (Version 1.2.0)

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

### UI-Verbesserungen (v1.2.0)
- 🎨 **AppBar auf MapScreen** (Profil + Favoriten)
- 🌙 **Dark Mode** mit Auto-Sunset
- 🎯 **Transparente AppBar** mit `extendBodyBehindAppBar`
- 📱 **Bottom Navigation** (Karte, POIs, Trip, AI)

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

### Trip-Generator Dialog (ChatScreen)
- **Ziel**: TextField mit Städte-Eingabe
- **Tage**: Slider (1-7 Tage)
- **Interessen**: FilterChips (Kultur, Natur, Geschichte, Essen, Nightlife, Shopping, Sport)
- **Start**: Optional TextField für Startpunkt
- **Output**: Formatierter Tagesplan mit POIs, Zeiten, Beschreibungen

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
