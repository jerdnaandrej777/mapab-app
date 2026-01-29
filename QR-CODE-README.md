# MapAB App - QR-Code Download

## Download-Link

**GitHub Release:** https://github.com/jerdnaandrej777/mapab-app/releases/tag/v1.6.7

## Verfügbare QR-Code Dateien

### 1. QR-CODE-DOWNLOAD.html
- **Vollständige Seite** mit Logo, Features und Anleitung
- Ideal zum Teilen per Link oder auf Website einbetten
- Responsive Design für alle Geräte

**Öffnen:**
```bash
start QR-CODE-DOWNLOAD.html
```

### 2. QR-CODE-SIMPLE.html
- **Minimalistische Version** zum Drucken
- Nur QR-Code + URL
- Print-optimiert

**Öffnen:**
```bash
start QR-CODE-SIMPLE.html
```

## Download-Optionen

### Via QR-Code:
1. Öffne eine der HTML-Dateien im Browser
2. Mit Android-Gerät QR-Code scannen (Kamera-App)
3. Link öffnet sich automatisch
4. APK herunterladen und installieren

### Direkter Link:
https://github.com/jerdnaandrej777/mapab-app/releases/tag/v1.6.7

## Verfügbare APKs

| Datei | Größe | Für |
|-------|-------|-----|
| **MapAB-v1.6.7.apk** | ~57 MB | **Empfohlen** - Universal |

## QR-Code drucken

### Methode 1: Browser (Chrome/Edge)
1. `QR-CODE-SIMPLE.html` öffnen
2. `Strg + P` oder "Drucken"-Button
3. Als PDF speichern oder direkt drucken

### Methode 2: Screenshot
1. `QR-CODE-DOWNLOAD.html` öffnen
2. Screenshot erstellen (`Win + Shift + S`)
3. Als PNG/JPG speichern und teilen

## Installation auf Android

1. **QR-Code scannen** mit Kamera-App
2. **GitHub Release** öffnet sich
3. **"MapAB-v1.6.7.apk"** herunterladen
4. **Installation erlauben:**
   - Einstellungen → Sicherheit
   - "Unbekannte Quellen" aktivieren (temporär)
5. **APK öffnen** und Installation bestätigen
6. **Fertig!** App starten und loslegen

## Features (v1.6.7)

### NEU in v1.6.7
- **POI-Detail Fotos Fix** - Enrichment wird jetzt vollständig abgewartet (await statt unawaited)
- **Highlights Fix** - POI-Highlights werden nach Routenberechnung korrekt angezeigt
- **Redundantes selectPOI() entfernt** - Verhindert Race Conditions
- **Bessere Performance** - Loading-Indikator wird korrekt angezeigt

### Aus v1.6.6
- **POI-Foto CORS-Fix** - Wikidata SPARQL bekommt jetzt `origin: '*'` Header
- **Rate-Limit-Handling** - HTTP 429 wird erkannt und 5 Sekunden gewartet
- **Weniger Concurrency** - Reduziert von 5 auf 3 parallele Enrichments
- **API-Call-Delays** - 200ms Pause zwischen Wikimedia-Calls
- **Erweitertes Error-Logging** - Detaillierte Logs für Debugging

### Aus v1.6.5
- **TripScreen vereinfacht** - Nur berechnete Routen werden angezeigt

### Aus v1.6.4
- **Snackbar entfernt** - POIs werden still zur Route hinzugefügt

### Aus v1.6.3
- **Euro Trip Route-Anzeige Fix** - Route erscheint jetzt auf Karte
- **keepAlive Fix** - RandomTripNotifier behält State bei Komponenten-Wechsel

### Aus v1.6.2
- **Euro Trip Performance-Fix** - Grid-Suche 100x schneller (vorher 10+ Min, jetzt ~4 Sek)
- **Timeout hinzugefügt** - Max 45 Sekunden für POI-Laden
- **Bessere Fehlermeldungen** - Klare Hinweise wenn keine POIs gefunden

### Aus v1.6.1
- **POI-Marker Direktnavigation** - Klick auf POI-Marker öffnet sofort Details
- **Kein Preview-Sheet** - Bottom Sheet Zwischenschritt entfernt

### Aus v1.6.0
- **POI-Fotos Lazy-Loading** - Alle Bilder werden jetzt beim Scrollen geladen
- **Kein Index-Limit mehr** - POIs ab Index 13 bekommen jetzt auch Bilder
- **ScrollController** - Debounced Scroll-Handler für effizientes Laden
- **Cache-Migration** - Alte POIs ohne Bilder werden automatisch entfernt

### Aus v1.5.9
- **GPS-Fallback entfernt** - POI-Liste zeigt Dialog statt München-Teststandort

