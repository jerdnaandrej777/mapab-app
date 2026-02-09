import type { VercelRequest, VercelResponse } from '@vercel/node';

import {
  HotelSearchRequestSchema,
  type HotelSearchRequest,
  type HotelSearchResponseAmenities,
  type HotelSearchResponseItem,
} from '../../lib/types';
import { rateLimitMiddleware } from '../../lib/middleware/rateLimit';

type GoogleNearbyResult = {
  place_id: string;
  name?: string;
  rating?: number;
  user_ratings_total?: number;
  vicinity?: string;
  geometry?: {
    location?: { lat: number; lng: number };
  };
  types?: string[];
};

type GoogleDetailsResult = {
  place_id?: string;
  name?: string;
  rating?: number;
  user_ratings_total?: number;
  formatted_address?: string;
  formatted_phone_number?: string;
  website?: string;
  editorial_summary?: { overview?: string };
  reviews?: Array<{ text?: string }>;
  types?: string[];
};

const KM_TO_METER = 1000;
const EARTH_RADIUS_KM = 6371;

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

  if (!(await rateLimitMiddleware(req, res, { maxRequests: 300 }))) {
    return;
  }

  const apiKey = process.env.GOOGLE_PLACES_API_KEY;
  if (!apiKey) {
    return res.status(503).json({
      error: 'Google Places API key missing',
      code: 'GOOGLE_PLACES_NOT_CONFIGURED',
    });
  }

  const parsed = HotelSearchRequestSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({
      error: 'Invalid request body',
      code: 'VALIDATION_ERROR',
      details: parsed.error.errors.map((e) => `${e.path.join('.')}: ${e.message}`).join(', '),
    });
  }

  try {
    const request = normalizeRequest(parsed.data);

    const nearby = await fetchNearbyHotels(request, apiKey);
    if (nearby.length === 0) {
      return res.status(200).json({ hotels: [] });
    }

    const detailTargets = nearby.slice(0, request.limit);
    const details = await Promise.all(
      detailTargets.map((item) => fetchPlaceDetails(item.place_id, request.language, apiKey)),
    );
    const detailsByPlaceId = new Map<string, GoogleDetailsResult>();
    for (const detail of details) {
      if (detail?.place_id) {
        detailsByPlaceId.set(detail.place_id, detail);
      }
    }

    const hotels = buildHotelResponse(detailTargets, detailsByPlaceId, request);
    const withReviewThreshold = applyReviewThreshold(hotels);

    return res.status(200).json({
      hotels: withReviewThreshold,
    });
  } catch (error) {
    console.error('[Hotel Search Error]', error);
    return res.status(500).json({
      error: 'Hotel search failed',
      code: 'HOTEL_SEARCH_FAILED',
    });
  }
}

function normalizeRequest(input: HotelSearchRequest): HotelSearchRequest & { limit: number } {
  const radiusKm = Math.min(20, Math.max(1, input.radiusKm ?? 20));
  const limit = Math.min(20, Math.max(1, input.limit ?? 8));
  const language = input.language && input.language.trim().length >= 2
    ? input.language.trim()
    : 'de';
  return {
    ...input,
    radiusKm,
    limit,
    language,
  };
}

async function fetchNearbyHotels(
  request: HotelSearchRequest & { limit: number },
  apiKey: string,
): Promise<GoogleNearbyResult[]> {
  const radiusMeters = Math.round(request.radiusKm * KM_TO_METER);
  const params = new URLSearchParams({
    key: apiKey,
    location: `${request.lat},${request.lng}`,
    radius: radiusMeters.toString(),
    type: 'lodging',
    language: request.language ?? 'de',
  });

  const response = await fetch(
    `https://maps.googleapis.com/maps/api/place/nearbysearch/json?${params.toString()}`,
  );
  const payload = await response.json() as {
    status?: string;
    error_message?: string;
    results?: GoogleNearbyResult[];
  };

  if (!response.ok || (payload.status && payload.status !== 'OK' && payload.status !== 'ZERO_RESULTS')) {
    throw new Error(`Nearby search failed: ${payload.status ?? response.statusText} ${payload.error_message ?? ''}`);
  }

  return (payload.results ?? []).slice(0, Math.max(request.limit * 2, 12));
}

async function fetchPlaceDetails(
  placeId: string,
  language: string | undefined,
  apiKey: string,
): Promise<GoogleDetailsResult | null> {
  const fields = [
    'place_id',
    'name',
    'rating',
    'user_ratings_total',
    'formatted_address',
    'formatted_phone_number',
    'website',
    'editorial_summary',
    'reviews',
    'types',
  ];

  const params = new URLSearchParams({
    key: apiKey,
    place_id: placeId,
    fields: fields.join(','),
    language: language ?? 'de',
    reviews_no_translations: 'true',
  });

  const response = await fetch(
    `https://maps.googleapis.com/maps/api/place/details/json?${params.toString()}`,
  );
  const payload = await response.json() as {
    status?: string;
    error_message?: string;
    result?: GoogleDetailsResult;
  };

  if (!response.ok || (payload.status && payload.status !== 'OK' && payload.status !== 'ZERO_RESULTS')) {
    return null;
  }

  return payload.result ?? null;
}

