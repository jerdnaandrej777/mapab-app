# Changelog v1.9.23 - Navigation Stabilitaets-Release

**Datum:** 2026-02-04
**Typ:** Stability / Navigation Crash-Fix
**Problem:** Navigation-Funktion verursacht App-Abstuerze durch GPS-Stream-Leaks, MapController-Race-Conditions, Timer-Callbacks nach dispose() und fehlende Null-Guards

## Root Cause

Analyse mit 3 parallelen Agenten ergab **10 kritische und 4 hohe Stabilitaetsprobleme** in der Navigation:

1. **GPS-Stream-Leak** - Doppelte GPS-Streams bei wiederholtem Navigation-Start
2. **MapController-Race-Condition** - Null-Zugriff im 60fps Interpolation-Callback zwischen Check und Nutzung
3. **Timer nach dispose()** - PositionInterpolator-Timer laeuft nach Screen-Exit weiter
4. **Provider nicht gestoppt** - NavigationProvider/TTS/POI-Discovery laufen nach Screen-Exit weiter
5. **Context-Deaktivierung** - context.pop() nach Navigator.pop() ohne mounted-Check
6. **arrivedAtWaypoint Re-Entry** - GPS-Updates triggern wiederholt Hauptlogik im Waypoint-Status
7. **Null-Route bei Rerouting** - state.route! ohne Null-Check in _reroute()
8. **GPS ohne Berechtigung** - Navigation startet GPS-Stream ohne Service/Permission-Check
9. **Leere Bounds** - LatLngBounds-Crash bei leerer Koordinaten-Liste
10. **TTS nach Navigation-Ende** - Sprachansagen laufen nach Stop weiter

## Aenderungen

### Fix 1: Doppelte GPS-Streams verhindern (KRITISCH)
**Datei:** `lib/features/navigation/providers/navigation_provider.dart`

`startNavigation()` prueft jetzt ob bereits navigiert wird und stoppt die vorherige Navigation sauber bevor eine neue gestartet wird. Verhindert akkumulierte GPS-Streams.

```dart
// NEU: Vorherige Navigation stoppen
if (state.isNavigating || state.isRerouting || state.isLoading) {
  debugPrint('[Navigation] Vorherige Navigation wird gestoppt');
  stopNavigation();
}
```

### Fix 2: arrivedAtWaypoint Re-Entry Guard (KRITISCH)
**Datei:** `lib/features/navigation/providers/navigation_provider.dart`

`_onPositionUpdate()` blockierte bei `arrivedAtWaypoint` nicht - GPS-Updates triggerten wiederholt die gesamte Navigationslogik. Jetzt wird im Waypoint-Status nur die Position aktualisiert.

```dart
// NEU: Bei arrivedAtWaypoint nur Position updaten
if (state.status == NavigationStatus.arrivedAtWaypoint) {
  state = state.copyWith(
    currentPosition: currentPos,
    currentHeading: position.heading,
    currentSpeedKmh: position.speed * 3.6,
  );
  return;
}
```

### Fix 3: Reroute Null-Check (KRITISCH)
**Datei:** `lib/features/navigation/providers/navigation_provider.dart`

`_reroute()` griff ohne Guard auf `state.route!` zu. Bei async State-Aenderungen konnte route null sein.

```dart
// NEU: Null-Check vor Rerouting
if (state.route == null) {
  debugPrint('[Navigation] Reroute abgebrochen: keine Route vorhanden');
  return;
}
```

### Fix 4: GPS-Verfuegbarkeit pruefen (HOCH)
**Datei:** `lib/features/navigation/providers/navigation_provider.dart`

`_startPositionStream()` startet GPS-Stream jetzt erst nach Service- und Permission-Check. Bei Fehler wird der State mit Fehlermeldung aktualisiert statt stiller Fehlstart.

```dart
// NEU: GPS-Service und Permission pruefen
final serviceEnabled = await Geolocator.isLocationServiceEnabled();
if (!serviceEnabled) {
  state = state.copyWith(error: 'GPS-Dienst nicht aktiviert');
  return;
}
final permission = await Geolocator.checkPermission();
if (permission == LocationPermission.denied || ...) {
  state = state.copyWith(error: 'GPS-Berechtigung fehlt');
  return;
}
```

### Fix 5: TTS Idle-Guard und VoiceService-Stop (HOCH)
**Datei:** `lib/features/navigation/providers/navigation_tts_provider.dart`

- `_onNavigationStateChanged()` hat jetzt einen expliziten Idle-Guard als erste Zeile
- `reset()` stoppt laufende Sprachausgabe via `voiceService.stopSpeaking()`

### Fix 6: Vollstaendiges dispose() im NavigationScreen (KRITISCH)
**Datei:** `lib/features/navigation/navigation_screen.dart`

`dispose()` stoppt jetzt alle Navigation-Provider sauber:

