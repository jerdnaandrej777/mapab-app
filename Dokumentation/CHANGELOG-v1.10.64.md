# Changelog v1.10.64 - Erinnerungspunkt-UX, Wetter-Forecast, POI-Publish

**Datum:** 10. Februar 2026
**Build:** 248

## Zusammenfassung

Erinnerungspunkt-Modal zeigt jetzt "Abbrechen" und "Erneut besuchen" statt AI-Trip-Buttons. Aufklappbarer 7-Tage-Wetter-Forecast im DayEditor. POI-Publish-Modal mit eigenem Titel.

## Aenderungen

### Verbessert

#### Erinnerungspunkt-Modal UX
- **AI-Buttons ausgeblendet**: `TripModeSelector` (AI Tagestrip / AI Euro Trip) wird bei aktivem Erinnerungspunkt komplett ausgeblendet
- **"Abbrechen"-Button**: Ersetzt den alten "Zurueck"-Button - schliesst den Erinnerungspunkt und kehrt zur normalen Kartenansicht mit Trip-Config-Panel zurueck (statt ins Journal zurueckzukehren)
- **"Erneut besuchen"**: Berechnet Route vom aktuellen GPS-Standort zum Erinnerungspunkt und oeffnet das "Deine Route"-Modal (RouteFocusFooter) mit Trip bearbeiten / Navigation starten / Route loeschen
- **Sauberer Flow**: Abbrechen -> normale Karte | Erneut besuchen -> GPS als Start, Erinnerungspunkt als Ziel -> "Deine Route"-Modal

#### POI-Publish Modal Titel
- `PublishPoiSheet` zeigt jetzt "POI veroeffentlichen" statt "Trip veroeffentlichen"
- 2 neue l10n-Keys (`publishPoiTitle`, `publishPoiSubtitle`) in 5 Sprachen

#### DayStats aufklappbarer Wetter-Forecast
- Wetter-Chip in DayStats anklickbar mit Chevron-Icon
- Klappt 7-Tage-Vorhersage fuer Zieladresse auf (horizontal scrollbar)
- `AnimatedSize`-Toggle mit sanfter Animation
- Auto-Close bei Tageswechsel
- Neue Methode `getDestinationForecast()` in `RouteWeatherState`
- Neuer l10n-Key `dayEditorForecastDestination` in 5 Sprachen

## Betroffene Dateien

| Datei | Aenderung |
|-------|-----------|
| `lib/features/map/widgets/trip_mode_selector.dart` | `memoryPointProvider` Watch + Hide-Logik |
| `lib/features/map/map_screen.dart` | `_MemoryPointFooter`: onBack -> onCancel, Icon close statt arrow_back, l10n.cancel statt journalBack |
| `lib/features/social/widgets/publish_poi_sheet.dart` | Eigene l10n-Keys publishPoiTitle/publishPoiSubtitle |
| `lib/features/trip/widgets/day_editor_overlay.dart` | Aufklappbarer Wetter-Forecast in DayStats |
| `lib/features/map/providers/weather_provider.dart` | `getDestinationForecast()` Methode |
| `lib/l10n/app_de.arb` | Neue l10n-Keys |
| `lib/l10n/app_en.arb` | Neue l10n-Keys |
| `lib/l10n/app_es.arb` | Neue l10n-Keys |
| `lib/l10n/app_fr.arb` | Neue l10n-Keys |
| `lib/l10n/app_it.arb` | Neue l10n-Keys |
