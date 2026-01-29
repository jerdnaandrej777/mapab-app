# Changelog v1.6.1 - POI-Marker Direktnavigation

**Release-Datum:** 27. Januar 2026

## Neue Features

### POI-Marker öffnet direkt Details
- **Direktnavigation** - Klick auf POI-Marker öffnet sofort die Detail-Seite
- **Kein Preview-Sheet mehr** - Bottom Sheet Zwischenschritt entfernt
- **Schnellerer Workflow** - Ein Klick weniger zum POI-Detail

## Technische Details

### Geänderte Dateien

| Datei | Änderung |
|-------|----------|
| `lib/features/map/widgets/map_view.dart` | `_onPOITap()` navigiert direkt zu `/poi/{id}` |

### Code-Änderung

```dart
// VORHER: Preview Sheet anzeigen
void _onPOITap(POI poi) {
  setState(() => _selectedPOIId = poi.id);
  _showPOIPreview(poi);  // Bottom Sheet
}

// NACHHER: Direkt zur Detail-Seite
void _onPOITap(POI poi) {
  setState(() => _selectedPOIId = poi.id);
  ref.read(pOIStateNotifierProvider.notifier).selectPOI(poi);
  context.push('/poi/${poi.id}');
}
```

## Verbesserungen

- **Bessere UX** - Weniger Klicks für häufige Aktion
- **Konsistenz** - POI-Liste und Map verhalten sich gleich

## Bekannte Einschränkungen

- Preview Sheet Code bleibt im Widget (kann später entfernt werden)

---

**Vollständige Änderungen seit v1.6.0:**
- POI-Marker Direktnavigation (v1.6.1)
