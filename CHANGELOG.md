# Changelog

Alle wichtigen Änderungen an der MapAB Flutter App werden in dieser Datei dokumentiert.

Das Format basiert auf [Keep a Changelog](https://keepachangelog.com/de/1.0.0/),
und dieses Projekt hält sich an [Semantic Versioning](https://semver.org/lang/de/).

---

## [1.10.49] - 2026-02-09

### Social-Ownership + Header-Hardening

#### Geaendert
- **AI-Assistent aus dem Header entfernt**
  - Der Header-Einstieg auf der Map wurde entfernt, um den bekannten Crash-Pfad zu umgehen.
- **Trip-Galerie: Owner kann eigene veroeffentlichte Trips direkt bearbeiten und loeschen**
  - In der oeffentlichen Trip-Detailansicht gibt es fuer den Besitzer jetzt ein Aktionsmenue mit Bearbeiten/Loeschen.
  - Bearbeitung umfasst Titel, Beschreibung und Tags.
- **POI-Galerie: Owner kann eigene veroeffentlichte POI-Posts direkt bearbeiten und loeschen**
  - In POI-Karten gibt es fuer den Besitzer ein Aktionsmenue mit Bearbeiten/Loeschen.
  - Bearbeitung umfasst Titel, Beschreibung, Kategorien und Must-See-Status.

#### Stabilitaet/Sicherheit
- **Owner-Checks im Backend-Zugriff verschaerft**
  - Delete/Update fuer Trips und POI-Posts sind jetzt strikt an `user_id` gebunden.
  - Offline-Fallback-Repository wurde auf die neuen Methoden erweitert.

#### Tests
- `flutter test` (komplette Suite) erfolgreich.

## [1.10.47] - 2026-02-09

### Routing- und UI-Stabilisierung

#### Behoben
- **Duplizierte POIs im Trip-Flow reduziert**
  - Die POI-Deduplizierung arbeitet jetzt nicht nur ueber IDs, sondern auch semantisch ueber Name + Distanz.
  - Near-Duplicates wie mehrere "Altstadt"-Varianten werden bei Auswahl/Optimierung konsolidiert.
- **Tagesrouten-Segment fuer letzten Tag korrigiert**
  - Segment-Extraktion im Day-Editor nutzt jetzt geordnete Wegpunkte statt globaler Start/End-Naehe.
  - Dadurch laeuft die dargestellte Tagesroute wieder ueber die POIs und greift bei Rundreisen nicht auf den falschen Fruehabschnitt.
- **Trip-Generierung und Day-Edit robuster gegen Re-Introduktion von Duplikaten**
  - Dedupe greift in Load-, Auswahl-, Optimierungs- und Edit-Pfaden (`add`, `reroll`, Rebuild).

#### Geaendert
- **Lade-Animationen im AI-Trip-Flow ueberarbeitet**
  - Fortschritt bleibt strikt von 1% bis 100%.
  - Weniger Icon-Rauschen, klarere visuelle Trennung zwischen AI-Tagestrip und Euro-Trip.

#### CI/Qualitaet
- **Neuer GitHub CI-Workflow fuer PRs/Push**
  - Flutter Tests + Analyze sowie Backend Typecheck + Lint sind als Gate definiert.

#### Tests
- Neue Regressionstests:
  - `test/widgets/day_mini_map_test.dart` (roundtrip/last-day segment extraction)
  - `test/repositories/trip_generator_daytrip_test.dart` (semantische POI-Deduplizierung)
- `flutter test` (komplette Suite) gruen.

## [1.10.46] - 2026-02-09

### Social-Flow + Navigation-Lifecycle Stabilisierung

#### Behoben
- **POI-Social Daten werden beim Oeffnen der Detailseite jetzt direkt geladen**
  - `POIDetailScreen` triggert `loadAll()` verlässlich nach dem initialen POI-Ladevorgang.
- **Reply-Moderation nutzt korrekte IDs**
  - Delete/Flag auf Replies verarbeitet jetzt die Reply-ID statt der Parent-Kommentar-ID.
- **Public Profile Routing repariert**
  - Neue Route `/profile/:userId` hinzugefuegt.
  - Auth-Guard so angepasst, dass nur das private `/profile` geschuetzt ist.
- **Sharing- und QR-Link-Schema vereinheitlicht**
  - Public-Links nutzen `https://mapab.app/gallery/{id}`.
  - Decoder bleibt rueckwaertskompatibel mit Legacy-Links (`/trip/{id}`).
- **Public Trip Detail zeigt echten QR-Code**
  - Platzhalter in der Social-Detailansicht durch `qr_flutter` QR-Rendering ersetzt.
- **Navigation-Lifecycle gehaertet**
  - Robusteres Resume-/Stop-Verhalten im Navigation- und Background-Service-Flow.

#### Technisch
- Geaenderte Dateien (Auszug):
  - `lib/app.dart`
  - `lib/data/services/sharing_service.dart`
  - `lib/features/poi/poi_detail_screen.dart`
  - `lib/features/poi/widgets/comment_card.dart`
  - `lib/features/poi/widgets/poi_comments_section.dart`
  - `lib/features/sharing/qr_scanner_screen.dart`
  - `lib/features/social/public_profile_screen.dart`
  - `lib/features/social/trip_detail_public_screen.dart`
  - `lib/features/navigation/providers/navigation_provider.dart`
  - `lib/features/navigation/services/navigation_background_service_android.dart`
  - `backend/supabase/migrations/013_admin_notifications_trip_photo.sql`

#### Tests
- `flutter test` (komplette Suite) gruen.
- Zusatztests fuer Sharing-Public-Links und Navigation-Launch-Args hinzugefuegt.

## [1.10.43] - 2026-02-09

### Favoriten-Flow angeglichen + Trip-Bearbeiten UI + AI-Assistent Stabilisierung

#### Geaendert
- **Favoriten-Routen verhalten sich wie berechnete AI-Routen**
  - Bei geladener Favoriten-Route zeigt das Trip-Panel jetzt beide Kernaktionen:
    - `Trip bearbeiten`
    - `Navigation starten`
- **Trip-Bearbeiten Footer angepasst**
  - Button-Text von `Weitere POIs hinzufügen` auf **`POIs hinzufügen`** umbenannt.
  - `POIs hinzufügen` oeffnet den POI-Browser jetzt als Bottom-Sheet-Modal (statt chaotischem Inline-Flow), im selben Design-/Hoehenkonzept.
- **POI-Hinzufuegen-Modal visuell an Trip-Bearbeiten angeglichen**
  - Konsistente Handle-Bar, Rahmen und Vollbild-Charakter.
- **AI-Assistent gegen Abstuerze gehaertet**
  - Schutz gegen paralleles Senden (`_isLoading`-Guard).
  - Zusätzliche Lifecycle-Sicherheit bei Scroll/Async-Location (`mounted`-Checks).
  - Robustere Text-Normalisierung fuer Intent-Erkennung (u.a. Umlaute) bei Nearby/Kategorie-Matching.

#### Technisch
- Geaenderte Dateien:
  - `lib/features/map/widgets/trip_config_panel.dart`
  - `lib/features/trip/widgets/day_editor_overlay.dart`
  - `lib/features/trip/widgets/corridor_browser_sheet.dart`
  - `lib/features/ai_assistant/chat_screen.dart`

## [1.10.42] - 2026-02-09

### AI-Assistent verbessert + Bottom-Sheet Konsistenz

#### Geaendert
- **Lokale Restaurant-Suche im AI-Chat robuster**
  - Restaurant-Intents werden jetzt priorisiert als Nearby-Anfrage behandelt.
  - Fallback-Suche greift bei leeren Treffern auf lokale POIs ohne Kategorie-Filter zurueck und filtert gezielt nach Restaurant-Indikatoren.
- **AI-POI-Karten koennen direkt zur Route hinzugefuegt werden**
  - Neue Aktion `Zur Route` in der AI-Chat-POI-Karte.
  - POIs werden direkt an aktive Route uebergeben oder starten eine neue Route (Auto-Route aus Standort).
- **Routen-Intent im Chat verbessert**
  - Bei Route/Trip-Planungsanfragen oeffnet der AI-Assistent direkt den Routen-Generator.
- **Bottom-Sheet Hoehen vereinheitlicht**
  - Alle verbleibenden abweichenden Bottom-Sheets in den betroffenen Flows nutzen jetzt denselben Hoehenvertrag wie das POI-Kategorien-Modal (`1.0 / 0.9 / 1.0`).

#### Technisch
- Geaenderte Dateien:
  - `lib/features/ai_assistant/chat_screen.dart`
  - `lib/features/trip/widgets/day_editor_overlay.dart`
  - `lib/features/trip/widgets/corridor_browser_sheet.dart`
  - `lib/features/social/trip_detail_public_screen.dart`

## [1.10.41] - 2026-02-08

### Trip-Bearbeiten UX vereinfacht

#### Geaendert
- **Footer im Trip-Bearbeiten Modal auf 2 klare Hauptaktionen reduziert**
  - `POIs hinzufügen` wurde zu **`Weitere POIs hinzufügen`** umbenannt.
  - Neuer Button **`Fertig`** neben `Weitere POIs hinzufügen`.
- **Neuer Fertig-Modal mit Uebersicht**
  - Zeigt `Übersichtskarte` mit aktueller Route und Tagessegment.
  - Zeigt kompaktes Stats-Widget: Stops, Distanz, Fahrzeit und Wetter.
  - Enthält zentrale Aktionen:
    - `Navigation starten`
    - `Route speichern` (mit Herz-Icon, speichert in Favoriten)
    - `Veröffentlichen`
    - Google-Maps Export-Button
- **Google-Maps-Button-Label dynamisch nach Modus**
  - Bei Tagestrip: **`Tagestrip in Google Maps`**
  - Bei AI Euro Trip: Label bleibt wie bisher **`Tag in Google Maps`**

#### Technisch
- Geaenderte Datei:
  - `lib/features/trip/widgets/day_editor_overlay.dart`

## [1.10.40] - 2026-02-08

### UI-Refactor Modale + Trip-Bearbeiten

#### Geaendert
- **Modale und Chips konsistenter im gesamten UI-Flow**
  - `AppTheme` erweitert: Light Theme hat jetzt explizite `dialogTheme`/`bottomSheetTheme`.
  - Chip-Styling in Light/Dark/OLED vereinheitlicht (Label-Kontrast inkl. `secondaryLabelStyle`).
- **AI-Assistent: Such-Radius Chips lesbar**
  - Quick-Radius `ChoiceChip`s im Radius-Dialog mit expliziten Kontrastfarben, Border und Checkmark-Style.
  - Kein weiss-auf-weiss Zustand mehr in Light/Dark/OLED.
- **Sehenswuerdigkeiten: Filter-Sheet lesbarer und design-konsistent**
  - Kategorie-`FilterChip`s mit klaren selected/unselected Text- und Hintergrundfarben.
  - Footer-Aktion auf klare Primary-CTA (`FilledButton`) umgestellt.
  - Header/Footer visuell an Modal-Design angepasst.
- **Trip bearbeiten aufgeraeumt (ohne Funktionsverlust)**
  - Header entlastet: `Favoriten speichern` und `Veroeffentlichen` aus der AppBar entfernt.
  - Alle 6 Aktionen bleiben erhalten und sind im Sticky-Footer priorisiert:
    - `Navigation starten` (primaer)
    - `POIs hinzufuegen`, `Route Teilen`, `Tag in Google Maps` (sekundaer)
    - `Favoriten speichern`, `Veroeffentlichen` (tertiaer)

#### Technisch
- Geaenderte Dateien:
  - `lib/core/theme/app_theme.dart`
  - `lib/features/ai_assistant/chat_screen.dart`
  - `lib/features/poi/widgets/poi_filters.dart`
  - `lib/features/trip/widgets/day_editor_overlay.dart`

## [1.10.39] - 2026-02-08

### Erweiterung AI-POI-Erlebnis

#### Hinzugefuegt
- **Neuer strukturierter AI-POI-Endpoint**
  - Backend-Route `POST /api/ai/poi-suggestions` liefert validierte, strukturierte Vorschlaege.
  - JSON-Schema-Output mit robustem Fallback-Ranking bei ungueltiger oder leerer AI-Antwort.
- **Kontextstarker AI-Prompt**
  - `TripContext` beruecksichtigt jetzt u.a. Standort, Wetter, ausgewaehlten Tag, bevorzugte Kategorien und Antwortsprache.

#### Geaendert
- **AI-Vorschlaege sind app-weit klickbar wie normale POIs**
  - Day-Editor, Day-Mini-Map, Hauptkarte und AI-Chat nutzen denselben POI-Detailflow.
  - AI-Marker und AI-Karten oeffnen konsistent POI-Details inkl. Enrichment.
- **AI liefert mehr und reichhaltigere Vorschlaege**
  - Standardmaessig bis zu 8 Vorschlaege.
  - Vorschlaege enthalten Begruendung, Highlights, lange Beschreibung und Bilder (Enrichment + Social-Fallback).
- **Navigation vervollstaendigt**
  - `ChatScreen` ist ueber `'/ai-assistant'` erreichbar.
  - `POIListScreen` ist ueber `'/pois'` erreichbar.

#### Technisch
- Neue/erweiterte Dateien:
  - `backend/api/ai/poi-suggestions.ts`
  - `backend/lib/types.ts`
  - `backend/lib/openai.ts`
  - `lib/data/services/ai_service.dart`
  - `lib/features/ai/providers/ai_trip_advisor_provider.dart`
  - `lib/features/ai_assistant/chat_screen.dart`
  - `lib/features/trip/widgets/day_editor_overlay.dart`
  - `lib/features/trip/widgets/day_mini_map.dart`
  - `lib/features/map/widgets/map_view.dart`
  - `lib/app.dart`

## [1.10.38] - 2026-02-08

### AI Tagestrip Routing-Stabilitaet

#### Behoben
- **AI Tagestrip bricht bei instabilen POI-Sets deutlich seltener ab**
  - `generateDayTrip(...)` nutzt jetzt mehrere Selektionsversuche (Retry-Strategie) statt nur einen Single-Pass.
  - Jeder Versuch wird separat optimiert und ueber die neue Backoff-Pipeline geroutet.
- **Routing-Backoff und Rescue sind robuster**
  - Zentrale Helper-Routeberechnung mit iterativem Entfernen problematischer Stops.
  - Single-POI-Rescue nutzt erweiterten Kandidatenpool: `routingPOIs` -> `constrainedPOIs` -> `availablePOIs`.
  - Fallback auf 1 POI wird aktiv genutzt, bevor ein harter Fehler geworfen wird.
- **Single-Day Edit-Flow behaelt Zielendpunkt bei A->B Trips**
  - `removePOI(...)`, `addPOIToTrip(...)` und `rerollPOI(...)` verwenden nicht mehr pauschal `end = start`.
  - Rebuild nutzt den echten Trip-Endpunkt und waehlt korrekt zwischen directional (A->B) und roundtrip Optimierung.
- **Diagnose verbessert**
  - Strukturierte Debug-Logs pro Daytrip-Versuch, inkl. Backoff-Schritten und Rescue-Pfad.

#### Technisch
- `lib/data/repositories/trip_generator_repo.dart`
  - Neue interne Helper fuer Daytrip-Versuche, Routing-Backoff, Rescue-Kandidaten und Single-Day-Endpoint-Resolve.
  - `generateDayTrip(...)` auf Retry-Flow mit zentralem Routing-Backoff umgestellt.
  - Single-Day-Edit-Rebuild auf echte Endpunkte korrigiert.
- `test/repositories/trip_generator_daytrip_test.dart`
  - Neue Regression-Tests fuer Retry-Erfolg, erweitertes Single-POI-Rescue und Zielerhalt bei `removePOI`/`addPOIToTrip`/`rerollPOI`.

---

## [1.10.35] - 2026-02-08

### Social Publish + POI Preview + Daytrip Stabilisierung

#### Behoben
- **POI-Veroeffentlichung schlaegt nicht mehr wegen fehlender RPC fehl**
  - Fallback auf direkten Insert in `poi_posts`, falls `publish_poi_post` in der Ziel-DB noch fehlt (`PGRST202`).
  - Detail-Antwort wird weiterhin ueber `get_public_poi` aufgeloest, inklusive robustem Fallback.
- **Veroeffentlichte Trips enthalten wieder vollstaendige Stop-Metadaten**
  - Beim Publish werden Source-POIs aus aktuellem Trip/Random-Trip gesammelt und in `tripData.stops` mit Feldern wie `score`, `tags`, `highlights`, `isMustSee`, `imageUrl` persistiert.
- **POI-Vorschau in oeffentlichen Trips ist korrekt verlinkt**
  - Stop-Parsing normalisiert jetzt `poiId`/`poi_id`, `lat`/`latitude`, `lng`/`longitude`, Kategorie- und Must-See-Felder.
  - Tap auf Mini-Tiles oeffnet den richtigen POI-Detailscreen; POI wird vorher in den lokalen State geladen.
- **POI-Detail via Deeplink/Browse ohne vorhandenen POI-State funktioniert stabil**
  - Neuer `ensurePOIById(...)` Flow laedt den POI bei Bedarf aus dem Repository nach und startet danach Enrichment.
- **AI Tagestrip findet robuster POIs bei duennen Regionen**
  - Mehrstufige Fallback-Kaskade (streng -> relaxed -> rescue) mit groesseren Radius-/Korridorgrenzen und abgesenktem Mindestscore.
  - Endpoint- und Midpoint-Rescue-Queries sowie tolerantere Korridorfilter verhindern fruehe "keine POIs gefunden"-Abbrueche.

#### Technisch
- `lib/data/repositories/social_repo.dart`
  - `publishTrip(..., sourcePOIs)` erweitert, `_tripToJson(...)` mit stopbezogenen Metadaten.
  - `publishPOI(...)` mit `PostgrestException(PGRST202)`-Fallback `_publishPOIWithDirectInsert(...)`.
- `lib/features/social/widgets/publish_trip_sheet.dart`
  - Source-POIs aus `tripStateProvider` und `randomTripNotifierProvider` zusammengefuehrt und an Repo uebergeben.
- `lib/features/social/trip_detail_public_screen.dart`
  - Robuste Stop-Normalisierung + POI-Erzeugung fuer Vorschau, Import und Deep-Link-Verhalten.
- `lib/features/poi/providers/poi_state_provider.dart`
  - `selectPOIById(...)` liefert bool statt Exception; neues `ensurePOIById(...)`.
- `lib/features/poi/poi_detail_screen.dart`
  - Nutzt `ensurePOIById(...)` und enriched nur, wenn erforderlich.
- `lib/data/repositories/poi_repo.dart`, `lib/data/repositories/supabase_poi_repo.dart`
  - `loadPOIById(...)` ergaenzt (Supabase + curated Fallback).
  - `loadPOIsInRadius(...)` / `loadPOIsInBounds(...)` um `minScore` erweitert.
- `lib/data/repositories/trip_generator_repo.dart`
  - Daytrip-Fallbacks, erweiterte Endpoint-Suche, toleranteste Korridorselektion.
- `supabase/migrations/20260208103000_poi_publish_rpc_fix.sql`
  - Definiert/aktualisiert `publish_poi_post(...)` und `get_public_poi(...)`.
- `docs/guides/BACKEND-SETUP.md`
  - Klarstellung: Migrationen `011` und `012` (bzw. neue CLI-Migration) sind fuer POI-Posts erforderlich.
- `test/repositories/trip_generator_daytrip_test.dart`
  - Test-Fakes an neue `minScore`-Signaturen angepasst.

---

## [1.10.25] - 2026-02-07

### AI Euro Trip Stabilisierung

#### Behoben
- **700-km-Hardlimit pro Tag wird jetzt strikt erzwungen**
  - Tagesplanung und Day-Edits validieren das Limit hart statt nur zu warnen.
  - Bei unloesbaren Verstoessen wird mit klarer `TripGenerationException` abgebrochen.
- **Tagesuebergabe ist konsistent**
  - Tag `N+1` startet exakt am Endpunkt von Tag `N` (POI oder ausgewaehltes Hotel).
  - Tagesexport und Navigation verwenden den echten Tagesendpunkt, nicht den ersten Stop des Folgetags.
- **Hotel-Logik fuer Mehrtagetrips erweitert**
  - Hotelradius auf maximal 20 km gesetzt.
  - Rich-Hoteldaten (Rating, Reviews, Highlights, Amenities, Kontakt, Booking-Link) integriert.
  - Falls Reviews vorhanden sind, werden Hotels mit mindestens 10 Reviews bevorzugt/zugelassen; transparenter Fallback bleibt aktiv.
- **Datumslogik fuer Booking korrigiert**
  - Booking-Links werden pro Uebernachtungstag mit korrektem Check-in/Check-out erstellt.
  - Trip-Startdatum wird im Random Trip Flow erfasst und persistiert.

#### Technisch
- `backend/api/hotels/search.ts` (neu): Google Places Hotel-Suche + Detailanreicherung.
- `lib/core/algorithms/day_planner.dart`: strukturierte Limit-Validierung und Endpunkt-korrekte Distanzberechnung.
- `lib/data/repositories/trip_generator_repo.dart`: Retry-/Abbruchlogik, Day-Edit-Hardlimit, Hotel-Dedupe und Hotel-Auswahl in echte Stop-Kette.
- `lib/data/services/hotel_service.dart`: Backend-first Hotelpipeline mit Overpass-Fallback.
- Neue/erweiterte Tests:
  - `test/algorithms/day_planner_test.dart`
  - `test/models/trip_model_test.dart`
  - `test/constants/trip_constants_test.dart`
  - `test/services/hotel_service_test.dart`

---

## [1.10.24] - 2026-02-07

### AI Tagestrip Fixes

#### Behoben
- **Reiseentfernung (km) wird jetzt als echtes Distanzlimit angewendet**
  - Bisher wurde `radiusKm` beim Tagestrip primär als Suchradius genutzt.
  - Die finale Route wird jetzt zusätzlich auf das eingestellte Distanzlimit begrenzt.
- **Tagestrip-Radius bleibt beim Moduswechsel erhalten**
  - Beim Wechsel zwischen `AI Tagestrip` und `AI Euro Trip` wird der gewählte Tagestrip-Wert nicht mehr auf 100 km zurückgesetzt.

#### Technisch
- `lib/data/repositories/trip_generator_repo.dart`
  - Distanz-Begrenzung per `trimRouteToMaxDistance(...)` in `generateDayTrip(...)`.
- `lib/features/random_trip/providers/random_trip_provider.dart`
  - Persistenter Tagestrip-Radius (`_lastDayTripRadiusKm`) statt Hard-Reset.
- `test/algorithms/route_optimizer_test.dart`
  - Regression-Tests für Distanz-Trim ergänzt.

---

## [1.7.19] - 2026-01-31

### UI-Verbesserungen

#### GPS Reverse Geocoding
- **GPS-Standorte zeigen echte Stadtnamen** (z.B. "München" statt "Mein Standort")
  - GPS-Button im Schnell-Modus verwendet Nominatim Reverse Geocoding
  - Automatisches Zentrieren beim App-Start zeigt Stadtname
  - Fallback auf "Mein Standort" bei Fehler
- **Dateien**: `lib/features/map/map_screen.dart` (Zeilen 630, 527)

#### Unified Weather Widget
- **Drei Wetter-Widgets zu einem intelligenten Widget zusammengeführt**
  - Ersetzt: `WeatherRecommendationBanner`, `WeatherBar`, `WeatherAlertBanner`
  - Automatischer Modus-Wechsel zwischen Standort-Wetter und Route-Wetter
  - Ein-/Ausklappbar mit persistiertem State
  - Integrierte Warnungen und Toggles (Wetter-Kategorien, Indoor-Filter)
  - Dark Mode vollständig kompatibel
- **Dateien**:
  - **NEU**: `lib/features/map/widgets/unified_weather_widget.dart`
  - **GELÖSCHT**: `lib/features/map/widgets/weather_bar.dart`
  - **GELÖSCHT**: `lib/features/map/widgets/weather_alert_banner.dart`
- **Details**: [Dokumentation/CHANGELOG-v1.7.19.md](Dokumentation/CHANGELOG-v1.7.19.md)

---

## [1.7.18] - 2026-01-31

### Snackbar Auto-Dismiss

#### Verbessert
- **"Route gespeichert" Snackbar verschwindet nach 1 Sekunde** (statt 4 Sekunden Flutter-Standard)
  - Gilt für beide Modi: Reguläre Route & AI Trip speichern
  - "Anzeigen" Button bleibt innerhalb der Sekunde funktionsfähig
  - Schnellere, weniger aufdringliche UX

#### Technisch
- **Dateien**: `lib/features/trip/trip_screen.dart` (Zeilen 221, 293)
- `duration: const Duration(seconds: 1)` Parameter zu beiden SnackBar-Widgets hinzugefügt
- Methoden: `_saveRoute()` und `_saveAITrip()`

---

## [1.7.17] - 2026-01-31

### Persistente Wetter-Widgets

#### Behoben
- **Wetter-Widgets verschwanden bei Navigation** zwischen Screens
  - Problem: Weather Provider hatten kein `keepAlive: true` → State wurde zurückgesetzt
  - Folgen: 15-Minuten-Cache funktionierte nicht, redundante API-Calls (5-10/Min)

#### Verbessert
- **`keepAlive: true` für Weather Provider**
  - WeatherChip bleibt sichtbar bei Screen-Wechseln
  - WeatherBar bleibt geladen (keine redundanten API-Calls)
  - Cache funktioniert korrekt (15 Minuten gültig)
  - **Performance:** ~90% weniger API-Calls zu Open-Meteo

#### Technisch
- **Dateien**: `lib/features/map/providers/weather_provider.dart` (Zeilen 108, 266)
- `RouteWeatherNotifier`: `@riverpod` → `@Riverpod(keepAlive: true)`
- `LocationWeatherNotifier`: `@riverpod` → `@Riverpod(keepAlive: true)`
- Konsistent mit anderen Providern (account, favorites, auth, tripState, pOIState)

---

## [1.7.16] - 2026-01-31

### WeatherBar einklappbar & Dauerhafte Adress-Anzeige

#### Hinzugefügt
- **WeatherBar jetzt einklappbar**
  - Tap auf Header wechselt zwischen ein-/ausgeklappt
  - Expand-Icon (▼/▲) rotiert sanft (200ms Animation)
  - Standard: Ausgeklappt beim ersten Anzeigen
  - Mehr Platz auf der Karte

- **Dauerhafte Adress-Anzeige** (`_RouteAddressBar`)
  - Start/Ziel-Adressen bleiben sichtbar bis Route gelöscht wird
  - Distanz + Dauer wenn Route berechnet (z.B. "5.2 km • 12 Min.")
  - Dark-Mode kompatibel
  - Position: Zwischen Wetter-Empfehlung und Suchleiste (Schnell-Modus)

#### Technisch
- **WeatherBar**: `lib/features/map/widgets/weather_bar.dart`
  - Konvertiert zu `ConsumerStatefulWidget` mit `_isExpanded` State
  - `AnimatedCrossFade` für Content, `AnimatedRotation` für Icon
- **RouteAddressBar**: `lib/features/map/map_screen.dart` (Zeilen 2073-2190)
  - Neue Widgets: `_RouteAddressBar`, `_AddressRow`
  - Basiert auf `_CompactCategorySelector` Pattern

---

## [1.7.15] - 2026-01-31

### GPS-Button Optimierung

#### Verbessert
- **Redundanter GPS-Button entfernt** - FloatingActionButton rechts unten (unter Settings) wurde entfernt
  - Vorher: 3 GPS-Buttons (Schnell-Modus, AI Trip, Floating rechts)
  - Nachher: 2 GPS-Buttons (Schnell-Modus, AI Trip) - klarere UX
- **Verbleibende GPS-Buttons**:
  - GPS-Button in der Schnell-Modus Suchleiste (setzt Startpunkt)
  - GPS-Button im AI Trip Panel (setzt Startpunkt für AI Trip)

#### Behoben
- **UX-Problem**: GPS-Button erschien doppelt - einmal in Suchleiste, einmal als Floating Button
- GPS-Funktion jetzt nur noch dort, wo sie konkret gebraucht wird (Startpunkt setzen)

#### Technisch
- **Dateien**: `lib/features/map/map_screen.dart` (Zeilen 403-417 entfernt)
- **Behält**: WeatherChip und Settings-Button als Floating Buttons
- `_centerOnLocation()` Methode bleibt für zukünftige Verwendung

---

## [1.7.14] - 2026-01-31

### GPS-Standort-Synchronisation zwischen Modi

#### Hinzugefügt
- **Automatische Standort-Synchronisation** beim Modus-Wechsel
  - AI Trip → Schnell-Modus: GPS-Standort wird als Startpunkt übertragen
  - Schnell-Modus → AI Trip: Startpunkt wird ins AI Trip Panel übertragen
  - Nur wenn Ziel-Modus noch keinen Startpunkt hat (kein Überschreiben)
- **Neue Methode** `_syncLocationBetweenModes()` in `map_screen.dart`
  - Prüft aktuellen Modus und synchronisiert Standort-Daten
  - Verwendet `randomTripNotifierProvider.setStartLocation()` und `routePlannerProvider.setStart()`
  - Debug-Logging für Transparenz

#### Geändert
- `_ModeToggle.onModeChanged` Callback erweitert um Synchronisations-Aufruf
- GPS-Button-Verhalten jetzt konsistent zwischen beiden Modi

#### Behoben
- **UX-Problem**: GPS-Button im AI Trip Modus setzte Standort nicht im Schnell-Modus
- Kein redundantes GPS-Abfragen mehr beim Modus-Wechsel
- Bessere Akku-Effizienz durch weniger GPS-Requests

#### Technisch
- **Dateien**: `lib/features/map/map_screen.dart` (Zeile 663-697)
- **Provider**: `randomTripNotifierProvider`, `routePlannerProvider`
- **Verhalten**: Conditional sync nur wenn Ziel-State leer ist

---

## [1.7.12] - 2026-01-30

### Wetter-Marker auf der Route

#### Hinzugefügt
- **Wetter-Marker auf Route** - 5 Wetter-Icons entlang der berechneten Route auf der Karte
  - Wetter-Emoji (☀️/⛅/🌧️/⛈️) mit Temperaturanzeige
  - Farbcodierter Hintergrund (Grün/Gelb/Orange/Rot) nach Wetterlage
  - Warning-Badge (!) bei schlechtem Wetter oder Unwetter
  - Pill-Form (60x32 px) zur Unterscheidung von POI-Markern
- **Tap-Details** - Bottom Sheet bei Klick auf Wetter-Marker
  - Ort-Label ("Start", "Ziel" oder "Routenpunkt X von 5")
  - Großes Wetter-Icon + Temperatur + Beschreibung
  - Gefühlte Temperatur, Wind, Niederschlag, Regenwahrscheinlichkeit
  - Kontextbezogene Empfehlung je nach Wetterlage
- **Auto-Wetter-Laden** - Wetter wird automatisch geladen bei:
  - Normale Routenberechnung (Start/Ziel)
  - AI Trip Preview (nach Generierung)
  - Gespeicherte Route laden (aus Favoriten)

#### Neu
- `RouteWeatherMarker` Widget - Wetter-Marker-Anzeige auf der Karte
- `showRouteWeatherDetail()` - Bottom Sheet mit Wetter-Details
- `_setupWeatherListeners()` - Automatisches Wetter-Laden für alle Routentypen

#### Technisch
- Layer-Reihenfolge: Wetter-Marker zwischen Route und POI-Markern
- Listener auf `routePlannerProvider`, `randomTripNotifierProvider`, `tripStateProvider`
- Dark Mode Support mit brightness-abhängigen Farbvarianten
- Open-Meteo API × 5 (mit 100ms Delay zwischen Anfragen)

#### Farbschema
| Wetterlage | Hintergrund | Text | Badge |
|------------|-------------|------|-------|
| ☀️ Gut | Grün shade50 | Grün shade800 | - |
| ⛅ Wechselhaft | Amber shade50 | Amber shade800 | - |
| 🌧️ Schlecht | Orange shade50 | Orange shade800 | ⚠️ |
| ⛈️ Unwetter | Rot shade50 | Rot shade800 | ⚠️ |

---

## [1.7.7] - 2026-01-29

### POI-Bildquellen optimiert & Chat-Bilder

#### Verbessert
- **OSM-Tags aus Overpass** - `image`, `wikimedia_commons`, `wikidata`, `wikipedia` Tags werden jetzt extrahiert und als Bildquelle genutzt (0 zusätzliche API-Calls)
- **Wikimedia Geo-Suche** - Radius von 5km auf 10km erhöht (mehr Treffer in ländlichen Gebieten)
- **Titel-Suche mit Suchvarianten** - Umlaute normalisieren (ä→ae), Präfix-Wörter entfernen (Schloss, Burg, Kloster etc.)
- **EN-Wikipedia Fallback** - Englische Wikipedia als Fallback wenn deutsche kein Bild liefert
- **Batch-Enrichment Fix** - Wikipedia-POIs mit Beschreibung aber ohne Bild bekommen jetzt Wikimedia Geo-Suche als Fallback

#### Hinzugefügt
- **Chat-Bilder** - POI-Karten im AI-Chat zeigen jetzt Bilder an
  - POIs erscheinen sofort mit Kategorie-Icons
  - Bilder laden im Hintergrund nach (1-3 Sekunden)
  - In-Place-Update der Chat-Nachricht mit angereicherten POIs
  - `mounted`-Check und Index-Bounds-Check für Sicherheit

#### Technisch
- `_parseOverpassPOI()` erweitert: extrahiert OSM Bild-Tags
- `_getSearchVariants()` Methode: erzeugt Suchvarianten ohne Umlaute/Präfixe
- `_fetchEnglishWikipediaImage()` Methode: EN-Wikipedia Fallback
- `ApiEndpoints.wikipediaEnSearch`: Neuer Endpoint für EN-Wikipedia
- `enrichPOIsBatch()`: Wikimedia Fallback für Wikipedia-POIs ohne Bild
- `_handleLocationBasedQuery()`: Hintergrund-Enrichment mit In-Place-Update

#### Bild-Trefferquote
| Version | Trefferquote |
|---------|-------------|
| v1.3.6 | ~60% |
| v1.3.7 | ~85% |
| v1.7.7 | ~95% |

---

## [1.7.6] - 2026-01-29

### Erweiterte Wetter-Funktionen

#### Hinzugefügt
- **Weather-Chip** - Kompakter Wetter-Anzeiger oben rechts auf der Karte
  - Zeigt aktuelle Temperatur und Wetter-Icon
  - Farbcodiert nach Wetter-Zustand (grün/gelb/orange/rot)
  - Bei Tap: Öffnet Wetter-Details-Sheet
- **Wetter-Alert-Banner** - Proaktive Warnungen bei schlechtem Wetter
  - Erscheint automatisch bei Unwetter/schlechtem Wetter am Standort
  - Spezifische Nachrichten für Gewitter, Schnee, Regen, Sturm
  - Dismiss-Button (einmal pro Session)
- **Wetter-Details-Sheet** - Vollständiges Wetter-Dashboard
  - 7-Tage-Vorhersage horizontal scrollbar
  - UV-Index mit Empfehlung (Niedrig/Mittel/Hoch/Sehr hoch/Extrem)
  - Sonnenauf- und Sonnenuntergang
  - POI-Empfehlungen basierend auf Wetter
- **WeatherBadge in POI-Karten** - Wetter-Empfehlungen auf POI-Cards
  - "Empfohlen" Badge für Indoor-POIs bei schlechtem Wetter
  - "Ideal" Badge für Outdoor-POIs bei gutem Wetter
  - "Regen" / "Unwetter" Warnung für Outdoor-POIs
- **AI Trip Wetter-Integration** - Wetter-basierte Kategorieauswahl
  - Wetter-Empfehlungs-Banner im AI Trip Panel
  - "Anwenden" Button für automatische Kategorie-Vorauswahl
  - Indoor-Kategorien bei schlechtem Wetter, Outdoor bei gutem

#### Neu
- `LocationWeatherNotifier` - Standort-Wetter ohne aktive Route
  - 15-Minuten-Cache für API-Effizienz
  - Automatisches Laden bei GPS-Position
- `WeatherChip` Widget - Kompakte Wetter-Anzeige
- `WeatherAlertBanner` Widget - Proaktive Warnungen
- `WeatherDetailsSheet` - Vollständiges Wetter-Dashboard
- `applyWeatherBasedCategories()` - Automatische Kategorieauswahl

#### Technisch
- Open-Meteo API für kostenlose Wetterdaten (kein API-Key nötig)
- WMO Weather Codes für Wetterklassifizierung
- 15-Minuten-Cache reduziert API-Aufrufe
- Session-basierter Dismiss-State für Alert-Banner

---

## [1.7.5] - 2026-01-29

### Route Löschen Button für AI-Chat Routen

#### Hinzugefügt
- **Route löschen Button** erscheint jetzt auch nach AI-Chat Routengenerierung
- Konsistentes Verhalten zwischen Schnell-Modus und AI-Chat

---

## [1.7.4] - 2026-01-29

### Auto-Route von GPS-Standort zu POI

#### Hinzugefügt
- **Auto-Route-Erstellung** - Beim Hinzufügen eines POIs ohne aktive Route
  - GPS-Position wird als Startpunkt verwendet
  - Route wird automatisch berechnet
  - Navigation zum Trip-Tab

---

## [1.7.3] - 2026-01-28

### POI-Foto Batch-Enrichment

#### Verbessert
- **7x schneller** - Batch-API für Wikipedia Multi-Title-Query
- Bis zu 50 POIs in einer Anfrage statt einzeln
- Reduzierte API-Calls von ~160 auf ~4 für 20 POIs

---

## [1.7.2] - 2026-01-28

### AI-Chat mit standortbasierten POI-Vorschlägen

#### Hinzugefügt
- **GPS-basierte POI-Suche** im AI-Chat
- Radius-Einstellung (10-100km)
- Anklickbare POI-Karten mit Bildern
- TripContext mit Standort-Informationen

---

## [1.7.1] - 2026-01-28

### Auto-Zoom Verbesserung

#### Behoben
- MapController-Timing-Fix für zuverlässiges Auto-Zoom

---

## [1.7.0] - 2026-01-28

### Auto-Navigation & Zoom

#### Hinzugefügt
- **Auto-Navigation** zum Trip-Tab nach Route-Berechnung
- **Auto-Zoom** auf Route beim Tab-Wechsel
- **"Auf Karte anzeigen" Button** im TripScreen

---

## [1.6.9] - 2026-01-28

### POI-Fotos überall

#### Hinzugefügt
- POI-Fotos in Favoriten, Trip-Stops, AI Trip Preview
- Auto-Enrichment beim Laden

---

## [1.6.8] - 2026-01-28

### GPS-Dialog & Löschbutton & POI-Details Fix

#### Behoben
- GPS-Dialog bei "Überrasch mich!" wenn GPS deaktiviert
- Löschbutton erscheint nach AI Trip Generierung
- POI-Details unter "Deine Route" funktionieren

---

## [1.6.7] - 2026-01-28

### POI-Detail Fotos & Highlights Fix

#### Behoben
- Fotos und Highlights werden nach Routenberechnung korrekt angezeigt
- Await statt unawaited für Enrichment

---

## [1.6.6] - 2026-01-28

### POI-Foto CORS & Rate-Limit Fix

#### Behoben
- Wikidata SPARQL CORS-Header
- Rate-Limit-Handling (HTTP 429)
- Concurrency von 5 auf 3 reduziert

---

## [1.6.5] - 2026-01-28

### TripScreen vereinfacht

#### Geändert
- Nur noch berechnete Routen angezeigt

---

## [1.6.4] - 2026-01-28

### POI Hinzufügen ohne Snackbar

#### Geändert
- Kein Snackbar mehr beim POI-Hinzufügen (weniger störend)

---

## [1.6.3] - 2026-01-28

### Euro Trip Route-Anzeige Fix

#### Behoben
- **Route erscheint nicht auf Karte** - Nach Generierung eines Euro Trips wurde die Route nicht angezeigt
- `RandomTripNotifier` hatte kein `keepAlive: true` - State ging verloren
- Route-Priorität in `map_view.dart` war falsch - AI Trip Preview hat jetzt Vorrang
- Start-Marker Priorität gefixt

---

## [1.6.2] - 2026-01-28

### Euro Trip Performance-Fix

#### Behoben
- **Euro Trip "lädt ewig"** - Wikipedia Grid-Suche war extrem langsam bei großen Radien
- Dynamische Grid-Size mit Maximum von 36 Zellen (6×6)
- 45 Sekunden Timeout verhindert endloses Warten

#### Performance
| Radius | Zeit vorher | Zeit nachher |
|--------|-------------|--------------|
| 600km | ~10 Min | ~4s |
| 1200km | ~40 Min | ~4s |

---

## [1.6.1] - 2026-01-27

### POI-Marker Direktnavigation

#### Geändert
- **POI-Marker Tap** - Klick öffnet sofort POI-Details (kein Preview-Sheet mehr)
- Schnellerer Zugriff auf POI-Informationen

---

## [1.6.0] - 2026-01-27

### POI-Fotos Lazy-Loading

#### Hinzugefügt
- **Alle POI-Bilder laden** - Bilder werden beim Scrollen automatisch nachgeladen
- Lazy-Loading für bessere Performance
- Keine fehlenden Bilder mehr in der POI-Liste

---

## [1.5.9] - 2026-01-27

### GPS-Teststandort entfernt

#### Geändert
- **Kein München-Fallback mehr** - GPS-Button zeigt Dialog statt Teststandort
- POI-Liste verhält sich konsistent mit MapScreen

---

## [1.5.8] - 2026-01-27

### Login-Screen Fix

#### Behoben
- **Formular immer sichtbar** - Login-Formular wurde manchmal nicht angezeigt
- Warnungen bei fehlender Supabase-Config

---

## [1.5.7] - 2026-01-26

### Mehrtägige Euro Trips

#### Hinzugefügt
- **Tagesweiser Google Maps Export** - Jeder Tag einzeln exportierbar
- **Automatische Tagesberechnung** - 600km = 1 Tag
- **Max 9 POIs pro Tag** - Google Maps Waypoint-Limit beachtet
- **Tag-Tab-Selector** - Übersichtliche Tagesauswahl
- **ActiveTripService** - Persistenz für aktive Trips

#### Technisch
- `TripConstants` für zentrale Konfiguration
- `DayPlanner` Algorithmus für optimale Tagesaufteilung

---

## [1.5.6] - 2026-01-26

### UI-Verbesserungen

#### Hinzugefügt
- **Floating Buttons ausblenden bei AI Trip** - Einstellungen- und GPS-Button werden ausgeblendet wenn AI Trip aktiv ist
- Aufgeräumtere Oberfläche beim Planen eines AI Trips

#### Technisch
- `map_screen.dart`: Bedingung `if (_planMode == MapPlanMode.schnell)` für Floating Buttons

---

## [1.5.5] - 2026-01-26

### POI-Card Layout-Fix

#### Behoben
- **POI-Liste zeigt alle POIs** - IntrinsicHeight + double.infinity Kombination verursachte Layout-Fehler
- Feste Card-Höhe (96px) statt dynamischer Berechnung

---

## [1.5.4] - 2026-01-26

### GPS-Dialog

#### Geändert
- **GPS-Button Verhalten** - Bei deaktiviertem GPS erscheint jetzt ein Dialog statt München-Fallback
- Dialog fragt ob GPS-Einstellungen geöffnet werden sollen

---

## [1.5.3] - 2026-01-26

### POI-Liste & Foto-Fix

#### Behoben
- **detourKm Filter** - Wird nur noch bei aktivem routeOnlyMode angewendet
- **Enrichment Cache** - Speichert nur POIs mit Bild (nicht ohne)
- maxDetourKm von 45 auf 100 km erhöht

---

## [1.5.2] - 2026-01-26

### POI-Liste Filter & Debug Fix

#### Behoben
- Filter werden automatisch zurückgesetzt wenn keine Route vorhanden
- POIs werden neu geladen wenn Liste leer ist

---

## [1.5.1] - 2026-01-26

### POI-Liste Race Condition Bugfix

#### Behoben
- **Atomare State-Updates** - `_updatePOIInState()` Methode für parallele Enrichment-Operationen
- POIs verschwanden nicht mehr nach dem Enrichment

---

## [1.5.0] - 2026-01-25

### AI Trip direkt auf MapScreen

#### Hinzugefügt
- **AI Trip Panel auf MapScreen** - Karte bleibt immer sichtbar während der Trip-Planung
- **AI Trip POI-Marker** - Nummerierte Icons mit Kategorie-Symbol auf der Karte
- **Auto-Modus-Wechsel** - Panel blendet nach Trip-Generierung automatisch aus
- **Auto-Zoom** - Karte zeigt generierte Route automatisch

---

## [1.4.9] - 2026-01-25

### AI Trip Navigation Fix

#### Behoben
- AI Trip öffnet keine separate Seite mehr
- Query-Parameter Support (`/trip?mode=ai`)

---

## [1.4.8] - 2026-01-25

### Integrierter Trip-Planer

#### Hinzugefügt
- **Mode-Tabs** - Umschalten zwischen "Schnell" und "AI Trip"
- **Aufklappbare Kategorien** - Übersichtliche POI-Auswahl
- AI Trip direkt im Trip-Screen integriert

---

## [1.4.7] - 2026-01-25

### Erweiterter Radius

#### Geändert
- **Tagesausflug** - 30-300 km (vorher max 200 km)
- **Euro Trip** - 100-5000 km (vorher max 3000 km)
- Quick-Select Buttons angepasst

---

## [1.4.5/1.4.6] - 2026-01-24

### POI-Card Redesign & AI-Chat

#### Hinzugefügt
- **POI-Card Redesign** - Kompaktes horizontales Layout
- **AI-Chat Verbesserungen** - Alle Vorschläge funktionieren

#### Behoben
- POI-Liste Bugfixes
- RouteOnlyMode wird korrekt zurückgesetzt

---

## [1.4.4] - 2026-01-24

### AI Trip POI-Bearbeitung

#### Hinzugefügt
- **POI-Löschen** - Einzelne POIs aus AI-Trip entfernen (min. 2 müssen bleiben)
- **POI-Würfeln** - Einzelnen POI neu würfeln (nicht gesamten Trip)
- **Per-POI Loading** - Individuelle Ladeanzeige pro POI

---

## [1.4.0-1.4.3] - 2026-01-24

### Neues Logo & Bugfixes

#### Hinzugefügt
- **Neues App-Logo** - Modernes Design mit App-Farben (Blau/Grün)
- **Mehr POIs** - Filter gelockert

#### Behoben
- Google Maps Export Fix
- Trip-Stops Bugfix
- Auto-Zoom auf Route

---

## [1.3.7] - 2026-01-23

### POI-Verbesserungen & Foto-Laden

#### Hinzugefügt
- **Route-POIs anklickbar**: Alle POIs in der Trip-Liste öffnen jetzt POI-Details bei Tap
- **Kategorie-basierte Bildsuche**: Wikimedia Commons Kategorie-Suche als 3. Fallback
- **Wikidata-Bilder**: P18 (Bild), P154 (Logo), P94 (Wappen) als Fallback-Quellen
- **Bereinigter Suchname**: Klammern und Bindestriche werden für bessere Treffer entfernt

#### Geändert
- Wikimedia Geo-Suche: Radius 2km → 5km, Ergebnisse 8 → 15
- Wikimedia Titel-Suche: Ergebnisse 5 → 10
- URL-Validierung erweitert: .gif, .svg, Wikimedia-spezifische URLs
- `_applyEnrichment()`: Alle Felder werden übertragen (thumbnailUrl, foundedYear, architectureStyle, hasWikidataData, isEnriched)

#### Behoben
- TripStopTile hatte keinen onTap Handler → POI-Details nicht erreichbar
- Wikidata-Bilder wurden nicht als Fallback genutzt
- foundedYear und architectureStyle wurden nicht auf POI übertragen

#### Technisch
- `trip_stop_tile.dart`: `onTap` Parameter + GestureDetector hinzugefügt
- `trip_screen.dart`: `onTap` navigiert zu `/poi/${stop.id}`
- `poi_enrichment_service.dart`: 3 neue Methoden (`_cleanSearchName`, `_convertToThumbUrl`, Kategorie-Suche)

---

## [1.3.6] - 2026-01-23

### Performance-Optimierungen

#### Hinzugefügt
- Paralleles POI-Laden: Curated, Wikipedia und Overpass werden gleichzeitig geladen (45% schneller)
- Region-Cache: POIs werden nach Region gecached (7 Tage gültig)
- Batch-Enrichment mit Rate-Limiting: 3 POIs pro Batch mit 500ms Pause

#### Geändert
- `loadPOIsInRadius()` und `loadAllPOIs()` nutzen jetzt `Future.wait()`
- Bilder werden auf Zielgröße skaliert (60% weniger Speicherverbrauch)
- ListView mit `cacheExtent: 500` für flüssigeres Scrollen

#### Performance-Vergleich
| Metrik | v1.3.5 | v1.3.6 |
|--------|--------|--------|
| POI-Laden (kalt) | ~5.5s | ~3.0s |
| POI-Laden (Cache) | ~5.5s | ~0.1s |
| Speicherverbrauch | 100% | ~40% |

---

## [1.3.5] - 2026-01-23

### AI Trip & Remember Me

#### Hinzugefügt
- "AI Trip" Toggle ersetzt "Landschaft"-Button auf der Karte
- Automatische POI-Bereinigung bei neuer Route
- "Anmeldedaten merken" Checkbox im Login-Screen

#### Geändert
- Random-Trip umbenannt zu "AI Trip" (AI Tagesausflug, AI Euro Trip)
- Mode-Icon von Auto zu Roboter geändert

#### Entfernt
- Zufalls-Trip FloatingActionButton (Funktion über Toggle verfügbar)
- Zoom-Buttons (+/-) für saubereres Design

---

## [1.3.4] - 2026-01-23

### Route Löschen & UI-Updates

#### Hinzugefügt
- X-Buttons zum Löschen von Start/Ziel in der Suchleiste
- "Route löschen" Button unterhalb des Fast/Scenic-Toggles
- "Gesamte Route löschen" Menüpunkt im Trip-Screen

#### Geändert
- Android Gradle Plugin: 8.5.0 → 8.9.1
- Gradle: 8.7 → 8.11.1
- NDK: 26.1.10909125 → 28.2.13676358

---

## [1.3.1] - 2026-01-23

### Credentials-Sicherung

#### Behoben
- **SICHERHEIT:** Supabase-Credentials aus Quellcode entfernt
- `--dart-define` für Build-Zeit Credentials implementiert

#### Hinzugefügt
- `run_dev.bat` und `build_release.bat` Build-Scripts
- `.env.local` als Referenz-Datei

#### Sicherheits-Vergleich
| Methode | Sicherheit |
|---------|------------|
| Hardcoded im Code | Kritisch |
| flutter_dotenv + Asset | Kritisch |
| --dart-define | Mittel |
| Backend-Proxy | Gut |

---

## [1.3.0] - 2026-01-22

### Google Maps Export & Route Teilen

#### Hinzugefügt
- Google Maps Export: Route direkt in Google Maps öffnen (mit Waypoints)
- Route Teilen: System-Share-Dialog (WhatsApp, Email, SMS, etc.)
- Share-Inhalt: Adressen, Distanz, Dauer, POI-Stops, Google Maps Link

#### Geändert
- SnackBar verschwindet nach 2 Sekunden automatisch (floating)

---

## [1.2.9] - 2026-01-22

### Route Starten & Wetter-Warnungen

#### Hinzugefügt
- "Route Starten" Button mit Distanz und Dauer-Anzeige
- WeatherBar mit 5 Messpunkten entlang der Route
- Wetter-Warnungen (Sturm, Gewitter, Schnee, Regen)
- Indoor-Filter Toggle bei schlechtem Wetter
- Route-Only-Modus für POIs
- `RouteSessionProvider` für aktive Routen-Sessions

#### Behoben
- Gast-Modus funktioniert jetzt (keepAlive für AccountNotifier)
- Favoriten werden gespeichert (keepAlive für FavoritesProvider)
- Langsamer App-Start nach Logout (rekursive Schleife behoben)

---

## [1.2.8] - 2026-01-22

### Animiertes Onboarding

#### Hinzugefügt
- 3 animierte Onboarding-Seiten vor dem Login
- Seite 1: Animierte Route mit POI-Markern
- Seite 2: Pulsierende AI-Kreise
- Seite 3: Phone-Cloud Sync Animation
- Page-Indicator mit animierten Punkten
- First-Time Detection via Hive

#### Technisch
- CustomPainter für Route-Animation
- 5 AnimationControllers für AI-Circle
- Daten-Partikel-Animation

---

## [1.2.7] - 2026-01-22

### Favoriten-System & POI-Bilder

#### Behoben
- LatLng Serialisierung für Routen-Favoriten
- POI-Favorit-Button implementiert (war nur TODO)
- Dynamisches Favorit-Icon (rot wenn favorisiert)
- sharing_service.dart Fehler

#### Hinzugefügt
- Route-Speichern-Button im Trip-Screen
- Supabase-Sync für Favoriten
- Pre-Enrichment für POI-Bilder (Top 20)
- CachedNetworkImage in Favoriten-Screen

#### Dark Mode Fixes
- AppTheme.* → colorScheme.* Migration
- Dynamische Schatten basierend auf Theme

---

## [1.2.6] - 2026-01-22

### Supabase Cloud Integration

#### Hinzugefügt
- Cloud-Sync für Trips, Favoriten und Achievements
- Email/Passwort Authentifizierung
- Backend API-Proxy für OpenAI (Key-Schutz)
- Auth-Screens (Login, Register, Forgot Password)
- Rate-Limiting: 100 Chat / 20 Trip-Plans pro Tag

#### Backend-Struktur
```
backend/
├── api/ai/chat.ts
├── api/ai/trip-plan.ts
├── api/health.ts
├── lib/openai.ts
└── supabase/migrations/
```

#### Sicherheit
- OpenAI-Key aus Flutter-Code entfernt
- Backend-Proxy unter Vercel deployed

---

## [1.2.5] - 2026-01-21

### POI-System Erweiterung

#### Hinzugefügt
- POI Enrichment Service (Wikipedia, Wikimedia, Wikidata)
- POI Highlights: UNESCO, Must-See, Geheimtipp, Historisch, Familienfreundlich
- Map-Marker mit Kategorie-Icons
- POI-Preview Sheet bei Tap auf Marker
- POI State Management (`POIStateNotifier`)
- Hive-basierter POI Cache (7 Tage Region, 30 Tage Enrichment)

#### Neue POI-Felder
- `foundedYear`, `architectureStyle`, `isEnriched`, `thumbnailUrl`

#### APIs integriert
- Wikipedia Extracts API
- Wikimedia Commons Geo-Search
- Wikidata SPARQL

---

## [1.2.4] - 2026-01-21

### AI-Trip ohne Ziel

#### Hinzugefügt
- Ziel-Feld im AI-Trip-Dialog ist jetzt optional
- GPS-Standort bei leerem Startfeld
- Interesse-zu-Kategorie Mapping (Kultur → museum, monument, etc.)

#### Hybrid-Modus
| Start | Ziel | Ergebnis |
|-------|------|----------|
| leer | leer | GPS → Random Route |
| "Berlin" | leer | Geocode → Random Route |
| beliebig | "Prag" | AI-Text-Plan |

---

## [1.2.3] - 2026-01-21

### Dark Mode Fix

#### Behoben
- Bottom Navigation Bar war immer weiß
- AppBar, Search Bar, POI Cards, Trip Tiles im Dark Mode
- System UI Overlay Style dynamisch angepasst

#### Pattern für Dark Mode
```dart
final colorScheme = Theme.of(context).colorScheme;
final isDark = Theme.of(context).brightness == Brightness.dark;

// Verwenden:
color: colorScheme.surface,
color: colorScheme.onSurface,

// Nicht verwenden:
color: Colors.white,
color: AppTheme.textPrimary,
```

---

## [1.2.2] - 2026-01-21

### Route-Planner Integration

#### Behoben
- **Hauptproblem:** Berechnete Routen erscheinen jetzt auf Trip-Screen
- Route → Trip-State Verbindung hergestellt

#### Hinzugefügt
- `RoutePlannerProvider` als State-Brücke
- Loading-Indikator während Route-Berechnung
- Start/Ziel-Adressen in Suchleiste

#### Key Fix
```dart
ref.read(tripStateProvider.notifier).setRoute(route);
```

---

## [1.2.1] - 2026-01-21

### Trip-Screen Integration

#### Hinzugefügt
- `TripStateProvider` für Routen-Anzeige
- Empty State mit "Zur Karte" und "AI-Trip generieren" Buttons
- Reorder, Remove, Clear Funktionen für Stops

#### Behoben
- Settings-Button über GPS-Button verschoben
- AI-Trip-Dialog: Weißer Text auf weißem Hintergrund
- `stop.category.icon` null-safety
- `detourKm` Type Conversion (num → int)

---

## [1.2.0] - 2026-01-21

### Profil, Favoriten & AI-Trip-Generator

#### Hinzugefügt
- Profil-Button in AppBar
- Level & XP System (Level 1-50)
- 21 Achievements (Bronze, Silber, Gold)
- Favoriten-Button mit Tab-View (Routen | POIs)
- AI-Trip-Generator mit OpenAI GPT-4o
- Suggestion Chip: "AI-Trip generieren"

#### Features im AI-Trip-Dialog
- Ziel (z.B. "Prag")
- Tage (1-7 via Slider)
- Interessen (Kultur, Natur, Geschichte, Essen, etc.)
- Startpunkt (optional)

---

## Archiv

Detaillierte Changelogs für jede Version sind unter `docs/archive/changelogs/` verfügbar.

---

## Links

- **Repository:** https://github.com/jerdnaandrej777/mapab-app
- **Dokumentation:** [docs/README.md](docs/README.md)
- **Security:** [SECURITY.md](SECURITY.md)
