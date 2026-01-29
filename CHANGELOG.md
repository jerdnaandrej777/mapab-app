# Changelog

Alle wichtigen Änderungen an der MapAB Flutter App werden in dieser Datei dokumentiert.

Das Format basiert auf [Keep a Changelog](https://keepachangelog.com/de/1.0.0/),
und dieses Projekt hält sich an [Semantic Versioning](https://semver.org/lang/de/).

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
