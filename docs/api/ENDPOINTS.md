# API-Referenz

## Übersicht

MapAB nutzt einen Node.js/TypeScript Backend-Proxy auf Vercel für AI-Features und Daten-Synchronisation.

**Base URL:** `https://backend-gules-gamma-30.vercel.app`

## Authentifizierung

Die meisten Endpoints nutzen Supabase Auth. Der `Authorization` Header enthält den JWT-Token:

```
Authorization: Bearer <supabase-jwt-token>
```

Für AI-Endpoints wird der Supabase Anon Key verwendet.

---

## Health Check

### GET /api/health

Prüft ob das Backend erreichbar ist.

**Response:**
```json
{
  "status": "ok",
  "timestamp": "2026-01-23T12:00:00Z"
}
```

---

## AI-Endpoints

### POST /api/ai/chat

AI-Chat mit GPT-4o.

**Rate Limit:** 100 Anfragen/Tag pro IP

**Request:**
```json
{
  "message": "Welche Sehenswürdigkeiten gibt es in München?",
  "context": {
    "currentRoute": {
      "start": "München",
      "end": "Berlin"
    },
    "stops": ["Nürnberg"]
  }
}
```

**Response:**
```json
{
  "response": "In München gibt es viele Sehenswürdigkeiten...",
  "tokens": 284
}
```

**Fehler:**
```json
{
  "error": "Rate limit exceeded",
  "retryAfter": 3600
}
```

---

### POST /api/ai/trip-plan

Generiert einen AI-basierten Reiseplan.

**Rate Limit:** 20 Anfragen/Tag pro IP

**Request:**
```json
{
  "destination": "Prag",
  "days": 3,
  "interests": ["Kultur", "Geschichte", "Essen"],
  "startLocation": "München"
}
```

**Response:**
```json
{
  "plan": "🗺️ AI-Trip-Plan: 3 Tage in Prag\n\nTag 1: Historisches Zentrum...",
  "tokens": 512
}
```

---

### POST /api/ai/poi-suggestions

Liefert strukturierte AI-POI-Empfehlungen fuer Day-Editor und Chat-Nearby.

**Request:**
```json
{
  "mode": "day_editor",
  "language": "de",
  "userContext": {
    "lat": 48.1371,
    "lng": 11.5753,
    "locationName": "Muenchen",
    "weatherCondition": "good",
    "selectedDay": 1,
    "totalDays": 3
  },
  "tripContext": {
    "routeStart": "Muenchen",
    "routeEnd": "Salzburg",
    "stops": [
      { "id": "poi-1", "name": "Marienplatz", "categoryId": "sight" }
    ]
  },
  "constraints": {
    "maxSuggestions": 8,
    "allowSwap": true
  },
  "candidates": [
    {
      "id": "poi-2",
      "name": "Nymphenburg",
      "categoryId": "castle",
      "lat": 48.1584,
      "lng": 11.5036,
      "score": 0.86,
      "isMustSee": true,
      "isCurated": true,
      "isUnesco": false,
      "isIndoor": false,
      "detourKm": 3.2,
      "routePosition": 0.42,
      "imageUrl": "https://...",
      "shortDescription": "Barockschloss",
      "tags": ["historisch", "garten"]
    }
  ]
}
```

**Response:**
```json
{
  "summary": "Diese POIs passen gut fuer Tag 1.",
  "suggestions": [
    {
      "poiId": "poi-2",
      "action": "add",
      "reason": "Passt thematisch und liegt nahe der Route.",
      "relevance": 0.92,
      "highlights": ["Historische Architektur", "Grosse Gartenanlage"],
      "longDescription": "Nymphenburg ist ein ausgedehnter Schlosskomplex..."
    }
  ]
}
```

**Fallback-Verhalten:**
- Bei ungueltiger AI-Antwort faellt das Backend automatisch auf regelbasiertes Ranking zurueck.
- `relevance` wird auf `0..1` begrenzt; `swap`-Actions enthalten immer ein `targetPoiId`.

---

## Trips

### GET /api/v1/trips

Listet alle Trips des authentifizierten Benutzers.

**Headers:**
```
Authorization: Bearer <jwt>
```

**Response:**
```json
{
  "trips": [
    {
      "id": "uuid",
      "name": "München → Berlin",
      "type": "daytrip",
      "route": {
        "start": {"lat": 48.1351, "lng": 11.5820},
        "end": {"lat": 52.5200, "lng": 13.4050},
        "startAddress": "München, Deutschland",
        "endAddress": "Berlin, Deutschland",
        "distanceKm": 584,
        "durationMinutes": 330
      },
      "stops": [],
      "createdAt": "2026-01-23T10:00:00Z",
      "isFavorite": true
    }
  ]
}
```

