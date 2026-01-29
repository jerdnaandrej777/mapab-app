# Changelog v1.5.5

**Release-Datum:** 26. Januar 2026

## Bugfixes

### POI-Liste zeigt jetzt alle POIs korrekt an

**Problem:** Die POI-Liste zeigte "15 von 22 POIs" an, aber nur 1 POI wurde tatsächlich in der Liste angezeigt.

**Ursache:** In der `POICard` wurde `IntrinsicHeight` zusammen mit `height: double.infinity` für das Bild verwendet. Diese Kombination ist problematisch, weil:
1. `IntrinsicHeight` erwartet, dass alle Kinder eine intrinsische Höhe haben
2. `height: double.infinity` hat keine intrinsische Höhe
3. Das führte dazu, dass die Layout-Berechnung für die meisten Cards fehlschlug

**Lösung:**
- `IntrinsicHeight` durch `SizedBox` mit fester Höhe (96px) ersetzt
- Bild-Höhe von `double.infinity` auf feste Höhe geändert
- Placeholder erhält ebenfalls feste Höhe

**Betroffene Datei:** `lib/features/poi/widgets/poi_card.dart`

## Technische Details

### Geänderter Code in `POICard`

```dart
// VORHER - Problematisch
child: IntrinsicHeight(
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      // Bild mit height: double.infinity
      CachedNetworkImage(
        height: double.infinity,  // <- Keine intrinsische Höhe!
        ...
      ),
    ],
  ),
)

// NACHHER - Feste Höhe
static const double _minCardHeight = 96.0;

child: SizedBox(
  height: _minCardHeight,
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      // Bild mit fester Höhe
      CachedNetworkImage(
        height: _minCardHeight,  // <- Feste Höhe
        ...
      ),
    ],
  ),
)
```

### Geänderte Dateien

| Datei | Änderung |
|-------|----------|
| `lib/features/poi/widgets/poi_card.dart` | `IntrinsicHeight` durch `SizedBox` ersetzt, feste Höhe für Bild und Placeholder |
| `pubspec.yaml` | Version 1.5.5 |

## Migration

Keine manuellen Schritte erforderlich. Die Änderungen sind abwärtskompatibel.

## Warum IntrinsicHeight + double.infinity problematisch ist

Flutter's `IntrinsicHeight` Widget berechnet die intrinsische Höhe aller Kinder und setzt dann alle auf die gleiche Höhe. Das funktioniert nur, wenn alle Kinder eine endliche intrinsische Höhe haben.

`double.infinity` als Höhe bedeutet "so groß wie möglich", was keine intrinsische Höhe ist. Das kann zu unvorhersehbarem Verhalten führen:
- Manche Cards werden korrekt gerendert
- Andere bekommen eine Höhe von 0 oder werden nicht sichtbar
- Das Verhalten kann je nach Flutter-Version und Gerät variieren

Die Lösung mit fester Höhe ist robuster und performanter, da keine aufwändige Layout-Berechnung nötig ist.

---

**Vorherige Version:** [v1.5.4](CHANGELOG-v1.5.4.md)
