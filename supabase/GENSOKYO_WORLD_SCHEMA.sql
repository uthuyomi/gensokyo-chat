-- Project Sigmaris - Gensokyo World (world_id + commands + event log)
-- ============================================================
-- Additive schema (safe to run multiple times).
-- Intended to be run in Supabase SQL Editor.
--
-- Goals:
-- - world_id is the primary unit (gensokyo_main, gensokyo_test, gensokyo_shard_01...)
-- - Command log (user intent) is append-only
-- - Event log (facts) is append-only with channel+seq ordering for replay
--
-- Notes:
-- - Service role bypasses RLS. Keep RLS off for these tables initially.
-- - When you need RLS later, add policies in a separate migration.
-- ============================================================

create extension if not exists pgcrypto;

-- --------------------------------------------
-- Worlds
-- --------------------------------------------

create table if not exists public.worlds (
  id text primary key,               -- world_id (e.g. gensokyo_main)
  layer_id text not null,            -- classification label (e.g. gensokyo)
  name text not null,
  created_at timestamptz not null default now()
);

-- --------------------------------------------
-- World state + snapshots (minimal, extensible)
-- --------------------------------------------

-- Current world state (per location). location_id='' means "global".
create table if not exists public.world_state (
  world_id text not null,
  location_id text not null default '',

  time_of_day text not null default 'day',  -- morning|day|evening|night
  weather text not null default 'clear',    -- clear|cloudy|rain|snow (extensible)
  season text not null default 'spring',    -- spring|summer|autumn|winter
  moon_phase text not null default 'unknown',
  anomaly jsonb,

  updated_at timestamptz not null default now(),
  primary key (world_id, location_id)
);

-- NPC snapshot (per npc_id). location_id='' means unknown/global.
create table if not exists public.world_npc_state (
  world_id text not null,
  npc_id text not null,

  location_id text not null default '',
  action text,
  emotion text,

  updated_at timestamptz not null default now(),
  primary key (world_id, npc_id)
);

create index if not exists idx_world_npc_state_world_loc
  on public.world_npc_state(world_id, location_id);

-- --------------------------------------------
-- NPC memory (swap-friendly containers)
-- --------------------------------------------

-- Short-term per-NPC state for throttling/cooldowns and tiny transient facts.
-- This is intentionally schema-light (JSON) so we can evolve without heavy migrations.
create table if not exists public.world_npc_memory_short (
  world_id text not null,
  npc_id text not null,

  state jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  primary key (world_id, npc_id)
);

create index if not exists idx_world_npc_memory_short_world_updated
  on public.world_npc_memory_short(world_id, updated_at desc);

-- Long-term memory is append-only. Start as a structured log; later, you can add embeddings/vector DB.
create table if not exists public.world_npc_memory_long (
  id uuid primary key default gen_random_uuid(),
  world_id text not null,
  npc_id text not null,

  ts timestamptz not null default now(),
  kind text not null default 'episode',     -- episode|relationship|note (extensible)
  summary text,
  payload jsonb not null default '{}'::jsonb
);

create index if not exists idx_world_npc_memory_long_world_npc_ts
  on public.world_npc_memory_long(world_id, npc_id, ts desc);

-- Visitor last visit per location (visitor_key can be user_id, session_id, etc.).
create table if not exists public.world_visits (
  world_id text not null,
  visitor_key text not null,
  location_id text not null,

  last_visit timestamptz not null,
  updated_at timestamptz not null default now(),
  primary key (world_id, visitor_key, location_id)
);

-- User state (for user_move / items / choices). Start simple; extend payload later.
create table if not exists public.world_user_state (
  world_id text not null,
  user_id uuid not null,

  location_id text not null default '',
  sub_location_id text,
  inventory jsonb not null default '{}'::jsonb,

  updated_at timestamptz not null default now(),
  primary key (world_id, user_id)
);

create index if not exists idx_world_user_state_world_loc
  on public.world_user_state(world_id, location_id);

