# MapAB v1.7.16 - WeatherBar einklappbar & Dauerhafte Adress-Anzeige

**Release-Datum:** 2026-01-31

## 🎯 Neue Features

### 1. WeatherBar jetzt einklappbar
- **Problem:** Wetter-Übersicht auf der Route nahm viel Platz ein
- **Lösung:** Ein-/Ausklapp-Funktion per Tap auf Header
- **Verhalten:**
  - Standard: Ausgeklappt beim ersten Anzeigen
  - Tap auf Header: Wechsel zwischen ein-/ausgeklappt
  - Expand-Icon (▼/▲) rotiert sanft (200ms Animation)
  - Eingeklappt: Nur Header sichtbar (Icon + Titel + Badge)
  - Ausgeklappt: Header + Wetter-Punkte + Alert

### 2. Dauerhafte Adress-Anzeige
- **Problem:** Start/Ziel-Adressen verschwanden nach Route-Berechnung
- **Lösung:** Neue `_RouteAddressBar` zeigt Adressen dauerhaft bis Route gelöscht wird
- **Features:**
  - 📍 Start-Adresse mit grünem Icon
  - 📍 Ziel-Adresse mit rotem Icon
  - 🛣️ Distanz + Dauer wenn Route berechnet (z.B. "5.2 km • 12 Min.")
  - 🎨 Dark-Mode kompatibel
  - 📱 Responsive mit Ellipsis bei langen Adressen
- **Position:** Zwischen Wetter-Empfehlung und Suchleiste (Schnell-Modus)

## 🔧 Technisch

### WeatherBar Änderungen
**Datei:** `lib/features/map/widgets/weather_bar.dart`
- Konvertiert von `ConsumerWidget` zu `ConsumerStatefulWidget`
- Neuer State: `_isExpanded` (bool, Default: true)
- `_WeatherHeader` erweitert mit `isExpanded` Parameter
- `InkWell` für tappable Header (Zeile 39-46)
- `AnimatedCrossFade` für Content Ein-/Ausklappen (Zeile 49-67)
- `AnimatedRotation` für Expand-Icon (Zeile 146-154)
- Animation-Dauer: 200ms (konsistent mit anderen Widgets)

### RouteAddressBar Implementierung
**Datei:** `lib/features/map/map_screen.dart`

**Neue Widgets:**
1. `_RouteAddressBar` (Zeile 2073-2147)
   - Container mit `surfaceContainerHighest` Background
   - Zeigt Start/Ziel nur wenn gesetzt (`hasStart || hasEnd`)
   - Distanz/Dauer nur wenn Route berechnet (`hasRoute`)

2. `_AddressRow` (Zeile 2149-2190)
   - Icon + Label + Adresse
   - Ellipsis bei langen Adressen
   - ColorScheme-kompatibel für Dark Mode

**Integration:**
- Position: Zeile 275 (nach `WeatherRecommendationBanner`, vor `_SearchBar`)
- Nur im Schnell-Modus sichtbar

**Architektur-Pattern:**
- Basiert auf `_CompactCategorySelector` Pattern
- AnimatedCrossFade + AnimatedRotation für sanfte UX
- State-Management via `setState()` (Widget-Level State)

## 📱 UX-Verbesserung

**Vorher:**
- Wetter-Übersicht immer ausgeklappt (viel Platz)
- Start/Ziel-Adressen nur in Suchleiste sichtbar
- Nach Route-Berechnung: Kein Überblick über Start/Ziel

**Nachher:**
- Wetter-Übersicht einklappbar → mehr Platz
- Adressen dauerhaft sichtbar bis Route gelöscht
- Klarer Überblick: Wohin fahre ich? Wie weit? Wie lange?
- Konsistentes Interaktions-Pattern (wie Kategorien-Auswahl)

## ✅ Testen

### WeatherBar:
1. Route berechnen → "Route starten" → WeatherBar ausgeklappt
2. Header tippen → WeatherBar eingeklappt (nur Header)
3. Erneut tippen → WeatherBar ausgeklappt
4. ▼/▲ Icon rotiert korrekt

### Adress-Anzeige:
1. Nur Start setzen → Zeigt nur Start
2. Nur Ziel setzen → Zeigt nur Ziel
3. Start + Ziel → Zeigt beide mit Trennlinie
4. Route berechnen → Distanz/Dauer erscheint
5. Route löschen → Adress-Bar verschwindet
6. Dark Mode → Farben korrekt

## 🎨 Design-Details

**WeatherBar Header:**
- Icon (24px) + Titel (14px, bold) + Badge (11px, colored)
- Expand-Icon (20px, onSurfaceVariant)
- Padding: 12px all

**RouteAddressBar:**
- Container: 12px padding, 12px border-radius
- Border: outline.withOpacity(0.2)
- Start-Icon: Grün (trip_origin)
- Ziel-Icon: Rot (location_on)
- Distanz-Icon: Primary (route, 14px)
- Font-Sizes: Label 10px, Adresse 13px, Route-Info 11px
