# CLAUDE.md - MapAB Flutter App

Diese Datei bietet Orientierung fÃ¼r Claude Code bei der Arbeit mit diesem Flutter-Projekt.

## ProjektÃ¼bersicht

Flutter-basierte mobile App fÃ¼r interaktive Routenplanung und POI-Entdeckung in Europa.
Version: 1.10.39 - Erweiterung AI-POI-Erlebnis (klickbar + reichhaltig + foto-basiert) | Plattformen: Android, iOS, Desktop
### Letztes Release (v1.10.39)

- Neuer strukturierter AI-Endpoint `POST /api/ai/poi-suggestions` mit validierter Ausgabe und Fallback-Ranking.
- AI-Vorschlaege sind ueber Day-Editor, Day-Mini-Map, Hauptkarte und AI-Chat klickbar wie normale POIs.
- AI-Suggestions auf bis zu 8 erweitert, inkl. longDescription, Highlights und Bilder (Enrichment + Social).
- Navigationsluecken geschlossen: `'/ai-assistant'` und `'/pois'` sind als Routen verfuegbar.
- Neue Tests fuer AI-Exception-Handling und tappable Day-Mini-Map-Marker.


## Tech Stack

| Kategorie | Technologie |
|-----------|-------------|
| Framework | Flutter 3.38.7+ |
| State Management | Riverpod 2.x mit Code-Generierung |
| Routing | GoRouter mit Bottom Navigation |
| Karte | flutter_map (2D) + maplibre_gl (3D Navigation) |
| HTTP | Dio mit Cache |
| Lokale Daten | Hive (Favoriten, Settings, Account) |
| Cloud-Backend | Supabase (PostgreSQL + Auth) |
| Models | Freezed fÃ¼r immutable Klassen |
| AI | OpenAI GPT-4o via Backend-Proxy |

## Entwicklung

