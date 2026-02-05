# CHANGELOG v1.10.6 - Route Speichern Button Fix

**Datum:** 2026-02-05
**Build:** 187

## Zusammenfassung

Fix für fehlenden "Route Speichern" Button bei AI Trips. Der Lesezeichen-Button in der AppBar des TripScreens wird jetzt sowohl für normale Routen als auch für AI Trips angezeigt.

## Bugfixes

### Route Speichern Button fehlt bei AI Trips

**Problem:**
Der "Route Speichern" Button (Lesezeichen-Icon) in der AppBar des TripScreens wurde nur für normale Routen angezeigt, nicht für AI Trips (Tagestrip oder Euro Trip).

**Ursache:**
Die Bedingung prüfte nur `tripState.hasRoute`, aber bei AI Trips ist die Route in `randomTripState.generatedTrip` gespeichert:

```dart
// VORHER - Button nur bei normalen Routen
if (tripState.hasRoute)
  IconButton(
    icon: const Icon(Icons.bookmark_add),
    onPressed: () => _saveRoute(context, ref, tripState),
  ),
```

**Lösung:**
Die Bedingung wurde erweitert, um auch AI Trips zu berücksichtigen:

```dart
// NACHHER - Button auch bei AI Trips
if (tripState.hasRoute ||
    randomTripState.step == RandomTripStep.preview ||
    randomTripState.step == RandomTripStep.confirmed)
  IconButton(
    icon: const Icon(Icons.bookmark_add),
    onPressed: () {
      if (randomTripState.step == RandomTripStep.preview ||
          randomTripState.step == RandomTripStep.confirmed) {
        _saveAITrip(context, ref, randomTripState);
      } else {
        _saveRoute(context, ref, tripState);
      }
    },
  ),
```

**Datei:** `lib/features/trip/trip_screen.dart` (Zeile 55-69)

---

## Technische Details

### Betroffene Dateien

| Datei | Änderungen |
|-------|------------|
| `lib/features/trip/trip_screen.dart` | AppBar Button-Bedingung erweitert für AI Trips |
| `pubspec.yaml` | Version 1.10.6+187 |

### Button-Sichtbarkeit nach dem Fix

| Route-Typ | Button sichtbar? |
|-----------|------------------|
| Normale Route | Ja |
| AI Trip (Preview) | Ja |
| AI Trip (Confirmed) | Ja |

### Verifikation

1. App starten
2. AI Trip generieren (Tagestrip oder Euro Trip)
3. Der Lesezeichen-Button sollte in der AppBar sichtbar sein
4. Button klicken → Dialog für Routennamen erscheint
5. Speichern → Route wird in Favoriten gespeichert

---

## Upgrade-Hinweise

Keine manuellen Schritte erforderlich. Einfach die neue Version installieren.
