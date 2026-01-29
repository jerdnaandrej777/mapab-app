# Changelog v1.6.4 - POI Hinzufügen ohne Snackbar

**Release-Datum:** 28. Januar 2026

## UX-Verbesserung

### Snackbar beim POI-Hinzufügen entfernt

**Vorher:** Beim Hinzufügen eines POIs zur Route erschien eine Snackbar-Meldung "{POI Name} zur Route hinzugefügt" mit einem "Rückgängig"-Button.

**Nachher:** POIs werden still zur Route hinzugefügt, ohne störende Meldung.

**Begründung:**
- Die Meldung war redundant - der Benutzer sieht die Änderung bereits in der UI
- Die Snackbar verdeckte teilweise andere UI-Elemente
- Schnelleres Hinzufügen mehrerer POIs ohne Unterbrechung

## Technische Details

### Geänderte Dateien

| Datei | Änderung |
|-------|----------|
| `lib/features/poi/poi_list_screen.dart` | Snackbar in `_addPOIToTrip()` entfernt |

### Code-Änderung

```dart
// VORHER - Mit Snackbar
void _addPOIToTrip(POI poi) {
  final tripNotifier = ref.read(tripStateProvider.notifier);
  tripNotifier.addStop(poi);

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('${poi.name} zur Route hinzugefügt'),
      action: SnackBarAction(
        label: 'Rückgängig',
        onPressed: () {
          tripNotifier.removeStop(poi.id);
        },
      ),
    ),
  );
}

// NACHHER - Ohne Snackbar
void _addPOIToTrip(POI poi) {
  final tripNotifier = ref.read(tripStateProvider.notifier);
  tripNotifier.addStop(poi);
}
```

---

**Vollständige Änderungen seit v1.6.3:**
- Snackbar beim POI-Hinzufügen entfernt (v1.6.4)