```bash
# Dependencies installieren
flutter pub get

# Code-Generierung (nach Model-Ã„nderungen)
flutter pub run build_runner build --delete-conflicting-outputs

# Watch-Mode fÃ¼r kontinuierliche Generierung
flutter pub run build_runner watch

# App starten (mit Credentials)
# Siehe: Dokumentation/SECURITY.md fÃ¼r --dart-define

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
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚           UI (features/)            â”‚  Screens, Widgets
â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¤
â”‚         Providers (Riverpod)        â”‚  State Management
â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¤
â”‚      Services & Repositories        â”‚  Business Logic
â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¤
â”‚            Models (data/)           â”‚  Datenstrukturen
â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¤
â”‚          External APIs              â”‚  Nominatim, OSRM, etc.
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
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
| `lib/core/constants/trip_constants.dart` | Trip-Konstanten: maxPoisPerDay, kmPerDay, minKmPerDay, maxKmPerDay (v1.5.7, v1.8.1) + maxHaversineKmForDisplay Getter (v1.9.5) |
| `lib/core/supabase/supabase_config.dart` | Supabase Credentials (--dart-define) |
| `lib/core/utils/weather_poi_utils.dart` | Zentralisierte Wetter/POI-Logik: getWeatherAdjustedScore, sortByWeatherRelevance, getBadgeInfo, isWeatherRecommended (v1.9.12) |
| `lib/core/algorithms/random_poi_selector.dart` | POI-Auswahl-Algorithmus mit effectiveScore-Unterstuetzung fuer Wetter-Gewichtung (v1.9.12) + removeAt(indexOf) statt removeWhere fuer O(n) statt O(n^2) Pool-Bereinigung (v1.9.28) |
| `lib/data/repositories/supabase_poi_repo.dart` | Supabase PostGIS POI-Repository: search_pois_in_radius/bounds RPC, uploadEnrichedPOI/Batch, snake_case->camelCase Mapping (v1.9.13) + getPOIById() fuer stabile POI-Deep-Links/Detailauflosung (v1.10.35) |
| `backend/supabase/migrations/002_pois_postgis.sql` | PostGIS Extension + pois Tabelle + search_pois_in_radius/bounds + upsert_poi RPC + RLS Policies (v1.9.13) |
| `backend/supabase/migrations/006_social_features_reset.sql` | Social Features RESET: Loescht alte Tabellen + erstellt user_profiles, trips, trip_likes, trip_imports + Indexes + RLS Policies + RPC Functions (search_public_trips, like_trip, unlike_trip, publish_trip, import_trip, etc.) (v1.10.9) |
| `backend/supabase/migrations/009_leaderboard.sql` | Leaderboard: XP, Level, Streak-Felder in user_profiles, get_leaderboard + get_my_leaderboard_position RPC (v1.10.23) |
| `backend/supabase/migrations/010_challenges.sql` | Challenges: challenge_definitions, user_challenges, streak_history Tabellen, assign_weekly_challenges + update_challenge_progress RPC (v1.10.23) |
| `supabase/migrations/20260208103000_poi_publish_rpc_fix.sql` | POI Publish RPC-Fix: erstellt/aktualisiert publish_poi_post() und get_public_poi() fuer POI-Posts ohne PGRST202-Fehler (v1.10.35) |
| `backend/scripts/seed_curated_pois.dart` | Seed-Script: curated_pois.json â†’ Supabase per upsert_poi RPC, idempotent (v1.9.13) |
| `lib/core/utils/location_helper.dart` | Zentralisiertes GPS-Utility: getCurrentPosition, showGpsDialog, checkPermissions (v1.9.27) |
| `lib/core/utils/url_utils.dart` | URL-Sanitisierung: validateHttpsUrl, sanitizeApiUrl (v1.9.27) |
| `analysis_options.yaml` | Lint-Regeln: prefer_const_constructors, avoid_print, use_build_context_synchronously, Excludes fuer generierte Dateien (v1.9.27) |
| `lib/core/l10n/l10n.dart` | Convenience Extension: `context.l10n` fuer Lokalisierung (v1.9.29) |
| `lib/core/l10n/category_l10n.dart` | Enum-Lokalisierung: POICategory, TripType, WeatherCondition, AppThemeMode Extensions (v1.9.29) |
| `lib/core/l10n/service_l10n.dart` | Context-freie Lokalisierung: fromLanguageCode(), localizedCategoryLabel() fuer Services/Provider ohne BuildContext (v1.10.3) |
| `lib/l10n/app_de.arb` | Template-ARB mit ~800+ lokalisierten Strings (v1.10.3) |
| `l10n.yaml` | Flutter l10n Konfiguration: arb-dir, template-arb-file, output-class (v1.9.29) |

### Features

| Datei | Beschreibung |
|-------|--------------|
| `lib/features/map/map_screen.dart` | Hauptscreen mit Karte + Unified Panel Design in beiden Modi + AppBar mit Favoriten/Profil/Settings (v1.7.37: extendBodyBehindAppBar: false, Panel-Kompaktierung) + Euro Trip Tage-Slider statt Radius (v1.7.38) + ActiveTripResumeBanner + Ãœberschreib-Dialog (v1.7.39) + Ziel als BottomSheet (v1.7.36: 50% Hoehe + Expanded Vorschlagsliste v1.8.1) + GPS-Fix _ensureGPSReady (v1.7.36) + "Navigation starten" Button in TripInfoBar (v1.9.0) + mounted-Checks nach async GPS-Operationen gegen setState-after-dispose (v1.9.22) + Listener-Subscriptions mit close() in dispose(), Slider onChangeEnd-Debounce (v1.9.28) |
| `lib/features/map/widgets/map_view.dart` | Karten-Widget mit Route + AI Trip Preview + Wetter-Badges auf POI-Markern + Routen-Wetter-Marker (v1.7.12) + Tagesweise Route/POIs bei Mehrtages-Trips (v1.7.40) + Auto-Zoom bei Tageswechsel (v1.8.1) + Mini-Wetter-Badges auf _AITripStopMarker, tagesspezifisch bei Multi-Day (v1.9.12) + Listener-Subscriptions mit close() in dispose(), doppelter randomTripNotifier-Listener gemergt (v1.9.28) |
| `lib/features/map/widgets/route_weather_marker.dart` | Wetter-Marker auf Route mit Tap-Detail-Sheet (v1.7.12) |
| `lib/features/poi/poi_list_screen.dart` | POI-Liste mit alle 15 Kategorien als Quick-Filter + konsistentes Chip-Feedback mit Schatten (v1.7.24) + Batch-Enrichment + AI-Trip-Stop-Integration (v1.7.8) - Referenz-Pattern fÃ¼r alle Kategorie-Chips (v1.7.26) + Wetter-Tipp Sortier-Chip + Wetter-Kontext-Banner bei schlechtem Wetter (v1.9.12) |
| `lib/features/poi/poi_detail_screen.dart` | POI-Details + AI-Trip-Stop-Integration (v1.7.8) + robustes Laden ueber ensurePOIById() fuer Deeplinks/Browse ohne vorhandenen POI-State (v1.10.35) |
| `lib/features/trip/trip_screen.dart` | Route + Stops + Auf Karte anzeigen Button + Route/AI-Trip in Favoriten speichern (v1.7.10) + Trip-Abschluss-Dialog (v1.7.39) + Export-Snackbar entfernt + Google Maps Hinweis (v1.7.40) + Korridor-POI-Browser Button (v1.8.0) + Navigation starten Button in beiden Modi: normale Route + AI Trip Preview (v1.9.0) + Wetter-Badges auf Stop-Tiles + Wetter-Hint bei bad/danger Wetter (v1.9.12) + AppBar Speichern-Button fuer AI Trips (v1.10.6) + Dominanter FilledButton.tonalIcon Speichern-Button + Speichern-Snackbar entfernt (v1.10.8) |
| `lib/features/navigation/navigation_screen.dart` | Vollbild-Navigation mit MapLibre GL 3D-Perspektive (Tilt 50Â°), Heading-basierter Bearing, GeoJSON Route-Rendering, Native Circle-Marker, Rerouting-Overlay (v1.9.0, v1.9.1: flutter_map â†’ maplibre_gl, v1.9.3: nativer User-Position Circle statt Flutter Center-Widget, Pan-Gesten aktiviert) + mounted-Check in 60fps Interpolation-Callback (v1.9.22) + Vollstaendiges dispose() mit Provider-Cleanup, lokaler MapController-Capture gegen Race-Condition, _arrivalDialogShown Flag, context.mounted Guards in Dialogen (v1.9.23) + Route/POI-Updates nur bei tatsaechlicher Aenderung statt jedem build(), moveCamera statt animateCamera fuer 60fps ohne Animation-Stacking (v1.9.25) + Sprachbefehle via VoiceService: "wie lange noch", "wo bin ich", "naechster Stopp", "Navigation beenden" + partielle Spracherkennung-UI (v1.9.29) + Route-Speichern-Button via TripSaveHelper (v1.10.9) |
| `lib/features/navigation/widgets/maneuver_banner.dart` | Manoever-Banner oben: Icon + Distanz + Instruktion (v1.9.0) |
| `lib/features/navigation/widgets/navigation_bottom_bar.dart` | Bottom Bar: Distanz, ETA, Tempo, Mute/Uebersicht/Beenden/Mikrofon Buttons (v1.9.0) + Sprachbefehl-Button mit aktiver Listening-Animation (v1.9.29) + onSave Callback fuer Route-Speichern-Button (v1.10.9) |
| `lib/features/navigation/widgets/poi_approach_card.dart` | Floating Card bei POI-Annaeherung: Kategorie-Icon, Name, Distanz, Besucht-Button (v1.9.0) |
| `lib/features/trip/widgets/day_editor_overlay.dart` | Vollbild-Editor fuer Trip-Tage mit Mini-Map, POI-Karten, Tages-Wetter, AI-Vorschlaege-Section, Korridor-Browser-Button (v1.8.0) + echte Distanz-Anzeige (v1.8.1) + MiniMap ValueKey + ~km Label (v1.8.2) + "Navigation starten" Button fuer tagesspezifische In-App Navigation (v1.9.0) + Button-Redesign: 3-Ebenen Layout mit dominantem Navi-Button, Route Teilen, OutlinedButton Google Maps (v1.9.4) + Fahrzeit-Chip in DayStats (v1.9.6) + Korridor-Browser Inline-Integration: MiniMap+Stats fixiert oben, CorridorBrowserContent inline statt Modal-Sheet, Auto-Close bei Tageswechsel (v1.9.7) + AI-POI-Empfehlungen als actionable Karten (_AIRecommendedPOICard), POI-Entfernen via onRemovePOI-Callback (v1.9.8) + Smart-Empfehlungen Button wetterunabhaengig, MiniMap recommendedPOIs Vorschau-Marker (v1.9.9) + _isIndoorCategory konsolidiert durch POICategory.isIndoor, Auto-Trigger AI bei bad/danger Wetter (v1.9.12) + context.mounted-Check bei doppeltem Navigator.pop (v1.9.22) + Waypoints auf AppRoute gesetzt, context.mounted Guard bei Navigation-Push (v1.9.23) + mounted-Guard in addPostFrameCallback, startLocation Null-Safety (v1.9.28) + AppBar Speichern-Button via TripSaveHelper (v1.10.9) + TextButton.icon "Veroeffentlichen" in AppBar fuer direktes Trip-Publishing (v1.10.16) |
| `lib/features/trip/widgets/editable_poi_card.dart` | POI-Karte im DayEditor mit Reroll/Delete + WeatherBadgeUnified (v1.9.12: konsolidiert, Dark-Mode-Fix) |
| `lib/features/trip/widgets/corridor_browser_sheet.dart` | Sheet zum Entdecken von POIs entlang der Route mit Slider + Kategorie-Filter (v1.8.0) + onAddPOI-Callback (v1.9.5) + CorridorBrowserContent als wiederverwendbares Widget extrahiert, DraggableScrollableSheet fuer TripScreen-Vollbild beibehalten (v1.9.7) + onRemovePOI-Callback mit Bestaetigungs-Dialog + markAsRemoved (v1.9.8) + Wetter-Sortierung, Header-Info, Indoor Quick-Filter Chip (v1.9.12) + Slider onChanged/onChangeEnd Debounce, Indoor-Toggle setCategoriesBatch, dispose() mit reset() (v1.9.20) + Weather-Watch Deduplizierung (einmal in build() statt doppelt in Header+Liste), Wetter-Sortier-Cache mit identical()-Check, ValueKey(poi.id) auf CompactPOICard (v1.9.21) |
| `lib/features/map/widgets/compact_poi_card.dart` | Kompakte 64px POI-Karte fuer Listen-Ansicht im Korridor-Browser (v1.8.0) + onRemove-Callback mit Minus-Icon (rot) fuer hinzugefuegte POIs (v1.9.8) + weatherCondition-Parameter fuer Wetter-Badges (v1.9.12) |
| `lib/features/map/widgets/weather_badge_unified.dart` | Einheitliches Wetter-Badge-Widget mit 3 Groessen (compact, inline, mini) + fromCategory Factory, ersetzt 3 duplizierte Badge-Implementierungen (v1.9.12) |
| `lib/features/map/utils/poi_trip_helper.dart` | Shared Utility: POI zu Trip hinzufuegen mit Feedback + GPS-Dialog (v1.8.0) |
| `lib/features/trip/utils/trip_save_helper.dart` | Shared Utility: Route/AI-Trip speichern mit Dialog + Favoriten-Integration: saveRoute(), saveAITrip(), saveRouteDirectly() (v1.10.9) |
| `lib/features/ai/widgets/ai_suggestion_banner.dart` | Wetter-Warnung im DayEditor mit "Indoor-Alternativen vorschlagen" Button (v1.8.0: verbunden) |
| `lib/features/ai_assistant/chat_screen.dart` | AI-Chat mit standortbasierten POI-VorschlÃ¤gen + Hintergrund-Enrichment (v1.7.7) + Kategorie-Fix (v1.7.9) + Wetter-aware Suggestion Chips, Wetter-Sortierung, Badges auf POI-Karten (v1.9.12) + Komplett lokalisiert: 24+ Strings, Demo-Banner, Radius-Dialog, Suggestion-Chips, Trip-Generator-Dialog (v1.10.3) |
| `lib/features/account/profile_screen.dart` | Profil mit XP |
| `lib/features/favorites/favorites_screen.dart` | Favoriten mit Auto-Enrichment + Gespeicherte Routen laden (v1.7.10) |
| `lib/features/auth/login_screen.dart` | Cloud-Login mit Remember Me |
| `lib/features/onboarding/onboarding_screen.dart` | Animiertes Onboarding |
| `lib/features/random_trip/random_trip_screen.dart` | AI Trip Generator (Legacy) |
| `lib/features/random_trip/widgets/day_tab_selector.dart` | Tag-Auswahl fÃ¼r mehrtÃ¤gige Trips (v1.5.7) |
| `lib/features/random_trip/widgets/start_location_picker.dart` | Startpunkt-Eingabe mit Geocoding-Autocomplete + GPS-Fallback + 300ms Debounce-Timer + mounted-Guards (v1.9.28) |
| `lib/features/random_trip/widgets/trip_preview_card.dart` | AI Trip Preview mit POI-Fotos & Navigation (v1.6.9) |
| `lib/features/map/widgets/weather_chip.dart` | Kompakter Wetter-Anzeiger auf MapScreen (v1.7.6) |
| `lib/features/map/widgets/weather_details_sheet.dart` | 7-Tage-Vorhersage Bottom Sheet (v1.7.6, v1.9.10: Vollbild DraggableScrollableSheet 85%) |
| `lib/features/map/widgets/unified_weather_widget.dart` | Intelligentes Wetter-Widget mit Auto-Modus-Wechsel (v1.7.22: startet zugeklappt) |
| `lib/features/journal/journal_screen.dart` | Reisetagebuch-Hauptscreen: Eintraege gruppiert nach Tagen, Header mit Statistiken (Fotos, Eintraege, Tage), FAB zum Hinzufuegen, Entry-Details-Sheet (v1.9.29) |
| `lib/features/journal/widgets/journal_entry_card.dart` | Eintragskarte mit Bild, Zeitstempel-Badge, POI-Name, Notiz-Vorschau (v1.9.29) |
| `lib/features/journal/widgets/add_journal_entry_sheet.dart` | BottomSheet zum Hinzufuegen: Kamera/Galerie Buttons, Notiz-TextField, Standort-Toggle (v1.9.29) |
| `lib/features/sharing/qr_scanner_screen.dart` | QR-Code-Scanner fuer Trip-Import: mobile_scanner Integration, mapab:// + https://mapab.app/trip/ Deep-Link-Parsing, automatische Routen-Berechnung via OSRM (v1.9.30) |
| `lib/features/templates/trip_templates_screen.dart` | Trip-Vorlagen-Auswahl: 12 vordefinierte Reisetypen, Zielgruppen-Filter (Alle/Paare/Familien/etc.), Tage-Stepper, direkte AI-Trip-Generierung (v1.9.30) |
| `lib/features/social/gallery_screen.dart` | Oeffentliche Trip-Galerie: Featured-Trips horizontal, Grid-Ansicht, Filter-Sheet (Vollbild, v1.10.0), Suche, Sortierung (Beliebt/Neueste/Likes), Trip-Typ-Filter, Tags, Infinite Scroll (v1.10.0) + FilterChip/ChoiceChip explizite Textfarben colorScheme.onPrimary/onSurface (v1.10.1) + _FilterSheet ref.watch() statt state-Parameter fuer sofortige Button-Updates (v1.10.7) |
| `lib/features/social/widgets/public_trip_card.dart` | Trip-Karte in Galerie: Thumbnail, Statistiken, Like-Button, Author-Info (v1.10.0) |
| `lib/features/social/trip_detail_public_screen.dart` | Trip-Detail-Ansicht: Route auf Karte, Stops, Author-Profil, Like/Import-Buttons (v1.10.0) + "Auf Karte"-Button zeigt Trip auf Hauptkarte: Route-Parsing aus tripData, POI-Erstellung, tripStateProvider.setRouteAndStops(), Auto-Zoom (v1.10.17) + robuste Stop-Normalisierung (poiId/lat/lng/category/tags), klickbare POI-Vorschau mit korrektem Detail-Linking (v1.10.35) + Highlight-Mapping (highlights -> tags), Must-See-Erkennung und Highlight-Anzeige in POI-Vorschau (v1.10.37) |
| `lib/features/social/widgets/publish_trip_sheet.dart` | Bottom Sheet zum Veroeffentlichen: Name, Beschreibung, Tags, Sichtbarkeit (v1.10.0) + FilterChip-Farben-Fix: explizite labelStyle/selectedColor/backgroundColor/checkmarkColor fuer sichtbare Tag-Buttons (v1.10.16) + Source-POI-Merge aus tripState/randomTrip fuer vollstaendige Publish-Stopdaten (v1.10.35) |
| `lib/features/leaderboard/leaderboard_screen.dart` | Globale Rangliste: 4 Sortieroptionen (XP/km/Trips/Likes), eigene Position immer sichtbar, Gold/Silber/Bronze Badges, Streak-Anzeige, Pagination (v1.10.23) |
| `lib/features/challenges/challenges_screen.dart` | WÃ¶chentliche Challenges: 9 Challenge-Typen, Streak-Karte mit Flammen-Gradient, Fortschrittsbalken, XP-Belohnungen, HIGHLIGHT-Badges, Timer bis Ablauf (v1.10.23) |

### Provider

| Datei | Beschreibung |
|-------|--------------|
| `lib/data/providers/account_provider.dart` | Account State (keepAlive) |
| `lib/data/providers/favorites_provider.dart` | Favoriten State (keepAlive) |
| `lib/data/providers/auth_provider.dart` | Auth State (keepAlive) |
| `lib/features/trip/providers/trip_state_provider.dart` | Trip State (keepAlive) + Auto-Routenberechnung (v1.7.2) + setRouteAndStops (v1.7.10) |
| `lib/features/poi/providers/poi_state_provider.dart` | POI State (keepAlive, v1.5.3 Filter-Fix, v1.7.9 2-Stufen-Batch) + ensurePOIById() fuer on-demand Nachladen und sichere selectPOIById()-Rueckgabe ohne Exception (v1.10.35) |
| `lib/features/map/providers/route_planner_provider.dart` | Route-Planner mit Auto-Zoom (v1.7.0) |
| `lib/features/map/providers/map_controller_provider.dart` | MapController + shouldFitToRoute (v1.7.0) |
| `lib/data/providers/active_trip_provider.dart` | Aktiver Trip Persistenz (keepAlive, v1.7.39) |
| `lib/data/providers/settings_provider.dart` | Settings mit Remember Me |
| `lib/features/random_trip/providers/random_trip_provider.dart` | AI Trip State mit Tages-Auswahl + Wetter-Kategorien + markAsConfirmed + weatherCategoriesApplied + resetWeatherCategories (v1.7.9) + ActiveTrip Persistenz + restoreFromActiveTrip (v1.7.39) + addPOIToDay() fuer Korridor-Browser DayEditor-Integration (v1.9.5+152) + removePOIFromDay() mit Min-1-Stop-Validierung (v1.9.8) + 700km-Fehlermeldung bei TripGenerationException (v1.9.9) + uebergibt Wetter an Trip-Generator fuer gewichtete POI-Auswahl (v1.9.12) + Null-Safety-Guards: startLocation-Check in rerollPOI/removePOI/addPOIToDay/removePOIFromDay (v1.9.22) + Lokale startLocation/startAddress-Capture vor async, generateTrip() Doppel-Aufruf-Guard, Provider-Refresh try-catch (v1.9.28) |
| `lib/features/map/providers/weather_provider.dart` | RouteWeather + LocationWeather + IndoorOnlyFilter (v1.7.6, v1.7.17 keepAlive) + Tages-Vorhersage: loadWeatherForRouteWithForecast, getDayForecast, getForecastPerDay (v1.8.0) + Request-Cancellation via _loadRequestId in loadWeatherForRoute + loadWeatherForRouteWithForecast (v1.9.22) + finally-Block setzt isLoading zurueck bei Request-Cancellation (v1.9.28) |
| `lib/features/trip/providers/corridor_browser_provider.dart` | Korridor-POI-Browser State: loadCorridorPOIs, bufferKm, Kategorie-Filter (v1.8.0) + markAsRemoved() fuer POI-Entfernen (v1.9.8) + Request-Cancellation via _loadRequestId (v1.9.16) + POI-Limit 150 vor compute() Isolate verhindert O(n*m) Explosion (v1.9.17) + setBufferKmLocal (Slider-Debounce), setCategoriesBatch (Indoor-Toggle-Batch), filteredPOIs Lazy-Cache, reset() cancelt laufende Requests, maxResults:150 (v1.9.20) + copyWith() erhaelt _filteredPOIsCache/_newPOICountCache bei nicht-filter-relevanten Updates, verhindert 150-POI-Refilter bei Slider-Drag (v1.9.21) + keepAlive: State bleibt bei Screen-Wechsel erhalten (v1.9.27) + bufferKm-Aenderung invalidiert Cache (v1.9.28) |
| `lib/features/ai/providers/ai_trip_advisor_provider.dart` | AI Trip Advisor: analyzeTrip (regelbasiert) + suggestAlternativesForDay (GPT-4o) (v1.8.0) + loadSmartRecommendations() alle Kategorien + Wetter-Gewichtung + Must-See-Bonus + _calculateSmartScore(), AISuggestion um aiReasoning/relevanceScore erweitert, recommendedPOIsPerDay State (v1.9.8, v1.9.9: Smart statt nur Indoor) + _isIndoor durch POICategory.isIndoor konsolidiert (v1.9.12) + _extractDayRoute() fuer tages-spezifische POI-Suche statt gesamte Route (v1.9.16) + Request-Cancellation + Loading-Safety try/finally (v1.9.16) + Stop-Radius statt Korridor (v1.9.18) + Crash-Fix: Nur Supabase+kuratiert (kein Wikipedia/Overpass), max 3 Suchpunkte 15km, Score>=50 Filter, Must-See/UNESCO/kuratiert Bonus, GPT Top-3 statt Top-5 (v1.9.19) + isLoading-Guard entfernt zugunsten requestId-Cancellation, neue Anfragen canceln alte sauber (v1.9.21) + keepAlive: Empfehlungen bleiben bei Tageswechsel erhalten (v1.9.27) + Alle Strings lokalisiert via _l10n Getter + ServiceL10n.localizedCategoryLabel() (v1.10.3) |
| `lib/features/navigation/providers/navigation_provider.dart` | Navigation State Machine: GPS-Stream (distanceFilter 1m), Route-Matching, Rerouting, POI-Erkennung (keepAlive, v1.9.0) + Doppel-Stream-Guard in startNavigation(), arrivedAtWaypoint Re-Entry Guard, Reroute Null-Check, GPS-Verfuegbarkeits-Pruefung (v1.9.23) + Step-Index-Cache (_stepRouteIndices) eliminiert O(n*m) pro GPS-Tick, gecachter nextStepRouteIndex (v1.9.25) + Foreground-Service-Integration: _startForegroundService, _onBackgroundData GPS-Callback, Benachrichtigungs-Updates (v1.9.29) + gpsDistanceFilter 2mâ†’1m fuer haeufigere Updates (v1.10.20) |
| `lib/features/navigation/providers/navigation_poi_discovery_provider.dart` | Must-See POI-Entdeckung entlang der Route: ref.listen auf GPS-Stream, dismissed/announced Sets, goldene Card + TTS (v1.9.14, keepAlive v1.9.27) |
| `lib/features/navigation/providers/navigation_tts_provider.dart` | TTS-Ansagen: Manoever (500/200/50m), Rerouting, POI-Annaeherung, Ziel erreicht (keepAlive, v1.9.0) + Idle-Guard, VoiceService-Stop in reset() (v1.9.23) + Silent-Catch Logging (v1.9.27) + _l10n Getter via lookupAppLocalizations, VoiceService.setLocale() bei Sprachwechsel, Must-See Announcement lokalisiert (v1.10.3) |
| `lib/data/providers/journal_provider.dart` | Reisetagebuch-State (keepAlive): activeJournal, allJournals, selectedDay, CRUD-Operationen fuer Eintraege und Tagebuecher (v1.9.29) |
| `lib/data/providers/gallery_provider.dart` | Trip-Galerie-State (keepAlive): GalleryNotifier (Trips, Featured, Filter, Suche, Pagination), TripDetailNotifier (Detail-Ansicht, Import), ProfileNotifier, MyProfileNotifier (v1.10.0) |
| `lib/data/providers/leaderboard_provider.dart` | Leaderboard-State (keepAlive): LeaderboardNotifier mit 4 Sortierkriterien (XP/km/Trips/Likes), eigene Position, Pagination (v1.10.23) |
| `lib/data/providers/challenges_provider.dart` | Challenges-State (keepAlive): ChallengesNotifier mit 9 Challenge-Typen, Streak-Tracking, wÃ¶chentliche Challenges, XP-Belohnungen (v1.10.23) |

Details: [Dokumentation/PROVIDER-GUIDE.md](Dokumentation/PROVIDER-GUIDE.md)

### Services

| Datei | Beschreibung |
|-------|--------------|
| `lib/data/services/ai_service.dart` | AI via Backend-Proxy + TripContext mit Standort (v1.7.2) + language-Parameter fuer mehrsprachige AI-Antworten (v1.10.3) |
| `lib/data/services/poi_enrichment_service.dart` | Wikipedia/Wikidata Enrichment + Batch-API + Image Pre-Cache + Session-Tracking (v1.7.9) + Upload-on-Enrich zu Supabase (v1.9.13) + Future.wait-Timeouts: 10s Parallel-Requests, 8s Fallback-Batch, 8s Geo-Batch (v1.9.22) + Individuelle Timeouts pro Request statt globaler Future.wait-Timeout (v1.9.24) + Image-Prefetch Concurrency-Limit _maxConcurrentPrefetches=5 (v1.9.28) |
| `lib/data/services/poi_cache_service.dart` | Hive-basiertes POI Caching |
| `lib/data/services/sync_service.dart` | Cloud-Sync |
| `lib/data/services/active_trip_service.dart` | Persistenz fÃ¼r aktive Trips (v1.5.7, v1.7.39 erweitert: POIs, Konfiguration) |
| `lib/data/services/voice_service.dart` | TTS (dynamisch de-DE/en-US/fr-FR/it-IT/es-ES), Spracherkennung, Navigation-Befehle + speakManeuver, speakRerouting, speakPOIApproaching, speakArrived (v1.9.0) + parseCommand() mit VoiceCommand Enum, listen() mit Partial-Text-Callback fuer Echtzeit-UI (v1.9.29) + setLocale() fuer dynamische TTS/STT-Sprache, mehrsprachige Sprachbefehle via _voiceKeywords Map, alle Ansagen ueber l10n (v1.10.3) + Intelligente Sprachassistentin (v1.10.11): getRandomGreeting() mit 8 BegrÃ¼ÃŸungen, getUnknownCommandResponse() mit 6 humorvollen Antworten, 5 neue VoiceCommands (routeWeather, routeRecommendation, tripOverview, remainingStops, helpCommands) |
| `lib/features/navigation/utils/latlong_converter.dart` | Konvertierung latlong2 <-> maplibre_gl, GeoJSON Builder, Bounds-Berechnung (v1.9.1) + Leere-Liste Guard in boundsFromCoords() (v1.9.23) |
| `lib/features/navigation/services/route_matcher_service.dart` | Snap-to-Road: snapToRoute, isOffRoute, getDistanceAlongRoute, calculateBearing (v1.9.0) |
| `lib/features/navigation/services/position_interpolator.dart` | 60fps Positions-Interpolation: GPS-Updates zu fluessigem Stream, Dead-Reckoning entlang Route (2500ms/80m), Adaptives Bearing-Smoothing (0.2/0.3/0.4 je nach Speed), Predictive Extension bei >80% Fortschritt (v1.9.14, v1.10.18, v1.10.20) |
| `lib/data/services/sharing_service.dart` | Route/Trip Sharing: Deep Links (mapab://), Base64-Encoding, Share-Text-Generierung, QR-Daten, Clipboard |
| `lib/features/sharing/share_trip_sheet.dart` | Share Bottom Sheet: QR-Code + Teilen/Link kopieren/Als Text teilen Buttons |
| `lib/data/services/journal_service.dart` | Reisetagebuch-Persistenz: Hive-basiert, ImagePicker fuer Kamera/Galerie, lokale Bildspeicherung in App-Dokumenten-Verzeichnis (v1.9.29) |
| `lib/features/navigation/services/navigation_foreground_service.dart` | Android Foreground Service fuer Hintergrund-Navigation: GPS-Tracking im Hintergrund, Benachrichtigungs-Steuerung, Service-Lifecycle-Management via flutter_foreground_task (v1.9.29) |

### Daten

| Datei | Beschreibung |
|-------|--------------|
| `lib/data/models/poi.dart` | POI Model (Freezed) |
| `lib/data/models/trip.dart` | Trip Model mit Tages-Helper-Methoden (v1.5.7) + echte Haversine-Distanz pro Tag (v1.8.1) + getStopsForDay sort by order Fix (v1.8.2) + getDistanceForDay Doppelzaehlungs-Fix: kein Outgoing-Segment mehr, letzter Tag nutzt route.end (v1.9.11) |
| `lib/data/models/weather.dart` | Weather + DailyForecast Models (Freezed) mit WMO-Code-Interpretation + condition Getter (v1.8.0) |
| `lib/data/models/navigation_step.dart` | NavigationStep, NavigationLeg, NavigationRoute Models (Freezed) mit ManeuverType/ManeuverModifier Enums (v1.9.0) |
| `lib/data/models/route.dart` | Route Model mit LatLng Converters |
| `lib/data/models/journal_entry.dart` | JournalEntry + TripJournal Models (Freezed): Foto-Eintraege mit Standort, Notiz, POI-Zuordnung, Tag-Gruppierung (v1.9.29) |
| `lib/data/models/trip_template.dart` | TripTemplate Model (Freezed): 12 vordefinierte Reisevorlagen mit id, name, description, emoji, recommendedDays, categories, tags, targetAudience + TripTemplates.all statische Liste + forAudience()/findById() Helper (v1.9.30) |
| `lib/data/models/public_trip.dart` | PublicTrip + UserProfile Models (Freezed): Oeffentliche Trip-Daten mit Author-Info, Statistiken, Like-Status + GallerySortBy/GalleryTripTypeFilter Enums (v1.10.0) |
| `lib/data/models/challenge.dart` | Challenge Model (Freezed): ChallengeType (9 Typen), ChallengeFrequency, UserChallenge, UserStreak + XP-Belohnungen (v1.10.23) |
| `lib/data/repositories/social_repo.dart` | Social Features Repository: loadFeaturedTrips, searchPublicTrips, likeTrip, loadUserProfile, publishTrip, importTrip - Supabase RPC Integration (v1.10.0) + Tabellenname-Fix public_trips->trips (v1.10.1) + POI Publish RPC-Fallback (PGRST202) via Direct-Insert und angereicherte tripData.stops beim Publish (v1.10.35) |
| `lib/data/repositories/leaderboard_repo.dart` | Leaderboard Repository: getLeaderboard() mit Sortierung (XP/km/Trips/Likes), getMyPosition(), Pagination (v1.10.23) |
| `lib/data/repositories/poi_repo.dart` | POI-Laden: Supabase-first Hybrid (PostGIS -> Client-Fallback -> Upload), 3-Layer parallel + Region-Cache + Overpass-Query (v1.7.23) + Kategorie-Inference (v1.7.9) + Supabase PostGIS Integration (v1.9.13) + Kategorisierung-Fix: Stadt-Suffixe, See-Suffix-RegExp, Coast/Bay/Marina, erweiterte Overpass-Queries (v1.9.13) + maxResults-Parameter (default 200) verhindert POI-Explosion bei grossen Bounding-Boxes (v1.9.17) + Future.wait 12s-Timeout in loadPOIsInBounds verhindert ANR bei haengenden APIs (v1.9.21) + Future.wait 12s-Timeout auch in loadPOIsInRadius + loadAllPOIs (v1.9.22) + Individuelle Timeouts pro API-Quelle statt globaler Future.wait-Timeout (v1.9.24) + Wikipedia-Grid 4er-Batches mit 200ms Pause + 8s Timeout + 200-POI-Cap, globaler 20s Future.wait-Timeout (v1.9.28) + minScore-Parameter in Radius/Bounds sowie loadPOIById() (Supabase+curated Fallback) (v1.10.35) |
| `lib/data/repositories/routing_repo.dart` | OSRM Fast/Scenic Routing + calculateNavigationRoute() mit steps=true fuer Turn-by-Turn (v1.9.0) |
| `lib/data/repositories/trip_generator_repo.dart` | Trip-Generierung mit Tage->Radius Berechnung (v1.7.38) + Richtungs-Optimierung + dynamische Tagesanzahl (v1.8.1) + Tag-beschraenkte POI-Bearbeitung bei Multi-Day Trips (v1.8.3) + Post-Validierung 700km Display-Limit (v1.9.5) + addPOIToTrip/addPOIToDay fuer POI-Hinzufuegen im DayEditor (v1.9.5+152) + _addPOIToDay() Exception statt Warning bei >700km, generateEuroTrip() Re-Split (v1.9.9) + Post-Validierung 3-fach Schleife statt einmalig (v1.9.11) + WeatherCondition-Parameter fuer wetter-gewichtete POI-Auswahl via ScoringUtils (v1.9.12) + Hotel-Filter: Hotels aus Tagestrip/EuroTrip POI-Auswahl entfernt (v1.9.13) + lastResult Null-Check statt force-unwrap, Post-Validierung Max-Tage-Cap 2x (v1.9.28) + Daytrip-POI-Rescue-Strategie (strict/relaxed/rescue), erweiterte Endpoint-Radien und tolerantere Korridorfilter (v1.10.35) + Emergency-Fallbacks (minScore 0), groesserer Radius/Buffer-Rescue und robustere Treffer in duennen Regionen (v1.10.37) + Retry-basierte Daytrip-Auswahl, zentrales Routing-Backoff mit erweitertem Single-POI-Rescue und A->B-Endpunkt-Erhalt in remove/add/reroll (v1.10.38) |
| `lib/core/algorithms/route_optimizer.dart` | Nearest-Neighbor + 2-opt TSP + Richtungs-optimierte Aâ†’B Routen (v1.8.1) + 2-opt Skip bei >50 POIs, reduzierte Iterationen 20-50 POIs (v1.9.28) |
| `lib/core/utils/navigation_instruction_generator.dart` | OSRM Maneuver â†’ Lokalisierte Instruktionen mit l10n-Parameter (Abbiegen, Kreisverkehr, Auffahrt, etc.) (v1.9.0, v1.10.3: AppLocalizations l10n Parameter, 35 neue ARB-Keys) |
| `lib/core/algorithms/day_planner.dart` | Distanz-basierte Tagesaufteilung 200-700km/Tag (v1.8.1, vorher 9-POI-Limit v1.5.7) + Display-basiertes Splitting, Merge-Guard, _splitLastDayIfOverLimit (v1.9.5) + _splitOverlimitDays() Safety-Split fuer Tage die trotz Clustering >700km sind (v1.9.11) + Absolute Iterations-Obergrenze min(clusters*2, 50) (v1.9.28) |
| `assets/data/curated_pois.json` | 527 kuratierte POIs |

## API-AbhÃ¤ngigkeiten

| API | Zweck | Auth |
|-----|-------|------|
| Nominatim | Geocoding | - |
| OSRM | Fast Routing | - |
| OpenRouteService | Scenic Routing | API-Key |
| Overpass | POIs & Hotels | - |
| Wikipedia DE | Geosearch + Extracts | - |
| Wikipedia EN | Fallback-Bilder (v1.7.7) | - |
| Wikipedia FR/IT/ES/NL/PL | Multi-Sprach-Fallback (v1.7.27) | - |
| Wikimedia Commons | POI-Bilder | - |
| Wikidata SPARQL | Strukturierte POI-Daten + Geo-Radius (v1.7.27) | - |
| Openverse | CC-Bilder Last-Resort (v1.7.27) | - |
| Open-Meteo | Wetter | - |
| OpenAI | AI-Chat | via Backend-Proxy |
| Supabase | Cloud-DB + Auth | Anon Key |

## Navigation (GoRouter)

```
/splash             â†’ SplashScreen (Auth + Onboarding Check)
/onboarding         â†’ OnboardingScreen (3 animierte Seiten)
/                   â†’ MapScreen (Hauptscreen)
/pois               â†’ POIListScreen
/poi/:id            â†’ POIDetailScreen
/trip               â†’ TripScreen (inkl. AI Trip v1.4.9)
/assistant          â†’ ChatScreen (AI)
/profile            â†’ ProfileScreen
/favorites          â†’ FavoritesScreen
/settings           â†’ SettingsScreen
/search             â†’ SearchScreen
/random-trip        â†’ RandomTripScreen (Legacy, jetzt in /trip integriert)
/navigation         â†’ NavigationScreen (Turn-by-Turn, v1.9.0)
/journal/:tripId    â†’ JournalScreen (Reisetagebuch mit Fotos, v1.9.29)
/scan               â†’ QRScannerScreen (Trip-Import per QR-Code, v1.9.30)
/templates          â†’ TripTemplatesScreen (12 vordefinierte Reisevorlagen, v1.9.30)
/gallery            â†’ GalleryScreen (Oeffentliche Trip-Galerie, v1.10.0)
/gallery/:id        â†’ TripDetailScreen (Trip-Detail mit Import-Option, v1.10.0)
/admin              â†’ AdminScreen (Admin-Dashboard mit Benachrichtigungen und Moderation, v1.10.13)
/leaderboard        â†’ LeaderboardScreen (Globale Rangliste mit 4 Sortieroptionen, v1.10.23)
/challenges         â†’ ChallengesScreen (WÃ¶chentliche Challenges + Streak-System, v1.10.23)
/login              â†’ LoginScreen (Supabase)
/register           â†’ RegisterScreen
/forgot-password    â†’ ForgotPasswordScreen
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
| Dateien | snake_case fÃ¼r Dart-Dateien |
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

