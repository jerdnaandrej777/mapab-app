# MapAB Flutter App - Changelog v1.2.1

**Release-Datum:** 21. Januar 2026
**Build:** Release APK (51.4 MB)
**Download:** [GitHub Release v1.2.1](https://github.com/jerdnaandrej777/mapab-app/releases/tag/v1.2.1)

---

## 🎉 Neue Features

### 1. Trip-Screen Integration

**Problem:** Trip-Tab war leer, zeigte keine berechneten Routen an.

**Lösung:** Vollständige Integration mit Route-State-Management

**Neue Dateien:**
- `lib/features/trip/providers/trip_state_provider.dart` - Riverpod Provider für Trip-State

**Features:**
- ✅ **Berechnete Routen anzeigen**: Start-Adresse, Ziel-Adresse, Stops
- ✅ **Trip-State Provider**: Zentrales State Management für Routen
- ✅ **Empty State**: Buttons zu "Zur Karte" und "AI-Trip generieren"
- ✅ **Reorder-Funktion**: Stops per Drag & Drop verschieben
- ✅ **Remove-Funktion**: Stops einzeln entfernen
- ✅ **Clear-Funktion**: Alle Stops löschen mit Bestätigungs-Dialog

**Provider-Methoden:**
```dart
class TripState extends _$TripState {
  void setRoute(AppRoute route);
  void addStop(POI poi);
  void removeStop(String poiId);
  void setStops(List<POI> stops);
  void clearStops();
  void clearAll();
  void reorderStops(int oldIndex, int newIndex);
}
```

**TripStateData Properties:**
```dart
class TripStateData {
  final AppRoute? route;
  final List<POI> stops;

  bool get hasRoute;
  bool get hasStops;
  double get totalDistance;
  int get totalDuration;  // inkl. 45 Min pro Stop
}
```

**UI-Änderungen:**
- Von `ConsumerStatefulWidget` zu `ConsumerWidget`
- Verwendet `tripStateProvider` statt lokalen State
- Empty State zeigt "Noch keine Route geplant" statt "Noch keine Stops geplant"

---

### 2. UI-Verbesserungen

#### 2.1 Settings-Button verschoben

**Vorher:**
```dart
Positioned(
  right: 16,
  top: MediaQuery.of(context).padding.top + 16,
  child: FloatingActionButton.small(...),
)
```

**Nachher:**
```dart
Column(
  children: [
    FloatingActionButton.small(icon: Icons.settings),  // ← NEU oben
    SizedBox(height: 8),
    FloatingActionButton.small(icon: Icons.my_location),
    SizedBox(height: 8),
    FloatingActionButton.small(icon: Icons.add),
    SizedBox(height: 4),
    FloatingActionButton.small(icon: Icons.remove),
  ],
)
```

**Reihenfolge (rechts unten → oben):**
1. ⚙️ Settings
2. 📍 GPS
3. ➕ Zoom In
4. ➖ Zoom Out

---

#### 2.2 AI-Trip-Dialog: Weißer Text gefixt

**Problem:** Text war weiß auf weißem Hintergrund, nicht lesbar.

**Vorher:**
```dart
Text('Tage: ${days.round()}'),  // Weiß auf weiß
const Text('Interessen:', style: TextStyle(fontWeight: FontWeight.bold)),  // Weiß
```

**Nachher:**
```dart
const Text(
  'Anzahl Tage',
  style: TextStyle(
    fontWeight: FontWeight.w500,
    fontSize: 14,
    color: Colors.black87,  // ← Gefixt
  ),
),
Text(
  '${days.round()} ${days.round() == 1 ? "Tag" : "Tage"}',
  style: const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.black,  // ← Gefixt
  ),
),
const Text(
  'Interessen:',
  style: TextStyle(
    fontWeight: FontWeight.w500,
    fontSize: 14,
    color: Colors.black87,  // ← Gefixt
  ),
),
```

**Verbesserungen:**
- Labels jetzt schwarz statt weiß
- Bessere Struktur mit separatem Label + Wert
- Singular/Plural-Handling für "Tag"/"Tage"

---

## 🐛 Bugfixes

### 1. Null-Safety Fix in trip_screen.dart

**Problem:** `stop.category.icon` konnte null sein (Compiler-Fehler)

**Fix:**
```dart
// VORHER (FEHLER):
icon: stop.category.icon,

// NACHHER (KORREKT):
icon: stop.category?.icon ?? '📍',
```

---

### 2. Type Conversion Fix

**Problem:** `detourKm` und `detourMinutes` sind `num`, aber `TripStopTile` erwartet `int`

**Fix:**
```dart
// VORHER (FEHLER):
detourKm: stop.detourKm ?? 0,
durationMinutes: stop.detourMinutes ?? 0,

// NACHHER (KORREKT):
detourKm: (stop.detourKm ?? 0).toInt(),
durationMinutes: (stop.detourMinutes ?? 0).toInt(),
```

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

**Build-Zeit:** ~248 Sekunden

---

### Code-Generierung

**Command:**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

**Output:**
- 895 Outputs generiert
- 1810 Actions in 50.4s
- Neue Datei: `trip_state_provider.g.dart`

---

### GitHub Release

**Tag:** `v1.2.1`
**URL:** https://github.com/jerdnaandrej777/mapab-app/releases/tag/v1.2.1

**Assets:**
- `app-release.apk` (51.4 MB)

**Download-Link:**
```
https://github.com/jerdnaandrej777/mapab-app/releases/download/v1.2.1/app-release.apk
```

**QR-Code:**
- Datei: `QR-CODE-DOWNLOAD.html`
- Zeigt direkt auf APK-Download v1.2.1
- Offline nutzbar (JavaScript QR-Generator)

---

## 📝 Commits

### 1. feat: Trip-Screen Integration & UI-Fixes

```
- Trip-Screen: Trip-State Provider für Routen-Anzeige
- MapScreen: Settings-Button über GPS-Button verschoben
- AI-Trip-Dialog: Weißer Text auf weißem Hintergrund gefixt
- Bugfixes: category?.icon null-safety, detourKm type conversion

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
```

**Geänderte Dateien:**
- `lib/features/trip/providers/trip_state_provider.dart` (NEU, 91 Zeilen)
- `lib/features/trip/trip_screen.dart` (370 Zeilen, umfangreich refactored)
- `lib/features/map/map_screen.dart` (+10 Zeilen, -8 Zeilen)
- `lib/features/ai_assistant/chat_screen.dart` (+32 Zeilen, -2 Zeilen)
- `QR-CODE-DOWNLOAD.html` (aktualisiert auf v1.2.1)
- `Dokumentation/CHANGELOG-v1.2.1.md` (NEU, dieses Dokument)

---

## 📊 Statistiken

**Geänderte Dateien:** 6
**Neue Dateien:** 2 (Provider + Changelog)
**Gesamt Zeilen hinzugefügt:** ~500
**Build-Zeit:** ~248s
**APK-Größe:** 51.4 MB

**Commits:** 1
**Build-Runner Outputs:** 895
**Actions:** 1810

---

## 🚀 Migration von v1.2.0

### Breaking Changes
**Keine!** Alle Änderungen sind abwärtskompatibel.

### Neue Provider
```dart
// lib/features/trip/providers/trip_state_provider.dart
final tripStateProvider = StateNotifierProvider<TripState, TripStateData>(...);
```

### Neue Dependencies
Keine neuen Dependencies, nur Code-Generierung für Provider.

---

## 🐞 Bekannte Issues

### 1. Trip-Übernahme aus AI-Generator fehlt noch

**Status:** 🚧 Planned für v1.3.0

Der AI-Trip-Generator zeigt zwar Pläne an, aber die "Übernehmen"-Funktion zum Laden in den Trip-State fehlt noch.

**Workaround:** Manuell POIs zur Route hinzufügen.

---

### 2. Route-Berechnung noch nicht in Trip-State integriert

**Status:** 🚧 Planned für v1.3.0

Wenn auf der Karte eine Route berechnet wird, wird diese noch nicht automatisch in den Trip-State übernommen.

**Workaround:** Route wird auf Karte angezeigt, aber nicht im Trip-Tab.

---

## 🎯 Nächste Schritte (v1.3.0)

### Geplante Features
1. **Route → Trip Integration**: Berechnete Routen automatisch in Trip-State übernehmen
2. **AI-Trip Übernahme**: "Übernehmen"-Button für AI-generierte Trips
3. **POI → Trip**: POI-Details mit "Zur Route hinzufügen" Button
4. **Trip-Optimierung**: TSP-Algorithmus für optimale Reihenfolge
5. **Trip-Speichern**: Routen in Favoriten speichern

### Performance-Optimierungen
- Provider-Optimierung für häufige Updates
- Lazy-Loading für POI-Details
- Caching für Routen-Berechnungen

### UI-Polishing
- Trip-Screen: Stop-Details-View
- Trip-Screen: Distanz/Dauer zwischen Stops anzeigen
- Trip-Screen: Vorschau-Karte für Route

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

**Version:** 1.2.1
**Build-Datum:** 21. Januar 2026
**Repository:** https://github.com/jerdnaandrej777/mapab-app
