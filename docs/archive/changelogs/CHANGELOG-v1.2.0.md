# MapAB Flutter App - Changelog v1.2.0

**Release-Datum:** 21. Januar 2026
**Build:** Release APK (51.4 MB)
**Download:** [GitHub Release v1.2.0](https://github.com/jerdnaandrej777/mapab-app/releases/tag/v1.2.0)

---

## 🎉 Neue Features

### 1. Profil-Button & Account-System

**Datei:** `lib/features/map/map_screen.dart`

Die MapScreen hat jetzt eine transparente AppBar mit direktem Zugriff auf das Account-System:

```dart
appBar: AppBar(
  title: const Text('MapAB'),
  backgroundColor: Colors.white.withOpacity(0.9),
  elevation: 0,
  actions: [
    IconButton(
      icon: const Icon(Icons.person_outline),
      onPressed: () => context.push('/profile'),
      tooltip: 'Profil',
    ),
  ],
),
```

**ProfileScreen Features:**
- 👤 **Avatar & Username**
- 📊 **Level & XP System** (Level 1-50)
- 🏆 **21 Achievements** (Bronze, Silber, Gold)
- 📈 **Statistiken**:
  - Geplante Trips
  - Zurückgelegte Kilometer
  - Besuchte POIs
  - Gespeicherte Favoriten

**Provider:** `accountNotifierProvider`
**Storage:** Hive Box `account`

---

### 2. Favoriten-Button & Management

**Datei:** `lib/features/favorites/favorites_screen.dart`

Vollständiges Favoriten-Management mit Kategorisierung:

```dart
IconButton(
  icon: const Icon(Icons.favorite_border),
  onPressed: () => context.push('/favorites'),
  tooltip: 'Favoriten',
),
```

**FavoritesScreen Features:**
- 📑 **Tab-View**: Routen | POIs
- 🗂️ **Kategorien**: Eigene Listen erstellen
- ❤️ **Quick-Actions**: Favorit hinzufügen/entfernen
- 🗑️ **Batch-Delete**: Alle löschen Funktion

**POI-Favoriten:**
- Grid-Layout mit Bildern
- Kategorie-Icons
- Tap to View Details

**Routen-Favoriten:**
- Start → Ziel Anzeige
- Distanz, Dauer, Stops
- Tap to Load Route

**Provider:** `favoritesNotifierProvider`
**Storage:** Hive Box `favorites`

---

### 3. AI-Trip-Generator

**Datei:** `lib/features/ai_assistant/chat_screen.dart`

Vollautomatische Routenplanung via OpenAI GPT-4o:

**Suggestion Chip:**
```dart
'🤖 AI-Trip generieren'
```

**Dialog-Features:**
- 📍 **Ziel**: TextField (z.B. "Prag", "Amsterdam")
- 📅 **Tage**: Slider (1-7 Tage)
- 🎯 **Interessen**: FilterChips
  - Kultur
  - Natur
  - Geschichte
  - Essen
  - Nightlife
  - Shopping
  - Sport
- 🚗 **Startpunkt**: Optional (z.B. "München")

**Output-Format:**
```
🗺️ AI-Trip-Plan: 3 Tage in Prag

Tag 1: Historisches Zentrum
• Prager Burg (2h) - UNESCO Welterbe
• Karlsbrücke (1h) - Gotische Brücke mit Statuen
• Altstädter Ring (1.5h) - Astronomische Uhr

Tag 2: Kleinseite & Vyšehrad
• Petřín-Aussichtsturm (1h) - 360° Stadtblick
• Lennon-Mauer (0.5h) - Streetart & Graffiti
• Vyšehrad (1.5h) - Festung mit Friedhof

Tag 3: Jüdisches Viertel & Wenzelsplatz
• Jüdisches Museum (2h) - 6 Synagogen
• Altneu-Synagoge (1h) - Älteste Europas
• Wenzelsplatz (1h) - Historischer Boulevard

💡 Empfehlung: Prag Card für 3 Tage (€58)
🍽️ Restaurant-Tipps: U Fleků (seit 1499), Lokal
🏨 Hotel-Tipp: Zentrum, nähe Altstädter Ring

[Übernehmen-Button] 🚧 Coming Soon
```

**Service-Integration:**
```dart
final response = await aiService.generateTripPlan(
  destination: destination,
  days: days.round(),
  interests: interests,
  startLocation: startLocation.isEmpty ? null : startLocation,
);
```

**Error-Handling:**
- ⚠️ **No API-Key**: Demo-Modus mit Beispiel-Daten
- ⚠️ **API-Fehler**: Detaillierte Fehlermeldung
- ⌛ **Timeout**: Nach 30s automatischer Fallback

---

### 4. AI-Chat Erweiterungen

**Datei:** `lib/data/services/ai_service.dart`

Der AI-Chat nutzt jetzt echte OpenAI GPT-4o Anfragen:

**Features:**
- 💬 **Kontext-bewusst**: Aktuelle Route & Stops werden mitgesendet
- 📝 **Chat-Historie**: Vorige Nachrichten für Kontext
- 🎯 **POI-Empfehlungen**: "Was gibt es auf meiner Route?"
- 🗺️ **Route-Optimierung**: "Wo kann ich eine Pause machen?"
- 🍽️ **Restaurant-Tipps**: "Bestes Restaurant in [Stadt]"

**API-Konfiguration:**
```dart
// lib/core/constants/api_keys.dart
class ApiKeys {
  static const String openAiApiKey = 'sk-proj-...';
}
```

**Logging:**
```
[AI] 🤖 Sende Chat-Request: "Welche Sehenswürdigkeiten gibt es?"
[AI] ✅ Chat erfolgreich (284 Tokens)
[AI] ⚠️ API-Key nicht konfiguriert, Demo-Modus
```

---

## 🐛 Bugfixes

### 1. FavoritesScreen Route-Display

**Problem:** `trip.route.startName` und `trip.route.endName` existieren nicht im `AppRoute` Model.

**Fix:**
```dart
// VORHER (FALSCH):
'${trip.route.startName} → ${trip.route.endName}'

// NACHHER (KORREKT):
'${trip.route.startAddress} → ${trip.route.endAddress}'
```

**Datei:** `lib/features/favorites/favorites_screen.dart:177`

---

### 2. Favoriten-Route nicht registriert

**Problem:** FavoritesScreen existierte, aber Route in `app.dart` fehlte.

**Fix:**
```dart
// lib/app.dart:154-159
GoRoute(
  path: '/favorites',
  name: 'favorites',
  builder: (context, state) => const FavoritesScreen(),
),
```

---

## 🎨 UI-Verbesserungen

### 1. AppBar auf MapScreen

**Vorher:**
- Keine AppBar
- Nur FloatingActionButtons
- Kein direkter Zugriff auf Profil/Favoriten

**Nachher:**
```dart
Scaffold(
  extendBodyBehindAppBar: true, // AppBar überlagert Karte
  appBar: AppBar(
    title: const Text('MapAB'),
    backgroundColor: Colors.white.withOpacity(0.9),
    elevation: 0,
    actions: [
      IconButton(icon: Icon(Icons.favorite_border), ...),
      IconButton(icon: Icon(Icons.person_outline), ...),
    ],
  ),
  body: Stack(...),
)
```

**Styling:**
- Transparenter Hintergrund (90% Opacity)
- Keine Elevation (Schatten)
- Icons: `Icons.favorite_border`, `Icons.person_outline`
- Tooltip für Accessibility

---

### 2. Bottom Navigation Bar

**Tabs:**
1. 🗺️ **Karte** - MapScreen
2. 📍 **POIs** - POI-Liste
3. 🚗 **Trip** - Routenplanung
4. 🤖 **AI** - Chat-Assistent

**Styling:**
- Material Design 3
- Active State: Primary Color Background
- Icons: Outlined (inactive) → Filled (active)
- Animation: Smooth transitions

---

## 📦 Build & Deployment

### Build-Informationen

**Command:**
```bash
flutter build apk --release
```

**Output:**
- **Datei:** `build/app/outputs/flutter-apk/app-release.apk`
- **Größe:** 51.4 MB
- **Min SDK:** Android 21 (Lollipop)
- **Target SDK:** Android 34

**Tree-Shaking:**
```
Font asset "CupertinoIcons.ttf": 257628 → 848 bytes (99.7%)
Font asset "MaterialIcons-Regular.otf": 1645184 → 10884 bytes (99.3%)
```

**Build-Zeit:** ~145 Sekunden

---

### GitHub Release

**Tag:** `v1.2.0`
**URL:** https://github.com/jerdnaandrej777/mapab-app/releases/tag/v1.2.0

**Assets:**
- `app-release.apk` (51.4 MB)

**Download-Link:**
```
https://github.com/jerdnaandrej777/mapab-app/releases/download/v1.2.0/app-release.apk
```

**QR-Code:**
- Datei: `QR-CODE-DOWNLOAD.html`
- Zeigt direkt auf APK-Download
- Offline nutzbar (JavaScript QR-Generator)

---

## 🔧 Code-Generierung

Nach den Änderungen wurde `build_runner` ausgeführt:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

**Output:**
- 191 neue Outputs generiert
- 695 Actions insgesamt
- Warnung: `json_annotation` Version (nicht kritisch)

**Generierte Dateien:**
- `*.g.dart` - JSON Serialization
- `*.freezed.dart` - Immutable Models
- Provider-Code für Riverpod

---

## 📝 Commits

### 1. feat: Profil, Favoriten & AI-Trip-Generator
```
- MapScreen: AppBar mit Profil + Favoriten Buttons
- FavoritesScreen: Route registriert, Bugfix startAddress/endAddress
- AI-Chat: Trip-Generator Dialog mit OpenAI Integration
- Features: Vollständiger Zugriff auf Account-System und Favoriten-Management

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
```

**Commit:** `e7d21a6`

---

### 2. docs: Update QR-Code auf v1.2.0
```
- QR-Code-Download.html aktualisiert
- Version, Features, APK-Name angepasst
```

**Commit:** `e6ea911`

---

### 3. fix: Korrekter APK-Download-Link
```
- QR-Code zeigt auf direkten APK-Download
- Download-Button mit korrektem Dateinamen
```

**Commit:** `adfd77c`

---

## 🔐 API-Keys

**OpenAI API-Key erforderlich für:**
- AI-Chat
- AI-Trip-Generator
- POI-Empfehlungen

**Konfiguration:**
```dart
// lib/core/constants/api_keys.dart
class ApiKeys {
  static const String openAiApiKey = 'sk-proj-...';
}
```

**Fallback:**
Wenn kein Key konfiguriert → Demo-Modus mit Beispiel-Daten

---

## 📊 Statistiken

**Geänderte Dateien:**
- `lib/app.dart` (+7 Zeilen)
- `lib/features/map/map_screen.dart` (+25 Zeilen)
- `lib/features/ai_assistant/chat_screen.dart` (+220 Zeilen)
- `lib/features/favorites/favorites_screen.dart` (neu, 424 Zeilen)

**Gesamt:** ~676 Zeilen Code hinzugefügt

**Commits:** 3
**Build-Zeit:** ~145s
**APK-Größe:** 51.4 MB

---

## 🚀 Migration von v1.1.0

### Breaking Changes
**Keine!** Alle Änderungen sind abwärtskompatibel.

### Neue Dependencies
```yaml
# pubspec.yaml (bereits vorhanden)
dependencies:
  flutter_riverpod: ^2.x
  freezed_annotation: ^2.x
  hive: ^2.x
  go_router: ^13.x
```

### Neue Hive Boxes
- `account` - Account-Daten (Level, XP, Achievements)
- `favorites` - Favoriten (Routen + POIs)

### API-Key Setup
1. OpenAI Account erstellen: https://platform.openai.com
2. API-Key generieren
3. In `lib/core/constants/api_keys.dart` eintragen
4. App neu bauen

---

## 🐞 Bekannte Issues

### 1. Trip-Übernahme fehlt
**Status:** 🚧 In Arbeit

Der "Übernehmen"-Button im AI-Trip-Generator ist noch nicht implementiert. Aktuell wird der generierte Plan nur im Chat angezeigt.

**Workaround:** Manuell POIs suchen und zur Route hinzufügen.

**Geplant für:** v1.3.0

---

### 2. Offline-Modus
**Status:** 🚧 In Arbeit

AI-Features benötigen Internetverbindung. Keine Offline-Fallbacks.

**Workaround:** App ohne AI-Features nutzbar.

**Geplant für:** v1.3.0

---

## 📚 Dokumentation

**Aktualisiert:**
- `CLAUDE.md` - Tech Stack, Features, Navigation
- `Dokumentation/CHANGELOG-v1.2.0.md` - Dieses Dokument
- `QR-CODE-DOWNLOAD.html` - Download-Seite

**Hinzugefügt:**
- Profil-System Dokumentation
- Favoriten-System Dokumentation
- AI-Integration Guide

---

## 🎯 Nächste Schritte (v1.3.0)

### Geplante Features
1. **Trip-Übernahme** - AI-generierte Trips direkt laden
2. **Offline-Mode** - Cached Tiles & POIs
3. **Share-Funktion** - Trips teilen via QR/Link
4. **Push-Notifications** - Trip-Erinnerungen
5. **Multi-Language** - Englisch Support

### Performance-Optimierungen
- POI-Batch-Loading
- Image-Lazy-Loading
- Route-Caching

### UI-Polishing
- Animations verbessern
- Loading-States
- Error-States

---

## 👏 Credits

**Entwicklung:**
- Haupt-Entwicklung: @jerdnaandrej777
- AI-Unterstützung: Claude Sonnet 4.5

**APIs:**
- OpenAI GPT-4o
- Nominatim (OpenStreetMap)
- Open-Meteo
- Wikipedia

**Frameworks:**
- Flutter Team
- Riverpod Community

---

**Version:** 1.2.0
**Build-Datum:** 21. Januar 2026
**Repository:** https://github.com/jerdnaandrej777/mapab-app
