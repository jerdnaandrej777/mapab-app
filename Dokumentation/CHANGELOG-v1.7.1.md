# Changelog v1.7.1 - Auto-Zoom Verbesserung

**Release-Datum:** 29. Januar 2026

## Übersicht

Diese Version behebt ein Timing-Problem beim Auto-Zoom auf die Route, wenn vom Trip-Tab zur Karte gewechselt wird.

## Verbesserungen

### Auto-Zoom Robustheit

**Problem:** Beim Klick auf "Auf Karte anzeigen" im TripScreen wurde manchmal nicht auf die Route gezoomt, weil der MapController noch nicht initialisiert war.

**Lösung:** Retry-Mechanismus mit 100ms Verzögerung, wenn MapController noch nicht bereit ist.

**Code (map_screen.dart:135-170):**
```dart
// Auto-Zoom auf Route bei Tab-Wechsel (v1.7.0)
final shouldFitToRoute = ref.watch(shouldFitToRouteProvider);
if (shouldFitToRoute) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;

    // Prüfe ob MapController bereit ist
    final mapController = ref.read(mapControllerProvider);
    if (mapController == null) {
      debugPrint('[MapScreen] MapController noch nicht bereit, warte...');
      // Retry nach kurzer Verzögerung
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          // Triggere erneuten Build durch State-Änderung
          setState(() {});
        }
      });
      return;
    }

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
    // Flag zurücksetzen (nur wenn MapController bereit war)
    ref.read(shouldFitToRouteProvider.notifier).state = false;
  });
}
```

## Geänderte Dateien

| Datei | Änderung |
|-------|----------|
| `lib/features/map/map_screen.dart` | Retry-Mechanismus für Auto-Zoom |
| `pubspec.yaml` | Version 1.7.1 |

## Funktionsweise

### Vorher (v1.7.0)
1. User klickt "Auf Karte anzeigen"
2. Navigation zu MapScreen
3. `shouldFitToRouteProvider` ist `true`
4. MapController ist noch `null` → Zoom schlägt fehl
5. Flag wird trotzdem zurückgesetzt

### Nachher (v1.7.1)
1. User klickt "Auf Karte anzeigen"
2. Navigation zu MapScreen
3. `shouldFitToRouteProvider` ist `true`
4. MapController ist noch `null` → Warte 100ms
5. Erneuter Build → MapController ist jetzt bereit
6. Zoom auf Route erfolgreich
7. Flag wird zurückgesetzt

## Debug-Logs

```
[MapScreen] MapController noch nicht bereit, warte...
[MapScreen] Auto-Zoom auf Route bei Tab-Wechsel
[Map] Route angezeigt: XXX km
```

## Migration

Keine Migration erforderlich. Abwärtskompatibel.
