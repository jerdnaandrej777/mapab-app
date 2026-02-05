# CHANGELOG v1.10.2 - Lokalisierung MapScreen

**Datum:** 5. Februar 2026
**Build:** 182

## Zusammenfassung

Lokalisierung der MapScreen-UI-Elemente (AI Tagestrip/Euro Trip Buttons und Trip-Konfigurationspanel) in alle 5 unterstützten Sprachen.

## Neue Features

### Lokalisierung der Map-Mode-Buttons

Die Buttons "AI Tagestrip" und "AI Euro Trip" auf der Startseite werden jetzt in der vom Benutzer gewählten Sprache angezeigt:

| Sprache | AI Tagestrip | AI Euro Trip |
|---------|--------------|--------------|
| Deutsch | AI Tagestrip | AI Euro Trip |
| English | AI Day Trip | AI Euro Trip |
| Français | AI Excursion | AI Euro Trip |
| Italiano | AI Gita | AI Euro Trip |
| Español | AI Excursión | AI Euro Trip |

### Lokalisierung des Trip-Konfigurationspanels

Folgende UI-Elemente im Trip-Konfigurationspanel wurden lokalisiert:

| Element | DE | EN |
|---------|----|----|
| Start-Label | Start | Start |
| Reisedauer | Reisedauer | Travel duration |
| Radius | Radius | Radius |
| Kategorien | Kategorien | Categories |
| X ausgewählt | {count} ausgewählt | {count} selected |
| Alle | Alle | All |
| Fertig | Fertig | Done |
| Ziel (optional) | Ziel (optional) | Destination (optional) |
| Zielort eingeben | Zielort eingeben... | Enter destination... |

### Trip-Beschreibungen lokalisiert

Die dynamischen Trip-Beschreibungen im Euro-Trip-Modus:

| Tage | DE | EN |
|------|----|----|
| 1 | Tagesausflug — ca. X km | Day trip — approx. X km |
| 2 | Wochenend-Trip — ca. X km | Weekend trip — approx. X km |
| 3-4 | Kurzurlaub — ca. X km | Short vacation — approx. X km |
| 5-7 | Wochenreise — ca. X km | Week trip — approx. X km |
| 8+ | Epischer Euro Trip — ca. X km | Epic Euro Trip — approx. X km |

## Technische Details

### Neue ARB-Keys

Folgende Keys wurden zu allen 5 Sprachdateien hinzugefügt:

```
mapModeAiDayTrip
mapModeAiEuroTrip
travelDuration
radiusLabel
categoriesLabel
tripDescDayTrip (mit {radius} Platzhalter)
tripDescWeekend (mit {radius} Platzhalter)
tripDescShortVacation (mit {radius} Platzhalter)
tripDescWeekTrip (mit {radius} Platzhalter)
tripDescEpic (mit {radius} Platzhalter)
selectedCount (mit {count} Platzhalter)
destinationOptional
enterDestination
```

### Geänderte Dateien

| Datei | Änderung |
|-------|----------|
| `lib/l10n/app_de.arb` | 13 neue Keys hinzugefügt |
| `lib/l10n/app_en.arb` | 13 neue Keys hinzugefügt |
| `lib/l10n/app_fr.arb` | 13 neue Keys hinzugefügt |
| `lib/l10n/app_it.arb` | 13 neue Keys hinzugefügt |
| `lib/l10n/app_es.arb` | 13 neue Keys hinzugefügt |
| `lib/features/map/widgets/trip_mode_selector.dart` | l10n-Import + lokalisierte Labels |
| `lib/features/map/widgets/trip_config_panel.dart` | Alle hardcodierten Strings durch l10n ersetzt |
| `pubspec.yaml` | Version 1.10.1+181 → 1.10.2+182 |

### Verwendete bestehende Keys

Folgende bereits existierende Keys wurden wiederverwendet:
- `start` → "Start"
- `done` → "Fertig"
- `remove` → "Entfernen"
- `all` → "Alle"
- `formatDayCount` → Plural für "X Tag/Tage"

## Betroffene Features

- MapScreen (Startseite)
- Trip-Mode-Selector (AI Tagestrip / AI Euro Trip Buttons)
- Trip-Konfigurationspanel (Tagestrip & Euro Trip)
- Ziel-Eingabe-Dialog

## Migration

Keine Migration erforderlich. Die Änderungen sind rein UI-bezogen.

---

**Vollständige Änderungsliste:** Siehe Git-Commit-History
