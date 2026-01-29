-- MapAB Supabase Schema
-- Migration 001: Initial Schema

-- ============================================
-- EXTENSIONS
-- ============================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- USERS TABLE (erweitert auth.users)
-- ============================================

CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username VARCHAR(50) UNIQUE NOT NULL,
    display_name VARCHAR(100) NOT NULL,
    avatar_url TEXT,

    -- Gamification
    total_xp INTEGER DEFAULT 0 CHECK (total_xp >= 0),
    level INTEGER DEFAULT 1 CHECK (level >= 1),

    -- Statistics
    total_trips INTEGER DEFAULT 0 CHECK (total_trips >= 0),
    total_distance_km DECIMAL(10,2) DEFAULT 0 CHECK (total_distance_km >= 0),
    total_pois_visited INTEGER DEFAULT 0 CHECK (total_pois_visited >= 0),

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Trigger für updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON public.users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- TRIPS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS public.trips (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,

    -- Trip Info
    name VARCHAR(200) NOT NULL,
    description TEXT,

    -- Start Location
    start_lat DECIMAL(10,7),
    start_lng DECIMAL(10,7),
    start_address VARCHAR(500),

    -- End Location
    end_lat DECIMAL(10,7),
    end_lng DECIMAL(10,7),
    end_address VARCHAR(500),

    -- Route Data
    distance_km DECIMAL(10,2),
    duration_minutes INTEGER,
    route_geometry TEXT, -- Encoded polyline

    -- Status
    is_favorite BOOLEAN DEFAULT FALSE,
    is_completed BOOLEAN DEFAULT FALSE,
    completed_at TIMESTAMPTZ,

    -- XP awarded for completion
    xp_awarded INTEGER DEFAULT 0,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_trips_user_id ON public.trips(user_id);
CREATE INDEX idx_trips_is_favorite ON public.trips(user_id, is_favorite) WHERE is_favorite = TRUE;

CREATE TRIGGER update_trips_updated_at
    BEFORE UPDATE ON public.trips
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- TRIP STOPS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS public.trip_stops (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trip_id UUID NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,

    -- POI Reference
    poi_id VARCHAR(100) NOT NULL,
    name VARCHAR(200) NOT NULL,

    -- Location
    latitude DECIMAL(10,7) NOT NULL,
    longitude DECIMAL(10,7) NOT NULL,

    -- Category
    category_id VARCHAR(50),

    -- Order in trip
    stop_order INTEGER NOT NULL,

    -- Visit Status
    is_visited BOOLEAN DEFAULT FALSE,
    visited_at TIMESTAMPTZ,

    -- Additional Data
    notes TEXT,
    photo_urls TEXT[] DEFAULT '{}',
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_trip_stops_trip_id ON public.trip_stops(trip_id);
CREATE UNIQUE INDEX idx_trip_stops_order ON public.trip_stops(trip_id, stop_order);

-- ============================================
-- FAVORITE POIS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS public.favorite_pois (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,

    -- POI Data
    poi_id VARCHAR(100) NOT NULL,
    name VARCHAR(200) NOT NULL,

    -- Location
    latitude DECIMAL(10,7) NOT NULL,
    longitude DECIMAL(10,7) NOT NULL,

    -- Category & Image
    category_id VARCHAR(50),
    image_url TEXT,

    -- User Notes
    notes TEXT,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),

    -- Unique constraint per user
    UNIQUE(user_id, poi_id)
);

CREATE INDEX idx_favorite_pois_user_id ON public.favorite_pois(user_id);

-- ============================================
-- JOURNAL ENTRIES TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS public.journal_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    trip_id UUID REFERENCES public.trips(id) ON DELETE SET NULL,

    -- Entry Content
    title VARCHAR(200) NOT NULL,
    content TEXT,

    -- Mood & Rating
    mood VARCHAR(50), -- happy, excited, relaxed, tired, etc.
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),

    -- Media
    photo_urls TEXT[] DEFAULT '{}',

    -- Location (optional)
    latitude DECIMAL(10,7),
    longitude DECIMAL(10,7),
    location_name VARCHAR(200),

    -- Timestamps
    entry_date DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_journal_entries_user_id ON public.journal_entries(user_id);
