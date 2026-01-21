# CLAUDE.md - MapAB Flutter App

Diese Datei bietet Orientierung für Claude Code bei der Arbeit mit diesem Flutter-Projekt.

## Projektübersicht

Flutter-basierte mobile App für interaktive Routenplanung und POI-Entdeckung in Europa.
Basiert auf dem Konzept der MapAB Web-App (`../Mobi/`).

## Tech Stack

- **Flutter**: 3.2+
- **State Management**: Riverpod 2.x mit Code-Generierung
- **Routing**: GoRouter
- **Karte**: flutter_map mit MapLibre
- **HTTP**: Dio mit Cache
- **Lokale Daten**: Hive
- **Models**: Freezed für immutable Klassen

## Entwicklung

```bash
# Dependencies installieren
flutter pub get

# Code-Generierung (nach Model-Änderungen)
flutter pub run build_runner build --delete-conflicting-outputs

# Watch-Mode für kontinuierliche Generierung
flutter pub run build_runner watch

# App starten
flutter run

# Release Build
flutter build apk
```

## Architektur

### Schichten

```
┌─────────────────────────────────────┐
│           UI (features/)            │  Screens, Widgets
├─────────────────────────────────────┤
│         Providers (Riverpod)        │  State Management
├─────────────────────────────────────┤
│      Services & Repositories        │  Business Logic
├─────────────────────────────────────┤
│            Models (data/)           │  Datenstrukturen
├─────────────────────────────────────┤
│          External APIs              │  Nominatim, OSRM, etc.
└─────────────────────────────────────┘
```

### Wichtige Dateien

| Datei | Beschreibung |
|-------|--------------|
| `lib/data/repositories/poi_repo.dart` | POI-Laden (3-Schichten: Curated → Wiki → Overpass) |
| `lib/data/repositories/weather_repo.dart` | Open-Meteo Wetter-API |
| `lib/data/services/hotel_service.dart` | Hotel-Suche mit Amenities & Booking.com |
| `lib/data/services/ai_service.dart` | OpenAI Integration |
| `lib/features/map/providers/map_controller_provider.dart` | Globaler MapController |
| `lib/features/map/providers/weather_provider.dart` | Routen-Wetter State |
| `lib/features/map/widgets/weather_bar.dart` | Wetter-Anzeige Widget |
| `lib/core/utils/scoring_utils.dart` | POI-Scoring mit Wetter-Anpassung |
| `assets/data/curated_pois.json` | 527 kuratierte POIs |

## API-Abhängigkeiten

| API | Zweck | Auth |
|-----|-------|------|
| Nominatim | Geocoding | - |
| OSRM | Fast Routing | - |
| OpenRouteService | Scenic Routing | API-Key |
| Overpass | POIs & Hotels | - |
| Wikipedia DE | Geosearch | - |
| Open-Meteo | Wetter | - |
| OpenAI | AI-Chat | API-Key |

## POI-Datenstruktur

### Kuratierte POIs (JSON)
```json
{
  "id": "de-1",
  "n": "Brandenburger Tor",
  "lat": 52.5163,
  "lng": 13.3777,
  "c": "monument",
  "r": 98,
  "tags": ["monument", "berlin"],
  "curated": true
}
```

Mapping:
- `n` = name
- `c` = category
- `r` = score (0-100)

### POI Model (Dart)
```dart
POI(
  id: 'de-1',
  name: 'Brandenburger Tor',
  latitude: 52.5163,
  longitude: 13.3777,
  categoryId: 'monument',
  score: 98,
  // Berechnete Felder:
  routePosition: 0.45,      // 0 = Start, 1 = Ende
  detourKm: 12.0,
  detourMinutes: 15,
  effectiveScore: 87.0,     // Nach Umweg-Berechnung
)
```

## POI-Kategorien

### Indoor-Kategorien (für Wetter-Filter)
- `museum`
- `church`
- `restaurant`
- `hotel`

### Outdoor-Kategorien
- `castle`, `nature`, `viewpoint`, `lake`, `coast`, `park`, `city`, `activity`, `monument`, `attraction`

## Wetter-Logik

### WeatherCondition Enum
- `good` - Klar, sonnig
- `mixed` - Wechselhaft
- `bad` - Regen, Schnee
- `danger` - Gewitter, Sturm
- `unknown` - Keine Daten

### Scoring-Anpassung
```dart
// Bei schlechtem Wetter (bad/danger):
// Indoor-POIs: Score + 15
// Outdoor-POIs: Score - 10

// Bei gutem Wetter:
// Outdoor-POIs: Score + 5
```

## Hotel-Service

### HotelSuggestion
```dart
HotelSuggestion(
  name: 'Hotel Beispiel',
  type: HotelType.hotel,
  stars: 4,
  amenities: HotelAmenities(
    wifi: true,
    parking: true,
    breakfast: true,
  ),
  checkInTime: '14:00',
  checkOutTime: '11:00',
)
```

### Booking.com URL
```dart
hotel.getBookingUrl(checkIn: DateTime.now());
// => https://www.booking.com/searchresults.html?ss=Hotel+Name&checkin=2026-01-21&...
```

## Riverpod Provider

### Wichtige Provider
```dart
// POI Repository
final poiRepositoryProvider

// Weather Repository
final weatherRepositoryProvider

// Route Weather State
final routeWeatherNotifierProvider

// Indoor-Only Filter
final indoorOnlyFilterProvider

// Map Controller
final mapControllerProvider

// Hotel Service
final hotelServiceProvider

// AI Service
final aiServiceProvider
```

## Konventionen

- **Sprache**: Deutsche UI-Labels, englischer Code
- **IDs**: `{land}-{nummer}` (z.B. `de-1`)
- **Dateien**: snake_case für Dart-Dateien
- **Klassen**: PascalCase
- **Provider**: camelCase mit `Provider` Suffix

## Debugging

### Debug-Logging aktiviert für:
- `[POI]` - POI-Laden
- `[Weather]` - Wetter-Laden
- `[AI]` - AI-Anfragen (inkl. API-Key Präfix)
- `[GPS]` - GPS-Funktionen

### AI-Fehler prüfen
Bei AI-Problemen zeigt das Logging:
- API-Key Präfix (erste 20 Zeichen)
- HTTP Status Code
- Detaillierte Fehlermeldung

## Android-Berechtigungen

In `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

## Bekannte Einschränkungen

1. **Wikipedia API**: 10km Radius-Limit pro Anfrage
2. **Overpass API**: Rate-Limiting, kann langsam sein
3. **OpenAI**: Benötigt aktives Guthaben
4. **GPS**: Nur mit HTTPS/Release Build zuverlässig

## Vergleich mit Web-Version (Mobi/)

| Feature | Web (Mobi/) | Flutter |
|---------|-------------|---------|
| POI-Laden | Gleiche 3-Schichten | Gleiche 3-Schichten |
| Wetter | Open-Meteo + Polling | Open-Meteo (manuell) |
| Hotels | Overpass + OSM Tags | Overpass + OSM Tags |
| AI | OpenAI GPT | OpenAI GPT |
| Karte | MapLibre GL JS | flutter_map |
| State | Vanilla JS | Riverpod |
