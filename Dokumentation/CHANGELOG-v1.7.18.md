# MapAB v1.7.18 - Snackbar Auto-Dismiss

**Release-Datum:** 31. Januar 2026

## 🎯 Verbesserung

### Route-Speichern Snackbar verschwindet automatisch
- **Problem:** Die "Route gespeichert" Snackbar blieb 4 Sekunden sichtbar (Flutter-Standard)
- **Feedback:** Benutzer wünschen sich schnelleres Ausblenden der Erfolgsmeldung
- **Lösung:** `duration: const Duration(seconds: 1)` Parameter hinzugefügt
- **Ergebnis:**
  - Snackbar verschwindet nach genau 1 Sekunde
  - "Anzeigen" Button bleibt innerhalb dieser Zeit funktionsfähig
  - Schnellere, weniger aufdringliche Benutzerführung
  - Gilt für beide Speicher-Modi (reguläre Route & AI Trip)

## 🔧 Technisch

**Dateien:**
- [lib/features/trip/trip_screen.dart:221](../lib/features/trip/trip_screen.dart#L221)
  - `_saveRoute()` Methode: SnackBar mit `duration` Parameter
- [lib/features/trip/trip_screen.dart:293](../lib/features/trip/trip_screen.dart#L293)
  - `_saveAITrip()` Methode: SnackBar mit `duration` Parameter

**Code-Änderung:**
```dart
// VORHER - Standard-Duration (4 Sekunden)
SnackBar(
  content: Text('Route "$result" gespeichert'),
  action: SnackBarAction(
    label: 'Anzeigen',
    onPressed: () => context.push('/favorites'),
  ),
),

// NACHHER - Auto-Dismiss nach 1 Sekunde
SnackBar(
  content: Text('Route "$result" gespeichert'),
  duration: const Duration(seconds: 1),  // NEU
  action: SnackBarAction(
    label: 'Anzeigen',
    onPressed: () => context.push('/favorites'),
  ),
),
```

## 📱 UX-Verbesserung

**Vorher:**
- ❌ Snackbar blieb 4 Sekunden sichtbar
- ❌ Blockierte unnötig lange den unteren Bildschirmbereich
- ❌ Verzögerte weitere Interaktionen

**Nachher:**
- ✅ Snackbar verschwindet nach 1 Sekunde
- ✅ Schnelles visuelles Feedback
- ✅ Weniger aufdringliche Benachrichtigung
- ✅ Benutzer kann schneller weiterarbeiten

## 🔍 Betroffene Szenarien

1. **Reguläre Route speichern** ([trip_screen.dart:197-228](../lib/features/trip/trip_screen.dart#L197-L228))
   - User öffnet More-Options → "Route speichern"
   - Dialog für Route-Namen
   - Nach Speichern: Snackbar für 1 Sekunde
   - "Anzeigen" Button navigiert zu Favoriten

2. **AI Trip speichern** ([trip_screen.dart:231-299](../lib/features/trip/trip_screen.dart#L231-L299))
   - User generiert AI Trip
   - More-Options → "Route speichern"
   - Dialog für Trip-Namen (mit Vorschlag basierend auf Modus)
   - Nach Speichern: Snackbar für 1 Sekunde
   - "Anzeigen" Button navigiert zu Favoriten

## 📊 Timing-Details

| Aktion | Vorher | Nachher | Verbesserung |
|--------|--------|---------|--------------|
| Snackbar-Dauer | 4000 ms | 1000 ms | -75% |
| Button verfügbar | Ja (4 Sek) | Ja (1 Sek) | Funktional |
| Auto-Dismiss | Ja | Ja | ✅ |
| Manuell schließbar | Ja (Swipe) | Ja (Swipe) | ✅ |

## ✅ Testen

### Route speichern:
1. Route mit Start/Ziel berechnen
2. TripScreen → More-Options (•••) → "Route speichern"
3. Namen eingeben → "Speichern"
4. **Snackbar erscheint und verschwindet nach 1 Sekunde** ✅
5. Optional: Auf "Anzeigen" klicken innerhalb der Sekunde

### AI Trip speichern:
1. AI Trip generieren (MapScreen → AI Trip Modus)
2. "Überrasch mich!" → Trip wird generiert
3. TripScreen → More-Options (•••) → "Route speichern"
4. Namen eingeben (Vorschlag: "AI Tagesausflug" / "AI Euro Trip")
5. **Snackbar erscheint und verschwindet nach 1 Sekunde** ✅

### "Anzeigen" Button:
1. Route speichern
2. **Schnell** auf "Anzeigen" Button klicken (innerhalb 1 Sekunde)
3. **Navigation zu Favoriten funktioniert** ✅

## 🏗️ Migration

Keine Breaking Changes - die Änderung betrifft nur die UI-Timing.

**Flutter SnackBar Duration:**
```dart
// Flutter Standard: 4 Sekunden (wenn duration nicht gesetzt)
SnackBar(content: Text('Message'));

// Custom Duration: 1-10 Sekunden empfohlen
SnackBar(
  content: Text('Message'),
  duration: const Duration(seconds: 1),  // Min: 1, Max: ~10
);
```

## 📝 Verwandte Änderungen

**Route Speichern Feature:**
- v1.7.10: Routen in Favoriten speichern & laden
- v1.7.10: "Route speichern" aus More-Options

**Dieses Release:**
- v1.7.18: Snackbar Auto-Dismiss nach 1 Sekunde

## 🔗 Links

- [trip_screen.dart](../lib/features/trip/trip_screen.dart)
- [CLAUDE.md - Route zu Favoriten speichern](../CLAUDE.md#route-zu-favoriten-speichern-v1710)
- [Flutter SnackBar Documentation](https://api.flutter.dev/flutter/material/SnackBar-class.html)
