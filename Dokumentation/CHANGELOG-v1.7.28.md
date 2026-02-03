# Changelog v1.7.28 - Panel Auto-Collapse, Modus-Persistenz & Euro Trip Persistenz

**Datum:** 31. Januar 2026
**Typ:** UX-Verbesserung
**Plattformen:** Android, iOS, Desktop

---

## Zusammenfassung

Nach Routenberechnung (Schnell oder AI Trip) klappt das Konfigurations-Panel automatisch ein, damit die Route auf der Karte besser sichtbar ist. Tippen auf den aktiven Modus klappt das Panel wieder auf. Der aktive Modus (Schnell/AI Trip) bleibt jetzt auch nach Navigation zu anderen Tabs und zurueck erhalten. Zusaetzlich: Mehrtaegige Euro Trips werden persistent in Hive gespeichert, sodass der Benutzer am naechsten Tag die Route wieder aufrufen und weitere Tage exportieren kann. "Tag exportiert" Meldung verschwindet nach 1 Sekunde automatisch.

---

## Aenderungen

### 1. **Panel Auto-Collapse nach Routenberechnung**
- **Schnell-Modus:** Nach Route-Berechnung klappt das Panel automatisch ein
- **AI Trip:** Nach Trip-Generierung klappt das Panel ein, Modus bleibt "AI Trip" (vorher: Auto-Switch zu Schnell)
- **Animation:** `AnimatedSize` mit 250ms easeInOut fuer fluessiges Ein-/Ausklappen

### 2. **Eingeklappte Route-Zusammenfassung**
- **Neues Widget:** `_CollapsedRouteSummary` zeigt kompakte Route-Info wenn Panel eingeklappt
- **Inhalt:** Route-Icon + Label (z.B. "AI Trip - 5 Stops") + Distanz/Dauer Badge + Expand-Chevron
- **Interaktion:** Tippen auf die Zusammenfassung klappt Panel wieder auf
- **Dark Mode:** Vollstaendig kompatibel (colorScheme.surface, keine hart-codierten Farben)

### 3. **Toggle-Expand ueber ModeToggle**
- **Gleicher Modus getippt:** Panel klappt auf/zu (Toggle)
- **Anderer Modus getippt:** Modus wechselt + Panel klappt auf
- **Visueller Hinweis:** Kleiner Expand-Chevron am aktiven Button wenn Panel eingeklappt

### 4. **Modus-Persistenz ueber Navigation**
- **Problem:** `MapPlanMode` war lokaler Widget-State → Reset auf "Schnell" bei jedem Screen-Rebuild
- **Loesung:** Neuer `mapPlanModeProvider` (Riverpod StateProvider) persistiert den Modus
- **Auto-Collapse:** `ref.listen` in `build()` erkennt Route-Berechnung und AI Trip-Generierung → Panel klappt automatisch ein
- **Mode-Restoration:** Falls Provider-State verloren geht, wird Modus per `addPostFrameCallback` in `build()` korrigiert
- **Ergebnis:** AI Trip bleibt AI Trip nach /trip → zurueck zur Karte

### 5. **Re-Expand bei Route-Loeschen**
- Route-Loeschen-Buttons (beide Modi) klappen Panel automatisch auf
- Logisch: Ohne Route gibt es nichts Eingeklapptes zu zeigen

---

## Technische Details

### Neue Provider in `map_controller_provider.dart`

```dart
/// Planungs-Modus (Schnell oder AI Trip)
enum MapPlanMode { schnell, aiTrip }

/// Aktiver Planungsmodus - persistiert ueber Screen-Rebuilds
final mapPlanModeProvider = StateProvider<MapPlanMode>((ref) => MapPlanMode.schnell);

/// Panel Collapsed-State (true = eingeklappt)
final mapPanelCollapsedProvider = StateProvider<bool>((ref) => false);
```

### Geaenderte Dateien

| Datei | Aenderung |
|-------|-----------|
| `lib/features/map/providers/map_controller_provider.dart` | `MapPlanMode` Enum + 2 neue StateProvider |
| `lib/features/map/map_screen.dart` | Lokalen State durch Provider ersetzt, AnimatedSize, CollapsedRouteSummary, ModeToggle Expand-Hint |

### Architektur-Entscheidungen

- **StateProvider statt @riverpod:** Folgt dem Muster von `shouldFitToRouteProvider` und `weatherWidgetCollapsedProvider` - einfache Werte, keine Code-Generierung noetig
- **AnimatedSize statt AnimatedCrossFade:** Panels sind komplexe Widget-Trees - AnimatedSize wrapped nur das Conditional und animiert die Hoehenuebergaenge sauber
- **`ref.listen` in `build()` statt `ref.listenManual` in `initState`:** Auto-Collapse-Listener und Fehler-Handler nutzen `ref.listen` in der `build()`-Methode. Das ist der idiomatische Riverpod-Ansatz - kein Timing-Problem mit `addPostFrameCallback`, automatisches Lifecycle-Management, Listener sind ab dem ersten Build aktiv
- **Mode-Restoration in `build()`:** Falls Provider-State durch Hot-Restart verloren geht, wird der korrekte Modus per `addPostFrameCallback` in `build()` korrigiert (nicht in initState)

