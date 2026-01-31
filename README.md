# MapAB Flutter App

Cross-Platform Reiseplanungs-App für iOS, Android und Desktop.

## Features

✅ **14 Haupt-Features implementiert:**

- 🌙 **Dark Mode mit Auto-Sunset** - Drei Theme-Modi (Light, Dark, OLED) mit automatischem Dark Mode bei Sonnenuntergang
- 🔔 **Push-Benachrichtigungen** - 4 Channels für Wetter, Trips, POIs und allgemeine Infos
- 🚗 **Echtzeit-Verkehrsdaten** - TomTom Integration mit Live-Traffic und Stauinformationen
- 📤 **Trip-Sharing & QR-Codes** - Teile Trips via Deep Links, Web-Links oder QR-Code
- 🤖 **KI-Personalisierung** - OpenAI GPT-4o für personalisierte Empfehlungen und Chat
- 💰 **Budget-Tracker** - Automatische Kostenschätzung mit 7 Kategorien und Tankerkönig-API
- 📈 **Höhenprofil für Bike/Wandern** - 4 Routing-Modi mit Schwierigkeitsgraden
- 📔 **Reisetagebuch mit Fotos** - Dokumentiere deine Trips mit Fotos, Ratings und Moods
- ♿ **Barrierefreiheit** - Filter für rollstuhlgerechte POIs und stufenfreie Routen
- 🏆 **Statistiken & Gamification** - XP-Level-System mit 21 Achievements
- 🎤 **Sprachsteuerung** - 8 Voice-Commands für Hands-free Bedienung
- 🍽️ **Services** - Restaurant, Tankstellen, E-Ladestationen entlang der Route
- 📱 **Emulator-Optimierungen** - GPS & Geocoding Fallbacks für Testing
- 👤 **Account-System** - Local-First Account Management mit Multi-Profilen und Gamification

### Kern-Funktionen (aus PWA)
- **Routenplanung**: Start/Ziel mit Autocomplete, Fast/Scenic Toggle
- **POI-Entdeckung**: 3-Schichten-System (527 kuratiert + Wikipedia + OSM)
- **Trip-Planung**: Drag-and-Drop, Export nach Google Maps
- **Wetter-Integration**: 5 Punkte entlang Route mit Vorhersage
- **Hotel-Suche**: OSM-basiert mit Booking.com Links

## Installation

### Voraussetzungen
- Flutter SDK 3.24.5+
- Dart 3.0+
- Android Studio / Xcode (für native Builds)
- Git

### Setup

```bash
# Dependencies installieren
flutter pub get

# Code-Generierung ausführen
flutter pub run build_runner build --delete-conflicting-outputs

# App starten (Android)
flutter run -d android

# App starten (iOS)
flutter run -d ios

# App starten (Web)
flutter run -d chrome
```

### API-Keys konfigurieren

Erstelle die Datei `lib/core/constants/api_keys.dart`:

```dart
class ApiKeys {
  // Required für KI-Features
  static const openAiApiKey = 'sk-...';         // OpenAI

  // Optional (Features funktionieren mit Fallbacks)
  static const tomtomApiKey = 'YOUR_KEY';       // TomTom Traffic API
  static const tankerkoenigApiKey = 'YOUR_KEY'; // Benzinpreise (nur DE)
  static const openChargeMapApiKey = 'YOUR_KEY'; // E-Ladestationen
}
```

**API-Keys erhalten:**
- **OpenAI:** https://platform.openai.com/api-keys
- **TomTom:** https://developer.tomtom.com/
- **Tankerkönig:** https://creativecommons.tankerkoenig.de/
- **OpenChargeMap:** https://openchargemap.org/site/develop/api

**Hinweis:** Die App funktioniert auch ohne API-Keys mit simulierten Daten.

## Architektur

```
lib/
├── core/                      # Theme, Constants, Utils
├── data/                      # Models, Providers, Services
├── features/                  # Feature-Module (Map, POI, Trip, etc.)
└── app.dart                   # Root Widget
```

### Tech-Stack

