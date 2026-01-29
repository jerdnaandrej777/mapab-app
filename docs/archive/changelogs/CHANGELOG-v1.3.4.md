# Changelog v1.3.4 - Route Löschen & UI-Updates

**Release-Datum:** 23. Januar 2026

## Neue Features

### Route Löschen Funktionalität

Die App bietet jetzt umfassende Möglichkeiten zum Löschen von Routen:

#### 1. X-Buttons in der Suchleiste (MapScreen)
- **Start-Adresse löschen**: X-Button erscheint neben der Start-Adresse
- **Ziel-Adresse löschen**: X-Button erscheint neben der Ziel-Adresse
- Beim Löschen wird auch die berechnete Route entfernt
- Das jeweils andere Feld bleibt erhalten

#### 2. "Route löschen" Button (MapScreen)
- Erscheint unterhalb des Fast/Scenic-Toggles
- Nur sichtbar wenn Start oder Ziel gesetzt ist
- Löscht mit einem Klick: Start + Ziel + Route + Trip-State
- Roter Button mit Papierkorb-Icon für klare Erkennbarkeit

#### 3. "Gesamte Route löschen" im Trip-Menü (TripScreen)
- Neuer Menüpunkt im Mehr-Menü (⋮)
- Bestätigungs-Dialog vor dem Löschen
- Löscht Route und alle Stops
- Navigiert automatisch zur Karte zurück

#### 4. Zufalls-Trip überschreibt bestehende Route
- Wenn bereits eine manuelle Route existiert
- Und dann ein Zufalls-Trip bestätigt wird
- Wird die alte Route automatisch überschrieben
- Keine Reste der alten Route im routePlannerProvider

## Technische Änderungen

### Neue Provider-Methode

```dart
// lib/features/map/providers/route_planner_provider.dart

/// Löscht die gesamte Route (Start, Ziel, berechnete Route)
void clearRoute() {
  state = const RoutePlannerData();
  // Auch im Trip-State löschen
  ref.read(tripStateProvider.notifier).clearAll();
}
```

### UI-Komponenten

**Neue Widgets in map_screen.dart:**
- `_RouteClearButton` - Der "Route löschen" Button
- `_SearchField.onClear` - Neuer Callback für X-Button

**Neue Parameter:**
- `_SearchBar.onStartClear` - Callback für Start-X-Button
- `_SearchBar.onEndClear` - Callback für Ziel-X-Button

### Geänderte Dateien

| Datei | Änderung |
|-------|----------|
| `lib/features/map/providers/route_planner_provider.dart` | `clearRoute()` Methode |
| `lib/features/map/map_screen.dart` | X-Buttons + Route löschen Button |
| `lib/features/trip/trip_screen.dart` | Menüpunkt + `_clearEntireRoute()` |
| `lib/features/random_trip/providers/random_trip_provider.dart` | Route-Reset in `confirmTrip()` |

## Build-System Updates

### Android Gradle Plugin
- **Vorher:** 8.5.0
- **Nachher:** 8.9.1

### Gradle Version
- **Vorher:** 8.7
- **Nachher:** 8.11.1

### NDK Version
- **Vorher:** 26.1.10909125
- **Nachher:** 28.2.13676358

## Geänderte Konfigurationsdateien

| Datei | Änderung |
|-------|----------|
| `android/settings.gradle` | AGP 8.9.1 |
| `android/gradle/wrapper/gradle-wrapper.properties` | Gradle 8.11.1 |
| `android/app/build.gradle` | NDK 28.2.13676358 |
| `pubspec.yaml` | Version 1.3.4+1 |

## Download

- **GitHub Release:** [v1.3.4](https://github.com/jerdnaandrej777/mapab-app/releases/tag/v1.3.4)
- **APK:** MapAB-v1.3.4.apk (56.6 MB)

## Verwendung

### Route einzeln löschen

```dart
// Start löschen (Ziel bleibt)
ref.read(routePlannerProvider.notifier).clearStart();

// Ziel löschen (Start bleibt)
ref.read(routePlannerProvider.notifier).clearEnd();
```

### Route komplett löschen

```dart
// Löscht Start + Ziel + Route + Trip-State
ref.read(routePlannerProvider.notifier).clearRoute();
```

## Screenshots

### MapScreen mit Route löschen Button
```
┌────────────────────────────────┐
│ 🟢 München                [X]  │  ← X-Button zum Löschen
│─────────────────────────────────│
│ 📍 Berlin                 [X]  │  ← X-Button zum Löschen
└────────────────────────────────┘

    [Schnell]  [Landschaft]

    [🗑️ Route löschen]           ← Neuer Button

    [▶️ Route starten - 584 km]
```

### TripScreen Menü
```
┌────────────────────────────────┐
│ ✨ Route optimieren            │
│ 💾 Route speichern             │
│ 📤 Route teilen                │
│ 🗑️ Alle Stops löschen          │
│ 🗑️ Gesamte Route löschen       │  ← NEU
└────────────────────────────────┘
```
