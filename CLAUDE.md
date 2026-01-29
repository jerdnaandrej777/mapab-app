# CLAUDE.md - MapAB Flutter App

Diese Datei bietet Orientierung für Claude Code bei der Arbeit mit diesem Flutter-Projekt.

## Projektübersicht

Flutter-basierte mobile App für interaktive Routenplanung und POI-Entdeckung in Europa.
Version: 1.6.7 | Plattformen: Android, iOS, Desktop

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
| `lib/features/map/map_screen.dart` | Hauptscreen mit Karte + AI Trip Panel + GPS-Dialog + Floating Buttons ausblenden (v1.5.6) |
| `lib/features/map/widgets/map_view.dart` | Karten-Widget mit Route + AI Trip Preview (v1.5.0) |
| `lib/features/poi/poi_list_screen.dart` | POI-Liste mit Filter |
| `lib/features/poi/poi_detail_screen.dart` | POI-Details |
| `lib/features/trip/trip_screen.dart` | Route + Stops + Tagesweiser Export - nur berechnete Routen (v1.6.5) |
| `lib/features/ai_assistant/chat_screen.dart` | AI-Chat |
| `lib/features/account/profile_screen.dart` | Profil mit XP |
| `lib/features/favorites/favorites_screen.dart` | Favoriten |
| `lib/features/auth/login_screen.dart` | Cloud-Login mit Remember Me |
| `lib/features/onboarding/onboarding_screen.dart` | Animiertes Onboarding |
| `lib/features/random_trip/random_trip_screen.dart` | AI Trip Generator (Legacy) |
| `lib/features/random_trip/widgets/day_tab_selector.dart` | Tag-Auswahl für mehrtägige Trips (v1.5.7) |

### Provider

| Datei | Beschreibung |
|-------|--------------|
| `lib/data/providers/account_provider.dart` | Account State (keepAlive) |
| `lib/data/providers/favorites_provider.dart` | Favoriten State (keepAlive) |
| `lib/data/providers/auth_provider.dart` | Auth State (keepAlive) |
| `lib/features/trip/providers/trip_state_provider.dart` | Trip State (keepAlive) |
| `lib/features/poi/providers/poi_state_provider.dart` | POI State (keepAlive, v1.5.3 Filter-Fix) |
| `lib/features/map/providers/route_planner_provider.dart` | Route-Planner |
| `lib/data/providers/settings_provider.dart` | Settings mit Remember Me |
| `lib/features/random_trip/providers/random_trip_provider.dart` | AI Trip State mit Tages-Auswahl (v1.5.7) |

Details: [Dokumentation/PROVIDER-GUIDE.md](Dokumentation/PROVIDER-GUIDE.md)

### Services

| Datei | Beschreibung |
|-------|--------------|
| `lib/data/services/ai_service.dart` | AI via Backend-Proxy |
| `lib/data/services/poi_enrichment_service.dart` | Wikipedia/Wikidata Enrichment (v1.6.6 CORS & Rate-Limit Fix) |
| `lib/data/services/poi_cache_service.dart` | Hive-basiertes POI Caching |
| `lib/data/services/sync_service.dart` | Cloud-Sync |
| `lib/data/services/active_trip_service.dart` | Persistenz für aktive Trips (v1.5.7) |

### Daten

| Datei | Beschreibung |
|-------|--------------|
| `lib/data/models/poi.dart` | POI Model (Freezed) |
| `lib/data/models/trip.dart` | Trip Model mit Tages-Helper-Methoden (v1.5.7) |
| `lib/data/models/route.dart` | Route Model mit LatLng Converters |
| `lib/data/repositories/poi_repo.dart` | POI-Laden (3-Layer, parallel + Region-Cache) |
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
| `[Weather]` | Wetter-Laden |
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
ref.read(pOIStateNotifierProvider.notifier).enrichPOI(poiId);
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
- **Batch-Enrichment**: Max 3 POIs gleichzeitig, 500ms Pause zwischen Batches
- **ListView**: `cacheExtent: 500` für flüssigeres Scrollen

### POI-Foto-Optimierungen (v1.3.7+, v1.6.6)

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

**Bildquellen (in Prioritäts-Reihenfolge):**
1. Wikipedia API (pageimages) - Hauptbild + Thumbnail
2. Wikimedia Commons Geo-Suche (5km Radius, 15 Ergebnisse)
3. Wikimedia Commons Titel-Suche (bereinigter Name)
4. Wikimedia Commons Kategorie-Suche
5. Wikidata SPARQL (P18 Bild, P154 Logo, P94 Wappen)

**Performance-Vergleich:**
| Metrik | v1.3.6 | v1.3.7 |
|--------|--------|--------|
| Zeit pro POI | 3-9 Sek | 1-3 Sek |
| Bild-Trefferquote | ~60% | ~85% |
| Wikimedia Radius | 500m | 5km |

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
