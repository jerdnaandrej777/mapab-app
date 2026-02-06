# CHANGELOG v1.10.8 - Favoriten-Navigation & Speichern-UX

**Datum:** 2026-02-06
**Build:** 189

## Zusammenfassung

Verbessertes Speichern-Erlebnis und direkter Navigationsstart für Routen aus Favoriten. Der Speichern-Button ist jetzt prominenter und die "Route gespeichert"-Meldung wurde entfernt. Bei geladenen Routen aus Favoriten erscheint "Navigation starten" statt "Überrasch mich!".

## Features

### Dominanter Speichern-Button

**Vorher:** Kleiner IconButton in der AppBar (nur Lesezeichen-Icon)

**Nachher:** `FilledButton.tonalIcon` mit Icon + "Speichern" Text - deutlich sichtbarer und intuitiver.

```dart
// VORHER - Kleiner IconButton
IconButton(
  icon: const Icon(Icons.bookmark_add),
  tooltip: context.l10n.tripSaveRoute,
  onPressed: () => _saveRoute(),
),

// NACHHER - Dominanter Button mit Text
FilledButton.tonalIcon(
  onPressed: () => _saveRoute(),
  icon: const Icon(Icons.bookmark_add, size: 18),
  label: Text(context.l10n.save),
  style: FilledButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    visualDensity: VisualDensity.compact,
  ),
),
```

**Datei:** `lib/features/trip/trip_screen.dart` (Zeile 59-76)

### Snackbar-Meldung entfernt

Die "Route wurde gespeichert"-Meldung wird nicht mehr angezeigt. Der dominantere Button gibt ausreichend visuelles Feedback beim Speichern.

**Entfernt in:**
- `_saveRoute()` - Normale Routen
- `_saveAITrip()` - AI Trips

**Datei:** `lib/features/trip/trip_screen.dart`

### Navigation starten bei geladener Route

Wenn eine Route aus den Favoriten geladen wird, zeigt das TripConfigPanel jetzt "Navigation starten" statt "Überrasch mich!".

```dart
// Prüfen ob Route aus Favoriten geladen ist
final tripState = ref.watch(tripStateProvider);
final tripHasRoute = tripState.hasRoute;

// Button-Logik
tripHasRoute
    // Navigation starten (Route aus Favoriten)
    ? FilledButton.icon(
        onPressed: () => context.push(
          '/navigation',
          extra: {
            'route': tripState.route,
            'stops': tripState.stops
                .asMap()
                .entries
                .map((e) => TripStop.fromPOI(e.value, order: e.key))
                .toList(),
          },
        ),
        icon: const Icon(Icons.navigation),
        label: Text(context.l10n.tripInfoStartNavigation),
      )
    // Überrasch mich! (keine Route geladen)
    : ElevatedButton(
        onPressed: _handleGenerateTrip,
        child: Text('🎲 ${context.l10n.mapSurpriseMe}'),
      ),
```

**Datei:** `lib/features/map/widgets/trip_config_panel.dart` (Zeile 585-641)

---

## Technische Details

### Betroffene Dateien

| Datei | Änderungen |
|-------|------------|
| `lib/features/trip/trip_screen.dart` | Speichern-Button zu FilledButton.tonalIcon, Snackbar entfernt |
| `lib/features/map/widgets/trip_config_panel.dart` | Navigation starten Button bei geladener Route |
| `pubspec.yaml` | Version 1.10.8+189 |

### Workflow: Route aus Favoriten laden

1. Benutzer öffnet Favoriten-Screen
2. Tippt auf gespeicherte Route
3. Route wird geladen, Karte zeigt Route
4. TripConfigPanel zeigt "Navigation starten" Button
5. Benutzer tippt auf Button → Navigation startet

### Verifikation

1. **Speichern-Button:**
   - Route planen oder AI Trip generieren
   - In AppBar: FilledButton mit "Speichern" Text sichtbar
   - Klicken → Dialog erscheint (keine Snackbar danach)

2. **Navigation starten:**
   - Favoriten öffnen
   - Gespeicherte Route antippen
   - Zur Karte navigieren
   - TripConfigPanel zeigt "Navigation starten" statt "Überrasch mich!"
   - Klicken → Navigation startet

---

## Upgrade-Hinweise

Keine manuellen Schritte erforderlich. Einfach die neue Version installieren.
