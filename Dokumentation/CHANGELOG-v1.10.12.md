# Changelog v1.10.12 - Navigation UI-Redesign

**Build:** 193
**Datum:** 6. Februar 2026

## Übersicht

Optimierung des Navigation-Screen Button-Layouts für bessere Übersichtlichkeit und konsistentes Design.

---

## Änderungen

### 1. Speichern-Button ins Banner verschoben

Der "Route speichern" Button wurde von der unteren Button-Leiste in das blaue ManeuverBanner (oben) verschoben:

| Vorher | Nachher |
|--------|---------|
| Unten in der Button-Zeile | Oben rechts im blauen Banner |
| Zwischen Mikrofon und Karte | Neben der Instruktion |

**Vorteile:**
- Bessere Sichtbarkeit während der Navigation
- Konsistentes Design mit dem Manöver-Icon (beide 48x48px)
- Mehr Platz in der unteren Button-Leiste

### 2. Beenden-Button quadratisch

Der "Beenden"-Button wurde von einem rechteckigen Button mit Text zu einem quadratischen Icon-Button geändert:

| Vorher | Nachher |
|--------|---------|
| `FilledButton.icon` mit "Beenden" Text | `_IconActionButton` mit X-Icon |
| Variable Breite (Expanded) | 48x48px quadratisch |
| Rot mit weißem Text | Rot mit weißem Icon |

### 3. Button-Zeile gleichmäßig verteilt

Die untere Button-Zeile nutzt jetzt `MainAxisAlignment.spaceEvenly` für gleichmäßige Verteilung:

| Button | Icon | Farbe |
|--------|------|-------|
| Stumm/Ton | 🔊 / 🔇 | Grau |
| Sprachbefehl | 🎤 | Grau (Blau wenn aktiv) |
| Übersicht | 🗺️ | Grau |
| Beenden | ✕ | Rot |

### 4. Sprechblase nach oben verschoben

Das Voice-Feedback (partielle Spracherkennung) erscheint jetzt oben unter dem Banner statt unten:

| Vorher | Nachher |
|--------|---------|
| `bottom: 180` | `top: 140` |
| Wurde von Bottom Bar verdeckt | Unter dem blauen Banner sichtbar |

---

## Technische Änderungen

### maneuver_banner.dart

```dart
// Neuer Parameter
final VoidCallback? onSave;

// Neues Widget im Banner (rechts)
if (onSave != null) ...[
  const SizedBox(width: 12),
  _SaveButton(onTap: onSave!, color: colorScheme.onPrimary),
]

// Neues Widget
class _SaveButton extends StatelessWidget { ... }
```

### navigation_bottom_bar.dart

```dart
// Entfernt: onSave Parameter

// Button-Zeile geändert
Row(
  mainAxisAlignment: MainAxisAlignment.spaceEvenly,  // Vorher: children mit Expanded
  children: [
    _IconActionButton(...),  // Mute
    _IconActionButton(...),  // Voice
    _IconActionButton(...),  // Overview
    _IconActionButton(isError: true, ...),  // Stop - NEU: quadratisch
  ],
)

// _IconActionButton erweitert
final bool isError;  // NEU: für roten Beenden-Button
```

### navigation_screen.dart

```dart
// ManeuverBanner erhält onSave
ManeuverBanner(
  onSave: _saveRoute,  // NEU
  ...
)

// NavigationBottomBar ohne onSave
NavigationBottomBar(
  // onSave entfernt
  ...
)

// Sprechblase Position
Positioned(
  top: 140,  // Vorher: bottom: 180
  ...
)
```

---

## Dateien geändert

| Datei | Änderungen |
|-------|------------|
| `lib/features/navigation/widgets/maneuver_banner.dart` | +onSave Parameter, +_SaveButton Widget |
| `lib/features/navigation/widgets/navigation_bottom_bar.dart` | -onSave, Beenden quadratisch, spaceEvenly Layout, +isError Parameter |
| `lib/features/navigation/navigation_screen.dart` | onSave ans Banner, Sprechblase top:140 |

---

## Visueller Vergleich

### Vorher
```
┌─────────────────────────────────────┐
│ [→]  1000 m                         │  <- Banner
│      Rechts abbiegen auf...         │
└─────────────────────────────────────┘

         ... Karte ...

┌─────────────────────────────────────┐
│  415 km  |  ~13:51  |  0 km/h      │
│ [🔊][🎤][📑][🗺️]  [ Beenden  ]    │  <- Button-Leiste
└─────────────────────────────────────┘
```

### Nachher
```
┌─────────────────────────────────────┐
│ [→]  1000 m              [📑]      │  <- Banner + Speichern
│      Rechts abbiegen auf...         │
└─────────────────────────────────────┘

┌─ Sprechblase ───────────────────────┐
│ 🎤 "Wie lange noch?"                │
└─────────────────────────────────────┘

         ... Karte ...

┌─────────────────────────────────────┐
│  415 km  |  ~13:51  |  0 km/h      │
│   [🔊]    [🎤]    [🗺️]    [✕]     │  <- 4 gleiche Buttons
└─────────────────────────────────────┘
```

---

## Testen

1. **Navigation starten** mit einer Route
2. **Speichern-Button** oben rechts im blauen Banner prüfen
3. **Beenden-Button** unten rechts - quadratisch und rot
4. **Sprachbefehl** aktivieren → Sprechblase erscheint oben unter dem Banner
5. **Button-Abstände** prüfen - alle 4 Buttons gleichmäßig verteilt
