-- MapAB Supabase Schema
-- Migration 006: Social Features RESET
-- Loescht alle vorhandenen Social-Tabellen und erstellt sie neu
-- WICHTIG: Fuehre dieses Script im Supabase SQL Editor aus!

-- ============================================
-- SCHRITT 1: ALLE RPC FUNCTIONS LOESCHEN
-- ============================================

DROP FUNCTION IF EXISTS search_public_trips CASCADE;
DROP FUNCTION IF EXISTS like_trip CASCADE;
DROP FUNCTION IF EXISTS unlike_trip CASCADE;
DROP FUNCTION IF EXISTS increment_trip_views CASCADE;
DROP FUNCTION IF EXISTS import_trip CASCADE;
DROP FUNCTION IF EXISTS upsert_user_profile CASCADE;
DROP FUNCTION IF EXISTS publish_trip CASCADE;
DROP FUNCTION IF EXISTS get_public_trip CASCADE;

-- ============================================
-- SCHRITT 2: ALLE TABELLEN LOESCHEN (mit CASCADE)
-- ============================================

DROP TABLE IF EXISTS public.trip_imports CASCADE;
DROP TABLE IF EXISTS public.trip_likes CASCADE;
DROP TABLE IF EXISTS public.trips CASCADE;
DROP TABLE IF EXISTS public.public_trips CASCADE;
DROP TABLE IF EXISTS public.user_profiles CASCADE;

-- ============================================
-- SCHRITT 3: HELPER FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- SCHRITT 4: USER PROFILES TABELLE
-- ============================================

CREATE TABLE public.user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    display_name VARCHAR(100),
    avatar_url TEXT,
    bio VARCHAR(500),
    total_km DECIMAL(10,2) NOT NULL DEFAULT 0,
    total_trips INTEGER NOT NULL DEFAULT 0,
    total_pois INTEGER NOT NULL DEFAULT 0,
    total_likes_received INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON public.user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- SCHRITT 5: TRIPS TABELLE
-- ============================================

CREATE TABLE public.trips (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    trip_name VARCHAR(200) NOT NULL,
    description TEXT,
    trip_type VARCHAR(50) NOT NULL DEFAULT 'daytrip'
        CHECK (trip_type IN ('daytrip', 'eurotrip')),
    trip_data JSONB NOT NULL,
    thumbnail_url TEXT,
    tags TEXT[] DEFAULT '{}',
    region VARCHAR(100),
    country_code VARCHAR(3),
    start_latitude DECIMAL(10,7),
    start_longitude DECIMAL(10,7),
    start_location GEOGRAPHY(POINT, 4326),
    distance_km DECIMAL(10,2),
    duration_hours DECIMAL(5,2),
    stop_count INTEGER NOT NULL DEFAULT 0,
    day_count INTEGER NOT NULL DEFAULT 1,
    likes_count INTEGER NOT NULL DEFAULT 0,
    views_count INTEGER NOT NULL DEFAULT 0,
    imports_count INTEGER NOT NULL DEFAULT 0,
    is_featured BOOLEAN NOT NULL DEFAULT FALSE,
    is_hidden BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TRIGGER update_trips_updated_at
    BEFORE UPDATE ON public.trips
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- SCHRITT 6: TRIP LIKES TABELLE
-- ============================================

CREATE TABLE public.trip_likes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    trip_id UUID NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, trip_id)
);

-- ============================================
-- SCHRITT 7: TRIP IMPORTS TABELLE
-- ============================================

CREATE TABLE public.trip_imports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    trip_id UUID NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, trip_id)
);

-- ============================================
-- SCHRITT 8: INDEXES
-- ============================================

CREATE INDEX idx_trips_popular ON public.trips (likes_count DESC, views_count DESC)
    WHERE is_hidden = FALSE;

CREATE INDEX idx_trips_recent ON public.trips (created_at DESC)
    WHERE is_hidden = FALSE;

