import type { VercelRequest, VercelResponse } from "@vercel/node";
import { randomUUID } from "node:crypto";
import { Redis } from "@upstash/redis";

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

// Fallback fuer lokale/dev Nutzung oder wenn Redis nicht konfiguriert ist.
const inMemoryRateLimitStore = new Map<string, { count: number; resetTime: number }>();
let redisClient: Redis | null | undefined;

function getRedisClient(): Redis | null {
  if (redisClient !== undefined) {
    return redisClient;
  }

  const url = process.env.UPSTASH_REDIS_REST_URL;
  const token = process.env.UPSTASH_REDIS_REST_TOKEN;
  if (!url || !token) {
    redisClient = null;
    return redisClient;
  }

  redisClient = new Redis({
    url,
    token,
  });
  return redisClient;
}

function getClientId(req: VercelRequest): string {
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

function resolveRateLimitConfig(config: RateLimitConfig = {}): {
  maxRequests: number;
  windowMs: number;
} {
  const maxRequests =
    config.maxRequests ??
    (parseInt(process.env.RATE_LIMIT_MAX_REQUESTS || "") || DEFAULT_MAX_REQUESTS);
  const windowMs =
    config.windowMs ??
    (parseInt(process.env.RATE_LIMIT_WINDOW_MS || "") || DEFAULT_WINDOW_MS);

  return { maxRequests, windowMs };
}

function checkRateLimitInMemory(
  clientId: string,
  maxRequests: number,
  windowMs: number,
): RateLimitResult {
  const now = Date.now();
  const windowStart = Math.floor(now / windowMs) * windowMs;
  const resetTime = windowStart + windowMs;
  const storeKey = `${clientId}:${windowStart}`;

  const record = inMemoryRateLimitStore.get(storeKey) ?? {
    count: 0,
    resetTime,
  };

  record.count++;
  inMemoryRateLimitStore.set(storeKey, record);

  return {
    allowed: record.count <= maxRequests,
    remaining: Math.max(0, maxRequests - record.count),
    reset: resetTime,
    limit: maxRequests,
  };
}

async function checkRateLimitRedis(
  clientId: string,
  maxRequests: number,
  windowMs: number,
): Promise<RateLimitResult> {
  const redis = getRedisClient();
  if (!redis) {
    return checkRateLimitInMemory(clientId, maxRequests, windowMs);
  }

  const now = Date.now();
  const windowStart = Math.floor(now / windowMs) * windowMs;
  const resetTime = windowStart + windowMs;
  const key = `rate_limit:${clientId}:${windowStart}`;

  // INCR ist atomar pro Key.
  const count = await redis.incr(key);
  if (count === 1) {
    await redis.expire(key, Math.ceil(windowMs / 1000));
  }

  return {
    allowed: count <= maxRequests,
    remaining: Math.max(0, maxRequests - count),
    reset: resetTime,
    limit: maxRequests,
  };
}

export async function checkRateLimit(
  req: VercelRequest,
  config: RateLimitConfig = {},
): Promise<RateLimitResult> {
  const { maxRequests, windowMs } = resolveRateLimitConfig(config);
  const clientId = getClientId(req);

  try {
    return await checkRateLimitRedis(clientId, maxRequests, windowMs);
  } catch (error) {
    console.error("[RateLimit] Redis check failed, fallback to in-memory", error);
    return checkRateLimitInMemory(clientId, maxRequests, windowMs);
  }
}

export function applyRateLimitHeaders(
  res: VercelResponse,
  result: RateLimitResult,
): void {
  res.setHeader("X-RateLimit-Limit", result.limit.toString());
  res.setHeader("X-RateLimit-Remaining", result.remaining.toString());
  res.setHeader("X-RateLimit-Reset", result.reset.toString());
}

export async function rateLimitMiddleware(
  req: VercelRequest,
  res: VercelResponse,
  config?: RateLimitConfig,
): Promise<boolean> {
  const result = await checkRateLimit(req, config);
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

setInterval(
  () => {
    const now = Date.now();
    for (const [key, record] of inMemoryRateLimitStore.entries()) {
      if (now >= record.resetTime) {
        inMemoryRateLimitStore.delete(key);
      }
    }
  },
  5 * 60 * 1000,
);