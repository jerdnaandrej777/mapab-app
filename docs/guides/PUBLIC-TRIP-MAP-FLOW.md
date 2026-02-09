# Public Trip Map Flow (v1.10.53)

## Ziel
Stabile und reproduzierbare Kartenanzeige fuer veroeffentlichte Trips aus der Trip-Galerie, ohne Uebernahme alter AI-/Planungszustaende.

## Kernverhalten

1. Beim Klick auf **"Auf Karte"** in einem Public Trip wird vor dem Laden zuerst alter Zustand bereinigt:
   - `routePlannerProvider.clearRoute()`
   - `randomTripNotifierProvider.reset()`
2. Danach werden Route + Stops des Public Trips in `tripStateProvider` gesetzt.
3. Auto-Zoom und Kartenfokus werden explizit aktiviert:
   - `shouldFitToRouteProvider = true`
   - `mapRouteFocusModeProvider = true`

## Standort-Start (Trip/POI)

- Der gleiche Reset wird auch bei:
  - **Trip ab aktuellem Standort starten**
  - **Einzelnen POI ab aktuellem Standort starten**
  ausgefuehrt, damit keine stale Preview-UI den Flow ueberlagert.

## Journal-Shortcut

- `MapScreen` hat in der AppBar ein eigenes Journal-Icon.
- Das Ziel `'/journal/:tripId?name=...'` wird anhand des aktiven Kontexts bestimmt:
  - Random-Trip Preview/Confirmed
  - Aktiver Trip-Route-State
  - RoutePlanner-State
  - Fallback auf `journal-home`

## Elevation-Performance

- `ElevationNotifier.loadElevation(...)` dedupliziert identische laufende Requests:
  - Wenn `isLoading == true` und `_routeHash` identisch ist, wird kein weiterer Request gestartet.

## Manuelle QA-Checkliste

1. Public Trip aus Galerie oeffnen und auf **Auf Karte** klicken:
   - Route + POIs werden auf der Hauptkarte angezeigt.
   - Kein alter AI-Footer (`Bearbeiten/Neu/Speichern`) sichtbar.
2. Im Public Trip:
   - **Trip ab Standort starten** pruefen.
   - **POI ab Standort starten** pruefen.
3. Map-Header:
   - Journal-Icon sichtbar und Navigation in das Reisetagebuch funktioniert.
4. Hoehenprofil:
   - Beim wiederholten Oeffnen derselben Route keine mehrfachen parallelen Ladevorgaenge.
