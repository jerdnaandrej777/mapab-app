# Changelog v1.4.0 - Neues Logo & Mehr POIs

**Release-Datum:** 23. Januar 2026

## Highlights

### Neues App-Logo
- Modernes Design mit offiziellen App-Farben
- Blauer Gradient-Hintergrund (#3B82F6 → #2563EB → #1D4ED8)
- Weißer Location-Pin mit grünem Akzent (#10B981)
- "MapAB" Text prominent im Logo
- Alle Android-Icon-Größen generiert

### Mehr POIs sichtbar
- POI-Qualitätsfilter von 70 auf 35 gesenkt
- OSM/Overpass POIs jetzt sichtbar (hatten nur Score 40)
- Wikipedia POIs mit Standard-Keywords sichtbar (Score 55)
- Deutlich mehr Sehenswürdigkeiten werden angezeigt

### App-Name offiziell "MapAB"
- AndroidManifest: `android:label="MapAB"`
- Konsistentes Branding in der gesamten App

## Technische Änderungen

### poi_repo.dart
```dart
// Vorher
const int minimumPOIScore = 70;

// Nachher
const int minimumPOIScore = 35;
```

### AndroidManifest.xml
```xml
<!-- Vorher -->
<application android:label="travel_planner" ...>

<!-- Nachher -->
<application android:label="MapAB" ...>
```

### generate-icons.js
- Neues SVG-Design mit App-Farben
- Blau-Gradient statt Lila
- Grüner Akzent im Pin (Secondary Color)
- Subtile Wellenformen im Hintergrund
- Schatten-Effekt für Tiefe

## Dateien geändert

| Datei | Änderung |
|-------|----------|
| `pubspec.yaml` | Version 1.3.9 → 1.4.0 |
| `lib/data/repositories/poi_repo.dart` | minimumPOIScore 70 → 35 |
| `android/app/src/main/AndroidManifest.xml` | App-Label → MapAB |
| `generate-icons.js` | Neues Logo-Design |
| `android/app/src/main/res/mipmap-*/ic_launcher.png` | Neue Icons |
| `assets/icon/mapab-icon.png` | Neues 1024x1024 Icon |
| `QR-CODE-DOWNLOAD.html` | v1.4.0 + neue Farben |
| `QR-CODE-SIMPLE.html` | v1.4.0 + neue Farben |
| `QR-CODE-README.md` | v1.4.0 + neue Features |
| `CLAUDE.md` | Version 1.4.0 |

## POI-Score-Übersicht

| POI-Quelle | Score | v1.3.9 (min 70) | v1.4.0 (min 35) |
|------------|-------|-----------------|-----------------|
| Kuratierte POIs | 50-100 | Teilweise | Alle |
| Wikipedia (bekannte Keywords) | 75 | Sichtbar | Sichtbar |
| Wikipedia (mittlere Keywords) | 65 | Gefiltert | Sichtbar |
| Wikipedia (Standard) | 55 | Gefiltert | Sichtbar |
| OSM/Overpass | 40 | Gefiltert | Sichtbar |

## Download

**GitHub Release:** https://github.com/jerdnaandrej777/mapab-app/releases/tag/v1.4.0

**APK:** MapAB-v1.4.0.apk (56.8 MB)
