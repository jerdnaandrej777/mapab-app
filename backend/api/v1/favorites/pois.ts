import type { VercelRequest, VercelResponse } from '@vercel/node';
import { getSupabaseClient, getUserIdFromToken } from '../../../lib/supabase.js';
import { z } from 'zod';

const AddFavoriteSchema = z.object({
  poiId: z.string().min(1),
  name: z.string().min(1).max(200),
  latitude: z.number(),
  longitude: z.number(),
  categoryId: z.string().optional(),
  imageUrl: z.string().url().optional(),
  notes: z.string().max(500).optional(),
});

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

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
        const { data, error } = await client
          .from('favorite_pois')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', { ascending: false });

        if (error) throw error;
        return res.json({ favorites: data });
      }

      case 'POST': {
        const parseResult = AddFavoriteSchema.safeParse(req.body);
        if (!parseResult.success) {
          return res.status(400).json({
            error: 'Invalid request',
            code: 'VALIDATION_ERROR',
            details: parseResult.error.errors,
          });
        }

        const favoriteData = parseResult.data;

        const { data, error } = await client
          .from('favorite_pois')
          .upsert({
            user_id: userId,
            poi_id: favoriteData.poiId,
            name: favoriteData.name,
            latitude: favoriteData.latitude,
            longitude: favoriteData.longitude,
            category_id: favoriteData.categoryId,
            image_url: favoriteData.imageUrl,
            notes: favoriteData.notes,
          }, {
            onConflict: 'user_id,poi_id',
          })
          .select()
          .single();

        if (error) throw error;
        return res.status(201).json({ favorite: data });
      }

      case 'DELETE': {
        const poiId = req.query.poiId as string;
        if (!poiId) {
          return res.status(400).json({ error: 'POI ID required', code: 'MISSING_ID' });
        }

        const { error } = await client
          .from('favorite_pois')
          .delete()
          .eq('user_id', userId)
          .eq('poi_id', poiId);

        if (error) throw error;
        return res.status(204).end();
      }

      default:
        return res.status(405).json({ error: 'Method not allowed' });
    }
  } catch (error) {
    console.error('[Favorites API Error]', error);
    return res.status(500).json({ error: 'Internal server error', code: 'INTERNAL_ERROR' });
  }
}
