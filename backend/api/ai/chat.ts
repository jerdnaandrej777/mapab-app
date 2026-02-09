import type { VercelRequest, VercelResponse } from "@vercel/node";
import { randomUUID } from "node:crypto";
import { ChatRequestSchema } from "../../lib/types";
import { getOpenAIClient, buildChatSystemPrompt } from "../../lib/openai";
import { rateLimitMiddleware } from "../../lib/middleware/rateLimit";

const ENDPOINT = "/api/ai/chat";
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

  if (!rateLimitMiddleware(req, res, { traceId })) {
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
    const parseResult = ChatRequestSchema.safeParse(req.body);

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

    const { message, context, history } = parseResult.data;
    const openai = getOpenAIClient();

    const messages: Array<{
      role: "system" | "user" | "assistant";
      content: string;
    }> = [
      {
        role: "system",
        content: buildChatSystemPrompt(context),
      },
    ];

    if (history && history.length > 0) {
      for (const msg of history) {
        if (msg.role === "user" || msg.role === "assistant") {
          messages.push({
            role: msg.role,
            content: msg.content,
          });
        }
      }
    }

    messages.push({
      role: "user",
      content: message,
    });

    const completion = await openai.chat.completions.create({
      model: MODEL,
      messages,
      max_tokens: 1000,
      temperature: 0.7,
    });

    const responseMessage = completion.choices[0]?.message?.content;

    if (!responseMessage) {
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
      message: responseMessage,
      tokensUsed: completion.usage?.total_tokens,
      traceId,
      source: "ai",
    });
  } catch (error) {
    console.error("[AI Chat Error]", error);

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
