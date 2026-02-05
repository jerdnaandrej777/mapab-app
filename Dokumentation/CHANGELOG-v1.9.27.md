# CHANGELOG v1.9.27 - Sicherheit, Refactoring & Code-Qualitaet

**Datum:** 2026-02-04
**Version:** 1.9.27+174
**Typ:** Multi-Phase Code-Verbesserung (Phasen 0-6)

## Uebersicht

Umfassende Code-Verbesserung in 7 Phasen: Sicherheit gehaertet, Dead Code entfernt, GPS-Logik konsolidiert, 298 Tests geschrieben, API-Modernisierung (withOpacity→withValues), Dark-Mode-Fixes, Lint-Regeln eingefuehrt, Provider-Lifecycle optimiert, 3 Features implementiert.

## Phase 0: Sofort-Bereinigung

- **image_picker entfernt** - Ungenutzte Dependency aus pubspec.yaml entfernt
- **Debug-Credentials geschuetzt** - Supabase Fallback-Credentials in `kDebugMode`-Guard gewrappt (`main.dart`)

## Phase 1: Sicherheit & Stabilitaet

- **Passwort-Mindestlaenge 8** - Login + Registrierung validieren Passwortlaenge (`login_screen.dart`, `register_screen.dart`)
- **HTTPS-Validierung** - API-Endpoints werden auf HTTPS geprueft (`api_config.dart`, `api_endpoints.dart`)
- **Hive-Verschluesselung** - Encryption Key aus SecureStorage statt Hardcoded (`main.dart`, `settings_provider.dart`)
- **URL-Sanitisierung** - Neues Utility `url_utils.dart` fuer sichere URL-Verarbeitung

## Phase 2: Code-Qualitaet & Refactoring

- **Dead Code entfernt** - 6 ungenutzte Model-Dateien geloescht: `cost.dart`, `elevation.dart`, `journal.dart`, `statistics.dart`, `traffic.dart`, `user_preferences.dart` + zugehoerige Provider und Repositories
- **GPS-Konsolidierung** - Neues `location_helper.dart` Utility vereinheitlicht GPS-Zugriff und Dialog-Logik
- **Dio-Interceptors** - Zentralisierte Request/Response-Logging und Error-Handling in `api_config.dart`
- **API-Endpoints zentralisiert** - Alle API-URLs in `api_endpoints.dart` konsolidiert

## Phase 3: Testing-Grundlage

- **Test-Helpers** - Shared `test_factories.dart` mit `createPOI()`, `createTrip()`, Staedte-Koordinaten
- **6 Test-Dateien** - Tests fuer: POI-Model, Trip-Model, Weather-Model, TripConstants, WeatherPOIUtils, RouteOptimizer
- **238 Tests** - Alle bestanden

## Phase 4: Robustheit & Zugaenglichkeit

- **Geocoding-Sanitisierung** - `_sanitizeQuery()` und `_maxQueryLength` in `geocoding_repo.dart`
- **AI-Service Error-Cleanup** - Unerreichbaren Rethrow entfernt, `isRetryable` Getter hinzugefuegt
- **SyncService Error-Tracking** - `SyncError`-Klasse mit `lastError` State
- **Accessibility** - `Semantics`-Widgets auf `_RouteClearButton`, `_ActiveTripResumeBanner`, `_InfoItem`, `ManeuverBanner` (liveRegion)
- **Auth-Validierung** - Name maxLength, Passwort-Komplexitaet (Gross/Klein/Zahl), E-Mail maxLength
- **274 Tests** - 36 neue Tests

## Phase 5: Performance & Modernisierung

- **235 withOpacity→withValues(alpha:) Migrationen** - Ueber 46 Dateien, Flutter 3.x moderne API
- **Dark-Mode-Fixes**:
  - `app_snackbar.dart`: `Colors.amber` → `colorScheme.tertiaryContainer`
  - `navigation_screen.dart`: `Colors.black54` → `colorScheme.scrim`
- **TextEditingController-Disposal** - Memory-Leak in `chat_screen.dart` Dialog behoben
- **Silent-Catch Logging** - Leere Catch-Bloecke in `navigation_tts_provider.dart` loggen jetzt Fehler
- **289 Tests** - 15 neue Tests

## Phase 6: Feinschliff & Wartbarkeit

### Lint-Regeln (`analysis_options.yaml`)
- Neues `analysis_options.yaml` mit `flutter_lints` als Basis
- `prefer_const_constructors`, `avoid_print`, `use_build_context_synchronously` als Warning
- `prefer_final_locals`, `prefer_single_quotes`, `sort_child_properties_last` als Info
- Generierter Code (`*.g.dart`, `*.freezed.dart`) wird ausgeschlossen

### Provider keepAlive (3 Provider)
- `CorridorBrowserNotifier` → `@Riverpod(keepAlive: true)` - POI-Filter-State bleibt bei Screen-Wechsel
- `AITripAdvisorNotifier` → `@Riverpod(keepAlive: true)` - GPT-4o-Empfehlungen bleiben bei Tageswechsel
- `NavigationPOIDiscoveryNotifier` → `@Riverpod(keepAlive: true)` - Discovery-State waehrend Navigation

### 3 Features implementiert (aus TODOs)
1. **Zwischenstopp auf Karte** - Long-Press auf Karte → "Als Stopp hinzufuegen" erstellt Waypoint-POI (`map_view.dart`)
2. **POI Teilen** - Share-Button in POI-Details sendet Name + Google-Maps-Link via `share_plus` (`poi_detail_screen.dart`)
3. **Route optimieren** - Menue-Item verbunden mit `RouteOptimizer` (Nearest-Neighbor + 2-opt TSP) (`trip_screen.dart`)

### Tests
- **298 Tests gesamt** - 9 neue Tests (5 RouteOptimizer + 4 keepAlive)

## Betroffene Dateien (Auswahl)

### Neu erstellt
- `lib/core/utils/location_helper.dart` - GPS-Utility
- `lib/core/utils/url_utils.dart` - URL-Sanitisierung
- `analysis_options.yaml` - Lint-Regeln
- `test/algorithms/route_optimizer_test.dart`
- `test/providers/keepalive_test.dart`
- 10+ weitere Test-Dateien

### Geaendert (wichtigste)
- `lib/main.dart` - Hive-Verschluesselung, Debug-Guard
- `lib/core/constants/api_config.dart` - HTTPS-Validierung, Dio-Interceptors
- `lib/features/auth/login_screen.dart` - Passwort-Validierung
- `lib/features/auth/register_screen.dart` - Auth-Validierung
- `lib/features/map/widgets/map_view.dart` - Zwischenstopp-Feature
- `lib/features/poi/poi_detail_screen.dart` - POI-Teilen
- `lib/features/trip/trip_screen.dart` - Route-Optimierung
- 46 Dateien mit withOpacity→withValues Migration

### Geloescht
- `lib/data/models/cost.dart`
- `lib/data/models/elevation.dart`
- `lib/data/models/journal.dart`
- `lib/data/models/statistics.dart`
- `lib/data/models/traffic.dart`
- `lib/data/models/user_preferences.dart`
- Zugehoerige Provider und Repositories
