# Changelog v1.10.15 (Build 196)

## Snackbar Auto-Dismiss Fix

Dieses Release behebt das Problem, dass die "Route gespeichert" Snackbar nicht automatisch verschwindet.

### Bugfixes

#### Snackbar bleibt haengen
- **Problem:** Die Snackbar "Route 'X' gespeichert" mit "Anzeigen"-Button verschwand nicht automatisch
- **Ursache:** Snackbars mit `SnackBarAction` haben in Flutter eine laengere Mindestdauer (ca. 10 Sekunden)
- **Loesung:**
  - Duration von 1 Sekunde auf **500 Millisekunden** reduziert
  - `SnackBarBehavior.floating` hinzugefuegt fuer korrektes Dismiss-Verhalten
  - "Anzeigen"-Button (SnackBarAction) entfernt

### Geaenderte Dateien

| Datei | Aenderung |
|-------|-----------|
| `lib/features/trip/utils/trip_save_helper.dart` | Alle 3 Snackbars (saveRoute, saveAITrip, saveRouteDirectly) auf 500ms + floating geaendert, Action entfernt |

### Code-Aenderung

```dart
// VORHER - bleibt haengen
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(context.l10n.tripRouteSaved(result)),
    duration: const Duration(seconds: 1),
    action: SnackBarAction(
      label: context.l10n.tripShowInFavorites,
      onPressed: () => context.push('/favorites'),
    ),
  ),
);

// NACHHER - verschwindet nach 0.5 Sekunden
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(context.l10n.tripRouteSaved(result)),
    duration: const Duration(milliseconds: 500),
    behavior: SnackBarBehavior.floating,
  ),
);
```

---

**Build:** 196
**Version:** 1.10.15
**Datum:** 2026-02-06
