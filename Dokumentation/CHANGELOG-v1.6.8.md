# Changelog v1.6.8 - GPS-Dialog, Löschbutton & POI-Details unter Route

**Datum:** 2026-01-29

## Überblick

Diese Version bringt vier wichtige UX-Verbesserungen:
1. GPS-Dialog bei "Überrasch mich!" wenn GPS deaktiviert (AI Trip Modus)
2. GPS-Button im Schnell-Modus zum Setzen des Startpunkts
3. Löschbutton erscheint jetzt auch nach AI Trip Generierung
4. POI-Details mit Foto werden unter "Deine Route" korrekt angezeigt

---

## 1. GPS-Dialog bei "Überrasch mich!"

### Problem

Wenn GPS deaktiviert war und der Benutzer auf "Überrasch mich!" klickte, wurde nur eine Fehlermeldung im State angezeigt. Es gab keinen Dialog, um die GPS-Einstellungen zu öffnen.

### Lösung

Neue Helper-Methoden in `_AITripPanelState`:

**Datei:** `lib/features/map/map_screen.dart`

```dart
/// Prüft GPS-Status und zeigt Dialog wenn deaktiviert
Future<bool> _checkGPSAndShowDialog() async {
  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    if (!mounted) return false;
    final shouldOpen = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('GPS deaktiviert'),
        content: const Text(
          'Die Ortungsdienste sind deaktiviert. Möchtest du die GPS-Einstellungen öffnen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Nein'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Einstellungen öffnen'),
          ),
        ],
      ),
    ) ?? false;
    if (shouldOpen) {
      await Geolocator.openLocationSettings();
    }
    return false;
  }
  return true;
}

/// Handelt GPS-Button-Klick mit Dialog
Future<void> _handleGPSButtonTap() async {
  final gpsAvailable = await _checkGPSAndShowDialog();
  if (!gpsAvailable) return;
  final notifier = ref.read(randomTripNotifierProvider.notifier);
  await notifier.useCurrentLocation();
}

/// Handelt "Überrasch mich!" Klick - prüft GPS wenn kein Startpunkt
Future<void> _handleGenerateTrip() async {
  final state = ref.read(randomTripNotifierProvider);
  final notifier = ref.read(randomTripNotifierProvider.notifier);

  if (!state.hasValidStart) {
    final gpsAvailable = await _checkGPSAndShowDialog();
    if (!gpsAvailable) return;
    await notifier.useCurrentLocation();
    final newState = ref.read(randomTripNotifierProvider);
    if (!newState.hasValidStart) return;
  }
  notifier.generateTrip();
}
```

### Änderungen an den Buttons

```dart
// GPS Button - vorher:
onTap: state.isLoading ? null : () => notifier.useCurrentLocation(),

// GPS Button - nachher:
onTap: state.isLoading ? null : _handleGPSButtonTap,

// Generate Button - vorher:
onPressed: state.canGenerate ? () => notifier.generateTrip() : null,

// Generate Button - nachher:
onPressed: state.isLoading ? null : _handleGenerateTrip,
```

---

## 2. GPS-Button im Schnell-Modus

### Problem

Im Schnell-Modus gab es keinen GPS-Button, um den aktuellen Standort als Startpunkt zu setzen. Der vorhandene GPS-Button (Floating Action Button) zentrierte nur die Karte.

### Lösung

GPS-Button zur `_SearchBar` hinzugefügt:

**Datei:** `lib/features/map/map_screen.dart`

**1. SearchBar erweitert mit GPS-Button:**

```dart
class _SearchBar extends StatelessWidget {
  // ... bestehende Parameter
  final VoidCallback? onGpsTap;
  final bool isLoadingGps;

  // GPS-Button neben Start-Feld:
  if (onGpsTap != null)
    InkWell(
      onTap: isLoadingGps ? null : onGpsTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        child: isLoadingGps
            ? CircularProgressIndicator(...)
            : Icon(Icons.my_location),
      ),
    ),
```

**2. Handler-Methode für Schnell-Modus GPS:**

```dart
/// GPS-Button im Schnell-Modus: Setzt aktuellen Standort als Startpunkt
Future<void> _handleSchnellModeGPS() async {
  // Prüft GPS-Status und zeigt Dialog wenn deaktiviert
  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    final shouldOpenSettings = await _showGpsDialog();
    if (shouldOpenSettings) {
      await Geolocator.openLocationSettings();
    }
    return;
  }

  // Position abrufen und als Startpunkt setzen
  final position = await Geolocator.getCurrentPosition(...);
  final latLng = LatLng(position.latitude, position.longitude);
  ref.read(routePlannerProvider.notifier).setStart(latLng, 'Mein Standort');

  // Karte zentrieren
  mapController.move(latLng, 15);
}
```

### Verhalten

- GPS-Button erscheint rechts neben dem Startpunkt-Feld
- Bei Klick: GPS-Status prüfen → Dialog wenn deaktiviert → Standort als Startpunkt setzen
- Loading-Indikator während der GPS-Ermittlung
- Button wird blau hinterlegt wenn "Mein Standort" als Start gesetzt ist

---

## 3. Löschbutton nach AI Trip Generierung

### Problem

Nach AI Trip Generierung erschien kein "Route löschen" Button auf der Karte. Der Button wurde nur für normale Routen (`routePlanner.hasStart || hasEnd`) angezeigt.

### Lösung

Zwei Anpassungen in `map_screen.dart`:

**1. Schnell-Modus: Erweiterte Bedingung**

