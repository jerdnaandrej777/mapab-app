# Changelog

Alle wichtigen Änderungen an der MapAB Flutter App werden in dieser Datei dokumentiert.

Das Format basiert auf [Keep a Changelog](https://keepachangelog.com/de/1.0.0/),
und dieses Projekt hält sich an [Semantic Versioning](https://semver.org/lang/de/).

---

## [1.10.23] - 2026-02-08

### Behoben

- **AI Tagestrip respektiert Reiseentfernung als hartes Limit**
  - Der im UI gewählte km-Wert wird jetzt als maximale Routenlänge behandelt
  - POIs werden vorab auf Distanz-Budget geprüft (Rundreise und A→B)
  - Mehrere Generierungsversuche pro POI-Anzahl reduzieren Zufallsausreißer
  - Klare Fehlermeldung, wenn keine Route innerhalb des Limits möglich ist
- **Datei**: `lib/data/repositories/trip_generator_repo.dart`
- **Details**: [Dokumentation/CHANGELOG-v1.10.23.md](Dokumentation/CHANGELOG-v1.10.23.md)

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
