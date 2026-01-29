# Changelog v1.4.5 - POI-Card Redesign & AI-Chat Verbesserungen

**Build-Datum:** 24. Januar 2026
**Flutter SDK:** 3.38.7

---

## Neue Features

### POI-Karten Redesign (Kompaktes Layout)

**Problem:** Die POI-Karten in der Liste zeigten Bilder über die volle Breite, was viel Platz verbrauchte und die Bilder oft verzerrt wirken ließ.

**Lösung:** Neues horizontales Layout mit quadratischem Bild (88x88px) links und Inhalt rechts.

**Vorteile:**
- **Mehr POIs sichtbar** - Kompaktere Darstellung zeigt mehr POIs auf einmal
- **Keine Bildverzerrung** - 1:1 Seitenverhältnis mit `BoxFit.cover`
- **Schnellere Ladezeit** - Kleinere Bilder (176px Cache statt 400px)
- **Cleaner Look** - Dezentere Schatten, kompaktere Badges

**UI-Änderungen:**
| Element | Vorher | Nachher |
|---------|--------|---------|
| Bild | 140px Höhe, volle Breite | 88x88px quadratisch links |
| Layout | Vertikal (Bild oben) | Horizontal (Bild links) |
| Badges | Text + Icon | Nur Icons (vertikal gestapelt) |
| Kategorie-Icon | Auf dem Bild | Neben dem Namen |
| Add-Button | IconButton | Kompakter runder Button |

### AI-Assistent Überarbeitung

**Problem:** Nur "AI-Trip generieren" funktionierte, alle anderen Vorschläge zeigten Fehler.

**Lösung:** Komplette Überarbeitung des AI-Assistenten mit:

1. **Alle Vorschläge funktionieren:**
   - 🤖 AI-Trip generieren → Dialog (wie bisher)
   - 🗺️ Sehenswürdigkeiten auf Route → Zeigt aktuelle Stops
   - 🌲 Naturhighlights zeigen → Zeigt Empfehlungen
   - 🍽️ Restaurants empfehlen → Zeigt Restaurant-Tipps

2. **Backend-Health-Check:**
   - Prüft beim Start ob Backend erreichbar
   - Automatischer Demo-Modus bei Fehler
   - Status-Banner zeigt Verbindungsstatus

3. **Intelligente Demo-Antworten:**
   - Erkennt Schlüsselwörter (Sehenswürdigkeiten, Natur, Restaurants, Hotels, Wetter, Route, Städte)
   - Zeigt kontextbezogene Antworten basierend auf Trip-State
   - Hilfreiche Tipps zur App-Nutzung

4. **User-Eingaben werden verarbeitet:**
   - Chat-History wird an Backend gesendet
   - Trip-Kontext (Route, Stops) wird mitgesendet
   - Sinnvolle Demo-Antworten bei Backend-Fehler

### Dark-Mode-Kompatibilität

**Problem:** Mehrere Widgets verwendeten hart-codierte Farben (`Colors.white`, `AppTheme.primaryColor`).

**Lösung:** Alle AI-Chat-Widgets nutzen jetzt `colorScheme`:

- `ChatMessageBubble` - User/AI Bubbles, Avatare, Loading-Animation
- `SuggestionChips` - Vorschlag-Buttons
- `ChatScreen` - Eingabefeld, Status-Banner, Empty-State

---

## Technische Änderungen

### Geänderte Dateien

| Datei | Änderung |
|-------|----------|
| `lib/features/poi/widgets/poi_card.dart` | Komplett neu: Horizontales Layout |
| `lib/features/ai_assistant/chat_screen.dart` | Komplett überarbeitet: Health-Check, Handler, Demo-Mode |
| `lib/features/ai_assistant/widgets/chat_message.dart` | Dark-Mode, verbesserte Animation |
| `lib/features/ai_assistant/widgets/suggestion_chips.dart` | Dark-Mode, InkWell |

### POI-Card Änderungen

```dart
// Bildgröße
static const double _imageSize = 88.0;

// Neues Layout
Row(
  children: [
    _buildImage(colorScheme),      // Links: Quadratisches Bild
    Expanded(child: _content()),   // Rechts: Name, Kategorie, Rating
  ],
)

// Cache-Optimierung
memCacheWidth: 176,  // 2x für Retina (vorher 400)
memCacheHeight: 176,
```

### AI-Chat Änderungen

```dart
// Backend-Health-Check
@override
void initState() {
  super.initState();
  _checkBackendHealth();
}

// Vorschläge-Handler
void _handleSuggestionTap(String suggestion) {
  switch (suggestion) {
    case '🤖 AI-Trip generieren':
      _showTripGeneratorDialog();
    case '🗺️ Sehenswürdigkeiten auf Route':
      _handleSehenswuerdigkeitenRequest();
    // ...
  }
}

// Intelligente Demo-Antworten
String _generateSmartDemoResponse(String query) {
  if (lowerQuery.contains('sehenswürd')) { ... }
  if (lowerQuery.contains('restaurant')) { ... }
  // ...
}
```

---

## UI-Vergleich

### POI-Karte

**Vorher (v1.4.4):**
```
┌──────────────────────────────┐
│  [═══════ BILD ═══════════] │ 140px
│  ⭐ Must-See         🏰     │
├──────────────────────────────┤
│  Schloss Neuschwanstein      │
│  Schloss • 12.5 km Umweg     │
│  ★★★★☆ 4.8 (15K)      [+]  │
└──────────────────────────────┘
```

**Nachher (v1.4.5):**
```
┌────────────────────────────────┐
│ ┌──────┐ Schloss Neuschwanstein 🏰│
│ │      │ Schloss • 12.5 km Umweg  │
│ │ BILD │                          │
│ │ ⭐   │ ★ 4.8 (15K)         (+) │
│ └──────┘                          │
└────────────────────────────────┘
```

### AI-Chat Vorschläge

**Vorher:** Nur "AI-Trip generieren" funktioniert
**Nachher:** Alle 4 Vorschläge haben eigene Handler

---

## Enthält auch (aus v1.4.4)

- **POI-Löschen:** Einzelne POIs aus AI-Trip entfernen
- **POI-Würfeln:** Einzelnen POI neu würfeln (nicht gesamten Trip)
- **Per-POI Loading:** Individuelle Ladeanzeige pro POI

---

## Download

- **APK:** `MapAB-v1.4.5.apk` (~57 MB)
- **GitHub Release:** https://github.com/jerdnaandrej777/mapab-app/releases/tag/v1.4.5
