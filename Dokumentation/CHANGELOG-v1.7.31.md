# CHANGELOG v1.7.31 - Unified Panel Design mit integrierter POI-Auswahl

**Datum:** 01. Februar 2026
**Build:** 131
**Typ:** Major Feature - UX-Redesign
**Plattformen:** Android, iOS, Desktop

## Zusammenfassung

Beide Panel-Modi (Schnell-Modus & AI Trip) erhalten ein einheitliches 2-Phasen-Design:
- **Phase 1**: Konfiguration (Radius, Kategorien, Start/Ziel)
- **Phase 2**: Ergebnis + integrierte POI-Auswahl direkt im Panel

POIs muessen nicht mehr ueber einen separaten Tab gesucht werden - sie erscheinen nach der Routenberechnung direkt im Panel.

## Neue Features

### 1. Schnell-Modus: Umkreis-Slider & Kategorien (Phase 1)
- **Umkreis-Slider**: 10-100 km maximaler Umweg von der Route, Quick-Select: 20, 50, 75, 100 km
- **Kategorien-Auswahl**: Modal mit allen 15 POI-Kategorien, Live-Update der Auswahl
- **Neue Provider**: `schnellRadiusProvider` (Default: 50 km), `schnellCategoriesProvider`
- Position: Unterhalb der SearchBar, oberhalb des Route-Loeschen-Buttons

### 2. Schnell-Modus: Inline-POI-Liste (Phase 2)
- **Route-Info-Bar**: "Start -> Ziel" mit Distanz (km) und Fahrzeit
- **Kategorie Quick-Filter Chips**: Horizontal scrollbar, filtert angezeigte POIs
- **Inline-POI-Liste**: Max ~200px, scrollbar, kompakte Cards mit Bild + Name + Kategorie + Umweg
- **"+" Button**: POI direkt als Stop zur Route hinzufuegen (mit Haekcken-Feedback)
- **"Alle X POIs anzeigen"**: Link zum vollen POI-Screen (Bottom-Tab)
- **Auto-POI-Laden**: Nach Routenberechnung werden POIs automatisch entlang der Route geladen
- **Batch-Enrichment**: Fotos fuer erste 10 POIs werden automatisch geladen

### 3. AI Trip: POI-Entdeckung nach Generierung (Phase 2)
- **Trip-Info**: "AI Tagesausflug - X Stops, Y km, Z min" Zusammenfassung
- **"Weitere POIs entdecken"**: Inline-POI-Liste mit POIs im Trip-Radius
- **Intelligentes Filtern**: Bereits gewahlte Trip-POIs werden aus der Liste ausgeblendet
- **"+" Button**: Fuegt POI zum AI Trip hinzu (markiert Trip als confirmed)
- **"Zurueck zur Konfiguration"**: Link um Phase 1 erneut anzuzeigen
- **Auto-POI-Laden**: Nach Trip-Generierung werden POIs im Radius geladen

### 4. CompactPOICard Widget (neu)
- Kompakte 64px-Hoehe Card fuer Panel-Integration
- Layout: [56x56 Bild] [Name + Kategorie-Icon + Umweg-km] [+/Check Button]
- Dark-Mode-kompatibel (colorScheme)
- AnimatedContainer(100ms) fuer Add-Feedback
- Wiederverwendbar in beiden Panels

### 5. POITripHelper Utility (neu)
- Extrahierte Add-to-Trip Logik (vorher in poi_list_screen.dart)
- Erkennt automatisch ob AI Trip aktiv ist
- Uebergibt AI-Route/Stops wenn noetig
- GPS-Dialog Handling
- Wiederverwendbar: Panel + POI-Liste + POI-Detail

## Technische Details

### Neue Dateien

| Datei | Beschreibung |
|-------|-------------|
| `lib/features/map/widgets/compact_poi_card.dart` | Kompakte POI-Card (64px) fuer Inline-Panel |
| `lib/features/map/utils/poi_trip_helper.dart` | Extrahierte Add-to-Trip Logik |

### Geaenderte Dateien

| Datei | Aenderung |
|-------|----------|
| `lib/features/map/providers/map_controller_provider.dart` | + `schnellRadiusProvider`, + `schnellCategoriesProvider` |
| `lib/features/map/map_screen.dart` | Komplettes Redesign beider Panels: 2-Phasen-Design, neue Widgets (_SchnellRadiusSlider, _SchnellCategorySelector, _SchnellCategoryFilterChips, _InlinePOIList, _AITripInlinePOIList), erweiterte Route/AI-Trip Listener fuer Auto-POI-Laden |
| `lib/features/poi/poi_list_screen.dart` | Nutzt jetzt `POITripHelper` + `schnellRadiusProvider` statt hardcoded 50km |
| `pubspec.yaml` | Version 1.7.30 -> 1.7.31 |

### Phasen-Umschaltung

**Schnell-Modus:**
- Phase 1 <-> 2 basiert auf `routePlanner.hasRoute`
- Route berechnet -> Phase 2 mit POI-Liste
- Route geloescht -> Zurueck zu Phase 1

**AI Trip:**
- Phase 1 <-> 2 basiert auf `state.step == preview || confirmed`
- Trip generiert -> Phase 2 mit POI-Entdeckung
- "Zurueck zur Konfiguration" -> Phase 1

### Auto-POI-Laden

**Schnell-Modus (Route-Listener):**
1. Route berechnet -> `loadPOIsForRoute(route)`
2. `setRouteOnlyMode(true)` + `setMaxDetour(schnellRadius)`
3. `setSelectedCategories(schnellCategories)`
4. `enrichPOIsBatch()` fuer erste 10 POIs

**AI Trip (Trip-Listener):**
1. Trip generiert -> `loadPOIsInRadius(center, radiusKm)`
2. `setSelectedCategories(tripCategories)`
3. `enrichPOIsBatch()` fuer erste 10 POIs
4. Bereits gewaehlte Trip-POIs aus Liste filtern

## Kompatibilitaet

- Keine Breaking Changes
- Bestehende Trips/Routen bleiben erhalten
- POI-Screen (Bottom-Tab) bleibt als Erweiterung erhalten
- Alle vorherigen Features funktionieren weiterhin

---

**Status:** Abgeschlossen
**Review:** Pending
**Deploy:** Pending
