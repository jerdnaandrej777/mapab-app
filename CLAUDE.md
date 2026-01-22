# CLAUDE.md - MapAB Flutter App

Diese Datei bietet Orientierung für Claude Code bei der Arbeit mit diesem Flutter-Projekt.

## Projektübersicht

Flutter-basierte mobile App für interaktive Routenplanung und POI-Entdeckung in Europa.
Basiert auf dem Konzept der MapAB Web-App (`../Mobi/`).

## Tech Stack

- **Flutter**: 3.38.7+
- **State Management**: Riverpod 2.x mit Code-Generierung
- **Routing**: GoRouter mit Bottom Navigation
- **Karte**: flutter_map mit MapLibre
- **HTTP**: Dio mit Cache
- **Lokale Daten**: Hive (Favoriten, Settings, Account)
- **Cloud-Backend**: Supabase (PostgreSQL + Auth) ⭐ v1.2.6
- **Models**: Freezed für immutable Klassen
- **AI**: OpenAI GPT-4o via Backend-Proxy ⭐ v1.2.6

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
| `lib/data/services/ai_service.dart` | AI via Backend-Proxy (kein API-Key im Client) ⭐ v1.2.6 |
| `lib/core/constants/api_config.dart` | Backend-URL Konfiguration ⭐ v1.2.6 |
| `lib/core/supabase/supabase_config.dart` | Supabase Project URL + Anon Key ⭐ v1.2.6 |
| `lib/core/supabase/supabase_client.dart` | Supabase Client Provider ⭐ v1.2.6 |
| `lib/data/providers/auth_provider.dart` | Auth State Management ⭐ v1.2.6 |
| `lib/data/services/auth_service.dart` | Supabase Auth Service ⭐ v1.2.6 |
| `lib/data/services/sync_service.dart` | Cloud-Sync für Trips/Favoriten ⭐ v1.2.6 |
| `lib/features/auth/login_screen.dart` | Cloud-Login mit Email/Passwort ⭐ v1.2.6 |
| `lib/features/auth/register_screen.dart` | Registrierung ⭐ v1.2.6 |
| `lib/features/auth/forgot_password_screen.dart` | Passwort-Reset ⭐ v1.2.6 |
| `lib/data/repositories/poi_repo.dart` | POI-Laden (3-Schichten: Curated → Wiki → Overpass) |
| `lib/data/services/poi_enrichment_service.dart` | Wikipedia/Wikimedia/Wikidata POI-Anreicherung ⭐ v1.2.5 |
| `lib/data/services/poi_cache_service.dart` | Hive-basiertes POI Caching ⭐ v1.2.5 |
| `lib/features/poi/providers/poi_state_provider.dart` | Zentrales POI State Management ⭐ v1.2.5 |
| `lib/features/map/widgets/map_view.dart` | Karte mit POI-Markern und Route-Polyline ⭐ v1.2.5 |
| `lib/data/repositories/weather_repo.dart` | Open-Meteo Wetter-API |
| `lib/data/services/hotel_service.dart` | Hotel-Suche mit Amenities & Booking.com |
| `lib/core/constants/api_keys.dart` | API-Keys (OpenAI, TomTom, etc.) |
| `assets/data/curated_pois.json` | 527 kuratierte POIs |
| `lib/features/onboarding/onboarding_screen.dart` | Haupt-Onboarding mit PageView ⭐ v1.2.8 |
| `lib/features/onboarding/providers/onboarding_provider.dart` | Hive-basiertes First-Time-Flag ⭐ v1.2.8 |
| `lib/features/onboarding/widgets/animated_route.dart` | CustomPainter Route-Animation ⭐ v1.2.8 |
| `lib/features/onboarding/widgets/animated_ai_circle.dart` | Pulsierende AI-Kreise ⭐ v1.2.8 |
| `lib/features/onboarding/widgets/animated_sync.dart` | Cloud-Sync Animation ⭐ v1.2.8 |
| `lib/features/map/providers/route_session_provider.dart` | Route-Session Management (POIs + Wetter) ⭐ v1.2.9 |
| `lib/features/map/widgets/weather_bar.dart` | WeatherBar mit Warnungen ⭐ v1.2.9 |
| `lib/features/trip/trip_screen.dart` | Trip-Screen mit Google Maps Export & Route Teilen ⭐ v1.3.0 |

## API-Abhängigkeiten

| API | Zweck | Auth |
|-----|-------|------|
| Nominatim | Geocoding | - |
| OSRM | Fast Routing | - |
| OpenRouteService | Scenic Routing | API-Key |
| Overpass | POIs & Hotels | - |
| Wikipedia DE | Geosearch + Extracts | - |
| Wikimedia Commons | POI-Bilder (Geo-Suche) | - |
| Wikidata SPARQL | Strukturierte POI-Daten | - |
| Open-Meteo | Wetter | - |
| OpenAI | AI-Chat | via Backend-Proxy ⭐ v1.2.6 |
| Supabase | Cloud-DB + Auth | Anon Key ⭐ v1.2.6 |
| Backend-Proxy | AI + Rate-Limiting | - ⭐ v1.2.6 |

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

// POI State (v1.2.5 - keepAlive)
final pOIStateNotifierProvider

// POI Enrichment Service (v1.2.5)
final poiEnrichmentServiceProvider

// POI Cache Service (v1.2.5 - keepAlive)
final poiCacheServiceProvider

// Auth State (v1.2.6 - Supabase)
final authNotifierProvider

// Supabase Client (v1.2.6)
final supabaseClientProvider

// Sync Service (v1.2.6)
final syncServiceProvider

// Favoriten Helper Provider (v1.2.7)
final isPOIFavoriteProvider(String poiId)   // Prüft einzelnen POI
final isRouteSavedProvider(String tripId)   // Prüft einzelne Route
final favoritePOIsProvider                  // Liste aller POI-Favoriten
final savedRoutesProvider                   // Liste aller gespeicherten Routen

