-- MapAB Supabase Schema
-- Migration 013: admin_notifications um trip_photo erweitern

ALTER TABLE public.admin_notifications
DROP CONSTRAINT IF EXISTS admin_notifications_content_type_check;

ALTER TABLE public.admin_notifications
ADD CONSTRAINT admin_notifications_content_type_check
CHECK (content_type IN ('photo', 'trip_photo', 'review', 'comment'));

-- Admin: Inhalt loeschen (inkl. trip_photo)
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
    v_deleted BOOLEAN := FALSE;
BEGIN
    IF auth.uid() NOT IN (SELECT user_id FROM public.admins) THEN
        RAISE EXCEPTION 'Not authorized';
    END IF;

    IF p_content_type = 'photo' THEN
        SELECT poi_id INTO v_poi_id FROM public.poi_photos WHERE id = p_content_id;
        DELETE FROM public.poi_photos WHERE id = p_content_id;
        v_deleted := FOUND;
    ELSIF p_content_type = 'trip_photo' THEN
        DELETE FROM public.trip_photos WHERE id = p_content_id;
        v_deleted := FOUND;
    ELSIF p_content_type = 'review' THEN
        SELECT poi_id INTO v_poi_id FROM public.poi_reviews WHERE id = p_content_id;
        DELETE FROM public.poi_reviews WHERE id = p_content_id;
        v_deleted := FOUND;
    ELSIF p_content_type = 'comment' THEN
        DELETE FROM public.comments WHERE id = p_content_id;
        v_deleted := FOUND;
    END IF;

    -- Update stats if POI
    IF v_poi_id IS NOT NULL THEN
        PERFORM update_poi_stats(v_poi_id);
    END IF;

    -- Remove related notifications
    DELETE FROM public.admin_notifications WHERE content_id = p_content_id;

    RETURN v_deleted;
END;
$$;
