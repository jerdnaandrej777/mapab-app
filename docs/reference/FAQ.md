# Häufig gestellte Fragen (FAQ)

## Installation

### Q: Welche Flutter-Version wird benötigt?
**A:** Flutter 3.24.5 oder höher. Prüfe mit:
```bash
flutter --version
flutter upgrade
```

### Q: Build schlägt fehl mit "Missing generated files"
**A:** Führe die Code-Generierung aus:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Q: APK lässt sich nicht auf Android installieren
**A:**
1. Aktiviere "Unbekannte Quellen" in den Einstellungen
2. Prüfe, ob genug Speicherplatz vorhanden ist
3. Deinstalliere ggf. eine ältere Version der App

---

## Features

### Q: Warum lädt die AI nicht?
**A:** Mögliche Ursachen:
1. `BACKEND_URL` ist nicht korrekt gesetzt
2. Keine Internetverbindung
3. Rate-Limit erreicht (100 Chat/20 Trip-Pläne pro Tag)

Prüfe mit:
```bash
curl https://backend-gules-gamma-30.vercel.app/api/health
```

### Q: POIs werden nicht angezeigt
**A:** POI-Loading hat 3 Quellen:
1. **Curated** (lokal) - 527 POIs in assets/
2. **Wikipedia** (API) - 10km Radius-Limit
3. **Overpass** (API) - Benötigt Internet

Überprüfe:
- Internetverbindung
- GPS-Berechtigung erteilt
- Filter-Einstellungen (alle Kategorien aktiviert?)

### Q: Route wird nicht berechnet
**A:**
1. Sind Start UND Ziel gesetzt?
2. Internetverbindung verfügbar?
3. OSRM-Server erreichbar? (Prüfe Console-Logs)

### Q: Dark Mode funktioniert nicht richtig
**A:**
- In Einstellungen → Theme → "Dunkel" oder "System" wählen
- OLED-Modus für echtes Schwarz (#000000)
- App neu starten falls nötig

### Q: Favoriten werden nicht gespeichert
**A:**
- Im Gast-Modus werden Favoriten nur lokal gespeichert
- Für Cloud-Sync: Registrieren und einloggen
- Bei Problemen: App-Daten löschen und neu einloggen

---

## GPS & Karte

### Q: GPS funktioniert nicht im Emulator
**A:** Der Emulator hat keine echten GPS-Daten. Optionen:
1. Mock Location App verwenden
2. ADB-Befehle für simulierte Koordinaten
3. Auf echtem Gerät testen

### Q: Karte zeigt nur graue Flächen
**A:**
- Internetverbindung prüfen
- HTTPS erforderlich für Tile-Loading
- Cache leeren (Einstellungen → Cache löschen)

### Q: GPS-Fallback zeigt immer München
**A:** Das ist beabsichtigt. Bei fehlendem GPS wird München (48.1351, 11.5820) als Default verwendet.

---

## Account & Cloud

### Q: Registrierung funktioniert nicht
**A:**
- E-Mail-Format prüfen
- Passwort mindestens 6 Zeichen
- Supabase-Projekt erreichbar?

### Q: Daten werden nicht synchronisiert
**A:**
- Eingeloggt? (Gast-Modus hat keine Cloud-Sync)
- Internetverbindung vorhanden?
- Rate-Limit nicht erreicht?

### Q: Kann ich meine Daten exportieren?
**A:** Aktuell nicht direkt möglich. Favoriten und Trips werden in Supabase gespeichert und können über die API abgerufen werden.

---

## Performance

### Q: App ist langsam
**A:**
1. Release-Build verwenden (nicht Debug)
2. Riverpod DevTools deaktivieren in Produktion
3. POI-Cache nutzen (7 Tage gültig)

### Q: POI-Bilder laden langsam
**A:**
- Bilder werden lazy geladen
- Cache wird nach erstem Laden genutzt
- Netzwerkqualität beeinflusst Ladezeit

### Q: Hoher Speicherverbrauch
**A:**
- keepAlive Provider halten Daten im Speicher
- Bei älteren Geräten: App regelmäßig neu starten
- Cache leeren in Einstellungen

---

## Entwicklung

### Q: Wie füge ich einen neuen POI hinzu?
**A:** Editiere `assets/data/curated_pois.json`:
```json
{
  "id": "de-999",
  "n": "Neuer POI",
  "c": "castle",
  "lat": 48.1351,
  "lng": 11.5820,
  "r": 4.5
}
```

### Q: Wie füge ich eine neue Kategorie hinzu?
**A:** In `lib/core/constants/categories.dart`:
```dart
enum POICategory {
  // ...
  newCategory('new', 'Neue Kategorie', '🆕'),
}
```

### Q: Wie debugge ich Provider?
**A:** Nutze Log-Prefixes:
```dart
debugPrint('[POI] ${pois.length} POIs geladen');
```

Oder Riverpod DevTools aktivieren.

---

## Sonstiges

### Q: Unterstützt die App iOS?
**A:** Die Codebasis ist Flutter-basiert und theoretisch iOS-kompatibel. Aktuell wird nur Android aktiv unterstützt.

### Q: Ist die App Open Source?
**A:** Das Repository ist auf GitHub verfügbar. Siehe [CONTRIBUTING.md](../../CONTRIBUTING.md) für Beitrags-Richtlinien.

### Q: Wie melde ich einen Bug?
**A:**
1. GitHub Issue erstellen
2. Beschreibe das Problem detailliert
3. Füge Logs und Screenshots bei
4. Gib Gerät und OS-Version an

---

## Siehe auch

- [Troubleshooting](TROUBLESHOOTING.md)
- [Backend-Setup](../guides/BACKEND-SETUP.md)
- [Security](../SECURITY.md)