### Internationalisierung (i18n)

Die App unterstÃ¼tzt 5 Sprachen mit Flutter's integriertem l10n-System:

**UnterstÃ¼tzte Sprachen:**
| Code | Sprache | Status |
|------|---------|--------|
| `de` | Deutsch | Basis (Template) |
| `en` | English | VollstÃ¤ndig |
| `fr` | FranÃ§ais | VollstÃ¤ndig |
| `it` | Italiano | VollstÃ¤ndig |
| `es` | EspaÃ±ol | VollstÃ¤ndig |

**Dateien:**
| Datei | Beschreibung |
|-------|--------------|
| `lib/l10n/app_de.arb` | Template-ARB (~700 Strings) |
| `lib/l10n/app_en.arb` | Englische Ãœbersetzungen |
| `lib/l10n/app_fr.arb` | FranzÃ¶sische Ãœbersetzungen |
| `lib/l10n/app_it.arb` | Italienische Ãœbersetzungen |
| `lib/l10n/app_es.arb` | Spanische Ãœbersetzungen |
| `lib/core/l10n/l10n.dart` | `context.l10n` Extension |
| `lib/core/l10n/category_l10n.dart` | Enum-Lokalisierung Extensions |
| `l10n.yaml` | Konfiguration fÃ¼r Code-Generierung |

**Verwendung:**

```dart
import '../../core/l10n/l10n.dart';

// Einfache Strings
Text(context.l10n.settingsTitle)

// Plurale
Text(context.l10n.dayCount(3))  // "3 Tage"

// Parameter
Text(context.l10n.feelsLike('18'))  // "GefÃ¼hlt 18Â°"
```

**Enum-Lokalisierung:**

```dart
import '../../core/l10n/category_l10n.dart';

// POI-Kategorien
final label = POICategory.castle.localizedLabel(context);  // "Burg"

// Theme-Modi
final label = AppThemeMode.dark.localizedLabel(context);  // "Dunkel"

// Trip-Typen
final label = TripType.eurotrip.localizedLabel(context);  // "Euro Trip"
```

**Neue Strings hinzufÃ¼gen:**
1. String in `lib/l10n/app_de.arb` hinzufÃ¼gen (mit @-Metadaten fÃ¼r Parameter/Plurale)
2. Ãœbersetzungen in allen anderen ARB-Dateien ergÃ¤nzen
3. `flutter gen-l10n` ausfÃ¼hren
4. Mit `context.l10n.neuerKey` verwenden

**ARB-Key-Konvention:** `bereich_beschreibung` (camelCase)
- `settingsTitle`, `settingsLanguage` (Settings)
- `errorNetwork`, `errorRouteCalculation` (Fehler)
- `categoryMuseum`, `categoryCastle` (POI-Kategorien)
- `tripGenerating`, `tripSave` (Trip)
- `authLoginButton`, `authEmailLabel` (Auth)

**Lokalisierungs-Checkliste fÃ¼r neue Features:**

Bei jedem neuen Feature sicherstellen:

1. **Keine hardcodierten Strings verwenden:**
   ```dart
   // FALSCH
   Text('Speichern')
   const Text('Abbrechen')

   // RICHTIG
   Text(context.l10n.save)
   Text(context.l10n.cancel)
   ```

2. **Import nicht vergessen:**
   ```dart
   import '../../core/l10n/l10n.dart';
   ```

3. **const entfernen bei l10n-Verwendung:**
   ```dart
   // FALSCH - Kompilierungsfehler!
   const Text(context.l10n.save)

   // RICHTIG
   Text(context.l10n.save)
   ```

4. **Neue Keys nach Konvention benennen:**
   - Format: `bereichBeschreibung` (camelCase)
   - Beispiele: `tripSaveRoute`, `navDistance`, `poiNotFound`

5. **ARB-Dateien aktualisieren:**
   - Neue Keys in `app_de.arb` hinzufÃ¼gen (Template)
   - Ãœbersetzungen in EN/FR/IT/ES ergÃ¤nzen
   - `flutter gen-l10n` ausfÃ¼hren

6. **Zentrale Helper nutzen:**
   - GPS-Dialog: `LocationHelper.showGpsDialog(context)`
   - Fehler-Snackbar: `AppSnackbar.showError(context, context.l10n.errorXxx)`

7. **Plurale und Parameter:**
   ```json
   // ARB-Datei
   "dayCount": "{count, plural, =1{1 Tag} other{{count} Tage}}",
   "@dayCount": { "placeholders": { "count": { "type": "int" } } }
   ```
   ```dart
   // Dart-Verwendung
   Text(context.l10n.dayCount(3))  // "3 Tage"
   ```

8. **Statische Listen mit Lokalisierung:**
   ```dart
   // FALSCH - Lokalisierung zur Compile-Zeit nicht mÃ¶glich
   final List<String> items = ['Eins', 'Zwei', 'Drei'];

   // RICHTIG - Methode mit BuildContext
   List<String> getItems(BuildContext context) => [
     context.l10n.itemOne,
     context.l10n.itemTwo,
     context.l10n.itemThree,
   ];
   ```

## Debugging

### Log-Prefixes