// Onboarding Provider (v1.2.8)
final onboardingNotifierProvider            // Hive-basiertes First-Time-Flag

// Route Session Provider (v1.2.9) ⭐ NEU
final routeSessionProvider                  // Aktive Route-Session (POIs + Wetter)

// WICHTIG: keepAlive Provider (v1.2.9) ⭐ NEU
// Diese Provider verwenden @Riverpod(keepAlive: true) damit der State
// bei Navigation nicht verloren geht:
// - accountNotifierProvider
// - favoritesNotifierProvider
// - authNotifierProvider
// - settingsNotifierProvider
// - tripStateProvider
// - pOIStateNotifierProvider
// - onboardingNotifierProvider
// - routeSessionProvider
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
- `[Enrichment]` - POI Enrichment Service ⭐ v1.2.5
- `[POICache]` - Cache Operationen ⭐ v1.2.5
- `[POIState]` - State Änderungen ⭐ v1.2.5
- `[POIList]` - POI-Liste Pre-Enrichment ⭐ v1.2.7
- `[Favorites]` - Favoriten-Operationen ⭐ v1.2.7
- `[Sync]` - Cloud-Sync ⭐ v1.2.6
- `[Weather]` - Wetter-Laden
- `[AI]` - AI-Anfragen (inkl. API-Key Präfix)
- `[GPS]` - GPS-Funktionen
- `[Sharing]` - Trip-Sharing & Deep Links ⭐ v1.2.7
- `[Splash]` - Splash-Screen Navigation ⭐ v1.2.9
- `[Account]` - Account-Laden und -Speichern ⭐ v1.2.9
- `[Onboarding]` - Onboarding-Status ⭐ v1.2.8

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
2. **Wikipedia CORS**: Im Web-Modus blockiert (funktioniert auf Android/iOS) ⭐ v1.2.5
3. **Wikimedia Rate-Limit**: Max 200 Anfragen/Minute ⭐ v1.2.5
4. **Overpass API**: Rate-Limiting, kann langsam sein
5. **OpenAI**: Benötigt aktives Guthaben
6. **GPS**: Nur mit HTTPS/Release Build zuverlässig

## Feature-Übersicht (Version 1.3.0)

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

### AI-Trip ohne Ziel (v1.2.4)
- 🎲 **Ziel optional** - AI-Trip-Dialog erlaubt leeres Ziel-Feld
- 📍 **GPS-Fallback** - Ohne Startpunkt wird automatisch GPS-Standort abgefragt
- 🎯 **Interessen-Mapping** - Gewählte Interessen werden zu POI-Kategorien gemappt
- 🚗 **Direkt zu Trip-Screen** - Bei leerem Ziel wird Random Route generiert und angezeigt
- 💬 **Hybrid-Modus** - Mit Ziel: AI-Text-Plan im Chat | Ohne Ziel: Random Route → Trip-Screen

### POI-System Erweiterung (v1.2.5)
- 🖼️ **POI Enrichment** - Wikipedia/Wikimedia/Wikidata Integration für Bilder & Beschreibungen
- 🌍 **POI Highlights** - UNESCO, Must-See, Geheimtipp, Historisch automatisch erkannt
- 📍 **Map-Marker** - POIs auf Karte mit Preview-Sheet bei Tap
- 📋 **Echte POI-Liste** - Live-Daten statt Demo-Einträge
- 💾 **POI Caching** - Hive-basiert mit 7-30 Tage Retention
- 🗂️ **Kategorie-Mapping** - Wikipedia-POIs erhalten passende Kategorien

### Supabase Cloud Integration (v1.2.6)
- ☁️ **Cloud-Sync** - Trips, Favoriten und Achievements in der Cloud gespeichert
- 🔐 **Account-System** - Email/Passwort Registrierung und Login
- 🛡️ **Backend-Proxy** - AI-Features laufen über sicheres Backend (kein API-Key im Client)
- 🔄 **Passwort-Reset** - Email-basiertes Zurücksetzen
- 👤 **Gast-Modus** - Weiterhin offline nutzbar ohne Registrierung
- 📊 **Server-seitige XP-Validierung** - Gamification-Daten serverseitig verifiziert
- 🔒 **Row Level Security** - Jeder User sieht nur eigene Daten

### Favoriten-System & POI-Bilder Fix (v1.2.7)
- ❤️ **POI-Favoriten funktionieren** - Toggle-Button mit dynamischem Icon (war TODO)
- 💾 **Route-Speichern-Button** - Bookmark-Icon im TripScreen mit Benennungs-Dialog
- 🖼️ **POI-Bilder in Liste** - Pre-Enrichment lädt Bilder für Top 20 POIs automatisch
- ☁️ **Cloud-Sync integriert** - Favoriten werden bei Login synchronisiert
- 🔧 **LatLng Serialisierung** - Custom JsonConverters für Freezed-Kompatibilität
- 📷 **CachedNetworkImage** - Effizientes Bilder-Caching in Favoriten-Screen
- 🚀 **Non-blocking Enrichment** - POI-Detail lädt ohne UI-Blockade
- 🌙 **Dark Mode Fixes** - AppTheme.* → colorScheme.* Migration komplett

### Animiertes Onboarding (v1.2.8)
- 🎬 **3 animierte Seiten** - POI-Route, KI-Assistent, Cloud-Sync Vorstellung
- ✨ **Native Flutter Animationen** - AnimationController, CustomPainter, Staggered Animations
- 🎨 **Dunkles Design** - Inspiriert vom Referenzbild mit pulsierenden Kreisen
- 📍 **Page-Indicator** - Animierte Punkte (aktiv = breiter Balken)
- 🔄 **First-Time Detection** - Hive-basiertes Flag für einmalige Anzeige
- 🎯 **Text-Highlights** - Farbige Wörter im Titel (RichText)
- ⏭️ **Überspringen-Option** - Header-Button für erfahrene Nutzer

