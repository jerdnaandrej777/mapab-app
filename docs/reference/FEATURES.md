# Feature-Matrix

Übersicht aller Features in MapAB mit Status und Version.

## Legende

| Symbol | Status |
|--------|--------|
| Stabil | Produktionsbereit |
| Beta | Funktional, in Entwicklung |
| Geplant | Noch nicht implementiert |

---

## Karten & Navigation

| Feature | Status | Version | Beschreibung |
|---------|--------|---------|--------------|
| Interaktive Karte | Stabil | 1.0.0 | MapLibre/OSM-basiert |
| GPS-Tracking | Stabil | 1.0.0 | Echtzeit-Position |
| Routenplanung (Schnell) | Stabil | 1.1.0 | OSRM-basiert |
| Routenplanung (Scenic) | Stabil | 1.2.5 | OpenRouteService |
| Route auf Karte | Stabil | 1.2.2 | Polyline-Darstellung |
| Start/Ziel Marker | Stabil | 1.2.5 | Grün/Rot markiert |
| Google Maps Export | Stabil | 1.3.0 | Route in Google Maps öffnen |
| Offline-Karten | Geplant | - | Tile-Caching |

---

## POI-System

| Feature | Status | Version | Beschreibung |
|---------|--------|---------|--------------|
| Curated POIs | Stabil | 1.0.0 | 527 handkuratierte POIs |
| Wikipedia-Enrichment | Stabil | 1.2.5 | Beschreibungen & Bilder |
| Wikimedia-Fallback | Stabil | 1.2.5 | Geo-basierte Bildsuche |
| Wikidata-Integration | Stabil | 1.2.5 | UNESCO, Gründungsjahr, etc. |
| POI-Marker auf Karte | Stabil | 1.2.5 | Kategorie-Icons |
| POI-Preview Sheet | Stabil | 1.2.5 | Tap auf Marker |
| POI-Highlights | Stabil | 1.2.5 | UNESCO, Must-See, Geheimtipp |
| POI-Cache | Stabil | 1.2.5 | 7 Tage Region, 30 Tage Enrichment |
| Region-Cache | Stabil | 1.3.6 | Paralleles Laden |
| POI-Suche | Geplant | - | Volltextsuche |

---

## AI-Features

| Feature | Status | Version | Beschreibung |
|---------|--------|---------|--------------|
| AI Chat | Stabil | 1.2.0 | GPT-4o Integration |
| AI Trip-Generator | Stabil | 1.2.0 | 1-7 Tage Pläne |
| AI Trip ohne Ziel | Stabil | 1.2.4 | Random Route generieren |
| Sprachsteuerung | Beta | 1.3.4 | Speech-to-Text |
| AI POI-Empfehlungen | Geplant | - | Personalisierte Vorschläge |

---

## Account & Cloud

| Feature | Status | Version | Beschreibung |
|---------|--------|---------|--------------|
| Gast-Modus | Stabil | 1.0.0 | Offline nutzbar |
| Email/Passwort Auth | Stabil | 1.2.6 | Supabase Auth |
| Cloud-Sync | Stabil | 1.2.6 | Trips & Favoriten |
| XP-System | Stabil | 1.2.0 | Level 1-50 |
| Achievements | Stabil | 1.2.0 | 21 Achievements |
| Remember Me | Stabil | 1.3.5 | Credentials speichern |
| Profil bearbeiten | Stabil | 1.2.6 | Username, Avatar |
| Passwort vergessen | Stabil | 1.2.6 | Email-Reset |

---

## Trip-Planung

| Feature | Status | Version | Beschreibung |
|---------|--------|---------|--------------|
| Trip-Screen | Stabil | 1.2.1 | Route-Übersicht |
| Stops hinzufügen | Stabil | 1.2.1 | POIs zur Route |
| Stops sortieren | Stabil | 1.2.1 | Drag & Drop |
| Route starten | Stabil | 1.2.9 | POIs entlang Route laden |
| Wetter-Warnungen | Stabil | 1.2.9 | 5 Messpunkte |
| Indoor-Filter | Stabil | 1.2.9 | Bei schlechtem Wetter |
| Route löschen | Stabil | 1.3.4 | X-Buttons, Clear-Button |
| Route teilen | Stabil | 1.3.0 | System-Share-Dialog |
| Route speichern | Stabil | 1.2.7 | Als Favorit |
| Turn-by-Turn Navigation | Geplant | - | Schritt-für-Schritt |

---

## Favoriten

| Feature | Status | Version | Beschreibung |
|---------|--------|---------|--------------|
| POI-Favoriten | Stabil | 1.2.7 | Herz-Button |
| Routen-Favoriten | Stabil | 1.2.7 | Bookmark-Button |
| Favoriten-Tabs | Stabil | 1.2.0 | POIs / Routen |
| Cloud-Sync | Stabil | 1.2.7 | Bei Login |

---

## UI & Design

| Feature | Status | Version | Beschreibung |
|---------|--------|---------|--------------|
| Dark Mode | Stabil | 1.2.3 | System/Dunkel/OLED |
| Bottom Navigation | Stabil | 1.0.0 | 4 Tabs |
| Animiertes Onboarding | Stabil | 1.2.8 | 3 Seiten |
| Material Design 3 | Stabil | 1.0.0 | Moderne UI |

---

## Performance (v1.3.6)

| Optimierung | Verbesserung |
|-------------|--------------|
| Paralleles POI-Laden | 45% schneller |
| Region-Cache | 98% schneller (Cache-Hit) |
| Batch-Enrichment | Weniger API-Fehler |
| Speicheroptimierte Bilder | 60% weniger RAM |

---

## Geplante Features

| Feature | Priorität | Beschreibung |
|---------|-----------|--------------|
| Offline-Karten | Hoch | Tile-Download |
| Turn-by-Turn Navigation | Hoch | Navigation |
| POI-Suche | Mittel | Volltextsuche |
| Multi-Language | Mittel | Englisch Support |
| iOS Release | Niedrig | App Store |

---

## Siehe auch

- [CHANGELOG](../../CHANGELOG.md)
- [POI-SYSTEM](../architecture/POI-SYSTEM.md)
- [PROVIDER-GUIDE](../architecture/PROVIDER-GUIDE.md)
