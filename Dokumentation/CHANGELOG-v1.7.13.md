# CHANGELOG v1.7.13 - Routen-Favoriten Bugfix

**Release-Datum:** 31. Januar 2026
**Version:** 1.7.13
**Build:** 1

---

## 🐛 Kritischer Bugfix: Routen-Favoriten

### Problem
Routen, die unter "Favoriten" gespeichert wurden, wurden nicht angezeigt. Beim Laden aus Hive trat ein JSON-Deserialisierungs-Fehler auf.

### Root Cause
Die Freezed Code-Generierung hatte fehlerhafte `toJson()` Methoden für die `Trip`-Klasse erstellt:

**Vorher (FALSCH):**
```dart
Map<String, dynamic> _$$TripImplToJson(_$TripImpl instance) =>
    <String, dynamic>{
      'route': instance.route,        // ❌ Dart-Objekt statt JSON
      'stops': instance.stops,        // ❌ Dart-Liste statt JSON-Array
      ...
    };
```

**Ergebnis:** Hive speicherte Dart-Objekte statt JSON-Maps, die beim Laden nicht deserialisiert werden konnten.

### Lösung
**Explizite JSON-Konverter** als top-level Funktionen hinzugefügt:

```dart
// lib/data/models/trip.dart

// JSON Converter für Trip nested objects (top-level Funktionen)
Map<String, dynamic> _tripRouteToJson(AppRoute route) => route.toJson();
AppRoute _tripRouteFromJson(Map<String, dynamic> json) =>
    AppRoute.fromJson(json);

List<Map<String, dynamic>> _tripStopsToJson(List<TripStop> stops) =>
    stops.map((s) => s.toJson()).toList();
List<TripStop> _tripStopsFromJson(List<dynamic> json) =>
    json.map((e) => TripStop.fromJson(e as Map<String, dynamic>)).toList();
```

**@JsonKey Annotationen** zur Factory-Klasse:

```dart
const factory Trip({
  @JsonKey(toJson: _tripRouteToJson, fromJson: _tripRouteFromJson)
  required AppRoute route,

  @JsonKey(toJson: _tripStopsToJson, fromJson: _tripStopsFromJson)
  @Default([]) List<TripStop> stops,
  ...
}) = _Trip;
```

**Gleiche Änderung für TripDay:**
```dart
const factory TripDay({
  @JsonKey(toJson: _tripDayStopsToJson, fromJson: _tripDayStopsFromJson)
  @Default([]) List<TripStop> stops,

  @JsonKey(
      toJson: _tripDayOvernightStopToJson,
      fromJson: _tripDayOvernightStopFromJson)
  TripStop? overnightStop,
  ...
}) = _TripDay;
```

**Ergebnis nach Code-Generierung:**
```dart
Map<String, dynamic> _$$TripImplToJson(_$TripImpl instance) =>
    <String, dynamic>{
      'route': _tripRouteToJson(instance.route),  // ✅ JSON-Map
      'stops': _tripStopsToJson(instance.stops),  // ✅ JSON-Array
      ...
    };
```

---

## 🔧 Neue Migration-Funktion

**Datei:** `lib/data/providers/favorites_provider.dart`

```dart
/// Löscht alle gespeicherten Routen (für Migration nach Bugfix v1.7.13)
Future<void> clearAllRoutes() async {
  final current = await _ensureLoaded();

  await _favoritesBox.put('saved_routes', []);
  state = AsyncValue.data(current.copyWith(savedRoutes: []));
  debugPrint('[Favorites] Alle Routen gelöscht (Migration)');
}
```

**Warum?** Alte Routen mit fehlerhafter Serialisierung können nicht geladen werden und müssen gelöscht werden.

---

## 📋 Betroffene Dateien

| Datei | Änderung |
|-------|----------|
| `lib/data/models/trip.dart` | JSON-Konverter hinzugefügt + @JsonKey Annotationen |
| `lib/data/models/trip.g.dart` | Automatisch neu generiert (korrekte toJson) |
| `lib/data/providers/favorites_provider.dart` | clearAllRoutes() Methode hinzugefügt |