### Route Starten & Wetter-Warnungen (v1.2.9)
- 🚗 **Route Starten Button** - Erscheint wenn Start + Ziel gewählt, lädt POIs & Wetter
- 🌤️ **WeatherBar** - Wetter-Zusammenfassung mit 5 Messpunkten entlang der Route
- ⚠️ **Wetter-Warnungen** - Unwetter, Regen, Schnee, Sturm mit Empfehlungen
- 🏠 **Indoor-Filter** - Bei schlechtem Wetter Indoor-POIs bevorzugen
- 📍 **Route-Only-Modus** - Nur POIs entlang der Route anzeigen (routeOnlyMode)
- 🔧 **RouteSessionProvider** - Neuer Provider für aktive Routen-Sessions
- 🔧 **FavoritesNotifier keepAlive** - State bleibt erhalten bei Navigation
- 🔧 **AccountNotifier keepAlive** - Gast-Account wird nicht mehr disposed
- ⚡ **Splash-Screen Überarbeitung** - Rekursive Schleife behoben, schneller Start
- 🐛 **Gast-Modus Fix** - "Als Gast fortfahren" funktioniert jetzt korrekt

### Google Maps Export & Route Teilen (v1.3.0) ⭐ NEU
- 🗺️ **Google Maps Export** - Route mit Start, Ziel und Waypoints direkt in Google Maps öffnen
- 📤 **Route Teilen** - Share-Funktion für WhatsApp, Email, SMS etc. mit Google Maps Link
- ⚡ **SnackBar Verbesserung** - "Zur Route hinzugefügt" verschwindet nach 2s automatisch (floating)

## Navigation-Struktur

### Routen (GoRouter)
```dart
/splash             → SplashScreen (Auth + Onboarding Check)
/onboarding         → OnboardingScreen (3 animierte Seiten) ⭐ v1.2.8
/                    → MapScreen (mit AppBar)
/pois               → POIListScreen
/poi/:id            → POIDetailScreen
/trip               → TripScreen
/assistant          → ChatScreen (AI)
/profile            → ProfileScreen
/favorites          → FavoritesScreen
/settings           → SettingsScreen
/search             → SearchScreen
/random-trip        → RandomTripScreen
/login              → LoginScreen (Supabase Auth) ⭐ v1.2.6
/register           → RegisterScreen ⭐ v1.2.6
/forgot-password    → ForgotPasswordScreen ⭐ v1.2.6
/login-local        → Legacy LoginScreen (lokales Profil)
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

---

## POI Enrichment System (v1.2.5) ⭐ NEU

### Architektur

```
┌─────────────────────────────────────────────────────┐
│                    UI Layer                          │
│  POIListScreen │ POIDetailScreen │ MapView (Marker) │
└────────────────────────┬────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────┐
│              POIStateNotifier (Riverpod)             │
│  loadPOIs() │ enrichPOI() │ filterPOIs()            │
└────────────────────────┬────────────────────────────┘
                         │
         ┌───────────────┼───────────────┐
         ▼               ▼               ▼
┌─────────────┐ ┌─────────────────┐ ┌─────────────┐
│ POIRepo     │ │ POIEnrichment   │ │ POICache    │
│ (3-Layer)   │ │ Service         │ │ (Hive)      │
└──────┬──────┘ └────────┬────────┘ └─────────────┘
       │                 │
       ▼                 ▼
┌─────────────────────────────────────────────────────┐
│                  Kostenlose APIs                     │
│ Wikipedia Extracts │ Wikimedia Commons │ Wikidata   │
└─────────────────────────────────────────────────────┘
```

### POI Enrichment Service

```dart
// lib/data/services/poi_enrichment_service.dart
class POIEnrichmentService {
  /// Enrichment-Flow:
  /// 1. Cache prüfen → falls Treffer, gecachten POI zurückgeben
  /// 2. Wikipedia Extracts API → Beschreibung + Hauptbild
  /// 3. Wikimedia Commons API → Geo-basierte Bildsuche (Fallback)
  /// 4. Wikidata SPARQL → UNESCO, Gründungsjahr, Architekturstil
  /// 5. Ergebnis cachen + zurückgeben
  Future<POI> enrichPOI(POI poi) async { ... }
}
```

### API-Endpoints

```dart
// Wikipedia Extracts (Beschreibung + Bild)
GET https://de.wikipedia.org/w/api.php
  ?action=query&titles={title}
  &prop=extracts|pageimages|pageprops
  &exintro=true&explaintext=true

// Wikimedia Commons (Geo-Suche)
GET https://commons.wikimedia.org/w/api.php
  ?action=query&generator=geosearch
  &ggscoord={lat}|{lng}&ggsradius=500
  &prop=imageinfo&iiprop=url

// Wikidata SPARQL (Strukturierte Daten)
GET https://query.wikidata.org/sparql
  ?query={SPARQL}&format=json
```

### POI Highlights

```dart
enum POIHighlight {
  unesco('🌍', 'UNESCO-Welterbe', 0xFF00CED1),
  mustSee('⭐', 'Must-See', 0xFFFFD700),
  secret('💎', 'Geheimtipp', 0xFF9370DB),
  historic('🏛️', 'Historisch', 0xFFA0522D),
  familyFriendly('👨‍👩‍👧‍👦', 'Familienfreundlich', 0xFF4CAF50);
}

