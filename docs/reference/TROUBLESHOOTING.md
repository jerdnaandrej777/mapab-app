# Fehlerbehebung

## Build-Fehler

### "Gradle build failed"

```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter build apk
```

### "CocoaPods not found" (iOS)

```bash
sudo gem install cocoapods
cd ios
pod install
cd ..
flutter build ios
```

### "Missing generated files"

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Bei Konflikten:
```bash
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### "Dependency version solving failed"

```bash
flutter pub cache repair
flutter pub get
```

### "Android SDK not found"

1. Android Studio öffnen
2. SDK Manager → Android SDK installieren
3. Pfad in Umgebungsvariablen setzen:
   ```
   ANDROID_HOME=C:\Users\<name>\AppData\Local\Android\Sdk
   ```

---

## Runtime-Fehler

### "Supabase connection failed"

1. Überprüfe `SUPABASE_URL` und `SUPABASE_ANON_KEY`
2. Prüfe ob Credentials aktuell sind
3. Teste Verbindung:
   ```bash
   curl https://your-project.supabase.co/rest/v1/
   ```

### "AI responses timeout"

1. Backend Health-Check:
   ```bash
   curl https://backend-gules-gamma-30.vercel.app/api/health
   ```
2. Rate-Limit möglicherweise erreicht (warte 1 Stunde)
3. OpenAI-API-Quota prüfen (im Vercel Dashboard)

### "GPS permission denied"

Android:
1. App-Einstellungen → Berechtigungen → Standort
2. "Immer erlauben" oder "Während der Nutzung" wählen

### "Network image failed to load"

1. Internetverbindung prüfen
2. URL im Browser testen
3. Cache leeren:
   ```dart
   await DefaultCacheManager().emptyCache();
   ```

### "Hive box not found"

```dart
// In main.dart sicherstellen:
await Hive.initFlutter();
await Hive.openBox('settings');
await Hive.openBox('account');
await Hive.openBox('favorites');
```

---

## UI-Probleme

### Dark Mode zeigt weiße Elemente

Prüfe ob `colorScheme` verwendet wird:
```dart
// Falsch:
color: Colors.white

// Richtig:
color: Theme.of(context).colorScheme.surface
```

Siehe [DARK-MODE.md](../guides/DARK-MODE.md) für Details.

### Bottom Navigation überlappt Inhalt

```dart
Scaffold(
  // Padding für BottomNav hinzufügen
  body: Padding(
    padding: EdgeInsets.only(bottom: 80),
    child: content,
  ),
  bottomNavigationBar: BottomNav(),
)
```

### Keyboard überdeckt Input-Feld

```dart
Scaffold(
  resizeToAvoidBottomInset: true, // Default: true
  body: SingleChildScrollView(
    child: content,
  ),
)
```

### Text nicht lesbar (Kontrast)

```dart
// Dynamische Textfarbe
color: Theme.of(context).colorScheme.onSurface

// Sekundärer Text
color: Theme.of(context).textTheme.bodySmall?.color
```

---

## Performance-Probleme

### App startet langsam

1. Release-Build verwenden (nicht Debug)
2. Splash-Screen optimieren
3. Lazy-Loading für schwere Provider

### POI-Liste ruckelt

```dart
ListView.builder(
  cacheExtent: 500, // Mehr vorrendern
  addAutomaticKeepAlives: true,
)
```

### Speicher läuft voll

1. Bilder mit `memCacheWidth`/`memCacheHeight` skalieren
2. Nicht benötigte Provider mit `autoDispose`
3. Cache regelmäßig leeren

---

## API-Fehler

### Rate Limit (429)

```json
{
  "error": "Rate limit exceeded",
  "retryAfter": 3600
}
```

**Lösung:** Warte die angegebene Zeit, reduziere Anfragen.

### Unauthorized (401)

**Lösung:**
1. Token abgelaufen → Neu einloggen
2. Token fehlt → Auth-Header prüfen

### Internal Server Error (500)

**Lösung:**
1. Backend-Logs prüfen (Vercel Dashboard)
2. Request-Format validieren
3. Bei persistentem Fehler: Issue erstellen

---

## Häufige Fehler-Logs

### `[POI] Fehler beim Laden`

```
[POI] Fehler beim Laden von POIs: TimeoutException
```

**Ursache:** Overpass API langsam/nicht erreichbar
**Lösung:** Curated POIs werden als Fallback verwendet

### `[Enrichment] Wikipedia nicht gefunden`

```
[Enrichment] Kein Wikipedia-Artikel für: "Unbekannter Ort"
```

**Ursache:** POI hat keinen Wikipedia-Eintrag
**Lösung:** Normal, wird übersprungen

### `[RoutePlanner] Fehler bei Routenberechnung`

```
[RoutePlanner] Fehler: SocketException
```

**Ursache:** OSRM-Server nicht erreichbar
**Lösung:** Internetverbindung prüfen

---

## Debug-Modus aktivieren

### Console-Logs

Alle wichtigen Operationen loggen mit Prefix:
- `[POI]` - POI-Operationen
- `[Enrichment]` - Wikipedia/Wikimedia
- `[RoutePlanner]` - Routing
- `[Account]` - Auth/Account
- `[Settings]` - Einstellungen

### Riverpod DevTools

```dart
void main() {
  runApp(ProviderScope(
    observers: [ProviderLogger()],
    child: const MyApp(),
  ));
}
```

### Network Inspector

In Chrome DevTools (Flutter Web) oder Flipper (Android).

---

## Kontakt

Bei ungelösten Problemen:

1. **GitHub Issue:** https://github.com/jerdnaandrej777/mapab-app/issues
2. Beschreibe:
   - Fehler-Meldung (exakt)
   - Schritte zur Reproduktion
   - Gerät und OS-Version
   - App-Version
3. Füge Logs und Screenshots bei

---

## Siehe auch

- [FAQ](FAQ.md)
- [Contributing](../../CONTRIBUTING.md)
- [Security](../SECURITY.md)