| Prefix | Komponente |
|--------|------------|
| `[POI]` | POI-Laden |
| `[POIList]` | POI-Liste Screen (v1.4.6+) |
| `[Enrichment]` | POI Enrichment Service |
| `[POICache]` | Cache Operationen |
| `[POIState]` | POI State Ã„nderungen |
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
| `[RoutePlanner]` | Route-Berechnung & POI-LÃ¶schung |
| `[RouteSession]` | Route-Session Start/Stop |
| `[RandomTrip]` | AI Trip Generierung |
| `[AI-Chat]` | AI Chat Route-Generierung |
| `[GoogleMaps]` | Google Maps Export & URL-Launch |
| `[DayExport]` | Tagesweiser Google Maps Export (v1.5.7) |
| `[ActiveTrip]` | Active Trip Persistenz (v1.5.7) |
| `[Share]` | Route Teilen |
| `[Corridor]` | Korridor-POI-Browser (v1.8.0) |
| `[AIAdvisor]` | AI Trip Advisor Vorschlaege (v1.8.0) |
| `[Navigation]` | In-App Navigation: GPS-Tracking, Route-Matching, Rerouting (v1.9.0) |
| `[NavigationTTS]` | TTS-Manoever-Ansagen (v1.9.0) |
| `[POI-Supabase]` | Supabase PostGIS Queries: Erfolg, Latenz, Anzahl (v1.9.13) |
| `[POI-Fallback]` | Fallback auf Client-APIs ausgeloest (v1.9.13) |
| `[POI-Upload]` | Enrichment-Upload zu Supabase (fire-and-forget) (v1.9.13) |

## Bekannte EinschrÃ¤nkungen

1. **Wikipedia API**: 10km Radius-Limit pro Anfrage
2. **Wikipedia CORS**: Im Web-Modus blockiert (Android/iOS funktioniert)
3. **Wikimedia Rate-Limit**: Max 200 Anfragen/Minute
4. **Overpass API**: Rate-Limiting, kann langsam sein
5. **OpenAI**: BenÃ¶tigt aktives Guthaben
6. **GPS**: Nur mit HTTPS/Release Build zuverlÃ¤ssig; bei deaktiviertem GPS erscheint Dialog (v1.5.4)
7. **AI-Chat**: BenÃ¶tigt `--dart-define=BACKEND_URL=...` (sonst Demo-Modus)
8. **Open-Meteo Vorhersage**: Max 16 Tage â†’ Trips > 7 Tage zeigen nur 7 Tage Vorhersage (v1.8.0)
9. **AI-Vorschlaege**: Backend muss erreichbar sein â†’ Fallback auf regelbasierte Vorschlaege (v1.8.0)
10. **Navigation**: GPS-Stream benoetigt physisches Geraet (Emulator unzuverlaessig), Rerouting benoetigt OSRM-Erreichbarkeit (v1.9.0). Pan-Gesten aktiviert seit v1.9.3, Kamera re-zentriert bei naechstem GPS-Tick
11. **MapLibre GL**: OpenFreeMap Tile-Server muss erreichbar sein fuer 3D-Navigation, Fallback auf flutter_map nicht automatisch (v1.9.1)

