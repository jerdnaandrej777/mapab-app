# Changelog v1.7.26 - Kategorie-Chips Konsistenz & Route-Löschen-Button Fix

**Datum:** 31. Januar 2026
**Typ:** UI-Fix - Minor Update
**Plattformen:** Android, iOS, Desktop
**APK-Größe:** 63.4 MB

---

## 🎨 Zusammenfassung

Konsistentes visuelles Feedback für alle Kategorie-Auswahl-Chips in der App. Die Modal-Kategorie-Buttons und der AI Trip CategorySelector verhalten sich jetzt identisch zu den POI-Quick-Filter-Chips: Material + InkWell für Ripple-Effekt, 100ms Animation, Schatten bei Auswahl, Dark-Mode-konforme Farben.

Zusätzlich: Der "Route löschen" Button im AI Trip Modus wurde von der externen Column in das scrollbare Panel verschoben, damit er nicht mehr von der Bottom Navigation abgeschnitten wird.

---

## ✨ Änderungen

### 1. **Modal-Kategorien an Quick-Filter-Chip-Pattern angepasst**
- **Problem:** Modal-Kategorie-Buttons nutzten `GestureDetector` (kein Ripple), 150ms Animation, dezente Kategoriefarben ohne Schatten - fühlte sich "verzögert" an
- **Lösung:** `Material(transparent)` + `InkWell` Wrapper, 100ms Animation, `colorScheme.primary` Hintergrund bei Auswahl, blauer Schatten
- **Ergebnis:** Sofortiger Ripple-Effekt beim Tippen, prominentes visuelles Feedback, konsistent mit POI-Quick-Filter

### 2. **AI Trip CategorySelector an Quick-Filter-Chip-Pattern angepasst**
- **Problem:** `_CategoryChip` nutzte statischen `Container` ohne Animation, hardcodierte Farben (`Colors.grey`, `AppTheme.textPrimary`), keinen Schatten
- **Lösung:** `AnimatedContainer` mit 100ms, `colorScheme.primary` + `onPrimary`, Schatten bei Auswahl
- **Ergebnis:** Dark-Mode-konform, konsistentes Verhalten in der gesamten App

### 3. **Check-Icon Position vereinheitlicht**
- **Vorher:** Modal: `Icons.check_circle` nach dem Label, CategorySelector: `Icons.check` nach dem Label
- **Nachher:** Beide: `Icons.check` VOR dem Label (wie bei POI-Quick-Filter-Chips)

### 4. **Route-Löschen-Button im AI Trip Panel nicht mehr abgeschnitten**
- **Problem:** Der "Route löschen" Button im AI Trip Modus war **außerhalb** des scrollbaren Panels in der äußeren Column positioniert. Bei vollem Panel (Wetter + Tagestrip/Euro Trip + Start + Radius + Kategorien + Generate-Button) wurde der Button von der Bottom Navigation abgeschnitten und war nicht klickbar.
- **Ursache:** Button wurde als separates Element nach `_AITripPanel()` in der Column platziert (seit v1.6.8), statt innerhalb des scrollbaren Bereichs
- **Lösung:** Button in die `_AITripPanel` `SingleChildScrollView` > `Column` verschoben, nach dem "Überrasch mich!" Button. Wird mit Divider visuell getrennt und nur angezeigt wenn eine Route existiert (Preview/Confirmed/Trip-Route)
- **Ergebnis:** Button ist immer durch Scrollen erreichbar, konsistent mit dem Schnell-Modus (wo der Button bereits im Panel integriert war)

---

## 🔧 Technische Details

### Betroffene Dateien

| Datei | Änderung |
|-------|----------|
| `lib/features/map/map_screen.dart` | Modal-Kategorien: GestureDetector → Material+InkWell, 150ms → 100ms, Schatten, colorScheme + Route-Löschen-Button von externer Column ins scrollbare AI Trip Panel verschoben |
| `lib/features/random_trip/widgets/category_selector.dart` | _CategoryChip: Container → AnimatedContainer, hardcodierte Farben → colorScheme, Schatten |
| `pubspec.yaml` | Version 1.7.25+125 → 1.7.26+126 |
| `QR-CODE-DOWNLOAD.html` | Links und Version auf v1.7.26 aktualisiert |
| `QR-CODE-SIMPLE.html` | Links und Version auf v1.7.26 aktualisiert |
| `qr-generator.html` | Links und Version auf v1.7.26 aktualisiert |

