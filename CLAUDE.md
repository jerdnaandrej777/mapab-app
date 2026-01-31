# CLAUDE.md - MapAB Flutter App

Diese Datei bietet Orientierung für Claude Code bei der Arbeit mit diesem Flutter-Projekt.

## Projektübersicht

Flutter-basierte mobile App für interaktive Routenplanung und POI-Entdeckung in Europa.
Version: 1.7.22 - UI-Feinschliff | Plattformen: Android, iOS, Desktop

## Tech Stack

| Kategorie | Technologie |
|-----------|-------------|
| Framework | Flutter 3.38.7+ |
| State Management | Riverpod 2.x mit Code-Generierung |
| Routing | GoRouter mit Bottom Navigation |
| Karte | flutter_map mit MapLibre |
| HTTP | Dio mit Cache |
| Lokale Daten | Hive (Favoriten, Settings, Account) |
| Cloud-Backend | Supabase (PostgreSQL + Auth) |
| Models | Freezed für immutable Klassen |
| AI | OpenAI GPT-4o via Backend-Proxy |

## Entwicklung

```bash
# Dependencies installieren
flutter pub get

# Code-Generierung (nach Model-Änderungen)
flutter pub run build_runner build --delete-conflicting-outputs

# Watch-Mode für kontinuierliche Generierung
flutter pub run build_runner watch

# App starten (mit Credentials)
# Siehe: Dokumentation/SECURITY.md für --dart-define

# Release Build - WICHTIG: Immer build_release.bat verwenden!
# NIEMALS nur "flutter build apk --release" - sonst fehlen Supabase-Credentials!
.\build_release.bat

# Oder manuell mit allen Credentials:
flutter build apk --release ^
  --dart-define=SUPABASE_URL=https://... ^
  --dart-define=SUPABASE_ANON_KEY=... ^
  --dart-define=BACKEND_URL=...
```

**ACHTUNG:** Ein APK ohne `--dart-define` Parameter hat keinen funktionierenden Login!
Siehe auch: Hotfix in CHANGELOG-v1.5.9.md

## Architektur

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

Details: [Dokumentation/PROVIDER-GUIDE.md](Dokumentation/PROVIDER-GUIDE.md)

## Wichtige Dateien

### Core

| Datei | Beschreibung |
|-------|--------------|
| `lib/app.dart` | Main App mit GoRouter |
| `lib/main.dart` | Entry Point, Hive Init |
| `lib/core/theme/app_theme.dart` | Theme-Definition |
| `lib/core/constants/api_config.dart` | Backend-URL (--dart-define) |
| `lib/core/constants/trip_constants.dart` | Trip-Konstanten: maxPoisPerDay, kmPerDay (v1.5.7) |
| `lib/core/supabase/supabase_config.dart` | Supabase Credentials (--dart-define) |

### Features

| Datei | Beschreibung |
|-------|--------------|
| `lib/features/map/map_screen.dart` | Hauptscreen mit Karte + Unified Panel Design in beiden Modi (v1.7.22: 12px Abstand Toggle→Panel in beiden Modi, Generating-Indicator Spacing) |
| `lib/features/map/widgets/map_view.dart` | Karten-Widget mit Route + AI Trip Preview + Wetter-Badges auf POI-Markern + Routen-Wetter-Marker (v1.7.12) |
| `lib/features/map/widgets/route_weather_marker.dart` | Wetter-Marker auf Route mit Tap-Detail-Sheet (v1.7.12) |
| `lib/features/poi/poi_list_screen.dart` | POI-Liste mit Filter + Batch-Enrichment + AI-Trip-Stop-Integration (v1.7.8) |
| `lib/features/poi/poi_detail_screen.dart` | POI-Details + AI-Trip-Stop-Integration (v1.7.8) |
| `lib/features/trip/trip_screen.dart` | Route + Stops + Auf Karte anzeigen Button + Route/AI-Trip in Favoriten speichern (v1.7.10) |
| `lib/features/ai_assistant/chat_screen.dart` | AI-Chat mit standortbasierten POI-Vorschlägen + Hintergrund-Enrichment (v1.7.7) + Kategorie-Fix (v1.7.9) |
| `lib/features/account/profile_screen.dart` | Profil mit XP |
| `lib/features/favorites/favorites_screen.dart` | Favoriten mit Auto-Enrichment + Gespeicherte Routen laden (v1.7.10) |
| `lib/features/auth/login_screen.dart` | Cloud-Login mit Remember Me |
| `lib/features/onboarding/onboarding_screen.dart` | Animiertes Onboarding |
| `lib/features/random_trip/random_trip_screen.dart` | AI Trip Generator (Legacy) |
| `lib/features/random_trip/widgets/day_tab_selector.dart` | Tag-Auswahl für mehrtägige Trips (v1.5.7) |
| `lib/features/random_trip/widgets/trip_preview_card.dart` | AI Trip Preview mit POI-Fotos & Navigation (v1.6.9) |
| `lib/features/map/widgets/weather_chip.dart` | Kompakter Wetter-Anzeiger auf MapScreen (v1.7.6) |
| `lib/features/map/widgets/weather_details_sheet.dart` | 7-Tage-Vorhersage Bottom Sheet (v1.7.6) |
| `lib/features/map/widgets/unified_weather_widget.dart` | Intelligentes Wetter-Widget mit Auto-Modus-Wechsel (v1.7.22: startet zugeklappt) |

### Provider

| Datei | Beschreibung |
|-------|--------------|
| `lib/data/providers/account_provider.dart` | Account State (keepAlive) |
| `lib/data/providers/favorites_provider.dart` | Favoriten State (keepAlive) |
| `lib/data/providers/auth_provider.dart` | Auth State (keepAlive) |
| `lib/features/trip/providers/trip_state_provider.dart` | Trip State (keepAlive) + Auto-Routenberechnung (v1.7.2) + setRouteAndStops (v1.7.10) |
| `lib/features/poi/providers/poi_state_provider.dart` | POI State (keepAlive, v1.5.3 Filter-Fix, v1.7.9 2-Stufen-Batch) |
| `lib/features/map/providers/route_planner_provider.dart` | Route-Planner mit Auto-Zoom (v1.7.0) |
| `lib/features/map/providers/map_controller_provider.dart` | MapController + shouldFitToRoute (v1.7.0) |
| `lib/data/providers/settings_provider.dart` | Settings mit Remember Me |
| `lib/features/random_trip/providers/random_trip_provider.dart` | AI Trip State mit Tages-Auswahl + Wetter-Kategorien + markAsConfirmed + weatherCategoriesApplied + resetWeatherCategories (v1.7.9) |
| `lib/features/map/providers/weather_provider.dart` | RouteWeather + LocationWeather + IndoorOnlyFilter (v1.7.6, v1.7.17 keepAlive) |

Details: [Dokumentation/PROVIDER-GUIDE.md](Dokumentation/PROVIDER-GUIDE.md)

### Services

| Datei | Beschreibung |
|-------|--------------|
| `lib/data/services/ai_service.dart` | AI via Backend-Proxy + TripContext mit Standort (v1.7.2) |
| `lib/data/services/poi_enrichment_service.dart` | Wikipedia/Wikidata Enrichment + Batch-API + Image Pre-Cache + Session-Tracking (v1.7.9) |
| `lib/data/services/poi_cache_service.dart` | Hive-basiertes POI Caching |
| `lib/data/services/sync_service.dart` | Cloud-Sync |
| `lib/data/services/active_trip_service.dart` | Persistenz für aktive Trips (v1.5.7) |

### Daten

| Datei | Beschreibung |
|-------|--------------|
| `lib/data/models/poi.dart` | POI Model (Freezed) |
| `lib/data/models/trip.dart` | Trip Model mit Tages-Helper-Methoden (v1.5.7) |
| `lib/data/models/route.dart` | Route Model mit LatLng Converters |
| `lib/data/repositories/poi_repo.dart` | POI-Laden (3-Layer, parallel + Region-Cache) + erweiterte Overpass-Query + Kategorie-Inference (v1.7.9) |
| `lib/data/repositories/trip_generator_repo.dart` | Trip-Generierung mit Radius→Tage Berechnung (v1.5.7) |
| `lib/core/algorithms/day_planner.dart` | Tages-Planung mit 9-POI-Limit (v1.5.7) |
| `assets/data/curated_pois.json` | 527 kuratierte POIs |

## API-Abhängigkeiten

