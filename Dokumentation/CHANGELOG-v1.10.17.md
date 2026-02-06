# Changelog v1.10.17 (Build 201)

## Trip auf Karte anzeigen

Dieses Release implementiert die "Auf Karte"-Funktion für veröffentlichte Trips in der Trip-Galerie.

### Neue Features

#### Veröffentlichte Trips auf Karte anzeigen (Build 201)
- **Feature:** "Auf Karte"-Button zeigt jetzt den kompletten Trip auf der Hauptkarte an
- **Vorher:** Button zeigte nur "Karten-Ansicht wird bald verfügbar" Snackbar
- **Nachher:**
  - Route wird als Polyline auf der Karte dargestellt
  - Alle Stops werden als POI-Marker angezeigt
  - Karte zoomt automatisch auf den Trip
- **Vorteil:** Benutzer können sich Trips vor dem Import auf der Karte ansehen

### Technische Details

#### Route-Parsing aus tripData
- Extrahiert Koordinaten aus `tripData['route']['coordinates']`
- Erstellt `AppRoute`-Objekt mit Start, End, Distanz und Dauer
- Parst Stops und erstellt `POI`-Objekte mit ID, Name, Kategorie

#### Provider-Integration
- Nutzt `tripStateProvider.setRouteAndStops()` zum Laden der Route
- Setzt `shouldFitToRouteProvider` für automatischen Karten-Zoom
- Navigiert zur Hauptkarte mit `context.go('/')`

### Geänderte Dateien

| Datei | Änderung |
|-------|----------|
| `lib/features/social/trip_detail_public_screen.dart` | `_showOnMap()` implementiert: Route-Parsing, POI-Erstellung, Provider-Integration |
| `lib/l10n/app_de.arb` | Neue Keys: `galleryMapNoData`, `galleryMapError` |
| `lib/l10n/app_en.arb` | Englische Übersetzungen |
| `lib/l10n/app_fr.arb` | Französische Übersetzungen |
| `lib/l10n/app_it.arb` | Italienische Übersetzungen |
| `lib/l10n/app_es.arb` | Spanische Übersetzungen |

### Neue Lokalisierungs-Keys

| Key | DE | EN |
|-----|----|----|
| `galleryMapNoData` | Keine Route-Daten verfügbar | No route data available |
| `galleryMapError` | Fehler beim Laden der Route | Error loading route |

### Code-Änderungen

#### _showOnMap() Implementierung

```dart
void _showOnMap(PublicTrip trip) {
  final tripData = trip.tripData;
  if (tripData == null) {
    AppSnackbar.showError(context, context.l10n.galleryMapNoData);
    return;
  }

  try {
    // Route-Koordinaten extrahieren
    final routeData = tripData['route'] as Map<String, dynamic>?;
    final coordsList = routeData?['coordinates'] as List<dynamic>? ?? [];
    final coordinates = coordsList.map((c) {
      final map = c as Map<String, dynamic>;
      return LatLng(
        (map['lat'] as num).toDouble(),
        (map['lng'] as num).toDouble(),
      );
    }).toList();

    // AppRoute erstellen
    final route = AppRoute(
      start: coordinates.first,
      end: coordinates.last,
      startAddress: trip.tripName,
      endAddress: trip.tripName,
      coordinates: coordinates,
      distanceKm: trip.distanceKm ?? 0,
      durationMinutes: ((trip.durationHours ?? 0) * 60).round(),
    );

    // Stops parsen
    final stopsData = tripData['stops'] as List<dynamic>? ?? [];
    final stops = stopsData.map((s) {
      final map = s as Map<String, dynamic>;
      return POI(
        id: map['poiId'] as String? ?? 'stop-${map.hashCode}',
        name: map['name'] as String? ?? 'Stop',
        latitude: (map['latitude'] as num).toDouble(),
        longitude: (map['longitude'] as num).toDouble(),
        categoryId: map['category'] as String? ?? 'attraction',
      );
    }).toList();

    // Route auf Karte laden
    ref.read(tripStateProvider.notifier).setRouteAndStops(route, stops);
    ref.read(shouldFitToRouteProvider.notifier).state = true;
    context.go('/');
  } catch (e) {
    AppSnackbar.showError(context, context.l10n.galleryMapError);
  }
}
```

---

**Build:** 201
**Version:** 1.10.17
**Datum:** 2026-02-06