// Computed im POI Model:
List<POIHighlight> get highlights {
  final result = <POIHighlight>[];
  if (tags.contains('unesco')) result.add(POIHighlight.unesco);
  if (isMustSee) result.add(POIHighlight.mustSee);
  if (isSecret) result.add(POIHighlight.secret);
  if (isHistoric) result.add(POIHighlight.historic);
  return result;
}
```

### Wikipedia Kategorie-Mapping

```dart
// lib/data/repositories/poi_repo.dart
String _inferCategoryFromTitle(String title) {
  final patterns = <String, List<String>>{
    'castle': ['schloss', 'burg', 'festung', 'castle', 'fortress', 'palast'],
    'church': ['kirche', 'dom', 'kathedrale', 'kloster', 'abtei', 'münster'],
    'museum': ['museum', 'galerie', 'gallery', 'ausstellung'],
    'nature': ['nationalpark', 'naturpark', 'naturschutz', 'biosphäre'],
    'lake': ['see', 'lake', 'teich', 'weiher', 'stausee', 'talsperre'],
    'viewpoint': ['aussicht', 'turm', 'tower', 'view', 'panorama'],
    'monument': ['denkmal', 'memorial', 'monument', 'gedenkstätte'],
  };
  // Match keywords → return category
}
```

### POI State Provider

```dart
// lib/features/poi/providers/poi_state_provider.dart
@Riverpod(keepAlive: true)
class POIStateNotifier extends _$POIStateNotifier {
  // POIs laden
  Future<void> loadPOIsInRadius({required LatLng center, required double radiusKm});
  Future<void> loadPOIsForRoute(AppRoute route);

  // On-Demand Enrichment
  Future<void> enrichPOI(String poiId);

  // Auswahl & Filter
  void selectPOI(POI? poi);
  void setFilter(POICategory? category);
  void setSearchQuery(String query);

  // Gefilterte POIs (für UI)
  List<POI> get filteredPOIs;
}
```

### POI Cache Service

```dart
// lib/data/services/poi_cache_service.dart
class POICacheService {
  static const Duration poiCacheDuration = Duration(days: 7);
  static const Duration enrichmentCacheDuration = Duration(days: 30);

  Future<void> cacheEnrichedPOI(POI poi);
  Future<POI?> getCachedEnrichedPOI(String poiId);
  Future<void> cachePOIs(List<POI> pois, String regionKey);
  Future<List<POI>?> getCachedPOIs(String regionKey);
  Future<void> cleanExpiredCache();
}
```

### Map-Marker Implementierung

```dart
// lib/features/map/widgets/map_view.dart

// POI-Marker Layer
if (poiState.filteredPOIs.isNotEmpty)
  MarkerLayer(
    markers: poiState.filteredPOIs.map((poi) {
      return Marker(
        point: poi.location,
        width: _selectedPOIId == poi.id ? 48 : (poi.isMustSee ? 40 : 32),
        height: _selectedPOIId == poi.id ? 48 : (poi.isMustSee ? 40 : 32),
        child: POIMarker(
          icon: poi.categoryIcon,
          isHighlight: poi.isMustSee,
          isSelected: _selectedPOIId == poi.id,
          onTap: () => _onPOITap(poi),
        ),
      );
    }).toList(),
  ),

// Route-Polyline
if (tripState.hasRoute || routePlanner.route != null)
  PolylineLayer(
    polylines: [
      Polyline(
        points: tripState.route?.coordinates ?? routePlanner.route?.coordinates ?? [],
        color: Theme.of(context).colorScheme.primary,
        strokeWidth: 5,
      ),
    ],
  ),
```

### POI Model Erweiterungen

```dart
// lib/data/models/poi.dart
@freezed
class POI with _$POI {
  const factory POI({
    // ... bestehende Felder ...

    // NEU v1.2.5
    int? foundedYear,           // Gründungsjahr (Wikidata)
    String? architectureStyle,  // Architekturstil (Wikidata)
    @Default(false) bool isEnriched,
    String? thumbnailUrl,
  }) = _POI;

  // Computed Properties
  bool get isHistoric => tags.contains('historic') || tags.contains('unesco');
  bool get isSecret => tags.contains('secret');
  List<POIHighlight> get highlights { ... }
  bool get hasHighlights => highlights.isNotEmpty;
}
```

### Debug-Logging

```
[Enrichment] Starte Enrichment für: Brandenburger Tor
[Enrichment] Wikipedia-Daten geladen: Bild ✓, Beschreibung ✓
[Enrichment] Wikidata-Daten geladen: UNESCO=true
[POICache] POI gecached: Brandenburger Tor
[POICache] Cache-Treffer für: Brandenburger Tor
```

### Bekannte Einschränkungen (v1.2.5)

1. **Wikipedia CORS** - Im Web-Modus blockiert, funktioniert auf Android/iOS
2. **Wikimedia Rate-Limit** - Max 200 Anfragen/Minute
3. **Wikidata SPARQL** - Kann bei komplexen Queries langsam sein
4. **Cache-Größe** - Bei vielen POIs kann Hive-Box groß werden

---

## Supabase Cloud Integration (v1.2.6) ⭐ NEU

### Architektur

```
┌─────────────────────────────────────────────────────┐
│                   Flutter App                        │
│  Login │ Register │ Trips │ Favorites │ AI-Chat     │
└────────────────────────┬────────────────────────────┘
                         │
         ┌───────────────┼───────────────┐
         ▼               ▼               ▼
┌─────────────┐ ┌─────────────────┐ ┌─────────────┐
│ Supabase    │ │ Backend-Proxy   │ │ Lokaler     │
│ (Auth + DB) │ │ (Vercel)        │ │ Storage     │
└──────┬──────┘ └────────┬────────┘ └──────┬──────┘
       │                 │                 │
       ▼                 ▼                 ▼
┌─────────────┐ ┌─────────────────┐ ┌─────────────┐
│ PostgreSQL  │ │ OpenAI API      │ │ Hive        │
│ + RLS       │ │ (Rate-Limited)  │ │ (Offline)   │
└─────────────┘ └─────────────────┘ └─────────────┘
```

### Supabase Konfiguration

```dart
// lib/core/supabase/supabase_config.dart
class SupabaseConfig {
  static const String supabaseUrl = 'https://kcjgnctfjodggpvqwgil.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGci...'; // Öffentlicher Key

