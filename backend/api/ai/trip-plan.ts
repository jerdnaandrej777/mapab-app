import type { VercelRequest, VercelResponse } from '@vercel/node';
import { TripPlanRequestSchema } from '../../lib/types';
import { getOpenAIClient, TRIP_PLAN_SYSTEM_PROMPT, buildTripPlanPrompt } from '../../lib/openai';
import { rateLimitMiddleware } from '../../lib/middleware/rateLimit';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  // CORS preflight
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  // Nur POST erlauben
  if (req.method !== 'POST') {
    return res.status(405).json({
      error: 'Method not allowed',
      code: 'METHOD_NOT_ALLOWED',
    });
  }

  // Rate Limiting prüfen (Trip-Pläne verbrauchen mehr Tokens, also strenger limitieren)
  if (!rateLimitMiddleware(req, res, { maxRequests: 20 })) {
    return; // Response wurde bereits gesendet
  }

  try {
    // Request validieren
    const parseResult = TripPlanRequestSchema.safeParse(req.body);

    if (!parseResult.success) {
      return res.status(400).json({
        error: 'Invalid request body',
        code: 'VALIDATION_ERROR',
        details: parseResult.error.errors.map(e => `${e.path.join('.')}: ${e.message}`).join(', '),
      });
    }

    const { destination, startLocation, days, interests } = parseResult.data;

    // Mindestens Ziel oder Start muss angegeben sein
    if (!destination && !startLocation) {
      return res.status(400).json({
        error: 'Either destination or startLocation must be provided',
        code: 'MISSING_LOCATION',
      });
    }

    // OpenAI Client
    const openai = getOpenAIClient();

    // User Prompt erstellen
    const userPrompt = buildTripPlanPrompt({
      destination,
      startLocation,
      days,
      interests,
    });

    // OpenAI Request
    const completion = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [
        {
          role: 'system',
          content: TRIP_PLAN_SYSTEM_PROMPT,
        },
        {
          role: 'user',
          content: userPrompt,
        },
      ],
      max_tokens: 2000, // Mehr Tokens für detaillierte Pläne
      temperature: 0.8, // Etwas kreativer
    });

    const planContent = completion.choices[0]?.message?.content;

    if (!planContent) {
      return res.status(500).json({
        error: 'No response from AI',
        code: 'AI_NO_RESPONSE',
      });
    }

    // Erfolgreiche Antwort
    return res.status(200).json({
      plan: planContent,
      tokensUsed: completion.usage?.total_tokens,
    });

  } catch (error) {
    console.error('[AI Trip-Plan Error]', error);

    // OpenAI-spezifische Fehler
    if (error instanceof Error) {
      if (error.message.includes('API key')) {
        return res.status(500).json({
          error: 'AI service configuration error',
          code: 'AI_CONFIG_ERROR',
        });
      }

      if (error.message.includes('quota') || error.message.includes('rate')) {
        return res.status(503).json({
          error: 'AI service temporarily unavailable',
          code: 'AI_RATE_LIMITED',
        });
      }
    }

    return res.status(500).json({
      error: 'Internal server error',
      code: 'INTERNAL_ERROR',
    });
  }
}
