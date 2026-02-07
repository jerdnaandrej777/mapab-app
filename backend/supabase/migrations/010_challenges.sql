-- Migration: 010_challenges.sql
-- Challenges & Streak-System

-- =====================================================
-- 1. Challenge-Definitionen (Templates)
-- =====================================================

CREATE TABLE IF NOT EXISTS challenge_definitions (
  id TEXT PRIMARY KEY,
  type TEXT NOT NULL DEFAULT 'visit_category',  -- visit_category, visit_country, complete_trips, take_photos, streak, weather, social, discover, distance
  frequency TEXT NOT NULL DEFAULT 'weekly',      -- daily, weekly, monthly, permanent
  target_count INTEGER NOT NULL DEFAULT 5,
  xp_reward INTEGER NOT NULL DEFAULT 100,
  category_filter TEXT,                          -- Fuer visitCategory
  country_filter TEXT,                           -- Fuer visitCountry
  weather_filter TEXT,                           -- Fuer weather (good/bad/rain)
  is_featured BOOLEAN DEFAULT FALSE,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- 2. User-Challenges (aktive Challenges pro Benutzer)
-- =====================================================

CREATE TABLE IF NOT EXISTS user_challenges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  challenge_id TEXT REFERENCES challenge_definitions(id) ON DELETE CASCADE,
  current_progress INTEGER NOT NULL DEFAULT 0,
  started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ,
  UNIQUE(user_id, challenge_id, started_at)
);

CREATE INDEX idx_user_challenges_user_id ON user_challenges(user_id);
CREATE INDEX idx_user_challenges_active ON user_challenges(user_id) WHERE completed_at IS NULL;

-- =====================================================
-- 3. Streak-Historie (fuer Statistiken)
-- =====================================================

CREATE TABLE IF NOT EXISTS streak_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  streak_length INTEGER NOT NULL,
  started_at TIMESTAMPTZ NOT NULL,
  ended_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, started_at)
);

CREATE INDEX idx_streak_history_user_id ON streak_history(user_id);

-- =====================================================
-- 4. Initiale Challenge-Definitionen
-- =====================================================

INSERT INTO challenge_definitions (id, type, frequency, target_count, xp_reward, category_filter, is_featured) VALUES
  -- Wöchentliche Kategorie-Challenges
  ('weekly_castles', 'visit_category', 'weekly', 3, 150, 'castle', false),
  ('weekly_museums', 'visit_category', 'weekly', 5, 200, 'museum', false),
  ('weekly_nature', 'visit_category', 'weekly', 4, 150, 'nature', false),
  ('weekly_viewpoints', 'visit_category', 'weekly', 3, 150, 'viewpoint', false),
  ('weekly_churches', 'visit_category', 'weekly', 4, 150, 'church', false),
  ('weekly_unesco', 'visit_category', 'weekly', 2, 250, 'unesco', true),

  -- Trip-Challenges
  ('weekly_trips', 'complete_trips', 'weekly', 3, 200, NULL, false),

  -- Foto-Challenges
  ('weekly_photos', 'take_photos', 'weekly', 10, 150, NULL, false),

  -- Social-Challenges
  ('weekly_share', 'social', 'weekly', 2, 100, NULL, false),

  -- Distanz-Challenges
  ('weekly_distance', 'distance', 'weekly', 200, 200, NULL, false),

  -- Entdeckungs-Challenges
  ('weekly_discover', 'discover', 'weekly', 10, 150, NULL, false),

  -- Tägliche Challenges
  ('daily_visit', 'visit_category', 'daily', 1, 25, NULL, false),
  ('daily_photo', 'take_photos', 'daily', 3, 30, NULL, false),

  -- Streak-Challenges
  ('streak_7', 'streak', 'permanent', 7, 100, NULL, false),
  ('streak_30', 'streak', 'permanent', 30, 500, NULL, true),
  ('streak_100', 'streak', 'permanent', 100, 2000, NULL, true)
ON CONFLICT (id) DO NOTHING;

-- =====================================================
-- 5. RPC: Aktive Challenges eines Benutzers laden
-- =====================================================

