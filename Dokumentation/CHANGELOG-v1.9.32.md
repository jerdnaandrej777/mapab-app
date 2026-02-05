# CHANGELOG v1.9.32 - Vollstaendige Lokalisierung

**Release-Datum:** 5. Februar 2026
**Build:** 179

## Uebersicht

Vollstaendige Internationalisierung der MapAB-App mit 5 Sprachen und ~700 lokalisierten Strings.

## Unterstuetzte Sprachen

| Code | Sprache | Status |
|------|---------|--------|
| `de` | Deutsch | Basis (Template) |
| `en` | English | Vollstaendig |
| `fr` | Francais | Vollstaendig |
| `it` | Italiano | Vollstaendig |
| `es` | Espanol | Vollstaendig |

---

## Neue Features

### 1. ARB-Lokalisierungssystem

**~700 lokalisierte Strings** in 5 Sprachen:

| Datei | Beschreibung |
|-------|--------------|
| `lib/l10n/app_de.arb` | Deutsches Template (~700 Keys) |
| `lib/l10n/app_en.arb` | Englische Uebersetzungen |
| `lib/l10n/app_fr.arb` | Franzoesische Uebersetzungen |
| `lib/l10n/app_it.arb` | Italienische Uebersetzungen |
| `lib/l10n/app_es.arb` | Spanische Uebersetzungen |

### 2. GPS-Dialog Zentralisierung

**Datei:** `lib/core/utils/location_helper.dart`

GPS-Dialoge aus 7+ Dateien in einen zentralen Helper konsolidiert:

```dart
// Vorher: Duplizierter Code in jeder Datei
showDialog(
  title: Text('GPS deaktiviert'),  // Hardcodiert!
  content: Text('Moechtest du die GPS-Einstellungen oeffnen?'),
  // ...
);

// Nachher: Zentraler Helper mit l10n
await LocationHelper.showGpsDialog(context);
// Nutzt context.l10n.gpsDisabledTitle, context.l10n.gpsDisabledMessage, etc.
```

**Betroffene Dateien:**
- `lib/features/poi/poi_list_screen.dart`
- `lib/features/ai_assistant/chat_screen.dart`
- `lib/features/map/utils/poi_trip_helper.dart`
- `lib/features/map/widgets/map_view.dart`
- `lib/features/random_trip/widgets/start_location_picker.dart`

### 3. Convenience Extension

**Datei:** `lib/core/l10n/l10n.dart`

```dart
// Kurzform fuer Lokalisierung
import '../../core/l10n/l10n.dart';

Text(context.l10n.settingsTitle)  // statt AppLocalizations.of(context)!.settingsTitle
```

### 4. Enum-Lokalisierung

**Datei:** `lib/core/l10n/category_l10n.dart`

Extensions fuer lokalisierte Enum-Labels:

```dart
POICategory.castle.localizedLabel(context)  // "Burg" / "Castle" / etc.
AppThemeMode.dark.localizedLabel(context)   // "Dunkel" / "Dark" / etc.
TripType.eurotrip.localizedLabel(context)   // "Euro Trip" / etc.
```

---

## Lokalisierte Screens

### Kritische Screens (Phase 2)

| Screen | Ersetzungen | Neue Keys |
|--------|-------------|-----------|
| `trip_screen.dart` | ~30 | 0 (existierende Keys) |
| `profile_screen.dart` | ~15 | 0 |
| `navigation_bottom_bar.dart` | 6 | 2 |
| `poi_approach_card.dart` | 1 | 0 |

### Wichtige Screens (Phase 3)

| Screen | Ersetzungen | Neue Keys |
|--------|-------------|-----------|
| `favorites_screen.dart` | ~8 | 0 |
| `poi_list_screen.dart` | 6 | 4 |
| `poi_detail_screen.dart` | 4 | 8 |
| `qr_scanner_screen.dart` | - | 14 |
| `trip_templates_screen.dart` | - | 20 |
| `ai_suggestion_banner.dart` | ~4 | 0 |
| `chat_screen.dart` | ~4 | 0 |

### Weitere Screens (Phase 5)

| Screen | Beschreibung |
|--------|--------------|
| `map_view.dart` | Kontextmenue |
| `share_trip_sheet.dart` | Sharing-Optionen |
| `navigation_screen.dart` | Navigation UI |
| `day_editor_overlay.dart` | Tag-Editor |
| `unified_weather_widget.dart` | Wetter-Anzeige |
| `poi_filters.dart` | Filter-Chips |
| `poi_reroll_button.dart` | Reroll-Button |
| `hotel_detail_sheet.dart` | Hotel-Details |

---

## Neue ARB-Keys

### Navigation (2 Keys)
```json
"navVoiceListening": "Hoert...",
"navVoice": "Sprache"
```

### POI-Liste (4 Keys)
```json
"poiWeatherTip": "Wetter-Tipp",
"poiResultsCount": "{filtered} von {total} POIs",
"poiNoResultsFilter": "Keine POIs mit diesen Filtern gefunden",
"poiNoResultsNearby": "Keine POIs in der Naehe gefunden"
```

### POI-Details (8 Keys)
```json
"poiAboutPlace": "Ueber diesen Ort",
"poiNoDescription": "Keine Beschreibung verfuegbar.",
"poiDescriptionLoading": "Beschreibung wird geladen...",
"poiFoundedYear": "Gegruendet {year}",
"poiRating": "{rating} von 5 ({count} Bewertungen)",
"poiCurated": "Kuratiert",
"poiVerified": "Verifiziert",
"poiContactInfo": "Kontakt & Info"
```