## Android-Berechtigungen

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />
```

---

## Dokumentation

### Changelogs

Versionsspezifische Ã„nderungen finden sich in:
- `Dokumentation/CHANGELOG-v1.10.39.md` (AI-POI-Erlebnis erweitert: strukturierte AI-Vorschlaege, klickbare AI-POIs in allen AI-Flaechen, mehr Vorschlaege mit longDescription/Highlights/Fotos, neue Routen `'/ai-assistant'` und `'/pois'`)
- `Dokumentation/CHANGELOG-v1.10.38.md` (AI Tagestrip Routing-Stabilitaet: Retry-Auswahl statt Single-Pass, zentrales Routing-Backoff mit erweitertem Single-POI-Rescue und konsistente A->B-Endpunkte bei remove/add/reroll im Single-Day-Edit-Flow)
- `Dokumentation/CHANGELOG-v1.10.35.md` (Social Publish + POI Preview + Daytrip Stabilisierung: publish_poi_post RPC-Fallback, angereicherte tripData.stops, korrekt verlinkte POI-Vorschau, erweiterte Daytrip-POI-Fallbacks)
- `Dokumentation/CHANGELOG-v1.10.34.md` (AI Tagestrip Stabilisierung: robuste POI-Fallback-Pipeline bei Korridor/Radius, Routing-Safety-Fallback, kontinuierlicher Ladefortschritt 1-100%, Lade-Widget auf Panel-Hoehe)
- `Dokumentation/CHANGELOG-v1.10.27.md` (EuroTrip Routing-Stabilisierung: OSRM-400 Fallback via segmentierte Berechnung, direkter Korridor-Filter statt Bounding-Box-Ausreißer, Vorwärts-POI-Progress ohne Rücksprung, Waypoint-Sanitizing/Downsampling)
- `Dokumentation/CHANGELOG-v1.10.26.md` (EuroTrip Stabilitaet: 700-km-gekoppelte POI-Selektion, segment-sichere Kandidatenwahl, Auto-Tagesreduktion statt Abbruch, Release-Rollout mit neuer APK/QR-Links)
- `Dokumentation/CHANGELOG-v1.10.24.md` (AI Tagestrip Fix: Reiseentfernung wird als echtes Distanzlimit erzwungen; Tagestrip-Radius bleibt beim Moduswechsel erhalten statt Reset auf 100km; 2 Regression-Tests fuer RouteOptimizer)
- `Dokumentation/CHANGELOG-v1.10.25.md` (AI Euro Trip Stabilisierung: 700-km-Hardlimit pro Tag, korrekte Tagesuebergabe Tag N -> Tag N+1, Hotel-Engine mit 20-km-Radius und Rich-Details inkl. Booking-Datum)
- `Dokumentation/CHANGELOG-v1.10.23.md` (Gamification: Leaderboard mit 4 Sortieroptionen, woechentliche Challenges (9 Typen), Streak-System, XP-Belohnungen bis 2000 XP, 20+ neue l10n-Keys)
- `Dokumentation/CHANGELOG-v1.10.22.md` (Routen-Reihenfolge pro Tag umkehrbar (Naechster Stopp/Navigation-Ziel), Start-/Ziel-Buttons blau, persistente Einstellung reverseRouteOrder, 5 neue l10n-Keys)
- `Dokumentation/CHANGELOG-v1.10.21.md` (Trip-Foto-Upload: Cover-Bild beim Veroeffentlichen, Foto-Galerie in Trip-Detail, TripPhoto Freezed-Model, Migration 008 trip_photos, 6 neue l10n-Keys in 5 Sprachen)
- `Dokumentation/CHANGELOG-v1.10.20.md` (FlÃ¼ssigere Navigation: GPS distanceFilter 2mâ†’1m, Dead-Reckoning 2500ms/80m, Adaptives Bearing-Smoothing 0.2/0.3/0.4 je nach Geschwindigkeit, Interval Min 100ms, Predictive Extension bei >80% Fortschritt)
- `Dokumentation/CHANGELOG-v1.10.19.md` (Bottom Sheets Vollbild: Alle 16 modalen Bottom Sheets oeffnen sich jetzt im Vollbild-Modus mit DraggableScrollableSheet, konsistente Handle Bars, useSafeArea, scrollbarer Inhalt)
- `Dokumentation/CHANGELOG-v1.10.18.md` (FlÃ¼ssigere Navigation: Dead-Reckoning entlang der Route bei GPS-Aussetzern, GPS distanceFilter 5mâ†’2m fÃ¼r hÃ¤ufigere Updates, sanfteres Bearing-Smoothing 0.35â†’0.25, schnellere Interval-Anpassung, Route-basierte Vorhersage statt nur Bearing-basiert)
- `Dokumentation/CHANGELOG-v1.10.17.md` (Trip auf Karte anzeigen: "Auf Karte"-Button in Trip-Detail zeigt veroeffentlichte Trips auf Hauptkarte, Route-Parsing aus tripData, POI-Erstellung, tripStateProvider.setRouteAndStops(), Auto-Zoom, 2 neue l10n-Keys)
- `Dokumentation/CHANGELOG-v1.10.16.md` (Trip Veroeffentlichen Button: TextButton.icon "Veroeffentlichen" in DayEditorOverlay AppBar, FilterChip-Farben-Fix im PublishTripSheet fuer sichtbare Tag-Buttons)
- `Dokumentation/CHANGELOG-v1.10.15.md` (Snackbar Auto-Dismiss Fix: "Route gespeichert" Snackbar verschwindet jetzt nach 500ms automatisch, SnackBarAction entfernt, SnackBarBehavior.floating hinzugefuegt)
- `Dokumentation/CHANGELOG-v1.10.14.md` (Trip-Galerie & Foto-Upload Fix: loadFeaturedTrips FK-Fehler behoben durch RPC statt direkte Query, upload_photo_sheet.dart erstellt, onAddPhoto Callback in POIPhotoGallery integriert, POI-Foto-Upload-Button jetzt sichtbar)
- `Dokumentation/CHANGELOG-v1.10.13.md` (POI Social Features: Foto-Upload zu POIs, 1-5 Sterne Bewertungen mit Hilfreich-Voting, Kommentare auf POIs und Trips, Admin-Dashboard mit Benachrichtigungen und Moderation, 70+ neue ARB-Keys in 5 Sprachen)
- `Dokumentation/CHANGELOG-v1.10.12.md` (Navigation UI-Redesign: Speichern-Button oben rechts im blauen ManeuverBanner, Beenden-Button quadratisch wie andere Buttons, alle 4 Buttons gleichmaessig verteilt mit spaceEvenly, Sprechblase von bottom:180 nach top:140 verschoben)
- `Dokumentation/CHANGELOG-v1.10.11.md` (Intelligente Sprachassistentin: Zufaellige Begruessungen beim Sprachbutton-Klick (8 Varianten), 5 neue Sprachbefehle (Wetter, Empfehlungen, Route-Uebersicht, verbleibende Stopps, Hilfe), humorvolle Fehlerantworten bei unbekannten Befehlen (6 Varianten), mehrsprachige Keywords fuer alle 5 Sprachen, 30+ neue ARB-Keys)
- `Dokumentation/CHANGELOG-v1.10.10.md` (Gamification-System: XP-Punkte + Level-System + 21 Achievements in 5 Kategorien, XP-Toasts, Level-Up-Dialoge, Achievement-Popups, GamificationOverlay, AchievementCard Widget, 15 neue ARB-Keys)
- `Dokumentation/CHANGELOG-v1.10.9.md` (Social Features DB-Fix & Route-Speichern-Buttons: TripSaveHelper Utility-Klasse fuer konsistentes Speichern, Route-Speichern-Button in DayEditorOverlay AppBar und NavigationBottomBar, Supabase Migration 006 Social Features RESET loescht alte Tabellen und erstellt vollstaendige Social-Struktur)
- `Dokumentation/CHANGELOG-v1.10.8.md` (Favoriten-Navigation & Speichern-UX: Dominanter FilledButton.tonalIcon Speichern-Button, Snackbar-Meldung entfernt, Navigation starten Button bei geladener Route aus Favoriten statt Ueberrasch mich)
- `Dokumentation/CHANGELOG-v1.10.7.md` (Filter-Modal Fix: Trip-Galerie Filter-Buttons reagieren sofort auf Auswahl, _FilterSheet holt State via ref.watch() statt als Parameter)
- `Dokumentation/CHANGELOG-v1.10.6.md` (Route Speichern Button Fix: AppBar Button fuer AI Trips erweitert, Button wird jetzt auch bei RandomTripStep.preview und confirmed angezeigt, ruft _saveAITrip() statt _saveRoute() auf)
- `Dokumentation/CHANGELOG-v1.10.5.md` (AI Euro Trip Crash-Fix Enrichment Safety: Fire-and-forget async mit runZonedGuarded abgesichert, Sub-Batching mit max 10 POIs pro Batch bei Euro Trips)
- `Dokumentation/CHANGELOG-v1.10.4.md` (AI Euro Trip Crash-Fix: ConcurrentModificationException in _flushPendingEnrichments() behoben durch Map-Kopie vor Iteration, Debouncer Race Condition in enrichPOIsBatch() behoben durch _enrichmentBatchActive Flag, Thread-Safety fuer POI-Enrichment)
- `Dokumentation/CHANGELOG-v1.10.3.md` (Vollstaendige Lokalisierung: Navigation Instructions mit l10n-Parameter, Voice Service dynamische TTS/STT-Sprache + mehrsprachige Sprachbefehle, AI Chat komplett lokalisiert, AI Trip Advisor lokalisiert, AI Service language-Parameter, 100+ neue ARB-Keys in allen 5 Sprachen, Gallery DB-Fix public_trips)
- `Dokumentation/CHANGELOG-v1.10.2.md` (MapScreen Lokalisierung: AI Tagestrip/Euro Trip Buttons, Trip-Config-Panel komplett lokalisiert, 13 neue ARB-Keys in allen 5 Sprachen)
- `Dokumentation/CHANGELOG-v1.10.1.md` (Galerie-Bugfix: Tabellenname public_tripsâ†’trips in social_repo.dart, FilterChip/ChoiceChip Textfarben mit explizitem colorScheme.onPrimary/onSurface, Filter-Sheet Vollbild-Modus)
- `Dokumentation/CHANGELOG-v1.10.0.md` (Social Features Release: Oeffentliche Trip-Galerie, Trips liken und importieren, Eigene Trips veroeffentlichen, Featured-Trips, Supabase Backend, Filter-Sheet Vollbild-Fix)
- `Dokumentation/CHANGELOG-v1.9.32.md` (Vollstaendige Lokalisierung: 5 Sprachen DE/EN/FR/IT/ES, ~700 ARB-Keys, 202+ hardcodierte Strings ersetzt, GPS-Dialog in LocationHelper zentralisiert mit l10n, Lokalisierungs-Checkliste in CLAUDE.md)
- `Dokumentation/CHANGELOG-v1.9.31.md` (Euro Trip Crash-Fix: Unendliche Rekursion in _markAttemptedWithoutPhoto() behoben (StackOverflow), Weather API Timeouts 15s/30s hinzugefuegt, Atomares _isGenerating Lock gegen Race Condition bei Doppel-Klick)
- `Dokumentation/CHANGELOG-v1.9.30.md` (Trip-Templates & QR-Scanner: 12 vordefinierte Reisevorlagen (Romantik, Kultur, Natur, Familie, Stadt, Abenteuer, Strand, Burgen, Wellness, Kulinarik, Foto, Schnell), QR-Code-Scanner fuer Trip-Import via mobile_scanner, Deep-Link-Parsing mapab:// + https://mapab.app/trip/, Zielgruppen-Filter, Template-Auswahl-UI)
- `Dokumentation/CHANGELOG-v1.9.28.md` (Euro Trip Crash-Fix: 22 Fixes in 7 Phasen - Null-Safety-Guards startLocation/lastResult, Listener-Lifecycle MapScreen/MapView/DayEditor, Race-Condition generateTrip Guard, Performance Wikipedia-Batching/2-opt-Cap/Prefetch-Limit, Weather isLoading finally-Block, Post-Validierungs-Loop Max-Tage-Cap, Slider/Geocoding-Debounce, Corridor-Cache-Invalidierung)
- `Dokumentation/CHANGELOG-v1.9.27.md` (Sicherheit, Refactoring & Code-Qualitaet: 7-Phasen-Verbesserung mit Security-Hardening, Dead-Code-Bereinigung, GPS-Konsolidierung zu LocationHelper, 298 Tests, 235x withOpacityâ†’withValues Migration, Dark-Mode-Fixes, analysis_options.yaml Lint-Regeln, 3 Provider keepAlive, 3 Features: Zwischenstopp auf Karte, POI-Teilen via share_plus, Route-Optimierung via RouteOptimizer)
- `Dokumentation/CHANGELOG-v1.9.25.md` (Navigation Performance-Fix: Step-Index-Cache _stepRouteIndices eliminiert O(n*m) pro GPS-Tick in _findCurrentStep, gecachter nextStepRouteIndex eliminiert redundanten findNearestIndex, Route/POI-Map-Updates nur bei tatsaechlicher Aenderung statt jedem build(), moveCamera statt animateCamera verhindert Animation-Stacking bei 60fps, POI-Discovery 500ms Throttle)
- `Dokumentation/CHANGELOG-v1.9.24.md` (POI-Laden Hotfix: Individuelle Timeouts pro API-Quelle in poi_repo.dart loadPOIsInRadius/loadPOIsInBounds/loadAllPOIs und poi_enrichment_service.dart, verhindert Ergebnisverlust bei einzelnem API-Timeout z.B. Overpass 504)
- `Dokumentation/CHANGELOG-v1.9.23.md` (Navigation Stabilitaets-Release: GPS-Stream-Leak-Fix mit Stop-before-Start Guard, MapController-Race-Fix via lokale Variable in 60fps Callback, vollstaendiges dispose() mit Provider-Cleanup, PositionInterpolator _isDisposed Safety, arrivedAtWaypoint Re-Entry Guard, Reroute Null-Check, GPS-Verfuegbarkeits-Pruefung, Arrival-Dialog _arrivalDialogShown Flag, context.mounted Guards in Dialogen, TTS Idle-Guard + VoiceService-Stop, Leere-Liste Bounds Guard, DayEditor Waypoints + context.mounted)
- `Dokumentation/CHANGELOG-v1.9.22.md` (Stabilitaets-Release: Future.wait 12s-Timeout in loadPOIsInRadius + loadAllPOIs, Enrichment-Timeouts 10s/8s, Null-Safety-Guards in rerollPOI/removePOI/addPOIToDay/removePOIFromDay, context.mounted bei doppeltem Navigator.pop im DayEditor, mounted-Checks nach async GPS-Ops im MapScreen, Weather-Provider Request-Cancellation via _loadRequestId, Navigation-Screen mounted-Check im 60fps Interpolation-Callback)
- `Dokumentation/CHANGELOG-v1.9.21.md` (Korridor-Browser ANR-Fix: copyWith() erhaelt _filteredPOIsCache bei nicht-filter-relevanten Updates, Wetter-Sortier-Cache mit identical()-Check, Weather-Watch Deduplizierung einmal in build(), ValueKey(poi.id) auf CompactPOICard, Future.wait 12s-Timeout in loadPOIsInBounds, AI-Advisor isLoading-Guard entfernt zugunsten requestId-Cancellation, newPOICount lazy cached)
- `Dokumentation/CHANGELOG-v1.9.20.md` (Korridor-Browser Performance-Fix: Slider-Debounce setBufferKmLocal/onChangeEnd, Indoor-Toggle setCategoriesBatch statt Loop, dispose() mit reset() cancelt laufende Requests, filteredPOIs Lazy-Cache, maxResults:150 an loadPOIsInBounds)
- `Dokumentation/CHANGELOG-v1.9.19.md` (Must-See AI-Empfehlungen Crash-Fix: Nur Supabase+kuratierte POIs kein Wikipedia/Overpass, max 3 Suchpunkte 15km, Score>=50 Filter, Must-See+40/UNESCO+20/kuratiert+15 Bonus, GPT Top-3 statt Top-5, Kandidaten 25 statt 50)
- `Dokumentation/CHANGELOG-v1.9.18.md` (Stop-Radius AI-Empfehlungen: POI-Suche im 20km Umkreis jedes Stops statt Korridor, parallele Future.wait, _StopCandidate mit nearestStop/distanceKm, Deduplizierung, Naehe-Bonus in SmartScore, ortsspezifisches GPT-Ranking mit Stop-Zuordnung)
- `Dokumentation/CHANGELOG-v1.9.17.md` (POI-Empfehlungen Performance Fix v2: maxResults=200 in poi_repo, Compute-Limit 150 POIs im Isolate, Buffer 50â†’25km, echtes TimeoutException statt stilles onTimeout, Kandidaten-Limit 50 vor Smart-Scoring)
- `Dokumentation/CHANGELOG-v1.9.16.md` (POI-Empfehlungen Crash Fix v1: Tages-Route-Extraktion _extractDayRoute(), Request-Cancellation _loadRequestId, Loading-Safety try/finally)
- `Dokumentation/CHANGELOG-v1.9.14.md` (Fluessige Navigation: 60fps Positions-Interpolation, Must-See POI Entdeckung mit goldener Card + TTS, Staedte/Seen/Kuesten-Erkennung)
- `Dokumentation/CHANGELOG-v1.9.13.md` (Supabase PostGIS POI-Backend + Kategorisierung-Fix: Stadt-Suffixe/-Keywords, See-Suffix-RegExp statt false-positive "see", Coast Bay/Marina/Fjord, erweiterte Overpass-Queries mit relation + reservoir, Hotel-Filter fuer Tagestrips)
- `Dokumentation/CHANGELOG-v1.9.12.md` (Wetter-POI-Integration: WeatherPOIUtils + WeatherBadgeUnified, Wetter-Badges/Sortierung/Indoor-Chips auf allen Screens, Auto-Trigger AI bei schlechtem Wetter, wetter-gewichtete Trip-Generierung, 3x duplizierte Indoor-Logik konsolidiert)
- `Dokumentation/CHANGELOG-v1.9.11.md` (Tagesdistanz-Fix: getDistanceForDay Doppelzaehlung behoben, DayPlanner _splitOverlimitDays Safety-Split, generateEuroTrip 3-fach Post-Validierung)
- `Dokumentation/CHANGELOG-v1.9.10.md` (Wetter-Details Vollbild-Sheet: DraggableScrollableSheet 85%, scrollbarer Inhalt, fixierter Header, nicht mehr von Bottom Navigation abgeschnitten)
- `Dokumentation/CHANGELOG-v1.9.9.md` (Smart AI-Empfehlungen: Alle Kategorien + Must-See + Wetter-Gewichtung, MiniMap Vorschau-Marker, wetterunabhaengiger Empfehlungen-Button, 700km-Tageslimit hart durchgesetzt)
- `Dokumentation/CHANGELOG-v1.9.8.md` (AI-POI-Empfehlungen: GPT-4o Indoor-Ranking + actionable POI-Karten im DayEditor, POI-Entfernen im Korridor-Browser mit Bestaetigungs-Dialog)
- `Dokumentation/CHANGELOG-v1.9.7.md` (Korridor-Browser Inline-Integration: MiniMap+Stats fixiert oben, CorridorBrowserContent extrahiert, Modal-Sheet durch Layout-Toggle ersetzt, Auto-Close bei Tageswechsel)
- `Dokumentation/CHANGELOG-v1.9.6.md` (Korridor-Browser Echtzeit-Vorschau: Partial-Height 55% im DayEditor, MiniMap bleibt sichtbar, Fahrzeit-Chip in DayStats, robusterer MiniMap ValueKey)
- `Dokumentation/CHANGELOG-v1.9.5.md` (700km Tageslimit: Display-basiertes Splitting, Rueckkehr-Segment, Merge-Guard, Post-Validierung)
- `Dokumentation/CHANGELOG-v1.9.4.md` (DayEditor Button-Redesign: Dominanter Navigation-Button, Route Teilen, 3-Ebenen Column-Layout, Google Maps als OutlinedButton)
- `Dokumentation/CHANGELOG-v1.9.3.md` (Navigation-Fix: Nativer MapLibre User-Position Circle statt Flutter Center-Widget, Pan-Gesten aktiviert, kein Zoom-Versatz mehr)
- `Dokumentation/CHANGELOG-v1.9.2.md` (Standort-Marker Fix: Scroll/Rotate-Gesten im Navigations-Modus deaktiviert, Kamera nur per GPS gesteuert)
- `Dokumentation/CHANGELOG-v1.9.1.md` (3D Navigation: MapLibre GL mit Pitch/Tilt, OpenFreeMap Vektor-Tiles, GeoJSON Route-Rendering)
- `Dokumentation/CHANGELOG-v1.9.0.md` (OSRM In-App Navigation: Turn-by-Turn, GPS-Tracking, TTS-Sprachansagen, Rerouting, POI-Waypoints, DayEditor tagesspezifische Navigation)
- `Dokumentation/CHANGELOG-v1.8.3.md` (Tag-Editor Fix: POI Reroll/Delete aendert nur betroffenen Tag, Folgetage bleiben erhalten, schnellere Tag-Bearbeitung)
- `Dokumentation/CHANGELOG-v1.8.2.md` (Google Maps Export-Fix: getStopsForDay sort by order, Distanz-Anzeige mit Destination-Segment + Faktor 1.35, MiniMap ValueKey bei Tageswechsel)
- `Dokumentation/CHANGELOG-v1.8.1.md` (Richtungs-optimierte Routen, Distanz-basierte Tagesaufteilung 200-700km/Tag, Auto-Zoom bei Tageswechsel, Ziel-BottomSheet Fix)
- `Dokumentation/CHANGELOG-v1.8.0.md` (Tages-Wettervorhersage, AI Indoor/Outdoor-Vorschlaege, Korridor-POI-Browser, Wetter-Badges)
- `Dokumentation/CHANGELOG-v1.7.40.md` (Tagesweise Karten-Anzeige, Export-Snackbar entfernt, Google Maps Hinweis)
- `Dokumentation/CHANGELOG-v1.7.39.md` (Aktiver Trip Persistenz: Resume-Banner, Ãœberschreib-Dialog, Abschluss-Dialog)
- `Dokumentation/CHANGELOG-v1.7.38.md` (Euro Trip: Tage statt Radius als primÃ¤rer Input, Quick-Select 2/4/7/10 Tage)
- `Dokumentation/CHANGELOG-v1.7.37.md` (AppBar-Fix: Buttons nicht mehr verdeckt + Panel-Kompaktierung + GPS-Fix)
- `Dokumentation/CHANGELOG-v1.7.34.md` (MehrtÃ¤giger Google Maps Export Fix: day-Feld bei removePOI/rerollPOI/Favoriten)
- `Dokumentation/CHANGELOG-v1.7.27.md` (POI-Foto-Optimierung: 6 neue Bildquellen, ~100% Trefferquote + Kategorie-Modal Live-Update Fix)
- `Dokumentation/CHANGELOG-v1.7.26.md` (Kategorie-Chips Konsistenz + Route-LÃ¶schen-Button Fix im AI Trip Panel)
- `Dokumentation/CHANGELOG-v1.7.24.md` (POI-Filter Chip Feedback - Konsistentes Rendering, 100ms Animation, Schatten)
- `Dokumentation/CHANGELOG-v1.7.23.md` (POI-Kategorien-Filter - Alle Kategorien, Overpass erweitert, Chip-Feedback)
- `Dokumentation/CHANGELOG-v1.7.22.md` (UI-Feinschliff - AbstÃ¤nde & Wetter-Widget Default)
- `Dokumentation/CHANGELOG-v1.7.21.md` (Unified Panel Design - Beide Modi scrollbar)
- `Dokumentation/CHANGELOG-v1.2.x.md`
- `Dokumentation/CHANGELOG-v1.3.x.md`
- `Dokumentation/CHANGELOG-v1.3.4.md` (Route LÃ¶schen Feature)
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
- `Dokumentation/CHANGELOG-v1.4.7.md` (Erweiterter Radius fÃ¼r AI-Trips)
- `Dokumentation/CHANGELOG-v1.4.8.md` (Integrierter Trip-Planer UI)
- `Dokumentation/CHANGELOG-v1.4.9.md` (AI Trip Navigation Fix)
- `Dokumentation/CHANGELOG-v1.5.0.md` (AI Trip direkt auf MapScreen)
- `Dokumentation/CHANGELOG-v1.5.1.md` (POI-Liste Race Condition Bugfix)
- `Dokumentation/CHANGELOG-v1.5.2.md` (POI-Liste Filter & Debug Fix)
- `Dokumentation/CHANGELOG-v1.5.3.md` (POI-Liste & Foto-Fix)
- `Dokumentation/CHANGELOG-v1.5.4.md` (GPS-Dialog statt MÃ¼nchen-Fallback)
- `Dokumentation/CHANGELOG-v1.5.5.md` (POI-Card Layout-Fix)
- `Dokumentation/CHANGELOG-v1.5.6.md` (Floating Buttons bei AI Trip ausblenden)
- `Dokumentation/CHANGELOG-v1.5.7.md` (MehrtÃ¤gige Euro Trips mit tagesweisem Google Maps Export)
- `Dokumentation/CHANGELOG-v1.5.8.md` (Login-Screen Fix: Formular immer sichtbar)
- `Dokumentation/CHANGELOG-v1.5.9.md` (GPS-Teststandort MÃ¼nchen entfernt)
- `Dokumentation/CHANGELOG-v1.6.0.md` (POI-Fotos Lazy-Loading - Alle Bilder werden jetzt geladen)
- `Dokumentation/CHANGELOG-v1.6.1.md` (POI-Marker Direktnavigation - Details sofort Ã¶ffnen)
- `Dokumentation/CHANGELOG-v1.6.2.md` (Euro Trip Performance-Fix - Grid-Suche optimiert)
- `Dokumentation/CHANGELOG-v1.6.3.md` (Euro Trip Route-Anzeige Fix - Route erscheint auf Karte)
- `Dokumentation/CHANGELOG-v1.6.4.md` (POI HinzufÃ¼gen ohne Snackbar)
- `Dokumentation/CHANGELOG-v1.6.5.md` (TripScreen vereinfacht - nur berechnete Routen)
- `Dokumentation/CHANGELOG-v1.6.6.md` (POI-Foto CORS & Rate-Limit Fix)
- `Dokumentation/CHANGELOG-v1.6.7.md` (POI-Detail Fotos & Highlights Fix)
- `Dokumentation/CHANGELOG-v1.6.8.md` (GPS-Dialog & LÃ¶schbutton & POI-Details Fix)
- `Dokumentation/CHANGELOG-v1.6.9.md` (POI-Fotos Ã¼berall - Favoriten, Trip-Stops, AI Trip Preview)
- `Dokumentation/CHANGELOG-v1.7.0.md` (Auto-Zoom auf Route & Route Starten Button)
- `Dokumentation/CHANGELOG-v1.7.1.md` (Auto-Zoom Verbesserung - MapController-Timing-Fix)
- `Dokumentation/CHANGELOG-v1.7.2.md` (AI-Chat mit standortbasierten POI-VorschlÃ¤gen)
- `Dokumentation/CHANGELOG-v1.7.3.md` (POI-Foto Batch-Enrichment - 7x schneller)
- `Dokumentation/CHANGELOG-v1.7.5.md` (Route LÃ¶schen Button fÃ¼r AI-Chat Routen)
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
- `Dokumentation/CHANGELOG-v1.7.22.md` (UI-Feinschliff - AbstÃ¤nde & Wetter-Widget Default)
- `Dokumentation/CHANGELOG-v1.7.24.md` (POI-Filter Chip Feedback - Konsistentes Rendering, Schatten)
- `Dokumentation/CHANGELOG-v1.7.26.md` (Kategorie-Chips Konsistenz + Route-LÃ¶schen-Button Fix)
- `Dokumentation/CHANGELOG-v1.7.27.md` (POI-Foto-Optimierung: 6 neue Bildquellen + Kategorie-Modal Live-Update Fix)

---

## Quick Reference

### Trip-Konstanten (v1.5.7+, v1.7.38+, v1.8.1+)

```dart
import '../../core/constants/trip_constants.dart';

// Google Maps Waypoint Limit
TripConstants.maxPoisPerDay;  // 9

// Kilometer pro Reisetag (fuer Radius-Berechnung)
TripConstants.kmPerDay;  // 600.0

// Tage aus Distanz berechnen
final days = TripConstants.calculateDaysFromDistance(1800);  // 3

// Radius aus Tagen berechnen
final radius = TripConstants.calculateRadiusFromDays(3);  // 1800.0

// Euro Trip Tage-Konstanten (v1.7.38)
TripConstants.euroTripQuickSelectDays;  // [2, 4, 7, 10]
TripConstants.euroTripMinDays;          // 1
TripConstants.euroTripMaxDays;          // 14
TripConstants.euroTripDefaultDays;      // 3

