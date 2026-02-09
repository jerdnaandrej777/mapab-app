import type { VercelRequest, VercelResponse } from "@vercel/node";
import { randomUUID } from "node:crypto";

// In-Memory Rate Limit Store (wird bei Serverless-Cold-Start zurückgesetzt)
// Für Produktion: Redis oder Supabase verwenden
const rateLimitStore = new Map<string, { count: number; resetTime: number }>();

const DEFAULT_MAX_REQUESTS = 100; // Pro Tag
const DEFAULT_WINDOW_MS = 24 * 60 * 60 * 1000; // 24 Stunden

interface RateLimitConfig {
  maxRequests?: number;
  windowMs?: number;
  traceId?: string;
}

export interface RateLimitResult {
  allowed: boolean;
  remaining: number;
  reset: number;
  limit: number;
}

function getClientId(req: VercelRequest): string {
  // Priorität: User-ID (Auth) > X-Forwarded-For > x-real-ip > 'anonymous'
  const userId = req.headers["x-user-id"] as string | undefined;
  if (userId) return `user:${userId}`;

  const forwardedFor = req.headers["x-forwarded-for"];
  if (forwardedFor) {
    const ip = Array.isArray(forwardedFor)
      ? forwardedFor[0]
      : forwardedFor.split(",")[0];
    return `ip:${ip.trim()}`;
  }

  const realIp = req.headers["x-real-ip"] as string | undefined;
  if (realIp) return `ip:${realIp}`;

  return "anonymous";
}

export function checkRateLimit(
  req: VercelRequest,
  config: RateLimitConfig = {},
): RateLimitResult {
  const maxRequests =
    config.maxRequests ??
    (parseInt(process.env.RATE_LIMIT_MAX_REQUESTS || "") ||
      DEFAULT_MAX_REQUESTS);
  const windowMs =
    config.windowMs ??
    (parseInt(process.env.RATE_LIMIT_WINDOW_MS || "") || DEFAULT_WINDOW_MS);

  const clientId = getClientId(req);
  const now = Date.now();

  let record = rateLimitStore.get(clientId);

  // Neuer Client oder Window abgelaufen
  if (!record || now >= record.resetTime) {
    record = {
      count: 0,
      resetTime: now + windowMs,
    };
  }

  record.count++;
  rateLimitStore.set(clientId, record);

  const remaining = Math.max(0, maxRequests - record.count);
  const allowed = record.count <= maxRequests;

  return {
    allowed,
    remaining,
    reset: record.resetTime,
    limit: maxRequests,
  };
}

export function applyRateLimitHeaders(
  res: VercelResponse,
  result: RateLimitResult,
): void {
  res.setHeader("X-RateLimit-Limit", result.limit.toString());
  res.setHeader("X-RateLimit-Remaining", result.remaining.toString());
  res.setHeader("X-RateLimit-Reset", result.reset.toString());
}

export function rateLimitMiddleware(
  req: VercelRequest,
  res: VercelResponse,
  config?: RateLimitConfig,
): boolean {
  const result = checkRateLimit(req, config);
  applyRateLimitHeaders(res, result);

  if (!result.allowed) {
    const traceId = config?.traceId ?? randomUUID();
    const message = "Rate limit exceeded";
    const code = "RATE_LIMIT_EXCEEDED";
    res.status(429).json({
      error: {
        message,
        code,
      },
      message,
      code,
      traceId,
      details: `Maximum ${result.limit} requests per day. Resets at ${new Date(result.reset).toISOString()}`,
    });
    return false;
  }

  return true;
}

// Cleanup alte Einträge (alle 5 Minuten)
setInterval(
  () => {
    const now = Date.now();
    for (const [key, record] of rateLimitStore.entries()) {
      if (now >= record.resetTime) {
        rateLimitStore.delete(key);
      }
    }
  },
  5 * 60 * 1000,
);
