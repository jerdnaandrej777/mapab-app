# CHANGELOG v1.9.9 - Smart AI-Empfehlungen & 700km-Tageslimit Fix

**Datum:** 3. Februar 2026
**Build:** 1.9.9+156

## Ueberblick

Zwei Aenderungen: (1) AI-Empfehlungen erweitert von "nur Indoor bei Regen" zu Smart-Empfehlungen mit Must-See-POIs aller Kategorien, Wetter-Gewichtung und Vorschau-Marker auf der MiniMap. (2) 700km-Tageslimit wird jetzt hart durchgesetzt statt nur gewarnt.

---

## Feature: Smart AI-Empfehlungen (alle Kategorien + Wetter-Gewichtung)

### Problem
AI-Empfehlungen wurden bisher NUR bei schlechtem Wetter angezeigt und filterten ausschliesslich auf wetter-resiliente Indoor-Kategorien (Museum, Kirche, Restaurant, Hotel, Burg, Aktivitaet). Must-See-Attraktionen und Outdoor-POIs wurden ignoriert. Empfohlene POIs waren nicht auf der Vorschau-Map sichtbar.

### Loesung
`loadAndRankIndoorAlternatives()` wurde zu `loadSmartRecommendations()` erweitert:
- Laedt ALLE Kategorien aus dem Korridor (nicht nur Indoor)
- Smart-Scoring: Must-See-Bonus (+30), Indoor-Bonus bei Regen (+20), Umweg-Penalty
- GPT-4o Prompt beruecksichtigt Wetter + Must-See + Kategorie-Vielfalt
- Neuer "POI-Empfehlungen laden" Button — wetterunabhaengig verfuegbar
- Empfohlene POIs erscheinen als halbtransparente Stern-Marker auf der MiniMap

### Smart-Score Berechnung
```
Score = POI-Basis-Score
      + (isMustSee ? 30 : 0)
      + (isBadWeather && isWeatherResilient ? 20 : 0)
      - (detourKm * 0.5)
```

### Geaenderte Dateien

**`lib/features/ai/providers/ai_trip_advisor_provider.dart`**
- `loadAndRankIndoorAlternatives()` → `loadSmartRecommendations()` umbenannt/erweitert
- Filter: `isWeatherResilient` entfernt, stattdessen `score > 30` fuer alle Kategorien
- Neue Methode `_calculateSmartScore()`: Must-See + Wetter + Umweg-Gewichtung
- GPT-Prompt erweitert: Must-See-Markierung, indoor/outdoor Labels, Wetter-Kontext
- `_rankRuleBased()` nutzt `_calculateSmartScore()` mit `relevanceScore`

**`lib/features/trip/widgets/day_editor_overlay.dart`**
- `_AISuggestionsSection` bekommt `onLoadRecommendations` Callback
- Bei leeren Suggestions: "POI-Empfehlungen laden" Button (wetterunabhaengig)
- Loading-Text: "Suche POI-Empfehlungen..." statt "Suche Indoor-Alternativen..."
- Banner-Callback: `loadSmartRecommendations()` statt `loadAndRankIndoorAlternatives()`
- MiniMap erhaelt `recommendedPOIs` aus advisorState

**`lib/features/trip/widgets/day_mini_map.dart`**
- Neuer Parameter `List<POI> recommendedPOIs` (Default: const [])
- Empfohlene POIs als halbtransparente Stern-Marker (tertiary Color, auto_awesome Icon)
- Bounds-Fitting beruecksichtigt empfohlene POIs fuer korrekten Kartenausschnitt

---

## Bug-Fix: 700km-Tageslimit wird jetzt hart durchgesetzt

### Problem
Post-Validierungen in `trip_generator_repo.dart` loggten nur Warnings bei >700km Display-Distanz pro Tag, verhinderten aber nichts:
- `_addPOIToDay()`: Warning statt Ablehnung
- `generateEuroTrip()`: Warning statt Re-Split

### Loesung

**`_addPOIToDay()` — Ablehnung statt Warning:**
POI wird nicht hinzugefuegt wenn die Display-Distanz des Tages >700km ueberschreiten wuerde. Wirft `TripGenerationException`, die im Provider als benutzerfreundliche Fehlermeldung angezeigt wird.

**`generateEuroTrip()` — Re-Split bei Ueberschreitung:**
Nach `planDays()` wird jeder Tag geprueft. Falls ein Tag >700km Display-Distanz hat, wird `planDays()` mit einem zusaetzlichen Tag aufgerufen (Re-Split).

### Geaenderte Dateien

**`lib/data/repositories/trip_generator_repo.dart`**
- `_addPOIToDay()`: Post-Validierung wirft `TripGenerationException` statt Warning
- `generateEuroTrip()`: `final actualDays` → `var actualDays`, Re-Split-Logik nach planDays()

**`lib/features/random_trip/providers/random_trip_provider.dart`**
- `addPOIToDay()` catch: Benutzerfreundliche Fehlermeldung bei `TripGenerationException` ("Tageslimit (700km) wuerde ueberschritten")

---

## Betroffene Dateien (Zusammenfassung)

| Datei | Aenderung |
|-------|-----------|
| `lib/features/ai/providers/ai_trip_advisor_provider.dart` | loadSmartRecommendations(), _calculateSmartScore(), erweiterter GPT-Prompt |
| `lib/features/trip/widgets/day_editor_overlay.dart` | "Empfehlungen laden" Button, MiniMap recommendedPOIs, Banner-Callback |
| `lib/features/trip/widgets/day_mini_map.dart` | recommendedPOIs Parameter, halbtransparente Stern-Marker |
| `lib/data/repositories/trip_generator_repo.dart` | _addPOIToDay() Exception, generateEuroTrip() Re-Split |
| `lib/features/random_trip/providers/random_trip_provider.dart` | 700km-Fehlermeldung |

---

## Technische Details

### GPT-4o Prompt (erweitert)
```
Wetter Tag 2: bad (8°/14°, 80% Regen)
Aktuelle Stops: Schloss Neuschwanstein (castle, outdoor), Marienbruecke (viewpoint, outdoor)
Outdoor-Stops die ersetzt werden koennten: Schloss Neuschwanstein (de-123), Marienbruecke (de-456)
Kandidaten-POIs entlang der Route: Deutsches Museum (museum, indoor, MUST-SEE, 12.3km Umweg, Score: 85), ...

Aufgabe: Waehle die besten 5 POIs als Empfehlungen fuer diesen Reisetag.
Beruecksichtige: Wetter (Indoor bei Regen bevorzugen), Must-See-Attraktionen, Kategorie-Vielfalt, Umweg.
Bei schlechtem Wetter: Schlage Indoor-Alternativen vor und nutze "swap" um Outdoor-Stops zu ersetzen.
Antworte als JSON Array:
[{"name": "...", "action": "add|swap", "targetPOIId": "...", "reasoning": "1 Satz", "score": 0.0-1.0}]
```

### 700km-Limit Enforcement
- `_addPOIToDay()`: `trip.getDistanceForDay(targetDay) > 700km` → TripGenerationException
- `generateEuroTrip()`: Post-planDays() Check → Re-Split mit actualDays + 1
- Benutzer-Feedback: "Tageslimit (700km) wuerde ueberschritten"

### Validierung
- flutter analyze: Keine neuen Fehler (351 pre-existing, alle withOpacity Deprecation Warnings)