// Distanz-basierte Tagesaufteilung (v1.8.1)
// Haversine-Werte (~30% kuerzer als echte Fahrstrecke)
TripConstants.minKmPerDay;    // 150.0  (~200km real)
TripConstants.maxKmPerDay;    // 500.0  (~700km real)
TripConstants.idealKmPerDay;  // 350.0  (~450km real)

// 700km Tageslimit (v1.9.5)
TripConstants.maxDisplayKmPerDay;         // 700.0 (absolute Obergrenze Anzeige)
TripConstants.maxHaversineKmForDisplay;   // ~518.5 (700 / 1.35)
TripConstants.haversineToDisplayFactor;   // 1.35
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
- âœ… Alle Elemente: `padding: EdgeInsets.all(12)`
- âœ… Divider zwischen Sections: `height: 1, opacity: 0.2`
- âœ… Buttons: Volle Breite mit `SizedBox(width: double.infinity)`
- âœ… SearchBar: `showContainer: false` im Panel
- âœ… 12px Abstand zwischen Mode-Toggle und Panel (v1.7.22)
- âœ… Wetter-Widget startet zugeklappt (v1.7.22)
- âœ… Route-LÃ¶schen-Button INNERHALB des scrollbaren Panels (v1.7.26, nicht extern in Column)

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

// PrÃ¼fen ob Warnung angezeigt werden soll
if (weatherState.showWarning) {
  // danger oder bad mit hoher Niederschlagswahrscheinlichkeit
}

// Wetter-Details-Sheet Ã¶ffnen (v1.9.10: Vollbild DraggableScrollableSheet 85%)
// Sheet ist ziehbar (50%-95%), Header fixiert, Inhalt scrollbar
showWeatherDetailsSheet(
  context,
  weather: weatherState.weather!,
  locationName: 'Mein Standort',
);

// AI Trip: Wetter-basierte Kategorien anwenden
ref.read(randomTripNotifierProvider.notifier)
    .applyWeatherBasedCategories(weatherState.condition);

// AI Trip: Wetter-Kategorien zurÃ¼cksetzen (v1.7.9 - Toggle)
ref.read(randomTripNotifierProvider.notifier)
    .resetWeatherCategories();

// PrÃ¼fen ob Wetter-Kategorien aktiv angewendet sind (v1.7.8)
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
  isIndoorPOI: poi.isIndoor,                // FÃ¼r Badge-Logik
);
```

**Wetter-ZustÃ¤nde:**

| WeatherCondition | Beschreibung | Empfehlung |
|------------------|--------------|------------|
| `good` | Sonnig, klar | Outdoor-POIs (grÃ¼n) |
| `mixed` | Wechselhaft, bewÃ¶lkt | Flexibel planen (gelb) |
| `bad` | Regen, Nebel | Indoor-POIs empfohlen (orange) |
| `danger` | Gewitter, Sturm, Schnee | Nur Indoor! (rot) |
| `unknown` | Keine Daten | - |

**Wetter-Widgets:**

| Widget | Verwendung |
|--------|------------|
| `WeatherChip` | Kompakter Anzeiger auf MapScreen |
| `WeatherAlertBanner` | Proaktive Warnung bei schlechtem Wetter |
| `WeatherRecommendationBanner` | Wetter-Empfehlung auf Hauptseite mit Toggle, opaker Hintergrund (Schnell + AI Trip, v1.7.9) |
| `WeatherDetailsSheet` | 7-Tage-Vorhersage Vollbild-Sheet (v1.9.10: DraggableScrollableSheet 85%) |
| `WeatherBadge` | Empfehlungs-Badge auf POI-Karten (Listen) |
| `POIMarker` (weather) | Mini-Wetter-Badge auf POI-Markern auf der Karte (v1.7.9) |
| `WeatherBar` | Routen-Wetter mit 5 Punkten |
| `RouteWeatherMarker` | Wetter-Marker auf Route mit Icon + Temperatur + Tap-Detail (v1.7.12) |
| `WeatherBadgeUnified` | Einheitliches Wetter-Badge in 3 Groessen (compact/inline/mini), ersetzt _WeatherBadgeInline + WeatherBadge + Inline-Badges (v1.9.12) |
| `_AISuggestionsSection` | AI-Vorschlaege-Liste im DayEditorOverlay (v1.8.0) |
| `CorridorBrowserSheet` | Bottom Sheet mit POIs entlang der Route + Filter + Indoor-Chip + Wetter-Sortierung (v1.8.0, v1.9.12) |
| `CompactPOICard` | Kompakte POI-Karte fuer Korridor-Browser + Wetter-Badge (v1.8.0, v1.9.12) |

### Persistente Wetter-Widgets (v1.7.17)

**Problem behoben:** Wetter-Widgets verschwanden bei Navigation zwischen Screens.

**LÃ¶sung:** `keepAlive: true` fÃ¼r Weather Provider:
```dart
@Riverpod(keepAlive: true)
class RouteWeatherNotifier extends _$RouteWeatherNotifier { ... }

@Riverpod(keepAlive: true)
class LocationWeatherNotifier extends _$LocationWeatherNotifier { ... }
```

**Ergebnis:**
- State bleibt Ã¼ber gesamte App-Session erhalten
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
// Mit keepAlive (fÃ¼r persistente States)
@Riverpod(keepAlive: true)
class MyNotifier extends _$MyNotifier {
  @override
  Future<MyState> build() async { ... }
}

// Ohne keepAlive (fÃ¼r temporÃ¤re States)
@riverpod
class MyNotifier extends _$MyNotifier { ... }
```

Dann: `flutter pub run build_runner build`

### POI zu Favoriten hinzufÃ¼gen

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

// PrÃ¼fen ob Route bereits gespeichert
final isSaved = ref.read(isRouteSavedProvider(tripId));

// Route aus Favoriten entfernen
await ref.read(favoritesNotifierProvider.notifier).removeRoute(tripId);
```

### Gespeicherte Route laden (v1.7.10)

```dart
// State zurÃ¼cksetzen
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

### Stops hinzufÃ¼gen/entfernen mit Auto-Neuberechnung (v1.7.4+)

```dart
// Stop hinzufÃ¼gen MIT Auto-Route (v1.7.4)
// Wenn keine Route existiert: GPS â†’ POI Route wird automatisch erstellt
final result = await ref.read(tripStateProvider.notifier).addStopWithAutoRoute(poi);

if (result.success) {
  if (result.routeCreated) {
    // Neue Route wurde erstellt (GPS â†’ POI)
    context.go('/trip');
  }
  // Sonst: Stop wurde zu bestehender Route hinzugefÃ¼gt
} else if (result.isGpsDisabled) {
  // GPS-Dialog anzeigen
}

// Stop zu AI Trip hinzufÃ¼gen (v1.7.8)
// Wenn ein AI Trip aktiv ist (Preview oder Confirmed), wird die AI-Route Ã¼bernommen
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

// Stop hinzufÃ¼gen OHNE Auto-Route (klassisch)
ref.read(tripStateProvider.notifier).addStop(poi);

// Stop entfernen - Route wird automatisch neu berechnet
ref.read(tripStateProvider.notifier).removeStop(poiId);

// Stops neu ordnen - Route wird automatisch neu berechnet
ref.read(tripStateProvider.notifier).reorderStops(oldIndex, newIndex);

// PrÃ¼fen ob Route gerade neu berechnet wird
final isRecalculating = ref.watch(tripStateProvider).isRecalculating;

// WICHTIG: Bei Stop-Ã„nderungen wird OSRM mit Waypoints aufgerufen
// â†’ Echte Distanz (km) und Fahrzeit werden aktualisiert
```

### Route lÃ¶schen (v1.3.4+)

```dart
// Einzeln lÃ¶schen (Start oder Ziel)
ref.read(routePlannerProvider.notifier).clearStart();
ref.read(routePlannerProvider.notifier).clearEnd();

// Komplett lÃ¶schen (Start + Ziel + Route + Trip-State + POIs)
ref.read(routePlannerProvider.notifier).clearRoute();
```

### POIs lÃ¶schen (v1.3.5+)

```dart
// Alle POIs manuell lÃ¶schen
ref.read(pOIStateNotifierProvider.notifier).clearPOIs();

// Route-Session stoppen (lÃ¶scht auch POIs und Wetter)
ref.read(routeSessionProvider.notifier).stopRoute();

// HINWEIS: POIs und Trip-Stops werden automatisch gelÃ¶scht bei:
// - Neuer Route-Berechnung (routePlannerProvider._tryCalculateRoute) - v1.4.2+
// - Route lÃ¶schen (routePlannerProvider.clearRoute)
// - AI Trip bestÃ¤tigen (randomTripProvider.confirmTrip)
// - AI Chat Route generieren (ChatScreen._generateRandomTripFromLocation)
```

### POI enrichen

```dart
// Einzelner POI
ref.read(pOIStateNotifierProvider.notifier).enrichPOI(poiId);

// Batch-Enrichment fÃ¼r mehrere POIs (v1.7.3 - 7x schneller, v1.7.9 - 2-Stufen-UI)
// Fotos erscheinen inkrementell: Cache â†’ Wikipedia â†’ Wikimedia Fallback
ref.read(pOIStateNotifierProvider.notifier).enrichPOIsBatch(poisList);

// WICHTIG v1.7.9: POIs ohne Foto werden NICHT mehr als isEnriched markiert
// â†’ Retry bei nÃ¤chster Session mÃ¶glich
// â†’ Session-Set (_sessionAttemptedWithoutPhoto) verhindert Endlosschleifen
```

### POI zum State hinzufÃ¼gen (v1.6.9+)

```dart
// POI manuell zum State hinzufÃ¼gen (fÃ¼r POI-Details-Navigation)
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

### Cloud-Sync Status prÃ¼fen

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

// Credentials lÃ¶schen
await settingsNotifier.clearCredentials();

// PrÃ¼fen ob Credentials gespeichert sind
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
// - aiTrip: Zeigt AI Trip Panel Ã¼ber der Karte

// Nach Trip-Generierung:
// - Route wird auf Karte angezeigt
// - Panel wird ausgeblendet (wechselt zu "Schnell")
// - POIs erscheinen als nummerierte Marker

// Alternativ: TripScreen fÃ¼r erweiterte Optionen
context.push('/trip');
context.push('/trip?mode=ai');
```

### AI Trip Panel auf MapScreen (v1.5.0+)

Das AI Trip Panel enthÃ¤lt folgende Elemente:
- **Modus-Auswahl**: Tagestrip / Euro Trip Buttons
- **Startpunkt**: Adress-Eingabe mit Autocomplete + GPS-Button
- **Reisedauer/Radius**: Tage-Slider (Euro Trip, v1.7.38) / Radius-Slider (Tagestrip)
- **Kategorien**: Aufklappbare Kategorie-Auswahl
- **Generate Button**: "Ãœberrasch mich!"

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

### AI Trip Einstellungen (v1.5.7+, v1.7.38: Tage statt Radius)

**Tagestrip-Modus (Radius-Slider, unverÃ¤ndert):**

| Einstellung | Min | Max | Default |
|-------------|-----|-----|---------|
| Radius | 30 km | 300 km | 100 km |

**Euro Trip-Modus (v1.7.38: Tage-Slider als primÃ¤rer Input):**

| Einstellung | Min | Max | Default |
|-------------|-----|-----|---------|
| Reisedauer | 1 Tag | 14 Tage | 3 Tage |
| Suchradius (auto) | 600 km | 8400 km | 1800 km |

**Euro Trip Radius-Berechnung (v1.7.38):**
- Formel: `Radius = Tage Ã— 600km` (Umkehrung von vorher)
- Benutzer wÃ¤hlt Tage, Radius wird automatisch berechnet
- Max 9 POIs pro Tag (Google Maps Limit)

**Quick-Select Buttons:**
- Tagesausflug: 50, 100, 200, 300 km
- Euro Trip: 2 Tage, 4 Tage, 7 Tage, 10 Tage (v1.7.38)

**Tage-Beschreibungen (Euro Trip):**

| Tage | Beschreibung |
|------|-------------|
| 1 | Tagesausflug |
| 2 | Wochenend-Trip |
| 3-4 | Kurzurlaub |
| 5-7 | Wochenreise |
| 8+ | Epischer Euro Trip |

### MehrtÃ¤giger Euro Trip Export (v1.5.7+, Fix v1.7.34)

```dart
// Tag auswÃ¤hlen (fÃ¼r tagesweisen Export)
ref.read(randomTripNotifierProvider.notifier).selectDay(2);

// Tag in Google Maps exportieren
// Start: Tag 1 = Trip-Start, ab Tag 2 = letzter Stop vom Vortag
// Waypoints: Alle Stops des Tages (max 9)
// Ziel: Letzter Tag = Trip-Start, sonst erster Stop vom Folgetag

// Tag als exportiert markieren
ref.read(randomTripNotifierProvider.notifier).completeDay(2);

// PrÃ¼fen ob Tag exportiert wurde
final state = ref.read(randomTripNotifierProvider);
final isCompleted = state.isDayCompleted(2);

// WICHTIG v1.7.34: Bei removePOI/rerollPOI wird _dayPlanner.planDays()
// aufgerufen, damit das day-Feld der Stops erhalten bleibt.
// Ohne diesen Fix starteten Folgetage am Trip-Start statt am letzten Stop.
// Auch _saveToFavorites nutzt jetzt trip.stops (mit day-Feld) statt selectedPOIs.
```

### Aktiver Trip Persistenz (v1.7.39+)

```dart
// Aktiver Trip wird automatisch gespeichert bei Multi-Day Euro Trips
// Nach confirmTrip(), completeDay(), selectDay(), uncompleteDay()

// Aktiven Trip aus Hive laden (Provider)
final activeTripAsync = ref.watch(activeTripNotifierProvider);
activeTripAsync.when(
  data: (data) {
    if (data != null) {
      // Aktiver Trip vorhanden
      print('${data.trip.name} - ${data.completedDays.length}/${data.trip.actualDays} Tage');
    }
  },
  loading: () {},
  error: (e, s) {},
);

// Trip wiederherstellen (aus ActiveTripData)
await ref.read(randomTripNotifierProvider.notifier).restoreFromActiveTrip(data);

// Aktiven Trip lÃ¶schen
await ref.read(activeTripNotifierProvider.notifier).clear();

// Provider refreshen (nach externem Save)
await ref.read(activeTripNotifierProvider.notifier).refresh();
```

**Automatisches Verhalten:**
- `confirmTrip()` â†’ Speichert bei Multi-Day
- `completeDay(N)` â†’ Speichert nach Tag-Export
- `selectDay(N)` â†’ Aktualisiert ausgewÃ¤hlten Tag
- `uncompleteDay(N)` â†’ Speichert nach RÃ¼ckgÃ¤ngig
- `reset()` â†’ LÃ¶scht aktiven Trip
- `generateTrip()` â†’ LÃ¶scht alten aktiven Trip

**UI-Komponenten:**
- `_ActiveTripResumeBanner` auf MapScreen (Banner mit Fortschritt + Fortsetzen Button)
- Ãœberschreib-Dialog bei neuem Trip wÃ¤hrend aktiver Trip existiert
- Trip-Abschluss-Dialog nach letztem Tag-Export

### AI Trip POIs bearbeiten (v1.4.4+)

```dart
final notifier = ref.read(randomTripNotifierProvider.notifier);

// Einzelnen POI aus dem Trip entfernen (min. 2 mÃ¼ssen bleiben)
notifier.removePOI(poiId);

// Einzelnen POI neu wÃ¼rfeln (nur dieser POI wird ersetzt)
notifier.rerollPOI(poiId);

// PrÃ¼fen ob POIs entfernt werden kÃ¶nnen (> 2 vorhanden)
final canRemove = ref.read(randomTripNotifierProvider).canRemovePOI;

// PrÃ¼fen ob ein bestimmter POI gerade geladen wird
final isLoading = ref.read(randomTripNotifierProvider).isPOILoading(poiId);
```