  static bool get isConfigured =>
    supabaseUrl.isNotEmpty && !supabaseUrl.contains('your-project');
}
```

### Backend API-Config

```dart
// lib/core/constants/api_config.dart
class ApiConfig {
  static const String backendBaseUrl = 'https://backend-gules-gamma-30.vercel.app';
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 60);

  static const String aiChatEndpoint = '/api/ai/chat';
  static const String aiTripPlanEndpoint = '/api/ai/trip-plan';
}
```

### Auth Provider

```dart
// lib/data/providers/auth_provider.dart
@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  Future<bool> signIn(String email, String password);
  Future<bool> signUp(String email, String password, {String? username});
  Future<void> signOut();
  Future<void> resetPassword(String email);
  void clearError();
}

// Auth State
@freezed
class AppAuthState with _$AppAuthState {
  const factory AppAuthState({
    User? user,
    @Default(false) bool isLoading,
    @Default(false) bool isAuthenticated,
    String? error,
  }) = _AppAuthState;
}
```

### AI Service (Backend-Proxy)

```dart
// lib/data/services/ai_service.dart
class AIService {
  // VORHER: Direkte OpenAI API Calls mit API-Key im Client
  // NACHHER: Alle Calls gehen über Backend-Proxy

  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.backendBaseUrl,  // Backend statt OpenAI
    // Kein Authorization Header mehr nötig!
  ));

  Future<String> chat({...}) async {
    final response = await _dio.post('/api/ai/chat', data: {...});
    return response.data['message'];
  }
}
```

### Datenbank-Schema (Supabase)

```sql
-- Kern-Tabellen
users              -- Erweitert auth.users mit Profil-Daten
trips              -- Gespeicherte Routen
trip_stops         -- POI-Stops pro Trip
favorite_pois      -- Favorisierte POIs
journal_entries    -- Reisetagebuch
user_achievements  -- Achievements & XP
ai_requests        -- Rate-Limiting Tracking

-- Wichtige Funktionen
calculate_level(xp)     -- Level aus XP berechnen
award_xp(user, xp)      -- XP vergeben + Level-Check
complete_trip(trip_id)  -- Trip abschließen + XP
```

### Row Level Security (RLS)

```sql
-- Jeder User sieht nur eigene Daten
CREATE POLICY "Users can view own trips" ON public.trips
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create own trips" ON public.trips
  FOR INSERT WITH CHECK (auth.uid() = user_id);
```

### Login-Screen Features

```dart
// lib/features/auth/login_screen.dart
class LoginScreen extends ConsumerStatefulWidget {
  // Features:
  // - Email/Passwort Login (wenn Supabase konfiguriert)
  // - "Als Gast fortfahren" (immer verfügbar)
  // - "Passwort vergessen?" Link
  // - "Registrieren" Link
  // - Fehler-Anzeige mit Dismiss
}
```

### Gast-Modus vs Cloud-Modus

| Feature | Gast-Modus | Cloud-Modus |
|---------|------------|-------------|
| Trips speichern | Lokal (Hive) | Cloud (Supabase) |
| Favoriten | Lokal | Cloud + Sync |
| Achievements | Lokal | Cloud + Validierung |
| AI-Chat | ✅ Ja | ✅ Ja |
| Geräte-Sync | ❌ Nein | ✅ Ja |
| Offline-Nutzung | ✅ Ja | ⚠️ Eingeschränkt |

### Backend-Endpoints

```
# AI-Proxy (öffentlich, Rate-Limited)
POST /api/ai/chat        - AI-Chat (100 req/Tag)
POST /api/ai/trip-plan   - Trip-Generator (20 req/Tag)
GET  /api/health         - Health-Check

# REST API (Auth erforderlich)
GET/POST   /api/v1/trips
GET/PATCH/DELETE /api/v1/trips/:id
POST       /api/v1/trips/:id/complete
GET/POST   /api/v1/favorites/pois
DELETE     /api/v1/favorites/pois/:id
GET/PATCH  /api/v1/users/me
```

### Debug-Logging (v1.2.6)

```
[Auth] Login erfolgreich: user@example.com
[Auth] Fehler: Invalid login credentials
[AI] Sende Chat-Anfrage an Backend...
[AI] Backend-Antwort erhalten (200)
[Sync] Synchronisiere 5 Trips...
[Sync] Upload erfolgreich
```

### Bekannte Einschränkungen (v1.2.6)

1. **Lokale Daten nicht migriert** - Bestehende Hive-Daten werden nicht automatisch in die Cloud übertragen
2. **Offline-Modus eingeschränkt** - Cloud-Features erfordern Internetverbindung
3. **Rate-Limiting** - AI-Anfragen sind auf 100 Chat / 20 Trip-Pläne pro Tag begrenzt

---

## Favoriten-System (v1.2.7) ⭐ NEU

### LatLng Serialisierung für Freezed

**Problem:** Das `latlong2` Package hat keine JSON-Serialisierung. Routes mit LatLng konnten nicht in Hive gespeichert werden.

**Lösung:** Custom `JsonConverter` für Freezed:

```dart
// lib/data/models/route.dart

/// Konvertiert einzelne LatLng-Objekte
class LatLngConverter implements JsonConverter<LatLng, Map<String, dynamic>> {
  const LatLngConverter();

  @override
  LatLng fromJson(Map<String, dynamic> json) {
    return LatLng(
      (json['lat'] as num).toDouble(),
      (json['lng'] as num).toDouble(),
    );
  }

  @override
  Map<String, dynamic> toJson(LatLng latLng) {
    return {'lat': latLng.latitude, 'lng': latLng.longitude};
  }
}

/// Konvertiert Listen von LatLng (z.B. Route-Koordinaten)
class LatLngListConverter implements JsonConverter<List<LatLng>, List<dynamic>> {
  const LatLngListConverter();

  @override
  List<LatLng> fromJson(List<dynamic> json) {
    return json.map((e) {
      final map = e as Map<String, dynamic>;
      return LatLng(
        (map['lat'] as num).toDouble(),
        (map['lng'] as num).toDouble(),
      );
    }).toList();
  }

