import OpenAI from 'openai';

type ChatCompletionCreateParams = OpenAI.ChatCompletionCreateParamsNonStreaming;
type ChatCompletionResponse = OpenAI.ChatCompletion;

// Singleton OpenAI Client
let openaiClient: OpenAI | null = null;

export function getOpenAIClient(): OpenAI {
  if (!openaiClient) {
    const apiKey = process.env.OPENAI_API_KEY?.trim();

    if (!apiKey) {
      throw new Error('OPENAI_API_KEY environment variable is not set');
    }

    openaiClient = new OpenAI({
      apiKey,
    });
  }

  return openaiClient;
}

interface ChatCompletionRetryOptions {
  timeoutMs?: number;
  maxRetries?: number;
  initialBackoffMs?: number;
}

function isRetryableOpenAIError(error: unknown): boolean {
  if (!(error instanceof Error)) return false;
  const status = (error as { status?: number }).status;
  if (status == 429) return true;
  if (status != null && status >= 500) return true;
  return error.name == 'AbortError';
}

function wait(ms: number): Promise<void> {
  return new Promise((resolve) => {
    setTimeout(resolve, ms);
  });
}

export async function createChatCompletionWithRetry(
  client: OpenAI,
  params: ChatCompletionCreateParams,
  options: ChatCompletionRetryOptions = {},
): Promise<ChatCompletionResponse> {
  const timeoutMs = options.timeoutMs ?? 15000;
  const maxRetries = options.maxRetries ?? 2;
  const initialBackoffMs = options.initialBackoffMs ?? 300;

  let attempt = 0;
  // maxRetries=2 -> insgesamt 3 Versuche
  while (true) {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), timeoutMs);

    try {
      return await client.chat.completions.create(params, {
        signal: controller.signal,
      });
    } catch (error) {
      if (attempt >= maxRetries || !isRetryableOpenAIError(error)) {
        throw error;
      }

      const jitter = Math.floor(Math.random() * 100);
      const backoff = initialBackoffMs * (1 << attempt) + jitter;
      attempt++;
      await wait(backoff);
    } finally {
      clearTimeout(timeout);
    }
  }
}

// System Prompts
export const CHAT_SYSTEM_PROMPT = `Du bist ein hilfreicher Reiseassistent fuer die MapAB App - eine App fuer Roadtrips und Sightseeing in Europa.

Deine Aufgaben:
- Beantworte Fragen zu Sehenswuerdigkeiten, Routen und Reiseplanung
- Gib hilfreiche Tipps fuer Roadtrips
- Empfehle interessante POIs (Points of Interest) basierend auf den Interessen des Nutzers
- Hilf bei der Routenoptimierung

Wichtige Regeln:
- Antworte immer auf Deutsch
- Halte dich kurz und praegnant (max 2-3 Absaetze)
- Sei freundlich und hilfsbereit
- Wenn du keine Information hast, sage es ehrlich
- Formatiere Listen mit Aufzaehlungszeichen fuer bessere Lesbarkeit`;

