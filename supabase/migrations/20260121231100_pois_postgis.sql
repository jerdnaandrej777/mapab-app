-- MapAB Supabase Schema
-- Migration 002: POIs mit PostGIS
-- Stufe 1: POI-System Migration zu Supabase PostGIS

-- ============================================
-- EXTENSIONS
-- ============================================

CREATE EXTENSION IF NOT EXISTS "postgis";

-- ============================================
-- POIS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS public.pois (
    -- Primaerschluessel: kompatibel mit bestehenden IDs (de-1, wiki-12345, osm-node-67890)
    id VARCHAR(100) PRIMARY KEY,

    -- Name des POI
    name VARCHAR(300) NOT NULL,

    -- PostGIS Geo-Spalte fuer ST_DWithin Queries
    location GEOGRAPHY(POINT, 4326) NOT NULL,

    -- Denormalisierte Koordinaten fuer schnellen Zugriff ohne PostGIS-Funktionen
    latitude DECIMAL(10,7) NOT NULL,
    longitude DECIMAL(10,7) NOT NULL,

    -- Kategorie (castle, nature, museum, viewpoint, lake, coast, park, city,
    --            activity, hotel, restaurant, unesco, church, monument, attraction)
    category_id VARCHAR(50) NOT NULL DEFAULT 'attraction',

    -- Basis-Score (0-100)
    score INTEGER NOT NULL DEFAULT 50 CHECK (score >= 0 AND score <= 100),

    -- Medien
    image_url TEXT,
    thumbnail_url TEXT,

    -- Beschreibung
    description TEXT,

    -- Curated/Wikipedia Flags
    is_curated BOOLEAN NOT NULL DEFAULT FALSE,
    has_wikipedia BOOLEAN NOT NULL DEFAULT FALSE,
    wikipedia_title VARCHAR(500),

    -- Tags (z.B. 'unesco', 'indoor', 'historic')
    tags TEXT[] DEFAULT '{}',

    -- Wikidata
    wikidata_id VARCHAR(50),
    wikidata_description TEXT,
    has_wikidata_data BOOLEAN NOT NULL DEFAULT FALSE,

    -- Kontakt
    phone VARCHAR(100),
    email VARCHAR(200),
    website TEXT,
    opening_hours VARCHAR(500),

    -- Enrichment-Felder
    founded_year INTEGER,
    architecture_style VARCHAR(200),
    is_enriched BOOLEAN NOT NULL DEFAULT FALSE,

    -- Tracking: Woher kommt der POI?
    source VARCHAR(50) NOT NULL DEFAULT 'unknown'
        CHECK (source IN ('curated', 'wikipedia', 'overpass', 'user', 'unknown')),

    -- Wer hat beigetragen / angereichert?
    contributed_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    enriched_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,

    -- Enrichment-Versionierung (inkrementiert bei jedem Update)
    enrichment_version INTEGER NOT NULL DEFAULT 0,
    last_enriched_at TIMESTAMPTZ,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Trigger fuer updated_at (wiederverwendet aus Migration 001)
CREATE TRIGGER update_pois_updated_at
    BEFORE UPDATE ON public.pois
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- INDEXES
-- ============================================

-- Spatial-Index fuer Geo-Queries (ST_DWithin, ST_Within)
CREATE INDEX idx_pois_location ON public.pois USING GIST (location);

-- Kategorie + Score fuer gefilterte Abfragen
CREATE INDEX idx_pois_category_score ON public.pois (category_id, score DESC);

-- Score fuer Qualitaets-Sortierung
CREATE INDEX idx_pois_score ON public.pois (score DESC);

-- Unenriched POIs finden (Partial Index)
CREATE INDEX idx_pois_unenriched ON public.pois (created_at)
    WHERE is_enriched = FALSE;

-- Curated POIs
CREATE INDEX idx_pois_curated ON public.pois (score DESC)
    WHERE is_curated = TRUE;

-- ============================================
-- ROW LEVEL SECURITY
-- ============================================

ALTER TABLE public.pois ENABLE ROW LEVEL SECURITY;

-- SELECT: Oeffentlich (auch anon) - POIs sind Public Data
CREATE POLICY "POIs are publicly readable" ON public.pois
    FOR SELECT
    USING (TRUE);

-- INSERT: Nur authentifizierte User (fuer Enrichment-Upload)
CREATE POLICY "Authenticated users can insert POIs" ON public.pois
    FOR INSERT
    WITH CHECK (auth.role() = 'authenticated');

-- UPDATE: Nur authentifizierte User (fuer Enrichment-Upload)
CREATE POLICY "Authenticated users can update POIs" ON public.pois
    FOR UPDATE
    USING (auth.role() = 'authenticated');

-- DELETE: Keine Client-Policy (nur service_role kann loeschen)

-- ============================================
-- RPC FUNCTIONS
-- ============================================

-- Sucht POIs in einem Radius um einen Punkt
-- Fuer: loadPOIsInRadius() Aufrufe (Trip-Gen, POI-Liste, AI Trips)
CREATE OR REPLACE FUNCTION search_pois_in_radius(
    p_lat DOUBLE PRECISION,
    p_lng DOUBLE PRECISION,
    p_radius_km DOUBLE PRECISION,
    p_category_ids TEXT[] DEFAULT NULL,
    p_min_score INTEGER DEFAULT 35,
    p_limit INTEGER DEFAULT 200
)
RETURNS SETOF public.pois
LANGUAGE sql
STABLE
AS $$
    SELECT *
    FROM public.pois
    WHERE ST_DWithin(
        location,
        ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography,
        p_radius_km * 1000  -- km zu Meter
    )
    AND score >= p_min_score
    AND (p_category_ids IS NULL OR category_id = ANY(p_category_ids))
    ORDER BY score DESC
    LIMIT p_limit;
$$;

-- Sucht POIs innerhalb einer Bounding Box
-- Fuer: loadPOIsInBounds() Aufrufe (Korridor-Browser, Route-POIs)
CREATE OR REPLACE FUNCTION search_pois_in_bounds(
    p_sw_lat DOUBLE PRECISION,
    p_sw_lng DOUBLE PRECISION,
    p_ne_lat DOUBLE PRECISION,
    p_ne_lng DOUBLE PRECISION,
    p_category_ids TEXT[] DEFAULT NULL,
    p_min_score INTEGER DEFAULT 35,
    p_limit INTEGER DEFAULT 200
)
RETURNS SETOF public.pois
LANGUAGE sql
STABLE
AS $$
    SELECT *
    FROM public.pois
    WHERE ST_Within(
        location::geometry,
        ST_MakeEnvelope(p_sw_lng, p_sw_lat, p_ne_lng, p_ne_lat, 4326)
    )
    AND score >= p_min_score
    AND (p_category_ids IS NULL OR category_id = ANY(p_category_ids))
    ORDER BY score DESC
    LIMIT p_limit;
$$;

-- Upsert: POI einfuegen oder Enrichment-Felder mergen
-- Score: GREATEST(existing, new) - hoechster Score gewinnt
-- Tags: Union (alte + neue, dedupliziert)
-- Leere Felder: COALESCE (nur leere Felder ueberschreiben)
CREATE OR REPLACE FUNCTION upsert_poi(
    p_id VARCHAR(100),
    p_name VARCHAR(300),
    p_latitude DOUBLE PRECISION,
    p_longitude DOUBLE PRECISION,
    p_category_id VARCHAR(50) DEFAULT 'attraction',
    p_score INTEGER DEFAULT 50,
    p_image_url TEXT DEFAULT NULL,
    p_thumbnail_url TEXT DEFAULT NULL,
    p_description TEXT DEFAULT NULL,
    p_is_curated BOOLEAN DEFAULT FALSE,
    p_has_wikipedia BOOLEAN DEFAULT FALSE,
    p_wikipedia_title VARCHAR(500) DEFAULT NULL,
    p_tags TEXT[] DEFAULT '{}',
    p_wikidata_id VARCHAR(50) DEFAULT NULL,
    p_wikidata_description TEXT DEFAULT NULL,
    p_has_wikidata_data BOOLEAN DEFAULT FALSE,
    p_phone VARCHAR(100) DEFAULT NULL,
    p_email VARCHAR(200) DEFAULT NULL,
    p_website TEXT DEFAULT NULL,
    p_opening_hours VARCHAR(500) DEFAULT NULL,
    p_founded_year INTEGER DEFAULT NULL,
    p_architecture_style VARCHAR(200) DEFAULT NULL,
    p_is_enriched BOOLEAN DEFAULT FALSE,
    p_source VARCHAR(50) DEFAULT 'unknown',
    p_contributed_by UUID DEFAULT NULL
)
RETURNS public.pois
LANGUAGE plpgsql
AS $$
DECLARE
    v_result public.pois;
BEGIN
    INSERT INTO public.pois (
        id, name, location, latitude, longitude,
        category_id, score, image_url, thumbnail_url, description,
        is_curated, has_wikipedia, wikipedia_title, tags,
        wikidata_id, wikidata_description, has_wikidata_data,
        phone, email, website, opening_hours,
        founded_year, architecture_style, is_enriched,
        source, contributed_by, enriched_by,
        enrichment_version, last_enriched_at
    )
    VALUES (
        p_id, p_name,
        ST_SetSRID(ST_MakePoint(p_longitude, p_latitude), 4326)::geography,
        p_latitude, p_longitude,
        p_category_id, p_score, p_image_url, p_thumbnail_url, p_description,
        p_is_curated, p_has_wikipedia, p_wikipedia_title, p_tags,
        p_wikidata_id, p_wikidata_description, p_has_wikidata_data,
        p_phone, p_email, p_website, p_opening_hours,
        p_founded_year, p_architecture_style, p_is_enriched,
        p_source, p_contributed_by,
        CASE WHEN p_is_enriched THEN p_contributed_by ELSE NULL END,
        CASE WHEN p_is_enriched THEN 1 ELSE 0 END,
        CASE WHEN p_is_enriched THEN NOW() ELSE NULL END
    )
    ON CONFLICT (id) DO UPDATE SET
        -- Name: nur ueberschreiben wenn neuer Name laenger (mehr Info)
        name = CASE
            WHEN LENGTH(EXCLUDED.name) > LENGTH(pois.name) THEN EXCLUDED.name
            ELSE pois.name
        END,
        -- Score: hoechster gewinnt
        score = GREATEST(pois.score, EXCLUDED.score),
        -- Enrichment-Felder: COALESCE (nur leere Felder ueberschreiben)
        image_url = COALESCE(pois.image_url, EXCLUDED.image_url),
        thumbnail_url = COALESCE(pois.thumbnail_url, EXCLUDED.thumbnail_url),
        description = COALESCE(pois.description, EXCLUDED.description),
        wikipedia_title = COALESCE(pois.wikipedia_title, EXCLUDED.wikipedia_title),
        wikidata_id = COALESCE(pois.wikidata_id, EXCLUDED.wikidata_id),
        wikidata_description = COALESCE(pois.wikidata_description, EXCLUDED.wikidata_description),
        phone = COALESCE(pois.phone, EXCLUDED.phone),
        email = COALESCE(pois.email, EXCLUDED.email),
        website = COALESCE(pois.website, EXCLUDED.website),
        opening_hours = COALESCE(pois.opening_hours, EXCLUDED.opening_hours),
        founded_year = COALESCE(pois.founded_year, EXCLUDED.founded_year),
        architecture_style = COALESCE(pois.architecture_style, EXCLUDED.architecture_style),
        -- Boolean Flags: OR (true gewinnt)
        has_wikipedia = pois.has_wikipedia OR EXCLUDED.has_wikipedia,
        has_wikidata_data = pois.has_wikidata_data OR EXCLUDED.has_wikidata_data,
        is_curated = pois.is_curated OR EXCLUDED.is_curated,
        is_enriched = pois.is_enriched OR EXCLUDED.is_enriched,
        -- Tags: Union (dedupliziert)
        tags = ARRAY(SELECT DISTINCT unnest(pois.tags || EXCLUDED.tags)),
        -- Tracking
        enriched_by = CASE
            WHEN EXCLUDED.is_enriched AND NOT pois.is_enriched THEN EXCLUDED.enriched_by
            ELSE pois.enriched_by
        END,
        enrichment_version = CASE
            WHEN EXCLUDED.is_enriched THEN pois.enrichment_version + 1
            ELSE pois.enrichment_version
        END,
        last_enriched_at = CASE
            WHEN EXCLUDED.is_enriched THEN NOW()
            ELSE pois.last_enriched_at
        END
    RETURNING * INTO v_result;

    RETURN v_result;
END;
$$;
