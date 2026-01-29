# Changelog v1.4.8

**Release-Datum:** 24. Januar 2026

## Hauptänderungen

### UI-Optimierung: Integrierter Trip-Planer

Die Trip-Planungsseite wurde komplett überarbeitet. AI Trip ist jetzt direkt im Trip-Screen integriert - keine separate Seite mehr nötig.

#### Neue Funktionen

- **Mode-Tabs**: Umschalten zwischen "Schnell" und "AI Trip" mit animiertem Selector
- **AI Trip Typ-Auswahl**: Buttons für "AI Tagesausflug" und "AI Euro Trip" direkt sichtbar
- **Integrierte Konfiguration**:
  - Startpunkt-Eingabe mit Adress-Suche oder GPS-Standort
  - Radius-Slider für beide Trip-Typen
  - Tage-Auswahl für Euro Trip
  - Aufklappbare Kategorie-Auswahl
- **"Überrasch mich!" Button**: Direkt im Trip-Screen
- **Preview auf gleicher Seite**: Nach Generierung wird die Route in der gleichen Ansicht angezeigt

#### UI-Verbesserungen

- Alle Konfigurationsoptionen werden ausgeblendet sobald ein Trip generiert wurde
- Beim Wechsel zu "Schnell" werden nur relevante Funktionen angezeigt
- Smooth Animationen mit `AnimatedCrossFade` für Kategorien
- Konsistentes Design mit Dark Mode Support

### Dark Mode Kompatibilität

Alle Widgets wurden für vollständige Dark Mode Unterstützung aktualisiert:

- `trip_screen.dart` - Komplette Neustrukturierung
- `start_location_picker.dart` - colorScheme statt AppTheme
- `radius_slider.dart` - Dark Mode Support
- `days_selector.dart` - Dark Mode Support
- `trip_preview_card.dart` - Dark Mode Support
- `poi_reroll_button.dart` - Dark Mode Support
- `hotel_suggestion_card.dart` - Dark Mode Support

### Code-Bereinigung

- Entfernung ungenutzter `_LocationButton` Klasse
- Entfernung von AppTheme-Referenzen zugunsten von `colorScheme`
- Verwendung von `colorScheme.surfaceContainerHighest` statt hartcodierter Farben

## Technische Details

### Neue Enums & Widgets

```dart
enum TripPlanMode {
  schnell('Schnell', Icons.bolt),
  aiTrip('AI Trip', Icons.auto_awesome);
}
```

### State Management

- `TripScreen` ist jetzt `ConsumerStatefulWidget` für lokalen Mode-State
- Kombinierte Nutzung von `tripStateProvider` und `randomTripNotifierProvider`

### Betroffene Dateien

| Datei | Änderung |
|-------|----------|
| `lib/features/trip/trip_screen.dart` | Komplett neu geschrieben |
| `lib/features/random_trip/widgets/start_location_picker.dart` | Dark Mode |
| `lib/features/random_trip/widgets/radius_slider.dart` | Dark Mode |
| `lib/features/random_trip/widgets/days_selector.dart` | Dark Mode |
| `lib/features/random_trip/widgets/trip_preview_card.dart` | Dark Mode |
| `lib/features/random_trip/widgets/poi_reroll_button.dart` | Dark Mode |
| `lib/features/random_trip/widgets/hotel_suggestion_card.dart` | Dark Mode |

## Migration

Die `/random-trip` Route existiert weiterhin für Abwärtskompatibilität, wird aber nicht mehr benötigt. Die AI Trip Funktionalität ist jetzt direkt über den Trip-Screen (`/trip`) erreichbar.

## Bekannte Einschränkungen

- Keine neuen Einschränkungen

---

**Vollständige Dokumentation:** Siehe [CLAUDE.md](../CLAUDE.md)
