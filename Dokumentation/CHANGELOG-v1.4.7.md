# Changelog v1.4.7 - Erweiterter Radius für AI-Trips

**Build-Datum:** 24. Januar 2026
**Flutter SDK:** 3.38.7

---

## Neue Features

### Erweiterter Such-Radius für AI-Trips

Die Radius-Einstellungen für AI-generierte Trips wurden deutlich erweitert, um größere Reisen zu ermöglichen.

#### Tagesausflug (AI Tagesausflug)
- **Vorher:** 30 - 200 km
- **Nachher:** 30 - 300 km
- **Default:** 100 km (unverändert)

#### Euro Trip (AI Euro Trip)
- **Vorher:** 100 - 800 km
- **Nachher:** 100 - 5000 km
- **Default:** 1000 km (vorher 300 km)

### Neue Radius-Beschreibungen

#### Tagesausflug
| Radius | Beschreibung |
|--------|--------------|
| ≤ 50 km | Kurzer Ausflug in der Nähe |
| ≤ 100 km | Idealer Tagesausflug |
| ≤ 150 km | Ausgedehnter Tagesausflug |
| ≤ 200 km | Langer Tagesausflug mit viel Fahrzeit |
| > 200 km | Sehr weiter Tagesausflug |

#### Euro Trip
| Radius | Beschreibung |
|--------|--------------|
| ≤ 300 km | Regionale Erkundung |
| ≤ 600 km | Mehrere Bundesländer/Kantone |
| ≤ 1000 km | Länder-übergreifend |
| ≤ 2000 km | Großer Euro Trip |
| ≤ 3500 km | Kontinentale Reise |
| > 3500 km | Epischer Europa-Trip |

### Quick-Select Buttons aktualisiert

#### Tagesausflug
- **Vorher:** 50, 100, 150, 200 km
- **Nachher:** 50, 100, 200, 300 km

#### Euro Trip
- **Vorher:** 200, 400, 600, 800 km
- **Nachher:** 500, 1000, 2500, 5000 km

---

## Geänderte Dateien

| Datei | Änderung |
|-------|----------|
| [radius_slider.dart](../lib/features/random_trip/widgets/radius_slider.dart) | Max-Radius erhöht, neue Beschreibungen, Quick-Select-Werte |
| [random_trip_provider.dart](../lib/features/random_trip/providers/random_trip_provider.dart) | Default für Euro Trip auf 1000 km |
| [pubspec.yaml](../pubspec.yaml) | Version auf 1.4.7+1 |

---

## Technische Details

### Slider-Divisions

Für den Euro Trip wurde die Slider-Schrittweite von 10 km auf 100 km erhöht, um bei dem größeren Bereich (5000 km) eine sinnvolle Anzahl von Schritten zu haben:

```dart
divisions: state.mode == RandomTripMode.daytrip
    ? ((maxRadius - minRadius) / 10).round()   // 27 Schritte
    : ((maxRadius - minRadius) / 100).round(), // 49 Schritte
```

---

## Download

- **APK:** `MapAB-v1.4.7.apk` (~57 MB)
- **GitHub Release:** https://github.com/jerdnaandrej777/mapab-app/releases/tag/v1.4.7
