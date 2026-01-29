# Changelog v1.4.9

**Release-Datum:** 24. Januar 2026

## Hauptänderungen

### Bugfix: AI Trip Navigation

Der AI Trip Button auf der MapScreen öffnete noch die separate RandomTripScreen-Seite (`/random-trip`) statt direkt zum integrierten TripScreen zu navigieren.

#### Änderungen

- **MapScreen**: AI Trip Button navigiert jetzt zu `/trip?mode=ai`
- **TripScreen**: Neuer `startWithAIMode` Parameter für direkten AI Trip Modus
- **app.dart**: Route liest Query-Parameter und übergibt an TripScreen

### Technische Details

```dart
// TripScreen mit Parameter
class TripScreen extends ConsumerStatefulWidget {
  final bool startWithAIMode;
  const TripScreen({super.key, this.startWithAIMode = false});
}

// Route mit Query-Parameter
GoRoute(
  path: '/trip',
  pageBuilder: (context, state) {
    final startWithAI = state.uri.queryParameters['mode'] == 'ai';
    return NoTransitionPage(
      child: TripScreen(startWithAIMode: startWithAI),
    );
  },
)
```

### Betroffene Dateien

| Datei | Änderung |
|-------|----------|
| `lib/features/map/map_screen.dart` | Navigation zu `/trip?mode=ai` |
| `lib/features/trip/trip_screen.dart` | `startWithAIMode` Parameter |
| `lib/app.dart` | Query-Parameter Handling |

## Migration

Keine Migration erforderlich. Die Änderung ist abwärtskompatibel.

---

**Vollständige Dokumentation:** Siehe [CLAUDE.md](../CLAUDE.md)
