# Changelog v1.10.20 - Flüssigere Navigation

**Datum:** 2026-02-06
**Build:** 204

## Übersicht

Optimierungen für eine flüssigere GPS-Navigation, ähnlich wie bei Google Maps. Der Positions-Punkt bewegt sich jetzt sanfter über die Straße.

## Änderungen

### 1. GPS-Update-Frequenz erhöht

**Datei:** `lib/features/navigation/providers/navigation_provider.dart`

- `gpsDistanceFilter`: 2m → **1m**
- Doppelt so häufige GPS-Updates für flüssigere Bewegung
- Trade-off: ~20-30% höherer Akku-Verbrauch

### 2. Dead-Reckoning verbessert

**Datei:** `lib/features/navigation/services/position_interpolator.dart`

- Max Zeit: 2000ms → **2500ms** (längere Vorhersage bei GPS-Ausfall)
- Max Distanz: 50m → **80m** (bessere Überbrückung in Tunneln)
- Neue Konstante `_deadReckoningMaxMeters` für Klarheit

### 3. Adaptives Bearing-Smoothing

**Datei:** `lib/features/navigation/services/position_interpolator.dart`

Neue Funktion `_getAdaptiveSmoothingFactor()`:

| Geschwindigkeit | Smoothing-Faktor | Verhalten |
|-----------------|------------------|-----------|
| < 20 km/h | 0.20 | Stabiler, weniger Zittern im Stadtverkehr |
| 20-60 km/h | 0.30 | Guter Kompromiss für Landstraßen |
| > 60 km/h | 0.40 | Sehr responsiv für Autobahnkurven |

Vorher: Fixer Faktor 0.25 für alle Geschwindigkeiten

### 4. Schnellere Interval-Anpassung

**Datei:** `lib/features/navigation/services/position_interpolator.dart`

- Min-Clamp: 150ms → **100ms** (schnellere Reaktion auf GPS-Bursts)
- Adaptiver Ratio: 0.5 fix → **0.7 bei >30 km/h** (schnellere Anpassung bei Fahrt)

```dart
// Vorher
.clamp(150, 2000)

// Nachher
final adaptiveRatio = _currentSpeedKmh > 30 ? 0.7 : 0.5;
.clamp(100, 2000)
```

### 5. Predictive Extension

**Datei:** `lib/features/navigation/services/position_interpolator.dart`

Neue Logik in `_onFrame()`:
- Bei >80% Interpolations-Fortschritt und >10 km/h
- Schaut ~50ms (basierend auf aktueller Geschwindigkeit) voraus
- Sanftes Blending (30%) mit der vorausgesagten Position
- Ergebnis: Flüssigere Übergänge zwischen GPS-Updates

```dart
if (_interpolationProgress > 0.8 && _currentSpeedKmh > 10 && _routeCoords.isNotEmpty) {
  final predictedPos = _moveAlongRouteFromIndex(
    finalPos,
    _routeIndex,
    (_currentSpeedKmh / 3.6) * 0.05, // ~50ms voraus
  );
  finalPos = _lerpLatLng(finalPos, predictedPos, 0.3);
}
```

## Vergleich: Vorher vs. Nachher

| Parameter | v1.10.19 | v1.10.20 |
|-----------|----------|----------|
| GPS distanceFilter | 2m | 1m |
| Dead-Reckoning Max Zeit | 2000ms | 2500ms |
| Dead-Reckoning Max Distanz | 50m | 80m |
| Bearing-Smoothing | 0.25 (fix) | 0.20/0.30/0.40 (adaptiv) |
| Interval Min-Clamp | 150ms | 100ms |
| Predictive Extension | - | Neu |

## Betroffene Dateien

1. `lib/features/navigation/providers/navigation_provider.dart` - GPS-Konfiguration
2. `lib/features/navigation/services/position_interpolator.dart` - Interpolationslogik

## Testen

1. **Stadtverkehr (~30 km/h):** Punkt sollte stabil sein, keine Zitterbewegungen
2. **Landstraße (~80 km/h):** Flüssige Bewegung ohne Sprünge
3. **Autobahnkurven (~120 km/h):** Schnelle Reaktion auf Richtungswechsel
4. **Tunnel:** Position bewegt sich weiter (Dead-Reckoning), kein Stillstand

## Risiken

| Risiko | Mitigation |
|--------|------------|
| Höherer Akku-Verbrauch | distanceFilter nur auf 1m, nicht 0.5m |
| Overshoot bei Dead-Reckoning | Max auf 80m begrenzt |
| Zu aggressive Rotation | Adaptive Smoothing mit Speed-Abhängigkeit |
