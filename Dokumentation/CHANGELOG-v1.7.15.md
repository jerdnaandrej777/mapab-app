# MapAB v1.7.15 - GPS-Button Optimierung

**Release-Datum:** 2026-01-31

## 🎯 Verbesserung

### Redundanter GPS-Button entfernt
- **Problem:** GPS-Button erschien doppelt - einmal in der Suchleiste und einmal als Floating Button
- **Lösung:** FloatingActionButton für GPS entfernt (rechts unten, unter Settings)
- **Verbleibende GPS-Buttons:**
  - GPS-Button in der Schnell-Modus Suchleiste (setzt Startpunkt)
  - GPS-Button im AI Trip Panel (setzt Startpunkt für AI Trip)

## 🔧 Technisch

**Dateien:**
- `lib/features/map/map_screen.dart`
  - FloatingActionButton für GPS entfernt (Zeilen 403-417)
  - Behält WeatherChip und Settings-Button
  - `_centerOnLocation()` Methode bleibt für zukünftige Verwendung

**Verhalten:**
- GPS-Funktion nur noch dort, wo sie konkret gebraucht wird (Startpunkt setzen)
- Kein redundanter Button mehr für Karten-Zentrierung

## 📱 UX-Verbesserung

**Vorher:** 3 GPS-Buttons (Schnell-Modus, AI Trip, Floating rechts)
**Nachher:** 2 GPS-Buttons (Schnell-Modus, AI Trip) - klarere UX ✅