CREATE INDEX idx_journal_entries_trip_id ON public.journal_entries(trip_id);
CREATE INDEX idx_journal_entries_date ON public.journal_entries(user_id, entry_date DESC);

CREATE TRIGGER update_journal_entries_updated_at
    BEFORE UPDATE ON public.journal_entries
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- USER ACHIEVEMENTS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS public.user_achievements (
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    achievement_id VARCHAR(50) NOT NULL,

    -- Progress
    current_value INTEGER DEFAULT 0,
    target_value INTEGER NOT NULL,

    -- Unlock Status
    is_unlocked BOOLEAN DEFAULT FALSE,
    unlocked_at TIMESTAMPTZ,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    PRIMARY KEY(user_id, achievement_id)
);

CREATE TRIGGER update_user_achievements_updated_at
    BEFORE UPDATE ON public.user_achievements
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- AI REQUEST TRACKING TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS public.ai_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.users(id) ON DELETE SET NULL,

    -- Request Info
    request_type VARCHAR(50) NOT NULL, -- chat, trip-plan
    tokens_used INTEGER,

    -- Rate Limiting
    ip_address INET,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_ai_requests_user_id ON public.ai_requests(user_id);
CREATE INDEX idx_ai_requests_created_at ON public.ai_requests(created_at DESC);
CREATE INDEX idx_ai_requests_rate_limit ON public.ai_requests(user_id, created_at DESC);

-- ============================================
-- ROW LEVEL SECURITY
-- ============================================

-- Enable RLS on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trips ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trip_stops ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.favorite_pois ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.journal_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_requests ENABLE ROW LEVEL SECURITY;

-- Users: Only own data
CREATE POLICY "Users can view own profile" ON public.users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.users
    FOR UPDATE USING (auth.uid() = id);

-- Trips: Only own trips
CREATE POLICY "Users can view own trips" ON public.trips
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create own trips" ON public.trips
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own trips" ON public.trips
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own trips" ON public.trips
    FOR DELETE USING (auth.uid() = user_id);

-- Trip Stops: Via trip ownership
CREATE POLICY "Users can view own trip stops" ON public.trip_stops
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM public.trips WHERE trips.id = trip_stops.trip_id AND trips.user_id = auth.uid())
    );

CREATE POLICY "Users can create stops for own trips" ON public.trip_stops
    FOR INSERT WITH CHECK (
        EXISTS (SELECT 1 FROM public.trips WHERE trips.id = trip_stops.trip_id AND trips.user_id = auth.uid())
    );

CREATE POLICY "Users can update stops for own trips" ON public.trip_stops
    FOR UPDATE USING (
        EXISTS (SELECT 1 FROM public.trips WHERE trips.id = trip_stops.trip_id AND trips.user_id = auth.uid())
    );

CREATE POLICY "Users can delete stops from own trips" ON public.trip_stops
    FOR DELETE USING (
        EXISTS (SELECT 1 FROM public.trips WHERE trips.id = trip_stops.trip_id AND trips.user_id = auth.uid())
    );

-- Favorite POIs: Only own favorites
CREATE POLICY "Users can view own favorites" ON public.favorite_pois
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create own favorites" ON public.favorite_pois
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own favorites" ON public.favorite_pois
    FOR DELETE USING (auth.uid() = user_id);

-- Journal Entries: Only own entries
CREATE POLICY "Users can view own journal" ON public.journal_entries
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create own entries" ON public.journal_entries
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own entries" ON public.journal_entries
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own entries" ON public.journal_entries
    FOR DELETE USING (auth.uid() = user_id);

-- User Achievements: Only own achievements
CREATE POLICY "Users can view own achievements" ON public.user_achievements
    FOR SELECT USING (auth.uid() = user_id);

