# Changelog v1.7.10 - Favoriten: Routen speichern & laden

**Release-Datum:** 30. Januar 2026

## Zusammenfassung

Diese Version behebt 4 Bugs, die verhinderten, dass Routen in den Favoriten gespeichert und geladen werden konnten. Die Infrastruktur (`FavoritesNotifier.saveRoute()`, Hive-Persistenz, Supabase Cloud-Sync) existierte bereits, wurde aber an entscheidenden Stellen nie aufgerufen.

## Behobene Bugs

### Bug 1: AI Trip "Speichern" speicherte NICHT in Favoriten

**Problem:** Der "Speichern"-Button bei AI Trip Preview rief nur `confirmTrip()` auf, das die Daten lediglich ins Memory (TripStateProvider) übertrug. `FavoritesNotifier.saveRoute()` wurde nie aufgerufen. AI Trips gingen bei App-Restart verloren.

**Lösung:** Neue Methode `_saveAITrip()` erstellt, die nach `confirmTrip()` aufgerufen wird. Sie zeigt einen Namens-Dialog und speichert den Trip mit korrektem Typ (daytrip/eurotrip) über `FavoritesNotifier.saveRoute()` in Hive + Supabase.

**Betroffene Datei:** `lib/features/trip/trip_screen.dart`

### Bug 2: "Route speichern" im More-Options-Menü war TODO

**Problem:** Die "Route speichern" Option im Bottom Sheet des TripScreens enthielt nur `// TODO: Speichern` und war nicht implementiert.

**Lösung:** Der `onTap`-Callback erkennt jetzt ob ein AI Trip oder eine manuelle Route aktiv ist und ruft entsprechend `_saveAITrip()` oder `_saveRoute()` auf.

**Betroffene Datei:** `lib/features/trip/trip_screen.dart`

### Bug 3: Gespeicherte Routen konnten nicht aus Favoriten geladen werden

**Problem:** Klick auf eine gespeicherte Route im Favoriten-Screen zeigte nur eine Snackbar ("Route öffnen: ..."). Der Code enthielt `// TODO: Route öffnen/laden`.

**Lösung:** Neue Methode `_loadSavedRoute()` erstellt, die:
1. Bestehenden State zurücksetzt (`clearRoute()` + `reset()`)
2. Route und Stops aus dem Trip-Objekt lädt (ohne OSRM-Neuberechnung)
3. Auto-Zoom auf die Route aktiviert
4. Zur Karte navigiert

**Betroffene Datei:** `lib/features/favorites/favorites_screen.dart`

### Bug 4: "Route teilen" im More-Options-Menü war TODO

**Problem:** Die "Route teilen" Option enthielt `// TODO: Teilen`, obwohl die `_shareRoute()` Methode bereits existierte.

**Lösung:** Der `onTap`-Callback ruft jetzt `_shareRoute()` auf.

**Betroffene Datei:** `lib/features/trip/trip_screen.dart`

## Neue Methoden

### `_saveAITrip()` in TripScreen

```dart
/// Speichert einen AI Trip in die Favoriten
Future<void> _saveAITrip(context, ref, randomTripState) async {
  // 1. Prüft ob generatedTrip vorhanden
  // 2. Zeigt Namens-Dialog (Hint: "AI Tagesausflug" oder "AI Euro Trip")
  // 3. Erstellt Trip mit korrektem TripType
  // 4. Speichert via FavoritesNotifier.saveRoute()
  // 5. Zeigt Erfolgs-Snackbar mit "Anzeigen"-Link
}
```

### `_loadSavedRoute()` in FavoritesScreen

```dart
/// Lädt eine gespeicherte Route und zeigt sie auf der Karte an
void _loadSavedRoute(Trip trip) {
  // 1. Prüft Route-Daten (coordinates nicht leer)
  // 2. clearRoute() + reset() - bestehenden State zurücksetzen
  // 3. TripStop.toPOI() - Stops konvertieren
  // 4. setRouteAndStops() - Route ohne OSRM-Neuberechnung laden
  // 5. shouldFitToRoute = true - Auto-Zoom aktivieren
  // 6. context.go('/') - Zur Karte navigieren
}
```

### `setRouteAndStops()` in TripStateProvider

