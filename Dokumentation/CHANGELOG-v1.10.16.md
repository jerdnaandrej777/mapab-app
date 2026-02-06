# Changelog v1.10.16 (Build 197-200)

## Trip Veröffentlichen Button & UI-Fixes

Dieses Release fügt die "Trip veröffentlichen"-Funktion zum DayEditorOverlay hinzu und behebt UI-Probleme im PublishTripSheet.

### Neue Features

#### Trip veröffentlichen im DayEditorOverlay (Build 199-200)
- **Feature:** Direkter "Veröffentlichen"-Button in der AppBar des Trip-Editors
- **Vorher:** Funktion war nur im TripScreen verfügbar, nicht im "Trip bearbeiten"-Screen
- **Nachher:** Prominenter TextButton.icon mit Weltkugel-Icon und "Veröffentlichen"-Label
- **Vorteil:** Benutzer können Trips direkt während der Bearbeitung veröffentlichen

### Bugfixes

#### FilterChip-Textfarben im PublishTripSheet (Build 200)
- **Problem:** Tag-Buttons (#roadtrip, #natur, etc.) zeigten keinen sichtbaren Text
- **Ursache:** FilterChip ohne explizite Textfarben bei bestimmten Theme-Konfigurationen
- **Lösung:** Explizite Farbdefinitionen für alle Zustände:
  - `selectedColor`: primary (blau wenn ausgewählt)
  - `backgroundColor`: surfaceContainerHighest (grauer Hintergrund)
  - `labelStyle.color`: onPrimary (weiß) wenn ausgewählt, onSurface (schwarz) wenn nicht
  - `checkmarkColor`: onPrimary (weißes Häkchen)
  - `side`: Border mit primary oder outline

### Geänderte Dateien

| Datei | Änderung |
|-------|----------|
| `lib/features/trip/widgets/day_editor_overlay.dart` | TextButton.icon "Veröffentlichen" in AppBar hinzugefügt (ersetzt PopupMenuButton) |
| `lib/features/social/widgets/publish_trip_sheet.dart` | FilterChip mit expliziten Farben für Label, Hintergrund, Checkmark und Border |

### Code-Änderungen

#### DayEditorOverlay - Veröffentlichen-Button

```dart
// VORHER - Verstecktes 3-Punkte-Menü (Build 199)
PopupMenuButton<String>(
  icon: const Icon(Icons.more_vert),
  itemBuilder: (context) => [
    PopupMenuItem<String>(
      value: 'publish',
      child: ListTile(
        leading: const Icon(Icons.public),
        title: Text(context.l10n.tripPublish),
        // ...
      ),
    ),
  ],
),

// NACHHER - Direkter Button (Build 200)
TextButton.icon(
  onPressed: () async {
    final published = await PublishTripSheet.show(context, trip);
    // ...
  },
  icon: const Icon(Icons.public, size: 20),
  label: Text(context.l10n.publishButton),
  style: TextButton.styleFrom(
    foregroundColor: Theme.of(context).colorScheme.primary,
  ),
),
```

#### PublishTripSheet - FilterChip-Farben

```dart
// VORHER - Unsichtbarer Text
FilterChip(
  label: Text('#$tag'),
  selected: isSelected,
  onSelected: (selected) { /* ... */ },
);

// NACHHER - Explizite Farben
FilterChip(
  label: Text(
    '#$tag',
    style: TextStyle(
      color: isSelected
          ? colorScheme.onPrimary
          : colorScheme.onSurface,
    ),
  ),
  selected: isSelected,
  selectedColor: colorScheme.primary,
  backgroundColor: colorScheme.surfaceContainerHighest,
  checkmarkColor: colorScheme.onPrimary,
  side: BorderSide(
    color: isSelected
        ? colorScheme.primary
        : colorScheme.outline.withValues(alpha: 0.5),
  ),
  onSelected: (selected) { /* ... */ },
);
```

### AppBar-Struktur im DayEditorOverlay

```
[X] Trip bearbeiten [📑 Speichern] [🔄 Neu] [🌐 Veröffentlichen]
```

### Build-Historie

| Build | Änderung |
|-------|----------|
| 197 | Initial: TripScreen 3-Punkte-Menü mit "Trip veröffentlichen" |
| 198 | Version-Fix in Settings |
| 199 | DayEditorOverlay: PopupMenuButton mit "Trip veröffentlichen" hinzugefügt |
| 200 | DayEditorOverlay: TextButton.icon statt PopupMenu + FilterChip-Farben-Fix |

---

**Build:** 200
**Version:** 1.10.16
**Datum:** 2026-02-06
