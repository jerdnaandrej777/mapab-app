# MapAB v1.7.14 - GPS-Standort-Synchronisation

**Release-Datum:** 2026-01-31

## 🎯 Feature

### GPS-Standort automatisch zwischen Modi synchronisieren
- **Problem:** GPS-Button im AI Trip Modus setzte Standort nicht im Schnell-Modus
- **Lösung:** Automatische Synchronisation beim Modus-Wechsel
  - AI Trip → Schnell: Standort wird als Startpunkt übertragen
  - Schnell → AI Trip: Startpunkt wird ins AI Trip Panel übertragen

## 🔧 Technisch

**Dateien:**
- `lib/features/map/map_screen.dart`
  - Neue Methode `_syncLocationBetweenModes()`
  - Erweitert `onModeChanged` Callback

**Verhalten:**
- Synchronisation nur wenn Ziel-Modus keinen Startpunkt hat
- Verhindert Überschreiben von manuell gesetzten Punkten
- Debug-Logging für Transparenz

## 📱 UX-Verbesserung

**Vorher:** GPS-Button klicken → Modus wechseln → Startpunkt fehlt → erneut klicken
**Nachher:** GPS-Button klicken → Modus wechseln → Startpunkt automatisch da ✅