---

## Vorher/Nachher

### Vorher (v1.7.27)
- Route berechnet → Panel bleibt offen, verdeckt Route
- AI Trip generiert → Auto-Switch zu Schnell-Modus (AI Trip Kontext verloren)
- Navigation weg und zurueck → Modus immer "Schnell"

### Nachher (v1.7.28)
- Route berechnet → Panel klappt ein, Route voll sichtbar
- AI Trip generiert → Panel klappt ein, Modus bleibt "AI Trip"
- Navigation weg und zurueck → Modus bleibt erhalten
- Tippen auf aktiven Modus → Panel klappt wieder auf

---

## Euro Trip Persistenz & Export-Verbesserung

### 6. **SnackBar Auto-Dismiss nach 1 Sekunde**
- **Problem:** Die "Tag X exportiert, Rueckgaengig" Meldung blieb ~4 Sekunden sichtbar
- **Fix:** `duration: const Duration(seconds: 1)` hinzugefuegt
- **Datei:** `lib/features/trip/trip_screen.dart`

### 7. **Euro Trip Persistenz (ActiveTripService aktiviert)**
- **Problem:** Mehrtaegige Euro Trips existierten nur im RAM (Riverpod `keepAlive`). Nach App-Neustart war der gesamte Fortschritt (generierte Route, exportierte Tage) verloren
- **Loesung:** Der bereits vorhandene aber ungenutzte `ActiveTripService` wird jetzt aktiviert

#### Was wird in Hive gespeichert:
| Daten | Hive-Key |
|-------|----------|
| Trip (Route + Stops) | `current_trip` (JSON) |
| Exportierte Tage | `completed_days` (List) |
| Ausgewaehlter Tag | `selected_day` (int) |
| Startpunkt | `start_lat`, `start_lng` (double) |
| Start-Adresse | `start_address` (String) |
| Trip-Modus | `trip_mode` (String) |
| Ausgewaehlte POIs | `selected_pois_json` (JSON) |
| Verfuegbare POIs | `available_pois_json` (JSON) |

#### Auto-Save Zeitpunkte:
- Nach `confirmTrip()` bei mehrtaegigen Euro Trips
- Nach jedem `completeDay()` (Tag exportiert)
- Nach jedem `uncompleteDay()` (Rueckgaengig)

#### Auto-Clear Zeitpunkte:
- Bei `reset()` (State zuruecksetzen)
- Bei `generateTrip()` (neuer Trip ueberschreibt alten)

### 8. **Resume-Banner im AI Trip Panel**
- Neues Banner "Euro Trip fortsetzen" im AI Trip Panel (MapScreen)
- Sichtbar wenn: gespeicherter Trip in Hive existiert UND kein Trip aktiv
- Design: `tertiaryContainer` Farbe mit History-Icon, Titel und Subtitle
- onTap: Laedt Trip aus Hive, stellt State wieder her, enriched POIs

### 9. **Resume-Button im TripScreen**
- Neuer "Euro Trip fortsetzen" Button in `_buildConfigView()` (Empty-State)
- Sichtbar wenn: gespeicherter Trip vorhanden
- onTap: Laedt Trip und navigiert zur Karte

### Benutzer-Flow

```
1. Euro Trip generieren (z.B. 3 Tage)
2. Trip bestaetigen → Automatisch in Hive gespeichert
3. Tag 1 exportieren → SnackBar (1 Sek) → Fortschritt in Hive
4. App schliessen
5. Naechster Tag: App oeffnen
6. AI Trip Panel → "Euro Trip fortsetzen" Banner
7. Antippen → Trip geladen mit Tag 2 ausgewaehlt
8. Tag 2 exportieren → Wiederholen fuer Tag 3
9. Neuen Trip generieren → Alter Trip aus Hive geloescht
```

### Zusaetzliche geaenderte Dateien

| Datei | Aenderung |
|-------|-----------|
| `lib/data/services/active_trip_service.dart` | Erweitert: startLocation, POI-Laden, keepAlive |
| `lib/features/random_trip/providers/random_trip_state.dart` | Neues Feld `hasResumableTrip` |
| `lib/features/random_trip/providers/random_trip_provider.dart` | Auto-Save, resumeTrip(), Hive-Integration |
| `lib/features/map/map_screen.dart` | Resume-Banner im AI Trip Panel |
| `lib/features/trip/trip_screen.dart` | SnackBar-Duration 1s + Resume-Button |

---

**Status:** Abgeschlossen
**Review:** Pending
**Deploy:** Released as v1.7.28
