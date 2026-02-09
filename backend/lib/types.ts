import { z } from "zod";

// ============================================
// Chat Request/Response Types
// ============================================

export const ChatMessageSchema = z.object({
  role: z.enum(["user", "assistant", "system"]),
  content: z.string(),
});

export const ClientMetaSchema = z
  .object({
    build: z.string().min(1).max(64).optional(),
    platform: z.string().min(1).max(32).optional(),
    sessionId: z.string().min(1).max(128).optional(),
  })
  .optional();

export const TripContextSchema = z
  .object({
    userLocation: z
      .object({
        lat: z.number(),
        lng: z.number(),
        name: z.string().optional(),
      })
      .optional(),
    routeStart: z.string().optional(),
    routeEnd: z.string().optional(),
    distanceKm: z.number().optional(),
    durationMinutes: z.number().optional(),
    stops: z
      .array(
        z.object({
          id: z.string().optional(),
          name: z.string(),
          category: z.string().optional(),
          day: z.number().int().optional(),
        }),
      )
      .optional(),
    responseLanguage: z.string().min(2).max(10).optional(),
    overallWeather: z.string().optional(),
    dayWeather: z.record(z.string(), z.string()).optional(),
    selectedDay: z.number().int().optional(),
    totalDays: z.number().int().optional(),
    preferredCategories: z.array(z.string()).optional(),
  })
  .optional();

export const ChatRequestSchema = z.object({
  message: z.string().min(1).max(4000),
  context: TripContextSchema,
  history: z.array(ChatMessageSchema).max(20).optional(),
  clientMeta: ClientMetaSchema,
});

export type ChatRequest = z.infer<typeof ChatRequestSchema>;

export interface ChatResponse {
  message: string;
  tokensUsed?: number;
  traceId?: string;
  source?: "ai" | "fallback";
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
  clientMeta: ClientMetaSchema,
});

export type TripPlanRequest = z.infer<typeof TripPlanRequestSchema>;

export interface TripPlanResponse {
  plan: string;
  tokensUsed?: number;
  traceId?: string;
  source?: "ai" | "fallback";
}

// ============================================
// Structured POI Suggestions
// ============================================

export const PoiSuggestionModeSchema = z.enum(["day_editor", "chat_nearby"]);

export const PoiSuggestionUserContextSchema = z
  .object({
    lat: z.number().optional(),
    lng: z.number().optional(),
    locationName: z.string().optional(),
    weatherCondition: z
      .enum(["good", "mixed", "bad", "danger", "unknown"])
      .optional(),
    selectedDay: z.number().int().optional(),
    totalDays: z.number().int().optional(),
  })
  .optional();

export const PoiSuggestionTripContextSchema = z
  .object({
    routeStart: z.string().optional(),
    routeEnd: z.string().optional(),
    stops: z
      .array(
        z.object({
          id: z.string(),
          name: z.string(),
          categoryId: z.string().optional(),
          day: z.number().int().optional(),
        }),
      )
      .optional(),
  })
  .optional();

export const PoiSuggestionConstraintsSchema = z
  .object({
    maxSuggestions: z.number().int().min(1).max(12).optional(),
    allowSwap: z.boolean().optional(),
  })
  .optional();

export const PoiSuggestionCandidateSchema = z.object({
  id: z.string().min(1),
  name: z.string().min(1),
  categoryId: z.string().min(1),
  lat: z.number(),
  lng: z.number(),
  score: z.number(),
  isMustSee: z.boolean(),
  isCurated: z.boolean(),
  isUnesco: z.boolean(),
  isIndoor: z.boolean(),
  detourKm: z.number().optional(),
  routePosition: z.number().optional(),
  imageUrl: z.string().url().optional(),
  shortDescription: z.string().optional(),
  tags: z.array(z.string()).optional(),
});

export const PoiSuggestionsRequestSchema = z.object({
  mode: PoiSuggestionModeSchema,
  language: z.string().min(2).max(10).optional(),
  userContext: PoiSuggestionUserContextSchema,
  tripContext: PoiSuggestionTripContextSchema,
  constraints: PoiSuggestionConstraintsSchema,
  candidates: z.array(PoiSuggestionCandidateSchema).min(1).max(60),
  clientMeta: ClientMetaSchema,
});

export const PoiSuggestionActionSchema = z.enum(["add", "swap"]);

export const PoiSuggestionSchema = z
  .object({
    poiId: z.string().min(1),
    action: PoiSuggestionActionSchema,
    targetPoiId: z.string().optional(),
    reason: z.string().min(1),
    relevance: z.number().min(0).max(1),
    highlights: z.array(z.string()).default([]),
    longDescription: z.string().min(1),
  })
  .superRefine((value, ctx) => {
    if (value.action === "swap" && !value.targetPoiId) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: "targetPoiId is required when action is swap",
        path: ["targetPoiId"],
      });
    }
  });

export const PoiSuggestionsResponseSchema = z.object({
  summary: z.string().default(""),
  suggestions: z.array(PoiSuggestionSchema).default([]),
});

export type PoiSuggestionsRequest = z.infer<typeof PoiSuggestionsRequestSchema>;
export type PoiSuggestionsResponse = z.infer<
  typeof PoiSuggestionsResponseSchema
>;

// ============================================
// Hotel Search Request/Response Types
// ============================================

export const HotelSearchRequestSchema = z.object({
  lat: z.number().gte(-90).lte(90),
  lng: z.number().gte(-180).lte(180),
  radiusKm: z.number().gt(0).lte(20).default(20),
  limit: z.number().int().min(1).max(20).default(8).optional(),
  checkInDate: z
    .string()
    .regex(/^\d{4}-\d{2}-\d{2}$/)
    .optional(),
  checkOutDate: z
    .string()
    .regex(/^\d{4}-\d{2}-\d{2}$/)
    .optional(),
  language: z.string().min(2).max(5).optional(),
  dayIndex: z.number().int().min(1).max(30).optional(),
});

export type HotelSearchRequest = z.infer<typeof HotelSearchRequestSchema>;

export interface HotelSearchResponseAmenities {
  wifi?: boolean;
  parking?: boolean;
  breakfast?: boolean;
  restaurant?: boolean;
  pool?: boolean;
  spa?: boolean;
  airConditioning?: boolean;
  petsAllowed?: boolean;
  wheelchairAccessible?: boolean;
}

export interface HotelSearchResponseItem {
  id: string;
  placeId: string;
  name: string;
  type: string;
  lat: number;
  lng: number;
  distanceKm: number;
  rating?: number;
  reviewCount?: number;
  highlights: string[];
  amenities: HotelSearchResponseAmenities;
  address?: string;
  phone?: string;
  website?: string;
  bookingUrl?: string;
  source: "google_places";
  dataQuality: "verified" | "few_or_no_reviews" | "limited";
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
