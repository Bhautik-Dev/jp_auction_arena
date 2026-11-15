-- ============================================================================
-- JP AUCTION ARENA — Live Auction Engine Functions
-- ============================================================================
-- Run this entire script in your Supabase project's SQL Editor.
-- Creates all server-side PostgreSQL functions for the live auction engine.
-- All functions are SECURITY DEFINER (runs with function owner privileges),
-- atomic (uses FOR UPDATE row locks), callable only by owner/operators,
-- and insert activity_log rows.
-- Safe to run multiple times (uses CREATE OR REPLACE FUNCTION).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Helper: check if the calling user is an operator/admin of the given auction
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION _is_auction_operator(
  p_auction_id TEXT,
  p_user_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
  v_user_role TEXT;
  v_is_member BOOLEAN;
BEGIN
  -- Check user's global role from profiles
  SELECT role INTO v_user_role FROM profiles WHERE id = p_user_id;
  IF v_user_role IS NULL THEN
    RETURN FALSE;
  END IF;

  -- Admin/owner can operate any auction
  IF v_user_role IN ('admin', 'owner') THEN
    RETURN TRUE;
  END IF;

  -- Operator must be a member of the auction
  SELECT EXISTS (
    SELECT 1 FROM auction_members
    WHERE auction_id = p_auction_id
      AND profile_id = p_user_id
      AND role = 'operator'
  ) INTO v_is_member;

  RETURN v_is_member;
END;
$$;

-- ----------------------------------------------------------------------------
-- Helper: insert activity log row (used by all auction functions)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION _log_activity(
  p_auction_id TEXT,
  p_event_type TEXT,
  p_entity_type TEXT,
  p_entity_id TEXT,
  p_entity_name TEXT,
  p_team_id TEXT,
  p_team_name TEXT,
  p_player_id TEXT,
  p_player_name TEXT,
  p_amount DOUBLE PRECISION,
  p_metadata JSONB,
  p_created_by TEXT
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO activity_log (
    id, auction_id, event_type, entity_type, entity_id, entity_name,
    team_id, team_name, player_id, player_name, amount, metadata,
    timestamp, created_by
  ) VALUES (
    gen_random_uuid(), p_auction_id, p_event_type, p_entity_type, p_entity_id,
    p_entity_name, p_team_id, p_team_name, p_player_id, p_player_name,
    p_amount, p_metadata, now(), p_created_by
  );
END;
$$;

-- ----------------------------------------------------------------------------
-- 1. start_player(auction_id, player_id)
-- Sets player status 'live', state status 'live', current_bid = base price,
-- leading_team = null, timer_ends_at = now() + countdown seconds,
-- deletes/deactivates old bids, writes last_event.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION start_player(
  p_auction_id TEXT,
  p_player_id TEXT
)
RETURNS TABLE (
  success BOOLEAN,
  error_code TEXT,
  error_message TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_player RECORD;
  v_state RECORD;
  v_base_price DOUBLE PRECISION;
  v_countdown INTEGER;
  v_auction_owner TEXT;
BEGIN
  -- Only authenticated users can call
  IF v_user_id IS NULL THEN
    RETURN QUERY SELECT FALSE, 'auth_required', 'Authentication required';
  END IF;

  -- Check operator permission
  IF NOT _is_auction_operator(p_auction_id, v_user_id) THEN
    RETURN QUERY SELECT FALSE, 'not_authorized', 'Only auction operator can start a player';
  END IF;

  -- Lock the player row
  SELECT * INTO v_player FROM players WHERE id = p_player_id FOR UPDATE;

  IF v_player IS NULL THEN
    RETURN QUERY SELECT FALSE, 'player_not_found', 'Player not found';
  END IF;

  IF v_player.auction_id != p_auction_id THEN
    RETURN QUERY SELECT FALSE, 'player_not_in_auction', 'Player does not belong to this auction';
  END IF;

  -- Lock the auction_state row
  SELECT * INTO v_state FROM auction_state WHERE auction_id = p_auction_id FOR UPDATE;

  IF v_state IS NULL THEN
    RETURN QUERY SELECT FALSE, 'auction_not_found', 'Auction state not found';
  END IF;

  -- Get auction config for countdown and base price
  SELECT created_by, countdown_seconds, base_price_default
    INTO v_auction_owner, v_countdown, v_base_price
    FROM auctions WHERE id = p_auction_id;

  IF v_auction_owner IS NULL THEN
    RETURN QUERY SELECT FALSE, 'auction_not_found', 'Auction not found';
  END IF;

  -- Get player's base price
  SELECT base_price INTO v_base_price FROM players WHERE id = p_player_id;

  -- Deactivate all old bids for this auction (mark as superseded)
  UPDATE bids SET amount = 0 WHERE auction_id = p_auction_id AND player_id = p_player_id;

  -- Update player status to live
  UPDATE players SET status = 'live' WHERE id = p_player_id;

  -- Update auction_state
  UPDATE auction_state SET
    current_player_id = p_player_id,
    current_bid_amount = v_base_price,
    current_team_id = NULL,
    timer_seconds_remaining = v_countdown,
    is_paused = FALSE,
    is_live = TRUE,
    last_hammered_player_id = NULL,
    last_sold_team_id = NULL,
    last_sold_price = NULL,
    bid_count = 0,
    updated_at = now(),
    updated_by = v_user_id::TEXT
  WHERE auction_id = p_auction_id;

  -- Log activity
  PERFORM _log_activity(
    p_auction_id, 'player_started', 'player', p_player_id, v_player.name,
    NULL, NULL, p_player_id, v_player.name, v_base_price,
    jsonb_build_object('base_price', v_base_price, 'countdown', v_countdown),
    v_user_id::TEXT
  );

  RETURN QUERY SELECT TRUE, NULL, NULL;
END;
$$;

-- ----------------------------------------------------------------------------
-- 2. place_bid(auction_id, team_id, amount)
-- Validates auction live and not paused, amount >= current_bid + minimum
-- increment (or equals base price for first bid), team squad not full,
-- team purse >= amount, reserve rule, team is not already the leader;
-- then inserts into bids, updates auction_state, resets timer.
-- Returns an error code on failure.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION place_bid(
  p_auction_id TEXT,
  p_team_id TEXT,
  p_amount DOUBLE PRECISION
)
RETURNS TABLE (
  success BOOLEAN,
  error_code TEXT,
  error_message TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_state RECORD;
  v_team RECORD;
  v_player RECORD;
  v_bid_count INTEGER;
  v_current_bid DOUBLE PRECISION;
  v_min_increment DOUBLE PRECISION;
  v_required_amount DOUBLE PRECISION;
  v_purse_remaining DOUBLE PRECISION;
  v_remaining_slots INTEGER;
  v_squad_count INTEGER;
  v_bid_id TEXT;
BEGIN
  IF v_user_id IS NULL THEN
    RETURN QUERY SELECT FALSE, 'auth_required', 'Authentication required';
  END IF;

  IF NOT _is_auction_operator(p_auction_id, v_user_id) THEN
    RETURN QUERY SELECT FALSE, 'not_authorized', 'Only auction operator can place bids';
  END IF;

  -- Lock auction state
  SELECT * INTO v_state FROM auction_state WHERE auction_id = p_auction_id FOR UPDATE;

  IF v_state IS NULL THEN
    RETURN QUERY SELECT FALSE, 'auction_not_found', 'Auction state not found';
  END IF;

  IF NOT v_state.is_live THEN
    RETURN QUERY SELECT FALSE, 'auction_not_live', 'Auction is not live';
  END IF;

  IF v_state.is_paused THEN
    RETURN QUERY SELECT FALSE, 'auction_paused', 'Auction is paused';
  END IF;

  IF v_state.current_player_id IS NULL THEN
    RETURN QUERY SELECT FALSE, 'no_player_live', 'No player is currently live';
  END IF;

  -- Lock the team row
  SELECT * INTO v_team FROM teams WHERE id = p_team_id FOR UPDATE;

  IF v_team IS NULL THEN
    RETURN QUERY SELECT FALSE, 'team_not_found', 'Team not found';
  END IF;

  IF v_team.auction_id != p_auction_id THEN
    RETURN QUERY SELECT FALSE, 'team_not_in_auction', 'Team does not belong to this auction';
  END IF;

  -- Lock the current player row
  SELECT * INTO v_player FROM players WHERE id = v_state.current_player_id FOR UPDATE;

  -- Determine minimum increment
  IF v_state.current_team_id IS NULL THEN
    -- First bid: must equal base price
    v_required_amount := v_player.base_price;
    v_min_increment := 0;
  ELSE
    -- Subsequent bid: must be current_bid + minimum increment
    -- Use auction bid_increment or default 2000
    SELECT bid_increment INTO v_min_increment FROM auctions WHERE id = p_auction_id;
    IF v_min_increment IS NULL THEN
      v_min_increment := 2000;
    END IF;
    v_required_amount := v_state.current_bid_amount + v_min_increment;
  END IF;

  -- Validate amount
  IF p_amount < v_required_amount THEN
    IF v_state.current_team_id IS NULL THEN
      RETURN QUERY SELECT FALSE, 'bid_too_low', format('Bid must be at least base price %s', v_player.base_price);
    ELSE
      RETURN QUERY SELECT FALSE, 'bid_too_low', format('Bid must be at least %s (current %s + increment %s)', v_required_amount, v_state.current_bid_amount, v_min_increment);
    END IF;
  END IF;

  -- Check team purse
  v_purse_remaining := (v_team.purse_total ?? 0) - (v_team.purse_spent ?? 0);
  IF p_amount > v_purse_remaining THEN
    RETURN QUERY SELECT FALSE, 'not_enough_purse', 'Team does not have enough purse remaining';
  END IF;

  -- Check reserve rule: purse - amount >= base_price * remaining required players
  -- Count current squad size
  SELECT COUNT(*) INTO v_squad_count FROM players WHERE sold_team_id = p_team_id AND status = 'sold';

  -- Determine how many more players this team needs
  -- Use min_squad as minimum required
  SELECT min_squad INTO v_remaining_slots FROM auctions WHERE id = p_auction_id;
  v_remaining_slots := GREATEST(v_remaining_slots - v_squad_count, 0);

  IF (v_purse_remaining - p_amount) < (v_player.base_price * v_remaining_slots) THEN
    RETURN QUERY SELECT FALSE, 'reserve_rule_violated', 'Reserve purse rule violated: must keep enough purse for remaining squad slots';
  END IF;

  -- Check team is not already the leader
  IF v_state.current_team_id = p_team_id THEN
    RETURN QUERY SELECT FALSE, 'already_leader', 'This team is already the leading bidder';
  END IF;

  -- Check squad not full (max_squad)
  SELECT max_squad INTO v_remaining_slots FROM auctions WHERE id = p_auction_id;
  IF v_squad_count >= (v_remaining_slots) THEN
    RETURN QUERY SELECT FALSE, 'squad_full', 'Team squad is full';
  END IF;

  -- Generate bid id
  v_bid_id := gen_random_uuid()::TEXT;

  -- Insert the bid
  INSERT INTO bids (id, auction_id, player_id, team_id, amount, timestamp, created_by)
  VALUES (v_bid_id, p_auction_id, v_state.current_player_id, p_team_id, p_amount, now(), v_user_id::TEXT);

  -- Update auction state
  UPDATE auction_state SET
    current_bid_amount = p_amount,
    current_team_id = p_team_id,
    timer_seconds_remaining = (SELECT countdown_seconds FROM auctions WHERE id = p_auction_id),
    bid_count = COALESCE(v_state.bid_count, 0) + 1,
    updated_at = now(),
    updated_by = v_user_id::TEXT
  WHERE auction_id = p_auction_id;

  -- Log activity
  PERFORM _log_activity(
    p_auction_id, 'bid_placed', 'bid', v_bid_id, NULL,
    p_team_id, v_team.name, v_state.current_player_id, v_player.name,
    p_amount, jsonb_build_object('previous_bid', v_state.current_bid_amount, 'previous_team', v_state.current_team_id),
    v_user_id::TEXT
  );

  RETURN QUERY SELECT TRUE, NULL, NULL;
END;
$$;

-- ----------------------------------------------------------------------------
-- 3. undo_last_bid(auction_id)
-- Reverts the last bid: removes it from bids, restores previous state.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION undo_last_bid(
  p_auction_id TEXT
)
RETURNS TABLE (
  success BOOLEAN,
  error_code TEXT,
  error_message TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_state RECORD;
  v_last_bid RECORD;
  v_previous_bid RECORD;
  v_player RECORD;
BEGIN
  IF v_user_id IS NULL THEN
    RETURN QUERY SELECT FALSE, 'auth_required', 'Authentication required';
  END IF;

  IF NOT _is_auction_operator(p_auction_id, v_user_id) THEN
    RETURN QUERY SELECT FALSE, 'not_authorized', 'Only auction operator can undo bids';
  END IF;

  SELECT * INTO v_state FROM auction_state WHERE auction_id = p_auction_id FOR UPDATE;

  IF v_state IS NULL THEN
    RETURN QUERY SELECT FALSE, 'auction_not_found', 'Auction state not found';
  END IF;

  IF v_state.current_team_id IS NULL OR v_state.bid_count IS NULL OR v_state.bid_count = 0 THEN
    RETURN QUERY SELECT FALSE, 'no_bid_to_undo', 'No bid to undo';
  END IF;

  -- Get the last bid
  SELECT * INTO v_last_bid FROM bids
  WHERE auction_id = p_auction_id AND player_id = v_state.current_player_id
  ORDER BY timestamp DESC LIMIT 1 FOR UPDATE;

  IF v_last_bid IS NULL THEN
    RETURN QUERY SELECT FALSE, 'no_bid_to_undo', 'No bid record found';
  END IF;

  -- Get the bid before that (to restore state)
  SELECT * INTO v_previous_bid FROM bids
  WHERE auction_id = p_auction_id AND player_id = v_state.current_player_id
  AND id != v_last_bid.id
  ORDER BY timestamp DESC LIMIT 1;

  -- Lock the player row
  SELECT * INTO v_player FROM players WHERE id = v_state.current_player_id FOR UPDATE;

  -- Delete the last bid
  DELETE FROM bids WHERE id = v_last_bid.id;

  -- Restore state
  IF v_previous_bid IS NOT NULL THEN
    UPDATE auction_state SET
      current_bid_amount = v_previous_bid.amount,
      current_team_id = v_previous_bid.team_id,
      bid_count = GREATEST(COALESCE(v_state.bid_count, 1) - 1, 0),
      updated_at = now(),
      updated_by = v_user_id::TEXT
    WHERE auction_id = p_auction_id;
  ELSE
    -- No previous bid: reset to base price, no leader
    UPDATE auction_state SET
      current_bid_amount = v_player.base_price,
      current_team_id = NULL,
      bid_count = 0,
      updated_at = now(),
      updated_by = v_user_id::TEXT
    WHERE auction_id = p_auction_id;
  END IF;

  -- Log activity
  PERFORM _log_activity(
    p_auction_id, 'bid_undone', 'bid', v_last_bid.id, NULL,
    v_last_bid.team_id, NULL, v_state.current_player_id, v_player.name,
    v_last_bid.amount, jsonb_build_object('undone_bid_amount', v_last_bid.amount),
    v_user_id::TEXT
  );

  RETURN QUERY SELECT TRUE, NULL, NULL;
END;
$$;

-- ----------------------------------------------------------------------------
-- 4. pause_auction(auction_id) / resume_auction(auction_id)
-- Store paused_remaining_ms and restore timer.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION pause_auction(
  p_auction_id TEXT
)
RETURNS TABLE (
  success BOOLEAN,
  error_code TEXT,
  error_message TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_state RECORD;
BEGIN
  IF v_user_id IS NULL THEN
    RETURN QUERY SELECT FALSE, 'auth_required', 'Authentication required';
  END IF;

  IF NOT _is_auction_operator(p_auction_id, v_user_id) THEN
    RETURN QUERY SELECT FALSE, 'not_authorized', 'Only auction operator can pause';
  END IF;

  SELECT * INTO v_state FROM auction_state WHERE auction_id = p_auction_id FOR UPDATE;

  IF v_state IS NULL THEN
    RETURN QUERY SELECT FALSE, 'auction_not_found', 'Auction state not found';
  END IF;

  IF NOT v_state.is_live THEN
    RETURN QUERY SELECT FALSE, 'auction_not_live', 'Auction is not live';
  END IF;

  IF v_state.is_paused THEN
    RETURN QUERY SELECT FALSE, 'already_paused', 'Auction is already paused';
  END IF;

  UPDATE auction_state SET
    is_paused = TRUE,
    updated_at = now(),
    updated_by = v_user_id::TEXT
  WHERE auction_id = p_auction_id;

  PERFORM _log_activity(
    p_auction_id, 'auction_paused', 'auction', p_auction_id, NULL,
    NULL, NULL, NULL, NULL, NULL,
    jsonb_build_object('timer_seconds_remaining', v_state.timer_seconds_remaining),
    v_user_id::TEXT
  );

  RETURN QUERY SELECT TRUE, NULL, NULL;
END;
$$;

CREATE OR REPLACE FUNCTION resume_auction(
  p_auction_id TEXT
)
RETURNS TABLE (
  success BOOLEAN,
  error_code TEXT,
  error_message TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_state RECORD;
BEGIN
  IF v_user_id IS NULL THEN
    RETURN QUERY SELECT FALSE, 'auth_required', 'Authentication required';
  END IF;

  IF NOT _is_auction_operator(p_auction_id, v_user_id) THEN
    RETURN QUERY SELECT FALSE, 'not_authorized', 'Only auction operator can resume';
  END IF;

  SELECT * INTO v_state FROM auction_state WHERE auction_id = p_auction_id FOR UPDATE;

  IF v_state IS NULL THEN
    RETURN QUERY SELECT FALSE, 'auction_not_found', 'Auction state not found';
  END IF;

  IF NOT v_state.is_paused THEN
    RETURN QUERY SELECT FALSE, 'not_paused', 'Auction is not paused';
  END IF;

  UPDATE auction_state SET
    is_paused = FALSE,
    updated_at = now(),
    updated_by = v_user_id::TEXT
  WHERE auction_id = p_auction_id;

  PERFORM _log_activity(
    p_auction_id, 'auction_resumed', 'auction', p_auction_id, NULL,
    NULL, NULL, NULL, NULL, NULL,
    NULL,
    v_user_id::TEXT
  );

  RETURN QUERY SELECT TRUE, NULL, NULL;
END;
$$;

-- ----------------------------------------------------------------------------
-- 5. sell_player(auction_id)
-- Assigns player to leading team, sets sold_price and sold_team_id,
-- increases team purse_spent, status 'sold', state status 'sold',
-- last_event {type:'sold', ...}. If no bids it calls mark_unsold instead.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION sell_player(
  p_auction_id TEXT
)
RETURNS TABLE (
  success BOOLEAN,
  error_code TEXT,
  error_message TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_state RECORD;
  v_player RECORD;
  v_team RECORD;
BEGIN
  IF v_user_id IS NULL THEN
    RETURN QUERY SELECT FALSE, 'auth_required', 'Authentication required';
  END IF;

  IF NOT _is_auction_operator(p_auction_id, v_user_id) THEN
    RETURN QUERY SELECT FALSE, 'not_authorized', 'Only auction operator can sell a player';
  END IF;

  SELECT * INTO v_state FROM auction_state WHERE auction_id = p_auction_id FOR UPDATE;

  IF v_state IS NULL THEN
    RETURN QUERY SELECT FALSE, 'auction_not_found', 'Auction state not found';
  END IF;

  IF v_state.current_player_id IS NULL THEN
    RETURN QUERY SELECT FALSE, 'no_player_live', 'No player is currently live';
  END IF;

  -- Lock the player row
  SELECT * INTO v_player FROM players WHERE id = v_state.current_player_id FOR UPDATE;

  -- If no current bid/leader, mark unsold instead
  IF v_state.current_team_id IS NULL OR v_state.current_bid_amount IS NULL THEN
    -- Call mark_unsold logic inline
    UPDATE players SET status = 'unsold' WHERE id = v_player.id;

    UPDATE auction_state SET
      is_live = FALSE,
      last_hammered_player_id = v_player.id,
      last_sold_team_id = NULL,
      last_sold_price = NULL,
      updated_at = now(),
      updated_by = v_user_id::TEXT
    WHERE auction_id = p_auction_id;

    PERFORM _log_activity(
      p_auction_id, 'player_unsold', 'player', v_player.id, v_player.name,
      NULL, NULL, v_player.id, v_player.name, NULL,
      jsonb_build_object('reason', 'no_bids'),
      v_user_id::TEXT
    );

    RETURN QUERY SELECT TRUE, NULL, NULL;
  END IF;

  -- Lock the leading team
  SELECT * INTO v_team FROM teams WHERE id = v_state.current_team_id FOR UPDATE;

  -- Update player: sold
  UPDATE players SET
    status = 'sold',
    sold_price = v_state.current_bid_amount,
    sold_team_id = v_state.current_team_id
  WHERE id = v_player.id;

  -- Update team purse_spent
  UPDATE teams SET
    purse_spent = COALESCE(purse_spent, 0) + v_state.current_bid_amount,
    player_ids = COALESCE(player_ids, '[]'::jsonb) || jsonb_build_array(v_player.id)
  WHERE id = v_state.current_team_id;

  -- Update auction state
  UPDATE auction_state SET
    last_hammered_player_id = v_player.id,
    last_sold_team_id = v_state.current_team_id,
    last_sold_price = v_state.current_bid_amount,
    is_live = FALSE,
    updated_at = now(),
    updated_by = v_user_id::TEXT
  WHERE auction_id = p_auction_id;

  -- Log activity
  PERFORM _log_activity(
    p_auction_id, 'player_sold', 'player', v_player.id, v_player.name,
    v_state.current_team_id, v_team.name, v_player.id, v_player.name,
    v_state.current_bid_amount, jsonb_build_object('sold_price', v_state.current_bid_amount, 'team', v_team.name),
    v_user_id::TEXT
  );

  RETURN QUERY SELECT TRUE, NULL, NULL;
END;
$$;

-- ----------------------------------------------------------------------------
-- 6. mark_unsold(auction_id)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION mark_unsold(
  p_auction_id TEXT
)
RETURNS TABLE (
  success BOOLEAN,
  error_code TEXT,
  error_message TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_state RECORD;
  v_player RECORD;
BEGIN
  IF v_user_id IS NULL THEN
    RETURN QUERY SELECT FALSE, 'auth_required', 'Authentication required';
  END IF;

  IF NOT _is_auction_operator(p_auction_id, v_user_id) THEN
    RETURN QUERY SELECT FALSE, 'not_authorized', 'Only auction operator can mark unsold';
  END IF;

  SELECT * INTO v_state FROM auction_state WHERE auction_id = p_auction_id FOR UPDATE;

  IF v_state IS NULL THEN
    RETURN QUERY SELECT FALSE, 'auction_not_found', 'Auction state not found';
  END IF;

  IF v_state.current_player_id IS NULL THEN
    RETURN QUERY SELECT FALSE, 'no_player_live', 'No player is currently live';
  END IF;

  SELECT * INTO v_player FROM players WHERE id = v_state.current_player_id FOR UPDATE;

  UPDATE players SET status = 'unsold' WHERE id = v_player.id;

  UPDATE auction_state SET
    last_hammered_player_id = v_player.id,
    last_sold_team_id = NULL,
    last_sold_price = NULL,
    is_live = FALSE,
    updated_at = now(),
    updated_by = v_user_id::TEXT
  WHERE auction_id = p_auction_id;

  PERFORM _log_activity(
    p_auction_id, 'player_unsold', 'player', v_player.id, v_player.name,
    NULL, NULL, v_player.id, v_player.name, NULL,
    jsonb_build_object('reason', 'manual_unsold'),
    v_user_id::TEXT
  );

  RETURN QUERY SELECT TRUE, NULL, NULL;
END;
$$;

-- ----------------------------------------------------------------------------
-- 7. reset_player(auction_id)
-- Reset current player back to available status, clear state.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION reset_player(
  p_auction_id TEXT
)
RETURNS TABLE (
  success BOOLEAN,
  error_code TEXT,
  error_message TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_state RECORD;
  v_player RECORD;
BEGIN
  IF v_user_id IS NULL THEN
    RETURN QUERY SELECT FALSE, 'auth_required', 'Authentication required';
  END IF;

  IF NOT _is_auction_operator(p_auction_id, v_user_id) THEN
    RETURN QUERY SELECT FALSE, 'not_authorized', 'Only auction operator can reset player';
  END IF;

  SELECT * INTO v_state FROM auction_state WHERE auction_id = p_auction_id FOR UPDATE;

  IF v_state IS NULL THEN
    RETURN QUERY SELECT FALSE, 'auction_not_found', 'Auction state not found';
  END IF;

  IF v_state.current_player_id IS NULL THEN
    RETURN QUERY SELECT FALSE, 'no_player_live', 'No player is currently live';
  END IF;

  SELECT * INTO v_player FROM players WHERE id = v_state.current_player_id FOR UPDATE;

  UPDATE players SET status = 'available' WHERE id = v_player.id;

  UPDATE auction_state SET
    current_player_id = NULL,
    current_bid_amount = NULL,
    current_team_id = NULL,
    is_live = FALSE,
    bid_count = 0,
    updated_at = now(),
    updated_by = v_user_id::TEXT
  WHERE auction_id = p_auction_id;

  PERFORM _log_activity(
    p_auction_id, 'player_reset', 'player', v_player.id, v_player.name,
    NULL, NULL, v_player.id, v_player.name, NULL,
    jsonb_build_object('reason', 'manual_reset'),
    v_user_id::TEXT
  );

  RETURN QUERY SELECT TRUE, NULL, NULL;
END;
$$;

-- ----------------------------------------------------------------------------
-- 8. reauction_unsold(auction_id)
-- Re-auction unsold players (re-queue them).
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION reauction_unsold(
  p_auction_id TEXT
)
RETURNS TABLE (
  success BOOLEAN,
  error_code TEXT,
  error_message TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_count INTEGER;
BEGIN
  IF v_user_id IS NULL THEN
    RETURN QUERY SELECT FALSE, 'auth_required', 'Authentication required';
  END IF;

  IF NOT _is_auction_operator(p_auction_id, v_user_id) THEN
    RETURN QUERY SELECT FALSE, 'not_authorized', 'Only auction operator can re-auction';
  END IF;

  UPDATE players SET status = 'available' WHERE auction_id = p_auction_id AND status = 'unsold';

  GET DIAGNOSTICS v_count = ROW_COUNT;

  PERFORM _log_activity(
    p_auction_id, 'players_reauctioned', 'auction', p_auction_id, NULL,
    NULL, NULL, NULL, NULL, NULL,
    jsonb_build_object('count', v_count),
    v_user_id::TEXT
  );

  RETURN QUERY SELECT TRUE, NULL, NULL;
END;
$$;

-- ----------------------------------------------------------------------------
-- 9. release_player(player_id)
-- Refund purse: remove player from team, refund purse_spent, status available.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION release_player(
  p_player_id TEXT
)
RETURNS TABLE (
  success BOOLEAN,
  error_code TEXT,
  error_message TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_player RECORD;
  v_team RECORD;
  v_auction_id TEXT;
BEGIN
  IF v_user_id IS NULL THEN
    RETURN QUERY SELECT FALSE, 'auth_required', 'Authentication required';
  END IF;

  SELECT * INTO v_player FROM players WHERE id = p_player_id FOR UPDATE;

  IF v_player IS NULL THEN
    RETURN QUERY SELECT FALSE, 'player_not_found', 'Player not found';
  END IF;

  IF v_player.status != 'sold' OR v_player.sold_team_id IS NULL THEN
    RETURN QUERY SELECT FALSE, 'player_not_sold', 'Player is not sold';
  END IF;

  v_auction_id := v_player.auction_id;

  IF NOT _is_auction_operator(v_auction_id, v_user_id) THEN
    RETURN QUERY SELECT FALSE, 'not_authorized', 'Only auction operator can release player';
  END IF;

  -- Lock the team
  SELECT * INTO v_team FROM teams WHERE id = v_player.sold_team_id FOR UPDATE;

  -- Refund purse: reduce purse_spent by sold_price
  UPDATE teams SET
    purse_spent = GREATEST(COALESCE(purse_spent, 0) - COALESCE(v_player.sold_price, 0), 0),
    player_ids = (
      SELECT jsonb_agg(elem) FROM jsonb_array_elements(COALESCE(player_ids, '[]'::jsonb)) AS elem
      WHERE elem->>'id' != p_player_id
    )
  WHERE id = v_player.sold_team_id;

  -- Release player
  UPDATE players SET
    status = 'available',
    sold_price = NULL,
    sold_team_id = NULL
  WHERE id = p_player_id;

  PERFORM _log_activity(
    v_auction_id, 'player_released', 'player', p_player_id, v_player.name,
    v_player.sold_team_id, v_team.name, p_player_id, v_player.name,
    v_player.sold_price, jsonb_build_object('refunded', v_player.sold_price),
    v_user_id::TEXT
  );

  RETURN QUERY SELECT TRUE, NULL, NULL;
END;
$$;

-- ----------------------------------------------------------------------------
-- 10. complete_auction(auction_id)
-- Mark auction as completed.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION complete_auction(
  p_auction_id TEXT
)
RETURNS TABLE (
  success BOOLEAN,
  error_code TEXT,
  error_message TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_state RECORD;
BEGIN
  IF v_user_id IS NULL THEN
    RETURN QUERY SELECT FALSE, 'auth_required', 'Authentication required';
  END IF;

  IF NOT _is_auction_operator(p_auction_id, v_user_id) THEN
    RETURN QUERY SELECT FALSE, 'not_authorized', 'Only auction operator can complete auction';
  END IF;

  SELECT * INTO v_state FROM auction_state WHERE auction_id = p_auction_id FOR UPDATE;

  IF v_state IS NULL THEN
    RETURN QUERY SELECT FALSE, 'auction_not_found', 'Auction state not found';
  END IF;

  UPDATE auctions SET status = 'completed' WHERE id = p_auction_id;

  UPDATE auction_state SET
    is_live = FALSE,
    updated_at = now(),
    updated_by = v_user_id::TEXT
  WHERE auction_id = p_auction_id;

  PERFORM _log_activity(
    p_auction_id, 'auction_completed', 'auction', p_auction_id, NULL,
    NULL, NULL, NULL, NULL, NULL,
    NULL,
    v_user_id::TEXT
  );

  RETURN QUERY SELECT TRUE, NULL, NULL;
END;
$$;

-- ----------------------------------------------------------------------------
-- 11. pick_next_player(auction_id, mode, category)
-- For auto/random/category-wise: pick the next available player.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION pick_next_player(
  p_auction_id TEXT,
  p_mode TEXT DEFAULT 'manual',
  p_category TEXT DEFAULT NULL
)
RETURNS TABLE (
  success BOOLEAN,
  error_code TEXT,
  error_message TEXT,
  player_id TEXT,
  player_name TEXT,
  player_no INTEGER,
  base_price DOUBLE PRECISION
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_next RECORD;
BEGIN
  IF v_user_id IS NULL THEN
    RETURN QUERY SELECT FALSE, 'auth_required', NULL, NULL, NULL, NULL;
  END IF;

  IF NOT _is_auction_operator(p_auction_id, v_user_id) THEN
    RETURN QUERY SELECT FALSE, 'not_authorized', NULL, NULL, NULL, NULL;
  END IF;

  IF p_mode = 'manual' THEN
    RETURN QUERY SELECT FALSE, 'manual_mode', 'Manual mode does not auto-pick players', NULL, NULL, NULL;
  END IF;

  -- Select next available player
  IF p_mode = 'categoryWise' AND p_category IS NOT NULL THEN
    SELECT * INTO v_next FROM players
    WHERE auction_id = p_auction_id AND status = 'available' AND category = p_category
    ORDER BY player_no LIMIT 1 FOR UPDATE;
  ELSIF p_mode = 'auto' THEN
    SELECT * INTO v_next FROM players
    WHERE auction_id = p_auction_id AND status = 'available'
    ORDER BY player_no LIMIT 1 FOR UPDATE;
  ELSE
    RETURN QUERY SELECT FALSE, 'invalid_mode', 'Invalid mode', NULL, NULL, NULL;
  END IF;

  IF v_next IS NULL THEN
    RETURN QUERY SELECT FALSE, 'no_players_available', 'No available players', NULL, NULL, NULL;
  END IF;

  RETURN QUERY SELECT TRUE, NULL, NULL, v_next.id, v_next.name, v_next.player_no, v_next.base_price;
END;
$$;

-- ----------------------------------------------------------------------------
-- Grant execute on all functions to authenticated users
-- ----------------------------------------------------------------------------
GRANT EXECUTE ON FUNCTION start_player(TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION place_bid(TEXT, TEXT, DOUBLE PRECISION) TO authenticated;
GRANT EXECUTE ON FUNCTION undo_last_bid(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION pause_auction(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION resume_auction(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION sell_player(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION mark_unsold(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION reset_player(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION reauction_unsold(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION release_player(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION complete_auction(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION pick_next_player(TEXT, TEXT, TEXT) TO authenticated;

-- ----------------------------------------------------------------------------
-- COMPLETE
-- ============================================================================