### Aus v1.5.8
- **Login-Screen Fix** - Formular wird jetzt IMMER angezeigt
- **Warnmeldung** - Zeigt Hinweis wenn Supabase nicht konfiguriert

### Aus v1.5.7
- **Mehrtägige Euro Trips** - Automatische Tagesberechnung (600km = 1 Tag)
- **Tagesweiser Google Maps Export** - Exportiere jeden Tag einzeln
- **Max 9 POIs pro Tag** - Google Maps Waypoint-Limit automatisch beachtet
- **DayTabSelector** - Horizontale Tab-Leiste zur Tagesauswahl
- **Persistenz vorbereitet** - Trip-Fortsetzung am nächsten Tag (ActiveTripService)

### Aus v1.5.6
- **Floating Buttons ausblenden** - Einstellungen- und GPS-Button werden bei AI Trip ausgeblendet
- **Aufgeräumtere UI** - Mehr Platz für das AI Trip Panel

### Aus v1.5.5
- **POI-Card Layout-Fix** - Alle POIs werden jetzt in der Liste angezeigt
- **Feste Card-Höhe** - IntrinsicHeight Problem behoben

### Aus v1.5.4
- **GPS-Dialog** - Fragt ob GPS-Einstellungen geöffnet werden sollen (statt München-Fallback)

### Aus v1.5.3
- **POI-Liste zeigt alle POIs** - detourKm Filter nur bei aktivem routeOnlyMode
- **Fotos laden zuverlässiger** - Cache speichert nur POIs mit Bild
- **maxDetourKm erhöht** - Von 45 auf 100 km für bessere Abdeckung

### Aus v1.5.2
- **POI-Liste Filter Fix** - Filter werden automatisch zurückgesetzt wenn keine Route vorhanden
- **Cache-Verbesserung** - POIs werden neu geladen wenn Liste leer ist
- **Debug-Output** - Umfangreiche Logs für bessere Fehleranalyse

### Aus v1.5.1
- **POI-Liste Bugfix** - Race Condition beim Enrichment behoben

### Aus v1.5.0
- AI Trip direkt auf MapScreen - Karte bleibt immer sichtbar
- AI Trip POI-Marker - Nummerierte Icons mit Kategorie-Symbol
- Auto-Modus-Wechsel - Panel blendet nach Trip-Generierung aus
- Auto-Zoom auf Route - Karte zeigt generierte Route automatisch

### Aus v1.4.9
- AI Trip Navigation Fix - Keine separate Seite mehr
- Query-Parameter Support (`/trip?mode=ai`)

### Aus v1.4.8
- Integrierter Trip-Planer - AI Trip direkt im Trip-Screen
- Mode-Tabs - Umschalten zwischen "Schnell" und "AI Trip"
- Aufklappbare Kategorien - Übersichtliche POI-Auswahl
- Dark Mode optimiert - Alle Widgets nutzen colorScheme

### Aus v1.4.7
- Erweiterter Radius - Tagesausflug bis 300 km, Euro Trip bis 5000 km

### Aus v1.4.5/v1.4.6
- POI-Card Redesign - Kompaktes horizontales Layout
- AI-Chat Verbesserungen - Alle Vorschläge funktionieren
- POI-Liste Bugfixes

### Aus v1.4.4
- POI-Löschen - Einzelne POIs aus AI-Trip entfernen
- POI-Würfeln - Einzelnen POI neu würfeln (nicht gesamten Trip)
- Per-POI Loading - Individuelle Ladeanzeige pro POI

### Basis-Features
- Cloud-Sync für Trips & Favoriten
- Email/Passwort Registrierung & Login
- AI über sicheres Backend (kein API-Key im Client)
- Account-System mit XP & 21 Achievements
- AI-Chat mit GPT-4o
- AI-Trip-Generator (1-7 Tage)
- Dark Mode mit Auto-Sunset
- POI-Enrichment (Wikipedia/Wikimedia)
- Interaktive Karte mit POI-Markern
- Routenplanung (Fast/Scenic)
- Favoriten-Management
- Gast-Modus (offline nutzbar)
- Google Maps Export - Funktioniert auf Android 11+
- Route Teilen - WhatsApp, Email, SMS
- Neues App-Logo mit App-Farben (Blau/Grün)
- Mehr POIs - Filter gelockert
- Login-Fix - Remember Me funktioniert
- Onboarding - Animierte Intro
- Performance-Optimierungen
- Region-Cache (7 Tage)

## Support

Bei Problemen:
- GitHub Issues: https://github.com/jerdnaandrej777/mapab-app/issues
- Repository: https://github.com/jerdnaandrej777/mapab-app

---

**Version:** 1.6.7
**Build-Datum:** 29. Januar 2026
**Flutter SDK:** 3.38.7