| API | Zweck | Auth |
|-----|-------|------|
| Nominatim | Geocoding | - |
| OSRM | Fast Routing | - |
| OpenRouteService | Scenic Routing | API-Key |
| Overpass | POIs & Hotels | - |
| Wikipedia DE | Geosearch + Extracts | - |
| Wikipedia EN | Fallback-Bilder (v1.7.7) | - |
| Wikimedia Commons | POI-Bilder | - |
| Wikidata SPARQL | Strukturierte POI-Daten | - |
| Open-Meteo | Wetter | - |
| OpenAI | AI-Chat | via Backend-Proxy |
| Supabase | Cloud-DB + Auth | Anon Key |

## Navigation (GoRouter)

```
/splash             → SplashScreen (Auth + Onboarding Check)
/onboarding         → OnboardingScreen (3 animierte Seiten)
/                   → MapScreen (Hauptscreen)
/pois               → POIListScreen
/poi/:id            → POIDetailScreen
/trip               → TripScreen (inkl. AI Trip v1.4.9)
/assistant          → ChatScreen (AI)
/profile            → ProfileScreen
/favorites          → FavoritesScreen
/settings           → SettingsScreen
/search             → SearchScreen
/random-trip        → RandomTripScreen (Legacy, jetzt in /trip integriert)
/login              → LoginScreen (Supabase)
/register           → RegisterScreen
/forgot-password    → ForgotPasswordScreen
```

### Bottom Navigation

1. Karte - MapScreen (Default)
2. POIs - POI-Liste mit Filter
3. Trip - Routenplanung
4. AI - Chat-Assistent

## Konventionen

| Aspekt | Regel |
|--------|-------|
| Sprache | Deutsche UI-Labels, englischer Code |
| IDs | `{land}-{nummer}` (z.B. `de-1`) |
| Dateien | snake_case für Dart-Dateien |
| Klassen | PascalCase |
| Provider | camelCase mit `Provider` Suffix |

### Dark Mode

**WICHTIG:** Keine hart-codierten Farben verwenden!

```dart
// RICHTIG
color: colorScheme.surface
color: colorScheme.onSurface

// FALSCH
color: Colors.white
color: AppTheme.textPrimary
```

Details: [Dokumentation/DARK-MODE.md](Dokumentation/DARK-MODE.md)

## Debugging

### Log-Prefixes

| Prefix | Komponente |
|--------|------------|
| `[POI]` | POI-Laden |
| `[POIList]` | POI-Liste Screen (v1.4.6+) |
| `[Enrichment]` | POI Enrichment Service |
| `[POICache]` | Cache Operationen |
| `[POIState]` | POI State Änderungen |
| `[Favorites]` | Favoriten-Operationen |
| `[Sync]` | Cloud-Sync |
| `[Weather]` | Routen-Wetter-Laden |
| `[LocationWeather]` | Standort-Wetter (v1.7.6) |
| `[AI]` | AI-Anfragen |
| `[GPS]` | GPS-Funktionen |
| `[Auth]` | Auth-Operationen |
| `[Splash]` | Splash-Screen Navigation |
| `[Account]` | Account-Laden |
| `[Onboarding]` | Onboarding-Status |
| `[Settings]` | Settings inkl. Remember Me |
| `[Login]` | Login inkl. Credentials laden |
| `[RoutePlanner]` | Route-Berechnung & POI-Löschung |
| `[RouteSession]` | Route-Session Start/Stop |
| `[RandomTrip]` | AI Trip Generierung |
| `[AI-Chat]` | AI Chat Route-Generierung |
| `[GoogleMaps]` | Google Maps Export & URL-Launch |
| `[DayExport]` | Tagesweiser Google Maps Export (v1.5.7) |
| `[ActiveTrip]` | Active Trip Persistenz (v1.5.7) |
| `[Share]` | Route Teilen |

## Bekannte Einschränkungen

1. **Wikipedia API**: 10km Radius-Limit pro Anfrage
2. **Wikipedia CORS**: Im Web-Modus blockiert (Android/iOS funktioniert)
3. **Wikimedia Rate-Limit**: Max 200 Anfragen/Minute
4. **Overpass API**: Rate-Limiting, kann langsam sein
5. **OpenAI**: Benötigt aktives Guthaben
6. **GPS**: Nur mit HTTPS/Release Build zuverlässig; bei deaktiviertem GPS erscheint Dialog (v1.5.4)
7. **AI-Chat**: Benötigt `--dart-define=BACKEND_URL=...` (sonst Demo-Modus)

## Android-Berechtigungen

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

---

## Dokumentation

### Changelogs

Versionsspezifische Änderungen finden sich in:
- `Dokumentation/CHANGELOG-v1.7.22.md` (UI-Feinschliff - Abstände & Wetter-Widget Default)
- `Dokumentation/CHANGELOG-v1.7.21.md` (Unified Panel Design - Beide Modi scrollbar)
- `Dokumentation/CHANGELOG-v1.2.x.md`
- `Dokumentation/CHANGELOG-v1.3.x.md`
- `Dokumentation/CHANGELOG-v1.3.4.md` (Route Löschen Feature)
- `Dokumentation/CHANGELOG-v1.3.5.md` (AI Trip & Remember Me)
- `Dokumentation/CHANGELOG-v1.3.6.md` (Performance-Optimierungen)
- `Dokumentation/CHANGELOG-v1.3.7.md` (POI-Verbesserungen, Foto-Laden)
- `Dokumentation/CHANGELOG-v1.4.0.md` (Neues Logo, Mehr POIs)
- `Dokumentation/CHANGELOG-v1.4.1.md` (Google Maps Export Fix)
- `Dokumentation/CHANGELOG-v1.4.2.md` (Trip-Stops Bugfix)
- `Dokumentation/CHANGELOG-v1.4.3.md` (Auto-Zoom auf Route)
- `Dokumentation/CHANGELOG-v1.4.4.md` (AI Trip POI-Bearbeitung)
- `Dokumentation/CHANGELOG-v1.4.5.md` (POI-Card Redesign & AI-Chat)
- `Dokumentation/CHANGELOG-v1.4.6.md` (POI-Liste & AI-Chat Bugfixes)
- `Dokumentation/CHANGELOG-v1.4.7.md` (Erweiterter Radius für AI-Trips)
- `Dokumentation/CHANGELOG-v1.4.8.md` (Integrierter Trip-Planer UI)
- `Dokumentation/CHANGELOG-v1.4.9.md` (AI Trip Navigation Fix)
- `Dokumentation/CHANGELOG-v1.5.0.md` (AI Trip direkt auf MapScreen)
- `Dokumentation/CHANGELOG-v1.5.1.md` (POI-Liste Race Condition Bugfix)
- `Dokumentation/CHANGELOG-v1.5.2.md` (POI-Liste Filter & Debug Fix)
- `Dokumentation/CHANGELOG-v1.5.3.md` (POI-Liste & Foto-Fix)
- `Dokumentation/CHANGELOG-v1.5.4.md` (GPS-Dialog statt München-Fallback)
- `Dokumentation/CHANGELOG-v1.5.5.md` (POI-Card Layout-Fix)
- `Dokumentation/CHANGELOG-v1.5.6.md` (Floating Buttons bei AI Trip ausblenden)
- `Dokumentation/CHANGELOG-v1.5.7.md` (Mehrtägige Euro Trips mit tagesweisem Google Maps Export)
- `Dokumentation/CHANGELOG-v1.5.8.md` (Login-Screen Fix: Formular immer sichtbar)
- `Dokumentation/CHANGELOG-v1.5.9.md` (GPS-Teststandort München entfernt)
- `Dokumentation/CHANGELOG-v1.6.0.md` (POI-Fotos Lazy-Loading - Alle Bilder werden jetzt geladen)
- `Dokumentation/CHANGELOG-v1.6.1.md` (POI-Marker Direktnavigation - Details sofort öffnen)
- `Dokumentation/CHANGELOG-v1.6.2.md` (Euro Trip Performance-Fix - Grid-Suche optimiert)
- `Dokumentation/CHANGELOG-v1.6.3.md` (Euro Trip Route-Anzeige Fix - Route erscheint auf Karte)
- `Dokumentation/CHANGELOG-v1.6.4.md` (POI Hinzufügen ohne Snackbar)
- `Dokumentation/CHANGELOG-v1.6.5.md` (TripScreen vereinfacht - nur berechnete Routen)
- `Dokumentation/CHANGELOG-v1.6.6.md` (POI-Foto CORS & Rate-Limit Fix)
- `Dokumentation/CHANGELOG-v1.6.7.md` (POI-Detail Fotos & Highlights Fix)
- `Dokumentation/CHANGELOG-v1.6.8.md` (GPS-Dialog & Löschbutton & POI-Details Fix)
- `Dokumentation/CHANGELOG-v1.6.9.md` (POI-Fotos überall - Favoriten, Trip-Stops, AI Trip Preview)
- `Dokumentation/CHANGELOG-v1.7.0.md` (Auto-Zoom auf Route & Route Starten Button)
- `Dokumentation/CHANGELOG-v1.7.1.md` (Auto-Zoom Verbesserung - MapController-Timing-Fix)
- `Dokumentation/CHANGELOG-v1.7.2.md` (AI-Chat mit standortbasierten POI-Vorschlägen)
- `Dokumentation/CHANGELOG-v1.7.3.md` (POI-Foto Batch-Enrichment - 7x schneller)
- `Dokumentation/CHANGELOG-v1.7.5.md` (Route Löschen Button für AI-Chat Routen)
- `Dokumentation/CHANGELOG-v1.7.4.md` (Auto-Route von GPS-Standort zu POI)
- `Dokumentation/CHANGELOG-v1.7.7.md` (POI-Bildquellen optimiert & Chat-Bilder)
- `Dokumentation/CHANGELOG-v1.7.8.md` (AI Trip Route mit POI-Stops erweitern + POI-Foto & Kategorisierung Optimierung)
- `Dokumentation/CHANGELOG-v1.7.10.md` (Favoriten: Routen speichern & laden)
- `Dokumentation/CHANGELOG-v1.7.12.md` (Wetter-Marker auf der Route)
- `Dokumentation/CHANGELOG-v1.7.14.md` (GPS-Standort-Synchronisation zwischen Modi)
- `Dokumentation/CHANGELOG-v1.7.15.md` (GPS-Button Optimierung)
- `Dokumentation/CHANGELOG-v1.7.16.md` (WeatherBar einklappbar & Dauerhafte Adress-Anzeige)
- `Dokumentation/CHANGELOG-v1.7.17.md` (Persistente Wetter-Widgets)
- `Dokumentation/CHANGELOG-v1.7.18.md` (Snackbar Auto-Dismiss)
- `Dokumentation/CHANGELOG-v1.7.19.md` (GPS Reverse Geocoding & Unified Weather Widget)
- `Dokumentation/CHANGELOG-v1.7.20.md` (Wetter-Widget im AI Trip & Modal-Kategorien)
- `Dokumentation/CHANGELOG-v1.7.21.md` (AI Trip Panel UI-Optimierungen)
- `Dokumentation/CHANGELOG-v1.7.22.md` (UI-Feinschliff - Abstände & Wetter-Widget Default)

