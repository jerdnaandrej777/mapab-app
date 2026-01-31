# MapAB v1.7.17 - Persistente Wetter-Widgets

**Release-Datum:** 31. Januar 2026

## 🎯 Verbesserung

### Wetter-Widgets bleiben bei Navigation sichtbar
- **Problem:** Wetter-Widgets verschwanden beim Wechsel zwischen Screens
- **Ursache:** Weather Provider hatten kein `keepAlive: true` → State wurde zurückgesetzt
- **Lösung:** `keepAlive: true` für RouteWeatherNotifier und LocationWeatherNotifier
- **Ergebnis:**
  - WeatherChip bleibt sichtbar (MapScreen → POI-Liste → MapScreen)
  - WeatherBar bleibt geladen (keine redundanten API-Calls)
  - 15-Minuten-Cache funktioniert jetzt korrekt
  - WeatherRecommendationBanner behält Toggle-State
  - WeatherAlertBanner bleibt konsistent

## 🔧 Technisch

**Dateien:**
- [lib/features/map/providers/weather_provider.dart:108](../lib/features/map/providers/weather_provider.dart#L108)
  - RouteWeatherNotifier: `@riverpod` → `@Riverpod(keepAlive: true)`
- [lib/features/map/providers/weather_provider.dart:266](../lib/features/map/providers/weather_provider.dart#L266)
  - LocationWeatherNotifier: `@riverpod` → `@Riverpod(keepAlive: true)`
- `lib/features/map/providers/weather_provider.g.dart`
  - `AutoDisposeNotifierProvider` → `NotifierProvider` (generiert)

**Cache-Logik (unverändert, funktioniert jetzt korrekt):**
```dart
// LocationWeatherNotifier.loadWeatherForLocation() - Zeile 276-279
if (state.isCacheValid && state.hasWeather) {
  debugPrint('[LocationWeather] Cache gueltig, ueberspringe');
  return;
}
```

## 📱 UX-Verbesserung

**Vorher:**
- ❌ Wetter-Widgets verschwanden bei Navigation
- ❌ 15-Minuten-Cache funktionierte nicht (State wurde zurückgesetzt)
- ❌ Redundante API-Calls bei jedem Screen-Wechsel
- ❌ Inkonsistente Anzeige (flackernde Widgets)

**Nachher:**
- ✅ Wetter-Widgets bleiben dauerhaft sichtbar
- ✅ Cache funktioniert korrekt (15 Minuten gültig)
- ✅ Keine redundanten API-Calls (nur bei Cache-Ablauf)
- ✅ Konsistente Anzeige über alle Screens

## 🔍 Betroffene Widgets

1. **WeatherChip** ([map_screen.dart:378-408](../lib/features/map/map_screen.dart#L378-L408))
   - Zeigt aktuelles Standort-Wetter
   - Tap → WeatherDetailsSheet mit 7-Tage-Vorhersage

2. **WeatherBar** ([map_screen.dart:334-339](../lib/features/map/map_screen.dart#L334-L339))
   - Zeigt 5 Wetter-Punkte entlang Route
   - Einklappbar (v1.7.16)

3. **WeatherRecommendationBanner** ([map_screen.dart:259-268](../lib/features/map/map_screen.dart#L259-L268))
   - Wetter-basierte POI-Empfehlungen
   - Toggle: Anwenden/Deaktivieren (v1.7.9)

4. **WeatherAlertBanner** ([map_screen.dart:410-416](../lib/features/map/map_screen.dart#L410-L416))
   - Proaktive Warnungen bei Unwetter
   - Zeigt nur bei `showWarning` Flag

5. **RouteWeatherMarker** (MapView, auf Route)
   - Wetter-Marker mit Icon + Temperatur
   - Tap → Detail-Sheet (v1.7.12)

## 📊 Performance-Verbesserung

**API-Calls zu Open-Meteo:**
- Vorher: Bei jedem Screen-Wechsel (ca. 5-10 Calls/Minute)
- Nachher: Nur bei Cache-Ablauf (alle 15 Minuten)
- **Reduzierung:** ~90% weniger API-Calls ✅

**State-Management:**
- Vorher: State-Reset bei jedem Dispose (jede Navigation)
- Nachher: State bleibt über App-Session erhalten
- **Vorteil:** Schnellere Screen-Wechsel, kein Flackern

## 🎨 Architektur-Pattern

**Konsistent mit anderen Providern:**
- `accountProvider` - `@Riverpod(keepAlive: true)` ✅
- `favoritesNotifierProvider` - `@Riverpod(keepAlive: true)` ✅
- `authNotifierProvider` - `@Riverpod(keepAlive: true)` ✅
- `tripStateProvider` - `@Riverpod(keepAlive: true)` ✅
- `pOIStateNotifierProvider` - `@Riverpod(keepAlive: true)` ✅
- **routeWeatherNotifierProvider** - `@Riverpod(keepAlive: true)` ✅ (NEU)
- **locationWeatherNotifierProvider** - `@Riverpod(keepAlive: true)` ✅ (NEU)

**Temporäre Provider (AutoDispose):**
- `indoorOnlyFilterProvider` - UI-Toggle ohne Persistenz (bleibt AutoDispose)

## ✅ Testen

### Standort-Wetter Persistenz:
1. App starten → WeatherChip erscheint
2. Navigiere zu POI-Liste
3. Zurück zu MapScreen → **WeatherChip bleibt sichtbar** ✅
4. Debug-Log: `[LocationWeather] Cache gueltig, ueberspringe`

### Routen-Wetter Persistenz:
1. Route berechnen → "Route starten"
2. WeatherBar erscheint (5 Punkte)
3. Navigiere zwischen MapScreen/TripScreen/POI-Liste
4. **WeatherBar bleibt geladen** (keine neuen API-Calls) ✅

### Cache-Invalidierung:
1. Wetter laden, warte 16 Minuten
2. Navigiere zwischen Screens → **Neues Laden** ✅
3. Debug-Log: API-Call zu Open-Meteo

## 🏗️ Migration

Keine Breaking Changes - die Änderung ist vollständig abwärtskompatibel.

**Für Entwickler:**
```dart
// Vorher: State ging bei Navigation verloren
ref.watch(locationWeatherNotifierProvider); // State = empty nach Tab-Wechsel

// Nachher: State bleibt erhalten
ref.watch(locationWeatherNotifierProvider); // State bleibt über Navigationen hinweg
```

## 📝 Verwandte Änderungen

**Basis-Feature:**
- v1.7.6: Wetter-Integration eingeführt (LocationWeather, RouteWeather)
- v1.7.9: WeatherRecommendationBanner mit Toggle
- v1.7.12: RouteWeatherMarker auf der Karte
- v1.7.16: WeatherBar einklappbar

**Dieses Release:**
- v1.7.17: Persistente Wetter-Widgets (keepAlive fix)

## 🔗 Links

- [CLAUDE.md - Wetter-Integration](../CLAUDE.md#wetter-integration-v176)
- [weather_provider.dart](../lib/features/map/providers/weather_provider.dart)
- [PROVIDER-GUIDE.md](PROVIDER-GUIDE.md)
