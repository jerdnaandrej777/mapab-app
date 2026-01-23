# CLAUDE.md - MapAB Flutter App

Diese Datei bietet Orientierung für Claude Code bei der Arbeit mit diesem Flutter-Projekt.

## Projektübersicht

Flutter-basierte mobile App für interaktive Routenplanung und POI-Entdeckung in Europa.
Version: 1.3.1 | Plattformen: Android, iOS, Desktop

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

# Release Build
flutter build apk --release --dart-define=...
```

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
| `lib/core/supabase/supabase_config.dart` | Supabase Credentials (--dart-define) |

### Features

| Datei | Beschreibung |
|-------|--------------|
| `lib/features/map/map_screen.dart` | Hauptscreen mit Karte |
| `lib/features/poi/poi_list_screen.dart` | POI-Liste mit Filter |
| `lib/features/poi/poi_detail_screen.dart` | POI-Details |
| `lib/features/trip/trip_screen.dart` | Route + Stops |
| `lib/features/ai_assistant/chat_screen.dart` | AI-Chat |
| `lib/features/account/profile_screen.dart` | Profil mit XP |
| `lib/features/favorites/favorites_screen.dart` | Favoriten |
| `lib/features/auth/login_screen.dart` | Cloud-Login |
| `lib/features/onboarding/onboarding_screen.dart` | Animiertes Onboarding |

### Provider

| Datei | Beschreibung |
|-------|--------------|
| `lib/data/providers/account_provider.dart` | Account State (keepAlive) |
| `lib/data/providers/favorites_provider.dart` | Favoriten State (keepAlive) |
| `lib/data/providers/auth_provider.dart` | Auth State (keepAlive) |
| `lib/features/trip/providers/trip_state_provider.dart` | Trip State (keepAlive) |
| `lib/features/poi/providers/poi_state_provider.dart` | POI State (keepAlive) |
| `lib/features/map/providers/route_planner_provider.dart` | Route-Planner |

Details: [Dokumentation/PROVIDER-GUIDE.md](Dokumentation/PROVIDER-GUIDE.md)

### Services

| Datei | Beschreibung |
|-------|--------------|
| `lib/data/services/ai_service.dart` | AI via Backend-Proxy |
| `lib/data/services/poi_enrichment_service.dart` | Wikipedia/Wikidata Enrichment |
| `lib/data/services/poi_cache_service.dart` | Hive-basiertes POI Caching |
| `lib/data/services/sync_service.dart` | Cloud-Sync |

### Daten

| Datei | Beschreibung |
|-------|--------------|
| `lib/data/models/poi.dart` | POI Model (Freezed) |
| `lib/data/models/route.dart` | Route Model mit LatLng Converters |
| `lib/data/repositories/poi_repo.dart` | POI-Laden (3-Layer) |
| `assets/data/curated_pois.json` | 527 kuratierte POIs |

## API-Abhängigkeiten

| API | Zweck | Auth |
|-----|-------|------|
| Nominatim | Geocoding | - |
| OSRM | Fast Routing | - |
| OpenRouteService | Scenic Routing | API-Key |
| Overpass | POIs & Hotels | - |
| Wikipedia DE | Geosearch + Extracts | - |
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
/trip               → TripScreen
/assistant          → ChatScreen (AI)
/profile            → ProfileScreen
/favorites          → FavoritesScreen
/settings           → SettingsScreen
/search             → SearchScreen
/random-trip        → RandomTripScreen
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
| `[Enrichment]` | POI Enrichment Service |
| `[POICache]` | Cache Operationen |
| `[POIState]` | POI State Änderungen |
| `[Favorites]` | Favoriten-Operationen |
| `[Sync]` | Cloud-Sync |
| `[Weather]` | Wetter-Laden |
| `[AI]` | AI-Anfragen |
| `[GPS]` | GPS-Funktionen |
| `[Auth]` | Auth-Operationen |
| `[Splash]` | Splash-Screen Navigation |
| `[Account]` | Account-Laden |
| `[Onboarding]` | Onboarding-Status |

## Bekannte Einschränkungen

1. **Wikipedia API**: 10km Radius-Limit pro Anfrage
2. **Wikipedia CORS**: Im Web-Modus blockiert (Android/iOS funktioniert)
3. **Wikimedia Rate-Limit**: Max 200 Anfragen/Minute
4. **Overpass API**: Rate-Limiting, kann langsam sein
5. **OpenAI**: Benötigt aktives Guthaben
6. **GPS**: Nur mit HTTPS/Release Build zuverlässig

## Android-Berechtigungen

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

---

## Dokumentation

Detaillierte Dokumentationen finden sich im `Dokumentation/`-Ordner:

### Feature-Dokumentation

| Datei | Inhalt |
|-------|--------|
| [FLUTTER-APP-DOKUMENTATION.md](Dokumentation/FLUTTER-APP-DOKUMENTATION.md) | Vollständige Feature-Übersicht, Download-Links |
| [BACKEND-SETUP.md](Dokumentation/BACKEND-SETUP.md) | Vercel + Supabase Setup-Anleitung |

### Technische Guides

| Datei | Inhalt |
|-------|--------|
| [POI-SYSTEM.md](Dokumentation/POI-SYSTEM.md) | POI-Datenstruktur, Kategorien, Enrichment, Caching |
| [PROVIDER-GUIDE.md](Dokumentation/PROVIDER-GUIDE.md) | Riverpod Provider, keepAlive, State Flows |
| [DARK-MODE.md](Dokumentation/DARK-MODE.md) | Theme-Implementierung, Dos/Don'ts, Farbreferenz |
| [SECURITY.md](Dokumentation/SECURITY.md) | Credentials, --dart-define, Build-Scripts |

### Planung

| Datei | Inhalt |
|-------|--------|
| [LARAVEL-MIGRATION.md](Dokumentation/LARAVEL-MIGRATION.md) | Geplante Backend-Migration zu Laravel |

### Changelogs

Versionsspezifische Änderungen finden sich in:
- `Dokumentation/CHANGELOG-v1.2.x.md`
- `Dokumentation/CHANGELOG-v1.3.x.md`

---

## Quick Reference

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

### Route berechnen

```dart
final routePlanner = ref.read(routePlannerProvider.notifier);
routePlanner.setStart(latLng, 'Adresse');
routePlanner.setEnd(latLng, 'Adresse');
// Route wird automatisch berechnet wenn beide gesetzt
```

### POI enrichen

```dart
ref.read(pOIStateNotifierProvider.notifier).enrichPOI(poiId);
```

### Cloud-Sync Status prüfen

```dart
final authState = ref.watch(authNotifierProvider);
if (authState.isAuthenticated) {
  // User ist eingeloggt, Cloud-Sync aktiv
}
```
