# Changelog v1.10.18 - Flüssigere Navigation

**Build:** 202
**Datum:** 6. Februar 2026

## Übersicht

Diese Version behebt das ruckelige Verhalten des Positions-Markers während der Navigation. Der Marker bewegt sich jetzt deutlich flüssiger, auch bei langsamen GPS-Updates oder kurzzeitigen GPS-Aussetzern.

## Änderungen

### PositionInterpolator (`lib/features/navigation/services/position_interpolator.dart`)

1. **Dead-Reckoning entlang der Route**
   - Wenn GPS-Updates ausbleiben aber Bewegung erwartet wird (Speed > 3 km/h), bewegt sich der Marker automatisch entlang der Route weiter
   - Begrenzt auf max 2 Sekunden / 50 Meter um Abweichungen zu minimieren
   - Neue Methoden: `_deadReckonAlongRoute()`, `_moveAlongRouteFromIndex()`

2. **Schnellere Interval-Anpassung**
   - Smoothing-Faktoren von 0.6/0.4 auf 0.5/0.5 geändert für responsivere Interpolation
   - Minimum-Interval von 300ms auf 150ms reduziert

3. **Sanfteres Bearing-Smoothing**
   - `_bearingSmoothingFactor` von 0.35 auf 0.25 reduziert für weniger ruckelige Rotation

4. **Neue Konstante**
   - `_deadReckoningMaxMs = 2000.0` - Maximale Zeit für Dead-Reckoning

### NavigationProvider (`lib/features/navigation/providers/navigation_provider.dart`)

1. **Häufigere GPS-Updates**
   - `gpsDistanceFilter` von 5 Meter auf 2 Meter reduziert
   - Ergibt ca. 2,5x häufigere Updates bei gleicher Geschwindigkeit

## Technische Details

### Dead-Reckoning Algorithmus

```dart
LatLng _deadReckonAlongRoute(int elapsedMs) {
  // Zeit über normale Interpolation hinaus
  final extraMs = elapsedMs - _expectedUpdateInterval.inMilliseconds;

  // Distanz basierend auf letzter bekannter Geschwindigkeit
  final speedMps = _currentSpeedKmh / 3.6;
  final extraDistanceM = speedMps * (extraMs / 1000.0);

  // Entlang der Route-Koordinaten bewegen (max 50m)
  return _moveAlongRouteFromIndex(_targetPosition!, _routeIndex, extraDistanceM.clamp(0, 50));
}
```

### Vorher vs. Nachher

| Metrik | v1.10.17 | v1.10.18 |
|--------|----------|----------|
| GPS-Filter | 5m | 2m |
| Bearing-Smoothing | 0.35 | 0.25 |
| Min. Interval | 300ms | 150ms |
| Dead-Reckoning | ❌ | ✅ (max 2s) |
| Route-basierte Vorhersage | ❌ | ✅ |

## Betroffene Dateien

- `lib/features/navigation/services/position_interpolator.dart`
- `lib/features/navigation/providers/navigation_provider.dart`

## Testen

1. Navigation starten auf einer längeren Route
2. Bei langsamer Fahrt (< 30 km/h) beobachten ob Marker flüssig bewegt
3. Bei Kurven prüfen ob Marker der Route folgt (nicht Luftlinie)
4. GPS kurz blockieren (Tunnel-Simulation) und prüfen ob Marker weiter fährt
