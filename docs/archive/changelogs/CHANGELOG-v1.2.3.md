# CHANGELOG v1.2.3 - Dark Mode Fix

**Release-Datum:** 21. Januar 2026

## Haupt-Fix: Dark Mode Support

**Problem:** Bei aktivem Dark Mode wurde nur der Text weiß, alle Hintergrund-Flächen blieben weiß - Text war dadurch nicht mehr lesbar.

**Ursache:** Hart-codierte `Colors.white` und `AppTheme.textPrimary/textSecondary` Farben in mehreren Komponenten.

**Lösung:** Alle betroffenen Komponenten nutzen jetzt dynamisch `Theme.of(context)` und `colorScheme` für Farben.

---

## Geänderte Dateien

### 1. `lib/app.dart` - MainBottomNavigation & Navigation Items

**Problem:** Bottom Navigation Bar war immer weiß.

**Fix:**
```dart
// VORHER
Container(
  decoration: BoxDecoration(
    color: Colors.white,
    boxShadow: [...],
  ),
)

// NACHHER
final theme = Theme.of(context);
final isDark = theme.brightness == Brightness.dark;

Container(
  decoration: BoxDecoration(
    color: theme.colorScheme.surface,
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
        ...
      ),
    ],
  ),
)
```

**_NavItem Widget:**
```dart
// VORHER
final color = isSelected
    ? AppTheme.primaryColor
    : AppTheme.textSecondary;

// NACHHER
final color = isSelected
    ? colorScheme.primary
    : theme.textTheme.bodyMedium?.color ?? colorScheme.onSurface.withOpacity(0.6);
```

**Zusätzlich:** System UI Overlay Style dynamisch anpassen
```dart
// Dynamische Status-/Navigationsbar-Farben
SystemChrome.setSystemUIOverlayStyle(
  SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    systemNavigationBarColor: isDark ? AppTheme.darkSurfaceColor : Colors.white,
    systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
  ),
);
```

---

### 2. `lib/main.dart` - System UI Einstellung entfernt

**Problem:** Statische weiße System-Navigation-Bar.

**Fix:** Statische Einstellung entfernt, wird jetzt dynamisch in `app.dart` gesetzt.

```dart
// VORHER
SystemChrome.setSystemUIOverlayStyle(
  const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ),
);

// NACHHER
// Dynamisch in TravelPlannerApp angepasst basierend auf Theme
```

---

### 3. `lib/features/map/map_screen.dart` - Hauptbildschirm

**Betroffene Komponenten:**
- AppBar Background
- FloatingActionButtons (Settings, GPS, Zoom +/-)
- `_SearchBar` Container
- `_SearchField` Textfarben
- `_RouteToggle` Container
- `_ToggleButton` Farben

**AppBar Fix:**
```dart
// VORHER
backgroundColor: Colors.white.withOpacity(0.9),

// NACHHER
backgroundColor: colorScheme.surface.withOpacity(0.9),
```

**FloatingActionButtons Fix:**
```dart
// VORHER
FloatingActionButton.small(
  backgroundColor: Colors.white,
  foregroundColor: AppTheme.textPrimary,
  ...
)

// NACHHER
FloatingActionButton.small(
  backgroundColor: colorScheme.surface,
  foregroundColor: colorScheme.onSurface,
  ...
)
```

**SearchBar Container:**
```dart
// VORHER
Container(
  decoration: BoxDecoration(
    color: Colors.white,
    boxShadow: AppTheme.cardShadow,
  ),
)

// NACHHER
Container(
  decoration: BoxDecoration(
    color: colorScheme.surface,
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
        ...
      ),
    ],
  ),
)
```

**SearchField Textfarben:**
```dart
// VORHER
color: value != null ? AppTheme.textPrimary : AppTheme.textHint,

// NACHHER
color: value != null ? colorScheme.onSurface : theme.hintColor,
```

**ToggleButton:**
```dart
// VORHER
color: isSelected ? AppTheme.primaryColor : Colors.transparent,
Icon(color: isSelected ? Colors.white : AppTheme.textSecondary)

// NACHHER
color: isSelected ? colorScheme.primary : Colors.transparent,
Icon(color: isSelected ? colorScheme.onPrimary : theme.textTheme.bodySmall?.color)
```

---

### 4. `lib/features/poi/widgets/poi_card.dart` - POI-Karten

**Card Container:**
```dart
// VORHER
Container(
  decoration: BoxDecoration(
    color: Colors.white,
    boxShadow: AppTheme.cardShadow,
  ),
)

// NACHHER
Container(
  decoration: BoxDecoration(
    color: colorScheme.surface,
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
        ...
      ),
    ],
  ),
)
```

**Kategorie Badge:**
```dart
// VORHER
color: Colors.white,

// NACHHER
color: colorScheme.surface,
```

**Text- und Icon-Farben:**
```dart
// VORHER
color: AppTheme.textPrimary,
color: AppTheme.textSecondary,

// NACHHER
color: colorScheme.onSurface,
color: theme.textTheme.bodySmall?.color,
```

