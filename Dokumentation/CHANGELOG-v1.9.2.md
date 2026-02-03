# CHANGELOG v1.9.2 - Standort-Marker Fix im 3D-Navigations-Modus

**Datum:** 3. Februar 2026
**Build:** 1.9.2+148

## Zusammenfassung

Behebt einen Bug, bei dem der Standort-Marker in der 3D-Navigation durch Wischen auf der Karte verschoben werden konnte. Scroll- und Rotate-Gesten sind jetzt im Navigations-Modus deaktiviert.

---

## Bugfix: Standort-Marker nicht mehr verschiebbar

### Problem

Der User-Position-Marker ist ein Flutter-Widget, das immer in der Bildschirmmitte positioniert ist (da die Kamera dem GPS folgt). Die MapLibre-Karte erlaubte jedoch Scroll-/Rotate-Gesten, wodurch die Karte unter dem Marker verschoben werden konnte. Der Marker erschien dadurch "losgeloest" von der tatsaechlichen GPS-Position.

### Ursache

```dart
// VORHER - Alle Gesten aktiviert
scrollGesturesEnabled: true,
rotateGesturesEnabled: true,
tiltGesturesEnabled: true,
```

### Loesung

Gesten im Navigations-Modus deaktiviert, im Uebersichts-Modus weiterhin erlaubt:

```dart
// NACHHER - Nur im Uebersichts-Modus erlaubt
scrollGesturesEnabled: _isOverviewMode,
rotateGesturesEnabled: _isOverviewMode,
tiltGesturesEnabled: false,
zoomGesturesEnabled: true,  // Pinch-to-Zoom bleibt
```

### Verhalten

| Modus | Scroll | Rotate | Tilt | Zoom |
|-------|--------|--------|------|------|
| Navigation (3D) | Gesperrt | Gesperrt | Gesperrt (50° fest) | Erlaubt |
| Uebersicht (2D) | Erlaubt | Erlaubt | Gesperrt | Erlaubt |

---

## Geaenderte Dateien (1)

| # | Datei | Aenderung |
|---|-------|-----------|
| 1 | `lib/features/navigation/navigation_screen.dart` | `scrollGesturesEnabled` und `rotateGesturesEnabled` an `_isOverviewMode` gebunden |

---

## Zusaetzlich: maplibre_gl Version-Fix

In v1.9.1 wurde `maplibre_gl: ^0.20.0` verwendet, was mit Flutter 3.38+ nicht kompatibel war (entfernte `PluginRegistry.Registrar` V1 Embedding API). Upgrade auf `maplibre_gl: ^0.25.0` in pubspec.yaml behebt den Build-Fehler.
