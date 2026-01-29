import { z } from 'zod';

// ============================================
// Chat Request/Response Types
// ============================================

export const ChatMessageSchema = z.object({
  role: z.enum(['user', 'assistant', 'system']),
  content: z.string(),
});

export const TripContextSchema = z.object({
  routeStart: z.string().optional(),
  routeEnd: z.string().optional(),
  distanceKm: z.number().optional(),
  durationMinutes: z.number().optional(),
  stops: z.array(z.object({
    name: z.string(),
    category: z.string().optional(),
  })).optional(),
}).optional();

export const ChatRequestSchema = z.object({
  message: z.string().min(1).max(4000),
  context: TripContextSchema,
  history: z.array(ChatMessageSchema).max(20).optional(),
});

export type ChatRequest = z.infer<typeof ChatRequestSchema>;

export interface ChatResponse {
  message: string;
  tokensUsed?: number;
}

// ============================================
// Trip Plan Request/Response Types
// ============================================

export const TripPlanRequestSchema = z.object({
  destination: z.string().min(1).max(200).optional(),
  startLocation: z.string().min(1).max(200).optional(),
  days: z.number().int().min(1).max(7),
  interests: z.array(z.string()).min(1).max(10),
  startLat: z.number().optional(),
  startLng: z.number().optional(),
});

export type TripPlanRequest = z.infer<typeof TripPlanRequestSchema>;

export interface TripPlanResponse {
  plan: string;
  tokensUsed?: number;
}

// ============================================
// Error Types
// ============================================

export interface APIError {
  error: string;
  code: string;
  details?: string;
}

// ============================================
// Rate Limit Types
// ============================================

export interface RateLimitInfo {
  remaining: number;
  reset: number;
  limit: number;
}
