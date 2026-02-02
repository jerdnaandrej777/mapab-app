# CHANGELOG v1.7.37 - AppBar-Fix & Panel-Kompaktierung

**Datum:** 2. Februar 2026
**Build:** 1.7.37+137

## Zusammenfassung

AppBar-Buttons (Favoriten, Profil, Settings) waren durch den Mode-Toggle verdeckt.
Panel war zu groß, sodass der "Überrasch mich!" Button abgeschnitten wurde.
Beide Probleme behoben durch Layout-Korrektur und Padding-Optimierung.

---

## Problem 1: AppBar-Buttons verdeckt

### Root Cause
`extendBodyBehindAppBar: true` bewirkte, dass der Body-Stack (inklusive Mode-Toggle)
ÜBER der AppBar gerendert wurde. Die SafeArea schützte zwar vor der StatusBar,
aber der Mode-Toggle begann direkt neben/über den AppBar-Buttons.

### Fix
```dart
// VORHER - Body rendert hinter AppBar
return Scaffold(
  extendBodyBehindAppBar: true,  // <- Problem!
  ...
);

// NACHHER - Body beginnt unter AppBar
return Scaffold(
  extendBodyBehindAppBar: false,
  ...
);
```

### SafeArea-Anpassung
```dart
// VORHER - doppeltes top-Padding (SafeArea + AppBar)
SafeArea(
  child: Padding(
    padding: const EdgeInsets.all(16),
    ...
  ),
)

// NACHHER - kein top-Padding noetig, AppBar uebernimmt
SafeArea(
  top: false,
  child: Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
    ...
  ),
)
```

---

## Problem 2: Panel zu groß / "Überrasch mich!" abgeschnitten

### Padding-Optimierung

| Element | Vorher | Nachher |
|---------|--------|---------|
| Start-Section Padding | `vertical: 8` | `vertical: 4` |
| Start-Label zu TextField | `SizedBox(height: 6)` | `SizedBox(height: 4)` |
| TextField contentPadding | `horizontal: 12, vertical: 10` | `horizontal: 10, vertical: 8` |
| Ziel-Section Padding | `vertical: 6` | `vertical: 4` |
| Ziel-Container Padding | `vertical: 10` | `vertical: 8` |
| Radius-Section Padding | `vertical: 6` | `vertical: 4` |
| Generate-Button Padding | `vertical: 8` (outer), `vertical: 12` (inner) | `vertical: 4` (outer), `vertical: 10` (inner) |
| Route-Loeschen Padding | `vertical: 8` | `vertical: 4` |
| CollapsibleTripPanel maxHeight | `0.65` | `0.75` |

### Geschaetzte Platzersparnis
- Padding-Reduktionen: ~30px
- AppBar nicht mehr ueberdeckt: ~56px mehr nutzbarer Platz
- **Gesamt: ~86px mehr Platz fuer Panel-Inhalt**

---

## Geaenderte Dateien

| Datei | Aenderungen |
|-------|-------------|
| `lib/features/map/map_screen.dart` | extendBodyBehindAppBar, SafeArea, alle Section-Paddings |
| `pubspec.yaml` | Version 1.7.36+136 -> 1.7.37+137 |
| `CLAUDE.md` | Version aktualisiert |
| `QR-CODE-DOWNLOAD.html` | Version, Links, Features aktualisiert |

---

## Hinweis: v1.7.36 Aenderungen (im selben Release enthalten)

Die folgenden Aenderungen wurden in v1.7.36 implementiert und sind in dieser APK enthalten:

- **Settings-Button in AppBar** statt FAB (immer sichtbar)
- **`_ensureGPSReady()`** ersetzt `_checkGPSAndShowDialog()` (prueft Services + Berechtigungen)
- **GPS-Timeout 10s -> 15s**, LocationAccuracy.high
- **Spezifische GPS-Fehlermeldungen** (TimeoutException, LocationServiceDisabled, Permission)
- **Ziel-Eingabe als BottomSheet** statt grossem Textfeld im Panel
- **Wetter-Widget kompakter** (reduzierte Margins, Fonts, Icons)
- **Startpunkt mit inline GPS-Button** (Label + GPS in einer Zeile)

---

## Verifikation

1. AppBar-Buttons (Favoriten, Profil, Settings) sichtbar und klickbar
2. Mode-Toggle (AI Tagestrip / AI Euro Trip) beginnt unter der AppBar
3. "Ueberrasch mich!" Button ohne Scrollen sichtbar (beide Modi)
4. Route-Loeschen Button erscheint nach Generierung und ist sichtbar
5. GPS-Button funktioniert (Snackbar bei Fehler)
6. Ziel-Button oeffnet BottomSheet korrekt
