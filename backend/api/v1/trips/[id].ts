import type { VercelRequest, VercelResponse } from '@vercel/node';
import { getSupabaseClient, getUserIdFromToken } from '../../../lib/supabase.js';

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

  const tripId = req.query.id as string;
  if (!tripId) {
    return res.status(400).json({ error: 'Trip ID required', code: 'MISSING_ID' });
  }

  try {
    switch (req.method) {
      case 'GET': {
        const { data, error } = await client
          .from('trips')
          .select('*, trip_stops(*)')
          .eq('id', tripId)
          .eq('user_id', userId)
          .single();

        if (error) {
          if (error.code === 'PGRST116') {
            return res.status(404).json({ error: 'Trip not found', code: 'NOT_FOUND' });
          }
          throw error;
        }

        return res.json({ trip: data });
      }

      case 'PATCH': {
        const updates: Record<string, unknown> = {};
        const { name, isFavorite, isCompleted } = req.body;

        if (name !== undefined) updates.name = name;
        if (isFavorite !== undefined) updates.is_favorite = isFavorite;
        if (isCompleted !== undefined) {
          updates.is_completed = isCompleted;
          if (isCompleted) updates.completed_at = new Date().toISOString();
        }

        const { data, error } = await client
          .from('trips')
          .update(updates)
          .eq('id', tripId)
          .eq('user_id', userId)
          .select()
          .single();

        if (error) throw error;
        return res.json({ trip: data });
      }

      case 'DELETE': {
        const { error } = await client
          .from('trips')
          .delete()
          .eq('id', tripId)
          .eq('user_id', userId);

        if (error) throw error;
        return res.status(204).end();
      }

      default:
        return res.status(405).json({ error: 'Method not allowed' });
    }
  } catch (error) {
    console.error('[Trip API Error]', error);
    return res.status(500).json({ error: 'Internal server error', code: 'INTERNAL_ERROR' });
  }
}
