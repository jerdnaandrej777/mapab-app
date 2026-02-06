-- MapAB Supabase Schema
-- Migration 004: Rename public_trips to trips
-- Fixes table name inconsistency between schema and client code

-- ============================================
-- RENAME TABLE
-- ============================================

-- Rename the main table
ALTER TABLE IF EXISTS public.public_trips RENAME TO trips;

-- ============================================
-- UPDATE FOREIGN KEY REFERENCES
-- ============================================

-- trip_likes references trips
ALTER TABLE public.trip_likes
    DROP CONSTRAINT IF EXISTS trip_likes_trip_id_fkey;

ALTER TABLE public.trip_likes
    ADD CONSTRAINT trip_likes_trip_id_fkey
    FOREIGN KEY (trip_id) REFERENCES public.trips(id) ON DELETE CASCADE;

-- trip_imports references trips
ALTER TABLE public.trip_imports
    DROP CONSTRAINT IF EXISTS trip_imports_trip_id_fkey;

ALTER TABLE public.trip_imports
    ADD CONSTRAINT trip_imports_trip_id_fkey
    FOREIGN KEY (trip_id) REFERENCES public.trips(id) ON DELETE CASCADE;

-- ============================================
-- UPDATE RPC FUNCTIONS
-- ============================================

-- search_public_trips: Update to use 'trips' table
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

-- like_trip: Update to use 'trips' table
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

-- unlike_trip: Update to use 'trips' table
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

-- increment_trip_views: Update to use 'trips' table
CREATE OR REPLACE FUNCTION increment_trip_views(p_trip_id UUID)
RETURNS VOID
LANGUAGE sql
SECURITY DEFINER
AS $$
    UPDATE public.trips
    SET views_count = views_count + 1
    WHERE id = p_trip_id;
$$;

-- import_trip: Update to use 'trips' table
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

-- publish_trip: Update to use 'trips' table
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
        start_latitude, start_longitude, start_location,
        distance_km, duration_hours, stop_count, day_count
    )
    VALUES (
        v_user_id, p_trip_name, p_trip_type, p_trip_data, p_description,
        p_thumbnail_url, p_tags, p_region, p_country_code,
        p_start_lat, p_start_lng,
        CASE WHEN p_start_lat IS NOT NULL AND p_start_lng IS NOT NULL
             THEN ST_SetSRID(ST_MakePoint(p_start_lng, p_start_lat), 4326)::geography
             ELSE NULL END,
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

-- get_public_trip: Update to use 'trips' table
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
-- UPDATE ROW LEVEL SECURITY POLICIES
-- ============================================

-- Drop old policies (they reference the old table name internally)
DROP POLICY IF EXISTS "Public trips are viewable by everyone" ON public.trips;
DROP POLICY IF EXISTS "Users can insert own trips" ON public.trips;
DROP POLICY IF EXISTS "Users can update own trips" ON public.trips;
DROP POLICY IF EXISTS "Users can delete own trips" ON public.trips;

-- Recreate policies for the renamed table
CREATE POLICY "Public trips are viewable by everyone" ON public.trips
    FOR SELECT USING (is_hidden = FALSE OR auth.uid() = user_id);

CREATE POLICY "Users can insert own trips" ON public.trips
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own trips" ON public.trips
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own trips" ON public.trips
    FOR DELETE USING (auth.uid() = user_id);
