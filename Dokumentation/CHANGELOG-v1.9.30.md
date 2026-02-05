# CHANGELOG v1.9.30 - Trip-Templates & QR-Scanner

**Release-Datum:** 5. Februar 2026
**Build:** 1.9.30+177

## Übersicht

Diese Version erweitert die App um **12 vordefinierte Reisevorlagen** und einen **QR-Code-Scanner für Trip-Import**. Benutzer können jetzt schnell einen passenden Trip-Typ auswählen und Trips per QR-Code von anderen Benutzern importieren.

---

## Neue Features

### 1. Trip-Templates (12 vordefinierte Reisevorlagen)

**Neue Dateien:**
- `lib/data/models/trip_template.dart` - Freezed-Model für Trip-Vorlagen
- `lib/features/templates/trip_templates_screen.dart` - Template-Auswahl-UI

**Verfügbare Vorlagen:**

| ID | Name | Emoji | Empfohlene Tage | Kategorien | Zielgruppe |
|----|------|-------|-----------------|------------|------------|
| `quick-escape` | Schneller Tagesausflug | ⚡ | 1 | viewpoint, nature, castle, lake | alle |
| `romantic-weekend` | Romantisches Wochenende | 💕 | 2 | castle, lake, viewpoint, restaurant | paare |
| `culture-tour` | Kulturreise | 🏛️ | 3 | museum, unesco, monument, church, city | alle |
| `nature-escape` | Natur-Auszeit | 🌲 | 4 | nature, park, lake, viewpoint | alle |
| `family-fun` | Familienspass | 👨‍👩‍👧‍👦 | 3 | activity, park, nature, museum | familien |
| `city-hopping` | Städtetrip | 🏙️ | 5 | city, museum, restaurant, monument, church | alle |
| `adventure-trip` | Abenteuer-Trip | 🎢 | 4 | activity, nature, viewpoint | abenteurer |
| `beach-vibes` | Strand & Küste | 🏖️ | 5 | coast, lake, nature, restaurant | alle |
| `castle-tour` | Burgen & Schlösser | 🏰 | 3 | castle, museum, park, restaurant | alle |
| `wellness-retreat` | Wellness & Entspannung | 🧘 | 2 | lake, nature, park, hotel | alle |
| `foodie-tour` | Kulinarische Reise | 🍷 | 3 | restaurant, city, nature, viewpoint | feinschmecker |
| `photo-tour` | Foto-Tour | 📸 | 4 | viewpoint, castle, nature, lake, coast | fotografen |

**Features:**
- Zielgruppen-Filter (Alle, Paare, Familien, Abenteurer, Fotografen, Feinschmecker)
- Tage-Stepper für Anpassung der empfohlenen Reisedauer
- Direkte Integration mit RandomTripProvider (setMode, setCategories, setEuroTripDays)
- Navigation zu MapScreen mit `?mode=ai` Parameter

**Verwendung:**
```dart
// Navigation zur Template-Auswahl
context.push('/templates');

// Programmatischer Zugriff auf Templates
final templates = TripTemplates.all;
final romantic = TripTemplates.findById('romantic-weekend');
final familyTemplates = TripTemplates.forAudience('familien');
```

---

### 2. QR-Code-Scanner für Trip-Import

**Neue Dateien:**
- `lib/features/sharing/qr_scanner_screen.dart` - Scanner-Screen mit mobile_scanner

**Dependencies:**
- `mobile_scanner: ^5.1.1` (neu hinzugefügt)

**Android-Berechtigungen:**
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-feature android:name="android.hardware.camera" android:required="false" />
```

**Unterstützte Deep-Link-Formate:**
1. `mapab://trip?data=BASE64_ENCODED_JSON`
2. `https://mapab.app/trip?data=BASE64_ENCODED_JSON`

**Trip-JSON-Struktur:**
```json
{
  "name": "Mein Trip",
  "type": "eurotrip",
  "stops": [
    {
      "id": "poi-1",
      "name": "POI Name",
      "lat": 48.1234,
      "lng": 11.5678,
      "category": "castle"
    }
  ]
}
```

**Features:**
- Echtzeit-QR-Code-Erkennung
- Automatische Routen-Berechnung via OSRM (calculateFastRoute)
- Fehlerbehandlung mit Snackbar-Feedback
- Flashlight-Toggle
- Loading-Overlay während Import

**Verwendung:**
```dart
// Navigation zum QR-Scanner
context.push('/scan');

// Im ShareTripSheet: QR-Code generieren
// Im QRScannerScreen: QR-Code scannen und importieren
```

---

## GoRouter-Änderungen

Neue Routes in `lib/app.dart`:

```dart
// QR-Code Scanner (Trip-Import)
GoRoute(
  path: '/scan',
  name: 'scan',
  builder: (context, state) => const QRScannerScreen(),
),

// Trip-Vorlagen
GoRoute(
  path: '/templates',
  name: 'templates',
  builder: (context, state) => const TripTemplatesScreen(),
),
```

---

## Technische Details

### Import-Konflikt-Lösung

`latlong2` exportiert eine `Path`-Klasse, die mit `dart:ui.Path` kollidiert. Lösung:
```dart
import 'package:latlong2/latlong.dart' show LatLng;
```

### API-Nutzung

**Routen-Berechnung:**
```dart
final route = await routingRepo.calculateFastRoute(
  start: start,           // LatLng
  end: end,               // LatLng
  waypoints: waypoints,   // List<LatLng>
  startAddress: 'Start',
  endAddress: 'Ziel',
);
```

### Error Handling

- `AppSnackbar.showSuccess()` für erfolgreichen Import
- `AppSnackbar.showError()` für ungültige QR-Codes
- JSON-Parsing mit try-catch
- Validierung der Deep-Link-Struktur

---

## Migration

Keine Breaking Changes. Neue Features sind additiv.

**Empfohlene Einstiegspunkte für UI-Integration:**
- Settings-Screen: Link zu `/templates`
- MapScreen: Quick-Action-Button für `/scan`
- ShareTripSheet: QR-Code-Generierung (bereits vorhanden via qr_flutter)

---

## Dateigröße

APK-Größe: 116.7 MB (Zunahme durch mobile_scanner native Library)