---

## Quick Reference

### Trip-Konstanten (v1.5.7+)

```dart
import '../../core/constants/trip_constants.dart';

// Google Maps Waypoint Limit
TripConstants.maxPoisPerDay;  // 9

// Kilometer pro Reisetag
TripConstants.kmPerDay;  // 600.0

// Tage aus Distanz berechnen
final days = TripConstants.calculateDaysFromDistance(1800);  // 3

// Radius aus Tagen berechnen
final radius = TripConstants.calculateRadiusFromDays(3);  // 1800.0
```

### Unified Panel Design (v1.7.21+)

Beide Modi (Schnell & AI Trip) nutzen das gleiche scrollbare Panel-Design:

```dart
// Schnell-Modus Panel
_SchnellModePanel(
  routePlanner: routePlanner,
  routeSession: routeSession,
  randomTripState: randomTripState,
  tripState: tripState,
  isLoadingSchnellGps: _isLoadingSchnellGps,
  onSchnellModeGPS: _handleSchnellModeGPS,
  onStartRoute: () {
    _startRoute(routePlanner.route!);
    context.go('/trip');
  },
)

// AI Trip Panel (analog)
_AITripPanel()
```

**Panel-Struktur:**
```dart
Container(
  decoration: BoxDecoration(surface, borderRadius: 16, shadow),
  child: ConstrainedBox(
    constraints: BoxConstraints(maxHeight: screenHeight * 0.65),
    child: SingleChildScrollView(
      child: Column(
        children: [
          UnifiedWeatherWidget(),  // Nutzt eigenes margin 12h/8v
          Divider(),
          Content(padding: all(12)),
          Divider(),
          Buttons(padding: all(12), width: double.infinity),
        ],
      ),
    ),
  ),
)
```

**Wichtige Konventionen:**
- ✅ Alle Elemente: `padding: EdgeInsets.all(12)`
- ✅ Divider zwischen Sections: `height: 1, opacity: 0.2`
- ✅ Buttons: Volle Breite mit `SizedBox(width: double.infinity)`
- ✅ SearchBar: `showContainer: false` im Panel
- ✅ 12px Abstand zwischen Mode-Toggle und Panel (v1.7.22)
- ✅ Wetter-Widget startet zugeklappt (v1.7.22)

### Wetter-Integration (v1.7.6+)

```dart
import '../providers/weather_provider.dart';

// Standort-Wetter laden (auch ohne Route)
ref.read(locationWeatherNotifierProvider.notifier).loadWeatherForLocation(
  latLng,
  locationName: 'Mein Standort',
);

// Wetter-State abfragen
final weatherState = ref.watch(locationWeatherNotifierProvider);
if (weatherState.hasWeather) {
  final weather = weatherState.weather!;
  print('${weather.formattedTemperature} - ${weather.description}');
}

// Prüfen ob Warnung angezeigt werden soll
if (weatherState.showWarning) {
  // danger oder bad mit hoher Niederschlagswahrscheinlichkeit
}

// Wetter-Details-Sheet öffnen
showWeatherDetailsSheet(
  context,
  weather: weatherState.weather!,
  locationName: 'Mein Standort',
);

// AI Trip: Wetter-basierte Kategorien anwenden
ref.read(randomTripNotifierProvider.notifier)
    .applyWeatherBasedCategories(weatherState.condition);

// AI Trip: Wetter-Kategorien zurücksetzen (v1.7.9 - Toggle)
ref.read(randomTripNotifierProvider.notifier)
    .resetWeatherCategories();

// Prüfen ob Wetter-Kategorien aktiv angewendet sind (v1.7.8)
final isApplied = ref.watch(randomTripNotifierProvider).weatherCategoriesApplied;

// POI-Karten mit Wetter-Badge (POICard Parameter)
POICard(
  weatherCondition: weatherState.condition,  // Optional
  // ...
);

// POI-Marker auf der Karte mit Wetter-Badge (v1.7.9)
POIMarker(
  icon: poi.categoryIcon,
  isHighlight: poi.isMustSee,
  isSelected: false,
  weatherCondition: weatherState.condition,  // Optional - zeigt Mini-Badge
  isIndoorPOI: poi.isIndoor,                // Für Badge-Logik
);
```

**Wetter-Zustände:**

| WeatherCondition | Beschreibung | Empfehlung |
|------------------|--------------|------------|
| `good` | Sonnig, klar | Outdoor-POIs (grün) |
| `mixed` | Wechselhaft, bewölkt | Flexibel planen (gelb) |
| `bad` | Regen, Nebel | Indoor-POIs empfohlen (orange) |
| `danger` | Gewitter, Sturm, Schnee | Nur Indoor! (rot) |
| `unknown` | Keine Daten | - |

**Wetter-Widgets:**

| Widget | Verwendung |
|--------|------------|
| `WeatherChip` | Kompakter Anzeiger auf MapScreen |
| `WeatherAlertBanner` | Proaktive Warnung bei schlechtem Wetter |
| `WeatherRecommendationBanner` | Wetter-Empfehlung auf Hauptseite mit Toggle, opaker Hintergrund (Schnell + AI Trip, v1.7.9) |
| `WeatherDetailsSheet` | 7-Tage-Vorhersage Bottom Sheet |
| `WeatherBadge` | Empfehlungs-Badge auf POI-Karten (Listen) |
| `POIMarker` (weather) | Mini-Wetter-Badge auf POI-Markern auf der Karte (v1.7.9) |
| `WeatherBar` | Routen-Wetter mit 5 Punkten |
| `RouteWeatherMarker` | Wetter-Marker auf Route mit Icon + Temperatur + Tap-Detail (v1.7.12) |

### Persistente Wetter-Widgets (v1.7.17)

