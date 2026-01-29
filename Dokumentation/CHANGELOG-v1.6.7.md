# Changelog v1.6.7 - POI-Detail Fotos & Highlights Fix

**Datum:** 2026-01-29

## Problem

Nach Routenberechnung wurden beim Klick auf POIs in der Liste keine Fotos und Highlights angezeigt. Der POI-Detail-Screen zeigte nur Placeholder-Icons und leere Highlight-Badges.

## Ursachenanalyse

### 1. Asynchrones Enrichment ohne Warten

Der POI-Detail-Screen startete das Enrichment asynchron mit `unawaited()`, wodurch das UI sofort mit dem ungereichterten POI gerendert wurde:

```dart
// VORHER (fehlerhaft):
if (state.selectedPOI != null && !state.selectedPOI!.isEnriched) {
  unawaited(notifier.enrichPOI(widget.poiId));  // Fire-and-forget!
}
```

**Ablauf:**
1. POI-Klick → `selectPOI(poi)` mit ungereichertem POI
2. Detail-Screen öffnet → UI rendert sofort
3. Enrichment läuft im Hintergrund
4. Ergebnis: Kein Foto, keine Highlights sichtbar

### 2. Doppeltes Selektieren

Die POI-Liste rief `selectPOI(poi)` auf, bevor der Detail-Screen geöffnet wurde. Dies war redundant, da der Detail-Screen selbst `selectPOIById()` aufruft:

```dart
// VORHER (redundant):
onTap: () {
  ref.read(pOIStateNotifierProvider.notifier).selectPOI(poi);  // Unnötig!
  context.push('/poi/${poi.id}');
},
```

## Implementierte Fixes

### Fix 1: Blockierendes Enrichment

**Datei:** `lib/features/poi/poi_detail_screen.dart`

```dart
// NACHHER (korrekt):
Future<void> _loadAndEnrichPOI() async {
  final notifier = ref.read(pOIStateNotifierProvider.notifier);

  try {
    notifier.selectPOIById(widget.poiId);

    // FIX v1.6.7: Enrichment BLOCKIEREND warten
    final state = ref.read(pOIStateNotifierProvider);
    if (state.selectedPOI != null && !state.selectedPOI!.isEnriched) {
      await notifier.enrichPOI(widget.poiId);  // await statt unawaited!
    }
  } catch (e) {
    debugPrint('[POIDetail] POI nicht gefunden: ${widget.poiId}');
  }
}
```

**Vorteile:**
- Loading-Indikator "Lade Details..." wird korrekt angezeigt
- Nach dem Laden sind Foto und Highlights sofort sichtbar
- Keine Race Conditions mehr

### Fix 2: Redundantes selectPOI entfernt

**Datei:** `lib/features/poi/poi_list_screen.dart`

```dart
// NACHHER (vereinfacht):
onTap: () {
  // selectPOI wird im Detail-Screen via selectPOIById aufgerufen
  context.push('/poi/${poi.id}');
},
```

**Vorteile:**
- Kein doppeltes Selektieren mehr
- Klarere Code-Struktur
- POI wird erst im Detail-Screen aus der aktuellen State-Liste geholt

## Betroffene Dateien

| Datei | Änderung |
|-------|----------|
| `lib/features/poi/poi_detail_screen.dart` | `unawaited` → `await`, `import 'dart:async'` entfernt |
| `lib/features/poi/poi_list_screen.dart` | `selectPOI(poi)` Aufruf entfernt |

## Verifikation

1. **Route berechnen** (Start + Ziel eingeben)
2. **POI-Liste öffnen** → POIs werden angezeigt
3. **Auf POI klicken** → Detail-Screen öffnet
4. **Prüfen:**
   - Loading-Indikator "Lade Details..." erscheint (wenn nicht gecached)
   - Nach Laden: Foto wird im Header angezeigt
   - Highlights erscheinen als farbige Badges
   - Beschreibung wird angezeigt

## Zusammenfassung

| Vorher | Nachher |
|--------|---------|
| POI-Klick → ungereicherter POI sofort angezeigt | POI-Klick → Loading → vollständiger POI |
| Kein Foto, keine Highlights | Foto und Highlights werden angezeigt |
| Doppeltes Selektieren (Liste + Detail) | Einmaliges Selektieren (nur Detail) |
| Race Condition mit State-Updates | Synchrones Laden, dann Anzeige |
