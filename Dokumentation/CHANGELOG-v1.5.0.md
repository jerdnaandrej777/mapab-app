# Changelog v1.5.0 - AI Trip direkt auf MapScreen

**Datum:** 24.01.2026

## Übersicht

Major UI-Redesign: AI Trip Konfiguration wurde direkt in den MapScreen integriert. Keine Navigation mehr zu einer separaten Seite - alles passiert auf einer Seite mit sichtbarer Karte im Hintergrund.

## Neue Features

### AI Trip Panel auf MapScreen

Der MapScreen hat jetzt einen integrierten Mode-Toggle:
- **Schnell**: Klassische Start/Ziel Eingabe
- **AI Trip**: Kompaktes Konfigurations-Panel über der Karte

#### AI Trip Panel Komponenten

1. **Modus-Auswahl**
   - Tagestrip Button (🤖)
   - Euro Trip Button (✈️)

2. **Startpunkt-Eingabe**
   - Adress-Suchfeld mit Autocomplete
   - GPS-Standort Button als Alternative
   - Vorschläge aus Nominatim API

3. **Radius-Slider**
   - Kompakter Slider mit aktuellem Wert
   - Quick-Select Buttons (50/100/200/300 km für Tagestrip)
   - Angepasste Werte für Euro Trip (500-5000 km)

4. **Kategorien-Auswahl**
   - Aufklappbares Panel
   - Anzeige der Anzahl ausgewählter Kategorien
   - Reset-Button
   - Farbige Kategorie-Chips

5. **Generate Button**
   - "Überrasch mich!" Button
   - Startet Trip-Generierung

### MapView Erweiterungen

- **AI Trip Preview Route**: Route wird während der Vorschau auf der Karte angezeigt
- **AI Trip POI Marker**: Neue `_AITripStopMarker` Komponente
  - Zeigt Kategorie-Icon im Kreis
  - Nummeriertes Badge (orange) in der Ecke
- **Auto-Zoom**: Karte zoomt automatisch auf generierte Route

### Automatisches Verhalten

- Nach Trip-Generierung wechselt UI automatisch zu "Schnell"-Modus
- Route und POIs bleiben auf der Karte sichtbar
- Panel wird ausgeblendet für maximale Kartenansicht

## Geänderte Dateien

### lib/features/map/map_screen.dart

- Neues Enum `MapPlanMode { schnell, aiTrip }`
- Neue State-Variablen: `_planMode`, `_categoriesExpanded`
- Listener für `randomTripNotifierProvider` (Auto-Zoom + Mode-Switch)
- Neue Widgets:
  - `_ModeToggle` - Schnell/AI Trip Umschalter
  - `_ModeButton` - Einzelner Toggle-Button
  - `_AITripPanel` - Kompaktes Konfigurations-Panel
  - `_CompactRadiusSlider` - Radius-Einstellung
  - `_CompactCategorySelector` - Kategorien-Auswahl
  - `_GeneratingIndicator` - Loading-Anzeige

### lib/features/map/widgets/map_view.dart

- Import von `random_trip_provider.dart` und `random_trip_state.dart`
- Erkennung von AI Trip Preview-Modus
- Anzeige von AI Trip Route und POIs
- Neues Widget `_AITripStopMarker`

## UI/UX Verbesserungen

| Vorher (v1.4.9) | Nachher (v1.5.0) |
|-----------------|------------------|
| AI Trip öffnet neue Seite | AI Trip auf gleicher Seite |
| Karte nicht sichtbar bei Konfiguration | Karte immer sichtbar |
| Separate Navigation erforderlich | Ein-Klick Modus-Wechsel |
| Route erst nach Speichern sichtbar | Route sofort in Preview sichtbar |

## Technische Details

### State-Management

```dart
// Lokaler State im MapScreen
MapPlanMode _planMode = MapPlanMode.schnell;
bool _categoriesExpanded = false;

// Listener für AI Trip State
ref.listenManual(randomTripNotifierProvider, (previous, next) {
  if (next.step == RandomTripStep.preview) {
    // Auto-Zoom auf Route
    _fitMapToRoute(next.generatedTrip?.trip.route);
    // Wechsel zu Schnell-Modus
    setState(() => _planMode = MapPlanMode.schnell);
  }
});
```

### MapView AI Trip Integration

```dart
// Prüfen ob AI Trip Preview aktiv
final isAITripPreview = randomTripState.step == RandomTripStep.preview;

// Route-Priorität: TripState > AI Trip Preview > RoutePlanner
points: tripState.route?.coordinates ??
    (isAITripPreview ? aiTripRoute?.coordinates : null) ??
    routePlanner.route?.coordinates ??
    []
```

## Bekannte Einschränkungen

- AI Trip Panel kann bei kleinen Bildschirmen viel Platz einnehmen
- Kategorien-Panel hat max-height von 120px (scrollbar)

## Migration

Keine Migration erforderlich. Die Änderungen sind rein UI-basiert und beeinflussen keine gespeicherten Daten.

## Nächste Schritte

- [ ] Animationen für Panel Ein-/Ausblenden verbessern
- [ ] Tablet-Layout mit Side-Panel
- [ ] Swipe-Geste zum Ausblenden des Panels
