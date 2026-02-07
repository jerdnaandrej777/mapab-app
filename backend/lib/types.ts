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
// Hotel Search Request/Response Types
// ============================================

export const HotelSearchRequestSchema = z.object({
  lat: z.number().gte(-90).lte(90),
  lng: z.number().gte(-180).lte(180),
  radiusKm: z.number().gt(0).lte(20).default(20),
  limit: z.number().int().min(1).max(20).default(8).optional(),
  checkInDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional(),
  checkOutDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional(),
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
  source: 'google_places';
  dataQuality: 'verified' | 'few_or_no_reviews' | 'limited';
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
