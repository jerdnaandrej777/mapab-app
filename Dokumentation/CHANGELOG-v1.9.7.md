# CHANGELOG v1.9.7 - Korridor-Browser Inline-Integration im Tag-Editor

**Datum:** 3. Februar 2026
**Build:** 1.9.7+154 (vorher 1.9.6+153)

## Zusammenfassung

Der Korridor-Browser ("POIs hinzufuegen") oeffnete sich bisher als Modal-BottomSheet und verdeckte die MiniMap und Tages-Statistiken. Ab v1.9.7 ist der Korridor-Browser direkt inline im DayEditor integriert: MiniMap + Stats bleiben fixiert oben sichtbar, der Korridor-Browser fuellt den restlichen Platz darunter aus. Kein Modal-Sheet mehr im DayEditor.

---

## Aenderung 1: CorridorBrowserContent als wiederverwendbares Widget

### corridor_browser_sheet.dart

Neues Widget `CorridorBrowserContent` extrahiert, das die gesamte UI-Logik enthaelt:
- Header mit Titel + Close-Button
- Buffer-Slider (10-100km Korridor-Breite)
- Kategorie-Filter-Chips
- POI-Liste mit CompactPOICards

**Parameter:**
```dart
class CorridorBrowserContent extends ConsumerStatefulWidget {
  final AppRoute route;
  final Set<String> existingStopIds;
  final Future<bool> Function(POI poi)? onAddPOI;
  final VoidCallback? onClose;
  final ScrollController? scrollController;
}
```

**Zwei Verwendungsmodi:**
1. **Inline (DayEditor):** `scrollController = null` → eigener interner Controller
2. **Modal (TripScreen):** `scrollController` vom DraggableScrollableSheet durchgereicht

`CorridorBrowserSheet` delegiert jetzt intern an `CorridorBrowserContent` — TripScreen-Nutzung (Vollbild) bleibt 100% identisch.

---

## Aenderung 2: DayEditor Layout-Umstrukturierung

### day_editor_overlay.dart

**Vorher (v1.9.6):**
```
Scaffold
  body: Column
    [DayTabSelector]
    Expanded(ListView: MiniMap, Stats, POI-Karten)  ← alles scrollte!
  bottomNavigationBar: _BottomActions
  → "POIs hinzufuegen" oeffnete Modal-BottomSheet
```

**Nachher (v1.9.7):**
```
Scaffold
  body: Column
    [DayTabSelector]
    MiniMap                    ← fixiert (scrollt NICHT)
    Stats                      ← fixiert (scrollt NICHT)
    if (corridorBrowserActive)
      Expanded(CorridorBrowserContent)   ← inline
    else
      Expanded(ListView: POI-Karten)     ← normal
  bottomNavigationBar: corridorBrowserActive ? null : _BottomActions
```

**Neue State-Variable:**
```dart
bool _isCorridorBrowserActive = false;
```

**Auto-Close bei Tageswechsel:**
```dart
ref.listen<int>(
  randomTripNotifierProvider.select((s) => s.selectedDay),
  (previous, next) {
    if (previous != next && _isCorridorBrowserActive) {
      setState(() => _isCorridorBrowserActive = false);
    }
  },
);
```

---

## Aenderung 3: BottomActions Callback

`_BottomActions` erweitert mit `VoidCallback onOpenCorridorBrowser`:
- "POIs hinzufuegen" Button ruft `onOpenCorridorBrowser` auf
- Kein `CorridorBrowserSheet.show()` mehr im DayEditor
- `bottomNavigationBar` wird ausgeblendet wenn Korridor-Browser aktiv

---

## Keine Aenderungen

| Datei | Grund |
|-------|-------|
| `corridor_browser_provider.dart` | State/Logic bleibt identisch |
| `compact_poi_card.dart` | Widget unveraendert |
| `day_mini_map.dart` | 180px Hoehe + didUpdateWidget → Live-Updates funktionieren |
| `trip_screen.dart` | Nutzt weiterhin `CorridorBrowserSheet.show()` Vollbild |
| `random_trip_provider.dart` | `addPOIToDay()` funktioniert korrekt |

---

## Verifizierung

- [x] `flutter analyze` → keine Fehler (nur info-level withOpacity Warnungen)
- [x] DayEditor: MiniMap + Stats oben fixiert, POI-Karten scrollbar
- [x] "POIs hinzufuegen" → Layout wechselt: Korridor-Browser inline unter Stats
- [x] MiniMap + Stats bleiben fixiert sichtbar
- [x] X-Button im Korridor-Browser → zurueck zum normalen DayEditor
- [x] Tageswechsel bei offenem Korridor-Browser → schliesst automatisch
- [x] TripScreen Korridor-Browser → weiterhin Vollbild-BottomSheet

## Betroffene Dateien

1. `lib/features/trip/widgets/corridor_browser_sheet.dart` — CorridorBrowserContent extrahiert
2. `lib/features/trip/widgets/day_editor_overlay.dart` — Inline-Integration + Layout-Umstrukturierung
3. `pubspec.yaml` — Version 1.9.7+154
4. `QR-CODE-DOWNLOAD.html` — v1.9.7 Links + Features
5. `CLAUDE.md` — Versions-Update + Feature-Beschreibungen
