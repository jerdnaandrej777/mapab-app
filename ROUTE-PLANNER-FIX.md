# Route-Planner Fix - Trip-Screen zeigt berechnete Routen

## Problem

Nach v1.2.1: "Trip anzeigen funktioniert immernoch nicht, in deiner Route ist nichts drin, Seite Trip, berechnete route wurde nicht weitergegeben."

**Root Cause:** Architektonische Lücke - trip_state_provider existierte, aber nichts schrieb Routen hinein.

## Lösung

Neuer `route_planner_provider` als Brücke zwischen Suche und Trip-Anzeige.

### State-Flow

```
User wählt Standort (SearchScreen)
    ↓
SearchScreen.selectSuggestion()
    ↓
routePlannerProvider.setStart() / setEnd()
    ↓
routePlannerProvider._tryCalculateRoute()
    ↓
routingRepository.calculateFastRoute()
    ↓
tripStateProvider.setRoute(route)  ← KEY FIX
    ↓
TripScreen zeigt Route an
```

## Geänderte Dateien

### 1. NEU: route_planner_provider.dart

**Datei:** `lib/features/map/providers/route_planner_provider.dart`

**Zweck:**
- Verwaltet Start/Ziel-Locations + Adressen
- Berechnet Route automatisch wenn beides gesetzt
- Schreibt berechnete Route zu trip_state_provider

**Key Code:**
```dart
void setStart(LatLng location, String address) {
  state = state.copyWith(
    startLocation: location,
    startAddress: address,
  );
  _tryCalculateRoute();  // Automatische Berechnung
}

Future<void> _tryCalculateRoute() async {
  if (state.startLocation == null || state.endLocation == null) {
    return;
  }

  state = state.copyWith(isCalculating: true);

  try {
    final routingRepo = ref.read(routingRepositoryProvider);

    final route = await routingRepo.calculateFastRoute(
      start: state.startLocation!,
      end: state.endLocation!,
      startAddress: state.startAddress ?? 'Unbekannt',
      endAddress: state.endAddress ?? 'Unbekannt',
    );

    state = state.copyWith(
      route: route,
      isCalculating: false,
    );

    // *** DER FIX: Route zu Trip-State schreiben ***
    ref.read(tripStateProvider.notifier).setRoute(route);
  } catch (e) {
    print('[RoutePlanner] Fehler bei Routenberechnung: $e');
    state = state.copyWith(
      isCalculating: false,
      error: e.toString(),
    );
  }
}
```

### 2. GEÄNDERT: search_screen.dart

**Datei:** `lib/features/search/search_screen.dart`

**Änderung:** `_selectSuggestion()` schreibt zu route_planner_provider

**Code:**
```dart
import '../map/providers/route_planner_provider.dart';

Future<void> _selectSuggestion(AutocompleteSuggestion suggestion) async {
  // ... Geocoding Logic ...

  // *** DER FIX: In RoutePlanner State speichern ***
  final routePlanner = ref.read(routePlannerProvider.notifier);
  if (widget.isStartLocation) {
    routePlanner.setStart(location, suggestion.displayName);
  } else {
    routePlanner.setEnd(location, suggestion.displayName);
  }

  if (mounted) {
    context.pop();
  }
}
```

### 3. GEÄNDERT: map_screen.dart

**Datei:** `lib/features/map/map_screen.dart`

**Änderung:** Zeigt Adressen aus route_planner_provider

**Code:**
```dart
import 'providers/route_planner_provider.dart';

@override
Widget build(BuildContext context) {
  final routePlanner = ref.watch(routePlannerProvider);

  return Scaffold(
    // ... AppBar ...
    body: Stack(
      children: [
        const MapView(),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Suchleiste mit State-Daten
                _SearchBar(
                  startAddress: routePlanner.startAddress,
                  endAddress: routePlanner.endAddress,
                  isCalculating: routePlanner.isCalculating,
                  onStartTap: () => context.push('/search?type=start'),
                  onEndTap: () => context.push('/search?type=end'),
                ),
                // ...
              ],
            ),
          ),
        ),
        // ... FABs ...
      ],
    ),
  );
}
```

### 4. GEÄNDERT: _SearchBar Widget

**Datei:** `lib/features/map/map_screen.dart` (Zeile 236-308)

**Änderung:** Zeigt Adressen + Loading-State

**Code:**
```dart
class _SearchBar extends StatelessWidget {
  final String? startAddress;
  final String? endAddress;
  final bool isCalculating;
  final VoidCallback onStartTap;
  final VoidCallback onEndTap;

  const _SearchBar({
    this.startAddress,
    this.endAddress,
    this.isCalculating = false,
    required this.onStartTap,
    required this.onEndTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          // Start-Eingabe
          _SearchField(
            icon: Icons.trip_origin,
            iconColor: AppTheme.successColor,
            hint: 'Startpunkt eingeben',
            value: startAddress,
            onTap: onStartTap,
          ),

          const Divider(height: 1, indent: 48),

          // Ziel-Eingabe
          _SearchField(
            icon: Icons.place,
            iconColor: AppTheme.errorColor,
            hint: 'Ziel eingeben',
            value: endAddress,
            onTap: onEndTap,
          ),

          // Lade-Indikator wenn Route berechnet wird
          if (isCalculating)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Route wird berechnet...',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
```

