# Changelog v1.10.24 (Build 207)

**Datum:** 7. Februar 2026

## AI Tagestrip: Distanzlimit- und Radius-Übernahme-Fix

Dieses Release behebt einen Fehler in der AI-Tagestrip-Logik: Die eingestellte maximale Reiseentfernung in km wurde bislang nicht zuverlässig übernommen.

### Behoben

#### 1. Radius wurde beim Moduswechsel zurückgesetzt
- Beim Wechsel zwischen `AI Tagestrip` und `AI Euro Trip` wurde der Tagestrip-Wert teils wieder auf `100 km` gesetzt.
- Der zuletzt gewählte Tagestrip-Wert wird jetzt im Provider beibehalten und beim Zurückwechseln korrekt wiederverwendet.

#### 2. Reiseentfernung wurde nur als Suchradius genutzt
- `radiusKm` wurde bisher primär für die POI-Suche verwendet.
- Die finale Tagestrip-Route konnte dadurch deutlich länger werden als der eingestellte Wert.
- Jetzt wird die Route nach der Optimierung zusätzlich auf das Distanzlimit begrenzt (`trimRouteToMaxDistance`).
- Wenn innerhalb des Limits keine Route möglich ist, erscheint eine klare Fehlermeldung statt einer unpassenden Route.

### Geänderte Dateien

| Datei | Änderung |
|-------|----------|
| `lib/features/random_trip/providers/random_trip_provider.dart` | Persistenter Tagestrip-Radius (`_lastDayTripRadiusKm`), kein 100km-Reset beim Moduswechsel |
| `lib/data/repositories/trip_generator_repo.dart` | Tagestrip-Distanzlimit als harte Grenze via `trimRouteToMaxDistance` |
| `test/algorithms/route_optimizer_test.dart` | 2 neue Regression-Tests für Distanz-Trim-Logik |

### Technische Hinweise

- Das Distanz-Trim basiert auf Haversine-Distanzen im Optimierer.
- Die reale Straßendistanz (OSRM) kann im Einzelfall leicht abweichen, ist jetzt aber an den eingestellten km-Wert gekoppelt statt ungebremst zu wachsen.

### Validierung

- `flutter test test/algorithms/route_optimizer_test.dart` ✅
- `flutter test test/algorithms/day_planner_test.dart` ✅

---

*Generiert mit Claude Code*
