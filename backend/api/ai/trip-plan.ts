import type { VercelRequest, VercelResponse } from "@vercel/node";
import { randomUUID } from "node:crypto";
import { TripPlanRequestSchema } from "../../lib/types";
import {
  getOpenAIClient,
  TRIP_PLAN_SYSTEM_PROMPT,
  buildTripPlanPrompt,
  createChatCompletionWithRetry,
} from "../../lib/openai";
import { rateLimitMiddleware } from "../../lib/middleware/rateLimit";

const ENDPOINT = "/api/ai/trip-plan";
const MODEL = "gpt-4o-mini";

function logRequest(params: {
  traceId: string;
  status: number;
  durationMs: number;
  fallback: boolean;
  model: string;
}) {
  console.log(
    "[AI API]",
    JSON.stringify({
      endpoint: ENDPOINT,
      traceId: params.traceId,
      status: params.status,
      durationMs: params.durationMs,
      fallback: params.fallback,
      model: params.model,
    }),
  );
}

function sendError(
  res: VercelResponse,
  status: number,
  traceId: string,
  code: string,
  message: string,
  details?: string,
) {
  return res.status(status).json({
    error: {
      message,
      code,
    },
    message,
    code,
    traceId,
    ...(details ? { details } : {}),
  });
}

export default async function handler(req: VercelRequest, res: VercelResponse) {
  const traceId = randomUUID();
  const startedAt = Date.now();

  if (req.method === "OPTIONS") {
    return res.status(200).end();
  }

  if (req.method !== "POST") {
    logRequest({
      traceId,
      status: 405,
      durationMs: Date.now() - startedAt,
      fallback: false,
      model: MODEL,
    });
    return sendError(
      res,
      405,
      traceId,
      "METHOD_NOT_ALLOWED",
      "Method not allowed",
    );
  }

  if (!(await rateLimitMiddleware(req, res, { maxRequests: 20, traceId }))) {
    logRequest({
      traceId,
      status: 429,
      durationMs: Date.now() - startedAt,
      fallback: false,
      model: MODEL,
    });
    return;
  }

  try {
    const parseResult = TripPlanRequestSchema.safeParse(req.body);

    if (!parseResult.success) {
      const details = parseResult.error.errors
        .map((e) => `${e.path.join(".")}: ${e.message}`)
        .join(", ");
      logRequest({
        traceId,
        status: 400,
        durationMs: Date.now() - startedAt,
        fallback: false,
        model: MODEL,
      });
      return sendError(
        res,
        400,
        traceId,
        "VALIDATION_ERROR",
        "Invalid request body",
        details,
      );
    }

    const { destination, startLocation, days, interests } = parseResult.data;

    if (!destination && !startLocation) {
      logRequest({
        traceId,
        status: 400,
        durationMs: Date.now() - startedAt,
        fallback: false,
        model: MODEL,
      });
      return sendError(
        res,
        400,
        traceId,
        "MISSING_LOCATION",
        "Either destination or startLocation must be provided",
      );
    }

    const openai = getOpenAIClient();

    const userPrompt = buildTripPlanPrompt({
      destination,
      startLocation,
      days,
      interests,
    });

    const completion = await createChatCompletionWithRetry(
      openai,
      {
        model: MODEL,
        messages: [
          {
            role: "system",
            content: TRIP_PLAN_SYSTEM_PROMPT,
          },
          {
            role: "user",
            content: userPrompt,
          },
        ],
        max_tokens: 2000,
        temperature: 0.8,
      },
      {
        timeoutMs: 20000,
        maxRetries: 2,
      },
    );

    const planContent = completion.choices[0]?.message?.content;

    if (!planContent) {
      logRequest({
        traceId,
        status: 500,
        durationMs: Date.now() - startedAt,
        fallback: false,
        model: MODEL,
      });
      return sendError(
        res,
        500,
        traceId,
        "AI_NO_RESPONSE",
        "No response from AI",
      );
    }

    logRequest({
      traceId,
      status: 200,
      durationMs: Date.now() - startedAt,
      fallback: false,
      model: MODEL,
    });
    return res.status(200).json({
      plan: planContent,
      tokensUsed: completion.usage?.total_tokens,
      traceId,
      source: "ai",
    });
  } catch (error) {
    console.error("[AI Trip-Plan Error]", error);

    if (error instanceof Error) {
      if (error.message.includes("API key")) {
        logRequest({
          traceId,
          status: 500,
          durationMs: Date.now() - startedAt,
          fallback: false,
          model: MODEL,
        });
        return sendError(
          res,
          500,
          traceId,
          "AI_CONFIG_ERROR",
          "AI service configuration error",
        );
      }

      if (error.message.includes("quota") || error.message.includes("rate")) {
        logRequest({
          traceId,
          status: 503,
          durationMs: Date.now() - startedAt,
          fallback: false,
          model: MODEL,
        });
        return sendError(
          res,
          503,
          traceId,
          "AI_RATE_LIMITED",
          "AI service temporarily unavailable",
        );
      }
    }

    logRequest({
      traceId,
      status: 500,
      durationMs: Date.now() - startedAt,
      fallback: false,
      model: MODEL,
    });
    return sendError(
      res,
      500,
      traceId,
      "INTERNAL_ERROR",
      "Internal server error",
    );
  }
}