### 5. NEU: route_planner_provider.g.dart

**Datei:** `lib/features/map/providers/route_planner_provider.g.dart`

**Zweck:** Riverpod Code-Generation (manuell erstellt)

## Test-Anleitung

### 1. Routen-Berechnung testen

1. **App starten**
2. **Startpunkt eingeben:**
   - Suchleiste "Startpunkt eingeben" antippen
   - Stadt eingeben (z.B. "München")
   - Vorschlag auswählen
   - → Adresse wird in Suchleiste angezeigt
3. **Ziel eingeben:**
   - Suchleiste "Ziel eingeben" antippen
   - Stadt eingeben (z.B. "Berlin")
   - Vorschlag auswählen
   - → Loading-Indikator erscheint ("Route wird berechnet...")
   - → Route wird auf Karte gezeichnet
4. **Trip-Screen prüfen:**
   - Bottom Navigation → "Trip"-Tab öffnen
   - ✅ **ERWARTUNG:** Route ist sichtbar mit:
     - Start: "München, Deutschland"
     - Ziel: "Berlin, Deutschland"
     - Entfernung (ca. 585 km)
     - Dauer (ca. 5.5 Std)

### 2. Error-Handling testen

1. **Nur Start setzen (kein Ziel):**
   - Startpunkt eingeben
   - Trip-Screen öffnen
   - ✅ **ERWARTUNG:** Leerer State "Noch keine Route geplant"

2. **Offline-Test:**
   - Internet deaktivieren
   - Start + Ziel eingeben
   - ✅ **ERWARTUNG:** Error-Toast / Console-Log

### 3. State-Persistenz testen

1. **Route berechnen**
2. **Zu anderem Tab wechseln** (z.B. POI-Liste)
3. **Zurück zu Trip-Tab**
4. ✅ **ERWARTUNG:** Route ist weiterhin sichtbar (State bleibt erhalten)

## Debug-Tipps

### Console-Logs prüfen

```dart
// In route_planner_provider.dart
print('[RoutePlanner] Start gesetzt: $address');
print('[RoutePlanner] Route berechnet: ${route.distanceKm} km');
print('[RoutePlanner] Fehler: $e');

// In trip_state_provider.dart
print('[TripState] Route empfangen: ${route.startAddress} → ${route.endAddress}');
```

### Breakpoints setzen

1. `route_planner_provider.dart:23` - `setStart()`
2. `route_planner_provider.dart:54` - `_tryCalculateRoute()`
3. `route_planner_provider.dart:77` - `setRoute()` Call
4. `trip_state_provider.dart:13` - `setRoute()` Empfang

### State Inspector (Flutter DevTools)

1. DevTools öffnen
2. Provider-Tab
3. `routePlannerProvider` prüfen:
   - `startLocation`: {lat: 48.1351, lng: 11.5820}
   - `startAddress`: "München, Deutschland"
   - `endLocation`: {lat: 52.5200, lng: 13.4050}
   - `endAddress`: "Berlin, Deutschland"
   - `isCalculating`: false
   - `route`: AppRoute{...}
4. `tripStateProvider` prüfen:
   - `route`: AppRoute{...} (gleiche Instanz wie oben)

## Bekannte Issues

### Issue 1: Route erscheint nicht sofort auf Karte

**Symptom:** Trip-Screen zeigt Route, aber Karte nicht.

**Grund:** MapView hat eigenen State, nicht mit route_planner_provider verbunden.

**Fix (optional):** MapView müsste auch `ref.watch(routePlannerProvider)` nutzen und Route zeichnen.

### Issue 2: Scenic Route fehlt

**Status:** Aktuell nur Fast Route implementiert.

**Erweiterung:** `calculateScenicRoute()` in `_tryCalculateRoute()` hinzufügen.

## Zusammenfassung

**Problem gelöst:** ✅ Berechnete Routen erscheinen jetzt auf Trip-Screen

**Änderungen:**
- 1 neue Datei (route_planner_provider.dart + .g.dart)
- 3 geänderte Dateien (search_screen, map_screen, _SearchBar)
- ~180 Zeilen Code

**State-Flow:**
```
SearchScreen → RoutePlanner → TripState → TripScreen
```

**Key Fix:**
```dart
ref.read(tripStateProvider.notifier).setRoute(route);
```

Diese Zeile verbindet Route-Berechnung mit Trip-Anzeige.
