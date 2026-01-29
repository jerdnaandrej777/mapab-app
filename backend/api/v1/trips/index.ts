import type { VercelRequest, VercelResponse } from '@vercel/node';
import { getSupabaseClient, getUserIdFromToken } from '../../../lib/supabase.js';
import { z } from 'zod';

// Validation Schema
const CreateTripSchema = z.object({
  name: z.string().min(1).max(200),
  startLat: z.number(),
  startLng: z.number(),
  startAddress: z.string().optional(),
  endLat: z.number(),
  endLng: z.number(),
  endAddress: z.string().optional(),
  distanceKm: z.number().optional(),
  durationMinutes: z.number().int().optional(),
  routeGeometry: z.string().optional(),
  isFavorite: z.boolean().optional(),
  stops: z.array(z.object({
    poiId: z.string(),
    name: z.string(),
    latitude: z.number(),
    longitude: z.number(),
    categoryId: z.string().optional(),
  })).optional(),
});

export default async function handler(req: VercelRequest, res: VercelResponse) {
  // CORS
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  // Auth prüfen
  const userId = await getUserIdFromToken(req.headers.authorization);
  if (!userId) {
    return res.status(401).json({ error: 'Unauthorized', code: 'UNAUTHORIZED' });
  }

  const client = getSupabaseClient(req.headers.authorization);
  if (!client) {
    return res.status(500).json({ error: 'Database not configured', code: 'DB_ERROR' });
  }

  try {
    switch (req.method) {
      case 'GET': {
        // Liste aller Trips
        const { data, error } = await client
          .from('trips')
          .select('*, trip_stops(*)')
          .eq('user_id', userId)
          .order('created_at', { ascending: false });

        if (error) throw error;
        return res.json({ trips: data });
      }

      case 'POST': {
        // Neuen Trip erstellen
        const parseResult = CreateTripSchema.safeParse(req.body);
        if (!parseResult.success) {
          return res.status(400).json({
            error: 'Invalid request',
            code: 'VALIDATION_ERROR',
            details: parseResult.error.errors,
          });
        }

        const tripData = parseResult.data;

        // Trip einfügen
        const { data: trip, error: tripError } = await client
          .from('trips')
          .insert({
            user_id: userId,
            name: tripData.name,
            start_lat: tripData.startLat,
            start_lng: tripData.startLng,
            start_address: tripData.startAddress,
            end_lat: tripData.endLat,
            end_lng: tripData.endLng,
            end_address: tripData.endAddress,
            distance_km: tripData.distanceKm,
            duration_minutes: tripData.durationMinutes,
            route_geometry: tripData.routeGeometry,
            is_favorite: tripData.isFavorite ?? false,
          })
          .select()
          .single();

        if (tripError) throw tripError;

        // Stops einfügen (falls vorhanden)
        if (tripData.stops && tripData.stops.length > 0) {
          const stopsData = tripData.stops.map((stop, index) => ({
            trip_id: trip.id,
            poi_id: stop.poiId,
            name: stop.name,
            latitude: stop.latitude,
            longitude: stop.longitude,
            category_id: stop.categoryId,
            stop_order: index,
          }));

          const { error: stopsError } = await client
            .from('trip_stops')
            .insert(stopsData);

          if (stopsError) {
            console.error('Stops insert error:', stopsError);
          }
        }

        return res.status(201).json({ trip });
      }

      default:
        return res.status(405).json({ error: 'Method not allowed' });
    }
  } catch (error) {
    console.error('[Trips API Error]', error);
    return res.status(500).json({ error: 'Internal server error', code: 'INTERNAL_ERROR' });
  }
}