---

### POST /api/v1/trips

Erstellt einen neuen Trip.

**Request:**
```json
{
  "name": "Wochenendtrip",
  "type": "daytrip",
  "route": {
    "start": {"lat": 48.1351, "lng": 11.5820},
    "end": {"lat": 52.5200, "lng": 13.4050},
    "startAddress": "München",
    "endAddress": "Berlin",
    "distanceKm": 584,
    "durationMinutes": 330,
    "coordinates": [[48.1351, 11.5820], ...]
  },
  "stops": []
}
```

**Response:**
```json
{
  "id": "uuid",
  "createdAt": "2026-01-23T10:00:00Z"
}
```

---

### GET /api/v1/trips/:id

Holt einen einzelnen Trip.

---

### PATCH /api/v1/trips/:id

Aktualisiert einen Trip.

**Request:**
```json
{
  "name": "Neuer Name",
  "isFavorite": true
}
```

---

### DELETE /api/v1/trips/:id

Löscht einen Trip.

---

### POST /api/v1/trips/:id/complete

Markiert einen Trip als abgeschlossen und vergibt XP.

**Response:**
```json
{
  "xpAwarded": 100,
  "newLevel": 5,
  "achievements": ["first_trip"]
}
```

---

## Favoriten

### GET /api/v1/favorites/pois

Listet alle favorisierten POIs.

**Response:**
```json
{
  "pois": [
    {
      "id": "de-1",
      "name": "Schloss Neuschwanstein",
      "category": "castle",
      "latitude": 47.5576,
      "longitude": 10.7498,
      "addedAt": "2026-01-23T10:00:00Z"
    }
  ]
}
```

---

### POST /api/v1/favorites/pois

Fügt einen POI zu Favoriten hinzu.

**Request:**
```json
{
  "poiId": "de-1",
  "name": "Schloss Neuschwanstein",
  "category": "castle",
  "latitude": 47.5576,
  "longitude": 10.7498
}
```

---

### DELETE /api/v1/favorites/pois/:id

Entfernt einen POI aus Favoriten.

---

## Benutzer

### GET /api/v1/users/me

Holt das Benutzerprofil.

**Response:**
```json
{
  "id": "uuid",
  "email": "user@example.com",
  "username": "Reisender",
  "avatarUrl": null,
  "xp": 1250,
  "level": 5,
  "createdAt": "2026-01-01T00:00:00Z"
}
```

---

### PATCH /api/v1/users/me

Aktualisiert das Benutzerprofil.

**Request:**
```json
{
  "username": "Neuer Name",
  "avatarUrl": "https://..."
}
```

---

## Externe APIs (Client-seitig)

Diese APIs werden direkt vom Flutter-Client aufgerufen:

### Nominatim (Geocoding)

```
GET https://nominatim.openstreetmap.org/search
  ?q=München
  &format=json
  &limit=5
```

### OSRM (Routing)

```
GET https://router.project-osrm.org/route/v1/driving/
  {start_lng},{start_lat};{end_lng},{end_lat}
  ?overview=full
  &geometries=geojson
```

### Open-Meteo (Wetter)

```
GET https://api.open-meteo.com/v1/forecast
  ?latitude=48.1351
  &longitude=11.5820
  &hourly=temperature_2m,weathercode
```

### Wikipedia API (POI-Enrichment)

```
GET https://de.wikipedia.org/w/api.php
  ?action=query
  &titles={title}
  &prop=extracts|pageimages
  &format=json
```

---

## Rate Limiting

| Endpoint | Limit | Zeitraum |
|----------|-------|----------|
| /api/ai/chat | 100 | Tag |
| /api/ai/trip-plan | 20 | Tag |
| /api/v1/* | 1000 | Tag |

Bei Überschreitung:
```json
{
  "error": "Rate limit exceeded",
  "retryAfter": 3600
}
```

---

## Fehler-Codes

| Code | Bedeutung |
|------|-----------|
| 400 | Bad Request - Ungültige Anfrage |
| 401 | Unauthorized - Token fehlt/ungültig |
| 403 | Forbidden - Keine Berechtigung |
| 404 | Not Found - Ressource nicht gefunden |
| 429 | Too Many Requests - Rate Limit |
| 500 | Internal Server Error |

---

## Siehe auch

- [Backend-Setup](../guides/BACKEND-SETUP.md)
- [Security](../SECURITY.md)
