# CHANGELOG v1.9.1 - 3D-Perspektive fuer Navigation (MapLibre GL)

**Datum:** 3. Februar 2026
**Build:** 1.9.1+147

## Zusammenfassung

Die In-App Navigation zeigt jetzt eine **echte 3D-Perspektive** mit 50° Neigung und Heading-basierter Kartenrotation. Umgesetzt durch Migration des NavigationScreen von `flutter_map` (2D Raster-Tiles) auf `maplibre_gl` (3D Vektor-Tiles mit OpenFreeMap).

---

## Feature: 3D Navigation mit MapLibre GL

### Was sich aendert

| Vorher (v1.9.0) | Nachher (v1.9.1) |
|------------------|-------------------|
| flutter_map (2D Raster-Tiles) | maplibre_gl (3D Vektor-Tiles) |
| Flache Draufsicht | 50° Neigung (3D-Perspektive) |
| OpenStreetMap Raster-Tiles | OpenFreeMap Vektor-Tiles |
| `mapController.move()` + `rotate()` | `animateCamera(CameraPosition(tilt, bearing))` |
| Flutter PolylineLayer | Native GeoJSON LineLayer |
| Flutter MarkerLayer | Native Circle-Annotations |

### 3D-Kamera-Konfiguration

| Modus | Zoom | Tilt | Bearing | Animation |
|-------|------|------|---------|-----------|
| Aktive Navigation | 16 | 50° | GPS-Heading | 500ms |
| Uebersicht | fit bounds | 0° (flach) | 0° (Nord) | 800ms |

### Architektur

- **Nur NavigationScreen migriert** — alle anderen Screens (MapScreen, MiniMap, TripPreview) bleiben auf `flutter_map`
- **Navigation Provider unveraendert** — gleiche State Machine, gleicher GPS-Stream
- **Overlay-Widgets unveraendert** — ManeuverBanner, BottomBar, POIApproachCard
- **Tile-Source**: OpenFreeMap `https://tiles.openfreemap.org/styles/liberty` (kostenlos, kein API-Key)

---

## Neue Dateien (2)

| # | Datei | Beschreibung |
|---|-------|-------------|
| 1 | `lib/features/navigation/utils/latlong_converter.dart` | Konvertierung latlong2 <-> maplibre_gl + GeoJSON Builder |
| 2 | `Dokumentation/CHANGELOG-v1.9.1.md` | Dieses Dokument |

## Geaenderte Dateien (3)

| # | Datei | Aenderung |
|---|-------|-----------|
| 1 | `lib/features/navigation/navigation_screen.dart` | FlutterMap → MapLibreMap, 3D-Kamera, GeoJSON Route-Rendering, Native Circle-Marker |
| 2 | `pubspec.yaml` | `maplibre_gl: ^0.20.0` hinzugefuegt, Version 1.9.1+147 |
| 3 | `android/app/proguard-rules.pro` | MapLibre GL Native Keep-Rules fuer R8/ProGuard |

---

## Technische Details

### LatLng-Konvertierung

Der Navigation Provider nutzt `latlong2.LatLng`, MapLibre nutzt `maplibre_gl.LatLng`. Die neue `LatLngConverter` Utility konvertiert zwischen beiden:
- `toMapLibre()` — fuer Kamera-Positionen
- `toGeoJsonLine()` — fuer Route-Polylines (RFC 7946: `[longitude, latitude]`)
- `boundsFromCoords()` — fuer Uebersichts-Modus

### Route-Rendering

Statt Flutter `PolylineLayer` werden jetzt native GeoJSON-Sources + LineLayers verwendet:
- `completed-route-source/layer` — gefahrener Teil (grau, 40% Opazitaet)
- `remaining-route-source/layer` — verbleibender Teil (Primary-Farbe)
- Update via `setGeoJsonSource()` bei jedem GPS-Tick (kein Widget-Rebuild)

### Marker-Strategie

- **User-Position**: Zentriertes Flutter-Widget (Kamera folgt GPS → User immer in Bildschirmmitte). Kein `Transform.rotate` mehr noetig da Karte selbst via `bearing` rotiert.
- **POI-Stops**: Native `CircleAnnotations` mit Farbkodierung (besucht=grau, unbesucht=secondary, Ziel=error)

### ProGuard

MapLibre GL bringt native Android-Libraries mit. Ohne Keep-Rules wuerde R8 diese bei `minifyEnabled true` entfernen:
```pro
-keep class org.maplibre.android.** { *; }
-keep class com.mapbox.mapboxsdk.** { *; }
```

---

## APK-Groesse

Erwarteter Zuwachs ~3-5 MB durch MapLibre GL Native SDK. flutter_map bleibt parallel installiert fuer alle anderen Screens.

---

## Verifizierung

1. **flutter analyze**: 0 Fehler in Navigation-Dateien
2. **Release Build**: APK mit ProGuard-Rules kompiliert
3. **Physisches Geraet**: 3D-Perspektive, Heading-Rotation, Route-Split, Marker
4. **Uebersichts-Modus**: Flattent zu 2D, zeigt gesamte Route
5. **TTS**: Sprachansagen weiterhin funktional (Provider unveraendert)