**Leere Stern-Bewertungen:**
```dart
// VORHER
color: Colors.grey.shade300

// NACHHER
color: isDark ? Colors.grey.shade600 : Colors.grey.shade300
```

---

### 5. `lib/features/trip/widgets/trip_stop_tile.dart` - Trip-Stops

**Tile Container:**
```dart
// VORHER
Container(
  decoration: BoxDecoration(
    color: Colors.white,
    boxShadow: AppTheme.cardShadow,
  ),
)

// NACHHER
Container(
  decoration: BoxDecoration(
    color: colorScheme.surface,
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
        ...
      ),
    ],
  ),
)
```

**Icon Background:**
```dart
// VORHER
color: AppTheme.backgroundColor,

// NACHHER
color: isDark ? colorScheme.surfaceContainerHighest : AppTheme.backgroundColor,
```

**Alle Farben:**
```dart
// VORHER
color: AppTheme.textHint,
color: AppTheme.textSecondary,

// NACHHER
color: theme.hintColor,
color: theme.textTheme.bodySmall?.color,
```

---

## Theme-Architektur (Referenz)

Das Dark Theme ist bereits korrekt in `lib/core/theme/app_theme.dart` definiert:

```dart
// Dark Mode Farben
static const Color darkBackgroundColor = Color(0xFF0F172A);
static const Color darkSurfaceColor = Color(0xFF1E293B);
static const Color darkCardColor = Color(0xFF334155);
static const Color darkTextPrimary = Color(0xFFF1F5F9);
static const Color darkTextSecondary = Color(0xFF94A3B8);

// Diese werden automatisch verwendet wenn brightness == Brightness.dark
```

---

## Ergebnis

| Komponente | Vorher (Dark Mode) | Nachher (Dark Mode) |
|------------|-------------------|---------------------|
| Bottom Navigation | Weiß | Dunkelgrau (#1E293B) |
| AppBar | Weiß | Dunkelgrau |
| Search Bar | Weiß | Dunkelgrau |
| POI Cards | Weiß | Dunkelgrau |
| Trip Tiles | Weiß | Dunkelgrau |
| FABs | Weiß | Dunkelgrau |
| Text | Weiß (unsichtbar!) | Hell (#F1F5F9) |
| System Navigation | Weiß | Dunkelgrau |

---

## Test-Anleitung

1. **App starten**
2. **Settings öffnen** (Zahnrad-Button auf MapScreen)
3. **Theme ändern:**
   - System → Automatisch nach System-Einstellung
   - Dunkel → Force Dark Mode
   - OLED Schwarz → True Black (#000000)
4. **Prüfen:**
   - Bottom Navigation: Dunkler Hintergrund mit hellen Icons ✅
   - Search Bar: Dunkler Hintergrund mit hellem Text ✅
   - FABs: Dunkle Buttons mit hellen Icons ✅
   - POI Cards: Dunkle Cards mit hellem Text ✅
   - Trip Screen: Dunkle Tiles mit hellem Text ✅

---

## Betroffene Dateien (Zusammenfassung)

| Datei | Zeilen geändert |
|-------|-----------------|
| `lib/app.dart` | ~50 |
| `lib/main.dart` | ~10 |
| `lib/features/map/map_screen.dart` | ~80 |
| `lib/features/poi/widgets/poi_card.dart` | ~40 |
| `lib/features/trip/widgets/trip_stop_tile.dart` | ~40 |
| **Gesamt** | **~220** |

---

## Weitere Hinweise

### Noch nicht angepasste Screens

Die folgenden Screens haben ebenfalls `Colors.white` Verwendungen, wurden aber nicht im Rahmen dieses Fixes geändert, da sie:
- Bereits funktional korrekt im Dark Mode sind (Kontrast auf farbigen Buttons)
- Weniger kritisch für die Lesbarkeit sind

**Optional für zukünftige Updates:**
- `chat_screen.dart` - Chat-Bubbles
- `poi_detail_screen.dart` - Detail-Header
- `random_trip_screen.dart` - Preview Cards
- `favorites_screen.dart` - Favoriten-Cards

### Pattern für zukünftige Entwicklung

**Immer verwenden:**
```dart
final theme = Theme.of(context);
final colorScheme = theme.colorScheme;
final isDark = theme.brightness == Brightness.dark;

// Hintergrund
color: colorScheme.surface,

// Text (primär)
color: colorScheme.onSurface,

// Text (sekundär)
color: theme.textTheme.bodySmall?.color,

// Hints
color: theme.hintColor,

// Dynamische Schatten
BoxShadow(
  color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
  ...
)
```

**Niemals verwenden:**
```dart
color: Colors.white,           // Hart-codiert!
color: AppTheme.textPrimary,   // Statisch!
boxShadow: AppTheme.cardShadow, // Keine Dark-Anpassung!
```
