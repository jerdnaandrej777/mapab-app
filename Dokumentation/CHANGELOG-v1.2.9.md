# Changelog v1.2.9 - Route Starten & Wetter-Warnungen

**Release-Datum:** 2026-01-22

## Übersicht

Diese Version fügt den "Route Starten" Button hinzu, der POIs entlang der Route lädt und Wetter-Warnungen anzeigt. Zusätzlich wurden kritische Bugs im Gast-Modus und Favoriten-System behoben.

---

## Neue Features

### 1. Route Starten Button

**Funktion:** Wenn Start und Ziel auf der Karte gewählt wurden, erscheint ein prominenter "Route Starten" Button.

**UI-Design:**
```
┌────────────────────────────────────────────────┐
│  ▶️  Route starten                             │
│      142 km · 1h 45min                        →│
└────────────────────────────────────────────────┘
```

- Gradient-Hintergrund in Primärfarbe
- Zeigt Distanz und geschätzte Dauer
- Schatten für visuelle Tiefe

### 2. WeatherBar mit Wetter-Warnungen

**Funktion:** Nach Klick auf "Route Starten" wird das Wetter entlang der Route geladen und in einer kompakten Bar angezeigt.

**Features:**
- 5 Messpunkte gleichmäßig auf der Route verteilt
- Temperaturbereich (z.B. "12° bis 18°")
- Farbcodierte Zustände (Grün/Gelb/Orange/Rot)
- Wetter-Icons für jeden Punkt

**Warnungen:**
| Bedingung | Warnung | Empfehlung |
|-----------|---------|------------|
| Wind > 60 km/h | "Sturmwarnung!" | Indoor-Filter |
| Gewitter | "Unwetterwarnung! Fahrt verschieben empfohlen." | - |
| Schnee | "Winterwetter! Schnee/Glätte möglich." | Indoor-Filter |
| Regen | "Regen erwartet." | Indoor-Filter |

### 3. Indoor-Filter Toggle

Bei schlechtem Wetter erscheint ein Toggle-Button "Nur Indoor-POIs", der:
- Outdoor-POIs ausblendet
- Museen, Kirchen, Restaurants hervorhebt
- Per Tap aktivierbar/deaktivierbar

### 4. Route-Only-Modus für POIs

**Neues Feld im POIState:**
```dart
@Default(false) bool routeOnlyMode,
```

Wenn aktiviert, werden nur POIs mit `routePosition != null` angezeigt (POIs entlang der Route).

---

## Neue Dateien

| Datei | Beschreibung |
|-------|--------------|
| `lib/features/map/providers/route_session_provider.dart` | Verwaltet aktive Routen-Sessions |

### RouteSessionState

```dart
class RouteSessionState {
  final bool isActive;        // Session aktiv?
  final bool isLoading;       // Laden läuft?
  final AppRoute? route;      // Aktive Route
  final bool poisLoaded;      // POIs geladen?
  final bool weatherLoaded;   // Wetter geladen?
  final String? error;        // Fehlermeldung

  bool get isReady => isActive && poisLoaded && weatherLoaded && !isLoading;
}
```

### RouteSession Provider

```dart
@Riverpod(keepAlive: true)
class RouteSession extends _$RouteSession {
  /// Startet Route-Session (lädt POIs + Wetter parallel)
  Future<void> startRoute(AppRoute route);

  /// Stoppt Session und setzt State zurück
  void stopRoute();
}
```

---

## Geänderte Dateien

| Datei | Änderung |
|-------|----------|
| `lib/features/map/map_screen.dart` | Route-Start-Button, Loading-Indikator, WeatherBar, Stop-Button |
| `lib/features/poi/providers/poi_state_provider.dart` | `routeOnlyMode` Feld + `setRouteOnlyMode()` Methode |
| `lib/data/providers/account_provider.dart` | `@Riverpod(keepAlive: true)` |
| `lib/data/providers/favorites_provider.dart` | `@Riverpod(keepAlive: true)` + `_ensureLoaded()` |
| `lib/features/account/splash_screen.dart` | Rekursive Schleife behoben |