export function buildChatSystemPrompt(context?: {
  userLocation?: { lat: number; lng: number; name?: string };
  routeStart?: string;
  routeEnd?: string;
  distanceKm?: number;
  durationMinutes?: number;
  stops?: Array<{ id?: string; name: string; category?: string; day?: number }>;
  responseLanguage?: string;
  overallWeather?: string;
  dayWeather?: Record<string, string>;
  selectedDay?: number;
  totalDays?: number;
  preferredCategories?: string[];
}): string {
  let prompt = CHAT_SYSTEM_PROMPT;

  if (context) {
    prompt += '\n\nAktuelle Trip-Informationen:';

    if (context.userLocation) {
      const locLabel = context.userLocation.name ?? 'Unbekannter Ort';
      prompt += `\n- Nutzerstandort: ${locLabel} (${context.userLocation.lat.toFixed(4)}, ${context.userLocation.lng.toFixed(4)})`;
    }

    if (context.routeStart && context.routeEnd) {
      prompt += `\n- Route: ${context.routeStart} -> ${context.routeEnd}`;
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
      prompt += `\n- Geplante Stops: ${context.stops.map((s) => s.name).join(', ')}`;
    }

    if (context.responseLanguage) {
      prompt += `\n- Antwortsprache: ${context.responseLanguage}`;
    }

    if (context.overallWeather) {
      prompt += `\n- Gesamtwetter: ${context.overallWeather}`;
    }

    if (context.dayWeather && Object.keys(context.dayWeather).length > 0) {
      const weatherPerDay = Object.entries(context.dayWeather)
        .map(([day, weather]) => `Tag ${day}: ${weather}`)
        .join(', ');
      prompt += `\n- Wetter je Tag: ${weatherPerDay}`;
    }

    if (context.selectedDay) {
      prompt += `\n- Aktuell bearbeiteter Tag: ${context.selectedDay}`;
    }

    if (context.totalDays) {
      prompt += `\n- Gesamte Reisetage: ${context.totalDays}`;
    }

    if (context.preferredCategories && context.preferredCategories.length > 0) {
      prompt += `\n- Bevorzugte Kategorien: ${context.preferredCategories.join(', ')}`;
    }
  }

  return prompt;
}

export const TRIP_PLAN_SYSTEM_PROMPT = `Du bist ein professioneller Reiseplaner fuer die MapAB App.

Deine Aufgabe ist es, detaillierte Tagesreiseplaene zu erstellen.

Format deiner Antwort:
1. Kurze Einleitung (1-2 Saetze)
2. Fuer jeden Tag:
   - **Tag X: [Titel]**
   - Morgens: [Aktivitaeten]
   - Mittags: [Aktivitaeten + Essensempfehlung]
   - Nachmittags: [Aktivitaeten]
   - Abends: [Aktivitaeten + ggf. Unterkunftsempfehlung]
3. Praktische Tipps am Ende

Regeln:
- Antworte immer auf Deutsch
- Beruecksichtige die angegebenen Interessen
- Schlage realistische Zeitplaene vor
- Erwaehne konkrete POIs und Sehenswuerdigkeiten
- Gib Schaetzungen fuer Fahrzeiten zwischen Orten`;

export function buildTripPlanPrompt(params: {
  destination?: string;
  startLocation?: string;
  days: number;
  interests: string[];
}): string {
  let userPrompt = `Erstelle einen ${params.days}-Tage Reiseplan`;

  if (params.destination) {
    userPrompt += ` fuer ${params.destination}`;
  } else if (params.startLocation) {
    userPrompt += ` mit Start in ${params.startLocation} (Ziel: Rundreise/Ueberraschung)`;
  } else {
    userPrompt += ' (beliebiges Ziel)';
  }

  userPrompt += `.\n\nInteressen: ${params.interests.join(', ')}`;

  if (!params.destination && params.startLocation) {
    userPrompt += `\n\nHinweis: Der Nutzer hat kein spezifisches Ziel angegeben. Schlage eine interessante Route/Rundreise ausgehend von ${params.startLocation} vor, die zu den Interessen passt.`;
  }

  return userPrompt;
}

export const POI_SUGGESTIONS_SYSTEM_PROMPT = `Du bist ein Reise-Optimierer fuer die MapAB App.
Deine Aufgabe: Wandle Kandidaten-POIs in konkrete, umsetzbare Empfehlungen um.

Regeln:
- Antworte ausschliesslich als gueltiges JSON-Objekt.
- Empfiehl nur POIs aus den uebergebenen Kandidaten.
- Priorisiere Must-See, UNESCO, kuratierte und gut wetter-passende Orte.
- Bei schlechtem Wetter moeglichst Indoor-Optionen priorisieren.
- "swap" nur verwenden, wenn explizit erlaubt und ein targetPoiId vorliegt.
- "relevance" muss zwischen 0.0 und 1.0 liegen.
- Nutze klare, konkrete Begruendungen.
- longDescription soll informationsreich sein (historisch, Erlebnis, praktische Tipps), aber ohne Halluzinationen.
`;
