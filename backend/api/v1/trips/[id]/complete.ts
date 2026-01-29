import type { VercelRequest, VercelResponse } from '@vercel/node';
import { getSupabaseClient, getUserIdFromToken } from '../../../../lib/supabase.js';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
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
    // Prüfen ob Trip dem User gehört
    const { data: trip, error: tripError } = await client
      .from('trips')
      .select('id, user_id, is_completed')
      .eq('id', tripId)
      .eq('user_id', userId)
      .single();

    if (tripError || !trip) {
      return res.status(404).json({ error: 'Trip not found', code: 'NOT_FOUND' });
    }

    if (trip.is_completed) {
      return res.status(400).json({ error: 'Trip already completed', code: 'ALREADY_COMPLETED' });
    }

    // complete_trip Funktion aufrufen (serverseitige XP-Berechnung)
    const { data, error } = await client
      .rpc('complete_trip', { p_trip_id: tripId });

    if (error) throw error;

    return res.json({
      success: true,
      xpEarned: data[0]?.xp_earned ?? 0,
      newTotalXp: data[0]?.new_total_xp ?? 0,
      newLevel: data[0]?.new_level ?? 1,
      levelUp: data[0]?.level_up ?? false,
    });
  } catch (error) {
    console.error('[Complete Trip Error]', error);
    return res.status(500).json({ error: 'Internal server error', code: 'INTERNAL_ERROR' });
  }
}
