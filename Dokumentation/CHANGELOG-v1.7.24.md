# Changelog v1.7.24 - POI-Filter Chip Feedback

**Datum:** 31. Januar 2026
**Typ:** UI-Fix - Minor Update
**Plattformen:** Android, iOS, Desktop

---

## 🎨 Zusammenfassung

Fix für das visuelle Feedback der POI-Kategorie-Filter-Chips. Die Hintergrundfarbe wird jetzt zusammen mit Border und Schatten konsistent im `AnimatedContainer` gerendert statt getrennt auf `Material` und `AnimatedContainer`. Animation beschleunigt auf 100ms.

---

## ✨ Änderungen

### 1. **Filter-Chip Hintergrundfarbe in AnimatedContainer verschoben**
- **Problem:** Hintergrundfarbe wurde auf dem `Material` Widget gesetzt (sofortige Änderung), während Border im `AnimatedContainer` über 200ms animierte - inkonsistentes visuelles Ergebnis
- **Lösung:** `Material.color` auf `Colors.transparent` gesetzt, Hintergrundfarbe in die `BoxDecoration` des `AnimatedContainer` verschoben
- **Ergebnis:** Alle visuellen Änderungen (Farbe, Border, Schatten) laufen jetzt konsistent über ein Widget

### 2. **Animation beschleunigt**
- **Vorher:** 200ms Animationsdauer
- **Nachher:** 100ms - snappigeres Feedback beim Tippen

### 3. **Schatten bei ausgewähltem Chip**
- **Neu:** Ausgewählte Chips haben jetzt einen blauen Schatten (`primary.withOpacity(0.3)`, blurRadius: 4, offset: 0,2)
- **Ergebnis:** Stärkerer visueller Unterschied zwischen ausgewählt und nicht-ausgewählt

---

## 🔧 Technische Details

### Betroffene Dateien

| Datei | Änderung |
|-------|----------|
| `lib/features/poi/poi_list_screen.dart` | `_FilterChip` Widget: Background von Material in BoxDecoration, 100ms Animation, Schatten |
| `pubspec.yaml` | Version 1.7.23+123 → 1.7.24+124 |
| `QR-CODE-DOWNLOAD.html` | Links und Version auf v1.7.24 aktualisiert |
| `QR-CODE-SIMPLE.html` | Links und Version auf v1.7.24 aktualisiert |

### Code-Änderungen

**_FilterChip Widget (poi_list_screen.dart):**
```dart
// VORHER - Hintergrundfarbe auf Material (sofort), Border auf AnimatedContainer (200ms)
Material(
  color: isSelected ? colorScheme.primary : colorScheme.surfaceContainerHighest,
  borderRadius: BorderRadius.circular(20),
  child: InkWell(
    child: AnimatedContainer(
      duration: Duration(milliseconds: 200),
      decoration: BoxDecoration(
        // Kein color - Background kommt von Material
        border: Border.all(...),
      ),
    ),
  ),
)

// NACHHER - Alles konsistent im AnimatedContainer
Material(
  color: Colors.transparent,  // Nur noch InkWell-Host
  borderRadius: BorderRadius.circular(20),
  child: InkWell(
    child: AnimatedContainer(
      duration: Duration(milliseconds: 100),  // Schneller
      decoration: BoxDecoration(
        color: isSelected ? colorScheme.primary : colorScheme.surfaceContainerHighest,
        border: Border.all(...),
        boxShadow: isSelected ? [BoxShadow(
          color: colorScheme.primary.withOpacity(0.3),
          blurRadius: 4,
          offset: Offset(0, 2),
        )] : null,
      ),
    ),
  ),
)
```

---

## 🎯 Auswirkungen

### Visuelles Feedback

| Aspekt | v1.7.23 | v1.7.24 |
|--------|---------|---------|
| Hintergrund-Rendering | `Material` (sofort) | `AnimatedContainer` (konsistent) |
| Animation | 200ms | 100ms |
| Schatten | Keiner | Blauer Schatten bei Selektion |
| Konsistenz | Farbe + Border getrennt gerendert | Alles in einem Widget |

---

## 🔄 Migration

**Keine Breaking Changes** - Rein visuelle Verbesserung der Filter-Chips.

---

## 📚 Siehe auch

- [CHANGELOG-v1.7.23.md](CHANGELOG-v1.7.23.md) - POI-Kategorien-Filter (Overpass erweitert, alle Chips sichtbar)
- [CHANGELOG-v1.7.22.md](CHANGELOG-v1.7.22.md) - UI-Feinschliff

---

**Status:** ✅ Abgeschlossen
**Review:** Pending
**Deploy:** Released as v1.7.24