  @override
  List<dynamic> toJson(List<LatLng> list) {
    return list.map((latLng) => {
      'lat': latLng.latitude,
      'lng': latLng.longitude,
    }).toList();
  }
}

/// Für nullable LatLng-Felder
class NullableLatLngConverter implements JsonConverter<LatLng?, Map<String, dynamic>?> { ... }
```

**Anwendung in Freezed-Models:**
```dart
@freezed
class AppRoute with _$AppRoute {
  const factory AppRoute({
    @LatLngConverter() required LatLng start,
    @LatLngConverter() required LatLng end,
    @LatLngListConverter() required List<LatLng> coordinates,
    // ...
  }) = _AppRoute;

  factory AppRoute.fromJson(Map<String, dynamic> json) => _$AppRouteFromJson(json);
}
```

### Favoriten-Provider Helper

```dart
// lib/data/providers/favorites_provider.dart

// Prüft ob POI favorisiert ist (reaktiv)
@riverpod
bool isPOIFavorite(IsPOIFavoriteRef ref, String poiId) {
  return ref.watch(favoritesNotifierProvider.notifier).isPOIFavorite(poiId);
}

// Prüft ob Route gespeichert ist (reaktiv)
@riverpod
bool isRouteSaved(IsRouteSavedRef ref, String tripId) {
  return ref.watch(favoritesNotifierProvider.notifier).isRouteSaved(tripId);
}

// Gibt alle favorisierten POIs zurück
@riverpod
List<POI> favoritePOIs(FavoritePOIsRef ref) {
  final favorites = ref.watch(favoritesNotifierProvider);
  return favorites.value?.favoritePOIs ?? [];
}

// Gibt alle gespeicherten Routen zurück
@riverpod
List<Trip> savedRoutes(SavedRoutesRef ref) {
  final favorites = ref.watch(favoritesNotifierProvider);
  return favorites.value?.savedRoutes ?? [];
}
```

### Cloud-Sync Integration

```dart
// Automatische Cloud-Sync in FavoritesNotifier

Future<void> addPOI(POI poi) async {
  // 1. Lokales Speichern in Hive
  final updated = [poi, ...current.favoritePOIs];
  await _favoritesBox.put('favorite_pois', updated.map((p) => p.toJson()).toList());

  // 2. Cloud-Sync (wenn eingeloggt)
  if (isAuthenticated) {
    final syncService = ref.read(syncServiceProvider);
    await syncService.saveFavoritePOI(poi);
  }
}

Future<void> saveRoute(Trip trip) async {
  // 1. Lokales Speichern
  // ...

  // 2. Cloud-Sync
  if (isAuthenticated) {
    await syncService.saveTrip(
      name: trip.name,
      route: trip.route,
      stops: trip.stops,
      isFavorite: true,
    );
  }
}
```

### Pre-Enrichment für POI-Bilder

```dart
// lib/features/poi/poi_list_screen.dart

/// Lädt Bilder für sichtbare POIs im Hintergrund
void _preEnrichVisiblePOIs() {
  final poiNotifier = ref.read(pOIStateNotifierProvider.notifier);
  final poiState = ref.read(pOIStateNotifierProvider);

  // Top 20 POIs ohne Bilder auswählen
  final poisToEnrich = poiState.filteredPOIs
      .where((poi) => !poi.isEnriched && poi.imageUrl == null)
      .take(20)
      .toList();

  // Nicht-blockierend im Hintergrund enrichen
  for (final poi in poisToEnrich) {
    unawaited(poiNotifier.enrichPOI(poi.id));
  }
}
```

### Debug-Logging (v1.2.7)

```
[Favorites] POI favorisiert: Brandenburger Tor
[Favorites] Route gespeichert: Berlin Tagestrip
[Favorites] Cloud-Sync gestartet...
[Sync] Upload erfolgreich
[POIList] Pre-Enrichment für 20 POIs starten
[Enrichment] Nicht-blockierend: Neuschwanstein
```

---

## Animiertes Onboarding-System (v1.2.8) ⭐ NEU

### Konzept

Ein anspruchsvolles Onboarding mit 3 animierten Seiten, die MapAB's Kernfeatures vorstellen:
- **Seite 1:** POI-Entdeckung (animierte Route mit Markern)
- **Seite 2:** KI-Reiseplanung (pulsierende AI-Kreise)
- **Seite 3:** Cloud-Sync (Geräte-Synchronisation)

### Architektur

```
lib/features/onboarding/
├── onboarding_screen.dart              # PageView-Container mit Header, Buttons
├── models/
│   └── onboarding_page_data.dart       # Page-Konfiguration (Titel, Animation)
├── providers/
│   └── onboarding_provider.dart        # Hive First-Time-Flag
└── widgets/
    ├── onboarding_page.dart            # Einzelne Seite Layout
    ├── page_indicator.dart             # Animierte 3-Punkte-Anzeige
    ├── animated_route.dart             # Seite 1: Route-Animation
    ├── animated_ai_circle.dart         # Seite 2: AI-Pulse
    └── animated_sync.dart              # Seite 3: Cloud-Sync
```

### Onboarding Provider

```dart
// lib/features/onboarding/providers/onboarding_provider.dart
@Riverpod(keepAlive: true)
class OnboardingNotifier extends _$OnboardingNotifier {
  static const String _key = 'hasSeenOnboarding';

  @override
  bool build() {
    final box = Hive.box('settings');
    return box.get(_key, defaultValue: false);
  }

  Future<void> completeOnboarding() async {
    final box = Hive.box('settings');
    await box.put(_key, true);
    state = true;
  }