function buildHotelResponse(
  nearby: GoogleNearbyResult[],
  detailsByPlaceId: Map<string, GoogleDetailsResult>,
  request: HotelSearchRequest & { limit: number },
): HotelSearchResponseItem[] {
  const items: HotelSearchResponseItem[] = [];

  for (const place of nearby) {
    const lat = place.geometry?.location?.lat;
    const lng = place.geometry?.location?.lng;
    if (lat == null || lng == null) continue;

    const detail = detailsByPlaceId.get(place.place_id);
    const rating = detail?.rating ?? place.rating;
    const reviewCount = detail?.user_ratings_total ?? place.user_ratings_total;

    const distanceKm = haversineKm(request.lat, request.lng, lat, lng);
    if (distanceKm > request.radiusKm + 0.3) {
      continue;
    }

    const highlights = extractHighlights(detail);
    const amenities = inferAmenities(detail);
    const checkInDate = request.checkInDate ?? isoDate(new Date());
    const checkOutDate = request.checkOutDate ?? isoDate(addDays(new Date(checkInDate), 1));

    items.push({
      id: place.place_id,
      placeId: place.place_id,
      name: detail?.name ?? place.name ?? 'Hotel',
      type: mapType(place.types ?? detail?.types ?? []),
      lat,
      lng,
      distanceKm: round(distanceKm, 2),
      rating: rating ?? undefined,
      reviewCount: reviewCount ?? undefined,
      highlights,
      amenities,
      address: detail?.formatted_address ?? place.vicinity,
      phone: detail?.formatted_phone_number,
      website: detail?.website,
      bookingUrl: buildBookingUrl(
        detail?.name ?? place.name ?? 'Hotel',
        lat,
        lng,
        checkInDate,
        checkOutDate,
      ),
      source: 'google_places',
      dataQuality: reviewCount != null && reviewCount >= 10 ? 'verified' : 'limited',
    });
  }

  items.sort((a, b) => a.distanceKm - b.distanceKm);
  return items.slice(0, request.limit);
}

function applyReviewThreshold(items: HotelSearchResponseItem[]): HotelSearchResponseItem[] {
  if (items.length === 0) return items;

  const strict = items.filter((item) => {
    if (item.reviewCount == null || item.reviewCount <= 0) return true;
    return item.reviewCount >= 10;
  });

  if (strict.length > 0) {
    return strict.map((item) => ({
      ...item,
      dataQuality: item.reviewCount != null && item.reviewCount >= 10
        ? 'verified'
        : item.dataQuality,
    }));
  }

  return items.map((item) => ({
    ...item,
    dataQuality: 'few_or_no_reviews',
  }));
}

function mapType(types: string[]): string {
  const normalized = types.map((t) => t.toLowerCase());
  if (normalized.includes('hostel')) return 'hostel';
  if (normalized.includes('guest_house')) return 'guest_house';
  if (normalized.includes('motel')) return 'motel';
  return 'hotel';
}

function extractHighlights(detail?: GoogleDetailsResult): string[] {
  const highlights: string[] = [];
  if (detail?.editorial_summary?.overview) {
    highlights.push(detail.editorial_summary.overview);
  }

  const reviewSnippets = (detail?.reviews ?? [])
    .map((review) => review.text?.trim())
    .filter((text): text is string => Boolean(text))
    .slice(0, 2);

  highlights.push(...reviewSnippets);

  // Deduplicate and trim long snippets.
  const seen = new Set<string>();
  return highlights
    .map((text) => text.length > 160 ? `${text.slice(0, 157)}...` : text)
    .filter((text) => {
      if (seen.has(text)) return false;
      seen.add(text);
      return true;
    });
}

function inferAmenities(detail?: GoogleDetailsResult): HotelSearchResponseAmenities {
  const textParts: string[] = [];
  if (detail?.editorial_summary?.overview) textParts.push(detail.editorial_summary.overview);
  for (const review of detail?.reviews ?? []) {
    if (review.text) textParts.push(review.text);
  }
  const blob = textParts.join(' ').toLowerCase();

  const containsAny = (needles: string[]) => needles.some((needle) => blob.includes(needle));

  return {
    wifi: containsAny(['wifi', 'wlan', 'internet']),
    parking: containsAny(['parking', 'parkplatz', 'garage']),
    breakfast: containsAny(['breakfast', 'fruehstueck', 'fruhstuck', 'frühstück']),
    restaurant: containsAny(['restaurant', 'dinner', 'essen']),
    pool: containsAny(['pool']),
    spa: containsAny(['spa', 'wellness']),
    airConditioning: containsAny(['air conditioning', 'klimaanlage']),
    petsAllowed: containsAny(['pet', 'haustier', 'dog-friendly']),
    wheelchairAccessible: containsAny(['wheelchair', 'barrierefrei']),
  };
}

function buildBookingUrl(
  name: string,
  lat: number,
  lng: number,
  checkInDate: string,
  checkOutDate: string,
): string {
  const params = new URLSearchParams({
    ss: name,
    checkin: checkInDate,
    checkout: checkOutDate,
    latitude: `${lat}`,
    longitude: `${lng}`,
    radius: '1',
  });
  const affiliateId = process.env.BOOKING_AFFILIATE_ID;
  if (affiliateId && affiliateId.trim().length > 0) {
    params.set('aid', affiliateId.trim());
  }
  return `https://www.booking.com/searchresults.html?${params.toString()}`;
}

function haversineKm(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const toRad = (value: number) => (value * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) *
      Math.cos(toRad(lat2)) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return EARTH_RADIUS_KM * c;
}

function round(value: number, digits: number): number {
  const factor = 10 ** digits;
  return Math.round(value * factor) / factor;
}

function addDays(date: Date, days: number): Date {
  const copy = new Date(date);
  copy.setUTCDate(copy.getUTCDate() + days);
  return copy;
}

function isoDate(date: Date): string {
  return date.toISOString().slice(0, 10);
}
