# Changelog v1.7.23 - POI-Kategorien-Filter Fix

**Datum:** 31. Januar 2026
**Typ:** Feature & Bugfix - Minor Update
**Plattformen:** Android, iOS, Desktop
**APK-Größe:** 58.1 MB

---

## 🎨 Zusammenfassung

Umfassende Überarbeitung des POI-Kategorie-Filtersystems. Alle 15 Kategorien sind jetzt als Quick-Filter-Chips sichtbar und anklickbar. Fehlende Overpass-Abfragen für Seen, Küsten, Hotels, Restaurants und Aktivitäten wurden ergänzt. Filter-Chips haben jetzt deutliches visuelles Feedback beim Anklicken.

---

## ✨ Änderungen

### 1. **Overpass-Query erweitert - Neue POI-Typen**
- **Problem:** Seen, Küsten/Strände, Hotels, Restaurants und Aktivitäten wurden nicht von der Overpass API abgefragt
- **Lösung:** 17 neue Query-Einträge für fehlende OSM-Tags
- **Neue Abfragen:**
  - `natural=water` + `water=lake` (Seen)
  - `natural=beach` (Strände)
  - `leisure=beach_resort` (Strandbäder)
  - `tourism=hotel` + `stars` (Hotels mit Bewertung)
  - `amenity=restaurant` + `cuisine` (Restaurants)
  - `tourism=theme_park` (Freizeitparks)
  - `leisure=water_park` (Wasserparks)
  - `leisure=swimming_area` (Schwimmbereiche)
  - `tourism=zoo` (Zoos)
  - `place=island` (Inseln)

### 2. **Kategorie-Mapping in _parseOverpassPOI erweitert**
- **Problem:** Selbst wenn Overpass-Daten zurückkamen, wurden viele Tags keiner Kategorie zugeordnet
- **Lösung:** Neue Mappings für alle fehlenden Kategorien
- **Neue Zuordnungen:**
  - `natural=water` + `water=lake` → `lake`
  - `natural=beach` / `leisure=beach_resort` / `place=island` → `coast`
  - `tourism=hotel` → `hotel`
  - `amenity=restaurant` → `restaurant`
  - `tourism=theme_park` / `tourism=zoo` / `leisure=water_park` / `leisure=swimming_area` → `activity`

### 3. **Alle 15 Kategorien als Quick-Filter sichtbar**
- **Problem:** Nur 6 von 15 Kategorien wurden als Quick-Filter-Chips angezeigt (`.take(6)`)
- **Lösung:** `.take(6)` entfernt - alle Kategorien horizontal scrollbar
- **Ergebnis:** Alle POICategory-Werte als Chips: Burgen, Natur, Museen, Aussichtspunkte, Seen, Küsten, Parks, Städte, Aktivitäten, Hotels, Restaurants, UNESCO, Kirchen, Denkmäler, Attraktionen

### 4. **Filter-Chip visuelles Feedback verbessert**
- **Problem:** `GestureDetector` ohne Ripple-Effekt - kein visuelles Feedback beim Tippen
- **Lösung:** `Material` + `InkWell` statt `GestureDetector`
- **Verbesserungen:**
  - Ripple-Effekt beim Tippen
  - Ausgewählt: `colorScheme.primary` (kräftiges Blau) statt `primaryContainer` (helles Blau)
  - Häkchen-Icon (✓) vor dem Label bei ausgewählten Chips
  - `AnimatedContainer` für sanfte Übergänge
  - Weißer Text auf blauem Hintergrund bei Selektion
  - Dickerer Rand (1.5px) bei ausgewählten Chips

### 5. **Dark Mode Fix in POI-Filter-Sheet**
- **Problem:** `Colors.white` hart-codiert im Filter-Sheet (Dark Mode inkompatibel)
- **Lösung:** `Colors.white` → `colorScheme.surface`

### 6. **ProGuard R8 Build-Fix**
- **Problem:** Release-Build schlug fehl mit `Missing class com.google.android.play.core.splitcompat.SplitCompatApplication`
- **Lösung:** Drei `-dontwarn` Regeln für `com.google.android.play.core` Pakete hinzugefügt

---

## 🔧 Technische Details

### Betroffene Dateien

| Datei | Änderung |
|-------|----------|
| `lib/data/repositories/poi_repo.dart` | 17 neue Overpass-Abfragen + 5 neue Kategorie-Mappings |
| `lib/features/poi/poi_list_screen.dart` | `.take(6)` entfernt + _FilterChip Widget komplett überarbeitet |
| `lib/features/poi/widgets/poi_filters.dart` | Dark Mode Fix: `Colors.white` → `colorScheme.surface` |
| `android/app/proguard-rules.pro` | Play Core `-dontwarn` Regeln |

### Code-Änderungen

