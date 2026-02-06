# Changelog v1.10.11 - Intelligente Sprachassistentin

**Build:** 192
**Datum:** 6. Februar 2026

## Übersicht

Erweiterung der Navigation-Sprachsteuerung zu einer intelligenten, sympathischen AI-Assistentin mit zufälligen Begrüßungen, erweiterten Sprachbefehlen und humorvoller Fehlerbehandlung.

---

## Neue Features

### 1. Zufällige Begrüßungen beim Sprachbutton

Beim Aktivieren der Spracherkennung spricht die AI jetzt eine zufällige Begrüßungsfrage:

| # | Deutsch | Englisch |
|---|---------|----------|
| 1 | "Bereit für deine Reise?" | "Ready for your trip?" |
| 2 | "Wie kann ich dir helfen?" | "How can I help you?" |
| 3 | "Was möchtest du wissen?" | "What would you like to know?" |
| 4 | "Ich höre!" | "I'm listening!" |
| 5 | "Frag mich was!" | "Ask me something!" |
| 6 | "Bereit für deinen Trip?" | "Ready for your journey?" |
| 7 | "Dein Navi-Assistent hier!" | "Your nav assistant here!" |
| 8 | "Wohin soll die Reise gehen?" | "Where shall we go?" |

### 2. Fünf neue Sprachbefehle

| Befehl | Keywords (DE) | Aktion |
|--------|---------------|--------|
| `routeWeather` | "Wetter", "Regen", "Temperatur" | Spricht das aktuelle Wetter auf der Route |
| `routeRecommendation` | "Empfehlung", "Tipp", "Highlight" | Empfiehlt Must-See POIs auf der Route |
| `tripOverview` | "Übersicht", "Meine Route" | Spricht Distanz und Anzahl Stopps |
| `remainingStops` | "Noch", "Verbleibend", "Rest" | Spricht Anzahl verbleibender Stopps |
| `helpCommands` | "Hilfe", "Was kannst du", "Befehle" | Erklärt verfügbare Sprachbefehle |

**Gesamt jetzt 14 Sprachbefehle** (9 bestehende + 5 neue)

### 3. Humorvolle Fehlerantworten

Bei unbekannten Sprachbefehlen antwortet die AI mit einer von 6 humorvollen Varianten:

| # | Antwort |
|---|---------|
| 1 | "Hmm, das hab ich nicht verstanden. Versuch mal 'Wie lange noch?' oder 'Nächster Stopp'" |
| 2 | "Ups! Mein Navi-Gehirn hat das nicht gecheckt. Sag 'Hilfe' für alle Befehle!" |
| 3 | "Das war wohl zu philosophisch für mich. Ich bin nur ein einfaches Navi!" |
| 4 | "Hä? Ich bin ein Navi, kein Gedankenleser! Frag mich nach der Route oder dem Wetter." |
| 5 | "Leider nicht verstanden. Probier 'Wo bin ich?' oder 'Was ist in der Nähe?'" |
| 6 | "Beep boop... Befehl nicht erkannt! Ich verstehe z.B. 'Wie lange noch?'" |

---

## Technische Änderungen

### voice_service.dart

```dart
// Neue VoiceCommand Enum-Werte
enum VoiceCommand {
  // ... bestehende ...
  routeWeather,        // NEU
  routeRecommendation, // NEU
  tripOverview,        // NEU
  remainingStops,      // NEU
  helpCommands,        // NEU
  unknown;
}

// Neue Methoden
String getRandomGreeting()        // 8 Begrüßungs-Varianten
String getUnknownCommandResponse() // 6 Fehler-Varianten

// Erweiterte Keywords für alle 5 Sprachen
_voiceKeywords: {
  'de': { 'weather': [...], 'recommend': [...], ... },
  'en': { 'weather': [...], 'recommend': [...], ... },
  'fr': { 'weather': [...], 'recommend': [...], ... },
  'it': { 'weather': [...], 'recommend': [...], ... },
  'es': { 'weather': [...], 'recommend': [...], ... },
}
```

### navigation_screen.dart

```dart
Future<void> _handleVoiceCommand() async {
  // NEU: Begrüßung sprechen vor dem Zuhören
  final greeting = voiceService.getRandomGreeting();
  await voiceService.speak(greeting);
  await Future.delayed(const Duration(milliseconds: 1500));

  // Dann Spracherkennung starten
  setState(() => _isListening = true);
  // ...
}

// Neue Cases in _executeVoiceCommand()
case VoiceCommand.routeWeather:
case VoiceCommand.routeRecommendation:
case VoiceCommand.tripOverview:
case VoiceCommand.remainingStops:
case VoiceCommand.helpCommands:
case VoiceCommand.unknown:
```

---

## Lokalisierung

**30+ neue ARB-Keys** in allen 5 Sprachen (DE, EN, FR, IT, ES):

### Begrüßungen
- `voiceGreeting1` - `voiceGreeting8`

### Fehlerantworten
- `voiceUnknown1` - `voiceUnknown6`

### Befehlslabels
- `voiceCmdRouteWeather`
- `voiceCmdRecommend`
- `voiceCmdOverview`
- `voiceCmdRemaining`
- `voiceCmdHelp`
- `voiceCmdUnknown`

### Antwort-Strings
- `voiceWeatherOnRoute`
- `voiceNoWeatherData`
- `voiceRecommendPOIs`
- `voiceNoRecommendations`
- `voiceRouteOverview`
- `voiceRemainingOne`
- `voiceRemainingMultiple`
- `voiceHelpText`

---

## Dateien geändert

| Datei | Änderungen |
|-------|------------|
| `lib/data/services/voice_service.dart` | +5 VoiceCommands, +Keywords, +getRandomGreeting(), +getUnknownCommandResponse() |
| `lib/features/navigation/navigation_screen.dart` | Begrüßung vor Lauschen, +6 neue Case-Handler |
| `lib/l10n/app_de.arb` | +30 neue Strings |
| `lib/l10n/app_en.arb` | +30 neue Strings |
| `lib/l10n/app_fr.arb` | +30 neue Strings |
| `lib/l10n/app_it.arb` | +30 neue Strings |
| `lib/l10n/app_es.arb` | +30 neue Strings |

---

## Testen

1. **Begrüßung testen**: Sprachbutton in Navigation drücken → Zufällige Frage hören
2. **Neue Befehle testen**:
   - "Wie ist das Wetter?" → Wetter-Ansage
   - "Was empfiehlst du?" → POI-Empfehlung
   - "Hilfe" → Befehlsliste vorlesen
3. **Fehlerbehandlung testen**: Unsinnigen Text sagen → Humorvolle Antwort
4. **Mehrsprachigkeit prüfen**: App-Sprache wechseln → Lokalisierte Antworten
