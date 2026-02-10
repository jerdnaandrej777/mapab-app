-- MapAB Supabase Schema
-- Migration 012: Favorite Trips (Bidirektionaler Cloud-Sync)
-- Dedizierte Tabelle fuer private gespeicherte Routen, getrennt von oeffentlichen Trips.
-- WICHTIG: Im Supabase SQL Editor ausfuehren!

-- ============================================
-- SCHRITT 1: TABELLE favorite_trips
-- ============================================

CREATE TABLE IF NOT EXISTS public.favorite_trips (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

    -- App-internes Trip-ID (aus Dart UUID)
    trip_id TEXT NOT NULL,
    trip_name TEXT NOT NULL,

    -- Komplettes Trip-Objekt als JSONB (Trip.toJson())
    trip_data JSONB NOT NULL,

    -- Denormalisierte Felder fuer Queries/Anzeige
    trip_type VARCHAR(50) NOT NULL DEFAULT 'daytrip'
        CHECK (trip_type IN ('daytrip', 'eurotrip')),
    distance_km DECIMAL(10,2),
    stop_count INTEGER NOT NULL DEFAULT 0,

    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Ein User kann jeden Trip nur einmal speichern
    UNIQUE(user_id, trip_id)
);

-- ============================================
-- SCHRITT 2: INDEXES
-- ============================================

CREATE INDEX IF NOT EXISTS idx_favorite_trips_user
    ON public.favorite_trips(user_id, created_at DESC);

-- ============================================
-- SCHRITT 3: TRIGGER fuer updated_at
-- ============================================

-- Helper-Function (idempotent)
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_favorite_trips_updated_at ON public.favorite_trips;
CREATE TRIGGER update_favorite_trips_updated_at
    BEFORE UPDATE ON public.favorite_trips
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- SCHRITT 4: ROW LEVEL SECURITY
-- ============================================

ALTER TABLE public.favorite_trips ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users view own favorite trips" ON public.favorite_trips;
CREATE POLICY "Users view own favorite trips"
    ON public.favorite_trips FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users insert own favorite trips" ON public.favorite_trips;
CREATE POLICY "Users insert own favorite trips"
    ON public.favorite_trips FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users update own favorite trips" ON public.favorite_trips;
CREATE POLICY "Users update own favorite trips"
    ON public.favorite_trips FOR UPDATE
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users delete own favorite trips" ON public.favorite_trips;
CREATE POLICY "Users delete own favorite trips"
    ON public.favorite_trips FOR DELETE
    USING (auth.uid() = user_id);

-- ============================================
-- SCHRITT 5: RPC FUNCTIONS
-- ============================================

-- Lade alle Favoriten-Trips eines Users
CREATE OR REPLACE FUNCTION get_user_favorite_trips(p_user_id UUID)
RETURNS SETOF public.favorite_trips AS $$
BEGIN
    RETURN QUERY
    SELECT * FROM public.favorite_trips
    WHERE user_id = p_user_id
    ORDER BY created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Lade alle Favoriten-POIs eines Users
CREATE OR REPLACE FUNCTION get_user_favorite_pois(p_user_id UUID)
RETURNS SETOF public.favorite_pois AS $$
BEGIN
    RETURN QUERY
    SELECT * FROM public.favorite_pois
    WHERE user_id = p_user_id
    ORDER BY created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