CREATE OR REPLACE FUNCTION get_user_challenges(p_user_id UUID)
RETURNS TABLE (
  id UUID,
  user_id UUID,
  challenge_id TEXT,
  type TEXT,
  frequency TEXT,
  target_count INTEGER,
  xp_reward INTEGER,
  category_filter TEXT,
  country_filter TEXT,
  weather_filter TEXT,
  is_featured BOOLEAN,
  current_progress INTEGER,
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    uc.id,
    uc.user_id,
    uc.challenge_id,
    cd.type,
    cd.frequency,
    cd.target_count,
    cd.xp_reward,
    cd.category_filter,
    cd.country_filter,
    cd.weather_filter,
    cd.is_featured,
    uc.current_progress,
    uc.started_at,
    uc.completed_at,
    uc.expires_at
  FROM user_challenges uc
  JOIN challenge_definitions cd ON uc.challenge_id = cd.id
  WHERE uc.user_id = p_user_id
    AND (uc.expires_at IS NULL OR uc.expires_at > NOW())
  ORDER BY uc.completed_at IS NULL DESC, uc.started_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 6. RPC: Wöchentliche Challenges zuweisen
-- =====================================================

CREATE OR REPLACE FUNCTION assign_weekly_challenges(p_user_id UUID)
RETURNS SETOF user_challenges AS $$
DECLARE
  v_week_start TIMESTAMPTZ;
  v_week_end TIMESTAMPTZ;
  v_challenge RECORD;
  v_assigned INTEGER := 0;
BEGIN
  -- Aktuellen Wochenstart berechnen (Montag 00:00)
  v_week_start := date_trunc('week', NOW());
  v_week_end := v_week_start + INTERVAL '7 days';

  -- Prüfen ob bereits Challenges für diese Woche zugewiesen
  IF EXISTS (
    SELECT 1 FROM user_challenges
    WHERE user_id = p_user_id
      AND started_at >= v_week_start
      AND started_at < v_week_end
  ) THEN
    -- Bereits zugewiesen, existierende zurückgeben
    RETURN QUERY
    SELECT * FROM user_challenges
    WHERE user_id = p_user_id
      AND started_at >= v_week_start
      AND started_at < v_week_end;
    RETURN;
  END IF;

  -- 3 zufällige wöchentliche Challenges auswählen und zuweisen
  FOR v_challenge IN
    SELECT id FROM challenge_definitions
    WHERE frequency = 'weekly' AND is_active = TRUE
    ORDER BY RANDOM()
    LIMIT 3
  LOOP
    INSERT INTO user_challenges (user_id, challenge_id, started_at, expires_at)
    VALUES (p_user_id, v_challenge.id, v_week_start, v_week_end)
    RETURNING * INTO v_challenge;

    v_assigned := v_assigned + 1;
  END LOOP;

  -- Zugewiesene Challenges zurückgeben
  RETURN QUERY
  SELECT * FROM user_challenges
  WHERE user_id = p_user_id
    AND started_at >= v_week_start
    AND started_at < v_week_end;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 7. RPC: Challenge-Fortschritt aktualisieren
-- =====================================================

CREATE OR REPLACE FUNCTION update_challenge_progress(
  p_user_id UUID,
  p_challenge_id TEXT,
  p_increment INTEGER DEFAULT 1
)
RETURNS user_challenges AS $$
DECLARE
  v_challenge user_challenges;
  v_definition challenge_definitions;
  v_xp_awarded INTEGER := 0;
BEGIN
  -- Challenge und Definition laden
  SELECT uc.*, cd.*
  INTO v_challenge, v_definition
  FROM user_challenges uc
  JOIN challenge_definitions cd ON uc.challenge_id = cd.id
  WHERE uc.user_id = p_user_id
    AND uc.challenge_id = p_challenge_id
    AND uc.completed_at IS NULL
    AND (uc.expires_at IS NULL OR uc.expires_at > NOW())
  ORDER BY uc.started_at DESC
  LIMIT 1;

  IF v_challenge.id IS NULL THEN
    RAISE EXCEPTION 'Keine aktive Challenge gefunden';
  END IF;

  -- Fortschritt aktualisieren
  UPDATE user_challenges
  SET current_progress = LEAST(current_progress + p_increment, v_definition.target_count),
      completed_at = CASE
        WHEN current_progress + p_increment >= v_definition.target_count THEN NOW()
        ELSE NULL
      END
  WHERE id = v_challenge.id
  RETURNING * INTO v_challenge;

  -- XP vergeben wenn abgeschlossen
  IF v_challenge.completed_at IS NOT NULL THEN
    UPDATE user_profiles
    SET total_xp = COALESCE(total_xp, 0) + v_definition.xp_reward,
        level = FLOOR(SQRT((COALESCE(total_xp, 0) + v_definition.xp_reward) / 100.0))::INTEGER
    WHERE id = p_user_id;
  END IF;

  RETURN v_challenge;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 8. RPC: Streak aktualisieren
-- =====================================================

CREATE OR REPLACE FUNCTION update_user_streak(p_user_id UUID)
RETURNS TABLE (
  current_streak INTEGER,
  longest_streak INTEGER,
  streak_continued BOOLEAN
) AS $$
DECLARE
  v_last_activity DATE;
  v_today DATE := CURRENT_DATE;
  v_current_streak INTEGER;
  v_longest_streak INTEGER;
  v_streak_continued BOOLEAN := FALSE;
BEGIN
  -- Aktuelle Werte laden
  SELECT
    up.last_activity_date::DATE,
    up.current_streak,
    up.longest_streak
  INTO v_last_activity, v_current_streak, v_longest_streak
  FROM user_profiles up
  WHERE up.id = p_user_id;

  -- Streak-Logik
  IF v_last_activity IS NULL OR v_last_activity < v_today - 1 THEN
    -- Keine Aktivität oder mehr als 1 Tag Pause: Streak auf 1 setzen
    IF v_current_streak > 1 THEN
      -- Alten Streak in Historie speichern
      INSERT INTO streak_history (user_id, streak_length, started_at, ended_at)
      VALUES (
        p_user_id,
        v_current_streak,
        v_today - v_current_streak,
        v_last_activity
      );
    END IF;
    v_current_streak := 1;
    v_streak_continued := FALSE;
  ELSIF v_last_activity = v_today - 1 THEN
    -- Gestern aktiv: Streak erhöhen
    v_current_streak := COALESCE(v_current_streak, 0) + 1;
    v_streak_continued := TRUE;
  ELSIF v_last_activity = v_today THEN
    -- Heute bereits aktiv: Keine Änderung
    v_streak_continued := TRUE;
  END IF;

  -- Longest Streak aktualisieren
  IF v_current_streak > COALESCE(v_longest_streak, 0) THEN
    v_longest_streak := v_current_streak;
  END IF;

  -- Profil aktualisieren
  UPDATE user_profiles
  SET current_streak = v_current_streak,
      longest_streak = v_longest_streak,
      last_activity_date = v_today
  WHERE id = p_user_id;

  -- Streak-Challenges prüfen
  PERFORM update_challenge_progress(p_user_id, 'streak_7', 0)
  WHERE v_current_streak >= 7
    AND EXISTS (
      SELECT 1 FROM user_challenges
      WHERE user_id = p_user_id
        AND challenge_id = 'streak_7'
        AND completed_at IS NULL
    );

  PERFORM update_challenge_progress(p_user_id, 'streak_30', 0)
  WHERE v_current_streak >= 30
    AND EXISTS (
      SELECT 1 FROM user_challenges
      WHERE user_id = p_user_id
        AND challenge_id = 'streak_30'
        AND completed_at IS NULL
    );

  RETURN QUERY SELECT v_current_streak, v_longest_streak, v_streak_continued;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 9. RLS Policies
-- =====================================================

ALTER TABLE user_challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE streak_history ENABLE ROW LEVEL SECURITY;

-- User kann eigene Challenges sehen und bearbeiten
CREATE POLICY "Users can view own challenges"
  ON user_challenges FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own challenges"
  ON user_challenges FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own challenges"
  ON user_challenges FOR UPDATE
  USING (auth.uid() = user_id);

-- User kann eigene Streak-Historie sehen
CREATE POLICY "Users can view own streak history"
  ON streak_history FOR SELECT
  USING (auth.uid() = user_id);

-- Challenge-Definitionen für alle lesbar
ALTER TABLE challenge_definitions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Challenge definitions are public"
  ON challenge_definitions FOR SELECT
  USING (true);

-- =====================================================
-- 10. Grants
-- =====================================================

GRANT SELECT ON challenge_definitions TO authenticated;
GRANT SELECT, INSERT, UPDATE ON user_challenges TO authenticated;
GRANT SELECT ON streak_history TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_challenges TO authenticated;
GRANT EXECUTE ON FUNCTION assign_weekly_challenges TO authenticated;
GRANT EXECUTE ON FUNCTION update_challenge_progress TO authenticated;
GRANT EXECUTE ON FUNCTION update_user_streak TO authenticated;