CREATE INDEX idx_trips_featured ON public.trips (created_at DESC)
    WHERE is_featured = TRUE AND is_hidden = FALSE;

CREATE INDEX idx_trips_user ON public.trips (user_id, created_at DESC);

CREATE INDEX idx_trips_tags ON public.trips USING GIN (tags);

CREATE INDEX idx_trips_region ON public.trips (country_code, region)
    WHERE is_hidden = FALSE;

CREATE INDEX idx_trip_likes_trip ON public.trip_likes (trip_id);
CREATE INDEX idx_trip_likes_user ON public.trip_likes (user_id);

CREATE INDEX idx_user_profiles_name ON public.user_profiles (display_name);

-- ============================================
-- SCHRITT 9: ROW LEVEL SECURITY
-- ============================================

ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trips ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trip_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trip_imports ENABLE ROW LEVEL SECURITY;

-- User Profiles Policies
CREATE POLICY "Profiles are publicly readable" ON public.user_profiles
    FOR SELECT USING (TRUE);

CREATE POLICY "Users can insert own profile" ON public.user_profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.user_profiles
    FOR UPDATE USING (auth.uid() = id);

-- Trips Policies
CREATE POLICY "Public trips are viewable by everyone" ON public.trips
    FOR SELECT USING (is_hidden = FALSE OR auth.uid() = user_id);

CREATE POLICY "Users can insert own trips" ON public.trips
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own trips" ON public.trips
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own trips" ON public.trips
    FOR DELETE USING (auth.uid() = user_id);

-- Trip Likes Policies
CREATE POLICY "Likes are publicly readable" ON public.trip_likes
    FOR SELECT USING (TRUE);

CREATE POLICY "Users can insert own likes" ON public.trip_likes
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own likes" ON public.trip_likes
    FOR DELETE USING (auth.uid() = user_id);

-- Trip Imports Policies
CREATE POLICY "Imports are readable by owner and trip author" ON public.trip_imports
    FOR SELECT USING (
        auth.uid() = user_id OR
        auth.uid() = (SELECT user_id FROM public.trips WHERE id = trip_id)
    );

CREATE POLICY "Users can insert own imports" ON public.trip_imports
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- ============================================
-- SCHRITT 10: RPC FUNCTIONS
-- ============================================

