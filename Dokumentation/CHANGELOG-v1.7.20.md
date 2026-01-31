# Changelog v1.7.20 - UI-Verbesserungen: Wetter-Widget & Spacing

**Release-Datum:** 2026-01-31
**Version:** 1.7.20
**Typ:** UI-Optimierung

---

## 🎨 Übersicht

UI-Verbesserungen auf dem MapScreen: Doppeltes Wetter-Widget entfernt und konsistente Abstände zwischen allen UI-Elementen.

---

## ✨ Änderungen

### UI-Optimierungen

**1. Doppeltes Wetter-Widget entfernt**
- `WeatherChip` über dem Settings-Button wurde entfernt
- Nur noch das `UnifiedWeatherWidget` im Hauptbereich bleibt bestehen
- Reduziert visuelle Redundanz und verbessert die Übersichtlichkeit

**2. Konsistente Abstände (12px) zwischen Widgets**
- Einheitliche 12px Abstände zwischen:
  - ModeToggle (Schnell/AI Trip)
  - UnifiedWeatherWidget (Wetter-Anzeige)
  - RouteAddressBar (Start/Ziel-Anzeige)
  - SearchBar (Eingabefelder)
- Verbesserte visuelle Harmonie und Balance

**3. Settings-Button vereinfacht**
- Steht jetzt alleine als Floating Action Button rechts unten
- Keine Column-Wrapper mehr nötig
- Klarere Positionierung

---

## 📁 Geänderte Dateien

### Code-Änderungen
- `lib/features/map/map_screen.dart`:
  - WeatherChip entfernt (Zeilen 368-380)
  - SizedBox(height: 12) zwischen allen Widgets hinzugefügt
  - RouteAddressBar margin entfernt (Container ohne Außenabstände)

---

## 🔍 Technische Details

### Vorher vs. Nachher

**Vorher:**
```dart
// Zwei Wetter-Widgets:
1. UnifiedWeatherWidget (oben)
2. WeatherChip (rechts unten über Settings)

// Inkonsistente Abstände:
ModeToggle → 12px → UnifiedWeatherWidget → 0px → RouteAddressBar → 0px → SearchBar
```

**Nachher:**
```dart
// Ein Wetter-Widget:
1. UnifiedWeatherWidget (oben)

// Konsistente Abstände:
ModeToggle → 12px → UnifiedWeatherWidget → 12px → RouteAddressBar → 12px → SearchBar
```

---

## 📱 User Experience

**Verbesserungen:**
- ✅ Keine doppelten Informationen mehr
- ✅ Aufgeräumteres, professionelleres Layout
- ✅ Verbesserte visuelle Hierarchie
- ✅ Konsistente Abstände = ruhigeres Design

---

## 🐛 Bugfixes

Keine Bugfixes in diesem Release.

---

## ⚙️ Build-Informationen

```bash
# Release Build
flutter build apk --release \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=... \
  --dart-define=BACKEND_URL=...

# Oder mit build_release.bat
.\build_release.bat
```

**Build-Ausgabe:** `build/app/outputs/flutter-apk/MapAB-v1.7.20.apk`

---

## 📊 Metriken

- **Code-Zeilen entfernt:** ~15 (WeatherChip Column-Wrapper)
- **Code-Zeilen hinzugefügt:** ~3 (SizedBox-Spacing)
- **UI-Komponenten reduziert:** -1 (WeatherChip)
- **Dateien geändert:** 1

---

## 🔄 Migration

Keine Migrations-Schritte erforderlich - rein visuelle Änderungen.

---

## 📝 Notizen

- Konsistentes 12px-Spacing entspricht dem Material Design Standard
- WeatherChip wurde entfernt da UnifiedWeatherWidget dieselben Informationen zeigt
- Diese Änderungen verbessern die visuelle Konsistenz ohne Funktionalität zu beeinträchtigen