```dart
// Route löschen Button (wenn Route, Start/Ziel ODER AI Trip vorhanden)
if (routePlanner.hasStart || routePlanner.hasEnd ||
    randomTripState.step == RandomTripStep.preview ||
    randomTripState.step == RandomTripStep.confirmed)
  Padding(
    padding: const EdgeInsets.only(top: 12),
    child: _RouteClearButton(
      onClear: () {
        // Beide States zurücksetzen
        ref.read(routePlannerProvider.notifier).clearRoute();
        ref.read(randomTripNotifierProvider.notifier).reset();
      },
    ),
  ),
```

**2. AI Trip Modus: Separater Button**

```dart
// === ROUTE LÖSCHEN BUTTON FÜR AI TRIP ===
if (_planMode == MapPlanMode.aiTrip &&
    !isGenerating &&
    (randomTripState.step == RandomTripStep.preview ||
     randomTripState.step == RandomTripStep.confirmed))
  Padding(
    padding: const EdgeInsets.only(top: 12),
    child: _RouteClearButton(
      onClear: () {
        ref.read(randomTripNotifierProvider.notifier).reset();
        ref.read(routePlannerProvider.notifier).clearRoute();
      },
    ),
  ),
```

---

## 4. POI-Details unter "Deine Route"

### Problem

Beim Klick auf einen Stop unter "Deine Route" (TripScreen) wurden keine POI-Details angezeigt. Der POI aus dem TripState war nicht im POIState vorhanden.

### Lösung

**Datei:** `lib/features/poi/providers/poi_state_provider.dart`

Neue Methode `addPOI()`:

```dart
/// Fügt einen einzelnen POI zum State hinzu (für Navigation von TripScreen)
void addPOI(POI poi) {
  final existingIndex = state.pois.indexWhere((p) => p.id == poi.id);
  if (existingIndex != -1) {
    // POI bereits vorhanden - aktualisieren
    final updatedPOIs = List<POI>.from(state.pois);
    updatedPOIs[existingIndex] = poi;
    state = state.copyWith(pois: updatedPOIs);
    debugPrint('[POIState] POI aktualisiert: ${poi.name}');
  } else {
    // POI hinzufügen
    state = state.copyWith(pois: [...state.pois, poi]);
    debugPrint('[POIState] POI hinzugefügt: ${poi.name}');
  }
}
```

**Datei:** `lib/features/trip/trip_screen.dart`

Navigation angepasst:

```dart
// VORHER:
onTap: () {
  context.push('/poi/${stop.id}');
},

// NACHHER:
onTap: () {
  // POI zum State hinzufügen bevor Navigation
  ref.read(pOIStateNotifierProvider.notifier).addPOI(stop);
  context.push('/poi/${stop.id}');
},

// Analog für onEdit:
onEdit: () {
  ref.read(pOIStateNotifierProvider.notifier).addPOI(stop);
  context.push('/poi/${stop.id}');
},
```

---

## Betroffene Dateien

| Datei | Änderung |
|-------|----------|
| `lib/features/map/map_screen.dart` | GPS-Dialog Methoden, Löschbutton-Erweiterung |
| `lib/features/poi/providers/poi_state_provider.dart` | Neue `addPOI()` Methode |
| `lib/features/trip/trip_screen.dart` | Import hinzugefügt, POI vor Navigation hinzufügen |

---

## Verifikation

### Test 1: GPS-Dialog im AI Trip Modus
1. GPS am Handy deaktivieren
2. App öffnen → Karte → "AI Trip" Tab
3. "Überrasch mich!" klicken
4. ✓ Dialog "GPS deaktiviert - Möchtest du Einstellungen öffnen?" erscheint
5. "Einstellungen öffnen" → GPS-Einstellungen öffnen sich

### Test 2: GPS-Button im Schnell-Modus
1. GPS am Handy deaktivieren
2. App öffnen → Karte → "Schnell" Tab (Standard)
3. GPS-Button (📍) neben Startpunkt-Feld klicken
4. ✓ Dialog "GPS deaktiviert" erscheint
5. GPS aktivieren → Button erneut klicken
6. ✓ "Mein Standort" wird als Startpunkt gesetzt
7. ✓ Karte zentriert sich auf aktuellen Standort

### Test 3: Löschbutton
1. Route im Schnell-Modus berechnen
2. ✓ Roter "Route löschen" Button erscheint
3. "AI Trip" Tab → "Überrasch mich!" mit GPS
4. Trip wird generiert
5. ✓ "Route löschen" Button erscheint
6. Button klicken → Route und AI Trip werden gelöscht

### Test 4: POI-Details unter "Deine Route"
1. Route mit Stops erstellen (Schnell-Modus oder AI Trip)
2. Zum Trip-Screen navigieren (Tab "Trip")
3. Auf einen Stop unter "Deine Route" klicken
4. ✓ POI-Details mit Foto werden angezeigt
5. ✓ "Lade Details..." erscheint kurz während Enrichment

---

## Zusammenfassung

| Feature | Vorher | Nachher |
|---------|--------|---------|
| GPS bei "Überrasch mich!" (AI Trip) | Nur Fehlermeldung | Dialog mit Einstellungen-Option |
| GPS-Button im Schnell-Modus | Nicht vorhanden | Button setzt Standort als Start |
| Löschbutton nach AI Trip | Nicht sichtbar | Button erscheint |
| POI-Details unter "Deine Route" | Leer/Fehler | Details mit Foto werden angezeigt |