**Problem behoben:** Wetter-Widgets verschwanden bei Navigation zwischen Screens.

**Lösung:** `keepAlive: true` für Weather Provider:
```dart
@Riverpod(keepAlive: true)
class RouteWeatherNotifier extends _$RouteWeatherNotifier { ... }

@Riverpod(keepAlive: true)
class LocationWeatherNotifier extends _$LocationWeatherNotifier { ... }
```

**Ergebnis:**
- State bleibt über gesamte App-Session erhalten
- 15-Minuten-Cache funktioniert korrekt
- Keine redundanten API-Calls bei Screen-Wechseln
- Konsistente Widget-Anzeige (~90% weniger API-Calls)

**Cache-Check funktioniert jetzt:**
```dart
// LocationWeatherNotifier.loadWeatherForLocation()
if (state.isCacheValid && state.hasWeather) {
  debugPrint('[LocationWeather] Cache gueltig, ueberspringe');
  return;
}
```

**Betroffene Widgets:**
- WeatherChip (MapScreen, rechts unten)
- WeatherBar (MapScreen, TripScreen)
- WeatherRecommendationBanner (MapScreen, Toggle)
- WeatherAlertBanner (MapScreen, unten)
- RouteWeatherMarker (MapView, auf Route)

### Neuen Provider erstellen

```dart
// Mit keepAlive (für persistente States)
@Riverpod(keepAlive: true)
class MyNotifier extends _$MyNotifier {
  @override
  Future<MyState> build() async { ... }
}

// Ohne keepAlive (für temporäre States)
@riverpod
class MyNotifier extends _$MyNotifier { ... }
```

Dann: `flutter pub run build_runner build`

### POI zu Favoriten hinzufügen

```dart
ref.read(favoritesNotifierProvider.notifier).addPOI(poi);
```

### Route zu Favoriten speichern (v1.7.10)

```dart
// Trip-Objekt erstellen und in Favoriten speichern
final trip = Trip(
  id: const Uuid().v4(),
  name: 'Meine Route',
  type: TripType.daytrip,  // oder TripType.eurotrip
  route: route,             // AppRoute-Objekt
  stops: pois.map((poi) => TripStop.fromPOI(poi)).toList(),
  createdAt: DateTime.now(),
);
await ref.read(favoritesNotifierProvider.notifier).saveRoute(trip);

// Prüfen ob Route bereits gespeichert
final isSaved = ref.read(isRouteSavedProvider(tripId));

// Route aus Favoriten entfernen
await ref.read(favoritesNotifierProvider.notifier).removeRoute(tripId);
```

### Gespeicherte Route laden (v1.7.10)

```dart
// State zurücksetzen
ref.read(routePlannerProvider.notifier).clearRoute();
ref.read(randomTripNotifierProvider.notifier).reset();

// Route und Stops laden OHNE OSRM-Neuberechnung
final stops = trip.stops.map((stop) => stop.toPOI()).toList();
ref.read(tripStateProvider.notifier).setRouteAndStops(trip.route, stops);

// Auto-Zoom auf Karte
ref.read(shouldFitToRouteProvider.notifier).state = true;
context.go('/');
```

### Route berechnen

```dart
final routePlanner = ref.read(routePlannerProvider.notifier);
routePlanner.setStart(latLng, 'Adresse');
routePlanner.setEnd(latLng, 'Adresse');
// Route wird automatisch berechnet wenn beide gesetzt
```

### Stops hinzufügen/entfernen mit Auto-Neuberechnung (v1.7.4+)

```dart
// Stop hinzufügen MIT Auto-Route (v1.7.4)
// Wenn keine Route existiert: GPS → POI Route wird automatisch erstellt
final result = await ref.read(tripStateProvider.notifier).addStopWithAutoRoute(poi);

if (result.success) {
  if (result.routeCreated) {
    // Neue Route wurde erstellt (GPS → POI)
    context.go('/trip');
  }
  // Sonst: Stop wurde zu bestehender Route hinzugefügt
} else if (result.isGpsDisabled) {
  // GPS-Dialog anzeigen
}

// Stop zu AI Trip hinzufügen (v1.7.8)
// Wenn ein AI Trip aktiv ist (Preview oder Confirmed), wird die AI-Route übernommen
final randomTripState = ref.read(randomTripNotifierProvider);
if (randomTripState.generatedTrip != null &&
    (randomTripState.step == RandomTripStep.preview ||
     randomTripState.step == RandomTripStep.confirmed)) {
  final result = await ref.read(tripStateProvider.notifier).addStopWithAutoRoute(
    poi,
    existingAIRoute: randomTripState.generatedTrip!.trip.route,
    existingAIStops: randomTripState.generatedTrip!.selectedPOIs,
  );
  if (result.success) {
    ref.read(randomTripNotifierProvider.notifier).markAsConfirmed();
  }
}

// Stop hinzufügen OHNE Auto-Route (klassisch)
ref.read(tripStateProvider.notifier).addStop(poi);

// Stop entfernen - Route wird automatisch neu berechnet
ref.read(tripStateProvider.notifier).removeStop(poiId);

// Stops neu ordnen - Route wird automatisch neu berechnet
ref.read(tripStateProvider.notifier).reorderStops(oldIndex, newIndex);

// Prüfen ob Route gerade neu berechnet wird
final isRecalculating = ref.watch(tripStateProvider).isRecalculating;

// WICHTIG: Bei Stop-Änderungen wird OSRM mit Waypoints aufgerufen
// → Echte Distanz (km) und Fahrzeit werden aktualisiert
```

### Route löschen (v1.3.4+)

```dart
// Einzeln löschen (Start oder Ziel)
ref.read(routePlannerProvider.notifier).clearStart();
ref.read(routePlannerProvider.notifier).clearEnd();

// Komplett löschen (Start + Ziel + Route + Trip-State + POIs)
ref.read(routePlannerProvider.notifier).clearRoute();
```

### POIs löschen (v1.3.5+)

```dart
// Alle POIs manuell löschen
ref.read(pOIStateNotifierProvider.notifier).clearPOIs();

// Route-Session stoppen (löscht auch POIs und Wetter)
ref.read(routeSessionProvider.notifier).stopRoute();

// HINWEIS: POIs und Trip-Stops werden automatisch gelöscht bei:
// - Neuer Route-Berechnung (routePlannerProvider._tryCalculateRoute) - v1.4.2+
// - Route löschen (routePlannerProvider.clearRoute)
// - AI Trip bestätigen (randomTripProvider.confirmTrip)
// - AI Chat Route generieren (ChatScreen._generateRandomTripFromLocation)
```

### POI enrichen

```dart
// Einzelner POI
ref.read(pOIStateNotifierProvider.notifier).enrichPOI(poiId);

// Batch-Enrichment für mehrere POIs (v1.7.3 - 7x schneller, v1.7.9 - 2-Stufen-UI)
// Fotos erscheinen inkrementell: Cache → Wikipedia → Wikimedia Fallback
ref.read(pOIStateNotifierProvider.notifier).enrichPOIsBatch(poisList);

// WICHTIG v1.7.9: POIs ohne Foto werden NICHT mehr als isEnriched markiert
// → Retry bei nächster Session möglich
// → Session-Set (_sessionAttemptedWithoutPhoto) verhindert Endlosschleifen
```

### POI zum State hinzufügen (v1.6.9+)

```dart
// POI manuell zum State hinzufügen (für POI-Details-Navigation)
ref.read(pOIStateNotifierProvider.notifier).addPOI(poi);

// Typischer Anwendungsfall: Vor Navigation zu POI-Details
ref.read(pOIStateNotifierProvider.notifier).addPOI(poi);
if (poi.imageUrl == null) {
  ref.read(pOIStateNotifierProvider.notifier).enrichPOI(poi.id);
}
context.push('/poi/${poi.id}');

// HINWEIS: addPOI() wird automatisch aufgerufen bei:
// - Favoriten-Screen: POI-Card Klick
// - TripScreen: Stop-Tile Klick
// - TripPreviewCard: Stop-Item Klick
// - RandomTripProvider: Nach Trip-Generierung (_enrichGeneratedPOIs)
```

### RouteOnlyMode (v1.4.6+)

