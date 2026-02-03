# CHANGELOG v1.9.4 - DayEditor Button-Redesign

**Datum:** 3. Februar 2026
**Build:** 1.9.4+150

## Zusammenfassung

Komplettes Redesign der Bottom-Action-Buttons im DayEditorOverlay. Der "Navigation starten" Button ist jetzt die dominante primaere Aktion. Neuer "Route Teilen" Button ermoeglicht das Teilen der Tages-Route. Das Layout wechselt von einer einzeiligen Row zu einem 3-Ebenen Column-Layout.

---

## Feature 1: Dominanter Navigation-Button

### Vorher

"Navigation starten" war ein kleiner `IconButton` ohne Label - gleichwertig mit dem "POIs entdecken" Button:

```dart
// VORHER - Kleiner IconButton
IconButton(
  onPressed: () => _startDayNavigation(context, ref),
  icon: const Icon(Icons.navigation_rounded),
  tooltip: 'Navigation starten',
  style: IconButton.styleFrom(
    foregroundColor: colorScheme.primary,
    backgroundColor: colorScheme.primaryContainer.withOpacity(0.5),
  ),
),
```

### Nachher

"Navigation starten" ist jetzt ein vollbreiter `FilledButton.icon` - die primaere Aktion im Tag-Editor:

```dart
// NACHHER - Dominanter FilledButton
SizedBox(
  width: double.infinity,
  child: FilledButton.icon(
    onPressed: () => _startDayNavigation(context, ref),
    icon: const Icon(Icons.navigation_rounded),
    label: const Text('Navigation starten'),
    style: FilledButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
),
```

**Styling-Pattern:** Konsistent mit dem "Navigation starten" Button im TripScreen (gleiche `FilledButton.icon` Variante mit `vertical: 14` Padding und `borderRadius: 12`).

---

## Feature 2: Neuer "Route Teilen" Button

Neuer Button zum Teilen der tagesspezifischen Route ueber den System-Share-Dialog.

### Funktionalitaet

- Gleiche Origin/Destination-Logik wie Google Maps Export
- Erstellt Google Maps URL mit Waypoints (max 9 Stops pro Tag)
- Formatierter Share-Text mit Tag-Nummer, Stop-Namen und Maps-Link
- Nutzt `share_plus` Package (bereits in `pubspec.yaml`)

### Share-Text Format

```
Meine Route - Tag 2 mit MapAB

Stops:
1. Schloss Neuschwanstein
2. Zugspitze
3. Deutsches Museum

In Google Maps oeffnen:
https://www.google.com/maps/dir/?api=1&origin=...&destination=...&waypoints=...&travelmode=driving
```

### Methode `_shareDayRoute()`

```dart
Future<void> _shareDayRoute(BuildContext context, WidgetRef ref) async {
  // 1. Stops fuer ausgewaehlten Tag laden
  // 2. Origin bestimmen (Tag 1: startLocation, Tag 2+: letzter Stop Vortag)
  // 3. Destination bestimmen (letzter Tag: startLocation, sonst: erster Stop Folgetag)
  // 4. Google Maps URL bauen
  // 5. Share-Text formatieren
  // 6. Share.share() aufrufen
}
```

---

## Feature 3: 3-Ebenen Button-Layout

### Vorher (einzeilige Row)

```
[POIs icon] [Navi icon] [===== Tag in Google Maps (FilledButton) =====]
```

Probleme:
- "Navigation starten" und "POIs entdecken" waren gleichwertige IconButtons
- Google Maps Export war die dominante Aktion (obwohl In-App Navigation primaer sein sollte)
- Kein Share-Button vorhanden

### Nachher (3-Ebenen Column)

```
[== POIs hinzufuegen ==] [== Route Teilen ==]      <- OutlinedButton.icon (Row)
[=========== Navigation starten (FilledButton) ===========]  <- DOMINANT
[=========== Tag X in Google Maps (OutlinedButton) ===========]  <- Tertiaer
```

### Button-Hierarchie

| Ebene | Button | Widget-Typ | Rolle |
|-------|--------|-----------|-------|
| 1 (oben) | POIs hinzufuegen | `OutlinedButton.icon` | Sekundaer |
| 1 (oben) | Route Teilen | `OutlinedButton.icon` | Sekundaer |
| 2 (mitte) | Navigation starten | `FilledButton.icon` | **Primaer/Dominant** |
| 3 (unten) | Tag X in Google Maps | `OutlinedButton.icon` | Tertiaer |

### Google Maps Button Demotion

Vorher `FilledButton.icon` (dominant, primary-Farbe), jetzt `OutlinedButton.icon` (tertiaer):

```dart
// NACHHER - OutlinedButton statt FilledButton
OutlinedButton.icon(
  onPressed: () => _openDayInGoogleMaps(context, ref),
  icon: Icon(
    isCompleted ? Icons.check_circle : Icons.open_in_new,
    size: 18,
  ),
  label: Text(
    isCompleted
        ? 'Tag $selectedDay erneut oeffnen'
        : 'Tag $selectedDay in Google Maps',
  ),
  style: OutlinedButton.styleFrom(
    foregroundColor: isCompleted ? Colors.green : null,
    side: isCompleted ? const BorderSide(color: Colors.green) : null,
    // ...
  ),
),
```

**Completion-Indikator bleibt erhalten:** Bei abgeschlossenem Tag wird der Button gruen mit `Icons.check_circle`.

---

## Scroll-Padding Anpassung

Die Bottom-Bar ist durch das 3-Ebenen Layout hoeher geworden. Das Scroll-Padding am Ende der ListView wurde entsprechend erhoeht:

```dart
// VORHER
const SizedBox(height: 80),  // Platz fuer Bottom Buttons

// NACHHER
const SizedBox(height: 160), // Platz fuer Bottom Buttons (3 Ebenen)
```

---

## Neuer Import

```dart
import 'package:share_plus/share_plus.dart';
```

---

## Geaenderte Dateien (1)

| # | Datei | Aenderung |
|---|-------|-----------|
| 1 | `lib/features/trip/widgets/day_editor_overlay.dart` | 3-Ebenen Button-Layout, dominanter Navi-Button, Route Teilen, Google Maps demoted, Scroll-Padding 80→160 |

---

## Dark Mode Kompatibilitaet

Alle neuen Buttons nutzen `colorScheme`-Referenzen (via Flutter `OutlinedButton`/`FilledButton` Defaults). Einzige Ausnahme: `Colors.green` fuer den Completion-Indikator des Google Maps Buttons - dies war bereits vorher so und ist akzeptabel als kontextueller Farb-Indikator.
