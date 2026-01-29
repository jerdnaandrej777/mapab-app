# Changelog v1.7.5 - Route Löschen Button für AI-Chat Routen

**Release-Datum:** 29. Januar 2026

## Zusammenfassung

Diese Version fügt den "Route löschen" Button auch für Routen hinzu, die über den AI-Assistenten (Chat) generiert wurden. Bisher fehlte dieser Button auf der Hauptseite, wenn eine Route über den AI-Chat erstellt wurde.

## Neue Features

### Route Löschen Button für AI-Chat Routen

**Problem:** Wenn eine Route über den AI-Assistenten (Chat-Screen) generiert wurde und auf der Hauptseite angezeigt wird, fehlte der "Route löschen" Button.

**Lösung:** Die Bedingung für den `_RouteClearButton` wurde erweitert um auch `tripState.hasRoute` zu prüfen.

**Betroffene Dateien:**
- `lib/features/map/map_screen.dart`

**Änderungen:**

1. **Schnell-Modus Button** (Zeile 279-297):
   - Bedingung erweitert um `tripState.hasRoute`
   - Button erscheint jetzt auch bei AI-Chat Routen

2. **AI Trip Modus Button** (Zeile 331-349):
   - Ebenfalls um `tripState.hasRoute` erweitert
   - Konsistentes Verhalten in beiden Modi

3. **Lösch-Aktion**:
   - Alle drei Route-States werden jetzt zurückgesetzt:
     - `routePlannerProvider.clearRoute()` - Schnell-Modus Route
     - `randomTripNotifierProvider.reset()` - AI Trip Panel Route
     - `tripStateProvider.clearAll()` - AI-Chat Route

## Code-Änderungen

```dart
// VORHER (v1.7.4) - Nur Schnell-Modus und AI Trip berücksichtigt:
if (routePlanner.hasStart || routePlanner.hasEnd ||
    randomTripState.step == RandomTripStep.preview ||
    randomTripState.step == RandomTripStep.confirmed)

// NACHHER (v1.7.5) - Auch AI-Chat Routen (tripState):
if (routePlanner.hasStart || routePlanner.hasEnd ||
    randomTripState.step == RandomTripStep.preview ||
    randomTripState.step == RandomTripStep.confirmed ||
    tripState.hasRoute)
```

## Technische Details

### Route-States in MapAB

Es gibt drei verschiedene Quellen für Routen:

| Provider | Quelle | Verwendung |
|----------|--------|------------|
| `routePlannerProvider` | Schnell-Modus | Start/Ziel manuell setzen |
| `randomTripNotifierProvider` | AI Trip Panel | Zufällige Route generieren |
| `tripStateProvider` | AI-Chat, Trip-Screen | Route mit Stops verwalten |

### Warum drei States?

- **routePlannerProvider**: Einfache A-nach-B Route
- **randomTripNotifierProvider**: AI-generierte Trips mit Vorschau
- **tripStateProvider**: Persistente Route mit bearbeitbaren Stops

Wenn eine Route über den AI-Chat generiert wird, wird sie im `tripStateProvider` gespeichert (nicht im `routePlannerProvider`), daher wurde der Löschen-Button bisher nicht angezeigt.

## Auswirkungen

- Keine Breaking Changes
- Keine API-Änderungen
- Verbesserte UX bei AI-Chat Routen
