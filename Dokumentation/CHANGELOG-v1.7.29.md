# Changelog v1.7.29 - Kategorie-Fallback, ref.listen Fix & CategorySelector Dark Mode

**Datum:** 31. Januar 2026
**Typ:** Bugfix & Architektur-Verbesserung
**Plattformen:** Android, iOS, Desktop

---

## Zusammenfassung

Behebt den Fehler "Keine POIs im Umkreis von Xkm gefunden", der auftrat, wenn der Benutzer nur 1 Kategorie ausgewaehlt hatte und keine POIs dieser Kategorie im Suchradius vorhanden waren. Zusaetzlich wurde die Panel Auto-Collapse Architektur von `ref.listenManual` in `initState` auf `ref.listen` in `build()` migriert (idiomatischer Riverpod-Ansatz). Der CategorySelector wurde auf Dark-Mode-kompatible `colorScheme`-Farben umgestellt.

---

## Aenderungen

### 1. **Kategorie-Fallback bei Trip-Generierung**
- **Problem:** Bei Auswahl von nur 1 Kategorie (z.B. "Kuesten & Straende" um Koeln) schlug die Trip-Generierung komplett fehl, weil keine POIs dieser Kategorie im Radius existierten
- **Loesung:** Automatischer Fallback auf alle Kategorien wenn der Kategorie-Filter 0 POIs ergibt
- **Betrifft:** Sowohl Tagestrip als auch Euro Trip Generierung
- **Verhalten:** `selectRandomPOIs()` nutzt weiterhin `preferredCategories` um die gewuenschte Kategorie zu bevorzugen - der Trip schlaegt aber nicht mehr fehl
- **Cache-Effizienz:** Der Fallback-Aufruf nutzt den bereits befuellten POI-Cache (POIs werden vor dem Kategorie-Filter gecached), daher praktisch keine zusaetzliche Ladezeit

### 2. **Doppeltes Fehler-Praefix behoben**
- **Problem:** Fehlermeldungen zeigten doppelt "Trip-Generierung fehlgeschlagen: Trip-Generierung fehlgeschlagen: ..." bei generischen Fehlern
- **Ursache:** `map_screen.dart` fuegt "Trip-Generierung fehlgeschlagen:" hinzu UND `random_trip_provider.dart` fuegt es ebenfalls hinzu
- **Fix:** `map_screen.dart` zeigt jetzt direkt `next.error!` ohne zusaetzliches Praefix

### 3. **Besseres Kategorie-Filter Logging**
- **Neu:** `[POI] Kategorie-Filter [coast]: 150 -> 0 POIs` zeigt explizit wie viele POIs durch den Filter entfallen
- **Neu:** `[TripGenerator] Keine POIs fuer Kategorien [coast] - Fallback auf alle Kategorien` bei Fallback-Aktivierung

### 4. **Panel Auto-Collapse: ref.listen Migration (v1.7.28 Bugfix)**
- **Problem:** Die v1.7.28 Listener (`ref.listenManual` in `addPostFrameCallback` in `initState()`) hatten Timing-/Lifecycle-Probleme:
  - Listener wurden NACH dem ersten Frame registriert
  - MapScreen wird bei Tab-Wechsel disposed (GoRouter ShellRoute OHNE IndexedStack)
  - Bei Rueckkehr lief `initState` erneut, registrierte neue Listener
- **Loesung:** Migration zu `ref.listen` in `build()` - idiomatischer Riverpod-Ansatz
- **Vorteile:** Kein Timing-Problem, automatisches Lifecycle-Management, keine doppelten Listener bei Widget-Rebuild
- **initState vereinfacht:** Nur noch `_handleInitialMapSetup()` fuer einmalige Map-Initialisierung (Zoom auf Route oder GPS)
- **Mode-Restoration:** Bedingte `addPostFrameCallback` in `build()` korrigiert Modus nach Hot-Restart

### 5. **CategorySelector Dark Mode Fix**
- **Problem:** `_CategoryChip` in `category_selector.dart` verwendete hart-codierte Farben (`Colors.grey`, `Color(category.colorValue)`, `AppTheme.textPrimary`)
- **Fix:** Komplett auf `colorScheme.*` umgestellt:
  - Ausgewaehlt: `colorScheme.primary` Hintergrund + `colorScheme.onPrimary` Text + blauer Schatten
  - Nicht ausgewaehlt: `colorScheme.surfaceContainerHighest` + `colorScheme.onSurface` Text
- **AnimatedContainer:** `Container` durch `AnimatedContainer` (100ms) ersetzt fuer konsistentes Chip-Feedback
- **Check-Icon:** Von rechts nach links verschoben (vor dem Label, wie in poi_list_screen.dart)
- **Ergebnis:** CategorySelector-Chips konsistent mit Quick-Filter-Chips (v1.7.26 Referenz-Pattern)

---

## Geaenderte Dateien

| Datei | Aenderung |
|-------|-----------|
| `lib/data/repositories/trip_generator_repo.dart` | Kategorie-Fallback in `generateDayTrip()` und `generateEuroTrip()` |
| `lib/features/map/map_screen.dart` | Doppeltes Fehler-Praefix entfernt + `ref.listen` in `build()` statt `ref.listenManual` in `initState` + `_handleInitialMapSetup()` extrahiert |
| `lib/data/repositories/poi_repo.dart` | Kategorie-Filter Debug-Logging |
| `lib/features/random_trip/widgets/category_selector.dart` | Dark Mode Fix: `colorScheme.*` statt hart-codierte Farben, AnimatedContainer, Check-Icon links |
| `pubspec.yaml` | Version 1.7.29+129 |

---

## Architektur: ref.listen in build()

```dart
// VORHER (v1.7.28 - Timing-Probleme):
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ref.listenManual(routePlannerProvider, (previous, next) { ... });
    ref.listenManual(randomTripNotifierProvider, (previous, next) { ... });
  });
}

// NACHHER (v1.7.29 - idiomatisch):
@override
Widget build(BuildContext context) {
  // Listener in build() - automatisches Lifecycle-Management
  ref.listen(routePlannerProvider, (previous, next) {
    if (previous == null) return; // Initialer Aufruf ignorieren
    if (next.hasRoute && previous.route != next.route) {
      _fitMapToRoute(next.route!);
      ref.read(mapPanelCollapsedProvider.notifier).state = true;
    }
  });

  ref.listen(randomTripNotifierProvider, (previous, next) {
    if (previous == null) return;
    if (next.step == RandomTripStep.preview &&
        previous.step != RandomTripStep.preview) {
      final aiRoute = next.generatedTrip?.trip.route;
      if (aiRoute != null && mounted) _fitMapToRoute(aiRoute);
      ref.read(mapPanelCollapsedProvider.notifier).state = true;
    }
  });
  // ...
}
```

---

## Reproduktion des Kategorie-Bugs

1. MapScreen oeffnen → AI Trip Modus
2. Startpunkt: Koeln (oder eine andere Stadt im Inland)
3. Radius: 280 km
4. Kategorien: Nur 1 auswaehlen (z.B. "Kuesten & Straende")
5. "Ueberrasch mich!" klicken
6. **Vorher:** Rote Fehlermeldung "Keine POIs im Umkreis von 280.0km gefunden"
7. **Nachher:** Trip wird mit verfuegbaren POIs generiert (bevorzugt die gewaehlte Kategorie)

---

**Status:** Abgeschlossen
**Review:** Pending
**Deploy:** Released as v1.7.29
