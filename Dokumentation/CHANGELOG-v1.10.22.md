# Changelog v1.10.22 (Build 205)

**Datum:** 7. Februar 2026

## UI-Verbesserung: Reiseentfernung statt Radius

### Änderungen

#### Label-Umbenennung
Der AI Tagestrip-Slider zeigt jetzt "Reiseentfernung" statt "Radius" an, was die tatsächliche Bedeutung des Parameters besser widerspiegelt.

**Lokalisierungen:**
| Sprache | Alt | Neu |
|---------|-----|-----|
| DE | Radius | Reiseentfernung |
| EN | Radius | Travel distance |
| FR | Rayon | Distance de voyage |
| IT | Raggio | Distanza di viaggio |
| ES | Radio | Distancia de viaje |

#### Icon-Änderung
- **Alt:** `Icons.radar` (Radar-Symbol)
- **Neu:** `Icons.straighten` (Lineal-Symbol, passend für Entfernungsmessung)

### Betroffene Dateien

| Datei | Änderung |
|-------|----------|
| `lib/features/map/widgets/trip_config_panel.dart` | Icon von radar auf straighten geändert |
| `lib/l10n/app_de.arb` | radiusLabel: "Reiseentfernung" |
| `lib/l10n/app_en.arb` | radiusLabel: "Travel distance" |
| `lib/l10n/app_fr.arb` | radiusLabel: "Distance de voyage" |
| `lib/l10n/app_it.arb` | radiusLabel: "Distanza di viaggio" |
| `lib/l10n/app_es.arb` | radiusLabel: "Distancia de viaje" |

### Technische Details

Der Slider-Bereich bleibt unverändert bei 30-300 km. Nur die Beschriftung und das Icon wurden angepasst, um die Benutzerfreundlichkeit zu verbessern.

---

*Generiert mit Claude Code*
