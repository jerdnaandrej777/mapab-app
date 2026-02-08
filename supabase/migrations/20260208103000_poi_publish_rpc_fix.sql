-- MapAB Supabase Schema
-- Migration: Publish RPC for POI posts + get_public_poi fix
-- Diese Migration behebt den Fehler:
-- PGRST202 ... Could not find the function public.publish_poi_post(...)

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
    WHERE s.id = p_post_id
    LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.publish_poi_post(
    p_poi_id VARCHAR(100),
    p_title VARCHAR(180),
    p_content TEXT DEFAULT NULL,
    p_categories TEXT[] DEFAULT '{}',
    p_is_must_see BOOLEAN DEFAULT FALSE,
    p_cover_photo_path TEXT DEFAULT NULL
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
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user UUID := auth.uid();
    v_post_id UUID;
BEGIN
    IF v_user IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    IF p_poi_id IS NULL OR LENGTH(BTRIM(p_poi_id)) = 0 THEN
        RAISE EXCEPTION 'poi_id is required';
    END IF;

    IF p_title IS NULL OR LENGTH(BTRIM(p_title)) < 3 THEN
        RAISE EXCEPTION 'title must be at least 3 characters';
    END IF;

    INSERT INTO public.poi_posts (
        poi_id,
        user_id,
        title,
        content,
        categories,
        is_must_see,
        cover_photo_path
    )
    VALUES (
        BTRIM(p_poi_id),
        v_user,
        BTRIM(p_title),
        NULLIF(BTRIM(COALESCE(p_content, '')), ''),
        COALESCE(p_categories, '{}'),
        COALESCE(p_is_must_see, FALSE),
        NULLIF(BTRIM(COALESCE(p_cover_photo_path, '')), '')
    )
    RETURNING poi_posts.id INTO v_post_id;

    RETURN QUERY
    SELECT * FROM public.get_public_poi(v_post_id);
END;
$$;
