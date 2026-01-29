# Changelog v1.7.0 - Auto-Navigation & Zoom

**Release-Datum:** 29. Januar 2026

## Übersicht

Diese Version verbessert die Benutzerführung durch automatische Navigation zum Trip-Tab nach Route-Berechnung und Auto-Zoom auf die Route beim Tab-Wechsel zurück zur Karte.

## Neue Features

### 🗺️ Auto-Navigation zum Trip-Tab

Nach Berechnung einer Route wird automatisch zum Trip-Tab navigiert, damit der Benutzer sofort die Route-Details sieht.

**Implementierung:**
- Listener im MapScreen auf `routePlannerProvider`
- 500ms Verzögerung für bessere UX (Route wird kurz auf Karte angezeigt)
- Navigation via `context.go('/trip')`

**Code (map_screen.dart:54-65):**
```dart
ref.listenManual(routePlannerProvider, (previous, next) {
  if (next.hasRoute && (previous?.route != next.route)) {
    _fitMapToRoute(next.route!);
    // Nach Route-Berechnung automatisch zum Trip-Tab navigieren
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        debugPrint('[MapScreen] Route berechnet - navigiere zu Trip-Tab');
        context.go('/trip');
      }
    });
  }
});
```

### 🔍 Auto-Zoom auf Route beim Tab-Wechsel

Beim Wechsel vom Trip-Tab zur Karte wird automatisch auf die berechnete Route gezoomt.

**Implementierung:**
- Neuer `shouldFitToRouteProvider` in `map_controller_provider.dart`
- Flag wird nach Route-Berechnung auf `true` gesetzt
- Im MapScreen `build()` wird geprüft und gezoomt

**Neuer Provider (map_controller_provider.dart:17):**
```dart
/// Provider der angibt, ob beim nächsten MapScreen-Anzeige auf die Route gezoomt werden soll
final shouldFitToRouteProvider = StateProvider<bool>((ref) => false);
```

**Logik im MapScreen (map_screen.dart:135-158):**
```dart
final shouldFitToRoute = ref.watch(shouldFitToRouteProvider);
if (shouldFitToRoute) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    // Bestimme welche Route angezeigt werden soll
    AppRoute? routeToFit;
    if (randomTripState.step == RandomTripStep.preview ||
        randomTripState.step == RandomTripStep.confirmed) {
      routeToFit = randomTripState.generatedTrip?.trip.route;
    } else if (tripState.hasRoute) {
      routeToFit = tripState.route;
    } else if (routePlanner.hasRoute) {
      routeToFit = routePlanner.route;
    }

    if (routeToFit != null) {
      debugPrint('[MapScreen] Auto-Zoom auf Route bei Tab-Wechsel');
      _fitMapToRoute(routeToFit);
    }
    // Flag zurücksetzen
    ref.read(shouldFitToRouteProvider.notifier).state = false;
  });
}
```

### 📍 "Auf Karte anzeigen" Button im TripScreen

Neuer prominenter Button im TripScreen, der zur Karte navigiert und automatisch auf die Route zoomt.

**Bei normaler Route (trip_screen.dart:542-556):**
```dart
FilledButton.icon(
  onPressed: route != null
      ? () {
          ref.read(shouldFitToRouteProvider.notifier).state = true;
          context.go('/');
        }
      : null,
  icon: const Icon(Icons.map_outlined),
  label: const Text('Auf Karte anzeigen'),
),
```

**Bei AI Trip Preview (trip_screen.dart:641-659):**
- Gleiche Funktionalität mit angepasstem Styling

## Geänderte Dateien

| Datei | Änderung |
|-------|----------|
| `lib/features/map/providers/map_controller_provider.dart` | Neuer `shouldFitToRouteProvider` |
| `lib/features/map/providers/route_planner_provider.dart` | Flag setzen nach Route-Berechnung |
| `lib/features/map/map_screen.dart` | Auto-Navigation zum Trip-Tab + Auto-Zoom |
| `lib/features/trip/trip_screen.dart` | "Auf Karte anzeigen" Button |
| `pubspec.yaml` | Version 1.7.0 |

## Funktionsweise

### Szenario 1: Normale Route berechnen
1. User gibt Start und Ziel ein
2. Route wird berechnet
3. Karte zoomt auf Route
4. Nach 500ms: Automatische Navigation zum Trip-Tab
5. User sieht Route-Details

### Szenario 2: Vom Trip-Tab zur Karte
1. User ist im Trip-Tab
2. User klickt auf "Auf Karte anzeigen" Button
3. `shouldFitToRouteProvider` wird auf `true` gesetzt
4. Navigation zur Karte
5. Karte zoomt automatisch auf Route

### Szenario 3: AI Trip
1. AI Trip wird generiert
2. Route erscheint auf Karte mit Auto-Zoom
3. User navigiert zum Trip-Tab
4. User klickt "Auf Karte anzeigen"
5. Karte zoomt auf AI Trip Route

## Debug-Logs

```
[MapScreen] Route berechnet - navigiere zu Trip-Tab
[MapScreen] Auto-Zoom auf Route bei Tab-Wechsel
[RoutePlanner] Route berechnet: XXX km
```

## Bekannte Limitierungen

- Bei sehr kurzen Routen (< 1km) kann der Auto-Zoom zu weit herangezoomt sein
- Die 500ms Verzögerung vor der Navigation ist ein Kompromiss zwischen UX und Geschwindigkeit

## Migration

Keine Migration erforderlich. Alle Änderungen sind abwärtskompatibel.
