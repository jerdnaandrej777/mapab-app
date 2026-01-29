# Changelog v1.4.6 - POI-Liste & AI-Chat Bugfixes

**Build-Datum:** 24. Januar 2026
**Flutter SDK:** 3.38.7

---

## Bugfixes

### POI-Liste zeigt nur 1 POI statt 2000+

**Problem:** Nach dem Erstellen einer Route und anschließendem Schließen wurde die POI-Liste fast leer angezeigt (nur 1 POI), obwohl über 2000 POIs geladen wurden.

**Ursache:** Der `routeOnlyMode` Filter blieb nach einer Route-Session auf `true` gesetzt. Dieser Filter entfernt alle POIs ohne `routePosition`. Wenn POIs ohne Route geladen werden (via GPS-Standort), haben sie keine `routePosition` und wurden alle herausgefiltert.

**Lösung:** Der `routeOnlyMode` wird jetzt explizit deaktiviert wenn keine Route vorhanden ist, bevor POIs geladen werden.

**Geänderte Datei:**
- `lib/features/poi/poi_list_screen.dart`

```dart
// WICHTIG: Wenn keine Route vorhanden ist, routeOnlyMode deaktivieren
// Sonst werden alle POIs herausgefiltert (da sie keine routePosition haben)
poiNotifier.setRouteOnlyMode(false);
debugPrint('[POIList] Keine Route vorhanden - routeOnlyMode deaktiviert');
```

---

### AI-Chat zeigt "Demo-Modus - keine Verbindung zum Backend"

**Problem:** Der AI-Chat zeigte permanent "Demo-Modus: Backend nicht erreichbar", obwohl das Backend möglicherweise nur nicht konfiguriert war.

**Ursache:**
1. Die `BACKEND_URL` war nicht per `--dart-define` gesetzt (Default ist leerer String `''`)
2. Der Health-Check versuchte trotzdem eine Anfrage zu senden, was fehlschlug
3. Die Fehlermeldung unterschied nicht zwischen "nicht konfiguriert" und "nicht erreichbar"

**Lösung:**
1. Der Health-Check prüft jetzt zuerst ob `ApiConfig.isConfigured` ist
2. Die Fehlermeldung im Chat zeigt jetzt den genauen Grund an:
   - "Backend-URL nicht konfiguriert" - wenn `BACKEND_URL` fehlt
   - "Backend nicht erreichbar" - wenn URL konfiguriert aber Server nicht antwortet
3. "Erneut prüfen"-Button wird nur angezeigt wenn URL konfiguriert ist

**Geänderte Dateien:**
- `lib/data/services/ai_service.dart`
- `lib/features/ai_assistant/chat_screen.dart`

```dart
// ai_service.dart - Health-Check mit Konfigurationsprüfung
Future<bool> checkHealth() async {
  if (!ApiConfig.isConfigured) {
    debugPrint('[AI] Backend nicht konfiguriert (BACKEND_URL fehlt in --dart-define)');
    return false;
  }
  // ... Rest des Health-Checks
}

// chat_screen.dart - Spezifische Fehlermeldung
final isConfigured = ApiConfig.isConfigured;
final message = isConfigured
    ? 'Demo-Modus: Backend nicht erreichbar'
    : 'Demo-Modus: Backend-URL nicht konfiguriert';
```

---

## Hinweis: Backend-URL konfigurieren

Um das AI-Backend zu aktivieren, muss die App mit der Backend-URL gestartet werden:

### Entwicklung
```bash
flutter run --dart-define=BACKEND_URL=https://dein-backend.vercel.app
```

### Release-Build
```bash
flutter build apk --release \
  --dart-define=BACKEND_URL=https://dein-backend.vercel.app \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...
```

---

## Technische Details

### routeOnlyMode Verhalten

Der `routeOnlyMode` ist ein Filter im `POIState`, der nur POIs mit `routePosition` (auf der Route) anzeigt:

```dart
// poi_state_provider.dart - Filter-Logik
if (routeOnlyMode) {
  result = result.where((poi) => poi.routePosition != null).toList();
}
```

**Wann wird routeOnlyMode aktiviert?**
- `RouteSession.startRoute()` aktiviert `routeOnlyMode` für POIs auf der Route

**Wann wird routeOnlyMode deaktiviert?**
- `RouteSession.stopRoute()` deaktiviert den Modus
- `POIListScreen._loadPOIs()` deaktiviert den Modus wenn keine Route vorhanden **(NEU in v1.4.6)**

### ApiConfig.isConfigured

```dart
// api_config.dart
static const String backendBaseUrl = String.fromEnvironment(
  'BACKEND_URL',
  defaultValue: '',  // Leer wenn nicht konfiguriert
);

static bool get isConfigured => backendBaseUrl.isNotEmpty;
```

---

## Debugging

### Neue Log-Nachrichten

| Prefix | Nachricht |
|--------|-----------|
| `[POIList]` | `Keine Route vorhanden - routeOnlyMode deaktiviert` |
| `[AI]` | `Backend nicht konfiguriert (BACKEND_URL fehlt in --dart-define)` |

---

## Download

- **APK:** `MapAB-v1.4.6.apk` (~57 MB)
- **GitHub Release:** https://github.com/jerdnaandrej777/mapab-app/releases/tag/v1.4.6