### QR-Scanner (14 Keys)
```json
"scanTitle": "Trip scannen",
"scanInstruction": "QR-Code scannen",
"scanDescription": "Halte dein Handy ueber einen MapAB QR-Code",
"scanLoading": "Trip wird geladen...",
"scanTripFound": "Trip gefunden!",
"scanStops": "{count} Stopps",
"scanDays": "{count, plural, =1{1 Tag} other{{count} Tage}}",
"scanImportQuestion": "Moechtest du diesen Trip importieren?",
"scanImport": "Importieren",
"scanInvalidCode": "Ungueltiger QR-Code",
"scanLoadError": "Trip konnte nicht geladen werden",
"scanInvalidMapabCode": "Kein gueltiger MapAB QR-Code",
"scanImportSuccess": "{name} wurde importiert!",
"scanImportError": "Trip konnte nicht importiert werden"
```

### Trip-Templates (20 Keys)
```json
"templatesTitle": "Trip-Vorlagen",
"templatesScanQr": "QR-Code scannen",
"templatesAudienceAll": "Alle",
"templatesAudienceCouples": "Paare",
"templatesAudienceFamilies": "Familien",
"templatesAudienceAdventurers": "Abenteurer",
"templatesAudienceFoodies": "Foodies",
"templatesAudiencePhotographers": "Fotografen",
"templatesDays": "{count, plural, =1{1 Tag} other{{count} Tage}}",
"templatesCategories": "{count} Kategorien",
"templatesIncludedCategories": "Enthaltene Kategorien",
"templatesDuration": "Reisedauer",
"templatesRecommended": "Empfohlen: {days} {unit}",
"templatesBestSeason": "Beste Reisezeit: {season}",
"templatesStartPlanning": "Trip planen",
"seasonSpring": "Fruehling",
"seasonSummer": "Sommer",
"seasonAutumn": "Herbst",
"seasonWinter": "Winter",
"seasonSpringAutumn": "Fruehling bis Herbst",
"seasonYearRound": "Ganzjaehrig"
```

---

## CLAUDE.md Erweiterungen

### Lokalisierungs-Checkliste fuer neue Features

1. **Keine hardcodierten Strings:**
   ```dart
   // FALSCH
   Text('Speichern')

   // RICHTIG
   Text(context.l10n.save)
   ```

2. **Import nicht vergessen:**
   ```dart
   import '../../core/l10n/l10n.dart';
   ```

3. **const entfernen bei l10n:**
   ```dart
   // FALSCH - Kompilierungsfehler!
   const Text(context.l10n.save)

   // RICHTIG
   Text(context.l10n.save)
   ```

4. **ARB-Key-Konvention:** `bereichBeschreibung` (camelCase)
   - `tripSaveRoute`, `navDistance`, `poiNotFound`

5. **Plurale und Parameter:**
   ```json
   "dayCount": "{count, plural, =1{1 Tag} other{{count} Tage}}"
   ```

---

## Betroffene Dateien

### Core
| Datei | Aenderung |
|-------|-----------|
| `lib/core/l10n/l10n.dart` | context.l10n Extension |
| `lib/core/l10n/category_l10n.dart` | Enum-Lokalisierung |
| `lib/core/utils/location_helper.dart` | GPS-Dialog mit l10n |
| `l10n.yaml` | Flutter l10n Konfiguration |

### ARB-Dateien
| Datei | Keys |
|-------|------|
| `lib/l10n/app_de.arb` | ~700 (Template) |
| `lib/l10n/app_en.arb` | ~700 |
| `lib/l10n/app_fr.arb` | ~700 |
| `lib/l10n/app_it.arb` | ~700 |
| `lib/l10n/app_es.arb` | ~700 |

### Lokalisierte Screens
- `lib/features/trip/trip_screen.dart`
- `lib/features/account/profile_screen.dart`
- `lib/features/favorites/favorites_screen.dart`
- `lib/features/poi/poi_list_screen.dart`
- `lib/features/poi/poi_detail_screen.dart`
- `lib/features/navigation/widgets/navigation_bottom_bar.dart`
- `lib/features/navigation/widgets/poi_approach_card.dart`
- `lib/features/sharing/qr_scanner_screen.dart`
- `lib/features/templates/trip_templates_screen.dart`
- `lib/features/ai/widgets/ai_suggestion_banner.dart`
- `lib/features/ai_assistant/chat_screen.dart`
- `lib/features/map/widgets/map_view.dart`
- `lib/features/map/utils/poi_trip_helper.dart`

---

## Verifikation

Nach dem Update:
1. App in Deutsch starten - alle Texte korrekt
2. Sprache auf Englisch wechseln - alle Texte uebersetzt
3. Sprache auf Franzoesisch/Italienisch/Spanisch wechseln
4. GPS deaktivieren → Dialog erscheint in gewaehlter Sprache
5. Trip-Templates oeffnen → Alle Labels uebersetzt
6. QR-Scanner oeffnen → Alle Labels uebersetzt

---

## Statistik

| Metrik | Wert |
|--------|------|
| Unterstuetzte Sprachen | 5 |
| Lokalisierte Strings | ~700 |
| Neue ARB-Keys | ~58-63 |
| Ersetzte hardcodierte Strings | 202+ |
| Zentralisierte GPS-Dialoge | 7+ Dateien |
