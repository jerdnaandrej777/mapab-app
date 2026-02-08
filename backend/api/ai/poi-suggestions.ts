import type { VercelRequest, VercelResponse } from '@vercel/node';
import {
  PoiSuggestionsRequestSchema,
  PoiSuggestionsResponseSchema,
  type PoiSuggestionsRequest,
  type PoiSuggestionsResponse,
} from '../../lib/types';
import { getOpenAIClient, POI_SUGGESTIONS_SYSTEM_PROMPT } from '../../lib/openai';
import { rateLimitMiddleware } from '../../lib/middleware/rateLimit';

function clampRelevance(value: number): number {
  if (!Number.isFinite(value)) return 0.5;
  return Math.max(0, Math.min(1, value));
}

function scoreCandidate(candidate: PoiSuggestionsRequest['candidates'][number], isBadWeather: boolean): number {
  let score = Number(candidate.score) || 0;
  if (candidate.isMustSee) score += 35;
  if (candidate.isCurated) score += 15;
  if (candidate.isUnesco) score += 20;
  if (isBadWeather && candidate.isIndoor) score += 20;
  if (candidate.detourKm != null) score -= candidate.detourKm * 0.5;
  return score;
}

function fallbackSuggestions(payload: PoiSuggestionsRequest): PoiSuggestionsResponse {
  const maxSuggestions = payload.constraints?.maxSuggestions ?? 8;
  const allowSwap = payload.constraints?.allowSwap ?? true;
  const weather = payload.userContext?.weatherCondition;
  const isBadWeather = weather === 'bad' || weather === 'danger';
  const targetStopId = allowSwap ? payload.tripContext?.stops?.[0]?.id : undefined;

  const sorted = [...payload.candidates].sort((a, b) => {
    return scoreCandidate(b, isBadWeather) - scoreCandidate(a, isBadWeather);
  });

  const top = sorted.slice(0, maxSuggestions);
  return {
    summary: top.length > 0
      ? 'Fallback-Empfehlungen wurden lokal aus Kandidaten erstellt.'
      : 'Keine passenden POIs gefunden.',
    suggestions: top.map((candidate, index) => {
      const highlights: string[] = [];
      if (candidate.isMustSee) highlights.push('Must-See');
      if (candidate.isUnesco) highlights.push('UNESCO');
      if (candidate.isCurated) highlights.push('Kuratiert');
      if (isBadWeather && candidate.isIndoor) highlights.push('Indoor bei schlechtem Wetter');

      const action = allowSwap && targetStopId && isBadWeather && index === 0 ? 'swap' : 'add';
      return {
        poiId: candidate.id,
        action,
        targetPoiId: action === 'swap' ? targetStopId : undefined,
        reason: isBadWeather && candidate.isIndoor
          ? `${candidate.name} passt wetterbedingt als Indoor-Alternative.`
          : `${candidate.name} hat hohe Relevanz fuer die aktuelle Route.`,
        relevance: clampRelevance((scoreCandidate(candidate, isBadWeather) + 20) / 160),
        highlights,
        longDescription:
          candidate.shortDescription?.trim() ||
          `${candidate.name} (${candidate.categoryId}) ist ein starker Kandidat mit Score ${candidate.score}.`,
      };
    }),
  };
}

function extractJsonObject(raw: string): string {
  const start = raw.indexOf('{');
  const end = raw.lastIndexOf('}');
  if (start === -1 || end === -1 || end <= start) {
    throw new Error('No JSON object found in AI response');
  }
  return raw.slice(start, end + 1);
}