```dart
/// Setzt Route und Stops gleichzeitig OHNE Route-Neuberechnung
/// Wird verwendet beim Laden gespeicherter Routen aus Favoriten,
/// da die Route bereits korrekt berechnet war
void setRouteAndStops(AppRoute route, List<POI> stops) {
  state = state.copyWith(route: route, stops: stops);
}
```

## Code-Änderungen im Detail

### trip_screen.dart

1. **Neue Methode `_saveAITrip()`** - Speichert AI Trips in Favoriten mit Namens-Dialog
2. **"Speichern"-Button (AI Trip Preview)** - Ruft `confirmTrip()` + `_saveAITrip()` auf
3. **Bottom Sheet "Route speichern"** - Erkennt Modus und ruft `_saveAITrip()` oder `_saveRoute()` auf
4. **Bottom Sheet "Route teilen"** - Ruft `_shareRoute()` auf

### favorites_screen.dart

1. **Neue Imports** - `trip_state_provider`, `route_planner_provider`, `map_controller_provider`, `random_trip_provider`
2. **Neue Methode `_loadSavedRoute()`** - Lädt Route aus Favoriten auf die Karte
3. **`onTap` bei Routen-Tile** - Ersetzt TODO durch `_loadSavedRoute(trip)`

### trip_state_provider.dart

1. **Neue Methode `setRouteAndStops()`** - Setzt Route und Stops ohne OSRM-API-Aufruf

## Technische Details

### Warum `setRouteAndStops()` statt `setRoute()` + `setStops()`?

`setStops()` ruft intern `_recalculateRoute()` auf, was einen OSRM-API-Call auslöst. Beim Laden einer gespeicherten Route ist das unnötig, da die Route bereits korrekt berechnet war. `setRouteAndStops()` setzt beide Werte gleichzeitig ohne Neuberechnung.

### Reihenfolge beim Laden

```
clearRoute()          → Setzt RoutePlanner, TripState, RouteSession, POIs zurück
reset()               → Setzt RandomTrip-State zurück
setRouteAndStops()    → Setzt neue Route + Stops (nach clearRoute!)
shouldFitToRoute      → Auto-Zoom auf Karte
context.go('/')       → Navigation zur Karte
```

`clearRoute()` ruft intern `tripState.clearAll()` auf. Daher muss `setRouteAndStops()` NACH `clearRoute()` aufgerufen werden, da sonst die neue Route sofort wieder gelöscht wird.

### Datenfluss: Route speichern

```
User klickt "Speichern"
  ↓
confirmTrip()           → In-Memory-Transfer (TripState)
  ↓
_saveAITrip()           → Namens-Dialog
  ↓
Trip erstellen          → ID, Name, Typ, Route, Stops, Datum
  ↓
saveRoute(trip)         → Hive 'saved_routes' + Supabase (wenn auth)
  ↓
Snackbar "Gespeichert"  → Mit "Anzeigen"-Link zu /favorites
```

### Datenfluss: Route laden

```
User klickt auf Route in Favoriten
  ↓
_loadSavedRoute(trip)
  ↓
clearRoute() + reset()  → State zurücksetzen
  ↓
TripStop.toPOI()        → Stops konvertieren (trip.dart:226)
  ↓
setRouteAndStops()      → Route + Stops setzen (ohne OSRM)
  ↓
shouldFitToRoute = true → Auto-Zoom
  ↓
context.go('/')         → Zur Karte navigieren
```

## Build-Fix

### `const` in `InputDecoration` entfernt

**Problem:** Release-Build schlug fehl mit `Not a constant expression` in `trip_screen.dart:251`. Die `InputDecoration` im Namens-Dialog von `_saveAITrip()` war als `const` markiert, enthielt aber eine Runtime-Expression (`randomTripState.mode == RandomTripMode.daytrip`).

**Lösung:** `const InputDecoration(...)` zu `InputDecoration(...)` geändert.

**Betroffene Datei:** `lib/features/trip/trip_screen.dart` (Zeile 249)

## Auswirkungen

- Keine Breaking Changes
- Keine API-Änderungen
- Keine Model-Änderungen
- Bestehende Flows (manuelles Route-Speichern via Bookmark-Icon) bleiben unverändert
- AI Trips werden jetzt dauerhaft in Hive + Supabase gespeichert
- Gespeicherte Routen können aus Favoriten geladen und auf der Karte angezeigt werden
