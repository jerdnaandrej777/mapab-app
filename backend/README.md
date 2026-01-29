# MapAB Backend

Backend API für die MapAB Flutter App. Schützt API-Keys und bietet zentrale Services.

## Setup

### 1. Dependencies installieren

```bash
cd backend
npm install
```

### 2. Environment Variables

Kopiere `.env.example` zu `.env` und fülle die Werte aus:

```bash
cp .env.example .env
```

**Erforderlich:**
- `OPENAI_API_KEY` - OpenAI API Key von https://platform.openai.com/api-keys

### 3. Lokal entwickeln

```bash
npm run dev
```

Das Backend startet unter `http://localhost:3000`.

### 4. Deployment (Vercel)

```bash
# Vercel CLI installieren (falls nicht vorhanden)
npm i -g vercel

# Deployment
vercel

# Produktions-Deployment
vercel --prod
```

**Wichtig:** Setze `OPENAI_API_KEY` in den Vercel Environment Variables!

## API Endpoints

### Health Check
```
GET /api/health
```

### AI Chat
```
POST /api/ai/chat
Content-Type: application/json

{
  "message": "Welche Sehenswürdigkeiten gibt es in Berlin?",
  "context": {
    "routeStart": "München",
    "routeEnd": "Berlin",
    "distanceKm": 580
  },
  "history": []
}
```

### AI Trip Plan
```
POST /api/ai/trip-plan
Content-Type: application/json

{
  "destination": "Prag",
  "startLocation": "München",
  "days": 3,
  "interests": ["Kultur", "Geschichte", "Essen"]
}
```

## Rate Limiting

- **Chat:** 100 Requests/Tag pro IP
- **Trip-Plan:** 20 Requests/Tag pro IP

## Projektstruktur

```
backend/
├── api/
│   ├── ai/
│   │   ├── chat.ts        # AI Chat Endpoint
│   │   └── trip-plan.ts   # Trip Plan Generator
│   └── health.ts          # Health Check
├── lib/
│   ├── middleware/
│   │   └── rateLimit.ts   # Rate Limiting
│   ├── openai.ts          # OpenAI Client & Prompts
│   └── types.ts           # TypeScript Types & Zod Schemas
├── package.json
├── tsconfig.json
└── vercel.json
```
