# CHANGELOG v1.9.10 - Wetter-Details Vollbild-Sheet

**Datum:** 3. Februar 2026
**Build:** 1.9.10+157

## Ueberblick

Das Wetter-Details Bottom Sheet wurde von halber Bildschirmhoehe auf ein DraggableScrollableSheet umgestellt, das 85% des Bildschirms einnimmt. Alle Inhalte (Vorhersage, UV-Index, Empfehlung) sind jetzt scrollbar und werden nicht mehr von der Bottom Navigation abgeschnitten.

---

## Fix: Wetter-Details Sheet wird nicht mehr abgeschnitten

### Problem
Das WeatherDetailsSheet oeffnete als `Column(mainAxisSize: MainAxisSize.min)` — es nahm nur so viel Platz ein wie der Inhalt benoetigte. Bei vielen Wetter-Daten (7-Tage-Vorhersage, Sonnenzeiten, UV-Index, Empfehlung) wurde der untere Teil vom Bottom Navigation Bar ("AI Tagestrip" / "AI Euro Trip") verdeckt.

### Loesung
Umstellung auf `DraggableScrollableSheet` mit scrollbarem Inhalt:

**showWeatherDetailsSheet():**
- `DraggableScrollableSheet` mit `initialChildSize: 0.85` (85% Bildschirmhoehe)
- `minChildSize: 0.5` — Sheet kann auf 50% zusammengeschoben werden
- `maxChildSize: 0.95` — Sheet kann fast auf Vollbild gezogen werden
- `ScrollController` wird an den Inhalt weitergegeben

**WeatherDetailsSheet Widget:**
- Header (Ortsname + Schliessen-Button) bleibt fixiert oben
- Alle weiteren Inhalte (Wetter, Vorhersage, Zusatzinfos, Empfehlung) in `SingleChildScrollView`
- `Column(mainAxisSize: MainAxisSize.min)` → `Column()` mit `Expanded` fuer scrollbaren Bereich
- Neuer optionaler Parameter `ScrollController? scrollController`

### Vorher vs. Nachher

| Aspekt | Vorher | Nachher |
|--------|--------|---------|
| Sheet-Hoehe | min (nur Inhalt) | 85% Bildschirm |
| Scrollbar | Nein | Ja |
| Ziehbar | Nein | Ja (50%-95%) |
| Bottom Nav Abschneiden | Ja | Nein |
| Header fixiert | Nein | Ja |

---

## Geaenderte Dateien

| Datei | Aenderung |
|-------|-----------|
| `lib/features/map/widgets/weather_details_sheet.dart` | DraggableScrollableSheet, ScrollController, fixierter Header, scrollbarer Inhalt |

---

## Technische Details

### DraggableScrollableSheet Konfiguration
```dart
DraggableScrollableSheet(
  initialChildSize: 0.85,  // 85% Bildschirmhoehe
  minChildSize: 0.5,       // Minimum 50%
  maxChildSize: 0.95,      // Maximum 95%
  builder: (context, scrollController) => WeatherDetailsSheet(
    scrollController: scrollController,
    // ...
  ),
)
```

### Layout-Struktur
```
Container (surface, borderRadius 20)
├── Handle (40x4, onSurfaceVariant)
├── Header (fixiert)
│   ├── Ortsname (titleLarge, bold)
│   ├── Datum/Uhrzeit (bodySmall)
│   └── Close-Button
└── Expanded → SingleChildScrollView (scrollController)
    ├── Aktuelles Wetter (Temperatur, Beschreibung, Wind)
    ├── Divider
    ├── 7-Tage-Vorhersage (horizontal ListView)
    ├── Zusatz-Infos (Sonnenzeiten, UV, Niederschlag)
    ├── Empfehlung (condition-basiert)
    └── SizedBox(24)
```

### Validierung
- flutter analyze: Keine neuen Fehler
