-- MapAB Supabase Schema
-- Migration 009: Leaderboard System
-- Erweitert user_profiles um XP/Level und erstellt Leaderboard RPC

-- ============================================
-- SCHRITT 1: XP & LEVEL FELDER HINZUFUEGEN
-- ============================================

ALTER TABLE public.user_profiles
ADD COLUMN IF NOT EXISTS total_xp INTEGER NOT NULL DEFAULT 0;

ALTER TABLE public.user_profiles
ADD COLUMN IF NOT EXISTS level INTEGER NOT NULL DEFAULT 1;

ALTER TABLE public.user_profiles
ADD COLUMN IF NOT EXISTS current_streak INTEGER NOT NULL DEFAULT 0;

ALTER TABLE public.user_profiles
ADD COLUMN IF NOT EXISTS longest_streak INTEGER NOT NULL DEFAULT 0;

ALTER TABLE public.user_profiles
ADD COLUMN IF NOT EXISTS last_activity_date DATE;

-- ============================================
-- SCHRITT 2: INDEX FUER LEADERBOARD
-- ============================================

CREATE INDEX IF NOT EXISTS idx_user_profiles_xp
ON public.user_profiles (total_xp DESC);

CREATE INDEX IF NOT EXISTS idx_user_profiles_km
ON public.user_profiles (total_km DESC);

CREATE INDEX IF NOT EXISTS idx_user_profiles_trips
ON public.user_profiles (total_trips DESC);

-- ============================================
-- SCHRITT 3: LEADERBOARD RPC FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION get_leaderboard(
    p_sort_by VARCHAR(20) DEFAULT 'xp',
    p_limit INTEGER DEFAULT 100,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    rank BIGINT,
    user_id UUID,
    display_name VARCHAR(100),
    avatar_url TEXT,
    total_xp INTEGER,
    level INTEGER,
    total_km DECIMAL(10,2),
    total_trips INTEGER,
    total_pois INTEGER,
    total_likes_received INTEGER,
    current_streak INTEGER,
    is_current_user BOOLEAN
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
    WITH ranked_users AS (
        SELECT
            up.id AS user_id,
            up.display_name,
            up.avatar_url,
            up.total_xp,
            up.level,
            up.total_km,
            up.total_trips,
            up.total_pois,
            up.total_likes_received,
            up.current_streak,
            ROW_NUMBER() OVER (
                ORDER BY
                    CASE WHEN p_sort_by = 'xp' THEN up.total_xp END DESC NULLS LAST,
                    CASE WHEN p_sort_by = 'km' THEN up.total_km END DESC NULLS LAST,
                    CASE WHEN p_sort_by = 'trips' THEN up.total_trips END DESC NULLS LAST,
                    CASE WHEN p_sort_by = 'likes' THEN up.total_likes_received END DESC NULLS LAST,
                    up.total_xp DESC NULLS LAST
            ) AS rank
        FROM public.user_profiles up
        WHERE up.display_name IS NOT NULL
    )
    SELECT
        ru.rank,
        ru.user_id,
        ru.display_name,
        ru.avatar_url,
        ru.total_xp,
        ru.level,
        ru.total_km,
        ru.total_trips,
        ru.total_pois,
        ru.total_likes_received,
        ru.current_streak,
        ru.user_id = auth.uid() AS is_current_user
    FROM ranked_users ru
    ORDER BY ru.rank
    LIMIT p_limit
    OFFSET p_offset;
$$;

-- ============================================
-- SCHRITT 4: EIGENE POSITION IM LEADERBOARD
-- ============================================

CREATE OR REPLACE FUNCTION get_my_leaderboard_position(
    p_sort_by VARCHAR(20) DEFAULT 'xp'
)
RETURNS TABLE (
    rank BIGINT,
    user_id UUID,
    display_name VARCHAR(100),
    avatar_url TEXT,
    total_xp INTEGER,
    level INTEGER,
    total_km DECIMAL(10,2),
    total_trips INTEGER,
    total_pois INTEGER,
    total_likes_received INTEGER,
    current_streak INTEGER
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
    WITH ranked_users AS (
        SELECT
            up.id AS user_id,
            up.display_name,
            up.avatar_url,
            up.total_xp,
            up.level,
            up.total_km,
            up.total_trips,
            up.total_pois,
            up.total_likes_received,
            up.current_streak,
            ROW_NUMBER() OVER (
                ORDER BY
                    CASE WHEN p_sort_by = 'xp' THEN up.total_xp END DESC NULLS LAST,
                    CASE WHEN p_sort_by = 'km' THEN up.total_km END DESC NULLS LAST,
                    CASE WHEN p_sort_by = 'trips' THEN up.total_trips END DESC NULLS LAST,
                    CASE WHEN p_sort_by = 'likes' THEN up.total_likes_received END DESC NULLS LAST,
                    up.total_xp DESC NULLS LAST
            ) AS rank
        FROM public.user_profiles up
        WHERE up.display_name IS NOT NULL
    )
    SELECT
        ru.rank,
        ru.user_id,
        ru.display_name,
        ru.avatar_url,
        ru.total_xp,
        ru.level,
        ru.total_km,
        ru.total_trips,
        ru.total_pois,
        ru.total_likes_received,
        ru.current_streak
    FROM ranked_users ru
    WHERE ru.user_id = auth.uid();
$$;

-- ============================================
-- SCHRITT 5: XP & LEVEL UPDATE FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION update_user_xp(
    p_xp_amount INTEGER
)
RETURNS public.user_profiles
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_result public.user_profiles;
    v_new_xp INTEGER;
    v_new_level INTEGER;
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Berechne neues XP und Level
    SELECT total_xp + p_xp_amount INTO v_new_xp
    FROM public.user_profiles
    WHERE id = v_user_id;

    -- Level = sqrt(xp / 100), mindestens 1
    v_new_level := GREATEST(1, FLOOR(SQRT(v_new_xp / 100.0))::INTEGER);

    -- Update Profil
    UPDATE public.user_profiles
    SET
        total_xp = v_new_xp,
        level = v_new_level,
        last_activity_date = CURRENT_DATE
    WHERE id = v_user_id
    RETURNING * INTO v_result;

    RETURN v_result;
END;
$$;

-- ============================================
-- SCHRITT 6: STREAK UPDATE FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION update_user_streak()
RETURNS public.user_profiles
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_result public.user_profiles;
    v_last_activity DATE;
    v_new_streak INTEGER;
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Hole letzte Aktivitaet
    SELECT last_activity_date, current_streak INTO v_last_activity, v_new_streak
    FROM public.user_profiles
    WHERE id = v_user_id;

    -- Streak-Logik
    IF v_last_activity IS NULL THEN
        -- Erster Tag
        v_new_streak := 1;
    ELSIF v_last_activity = CURRENT_DATE THEN
        -- Bereits heute aktiv, keine Aenderung
        NULL;
    ELSIF v_last_activity = CURRENT_DATE - 1 THEN
        -- Gestern aktiv, Streak erhoehen
        v_new_streak := v_new_streak + 1;
    ELSE
        -- Mehr als 1 Tag Pause, Streak zuruecksetzen
        v_new_streak := 1;
    END IF;

    -- Update Profil
    UPDATE public.user_profiles
    SET
        current_streak = v_new_streak,
        longest_streak = GREATEST(longest_streak, v_new_streak),
        last_activity_date = CURRENT_DATE
    WHERE id = v_user_id
    RETURNING * INTO v_result;

    RETURN v_result;
END;
$$;

-- ============================================
-- FERTIG!
-- ============================================
