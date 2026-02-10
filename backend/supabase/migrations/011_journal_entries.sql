-- MapAB Supabase Schema
-- Migration 011: Journal Entries Cloud Storage
-- Erstellt private Journal-Einträge-Tabelle mit RLS
-- WICHTIG: Führe dieses Script im Supabase SQL Editor aus!

-- ============================================
-- SCHRITT 1: JOURNAL ENTRIES TABELLE
-- ============================================

-- UUID Extension (falls noch nicht vorhanden)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Haupttabelle für Journal-Einträge (PRIVATE, nur für User sichtbar)
CREATE TABLE public.journal_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    trip_id TEXT NOT NULL,
    trip_name TEXT NOT NULL,
    poi_id TEXT,
    poi_name TEXT,
    note TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    day_number INTEGER,
    has_photo BOOLEAN NOT NULL DEFAULT FALSE,
    photo_storage_path TEXT,           -- Supabase Storage URL
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    synced_at TIMESTAMPTZ,             -- Last cloud sync timestamp

    -- Constraints
    CONSTRAINT valid_day_number CHECK (day_number IS NULL OR day_number >= 1),
    CONSTRAINT valid_coordinates CHECK (
        (latitude IS NULL AND longitude IS NULL) OR
        (latitude IS NOT NULL AND longitude IS NOT NULL)
    )
);

-- ============================================
-- SCHRITT 2: INDEXES FÜR PERFORMANCE
-- ============================================

-- Index für User + Trip Lookup (häufigste Query)
CREATE INDEX idx_journal_user_trip ON public.journal_entries(user_id, trip_id);

-- Index für chronologische Sortierung
CREATE INDEX idx_journal_created ON public.journal_entries(user_id, created_at DESC);

-- Index für Tages-Filter
CREATE INDEX idx_journal_day ON public.journal_entries(user_id, trip_id, day_number) WHERE day_number IS NOT NULL;

-- Index für Photo-Filter
CREATE INDEX idx_journal_photos ON public.journal_entries(user_id) WHERE has_photo = TRUE;

-- ============================================
-- SCHRITT 3: TRIGGER FÜR UPDATED_AT
-- ============================================

-- Trigger Function (falls noch nicht existiert)
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger für journal_entries
CREATE TRIGGER trigger_update_journal_entries_updated_at
    BEFORE UPDATE ON public.journal_entries
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- SCHRITT 4: ROW LEVEL SECURITY (RLS)
-- ============================================

ALTER TABLE public.journal_entries ENABLE ROW LEVEL SECURITY;

-- Policy: Nur Owner kann eigene Einträge sehen
CREATE POLICY "Users can view own journal entries"
    ON public.journal_entries
    FOR SELECT
    USING (auth.uid() = user_id);

-- Policy: Nur Owner kann eigene Einträge erstellen
CREATE POLICY "Users can insert own journal entries"
    ON public.journal_entries
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Policy: Nur Owner kann eigene Einträge bearbeiten
CREATE POLICY "Users can update own journal entries"
    ON public.journal_entries
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Policy: Nur Owner kann eigene Einträge löschen
CREATE POLICY "Users can delete own journal entries"
    ON public.journal_entries
    FOR DELETE
    USING (auth.uid() = user_id);

-- ============================================
-- SCHRITT 5: RPC FUNCTIONS
-- ============================================

-- Function: Lade alle Journals eines Users (Trip-Übersicht)
CREATE OR REPLACE FUNCTION get_user_journals(p_user_id UUID)
RETURNS TABLE(
    trip_id TEXT,
    trip_name TEXT,
    entry_count BIGINT,
    photo_count BIGINT,
    last_entry_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Nur eigene Journals abrufen (zusätzliche Sicherheit)
    IF p_user_id != auth.uid() THEN
        RAISE EXCEPTION 'Unauthorized: You can only access your own journals';
    END IF;

    RETURN QUERY
    SELECT
        je.trip_id,
        MAX(je.trip_name) as trip_name,
        COUNT(*) as entry_count,
        COUNT(*) FILTER (WHERE je.has_photo = TRUE) as photo_count,
        MAX(je.created_at) as last_entry_at
    FROM public.journal_entries je
    WHERE je.user_id = p_user_id
    GROUP BY je.trip_id
    ORDER BY last_entry_at DESC;
END;
$$;

-- Function: Lade alle Einträge eines Trips
CREATE OR REPLACE FUNCTION get_journal_entries_for_trip(
    p_user_id UUID,
    p_trip_id TEXT
)
RETURNS SETOF public.journal_entries
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Nur eigene Entries abrufen (zusätzliche Sicherheit)
    IF p_user_id != auth.uid() THEN
        RAISE EXCEPTION 'Unauthorized: You can only access your own entries';
    END IF;

    RETURN QUERY
    SELECT *
    FROM public.journal_entries
    WHERE user_id = p_user_id AND trip_id = p_trip_id
    ORDER BY created_at DESC;
END;
$$;

-- Function: Lösche komplettes Journal (alle Entries eines Trips)
CREATE OR REPLACE FUNCTION delete_journal(
    p_user_id UUID,
    p_trip_id TEXT
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_deleted_count INTEGER;
BEGIN
    -- Nur eigene Entries löschen (zusätzliche Sicherheit)
    IF p_user_id != auth.uid() THEN
        RAISE EXCEPTION 'Unauthorized: You can only delete your own journals';
    END IF;

    -- Lösche alle Entries des Trips
    DELETE FROM public.journal_entries
    WHERE user_id = p_user_id AND trip_id = p_trip_id;

    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;

    RETURN v_deleted_count;
END;
$$;

-- ============================================
-- STORAGE BUCKET SETUP (via Supabase Dashboard)
-- ============================================

-- WICHTIG: Die folgenden Schritte müssen manuell im Supabase Dashboard ausgeführt werden:
--
-- 1. Storage Bucket erstellen:
--    - Name: "journal-photos"
--    - Public: FALSE (privater Bucket)
--    - Allowed MIME types: image/jpeg, image/jpg, image/png
--    - Max file size: 10 MB
--
-- 2. Storage RLS Policies erstellen (via Dashboard SQL Editor):

-- Policy: Upload nur für eigene Fotos
-- CREATE POLICY "Users can upload own journal photos"
--   ON storage.objects FOR INSERT
--   WITH CHECK (
--     bucket_id = 'journal-photos'
--     AND auth.uid()::text = (storage.foldername(name))[1]
--   );

-- Policy: Download nur für eigene Fotos
-- CREATE POLICY "Users can view own journal photos"
--   ON storage.objects FOR SELECT
--   USING (
--     bucket_id = 'journal-photos'
--     AND auth.uid()::text = (storage.foldername(name))[1]
--   );

-- Policy: Löschen nur für eigene Fotos
-- CREATE POLICY "Users can delete own journal photos"
--   ON storage.objects FOR DELETE
--   USING (
--     bucket_id = 'journal-photos'
--     AND auth.uid()::text = (storage.foldername(name))[1]
--   );

-- Pfad-Struktur: journal-photos/{user_id}/{trip_id}/{entry_id}.jpg

-- ============================================
-- FERTIG!
-- ============================================
-- Wenn dieses Script ohne Fehler durchläuft,
-- ist die Journal-Cloud-Storage korrekt eingerichtet.
--
-- Nächste Schritte:
-- 1. Storage Bucket "journal-photos" im Dashboard erstellen
-- 2. Storage RLS Policies im Dashboard SQL Editor ausführen
-- 3. Flutter Code deployen (journal_cloud_repo.dart)
