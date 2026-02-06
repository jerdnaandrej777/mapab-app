# Changelog v1.10.19 - Bottom Sheets Vollbild

**Datum:** 6. Februar 2026
**Build:** 203

## Übersicht

Alle modalen Bottom Sheets öffnen sich jetzt im Vollbild-Modus für eine konsistente und bessere Benutzererfahrung. Vorher öffneten sich die Sheets auf unterschiedlichen Höhen.

## Änderungen

### UI/UX Verbesserungen

- **Vollbild Bottom Sheets**: Alle 16 Bottom Sheets nutzen jetzt `DraggableScrollableSheet` mit `initialChildSize: 1.0`
- **Konsistente Handle Bars**: Alle Sheets haben einheitliche Drag-Handles (40x4px)
- **Safe Area**: `useSafeArea: true` verhindert Überlappung mit System-UI
- **Scrollbarer Inhalt**: Sheets mit viel Inhalt sind jetzt scrollbar

### Betroffene Dateien

| Datei | Sheet-Typ |
|-------|-----------|
| `publish_trip_sheet.dart` | Trip-Veröffentlichung |
| `share_trip_sheet.dart` | Trip-Teilen |
| `journal_screen.dart` | Eintrag-Details |
| `weather_details_sheet.dart` | Wetter-Details |
| `add_journal_entry_sheet.dart` | Tagebuch-Eintrag |
| `upload_photo_sheet.dart` | Foto-Upload |
| `submit_review_sheet.dart` | Bewertung abgeben |
| `hotel_detail_sheet.dart` | Hotel-Details |
| `poi_filters.dart` | POI-Filter |
| `trip_templates_screen.dart` | Template-Detail |
| `profile_screen.dart` | Achievement-Sheet |
| `poi_list_screen.dart` | Filter-Sheet |
| `trip_config_panel.dart` | Destination + Kategorien |
| `map_view.dart` | POI-Preview |
| `route_weather_marker.dart` | Routen-Wetter |

### Technische Details

```dart
// Vorher - unterschiedliche Höhen
showModalBottomSheet(
  builder: (context) => Container(
    child: Column(mainAxisSize: MainAxisSize.min, ...),
  ),
);

// Nachher - einheitlich Vollbild
showModalBottomSheet(
  isScrollControlled: true,
  useSafeArea: true,
  builder: (context) => DraggableScrollableSheet(
    initialChildSize: 1.0,
    minChildSize: 0.9,
    maxChildSize: 1.0,
    expand: false,
    builder: (context, scrollController) => Container(
      child: Column(
        children: [
          // Handle Bar
          Container(width: 40, height: 4, ...),
          // Scrollbarer Inhalt
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              ...
            ),
          ),
        ],
      ),
    ),
  ),
);
```

## Migration

Keine Migration erforderlich - rein visuelle Änderung.

## Zusammenfassung

- 16 Bottom Sheets auf Vollbild umgestellt
- Konsistente UX über die gesamte App
- Keine funktionalen Änderungen
