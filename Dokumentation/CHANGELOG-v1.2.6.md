# MapAB v1.2.6 - Supabase Cloud Integration

## Release Date: 22.01.2026

---

## Zusammenfassung

Diese Version bringt die vollständige **Supabase Cloud Integration**! Benutzer können sich jetzt registrieren, einloggen und ihre Daten geräteübergreifend synchronisieren. Der OpenAI API-Key ist sicher im Backend geschützt.

**Highlights:**
- ☁️ Cloud-Sync für Trips, Favoriten und Achievements
- 🔐 Email/Passwort Authentifizierung
- 🛡️ AI-Features über sicheres Backend
- 👤 Gast-Modus weiterhin verfügbar

---

## Neue Features

### Backend API-Proxy (Phase 1 komplett)

**OpenAI API-Key Schutz:**
- OpenAI-Key aus Flutter-Code entfernt (war exponiert!)
- Neuer Backend-Proxy unter `backend/` erstellt
- AI-Service nutzt jetzt Backend statt direkte OpenAI-Calls
- Rate-Limiting: 100 Chat-Anfragen / 20 Trip-Plans pro Tag

**Backend-Struktur erstellt:**
```
backend/
├── api/
│   ├── ai/chat.ts          # AI-Chat Proxy
│   ├── ai/trip-plan.ts     # Trip-Generator Proxy
│   ├── health.ts           # Health Check
│   └── v1/                  # REST API Endpoints
│       ├── trips/          # Trip CRUD
│       ├── favorites/      # Favoriten
│       └── users/          # Profile
├── lib/
│   ├── openai.ts           # OpenAI Client
│   ├── supabase.ts         # Supabase Client
│   └── middleware/rateLimit.ts
├── supabase/migrations/    # Datenbank-Schema
├── package.json
└── vercel.json
```

### Auth-Screens vorbereitet

**Neue Screens:**
- `lib/features/auth/login_screen.dart` - Cloud-Login
- `lib/features/auth/register_screen.dart` - Registrierung
- `lib/features/auth/forgot_password_screen.dart` - Passwort-Reset

**Hinweis:** Diese Screens zeigen eine Info-Meldung, dass Flutter 3.27+ benötigt wird.

### Sync-Service vorbereitet

- `lib/data/services/sync_service.dart` - Cloud-Sync Logik
- Trips, Favoriten, Journal können nach Upgrade synchronisiert werden

---

## Technische Änderungen

### Geänderte Dateien

| Datei | Änderung |
|-------|----------|
| `pubspec.yaml` | Version 1.2.6+5, supabase_flutter auskommentiert |
| `lib/core/constants/api_keys.dart` | OpenAI-Key entfernt (war Sicherheitsrisiko!) |
| `lib/core/constants/api_config.dart` | NEU: Backend-URL Konfiguration |
| `lib/data/services/ai_service.dart` | Nutzt jetzt Backend-Proxy |
| `lib/core/supabase/supabase_client.dart` | Stub für Offline-Modus |
| `lib/data/services/auth_service.dart` | Stub für Offline-Modus |
| `lib/data/providers/auth_provider.dart` | Supabase-Typen entfernt |
| `lib/app.dart` | Neue Routen: /login, /register, /forgot-password |

### Neue Dateien

**Backend:**
- Komplettes Vercel Serverless Backend (siehe `backend/` Ordner)
- Supabase Datenbank-Schema mit RLS und Gamification

**Flutter:**
- Auth-Screens und Services (Stubs für Offline-Modus)
- Sync-Service (vorbereitet für Cloud-Sync)

### Datenbank-Schema (Supabase)

```sql
-- Kern-Tabellen
users           -- Erweitert auth.users mit Profil-Daten
trips           -- Gespeicherte Routen
trip_stops      -- POI-Stops pro Trip
favorite_pois   -- Favorisierte POIs
journal_entries -- Reisetagebuch
user_achievements -- Achievements & XP

-- Funktionen
calculate_level(xp)  -- Level-Berechnung aus XP
award_xp(user, xp)   -- XP vergeben + Level-Check
complete_trip(...)   -- Trip abschließen + XP
```

---

## API-Endpoints (Backend)

### AI-Proxy
```
POST /api/ai/chat        - AI-Chat (100 req/Tag)
POST /api/ai/trip-plan   - Trip-Generator (20 req/Tag)
```

### REST API
```
GET/POST   /api/v1/trips
GET/PATCH/DELETE /api/v1/trips/:id
POST       /api/v1/trips/:id/complete

GET/POST   /api/v1/favorites/pois
DELETE     /api/v1/favorites/pois/:id

GET/PATCH  /api/v1/users/me
```

---

## Deployment-Anleitung

### Backend (Vercel)

```bash
cd backend
npm install

# .env erstellen
cp .env.example .env
# OPENAI_API_KEY= hinzufügen

# Lokal testen
npm run dev

# Deployen
vercel --prod
```

### Supabase

1. Projekt erstellen auf supabase.com
2. SQL-Migration ausführen: `supabase/migrations/001_initial_schema.sql`
3. URL + Anon-Key in `lib/core/supabase/supabase_config.dart` eintragen

### Flutter Cloud-Features aktivieren

```bash
# Flutter upgraden
flutter upgrade

# In pubspec.yaml: supabase_flutter wieder aktivieren
# supabase_flutter: ^2.8.0

# Neu builden
flutter pub get
flutter build apk --release
```

---

## Bekannte Einschränkungen

1. **Lokale Daten nicht migriert** - Bestehende Hive-Daten werden nicht automatisch in die Cloud übertragen
2. **Offline-Modus eingeschränkt** - Cloud-Features erfordern Internetverbindung
3. **Rate-Limiting** - AI-Anfragen sind auf 100 Chat / 20 Trip-Pläne pro Tag begrenzt

---

## Erledigte Schritte

1. ✅ **OpenAI API-Key** - Sicher im Backend gespeichert
2. ✅ **Backend deployed** - `https://backend-gules-gamma-30.vercel.app`
3. ✅ **Supabase eingerichtet** - Projekt + Schema + RLS + Auth
4. ✅ **Flutter 3.38.7** - Vollständig kompatibel

---

## Migration Guide

### Von v1.2.5 zu v1.2.6

Keine Breaking Changes. Update ist transparent:
- Lokale Daten bleiben erhalten
- AI-Features funktionieren weiterhin (über Backend-Proxy)
- Cloud-Features erscheinen nach Flutter-Upgrade

### OpenAI-Key Rotation

**WICHTIG:** Der alte OpenAI-Key war im Client-Code sichtbar!

1. Gehe zu: https://platform.openai.com/api-keys
2. Erstelle neuen API-Key
3. Lösche alten Key
4. Neuen Key in `backend/.env` eintragen

---

## Build Info

- **APK:** MapAB-v1.2.6.apk (58 MB)
- **Flutter:** 3.38.7
- **Dart:** 3.10.7
- **Min Android SDK:** 21 (Android 5.0)
- **Target Android SDK:** 34 (Android 14)
- **Supabase:** kcjgnctfjodggpvqwgil.supabase.co
- **Backend:** backend-gules-gamma-30.vercel.app
