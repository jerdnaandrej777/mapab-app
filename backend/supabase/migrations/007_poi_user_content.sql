-- MapAB Supabase Schema
-- Migration 007: POI User Content (Fotos, Bewertungen, Kommentare, Admin)
-- WICHTIG: Fuehre dieses Script im Supabase SQL Editor aus!
-- VORAUSSETZUNG: Migration 006 muss zuerst ausgefuehrt werden!

-- ============================================
-- SCHRITT 1: HELPER FUNCTION (falls nicht vorhanden)
-- ============================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- SCHRITT 2: ADMINS TABELLE
-- ============================================

CREATE TABLE IF NOT EXISTS public.admins (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    role VARCHAR(20) NOT NULL DEFAULT 'moderator'
        CHECK (role IN ('moderator', 'admin', 'super_admin')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- SCHRITT 3: POI PHOTOS TABELLE
-- ============================================

CREATE TABLE public.poi_photos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    poi_id VARCHAR(100) NOT NULL,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    storage_path TEXT NOT NULL,
    thumbnail_path TEXT,
    caption VARCHAR(500),
    likes_count INTEGER NOT NULL DEFAULT 0,
    is_flagged BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- SCHRITT 4: POI REVIEWS TABELLE
-- ============================================

CREATE TABLE public.poi_reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    poi_id VARCHAR(100) NOT NULL,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    review_text TEXT,
    visit_date DATE,
    helpful_count INTEGER NOT NULL DEFAULT 0,
    is_flagged BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(poi_id, user_id)
);

CREATE TRIGGER update_poi_reviews_updated_at
    BEFORE UPDATE ON public.poi_reviews
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- SCHRITT 5: REVIEW HELPFUL VOTES TABELLE
-- ============================================

CREATE TABLE public.review_helpful_votes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    review_id UUID NOT NULL REFERENCES public.poi_reviews(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(review_id, user_id)
);

-- ============================================
-- SCHRITT 6: COMMENTS TABELLE (POIs + Trips)
-- ============================================

CREATE TABLE public.comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    target_type VARCHAR(20) NOT NULL CHECK (target_type IN ('poi', 'trip')),
    target_id VARCHAR(100) NOT NULL,
    parent_id UUID REFERENCES public.comments(id) ON DELETE CASCADE,
    content TEXT NOT NULL CHECK (char_length(content) >= 1 AND char_length(content) <= 2000),
    likes_count INTEGER NOT NULL DEFAULT 0,
    is_flagged BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TRIGGER update_comments_updated_at
    BEFORE UPDATE ON public.comments
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- SCHRITT 7: POI STATS TABELLE (Aggregiert)
-- ============================================

CREATE TABLE public.poi_stats (
    poi_id VARCHAR(100) PRIMARY KEY,
    avg_rating DECIMAL(2,1) NOT NULL DEFAULT 0,
    review_count INTEGER NOT NULL DEFAULT 0,
    photo_count INTEGER NOT NULL DEFAULT 0,
    comment_count INTEGER NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- SCHRITT 8: ADMIN NOTIFICATIONS TABELLE
-- ============================================

CREATE TABLE public.admin_notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type VARCHAR(50) NOT NULL CHECK (type IN ('new_photo', 'new_review', 'new_comment', 'flagged_content')),
    content_type VARCHAR(20) NOT NULL CHECK (content_type IN ('photo', 'review', 'comment')),
    content_id UUID NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    poi_id VARCHAR(100),
    target_id VARCHAR(100),
    message TEXT,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- SCHRITT 9: INDEXES
-- ============================================

-- POI Photos
CREATE INDEX idx_poi_photos_poi ON public.poi_photos (poi_id, created_at DESC);
CREATE INDEX idx_poi_photos_user ON public.poi_photos (user_id);
CREATE INDEX idx_poi_photos_flagged ON public.poi_photos (is_flagged) WHERE is_flagged = TRUE;

-- POI Reviews
CREATE INDEX idx_poi_reviews_poi ON public.poi_reviews (poi_id, created_at DESC);
CREATE INDEX idx_poi_reviews_poi_rating ON public.poi_reviews (poi_id, rating DESC);
CREATE INDEX idx_poi_reviews_user ON public.poi_reviews (user_id);
CREATE INDEX idx_poi_reviews_flagged ON public.poi_reviews (is_flagged) WHERE is_flagged = TRUE;

-- Review Helpful Votes
CREATE INDEX idx_review_helpful_review ON public.review_helpful_votes (review_id);
CREATE INDEX idx_review_helpful_user ON public.review_helpful_votes (user_id);

-- Comments
CREATE INDEX idx_comments_target ON public.comments (target_type, target_id, created_at DESC);
CREATE INDEX idx_comments_parent ON public.comments (parent_id) WHERE parent_id IS NOT NULL;
CREATE INDEX idx_comments_user ON public.comments (user_id);
CREATE INDEX idx_comments_flagged ON public.comments (is_flagged) WHERE is_flagged = TRUE;

-- Admin Notifications
CREATE INDEX idx_admin_notifications_unread ON public.admin_notifications (created_at DESC) WHERE is_read = FALSE;
CREATE INDEX idx_admin_notifications_type ON public.admin_notifications (type, created_at DESC);

-- ============================================
-- SCHRITT 10: ROW LEVEL SECURITY
-- ============================================

ALTER TABLE public.admins ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.poi_photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.poi_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.review_helpful_votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.poi_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_notifications ENABLE ROW LEVEL SECURITY;

-- Admins Policies
CREATE POLICY "Admins table is only readable by admins" ON public.admins
    FOR SELECT USING (
        auth.uid() IN (SELECT user_id FROM public.admins)
    );

-- POI Photos Policies
CREATE POLICY "Photos are publicly readable" ON public.poi_photos
    FOR SELECT USING (is_flagged = FALSE OR auth.uid() = user_id);

CREATE POLICY "Authenticated users can insert photos" ON public.poi_photos
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own photos" ON public.poi_photos
    FOR DELETE USING (
        auth.uid() = user_id OR
        auth.uid() IN (SELECT user_id FROM public.admins)
    );

CREATE POLICY "Admins can update photos" ON public.poi_photos
    FOR UPDATE USING (
        auth.uid() IN (SELECT user_id FROM public.admins)
    );

-- POI Reviews Policies
CREATE POLICY "Reviews are publicly readable" ON public.poi_reviews
    FOR SELECT USING (TRUE);

CREATE POLICY "Authenticated users can insert reviews" ON public.poi_reviews
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own reviews" ON public.poi_reviews
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users and admins can delete reviews" ON public.poi_reviews
    FOR DELETE USING (
        auth.uid() = user_id OR
        auth.uid() IN (SELECT user_id FROM public.admins)
    );

-- Review Helpful Votes Policies
CREATE POLICY "Helpful votes are publicly readable" ON public.review_helpful_votes
    FOR SELECT USING (TRUE);

CREATE POLICY "Authenticated users can insert helpful votes" ON public.review_helpful_votes
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own helpful votes" ON public.review_helpful_votes
    FOR DELETE USING (auth.uid() = user_id);

-- Comments Policies
CREATE POLICY "Non-flagged comments are publicly readable" ON public.comments
    FOR SELECT USING (is_flagged = FALSE OR auth.uid() = user_id);

CREATE POLICY "Authenticated users can insert comments" ON public.comments
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own comments" ON public.comments
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users and admins can delete comments" ON public.comments
    FOR DELETE USING (
        auth.uid() = user_id OR
        auth.uid() IN (SELECT user_id FROM public.admins)
    );

-- POI Stats Policies
CREATE POLICY "Stats are publicly readable" ON public.poi_stats
    FOR SELECT USING (TRUE);

-- Admin Notifications Policies
CREATE POLICY "Only admins can read notifications" ON public.admin_notifications
    FOR SELECT USING (
        auth.uid() IN (SELECT user_id FROM public.admins)
    );

CREATE POLICY "Only admins can update notifications" ON public.admin_notifications
    FOR UPDATE USING (
        auth.uid() IN (SELECT user_id FROM public.admins)
    );

-- ============================================
-- SCHRITT 11: RPC FUNCTIONS
-- ============================================

-- Pruefen ob Benutzer Admin ist
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
    SELECT EXISTS(
        SELECT 1 FROM public.admins WHERE user_id = auth.uid()
    );
$$;

-- POI Stats aktualisieren (intern)
CREATE OR REPLACE FUNCTION update_poi_stats(p_poi_id VARCHAR(100))
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    INSERT INTO public.poi_stats (poi_id, avg_rating, review_count, photo_count, comment_count, updated_at)
    SELECT
        p_poi_id,
        COALESCE((SELECT AVG(rating)::DECIMAL(2,1) FROM public.poi_reviews WHERE poi_id = p_poi_id), 0),
        COALESCE((SELECT COUNT(*) FROM public.poi_reviews WHERE poi_id = p_poi_id), 0),
        COALESCE((SELECT COUNT(*) FROM public.poi_photos WHERE poi_id = p_poi_id AND is_flagged = FALSE), 0),
        COALESCE((SELECT COUNT(*) FROM public.comments WHERE target_type = 'poi' AND target_id = p_poi_id AND is_flagged = FALSE AND parent_id IS NULL), 0),
        NOW()
    ON CONFLICT (poi_id) DO UPDATE SET
        avg_rating = EXCLUDED.avg_rating,
        review_count = EXCLUDED.review_count,
        photo_count = EXCLUDED.photo_count,
        comment_count = EXCLUDED.comment_count,
        updated_at = NOW();
END;
$$;

-- Admin-Benachrichtigung erstellen (intern)
CREATE OR REPLACE FUNCTION create_admin_notification(
    p_type VARCHAR(50),
    p_content_type VARCHAR(20),
    p_content_id UUID,
    p_user_id UUID,
    p_poi_id VARCHAR(100) DEFAULT NULL,
    p_target_id VARCHAR(100) DEFAULT NULL,
    p_message TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE sql
SECURITY DEFINER
AS $$
    INSERT INTO public.admin_notifications (type, content_type, content_id, user_id, poi_id, target_id, message)
    VALUES (p_type, p_content_type, p_content_id, p_user_id, p_poi_id, p_target_id, p_message);
$$;

-- Bewertung abgeben (Upsert)
CREATE OR REPLACE FUNCTION submit_poi_review(
    p_poi_id VARCHAR(100),
    p_rating INTEGER,
    p_review_text TEXT DEFAULT NULL,
    p_visit_date DATE DEFAULT NULL
)
RETURNS public.poi_reviews
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_result public.poi_reviews;
    v_is_new BOOLEAN;
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Check if review exists
    SELECT NOT EXISTS(
        SELECT 1 FROM public.poi_reviews WHERE poi_id = p_poi_id AND user_id = v_user_id
    ) INTO v_is_new;

    -- Upsert review
    INSERT INTO public.poi_reviews (poi_id, user_id, rating, review_text, visit_date)
    VALUES (p_poi_id, v_user_id, p_rating, p_review_text, p_visit_date)
    ON CONFLICT (poi_id, user_id) DO UPDATE SET
        rating = EXCLUDED.rating,
        review_text = EXCLUDED.review_text,
        visit_date = EXCLUDED.visit_date,
        updated_at = NOW()
    RETURNING * INTO v_result;

    -- Update stats
    PERFORM update_poi_stats(p_poi_id);

    -- Notify admins only for new reviews
    IF v_is_new THEN
        PERFORM create_admin_notification(
            'new_review', 'review', v_result.id, v_user_id, p_poi_id, NULL,
            'Neue Bewertung: ' || p_rating || ' Sterne'
        );
    END IF;

    RETURN v_result;
END;
$$;

-- Hilfreich-Markierung toggle
CREATE OR REPLACE FUNCTION vote_review_helpful(p_review_id UUID)
RETURNS TABLE (helpful_count INTEGER, is_helpful_by_me BOOLEAN)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_exists BOOLEAN;
    v_new_count INTEGER;
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Check if vote exists
    SELECT EXISTS(
        SELECT 1 FROM public.review_helpful_votes
        WHERE review_id = p_review_id AND user_id = v_user_id
    ) INTO v_exists;

    IF v_exists THEN
        -- Remove vote
        DELETE FROM public.review_helpful_votes
        WHERE review_id = p_review_id AND user_id = v_user_id;

        UPDATE public.poi_reviews
        SET helpful_count = GREATEST(0, helpful_count - 1)
        WHERE id = p_review_id
        RETURNING poi_reviews.helpful_count INTO v_new_count;

        RETURN QUERY SELECT v_new_count, FALSE;
    ELSE
        -- Add vote
        INSERT INTO public.review_helpful_votes (review_id, user_id)
        VALUES (p_review_id, v_user_id);

        UPDATE public.poi_reviews
        SET helpful_count = helpful_count + 1
        WHERE id = p_review_id
        RETURNING poi_reviews.helpful_count INTO v_new_count;

        RETURN QUERY SELECT v_new_count, TRUE;
    END IF;
END;
$$;

-- POI Stats mit eigener Bewertung laden
CREATE OR REPLACE FUNCTION get_poi_stats(p_poi_id VARCHAR(100))
RETURNS TABLE (
    avg_rating DECIMAL(2,1),
    review_count INTEGER,
    photo_count INTEGER,
    comment_count INTEGER,
    my_rating INTEGER,
    my_review_text TEXT,
    my_review_id UUID
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
    SELECT
        COALESCE(s.avg_rating, 0),
        COALESCE(s.review_count, 0),
        COALESCE(s.photo_count, 0),
        COALESCE(s.comment_count, 0),
        r.rating,
        r.review_text,
        r.id
    FROM (SELECT 1) AS dummy
    LEFT JOIN public.poi_stats s ON s.poi_id = p_poi_id
    LEFT JOIN public.poi_reviews r ON r.poi_id = p_poi_id AND r.user_id = auth.uid();
$$;

-- Kommentar hinzufuegen
CREATE OR REPLACE FUNCTION add_comment(
    p_target_type VARCHAR(20),
    p_target_id VARCHAR(100),
    p_content TEXT,
    p_parent_id UUID DEFAULT NULL
)
RETURNS public.comments
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_result public.comments;
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    INSERT INTO public.comments (user_id, target_type, target_id, content, parent_id)
    VALUES (v_user_id, p_target_type, p_target_id, p_content, p_parent_id)
    RETURNING * INTO v_result;

    -- Update stats if POI (only top-level comments)
    IF p_target_type = 'poi' AND p_parent_id IS NULL THEN
        PERFORM update_poi_stats(p_target_id);
    END IF;

    -- Notify admins
    PERFORM create_admin_notification(
        'new_comment', 'comment', v_result.id, v_user_id,
        CASE WHEN p_target_type = 'poi' THEN p_target_id ELSE NULL END,
        p_target_id,
        'Neuer Kommentar'
    );

    RETURN v_result;
END;
$$;

-- Foto-Upload registrieren
CREATE OR REPLACE FUNCTION register_poi_photo(
    p_poi_id VARCHAR(100),
    p_storage_path TEXT,
    p_thumbnail_path TEXT DEFAULT NULL,
    p_caption VARCHAR(500) DEFAULT NULL
)
RETURNS public.poi_photos
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_result public.poi_photos;
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    INSERT INTO public.poi_photos (poi_id, user_id, storage_path, thumbnail_path, caption)
    VALUES (p_poi_id, v_user_id, p_storage_path, p_thumbnail_path, p_caption)
    RETURNING * INTO v_result;

    -- Update stats
    PERFORM update_poi_stats(p_poi_id);

    -- Notify admins
    PERFORM create_admin_notification(
        'new_photo', 'photo', v_result.id, v_user_id, p_poi_id, NULL,
        'Neues Foto hochgeladen'
    );

    RETURN v_result;
END;
$$;

-- Inhalt melden
CREATE OR REPLACE FUNCTION flag_content(
    p_content_type VARCHAR(20),
    p_content_id UUID,
    p_reason TEXT DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_poi_id VARCHAR(100);
    v_target_id VARCHAR(100);
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Update is_flagged
    IF p_content_type = 'photo' THEN
        UPDATE public.poi_photos SET is_flagged = TRUE WHERE id = p_content_id
        RETURNING poi_id INTO v_poi_id;
    ELSIF p_content_type = 'review' THEN
        UPDATE public.poi_reviews SET is_flagged = TRUE WHERE id = p_content_id
        RETURNING poi_id INTO v_poi_id;
    ELSIF p_content_type = 'comment' THEN
        UPDATE public.comments SET is_flagged = TRUE WHERE id = p_content_id
        RETURNING target_id INTO v_target_id;
    END IF;

    -- Notify admins
    PERFORM create_admin_notification(
        'flagged_content', p_content_type, p_content_id, v_user_id, v_poi_id, v_target_id,
        COALESCE(p_reason, 'Inhalt wurde gemeldet')
    );

    RETURN TRUE;
END;
$$;

-- Admin: Benachrichtigungen laden
CREATE OR REPLACE FUNCTION admin_get_notifications(
    p_unread_only BOOLEAN DEFAULT FALSE,
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    type VARCHAR(50),
    content_type VARCHAR(20),
    content_id UUID,
    user_id UUID,
    poi_id VARCHAR(100),
    target_id VARCHAR(100),
    message TEXT,
    is_read BOOLEAN,
    created_at TIMESTAMPTZ,
    user_name VARCHAR(100),
    user_avatar TEXT
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
    SELECT
        n.id,
        n.type,
        n.content_type,
        n.content_id,
        n.user_id,
        n.poi_id,
        n.target_id,
        n.message,
        n.is_read,
        n.created_at,
        p.display_name AS user_name,
        p.avatar_url AS user_avatar
    FROM public.admin_notifications n
    LEFT JOIN public.user_profiles p ON p.id = n.user_id
    WHERE
        auth.uid() IN (SELECT user_id FROM public.admins)
        AND (NOT p_unread_only OR n.is_read = FALSE)
    ORDER BY n.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
$$;

-- Admin: Benachrichtigung als gelesen markieren
CREATE OR REPLACE FUNCTION admin_mark_notification_read(p_notification_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    IF auth.uid() NOT IN (SELECT user_id FROM public.admins) THEN
        RAISE EXCEPTION 'Not authorized';
    END IF;

    UPDATE public.admin_notifications SET is_read = TRUE WHERE id = p_notification_id;
    RETURN FOUND;
END;
$$;

-- Admin: Alle Benachrichtigungen als gelesen markieren
CREATE OR REPLACE FUNCTION admin_mark_all_notifications_read()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_count INTEGER;
BEGIN
    IF auth.uid() NOT IN (SELECT user_id FROM public.admins) THEN
        RAISE EXCEPTION 'Not authorized';
    END IF;

    UPDATE public.admin_notifications SET is_read = TRUE WHERE is_read = FALSE;
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RETURN v_count;
END;
$$;

-- Admin: Inhalt loeschen
CREATE OR REPLACE FUNCTION admin_delete_content(
    p_content_type VARCHAR(20),
    p_content_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_poi_id VARCHAR(100);
BEGIN
    IF auth.uid() NOT IN (SELECT user_id FROM public.admins) THEN
        RAISE EXCEPTION 'Not authorized';
    END IF;

    IF p_content_type = 'photo' THEN
        SELECT poi_id INTO v_poi_id FROM public.poi_photos WHERE id = p_content_id;
        DELETE FROM public.poi_photos WHERE id = p_content_id;
    ELSIF p_content_type = 'review' THEN
        SELECT poi_id INTO v_poi_id FROM public.poi_reviews WHERE id = p_content_id;
        DELETE FROM public.poi_reviews WHERE id = p_content_id;
    ELSIF p_content_type = 'comment' THEN
        DELETE FROM public.comments WHERE id = p_content_id;
    END IF;

    -- Update stats if POI
    IF v_poi_id IS NOT NULL THEN
        PERFORM update_poi_stats(v_poi_id);
    END IF;

    -- Remove related notifications
    DELETE FROM public.admin_notifications WHERE content_id = p_content_id;

    RETURN FOUND;
END;
$$;

-- Admin: Gemeldete Inhalte laden
CREATE OR REPLACE FUNCTION admin_get_flagged_content(
    p_content_type VARCHAR(20) DEFAULT NULL,
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    content_type VARCHAR(20),
    content_id UUID,
    poi_id VARCHAR(100),
    user_id UUID,
    user_name VARCHAR(100),
    content_preview TEXT,
    created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
BEGIN
    IF auth.uid() NOT IN (SELECT user_id FROM public.admins) THEN
        RAISE EXCEPTION 'Not authorized';
    END IF;

    RETURN QUERY
    SELECT * FROM (
        -- Photos
        SELECT
            'photo'::VARCHAR(20) AS content_type,
            ph.id AS content_id,
            ph.poi_id,
            ph.user_id,
            p.display_name AS user_name,
            ph.caption AS content_preview,
            ph.created_at
        FROM public.poi_photos ph
        LEFT JOIN public.user_profiles p ON p.id = ph.user_id
        WHERE ph.is_flagged = TRUE
            AND (p_content_type IS NULL OR p_content_type = 'photo')

        UNION ALL

        -- Reviews
        SELECT
            'review'::VARCHAR(20),
            r.id,
            r.poi_id,
            r.user_id,
            p.display_name,
            LEFT(r.review_text, 100),
            r.created_at
        FROM public.poi_reviews r
        LEFT JOIN public.user_profiles p ON p.id = r.user_id
        WHERE r.is_flagged = TRUE
            AND (p_content_type IS NULL OR p_content_type = 'review')

        UNION ALL

        -- Comments
        SELECT
            'comment'::VARCHAR(20),
            c.id,
            CASE WHEN c.target_type = 'poi' THEN c.target_id ELSE NULL END,
            c.user_id,
            p.display_name,
            LEFT(c.content, 100),
            c.created_at
        FROM public.comments c
        LEFT JOIN public.user_profiles p ON p.id = c.user_id
        WHERE c.is_flagged = TRUE
            AND (p_content_type IS NULL OR p_content_type = 'comment')
    ) AS flagged
    ORDER BY created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$;

-- Reviews mit Hilfreich-Status laden
CREATE OR REPLACE FUNCTION get_poi_reviews(
    p_poi_id VARCHAR(100),
    p_limit INTEGER DEFAULT 20,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    poi_id VARCHAR(100),
    user_id UUID,
    rating INTEGER,
    review_text TEXT,
    visit_date DATE,
    helpful_count INTEGER,
    is_flagged BOOLEAN,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    author_name VARCHAR(100),
    author_avatar TEXT,
    is_helpful_by_me BOOLEAN
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
    SELECT
        r.id,
        r.poi_id,
        r.user_id,
        r.rating,
        r.review_text,
        r.visit_date,
        r.helpful_count,
        r.is_flagged,
        r.created_at,
        r.updated_at,
        p.display_name AS author_name,
        p.avatar_url AS author_avatar,
        EXISTS(
            SELECT 1 FROM public.review_helpful_votes v
            WHERE v.review_id = r.id AND v.user_id = auth.uid()
        ) AS is_helpful_by_me
    FROM public.poi_reviews r
    LEFT JOIN public.user_profiles p ON p.id = r.user_id
    WHERE r.poi_id = p_poi_id
        AND r.is_flagged = FALSE
    ORDER BY r.helpful_count DESC, r.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
$$;

-- Photos mit Author laden
CREATE OR REPLACE FUNCTION get_poi_photos(
    p_poi_id VARCHAR(100),
    p_limit INTEGER DEFAULT 20,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    poi_id VARCHAR(100),
    user_id UUID,
    storage_path TEXT,
    thumbnail_path TEXT,
    caption VARCHAR(500),
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
        ph.poi_id,
        ph.user_id,
        ph.storage_path,
        ph.thumbnail_path,
        ph.caption,
        ph.likes_count,
        ph.created_at,
        p.display_name AS author_name,
        p.avatar_url AS author_avatar
    FROM public.poi_photos ph
    LEFT JOIN public.user_profiles p ON p.id = ph.user_id
    WHERE ph.poi_id = p_poi_id
        AND ph.is_flagged = FALSE
    ORDER BY ph.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
$$;

-- Comments mit Author laden
CREATE OR REPLACE FUNCTION get_comments(
    p_target_type VARCHAR(20),
    p_target_id VARCHAR(100),
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    target_type VARCHAR(20),
    target_id VARCHAR(100),
    parent_id UUID,
    content TEXT,
    likes_count INTEGER,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    author_name VARCHAR(100),
    author_avatar TEXT,
    reply_count BIGINT
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
    SELECT
        c.id,
        c.user_id,
        c.target_type,
        c.target_id,
        c.parent_id,
        c.content,
        c.likes_count,
        c.created_at,
        c.updated_at,
        p.display_name AS author_name,
        p.avatar_url AS author_avatar,
        (SELECT COUNT(*) FROM public.comments r WHERE r.parent_id = c.id AND r.is_flagged = FALSE) AS reply_count
    FROM public.comments c
    LEFT JOIN public.user_profiles p ON p.id = c.user_id
    WHERE c.target_type = p_target_type
        AND c.target_id = p_target_id
        AND c.parent_id IS NULL
        AND c.is_flagged = FALSE
    ORDER BY c.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
$$;

-- Antworten zu einem Kommentar laden
CREATE OR REPLACE FUNCTION get_comment_replies(
    p_parent_id UUID,
    p_limit INTEGER DEFAULT 50
)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    target_type VARCHAR(20),
    target_id VARCHAR(100),
    parent_id UUID,
    content TEXT,
    likes_count INTEGER,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    author_name VARCHAR(100),
    author_avatar TEXT
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
    SELECT
        c.id,
        c.user_id,
        c.target_type,
        c.target_id,
        c.parent_id,
        c.content,
        c.likes_count,
        c.created_at,
        c.updated_at,
        p.display_name AS author_name,
        p.avatar_url AS author_avatar
    FROM public.comments c
    LEFT JOIN public.user_profiles p ON p.id = c.user_id
    WHERE c.parent_id = p_parent_id
        AND c.is_flagged = FALSE
    ORDER BY c.created_at ASC
    LIMIT p_limit;
$$;

-- ============================================
-- FERTIG!
-- ============================================
-- Vergiss nicht, den Storage Bucket 'poi-photos' manuell zu erstellen!
-- Dashboard > Storage > New Bucket > Name: poi-photos, Public: true
