import type { VercelRequest, VercelResponse } from '@vercel/node';
import { ChatRequestSchema } from '../../lib/types';
import { getOpenAIClient, buildChatSystemPrompt } from '../../lib/openai';
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

  // Rate Limiting prüfen
  if (!rateLimitMiddleware(req, res)) {
    return; // Response wurde bereits gesendet
  }

  try {
    // Request validieren
    const parseResult = ChatRequestSchema.safeParse(req.body);

    if (!parseResult.success) {
      return res.status(400).json({
        error: 'Invalid request body',
        code: 'VALIDATION_ERROR',
        details: parseResult.error.errors.map(e => `${e.path.join('.')}: ${e.message}`).join(', '),
      });
    }

    const { message, context, history } = parseResult.data;

    // OpenAI Client
    const openai = getOpenAIClient();

    // Messages aufbauen
    const messages: Array<{ role: 'system' | 'user' | 'assistant'; content: string }> = [
      {
        role: 'system',
        content: buildChatSystemPrompt(context),
      },
    ];

    // History hinzufügen (falls vorhanden)
    if (history && history.length > 0) {
      for (const msg of history) {
        if (msg.role === 'user' || msg.role === 'assistant') {
          messages.push({
            role: msg.role,
            content: msg.content,
          });
        }
      }
    }

    // Aktuelle Nachricht
    messages.push({
      role: 'user',
      content: message,
    });

    // OpenAI Request
    const completion = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: messages,
      max_tokens: 1000,
      temperature: 0.7,
    });

    const responseMessage = completion.choices[0]?.message?.content;

    if (!responseMessage) {
      return res.status(500).json({
        error: 'No response from AI',
        code: 'AI_NO_RESPONSE',
      });
    }

    // Erfolgreiche Antwort
    return res.status(200).json({
      message: responseMessage,
      tokensUsed: completion.usage?.total_tokens,
    });

  } catch (error) {
    console.error('[AI Chat Error]', error);

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
