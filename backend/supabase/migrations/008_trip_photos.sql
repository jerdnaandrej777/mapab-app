-- MapAB Supabase Schema
-- Migration 008: Trip Photos (Cover-Bild + Galerie)
-- WICHTIG: Fuehre dieses Script im Supabase SQL Editor aus!
-- VORAUSSETZUNG: Migration 006 und 007 muessen zuerst ausgefuehrt werden!

-- ============================================
-- SCHRITT 1: COVER_IMAGE_PATH ZUR TRIPS TABELLE
-- ============================================

-- Neues Feld fuer den Storage-Pfad des Cover-Bildes
ALTER TABLE public.trips
ADD COLUMN IF NOT EXISTS cover_image_path TEXT;

-- ============================================
-- SCHRITT 2: TRIP PHOTOS TABELLE
-- ============================================

CREATE TABLE IF NOT EXISTS public.trip_photos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_id UUID NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    storage_path TEXT NOT NULL,
    thumbnail_path TEXT,
    caption VARCHAR(500),
    display_order INTEGER NOT NULL DEFAULT 0,
    likes_count INTEGER NOT NULL DEFAULT 0,
    is_flagged BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- SCHRITT 3: INDEXES
-- ============================================

CREATE INDEX IF NOT EXISTS idx_trip_photos_trip ON public.trip_photos (trip_id, display_order);
CREATE INDEX IF NOT EXISTS idx_trip_photos_user ON public.trip_photos (user_id);
CREATE INDEX IF NOT EXISTS idx_trip_photos_flagged ON public.trip_photos (is_flagged) WHERE is_flagged = TRUE;

-- ============================================
-- SCHRITT 4: ROW LEVEL SECURITY
-- ============================================

ALTER TABLE public.trip_photos ENABLE ROW LEVEL SECURITY;

-- Fotos von nicht-versteckten Trips sind oeffentlich lesbar
CREATE POLICY "Trip photos are publicly readable" ON public.trip_photos
    FOR SELECT USING (
        is_flagged = FALSE OR auth.uid() = user_id
    );

-- Nur authentifizierte User koennen eigene Fotos hochladen
CREATE POLICY "Authenticated users can insert trip photos" ON public.trip_photos
    FOR INSERT WITH CHECK (
        auth.uid() = user_id AND
        -- Nur zu eigenen Trips
        trip_id IN (SELECT id FROM public.trips WHERE user_id = auth.uid())
    );

-- User koennen eigene Fotos loeschen, Admins alles
CREATE POLICY "Users can delete own trip photos" ON public.trip_photos
    FOR DELETE USING (
        auth.uid() = user_id OR
        auth.uid() IN (SELECT user_id FROM public.admins)
    );

-- Admins koennen Fotos aktualisieren (z.B. flaggen)
CREATE POLICY "Admins can update trip photos" ON public.trip_photos
    FOR UPDATE USING (
        auth.uid() IN (SELECT user_id FROM public.admins)
    );

-- ============================================
-- SCHRITT 5: RPC FUNCTIONS
-- ============================================

-- Foto-Upload registrieren
CREATE OR REPLACE FUNCTION register_trip_photo(
    p_trip_id UUID,
    p_storage_path TEXT,
    p_thumbnail_path TEXT DEFAULT NULL,
    p_caption VARCHAR(500) DEFAULT NULL,
    p_display_order INTEGER DEFAULT 0
)
RETURNS public.trip_photos
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_result public.trip_photos;
    v_trip_owner UUID;
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Pruefen ob Trip dem User gehoert
    SELECT user_id INTO v_trip_owner FROM public.trips WHERE id = p_trip_id;
    IF v_trip_owner IS NULL THEN
        RAISE EXCEPTION 'Trip not found';
    END IF;
    IF v_trip_owner != v_user_id THEN
        RAISE EXCEPTION 'Not authorized to add photos to this trip';
    END IF;

    INSERT INTO public.trip_photos (trip_id, user_id, storage_path, thumbnail_path, caption, display_order)
    VALUES (p_trip_id, v_user_id, p_storage_path, p_thumbnail_path, p_caption, p_display_order)
    RETURNING * INTO v_result;

    -- Admin-Benachrichtigung (falls Funktion existiert)
    BEGIN
        PERFORM create_admin_notification(
            'new_photo', 'trip_photo', v_result.id, v_user_id, NULL, p_trip_id::VARCHAR,
            'Neues Trip-Foto hochgeladen'
        );
    EXCEPTION WHEN undefined_function THEN
        -- Ignorieren wenn create_admin_notification nicht existiert
        NULL;
    END;

    RETURN v_result;
END;
$$;

-- Cover-Bild setzen
CREATE OR REPLACE FUNCTION set_trip_cover_image(
    p_trip_id UUID,
    p_storage_path TEXT
)
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

    UPDATE public.trips
    SET cover_image_path = p_storage_path,
        updated_at = NOW()
    WHERE id = p_trip_id AND user_id = v_user_id;

    RETURN FOUND;
END;
$$;

-- Trip-Fotos laden
CREATE OR REPLACE FUNCTION get_trip_photos(
    p_trip_id UUID,
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    trip_id UUID,
    user_id UUID,
    storage_path TEXT,
    thumbnail_path TEXT,
    caption VARCHAR(500),
    display_order INTEGER,
    likes_count INTEGER,
    created_at TIMESTAMPTZ,
    author_name VARCHAR(100),
    author_avatar TEXT
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
    SELECT
        ph.id,
        ph.trip_id,
        ph.user_id,
        ph.storage_path,
        ph.thumbnail_path,
        ph.caption,
        ph.display_order,
        ph.likes_count,
        ph.created_at,
        p.display_name AS author_name,
        p.avatar_url AS author_avatar
    FROM public.trip_photos ph
    LEFT JOIN public.user_profiles p ON p.id = ph.user_id
    WHERE ph.trip_id = p_trip_id
        AND ph.is_flagged = FALSE
    ORDER BY ph.display_order ASC, ph.created_at ASC
    LIMIT p_limit
    OFFSET p_offset;
$$;

-- Foto loeschen
CREATE OR REPLACE FUNCTION delete_trip_photo(p_photo_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_photo_owner UUID;
    v_is_admin BOOLEAN;
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Foto-Owner pruefen
    SELECT user_id INTO v_photo_owner FROM public.trip_photos WHERE id = p_photo_id;
    IF v_photo_owner IS NULL THEN
        RETURN FALSE;
    END IF;

    -- Admin-Check
    SELECT EXISTS(SELECT 1 FROM public.admins WHERE user_id = v_user_id) INTO v_is_admin;

    IF v_photo_owner != v_user_id AND NOT v_is_admin THEN
        RAISE EXCEPTION 'Not authorized to delete this photo';
    END IF;

    DELETE FROM public.trip_photos WHERE id = p_photo_id;
    RETURN FOUND;
END;
$$;

-- ============================================
-- FERTIG!
-- ============================================
-- Vergiss nicht, den Storage Bucket 'trip-photos' manuell zu erstellen!
-- Dashboard > Storage > New Bucket > Name: trip-photos, Public: true