-- AI Requests: Only own requests (for viewing usage)
CREATE POLICY "Users can view own ai requests" ON public.ai_requests
    FOR SELECT USING (auth.uid() = user_id);

-- ============================================
-- FUNCTIONS FOR GAMIFICATION
-- ============================================

-- Calculate level from XP
CREATE OR REPLACE FUNCTION calculate_level(xp INTEGER)
RETURNS INTEGER AS $$
BEGIN
    -- Level formula: sqrt(xp / 100) + 1
    -- Level 1: 0-99 XP
    -- Level 2: 100-399 XP
    -- Level 3: 400-899 XP
    -- etc.
    RETURN GREATEST(1, FLOOR(SQRT(xp / 100.0)) + 1)::INTEGER;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Award XP and update level
CREATE OR REPLACE FUNCTION award_xp(p_user_id UUID, p_xp INTEGER)
RETURNS TABLE(new_total_xp INTEGER, new_level INTEGER, level_up BOOLEAN) AS $$
DECLARE
    v_old_level INTEGER;
    v_new_level INTEGER;
    v_new_total_xp INTEGER;
BEGIN
    -- Get current state
    SELECT total_xp, level INTO v_new_total_xp, v_old_level
    FROM public.users
    WHERE id = p_user_id;

    -- Add XP
    v_new_total_xp := v_new_total_xp + p_xp;

    -- Calculate new level
    v_new_level := calculate_level(v_new_total_xp);

    -- Update user
    UPDATE public.users
    SET total_xp = v_new_total_xp,
        level = v_new_level
    WHERE id = p_user_id;

    -- Return result
    new_total_xp := v_new_total_xp;
    new_level := v_new_level;
    level_up := v_new_level > v_old_level;

    RETURN NEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Complete trip and award XP
CREATE OR REPLACE FUNCTION complete_trip(p_trip_id UUID)
RETURNS TABLE(xp_earned INTEGER, new_total_xp INTEGER, new_level INTEGER, level_up BOOLEAN) AS $$
DECLARE
    v_user_id UUID;
    v_distance_km DECIMAL;
    v_stops_count INTEGER;
    v_xp_earned INTEGER;
BEGIN
    -- Get trip info
    SELECT user_id, distance_km
    INTO v_user_id, v_distance_km
    FROM public.trips
    WHERE id = p_trip_id AND is_completed = FALSE;

    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Trip not found or already completed';
    END IF;

    -- Count visited stops
    SELECT COUNT(*)
    INTO v_stops_count
    FROM public.trip_stops
    WHERE trip_id = p_trip_id AND is_visited = TRUE;

    -- Calculate XP
    -- Base: 50 XP
    -- + 1 XP per km (capped at 200)
    -- + 25 XP per visited stop
    v_xp_earned := 50
        + LEAST(COALESCE(v_distance_km, 0)::INTEGER, 200)
        + (v_stops_count * 25);

    -- Mark trip as completed
    UPDATE public.trips
    SET is_completed = TRUE,
        completed_at = NOW(),
        xp_awarded = v_xp_earned
    WHERE id = p_trip_id;

    -- Update user stats
    UPDATE public.users
    SET total_trips = total_trips + 1,
        total_distance_km = total_distance_km + COALESCE(v_distance_km, 0),
        total_pois_visited = total_pois_visited + v_stops_count
    WHERE id = v_user_id;

    -- Award XP
    SELECT a.new_total_xp, a.new_level, a.level_up
    INTO new_total_xp, new_level, level_up
    FROM award_xp(v_user_id, v_xp_earned) a;

    xp_earned := v_xp_earned;

    RETURN NEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- TRIGGER FOR AUTO USER CREATION
-- ============================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.users (id, username, display_name, avatar_url)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'username', 'user_' || substr(NEW.id::text, 1, 8)),
        COALESCE(NEW.raw_user_meta_data->>'display_name', NEW.email),
        NEW.raw_user_meta_data->>'avatar_url'
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger on auth.users insert
CREATE OR REPLACE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
