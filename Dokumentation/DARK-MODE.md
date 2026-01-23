# Dark Mode Implementierung

Diese Dokumentation beschreibt die korrekte Implementierung des Dark Mode in der MapAB Flutter App.

## Inhaltsverzeichnis

1. [Theme-Provider](#theme-provider)
2. [Korrekte Widget-Implementierung](#korrekte-widget-implementierung)
3. [Verbotene Patterns](#verbotene-patterns)
4. [Farbreferenz](#farbreferenz)
5. [Checkliste](#checkliste)

---

## Theme-Provider

### Settings Provider

```dart
// lib/data/providers/settings_provider.dart
@Riverpod(keepAlive: true)
class SettingsNotifier extends _$SettingsNotifier {
  @override
  Future<AppSettings> build() async {
    return await _loadSettings();
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    final current = state.value!;
    state = AsyncValue.data(current.copyWith(themeMode: mode));
    await _saveSettings();
  }
}
```

### Theme-Modi

```dart
enum AppThemeMode {
  light,     // Immer hell
  dark,      // Immer dunkel
  oled,      // True Black für OLED
  system,    // Folgt System-Einstellung
  autoSunset // Automatisch bei Sonnenuntergang
}
```

### Effektiver Theme-Modus

```dart
// Berechnet den aktuellen Theme-Modus unter Berücksichtigung von Auto-Sunset
@riverpod
ThemeMode effectiveThemeMode(Ref ref) {
  final settings = ref.watch(settingsNotifierProvider);
  return settings.when(
    data: (s) {
      switch (s.themeMode) {
        case AppThemeMode.light:
          return ThemeMode.light;
        case AppThemeMode.dark:
        case AppThemeMode.oled:
          return ThemeMode.dark;
        case AppThemeMode.system:
          return ThemeMode.system;
        case AppThemeMode.autoSunset:
          return _isNightTime() ? ThemeMode.dark : ThemeMode.light;
      }
    },
    loading: () => ThemeMode.system,
    error: (_, __) => ThemeMode.system,
  );
}
```

---

## Korrekte Widget-Implementierung

### Standard-Pattern

**MUSS in allen Widgets mit Hintergrund/Text verwendet werden:**

```dart
@override
Widget build(BuildContext context) {
  // Theme-Variablen IMMER am Anfang extrahieren
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final isDark = theme.brightness == Brightness.dark;

  return Container(
    decoration: BoxDecoration(
      // Theme-Farbe verwenden
      color: colorScheme.surface,
      boxShadow: [
        BoxShadow(
          // Stärkere Schatten im Dark Mode
          color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
          blurRadius: 10,
        ),
      ],
    ),
    child: Text(
      'Text',
      style: TextStyle(
        // Theme-Textfarbe verwenden
        color: colorScheme.onSurface,
      ),
    ),
  );
}
```

### Card-Widgets

```dart
Widget build(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return Card(
    color: colorScheme.surface,
    elevation: isDark ? 0 : 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: isDark
          ? BorderSide(color: colorScheme.outline.withOpacity(0.2))
          : BorderSide.none,
    ),
    child: ...
  );
}
```

### Icon-Buttons

```dart
IconButton(
  icon: Icon(
    Icons.favorite,
    color: colorScheme.primary,
  ),
  onPressed: () {},
)
```

### Text-Stile

```dart
Text(
  'Titel',
  style: TextStyle(
    color: colorScheme.onSurface,
    fontWeight: FontWeight.bold,
  ),
)

Text(
  'Untertitel',
  style: TextStyle(
    color: colorScheme.onSurface.withOpacity(0.7),
  ),
)
```

---

## Verbotene Patterns

### NIEMALS hart-codierte Farben

```dart
// VERBOTEN - Funktioniert nicht im Dark Mode
color: Colors.white,
color: Colors.black,
color: Colors.grey[200],
color: Color(0xFFFFFFFF),
```

### NIEMALS statische AppTheme-Farben

```dart
// VERBOTEN - Reagiert nicht auf Theme-Wechsel
color: AppTheme.textPrimary,
color: AppTheme.textSecondary,
color: AppTheme.backgroundColor,
color: AppTheme.surfaceColor,
```

### NIEMALS statische Schatten

```dart
// VERBOTEN
boxShadow: AppTheme.cardShadow,

// RICHTIG
boxShadow: [
  BoxShadow(
    color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
    blurRadius: 10,
  ),
],
```

### NIEMALS Container ohne Theme-Farbe

```dart
// VERBOTEN
Container(
  color: Colors.white,
  child: ...
)

// RICHTIG
Container(
  color: colorScheme.surface,
  child: ...
)
```

---

## Farbreferenz

### ColorScheme Mapping

| Verwendung | Light Mode | Dark Mode | OLED Mode |
|------------|------------|-----------|-----------|
| `surface` | `#FFFFFF` | `#1E293B` | `#000000` |
| `onSurface` | `#1E293B` | `#F1F5F9` | `#F1F5F9` |
| `surfaceContainerHighest` | `#F1F5F9` | `#334155` | `#1A1A1A` |
| `primary` | `#3B82F6` | `#60A5FA` | `#60A5FA` |
| `onPrimary` | `#FFFFFF` | `#1E293B` | `#000000` |
| `secondary` | `#06B6D4` | `#22D3EE` | `#22D3EE` |
| `error` | `#EF4444` | `#F87171` | `#F87171` |
| `outline` | `#E2E8F0` | `#475569` | `#333333` |

### Kontext-abhängige Farben

```dart
// Hintergrund
colorScheme.surface         // Haupthintergrund
colorScheme.surfaceContainerHighest  // Karten, erhöhte Elemente

// Text
colorScheme.onSurface       // Primärer Text
colorScheme.onSurface.withOpacity(0.7)  // Sekundärer Text
colorScheme.onSurface.withOpacity(0.5)  // Hint-Text

// Interaktive Elemente
colorScheme.primary         // Buttons, Links, Akzente
colorScheme.onPrimary       // Text auf Primary
colorScheme.secondary       // Sekundäre Akzente

// Rahmen & Trennlinien
colorScheme.outline         // Rahmen
colorScheme.outlineVariant  // Subtile Trennlinien
```

---

## Checkliste

### Vor dem Commit prüfen

- [ ] Keine `Colors.white` oder `Colors.black` verwendet
- [ ] Keine `AppTheme.xyz` statischen Farben verwendet
- [ ] `Theme.of(context)` am Widget-Anfang extrahiert
- [ ] Alle Texte verwenden `colorScheme.onSurface`
- [ ] Alle Hintergründe verwenden `colorScheme.surface`
- [ ] Schatten haben dynamische Opacity (`isDark ? 0.3 : 0.08`)
- [ ] Cards haben im Dark Mode `elevation: 0` oder Border

### Test-Schritte

1. App im Light Mode starten
2. Zu Settings navigieren
3. Dark Mode aktivieren
4. Alle Screens durchgehen:
   - MapScreen
   - POI-Liste
   - POI-Detail
   - Trip-Screen
   - AI-Chat
   - Profil
   - Favoriten
   - Settings

### Bekannte Probleme

| Screen | Problem | Lösung |
|--------|---------|--------|
| Bottom Navigation | Weißer Hintergrund | `colorScheme.surface` |
| Search Bar | Harter Schatten | `isDark ? 0.3 : 0.05` |
| POI Card Badge | Falscher Textkontrast | `colorScheme.onPrimaryContainer` |
