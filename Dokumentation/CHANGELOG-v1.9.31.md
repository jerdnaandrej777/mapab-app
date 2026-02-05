# CHANGELOG v1.9.31 - Euro Trip Crash-Fix

**Release-Datum:** 5. Februar 2026
**Build:** 178

## Kritische Bugfixes

### 1. Unendliche Rekursion behoben (KRITISCH)
**Datei:** `lib/data/services/poi_enrichment_service.dart:112`

**Problem:** Die Funktion `_markAttemptedWithoutPhoto()` rief sich selbst endlos auf, was zu einem **StackOverflowError** und App-Crash fuehrte. Dies passierte bei jedem POI ohne Bild waehrend des Enrichments.

**Ursache:**
```dart
// VORHER (Bug):
static void _markAttemptedWithoutPhoto(String poiId) {
  if (_sessionAttemptedWithoutPhoto.length >= _maxSessionAttemptedEntries) {
    // ... cleanup ...
  }
  _markAttemptedWithoutPhoto(poiId);  // <- ENDLOSE REKURSION!
}
```

**Loesung:**
```dart
// NACHHER (Fix):
static void _markAttemptedWithoutPhoto(String poiId) {
  if (_sessionAttemptedWithoutPhoto.length >= _maxSessionAttemptedEntries) {
    // ... cleanup ...
  }
  _sessionAttemptedWithoutPhoto[poiId] = DateTime.now();  // <- Korrektes Setzen
}
```

**Impact:** Euro Trip stuerzte sofort ab, sobald ein POI ohne Bild enriched wurde.

---

### 2. Weather API Timeouts hinzugefuegt
**Datei:** `lib/data/repositories/weather_repo.dart`

**Problem:** API-Calls hatten keine expliziten Timeouts. Wenn Open-Meteo langsam oder nicht erreichbar war, fror die App ein.

**Loesung:**
| Methode | Timeout |
|---------|---------|
| `getCurrentWeather()` | 15 Sekunden |
| `getWeatherWithForecast()` | 15 Sekunden |
| `getWeatherAlongRoute()` | 30 Sekunden (global) |

**Code:**
```dart
final response = await _dio.get(...).timeout(
  const Duration(seconds: 15),
  onTimeout: () => throw WeatherException('Wetter-API Timeout nach 15s'),
);
```

---

### 3. Race Condition Guard verbessert
**Datei:** `lib/features/random_trip/providers/random_trip_provider.dart`

**Problem:** Bei schnellem Doppel-Klick auf "Ueberrasch mich!" konnten zwei Trip-Generierungen parallel laufen, was zu State-Corruption fuehrte.

**Loesung:** Atomares `_isGenerating` Lock als Instance-Variable:

```dart
class RandomTripNotifier extends _$RandomTripNotifier {
  bool _isGenerating = false;  // NEU: Atomares Lock

  Future<void> generateTrip() async {
    // Atomares Lock - pruefen UND setzen in einem Schritt
    if (_isGenerating) {
      debugPrint('[RandomTrip] Trip-Generierung laeuft bereits (Lock), ignoriere');
      return;
    }
    _isGenerating = true;

    try {
      // ... Trip-Generierung ...
    } finally {
      _isGenerating = false;  // Lock immer zuruecksetzen
    }
  }
}
```

**Zusaetzlich:** Alle fruehen `return`-Statements setzen jetzt `_isGenerating = false` vor dem Return.

---

## Betroffene Dateien

| Datei | Aenderung |
|-------|-----------|
| `lib/data/services/poi_enrichment_service.dart` | Rekursions-Bug behoben (Zeile 112) |
| `lib/data/repositories/weather_repo.dart` | 15s/30s Timeouts hinzugefuegt |
| `lib/features/random_trip/providers/random_trip_provider.dart` | Atomares `_isGenerating` Lock |
| `pubspec.yaml` | Version 1.9.31+178 |
| `QR-CODE-DOWNLOAD.html` | Aktualisiert |

---

## Symptome vor dem Fix

- Euro Trip: App stuerzt sofort nach "Ueberrasch mich!" ab
- App haengt endlos wenn Wetter-API nicht antwortet
- Doppel-Klick fuehrt zu korruptem Trip-State

## Verifikation

Nach dem Fix sollte:
1. Euro Trip ohne Absturz generiert werden
2. Bei Wetter-Timeout nach 15s eine Fehlermeldung erscheinen
3. Doppel-Klick auf "Ueberrasch mich!" ignoriert werden
