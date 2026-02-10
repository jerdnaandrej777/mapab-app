# Changelog v1.10.62 - POI-Publish Favoriten, Journal-Bug-Fix

**Datum:** 10. Februar 2026
**Build:** 246

## Zusammenfassung

POIs koennen jetzt aus den Favoriten veroeffentlicht werden (Publish-Button auf jeder POI-Card). Journal-Eintraege bleiben unabhaengig vom Route-Status sichtbar - der Bug, bei dem Eintraege nach Routenberechnung verschwanden, ist behoben.

## Aenderungen

### POI-Publish aus Favoriten

- **Publish-Button** auf jeder POI-Card im Favoriten-Screen (oben-links, Globe-Icon)
- Auth-Check: Zeigt Login-Hinweis wenn nicht eingeloggt
- Oeffnet das existierende `PublishPoiSheet` (wiederverwendbar aus allen Modulen)
- Analog zum Route-Publish-Button der bereits auf Route-Tiles existiert

### Journal-Bug-Fix

- **Root Cause:** `_openJournalFromMap()` in `map_screen.dart` verwendete verschiedene `tripId`-Werte je nach Route-Status:
  - Keine Route: `'journal-home'`
  - Route berechnet: `'route-${route.hashCode}'` (wechselnde ID!)
  - AI Trip: `trip.id`
- Eintraege mit `tripId='journal-home'` waren unsichtbar wenn die App `tripId='route-12345'` verwendete
- **Fix:** Immer `'journal-home'` als Standard-tripId nutzen, ausser bei einem echten AI Trip
- Eintraege sind jetzt unabhaengig vom Route-Status immer sichtbar

## Geaenderte Dateien

| Datei | Aenderung |
|-------|-----------|
| `lib/features/favorites/favorites_screen.dart` | Publish-Button auf POI-Cards, `_publishPOI()` Methode |
| `lib/features/map/map_screen.dart` | `_openJournalFromMap()`: stabiles `'journal-home'` tripId |
| `pubspec.yaml` | Version 1.10.62+246 |
