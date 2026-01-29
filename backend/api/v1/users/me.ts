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

  try {
    switch (req.method) {
      case 'GET': {
        const { data, error } = await client
          .from('users')
          .select('*')
          .eq('id', userId)
          .single();

        if (error) {
          if (error.code === 'PGRST116') {
            return res.status(404).json({ error: 'User not found', code: 'NOT_FOUND' });
          }
          throw error;
        }

        return res.json({
          user: {
            id: data.id,
            username: data.username,
            displayName: data.display_name,
            avatarUrl: data.avatar_url,
            totalXp: data.total_xp,
            level: data.level,
            totalTrips: data.total_trips,
            totalDistanceKm: data.total_distance_km,
            totalPoisVisited: data.total_pois_visited,
            createdAt: data.created_at,
          },
        });
      }

      case 'PATCH': {
        const updates: Record<string, unknown> = {};
        const { username, displayName, avatarUrl } = req.body;

        if (username !== undefined) updates.username = username;
        if (displayName !== undefined) updates.display_name = displayName;
        if (avatarUrl !== undefined) updates.avatar_url = avatarUrl;

        if (Object.keys(updates).length === 0) {
          return res.status(400).json({ error: 'No updates provided', code: 'NO_UPDATES' });
        }

        const { data, error } = await client
          .from('users')
          .update(updates)
          .eq('id', userId)
          .select()
          .single();

        if (error) throw error;

        return res.json({
          user: {
            id: data.id,
            username: data.username,
            displayName: data.display_name,
            avatarUrl: data.avatar_url,
            totalXp: data.total_xp,
            level: data.level,
          },
        });
      }

      default:
        return res.status(405).json({ error: 'Method not allowed' });
    }
  } catch (error) {
    console.error('[User API Error]', error);
    return res.status(500).json({ error: 'Internal server error', code: 'INTERNAL_ERROR' });
  }
}