```dart
// RouteOnlyMode aktivieren (nur POIs mit routePosition anzeigen)
ref.read(pOIStateNotifierProvider.notifier).setRouteOnlyMode(true);

// RouteOnlyMode deaktivieren (alle POIs anzeigen)
ref.read(pOIStateNotifierProvider.notifier).setRouteOnlyMode(false);

// WICHTIG: Wird automatisch aktiviert bei RouteSession.startRoute()
// WICHTIG: Wird automatisch deaktiviert bei:
// - RouteSession.stopRoute()
// - POIListScreen._loadPOIs() wenn keine Route vorhanden (v1.4.6+)
```

### Cloud-Sync Status prüfen

```dart
final authState = ref.watch(authNotifierProvider);
if (authState.isAuthenticated) {
  // User ist eingeloggt, Cloud-Sync aktiv
}
```

### Remember Me - Credentials speichern (v1.3.5+)

```dart
// Credentials speichern nach erfolgreichem Login
final settingsNotifier = ref.read(settingsNotifierProvider.notifier);
await settingsNotifier.saveCredentials(email, password);

// Credentials löschen
await settingsNotifier.clearCredentials();

// Prüfen ob Credentials gespeichert sind
final settings = ref.read(settingsNotifierProvider);
if (settings.hasStoredCredentials) {
  final email = settings.savedEmail;
  final password = settings.savedPassword; // Automatisch dekodiert
}
```

### AI Trip starten (v1.5.0+)

```dart
// AI Trip ist jetzt direkt im MapScreen integriert (v1.5.0)
// Einfach auf "AI Trip" Toggle klicken - Karte bleibt sichtbar

// MapScreen Modus-Enum:
enum MapPlanMode { schnell, aiTrip }

// Der Modus wird lokal im MapScreen State verwaltet:
// - schnell: Zeigt Start/Ziel Suchleiste
// - aiTrip: Zeigt AI Trip Panel über der Karte

// Nach Trip-Generierung:
// - Route wird auf Karte angezeigt
// - Panel wird ausgeblendet (wechselt zu "Schnell")
// - POIs erscheinen als nummerierte Marker

// Alternativ: TripScreen für erweiterte Optionen
context.push('/trip');
context.push('/trip?mode=ai');
```

### AI Trip Panel auf MapScreen (v1.5.0+)

Das AI Trip Panel enthält folgende Elemente:
- **Modus-Auswahl**: Tagestrip / Euro Trip Buttons
- **Startpunkt**: Adress-Eingabe mit Autocomplete + GPS-Button
- **Radius-Slider**: Mit Quick-Select Buttons
- **Kategorien**: Aufklappbare Kategorie-Auswahl
- **Generate Button**: "Überrasch mich!"

```dart
// MapView zeigt AI Trip Preview:
// - Route-Polyline
// - POIs als _AITripStopMarker (mit Nummer + Icon)
// - Start-Marker

// Nach Generierung: Auto-Zoom auf Route
ref.listenManual(randomTripNotifierProvider, (previous, next) {
  if (next.step == RandomTripStep.preview) {
    _fitMapToRoute(next.generatedTrip?.trip.route);
  }
});
```

### AI Trip Radius-Einstellungen (v1.5.7+)

| Modus | Min | Max | Default |
|-------|-----|-----|---------|
| Tagesausflug | 30 km | 300 km | 100 km |
| Euro Trip | 100 km | 5000 km | 1000 km |

**Euro Trip Tagesberechnung:**
- Formel: `Tage = ceil(Radius / 600km)`
- Beispiel: 1800km = 3 Tage
- Max 9 POIs pro Tag (Google Maps Limit)

**Quick-Select Buttons:**
- Tagesausflug: 50, 100, 200, 300 km
- Euro Trip: 1 Tag (600km), 2 Tage (1200km), 4 Tage (2400km), 7 Tage (4200km)

### Mehrtägiger Euro Trip Export (v1.5.7+)

```dart
// Tag auswählen (für tagesweisen Export)
ref.read(randomTripNotifierProvider.notifier).selectDay(2);

// Tag in Google Maps exportieren
// Start: Tag 1 = Trip-Start, ab Tag 2 = letzter Stop vom Vortag
// Waypoints: Alle Stops des Tages (max 9)
// Ziel: Letzter Tag = Trip-Start, sonst erster Stop vom Folgetag

// Tag als exportiert markieren
ref.read(randomTripNotifierProvider.notifier).completeDay(2);

// Prüfen ob Tag exportiert wurde
final state = ref.read(randomTripNotifierProvider);
final isCompleted = state.isDayCompleted(2);
```

### AI Trip POIs bearbeiten (v1.4.4+)

```dart
final notifier = ref.read(randomTripNotifierProvider.notifier);

// Einzelnen POI aus dem Trip entfernen (min. 2 müssen bleiben)
notifier.removePOI(poiId);

// Einzelnen POI neu würfeln (nur dieser POI wird ersetzt)
notifier.rerollPOI(poiId);

// Prüfen ob POIs entfernt werden können (> 2 vorhanden)
final canRemove = ref.read(randomTripNotifierProvider).canRemovePOI;

// Prüfen ob ein bestimmter POI gerade geladen wird
final isLoading = ref.read(randomTripNotifierProvider).isPOILoading(poiId);
```

**Features:**
- **POI löschen**: Entferne ungewünschte POIs vor dem Speichern
- **POI neu würfeln**: Ersetze nur einen einzelnen POI (nicht den ganzen Trip)
- **Minimum-Prüfung**: Mindestens 2 POIs müssen im Trip bleiben
- **Per-POI Loading**: Individuelle Loading-Anzeige pro POI
- **Auto-Routenberechnung**: Route wird nach jeder Änderung automatisch neu berechnet

### POI-Laden mit Cache (v1.3.6+)

```dart
// POIs werden automatisch gecached nach Region
// Bei erneutem Besuch: Sofortiges Laden aus Cache

// Cache manuell leeren (bei Bedarf)
final cacheService = ref.read(poiCacheServiceProvider);
await cacheService.clearAll();

// Cache-Statistiken abrufen
final stats = await cacheService.getStats();
debugPrint('Regions: ${stats['regions']}, Enriched: ${stats['enrichedPOIs']}');
```

### Performance-Hinweise (v1.3.6+)

- **POI-Laden**: 3 Quellen werden parallel geladen (50-70% schneller)
- **Region-Cache**: 7 Tage gültig, sofortiges Laden bei erneutem Besuch
- **Enrichment-Cache**: 30 Tage gültig für Bilder/Beschreibungen
- **Batch-Enrichment**: Wikipedia Multi-Title-Query für bis zu 50 POIs (v1.7.3)
- **ListView**: `cacheExtent: 500` für flüssigeres Scrollen

### POI-Foto-Optimierungen (v1.3.7+, v1.6.6, v1.7.3, v1.7.7, v1.7.9)

```dart
// Prüfen ob POI gerade enriched wird (Per-POI Loading State)
final isLoading = ref.read(pOIStateNotifierProvider).isPOIEnriching(poiId);

// Enrichment Service Konfiguration (v1.6.6)
POIEnrichmentService._maxConcurrentEnrichments = 3;  // Max 3 parallel (reduziert von 5)
POIEnrichmentService._enrichmentTimeout = 25000;     // 25 Sekunden
POIEnrichmentService._maxRetries = 3;                // 3 Versuche bei Fehler
POIEnrichmentService._apiCallDelay = 200;            // 200ms zwischen API-Calls
```

**Architektur-Verbesserungen:**
- **Parallele API-Calls**: Wikipedia + Wikimedia gleichzeitig (statt sequenziell)
- **Retry-Logik**: 3 Versuche mit Exponential Backoff (500ms → 1s → 1.5s)
- **Concurrency-Limits**: Max 3 gleichzeitige Enrichments (v1.6.6: reduziert für Rate-Limit-Schutz)
- **Per-POI Loading State**: `enrichingPOIIds` Set im POIState
- **Doppel-Enrichment-Schutz**: Prüfung vor jedem Enrichment-Start
- **Rate-Limit-Handling**: HTTP 429 wird erkannt und 5 Sekunden gewartet (v1.6.6)
- **API-Call-Delays**: 200ms Pause zwischen Wikimedia-Calls (v1.6.6)
- **OSM-Tags**: Overpass `image`, `wikimedia_commons`, `wikidata`, `wikipedia` Tags werden extrahiert (v1.7.7)
- **EN-Wikipedia Fallback**: Englische Wikipedia als Fallback wenn DE kein Bild liefert (v1.7.7)
- **Suchvarianten**: Umlaute normalisieren + Präfix-Wörter entfernen für bessere Wikimedia-Treffer (v1.7.7)
- **Batch-Fix**: Wikipedia-POIs ohne Bild bekommen Wikimedia Geo-Suche Fallback (v1.7.7)
- **Batch-Limit 5→15**: Wikimedia-Fallback jetzt für bis zu 15 POIs statt nur 5 (v1.7.9)
- **Sub-Batching**: 5er-Gruppen mit 500ms Pause zwischen Batches für Rate-Limit-Schutz (v1.7.9)
- **isEnriched-Fix**: POIs ohne Foto werden NICHT mehr als "enriched" markiert, Session-Set verhindert Endlosschleifen (v1.7.9)
- **2-Stufen-UI-Update**: Cache/Wikipedia-Treffer sofort anzeigen, Wikimedia-Fallbacks inkrementell nachliefern (v1.7.9)
- **Image Pre-Caching**: Bild-URLs werden nach Enrichment im Disk-Cache vorgeladen für sofortige Anzeige (v1.7.9)
- **OSM-URL-Validierung**: `image`-Tags aus Overpass werden auf gültige HTTP-URLs geprüft (v1.7.9)