```dart
@override
void dispose() {
  _interpolationSub?.cancel();
  _interpolator.dispose();
  _mapController?.dispose();
  // NEU: Alle Provider stoppen
  ref.read(navigationNotifierProvider.notifier).stopNavigation();
  ref.read(navigationTtsProvider.notifier).reset();
  ref.read(navigationPOIDiscoveryNotifierProvider.notifier).reset();
  super.dispose();
}
```

### Fix 7: MapController Race-Condition eliminiert (KRITISCH)
**Datei:** `lib/features/navigation/navigation_screen.dart`

`_onInterpolatedPosition()` (60fps Callback) captured jetzt den MapController in einer lokalen Variable. Eliminiert null-zwischen-check-und-nutzung Race.

```dart
// NEU: Lokal capturen statt Feld-Zugriff
final controller = _mapController;
if (controller == null) return;
controller.updateCircle(...);
controller.animateCamera(...);
```

Gleiches Pattern auch in:
- `_updateRouteSources()` PostFrameCallback
- `_updatePOIMarkerColors()`
- Overview-Mode Toggle

### Fix 8: Arrival-Dialog Mehrfach-Anzeige (HOCH)
**Datei:** `lib/features/navigation/navigation_screen.dart`

`_arrivalDialogShown` Flag verhindert mehrfache Anzeige des Ziel-Dialogs bei wiederholten State-Updates.

### Fix 9: Dialog-Cleanup und context.mounted Guards (HOCH)
**Datei:** `lib/features/navigation/navigation_screen.dart`

Beide Dialoge (Stop-Navigation und Arrival) haben jetzt:
- POI-Discovery Provider reset
- `if (context.mounted)` vor `context.pop()`

### Fix 10: PositionInterpolator _isDisposed Safety (KRITISCH)
**Datei:** `lib/features/navigation/services/position_interpolator.dart`

- `_isDisposed` Flag in `onGPSUpdate()` und `_onFrame()` geprueft
- `dispose()` setzt `_isDisposed = true` als erstes, vor Timer-Cancel
- `_onFrame()` cancelt Timer wenn disposed

### Fix 11: DayEditor Navigation-Fix (HOCH)
**Datei:** `lib/features/trip/widgets/day_editor_overlay.dart`

- Waypoints auf AppRoute gesetzt (vorher leer)
- `if (context.mounted)` vor `context.push('/navigation')` nach `Navigator.pop()`

### Fix 12: Leere-Liste Guard in boundsFromCoords (MITTEL)
**Datei:** `lib/features/navigation/utils/latlong_converter.dart`

Fallback auf Deutschland-Bounds bei leerer Koordinaten-Liste statt invertierte Bounds / MapLibre Crash.

## Betroffene Dateien (6 Stueck)

| Datei | Aenderungen | Prioritaet |
|-------|------------|------------|
| `lib/features/navigation/providers/navigation_provider.dart` | Fix 1-4: Doppel-Stream, Waypoint-Guard, Reroute-Null, GPS-Check | KRITISCH |
| `lib/features/navigation/providers/navigation_tts_provider.dart` | Fix 5: Idle-Guard, VoiceService-Stop | HOCH |
| `lib/features/navigation/navigation_screen.dart` | Fix 6-9: dispose(), Controller-Race, Arrival-Flag, Dialog-Guards | KRITISCH |
| `lib/features/navigation/services/position_interpolator.dart` | Fix 10: _isDisposed Flag in Timer/GPS/dispose | KRITISCH |
| `lib/features/trip/widgets/day_editor_overlay.dart` | Fix 11: Waypoints + context.mounted Guard | HOCH |
| `lib/features/navigation/utils/latlong_converter.dart` | Fix 12: Leere-Liste Bounds Guard | MITTEL |

## Crash-Pattern-Analyse

| Pattern | Vorkommen | Fix-Typ |
|---------|-----------|---------|
| GPS-Stream-Leak | 1 Stelle | Stop-before-Start Guard |
| MapController null Race | 4 Stellen | Lokale Variable capturen |
| Timer nach dispose | 2 Stellen | _isDisposed Flag |
| Provider nicht gestoppt | 3 Provider | dispose() cleanup |
| context nach deactivate | 3 Stellen | context.mounted Guard |
| Null-Route Zugriff | 2 Stellen | Null-Check + Early Return |
| arrivedAtWaypoint Re-Entry | 1 Stelle | Status-Guard |
| Leere Bounds | 1 Stelle | Empty-List Fallback |

## Test-Plan

1. **GPS-Stream-Leak:** Navigation starten → Back-Button → erneut starten → Log: nur ein `[Navigation] Starte Navigation`
2. **Schnelles Oeffnen/Schliessen:** NavigationScreen 5x schnell oeffnen/schliessen → kein Crash
3. **DayEditor-Navigation:** Aus DayEditor Navigation starten → kein StateError
4. **Ziel-Dialog:** Ziel erreichen → Dialog erscheint genau 1x
5. **GPS deaktiviert:** Navigation starten ohne GPS → Fehlermeldung statt Crash
6. **TTS-Cleanup:** Navigation beenden → keine weiteren Sprachansagen
7. **Rerouting:** Waehrend Rerouting Navigation beenden → kein Null-Crash
