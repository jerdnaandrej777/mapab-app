# Changelog v1.7.2 - AI-Chat mit standortbasierten POI-Vorschlägen

**Datum:** 2026-01-29

## Neue Features

### AI-Chat Standort-Integration

Der AI-Assistent schlägt jetzt POIs basierend auf dem aktuellen Standort des Benutzers vor.

#### 1. Automatisches GPS-Laden

- GPS-Standort wird beim Öffnen des Chats automatisch geladen
- Reverse Geocoding zeigt Ortsname (z.B. "München")
- GPS-Dialog bei deaktivierten Ortungsdiensten

#### 2. Location-Header mit Radius-Einstellung

- Standort-Anzeige im Chat-Header: `📍 München [30 km]`
- Radius-Slider (10-100 km) über Settings-Button
- Quick-Select Buttons: 15, 30, 50, 100 km

#### 3. Neue Suggestion Chips

- `📍 POIs in meiner Nähe` - Alle POIs im Radius
- `🏰 Sehenswürdigkeiten` - Museen, Schlösser, Denkmäler
- `🌲 Natur & Parks` - Natur, Parks, Seen
- `🍽️ Restaurants` - Restaurants und Cafés

#### 4. Standortbasierte POI-Suche

- Keyword-Erkennung für Anfragen wie "Was gibt es hier zu sehen?"
- Automatische Kategorien-Extraktion aus Anfrage-Text
- POIs nach Distanz sortiert

#### 5. Anklickbare POI-Karten

- POI-Karten mit Bild, Name, Beschreibung und Distanz
- Tap öffnet POI-Details
- Automatisches Enrichment für Bilder
- "Alle X POIs anzeigen" Button bei >5 Ergebnissen

#### 6. TripContext-Erweiterung

- Standort wird an Backend gesendet (für zukünftige AI-Verbesserungen)
- Neue Felder: `userLatitude`, `userLongitude`, `userLocationName`

## Geänderte Dateien

| Datei | Änderung |
|-------|----------|
| `lib/features/ai_assistant/chat_screen.dart` | GPS-Integration, POI-Suche, POI-Karten, Radius-Slider, Location-Header |
| `lib/data/services/ai_service.dart` | TripContext um Standort-Felder erweitert |

## Kategorien-Mapping

| Benutzer-Anfrage | POI-Kategorien |
|------------------|----------------|
| "Sehenswürdigkeiten" | `museum`, `monument`, `castle`, `viewpoint`, `unesco` |
| "Natur", "Parks" | `nature`, `park`, `lake`, `waterfall` |
| "Restaurants", "Essen" | `restaurant`, `cafe` |
| "Hotels" | `hotel` |
| Unspezifisch | Alle Kategorien |

## UI-Layout

```
┌─────────────────────────────────────┐
│ AI-Assistent                    [←] │  AppBar
├─────────────────────────────────────┤
│ 📍 München          [30 km] [⚙️]   │  Location Header
├─────────────────────────────────────┤
│                                     │
│ [Chat-Nachrichten]                  │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ 🏰 Schloss Nymphenburg          │ │  POI-Karte
│ │    Barockschloss · 5.2 km    → │ │
│ └─────────────────────────────────┘ │
│                                     │
├─────────────────────────────────────┤
│ [📍 POIs] [🏰 Sehens.] [🌲 Natur]  │  Suggestion Chips
├─────────────────────────────────────┤
│ [Nachricht eingeben...]         [→] │  Input
└─────────────────────────────────────┘
```

## Technische Details

### GPS-Pattern (aus map_screen.dart wiederverwendet)

```dart
Future<void> _initializeLocation() async {
  // 1. GPS-Status prüfen
  final serviceEnabled = await Geolocator.isLocationServiceEnabled();

  // 2. Berechtigung prüfen/anfordern
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }

  // 3. Position abrufen
  final position = await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.medium,
    timeLimit: const Duration(seconds: 10),
  );

  // 4. Reverse Geocoding
  final result = await geocodingRepo.reverseGeocode(location);
}
```

### POI-Suche

```dart
final pois = await poiRepo.loadPOIsInRadius(
  center: _currentLocation!,
  radiusKm: _searchRadius,  // 10-100km
  categoryFilter: categories,  // z.B. ['museum', 'castle']
);
```

## Log-Prefixes

| Prefix | Komponente |
|--------|------------|
| `[AI-Chat]` | Standort-Laden, POI-Suche, Fehler |

## Bekannte Einschränkungen

- POI-Suche funktioniert nur mit aktivem GPS oder nach manuellem Standort-Setzen
- Backend erhält Standort, nutzt ihn aber noch nicht für AI-Empfehlungen (zukünftige Verbesserung)
