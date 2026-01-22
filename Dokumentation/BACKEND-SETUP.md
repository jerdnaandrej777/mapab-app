# MapAB Backend - Setup Guide

## Übersicht

Dieses Backend schützt sensible API-Keys und bietet zentrale Services für:
- AI-Features (OpenAI Proxy)
- Benutzer-Authentifizierung (Supabase Auth)
- Cloud-Synchronisation (Trips, Favoriten, Achievements)
- Server-seitige XP-Validierung

## Tech Stack

| Komponente | Technologie |
|------------|-------------|
| Runtime | Node.js 20+ |
| Framework | Vercel Serverless Functions |
| Datenbank | PostgreSQL (Supabase) |
| Auth | Supabase Auth |
| Validation | Zod |
| AI | OpenAI API |

---

## 1. Vercel Backend Deployment

### 1.1 Vercel Projekt erstellen

```bash
cd backend
npm install

# Vercel CLI installieren (falls nicht vorhanden)
npm i -g vercel

# Mit Vercel verknüpfen
vercel link

# Lokal testen
vercel dev
```

### 1.2 Environment Variables setzen

In Vercel Dashboard → Settings → Environment Variables:

| Variable | Beschreibung | Erforderlich |
|----------|--------------|--------------|
| `OPENAI_API_KEY` | OpenAI API Key | ✅ Ja |
| `SUPABASE_URL` | Supabase Projekt URL | ✅ Ja |
| `SUPABASE_ANON_KEY` | Supabase Anon Key | ✅ Ja |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase Service Role Key | ✅ Ja |
| `RATE_LIMIT_MAX_REQUESTS` | Max Requests/Tag (default: 100) | Nein |

### 1.3 Deployment

```bash
# Preview Deployment
vercel

# Production Deployment
vercel --prod
```

Die Backend-URL wird ausgegeben (z.B. `https://mapab-backend.vercel.app`).

---

## 2. Supabase Setup

### 2.1 Projekt erstellen

1. Gehe zu https://supabase.com/dashboard
2. Klicke "New Project"
3. Wähle Region (am besten EU für DSGVO)
4. Notiere URL und Anon-Key

### 2.2 Datenbank-Schema anlegen

1. Gehe zu SQL Editor
2. Kopiere den Inhalt von `backend/supabase/migrations/001_initial_schema.sql`
3. Führe das SQL aus

### 2.3 Auth konfigurieren

1. Gehe zu Authentication → Settings
2. Aktiviere "Email" Provider
3. Optional: Google/Apple OAuth konfigurieren

### 2.4 RLS prüfen

Die Row Level Security ist bereits im Schema definiert. Prüfe unter Database → Tables, dass RLS aktiviert ist.

---

## 3. Flutter Konfiguration

### 3.1 Supabase Config eintragen

Bearbeite `lib/core/supabase/supabase_config.dart`:

```dart
class SupabaseConfig {
  // Bereits konfiguriert für MapAB:
  static const String supabaseUrl = 'https://kcjgnctfjodggpvqwgil.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIs...'; // Vollständiger Key in Datei
}
```

### 3.2 Backend URL eintragen

Bearbeite `lib/core/constants/api_config.dart`:

```dart
class ApiConfig {
  // Bereits konfiguriert:
  static const String backendBaseUrl = 'https://backend-gules-gamma-30.vercel.app';
}
```

### 3.3 Dependencies installieren

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 4. API Endpoints

### AI Endpoints (öffentlich, Rate-Limited)

| Methode | Endpoint | Beschreibung |
|---------|----------|--------------|
| POST | `/api/ai/chat` | Chat mit AI-Assistent |
| POST | `/api/ai/trip-plan` | Trip-Plan generieren |
| GET | `/api/health` | Health-Check |

### REST API (Auth erforderlich)

| Methode | Endpoint | Beschreibung |
|---------|----------|--------------|
| GET | `/api/v1/users/me` | Profil laden |
| PATCH | `/api/v1/users/me` | Profil aktualisieren |
| GET | `/api/v1/trips` | Trips auflisten |
| POST | `/api/v1/trips` | Trip erstellen |
| GET | `/api/v1/trips/:id` | Trip Details |
| PATCH | `/api/v1/trips/:id` | Trip aktualisieren |
| DELETE | `/api/v1/trips/:id` | Trip löschen |
| POST | `/api/v1/trips/:id/complete` | Trip abschließen (+XP) |
| GET | `/api/v1/favorites/pois` | Favoriten laden |
| POST | `/api/v1/favorites/pois` | Favorit hinzufügen |
| DELETE | `/api/v1/favorites/pois?poiId=X` | Favorit entfernen |

---

## 5. Rate Limiting

| Endpoint | Limit | Window |
|----------|-------|--------|
| `/api/ai/chat` | 100/Tag | 24h |
| `/api/ai/trip-plan` | 20/Tag | 24h |
| REST API | Unbegrenzt* | - |

*REST API nutzt Supabase Rate Limits.

---

## 6. Sicherheit

### Kritische Punkte

1. **OpenAI Key** - Nur im Backend, NIE im Client
2. **Supabase Service Role Key** - Nur im Backend
3. **JWT Tokens** - Werden von Supabase verwaltet
4. **RLS Policies** - Jeder User sieht nur eigene Daten

### Best Practices

- Alle Environment Variables als `secret` in Vercel markieren
- CORS ist auf alle Origins erlaubt (für Mobile Apps)
- Rate Limiting schützt vor Missbrauch
- Input-Validierung mit Zod

---

## 7. Lokale Entwicklung

### Backend

```bash
cd backend
npm run dev
# → http://localhost:3000
```

### Flutter (mit lokalem Backend)

```bash
flutter run --dart-define=BACKEND_URL=http://localhost:3000
```

---

## 8. Troubleshooting

### "AI service configuration error"
→ `OPENAI_API_KEY` nicht gesetzt oder ungültig

### "Database not configured"
→ Supabase Environment Variables prüfen

### "Unauthorized"
→ JWT Token abgelaufen, neu einloggen

### "Rate limit exceeded"
→ Tageslimit erreicht, 24h warten

---

## 9. Kosten

### Vercel (Free Tier)
- 100GB Bandwidth/Monat
- 100.000 Serverless Function Invocations

### Supabase (Free Tier)
- 500MB Datenbank
- 50.000 Monthly Active Users
- 1GB File Storage

### OpenAI
- Pay-per-use (~$0.002/1K tokens für gpt-4o-mini)

---

## 10. Migration von lokalem Modus

Bestehende lokale Daten (Hive) werden **nicht** automatisch migriert.

Optionen:
1. Neu anfangen (empfohlen)
2. Export-/Import-Feature bauen (TODO)

---

## Änderungshistorie

| Version | Datum | Änderungen |
|---------|-------|------------|
| 1.0.0 | 2026-01-21 | Initial Release |
| 1.1.0 | 2026-01-22 | Supabase vollständig konfiguriert, Auth aktiviert |