  Future<void> resetOnboarding() async {
    final box = Hive.box('settings');
    await box.put(_key, false);
    state = false;
  }
}
```

### Splash Screen Integration

```dart
// lib/features/account/splash_screen.dart
Future<void> _checkAuthAndNavigate() async {
  await Future.delayed(const Duration(seconds: 2));

  // 0. Prüfe ob Onboarding bereits gesehen wurde
  final hasSeenOnboarding = ref.read(onboardingNotifierProvider);

  if (!hasSeenOnboarding) {
    debugPrint('[Splash] Onboarding nicht gesehen → /onboarding');
    context.go('/onboarding');
    return;
  }

  // 1. Prüfe Cloud-Auth (Supabase)
  // 2. Prüfe lokalen Account
  // ...
}
```

### Animations-Implementierungen

#### AnimatedRoute (Seite 1)

```dart
// CustomPainter für Route mit POI-Markern
class _RoutePainter extends CustomPainter {
  final double pathProgress;      // 0.0 - 1.0
  final double marker1Progress;   // Staggered
  final double marker2Progress;
  final double marker3Progress;
  final double pulseProgress;     // Endlos-Loop

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Route als Bezier-Kurve zeichnen (partiell)
    final pathMetrics = path.computeMetrics().first;
    final extractPath = pathMetrics.extractPath(0, length * pathProgress);
    canvas.drawPath(extractPath, linePaint);

    // 2. POI-Marker mit Bounce-Effekt
    _drawMarker(canvas, poi1, marker1Progress, Icons.castle);
    _drawMarker(canvas, poi2, marker2Progress, Icons.museum);
    _drawMarker(canvas, poi3, marker3Progress, Icons.water);

    // 3. Pulsierende Ringe
    _drawPulseRing(canvas, position, pulseProgress, primaryColor);
  }
}
```

#### AnimatedAICircle (Seite 2)

```dart
// Pulsierende konzentrische Ringe (wie im Referenzbild)
class AnimatedAICircle extends StatefulWidget {
  // 5 AnimationControllers:
  // - _pulse1Controller (2500ms) - Innerer Ring
  // - _pulse2Controller (3000ms) - Mittlerer Ring
  // - _pulse3Controller (3500ms) - Äußerer Ring
  // - _glowController (2000ms, reverse) - Hintergrund-Glow
  // - _iconController (1500ms, reverse) - Smiley "Atmen"
}

// Custom Smiley-Painter
class _SmileyPainter extends CustomPainter {
  void paint(Canvas canvas, Size size) {
    // Lächeln als Bezier-Kurve
    smilePath.quadraticBezierTo(center.dx, center.dy + smileHeight, ...);

    // Augen als Kreise
    canvas.drawCircle(Offset(center.dx - eyeSpacing, eyeY), 3, eyePaint);
    canvas.drawCircle(Offset(center.dx + eyeSpacing, eyeY), 3, eyePaint);
  }
}
```

#### AnimatedSync (Seite 3)

```dart
// Daten-Partikel zwischen Phone und Cloud
class _DataParticlesPainter extends CustomPainter {
  final double progress;

  void paint(Canvas canvas, Size size) {
    // Phone-Position links, Cloud-Position rechts
    final phoneCenter = Offset(size.width * 0.25, size.height * 0.5);
    final cloudCenter = Offset(size.width * 0.75, size.height * 0.5);

    // Partikel entlang der Linie
    for (int i = 0; i < 5; i++) {
      final particleProgress = (progress + i * 0.2) % 1.0;
      final particleX = phoneCenter.dx + (cloudCenter.dx - phoneCenter.dx) * particleProgress;
      canvas.drawCircle(Offset(particleX, particleY), radius, paint);
    }
  }
}
```

### Page Indicator

```dart
// Animierte Punkte (aktiv = breiter Balken)
class PageIndicator extends StatelessWidget {
  final int currentPage;
  final int pageCount;

  Widget build(BuildContext context) {
    return Row(
      children: List.generate(pageCount, (index) {
        final isActive = index == currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: isActive ? 28 : 10,
          height: 10,
          decoration: BoxDecoration(
            color: isActive ? activeColor : inactiveColor.withOpacity(0.5),
            borderRadius: BorderRadius.circular(5),
          ),
        );
      }),
    );
  }
}
```

### App-Flow mit Onboarding

```
┌─────────────────────────────────────────────────────┐
│                    App Start                         │
└──────────────────┬──────────────────────────────────┘
                   │
                   v
┌─────────────────────────────────────────────────────┐
│              SplashScreen (2s)                       │
│   ref.read(onboardingNotifierProvider)              │
└──────────────────┬──────────────────────────────────┘
                   │
         ┌────────┴────────┐
         │                 │
    hasSeenOnboarding   !hasSeenOnboarding
         │                 │
         v                 v
┌─────────────┐   ┌─────────────────────────────────┐
│ Auth-Check  │   │        OnboardingScreen          │
│ → /login    │   │   PageView (3 animierte Seiten) │
│ → /         │   │   "Überspringen" oder "Weiter"  │
└─────────────┘   └──────────────┬──────────────────┘
                                 │
                                 v
                  ┌─────────────────────────────────┐
                  │    completeOnboarding()          │
                  │    Hive: hasSeenOnboarding=true  │
                  │    context.go('/login')          │
                  └─────────────────────────────────┘
```

### Design-Farben

| Element | Wert |
|---------|------|
| Hintergrund | `#0F172A` (immer dunkel) |
| Primary (Route) | `#3B82F6` (Blue) |
| Secondary (AI) | `#06B6D4` (Cyan) |
| Tertiary (Sync) | `#22C55E` (Green) |
| Text | `#FFFFFF` / `#FFFFFF70` |
| Aktiver Dot | `#3B82F6` |
| Inaktiver Dot | `#475569` |

### Test-Anleitung

1. **Erstmaliger Start:**
   - App-Daten löschen / frische Installation
   - App starten
   - ✅ Onboarding erscheint mit Animationen

2. **Seiten-Navigation:**
   - Links/rechts wischen
   - ✅ Seiten wechseln flüssig, Indicator aktualisiert

