# Changelog v1.5.6

**Release-Datum:** 26. Januar 2026

## UI-Verbesserungen

### Floating Buttons bei AI Trip ausblenden

**Beschreibung:** Die Einstellungen- und GPS-Standort-Buttons werden jetzt ausgeblendet, wenn der "AI Trip"-Modus aktiv ist. Dies sorgt für eine aufgeräumtere Oberfläche beim Planen eines AI Trips.

**Verhalten:**
- **Schnell-Modus:** Einstellungen- und GPS-Button sichtbar (unten rechts)
- **AI Trip-Modus:** Beide Buttons werden ausgeblendet

**Warum diese Änderung?**
- Das AI Trip Panel benötigt mehr Platz auf dem Bildschirm
- Die Buttons überlappten teilweise mit dem Panel
- GPS-Standort kann direkt im AI Trip Panel über den "GPS-Standort"-Button gesetzt werden
- Einstellungen sind während der Trip-Planung selten benötigt

### Geänderte Dateien

| Datei | Änderung |
|-------|----------|
| `lib/features/map/map_screen.dart` | Floating Buttons nur im Schnell-Modus anzeigen |
| `pubspec.yaml` | Version 1.5.6 |

## Technische Details

### Geänderter Code in `MapScreen`

```dart
// VORHER - Immer sichtbar
Positioned(
  right: 16,
  bottom: 100,
  child: Column(
    children: [
      FloatingActionButton.small(heroTag: 'settings', ...),
      FloatingActionButton.small(heroTag: 'gps', ...),
    ],
  ),
),

// NACHHER - Nur im Schnell-Modus sichtbar
if (_planMode == MapPlanMode.schnell)
  Positioned(
    right: 16,
    bottom: 100,
    child: Column(
      children: [
        FloatingActionButton.small(heroTag: 'settings', ...),
        FloatingActionButton.small(heroTag: 'gps', ...),
      ],
    ),
  ),
```

## Migration

Keine manuellen Schritte erforderlich. Die Änderungen sind abwärtskompatibel.

---

**Vorherige Version:** [v1.5.5](CHANGELOG-v1.5.5.md)
