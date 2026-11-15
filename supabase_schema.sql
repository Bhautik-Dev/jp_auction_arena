-- ============================================================================
-- JP AUCTION ARENA — Supabase Database Schema
-- ============================================================================
-- Run this entire script in your Supabase project's SQL Editor.
-- Creates all 8 tables, enables RLS, and sets up permissive policies for
-- the anon role (public client access via the Flutter app).
-- No paid services required — works on Supabase Free Tier.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. profiles — User profiles linked to Supabase Auth
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS profiles (
  id              UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email           TEXT,
  full_name       TEXT,
  avatar_url      TEXT,
  role            TEXT DEFAULT 'admin',
  org_name        TEXT,
  phone           TEXT,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 2. auctions — Auction configurations
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS auctions (
  id                 TEXT PRIMARY KEY,
  name               TEXT NOT NULL DEFAULT 'Untitled Auction',
  logo_base64        TEXT,
  venue              TEXT,
  description        TEXT,
  start_date_time    TIMESTAMPTZ,
  status             TEXT DEFAULT 'draft',
  categories         JSONB DEFAULT '["Batsman", "Bowler", "All-Rounder", "Wicket-Keeper"]',
  number_of_teams    INTEGER DEFAULT 8,
  min_squad          INTEGER DEFAULT 11,
  max_squad          INTEGER DEFAULT 15,
  base_price_default DOUBLE PRECISION DEFAULT 10000,
  bid_increment      DOUBLE PRECISION DEFAULT 2000,
  team_purse         DOUBLE PRECISION DEFAULT 1000000,
  countdown_seconds  INTEGER DEFAULT 30,
  mode               TEXT DEFAULT 'manual',
  created_at         TIMESTAMPTZ DEFAULT NOW(),
  contact_phone      TEXT,
  contact_email      TEXT,
  category_base_prices JSONB DEFAULT '{}',
  reserve_purse_rule BOOLEAN DEFAULT TRUE,
  smart_bid_slabs    BOOLEAN DEFAULT FALSE,
  created_by         TEXT
);

-- ----------------------------------------------------------------------------
-- 3. auction_members — Many-to-many relation between profiles and auctions
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS auction_members (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  auction_id TEXT NOT NULL,
  profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  role       TEXT,
  joined_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (auction_id, profile_id)
);

-- ----------------------------------------------------------------------------
-- 4. teams — Teams participating in an auction
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS teams (
  id          TEXT PRIMARY KEY,
  auction_id  TEXT NOT NULL,
  name        TEXT NOT NULL DEFAULT 'Team',
  logo_base64 TEXT,
  owner_name  TEXT,
  purse_total DOUBLE PRECISION DEFAULT 1000000,
  purse_spent DOUBLE PRECISION DEFAULT 0,
  player_ids  JSONB DEFAULT '[]',
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  created_by  TEXT
);

-- ----------------------------------------------------------------------------
-- 5. players — Players registered in an auction
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS players (
  id             TEXT PRIMARY KEY,
  auction_id     TEXT NOT NULL,
  player_no      INTEGER,
  name           TEXT,
  photo_base64   TEXT,
  age            INTEGER DEFAULT 20,
  village        TEXT DEFAULT '',
  category       TEXT DEFAULT 'All-Rounder',
  batting_style  TEXT DEFAULT 'Right Hand Bat',
  bowling_style  TEXT DEFAULT 'Right Arm Medium',
  matches        INTEGER DEFAULT 0,
  runs           INTEGER DEFAULT 0,
  wickets        INTEGER DEFAULT 0,
  high_score     INTEGER DEFAULT 0,
  strike_rate    DOUBLE PRECISION DEFAULT 0.0,
  economy        DOUBLE PRECISION DEFAULT 0.0,
  base_price     DOUBLE PRECISION DEFAULT 10000.0,
  is_icon        BOOLEAN DEFAULT FALSE,
  is_owner       BOOLEAN DEFAULT FALSE,
  is_retained    BOOLEAN DEFAULT FALSE,
  retained_team_id TEXT,
  status         TEXT DEFAULT 'available',
  sold_price     DOUBLE PRECISION,
  sold_team_id   TEXT,
  created_at     TIMESTAMPTZ DEFAULT NOW(),
  created_by     TEXT
);

-- ----------------------------------------------------------------------------
-- 6. bids — Individual bid records
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS bids (
  id         TEXT PRIMARY KEY,
  auction_id TEXT NOT NULL,
  player_id  TEXT NOT NULL,
  team_id    TEXT NOT NULL,
  amount     DOUBLE PRECISION NOT NULL DEFAULT 0,
  timestamp  TIMESTAMPTZ DEFAULT NOW(),
  created_by TEXT
);

-- ----------------------------------------------------------------------------
-- 7. auction_state — Live auction operational state
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS auction_state (
  id                     TEXT PRIMARY KEY,
  auction_id             TEXT NOT NULL,
  current_player_id      TEXT,
  current_bid_amount     DOUBLE PRECISION,
  current_team_id        TEXT,
  timer_seconds_remaining INTEGER,
  is_paused              BOOLEAN DEFAULT FALSE,
  is_live                BOOLEAN DEFAULT FALSE,
  last_hammered_player_id TEXT,
  last_sold_team_id      TEXT,
  last_sold_price        DOUBLE PRECISION,
  bid_count              INTEGER DEFAULT 0,
  updated_at             TIMESTAMPTZ DEFAULT NOW(),
  updated_by             TEXT
);

-- ----------------------------------------------------------------------------
-- 8. activity_log — System event log for audit trails
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS activity_log (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  auction_id  TEXT NOT NULL,
  event_type  TEXT,
  entity_type TEXT,
  entity_id   TEXT,
  entity_name TEXT,
  team_id     TEXT,
  team_name   TEXT,
  player_id   TEXT,
  player_name TEXT,
  amount      DOUBLE PRECISION,
  metadata    JSONB DEFAULT '{}',
  timestamp   TIMESTAMPTZ DEFAULT NOW(),
  created_by  TEXT
);

-- ============================================================================
-- INDEXES for query performance
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_teams_auction_id ON teams(auction_id);
CREATE INDEX IF NOT EXISTS idx_players_auction_id ON players(auction_id);
CREATE INDEX IF NOT EXISTS idx_players_status ON players(status);
CREATE INDEX IF NOT EXISTS idx_players_sold_team_id ON players(sold_team_id);
CREATE INDEX IF NOT EXISTS idx_bids_auction_id ON bids(auction_id);
CREATE INDEX IF NOT EXISTS idx_bids_player_id ON bids(player_id);
CREATE INDEX IF NOT EXISTS idx_bids_team_id ON bids(team_id);
CREATE INDEX IF NOT EXISTS idx_auction_members_auction_id ON auction_members(auction_id);
CREATE INDEX IF NOT EXISTS idx_auction_members_profile_id ON auction_members(profile_id);
CREATE INDEX IF NOT EXISTS idx_activity_log_auction_id ON activity_log(auction_id);
CREATE INDEX IF NOT EXISTS idx_activity_log_timestamp ON activity_log(timestamp);
CREATE INDEX IF NOT EXISTS idx_auction_state_auction_id ON auction_state(auction_id);

-- ============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================================
-- Supabase enables RLS by default on new tables, but we explicitly enable it
-- here for clarity. All policies below grant the `anon` role full CRUD access
-- because this is a self-operated local auction app using the publishable key.
-- For production multi-tenant use, replace WITH CHECK (true) with appropriate
-- tenant/auction ID isolation rules.

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE auctions ENABLE ROW LEVEL SECURITY;
ALTER TABLE auction_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE players ENABLE ROW LEVEL SECURITY;
ALTER TABLE bids ENABLE ROW LEVEL SECURITY;
ALTER TABLE auction_state ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_log ENABLE ROW LEVEL SECURITY;

-- Permissive policies for anon role (public client access)
CREATE POLICY "Enable all access for anon role" ON profiles
  FOR ALL TO anon USING (true) WITH CHECK (true);

CREATE POLICY "Enable all access for anon role" ON auctions
  FOR ALL TO anon USING (true) WITH CHECK (true);

CREATE POLICY "Enable all access for anon role" ON auction_members
  FOR ALL TO anon USING (true) WITH CHECK (true);

CREATE POLICY "Enable all access for anon role" ON teams
  FOR ALL TO anon USING (true) WITH CHECK (true);

CREATE POLICY "Enable all access for anon role" ON players
  FOR ALL TO anon USING (true) WITH CHECK (true);

CREATE POLICY "Enable all access for anon role" ON bids
  FOR ALL TO anon USING (true) WITH CHECK (true);

CREATE POLICY "Enable all access for anon role" ON auction_state
  FOR ALL TO anon USING (true) WITH CHECK (true);

CREATE POLICY "Enable all access for anon role" ON activity_log
  FOR ALL TO anon USING (true) WITH CHECK (true);

-- ============================================================================
-- COMPLETE
-- ============================================================================
-- After running this script:
-- 1. All 8 tables exist with correct column names matching the Flutter models
-- 2. RLS is enabled and the anon role can perform INSERT/UPDATE/DELETE/SELECT
-- 3. The Flutter app can connect and sync data to Supabase
-- 4. Data persists across app restarts and devices
-- ============================================================================
