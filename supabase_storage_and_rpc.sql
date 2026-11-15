-- ============================================================================
-- JP AUCTION ARENA — Supabase Storage Buckets, RPC Functions & Policies
-- ============================================================================
-- Run this entire script in your Supabase project's SQL Editor.
-- Creates storage buckets for tournament logos and player photos,
-- sets up public-read/authenticated-write storage policies, and installs
-- the create_auction_with_teams() RPC for atomic auction+team creation.
-- Safe to run multiple times (uses idempotent patterns).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. STORAGE BUCKETS
-- ----------------------------------------------------------------------------
-- Public buckets: anyone can read (public URLs), only authenticated users can write.

insert into storage.buckets (id, name, public)
values ('logos', 'logos', true)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public)
values ('player-photos', 'player-photos', true)
on conflict (id) do nothing;

-- ----------------------------------------------------------------------------
-- 2. STORAGE POLICIES — logos bucket
-- ----------------------------------------------------------------------------
-- Public read access (anyone can view tournament logos)
drop policy if exists "Public read access for logos" on storage.objects;
create policy "Public read access for logos"
on storage.objects
for select
using (bucket_id = 'logos');

-- Authenticated upload (only signed-in users can upload logos)
drop policy if exists "Authenticated upload for logos" on storage.objects;
create policy "Authenticated upload for logos"
on storage.objects
for insert
with check (bucket_id = 'logos' and auth.role() = 'authenticated');

-- Authenticated update (owners can update their uploads)
drop policy if exists "Authenticated update for logos" on storage.objects;
create policy "Authenticated update for logos"
on storage.objects
for update
using (bucket_id = 'logos' and auth.role() = 'authenticated');

-- Authenticated delete
drop policy if exists "Authenticated delete for logos" on storage.objects;
create policy "Authenticated delete for logos"
on storage.objects
for delete
using (bucket_id = 'logos' and auth.role() = 'authenticated');

-- ----------------------------------------------------------------------------
-- 3. STORAGE POLICIES — player-photos bucket
-- ----------------------------------------------------------------------------
drop policy if exists "Public read access for player-photos" on storage.objects;
create policy "Public read access for player-photos"
on storage.objects
for select
using (bucket_id = 'player-photos');

drop policy if exists "Authenticated upload for player-photos" on storage.objects;
create policy "Authenticated upload for player-photos"
on storage.objects
for insert
with check (bucket_id = 'player-photos' and auth.role() = 'authenticated');

drop policy if exists "Authenticated update for player-photos" on storage.objects;
create policy "Authenticated update for player-photos"
on storage.objects
for update
using (bucket_id = 'player-photos' and auth.role() = 'authenticated');

drop policy if exists "Authenticated delete for player-photos" on storage.objects;
create policy "Authenticated delete for player-photos"
on storage.objects
for delete
using (bucket_id = 'player-photos' and auth.role() = 'authenticated');

-- ----------------------------------------------------------------------------
-- 4. RPC: create_auction_with_teams(auction_data jsonb, teams jsonb[])
-- ----------------------------------------------------------------------------
-- Atomically creates one auction row plus N team rows in a single transaction.
-- Returns the auction_id and array of team_ids.
-- Only callable by authenticated users (creator set to auth.uid()).
-- ----------------------------------------------------------------------------
create or replace function create_auction_with_teams(
  p_auction_data jsonb,
  p_teams jsonb[]
)
returns table (
  auction_id text,
  team_ids text[]
)
language plpgsql
as $$
declare
  v_auction_id text;
begin
  -- 1. Insert the auction row
  insert into auctions (
    id,
    name,
    logo_base64,
    venue,
    description,
    start_date_time,
    status,
    categories,
    number_of_teams,
    min_squad,
    max_squad,
    base_price_default,
    bid_increment,
    team_purse,
    countdown_seconds,
    mode,
    created_at,
    contact_phone,
    contact_email,
    category_base_prices,
    reserve_purse_rule,
    smart_bid_slabs,
    created_by
  ) values (
    coalesce(p_auction_data->>'id', gen_random_uuid()::text),
    p_auction_data->>'name',
    p_auction_data->>'logo_base64',
    p_auction_data->>'venue',
    p_auction_data->>'description',
    (p_auction_data->>'start_date_time')::timestamptz,
    coalesce(p_auction_data->>'status', 'draft'),
    p_auction_data->'categories',
    (p_auction_data->>'number_of_teams')::int,
    (p_auction_data->>'min_squad')::int,
    (p_auction_data->>'max_squad')::int,
    (p_auction_data->>'base_price_default')::numeric,
    (p_auction_data->>'bid_increment')::numeric,
    (p_auction_data->>'team_purse')::numeric,
    (p_auction_data->>'countdown_seconds')::int,
    coalesce(p_auction_data->>'mode', 'manual'),
    now(),
    p_auction_data->>'contact_phone',
    p_auction_data->>'contact_email',
    p_auction_data->'category_base_prices',
    coalesce((p_auction_data->>'reserve_purse_rule')::boolean, true),
    coalesce((p_auction_data->>'smart_bid_slabs')::boolean, false),
    auth.uid()::text
  )
  returning id into v_auction_id;

  -- 2. Insert team rows (if any provided)
  if p_teams is not null then
    for i in 1..jsonb_array_length(p_teams) loop
      insert into teams (
        id,
        auction_id,
        name,
        logo_base64,
        owner_name,
        purse_total,
        purse_spent,
        player_ids,
        created_at,
        created_by
      ) values (
        coalesce((p_teams[i - 1]->>'id')::text, gen_random_uuid()::text),
        v_auction_id,
        p_teams[i - 1]->>'name',
        p_teams[i - 1]->>'logo_base64',
        p_teams[i - 1]->>'owner_name',
        (p_teams[i - 1]->>'purse_total')::numeric,
        0,
        '[]'::jsonb,
        now(),
        auth.uid()::text
      );
    end loop;
  end if;

  -- 3. Return auction_id + array of team_ids
  select v_auction_id, array_agg(t.id)
  into auction_id, team_ids
  from teams t
  where t.auction_id = v_auction_id;

  return;
end;
$$;

-- Grant execute on the RPC to authenticated users
grant execute on function create_auction_with_teams(jsonb, jsonb[]) to authenticated;

-- ----------------------------------------------------------------------------
-- 5. INDEXES for realtime performance
-- ----------------------------------------------------------------------------
create index if not exists idx_teams_auction_id on teams(auction_id);
create index if not exists idx_players_auction_id on players(auction_id);
create index if not exists idx_players_status on players(status);
create index if not exists idx_bids_auction_id on bids(auction_id);
create index if not exists idx_bids_player_id on bids(player_id);

-- ----------------------------------------------------------------------------
-- COMPLETE
-- ============================================================================
