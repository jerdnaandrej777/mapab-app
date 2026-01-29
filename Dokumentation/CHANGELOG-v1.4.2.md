# Changelog v1.4.2 - Trip-Stops Bugfix

**Build-Datum:** 24. Januar 2026
**Flutter SDK:** 3.38.7

---

## Bugfix

### Trip-Stops werden bei neuer Route nicht gelöscht

**Problem:** Wenn eine Route berechnet wurde (z.B. in Deutschland), POIs zur Trip-Liste hinzugefügt wurden, und danach manuell Start/Ziel auf der Karte an einem anderen Ort (z.B. Mallorca) gesetzt wurden, blieben die alten Trip-Stops aus Deutschland im Trip-Screen sichtbar.

**Ursache:** In `_tryCalculateRoute()` wurden zwar die POIs (`pOIStateNotifierProvider.clearPOIs()`) und die Route-Session gelöscht, aber die Trip-Stops (`tripStateProvider.clearStops()`) wurden nicht gelöscht.

**Lösung:** Beim Berechnen einer neuen Route werden jetzt auch die Trip-Stops gelöscht.

**Geänderte Datei:**
- `lib/features/map/providers/route_planner_provider.dart` (Zeile 77)

```dart
// Alte Route-Session stoppen, POIs und Trip-Stops löschen
ref.read(routeSessionProvider.notifier).stopRoute();
ref.read(pOIStateNotifierProvider.notifier).clearPOIs();
ref.read(tripStateProvider.notifier).clearStops();  // NEU
print('[RoutePlanner] Alte Route-Session, POIs und Trip-Stops gelöscht');
```

---

## Technische Details

### State-Management Verbesserung

Die Route-Berechnung löscht jetzt konsistent alle abhängigen States:
1. Route-Session (`routeSessionProvider.stopRoute()`)
2. POIs (`pOIStateNotifierProvider.clearPOIs()`)
3. **Trip-Stops** (`tripStateProvider.clearStops()`) - NEU

Dies stellt sicher, dass beim Setzen neuer Start-/Zielpunkte keine veralteten Daten angezeigt werden.

---

## Upgrade-Hinweise

- Keine Breaking Changes
- APK kann direkt über v1.4.1 installiert werden
- Bestehende Favoriten und Cloud-Daten bleiben erhalten

---

## Download

- **APK:** `MapAB-v1.4.2.apk` (57 MB)
- **GitHub Release:** https://github.com/jerdnaandrej777/mapab-app/releases/tag/v1.4.2