**Bildquellen (in Prioritäts-Reihenfolge):**
1. OSM-Tags aus Overpass: `image`, `wikimedia_commons` Tags (v1.7.7, v1.7.9: URL-Validierung)
2. Wikipedia DE API (pageimages) - Hauptbild + Thumbnail
3. Wikimedia Commons Geo-Suche (10km Radius, 15 Ergebnisse) (v1.7.7: 10km statt 5km)
4. Wikimedia Commons Titel-Suche (mit Suchvarianten: Umlaute, Präfixe) (v1.7.7)
5. Wikimedia Commons Kategorie-Suche
6. Wikipedia EN API (Fallback nur für Bild) (v1.7.7)
7. Wikidata SPARQL (P18 Bild, P154 Logo, P94 Wappen)

**Performance-Vergleich:**
| Metrik | v1.3.6 | v1.3.7 | v1.7.3 | v1.7.7 | v1.7.9 |
|--------|--------|--------|--------|--------|--------|
| Zeit für 20 POIs | 60+ Sek | 21+ Sek | ~3 Sek | ~3 Sek | ~2 Sek |
| API-Calls für 20 POIs | ~160 | ~80 | ~4 | ~4-8 | ~4-8 |
| Bild-Trefferquote | ~60% | ~85% | ~85% | ~95% | ~98% |
| Fallback-Coverage | 5 POIs | 5 POIs | 5 POIs | 5 POIs | 15 POIs |

### POI Enrichment Race Condition Fix (v1.5.1)

**Problem:** POIs wurden geladen, kurz angezeigt und verschwanden dann - nur 1 POI blieb sichtbar.

**Ursache:** Beim parallelen Enrichment (8 POIs gleichzeitig) überschrieben sich die State-Updates gegenseitig:

```dart
// VORHER (fehlerhaft):
final updatedPOIs = List<POI>.from(state.pois);  // Snapshot zum Zeitpunkt X
// ... async await (andere Enrichments können hier state ändern)
state = state.copyWith(pois: updatedPOIs);  // Überschreibt ALLE Änderungen seit X
```

**Lösung:** Atomare State-Updates mit `_updatePOIInState()`:

```dart
// NACHHER (korrekt):
void _updatePOIInState(String poiId, POI updatedPOI) {
  // Liest den AKTUELLEN State (nicht eine alte Kopie)
  final currentPOIs = state.pois;
  final currentIndex = currentPOIs.indexWhere((p) => p.id == poiId);

  if (currentIndex == -1) return;

  final updatedPOIs = List<POI>.from(currentPOIs);
  updatedPOIs[currentIndex] = updatedPOI;

  state = state.copyWith(pois: updatedPOIs, ...);
}
```

**WICHTIG für zukünftige Entwicklung:**
- Bei asynchronen Operationen IMMER den aktuellen State zum Zeitpunkt des Updates lesen
- Keine alten State-Kopien nach `await` weiterverwenden
- Parallel laufende State-Updates müssen atomar sein

### POI-Liste Filter-Fix (v1.5.3)

**Problem:** POI-Liste zeigte oft nur 1 POI, obwohl mehr geladen wurden.

**Ursache:** Der `detourKm`-Filter wurde IMMER angewendet, nicht nur im Route-Modus:

```dart
// VORHER (fehlerhaft):
// Dieser Filter war IMMER aktiv, auch ohne Route!
result = result
    .where((poi) =>
        poi.detourKm == null || poi.detourKm! <= maxDetourKm)
    .toList();
```

**Lösung:** Filter nur bei aktivem `routeOnlyMode` anwenden:

```dart
// NACHHER (korrekt):
// Umweg-Filter NUR wenn routeOnlyMode aktiv
if (routeOnlyMode) {
  result = result
      .where((poi) =>
          poi.detourKm == null || poi.detourKm! <= maxDetourKm)
      .toList();
}
```

**Zusätzliche Änderungen:**
- Default `maxDetourKm` von 45 auf **100 km** erhöht
- Debug-Logging für alle Filter-Schritte hinzugefügt

### POI Enrichment Cache-Fix (v1.5.3)

**Problem:** POI-Fotos wurden oft nicht geladen, ohne ersichtlichen Grund.

**Ursache:** POIs mit Beschreibung aber **ohne Bild** wurden gecacht → Bild wurde nie erneut gesucht (30 Tage Cache!)

```dart
// VORHER (fehlerhaft):
if (cacheService != null && !enrichment.isEmpty) {  // isEmpty = !hasImage && !hasDescription
  await cacheService.cacheEnrichedPOI(enrichedPOI);  // Cached auch POIs ohne Bild!
}
```

**Lösung:** Nur POIs mit Bild cachen:

```dart
// NACHHER (korrekt):
if (cacheService != null && enrichment.hasImage) {  // NUR wenn Bild vorhanden
  await cacheService.cacheEnrichedPOI(enrichedPOI);
}
```

**Zusätzliche Änderungen:**
- `resetStaticState()` Methode hinzugefügt (wird bei Provider-Init aufgerufen)
- Failure-Logs: `[Enrichment] ⚠️ Kein Wikimedia-Bild gefunden für: ...`

### GPS-Button Verhalten (v1.5.4)

**Vorher:** Bei deaktivierten GPS wurde München (48.1351, 11.5820) als Test-Standort verwendet.

**Nachher:** Dialog fragt ob GPS-Einstellungen geöffnet werden sollen.

```dart
// GPS-Button auf MapScreen: _centerOnLocation()
// 1. Prüft ob Location Services aktiviert sind
// 2. Bei deaktiviert: Zeigt Dialog mit Frage
// 3. "Einstellungen öffnen" → Geolocator.openLocationSettings()
// 4. "Nein" → Abbrechen (kein Fallback)

// Implementierung des Dialogs:
Future<bool> _showGpsDialog() async {
  return await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('GPS deaktiviert'),
      content: const Text(
        'Die Ortungsdienste sind deaktiviert. Möchtest du die GPS-Einstellungen öffnen?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Nein'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Einstellungen öffnen'),
        ),
      ],
    ),
  ) ?? false;
}
```

**Konsistenz:** Das Verhalten ist jetzt konsistent mit `RandomTripProvider`, der bereits Fehlermeldungen statt Fallback-Standorte verwendet.

### GPS-Dialog bei AI Trip (v1.6.8)

**Problem:** Bei "Überrasch mich!" ohne GPS wurde nur eine Fehlermeldung angezeigt, kein Dialog.

**Lösung:** Neue Helper-Methoden in `_AITripPanelState`:

```dart
// GPS-Button und "Überrasch mich!" Button nutzen jetzt:
Future<bool> _checkGPSAndShowDialog() async {
  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Dialog anzeigen mit Option "Einstellungen öffnen"
    return false;
  }
  return true;
}

Future<void> _handleGenerateTrip() async {
  // Wenn kein Startpunkt gesetzt, GPS-Dialog anzeigen
  if (!state.hasValidStart) {
    final gpsAvailable = await _checkGPSAndShowDialog();
    if (!gpsAvailable) return;
    await notifier.useCurrentLocation();
  }
  notifier.generateTrip();
}
```

**Ergebnis:** Bei deaktiviertem GPS erscheint jetzt auch bei "Überrasch mich!" ein Dialog.

### GPS-Button im Schnell-Modus (v1.6.8)

