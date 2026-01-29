import OpenAI from 'openai';

// Singleton OpenAI Client
let openaiClient: OpenAI | null = null;

export function getOpenAIClient(): OpenAI {
  if (!openaiClient) {
    const apiKey = process.env.OPENAI_API_KEY?.trim();

    if (!apiKey) {
      throw new Error('OPENAI_API_KEY environment variable is not set');
    }

    // Debug: Log API key prefix (nur erste 20 Zeichen)
    console.log('[OpenAI] API Key Prefix:', apiKey.substring(0, 20) + '...');
    console.log('[OpenAI] API Key Length:', apiKey.length);

    openaiClient = new OpenAI({
      apiKey: apiKey,
    });
  }

  return openaiClient;
}

// System Prompts
export const CHAT_SYSTEM_PROMPT = `Du bist ein hilfreicher Reiseassistent für die MapAB App - eine App für Roadtrips und Sightseeing in Europa.

Deine Aufgaben:
- Beantworte Fragen zu Sehenswürdigkeiten, Routen und Reiseplanung
- Gib hilfreiche Tipps für Roadtrips
- Empfehle interessante POIs (Points of Interest) basierend auf den Interessen des Nutzers
- Hilf bei der Routenoptimierung

Wichtige Regeln:
- Antworte immer auf Deutsch
- Halte dich kurz und prägnant (max 2-3 Absätze)
- Sei freundlich und hilfsbereit
- Wenn du keine Information hast, sage es ehrlich
- Formatiere Listen mit Aufzählungszeichen für bessere Lesbarkeit`;

export function buildChatSystemPrompt(context?: {
  routeStart?: string;
  routeEnd?: string;
  distanceKm?: number;
  durationMinutes?: number;
  stops?: Array<{ name: string; category?: string }>;
}): string {
  let prompt = CHAT_SYSTEM_PROMPT;

  if (context) {
    prompt += '\n\nAktuelle Trip-Informationen:';

    if (context.routeStart && context.routeEnd) {
      prompt += `\n- Route: ${context.routeStart} → ${context.routeEnd}`;
    }

    if (context.distanceKm) {
      prompt += `\n- Entfernung: ${context.distanceKm.toFixed(1)} km`;
    }

    if (context.durationMinutes) {
      const hours = Math.floor(context.durationMinutes / 60);
      const minutes = context.durationMinutes % 60;
      prompt += `\n- Fahrtzeit: ${hours}h ${minutes}min`;
    }

    if (context.stops && context.stops.length > 0) {
      prompt += `\n- Geplante Stops: ${context.stops.map(s => s.name).join(', ')}`;
    }
  }

  return prompt;
}

export const TRIP_PLAN_SYSTEM_PROMPT = `Du bist ein professioneller Reiseplaner für die MapAB App.

Deine Aufgabe ist es, detaillierte Tagesreisepläne zu erstellen.

Format deiner Antwort:
1. Kurze Einleitung (1-2 Sätze)
2. Für jeden Tag:
   - **Tag X: [Titel]**
   - Morgens: [Aktivitäten]
   - Mittags: [Aktivitäten + Essensempfehlung]
   - Nachmittags: [Aktivitäten]
   - Abends: [Aktivitäten + ggf. Unterkunftsempfehlung]
3. Praktische Tipps am Ende

Regeln:
- Antworte immer auf Deutsch
- Berücksichtige die angegebenen Interessen
- Schlage realistische Zeitpläne vor
- Erwähne konkrete POIs und Sehenswürdigkeiten
- Gib Schätzungen für Fahrzeiten zwischen Orten`;

export function buildTripPlanPrompt(params: {
  destination?: string;
  startLocation?: string;
  days: number;
  interests: string[];
}): string {
  let userPrompt = `Erstelle einen ${params.days}-Tage Reiseplan`;

  if (params.destination) {
    userPrompt += ` für ${params.destination}`;
  } else if (params.startLocation) {
    userPrompt += ` mit Start in ${params.startLocation} (Ziel: Rundreise/Überraschung)`;
  } else {
    userPrompt += ` (beliebiges Ziel)`;
  }

  userPrompt += `.\n\nInteressen: ${params.interests.join(', ')}`;

  if (!params.destination && params.startLocation) {
    userPrompt += `\n\nHinweis: Der Nutzer hat kein spezifisches Ziel angegeben. Schlage eine interessante Route/Rundreise ausgehend von ${params.startLocation} vor, die zu den Interessen passt.`;
  }

  return userPrompt;
}