3. **"Weiter" Buttons:**
   - Auf Seite 1-2: "Weiter" → nächste Seite
   - Auf Seite 3: "Los geht's" → /login

4. **"Überspringen":**
   - Header-Button klicken
   - ✅ Direkt zu /login

5. **Wiederholter Start:**
   - App schließen und neu starten
   - ✅ Kein Onboarding, direkt zu Splash → Auth-Check

### Geänderte Dateien (v1.2.8)

| Datei | Änderung |
|-------|----------|
| `lib/features/onboarding/` (NEU) | Komplettes Onboarding-Feature |
| `lib/app.dart` | `/onboarding` Route hinzugefügt |
| `lib/features/account/splash_screen.dart` | Onboarding-Check vor Auth-Check |

---

## Provider & Splash-Screen Fixes (v1.2.9) ⭐ NEU

### Problem: Gast-Modus und Favoriten funktionierten nicht

**Symptome:**
- "Als Gast fortfahren" führte nicht zur Hauptseite
- POI-Favoriten wurden nicht gespeichert
- Routen-Speichern funktionierte nicht
- App startete sehr langsam nach Logout

**Ursachen:**

1. **AutoDispose Provider**: `AccountNotifier` und `FavoritesNotifier` verwendeten `@riverpod` (AutoDispose). Der State wurde beim Verlassen des Screens gelöscht.

2. **Early-Return bei null State**: Die Favoriten-Methoden hatten `if (state.value == null) return;` - wenn der State noch lädt, passierte nichts.

3. **Rekursive Schleife im Splash-Screen**: Bei `loading` rief sich `_checkAuthAndNavigate()` endlos selbst auf.

### Lösung 1: keepAlive für kritische Provider

```dart
// VORHER - State wird bei Navigation gelöscht
@riverpod
class AccountNotifier extends _$AccountNotifier { ... }

// NACHHER - State bleibt erhalten
@Riverpod(keepAlive: true)
class AccountNotifier extends _$AccountNotifier { ... }
```

**Betroffene Provider:**
- `lib/data/providers/account_provider.dart` → `@Riverpod(keepAlive: true)`
- `lib/data/providers/favorites_provider.dart` → `@Riverpod(keepAlive: true)`

### Lösung 2: _ensureLoaded() für Favoriten

```dart
// lib/data/providers/favorites_provider.dart

/// Wartet bis der State geladen ist und gibt ihn zurück
Future<FavoritesState> _ensureLoaded() async {
  // Wenn bereits geladen, direkt zurückgeben
  if (state.hasValue && state.value != null) {
    return state.value!;
  }

  // Warte auf das Laden
  debugPrint('[Favorites] Warte auf State-Laden...');
  final currentState = await future;
  debugPrint('[Favorites] State geladen: ${currentState.routeCount} Routen, ${currentState.poiCount} POIs');
  return currentState;
}

// Verwendung in allen Mutations-Methoden:
Future<void> saveRoute(Trip trip) async {
  final current = await _ensureLoaded();  // Wartet auf State
  // ... Rest der Logik
}

Future<void> addPOI(POI poi) async {
  final current = await _ensureLoaded();  // Wartet auf State
  // ... Rest der Logik
}
```

### Lösung 3: Splash-Screen Überarbeitung

```dart
// VORHER - Rekursive Schleife!
loading: () {
  Future.delayed(const Duration(milliseconds: 500), () {
    _checkAuthAndNavigate();  // Ruft sich endlos selbst auf
  });
},

// NACHHER - Reaktiv mit ref.watch()
class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _hasNavigated = false;
  bool _initialDelayDone = false;

  @override
  Widget build(BuildContext context) {
    if (!_initialDelayDone) return _buildSplashUI();

    // Reaktiv auf Provider-Änderungen reagieren
    final hasSeenOnboarding = ref.watch(onboardingNotifierProvider);
    final authState = ref.watch(authNotifierProvider);
    final accountAsync = ref.watch(accountNotifierProvider);

    // Navigation mit _hasNavigated Flag (verhindert mehrfache Navigation)
    // ...
  }
}
```

### Geänderte Dateien (v1.2.9)

| Datei | Änderung |
|-------|----------|
| `lib/data/providers/account_provider.dart` | `@Riverpod(keepAlive: true)` |
| `lib/data/providers/favorites_provider.dart` | `@Riverpod(keepAlive: true)` + `_ensureLoaded()` |
| `lib/features/account/splash_screen.dart` | Komplett überarbeitet, reaktiv mit `ref.watch()` |
| `*.g.dart` | Neu generiert (AsyncNotifierProvider statt AutoDisposeAsyncNotifierProvider) |

### Debug-Logging (v1.2.9)

```
[Splash] Navigiere zu: /login
[Splash] Lokaler Account: Gast
[Favorites] Warte auf State-Laden...
[Favorites] State geladen: 0 Routen, 0 POIs
[Favorites] POI favorisiert: Brandenburger Tor
[Favorites] Route gespeichert: Berlin Tagestrip
```

### Riverpod: AutoDispose vs keepAlive

| Aspekt | `@riverpod` (AutoDispose) | `@Riverpod(keepAlive: true)` |
|--------|---------------------------|------------------------------|
| State-Lebensdauer | Bis kein Widget mehr watched | Bis App beendet |
| Memory | Automatisch freigegeben | Bleibt im Speicher |
| Anwendungsfall | Temporäre UI-States | Persistente App-States |
| Beispiele | Form-Input, Suche | Account, Favoriten, Settings |

### Wann keepAlive verwenden?

✅ **Verwende keepAlive für:**
- Account/Auth State
- Favoriten/Gespeicherte Daten
- App-weite Settings
- States die über Navigation hinweg erhalten bleiben sollen

❌ **Verwende AutoDispose für:**
- Screen-spezifische States
- Form-Eingaben
- Temporäre Filter/Suchen
- States die bei Screen-Verlassen zurückgesetzt werden sollen
