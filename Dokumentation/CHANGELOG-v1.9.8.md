# CHANGELOG v1.9.8 - AI-POI-Empfehlungen & POI-Entfernen im Korridor-Browser

**Datum:** 3. Februar 2026
**Build:** 1.9.8+155

## Ueberblick

Zwei neue Features fuer den Tag-Editor: (1) AI-gestuetzte Indoor-POI-Empfehlungen mit GPT-4o Ranking bei schlechtem Wetter, dargestellt als interaktive POI-Karten mit Hinzufuegen/Tauschen-Buttons. (2) Bereits hinzugefuegte POIs lassen sich direkt im Korridor-Browser wieder entfernen.

---

## Feature 1: AI-POI-Empfehlungen als actionable Karten

### Problem
Bei schlechtem Wetter zeigte das System bisher nur Text-Vorschlaege ("Ersetze X durch ein Museum"). Der User musste selbst nach passenden POIs suchen und diese manuell hinzufuegen.

### Loesung
Das System laedt jetzt automatisch Indoor-POIs entlang des Korridors, sendet sie an GPT-4o zur Bewertung und zeigt die Ergebnisse als interaktive POI-Karten mit Action-Buttons.

### Ablauf
1. User tippt "Indoor-Alternativen vorschlagen" im DayEditor
2. System laedt Korridor-POIs (indoor/wetter-resilient, 50km Buffer)
3. GPT-4o rankt und begruendet die Top-5 Empfehlungen
4. POI-Karten mit Kategorie-Icon, Name, "Empfohlen"-Badge und AI-Begruendung erscheinen
5. User klickt "Hinzufuegen" (Plus-Icon) oder "Tauschen" (Swap-Icon)
6. Fallback bei GPT-Fehler: Regelbasiertes Ranking nach Score + Umweg

### Geaenderte Dateien

**`lib/features/ai/providers/ai_trip_advisor_provider.dart`**
- `AISuggestion` erweitert: `aiReasoning` (String?), `relevanceScore` (double?)
- `AITripAdvisorState` erweitert: `recommendedPOIsPerDay` Map + Getter
- Neue Methode `loadAndRankIndoorAlternatives()`:
  - Laedt Korridor-POIs via CorridorBrowserProvider (50km Buffer)
  - Filtert auf `isWeatherResilient` Kategorien
  - Sendet max 15 Kandidaten an GPT-4o
  - GPT liefert JSON mit action (add/swap), reasoning, score
  - Fallback: `_rankRuleBased()` sortiert nach Score desc + Umweg asc
- Neue Methode `_rankWithGPT()`: Baut Prompt mit Stops + Wetter + Kandidaten
- Neue Methode `_parseGPTResponse()`: Extrahiert JSON-Array, matched POI-Namen
- Neue Methode `_rankRuleBased()`: Regelbasierter Fallback, Top 5

**`lib/features/trip/widgets/day_editor_overlay.dart`**
- `_AISuggestionsSection` komplett umgebaut:
  - Header: "AI-Empfehlungen" mit auto_awesome Icon
  - Fuer Suggestions MIT `alternativePOI` → `_AIRecommendedPOICard`
  - Fuer Suggestions OHNE `alternativePOI` → bestehende Text-Darstellung
- Neues Widget `_AIRecommendedPOICard`:
  - Layout: Kategorie-Icon (40x40) + Name + "Empfohlen"-Badge + Umweg-Info
  - Darunter: AI-Reasoning Text (italic, max 2 Zeilen)
  - Action-Button: Plus (Hinzufuegen) oder Swap (Tauschen)
  - Container: primaryContainer.withOpacity(0.15), primary Border
- `_handleAdd()`: addPOIToDay() + SnackBar
- `_handleSwap()`: removePOI(targetId) + addPOIToDay(newPOI) + SnackBar
- Banner-Callback geaendert: `loadAndRankIndoorAlternatives()` statt `suggestAlternativesForDay()`

---

## Feature 2: POI-Entfernen im Korridor-Browser

### Problem
Im inline Korridor-Browser konnten POIs zum Trip hinzugefuegt werden (Plus → Haekchen), aber nicht wieder entfernt werden. Der User musste den Korridor-Browser schliessen und den POI in der normalen POI-Liste loeschen.

### Loesung
Hinzugefuegte POIs zeigen jetzt ein rotes Minus-Icon statt des gruenen Haekchens. Antippen oeffnet einen Bestaetigungs-Dialog und entfernt den POI bei Bestaetigung.