**Features:**
- **POI lÃ¶schen**: Entferne ungewÃ¼nschte POIs vor dem Speichern
- **POI neu wÃ¼rfeln**: Ersetze nur einen einzelnen POI (nicht den ganzen Trip)
- **Minimum-PrÃ¼fung**: Mindestens 2 POIs mÃ¼ssen im Trip bleiben
- **Per-POI Loading**: Individuelle Loading-Anzeige pro POI
- **Auto-Routenberechnung**: Route wird nach jeder Ã„nderung automatisch neu berechnet
- **Tag-beschraenkte Bearbeitung (v1.8.3)**: Bei Mehrtages-Trips wird nur der betroffene Tag modifiziert, alle anderen Tage bleiben unveraendert. Kein globales `planDays()` mehr â€” stattdessen `_removePOIFromDay()` / `_rerollPOIForDay()` in `trip_generator_repo.dart`

### POI-Kategorien-Filter (v1.7.23+)

**Alle 15 Kategorien** sind als horizontale Quick-Filter-Chips auf der POI-Liste verfÃ¼gbar:

| Kategorie | OSM-Tags | Overpass-Query |
|-----------|----------|----------------|
| `castle` | `historic=castle` | âœ… seit v1.0 |
| `nature` | `natural=*` (excl. water/beach) | âœ… seit v1.0 |
| `museum` | `tourism=museum` | âœ… seit v1.0 |
| `viewpoint` | `tourism=viewpoint` | âœ… seit v1.0 |
| `lake` | `natural=water` + `water=lake/reservoir`, `relation` fuer grosse Seen, See-Suffix-Erkennung | âœ… erweitert v1.9.13 |
| `coast` | `natural=beach/bay`, `leisure=beach_resort/marina`, `place=island` | âœ… erweitert v1.9.13 |
| `park` | `leisure=park` | âœ… seit v1.0 |
| `city` | `place=city/town`, Stadt-Suffix-Erkennung (-stadt/-furt/-heim/-hausen) | âœ… erweitert v1.9.13 |
| `activity` | `tourism=theme_park/zoo`, `leisure=water_park/swimming_area` | âœ… seit v1.7.23 |
| `hotel` | `tourism=hotel` + `stars` | âœ… seit v1.7.23 |
| `restaurant` | `amenity=restaurant` + `cuisine` | âœ… seit v1.7.23 |
| `unesco` | `heritage=*` | âœ… seit v1.0 |
| `church` | `amenity=place_of_worship` | âœ… seit v1.0 |
| `monument` | `historic=monument/memorial` | âœ… seit v1.0 |
| `attraction` | `tourism=attraction` | âœ… seit v1.0 |

**Filter-Chip Widget (v1.7.24, v1.7.26 als Referenz-Pattern fÃ¼r alle Chips):**
- `Material(transparent)` + `InkWell` fÃ¼r Ripple-Effekt
- `AnimatedContainer` (100ms) rendert alles konsistent: Hintergrund, Border, Schatten
- AusgewÃ¤hlt: `colorScheme.primary` Hintergrund + weiÃŸer Text + HÃ¤kchen-Icon + blauer Schatten
- Alle Chips horizontal scrollbar in `ListView`
- **v1.7.26:** Modal-Kategorien + AI Trip CategorySelector nutzen dasselbe Pattern

```dart
// Kategorie-Filter setzen
final notifier = ref.read(pOIStateNotifierProvider.notifier);
final categories = {POICategory.lake, POICategory.coast};
notifier.setSelectedCategories(categories);

// Filter zurÃ¼cksetzen
notifier.resetFilters();

// Aktive Filter prÃ¼fen
final hasFilters = ref.read(pOIStateNotifierProvider).hasActiveFilters;
final selected = ref.read(pOIStateNotifierProvider).selectedCategories;
```

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
- **Region-Cache**: 7 Tage gÃ¼ltig, sofortiges Laden bei erneutem Besuch
- **Enrichment-Cache**: 30 Tage gÃ¼ltig fÃ¼r Bilder/Beschreibungen
- **Batch-Enrichment**: Wikipedia Multi-Title-Query fÃ¼r bis zu 50 POIs (v1.7.3)
- **ListView**: `cacheExtent: 500` fÃ¼r flÃ¼ssigeres Scrollen

### POI-Foto-Optimierungen (v1.3.7+, v1.6.6, v1.7.3, v1.7.7, v1.7.9)

```dart
// PrÃ¼fen ob POI gerade enriched wird (Per-POI Loading State)
final isLoading = ref.read(pOIStateNotifierProvider).isPOIEnriching(poiId);

// Enrichment Service Konfiguration (v1.6.6)
POIEnrichmentService._maxConcurrentEnrichments = 3;  // Max 3 parallel (reduziert von 5)
POIEnrichmentService._enrichmentTimeout = 25000;     // 25 Sekunden
POIEnrichmentService._maxRetries = 3;                // 3 Versuche bei Fehler
POIEnrichmentService._apiCallDelay = 200;            // 200ms zwischen API-Calls
```

**Architektur-Verbesserungen:**
- **Parallele API-Calls**: Wikipedia + Wikimedia gleichzeitig (statt sequenziell)
- **Retry-Logik**: 3 Versuche mit Exponential Backoff (500ms â†’ 1s â†’ 1.5s)
- **Concurrency-Limits**: Max 3 gleichzeitige Enrichments (v1.6.6: reduziert fÃ¼r Rate-Limit-Schutz)
- **Per-POI Loading State**: `enrichingPOIIds` Set im POIState
- **Doppel-Enrichment-Schutz**: PrÃ¼fung vor jedem Enrichment-Start
- **Rate-Limit-Handling**: HTTP 429 wird erkannt und 5 Sekunden gewartet (v1.6.6)
- **API-Call-Delays**: 200ms Pause zwischen Wikimedia-Calls (v1.6.6)
- **OSM-Tags**: Overpass `image`, `wikimedia_commons`, `wikidata`, `wikipedia` Tags werden extrahiert (v1.7.7)
- **EN-Wikipedia Fallback**: Englische Wikipedia als Fallback wenn DE kein Bild liefert (v1.7.7)
- **Suchvarianten**: Umlaute normalisieren + PrÃ¤fix-WÃ¶rter entfernen fÃ¼r bessere Wikimedia-Treffer (v1.7.7)
- **Batch-Fix**: Wikipedia-POIs ohne Bild bekommen Wikimedia Geo-Suche Fallback (v1.7.7)
- **Batch-Limit 5â†’15**: Wikimedia-Fallback jetzt fÃ¼r bis zu 15 POIs statt nur 5 (v1.7.9)
- **Sub-Batching**: 5er-Gruppen mit 500ms Pause zwischen Batches fÃ¼r Rate-Limit-Schutz (v1.7.9)
- **isEnriched-Fix**: POIs ohne Foto werden NICHT mehr als "enriched" markiert, Session-Set verhindert Endlosschleifen (v1.7.9)
- **2-Stufen-UI-Update**: Cache/Wikipedia-Treffer sofort anzeigen, Wikimedia-Fallbacks inkrementell nachliefern (v1.7.9)
- **Image Pre-Caching**: Bild-URLs werden nach Enrichment im Disk-Cache vorgeladen fÃ¼r sofortige Anzeige (v1.7.9)
- **OSM-URL-Validierung**: `image`-Tags aus Overpass werden auf gÃ¼ltige HTTP-URLs geprÃ¼ft (v1.7.9)

**Bildquellen (in PrioritÃ¤ts-Reihenfolge):**
1. OSM-Tags aus Overpass: `image`, `wikimedia_commons` Tags (v1.7.7, v1.7.9: URL-Validierung)
2. Wikipedia DE API (pageimages) - Hauptbild + Thumbnail
3. Wikimedia Commons Geo-Suche (10km Radius, 15 Ergebnisse) (v1.7.7: 10km statt 5km)
4. Wikimedia Commons Titel-Suche (mit Suchvarianten: Umlaute, PrÃ¤fixe) (v1.7.7)
5. Wikimedia Commons Kategorie-Suche
6. Wikipedia EN API (Fallback nur fÃ¼r Bild) (v1.7.7)
7. Wikidata SPARQL (P18 Bild, P948 Wikivoyage-Banner, P154 Logo, P94 Wappen) (v1.7.27: P948 + P373)
8. Wikidata P373 Commons-Category-Search (v1.7.27)
9. Wikipedia FR/IT/ES/NL/PL (lÃ¤nderspezifisch priorisiert) (v1.7.27)
10. Wikidata Geo-Radius (wikibase:around, 2km, P18-Bilder) (v1.7.27)
11. Openverse CC-Bilder (800M+ Creative-Commons, Last-Resort) (v1.7.27)

**Performance-Vergleich:**
| Metrik | v1.3.6 | v1.3.7 | v1.7.3 | v1.7.7 | v1.7.9 | v1.7.27 |
|--------|--------|--------|--------|--------|--------|---------|
| Zeit fÃ¼r 20 POIs | 60+ Sek | 21+ Sek | ~3 Sek | ~3 Sek | ~2 Sek | ~2 Sek |
| API-Calls fÃ¼r 20 POIs | ~160 | ~80 | ~4 | ~4-8 | ~4-8 | ~4-12 |
| Bild-Trefferquote | ~60% | ~85% | ~85% | ~95% | ~98% | ~100% |
| Fallback-Coverage | 5 POIs | 5 POIs | 5 POIs | 5 POIs | 15 POIs | 15 POIs |

### POI Enrichment Race Condition Fix (v1.5.1)

**Problem:** POIs wurden geladen, kurz angezeigt und verschwanden dann - nur 1 POI blieb sichtbar.

**Ursache:** Beim parallelen Enrichment (8 POIs gleichzeitig) Ã¼berschrieben sich die State-Updates gegenseitig:

```dart
// VORHER (fehlerhaft):
final updatedPOIs = List<POI>.from(state.pois);  // Snapshot zum Zeitpunkt X
// ... async await (andere Enrichments kÃ¶nnen hier state Ã¤ndern)
state = state.copyWith(pois: updatedPOIs);  // Ãœberschreibt ALLE Ã„nderungen seit X
```

**LÃ¶sung:** Atomare State-Updates mit `_updatePOIInState()`:

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

**WICHTIG fÃ¼r zukÃ¼nftige Entwicklung:**
- Bei asynchronen Operationen IMMER den aktuellen State zum Zeitpunkt des Updates lesen
- Keine alten State-Kopien nach `await` weiterverwenden
- Parallel laufende State-Updates mÃ¼ssen atomar sein

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

**LÃ¶sung:** Filter nur bei aktivem `routeOnlyMode` anwenden:

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

**ZusÃ¤tzliche Ã„nderungen:**
- Default `maxDetourKm` von 45 auf **100 km** erhÃ¶ht
- Debug-Logging fÃ¼r alle Filter-Schritte hinzugefÃ¼gt

### POI Enrichment Cache-Fix (v1.5.3)

**Problem:** POI-Fotos wurden oft nicht geladen, ohne ersichtlichen Grund.

**Ursache:** POIs mit Beschreibung aber **ohne Bild** wurden gecacht â†’ Bild wurde nie erneut gesucht (30 Tage Cache!)

```dart
// VORHER (fehlerhaft):
if (cacheService != null && !enrichment.isEmpty) {  // isEmpty = !hasImage && !hasDescription
  await cacheService.cacheEnrichedPOI(enrichedPOI);  // Cached auch POIs ohne Bild!
}
```

**LÃ¶sung:** Nur POIs mit Bild cachen:

```dart
// NACHHER (korrekt):
if (cacheService != null && enrichment.hasImage) {  // NUR wenn Bild vorhanden
  await cacheService.cacheEnrichedPOI(enrichedPOI);
}
```

**ZusÃ¤tzliche Ã„nderungen:**
- `resetStaticState()` Methode hinzugefÃ¼gt (wird bei Provider-Init aufgerufen)
- Failure-Logs: `[Enrichment] âš ï¸ Kein Wikimedia-Bild gefunden fÃ¼r: ...`

### GPS-Button Verhalten (v1.5.4)

**Vorher:** Bei deaktivierten GPS wurde MÃ¼nchen (48.1351, 11.5820) als Test-Standort verwendet.

**Nachher:** Dialog fragt ob GPS-Einstellungen geÃ¶ffnet werden sollen.

```dart
// GPS-Button auf MapScreen: _centerOnLocation()
// 1. PrÃ¼ft ob Location Services aktiviert sind
// 2. Bei deaktiviert: Zeigt Dialog mit Frage
// 3. "Einstellungen Ã¶ffnen" â†’ Geolocator.openLocationSettings()
// 4. "Nein" â†’ Abbrechen (kein Fallback)

// Implementierung des Dialogs:
Future<bool> _showGpsDialog() async {
  return await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('GPS deaktiviert'),
      content: const Text(
        'Die Ortungsdienste sind deaktiviert. MÃ¶chtest du die GPS-Einstellungen Ã¶ffnen?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Nein'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Einstellungen Ã¶ffnen'),
        ),
      ],
    ),
  ) ?? false;
}
```

**Konsistenz:** Das Verhalten ist jetzt konsistent mit `RandomTripProvider`, der bereits Fehlermeldungen statt Fallback-Standorte verwendet.

### GPS-Dialog bei AI Trip (v1.6.8)

**Problem:** Bei "Ãœberrasch mich!" ohne GPS wurde nur eine Fehlermeldung angezeigt, kein Dialog.

**LÃ¶sung:** Neue Helper-Methoden in `_AITripPanelState`:

```dart
// GPS-Button und "Ãœberrasch mich!" Button nutzen jetzt:
Future<bool> _checkGPSAndShowDialog() async {
  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Dialog anzeigen mit Option "Einstellungen Ã¶ffnen"
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

**Ergebnis:** Bei deaktiviertem GPS erscheint jetzt auch bei "Ãœberrasch mich!" ein Dialog.

### GPS-Button im Schnell-Modus (v1.6.8)

**Problem:** Im Schnell-Modus gab es keinen GPS-Button zum Setzen des aktuellen Standorts als Startpunkt.

**LÃ¶sung:** GPS-Button zur `_SearchBar` hinzugefÃ¼gt:

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
  // GPS-Status prÃ¼fen, Dialog wenn deaktiviert
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

**LÃ¶sung:** Feste Card-HÃ¶he (96px) statt dynamischer Berechnung.

```dart
// VORHER - Problematisch
child: IntrinsicHeight(
  child: Row(
    children: [
      CachedNetworkImage(
        height: double.infinity,  // <- Keine intrinsische HÃ¶he!
      ),
    ],
  ),
)

// NACHHER - Feste HÃ¶he
static const double _minCardHeight = 96.0;

