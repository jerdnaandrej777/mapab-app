# Changelog v1.4.4 - AI Trip POI-Bearbeitung

**Build-Datum:** 24. Januar 2026
**Flutter SDK:** 3.38.7

---

## Neue Features

### Einzelne POIs aus AI-Trip löschen

**Problem:** Bei einem AI-generierten Trip (Tagesausflug oder Euro Trip) konnte man vor dem Speichern keine einzelnen POIs entfernen, sondern musste den gesamten Trip neu generieren.

**Lösung:** In der Trip-Vorschau hat jeder POI jetzt einen Löschen-Button (🗑️). Nach dem Entfernen wird die Route automatisch neu berechnet.

**Einschränkung:** Mindestens 2 POIs müssen im Trip bleiben.

### Einzelne POIs neu würfeln (lokal statt global)

**Problem:** Der "Neu würfeln"-Button hat immer den gesamten Trip neu generiert, anstatt nur einen einzelnen POI zu ersetzen.

**Lösung:** Der Würfel-Button (🎲) ersetzt jetzt nur den einzelnen POI durch einen neuen aus der verfügbaren POI-Liste. Die restlichen POIs bleiben erhalten.

### Per-POI Loading-Anzeige

**Problem:** Beim Laden wurde keine Information angezeigt, welcher POI gerade bearbeitet wird.

**Lösung:** Jeder POI hat jetzt eine individuelle Loading-Anzeige. Während ein POI geladen wird, sind die Buttons für andere POIs deaktiviert.

---

## Technische Änderungen

### Geänderte Dateien

| Datei | Änderung |
|-------|----------|
| `lib/data/repositories/trip_generator_repo.dart` | Neue `removePOI()` Methode |
| `lib/features/random_trip/providers/random_trip_provider.dart` | Neue `removePOI()` Methode + `loadingPOIId` State |
| `lib/features/random_trip/providers/random_trip_state.dart` | Neues `loadingPOIId` Feld + `canRemovePOI` / `isPOILoading()` Getter |
| `lib/features/random_trip/widgets/poi_reroll_button.dart` | Neues `POIActionButtons` Widget (Delete + Reroll) |
| `lib/features/random_trip/widgets/trip_preview_card.dart` | Integration der neuen Buttons |

### Neue Provider-Methoden

```dart
// POI entfernen
ref.read(randomTripNotifierProvider.notifier).removePOI(poiId);

// POI neu würfeln (ersetzt nur diesen POI)
ref.read(randomTripNotifierProvider.notifier).rerollPOI(poiId);
```

### Neue State-Getter

```dart
// Kann POIs entfernt werden? (> 2 vorhanden)
final canRemove = state.canRemovePOI;

// Welcher POI wird gerade geladen?
final loadingId = state.loadingPOIId;

// Ist ein bestimmter POI am Laden?
final isLoading = state.isPOILoading(poiId);
```

---

## UI-Änderungen

### Vorher (v1.4.3)
- Nur Würfel-Button pro POI
- Würfeln generiert gesamten Trip neu

### Nachher (v1.4.4)
- Löschen-Button (🗑️) + Würfel-Button (🎲) pro POI
- Löschen entfernt nur diesen POI
- Würfeln ersetzt nur diesen POI
- Individuelle Loading-Anzeige pro POI
- Buttons deaktiviert während Laden

---

## Enthält auch (aus v1.4.3)

- **Auto-Zoom auf Route**: Karte zoomt beim Wechsel von Trip automatisch auf Route

---

## Download

- **APK:** `MapAB-v1.4.4.apk` (57 MB)
- **GitHub Release:** https://github.com/jerdnaandrej777/mapab-app/releases/tag/v1.4.4
