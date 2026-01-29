# Changelog v1.4.3 - Auto-Zoom auf Route

**Build-Datum:** 24. Januar 2026
**Flutter SDK:** 3.38.7

---

## Neues Feature

### Auto-Zoom auf Route beim Wechsel von Trip zur Karte

**Problem:** Wenn eine Route berechnet wurde und man vom Trip-Screen zur Karte wechselte, zeigte die Karte den zuletzt angezeigten Ausschnitt statt die Route.

**Lösung:** Beim Anzeigen des MapScreens wird jetzt geprüft, ob bereits eine Route existiert. Wenn ja, wird die Karte automatisch auf den Routen-Ausschnitt gezoomt.

**Geänderte Datei:**
- `lib/features/map/map_screen.dart` (initState)

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    // Wenn bereits eine Route existiert (z.B. von Trip-Screen kommend), zoome darauf
    final routePlanner = ref.read(routePlannerProvider);
    if (routePlanner.hasRoute) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _fitMapToRoute(routePlanner.route!);
        }
      });
    }
    // ... Listener für neue Routen
  });
}
```

---

## Enthält auch (aus v1.4.2)

- **Trip-Stops Bugfix**: Alte Stops werden bei neuer Route automatisch gelöscht

---

## Download

- **APK:** `MapAB-v1.4.3.apk` (57 MB)
- **GitHub Release:** https://github.com/jerdnaandrej777/mapab-app/releases/tag/v1.4.3
