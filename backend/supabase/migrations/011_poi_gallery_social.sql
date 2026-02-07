-- MapAB Supabase Schema
-- Migration 011: Public POI Gallery + Likes + Voting + Reputation
-- Voraussetzung: 006, 007, 008

-- ============================================
-- TABLES
-- ============================================

CREATE TABLE IF NOT EXISTS public.poi_posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    poi_id VARCHAR(100) NOT NULL,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title VARCHAR(180) NOT NULL,
    content TEXT,
    categories TEXT[] NOT NULL DEFAULT '{}',
    is_must_see BOOLEAN NOT NULL DEFAULT FALSE,
    cover_photo_path TEXT,
    is_hidden BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.poi_post_likes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID NOT NULL REFERENCES public.poi_posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(post_id, user_id)
);

CREATE TABLE IF NOT EXISTS public.poi_votes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID NOT NULL REFERENCES public.poi_posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    vote SMALLINT NOT NULL CHECK (vote IN (-1, 1)),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(post_id, user_id)
);

CREATE TABLE IF NOT EXISTS public.user_reputation (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    points INTEGER NOT NULL DEFAULT 0,
    level INTEGER NOT NULL DEFAULT 1,
    badge VARCHAR(64) NOT NULL DEFAULT 'Explorer',
    weekly_points INTEGER NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_poi_posts_created ON public.poi_posts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_poi_posts_poi ON public.poi_posts(poi_id);
CREATE INDEX IF NOT EXISTS idx_poi_post_likes_post ON public.poi_post_likes(post_id);
CREATE INDEX IF NOT EXISTS idx_poi_votes_post ON public.poi_votes(post_id);
CREATE INDEX IF NOT EXISTS idx_user_reputation_points ON public.user_reputation(points DESC);

-- ============================================
-- RLS
-- ============================================

ALTER TABLE public.poi_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.poi_post_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.poi_votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_reputation ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public read poi posts" ON public.poi_posts;
CREATE POLICY "Public read poi posts" ON public.poi_posts
    FOR SELECT USING (is_hidden = FALSE);

DROP POLICY IF EXISTS "Auth insert poi posts" ON public.poi_posts;
CREATE POLICY "Auth insert poi posts" ON public.poi_posts
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Owner or admin update poi posts" ON public.poi_posts;
CREATE POLICY "Owner or admin update poi posts" ON public.poi_posts
    FOR UPDATE USING (
        auth.uid() = user_id OR auth.uid() IN (SELECT user_id FROM public.admins)
    );

DROP POLICY IF EXISTS "Owner or admin delete poi posts" ON public.poi_posts;
CREATE POLICY "Owner or admin delete poi posts" ON public.poi_posts
    FOR DELETE USING (
        auth.uid() = user_id OR auth.uid() IN (SELECT user_id FROM public.admins)
    );

DROP POLICY IF EXISTS "Public read poi post likes" ON public.poi_post_likes;
CREATE POLICY "Public read poi post likes" ON public.poi_post_likes
    FOR SELECT USING (TRUE);

DROP POLICY IF EXISTS "Auth manage own poi post likes" ON public.poi_post_likes;
CREATE POLICY "Auth manage own poi post likes" ON public.poi_post_likes
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Public read poi votes" ON public.poi_votes;
CREATE POLICY "Public read poi votes" ON public.poi_votes
    FOR SELECT USING (TRUE);

DROP POLICY IF EXISTS "Auth manage own poi votes" ON public.poi_votes;
CREATE POLICY "Auth manage own poi votes" ON public.poi_votes
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Public read user reputation" ON public.user_reputation;
CREATE POLICY "Public read user reputation" ON public.user_reputation
    FOR SELECT USING (TRUE);

DROP POLICY IF EXISTS "Owner update user reputation" ON public.user_reputation;
CREATE POLICY "Owner update user reputation" ON public.user_reputation
    FOR UPDATE USING (auth.uid() = user_id);

-- ============================================
-- VIEW
-- ============================================

CREATE OR REPLACE VIEW public.poi_social_stats_view AS
SELECT
    p.id,
    p.poi_id,
    p.user_id,
    p.title,
    p.content,
    p.categories,
    p.is_must_see,
    p.cover_photo_path,
    p.created_at,
    COALESCE(ps.avg_rating, 0) AS rating_avg,
    COALESCE(ps.review_count, 0) AS rating_count,
    COALESCE(ps.photo_count, 0) AS photo_count,
    COALESCE(ps.comment_count, 0) AS comment_count,
    COALESCE(pl.likes_count, 0) AS likes_count,
    COALESCE(v.vote_score, 0) AS vote_score,
    (
      (COALESCE(ps.avg_rating, 0) * LN(COALESCE(ps.review_count, 0) + 1)) * 0.55 +
      (COALESCE(v.vote_score, 0)) * 0.20 +
      (LN(COALESCE(ps.photo_count, 0) + 1)) * 0.15 +
      (1.0 / (1.0 + (EXTRACT(EPOCH FROM (NOW() - p.created_at)) / 86400.0))) * 0.10
    )::NUMERIC(10,4) AS trending_score
FROM public.poi_posts p
LEFT JOIN public.poi_stats ps ON ps.poi_id = p.poi_id
LEFT JOIN (
    SELECT post_id, COUNT(*)::INT AS likes_count
    FROM public.poi_post_likes
    GROUP BY post_id
) pl ON pl.post_id = p.id
LEFT JOIN (
    SELECT post_id, COALESCE(SUM(vote), 0)::INT AS vote_score
    FROM public.poi_votes
    GROUP BY post_id
) v ON v.post_id = p.id
WHERE p.is_hidden = FALSE;

-- ============================================
-- RPCs
-- ============================================

CREATE OR REPLACE FUNCTION public.search_public_pois(
    p_query TEXT DEFAULT NULL,
    p_categories TEXT[] DEFAULT NULL,
    p_must_see_only BOOLEAN DEFAULT NULL,
    p_sort_by TEXT DEFAULT 'trending',
    p_limit INTEGER DEFAULT 20,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    poi_id VARCHAR(100),
    user_id UUID,
    title VARCHAR(180),
    content TEXT,
    categories TEXT[],
    is_must_see BOOLEAN,
    cover_photo_path TEXT,
    rating_avg NUMERIC,
    rating_count INTEGER,
    vote_score INTEGER,
    likes_count INTEGER,
    comment_count INTEGER,
    photo_count INTEGER,
    author_name VARCHAR(100),
    author_avatar TEXT,
    is_liked_by_me BOOLEAN,
    created_at TIMESTAMPTZ
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
    SELECT
        s.id, s.poi_id, s.user_id, s.title, s.content, s.categories, s.is_must_see,
        s.cover_photo_path, s.rating_avg, s.rating_count, s.vote_score, s.likes_count,
        s.comment_count, s.photo_count,
        up.display_name AS author_name,
        up.avatar_url AS author_avatar,
        EXISTS(
            SELECT 1 FROM public.poi_post_likes l
            WHERE l.post_id = s.id AND l.user_id = auth.uid()
        ) AS is_liked_by_me,
        s.created_at
    FROM public.poi_social_stats_view s
    LEFT JOIN public.user_profiles up ON up.id = s.user_id
    WHERE
      (p_query IS NULL OR s.title ILIKE '%' || p_query || '%' OR COALESCE(s.content, '') ILIKE '%' || p_query || '%')
      AND (p_categories IS NULL OR s.categories && p_categories)
      AND (p_must_see_only IS NULL OR s.is_must_see = p_must_see_only)
    ORDER BY
      CASE WHEN p_sort_by = 'recent' THEN s.created_at END DESC,
      CASE WHEN p_sort_by = 'top_rated' THEN s.rating_avg END DESC,
      CASE WHEN p_sort_by = 'top_rated' THEN s.rating_count END DESC,
      CASE WHEN p_sort_by = 'trending' THEN s.trending_score END DESC,
      s.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
$$;

CREATE OR REPLACE FUNCTION public.get_public_poi(p_post_id UUID)
RETURNS TABLE (
    id UUID,
    poi_id VARCHAR(100),
    user_id UUID,
    title VARCHAR(180),
    content TEXT,
    categories TEXT[],
    is_must_see BOOLEAN,
    cover_photo_path TEXT,
    rating_avg NUMERIC,
    rating_count INTEGER,
    vote_score INTEGER,
    likes_count INTEGER,
    comment_count INTEGER,
    photo_count INTEGER,
    author_name VARCHAR(100),
    author_avatar TEXT,
    is_liked_by_me BOOLEAN,
    created_at TIMESTAMPTZ
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
    SELECT * FROM public.search_public_pois(
      NULL, NULL, NULL, 'trending', 1, 0
    ) WHERE id = p_post_id;
$$;

CREATE OR REPLACE FUNCTION public.like_poi_post(p_post_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user UUID := auth.uid();
BEGIN
    IF v_user IS NULL THEN
      RAISE EXCEPTION 'Not authenticated';
    END IF;

    INSERT INTO public.poi_post_likes(post_id, user_id)
    VALUES (p_post_id, v_user)
    ON CONFLICT (post_id, user_id) DO NOTHING;

    RETURN TRUE;
END;
$$;

CREATE OR REPLACE FUNCTION public.unlike_poi_post(p_post_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user UUID := auth.uid();
BEGIN
    IF v_user IS NULL THEN
      RAISE EXCEPTION 'Not authenticated';
    END IF;

    DELETE FROM public.poi_post_likes
    WHERE post_id = p_post_id AND user_id = v_user;

    RETURN TRUE;
END;
$$;

CREATE OR REPLACE FUNCTION public.vote_poi(p_post_id UUID, p_vote SMALLINT)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user UUID := auth.uid();
    v_score INTEGER;
BEGIN
    IF v_user IS NULL THEN
      RAISE EXCEPTION 'Not authenticated';
    END IF;
    IF p_vote NOT IN (-1, 1) THEN
      RAISE EXCEPTION 'Vote must be -1 or 1';
    END IF;

    INSERT INTO public.poi_votes(post_id, user_id, vote)
    VALUES (p_post_id, v_user, p_vote)
    ON CONFLICT (post_id, user_id) DO UPDATE SET vote = EXCLUDED.vote;

    SELECT COALESCE(SUM(vote), 0)::INT INTO v_score
    FROM public.poi_votes
    WHERE post_id = p_post_id;

    RETURN v_score;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_top_rated_pois(p_limit INTEGER DEFAULT 20)
RETURNS TABLE (
    id UUID,
    poi_id VARCHAR(100),
    title VARCHAR(180),
    rating_avg NUMERIC,
    rating_count INTEGER,
    vote_score INTEGER,
    trending_score NUMERIC
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
    SELECT id, poi_id, title, rating_avg, rating_count, vote_score, trending_score
    FROM public.poi_social_stats_view
    ORDER BY rating_avg DESC, rating_count DESC, trending_score DESC
    LIMIT p_limit;
$$;
