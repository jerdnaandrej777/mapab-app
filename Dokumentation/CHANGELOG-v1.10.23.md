# Changelog v1.10.23 (Build 206)

**Datum:** 8. Februar 2026

## Fix: AI Tagestrip respektiert Reiseentfernung als echtes Maximum

### Problem
Bei AI Tagestrips wurde die gewählte Reiseentfernung (z. B. 100 km, 300 km) nicht zuverlässig eingehalten.
Die Route konnte deutlich länger werden, weil der Wert nur indirekt als POI-Suchradius wirkte.

### Änderungen

#### 1) Hartes Distanzlimit für Tagestrip-Routen
- Der gewählte Wert wird jetzt als **maximale Routenlänge** behandelt.
- Ist die berechnete Route länger als das Limit, wird die Konfiguration automatisch angepasst.

#### 2) Vorfilterung ungeeigneter POIs
- POIs, die rechnerisch nicht in das Distanzbudget passen, werden vor der Auswahl entfernt.
- Rundreise: `Start → POI` muss innerhalb von `maxDistance / 2` liegen.
- A→B Trip: `Start → POI + POI → Ziel` muss innerhalb des Limits liegen.

#### 3) Robustere Generierung mit mehreren Versuchen
- Für jede POI-Anzahl werden mehrere Varianten berechnet.
- Wenn nötig, wird die POI-Anzahl schrittweise reduziert, bis die Route passt.
- Dadurch werden Zufallsausreißer in der Auswahl deutlich reduziert.

#### 4) Verständliche Fehlermeldung bei zu kleinem Limit
- Wenn keine Route die Vorgabe erfüllen kann, erscheint eine klare Meldung mit kürzester gefundener Distanz und Hinweis zur Korrektur.

### Betroffene Dateien

| Datei | Änderung |
|-------|----------|
| `lib/data/repositories/trip_generator_repo.dart` | Distanzlimit-Härtung, POI-Vorfilterung, Mehrfachversuche bei Tagestrips |
| `CLAUDE.md` | Versionsstand auf v1.10.23 + Kurzbeschreibung ergänzt |
| `docs/qr-code-download.html` | Download-Seite auf v1.10.23 / Build 206 aktualisiert |

---

*Generiert mit Claude Code*
