# Changelog v1.3.0 - Google Maps Export & Route Teilen

**Release-Datum:** 22. Januar 2026

## Neue Features

### 🗺️ Google Maps Export
Die Route kann jetzt direkt in Google Maps geöffnet werden:
- Start-Koordinaten werden übernommen
- Ziel-Koordinaten werden übernommen
- Alle POI-Stops werden als Waypoints hinzugefügt (max. 10)
- Navigation startet automatisch mit Travelmode "Driving"

**Button:** "Google Maps" im TripScreen unten links

### 📤 Route Teilen
Die Route kann über den System-Share-Dialog geteilt werden:
- WhatsApp
- Email
- SMS
- Telegram
- Andere Apps

**Share-Inhalt:**
- Start- und Ziel-Adressen
- Gesamtdistanz und geschätzte Dauer
- Liste aller POI-Stops
- Direkter Google Maps Link zum Öffnen

**Button:** "Route Teilen" im TripScreen unten rechts (ersetzt "Navigation")

### ⚡ SnackBar Verbesserung
Wenn ein POI zur Route hinzugefügt wird:
- **Vorher:** SnackBar blieb offen mit "Rückgängig" Button
- **Nachher:** SnackBar verschwindet nach 2 Sekunden automatisch (floating)

## Geänderte Dateien

| Datei | Änderung |
|-------|----------|
| `lib/features/trip/trip_screen.dart` | Google Maps Export + Route Teilen implementiert |
| `lib/features/poi/poi_detail_screen.dart` | SnackBar Duration auf 2s + floating |
| `pubspec.yaml` | Version auf 1.3.0 aktualisiert |
| `QR-CODE-DOWNLOAD.html` | Download-Link auf v1.3.0 aktualisiert |

## Neue Imports (trip_screen.dart)

```dart
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
```

## Neue Methoden (trip_screen.dart)

### _openInGoogleMaps()
```dart
Future<void> _openInGoogleMaps(BuildContext context, TripStateData tripState) async {
  // Generiert Google Maps URL mit Waypoints
  // Öffnet URL mit url_launcher
}
```

### _shareRoute()
```dart
Future<void> _shareRoute(BuildContext context, TripStateData tripState) async {
  // Generiert Share-Text mit Route-Details
  // Öffnet System-Share-Dialog
}
```

## Google Maps URL Format

```
https://www.google.com/maps/dir/?api=1
  &origin=52.5200,13.4050
  &destination=48.1351,11.5820
  &waypoints=49.4521,11.0767|48.4011,11.7453
  &travelmode=driving
```

## Bekannte Einschränkungen

- **Waypoints Limit:** Google Maps unterstützt maximal 10 Waypoints
- **Android-spezifisch:** Google Maps App muss installiert sein
- **URL-Länge:** Bei sehr vielen Stops kann die URL zu lang werden

## Screenshots

### Trip-Screen mit Export-Buttons
```
┌─────────────────────────────────────────────────┐
│                    Deine Route                   │
├─────────────────────────────────────────────────┤
│  ○ Berlin, Alexanderplatz (Start)               │
│  │                                              │
│  ● Schloss Neuschwanstein (+45 km, +30 min)     │
│  │                                              │
│  ● Nürnberger Altstadt (+23 km, +20 min)        │
│  │                                              │
│  ◉ München, Marienplatz (Ziel)                  │
├─────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐       │
│  │  🗺️ Google Maps │  │  📤 Route Teilen │       │
│  └─────────────────┘  └─────────────────┘       │
└─────────────────────────────────────────────────┘
```

## Upgrade-Anleitung

1. APK v1.3.0 herunterladen
2. Über bestehende Installation installieren (Daten bleiben erhalten)
3. App öffnen und neue Features nutzen

---

**GitHub Release:** https://github.com/jerdnaandrej777/mapab-app/releases/tag/v1.3.0