---

## Datenfluss

```
User wählt Start → User wählt Ziel
         ↓
Route wird automatisch berechnet (routePlanner._tryCalculateRoute)
         ↓
"Route Starten" Button erscheint (routePlanner.hasRoute = true)
         ↓
User klickt Button → routeSession.startRoute(route)
         ↓
  ┌──────────────────────────────────────┐
  │  Parallel (Future.wait):             │
  │  - loadPOIsForRoute(route)           │
  │  - loadWeatherForRoute(coordinates)  │
  └──────────────────────────────────────┘
         ↓
routeSession.isReady = true
         ↓
  ┌──────────────────────────────────────┐
  │  UI aktualisiert:                    │
  │  - WeatherBar eingeblendet           │
  │  - POI-Marker auf Route gefiltert    │
  │  - Warnungen bei schlechtem Wetter   │
  └──────────────────────────────────────┘
```

---

## Behobene Bugs

### 1. Gast-Modus funktioniert nicht

**Problem:** "Als Gast fortfahren" erstellte einen Account, aber der User wurde nicht zur Hauptseite weitergeleitet.

**Ursache:** `AccountNotifier` war ein AutoDispose-Provider. Der State wurde disposed, sobald der Login-Screen verlassen wurde.

**Fix:** `@Riverpod(keepAlive: true)` in `account_provider.dart`

### 2. Favoriten werden nicht gespeichert

**Problem:** POIs und Routen konnten nicht als Favoriten gespeichert werden.

**Fix:**
- `@Riverpod(keepAlive: true)` in `favorites_provider.dart`
- Neue `_ensureLoaded()` Methode, die auf geladenen State wartet

### 3. Langsamer App-Start nach Logout

**Problem:** Rekursive Schleife im Splash-Screen.

**Fix:** Splash-Screen komplett überarbeitet mit `ref.watch()` statt rekursive Aufrufe.

---

## Neue UI-Widgets

### _RouteStartButton

Prominenter Button mit Route-Info:
- Play-Icon links
- "Route starten" Titel
- Distanz + Dauer
- Pfeil rechts

### _RouteLoadingIndicator

Zeigt während dem Laden:
- CircularProgressIndicator
- "Route wird vorbereitet..."
- "POIs und Wetter werden geladen"

### _RouteStopButton

Kompakter TextButton zum Beenden:
- Rotes X-Icon
- "Route beenden" Text

---

## Debug-Logging

Neue Log-Ausgaben:

```
[RouteSession] Starte Route: München → Berlin
[RouteSession] Route gestartet - POIs: true, Wetter: true
[RouteSession] Route gestoppt
[POIState] Route-Only-Modus: true
[Weather] 5 Punkte geladen, Zustand: mixed
```

---

## Migration

Keine Migration erforderlich. Nach dem Update:

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

---

## Bekannte Einschränkungen

- WeatherBar zeigt maximal 5 Wetter-Punkte (Performance)
- Wetter-Daten haben ~15 Minuten Cache
- Indoor-Filter basiert auf Kategorie-Mapping (nicht 100% akkurat)

---

## Screenshots

### Route Starten Button
Nach Auswahl von Start und Ziel erscheint der Button unter dem Route-Toggle.

### WeatherBar
Zeigt Wetter-Zusammenfassung mit farbcodierten Punkten und optionalen Warnungen.

### Indoor-Filter
Bei schlechtem Wetter erscheint ein Toggle für Indoor-POIs.

---

## Nächste Schritte (v1.3.0)

- [ ] Turn-by-Turn Navigation
- [ ] Echtzeit-Wetter-Updates während der Fahrt
- [ ] POI-Benachrichtigungen bei Annäherung
- [ ] Offline-Karten-Download