**Overpass-Query (poi_repo.dart):**
```dart
// NEU: Seen
node["natural"="water"]["water"="lake"]["name"]($bbox);
way["natural"="water"]["water"="lake"]["name"]($bbox);

// NEU: Strände
node["natural"="beach"]["name"]($bbox);
way["natural"="beach"]["name"]($bbox);
node["leisure"="beach_resort"]["name"]($bbox);
way["leisure"="beach_resort"]["name"]($bbox);

// NEU: Hotels, Restaurants
node["tourism"="hotel"]["name"]["stars"]($bbox);
way["tourism"="hotel"]["name"]["stars"]($bbox);
node["amenity"="restaurant"]["name"]["cuisine"]($bbox);

// NEU: Aktivitäten
node["tourism"="theme_park"]["name"]($bbox);
node["leisure"="water_park"]["name"]($bbox);
node["tourism"="zoo"]["name"]($bbox);
node["place"="island"]["name"]($bbox);
```

**Kategorie-Mapping (poi_repo.dart):**
```dart
} else if (tags['natural'] == 'water' && tags['water'] == 'lake') {
  category = 'lake';
} else if (tags['natural'] == 'beach' || tags['leisure'] == 'beach_resort' || tags['place'] == 'island') {
  category = 'coast';
} else if (tags['tourism'] == 'hotel') {
  category = 'hotel';
} else if (tags['amenity'] == 'restaurant') {
  category = 'restaurant';
} else if (tags['tourism'] == 'theme_park' || tags['tourism'] == 'zoo' ||
           tags['leisure'] == 'water_park' || tags['leisure'] == 'swimming_area') {
  category = 'activity';
}
```

**Quick-Filter (poi_list_screen.dart):**
```dart
// VORHER - Nur 6 Kategorien
...POICategory.values.take(6).map((cat) => Padding(

// NACHHER - Alle 15 Kategorien
...POICategory.values.map((cat) => Padding(
```

**FilterChip Widget (poi_list_screen.dart):**
```dart
// VORHER
GestureDetector(
  onTap: onTap,
  child: Container(
    decoration: BoxDecoration(
      color: isSelected ? colorScheme.primaryContainer : ...,
    ),
    child: Row(children: [icon, label]),
  ),
)

// NACHHER
Material(
  color: isSelected ? colorScheme.primary : ...,
  borderRadius: BorderRadius.circular(20),
  child: InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: AnimatedContainer(
      duration: Duration(milliseconds: 200),
      child: Row(children: [
        icon,
        if (isSelected) Icon(Icons.check, size: 14),
        label,
      ]),
    ),
  ),
)
```

**Dark Mode Fix (poi_filters.dart):**
```dart
// VORHER
color: Colors.white,

// NACHHER
final colorScheme = Theme.of(context).colorScheme;
color: colorScheme.surface,
```

**ProGuard (proguard-rules.pro):**
```
# Google Play Core (Flutter deferred components)
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
```

---

## 🎯 Auswirkungen

### Benutzerfreundlichkeit
- **Alle Kategorien filterbar:** Benutzer können jetzt nach allen 15 Kategorien filtern
- **Seen & Küsten:** Zeigen jetzt tatsächlich POIs an (vorher immer leer)
- **Visuelles Feedback:** Deutlich sichtbar welche Kategorien ausgewählt sind
- **Dark Mode:** Filter-Sheet funktioniert korrekt im Dark Mode

### POI-Abdeckung

| Kategorie | Vorher | Nachher |
|-----------|--------|---------|
| Burgen, Natur, Museen, Aussichtspunkte | ✅ | ✅ |
| Seen | ❌ Keine Ergebnisse | ✅ via `natural=water` |
| Küsten & Strände | ❌ Keine Ergebnisse | ✅ via `natural=beach` |
| Hotels | ❌ Keine Ergebnisse | ✅ via `tourism=hotel` |
| Restaurants | ❌ Keine Ergebnisse | ✅ via `amenity=restaurant` |
| Aktivitäten | ❌ Keine Ergebnisse | ✅ via `theme_park`, `zoo`, `water_park` |
| Parks, Städte, UNESCO, Kirchen, Denkmäler | ✅ | ✅ |

### Quick-Filter Chips

| Aspekt | Vorher | Nachher |
|--------|--------|---------|
| Sichtbare Kategorien | 6 | 15 (alle) |
| Visuelles Feedback | Kein Ripple | Ripple + AnimatedContainer |
| Ausgewählt-Farbe | `primaryContainer` (hell) | `primary` (kräftig) |
| Ausgewählt-Indikator | Nur Farbwechsel | Häkchen + Farbe + Schrift |
| Tap-Bereich | GestureDetector | InkWell (mit Splash) |

---

## 🔄 Migration

**Keine Breaking Changes** - Erweiterte Overpass-Abfragen und UI-Verbesserungen.

---

## 📚 Siehe auch

- [CHANGELOG-v1.7.22.md](CHANGELOG-v1.7.22.md) - UI-Feinschliff
- [CHANGELOG-v1.7.9.md](CHANGELOG-v1.7.9.md) - Kategorie-Inference & Wetter-Kategorien
- [CHANGELOG-v1.5.3.md](CHANGELOG-v1.5.3.md) - POI-Liste Filter-Fix

---

**Status:** ✅ Abgeschlossen
**Review:** Pending
**Deploy:** Released as v1.7.23