**Problem:** Im Schnell-Modus gab es keinen GPS-Button zum Setzen des aktuellen Standorts als Startpunkt.

**Lösung:** GPS-Button zur `_SearchBar` hinzugefügt:

```dart
// _SearchBar erweitert mit GPS-Button Parameter:
_SearchBar(
  startAddress: routePlanner.startAddress,
  // ... andere Parameter
  onGpsTap: _handleSchnellModeGPS,
  isLoadingGps: _isLoadingSchnellGps,
),

// Handler-Methode:
Future<void> _handleSchnellModeGPS() async {
  // GPS-Status prüfen, Dialog wenn deaktiviert
  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    final shouldOpen = await _showGpsDialog();
    if (shouldOpen) await Geolocator.openLocationSettings();
    return;
  }
  // Position abrufen und als Startpunkt setzen
  final position = await Geolocator.getCurrentPosition(...);
  ref.read(routePlannerProvider.notifier).setStart(latLng, 'Mein Standort');
}
```

**Ergebnis:** GPS-Button erscheint neben dem Startpunkt-Feld im Schnell-Modus. Bei Klick wird der aktuelle Standort als Startpunkt gesetzt (mit GPS-Dialog wenn deaktiviert).

### POI-Card Layout-Fix (v1.5.5)

**Problem:** POI-Liste zeigte "15 von 22 POIs" an, aber nur 1 POI war sichtbar.

**Ursache:** `IntrinsicHeight` + `height: double.infinity` im Bild verursachte Layout-Fehler.

**Lösung:** Feste Card-Höhe (96px) statt dynamischer Berechnung.

```dart
// VORHER - Problematisch
child: IntrinsicHeight(
  child: Row(
    children: [
      CachedNetworkImage(
        height: double.infinity,  // <- Keine intrinsische Höhe!
      ),
    ],
  ),
)

// NACHHER - Feste Höhe
static const double _minCardHeight = 96.0;

child: SizedBox(
  height: _minCardHeight,
  child: Row(
    children: [
      CachedNetworkImage(
        height: _minCardHeight,  // <- Feste Höhe
      ),
    ],
  ),
)
```

**WICHTIG für zukünftige Entwicklung:**
- Niemals `IntrinsicHeight` mit `double.infinity` kombinieren
- Widgets innerhalb von `IntrinsicHeight` müssen eine intrinsische Höhe haben
- Feste Höhen sind performanter als dynamische Layout-Berechnungen

### POI-Foto CORS & Rate-Limit Fix (v1.6.6)

**Problem:** POI-Fotos wurden nicht angezeigt.

**Ursachen & Fixes:**

1. **Wikidata SPARQL ohne `origin: '*'` Header**
   - Wikidata-Fallback-Bilder konnten nicht geladen werden
   - Fix: `origin: '*'` Parameter und `Origin`-Header hinzugefügt

2. **Rate-Limiting ohne Handling**
   - Bei vielen POIs: Silent Failures durch Wikimedia Rate-Limit (200 Req/Min)
   - Fix: HTTP 429 wird erkannt und 5 Sekunden gewartet

3. **Zu hohe Concurrency**
   - 5 parallele Enrichments × 3 API-Calls = 15 gleichzeitige Requests
   - Fix: Concurrency von 5 auf 3 reduziert

4. **Fehlende Delays zwischen API-Calls**
   - Burst-Anfragen triggerten Rate-Limiting
   - Fix: 200ms Delay zwischen Wikimedia Titel-/Kategorie-Suche

```dart
// VORHER (fehlerhaft) - Wikidata ohne CORS:
options: Options(
  headers: {'Accept': 'application/sparql-results+json'},
),

// NACHHER (korrekt):
{
  'query': query,
  'format': 'json',
  'origin': '*',  // NEU
},
options: Options(
  headers: {
    'Accept': 'application/sparql-results+json',
    'Origin': 'https://mapab.app',  // NEU
  },
),
```

**Erweitertes Error-Logging:**
- `[Enrichment] ⚠️ Rate-Limit (429) erreicht!`
- `[Enrichment] ⏱️ Timeout bei Versuch X`
- `[Enrichment] ❌ API-Fehler: Status=X, Typ=Y, URL=Z`

### POI-Detail Fotos & Highlights Fix (v1.6.7)

**Problem:** Nach Routenberechnung wurden beim Klick auf POIs keine Fotos und Highlights angezeigt.

**Ursachen & Fixes:**

1. **Asynchrones Enrichment ohne Warten**
   - `unawaited(enrichPOI())` → UI renderte mit ungereichertem POI
   - Fix: `await enrichPOI()` - blockierendes Warten auf Enrichment

2. **Redundantes Selektieren**
   - POI-Liste rief `selectPOI(poi)` auf, dann nochmal im Detail-Screen
   - Fix: `selectPOI()` in POI-Liste entfernt

```dart
// VORHER (fehlerhaft) - poi_detail_screen.dart:
unawaited(notifier.enrichPOI(widget.poiId));  // Fire-and-forget!

// NACHHER (korrekt):
await notifier.enrichPOI(widget.poiId);  // Blockierend warten
```

```dart
// VORHER (redundant) - poi_list_screen.dart:
onTap: () {
  ref.read(pOIStateNotifierProvider.notifier).selectPOI(poi);
  context.push('/poi/${poi.id}');
},

// NACHHER (vereinfacht):
onTap: () {
  context.push('/poi/${poi.id}');  // selectPOI wird im Detail-Screen aufgerufen
},
```

**Ergebnis:**
- Loading-Indikator "Lade Details..." wird korrekt angezeigt
- Nach dem Laden sind Foto und Highlights sofort sichtbar
- Keine Race Conditions mehr

### POI-Details unter "Deine Route" (v1.6.8)

**Problem:** Beim Klick auf einen Stop unter "Deine Route" wurden keine POI-Details angezeigt.

**Ursache:** Der POI aus dem TripState war nicht im POIState vorhanden, daher konnte der POIDetailScreen ihn nicht finden.

**Lösung:** Neue `addPOI()` Methode im POIStateProvider:

```dart
// poi_state_provider.dart
void addPOI(POI poi) {
  final existingIndex = state.pois.indexWhere((p) => p.id == poi.id);
  if (existingIndex != -1) {
    // POI bereits vorhanden - aktualisieren
    final updatedPOIs = List<POI>.from(state.pois);
    updatedPOIs[existingIndex] = poi;
    state = state.copyWith(pois: updatedPOIs);
  } else {
    // POI hinzufügen
    state = state.copyWith(pois: [...state.pois, poi]);
  }
}

// trip_screen.dart - Navigation angepasst:
onTap: () {
  ref.read(pOIStateNotifierProvider.notifier).addPOI(stop);
  context.push('/poi/${stop.id}');
},
```

**Ergebnis:** POI-Details mit Foto werden jetzt korrekt angezeigt.

### Löschbutton für AI Trip (v1.6.8)

**Problem:** Nach AI Trip Generierung erschien kein Löschbutton auf der Karte.

**Ursache:** Der `_RouteClearButton` wurde nur für `routePlanner.hasStart || hasEnd` angezeigt, nicht für AI Trips.

**Lösung:** Zwei Anpassungen in `map_screen.dart`:

```dart
// 1. Schnell-Modus: Erweiterte Bedingung
if (routePlanner.hasStart || routePlanner.hasEnd ||
    randomTripState.step == RandomTripStep.preview ||
    randomTripState.step == RandomTripStep.confirmed)
  _RouteClearButton(
    onClear: () {
      ref.read(routePlannerProvider.notifier).clearRoute();
      ref.read(randomTripNotifierProvider.notifier).reset();
    },
  ),

// 2. AI Trip Modus: Separater Button
if (_planMode == MapPlanMode.aiTrip &&
    !isGenerating &&
    (randomTripState.step == RandomTripStep.preview ||
     randomTripState.step == RandomTripStep.confirmed))
  _RouteClearButton(...)
```

**Ergebnis:** Der "Route löschen" Button erscheint jetzt auch nach AI Trip Generierung.

### Auto-Zoom & Route Starten (v1.7.0, aktualisiert v1.7.8)

**Feature 1: "Route starten" Button statt Auto-Navigation (v1.7.8)**

Nach Berechnung einer Route wird die Karte auf die Route gezoomt. Der "Route starten" Button erscheint mit Distanz/Dauer-Info. Erst nach Klick navigiert die App zum Trip-Tab.