child: SizedBox(
  height: _minCardHeight,
  child: Row(
    children: [
      CachedNetworkImage(
        height: _minCardHeight,  // <- Feste HÃ¶he
      ),
    ],
  ),
)
```

**WICHTIG fÃ¼r zukÃ¼nftige Entwicklung:**
- Niemals `IntrinsicHeight` mit `double.infinity` kombinieren
- Widgets innerhalb von `IntrinsicHeight` mÃ¼ssen eine intrinsische HÃ¶he haben
- Feste HÃ¶hen sind performanter als dynamische Layout-Berechnungen

### POI-Foto CORS & Rate-Limit Fix (v1.6.6)

**Problem:** POI-Fotos wurden nicht angezeigt.

**Ursachen & Fixes:**

1. **Wikidata SPARQL ohne `origin: '*'` Header**
   - Wikidata-Fallback-Bilder konnten nicht geladen werden
   - Fix: `origin: '*'` Parameter und `Origin`-Header hinzugefÃ¼gt

2. **Rate-Limiting ohne Handling**
   - Bei vielen POIs: Silent Failures durch Wikimedia Rate-Limit (200 Req/Min)
   - Fix: HTTP 429 wird erkannt und 5 Sekunden gewartet

3. **Zu hohe Concurrency**
   - 5 parallele Enrichments Ã— 3 API-Calls = 15 gleichzeitige Requests
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
- `[Enrichment] âš ï¸ Rate-Limit (429) erreicht!`
- `[Enrichment] â±ï¸ Timeout bei Versuch X`
- `[Enrichment] âŒ API-Fehler: Status=X, Typ=Y, URL=Z`

### POI-Detail Fotos & Highlights Fix (v1.6.7)

**Problem:** Nach Routenberechnung wurden beim Klick auf POIs keine Fotos und Highlights angezeigt.

**Ursachen & Fixes:**

1. **Asynchrones Enrichment ohne Warten**
   - `unawaited(enrichPOI())` â†’ UI renderte mit ungereichertem POI
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

**LÃ¶sung:** Neue `addPOI()` Methode im POIStateProvider:

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
    // POI hinzufÃ¼gen
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

### LÃ¶schbutton fÃ¼r AI Trip (v1.6.8, aktualisiert v1.7.26)

**Problem v1.6.8:** Nach AI Trip Generierung erschien kein LÃ¶schbutton auf der Karte.

**Ursache:** Der `_RouteClearButton` wurde nur fÃ¼r `routePlanner.hasStart || hasEnd` angezeigt, nicht fÃ¼r AI Trips.

**LÃ¶sung v1.6.8:** Schnell-Modus: Erweiterte Bedingung + AI Trip Modus: Separater Button.

**Problem v1.7.26:** Der AI Trip "Route lÃ¶schen" Button war **auÃŸerhalb** des scrollbaren Panels in der Ã¤uÃŸeren Column positioniert. Bei vollem Panel (Wetter + Konfiguration) wurde der Button von der Bottom Navigation abgeschnitten.

**LÃ¶sung v1.7.26:** Button **in** das `_AITripPanel` verschoben (innerhalb von `SingleChildScrollView`):

```dart
// AI Trip Panel - Route lÃ¶schen jetzt INNERHALB des scrollbaren Bereichs
SingleChildScrollView(
  child: Column(
    children: [
      // ... Wetter, Typ, Start, Radius, Kategorien ...
      GenerateButton(),             // "Ãœberrasch mich!"
      // v1.7.26: Route lÃ¶schen im Panel statt extern
      if (hasRoute) ...[
        Divider(),
        Padding(
          padding: EdgeInsets.all(12),
          child: _RouteClearButton(onClear: () { ... }),
        ),
      ],
    ],
  ),
)
```

**Ergebnis:** Der "Route lÃ¶schen" Button ist immer durch Scrollen erreichbar und wird nicht mehr abgeschnitten.

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

**Feature 4: GPS-Fallback fÃ¼r Kartenausschnitt (v1.7.2)**

Ohne Route wird der GPS-Standort als Kartenzentrum verwendet.

```dart
// map_screen.dart - initState und build()
// PrÃ¼fe ob irgendeine Route vorhanden ist
final hasAnyRoute = routePlanner.hasRoute ||
    tripState.hasRoute ||
    randomTripState.step == RandomTripStep.preview ||
    randomTripState.step == RandomTripStep.confirmed;

if (hasAnyRoute) {
  // Auf Route zoomen (PrioritÃ¤t: AI Trip > Trip > RoutePlanner)
  _fitMapToRoute(routeToFit);
} else {
  // Keine Route â†’ GPS-Standort zentrieren
  _centerOnCurrentLocationSilent();
}

// Fallback bei GPS-Fehler: Europa-Zentrum
void _showDefaultMapCenter() {
  mapController?.move(const LatLng(50.0, 10.0), 6.0);
}
```

**Ergebnis:** Bessere BenutzerfÃ¼hrung zwischen Karte und Trip-Tab. Karte zeigt immer relevanten Ausschnitt.

### AI-Chat mit standortbasierten POI-VorschlÃ¤gen (v1.7.2)

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
// ðŸ“ MÃ¼nchen          [30 km] [âš™ï¸]
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
  'ðŸ“ POIs in meiner NÃ¤he',
  'ðŸ° SehenswÃ¼rdigkeiten',
  'ðŸŒ² Natur & Parks',
  'ðŸ½ï¸ Restaurants',
];

// Keyword-Erkennung fÃ¼r standortbasierte Anfragen
bool _isLocationBasedQuery(String query) {
  final keywords = ['in meiner nÃ¤he', 'um mich', 'hier', 'zeig mir', ...];
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

// Backend erhÃ¤lt Standort im Kontext
final contextData = <String, dynamic>{};
if (context.hasUserLocation) {
  contextData['userLocation'] = {
    'lat': context.userLatitude,
    'lng': context.userLongitude,
    'name': context.userLocationName,
  };
}
```

**Kategorien-Zuordnung (v1.7.9: ungÃ¼ltige IDs gefixt + erweitert, v1.7.23: Overpass-Abfragen fÃ¼r alle Kategorien):**

| Anfrage | Kategorien |
|---------|------------|
| "SehenswÃ¼rdigkeiten" | `museum`, `monument`, `castle`, `viewpoint`, `unesco` |
| "Natur", "Parks" | `nature`, `park`, `lake`, `coast` |
| "Restaurants", "Essen" | `restaurant` |
| "Hotels" | `hotel` |
| "Kultur" | `museum`, `monument`, `church`, `castle`, `unesco` |
| "Strand", "KÃ¼ste" | `coast` |
| "AktivitÃ¤t", "Sport" | `activity` |
| "Wandern" | `nature`, `viewpoint`, `park` |
| "Familie" | `activity`, `park`, `museum` |
| "Zoo", "Freizeitpark", "Therme" | `activity` |
| "Stadt" | `city` |
| Unspezifisch | alle Kategorien |

**Feature 6: Hintergrund-Enrichment fÃ¼r POI-Bilder im Chat (v1.7.7)**

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

**Ergebnis:** Der AI-Chat schlÃ¤gt POIs basierend auf dem aktuellen Standort vor. Benutzer kÃ¶nnen den Such-Radius anpassen und direkt zu POI-Details navigieren. POI-Bilder werden im Hintergrund geladen und erscheinen nach 1-3 Sekunden (v1.7.7).

### Tages-Wettervorhersage (v1.8.0+)

Bei mehrtaegigen Trips wird jetzt eine echte 7-Tage-Vorhersage pro Routenpunkt geladen statt nur das aktuelle Wetter.

```dart
import '../providers/weather_provider.dart';

// Multi-Day Trip: Vorhersage laden (statt nur aktuelles Wetter)
ref.read(routeWeatherNotifierProvider.notifier)
    .loadWeatherForRouteWithForecast(
      routeCoords,
      forecastDays: tripDays,  // max 7 (Open-Meteo Limit)
    );

// Wetter-State
final routeWeather = ref.watch(routeWeatherNotifierProvider);

// Vorhersage fuer einen bestimmten Tag (1-basiert)
final dayForecast = routeWeather.getDayForecast(2, totalDays);
// â†’ DailyForecast? mit temperatureMax, Min, weatherCode, precipitationProbabilityMax

// Wetter-Condition pro Tag aus Vorhersage
final forecastPerDay = routeWeather.getForecastPerDay(totalDays);
// â†’ Map<int, WeatherCondition> {1: good, 2: bad, 3: mixed}

// Formatierte Strings fuer AI-Kontext
final weatherStrings = routeWeather.getForecastPerDayAsStrings(totalDays);
// â†’ Map<int, String> {1: "good (12Â°/18Â°, 10% Regen)", 2: "bad (8Â°/14Â°, 80% Regen)"}

// Pruefen ob Vorhersage-Daten vorhanden
if (routeWeather.hasForecast) {
  // Echte Vorhersage verfuegbar
} else {
  // Fallback auf positionsbasiertes Mapping
}
```

**WeatherPoint Erweiterung:**
```dart
class WeatherPoint {
  final LatLng location;
  final Weather weather;
  final double routePosition;       // 0.0-1.0
  final List<DailyForecast>? dailyForecast;  // NEU v1.8.0
  final int? dayNumber;                       // NEU v1.8.0 (1-basiert)
}
```

**Wetter-Badges auf EditablePOICard:**

| Situation | Badge | Farbe |
|-----------|-------|-------|
| Outdoor + gut | "Ideal" | Gruen |
| Indoor + schlecht | "Empfohlen" | Gruen |
| Outdoor + Regen | "Regen" | Orange |
| Outdoor + Unwetter | "Unwetter" | Rot |

### AI-Vorschlaege bei schlechtem Wetter (v1.8.0+)

GPT-4o schlaegt Indoor-Alternativen vor wenn Outdoor-POIs auf Regentage fallen.

```dart
import '../../ai/providers/ai_trip_advisor_provider.dart';

// AI-Vorschlaege fuer einen Tag anfordern
await ref.read(aITripAdvisorNotifierProvider.notifier)
    .suggestAlternativesForDay(
      day: selectedDay,
      trip: trip,
      routeWeather: routeWeather,
      availablePOIs: availablePOIs,
    );

// State abfragen
final advisorState = ref.watch(aITripAdvisorNotifierProvider);
final suggestions = advisorState.getSuggestionsForDay(selectedDay);
// â†’ List<AISuggestion> mit message, type, replacementPOIName, actionType

// Pruefen ob Vorschlaege vorhanden
if (advisorState.hasSuggestionsForDay(selectedDay)) {
  for (final suggestion in suggestions) {
    print('${suggestion.type}: ${suggestion.message}');
    // type: weather | optimization | alternative | general
    // actionType: swap | remove | reorder (optional)
  }
}

// Loading-State
if (advisorState.isLoading) {
  // Shimmer/Skeleton anzeigen
}

// Regelbasierte Analyse (ohne AI-Backend)
ref.read(aITripAdvisorNotifierProvider.notifier).analyzeTrip(trip, routeWeather);
```

**Fallback-Verhalten:**
- Backend erreichbar â†’ GPT-4o Vorschlaege
- Backend nicht erreichbar â†’ Regelbasierte Vorschlaege (Outdoor auf Regentag â†’ Indoor vorschlagen)

### Korridor-POI-Browser (v1.8.0+)

Entdecke und fuege POIs entlang einer berechneten Route hinzu.

```dart
import '../providers/corridor_browser_provider.dart';
import '../widgets/corridor_browser_sheet.dart';
import '../../map/utils/poi_trip_helper.dart';

// Bottom Sheet oeffnen (Standard: POITripHelper)
CorridorBrowserSheet.show(
  context: context,
  route: route,                 // AppRoute
  existingStopIds: stopIds,     // Set<String> bereits hinzugefuegte POIs
);

// Bottom Sheet oeffnen mit Callback (v1.9.5+152: DayEditor-Integration)
CorridorBrowserSheet.show(
  context: context,
  route: trip.route,
  existingStopIds: trip.stops.map((s) => s.poiId).toSet(),
  onAddPOI: (poi) async {
    final success = await ref
        .read(randomTripNotifierProvider.notifier)
        .addPOIToDay(poi, selectedDay);
    return success;
  },
);

// Provider direkt nutzen
final corridorState = ref.watch(corridorBrowserNotifierProvider);

// POIs laden
ref.read(corridorBrowserNotifierProvider.notifier).loadCorridorPOIs(
  route: route,
  bufferKm: 30.0,            // Korridor-Breite (10-100km)
  categories: {POICategory.museum, POICategory.castle},  // Optional
);

// Korridor-Breite aendern
ref.read(corridorBrowserNotifierProvider.notifier).setBufferKm(50.0);

// Kategorie-Filter
ref.read(corridorBrowserNotifierProvider.notifier).toggleCategory(POICategory.nature);

// POI zum Trip hinzufuegen (mit Feedback)
await POITripHelper.addPOIWithFeedback(
  context: context,
  ref: ref,
  poi: poi,
);

// POI als hinzugefuegt markieren (im Browser)
ref.read(corridorBrowserNotifierProvider.notifier).markAsAdded(poi.id);

// Gefilterte POIs (ohne bereits hinzugefuegte)
final pois = corridorState.filteredPOIs;
final count = corridorState.newPOICount;
```

**Einstiegspunkte:**
1. `TripScreen` â†’ "POIs entlang der Route" Button (sowohl normale Route als auch AI Trip) â€” nutzt Standard-POITripHelper
2. `DayEditorOverlay` â†’ IconButton "POIs entdecken" in BottomActions â€” nutzt `onAddPOI`-Callback fuer direktes Hinzufuegen zum randomTripNotifier (v1.9.5+152)

**CompactPOICard Widget:**
```dart
CompactPOICard(
  name: poi.name,
  category: poi.category,
  imageUrl: poi.imageUrl,
  detourKm: '${poi.detourKm?.toStringAsFixed(1)} km',  // Optional
  isAdded: isAlreadyInTrip,
  onTap: () => navigateToPOI(poi),
  onAdd: () => addPOIToTrip(poi),
);
```

### Reisetagebuch (v1.9.29+)

Dokumentiere deine Reisen mit Fotos und Notizen zu jedem POI.

```dart
import '../../data/providers/journal_provider.dart';
import '../../features/journal/journal_screen.dart';

// Tagebuch oeffnen (via GoRouter)
context.push('/journal/$tripId?name=${Uri.encodeComponent(tripName)}');

// Tagebuch erstellen oder laden
await ref.read(journalNotifierProvider.notifier).getOrCreateJournal(
  tripId: tripId,
  tripName: tripName,
);

// State abfragen
final journalState = ref.watch(journalNotifierProvider);
final journal = journalState.activeJournal;

// Text-Eintrag hinzufuegen
await ref.read(journalNotifierProvider.notifier).addTextEntry(
  note: 'Toller Aussichtspunkt!',
  poiId: poi.id,
  poiName: poi.name,
  latitude: location?.latitude,
  longitude: location?.longitude,
  dayNumber: 1,
);

// Foto-Eintrag hinzufuegen (Kamera)
await ref.read(journalNotifierProvider.notifier).addPhotoFromCamera(
  note: 'Sonnenuntergang am See',
  poiId: poi.id,
  poiName: poi.name,
  latitude: location?.latitude,
  longitude: location?.longitude,
  dayNumber: 1,
);

// Foto-Eintrag hinzufuegen (Galerie)
await ref.read(journalNotifierProvider.notifier).addPhotoFromGallery(
  note: 'Historische Altstadt',
  dayNumber: 2,
);

// Eintrag loeschen
await ref.read(journalNotifierProvider.notifier).deleteEntry(entryId);

// Tagebuch loeschen
await ref.read(journalNotifierProvider.notifier).deleteJournal(tripId);

// Eintraege fuer einen Tag abrufen
final dayEntries = journal?.entriesForDay(1);

// Eintraege fuer einen POI abrufen
final poiEntries = journal?.entriesForPOI(poiId);

// Statistiken
final photoCount = journal?.photoCount;
final entryCount = journal?.entryCount;
final daysWithEntries = journal?.daysWithEntries;
```

**Einstiegspunkt:**
- `TripScreen` â†’ Menue (drei Punkte) â†’ "Tagebuch oeffnen"

**Widgets:**
- `JournalScreen` - Hauptansicht mit Tages-Gruppierung und Statistik-Header
- `JournalEntryCard` - Kompakte Karte fuer Eintraege mit Bild + Zeitstempel
- `AddJournalEntrySheet` - Bottom Sheet zum Hinzufuegen (Kamera/Galerie/Notiz)
- `_EntryDetailsSheet` - Vollbild-Ansicht eines Eintrags

**Speicherung:**
- Eintraege in Hive Box `journal_entries`
- Tagebuecher in Hive Box `journals`
- Bilder im App-Dokumenten-Verzeichnis: `{appDir}/journal/{tripId}/{uuid}.jpg`
- Bilder werden auf 1920x1080 bei 85% Qualitaet komprimiert









