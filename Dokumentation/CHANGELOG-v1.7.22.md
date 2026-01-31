# Changelog v1.7.22 - UI-Feinschliff

**Datum:** 31. Januar 2026
**Typ:** UI/UX Verbesserung - Minor Update
**Plattformen:** Android, iOS, Desktop
**APK-Größe:** 57.6 MB

---

## 🎨 Zusammenfassung

Kleine UI-Verfeinerungen für konsistente Abstände im MapScreen und verbessertes Wetter-Widget-Verhalten. Mode-Toggle und Panel haben jetzt in beiden Modi einheitlichen 12px Abstand. Das Wetter-Widget startet zugeklappt für mehr Kartenplatz.

---

## ✨ Änderungen

### 1. **12px Abstand zwischen Mode-Toggle und Schnell-Modus Panel**
- **Problem:** Im Schnell-Modus fehlte der Abstand zwischen Toggle und Panel (0px), während AI Trip bereits 12px hatte
- **Lösung:** `SizedBox(height: 12)` vor `_SchnellModePanel` eingefügt
- **Vorteil:** Konsistente Abstände in beiden Modi

### 2. **Wetter-Widget standardmäßig zugeklappt**
- **Problem:** Wetter-Widget startete aufgeklappt und verbrauchte Platz auf der Karte
- **Lösung:** `weatherWidgetCollapsedProvider` Default von `false` auf `true` geändert
- **Vorteil:** Mehr Kartenplatz beim Start, Widget lässt sich bei Bedarf aufklappen
- **Session-persistent:** Zustand bleibt über die gesamte App-Session erhalten

### 3. **12px Abstand zwischen Mode-Toggle und Generating-Indicator**
- **Problem:** "Trip wird generiert" Indicator klebte direkt am Mode-Toggle
- **Lösung:** `SizedBox(height: 12)` vor `_GeneratingIndicator` eingefügt
- **Vorteil:** Konsistenter Abstand auch während der Trip-Generierung

---

## 🔧 Technische Details

### Betroffene Dateien

| Datei | Änderung |
|-------|----------|
| `lib/features/map/map_screen.dart` | SizedBox(height: 12) vor Schnell-Panel und Generating-Indicator |
| `lib/features/map/widgets/unified_weather_widget.dart` | weatherWidgetCollapsedProvider Default: true |

### Code-Änderungen

**Schnell-Modus Panel (map_screen.dart):**
```dart
// VORHER
if (_planMode == MapPlanMode.schnell && !isGenerating)
  _SchnellModePanel(...)

// NACHHER
if (_planMode == MapPlanMode.schnell && !isGenerating) ...[
  const SizedBox(height: 12),
  _SchnellModePanel(...),
],
```

**Generating-Indicator (map_screen.dart):**
```dart
// VORHER
if (isGenerating)
  _GeneratingIndicator(),

// NACHHER
if (isGenerating) ...[
  const SizedBox(height: 12),
  _GeneratingIndicator(),
],
```

**Wetter-Widget Default (unified_weather_widget.dart):**
```dart
// VORHER
final weatherWidgetCollapsedProvider = StateProvider<bool>((ref) => false);

// NACHHER
final weatherWidgetCollapsedProvider = StateProvider<bool>((ref) => true);
```

---

## 🎯 Auswirkungen

### Benutzerfreundlichkeit
- **Konsistente Abstände:** Toggle-zu-Panel Abstand ist in allen Modi identisch (12px)
- **Mehr Kartenplatz:** Wetter-Widget startet zugeklappt
- **Aufgeräumte UI:** Generating-Indicator hat angemessenen Abstand

### Performance
- **Keine Änderung:** Rein visuelle Anpassungen

---

## 📊 Vorher/Nachher Vergleich

### Abstände

| Element | Vorher | Nachher |
|---------|--------|---------|
| Toggle → Schnell-Panel | 0px | 12px |
| Toggle → AI Trip Panel | 12px | 12px (unverändert) |
| Toggle → Generating-Indicator | 0px | 12px |
| Wetter-Widget Start-Zustand | Aufgeklappt | Zugeklappt |

---

## 🔄 Migration

**Keine Breaking Changes** - Rein UI-bezogene Optimierungen.

---

## 📚 Siehe auch

- [CHANGELOG-v1.7.21.md](CHANGELOG-v1.7.21.md) - Unified Panel Design
- [CHANGELOG-v1.7.20.md](CHANGELOG-v1.7.20.md) - Wetter-Widget im AI Trip
- [CHANGELOG-v1.7.19.md](CHANGELOG-v1.7.19.md) - Unified Weather Widget

---

**Status:** ✅ Abgeschlossen
**Review:** Pending
**Deploy:** Released as v1.7.22