function buildUserPrompt(payload: PoiSuggestionsRequest): string {
  const maxSuggestions = payload.constraints?.maxSuggestions ?? 8;
  const allowSwap = payload.constraints?.allowSwap ?? true;
  const weather = payload.userContext?.weatherCondition ?? 'unknown';
  const locationName = payload.userContext?.locationName ?? 'Unbekannt';

  const stopSummary = payload.tripContext?.stops?.length
    ? payload.tripContext.stops
        .map((s) => `${s.name}${s.id ? ` (${s.id})` : ''}${s.day ? ` Tag ${s.day}` : ''}`)
        .join(', ')
    : 'Keine Stops';

  const candidates = payload.candidates
    .map((c) => {
      const tags = c.tags?.join(', ') ?? '';
      return `- id=${c.id}; name=${c.name}; category=${c.categoryId}; score=${c.score}; mustSee=${c.isMustSee}; curated=${c.isCurated}; unesco=${c.isUnesco}; indoor=${c.isIndoor}; detourKm=${c.detourKm ?? '?'}; routePosition=${c.routePosition ?? '?'}; short=${c.shortDescription ?? ''}; tags=${tags}`;
    })
    .join('\n');

  return `
Erzeuge strukturierte POI-Empfehlungen als JSON-Objekt.

Modus: ${payload.mode}
Sprache: ${payload.language ?? 'de'}
Ort: ${locationName}
Wetter: ${weather}
Route: ${payload.tripContext?.routeStart ?? 'n/a'} -> ${payload.tripContext?.routeEnd ?? 'n/a'}
Stops: ${stopSummary}
maxSuggestions: ${maxSuggestions}
allowSwap: ${allowSwap}

Kandidaten:
${candidates}

Antworte exakt im Format:
{
  "summary": "...",
  "suggestions": [
    {
      "poiId": "...",
      "action": "add|swap",
      "targetPoiId": "... optional bei swap",
      "reason": "...",
      "relevance": 0.0,
      "highlights": ["..."],
      "longDescription": "..."
    }
  ]
}
`.trim();
}

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({
      error: 'Method not allowed',
      code: 'METHOD_NOT_ALLOWED',
    });
  }

  // Slightly stricter than normal chat.
  if (!rateLimitMiddleware(req, res, { maxRequests: 60 })) {
    return;
  }

  const parsed = PoiSuggestionsRequestSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({
      error: 'Invalid request body',
      code: 'VALIDATION_ERROR',
      details: parsed.error.errors.map((e) => `${e.path.join('.')}: ${e.message}`).join(', '),
    });
  }

  const payload = parsed.data;

  try {
    const openai = getOpenAIClient();
    const completion = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [
        {
          role: 'system',
          content: POI_SUGGESTIONS_SYSTEM_PROMPT,
        },
        {
          role: 'user',
          content: buildUserPrompt(payload),
        },
      ],
      response_format: { type: 'json_object' },
      temperature: 0.4,
      max_tokens: 1800,
    });

    const rawMessage = completion.choices[0]?.message?.content;
    if (!rawMessage) {
      const fallback = fallbackSuggestions(payload);
      return res.status(200).json({
        ...fallback,
        source: 'fallback',
        tokensUsed: completion.usage?.total_tokens,
      });
    }

    let validated: PoiSuggestionsResponse;
    try {
      const parsedJson = JSON.parse(extractJsonObject(rawMessage));
      const responseValidation = PoiSuggestionsResponseSchema.safeParse(parsedJson);

      if (!responseValidation.success) {
        throw new Error(responseValidation.error.errors.map((e) => `${e.path.join('.')}: ${e.message}`).join(', '));
      }

      validated = responseValidation.data;
      const allowedCandidateIds = new Set(payload.candidates.map((c) => c.id));
      const allowedStopIds = new Set((payload.tripContext?.stops ?? []).map((s) => s.id));

      validated = {
        summary: validated.summary,
        suggestions: validated.suggestions
          .filter((s) => allowedCandidateIds.has(s.poiId))
          .map((s) => ({
            ...s,
            relevance: clampRelevance(s.relevance),
            targetPoiId: s.action === 'swap' && s.targetPoiId && allowedStopIds.has(s.targetPoiId)
              ? s.targetPoiId
              : undefined,
          }))
          .map((s) => (s.action === 'swap' && !s.targetPoiId ? { ...s, action: 'add' as const } : s)),
      };

      if ((payload.constraints?.maxSuggestions ?? 8) < validated.suggestions.length) {
        validated.suggestions = validated.suggestions.slice(0, payload.constraints?.maxSuggestions ?? 8);
      }
    } catch (parseError) {
      console.error('[AI POI Suggestions] Parsing failed, using fallback:', parseError);
      validated = fallbackSuggestions(payload);
      return res.status(200).json({
        ...validated,
        source: 'fallback',
        tokensUsed: completion.usage?.total_tokens,
      });
    }

    return res.status(200).json({
      ...validated,
      source: 'ai',
      tokensUsed: completion.usage?.total_tokens,
    });
  } catch (error) {
    console.error('[AI POI Suggestions] Error:', error);
    const fallback = fallbackSuggestions(payload);
    return res.status(200).json({
      ...fallback,
      source: 'fallback',
    });
  }
}
