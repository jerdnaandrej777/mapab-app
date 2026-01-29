# Changelog v1.6.5 - TripScreen Vereinfachung

**Datum:** 28.01.2026

## Übersicht

Der TripScreen wurde vereinfacht und zeigt jetzt nur noch berechnete Routen an. Die Mode-Auswahl-Buttons (Schnell / AI Trip) und die AI Trip Konfiguration wurden entfernt.

## Änderungen

### Entfernte UI-Elemente

1. **Mode-Selector Buttons entfernt**
   - "Schnell" und "AI Trip" Toggle-Buttons
   - `TripPlanMode` Enum wird nicht mehr für UI verwendet

2. **AI Trip Konfiguration entfernt**
   - Startpunkt-Picker
   - Radius-Slider
   - Tage-Auswahl (DaysSelector)
   - Kategorien-Auswahl (expandable)
   - "Überrasch mich!" Button

3. **Entfernte Widgets**
   - `_CategoryChip` Widget
   - `_buildModeSelector()` Methode
   - `_buildAITripModeContent()` Methode
   - `_buildAITripTypeSelector()` Methode
   - `_buildExpandableCategorySelector()` Methode
   - `_buildGenerateButton()` Methode

### Code-Änderungen

**Entfernte State-Variablen:**
```dart
// ENTFERNT:
late TripPlanMode _selectedMode;
bool _categoriesExpanded = false;
bool _initialized = false;
```

**Entfernter Parameter:**
```dart
// VORHER:
class TripScreen extends ConsumerStatefulWidget {
  final bool startWithAIMode;
  const TripScreen({super.key, this.startWithAIMode = false});
}

// NACHHER:
class TripScreen extends ConsumerStatefulWidget {
  const TripScreen({super.key});
}
```

**Vereinfachte ConfigView:**
```dart
// VORHER: Mode-Selector + AI Trip oder Schnell Inhalt
Widget _buildConfigView(...) {
  return Column(
    children: [
      _buildModeSelector(theme, colorScheme),
      Expanded(
        child: _selectedMode == TripPlanMode.schnell
            ? _buildSchnellModeContent(...)
            : _buildAITripModeContent(...),
      ),
    ],
  );
}

// NACHHER: Nur "Keine Route" Hinweis
Widget _buildConfigView(...) {
  return Center(
    child: Column(
      children: [
        Icon(Icons.route, ...),
        Text('Keine Route vorhanden'),
        Text('Tippe auf die Karte, um Start und Ziel festzulegen'),
        ElevatedButton.icon(
          onPressed: () => context.go('/'),
          label: Text('Zur Karte'),
        ),
      ],
    ),
  );
}
```

### Router-Änderung (app.dart)

```dart
// VORHER:
GoRoute(
  path: '/trip',
  pageBuilder: (context, state) {
    final startWithAI = state.uri.queryParameters['mode'] == 'ai';
    return NoTransitionPage(
      child: TripScreen(startWithAIMode: startWithAI),
    );
  },
),

// NACHHER:
GoRoute(
  path: '/trip',
  pageBuilder: (context, state) => const NoTransitionPage(
    child: TripScreen(),
  ),
),
```

### Entfernte Imports

```dart
// Nicht mehr benötigt:
import '../random_trip/widgets/start_location_picker.dart';
import '../random_trip/widgets/radius_slider.dart';
import '../random_trip/widgets/days_selector.dart';
```

## Beibehaltene Funktionalität

- Route-Anzeige mit Start, Ziel und Stops
- AI Trip Preview (wenn über MapScreen generiert)
- Google Maps Export
- Route Teilen
- Tagesweiser Export für Mehrtages-Trips
- Hotel-Vorschläge für AI Trips

## Begründung

Die AI Trip Konfiguration ist bereits im MapScreen integriert (seit v1.5.0). Die doppelte UI im TripScreen war redundant und verwirrend. Der TripScreen konzentriert sich jetzt auf seine Kernfunktion: Die Anzeige und Verwaltung von berechneten Routen.

## Geänderte Dateien

| Datei | Änderung |
|-------|----------|
| `lib/features/trip/trip_screen.dart` | Mode-Selector und AI Trip Config entfernt |
| `lib/app.dart` | `startWithAIMode` Parameter entfernt |

## Migration

Keine Migration erforderlich. Die Route `/trip?mode=ai` funktioniert weiterhin, ignoriert aber den Parameter.