---

## ⚠️ Breaking Changes & Migration

### Option A: App neu installieren (Empfohlen)
Die einfachste Methode:
1. App deinstallieren
2. Neue APK installieren
3. **Alle Hive-Daten werden gelöscht** (inkl. alte defekte Routen)

### Option B: Alte Routen manuell löschen
Falls du andere Favoriten behalten möchtest:
- Über Flutter DevTools → Hive Inspector → Box 'favorites' → Key 'saved_routes' löschen
- **POI-Favoriten bleiben erhalten**

### Option C: clearAllRoutes() aufrufen (für Entwickler)
```dart
// In einem Debug-Screen oder initState()
ref.read(favoritesNotifierProvider.notifier).clearAllRoutes();
```

---

## ✅ Verifikation

Nach dem Update sollten folgende Funktionen wieder funktionieren:

1. **Route speichern:**
   - TripScreen → Stern-Icon klicken
   - Routenname eingeben
   - Erfolgsmeldung erscheint

2. **Route in Favoriten anzeigen:**
   - Favoriten-Tab öffnen
   - "Routen" Tab auswählen
   - ✅ Route wird mit Name, Distanz, Dauer angezeigt

3. **Route laden:**
   - Auf gespeicherte Route klicken
   - ✅ Route erscheint auf Karte
   - ✅ Stops werden im TripScreen angezeigt

4. **Cloud-Sync (falls eingeloggt):**
   - ✅ Routen werden zu Supabase synchronisiert
   - ✅ Auf anderen Geräten verfügbar

---

## 🔍 Technische Details

### Warum funktionierte AppRoute aber Trip nicht?

**AppRoute (route.dart) - FUNKTIONIERT:**
```dart
@freezed
class AppRoute with _$AppRoute {
  const factory AppRoute({
    @LatLngConverter() required LatLng start,  // Expliziter Converter
    @LatLngConverter() required LatLng end,
    ...
  }) = _AppRoute;
}
```

Freezed erkennt `@LatLngConverter()` und generiert korrekt:
```dart
'start': const LatLngConverter().toJson(instance.start),
```

**Trip (trip.dart) - FUNKTIONIERTE NICHT:**
```dart
@freezed
class Trip with _$Trip {
  const factory Trip({
    required AppRoute route,  // ❌ Keine Annotation für nested Freezed-Klasse
    @Default([]) List<TripStop> stops,
    ...
  }) = _Trip;
}
```

Freezed generierte FEHLERHAFT:
```dart
'route': instance.route,  // ❌ Sollte instance.route.toJson() sein
```

**Fazit:** Nested Freezed-Klassen ohne explizite Converter-Annotation werden von Freezed **nicht automatisch** mit `.toJson()` serialisiert. Explizite `@JsonKey` Annotationen sind erforderlich.

---

## 📊 Auswirkungen

- **Betroffene User:** Alle, die Routen in Favoriten gespeichert haben (v1.7.10 - v1.7.12)
- **Datenintegrität:** POI-Favoriten ✅ nicht betroffen, Routen-Favoriten ❌ müssen neu gespeichert werden
- **Cloud-Sync:** Nach Migration funktioniert Sync wieder korrekt

---

## 🎯 Zusammenfassung

| Aspekt | Status |
|--------|--------|
| **Routen speichern** | ✅ Behoben |
| **Routen anzeigen** | ✅ Behoben |
| **Routen laden** | ✅ Behoben |
| **Cloud-Sync** | ✅ Behoben |
| **Migration nötig** | ⚠️ Ja - alte Routen löschen |
| **POI-Favoriten** | ✅ Nicht betroffen |

---

**Nächste Version:** v1.7.14 (geplant)
**Verwandte Issues:** Routen-Favoriten JSON-Serialisierung
**Tests:** Manueller Test durchgeführt ✅