CREATE OR REPLACE FUNCTION search_public_trips(
    p_query TEXT DEFAULT NULL,
    p_tags TEXT[] DEFAULT NULL,
    p_country_code VARCHAR(3) DEFAULT NULL,
    p_trip_type VARCHAR(50) DEFAULT NULL,
    p_sort_by VARCHAR(20) DEFAULT 'popular',
    p_limit INTEGER DEFAULT 20,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    trip_name VARCHAR(200),
    description TEXT,
    trip_type VARCHAR(50),
    thumbnail_url TEXT,
    tags TEXT[],
    region VARCHAR(100),
    country_code VARCHAR(3),
    distance_km DECIMAL(10,2),
    stop_count INTEGER,
    day_count INTEGER,
    likes_count INTEGER,
    views_count INTEGER,
    is_featured BOOLEAN,
    created_at TIMESTAMPTZ,
    author_name VARCHAR(100),
    author_avatar TEXT,
    is_liked_by_me BOOLEAN
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
    SELECT
        t.id,
        t.user_id,
        t.trip_name,
        t.description,
        t.trip_type,
        t.thumbnail_url,
        t.tags,
        t.region,
        t.country_code,
        t.distance_km,
        t.stop_count,
        t.day_count,
        t.likes_count,
        t.views_count,
        t.is_featured,
        t.created_at,
        p.display_name AS author_name,
        p.avatar_url AS author_avatar,
        EXISTS(
            SELECT 1 FROM public.trip_likes l
            WHERE l.trip_id = t.id AND l.user_id = auth.uid()
        ) AS is_liked_by_me
    FROM public.trips t
    LEFT JOIN public.user_profiles p ON p.id = t.user_id
    WHERE t.is_hidden = FALSE
        AND (p_query IS NULL OR
             t.trip_name ILIKE '%' || p_query || '%' OR
             t.description ILIKE '%' || p_query || '%')
        AND (p_tags IS NULL OR t.tags && p_tags)
        AND (p_country_code IS NULL OR t.country_code = p_country_code)
        AND (p_trip_type IS NULL OR t.trip_type = p_trip_type)
    ORDER BY
        CASE WHEN p_sort_by = 'popular' THEN t.likes_count + t.views_count / 10 END DESC NULLS LAST,
        CASE WHEN p_sort_by = 'recent' THEN t.created_at END DESC NULLS LAST,
        CASE WHEN p_sort_by = 'likes' THEN t.likes_count END DESC NULLS LAST,
        t.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
$$;

CREATE OR REPLACE FUNCTION like_trip(p_trip_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    INSERT INTO public.trip_likes (user_id, trip_id)
    VALUES (v_user_id, p_trip_id)
    ON CONFLICT (user_id, trip_id) DO NOTHING;

    IF FOUND THEN
        UPDATE public.trips
        SET likes_count = likes_count + 1
        WHERE id = p_trip_id;

        UPDATE public.user_profiles
        SET total_likes_received = total_likes_received + 1
        WHERE id = (SELECT user_id FROM public.trips WHERE id = p_trip_id);

        RETURN TRUE;
    END IF;

    RETURN FALSE;
END;
$$;

CREATE OR REPLACE FUNCTION unlike_trip(p_trip_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    DELETE FROM public.trip_likes
    WHERE user_id = v_user_id AND trip_id = p_trip_id;

    IF FOUND THEN
        UPDATE public.trips
        SET likes_count = GREATEST(0, likes_count - 1)
        WHERE id = p_trip_id;

        UPDATE public.user_profiles
        SET total_likes_received = GREATEST(0, total_likes_received - 1)
        WHERE id = (SELECT user_id FROM public.trips WHERE id = p_trip_id);

        RETURN TRUE;
    END IF;

    RETURN FALSE;
END;
$$;

CREATE OR REPLACE FUNCTION increment_trip_views(p_trip_id UUID)
RETURNS VOID
LANGUAGE sql
SECURITY DEFINER
AS $$
    UPDATE public.trips
    SET views_count = views_count + 1
    WHERE id = p_trip_id;
$$;

CREATE OR REPLACE FUNCTION import_trip(p_trip_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_trip_data JSONB;
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    SELECT trip_data INTO v_trip_data
    FROM public.trips
    WHERE id = p_trip_id AND is_hidden = FALSE;

    IF v_trip_data IS NULL THEN
        RAISE EXCEPTION 'Trip not found';
    END IF;

    INSERT INTO public.trip_imports (user_id, trip_id)
    VALUES (v_user_id, p_trip_id)
    ON CONFLICT (user_id, trip_id) DO NOTHING;

    IF FOUND THEN
        UPDATE public.trips
        SET imports_count = imports_count + 1
        WHERE id = p_trip_id;
    END IF;

    RETURN v_trip_data;
END;
$$;

CREATE OR REPLACE FUNCTION upsert_user_profile(
    p_display_name VARCHAR(100) DEFAULT NULL,
    p_avatar_url TEXT DEFAULT NULL,
    p_bio VARCHAR(500) DEFAULT NULL
)
RETURNS public.user_profiles
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_result public.user_profiles;
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    INSERT INTO public.user_profiles (id, display_name, avatar_url, bio)
    VALUES (v_user_id, p_display_name, p_avatar_url, p_bio)
    ON CONFLICT (id) DO UPDATE SET
        display_name = COALESCE(EXCLUDED.display_name, user_profiles.display_name),
        avatar_url = COALESCE(EXCLUDED.avatar_url, user_profiles.avatar_url),
        bio = COALESCE(EXCLUDED.bio, user_profiles.bio),
        updated_at = NOW()
    RETURNING * INTO v_result;

    RETURN v_result;
END;
$$;

CREATE OR REPLACE FUNCTION publish_trip(
    p_trip_name VARCHAR(200),
    p_trip_type VARCHAR(50),
    p_trip_data JSONB,
    p_description TEXT DEFAULT NULL,
    p_thumbnail_url TEXT DEFAULT NULL,
    p_tags TEXT[] DEFAULT '{}',
    p_region VARCHAR(100) DEFAULT NULL,
    p_country_code VARCHAR(3) DEFAULT NULL,
    p_start_lat DOUBLE PRECISION DEFAULT NULL,
    p_start_lng DOUBLE PRECISION DEFAULT NULL,
    p_distance_km DECIMAL(10,2) DEFAULT NULL,
    p_duration_hours DECIMAL(5,2) DEFAULT NULL,
    p_stop_count INTEGER DEFAULT 0,
    p_day_count INTEGER DEFAULT 1
)
RETURNS public.trips
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_result public.trips;
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    INSERT INTO public.trips (
        user_id, trip_name, trip_type, trip_data, description,
        thumbnail_url, tags, region, country_code,
        start_latitude, start_longitude,
        distance_km, duration_hours, stop_count, day_count
    )
    VALUES (
        v_user_id, p_trip_name, p_trip_type, p_trip_data, p_description,
        p_thumbnail_url, p_tags, p_region, p_country_code,
        p_start_lat, p_start_lng,
        p_distance_km, p_duration_hours, p_stop_count, p_day_count
    )
    RETURNING * INTO v_result;

    UPDATE public.user_profiles
    SET total_trips = total_trips + 1,
        total_km = total_km + COALESCE(p_distance_km, 0),
        total_pois = total_pois + COALESCE(p_stop_count, 0)
    WHERE id = v_user_id;

    RETURN v_result;
END;
$$;

CREATE OR REPLACE FUNCTION get_public_trip(p_trip_id UUID)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    trip_name VARCHAR(200),
    description TEXT,
    trip_type VARCHAR(50),
    trip_data JSONB,
    thumbnail_url TEXT,
    tags TEXT[],
    region VARCHAR(100),
    country_code VARCHAR(3),
    distance_km DECIMAL(10,2),
    duration_hours DECIMAL(5,2),
    stop_count INTEGER,
    day_count INTEGER,
    likes_count INTEGER,
    views_count INTEGER,
    imports_count INTEGER,
    is_featured BOOLEAN,
    created_at TIMESTAMPTZ,
    author_name VARCHAR(100),
    author_avatar TEXT,
    author_total_trips INTEGER,
    is_liked_by_me BOOLEAN,
    is_imported_by_me BOOLEAN
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
    SELECT
        t.id,
        t.user_id,
        t.trip_name,
        t.description,
        t.trip_type,
        t.trip_data,
        t.thumbnail_url,
        t.tags,
        t.region,
        t.country_code,
        t.distance_km,
        t.duration_hours,
        t.stop_count,
        t.day_count,
        t.likes_count,
        t.views_count,
        t.imports_count,
        t.is_featured,
        t.created_at,
        p.display_name AS author_name,
        p.avatar_url AS author_avatar,
        p.total_trips AS author_total_trips,
        EXISTS(
            SELECT 1 FROM public.trip_likes l
            WHERE l.trip_id = t.id AND l.user_id = auth.uid()
        ) AS is_liked_by_me,
        EXISTS(
            SELECT 1 FROM public.trip_imports i
            WHERE i.trip_id = t.id AND i.user_id = auth.uid()
        ) AS is_imported_by_me
    FROM public.trips t
    LEFT JOIN public.user_profiles p ON p.id = t.user_id
    WHERE t.id = p_trip_id
        AND (t.is_hidden = FALSE OR t.user_id = auth.uid());
$$;

-- ============================================
-- FERTIG!
-- ============================================
-- Wenn dieses Script ohne Fehler durchlaeuft,
-- sind alle Social Features korrekt eingerichtet.
