# Changelog v1.6.2 - Euro Trip Performance-Fix

**Release-Datum:** 28. Januar 2026

## Fehlerbehebung

### Euro Trip "lädt ewig" Problem gelöst
- **Ursache:** Wikipedia Grid-Suche war extrem langsam bei großen Radien
  - Bei 600km Radius: 80×80 = 6400 Grid-Zellen mit je 100ms Delay = **10+ Minuten!**
- **Lösung:** Dynamische Grid-Size mit Maximum von 36 Zellen (6×6)
  - Jetzt bei 600km: 6×6 = 36 Zellen = **~4 Sekunden**

### Verbessertes Debug-Logging
- Log-Ausgaben für Grid-Berechnung: `[POI] Wikipedia Grid: 6x6 Zellen, 200km pro Zelle`
- Log-Ausgaben für POI-Anzahl: `[TripGenerator] 45 POIs gefunden`
- Log-Ausgaben für Route: `[TripGenerator] ✓ Route berechnet: 1234km`

### Timeout für POI-Laden
- 45 Sekunden Timeout verhindert endloses Warten
- Bei Timeout: Klare Fehlermeldung "Keine POIs gefunden. Versuche anderen Startpunkt oder kleineren Radius."

## Technische Details

### Geänderte Dateien

| Datei | Änderung |
|-------|----------|
| `lib/data/repositories/poi_repo.dart` | Dynamische Grid-Size statt feste 15km |
| `lib/data/repositories/trip_generator_repo.dart` | Timeout + Debug-Logging |

### Grid-Berechnung

```dart
// VORHER: Feste Grid-Size
final gridSize = 15.0; // km pro Grid-Zelle
final cellsPerSide = (radiusKm * 2 / gridSize).ceil();
// Bei 600km: (1200 / 15).ceil() = 80 → 6400 Zellen

// NACHHER: Dynamische Grid-Size
const maxCellsPerSide = 6;
final gridSize = max((radiusKm * 2 / maxCellsPerSide), 15.0);
final cellsPerSide = min((radiusKm * 2 / gridSize).ceil(), maxCellsPerSide);
// Bei 600km: max 6×6 = 36 Zellen
```

### Performance-Vergleich

| Radius | Zellen vorher | Zeit vorher | Zellen nachher | Zeit nachher |
|--------|---------------|-------------|----------------|--------------|
| 100km | 14×14 = 196 | ~20s | 6×6 = 36 | ~4s |
| 300km | 40×40 = 1600 | ~3 Min | 6×6 = 36 | ~4s |
| 600km | 80×80 = 6400 | ~10 Min | 6×6 = 36 | ~4s |
| 1200km | 160×160 = 25600 | ~40 Min | 6×6 = 36 | ~4s |

## Hinweise

- Bei sehr großen Radien werden weniger Wikipedia-POIs gefunden (größere Grid-Abstände)
- Overpass- und kuratierte POIs sind davon nicht betroffen
- Für bessere Abdeckung bei großen Radien: Mehrere kleinere Trips erstellen

---

**Vollständige Änderungen seit v1.6.1:**
- Euro Trip Performance-Fix (v1.6.2)
