# Riverpod Provider Guide

Diese Dokumentation beschreibt das State Management mit Riverpod in der MapAB Flutter App.

## Inhaltsverzeichnis

1. [Provider-Übersicht](#provider-übersicht)
2. [keepAlive vs AutoDispose](#keepalive-vs-autodispose)
3. [State-Flows](#state-flows)
4. [Patterns](#patterns)
5. [Debugging](#debugging)

---

## Provider-Übersicht

### Kern-Provider (keepAlive)

Diese Provider behalten ihren State über die gesamte App-Lebensdauer:

| Provider | Datei | Beschreibung |
|----------|-------|--------------|
| `accountNotifierProvider` | `account_provider.dart` | Account-Daten (Level, XP, Stats) |
| `favoritesNotifierProvider` | `favorites_provider.dart` | Favoriten (POIs + Routen) |
| `authNotifierProvider` | `auth_provider.dart` | Supabase Auth State |
| `settingsNotifierProvider` | `settings_provider.dart` | App-Einstellungen (Theme, etc.) |
| `tripStateProvider` | `trip_state_provider.dart` | Aktive Route + Stops |
| `pOIStateNotifierProvider` | `poi_state_provider.dart` | POI-Liste + Filter |
| `onboardingNotifierProvider` | `onboarding_provider.dart` | First-Time-Flag |
| `routeSessionProvider` | `route_session_provider.dart` | Aktive Route-Session |

### Service-Provider

| Provider | Datei | Beschreibung |
|----------|-------|--------------|
| `poiRepositoryProvider` | `poi_repo.dart` | POI-Laden (3-Layer) |
| `weatherRepositoryProvider` | `weather_repo.dart` | Open-Meteo API |
| `hotelServiceProvider` | `hotel_service.dart` | Hotel-Suche |
| `aiServiceProvider` | `ai_service.dart` | AI-Chat via Backend |
| `syncServiceProvider` | `sync_service.dart` | Cloud-Sync |
| `poiEnrichmentServiceProvider` | `poi_enrichment_service.dart` | POI Enrichment |
| `poiCacheServiceProvider` | `poi_cache_service.dart` | POI Caching |
| `supabaseClientProvider` | `supabase_client.dart` | Supabase Client |

### Helper-Provider (AutoDispose)

| Provider | Beschreibung |
|----------|--------------|
| `isPOIFavoriteProvider(String)` | Prüft ob POI favorisiert ist |
| `isRouteSavedProvider(String)` | Prüft ob Route gespeichert ist |
| `favoritePOIsProvider` | Liste aller POI-Favoriten |
| `savedRoutesProvider` | Liste aller gespeicherten Routen |
| `routePlannerProvider` | Start/Ziel-Verwaltung |
| `routeWeatherNotifierProvider` | Wetter-State für Route |
| `indoorOnlyFilterProvider` | Indoor-Filter bei schlechtem Wetter |
| `effectiveThemeModeProvider` | Berechneter Theme-Modus |

---

## keepAlive vs AutoDispose

### Unterschiede

| Aspekt | `@riverpod` (AutoDispose) | `@Riverpod(keepAlive: true)` |
|--------|---------------------------|------------------------------|
| State-Lebensdauer | Bis kein Widget mehr watched | Bis App beendet |
| Memory | Automatisch freigegeben | Bleibt im Speicher |
| Anwendungsfall | Temporäre UI-States | Persistente App-States |

### Wann keepAlive verwenden?

**Verwende keepAlive für:**
- Account/Auth State
- Favoriten/Gespeicherte Daten
- App-weite Settings
- States die über Navigation hinweg erhalten bleiben sollen

**Verwende AutoDispose für:**
- Screen-spezifische States
- Form-Eingaben
- Temporäre Filter/Suchen
- States die bei Screen-Verlassen zurückgesetzt werden sollen

### Beispiel

```dart
// AutoDispose - State wird bei Navigation gelöscht
@riverpod
class SearchQuery extends _$SearchQuery {
  @override
  String build() => '';
}

// keepAlive - State bleibt erhalten
@Riverpod(keepAlive: true)
class AccountNotifier extends _$AccountNotifier {
  @override
  Future<Account> build() async {
    return await _loadAccount();
  }
}
```

---

## State-Flows

### Route-Planner Flow

```
┌─────────────────────────────────────────────────────┐
│              User wählt Standort                     │
│                 (SearchScreen)                       │
└──────────────────┬──────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────┐
│        routePlannerProvider.setStart() /             │
│        routePlannerProvider.setEnd()                 │
└──────────────────┬──────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────┐
│    routePlannerProvider._tryCalculateRoute()         │
│    (automatisch wenn beide gesetzt)                  │
└──────────────────┬──────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────┐
│      routingRepository.calculateFastRoute()          │
│      (OSRM API Call)                                 │
└──────────────────┬──────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────┐
│  tripStateProvider.setRoute(route) ← KEY CONNECTION  │
└──────────────────┬──────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────┐
│        TripScreen zeigt Route an                     │
└─────────────────────────────────────────────────────┘
```

### Random-Trip Flow

```
┌─────────────────────────────────────────────────────┐
│     User klickt "Überrasch mich!" (ohne Start)      │
└──────────────────┬──────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────┐
│  generateTrip() prüft: hasValidStart? NEIN          │
│  → useCurrentLocation() wird automatisch aufgerufen │
└──────────────────┬──────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────┐
│  GPS-Position ermittelt (oder München-Fallback)     │
│  → state.startLocation + startAddress gesetzt       │
└──────────────────┬──────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────┐
│  Trip wird generiert (tripGeneratorRepository)      │
│  → POIs geladen, Route optimiert, Stops erstellt    │
└──────────────────┬──────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────┐
│  User klickt "Bestätigen"                           │
│  → confirmTrip() aufgerufen                         │
└──────────────────┬──────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────┐
│  tripStateProvider.setRoute(route)                  │
│  tripStateProvider.setStops(pois)                   │
│  → State wird persistent gespeichert (keepAlive)    │
└──────────────────┬──────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────┐
│  Navigation zu /trip                                │
│  → TripScreen zeigt Route + Stops                   │
└─────────────────────────────────────────────────────┘
```

---

## Patterns

### _ensureLoaded() Pattern

Für AsyncNotifier mit keepAlive, die auf geladenen State warten müssen:

```dart
// lib/data/providers/favorites_provider.dart

@Riverpod(keepAlive: true)
class FavoritesNotifier extends _$FavoritesNotifier {
  @override
  Future<FavoritesState> build() async {
    return await _loadFavorites();
  }

  /// Wartet bis der State geladen ist und gibt ihn zurück
  Future<FavoritesState> _ensureLoaded() async {
    // Wenn bereits geladen, direkt zurückgeben
    if (state.hasValue && state.value != null) {
      return state.value!;
    }

    // Warte auf das Laden
    debugPrint('[Favorites] Warte auf State-Laden...');
    final currentState = await future;
    debugPrint('[Favorites] State geladen');
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
}
```

### Freezed State Classes

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

  // Computed getters
  const RoutePlannerData._();
  bool get hasStart => startLocation != null;
  bool get hasEnd => endLocation != null;
  bool get canCalculate => hasStart && hasEnd;
}
```

### Provider Watching

```dart
// In ConsumerWidget
@override
Widget build(BuildContext context, WidgetRef ref) {
  // Reactive watching - rebuilds when state changes
  final favorites = ref.watch(favoritesNotifierProvider);

  return favorites.when(
    loading: () => const CircularProgressIndicator(),
    error: (e, st) => Text('Fehler: $e'),
    data: (state) => ListView.builder(
      itemCount: state.favoritePOIs.length,
      itemBuilder: (context, index) => POICard(poi: state.favoritePOIs[index]),
    ),
  );
}

// Für einmalige Aktionen
void _onTap() {
  // read statt watch für Aktionen
  ref.read(favoritesNotifierProvider.notifier).addPOI(poi);
}
```

---

## Debugging

### Debug-Logging Prefixes

| Prefix | Provider/Komponente |
|--------|---------------------|
| `[Favorites]` | FavoritesNotifier |
| `[Account]` | AccountNotifier |
| `[Auth]` | AuthNotifier |
| `[Splash]` | SplashScreen Navigation |
| `[POIState]` | POIStateNotifier |

### Common Issues

**Problem: State wird bei Navigation gelöscht**
- Lösung: `@Riverpod(keepAlive: true)` verwenden

**Problem: Methode tut nichts wenn State noch lädt**
- Lösung: `_ensureLoaded()` Pattern implementieren

**Problem: Rekursive Schleife im Splash-Screen**
- Lösung: Reaktives Pattern mit `ref.watch()` und `_hasNavigated` Flag

### Riverpod DevTools

```dart
// In main.dart für Debugging
void main() {
  runApp(
    ProviderScope(
      observers: [ProviderLogger()],
      child: const MyApp(),
    ),
  );
}

class ProviderLogger extends ProviderObserver {
  @override
  void didUpdateProvider(ProviderBase provider, Object? previousValue, Object? newValue, ProviderContainer container) {
    debugPrint('[Provider] ${provider.name}: $previousValue -> $newValue');
  }
}
```