### Button-Logik (CompactPOICard)
- `isAdded == false` + `onAdd != null` → Gruenes Plus-Icon, Tap → `onAdd`
- `isAdded == true` + `onRemove == null` → Gruenes Haekchen (kein Tap)
- `isAdded == true` + `onRemove != null` → Rotes Minus-Icon, Tap → `onRemove`

### Geaenderte Dateien

**`lib/features/trip/providers/corridor_browser_provider.dart`**
- Neue Methode `markAsRemoved(poiId)`: Entfernt poiId aus `addedPOIIds` Set

**`lib/features/map/widgets/compact_poi_card.dart`**
- Neuer Parameter `VoidCallback? onRemove`
- Button-Icon: Minus (rot) wenn `isAdded && onRemove != null`
- Button-Hintergrund: `errorContainer.withOpacity(0.3)` fuer Remove-State

**`lib/features/random_trip/providers/random_trip_provider.dart`**
- Neue Methode `removePOIFromDay(poiId, dayNumber)`:
  - Validiert: mindestens 1 Stop pro Tag muss verbleiben
  - Delegiert an `_tripGenerator.removePOI()`
  - Synchronisiert TripStateProvider
  - Persistiert aktiven Trip bei Multi-Day
  - Gibt `bool` zurueck (Erfolg/Misserfolg)

**`lib/features/trip/widgets/corridor_browser_sheet.dart`**
- `CorridorBrowserContent`, `CorridorBrowserSheet`, `show()`: Neuer Parameter `Future<bool> Function(POI)? onRemovePOI`
- Neue Methode `_removePOI(POI)`:
  - Bestaetigungs-AlertDialog ("Stop entfernen?")
  - Bei Erfolg: `markAsRemoved()` + SnackBar
  - Bei Misserfolg: "Mindestens 1 Stop pro Tag erforderlich" SnackBar

**`lib/features/trip/widgets/day_editor_overlay.dart`**
- `CorridorBrowserContent` Aufruf um `onRemovePOI` erweitert:
  ```dart
  onRemovePOI: (poi) async {
    final success = await ref
        .read(randomTripNotifierProvider.notifier)
        .removePOIFromDay(poi.id, selectedDay);
    return success;
  },
  ```

---

## Betroffene Dateien (Zusammenfassung)

| Datei | Aenderung |
|-------|-----------|
| `lib/features/ai/providers/ai_trip_advisor_provider.dart` | AISuggestion erweitert, loadAndRankIndoorAlternatives(), GPT-Ranking + Fallback |
| `lib/features/trip/widgets/day_editor_overlay.dart` | _AIRecommendedPOICard, _AISuggestionsSection Umbau, onRemovePOI, Banner-Callback |
| `lib/features/trip/widgets/corridor_browser_sheet.dart` | onRemovePOI Parameter + _removePOI() Handler |
| `lib/features/trip/providers/corridor_browser_provider.dart` | markAsRemoved() |
| `lib/features/map/widgets/compact_poi_card.dart` | onRemove Callback + Minus-Icon |
| `lib/features/random_trip/providers/random_trip_provider.dart` | removePOIFromDay() |

---

## Technische Details

### GPT-4o Prompt-Struktur
```
Wetter Tag 2: bad (8°/14°, 80% Regen)
Aktuelle Stops: Schloss Neuschwanstein (castle, outdoor), Marienbruecke (viewpoint, outdoor)
Outdoor-Stops die ersetzt werden koennten: Schloss Neuschwanstein (de-123), Marienbruecke (de-456)
Indoor-Alternativen: Deutsches Museum (museum, 12.3km Umweg, Score: 85), ...

Waehle die besten 5 Indoor-Alternativen. Antworte als JSON Array:
[{"name": "...", "action": "add|swap", "targetPOIId": "...", "reasoning": "1 Satz", "score": 0.0-1.0}]
```

### Fallback-Verhalten
- Backend erreichbar → GPT-4o rankt und begruendet
- Backend nicht erreichbar → Regelbasiert: Score desc, Umweg asc, Top 5
- Keine Indoor-POIs im Korridor → Fehlermeldung

### Validierung
- POI-Entfernen: Min 1 Stop pro Tag, Bestaetigungs-Dialog, SnackBar-Feedback
- AI-Empfehlungen: Max 15 Kandidaten an GPT, Max 5 Ergebnisse, JSON-Parsing mit Error-Handling
- flutter analyze: Keine neuen Fehler