```dart
// map_screen.dart - Listener zoomt nur auf Route (keine Auto-Navigation)
ref.listenManual(routePlannerProvider, (previous, next) {
  if (next.hasRoute && (previous?.route != next.route)) {
    _fitMapToRoute(next.route!);
  }
});

// "Route starten" Button navigiert zum Trip-Tab
_RouteStartButton(
  route: routePlanner.route!,
  onStart: () {
    _startRoute(routePlanner.route!);
    context.go('/trip');
  },
),
```

**Feature 2: Auto-Zoom auf Route beim Tab-Wechsel**

Beim Wechsel vom Trip-Tab zur Karte wird automatisch auf die Route gezoomt.

```dart
// map_controller_provider.dart - Neuer Provider
final shouldFitToRouteProvider = StateProvider<bool>((ref) => false);

// route_planner_provider.dart - Nach Route-Berechnung
ref.read(shouldFitToRouteProvider.notifier).state = true;

// map_screen.dart - Im build()
final shouldFitToRoute = ref.watch(shouldFitToRouteProvider);
if (shouldFitToRoute) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (routeToFit != null) _fitMapToRoute(routeToFit);
    ref.read(shouldFitToRouteProvider.notifier).state = false;
  });
}
```

**Feature 3: "Auf Karte anzeigen" Button im TripScreen**

```dart
// trip_screen.dart
FilledButton.icon(
  onPressed: () {
    ref.read(shouldFitToRouteProvider.notifier).state = true;
    context.go('/');
  },
  icon: const Icon(Icons.map_outlined),
  label: const Text('Auf Karte anzeigen'),
),
```

**Feature 4: GPS-Fallback für Kartenausschnitt (v1.7.2)**

Ohne Route wird der GPS-Standort als Kartenzentrum verwendet.

```dart
// map_screen.dart - initState und build()
// Prüfe ob irgendeine Route vorhanden ist
final hasAnyRoute = routePlanner.hasRoute ||
    tripState.hasRoute ||
    randomTripState.step == RandomTripStep.preview ||
    randomTripState.step == RandomTripStep.confirmed;

if (hasAnyRoute) {
  // Auf Route zoomen (Priorität: AI Trip > Trip > RoutePlanner)
  _fitMapToRoute(routeToFit);
} else {
  // Keine Route → GPS-Standort zentrieren
  _centerOnCurrentLocationSilent();
}

// Fallback bei GPS-Fehler: Europa-Zentrum
void _showDefaultMapCenter() {
  mapController?.move(const LatLng(50.0, 10.0), 6.0);
}
```

**Ergebnis:** Bessere Benutzerführung zwischen Karte und Trip-Tab. Karte zeigt immer relevanten Ausschnitt.

### AI-Chat mit standortbasierten POI-Vorschlägen (v1.7.2)

**Feature 1: Automatisches GPS-Laden beim Chat-Start**

```dart
// chat_screen.dart - initState
@override
void initState() {
  super.initState();
  _checkBackendHealth();
  _initializeLocation(); // GPS automatisch beim Start laden
}

// State-Variablen
LatLng? _currentLocation;
String? _currentLocationName;
bool _isLoadingLocation = false;
double _searchRadius = 30.0; // 10-100km einstellbar
```

**Feature 2: Location-Header mit Radius-Einstellung**

```dart
// Zeigt aktuellen Standort und Radius
// 📍 München          [30 km] [⚙️]
Widget _buildLocationHeader(ColorScheme colorScheme) {
  // Standort-Info oder "Standort aktivieren" Button
  // Radius-Anzeige mit Settings-Button
}

// Radius-Slider Dialog (10-100km)
void _showRadiusSliderDialog() {
  // Quick-Select: 15, 30, 50, 100 km
}
```

**Feature 3: Standortbasierte POI-Suche**

```dart
// Neue Suggestion Chips
final _suggestions = [
  '📍 POIs in meiner Nähe',
  '🏰 Sehenswürdigkeiten',
  '🌲 Natur & Parks',
  '🍽️ Restaurants',
];

// Keyword-Erkennung für standortbasierte Anfragen
bool _isLocationBasedQuery(String query) {
  final keywords = ['in meiner nähe', 'um mich', 'hier', 'zeig mir', ...];
  return keywords.any((k) => query.toLowerCase().contains(k));
}

// POI-Suche mit Kategorien-Filter
Future<void> _handleLocationBasedQuery(String query) async {
  final categories = _getCategoriesFromQuery(query);
  final pois = await poiRepo.loadPOIsInRadius(
    center: _currentLocation!,
    radiusKm: _searchRadius,
    categoryFilter: categories,
  );
  // POIs nach Distanz sortieren und als Karten anzeigen
}
```

**Feature 4: Anklickbare POI-Karten im Chat**

```dart
// POI-Karten mit Bild, Name, Beschreibung, Distanz
Widget _buildPOICard(POI poi, ColorScheme colorScheme) {
  return Card(
    child: InkWell(
      onTap: () => _navigateToPOI(poi),
      child: Row(
        children: [
          // Bild (CachedNetworkImage)
          // Name + Beschreibung
          // Distanz Badge
          // Pfeil-Icon
        ],
      ),
    ),
  );
}

// Navigation zu POI-Details
void _navigateToPOI(POI poi) {
  ref.read(pOIStateNotifierProvider.notifier).addPOI(poi);
  if (poi.imageUrl == null) {
    ref.read(pOIStateNotifierProvider.notifier).enrichPOI(poi.id);
  }
  context.push('/poi/${poi.id}');
}
```

**Feature 5: TripContext mit Standort-Informationen**

```dart
// ai_service.dart - TripContext erweitert
class TripContext {
  final AppRoute? route;
  final List<POI> stops;

  // NEU: Standort-Informationen
  final double? userLatitude;
  final double? userLongitude;
  final String? userLocationName;

  bool get hasUserLocation => userLatitude != null && userLongitude != null;
}

// Backend erhält Standort im Kontext
final contextData = <String, dynamic>{};
if (context.hasUserLocation) {
  contextData['userLocation'] = {
    'lat': context.userLatitude,
    'lng': context.userLongitude,
    'name': context.userLocationName,
  };
}
```

**Kategorien-Zuordnung (v1.7.9: ungültige IDs gefixt + erweitert):**

| Anfrage | Kategorien |
|---------|------------|
| "Sehenswürdigkeiten" | `museum`, `monument`, `castle`, `viewpoint`, `unesco` |
| "Natur", "Parks" | `nature`, `park`, `lake`, `coast` |
| "Restaurants", "Essen" | `restaurant` |
| "Hotels" | `hotel` |
| "Kultur" | `museum`, `monument`, `church`, `castle`, `unesco` |
| "Strand", "Küste" | `coast` |
| "Aktivität", "Sport" | `activity` |
| "Wandern" | `nature`, `viewpoint`, `park` |
| "Familie" | `activity`, `park`, `museum` |
| "Zoo", "Freizeitpark", "Therme" | `activity` |
| "Stadt" | `city` |
| Unspezifisch | alle Kategorien |

**Feature 6: Hintergrund-Enrichment für POI-Bilder im Chat (v1.7.7)**

```dart
// chat_screen.dart - _handleLocationBasedQuery()
// POIs werden sofort mit Kategorie-Icons angezeigt
setState(() {
  _messages.add({
    'content': headerText,
    'isUser': false,
    'type': ChatMessageType.poiList,
    'pois': sortedPOIs,
  });
});

// Hintergrund-Enrichment: Bilder laden asynchron nach
final messageIndex = _messages.length - 1;
final poisToEnrich = sortedPOIs
    .where((p) => p.imageUrl == null && !p.isEnriched)
    .take(10)
    .toList();

if (poisToEnrich.isNotEmpty) {
  final enrichmentService = ref.read(poiEnrichmentServiceProvider);
  final enrichedMap = await enrichmentService.enrichPOIsBatch(poisToEnrich);

  if (mounted && messageIndex < _messages.length) {
    final updatedPOIs = sortedPOIs.map((p) => enrichedMap[p.id] ?? p).toList();
    setState(() {
      _messages[messageIndex] = {..._messages[messageIndex], 'pois': updatedPOIs};
    });
  }
}
```

**Ergebnis:** Der AI-Chat schlägt POIs basierend auf dem aktuellen Standort vor. Benutzer können den Such-Radius anpassen und direkt zu POI-Details navigieren. POI-Bilder werden im Hintergrund geladen und erscheinen nach 1-3 Sekunden (v1.7.7).