| Technologie | Version | Zweck |
|-------------|---------|-------|
| Flutter SDK | 3.24.5 | UI Framework |
| Riverpod | 2.4.9 | State Management |
| GoRouter | 13.0.0 | Navigation |
| Hive | 2.2.3 | Local Storage |
| Freezed | 2.4.6 | Immutable Models |
| flutter_map | 6.1.0 | Kartenansicht |

## Dokumentation

📖 **[Komplette Feature-Dokumentation](docs/FLUTTER-APP-DOKUMENTATION.md)**

Die vollständige Dokumentation enthält:
- Detaillierte Feature-Beschreibungen
- Code-Beispiele
- API-Integration
- State Management
- Testing Guide

## Build Commands

```bash
# Debug Build (Android)
flutter build apk --debug

# Release Build (Android)
flutter build apk --release

# Release Build (iOS)
flutter build ipa --release

# Web Build
flutter build web --release

# Windows Build
flutter build windows --release
```

## Testing

```bash
# Unit Tests
flutter test test/unit/

# Widget Tests
flutter test test/widget/

# Integration Tests
flutter test integration_test/

# Alle Tests
flutter test
```

## Recent Updates (Januar 2026)

### v1.7.14 - GPS-Standort-Synchronisation (31. Januar 2026)
- **Automatische Standort-Synchronisation** - GPS-Standort wird automatisch zwischen Schnell & AI Trip Modi übertragen
- **Nahtloser Modus-Wechsel** - GPS einmal klicken, in beiden Modi verfügbar
- **Intelligente Logik** - Synchronisation nur wenn Ziel-Modus keinen Startpunkt hat
- **UX-Verbesserung** - Kein doppeltes Klicken mehr notwendig

### v1.7.12 - Wetter-Marker auf der Route (30. Januar 2026)
- **Wetter-Marker auf Route** - 5 Wetter-Icons entlang der berechneten Route mit Temperatur
- **Farbcodierte Marker** - Grün/Gelb/Orange/Rot je nach Wetterlage
- **Tap-Details** - Bottom Sheet mit Wind, Niederschlag, Empfehlung
- **Auto-Wetter-Laden** - Wetter bei Routenberechnung, AI Trip & gespeicherten Routen

### v1.7.10 - Routen speichern & laden
- **Route in Favoriten speichern** - AI Trips und normale Routen dauerhaft speichern
- **Gespeicherte Routen laden** - Aus Favoriten direkt auf Karte anzeigen

### v1.7.8 - AI Trip mit POI-Stops erweitern
- **POI-Stops zu AI-Route hinzufügen** - POI-Details & POI-Liste Integration
- **Route Starten Button** - Manuell zum Trip-Tab navigieren (statt Auto-Navigation)

### v1.7.7 - POI-Bildquellen optimiert
- **~95% Bild-Trefferquote** - OSM-Tags, EN-Wikipedia Fallback, Suchvarianten
- **Chat-Bilder** - POI-Karten im AI-Chat zeigen Bilder an

### v1.7.6 - Wetter-Integration erweitert
- **WeatherChip** - Kompakter Wetter-Anzeiger auf MapScreen
- **WeatherAlertBanner** - Proaktive Warnungen bei schlechtem Wetter
- **7-Tage-Vorhersage** - Vollständiges Wetter-Dashboard
- **AI Trip Wetter-Integration** - Wetter-basierte Kategorieauswahl

### v1.5.7 - Mehrtägige Euro Trips mit tagesweisem Google Maps Export
- **Automatische Tagesberechnung** - 600km = 1 Tag (max 14 Tage)
- **Max 9 POIs pro Tag** - Google Maps Waypoint-Limit automatisch beachtet
- **Tagesweiser Export** - Exportiere jeden Tag einzeln nach Google Maps
- **DayTabSelector** - Neue horizontale Tab-Leiste zur Tagesauswahl
- **Persistenz vorbereitet** - ActiveTripService für Trip-Fortsetzung

