# Changelog v1.2.4

**Release-Datum:** 21. Januar 2026

## 🎲 Neues Feature: AI-Trip ohne Ziel

### Zusammenfassung

Der AI-Trip-Dialog im ChatScreen wurde erweitert: Das Ziel-Feld ist jetzt optional. Wenn kein Ziel angegeben wird, generiert die App automatisch eine zufällige Route basierend auf den gewählten Interessen und navigiert direkt zum Trip-Screen.

### Hybrid-Modus

| Start | Ziel | Ergebnis |
|-------|------|----------|
| leer | leer | GPS-Abfrage → Random Route → Trip-Screen |
| "Berlin" | leer | Geocode Berlin → Random Route → Trip-Screen |
| beliebig | "Prag" | AI-Text-Plan im Chat (wie bisher) |

---

## Änderungen

### `lib/features/ai_assistant/chat_screen.dart`

#### Neue Imports
```dart
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/categories.dart';
import '../../data/repositories/geocoding_repo.dart';
import '../../data/repositories/trip_generator_repo.dart';
import '../../features/trip/providers/trip_state_provider.dart';
```

#### Geänderte Dialog-Labels
```dart
// Ziel
labelText: 'Ziel (optional)'
hintText: 'Leer = Zufällige Route um Startpunkt'

// Start
labelText: 'Startpunkt (optional)'
hintText: 'Leer = GPS-Standort verwenden'
```

#### Neue Methode: `_getLocationIfNeeded()`
- Geocoding für manuelle Eingabe
- GPS-Standort bei leerem Feld
- Reverse Geocoding für Adresse
- Berechtigungen automatisch anfordern

#### Neue Methode: `_mapInterestsToCategories()`
```dart
'Kultur' → ['museum', 'monument', 'unesco']
'Natur' → ['nature', 'park', 'lake', 'viewpoint']
'Geschichte' → ['castle', 'church', 'monument']
'Essen' → ['restaurant']
'Nightlife' → ['city']
'Shopping' → ['city']
'Sport' → ['activity']
```

#### Neue Methode: `_generateRandomTripFromLocation()`
- Interessen → Kategorien mappen
- TripGenerator aufrufen
- Erfolgsmeldung im Chat anzeigen
- Route an TripStateProvider übergeben
- Automatisch zu `/trip` navigieren

#### Geänderte Validierungs-Logik
```dart
// Vorher: Ziel war Pflichtfeld
if (destinationController.text.trim().isEmpty) {
  // Fehler
}

// Nachher: Hybrid-Logik
if (destination.isNotEmpty) {
  // AI-Text-Plan (wie bisher)
  _generateTrip(...);
} else {
  // Random Route
  final location = await _getLocationIfNeeded(startText);
  await _generateRandomTripFromLocation(location, interests, days);
}
```

---

## Statistiken

| Metrik | Wert |
|--------|------|
| Geänderte Dateien | 1 |
| Neue Zeilen | +264 |
| Gelöschte Zeilen | -19 |
| Neue Methoden | 3 |

---

## Test-Szenarien

### Test 1: Beide Felder leer
1. AI-Assistent öffnen
2. "🤖 AI-Trip generieren" klicken
3. Alle Felder leer lassen
4. Nur Interessen wählen (z.B. Natur, Geschichte)
5. "Generieren" klicken
6. **Erwartung:** GPS-Dialog → Erlauben → Trip-Screen mit Route

### Test 2: Nur Start ausgefüllt
1. Start: "Berlin"
2. Ziel: leer
3. Interessen: Kultur
4. **Erwartung:** Random Route um Berlin → Trip-Screen

### Test 3: Beide ausgefüllt (altes Verhalten)
1. Start: "München"
2. Ziel: "Prag"
3. **Erwartung:** AI-Text-Plan im Chat (keine Navigation)

### Test 4: GPS verweigert
1. Beide Felder leer
2. GPS-Berechtigung verweigern
3. **Erwartung:** Fehlermeldung "Bitte Standort eingeben oder GPS aktivieren"

---

## Migration

Keine Migration erforderlich. Die Änderung ist abwärtskompatibel:
- Bestehendes Verhalten (Ziel ausgefüllt) bleibt identisch
- Neues Verhalten nur bei leerem Ziel-Feld
