# Changelog v1.6.3 - Euro Trip Route-Anzeige Fix

**Release-Datum:** 28. Januar 2026

## Fehlerbehebung

### Euro Trip Route erscheint nicht auf Karte

**Problem:** Nach Generierung eines Euro Trips wurde die Route nicht auf der Karte angezeigt, obwohl die Generierung erfolgreich war.

**Ursachen:**
1. `RandomTripNotifier` hatte kein `keepAlive: true` - State ging beim Komponenten-Wechsel verloren
2. Route-Priorität in `map_view.dart` war falsch - alte Trip-Route wurde vor AI Trip Route angezeigt
3. Start-Marker Priorität war falsch - `routePlanner.startLocation` statt `randomTripState.startLocation`

**Lösung:**
- `@Riverpod(keepAlive: true)` für `RandomTripNotifier` hinzugefügt
- Route-Koordinaten Priorität geändert: AI Trip Preview → TripState → RoutePlanner
- Start-Marker Priorität geändert: AI Trip Preview hat Vorrang

## Technische Details

### Geänderte Dateien

| Datei | Änderung |
|-------|----------|
| `lib/features/random_trip/providers/random_trip_provider.dart` | `keepAlive: true` + Debug-Logging |
| `lib/features/map/widgets/map_view.dart` | Route/Marker Priorität gefixt |
| `lib/features/map/map_screen.dart` | Debug-Logging für State-Änderungen |

### Route-Priorität Fix

```dart
// VORHER - AI Trip Route wurde ignoriert wenn alte Route existierte
points: tripState.route?.coordinates ??
        routePlanner.route?.coordinates ??
        aiTripRoute?.coordinates ?? []

// NACHHER - AI Trip Preview hat Priorität
points: (isAITripPreview && aiTripRoute != null)
    ? aiTripRoute.coordinates
    : (tripState.route?.coordinates ??
        routePlanner.route?.coordinates ??
        [])
```

### keepAlive Fix

```dart
// VORHER - State konnte verloren gehen
@riverpod
class RandomTripNotifier extends _$RandomTripNotifier { ... }

// NACHHER - State bleibt erhalten
@Riverpod(keepAlive: true)
class RandomTripNotifier extends _$RandomTripNotifier { ... }
```

## Hinweise

- Debug-Logging wurde hinzugefügt (`[MapScreen]`, `[RandomTrip]`)
- Die Route wird jetzt automatisch auf die Karte gezoomt nach Generierung
- Start-Marker zeigt den korrekten Startpunkt für AI Trips

---

**Vollständige Änderungen seit v1.6.2:**
- Euro Trip Route-Anzeige Fix (v1.6.3)