-- --------------------------------------------
-- Realtime event channels + log
-- --------------------------------------------

create table if not exists public.world_event_channels (
  channel text primary key,          -- "world:{world_id}" or "world:{world_id}:{loc}"
  world_id text not null,
  layer_id text not null,
  location_id text,                  -- nullable for global channels
  current_seq bigint not null default 0,
  updated_at timestamptz not null default now()
);

create table if not exists public.world_event_log (
  id uuid primary key default gen_random_uuid(),
  channel text not null references public.world_event_channels(channel) on delete cascade,
  seq bigint not null,
  ts timestamptz not null default now(),

  world_id text not null,
  layer_id text not null,
  location_id text,

  type text not null,                -- "world_tick" | "npc_action" | "npc_say" | "system" (extensible)
  actor jsonb,
  payload jsonb not null default '{}'::jsonb
);

create unique index if not exists idx_world_event_log_channel_seq
  on public.world_event_log(channel, seq);

create index if not exists idx_world_event_log_channel_seq_desc
  on public.world_event_log(channel, seq desc);

create index if not exists idx_world_event_log_channel_ts_desc
  on public.world_event_log(channel, ts desc);

-- Atomic seq increment per channel.
create or replace function public.world_next_seq(
  p_channel text,
  p_world_id text,
  p_layer_id text,
  p_location_id text
) returns bigint
language plpgsql
security definer
as $$
declare
  v_seq bigint;
begin
  insert into public.world_event_channels(channel, world_id, layer_id, location_id, current_seq)
  values (p_channel, p_world_id, p_layer_id, nullif(p_location_id, ''), 0)
  on conflict (channel) do update
    set current_seq = public.world_event_channels.current_seq + 1,
        updated_at = now()
  returning current_seq into v_seq;

  -- If this was the first insert (seq=0), bump once so the first event becomes 1.
  if v_seq = 0 then
    update public.world_event_channels
      set current_seq = current_seq + 1,
          updated_at = now()
      where channel = p_channel
    returning current_seq into v_seq;
  end if;

  return v_seq;
end $$;

-- Append an event and return the inserted row.
create or replace function public.world_append_event(
  p_world_id text,
  p_layer_id text,
  p_location_id text,
  p_type text,
  p_actor jsonb,
  p_payload jsonb,
  p_ts timestamptz default null
) returns public.world_event_log
language plpgsql
security definer
as $$
declare
  v_channel text;
  v_seq bigint;
  v_row public.world_event_log;
begin
  v_channel :=
    case
      when p_location_id is null or p_location_id = '' then 'world:' || p_world_id
      else 'world:' || p_world_id || ':' || p_location_id
    end;

  v_seq := public.world_next_seq(v_channel, p_world_id, p_layer_id, p_location_id);

  insert into public.world_event_log(
    channel, seq, ts,
    world_id, layer_id, location_id,
    type, actor, payload
  )
  values (
    v_channel, v_seq, coalesce(p_ts, now()),
    p_world_id, p_layer_id, nullif(p_location_id, ''),
    p_type, p_actor, coalesce(p_payload, '{}'::jsonb)
  )
  returning * into v_row;

  return v_row;
end $$;

-- --------------------------------------------
-- Command log (user intent)
-- --------------------------------------------

create table if not exists public.world_command_log (
  id uuid primary key default gen_random_uuid(),

  world_id text not null,
  user_id uuid,

  type text not null,
  payload jsonb not null default '{}'::jsonb,

  dedupe_key text,
  correlation_id uuid not null default gen_random_uuid(),
  causation_id uuid,

  status text not null default 'queued',  -- queued|accepted|rejected|processing|done|failed
  error_code text,
  error_message text,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists idx_world_command_dedupe
  on public.world_command_log(world_id, dedupe_key)
  where dedupe_key is not null;

create index if not exists idx_world_command_world_time
  on public.world_command_log(world_id, created_at desc);

create index if not exists idx_world_command_corr
  on public.world_command_log(world_id, correlation_id);
