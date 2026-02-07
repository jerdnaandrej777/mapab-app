# CHANGELOG v1.10.32

Datum: 8. Februar 2026
Build: 215

## Highlights
- AI-Tagestrip stabilisiert: POIs werden wieder robust erkannt und Route laedt auch bei problematischen Einzel-POIs.
- Trip-Galerie verbessert: POI-Filterbutton-Text ist in allen Zustaenden klar lesbar und konsistent zur restlichen UI.

## Technische Aenderungen
- `lib/data/repositories/trip_generator_repo.dart`
  - Routing-Backoff fuer Daytrip-Generierung: bei Routingfehlern wird nicht mehr sofort abgebrochen,
    stattdessen werden unroutbare Ausreisser-POIs schrittweise entfernt und erneut geroutet.
  - Nur valide POI-Koordinaten werden in die finale Routing-Pipeline uebernommen.
- `lib/features/social/gallery_screen.dart`
  - POI-Filterchips (`Must-See`, `Top bewertet`, `Neu`, `Trending`, Kategorien) mit expliziten
    Textfarben fuer selected/unselected + konsistenten Chip-Farben.

## Ergebnis
- Deutlich weniger Abbrueche bei AI-Tagestrip-Routenberechnung.
- Filter-UI in der Trip-Galerie ist wieder gut lesbar.
