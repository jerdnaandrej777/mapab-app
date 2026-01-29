# Changelog v1.4.1 - Google Maps Export Fix

**Release-Datum:** 23. Januar 2026
**Build:** 1.4.1+1

## Zusammenfassung

Diese Version behebt das Problem, dass der Google Maps Export auf Android 11+ (API 30+) Geräten nicht funktionierte.

---

## Bugfixes

### Google Maps Export funktioniert wieder

**Problem:** Auf Android 11+ Geräten konnte die App Google Maps nicht öffnen. Der "Google Maps" Button im Trip-Screen zeigte nur eine Fehlermeldung.

**Ursache:** Seit Android 11 müssen Apps explizit deklarieren, welche anderen Apps sie aufrufen möchten (`<queries>` in AndroidManifest.xml). Diese Deklarationen fehlten.

**Lösung:**
- `AndroidManifest.xml` erweitert um Queries für:
  - `https` / `http` URLs (Google Maps, Browser)
  - `tel` Schema (Telefonnummern)
  - `mailto` Schema (E-Mail)

### Route Teilen verbessert

- Locale-sichere Koordinaten-Formatierung mit `toStringAsFixed(6)`
- Try-catch Fehlerbehandlung für bessere Stabilität
- Debug-Logging mit `[GoogleMaps]` Prefix für einfacheres Debugging

---

## Technische Details

### Geänderte Dateien

| Datei | Änderung |
|-------|----------|
| `android/app/src/main/AndroidManifest.xml` | `<queries>` für URL-Launcher hinzugefügt |
| `lib/features/trip/trip_screen.dart` | `_openInGoogleMaps()` und `_shareRoute()` verbessert |
| `pubspec.yaml` | Version 1.4.0 → 1.4.1 |

### AndroidManifest.xml Änderungen

```xml
<queries>
    <!-- Text selection (Flutter engine) -->
    <intent>
        <action android:name="android.intent.action.PROCESS_TEXT"/>
        <data android:mimeType="text/plain"/>
    </intent>

    <!-- HTTPS URLs (Google Maps, Websites) -->
    <intent>
        <action android:name="android.intent.action.VIEW"/>
        <category android:name="android.intent.category.BROWSABLE"/>
        <data android:scheme="https"/>
    </intent>

    <!-- HTTP URLs (Fallback) -->
    <intent>
        <action android:name="android.intent.action.VIEW"/>
        <category android:name="android.intent.category.BROWSABLE"/>
        <data android:scheme="http"/>
    </intent>

    <!-- Phone calls (POI details, Hotel) -->
    <intent>
        <action android:name="android.intent.action.VIEW"/>
        <data android:scheme="tel"/>
    </intent>

    <!-- Email (POI details, Hotel) -->
    <intent>
        <action android:name="android.intent.action.VIEW"/>
        <data android:scheme="mailto"/>
    </intent>
</queries>
```

### Code-Verbesserungen in trip_screen.dart

```dart
// Vorher
final origin = '${route.start.latitude},${route.start.longitude}';

// Nachher (locale-safe)
final origin = '${route.start.latitude.toStringAsFixed(6)},${route.start.longitude.toStringAsFixed(6)}';
```

```dart
// Vorher
if (await canLaunchUrl(uri)) {
  await launchUrl(uri, mode: LaunchMode.externalApplication);
} else {
  // Error
}

// Nachher (robuster)
try {
  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
} catch (e) {
  debugPrint('[GoogleMaps] Error: $e');
  // Error handling
}
```

---

## Test-Szenarien

- [x] Google Maps mit Route öffnen (ohne Stops)
- [x] Google Maps mit Route + Waypoints öffnen
- [x] Route teilen via WhatsApp/Email
- [x] Telefonnummer öffnen (POI-Detail)
- [x] Website öffnen (POI-Detail)
- [x] Email öffnen (POI-Detail)

---

## Upgrade-Hinweise

Keine besonderen Upgrade-Schritte erforderlich. Einfach die neue APK installieren.

---

## Download

- **APK:** `MapAB-v1.4.1.apk` (57 MB)
- **GitHub Release:** https://github.com/jerdnaandrej777/mapab-app/releases/tag/v1.4.1