### v1.5.6 - Floating Buttons bei AI Trip ausblenden
- **Aufgeräumtere UI** - Einstellungen- und GPS-Button werden bei AI Trip ausgeblendet
- GPS-Standort kann direkt im AI Trip Panel gesetzt werden

### v1.5.5 - POI-Card Layout-Fix
- **Alle POIs sichtbar** - IntrinsicHeight Problem behoben
- Feste Card-Höhe (96px) für stabiles Layout

### v1.5.4 - GPS-Dialog
- **GPS-Dialog** - Fragt ob GPS-Einstellungen geöffnet werden sollen (statt München-Fallback)

### v1.5.0-v1.5.3 - AI Trip auf MapScreen
- **AI Trip direkt auf MapScreen** - Karte bleibt immer sichtbar
- **POI-Marker** - Nummerierte Icons mit Kategorie-Symbol
- **Auto-Zoom** - Route wird automatisch angezeigt
- **POI-Liste Bugfixes** - Race Condition und Filter-Probleme behoben

### v1.4.x - AI Trip Verbesserungen
- **Erweiterter Radius** - Tagesausflug bis 300 km, Euro Trip bis 5000 km
- **POI-Card Redesign** - Kompaktes horizontales Layout
- **POI-Bearbeitung** - Einzelne POIs löschen oder neu würfeln
- **Integrierter Trip-Planer** - AI Trip direkt im Trip-Screen

### Wichtig nach Code-Updates

Nach dem Pullen neuer Änderungen bitte ausführen:

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

Dies generiert die notwendigen Freezed-Dateien für das Account-System.

## Bekannte Probleme & Lösungen

### Android-Emulator

**✅ GPS funktioniert jetzt mit Fallback**
- **Verhalten:** App zeigt "München, Deutschland (Test-Standort)" wenn GPS nicht verfügbar
- **Standort:** München (48.1351, 11.5820)
- **Lösung:**
  - Automatischer Fallback in Random Trip integriert
  - Teste auf echtem Gerät für echte GPS-Features
  - Oder: Mock Location in Android Studio setzen (Extended Controls → Location)

**✅ Geocoding mit Offline-Fallback**
- **Verhalten:** "Kein Internet - Zeige lokale Vorschläge"
- **Lösung:**
  - App zeigt 15 deutsche Städte als Offline-Fallback
  - Teste auf echtem Gerät mit Internet für volle Funktionalität

### Web-Build

**Problem:** CORS-Fehler bei externen APIs
- **Symptom:** Karten-Tiles laden nicht, API-Anfragen blockiert
- **Lösung:**
  - Option 1: Proxy-Server verwenden (z.B. cors-anywhere)
  - Option 2: Backend-für-Frontend Pattern implementieren
  - Option 3: Nur native Builds verwenden

**Problem:** Karten-Tiles laden langsam
- **Lösung:** Package installieren:
  ```yaml
  dependencies:
    flutter_map_cancellable_tile_provider: ^1.0.0
  ```

### iOS-Build

**Problem:** App stürzt ab beim GPS-Zugriff
- **Ursache:** Fehlende Permissions in Info.plist
- **Lösung:**
  ```xml
  <key>NSLocationWhenInUseUsageDescription</key>
  <string>Wird für Routenplanung benötigt</string>
  ```

**Problem:** Build fails mit "Capabilities not configured"
- **Lösung:**
  - Xcode öffnen → Target → Signing & Capabilities
  - Hinzufügen: Location When In Use, Background Modes

## API-Abhängigkeiten

| API | Zweck | Auth | Fallback |
|-----|-------|------|----------|
| OpenAI | KI-Chat & Empfehlungen | API-Key | - |
| TomTom | Echtzeit-Verkehr | API-Key | Simuliert |
| Tankerkönig | Benzinpreise (DE) | API-Key | Simuliert |
| OpenChargeMap | E-Ladestationen | Optional | - |
| Overpass/OSM | POI Services | - | - |
| Open-Elevation | Höhendaten | - | OpenTopoData |
| Nominatim | Geocoding | - | Offline-Liste (15 Städte) |
| OSRM | Schnelle Routen | - | - |
| OpenRouteService | Scenic Routen | API-Key | - |
| Open-Meteo | Wetter | - | - |