### Code-Änderungen

**Modal-Kategorien (map_screen.dart):**
```dart
// VORHER - GestureDetector ohne Ripple, 150ms, Kategoriefarben
GestureDetector(
  onTap: () => notifier.toggleCategory(category),
  child: AnimatedContainer(
    duration: Duration(milliseconds: 150),
    decoration: BoxDecoration(
      color: isSelected
          ? categoryColor.withOpacity(0.2)
          : colorScheme.surfaceContainerHighest,
      border: Border.all(
        color: isSelected ? categoryColor : ...,
        width: isSelected ? 2 : 1,
      ),
    ),
  ),
)

// NACHHER - Material+InkWell mit Ripple, 100ms, colorScheme.primary + Schatten
Material(
  color: Colors.transparent,
  borderRadius: BorderRadius.circular(20),
  child: InkWell(
    onTap: () => notifier.toggleCategory(category),
    borderRadius: BorderRadius.circular(20),
    child: AnimatedContainer(
      duration: Duration(milliseconds: 100),
      decoration: BoxDecoration(
        color: isSelected
            ? colorScheme.primary
            : colorScheme.surfaceContainerHighest,
        border: Border.all(
          color: isSelected ? colorScheme.primary : ...,
          width: isSelected ? 1.5 : 1,
        ),
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

**AI Trip CategorySelector (category_selector.dart):**
```dart
// VORHER - Container ohne Animation, hardcodierte Farben
Material(
  color: isSelected
      ? Color(category.colorValue).withOpacity(0.15)
      : Colors.grey.withOpacity(0.08),
  child: InkWell(
    child: Container(  // Keine Animation!
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? Color(category.colorValue) : Colors.grey...,
        ),
      ),
      child: Text(style: TextStyle(color: AppTheme.textPrimary)),  // Hardcoded!
    ),
  ),
)

// NACHHER - AnimatedContainer mit colorScheme + Schatten
Material(
  color: Colors.transparent,
  child: InkWell(
    child: AnimatedContainer(
      duration: Duration(milliseconds: 100),
      decoration: BoxDecoration(
        color: isSelected ? colorScheme.primary : colorScheme.surfaceContainerHighest,
        boxShadow: isSelected ? [BoxShadow(...)] : null,
      ),
      child: Text(style: TextStyle(color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface)),
    ),
  ),
)
```

---

## 🎯 Auswirkungen

### Konsistenz-Vergleich

| Eigenschaft | v1.7.25 Modal | v1.7.25 CategorySelector | v1.7.26 (beide) | POI Quick-Filter |
|---|---|---|---|---|
| Tap-Wrapper | GestureDetector | Material+InkWell | Material+InkWell | Material+InkWell |
| Animation | 150ms | Keine | 100ms | 100ms |
| Hintergrund (selected) | categoryColor 20% | categoryColor 15% | colorScheme.primary | colorScheme.primary |
| Text (selected) | categoryColor | categoryColor | colorScheme.onPrimary | colorScheme.onPrimary |
| Schatten | Nein | Nein | Ja | Ja |
| Dark-Mode | OK | Hardcoded | OK | OK |

---

## 🔄 Migration

**Keine Breaking Changes** - Rein visuelle Verbesserung der Kategorie-Chips. Funktionalität bleibt identisch.

---

## 📚 Siehe auch

- [CHANGELOG-v1.7.24.md](CHANGELOG-v1.7.24.md) - POI-Filter Chip Feedback (das Referenz-Pattern)
- [CHANGELOG-v1.7.23.md](CHANGELOG-v1.7.23.md) - POI-Kategorien-Filter (Overpass erweitert, alle Chips sichtbar)
- [CHANGELOG-v1.7.25.md](CHANGELOG-v1.7.25.md) - POI & Wetter Optimierungen

---

**Status:** ✅ Abgeschlossen
**Review:** Pending
**Deploy:** Released as v1.7.26