## POI-Kategorien

| Kategorie | Icon | Indoor | Beispiele |
|-----------|------|--------|-----------|
| castle | 🏰 | Nein | Neuschwanstein, Hohenzollern |
| nature | 🌲 | Nein | Schwarzwald, Alpen |
| museum | 🏛️ | Ja | Deutsches Museum, Louvre |
| viewpoint | 🏔️ | Nein | Zugspitze, Eibsee |
| lake | 🏞️ | Nein | Bodensee, Königssee |
| coast | 🏖️ | Nein | Nordsee, Ostsee |
| park | 🌳 | Nein | Englischer Garten |
| city | 🏙️ | Nein | München, Berlin |
| unesco | 🌍 | Nein | Kölner Dom, Bamberg |
| church | ⛪ | Ja | Frauenkirche, Sagrada Familia |
| monument | 🗿 | Nein | Brandenburger Tor |
| attraction | 🎡 | Gemischt | Miniatur Wunderland |
| hotel | 🏨 | Ja | Booking.com Integration |
| restaurant | 🍽️ | Ja | OSM-basiert |

## Projektstruktur

```
mapab-app/
├── android/                    # Android-spezifische Configs
├── ios/                        # iOS-spezifische Configs
├── lib/
│   ├── core/
│   │   ├── theme/             # Dark Mode, Themes
│   │   ├── constants/         # API Keys, Endpoints
│   │   └── utils/             # Helper-Funktionen
│   ├── data/
│   │   ├── models/            # Freezed Data Models
│   │   │   └── user_account.dart  # Account-Model (NEU)
│   │   ├── providers/         # Riverpod Provider
│   │   │   └── account_provider.dart  # Account State (NEU)
│   │   ├── repositories/      # API Repositories
│   │   └── services/          # Business Logic
│   ├── features/
│   │   ├── account/           # Account-System (NEU)
│   │   │   ├── login_screen.dart
│   │   │   ├── profile_screen.dart
│   │   │   └── splash_screen.dart
│   │   ├── map/               # Kartenansicht
│   │   ├── search/            # Orts-Suche
│   │   ├── poi/               # POI-Listen
│   │   ├── trip/              # Trip-Planung
│   │   ├── ai_assistant/      # KI-Chat
│   │   ├── settings/          # Einstellungen
│   │   ├── sharing/           # Trip-Export & QR
│   │   ├── journal/           # Reisetagebuch (TODO)
│   │   └── statistics/        # Achievements (TODO)
│   ├── app.dart               # Root Widget
│   └── main.dart              # Entry Point
├── assets/
│   └── data/
│       └── curated_pois.json  # 527 POIs
├── test/                      # Tests
├── pubspec.yaml               # Dependencies
└── README.md                  # Diese Datei
```

## Entwicklung

### Code-Generierung

Nach Änderungen an Freezed/Riverpod-Klassen:

```bash
flutter pub run build_runner build --delete-conflicting-outputs

# Oder Watch-Mode:
flutter pub run build_runner watch
```

### Hot Reload / Hot Restart

- **r** - Hot Reload (schnell, behält State)
- **R** - Hot Restart (neu starten, verliert State)
- **q** - App beenden

### Debugging

```bash
# Mit Verbose Logging
flutter run --verbose

# Spezifisches Gerät
flutter run -d <device_id>

# Release Mode testen
flutter run --release
```

## Lizenz

MIT License

Copyright (c) 2026 MapAB Team

## Support & Kontakt

- **Issues:** https://github.com/yourusername/mapab-flutter/issues
- **Discussions:** https://github.com/yourusername/mapab-flutter/discussions
- **Email:** support@mapab.app
- **Website:** https://mapab.app

## Inspiration

Basiert auf den Konzepten einer JavaScript-basierten Progressive Web App für Reiseplanung.

---

**Version:** 1.7.14
**Release:** 31. Januar 2026
**Erstellt mit:** Flutter 💙
