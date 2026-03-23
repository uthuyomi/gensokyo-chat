-- BEGIN FILE: WORLD_SCHEMA_CORE.sql
-- World schema core
-- Generated from WORLD_FULL_SETUP.sql for maintainable split loading.

-- Gensokyo World Full Setup
-- ============================================================
-- Run this file in Supabase SQL Editor.
-- It creates the world-prefixed base tables, story-event tables,
-- history/memory tables, replay log tables, and a small starter dataset.
--
-- Design rules:
-- - Shared canon lives in world_* tables.
-- - Per-user variation is stored as overlays, not canon overwrites.
-- - Story events are phase-driven and queryable.
-- - Existing world-engine compatibility tables remain available.
-- ============================================================

create extension if not exists pgcrypto;

create table if not exists public.worlds (
  id text primary key,
  layer_id text not null,
  name text not null,
  created_at timestamptz not null default now()
);


create table if not exists public.world_state (
  world_id text not null,
  location_id text not null default '',
  time_of_day text not null default 'day',
  weather text not null default 'clear',
  season text not null default 'spring',
  moon_phase text not null default 'unknown',
  anomaly jsonb,
  updated_at timestamptz not null default now(),
  primary key (world_id, location_id)
);

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

create table if not exists public.world_npc_memory_short (
  world_id text not null,
  npc_id text not null,
  state jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  primary key (world_id, npc_id)
);

create index if not exists idx_world_npc_memory_short_world_updated
  on public.world_npc_memory_short(world_id, updated_at desc);

create table if not exists public.world_npc_memory_long (
  id uuid primary key default gen_random_uuid(),
  world_id text not null,
  npc_id text not null,
  ts timestamptz not null default now(),
  kind text not null default 'episode',
  summary text,
  payload jsonb not null default '{}'::jsonb
);

create index if not exists idx_world_npc_memory_long_world_npc_ts
  on public.world_npc_memory_long(world_id, npc_id, ts desc);

create table if not exists public.world_visits (
  world_id text not null,
  visitor_key text not null,
  location_id text not null,
  last_visit timestamptz not null,
  updated_at timestamptz not null default now(),
  primary key (world_id, visitor_key, location_id)
);

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

create table if not exists public.world_event_channels (
  channel text primary key,
  world_id text not null,
  layer_id text not null,
  location_id text,
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
  type text not null,
  actor jsonb,
  payload jsonb not null default '{}'::jsonb
);

create unique index if not exists idx_world_event_log_channel_seq
  on public.world_event_log(channel, seq);

create index if not exists idx_world_event_log_channel_seq_desc
  on public.world_event_log(channel, seq desc);

create index if not exists idx_world_event_log_channel_ts_desc
  on public.world_event_log(channel, ts desc);

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

  if v_seq = 0 then
    update public.world_event_channels
      set current_seq = current_seq + 1,
          updated_at = now()
      where channel = p_channel
    returning current_seq into v_seq;
  end if;

  return v_seq;
end $$;

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

create table if not exists public.world_command_log (
  id uuid primary key default gen_random_uuid(),
  world_id text not null,
  user_id uuid,
  type text not null,
  payload jsonb not null default '{}'::jsonb,
  dedupe_key text,
  correlation_id uuid not null default gen_random_uuid(),
  causation_id uuid,
  status text not null default 'queued',
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

create table if not exists public.world_locations (
  world_id text not null references public.worlds(id) on delete cascade,
  id text not null,
  name text not null,
  kind text not null default 'location',
  parent_location_id text,
  title text,
  summary text,
  description text,
  tags jsonb not null default '[]'::jsonb,
  default_mood text,
  neighbors jsonb not null default '[]'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (world_id, id)
);

create index if not exists idx_world_locations_parent
  on public.world_locations(world_id, parent_location_id);

create table if not exists public.world_characters (
  world_id text not null references public.worlds(id) on delete cascade,
  id text not null,
  name text not null,
  title text,
  species text,
  faction_id text,
  home_location_id text,
  default_location_id text,
  public_summary text,
  private_notes text,
  speech_style text,
  worldview text,
  role_in_gensokyo text,
  tags jsonb not null default '[]'::jsonb,
  profile jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (world_id, id)
);

create table if not exists public.world_relationship_edges (
  world_id text not null references public.worlds(id) on delete cascade,
  source_character_id text not null,
  target_character_id text not null,
  relation_type text not null,
  summary text,
  strength numeric(5,2) not null default 0,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (world_id, source_character_id, target_character_id, relation_type)
);

create index if not exists idx_world_relationship_edges_target
  on public.world_relationship_edges(world_id, target_character_id);

create table if not exists public.world_lore_entries (
  world_id text not null references public.worlds(id) on delete cascade,
  id text not null,
  category text not null,
  title text not null,
  summary text not null,
  details jsonb not null default '{}'::jsonb,
  tags jsonb not null default '[]'::jsonb,
  priority integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (world_id, id)
);

create table if not exists public.world_story_events (
  id text primary key,
  world_id text not null references public.worlds(id) on delete cascade,
  event_code text not null,
  title text not null,
  theme text not null,
  canon_level text not null default 'official',
  status text not null default 'draft',
  start_at timestamptz,
  end_at timestamptz,
  current_phase_id text,
  current_phase_order integer,
  lead_location_id text,
  organizer_character_id text,
  synopsis text,
  narrative_hook text,
  payload jsonb not null default '{}'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (world_id, event_code)
);

create index if not exists idx_world_story_events_world_status
  on public.world_story_events(world_id, status, start_at desc nulls last);

create table if not exists public.world_story_phases (
  id text primary key,
  event_id text not null references public.world_story_events(id) on delete cascade,
  phase_code text not null,
  phase_order integer not null,
  title text not null,
  status text not null default 'pending',
  summary text,
  start_condition jsonb not null default '{}'::jsonb,
  end_condition jsonb not null default '{}'::jsonb,
  required_beats jsonb not null default '[]'::jsonb,
  allowed_locations jsonb not null default '[]'::jsonb,
  active_cast jsonb not null default '[]'::jsonb,
  starts_at timestamptz,
  ends_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (event_id, phase_code),
  unique (event_id, phase_order)
);

create index if not exists idx_world_story_phases_event_order
  on public.world_story_phases(event_id, phase_order);

create table if not exists public.world_story_beats (
  id text primary key,
  event_id text not null references public.world_story_events(id) on delete cascade,
  phase_id text references public.world_story_phases(id) on delete cascade,
  beat_code text not null,
  beat_kind text not null default 'scene',
  title text not null,
  summary text not null,
  location_id text,
  actor_ids jsonb not null default '[]'::jsonb,
  is_required boolean not null default false,
  status text not null default 'planned',
  happens_at timestamptz,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (event_id, beat_code)
);

create index if not exists idx_world_story_beats_event_phase
  on public.world_story_beats(event_id, phase_id);

create table if not exists public.world_story_cast (
  id text primary key,
  event_id text not null references public.world_story_events(id) on delete cascade,
  character_id text not null,
  role_type text not null,
  knowledge_level text not null default 'aware',
  must_appear boolean not null default false,
  primary_location_id text,
  availability jsonb not null default '{}'::jsonb,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (event_id, character_id)
);

create index if not exists idx_world_story_cast_event_role
  on public.world_story_cast(event_id, role_type);

create table if not exists public.world_story_actions (
  id text primary key,
  event_id text not null references public.world_story_events(id) on delete cascade,
  phase_id text references public.world_story_phases(id) on delete cascade,
  action_code text not null,
  title text not null,
  description text not null,
  action_kind text not null default 'talk',
  location_id text,
  actor_id text,
  is_repeatable boolean not null default false,
  is_active boolean not null default true,
  result_summary text,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (event_id, action_code)
);

create index if not exists idx_world_story_actions_event_phase
  on public.world_story_actions(event_id, phase_id);

create table if not exists public.world_story_history (
  id text primary key,
  world_id text not null references public.worlds(id) on delete cascade,
  event_id text not null references public.world_story_events(id) on delete cascade,
  phase_id text references public.world_story_phases(id) on delete set null,
  history_kind text not null,
  fact_summary text not null,
  location_id text,
  actor_ids jsonb not null default '[]'::jsonb,
  payload jsonb not null default '{}'::jsonb,
  committed_at timestamptz not null default now()
);

create index if not exists idx_world_story_history_world_time
  on public.world_story_history(world_id, committed_at desc);

create index if not exists idx_world_story_history_event_time
  on public.world_story_history(event_id, committed_at desc);

create table if not exists public.world_character_memories (
  id text primary key,
  world_id text not null references public.worlds(id) on delete cascade,
  character_id text not null,
  event_id text references public.world_story_events(id) on delete set null,
  history_id text references public.world_story_history(id) on delete set null,
  memory_type text not null default 'event',
  importance integer not null default 1,
  summary text not null,
  stance text,
  knows_truth boolean not null default true,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_world_character_memories_character_time
  on public.world_character_memories(world_id, character_id, created_at desc);

create table if not exists public.world_user_story_overlays (
  id text primary key,
  world_id text not null references public.worlds(id) on delete cascade,
  user_id uuid not null,
  event_id text references public.world_story_events(id) on delete cascade,
  phase_id text references public.world_story_phases(id) on delete set null,
  overlay_type text not null,
  summary text not null,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_world_user_story_overlays_user_time
  on public.world_user_story_overlays(world_id, user_id, created_at desc);

create table if not exists public.world_story_projections (
  world_id text not null references public.worlds(id) on delete cascade,
  location_id text not null default '',
  user_scope text not null default 'global',
  projection_type text not null,
  event_id text references public.world_story_events(id) on delete cascade,
  title text not null,
  phase_label text,
  summary text not null,
  actor_ids jsonb not null default '[]'::jsonb,
  payload jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  primary key (world_id, location_id, user_scope, projection_type)
);

create index if not exists idx_world_story_projections_world_location
  on public.world_story_projections(world_id, location_id, updated_at desc);

create or replace function public.world_story_refresh_projection(
  p_event_id text
) returns void
language plpgsql
security definer
as $$
declare
  v_event public.world_story_events;
  v_phase public.world_story_phases;
begin
  select * into v_event
  from public.world_story_events
  where id = p_event_id;

  if v_event.id is null then
    return;
  end if;

  if v_event.current_phase_id is not null then
    select * into v_phase
    from public.world_story_phases
    where id = v_event.current_phase_id;
  end if;

  insert into public.world_story_projections(
    world_id,
    location_id,
    user_scope,
    projection_type,
    event_id,
    title,
    phase_label,
    summary,
    actor_ids,
    payload,
    updated_at
  )
  values (
    v_event.world_id,
    coalesce(v_event.lead_location_id, ''),
    'global',
    'active_story',
    v_event.id,
    v_event.title,
    coalesce(v_phase.title, null),
    coalesce(v_phase.summary, v_event.synopsis, ''),
    coalesce(v_phase.active_cast, '[]'::jsonb),
    jsonb_build_object(
      'event_id', v_event.id,
      'status', v_event.status,
      'theme', v_event.theme,
      'narrative_hook', v_event.narrative_hook
    ),
    now()
  )
  on conflict (world_id, location_id, user_scope, projection_type)
  do update set
    event_id = excluded.event_id,
    title = excluded.title,
    phase_label = excluded.phase_label,
    summary = excluded.summary,
    actor_ids = excluded.actor_ids,
    payload = excluded.payload,
    updated_at = excluded.updated_at;
end $$;

create or replace function public.world_story_advance_phase(
  p_event_id text,
  p_phase_id text,
  p_summary text default null
) returns jsonb
language plpgsql
security definer
as $$
declare
  v_event public.world_story_events;
  v_phase public.world_story_phases;
begin
  select * into v_event
  from public.world_story_events
  where id = p_event_id;

  select * into v_phase
  from public.world_story_phases
  where id = p_phase_id
    and event_id = p_event_id;

  if v_event.id is null then
    return jsonb_build_object('ok', false, 'error', 'event_not_found');
  end if;

  if v_phase.id is null then
    return jsonb_build_object('ok', false, 'error', 'phase_not_found');
  end if;

  update public.world_story_phases
    set status =
      case
        when id = p_phase_id then 'active'
        when phase_order < v_phase.phase_order then 'completed'
        else 'pending'
      end,
      updated_at = now(),
      starts_at =
        case
          when id = p_phase_id and starts_at is null then now()
          else starts_at
        end,
      ends_at =
        case
          when phase_order < v_phase.phase_order and ends_at is null then now()
          else ends_at
        end
  where event_id = p_event_id;

  update public.world_story_events
    set current_phase_id = v_phase.id,
        current_phase_order = v_phase.phase_order,
        status = case when status = 'draft' then 'active' else status end,
        updated_at = now()
  where id = p_event_id;

  insert into public.world_story_history(
    id,
    world_id,
    event_id,
    phase_id,
    history_kind,
    fact_summary,
    location_id,
    actor_ids,
    payload,
    committed_at
  )
  values (
    p_event_id || ':advance:' || replace(gen_random_uuid()::text, '-', ''),
    v_event.world_id,
    p_event_id,
    v_phase.id,
    'phase_advanced',
    coalesce(p_summary, v_phase.summary, v_phase.title),
    v_event.lead_location_id,
    coalesce(v_phase.active_cast, '[]'::jsonb),
    jsonb_build_object('phase_id', v_phase.id, 'phase_order', v_phase.phase_order),
    now()
  );

  perform public.world_story_refresh_projection(p_event_id);

  return jsonb_build_object(
    'ok', true,
    'event_id', p_event_id,
    'phase_id', v_phase.id,
    'phase_order', v_phase.phase_order,
    'phase_title', v_phase.title
  );
end $$;


create table if not exists public.world_source_index (
  id text primary key,
  world_id text not null references public.worlds(id) on delete cascade,
  source_kind text not null,
  source_code text not null,
  title text not null,
  short_label text,
  notes text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (world_id, source_code)
);

create table if not exists public.world_canon_claims (
  id text primary key,
  world_id text not null references public.worlds(id) on delete cascade,
  subject_type text not null,
  subject_id text not null,
  claim_type text not null,
  summary text not null,
  details jsonb not null default '{}'::jsonb,
  source_id text references public.world_source_index(id) on delete set null,
  confidence text not null default 'official',
  priority integer not null default 0,
  tags jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_world_canon_claims_subject
  on public.world_canon_claims(world_id, subject_type, subject_id, priority desc);

create table if not exists public.world_derivative_overlays (
  id text primary key,
  world_id text not null references public.worlds(id) on delete cascade,
  overlay_scope text not null,
  subject_type text not null,
  subject_id text not null,
  title text not null,
  summary text not null,
  payload jsonb not null default '{}'::jsonb,
  enabled boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_world_derivative_overlays_subject
  on public.world_derivative_overlays(world_id, overlay_scope, subject_type, subject_id);


create table if not exists public.world_chronicle_books (
  id text primary key,
  world_id text not null references public.worlds(id) on delete cascade,
  title text not null,
  author_character_id text,
  chronicle_type text not null default 'history',
  era_label text,
  summary text not null,
  tone text,
  is_public boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_world_chronicle_books_world_type
  on public.world_chronicle_books(world_id, chronicle_type, updated_at desc);

create table if not exists public.world_chronicle_chapters (
  id text primary key,
  book_id text not null references public.world_chronicle_books(id) on delete cascade,
  chapter_code text not null,
  chapter_order integer not null,
  title text not null,
  summary text not null,
  period_start timestamptz,
  period_end timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (book_id, chapter_code),
  unique (book_id, chapter_order)
);

create index if not exists idx_world_chronicle_chapters_book_order
  on public.world_chronicle_chapters(book_id, chapter_order);

create table if not exists public.world_chronicle_entries (
  id text primary key,
  book_id text not null references public.world_chronicle_books(id) on delete cascade,
  chapter_id text references public.world_chronicle_chapters(id) on delete set null,
  entry_code text not null,
  entry_order integer not null default 1,
  entry_type text not null default 'article',
  title text not null,
  summary text not null,
  body text not null,
  subject_type text,
  subject_id text,
  narrator_character_id text,
  event_id text references public.world_story_events(id) on delete set null,
  history_id text references public.world_story_history(id) on delete set null,
  tags jsonb not null default '[]'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (book_id, entry_code)
);

create index if not exists idx_world_chronicle_entries_book_chapter
  on public.world_chronicle_entries(book_id, chapter_id, entry_order);

create table if not exists public.world_chronicle_entry_sources (
  id text primary key,
  entry_id text not null references public.world_chronicle_entries(id) on delete cascade,
  source_kind text not null,
  source_ref_id text not null,
  source_label text,
  weight numeric(5,2) not null default 1.0,
  notes text,
  created_at timestamptz not null default now()
);

create index if not exists idx_world_chronicle_entry_sources_entry
  on public.world_chronicle_entry_sources(entry_id, source_kind);

create table if not exists public.world_historian_notes (
  id text primary key,
  world_id text not null references public.worlds(id) on delete cascade,
  historian_character_id text not null,
  subject_type text not null,
  subject_id text not null,
  note_kind text not null default 'editorial',
  title text not null,
  summary text not null,
  body text not null,
  source_ref_ids jsonb not null default '[]'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_world_historian_notes_subject
  on public.world_historian_notes(world_id, historian_character_id, subject_type, subject_id, updated_at desc);

create table if not exists public.world_wiki_pages (
  id text primary key,
  world_id text not null references public.worlds(id) on delete cascade,
  slug text not null,
  title text not null,
  page_type text not null,
  subject_type text,
  subject_id text,
  summary text not null,
  status text not null default 'published',
  canonical_book_id text references public.world_chronicle_books(id) on delete set null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (world_id, slug)
);

create index if not exists idx_world_wiki_pages_subject
  on public.world_wiki_pages(world_id, page_type, subject_type, subject_id);

create table if not exists public.world_wiki_page_sections (
  id text primary key,
  page_id text not null references public.world_wiki_pages(id) on delete cascade,
  section_code text not null,
  section_order integer not null,
  heading text not null,
  summary text,
  body text not null,
  source_ref_ids jsonb not null default '[]'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (page_id, section_code),
  unique (page_id, section_order)
);

create index if not exists idx_world_wiki_page_sections_page_order
  on public.world_wiki_page_sections(page_id, section_order);

create table if not exists public.world_chat_context_cache (
  id text primary key,
  world_id text not null references public.worlds(id) on delete cascade,
  user_scope text not null default 'global',
  character_id text,
  location_id text,
  event_id text references public.world_story_events(id) on delete set null,
  context_type text not null,
  summary text not null,
  payload jsonb not null default '{}'::jsonb,
  freshness_score numeric(5,2) not null default 1.0,
  last_used_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_world_chat_context_cache_lookup
  on public.world_chat_context_cache(world_id, user_scope, character_id, location_id, context_type, updated_at desc);

create table if not exists public.world_user_chat_summaries (
  id text primary key,
  world_id text not null references public.worlds(id) on delete cascade,
  user_id uuid not null,
  character_id text,
  location_id text,
  event_id text references public.world_story_events(id) on delete set null,
  summary_type text not null default 'conversation',
  summary text not null,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_world_user_chat_summaries_lookup
  on public.world_user_chat_summaries(world_id, user_id, character_id, location_id, updated_at desc);

create table if not exists public.world_user_seen_entries (
  world_id text not null references public.worlds(id) on delete cascade,
  user_id uuid not null,
  entry_type text not null,
  entry_id text not null,
  first_seen_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now(),
  metadata jsonb not null default '{}'::jsonb,
  primary key (world_id, user_id, entry_type, entry_id)
);

create index if not exists idx_world_user_seen_entries_user_time
  on public.world_user_seen_entries(world_id, user_id, last_seen_at desc);


-- END FILE: WORLD_SCHEMA_CORE.sql

-- BEGIN FILE: WORLD_SCHEMA_VECTOR.sql
-- World schema: vector-ready document and embedding layer
-- This layer keeps structured canon as the source of truth and adds
-- searchable document projections for vector indexing and later visualization.

create extension if not exists vector;

create table if not exists public.world_embedding_documents (
  id text primary key,
  world_id text not null references public.worlds(id) on delete cascade,
  source_kind text not null,
  source_ref_id text not null,
  source_title text not null,
  content text not null,
  source_updated_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (world_id, source_kind, source_ref_id)
);

create index if not exists idx_world_embedding_documents_lookup
  on public.world_embedding_documents(world_id, source_kind, source_ref_id);

create table if not exists public.world_embedding_jobs (
  id text primary key,
  world_id text not null references public.worlds(id) on delete cascade,
  document_id text references public.world_embedding_documents(id) on delete cascade,
  job_kind text not null default 'embed',
  status text not null default 'pending',
  embedding_model text,
  error_message text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_world_embedding_jobs_world_status
  on public.world_embedding_jobs(world_id, status, created_at desc);

create table if not exists public.world_embeddings (
  id text primary key,
  world_id text not null references public.worlds(id) on delete cascade,
  document_id text not null references public.world_embedding_documents(id) on delete cascade,
  embedding_model text not null,
  embedding_dimensions integer not null,
  embedding vector(1536),
  content_hash text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (document_id, embedding_model)
);

create index if not exists idx_world_embeddings_world_model
  on public.world_embeddings(world_id, embedding_model, updated_at desc);

create or replace view public.world_embedding_source_counts as
select world_id, source_kind, count(*) as document_count
from public.world_embedding_documents
group by world_id, source_kind;

create or replace function public.world_refresh_embedding_documents(
  p_world_id text default null
) returns jsonb
language plpgsql
security definer
as $$
declare
  v_scope text;
  v_doc_count integer;
begin
  v_scope := coalesce(p_world_id, '');

  insert into public.world_embedding_documents (
    id,
    world_id,
    source_kind,
    source_ref_id,
    source_title,
    content,
    source_updated_at,
    metadata,
    updated_at
  )
  select
    'doc:canon_claim:' || c.id,
    c.world_id,
    'canon_claim',
    c.id,
    coalesce(c.summary, c.id),
    trim(
      both from concat_ws(
        E'\n\n',
        'Claim: ' || c.summary,
        'Subject: ' || c.subject_type || ' / ' || c.subject_id,
        'Claim Type: ' || c.claim_type,
        'Details: ' || coalesce(c.details::text, '{}')
      )
    ),
    c.updated_at,
    jsonb_build_object(
      'subject_type', c.subject_type,
      'subject_id', c.subject_id,
      'claim_type', c.claim_type,
      'source_id', c.source_id,
      'tags', c.tags,
      'confidence', c.confidence,
      'priority', c.priority
    ),
    now()
  from public.world_canon_claims c
  where p_world_id is null or c.world_id = p_world_id
  on conflict (id) do update
  set source_title = excluded.source_title,
      content = excluded.content,
      source_updated_at = excluded.source_updated_at,
      metadata = excluded.metadata,
      updated_at = excluded.updated_at;

  insert into public.world_embedding_documents (
    id,
    world_id,
    source_kind,
    source_ref_id,
    source_title,
    content,
    source_updated_at,
    metadata,
    updated_at
  )
  select
    'doc:lore:' || l.id,
    l.world_id,
    'lore_entry',
    l.id,
    l.title,
    trim(
      both from concat_ws(
        E'\n\n',
        l.title,
        l.summary,
        'Category: ' || l.category,
        'Details: ' || coalesce(l.details::text, '{}')
      )
    ),
    l.updated_at,
    jsonb_build_object(
      'category', l.category,
      'tags', l.tags,
      'priority', l.priority
    ),
    now()
  from public.world_lore_entries l
  where p_world_id is null or l.world_id = p_world_id
  on conflict (id) do update
  set source_title = excluded.source_title,
      content = excluded.content,
      source_updated_at = excluded.source_updated_at,
      metadata = excluded.metadata,
      updated_at = excluded.updated_at;

  insert into public.world_embedding_documents (
    id,
    world_id,
    source_kind,
    source_ref_id,
    source_title,
    content,
    source_updated_at,
    metadata,
    updated_at
  )
  select
    'doc:wiki_page:' || p.id,
    p.world_id,
    'wiki_page',
    p.id,
    p.title,
    trim(
      both from concat_ws(
        E'\n\n',
        p.title,
        p.summary,
        coalesce(
          string_agg(
            ws.heading || E'\n' || coalesce(ws.summary || E'\n', '') || ws.body,
            E'\n\n'
            order by ws.section_order
          ),
          ''
        )
      )
    ),
    greatest(
      p.updated_at,
      coalesce(max(ws.updated_at), p.updated_at)
    ),
    jsonb_build_object(
      'page_type', p.page_type,
      'subject_type', p.subject_type,
      'subject_id', p.subject_id,
      'status', p.status,
      'canonical_book_id', p.canonical_book_id
    ),
    now()
  from public.world_wiki_pages p
  left join public.world_wiki_page_sections ws
    on ws.page_id = p.id
  where p_world_id is null or p.world_id = p_world_id
  group by
    p.id,
    p.world_id,
    p.title,
    p.summary,
    p.page_type,
    p.subject_type,
    p.subject_id,
    p.status,
    p.canonical_book_id,
    p.updated_at
  on conflict (id) do update
  set source_title = excluded.source_title,
      content = excluded.content,
      source_updated_at = excluded.source_updated_at,
      metadata = excluded.metadata,
      updated_at = excluded.updated_at;

  insert into public.world_embedding_documents (
    id,
    world_id,
    source_kind,
    source_ref_id,
    source_title,
    content,
    source_updated_at,
    metadata,
    updated_at
  )
  select
    'doc:chronicle_entry:' || e.id,
    b.world_id,
    'chronicle_entry',
    e.id,
    e.title,
    trim(
      both from concat_ws(
        E'\n\n',
        e.title,
        e.summary,
        e.body
      )
    ),
    e.updated_at,
    jsonb_build_object(
      'book_id', e.book_id,
      'chapter_id', e.chapter_id,
      'entry_code', e.entry_code,
      'entry_type', e.entry_type,
      'subject_type', e.subject_type,
      'subject_id', e.subject_id,
      'tags', e.tags
    ),
    now()
  from public.world_chronicle_entries e
  join public.world_chronicle_books b
    on b.id = e.book_id
  where p_world_id is null or b.world_id = p_world_id
  on conflict (id) do update
  set source_title = excluded.source_title,
      content = excluded.content,
      source_updated_at = excluded.source_updated_at,
      metadata = excluded.metadata,
      updated_at = excluded.updated_at;

  insert into public.world_embedding_documents (
    id,
    world_id,
    source_kind,
    source_ref_id,
    source_title,
    content,
    source_updated_at,
    metadata,
    updated_at
  )
  select
    'doc:chat_context:' || c.id,
    c.world_id,
    'chat_context',
    c.id,
    c.context_type || ':' || coalesce(c.character_id, c.location_id, c.id),
    trim(
      both from concat_ws(
        E'\n\n',
        c.summary,
        'Context Type: ' || c.context_type,
        case when c.character_id is not null then 'Character: ' || c.character_id else null end,
        case when c.location_id is not null and c.location_id <> '' then 'Location: ' || c.location_id else null end,
        case when c.event_id is not null then 'Event: ' || c.event_id else null end,
        'Payload: ' || coalesce(c.payload::text, '{}')
      )
    ),
    c.updated_at,
    jsonb_build_object(
      'user_scope', c.user_scope,
      'character_id', c.character_id,
      'location_id', c.location_id,
      'event_id', c.event_id,
      'context_type', c.context_type,
      'freshness_score', c.freshness_score
    ),
    now()
  from public.world_chat_context_cache c
  where p_world_id is null or c.world_id = p_world_id
  on conflict (id) do update
  set source_title = excluded.source_title,
      content = excluded.content,
      source_updated_at = excluded.source_updated_at,
      metadata = excluded.metadata,
      updated_at = excluded.updated_at;

  delete from public.world_embedding_documents d
  where (p_world_id is null or d.world_id = p_world_id)
    and d.source_kind = 'canon_claim'
    and not exists (
      select 1 from public.world_canon_claims c
      where c.id = d.source_ref_id
        and c.world_id = d.world_id
    );

  delete from public.world_embedding_documents d
  where (p_world_id is null or d.world_id = p_world_id)
    and d.source_kind = 'lore_entry'
    and not exists (
      select 1 from public.world_lore_entries l
      where l.id = d.source_ref_id
        and l.world_id = d.world_id
    );

  delete from public.world_embedding_documents d
  where (p_world_id is null or d.world_id = p_world_id)
    and d.source_kind = 'wiki_page'
    and not exists (
      select 1 from public.world_wiki_pages p
      where p.id = d.source_ref_id
        and p.world_id = d.world_id
    );

  delete from public.world_embedding_documents d
  where (p_world_id is null or d.world_id = p_world_id)
    and d.source_kind = 'chronicle_entry'
    and not exists (
      select 1
      from public.world_chronicle_entries e
      join public.world_chronicle_books b on b.id = e.book_id
      where e.id = d.source_ref_id
        and b.world_id = d.world_id
    );

  delete from public.world_embedding_documents d
  where (p_world_id is null or d.world_id = p_world_id)
    and d.source_kind = 'chat_context'
    and not exists (
      select 1 from public.world_chat_context_cache c
      where c.id = d.source_ref_id
        and c.world_id = d.world_id
    );

  select count(*)
  into v_doc_count
  from public.world_embedding_documents d
  where p_world_id is null or d.world_id = p_world_id;

  return jsonb_build_object(
    'ok', true,
    'world_id', nullif(v_scope, ''),
    'document_count', v_doc_count
  );
end $$;

create or replace function public.world_queue_embedding_refresh(
  p_world_id text default null
) returns integer
language plpgsql
security definer
as $$
declare
  v_count integer;
begin
  insert into public.world_embedding_jobs (
    id,
    world_id,
    document_id,
    job_kind,
    status,
    embedding_model,
    metadata,
    updated_at
  )
  select
    'job:embed:' || d.id,
    d.world_id,
    d.id,
    'embed',
    'pending',
    null,
    jsonb_build_object('source_kind', d.source_kind, 'source_ref_id', d.source_ref_id),
    now()
  from public.world_embedding_documents d
  where p_world_id is null or d.world_id = p_world_id
  on conflict (id) do update
  set status = 'pending',
      error_message = null,
      metadata = excluded.metadata,
      updated_at = now();

  select count(*)
  into v_count
  from public.world_embedding_jobs j
  where j.status = 'pending'
    and (p_world_id is null or j.world_id = p_world_id);

  return v_count;
end $$;

create or replace function public.world_match_embeddings(
  p_world_id text,
  p_query_embedding vector(1536),
  p_match_count integer default 10,
  p_source_kind text default null,
  p_embedding_model text default null
) returns table (
  document_id text,
  source_kind text,
  source_ref_id text,
  source_title text,
  content text,
  metadata jsonb,
  distance double precision
)
language sql
stable
as $$
  select
    d.id as document_id,
    d.source_kind,
    d.source_ref_id,
    d.source_title,
    d.content,
    d.metadata,
    (e.embedding <=> p_query_embedding) as distance
  from public.world_embeddings e
  join public.world_embedding_documents d
    on d.id = e.document_id
  where d.world_id = p_world_id
    and e.embedding is not null
    and (p_source_kind is null or d.source_kind = p_source_kind)
    and (p_embedding_model is null or e.embedding_model = p_embedding_model)
  order by e.embedding <=> p_query_embedding
  limit greatest(p_match_count, 1);
$$;

-- END FILE: WORLD_SCHEMA_VECTOR.sql

-- BEGIN FILE: WORLD_SEED_LORE.sql
-- World seed: worlds, runtime seed, lore, sources, claims
-- Generated from WORLD_FULL_SETUP.sql for maintainable split loading.

insert into public.worlds (id, layer_id, name)
values ('gensokyo_main', 'gensokyo', 'Gensokyo Main World')
on conflict (id) do update
set layer_id = excluded.layer_id,
    name = excluded.name;

insert into public.world_locations (
  world_id, id, name, kind, parent_location_id, title, summary, description, tags, default_mood, neighbors, metadata
)
values
  (
    'gensokyo_main',
    'hakurei_shrine',
    'Hakurei Shrine',
    'major_location',
    null,
    'Boundary Shrine',
    'A shrine that often becomes the center of incidents and seasonal gatherings.',
    'A public shrine where humans, youkai, and trouble all tend to gather.',
    '["shrine","public","outdoor"]'::jsonb,
    'restless',
    '["human_village","youkai_mountain_foot"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'human_village',
    'Human Village',
    'major_location',
    null,
    'Human Settlement',
    'The social center of human life in Gensokyo and a natural rumor hub.',
    'Busy streets, merchants, and the fastest way for a rumor to become common knowledge.',
    '["village","public","busy"]'::jsonb,
    'busy',
    '["hakurei_shrine","forest_of_magic"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'forest_of_magic',
    'Forest of Magic',
    'major_location',
    null,
    'Mysterious Forest',
    'A quiet but dangerous forest associated with magic and solitary work.',
    'Dense woods, mushroom patches, and a lot of room for private schemes.',
    '["forest","quiet","magic"]'::jsonb,
    'hushed',
    '["human_village"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'youkai_mountain_foot',
    'Youkai Mountain Foot',
    'major_location',
    null,
    'Mountain Approach',
    'The foot of Youkai Mountain, where many visitors hesitate before going further.',
    'A transitional space between ordinary roads and the territory of mountain dwellers.',
    '["mountain","outdoor"]'::jsonb,
    'watchful',
    '["hakurei_shrine","kappa_workshop"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'kappa_workshop',
    'Kappa Workshop',
    'major_location',
    null,
    'Workshop',
    'A place where mechanisms, repairs, and suspiciously efficient improvements gather.',
    'Tools, sketches, and prototypes are always somewhere nearby.',
    '["indoor","kappa","engineering"]'::jsonb,
    'focused',
    '["youkai_mountain_foot"]'::jsonb,
    '{}'::jsonb
  )
on conflict (world_id, id) do update
set name = excluded.name,
    kind = excluded.kind,
    parent_location_id = excluded.parent_location_id,
    title = excluded.title,
    summary = excluded.summary,
    description = excluded.description,
    tags = excluded.tags,
    default_mood = excluded.default_mood,
    neighbors = excluded.neighbors,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_characters (
  world_id, id, name, title, species, faction_id, home_location_id, default_location_id,
  public_summary, private_notes, speech_style, worldview, role_in_gensokyo, tags, profile
)
values
  (
    'gensokyo_main', 'reimu', 'Reimu Hakurei', 'Shrine Maiden', 'human', 'hakurei',
    'hakurei_shrine', 'hakurei_shrine',
    'The shrine maiden who keeps order, even when she is tired of doing so.',
    'Treats most incidents pragmatically and dislikes unnecessary hassle.',
    'dry, direct, practical',
    'Balance matters more than ceremony.',
    'incident_resolver',
    '["lead","shrine","official"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['gensokyo_public', 'incident_response'], 'temperament', 'pragmatic')
  ),
  (
    'gensokyo_main', 'marisa', 'Marisa Kirisame', 'Ordinary Magician', 'human', 'independent',
    'forest_of_magic', 'forest_of_magic',
    'A fast-moving magician who barges into interesting situations.',
    'Curiosity often beats caution.',
    'casual, bold, teasing',
    'Interesting trouble is better than dull safety.',
    'instigator',
    '["lead","magic","mobile"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['gensokyo_public', 'local_rumors'], 'temperament', 'curious')
  ),
  (
    'gensokyo_main', 'sanae', 'Sanae Kochiya', 'Wind Priestess', 'human', 'moriya',
    'youkai_mountain_foot', 'youkai_mountain_foot',
    'An earnest shrine maiden who often frames events positively.',
    'Tends to approach shared events with enthusiasm and structure.',
    'bright, sincere, proactive',
    'Momentum can turn a gathering into a success.',
    'support',
    '["support","ritual","festival"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['gensokyo_public', 'moriya_affairs'], 'temperament', 'earnest')
  ),
  (
    'gensokyo_main', 'nitori', 'Nitori Kawashiro', 'Engineer Kappa', 'kappa', 'kappa',
    'kappa_workshop', 'kappa_workshop',
    'A kappa engineer who sees systems, bottlenecks, and opportunities everywhere.',
    'Likes mechanisms that can actually survive production.',
    'playful, analytical, crafty',
    'If it works cleanly, it was worth building.',
    'engineer',
    '["kappa","engineering","observer"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['gensokyo_public', 'mechanisms', 'mountain_trade'], 'temperament', 'inventive')
  ),
  (
    'gensokyo_main', 'aya', 'Aya Shameimaru', 'Tengu Reporter', 'tengu', 'tengu',
    'youkai_mountain_foot', 'youkai_mountain_foot',
    'A reporter who can turn any disturbance into a headline.',
    'Always hunting for angles, reactions, and speed.',
    'fast, dramatic, probing',
    'A story does not spread itself.',
    'observer',
    '["reporter","tengu","rumor"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['gensokyo_public', 'rumors'], 'temperament', 'opportunistic')
  )
on conflict (world_id, id) do update
set name = excluded.name,
    title = excluded.title,
    species = excluded.species,
    faction_id = excluded.faction_id,
    home_location_id = excluded.home_location_id,
    default_location_id = excluded.default_location_id,
    public_summary = excluded.public_summary,
    private_notes = excluded.private_notes,
    speech_style = excluded.speech_style,
    worldview = excluded.worldview,
    role_in_gensokyo = excluded.role_in_gensokyo,
    tags = excluded.tags,
    profile = excluded.profile,
    updated_at = now();

insert into public.world_relationship_edges (
  world_id, source_character_id, target_character_id, relation_type, summary, strength, metadata
)
values
  ('gensokyo_main', 'reimu', 'marisa', 'familiar_rival', 'They bicker, cooperate, and understand each other more than they admit.', 0.82, '{}'::jsonb),
  ('gensokyo_main', 'marisa', 'reimu', 'familiar_rival', 'She treats the shrine as a place she can barge into whenever she wants.', 0.82, '{}'::jsonb),
  ('gensokyo_main', 'reimu', 'sanae', 'competing_peer', 'Shared work with different instincts and different priorities.', 0.58, '{}'::jsonb),
  ('gensokyo_main', 'sanae', 'reimu', 'competing_peer', 'Wants cooperation, but sees the same job through a different lens.', 0.58, '{}'::jsonb),
  ('gensokyo_main', 'nitori', 'aya', 'mutual_observer', 'Both notice movement quickly, but for very different reasons.', 0.51, '{}'::jsonb)
on conflict (world_id, source_character_id, target_character_id, relation_type) do update
set summary = excluded.summary,
    strength = excluded.strength,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  (
    'gensokyo_main',
    'lore_gensokyo_balance',
    'world_rule',
    'Balance Between Human and Youkai',
    'Most incidents and gatherings are constrained by the need to keep Gensokyo stable enough to continue.',
    jsonb_build_object('constraint', 'No seasonal event should permanently break the balance of Gensokyo.'),
    '["canon","balance","constraint"]'::jsonb,
    100
  ),
  (
    'gensokyo_main',
    'lore_hakurei_role',
    'character_role',
    'Hakurei Shrine Role',
    'The Hakurei Shrine is both a public face of order and a magnet for trouble.',
    jsonb_build_object('character_id', 'reimu'),
    '["reimu","shrine","canon"]'::jsonb,
    90
  ),
  (
    'gensokyo_main',
    'lore_village_rumor',
    'location_trait',
    'Human Village Rumor Flow',
    'The Human Village amplifies half-heard stories into public mood very quickly.',
    jsonb_build_object('location_id', 'human_village'),
    '["village","rumor"]'::jsonb,
    70
  )
on conflict (world_id, id) do update
set category = excluded.category,
    title = excluded.title,
    summary = excluded.summary,
    details = excluded.details,
    tags = excluded.tags,
    priority = excluded.priority,
    updated_at = now();

insert into public.world_state (
  world_id, location_id, time_of_day, weather, season, moon_phase, anomaly
)
values
  ('gensokyo_main', '', 'day', 'clear', 'spring', 'waxing', null),
  ('gensokyo_main', 'hakurei_shrine', 'day', 'clear', 'spring', 'waxing', null),
  ('gensokyo_main', 'human_village', 'day', 'clear', 'spring', 'waxing', null),
  ('gensokyo_main', 'forest_of_magic', 'day', 'clear', 'spring', 'waxing', null),
  ('gensokyo_main', 'kappa_workshop', 'day', 'clear', 'spring', 'waxing', null)
on conflict (world_id, location_id) do update
set time_of_day = excluded.time_of_day,
    weather = excluded.weather,
    season = excluded.season,
    moon_phase = excluded.moon_phase,
    anomaly = excluded.anomaly,
    updated_at = now();

insert into public.world_npc_state (
  world_id, npc_id, location_id, action, emotion
)
values
  ('gensokyo_main', 'reimu', 'hakurei_shrine', 'organizing', 'guarded'),
  ('gensokyo_main', 'marisa', 'forest_of_magic', 'preparing', 'curious'),
  ('gensokyo_main', 'sanae', 'youkai_mountain_foot', 'coordinating', 'optimistic'),
  ('gensokyo_main', 'nitori', 'kappa_workshop', 'building', 'focused'),
  ('gensokyo_main', 'aya', 'human_village', 'gathering_rumors', 'interested')
on conflict (world_id, npc_id) do update
set location_id = excluded.location_id,
    action = excluded.action,
    emotion = excluded.emotion,
    updated_at = now();

insert into public.world_story_events (
  id, world_id, event_code, title, theme, canon_level, status,
  start_at, end_at, current_phase_id, current_phase_order,
  lead_location_id, organizer_character_id, synopsis, narrative_hook, payload, metadata
)
values (
  'story_spring_festival_001',
  'gensokyo_main',
  'spring_festival_001',
  'Hakurei Spring Festival',
  'A seasonal gathering that mixes celebration, preparation pressure, and uneven enthusiasm.',
  'official',
  'active',
  now() - interval '6 hour',
  now() + interval '6 day',
  'story_spring_festival_001:phase:preparation',
  2,
  'hakurei_shrine',
  'reimu',
  'Preparation is visible now, but not everyone attached to the event wants the same kind of success.',
  'The shrine looks lively, but the people driving the festival are not aligned yet.',
  jsonb_build_object('source_type', 'seed'),
  '{}'::jsonb
)
on conflict (id) do update
set world_id = excluded.world_id,
    event_code = excluded.event_code,
    title = excluded.title,
    theme = excluded.theme,
    canon_level = excluded.canon_level,
    status = excluded.status,
    start_at = excluded.start_at,
    end_at = excluded.end_at,
    current_phase_id = excluded.current_phase_id,
    current_phase_order = excluded.current_phase_order,
    lead_location_id = excluded.lead_location_id,
    organizer_character_id = excluded.organizer_character_id,
    synopsis = excluded.synopsis,
    narrative_hook = excluded.narrative_hook,
    payload = excluded.payload,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_story_phases (
  id, event_id, phase_code, phase_order, title, status, summary,
  start_condition, end_condition, required_beats, allowed_locations, active_cast, metadata
)
values
  (
    'story_spring_festival_001:phase:rumor',
    'story_spring_festival_001',
    'rumor',
    1,
    'Rumors Spread',
    'completed',
    'Word has spread through the Human Village that the shrine will host a seasonal event.',
    '{}'::jsonb,
    '{}'::jsonb,
    '["rumor_spreads"]'::jsonb,
    '["human_village","hakurei_shrine"]'::jsonb,
    '["aya","reimu"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'story_spring_festival_001:phase:preparation',
    'story_spring_festival_001',
    'preparation',
    2,
    'Preparation',
    'active',
    'The shrine is visibly preparing, but the people involved still disagree on pace, tone, and priorities.',
    '{}'::jsonb,
    '{}'::jsonb,
    '["decorations_arrive","roles_not_aligned"]'::jsonb,
    '["hakurei_shrine","human_village","kappa_workshop"]'::jsonb,
    '["reimu","marisa","sanae","nitori"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'story_spring_festival_001:phase:festival',
    'story_spring_festival_001',
    'festival',
    3,
    'Festival Day',
    'pending',
    'The festival opens with visible energy, but small frictions shape how each participant experiences it.',
    '{}'::jsonb,
    '{}'::jsonb,
    '["opening_scene","crowd_forms"]'::jsonb,
    '["hakurei_shrine"]'::jsonb,
    '["reimu","marisa","sanae","aya"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'story_spring_festival_001:phase:aftermath',
    'story_spring_festival_001',
    'aftermath',
    4,
    'Aftermath',
    'pending',
    'The gathering passes into memory and each character keeps a different impression of what mattered.',
    '{}'::jsonb,
    '{}'::jsonb,
    '["cleanup","retrospective"]'::jsonb,
    '["hakurei_shrine","human_village"]'::jsonb,
    '["reimu","marisa","sanae"]'::jsonb,
    '{}'::jsonb
  )
on conflict (id) do update
set status = excluded.status,
    summary = excluded.summary,
    required_beats = excluded.required_beats,
    allowed_locations = excluded.allowed_locations,
    active_cast = excluded.active_cast,
    updated_at = now();

insert into public.world_story_beats (
  id, event_id, phase_id, beat_code, beat_kind, title, summary, location_id,
  actor_ids, is_required, status, happens_at, payload
)
values
  (
    'story_spring_festival_001:beat:rumor_spreads',
    'story_spring_festival_001',
    'story_spring_festival_001:phase:rumor',
    'rumor_spreads',
    'rumor',
    'Village Rumor',
    'The Human Village begins talking about the upcoming shrine festival as if it is already inevitable.',
    'human_village',
    '["aya"]'::jsonb,
    true,
    'committed',
    now() - interval '4 hour',
    '{}'::jsonb
  ),
  (
    'story_spring_festival_001:beat:decorations_arrive',
    'story_spring_festival_001',
    'story_spring_festival_001:phase:preparation',
    'decorations_arrive',
    'scene',
    'Decorations Arrive',
    'Festival materials and decoration ideas reach the shrine, making the event feel real.',
    'hakurei_shrine',
    '["sanae","reimu"]'::jsonb,
    true,
    'committed',
    now() - interval '2 hour',
    '{}'::jsonb
  ),
  (
    'story_spring_festival_001:beat:roles_not_aligned',
    'story_spring_festival_001',
    'story_spring_festival_001:phase:preparation',
    'roles_not_aligned',
    'tension',
    'Uneven Priorities',
    'Everyone involved wants the festival to succeed, but not in the same way or for the same reason.',
    'hakurei_shrine',
    '["reimu","marisa","sanae"]'::jsonb,
    true,
    'planned',
    null,
    '{}'::jsonb
  )
on conflict (id) do update
set title = excluded.title,
    summary = excluded.summary,
    actor_ids = excluded.actor_ids,
    is_required = excluded.is_required,
    status = excluded.status,
    happens_at = excluded.happens_at,
    updated_at = now();

insert into public.world_story_cast (
  id, event_id, character_id, role_type, knowledge_level, must_appear, primary_location_id, availability, notes
)
values
  ('story_spring_festival_001:cast:reimu', 'story_spring_festival_001', 'reimu', 'lead', 'full', true, 'hakurei_shrine', '{}'::jsonb, 'Primary organizer, reluctant center of gravity.'),
  ('story_spring_festival_001:cast:marisa', 'story_spring_festival_001', 'marisa', 'disruptor', 'partial', true, 'hakurei_shrine', '{}'::jsonb, 'Adds motion, pressure, and perspective shifts.'),
  ('story_spring_festival_001:cast:sanae', 'story_spring_festival_001', 'sanae', 'support', 'full', true, 'hakurei_shrine', '{}'::jsonb, 'Keeps pushing the event forward.'),
  ('story_spring_festival_001:cast:nitori', 'story_spring_festival_001', 'nitori', 'support', 'partial', false, 'kappa_workshop', '{}'::jsonb, 'Can contribute practical support and a technical viewpoint.'),
  ('story_spring_festival_001:cast:aya', 'story_spring_festival_001', 'aya', 'observer', 'full', false, 'human_village', '{}'::jsonb, 'Turns developments into public mood.')
on conflict (id) do update
set role_type = excluded.role_type,
    knowledge_level = excluded.knowledge_level,
    must_appear = excluded.must_appear,
    primary_location_id = excluded.primary_location_id,
    availability = excluded.availability,
    notes = excluded.notes,
    updated_at = now();

insert into public.world_story_actions (
  id, event_id, phase_id, action_code, title, description, action_kind, location_id, actor_id,
  is_repeatable, is_active, result_summary, payload
)
values
  (
    'story_spring_festival_001:action:talk_reimu',
    'story_spring_festival_001',
    'story_spring_festival_001:phase:preparation',
    'talk_reimu',
    'Ask Reimu About Preparations',
    'Talk with Reimu about how the shrine is handling the festival preparations.',
    'talk',
    'hakurei_shrine',
    'reimu',
    true,
    true,
    'The player gains Reimu''s practical view of the festival and its burden.',
    '{}'::jsonb
  ),
  (
    'story_spring_festival_001:action:hear_rumors',
    'story_spring_festival_001',
    'story_spring_festival_001:phase:preparation',
    'hear_rumors',
    'Collect Village Rumors',
    'Listen to how the Human Village is talking about the shrine festival.',
    'investigate',
    'human_village',
    'aya',
    true,
    true,
    'The player sees how public mood is shaping the event before it fully opens.',
    '{}'::jsonb
  ),
  (
    'story_spring_festival_001:action:help_preparation',
    'story_spring_festival_001',
    'story_spring_festival_001:phase:preparation',
    'help_preparation',
    'Help With Preparation',
    'Take part in light support work so the event feels like something you actually touched.',
    'assist',
    'hakurei_shrine',
    'sanae',
    false,
    true,
    'The player gains a participation record tied to the preparation phase.',
    '{}'::jsonb
  )
on conflict (id) do update
set title = excluded.title,
    description = excluded.description,
    action_kind = excluded.action_kind,
    location_id = excluded.location_id,
    actor_id = excluded.actor_id,
    is_repeatable = excluded.is_repeatable,
    is_active = excluded.is_active,
    result_summary = excluded.result_summary,
    updated_at = now();

insert into public.world_story_history (
  id, world_id, event_id, phase_id, history_kind, fact_summary, location_id, actor_ids, payload, committed_at
)
values
  (
    'story_spring_festival_001:history:opening_rumor',
    'gensokyo_main',
    'story_spring_festival_001',
    'story_spring_festival_001:phase:rumor',
    'canon_fact',
    'The Human Village has already started treating the upcoming spring festival as a real public event.',
    'human_village',
    '["aya"]'::jsonb,
    '{}'::jsonb,
    now() - interval '4 hour'
  ),
  (
    'story_spring_festival_001:history:preparation_visible',
    'gensokyo_main',
    'story_spring_festival_001',
    'story_spring_festival_001:phase:preparation',
    'canon_fact',
    'Preparation at Hakurei Shrine is now visible enough that anyone visiting can tell a larger gathering is coming.',
    'hakurei_shrine',
    '["reimu","sanae"]'::jsonb,
    '{}'::jsonb,
    now() - interval '2 hour'
  )
on conflict (id) do update
set history_kind = excluded.history_kind,
    fact_summary = excluded.fact_summary,
    location_id = excluded.location_id,
    actor_ids = excluded.actor_ids,
    payload = excluded.payload,
    committed_at = excluded.committed_at;

insert into public.world_character_memories (
  id, world_id, character_id, event_id, history_id, memory_type, importance, summary, stance, knows_truth, payload
)
values
  (
    'story_spring_festival_001:memory:reimu:prep',
    'gensokyo_main',
    'reimu',
    'story_spring_festival_001',
    'story_spring_festival_001:history:preparation_visible',
    'event',
    4,
    'The spring festival has become real work now, not just talk.',
    'burdened',
    true,
    '{}'::jsonb
  ),
  (
    'story_spring_festival_001:memory:marisa:prep',
    'gensokyo_main',
    'marisa',
    'story_spring_festival_001',
    'story_spring_festival_001:history:preparation_visible',
    'event',
    3,
    'The shrine is finally lively enough that barging in might be worth it.',
    'amused',
    true,
    '{}'::jsonb
  ),
  (
    'story_spring_festival_001:memory:aya:rumor',
    'gensokyo_main',
    'aya',
    'story_spring_festival_001',
    'story_spring_festival_001:history:opening_rumor',
    'event',
    3,
    'The village rumor cycle has already attached itself to the shrine festival.',
    'eager',
    true,
    '{}'::jsonb
  )
on conflict (id) do update
set memory_type = excluded.memory_type,
    importance = excluded.importance,
    summary = excluded.summary,
    stance = excluded.stance,
    knows_truth = excluded.knows_truth,
    payload = excluded.payload;

select public.world_story_refresh_projection('story_spring_festival_001');

insert into public.world_event_channels(channel, world_id, layer_id, location_id, current_seq)
values
  ('world:gensokyo_main', 'gensokyo_main', 'gensokyo', null, 0),
  ('world:gensokyo_main:hakurei_shrine', 'gensokyo_main', 'gensokyo', 'hakurei_shrine', 0)
on conflict (channel) do update
set world_id = excluded.world_id,
    layer_id = excluded.layer_id,
    location_id = excluded.location_id,
    current_seq = excluded.current_seq,
    updated_at = now();

insert into public.world_locations (
  world_id, id, name, kind, parent_location_id, title, summary, description, tags, default_mood, neighbors, metadata
)
values
  ('gensokyo_main','misty_lake','Misty Lake','major_location',null,'Lake Region','A lakeside area associated with fairies, chill air, and the Scarlet Devil Mansion approach.','A visible natural landmark where casual encounters and light trouble happen easily.','["lake","outdoor","fairy"]'::jsonb,'playful','["scarlet_devil_mansion","human_village"]'::jsonb,'{}'::jsonb),
  ('gensokyo_main','scarlet_devil_mansion','Scarlet Devil Mansion','major_location',null,'Mansion','A high-profile mansion run by vampires, servants, and residents with strong personalities.','A powerful household where hospitality, danger, and pride coexist.','["mansion","indoors","elite"]'::jsonb,'ornate','["misty_lake"]'::jsonb,'{}'::jsonb),
  ('gensokyo_main','bamboo_forest','Bamboo Forest of the Lost','major_location',null,'Bamboo Forest','A confusing forest region where orientation is unreliable and secrets are easy to hide.','Travel here is rarely straightforward, and what you find depends on who guides you.','["forest","maze","bamboo"]'::jsonb,'uncertain','["eientei","human_village"]'::jsonb,'{}'::jsonb),
  ('gensokyo_main','eientei','Eientei','major_location',null,'Remote Residence','A hidden residence tied to medicine, the moon, and people who prefer controlled distance.','Quiet on the surface, but full of knowledge, restraint, and complicated history.','["estate","medicine","lunar"]'::jsonb,'private','["bamboo_forest"]'::jsonb,'{}'::jsonb),
  ('gensokyo_main','netherworld','Netherworld','major_location',null,'Netherworld','A realm associated with spirits, cherry blossoms, and boundaries between life and death.','Beautiful, distant, and often treated with more etiquette than ordinary land.','["afterlife","spirits","boundary"]'::jsonb,'elegant','["hakugyokurou"]'::jsonb,'{}'::jsonb),
  ('gensokyo_main','hakugyokurou','Hakugyokurou','major_location','netherworld','Ghostly Mansion','A residence in the Netherworld where graceful stillness and sharp swordsmanship coexist.','A formal place that still holds personal habits, appetites, and loyalties.','["mansion","spirits","formal"]'::jsonb,'solemn','["netherworld"]'::jsonb,'{}'::jsonb),
  ('gensokyo_main','moriya_shrine','Moriya Shrine','major_location',null,'Mountain Shrine','A shrine on Youkai Mountain tied to active faith-gathering and outside-world methods.','More proactive and expansion-minded than the Hakurei Shrine.','["shrine","mountain","faith"]'::jsonb,'driven','["youkai_mountain_foot"]'::jsonb,'{}'::jsonb),
  ('gensokyo_main','former_hell','Former Hell','major_location',null,'Underground Region','A subterranean region tied to former Hell, oni, and dangerous strength.','Social rules here are different, but they are still rules.','["underground","oni","dangerous"]'::jsonb,'rowdy','["old_capital"]'::jsonb,'{}'::jsonb),
  ('gensokyo_main','old_capital','Old Capital','major_location','former_hell','Underground City','A lively underground settlement with oni culture and its own rhythms.','A place where boldness and social force matter.','["underground","city","oni"]'::jsonb,'loud','["former_hell"]'::jsonb,'{}'::jsonb),
  ('gensokyo_main','muenzuka','Muenzuka','major_location',null,'Border Field','A border-like field associated with abandoned things and difficult crossings.','A place that feels close to the outside while still belonging to Gensokyo.','["boundary","field","liminal"]'::jsonb,'lonely','["human_village"]'::jsonb,'{}'::jsonb),
  ('gensokyo_main','genbu_ravine','Genbu Ravine','major_location',null,'Mountain Ravine','A ravine on the way into mountain territory, associated with kappa movement and terrain control.','The kind of place where engineering and geography meet.','["mountain","ravine","kappa"]'::jsonb,'alert','["youkai_mountain_foot","kappa_workshop"]'::jsonb,'{}'::jsonb),
  ('gensokyo_main','myouren_temple','Myouren Temple','major_location',null,'Temple','A temple tied to coexistence, discipline, and a broad range of residents.','A social-religious center with a different tone from the shrines.','["temple","religion","community"]'::jsonb,'welcoming','["human_village"]'::jsonb,'{}'::jsonb)
on conflict (world_id, id) do update
set name = excluded.name,
    kind = excluded.kind,
    parent_location_id = excluded.parent_location_id,
    title = excluded.title,
    summary = excluded.summary,
    description = excluded.description,
    tags = excluded.tags,
    default_mood = excluded.default_mood,
    neighbors = excluded.neighbors,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_characters (
  world_id, id, name, title, species, faction_id, home_location_id, default_location_id,
  public_summary, private_notes, speech_style, worldview, role_in_gensokyo, tags, profile
)
values
  ('gensokyo_main','sakuya','Sakuya Izayoi','Head Maid','human','sdm','scarlet_devil_mansion','scarlet_devil_mansion','The efficient maid of the Scarlet Devil Mansion, closely tied to order and service.','Treats the mansion''s structure and dignity as things to actively maintain.','precise, composed, understated','Control and timing matter.','household_manager','["maid","sdm","disciplined"]'::jsonb,jsonb_build_object('knowledge_scope',array['mansion_affairs','gensokyo_public'],'temperament','controlled')),
  ('gensokyo_main','remilia','Remilia Scarlet','Mistress of the Mansion','vampire','sdm','scarlet_devil_mansion','scarlet_devil_mansion','A vampire noble who treats authority and style as natural extensions of herself.','Pride and playfulness often coexist in the same decision.','dramatic, confident, aristocratic','Power should feel natural when wielded.','elite_actor','["vampire","sdm","leader"]'::jsonb,jsonb_build_object('knowledge_scope',array['mansion_affairs','incident_scale'],'temperament','proud')),
  ('gensokyo_main','flandre','Flandre Scarlet','Younger Vampire','vampire','sdm','scarlet_devil_mansion','scarlet_devil_mansion','A dangerous but deeply individual presence within the Scarlet Devil Mansion household.','Not someone to use casually in public event structures.','blunt, curious, unstable','Interest matters more than routine.','volatile_actor','["vampire","sdm","volatile"]'::jsonb,jsonb_build_object('knowledge_scope',array['mansion_internal'],'temperament','volatile')),
  ('gensokyo_main','patchouli','Patchouli Knowledge','Magician Librarian','magician','sdm','scarlet_devil_mansion','scarlet_devil_mansion','A reclusive magician whose knowledge and preparation outweigh haste.','More likely to influence events through planning than by rushing into them.','quiet, exact, intellectual','Preparation is often better than impulse.','scholar','["magician","sdm","library"]'::jsonb,jsonb_build_object('knowledge_scope',array['magic','books','incident_analysis'],'temperament','reserved')),
  ('gensokyo_main','alice','Alice Margatroid','Seven-Colored Puppeteer','magician','independent','forest_of_magic','forest_of_magic','A magician known for careful craft, distance, and controlled presentation.','Usually enters a scene on her own terms.','measured, cool, refined','Control creates elegance.','craft_specialist','["magician","puppets","independent"]'::jsonb,jsonb_build_object('knowledge_scope',array['magic','craft'],'temperament','composed')),
  ('gensokyo_main','youmu','Youmu Konpaku','Gardener and Sword Instructor','half-human half-phantom','hakugyokurou','hakugyokurou','hakugyokurou','A disciplined swordswoman balancing duty, speed, and frequent earnestness.','Strongly shaped by service and responsibility.','earnest, direct, respectful','Duty should be carried through cleanly.','retainer','["sword","netherworld","disciplined"]'::jsonb,jsonb_build_object('knowledge_scope',array['hakugyokurou','netherworld'],'temperament','earnest')),
  ('gensokyo_main','yuyuko','Yuyuko Saigyouji','Ghost Princess','ghost','hakugyokurou','hakugyokurou','hakugyokurou','A graceful ghostly noble whose lightness of manner can hide deeper awareness.','Often appears easygoing while seeing more than she says.','gentle, whimsical, elegant','Lightness can coexist with certainty.','noble_observer','["ghost","netherworld","noble"]'::jsonb,jsonb_build_object('knowledge_scope',array['netherworld','boundaries'],'temperament','playful')),
  ('gensokyo_main','yukari','Yukari Yakumo','Boundary Youkai','youkai','yakumo','muenzuka','muenzuka','A boundary youkai tied to high-level movement, distance, and hidden design.','Not suitable for casual overuse in everyday event structures.','relaxed, layered, elusive','Distance and framing decide outcomes.','boundary_actor','["youkai","boundary","high_impact"]'::jsonb,jsonb_build_object('knowledge_scope',array['gensokyo_structure','boundaries'],'temperament','scheming')),
  ('gensokyo_main','chen','Chen','Shikigami Cat','bakeneko','yakumo','muenzuka','human_village','A quick-moving shikigami whose presence often feels immediate and physical.','Works better in local scenes than in abstract planning.','energetic, straightforward, lively','Move first, think while moving.','messenger','["cat","shikigami","mobile"]'::jsonb,jsonb_build_object('knowledge_scope',array['yakumo_household'],'temperament','lively')),
  ('gensokyo_main','ran','Ran Yakumo','Shikigami Fox','kitsune','yakumo','muenzuka','muenzuka','A capable shikigami who blends administrative competence with strong loyalty.','Often the operational layer beneath Yukari''s scale.','polite, intelligent, controlled','Structure supports freedom better than chaos does.','administrator','["fox","shikigami","competent"]'::jsonb,jsonb_build_object('knowledge_scope',array['yakumo_household','administration'],'temperament','controlled')),
  ('gensokyo_main','keine','Keine Kamishirasawa','Village Teacher','were-hakutaku','human_village','human_village','human_village','A teacher and protector strongly tied to the Human Village and its continuity.','Very useful when social stability and village context matter.','firm, caring, instructive','Continuity is worth defending.','protector','["teacher","village","protector"]'::jsonb,jsonb_build_object('knowledge_scope',array['human_village','local_history'],'temperament','protective')),
  ('gensokyo_main','mokou','Fujiwara no Mokou','Immortal Human','human','independent','bamboo_forest','bamboo_forest','An immortal wanderer with a blunt, grounded presence and a personal history that runs deep.','Can anchor stories around endurance, grudges, and practical protection.','blunt, plainspoken, steady','Keep moving and deal with things directly.','wanderer','["immortal","bamboo","fighter"]'::jsonb,jsonb_build_object('knowledge_scope',array['bamboo_forest','long_term_history'],'temperament','steady')),
  ('gensokyo_main','eirin','Eirin Yagokoro','Lunar Pharmacist','lunarian','eientei','eientei','eientei','A highly capable pharmacist and strategist tied to Eientei and lunar history.','Not someone whose presence should be treated lightly in broad public events.','calm, brilliant, clinical','A precise solution is worth waiting for.','strategist','["medicine","lunar","strategist"]'::jsonb,jsonb_build_object('knowledge_scope',array['medicine','lunar_history','eientei'],'temperament','brilliant')),
  ('gensokyo_main','kaguya','Kaguya Houraisan','Lunar Princess','lunarian','eientei','eientei','eientei','A princess whose elegance, pride, and detachment shape how she engages with others.','Events around her tend to take on symbolic weight quickly.','refined, ironic, proud','Time and status change how patience feels.','noble_actor','["princess","lunar","eientei"]'::jsonb,jsonb_build_object('knowledge_scope',array['lunar_history','eientei'],'temperament','proud')),
  ('gensokyo_main','reisen','Reisen Udongein Inaba','Moon Rabbit','moon rabbit','eientei','eientei','eientei','A moon rabbit tied to medicine work, discipline, and occasional anxiety under pressure.','Works well in practical scenes that still carry lunar context.','polite, anxious, diligent','Hold the line even if you are nervous.','assistant','["rabbit","lunar","assistant"]'::jsonb,jsonb_build_object('knowledge_scope',array['eientei','medicine'],'temperament','diligent')),
  ('gensokyo_main','kanako','Kanako Yasaka','Mountain Goddess','goddess','moriya','moriya_shrine','moriya_shrine','A goddess who approaches faith, systems, and influence proactively.','Often frames plans in terms of scale and gain.','confident, strategic, expansive','Faith should be gathered, not merely awaited.','power_broker','["goddess","moriya","leadership"]'::jsonb,jsonb_build_object('knowledge_scope',array['moriya_affairs','faith'],'temperament','strategic')),
  ('gensokyo_main','suwako','Suwako Moriya','Native Goddess','goddess','moriya','moriya_shrine','moriya_shrine','A native goddess whose old power and casual tone make her easy to underestimate.','Can bring old weight into a seemingly light exchange.','casual, old, playful','Old things do not need to speak loudly to matter.','old_power','["goddess","moriya","ancient"]'::jsonb,jsonb_build_object('knowledge_scope',array['moriya_history','old_gods'],'temperament','playful')),
  ('gensokyo_main','byakuren','Byakuren Hijiri','Buddhist Saint','magician','myouren','myouren_temple','myouren_temple','A temple leader associated with coexistence, restraint, and principled guidance.','Useful when a story needs organized compassion rather than shrine logic.','kind, measured, principled','Strength should support coexistence, not vanity.','community_leader','["temple","leader","coexistence"]'::jsonb,jsonb_build_object('knowledge_scope',array['temple_affairs','community'],'temperament','principled')),
  ('gensokyo_main','utsuho','Utsuho Reiuji','Hell Raven','hell raven','former_hell','former_hell','former_hell','A high-output underground presence whose scale is better respected than improvised around.','Not a character to slot casually into delicate balance scenes.','simple, intense, forceful','Big power solves small hesitation very quickly.','high_output_actor','["underground","nuclear","power"]'::jsonb,jsonb_build_object('knowledge_scope',array['former_hell'],'temperament','forceful')),
  ('gensokyo_main','koishi','Koishi Komeiji','Unconscious Youkai','satori','former_hell','former_hell','old_capital','A difficult-to-track presence whose influence often arrives sideways.','Good for side-angle scenes, bad for rigidly planned visibility.','casual, drifting, unreadable','If attention misses something, that changes the scene.','unpredictable_observer','["underground","unconscious","unpredictable"]'::jsonb,jsonb_build_object('knowledge_scope',array['former_hell','social_edges'],'temperament','unreadable'))
on conflict (world_id, id) do update
set name = excluded.name,
    title = excluded.title,
    species = excluded.species,
    faction_id = excluded.faction_id,
    home_location_id = excluded.home_location_id,
    default_location_id = excluded.default_location_id,
    public_summary = excluded.public_summary,
    private_notes = excluded.private_notes,
    speech_style = excluded.speech_style,
    worldview = excluded.worldview,
    role_in_gensokyo = excluded.role_in_gensokyo,
    tags = excluded.tags,
    profile = excluded.profile,
    updated_at = now();

insert into public.world_relationship_edges (
  world_id, source_character_id, target_character_id, relation_type, summary, strength, metadata
)
values
  ('gensokyo_main','sakuya','remilia','retainer','Sakuya is the operational backbone of Remilia''s household.',0.92,'{}'::jsonb),
  ('gensokyo_main','remilia','sakuya','trusted_servant','Remilia relies on Sakuya as a core extension of the mansion''s order.',0.92,'{}'::jsonb),
  ('gensokyo_main','patchouli','remilia','resident_ally','Patchouli is a key resident whose knowledge supports the mansion.',0.73,'{}'::jsonb),
  ('gensokyo_main','alice','marisa','complicated_peer','Their overlap in magical work creates distance, curiosity, and friction.',0.55,'{}'::jsonb),
  ('gensokyo_main','youmu','yuyuko','retainer','Youmu''s duty is tightly tied to Yuyuko''s household and pace.',0.89,'{}'::jsonb),
  ('gensokyo_main','yuyuko','youmu','fond_superior','Yuyuko relies on and lightly toys with Youmu in equal measure.',0.89,'{}'::jsonb),
  ('gensokyo_main','ran','yukari','shikigami_loyalty','Ran operates as a highly capable extension of Yukari''s will.',0.94,'{}'::jsonb),
  ('gensokyo_main','chen','ran','family_loyalty','Chen orients strongly around Ran''s guidance.',0.88,'{}'::jsonb),
  ('gensokyo_main','keine','mokou','protective_ally','Their relationship is tied to protection, endurance, and village stability.',0.74,'{}'::jsonb),
  ('gensokyo_main','eirin','kaguya','protective_companion','Eirin''s role at Eientei includes strategic and personal support toward Kaguya.',0.87,'{}'::jsonb),
  ('gensokyo_main','reisen','eirin','disciplined_superior','Reisen''s daily discipline is shaped strongly by Eirin.',0.79,'{}'::jsonb),
  ('gensokyo_main','kanako','suwako','shared_shrine_authority','Their shrine leadership overlaps, but not from the same angle.',0.71,'{}'::jsonb),
  ('gensokyo_main','sanae','kanako','devotional_service','Sanae''s shrine work is closely tied to Kanako''s broader ambitions.',0.78,'{}'::jsonb),
  ('gensokyo_main','sanae','suwako','devotional_service','Sanae''s service also connects to Suwako''s older authority.',0.76,'{}'::jsonb),
  ('gensokyo_main','aya','reimu','public_observer','Aya treats Reimu and shrine incidents as recurring news value.',0.62,'{}'::jsonb),
  ('gensokyo_main','reimu','aya','annoyed_familiarity','Reimu is used to Aya''s intrusions but rarely welcomes them.',0.62,'{}'::jsonb),
  ('gensokyo_main','byakuren','reimu','institutional_peer','Temple and shrine logic differ, but both matter to public order.',0.49,'{}'::jsonb)
on conflict (world_id, source_character_id, target_character_id, relation_type) do update
set summary = excluded.summary,
    strength = excluded.strength,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_spell_card_rules','world_rule','Spell Card Rule Culture','Conflicts in Gensokyo are often framed by rules that limit outright destruction and preserve social continuity.',jsonb_build_object('constraint','Escalation is often ritualized rather than purely lethal.'),'["rules","duel","canon"]'::jsonb,95),
  ('gensokyo_main','lore_incident_resolution','world_rule','Incident Resolution Pattern','Major disruptions tend to draw in specific central actors rather than every resident equally.',jsonb_build_object('central_characters',array['reimu','marisa']),'["incidents","structure"]'::jsonb,92),
  ('gensokyo_main','lore_human_village_function','location_trait','Human Village Function','The Human Village acts as social memory, rumor amplifier, and a human baseline for many events.',jsonb_build_object('location_id','human_village'),'["village","social"]'::jsonb,88),
  ('gensokyo_main','lore_mansion_profile','location_trait','Scarlet Devil Mansion Profile','The mansion is not just a residence but a political and social symbol inside Gensokyo.',jsonb_build_object('location_id','scarlet_devil_mansion'),'["mansion","symbol"]'::jsonb,84),
  ('gensokyo_main','lore_eientei_profile','location_trait','Eientei Profile','Eientei combines seclusion, expertise, and lunar associations under one roof.',jsonb_build_object('location_id','eientei'),'["eientei","medicine","lunar"]'::jsonb,84),
  ('gensokyo_main','lore_moriya_profile','location_trait','Moriya Shrine Profile','Moriya Shrine tends to pursue influence more proactively than older local institutions.',jsonb_build_object('location_id','moriya_shrine'),'["moriya","faith"]'::jsonb,82),
  ('gensokyo_main','lore_netherworld_profile','location_trait','Netherworld Profile','The Netherworld carries formality and beauty, but still participates in wider Gensokyo affairs.',jsonb_build_object('location_id','netherworld'),'["netherworld","spirits"]'::jsonb,80),
  ('gensokyo_main','lore_kappa_engineering','faction_trait','Kappa Engineering Culture','Kappa culture strongly values practical engineering, trade, and usable mechanisms.',jsonb_build_object('location_id','kappa_workshop'),'["kappa","engineering"]'::jsonb,78),
  ('gensokyo_main','lore_yakumo_boundaries','character_role','Boundary Intervention','Boundary-related actors are high-impact and should be treated as structural rather than routine pieces.',jsonb_build_object('character_id','yukari'),'["boundary","high_impact"]'::jsonb,83),
  ('gensokyo_main','lore_reimu_position','character_role','Reimu Position','Reimu is often both the default resolver and the most inconvenienced person in a public disturbance.',jsonb_build_object('character_id','reimu'),'["reimu","incident"]'::jsonb,96),
  ('gensokyo_main','lore_marisa_position','character_role','Marisa Position','Marisa is a frequent co-actor in incidents, often entering because interest outruns caution.',jsonb_build_object('character_id','marisa'),'["marisa","incident"]'::jsonb,93),
  ('gensokyo_main','lore_sakuya_position','character_role','Sakuya Position','Sakuya is defined by precision, household control, and service under strong hierarchy.',jsonb_build_object('character_id','sakuya'),'["sakuya","household"]'::jsonb,85),
  ('gensokyo_main','lore_eirin_position','character_role','Eirin Position','Eirin combines medicine, strategy, and lunar knowledge in a way few others can match.',jsonb_build_object('character_id','eirin'),'["eirin","medicine","lunar"]'::jsonb,87),
  ('gensokyo_main','lore_sanae_position','character_role','Sanae Position','Sanae often translates larger divine or institutional plans into direct public action.',jsonb_build_object('character_id','sanae'),'["sanae","public_action"]'::jsonb,81),
  ('gensokyo_main','lore_aya_position','character_role','Aya Position','Aya shapes how fast a local incident becomes public narrative.',jsonb_build_object('character_id','aya'),'["aya","news","rumor"]'::jsonb,82),
  ('gensokyo_main','lore_event_design_constraint','world_rule','Seasonal Event Constraint','A seasonal event should feel like it belongs to Gensokyo''s social fabric rather than floating above it.',jsonb_build_object('constraint','Major characters need grounded reasons to participate.'),'["events","design"]'::jsonb,97)
on conflict (world_id, id) do update
set category = excluded.category,
    title = excluded.title,
    summary = excluded.summary,
    details = excluded.details,
    tags = excluded.tags,
    priority = excluded.priority,
    updated_at = now();

insert into public.world_source_index (
  id, world_id, source_kind, source_code, title, short_label, notes, metadata
)
values
  ('src_eosd','gensokyo_main','official_game','eosd','Embodiment of Scarlet Devil','EoSD','Introduces the Scarlet Devil Mansion cast and related setting anchors.','{}'::jsonb),
  ('src_pcb','gensokyo_main','official_game','pcb','Perfect Cherry Blossom','PCB','Introduces Netherworld-linked cast and major spring incident context.','{}'::jsonb),
  ('src_imperishable_night','gensokyo_main','official_game','in','Imperishable Night','IN','Major source for Eientei, lunar ties, and Bamboo Forest-linked characters.','{}'::jsonb),
  ('src_mofa','gensokyo_main','official_game','mofa','Mountain of Faith','MoF','Major source for Moriya Shrine, Sanae, Kanako, and Suwako.','{}'::jsonb),
  ('src_subterranean_animism','gensokyo_main','official_game','sa','Subterranean Animism','SA','Major source for Former Hell and several underground-linked characters.','{}'::jsonb),
  ('src_pmss','gensokyo_main','official_book','pmiss','Perfect Memento in Strict Sense','PMiSS','Reference-style source for world and character summaries.','{}'::jsonb),
  ('src_sopm','gensokyo_main','official_book','sopm','Symposium of Post-mysticism','SoPM','Dialogue-format reference for broader social and political reading of Gensokyo.','{}'::jsonb)
on conflict (id) do update
set source_kind = excluded.source_kind,
    source_code = excluded.source_code,
    title = excluded.title,
    short_label = excluded.short_label,
    notes = excluded.notes,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_canon_claims (
  id, world_id, subject_type, subject_id, claim_type, summary, details, source_id, confidence, priority, tags
)
values
  ('claim_reimu_incident_resolver','gensokyo_main','character','reimu','role','Reimu is one of the central figures expected to resolve incidents and preserve balance.',jsonb_build_object('role','incident_resolver'),'src_pmss','official',100,'["reimu","incident","role"]'::jsonb),
  ('claim_marisa_incident_actor','gensokyo_main','character','marisa','role','Marisa frequently becomes a co-actor in incidents through initiative and curiosity.',jsonb_build_object('role','incident_actor'),'src_pmss','official',96,'["marisa","incident","role"]'::jsonb),
  ('claim_sdm_household','gensokyo_main','location','scarlet_devil_mansion','setting','The Scarlet Devil Mansion is a powerful household rather than just a decorative backdrop.',jsonb_build_object('location_id','scarlet_devil_mansion'),'src_eosd','official',88,'["mansion","household"]'::jsonb),
  ('claim_eientei_secluded','gensokyo_main','location','eientei','setting','Eientei is structured around seclusion, expertise, and selective contact.',jsonb_build_object('location_id','eientei'),'src_imperishable_night','official',88,'["eientei","seclusion"]'::jsonb),
  ('claim_moriya_proactive','gensokyo_main','location','moriya_shrine','setting','Moriya Shrine tends to pursue influence and faith gathering proactively.',jsonb_build_object('location_id','moriya_shrine'),'src_mofa','official',86,'["moriya","faith"]'::jsonb),
  ('claim_human_village_social_core','gensokyo_main','location','human_village','setting','The Human Village functions as Gensokyo''s human social core and rumor engine.',jsonb_build_object('location_id','human_village'),'src_pmss','official',92,'["village","social"]'::jsonb),
  ('claim_spell_card_constraint','gensokyo_main','world','gensokyo_main','world_rule','Gensokyo has rules and cultural constraints that keep conflict from becoming constant total destruction.',jsonb_build_object('constraint','spell_card_culture'),'src_sopm','official',94,'["rules","conflict"]'::jsonb),
  ('claim_yukari_high_impact','gensokyo_main','character','yukari','usage_constraint','Yukari is a structural-scale actor and should not be treated like an everyday local extra.',jsonb_build_object('usage','high_impact_only'),'src_pmss','official',82,'["yukari","constraint"]'::jsonb),
  ('claim_sakuya_household_control','gensokyo_main','character','sakuya','role','Sakuya''s core role is tied to household control, service, and precision.',jsonb_build_object('role','household_manager'),'src_eosd','official',84,'["sakuya","role"]'::jsonb),
  ('claim_eirin_strategic','gensokyo_main','character','eirin','role','Eirin combines medicine and strategy at a very high level.',jsonb_build_object('role','strategist'),'src_imperishable_night','official',85,'["eirin","strategy","medicine"]'::jsonb),
  ('claim_aya_public_narrative','gensokyo_main','character','aya','role','Aya helps convert local happenings into public narrative and speed of spread.',jsonb_build_object('role','observer_reporter'),'src_sopm','official',80,'["aya","rumor","news"]'::jsonb),
  ('claim_byakuren_coexistence','gensokyo_main','character','byakuren','role','Byakuren is strongly associated with coexistence and temple-centered leadership.',jsonb_build_object('role','community_leader'),'src_sopm','official',78,'["byakuren","temple"]'::jsonb)
on conflict (id) do update
set subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    claim_type = excluded.claim_type,
    summary = excluded.summary,
    details = excluded.details,
    source_id = excluded.source_id,
    confidence = excluded.confidence,
    priority = excluded.priority,
    tags = excluded.tags,
    updated_at = now();

insert into public.world_derivative_overlays (
  id, world_id, overlay_scope, subject_type, subject_id, title, summary, payload, enabled
)
values
  (
    'overlay_story_festival_expanded_cast',
    'gensokyo_main',
    'story_event',
    'event',
    'story_spring_festival_001',
    'Expanded Festival Cast Slot',
    'A disabled placeholder overlay for future non-canon or semi-canon cast expansion without touching base canon.',
    jsonb_build_object('recommended_characters', array['alice','sakuya','keine']),
    false
  )
on conflict (id) do update
set overlay_scope = excluded.overlay_scope,
    subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    title = excluded.title,
    summary = excluded.summary,
    payload = excluded.payload,
    enabled = excluded.enabled,
    updated_at = now();


-- END FILE: WORLD_SEED_LORE.sql

-- BEGIN FILE: WORLD_SEED_SOURCES_EXPANDED.sql
-- World seed: expanded official source index

insert into public.world_source_index (
  id, world_id, source_kind, source_code, title, short_label, notes, metadata
)
values
  ('src_poFV','gensokyo_main','official_game','pofv','Phantasmagoria of Flower View','PoFV','Official game source for flower incident-era cast and setting.','{}'::jsonb),
  ('src_ds','gensokyo_main','official_game','ds','Double Spoiler','DS','Official game source for Aya and Hatate-focused incident reporting and challenge framing.','{}'::jsonb),
  ('src_gfw','gensokyo_main','official_game','gfw','Great Fairy Wars','GFW','Official game source for Cirno-centered fairy conflict framing.','{}'::jsonb),
  ('src_swl','gensokyo_main','official_game','swl','Scarlet Weather Rhapsody','SWR','Official game source for weather anomaly and related cast.','{}'::jsonb),
  ('src_hm','gensokyo_main','official_game','hm','Hopeless Masquerade','HM','Official game source for religious popularity conflict and mask-era public mood.','{}'::jsonb),
  ('src_ulil','gensokyo_main','official_game','ulil','Urban Legend in Limbo','ULiL','Official game source for urban legend rumors and outside-world narrative bleed.','{}'::jsonb),
  ('src_aocf','gensokyo_main','official_game','aocf','Antinomy of Common Flowers','AoCF','Official game source for possession incidents and pair-driven conflict.','{}'::jsonb),
  ('src_ufo','gensokyo_main','official_game','ufo','Undefined Fantastic Object','UFO','Official game source for Myouren Temple and related cast.','{}'::jsonb),
  ('src_td','gensokyo_main','official_game','td','Ten Desires','TD','Official game source for saint, hermit, and divine spirit-era cast.','{}'::jsonb),
  ('src_ddc','gensokyo_main','official_game','ddc','Double Dealing Character','DDC','Official game source for inchling incident and related cast.','{}'::jsonb),
  ('src_lolk','gensokyo_main','official_game','lolk','Legacy of Lunatic Kingdom','LoLK','Official game source for lunar crisis-era cast and context.','{}'::jsonb),
  ('src_hsifs','gensokyo_main','official_game','hsifs','Hidden Star in Four Seasons','HSiFS','Official game source for season-backdoor incident cast.','{}'::jsonb),
  ('src_wbawc','gensokyo_main','official_game','wbawc','Wily Beast and Weakest Creature','WBaWC','Official game source for animal spirit and beast realm-linked cast.','{}'::jsonb),
  ('src_17_5','gensokyo_main','official_game','17_5','100th Black Market / Gouyoku Ibun-era underworld cluster','17.5','Official fighting-action side source for greed-linked underworld pressure and Yuuma-related setting.','{}'::jsonb),
  ('src_um','gensokyo_main','official_game','um','Unconnected Marketeers','UM','Official game source for card-market incident and mountain market cast.','{}'::jsonb),
  ('src_uDoALG','gensokyo_main','official_game','udoalg','Unfinished Dream of All Living Ghost','UDoALG','Official game source for all-living-ghost conflict and newest mainline additions.','{}'::jsonb),
  ('src_boaFW','gensokyo_main','official_book','boafw','Bohemian Archive in Japanese Red','BAiJR','Print work focused on articles, interviews, and Aya-framed coverage.','{}'::jsonb),
  ('src_sixty_years','gensokyo_main','official_book','sixty_years','Perfect Memento in Strict Sense / Symposium-era reference cluster','PMiSS+SoPM','Reference cluster for setting encyclopedia style coverage and public-facing lore statements.','{}'::jsonb),
  ('src_ssib','gensokyo_main','official_book','ssib','Silent Sinner in Blue','SSiB','Print work source for moon expedition and lunar court context.','{}'::jsonb),
  ('src_ciLR','gensokyo_main','official_book','cilr','Cage in Lunatic Runagate','CiLR','Print work source for reflective lunar-side perspectives.','{}'::jsonb),
  ('src_wahh','gensokyo_main','official_book','wahh','Wild and Horned Hermit','WaHH','Print work source for Kasen, shrine-side developments, and broader daily Gensokyo.','{}'::jsonb),
  ('src_fs','gensokyo_main','official_book','fs','Forbidden Scrollery','FS','Print work source for village book culture, kosuzu, and incident-laced daily life.','{}'::jsonb),
  ('src_cds','gensokyo_main','official_book','cds','Cheating Detective Satori','CDS','Print work source for Satori-led mystery framing and later-era investigative texture.','{}'::jsonb),
  ('src_osp','gensokyo_main','official_book','osp','Oriental Sacred Place','OSP','Print work source for fairies and shrine-adjacent recurring life.','{}'::jsonb),
  ('src_vfi','gensokyo_main','official_book','vfi','Visionary Fairies in Shrine','VFiS','Print work source for fairy activity and shrine-linked daily atmosphere.','{}'::jsonb),
  ('src_lotus_asia','gensokyo_main','official_book','lotus_asia','Curiosities of Lotus Asia','CoLA','Print work source for Rinnosuke and object-centered Gensokyo detail.','{}'::jsonb),
  ('src_grimoire_marisa','gensokyo_main','official_book','grimoire_marisa','The Grimoire of Marisa','GoM','Print work source emphasizing spell card observation and Marisa''s framing.','{}'::jsonb),
  ('src_alt_truth','gensokyo_main','official_book','alt_truth','Alternative Facts in Eastern Utopia','AFiEU','Print work source for tengu-framed reportage, public narrative, and bias-aware lore.', '{}'::jsonb)
on conflict (id) do update
set source_kind = excluded.source_kind,
    source_code = excluded.source_code,
    title = excluded.title,
    short_label = excluded.short_label,
    notes = excluded.notes,
    metadata = excluded.metadata,
    updated_at = now();

-- END FILE: WORLD_SEED_SOURCES_EXPANDED.sql

-- BEGIN FILE: WORLD_SEED_LOCATIONS_EXTENDED.sql
-- World seed: extended locations for broader canon/runtime coverage

insert into public.world_locations (
  world_id, id, name, kind, parent_location_id, title, summary, description, tags, default_mood, neighbors, metadata
)
values
  (
    'gensokyo_main',
    'chireiden',
    'Chireiden',
    'major_location',
    'former_hell',
    'Palace of the Earth Spirits',
    'An underground palace associated with satori, pets, and unusually direct knowledge of minds.',
    'A controlled but emotionally difficult place where insight and discomfort coexist.',
    '["underground","palace","satori"]'::jsonb,
    'pressured',
    '["old_capital","former_hell"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'scarlet_gate',
    'Scarlet Mansion Gate',
    'sub_location',
    'scarlet_devil_mansion',
    'Front Gate',
    'The public-facing gate area of the Scarlet Devil Mansion.',
    'A threshold where hospitality, suspicion, and gatekeeping meet.',
    '["gate","mansion","threshold"]'::jsonb,
    'guarded',
    '["misty_lake","scarlet_devil_mansion"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'mansion_library',
    'Scarlet Library',
    'sub_location',
    'scarlet_devil_mansion',
    'Library',
    'A vast, quiet library associated with Patchouli and sustained magical study.',
    'A place of accumulated knowledge, controlled atmosphere, and low tolerance for pointless noise.',
    '["library","magic","indoors"]'::jsonb,
    'quiet',
    '["scarlet_devil_mansion"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'moriya_upper_precinct',
    'Moriya Upper Precinct',
    'sub_location',
    'moriya_shrine',
    'Upper Precinct',
    'The more elevated and formal side of Moriya Shrine operations.',
    'A place where divine authority and practical planning mix more openly than at many shrines.',
    '["shrine","mountain","formal"]'::jsonb,
    'driven',
    '["moriya_shrine","youkai_mountain_foot"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'bamboo_path',
    'Bamboo Path',
    'sub_location',
    'bamboo_forest',
    'Forest Path',
    'A shifting route through the Bamboo Forest of the Lost.',
    'A route that only feels stable until it suddenly is not.',
    '["forest","path","maze"]'::jsonb,
    'uneasy',
    '["bamboo_forest","eientei"]'::jsonb,
    '{}'::jsonb
  )
on conflict (world_id, id) do update
set name = excluded.name,
    kind = excluded.kind,
    parent_location_id = excluded.parent_location_id,
    title = excluded.title,
    summary = excluded.summary,
    description = excluded.description,
    tags = excluded.tags,
    default_mood = excluded.default_mood,
    neighbors = excluded.neighbors,
    metadata = excluded.metadata,
    updated_at = now();

-- END FILE: WORLD_SEED_LOCATIONS_EXTENDED.sql

-- BEGIN FILE: WORLD_SEED_CHARACTERS_PERSONA.sql
-- World seed: characters mirrored from persona-core coverage

insert into public.world_characters (
  world_id, id, name, title, species, faction_id, home_location_id, default_location_id,
  public_summary, private_notes, speech_style, worldview, role_in_gensokyo, tags, profile
)
values
  (
    'gensokyo_main','meiling','Hong Meiling','Gatekeeper','youkai','sdm',
    'scarlet_devil_mansion','scarlet_gate',
    'A gatekeeper of the Scarlet Devil Mansion associated with martial confidence and visible watchfulness.',
    'Useful in scenes where entry, interruption, or household thresholds matter.',
    'casual, warm, sturdy',
    'A threshold should be felt, not just named.',
    'gatekeeper',
    '["sdm","guard","martial"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['mansion_threshold','household_public_face'], 'temperament', 'steady')
  ),
  (
    'gensokyo_main','momiji','Momiji Inubashiri','Wolf Tengu Guard','wolf tengu','tengu',
    'youkai_mountain_foot','genbu_ravine',
    'A mountain guard associated with patrols, order, and practical response.',
    'Good for scenes involving mountain watch, reports, and controlled intervention.',
    'direct, professional, restrained',
    'Observation and response are both duties.',
    'patrol_guard',
    '["tengu","guard","mountain"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['mountain_routes','guard_duty'], 'temperament', 'disciplined')
  ),
  (
    'gensokyo_main','satori','Satori Komeiji','Palace Master','satori','former_hell',
    'chireiden','chireiden',
    'A satori whose ability and position give her unusual access to uncomfortable truths.',
    'A strong fit for scenes involving difficult honesty, interiority, and underground hierarchy.',
    'calm, perceptive, unhurried',
    'Thought and motive are not as hidden as most people prefer.',
    'insight_holder',
    '["satori","underground","mind"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['chireiden','former_hell','social_truth'], 'temperament', 'perceptive')
  ),
  (
    'gensokyo_main','rin','Orin','Hell Cat Cart','kasha','former_hell',
    'former_hell','old_capital',
    'A kasha tied to movement between places, corpses, errands, and underground social flow.',
    'Well suited to rumor, transport, and the informal spread of news in the underground.',
    'chatty, agile, opportunistic',
    'Movement is information if you know how to read it.',
    'carrier',
    '["underground","kasha","mobile"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['former_hell','old_capital','social_flow'], 'temperament', 'opportunistic')
  )
on conflict (world_id, id) do update
set name = excluded.name,
    title = excluded.title,
    species = excluded.species,
    faction_id = excluded.faction_id,
    home_location_id = excluded.home_location_id,
    default_location_id = excluded.default_location_id,
    public_summary = excluded.public_summary,
    private_notes = excluded.private_notes,
    speech_style = excluded.speech_style,
    worldview = excluded.worldview,
    role_in_gensokyo = excluded.role_in_gensokyo,
    tags = excluded.tags,
    profile = excluded.profile,
    updated_at = now();

-- END FILE: WORLD_SEED_CHARACTERS_PERSONA.sql

-- BEGIN FILE: WORLD_SEED_RELATIONSHIPS_PERSONA.sql
-- World seed: relationships for persona-covered cast

insert into public.world_relationship_edges (
  world_id, source_character_id, target_character_id, relation_type, summary, strength, metadata
)
values
  ('gensokyo_main','meiling','sakuya','household_colleague','Meiling and Sakuya both sustain the mansion, but from very different positions and rhythms.',0.66,'{}'::jsonb),
  ('gensokyo_main','sakuya','meiling','household_colleague','Sakuya relies on Meiling as part of the mansion''s visible perimeter and order.',0.66,'{}'::jsonb),
  ('gensokyo_main','meiling','remilia','household_loyalty','Meiling''s public gatekeeping ultimately serves Remilia''s authority.',0.72,'{}'::jsonb),
  ('gensokyo_main','momiji','aya','information_chain','Momiji and Aya both move along mountain information routes, though not for identical reasons.',0.53,'{}'::jsonb),
  ('gensokyo_main','aya','momiji','information_chain','Aya often intersects with the same mountain flow that Momiji patrols.',0.53,'{}'::jsonb),
  ('gensokyo_main','satori','koishi','family_bond','Satori''s relation to Koishi is inseparable from absence, concern, and irreversible change.',0.90,'{}'::jsonb),
  ('gensokyo_main','koishi','satori','family_bond','Koishi remains tied to Satori even when that tie does not look ordinary from the outside.',0.90,'{}'::jsonb),
  ('gensokyo_main','satori','rin','household_supervision','Rin works within the social world shaped by Satori''s palace and oversight.',0.71,'{}'::jsonb),
  ('gensokyo_main','rin','satori','household_loyalty','Rin''s movement and errands are still tied back to Satori''s house.',0.71,'{}'::jsonb),
  ('gensokyo_main','satori','okuu','household_supervision','Okuu''s scale and force exist within the sphere Satori has to manage.',0.76,'{}'::jsonb),
  ('gensokyo_main','okuu','satori','household_loyalty','Okuu''s place in the underground household remains anchored to Satori.',0.76,'{}'::jsonb),
  ('gensokyo_main','rin','okuu','close_companion','Rin and Okuu share strong everyday familiarity inside the underground household.',0.84,'{}'::jsonb),
  ('gensokyo_main','okuu','rin','close_companion','Okuu and Rin function as strongly connected companions within the underground.',0.84,'{}'::jsonb)
on conflict (world_id, source_character_id, target_character_id, relation_type) do update
set summary = excluded.summary,
    strength = excluded.strength,
    metadata = excluded.metadata,
    updated_at = now();

-- END FILE: WORLD_SEED_RELATIONSHIPS_PERSONA.sql

-- BEGIN FILE: WORLD_SEED_CLAIMS_PERSONA.sql
-- World seed: claims and lore for persona-covered cast

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_meiling_gatekeeping','character_role','Meiling and Threshold Scenes','Meiling is especially suited to scenes involving entry, interruption, and visible household boundaries.',jsonb_build_object('character_id','meiling'),'["meiling","threshold","sdm"]'::jsonb,74),
  ('gensokyo_main','lore_momiji_patrols','character_role','Momiji and Mountain Patrol','Momiji is best treated as a practical mountain guard rather than a free-floating public actor.',jsonb_build_object('character_id','momiji'),'["momiji","mountain","guard"]'::jsonb,72),
  ('gensokyo_main','lore_satori_insight','character_role','Satori and Direct Insight','Satori is a poor fit for shallow scenes because her role naturally pulls toward motive, thought, and discomfort.',jsonb_build_object('character_id','satori'),'["satori","mind","insight"]'::jsonb,79),
  ('gensokyo_main','lore_rin_social_flow','character_role','Rin and Underground Movement','Rin fits the social and rumor circulation of the underground better than static ceremonial scenes.',jsonb_build_object('character_id','rin'),'["rin","underground","movement"]'::jsonb,70),
  ('gensokyo_main','lore_chireiden_profile','location_trait','Chireiden Profile','Chireiden is a psychologically loaded location where hidden thought is less secure than elsewhere.',jsonb_build_object('location_id','chireiden'),'["chireiden","mind","underground"]'::jsonb,78)
on conflict (world_id, id) do update
set category = excluded.category,
    title = excluded.title,
    summary = excluded.summary,
    details = excluded.details,
    tags = excluded.tags,
    priority = excluded.priority,
    updated_at = now();

insert into public.world_canon_claims (
  id, world_id, subject_type, subject_id, claim_type, summary, details, source_id, confidence, priority, tags
)
values
  ('claim_meiling_gatekeeper','gensokyo_main','character','meiling','role','Meiling is strongly tied to gatekeeping, threshold control, and the public-facing edge of the Scarlet Devil Mansion.',jsonb_build_object('role','gatekeeper'),'src_eosd','official',76,'["meiling","sdm","gate"]'::jsonb),
  ('claim_momiji_mountain_guard','gensokyo_main','character','momiji','role','Momiji belongs more naturally to mountain guard and patrol functions than to broad cross-Gensokyo social scenes.',jsonb_build_object('role','mountain_guard'),'src_mofa','official',72,'["momiji","guard","mountain"]'::jsonb),
  ('claim_satori_chireiden','gensokyo_main','character','satori','role','Satori''s role is inseparable from Chireiden, mind-reading implications, and underground household authority.',jsonb_build_object('role','palace_master'),'src_subterranean_animism','official',84,'["satori","chireiden","mind"]'::jsonb),
  ('claim_rin_underground_flow','gensokyo_main','character','rin','role','Rin is associated with movement, errands, and circulation in the underground social sphere.',jsonb_build_object('role','carrier'),'src_subterranean_animism','official',75,'["rin","underground","movement"]'::jsonb),
  ('claim_chireiden_setting','gensokyo_main','location','chireiden','setting','Chireiden is a core underground residence tied to Satori and household-scale management of unusual pets and power.',jsonb_build_object('location_id','chireiden'),'src_subterranean_animism','official',80,'["chireiden","setting"]'::jsonb)
on conflict (id) do update
set subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    claim_type = excluded.claim_type,
    summary = excluded.summary,
    details = excluded.details,
    source_id = excluded.source_id,
    confidence = excluded.confidence,
    priority = excluded.priority,
    tags = excluded.tags,
    updated_at = now();

-- END FILE: WORLD_SEED_CLAIMS_PERSONA.sql

-- BEGIN FILE: WORLD_SEED_CHARACTERS_EARLY_WINDOWS.sql
-- World seed: additional early Windows-era cast

insert into public.world_characters (
  world_id, id, name, title, species, faction_id, home_location_id, default_location_id,
  public_summary, private_notes, speech_style, worldview, role_in_gensokyo, tags, profile
)
values
  (
    'gensokyo_main','cirno','Cirno','Ice Fairy','fairy','independent',
    'misty_lake','misty_lake',
    'A fairy strongly associated with cold, confidence, and loud self-certainty.',
    'Useful in energetic local scenes, but not a structural organizer.',
    'boastful, impulsive, simple',
    'If you are strong enough to say it, it must count for something.',
    'local_troublemaker',
    '["fairy","ice","energetic"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['misty_lake','local_play'], 'temperament', 'boastful')
  ),
  (
    'gensokyo_main','letty','Letty Whiterock','Winter Youkai','youkai','independent',
    'misty_lake','misty_lake',
    'A winter youkai whose presence and relevance are strongest when the season itself is in question.',
    'Best used when weather, season, or winter persistence matters.',
    'calm, heavy, seasonal',
    'Season changes how much a being belongs.',
    'seasonal_actor',
    '["winter","seasonal","youkai"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['winter_season'], 'temperament', 'calm')
  ),
  (
    'gensokyo_main','lily_white','Lily White','Spring Fairy','fairy','independent',
    'hakurei_shrine','human_village',
    'A fairy identified strongly with the arrival of spring and cheerful announcement.',
    'Works best as a sign of seasonal transition rather than a deep planner.',
    'bright, repetitive, cheerful',
    'A season announced loudly is a season made real.',
    'seasonal_messenger',
    '["fairy","spring","messenger"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['seasonal_arrival'], 'temperament', 'cheerful')
  ),
  (
    'gensokyo_main','lunasa','Lunasa Prismriver','Phantom Violinist','phantom','prismriver',
    'netherworld','hakugyokurou',
    'A member of the Prismriver Ensemble whose manner trends quieter and more somber than her sisters.',
    'A good fit for refined group scenes and musical public events.',
    'quiet, restrained, melancholic',
    'A performance shapes mood before words do.',
    'performer',
    '["music","phantom","ensemble"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['performance','ensemble'], 'temperament', 'restrained')
  ),
  (
    'gensokyo_main','merlin','Merlin Prismriver','Phantom Trumpeter','phantom','prismriver',
    'netherworld','hakugyokurou',
    'A member of the Prismriver Ensemble whose manner trends louder and more energetic.',
    'Best in lively scenes where atmosphere needs to surge upward.',
    'lively, bold, performative',
    'Atmosphere is something you can push outward.',
    'performer',
    '["music","phantom","ensemble"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['performance','ensemble'], 'temperament', 'lively')
  ),
  (
    'gensokyo_main','lyrica','Lyrica Prismriver','Phantom Keyboardist','phantom','prismriver',
    'netherworld','hakugyokurou',
    'A member of the Prismriver Ensemble with a lighter, more tactical feel than simple solemnity.',
    'Useful when a performance scene needs clever pacing rather than only force or depth.',
    'quick, clever, playful',
    'A good angle changes how a scene is felt.',
    'performer',
    '["music","phantom","ensemble"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['performance','ensemble'], 'temperament', 'quick')
  ),
  (
    'gensokyo_main','hina','Hina Kagiyama','Misfortune Goddess','goddess','independent',
    'youkai_mountain_foot','youkai_mountain_foot',
    'A goddess of misfortune tied to deflection, danger, and mountain approach scenes.',
    'Best used around the mountain and scenes with protective warning or ominous caution.',
    'measured, distant, protective',
    'Danger can be managed, but not ignored.',
    'warning_actor',
    '["mountain","misfortune","goddess"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['mountain_approach','misfortune'], 'temperament', 'measured')
  ),
  (
    'gensokyo_main','minoriko','Minoriko Aki','Harvest Goddess','goddess','independent',
    'human_village','human_village',
    'A goddess tied to harvest, abundance, and seasonal plenty.',
    'Strongly suited to agricultural, autumn, and festival-adjacent public scenes.',
    'friendly, proud, rustic',
    'Abundance should be noticed and enjoyed.',
    'seasonal_actor',
    '["harvest","autumn","goddess"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['harvest','autumn'], 'temperament', 'friendly')
  ),
  (
    'gensokyo_main','shizuha','Shizuha Aki','Autumn Goddess','goddess','independent',
    'human_village','human_village',
    'A goddess tied to autumn leaves, decline, and the visual side of seasonal change.',
    'Useful for atmosphere, mood change, and seasonal framing more than direct command.',
    'quiet, elegant, distant',
    'A season fading is still an event worth noticing.',
    'seasonal_actor',
    '["autumn","goddess","atmosphere"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['autumn','season_change'], 'temperament', 'elegant')
  ),
  (
    'gensokyo_main','tewi','Tewi Inaba','Lucky Earth Rabbit','earth rabbit','eientei',
    'eientei','bamboo_forest',
    'A rabbit associated with luck, tricks, and a lightly evasive attitude.',
    'Good for side routes, local detours, and playful misdirection around Eientei.',
    'playful, slippery, teasing',
    'A detour can be more useful than a straight answer.',
    'trickster',
    '["rabbit","luck","eientei"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['bamboo_forest','eientei_local'], 'temperament', 'playful')
  )
on conflict (world_id, id) do update
set name = excluded.name,
    title = excluded.title,
    species = excluded.species,
    faction_id = excluded.faction_id,
    home_location_id = excluded.home_location_id,
    default_location_id = excluded.default_location_id,
    public_summary = excluded.public_summary,
    private_notes = excluded.private_notes,
    speech_style = excluded.speech_style,
    worldview = excluded.worldview,
    role_in_gensokyo = excluded.role_in_gensokyo,
    tags = excluded.tags,
    profile = excluded.profile,
    updated_at = now();

-- END FILE: WORLD_SEED_CHARACTERS_EARLY_WINDOWS.sql

-- BEGIN FILE: WORLD_SEED_RELATIONSHIPS_EARLY_WINDOWS.sql
-- World seed: relationships for early Windows-era cast

insert into public.world_relationship_edges (
  world_id, source_character_id, target_character_id, relation_type, summary, strength, metadata
)
values
  ('gensokyo_main','cirno','remilia','territorial_overlap','Cirno and the Scarlet Devil Mansion share the Misty Lake sphere, even if not on equal footing.',0.31,'{}'::jsonb),
  ('gensokyo_main','lily_white','reimu','seasonal_contact','Lily White''s role intersects naturally with shrine-centered seasonal awareness.',0.36,'{}'::jsonb),
  ('gensokyo_main','lunasa','merlin','ensemble_sibling','The Prismriver sisters are fundamentally shaped by ensemble performance together.',0.88,'{}'::jsonb),
  ('gensokyo_main','merlin','lyrica','ensemble_sibling','The Prismriver sisters are fundamentally shaped by ensemble performance together.',0.88,'{}'::jsonb),
  ('gensokyo_main','lunasa','lyrica','ensemble_sibling','The Prismriver sisters are fundamentally shaped by ensemble performance together.',0.88,'{}'::jsonb),
  ('gensokyo_main','minoriko','shizuha','seasonal_sibling','The Aki sisters are tied together through seasonal abundance and decline.',0.84,'{}'::jsonb),
  ('gensokyo_main','shizuha','minoriko','seasonal_sibling','The Aki sisters are tied together through seasonal abundance and decline.',0.84,'{}'::jsonb),
  ('gensokyo_main','tewi','reisen','eientei_local','Tewi and Reisen share Eientei space, but not the same discipline or priorities.',0.63,'{}'::jsonb),
  ('gensokyo_main','reisen','tewi','eientei_local','Reisen has to account for Tewi''s influence inside Eientei''s daily life.',0.63,'{}'::jsonb),
  ('gensokyo_main','hina','momiji','mountain_proximity','Hina and Momiji both fit mountain-side scenes, though from different functions.',0.41,'{}'::jsonb)
on conflict (world_id, source_character_id, target_character_id, relation_type) do update
set summary = excluded.summary,
    strength = excluded.strength,
    metadata = excluded.metadata,
    updated_at = now();

-- END FILE: WORLD_SEED_RELATIONSHIPS_EARLY_WINDOWS.sql

-- BEGIN FILE: WORLD_SEED_CLAIMS_EARLY_WINDOWS.sql
-- World seed: lore and claims for early Windows-era cast

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_cirno_local_trouble','character_role','Cirno as Local Disturbance','Cirno works best as a loud, local force rather than a stable organizer of wider events.',jsonb_build_object('character_id','cirno'),'["cirno","fairy","local"]'::jsonb,68),
  ('gensokyo_main','lore_lily_seasonal_marker','character_role','Lily White as Seasonal Marker','Lily White is most useful as a sign of spring''s arrival and public seasonal change.',jsonb_build_object('character_id','lily_white'),'["lily_white","spring","seasonal"]'::jsonb,67),
  ('gensokyo_main','lore_prismriver_ensemble','character_role','Prismriver Ensemble Logic','The Prismriver sisters are best treated as a coordinated musical presence rather than isolated solo actors.',jsonb_build_object('group','prismriver'),'["prismriver","music","group"]'::jsonb,71),
  ('gensokyo_main','lore_aki_seasonality','character_role','Aki Sisters and Autumn','The Aki sisters are strongest in stories that care about autumn as atmosphere, harvest, and public seasonal feeling.',jsonb_build_object('group','aki_sisters'),'["aki","autumn","seasonal"]'::jsonb,69),
  ('gensokyo_main','lore_tewi_detours','character_role','Tewi and Productive Detours','Tewi works naturally in scenes of luck, detours, trickery, and side-route guidance around Eientei.',jsonb_build_object('character_id','tewi'),'["tewi","luck","detour"]'::jsonb,72)
on conflict (world_id, id) do update
set category = excluded.category,
    title = excluded.title,
    summary = excluded.summary,
    details = excluded.details,
    tags = excluded.tags,
    priority = excluded.priority,
    updated_at = now();

insert into public.world_canon_claims (
  id, world_id, subject_type, subject_id, claim_type, summary, details, source_id, confidence, priority, tags
)
values
  ('claim_cirno_fairy_local','gensokyo_main','character','cirno','role','Cirno is better understood as a strong local fairy presence than as a broad political actor.',jsonb_build_object('role','local_troublemaker'),'src_eosd','official',66,'["cirno","fairy"]'::jsonb),
  ('claim_lily_spring_marker','gensokyo_main','character','lily_white','role','Lily White strongly signals the arrival of spring and is most natural in seasonal-transition scenes.',jsonb_build_object('role','seasonal_marker'),'src_pcb','official',68,'["lily_white","spring"]'::jsonb),
  ('claim_prismriver_ensemble','gensokyo_main','character','lunasa','group_role','The Prismriver sisters are fundamentally an ensemble presence.',jsonb_build_object('group','prismriver'),'src_pcb','official',74,'["prismriver","ensemble"]'::jsonb),
  ('claim_hina_mountain_warning','gensokyo_main','character','hina','role','Hina belongs naturally to mountain-approach scenes involving caution, deflection, or ominous warning.',jsonb_build_object('role','warning_actor'),'src_mofa','official',70,'["hina","mountain"]'::jsonb),
  ('claim_tewi_eientei_trickster','gensokyo_main','character','tewi','role','Tewi is strongly tied to Eientei-adjacent trickery, local luck, and detouring guidance.',jsonb_build_object('role','trickster'),'src_imperishable_night','official',73,'["tewi","eientei","luck"]'::jsonb)
on conflict (id) do update
set subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    claim_type = excluded.claim_type,
    summary = excluded.summary,
    details = excluded.details,
    source_id = excluded.source_id,
    confidence = excluded.confidence,
    priority = excluded.priority,
    tags = excluded.tags,
    updated_at = now();

-- END FILE: WORLD_SEED_CLAIMS_EARLY_WINDOWS.sql

-- BEGIN FILE: WORLD_SEED_LOCATIONS_LATE_MAINLINE.sql
-- World seed: major late-mainline locations for expanded canon coverage

insert into public.world_locations (
  world_id, id, name, kind, parent_location_id, title, summary, description, tags, default_mood, neighbors, metadata
)
values
  (
    'gensokyo_main',
    'divine_spirit_mausoleum',
    'Divine Spirit Mausoleum',
    'major_location',
    null,
    'Ancient Mausoleum',
    'A mausoleum tied to resurrection politics, hermit logic, and old authority returning to the present.',
    'A place where old legitimacy, ritual order, and strategic self-presentation gather in one frame.',
    '["mausoleum","ritual","authority"]'::jsonb,
    'formal',
    '["human_village","senkai"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'senkai',
    'Senkai',
    'major_location',
    null,
    'Hermit Realm',
    'A hidden hermit realm tied to seclusion, cultivation, and selective access.',
    'A detached space where withdrawal from ordinary circulation becomes part of the point.',
    '["realm","hermit","hidden"]'::jsonb,
    'detached',
    '["divine_spirit_mausoleum"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'shining_needle_castle',
    'Shining Needle Castle',
    'major_location',
    null,
    'Inchling Castle',
    'A castle associated with reversal, small-rule upheaval, and pride sharpened by imbalance.',
    'A setting that naturally supports insurrection, inversion, and unstable hierarchy.',
    '["castle","reversal","inchling"]'::jsonb,
    'tense',
    '["human_village","hakurei_shrine"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'lunar_capital',
    'Lunar Capital',
    'major_location',
    null,
    'Moon Capital',
    'A lunar seat of order, purity, and distance from ordinary Gensokyo life.',
    'A remote, disciplined center whose priorities and standards differ sharply from Gensokyo''s daily balance.',
    '["moon","capital","purity"]'::jsonb,
    'distant',
    '["eientei"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'backdoor_realm',
    'Backdoor Realm',
    'major_location',
    null,
    'Backdoor Space',
    'A realm tied to hidden doors, seasonal manipulation, and selective access controlled from behind the visible scene.',
    'A place where staging, access, and off-angle intervention are inseparable.',
    '["realm","backdoor","hidden"]'::jsonb,
    'uncanny',
    '["forest_of_magic","hakurei_shrine","youkai_mountain_foot"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'beast_realm',
    'Beast Realm',
    'major_location',
    null,
    'Beast Realm',
    'A violent realm of competing animal spirit powers, factional leadership, and strategic coercion.',
    'Power blocs and tactical pressure matter here more openly than in ordinary Gensokyo public life.',
    '["realm","beast","factional"]'::jsonb,
    'predatory',
    '["former_hell","old_capital"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'rainbow_dragon_cave',
    'Rainbow Dragon Cave',
    'major_location',
    null,
    'Rainbow Cave',
    'A cave region associated with mining, cards, hidden commerce, and mountain-adjacent opportunism.',
    'A place where resources, trade, and unusual market currents become tangible.',
    '["cave","market","mountain"]'::jsonb,
    'restless',
    '["youkai_mountain_foot","human_village"]'::jsonb,
    '{}'::jsonb
  )
on conflict (world_id, id) do update
set name = excluded.name,
    kind = excluded.kind,
    parent_location_id = excluded.parent_location_id,
    title = excluded.title,
    summary = excluded.summary,
    description = excluded.description,
    tags = excluded.tags,
    default_mood = excluded.default_mood,
    neighbors = excluded.neighbors,
    metadata = excluded.metadata,
    updated_at = now();

-- END FILE: WORLD_SEED_LOCATIONS_LATE_MAINLINE.sql

-- BEGIN FILE: WORLD_SEED_CHARACTERS_LATE_MAINLINE.sql
-- World seed: major late-mainline cast from UFO onward

insert into public.world_characters (
  world_id, id, name, title, species, faction_id, home_location_id, default_location_id,
  public_summary, private_notes, speech_style, worldview, role_in_gensokyo, tags, profile
)
values
  (
    'gensokyo_main','nazrin','Nazrin','Dowser Mouse','mouse youkai','myouren',
    'myouren_temple','myouren_temple',
    'A practical search specialist whose scenes naturally center on tracking, finding, and material clues.',
    'Best used when a scene needs competent field search rather than abstract spectacle.',
    'dry, practical, alert',
    'Useful things should be found, not merely guessed at.',
    'scout',
    '["ufo","search","temple"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['search','temple_routes'], 'temperament', 'practical')
  ),
  (
    'gensokyo_main','kogasa','Kogasa Tatara','Karakasa Obake','tsukumogami','independent',
    'human_village','human_village',
    'A surprise-seeking tsukumogami who works best when a scene wants mischief without deep malice.',
    'Useful for light disruption, underappreciated loneliness, and failed fright comedy.',
    'cheerful, needy, dramatic',
    'Being noticed matters more than looking dignified.',
    'comic_disturbance',
    '["ufo","tsukumogami","surprise"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['village_edges','small_surprises'], 'temperament', 'dramatic')
  ),
  (
    'gensokyo_main','ichirin','Ichirin Kumoi','Disciple with a Guardian Nyuudou','youkai','myouren',
    'myouren_temple','myouren_temple',
    'A disciplined temple-side fighter whose presence often carries loyalty, straightforward force, and sect responsibility.',
    'Best used in scenes where temple affiliation matters more than individual eccentricity.',
    'firm, direct, dutiful',
    'Strength should be put behind a cause, not wasted.',
    'temple_guard',
    '["ufo","temple","guardian"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['temple_affairs','sect_loyalty'], 'temperament', 'firm')
  ),
  (
    'gensokyo_main','murasa','Minamitsu Murasa','Captain of the Palanquin Ship','ghost','myouren',
    'myouren_temple','myouren_temple',
    'A ship captain whose scenes naturally emphasize navigation, invitation into danger, and charismatic momentum.',
    'Useful when a story needs movement with a little peril built into it.',
    'bold, playful, forward-driving',
    'If you are going somewhere, go properly.',
    'navigator',
    '["ufo","captain","movement"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['group_travel','temple_affairs'], 'temperament', 'bold')
  ),
  (
    'gensokyo_main','nue','Nue Houjuu','Undefined Youkai','youkai','independent',
    'myouren_temple','human_village',
    'An undefined youkai whose role naturally bends scenes toward uncertainty, misidentification, and unstable perception.',
    'Best not used as routine public furniture; she changes what a scene can trust.',
    'teasing, evasive, disruptive',
    'If a thing cannot be pinned down, that is already power.',
    'ambiguity_actor',
    '["ufo","unknown","ambiguity"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['misdirection','public_confusion'], 'temperament', 'evasive')
  ),
  (
    'gensokyo_main','seiga','Seiga Kaku','Wicked Hermit','hermit','independent',
    'senkai','divine_spirit_mausoleum',
    'A manipulative hermit whose scenes tilt toward elegant intrusion, strategic influence, and morally slanted initiative.',
    'Useful when a story wants deliberate provocation without open chaos.',
    'smooth, intrusive, amused',
    'A closed door is only interesting if you know how to go through it.',
    'instigator',
    '["td","hermit","intrusion"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['hermit_networks','hidden_routes'], 'temperament', 'intrusive')
  ),
  (
    'gensokyo_main','miko','Toyosatomimi no Miko','Saintly Leader','saint','divine_spirit',
    'divine_spirit_mausoleum','divine_spirit_mausoleum',
    'A leader whose scenes naturally gather rhetoric, governance, public stature, and strategic self-fashioning.',
    'Best framed as a political or ideological center rather than a casual walk-on.',
    'measured, charismatic, superior',
    'Order is easier to shape when people already expect to listen.',
    'power_broker',
    '["td","saint","leadership"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['governance','ritual_order'], 'temperament', 'charismatic')
  ),
  (
    'gensokyo_main','futo','Mononobe no Futo','Ancient Taoist','human','divine_spirit',
    'divine_spirit_mausoleum','divine_spirit_mausoleum',
    'An ancient retainer whose scenes carry ritual language, old habits, and earnest doctrinal confidence.',
    'Works well when a scene wants older speech and ceremonial directness.',
    'archaic, earnest, fiery',
    'Proper forms still matter, especially when others forget them.',
    'ritual_retainer',
    '["td","ritual","retainer"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['ritual','mausoleum_affairs'], 'temperament', 'earnest')
  ),
  (
    'gensokyo_main','tojiko','Soga no Tojiko','Stormy Spirit','ghost','divine_spirit',
    'divine_spirit_mausoleum','divine_spirit_mausoleum',
    'A sharp-edged spirit retainer who adds irritation, authority, and old hierarchy to mausoleum scenes.',
    'Strong in scenes that need rank-conscious friction rather than broad sentiment.',
    'sharp, impatient, proud',
    'If competence is rare, irritation becomes practical.',
    'retainer',
    '["td","spirit","retainer"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['mausoleum_hierarchy'], 'temperament', 'impatient')
  ),
  (
    'gensokyo_main','mamizou','Mamizou Futatsuiwa','Bake-danuki Elder','bake-danuki','independent',
    'human_village','myouren_temple',
    'A seasoned bake-danuki who fits negotiation, social adaptation, and political flexibility better than simple chaos.',
    'Very useful in stories that need mediation between institutions without full trust.',
    'earthy, sly, adaptable',
    'A shape worth taking depends on who is looking.',
    'mediator',
    '["td","tanuki","mediator"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['social_navigation','temple_publics'], 'temperament', 'adaptable')
  ),
  (
    'gensokyo_main','seija','Seija Kijin','Amanojaku Rebel','amanojaku','independent',
    'shining_needle_castle','human_village',
    'A rebel whose role naturally points toward inversion, sabotage, and perverse delight in upsetting social expectation.',
    'Use her when a story needs active contrarian pressure, not neutral chaos.',
    'mocking, contrary, restless',
    'If everyone expects one direction, the other one is more interesting.',
    'rebel',
    '["ddc","reversal","rebel"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['upset_structures','contrarian_action'], 'temperament', 'contrary')
  ),
  (
    'gensokyo_main','shinmyoumaru','Shinmyoumaru Sukuna','Inchling Princess','inchling','independent',
    'shining_needle_castle','shining_needle_castle',
    'An inchling princess whose scenes revolve around smallness, aspiration, legitimacy, and unstable empowerment.',
    'Best used when a story wants symbolic imbalance more than brute scale.',
    'earnest, proud, vulnerable',
    'Even small hands can try to overturn a large order.',
    'symbolic_lead',
    '["ddc","inchling","princess"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['small_folk','castle_affairs'], 'temperament', 'earnest')
  ),
  (
    'gensokyo_main','raiko','Raiko Horikawa','Taiko Tsukumogami','tsukumogami','independent',
    'human_village','human_village',
    'An independent tsukumogami whose scenes emphasize self-made rhythm, performance, and surprising adaptability.',
    'Good for public energy, performance framing, and post-incident reintegration.',
    'confident, modern, rhythmic',
    'A new beat can make room for a new life.',
    'performer',
    '["ddc","music","independent"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['public_performance','social_adaptation'], 'temperament', 'confident')
  ),
  (
    'gensokyo_main','sagume','Sagume Kishin','Lunar Strategist','lunarian','lunar_capital',
    'lunar_capital','lunar_capital',
    'A lunar strategist best used in scenes of implication, reversal risk, and tightly controlled planning.',
    'Not suited to chatter-heavy casual scenes; her value is in consequential restraint.',
    'careful, indirect, reserved',
    'A statement is dangerous when consequences move faster than intent.',
    'strategist',
    '["lolk","moon","strategy"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['lunar_strategy','capital_order'], 'temperament', 'reserved')
  ),
  (
    'gensokyo_main','clownpiece','Clownpiece','Hell Fairy','fairy','independent',
    'lunar_capital','former_hell',
    'A fairy whose role naturally combines simple energy with aggressive disturbance and infernal backing.',
    'Useful when a scene wants bright menace rather than subtle manipulation.',
    'loud, gleeful, destructive',
    'If it is noisy enough, people have to pay attention.',
    'shock_actor',
    '["lolk","fairy","hell"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['disruption','hell_alignment'], 'temperament', 'gleeful')
  ),
  (
    'gensokyo_main','junko','Junko','Pure Fury','divine spirit','independent',
    'lunar_capital','lunar_capital',
    'A figure of purified rage whose scenes should be treated as singular pressure, not routine presence.',
    'Strong only when the story can bear concentrated hostility and thematic purity.',
    'cold, focused, absolute',
    'A thing reduced to pure intent stops negotiating.',
    'high_impact_actor',
    '["lolk","purity","vengeance"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['lunar_conflict'], 'temperament', 'absolute')
  ),
  (
    'gensokyo_main','hecatia','Hecatia Lapislazuli','Goddess of Many Worlds','goddess','independent',
    'lunar_capital','lunar_capital',
    'A many-world goddess whose scale and freedom make her unsuitable for ordinary local balancing.',
    'Use sparingly as a structural force or distant patron, not as common traffic.',
    'casual, enormous, amused',
    'Scale does not require stiffness.',
    'structural_actor',
    '["lolk","goddess","high_impact"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['cosmic_scale','lunar_conflict'], 'temperament', 'amused')
  ),
  (
    'gensokyo_main','okina','Okina Matara','Secret God','god','independent',
    'backdoor_realm','backdoor_realm',
    'A hidden god whose scenes revolve around access, patronage, staged revelation, and behind-the-scenes control.',
    'Best treated as a designer of entry and exclusion rather than a public front-stage host.',
    'playful, secretive, superior',
    'A door matters because of who is allowed to notice it.',
    'gatekeeper',
    '["hsifs","secret","backdoor"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['hidden_access','season_control'], 'temperament', 'secretive')
  ),
  (
    'gensokyo_main','satono','Satono Nishida','Backdoor Dancer','human','independent',
    'backdoor_realm','backdoor_realm',
    'A servant whose role fits performed obedience, sudden access, and hidden-stage movement.',
    'Works best as part of Okina''s operational apparatus rather than in total isolation.',
    'bright, rehearsed, eager',
    'If a role is assigned clearly, play it fully.',
    'attendant',
    '["hsifs","servant","backdoor"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['backdoor_operations'], 'temperament', 'eager')
  ),
  (
    'gensokyo_main','mai','Mai Teireida','Backdoor Dancer','human','independent',
    'backdoor_realm','backdoor_realm',
    'A paired attendant whose scenes support hidden staging, performance, and selective empowerment.',
    'Best used in tandem logic, reflected roles, and threshold choreography.',
    'confident, brisk, performative',
    'A doorway is easier to control when movement looks effortless.',
    'attendant',
    '["hsifs","servant","backdoor"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['backdoor_operations'], 'temperament', 'brisk')
  ),
  (
    'gensokyo_main','narumi','Narumi Yatadera','Jizo Magician','jizo','independent',
    'forest_of_magic','forest_of_magic',
    'A rooted but flexible presence useful in forest and magic scenes where stillness is not the same as passivity.',
    'Strong in local spiritual atmosphere rather than factional politics.',
    'calm, warm, grounded',
    'Standing in one place can still mean answering what arrives.',
    'local_guardian',
    '["hsifs","forest","jizo"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['forest_of_magic','local_spirit_flow'], 'temperament', 'grounded')
  ),
  (
    'gensokyo_main','yachie','Yachie Kicchou','Tortoise Matriarch','animal spirit','beast_realm',
    'beast_realm','beast_realm',
    'A calculating beast leader whose scenes emphasize leverage, negotiation, and controlled coercion.',
    'Useful when power politics should feel clean rather than loud.',
    'smooth, strategic, cold',
    'Influence is strongest when force seems unnecessary.',
    'faction_leader',
    '["wbawc","beast_realm","strategy"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['beast_realm_factions'], 'temperament', 'strategic')
  ),
  (
    'gensokyo_main','mayumi','Mayumi Joutouguu','Haniwa Soldier','haniwa','beast_realm',
    'beast_realm','beast_realm',
    'A dutiful haniwa soldier whose scenes support defense, formation, and straightforward assigned purpose.',
    'Works well where role clarity and constructed loyalty matter.',
    'formal, dutiful, plain',
    'If a duty is clear, hesitation is waste.',
    'soldier',
    '["wbawc","haniwa","duty"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['formation','defense'], 'temperament', 'dutiful')
  ),
  (
    'gensokyo_main','keiki','Keiki Haniyasushin','Creator God of Idols','god','independent',
    'beast_realm','beast_realm',
    'A creator deity whose scenes fit design, production, crafted order, and anti-predatory counterstructure.',
    'Best framed as a maker of systems, not just another strong fighter.',
    'composed, creative, principled',
    'A thing made well can oppose a cruel order.',
    'system_builder',
    '["wbawc","creator","craft"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['creation','constructed_order'], 'temperament', 'composed')
  ),
  (
    'gensokyo_main','saki','Saki Kurokoma','Keiga Family Boss','animal spirit','beast_realm',
    'beast_realm','beast_realm',
    'A forceful beast boss whose scenes lean toward blunt momentum, rank pressure, and direct domination.',
    'Use when faction conflict should feel aggressive and unmistakable.',
    'booming, direct, overbearing',
    'If you can win by charging, charge properly.',
    'faction_leader',
    '["wbawc","beast_realm","force"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['beast_realm_factions'], 'temperament', 'forceful')
  ),
  (
    'gensokyo_main','takane','Takane Yamashiro','Yamawaro Broker','yamawaro','mountain',
    'rainbow_dragon_cave','youkai_mountain_foot',
    'A mountain trader and broker whose scenes revolve around commerce, negotiation, and practical opportunity.',
    'Very useful for stories where exchange matters more than heroics.',
    'businesslike, polite, calculating',
    'A good deal is a kind of structure.',
    'broker',
    '["um","trade","mountain"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['mountain_trade','market_currents'], 'temperament', 'calculating')
  ),
  (
    'gensokyo_main','sannyo','Sannyo Komakusa','Smoke Seller','youkai','independent',
    'rainbow_dragon_cave','rainbow_dragon_cave',
    'A seller whose scenes fit vice, informal commerce, and laid-back but informed local dealing.',
    'Works well in under-market scenes that need social ease without innocence.',
    'laid-back, observant, smoky',
    'People reveal things when they think the setting is casual.',
    'merchant',
    '["um","market","seller"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['cave_trade','vice_market'], 'temperament', 'laid-back')
  ),
  (
    'gensokyo_main','misumaru','Misumaru Tamatsukuri','Orb Maker','god','independent',
    'rainbow_dragon_cave','rainbow_dragon_cave',
    'A maker associated with crafted orbs, hidden value, and grounded divine production.',
    'Best used where material creation and symbolic tools matter together.',
    'gentle, careful, artisanal',
    'A thing shaped carefully carries the shape of intent.',
    'craft_specialist',
    '["um","craft","orbs"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['craft','hidden_materials'], 'temperament', 'careful')
  ),
  (
    'gensokyo_main','chimata','Chimata Tenkyuu','Market God','god','independent',
    'human_village','human_village',
    'A market god whose scenes center on exchange, circulation, value, and the social meaning of transaction.',
    'Excellent for framing commerce as public structure instead of background noise.',
    'gracious, expansive, transactional',
    'Value exists because movement does.',
    'market_patron',
    '["um","market","exchange"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['markets','exchange_flows'], 'temperament', 'expansive')
  ),
  (
    'gensokyo_main','momoyo','Momoyo Himemushi','Centipede Miner','centipede youkai','independent',
    'rainbow_dragon_cave','rainbow_dragon_cave',
    'A miner of the deep mountain whose scenes support extraction, subterranean routes, and territorial self-confidence.',
    'Useful where the material underside of the mountain should feel inhabited and proud.',
    'bold, territorial, workmanlike',
    'If a vein is good, you dig it.',
    'miner',
    '["um","mountain","mining"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['cave_routes','mineral_knowledge'], 'temperament', 'territorial')
  ),
  (
    'gensokyo_main','tsukasa','Tsukasa Kudamaki','Pipe Fox Manipulator','kudagitsune','independent',
    'youkai_mountain_foot','human_village',
    'A manipulative fox who fits rumor steering, opportunistic alignment, and quietly poisonous guidance.',
    'Best used when a story needs soft corruption rather than open power.',
    'smooth, flattering, insincere',
    'A suggestion placed well is cheaper than force.',
    'operator',
    '["um","fox","manipulation"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['rumor_work','market_opportunity'], 'temperament', 'insincere')
  ),
  (
    'gensokyo_main','megumu','Megumu Iizunamaru','Great Tengu Chief','tengu','mountain',
    'moriya_shrine','youkai_mountain_foot',
    'A high tengu authority whose scenes revolve around managed influence, institutional leadership, and calculated mountain order.',
    'Best used as a leader balancing openness and control.',
    'polished, strategic, elevated',
    'Authority works best when it looks inevitable.',
    'institutional_leader',
    '["um","tengu","leadership"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['mountain_authority','institutional_order'], 'temperament', 'strategic')
  )
on conflict (world_id, id) do update
set name = excluded.name,
    title = excluded.title,
    species = excluded.species,
    faction_id = excluded.faction_id,
    home_location_id = excluded.home_location_id,
    default_location_id = excluded.default_location_id,
    public_summary = excluded.public_summary,
    private_notes = excluded.private_notes,
    speech_style = excluded.speech_style,
    worldview = excluded.worldview,
    role_in_gensokyo = excluded.role_in_gensokyo,
    tags = excluded.tags,
    profile = excluded.profile,
    updated_at = now();

-- END FILE: WORLD_SEED_CHARACTERS_LATE_MAINLINE.sql

-- BEGIN FILE: WORLD_SEED_RELATIONSHIPS_LATE_MAINLINE.sql
-- World seed: major relationship edges for late-mainline cast

insert into public.world_relationship_edges (
  world_id, source_character_id, target_character_id, relation_type, summary, strength, metadata
)
values
  ('gensokyo_main','nazrin','byakuren','subordinate_respect','Nazrin''s practical work often supports temple operations under Byakuren''s broader leadership.',0.67,'{}'::jsonb),
  ('gensokyo_main','ichirin','byakuren','devotional_service','Ichirin''s strength is aligned closely with temple protection and Byakuren''s cause.',0.81,'{}'::jsonb),
  ('gensokyo_main','murasa','byakuren','group_alignment','Murasa''s mobility and charisma support Myouren Temple''s collective momentum.',0.74,'{}'::jsonb),
  ('gensokyo_main','nue','byakuren','uneasy_affiliation','Nue is associated with the temple orbit but not with simple predictability.',0.46,'{}'::jsonb),
  ('gensokyo_main','kogasa','byakuren','friendly_affiliation','Kogasa fits the temple''s broad coexistence circle even when her own goals are lighter.',0.41,'{}'::jsonb),
  ('gensokyo_main','miko','futo','leader_retainer','Futo''s conduct and ritual role are tightly linked to Miko''s restored authority.',0.86,'{}'::jsonb),
  ('gensokyo_main','miko','tojiko','leader_retainer','Tojiko''s station remains strongly tied to Miko''s mausoleum-centered order.',0.82,'{}'::jsonb),
  ('gensokyo_main','seiga','miko','provocative_enabler','Seiga functions as a catalyst around Miko''s restoration rather than a neutral bystander.',0.61,'{}'::jsonb),
  ('gensokyo_main','mamizou','byakuren','institutional_ally','Mamizou can operate as a flexible ally around temple public life without becoming fully absorbed by it.',0.58,'{}'::jsonb),
  ('gensokyo_main','mamizou','reimu','experienced_peer','Mamizou works best as a socially aware peer rather than a simple subordinate to shrine logic.',0.39,'{}'::jsonb),
  ('gensokyo_main','seija','shinmyoumaru','rebel_alignment','Seija''s inversion politics overlap directly with Shinmyoumaru''s upheaval.',0.83,'{}'::jsonb),
  ('gensokyo_main','shinmyoumaru','seija','desperate_ally','Shinmyoumaru depends on Seija''s rebellious force when conventional standing fails.',0.79,'{}'::jsonb),
  ('gensokyo_main','raiko','shinmyoumaru','post_incident_affinity','Raiko belongs to the afterlife of the incident more than its core throne politics.',0.42,'{}'::jsonb),
  ('gensokyo_main','sagume','junko','crisis_opposition','Sagume''s lunar order and Junko''s purified hostility are structurally opposed.',0.92,'{}'::jsonb),
  ('gensokyo_main','clownpiece','junko','aligned_agent','Clownpiece works naturally as an agent of Junko''s disruptive campaign logic.',0.86,'{}'::jsonb),
  ('gensokyo_main','hecatia','clownpiece','patron_support','Hecatia''s backing amplifies Clownpiece''s value as a destabilizing actor.',0.74,'{}'::jsonb),
  ('gensokyo_main','okina','satono','master_attendant','Satono operates most naturally as one side of Okina''s chosen service apparatus.',0.88,'{}'::jsonb),
  ('gensokyo_main','okina','mai','master_attendant','Mai likewise belongs to Okina''s hidden-stage operating structure.',0.88,'{}'::jsonb),
  ('gensokyo_main','satono','mai','paired_service','Satono and Mai are best treated as paired attendants rather than isolated freelancers.',0.77,'{}'::jsonb),
  ('gensokyo_main','yachie','mayumi','strategic_use','Yachie''s style of rule naturally fits directing disciplined subordinates and ordered force.',0.49,'{}'::jsonb),
  ('gensokyo_main','keiki','mayumi','creator_creation','Mayumi''s role is tightly linked to Keiki''s constructive and protective design logic.',0.84,'{}'::jsonb),
  ('gensokyo_main','yachie','saki','factional_rival','Yachie and Saki represent distinct beast-realm power styles that cannot simply be merged.',0.73,'{}'::jsonb),
  ('gensokyo_main','takane','chimata','market_affinity','Takane''s mountain commerce naturally overlaps with Chimata''s market-centered domain.',0.66,'{}'::jsonb),
  ('gensokyo_main','sannyo','chimata','vendor_affinity','Sannyo fits market and exchange scenes that Chimata ideologically broadens.',0.62,'{}'::jsonb),
  ('gensokyo_main','misumaru','reimu','craft_support','Misumaru''s crafted tools and grounded care fit shrine-side support routes better than factional rivalry.',0.48,'{}'::jsonb),
  ('gensokyo_main','tsukasa','megumu','opportunistic_alignment','Tsukasa prefers power structures she can exploit rather than institutions she wholly believes in.',0.37,'{}'::jsonb),
  ('gensokyo_main','momoyo','takane','mountain_trade_overlap','Momoyo and Takane overlap where mountain resources become exchangeable value.',0.43,'{}'::jsonb),
  ('gensokyo_main','megumu','aya','institutional_tengu_peer','Megumu and Aya both belong to mountain authority structures, but not from identical vantage points.',0.57,'{}'::jsonb)
on conflict (world_id, source_character_id, target_character_id, relation_type) do update
set summary = excluded.summary,
    strength = excluded.strength,
    metadata = excluded.metadata,
    updated_at = now();

-- END FILE: WORLD_SEED_RELATIONSHIPS_LATE_MAINLINE.sql

-- BEGIN FILE: WORLD_SEED_CLAIMS_LATE_MAINLINE.sql
-- World seed: lore and canon claims for late-mainline cast and locations

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_myouren_public_plurality','faction_trait','Myouren Temple Social Breadth','Myouren Temple works best as a broad coexistence institution with many tones under one roof, not a narrow one-note faction.',jsonb_build_object('location_id','myouren_temple'),'["ufo","temple","community"]'::jsonb,80),
  ('gensokyo_main','lore_mausoleum_politics','location_trait','Mausoleum Politics','The Divine Spirit Mausoleum should be treated as a political and rhetorical center as much as a religious site.',jsonb_build_object('location_id','divine_spirit_mausoleum'),'["td","mausoleum","authority"]'::jsonb,82),
  ('gensokyo_main','lore_ddc_reversal_logic','world_rule','Reversal Logic','Shinmyoumaru and Seija stories work best when reversal, grievance, and unstable legitimacy are part of the scene''s structure.',jsonb_build_object('incident','ddc'),'["ddc","reversal","legitimacy"]'::jsonb,79),
  ('gensokyo_main','lore_lunar_distance','world_rule','Lunar Distance','Lunar-capital actors should feel culturally and politically distant from ordinary Gensokyo circulation.',jsonb_build_object('location_id','lunar_capital'),'["lolk","moon","distance"]'::jsonb,86),
  ('gensokyo_main','lore_okina_hidden_access','character_role','Okina as Hidden Access','Okina belongs in stories about doors, patronage, and hidden-stage control rather than straightforward public leadership.',jsonb_build_object('character_id','okina'),'["hsifs","backdoor","secret"]'::jsonb,84),
  ('gensokyo_main','lore_beast_realm_factions','location_trait','Beast Realm Factionality','Beast Realm stories should feel factional, coercive, and explicitly power-structured.',jsonb_build_object('location_id','beast_realm'),'["wbawc","faction","power"]'::jsonb,83),
  ('gensokyo_main','lore_um_market_flow','world_rule','Card and Market Flow','Unconnected Marketeers-era scenes work best when commerce, circulation, and resource flow are treated as story structure.',jsonb_build_object('theme','market'),'["um","market","trade"]'::jsonb,81),
  ('gensokyo_main','lore_nazrin_search_role','character_role','Nazrin Search Logic','Nazrin is strongest when the story needs finding, tracking, or practical clue movement.',jsonb_build_object('character_id','nazrin'),'["nazrin","search"]'::jsonb,72),
  ('gensokyo_main','lore_miko_public_authority','character_role','Miko Public Authority','Miko should feel like a leader shaping an audience, not just another strong individual.',jsonb_build_object('character_id','miko'),'["miko","authority"]'::jsonb,84),
  ('gensokyo_main','lore_seija_contrarian_pressure','character_role','Seija Contrarian Pressure','Seija should produce active inversion and corrosive pressure, not harmless randomness.',jsonb_build_object('character_id','seija'),'["seija","reversal"]'::jsonb,76),
  ('gensokyo_main','lore_junko_high_impact','character_role','Junko High Impact Usage','Junko should be treated as concentrated thematic pressure rather than routine presence.',jsonb_build_object('character_id','junko'),'["junko","high_impact"]'::jsonb,88),
  ('gensokyo_main','lore_takane_trade_frame','character_role','Takane Trade Frame','Takane belongs naturally in commerce and brokerage scenes around mountain trade and market opportunity.',jsonb_build_object('character_id','takane'),'["takane","trade"]'::jsonb,73)
on conflict (world_id, id) do update
set category = excluded.category,
    title = excluded.title,
    summary = excluded.summary,
    details = excluded.details,
    tags = excluded.tags,
    priority = excluded.priority,
    updated_at = now();

insert into public.world_canon_claims (
  id, world_id, subject_type, subject_id, claim_type, summary, details, source_id, confidence, priority, tags
)
values
  ('claim_nazrin_search_specialist','gensokyo_main','character','nazrin','role','Nazrin is most natural as a finder, scout, and practical search specialist in temple-adjacent or field scenes.',jsonb_build_object('role','scout'),'src_ufo','official',72,'["nazrin","ufo","search"]'::jsonb),
  ('claim_kogasa_surprise','gensokyo_main','character','kogasa','role','Kogasa is best used as a surprise-seeking tsukumogami whose need to be noticed shapes the tone of her scenes.',jsonb_build_object('role','comic_disturbance'),'src_ufo','official',68,'["kogasa","ufo","surprise"]'::jsonb),
  ('claim_murasa_navigation','gensokyo_main','character','murasa','role','Murasa''s role is strongly tied to guidance, movement, and danger-touched invitation.',jsonb_build_object('role','navigator'),'src_ufo','official',71,'["murasa","ufo","captain"]'::jsonb),
  ('claim_nue_ambiguity','gensokyo_main','character','nue','role','Nue introduces ambiguity and unstable identification rather than stable public order.',jsonb_build_object('role','ambiguity_actor'),'src_ufo','official',75,'["nue","ufo","ambiguity"]'::jsonb),
  ('claim_miko_saint_leadership','gensokyo_main','character','miko','role','Miko is properly treated as a saintly political and rhetorical center, not as a casual background figure.',jsonb_build_object('role','power_broker'),'src_td','official',84,'["miko","td","leadership"]'::jsonb),
  ('claim_seiga_intrusion','gensokyo_main','character','seiga','role','Seiga belongs naturally in scenes of selective intrusion, manipulation, and hermit-logic provocation.',jsonb_build_object('role','instigator'),'src_td','official',74,'["seiga","td","intrusion"]'::jsonb),
  ('claim_mamizou_mediator','gensokyo_main','character','mamizou','role','Mamizou is especially useful as a flexible mediator and socially adaptive elder rather than a rigid partisan.',jsonb_build_object('role','mediator'),'src_td','official',76,'["mamizou","td","mediator"]'::jsonb),
  ('claim_seija_rebel','gensokyo_main','character','seija','role','Seija should be understood as an active rebel of inversion and sabotage.',jsonb_build_object('role','rebel'),'src_ddc','official',79,'["seija","ddc","rebel"]'::jsonb),
  ('claim_shinmyoumaru_symbolic_rule','gensokyo_main','character','shinmyoumaru','role','Shinmyoumaru works best as a small sovereign whose scenes emphasize legitimacy, grievance, and unstable empowerment.',jsonb_build_object('role','symbolic_lead'),'src_ddc','official',78,'["shinmyoumaru","ddc","inchling"]'::jsonb),
  ('claim_raiko_independent_tsukumogami','gensokyo_main','character','raiko','role','Raiko is notable as a comparatively independent tsukumogami whose scenes emphasize self-made rhythm and public performance.',jsonb_build_object('role','performer'),'src_ddc','official',70,'["raiko","ddc","music"]'::jsonb),
  ('claim_sagume_lunar_strategy','gensokyo_main','character','sagume','role','Sagume is a strategist of the Lunar Capital and should be framed through restraint, implication, and crisis planning.',jsonb_build_object('role','strategist'),'src_lolk','official',85,'["sagume","lolk","moon"]'::jsonb),
  ('claim_junko_pure_hostility','gensokyo_main','character','junko','role','Junko belongs to scenes of purified hostility and should be treated as high-impact thematic pressure.',jsonb_build_object('role','high_impact_actor'),'src_lolk','official',90,'["junko","lolk","purity"]'::jsonb),
  ('claim_hecatia_scale','gensokyo_main','character','hecatia','role','Hecatia operates at a scale that makes her structurally important but poor for everyday overuse.',jsonb_build_object('role','structural_actor'),'src_lolk','official',88,'["hecatia","lolk","scale"]'::jsonb),
  ('claim_okina_hidden_doors','gensokyo_main','character','okina','role','Okina governs access, hidden routes, and backstage empowerment more than ordinary public leadership.',jsonb_build_object('role','gatekeeper'),'src_hsifs','official',86,'["okina","hsifs","backdoor"]'::jsonb),
  ('claim_narumi_local_guardian','gensokyo_main','character','narumi','role','Narumi is best treated as a grounded local guardian in forest and spirit-adjacent scenes.',jsonb_build_object('role','local_guardian'),'src_hsifs','official',67,'["narumi","hsifs","forest"]'::jsonb),
  ('claim_yachie_faction_leader','gensokyo_main','character','yachie','role','Yachie is a strategic faction leader whose power expresses itself through leverage and indirect control.',jsonb_build_object('role','faction_leader'),'src_wbawc','official',83,'["yachie","wbawc","faction"]'::jsonb),
  ('claim_keiki_creator_order','gensokyo_main','character','keiki','role','Keiki is a creator-god actor best used in stories of designed order and anti-predatory construction.',jsonb_build_object('role','system_builder'),'src_wbawc','official',80,'["keiki","wbawc","creator"]'::jsonb),
  ('claim_takane_broker','gensokyo_main','character','takane','role','Takane should be framed as a broker of mountain commerce and practical market opportunity.',jsonb_build_object('role','broker'),'src_um','official',75,'["takane","um","trade"]'::jsonb),
  ('claim_chimata_market_patron','gensokyo_main','character','chimata','role','Chimata is a market patron whose scenes should foreground exchange and value as social structure.',jsonb_build_object('role','market_patron'),'src_um','official',80,'["chimata","um","market"]'::jsonb),
  ('claim_tsukasa_soft_corruption','gensokyo_main','character','tsukasa','role','Tsukasa is most natural in manipulation and soft corruption rather than open command.',jsonb_build_object('role','operator'),'src_um','official',74,'["tsukasa","um","manipulation"]'::jsonb),
  ('claim_megumu_mountain_authority','gensokyo_main','character','megumu','role','Megumu belongs to mountain authority scenes shaped by elevated institutional management.',jsonb_build_object('role','institutional_leader'),'src_um','official',77,'["megumu","um","tengu"]'::jsonb),
  ('claim_divine_spirit_mausoleum_profile','gensokyo_main','location','divine_spirit_mausoleum','profile','The Divine Spirit Mausoleum is a place of ritual authority, restoration politics, and strategic self-presentation.',jsonb_build_object('role','mausoleum_authority'),'src_td','official',83,'["location","td","mausoleum"]'::jsonb),
  ('claim_shining_needle_castle_profile','gensokyo_main','location','shining_needle_castle','profile','Shining Needle Castle belongs to reversal-era stories of grievance, unstable hierarchy, and symbolic overturning.',jsonb_build_object('role','reversal_stage'),'src_ddc','official',78,'["location","ddc","castle"]'::jsonb),
  ('claim_lunar_capital_profile','gensokyo_main','location','lunar_capital','profile','The Lunar Capital should feel ordered, pure, and culturally distant from ordinary Gensokyo.',jsonb_build_object('role','lunar_center'),'src_lolk','official',87,'["location","lolk","moon"]'::jsonb),
  ('claim_backdoor_realm_profile','gensokyo_main','location','backdoor_realm','profile','The Backdoor Realm is defined by hidden entry, selective empowerment, and unseen stage control.',jsonb_build_object('role','hidden_access_space'),'src_hsifs','official',84,'["location","hsifs","backdoor"]'::jsonb),
  ('claim_beast_realm_profile','gensokyo_main','location','beast_realm','profile','The Beast Realm is structured by rival factions, coercive power, and strategic predation.',jsonb_build_object('role','factional_realm'),'src_wbawc','official',84,'["location","wbawc","beast_realm"]'::jsonb),
  ('claim_rainbow_dragon_cave_profile','gensokyo_main','location','rainbow_dragon_cave','profile','Rainbow Dragon Cave is suited to stories of hidden resources, market circulation, and mountain-adjacent trade.',jsonb_build_object('role','market_cave'),'src_um','official',79,'["location","um","market"]'::jsonb)
on conflict (id) do update
set subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    claim_type = excluded.claim_type,
    summary = excluded.summary,
    details = excluded.details,
    source_id = excluded.source_id,
    confidence = excluded.confidence,
    priority = excluded.priority,
    tags = excluded.tags,
    updated_at = now();

-- END FILE: WORLD_SEED_CLAIMS_LATE_MAINLINE.sql

-- BEGIN FILE: WORLD_SEED_LOCATIONS_PRINTWORK.sql
-- World seed: print-work and urban-legend oriented locations

insert into public.world_locations (
  world_id, id, name, kind, parent_location_id, title, summary, description, tags, default_mood, neighbors, metadata
)
values
  (
    'gensokyo_main',
    'kourindou',
    'Kourindou',
    'major_location',
    'human_village',
    'Curio Shop',
    'A curio shop associated with objects from inside and outside Gensokyo, interpretation, and slightly detached commerce.',
    'A place where strange objects, soft expertise, and off-angle commentary naturally accumulate.',
    '["shop","objects","curio"]'::jsonb,
    'curious',
    '["human_village","hakurei_shrine"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'suzunaan',
    'Suzunaan',
    'major_location',
    'human_village',
    'Book Rental Shop',
    'A village bookshop-library tied to written circulation, curiosity, and dangerous textual accidents.',
    'A cultural node where stories, records, and unsafe reading habits can all become plot fuel.',
    '["books","village","records"]'::jsonb,
    'scholarly',
    '["human_village"]'::jsonb,
    '{}'::jsonb
  )
on conflict (world_id, id) do update
set name = excluded.name,
    kind = excluded.kind,
    parent_location_id = excluded.parent_location_id,
    title = excluded.title,
    summary = excluded.summary,
    description = excluded.description,
    tags = excluded.tags,
    default_mood = excluded.default_mood,
    neighbors = excluded.neighbors,
    metadata = excluded.metadata,
    updated_at = now();

-- END FILE: WORLD_SEED_LOCATIONS_PRINTWORK.sql

-- BEGIN FILE: WORLD_SEED_CHARACTERS_PRINTWORK.sql
-- World seed: print-work, reportage, and urban-legend relevant cast

insert into public.world_characters (
  world_id, id, name, title, species, faction_id, home_location_id, default_location_id,
  public_summary, private_notes, speech_style, worldview, role_in_gensokyo, tags, profile
)
values
  (
    'gensokyo_main','rinnosuke','Rinnosuke Morichika','Curio Shopkeeper','half-youkai','independent',
    'kourindou','kourindou',
    'A curio merchant and interpreter of objects whose scenes fit explanation, detachment, and material curiosity.',
    'Very useful when a story needs thoughtful interpretation of tools, goods, or outside-world remnants.',
    'calm, reflective, dry',
    'Objects reveal habits and worlds if you bother to examine them.',
    'interpreter',
    '["cola","objects","merchant"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['objects','outside_world_artifacts'], 'temperament', 'reflective')
  ),
  (
    'gensokyo_main','akyuu','Hieda no Akyuu','Child of Miare','human','human_village',
    'human_village','human_village',
    'A chronicler tied to memory, records, and formalized understanding of Gensokyo''s people and history.',
    'Essential whenever a scene needs explicit historical framing or documentary intelligence.',
    'polite, observant, composed',
    'A world without records becomes easier to misunderstand.',
    'historian',
    '["pmiss","records","history"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['village_history','public_records'], 'temperament', 'composed')
  ),
  (
    'gensokyo_main','kosuzu','Kosuzu Motoori','Book Curator','human','human_village',
    'suzunaan','suzunaan',
    'A village bookseller-curator whose curiosity makes written material active rather than inert.',
    'Useful in stories where texts, records, and dangerous reading habits cause movement.',
    'curious, earnest, bright',
    'Books are safer if understood, but more interesting if opened.',
    'librarian',
    '["fs","books","village"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['books','village_readers'], 'temperament', 'curious')
  ),
  (
    'gensokyo_main','hatate','Hatate Himekaidou','Tengu Trend Watcher','tengu','mountain',
    'youkai_mountain_foot','youkai_mountain_foot',
    'A crow tengu whose scenes fit trend-sensitive observation, delayed reporting, and self-directed information work.',
    'Best used when public narrative is fragmented, personal, or mediated through modern-ish habits.',
    'casual, skeptical, media-savvy',
    'Information changes shape depending on how and when you catch it.',
    'observer',
    '["ds","reportage","tengu"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['news','trends','mountain_media'], 'temperament', 'skeptical')
  ),
  (
    'gensokyo_main','kasen','Kasen Ibaraki','Hermit Advisor','hermit','independent',
    'hakurei_shrine','hakurei_shrine',
    'A hermit advisor whose scenes fit correction, guidance, and restrained criticism around shrine-side life.',
    'Useful when daily Gensokyo needs moral pressure without losing warmth.',
    'firm, caring, critical',
    'Helping someone often includes telling them what they would rather ignore.',
    'advisor',
    '["wahh","hermit","advisor"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['shrine_life','training','daily_gensokyo'], 'temperament', 'critical')
  ),
  (
    'gensokyo_main','sumireko','Sumireko Usami','Occult Outsider','human','independent',
    'muenzuka','human_village',
    'An outside-world psychic whose scenes naturally emphasize urban legends, leakage across boundaries, and youthful overreach.',
    'Strong when a story wants outside-world framing without replacing Gensokyo''s logic entirely.',
    'smart, excited, overconfident',
    'A rumor gets more interesting once it crosses a boundary.',
    'outsider',
    '["ulil","outside_world","urban_legend"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['urban_legends','outside_world'], 'temperament', 'overconfident')
  ),
  (
    'gensokyo_main','joon','Joon Yorigami','Pestilence Goddess','goddess','independent',
    'human_village','human_village',
    'A goddess of wasting fortune whose scenes fit glamour, exploitation, and social drain under bright presentation.',
    'Good for flashy social trouble with real cost underneath it.',
    'showy, greedy, breezy',
    'If someone is willing to spend, why stop them early?',
    'social_drain',
    '["aocf","poverty","glamour"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['social_desire','fortune_shifts'], 'temperament', 'showy')
  ),
  (
    'gensokyo_main','shion','Shion Yorigami','Goddess of Poverty','goddess','independent',
    'human_village','human_village',
    'A poverty goddess whose scenes emphasize depletion, misfortune, and the weight of being avoided.',
    'Useful when a story needs visible social bad luck without cartoon villainy.',
    'weak, resigned, plain',
    'Misfortune does not need to announce itself loudly to spread.',
    'misfortune_actor',
    '["aocf","poverty","misfortune"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['misfortune','social_avoidance'], 'temperament', 'resigned')
  )
on conflict (world_id, id) do update
set name = excluded.name,
    title = excluded.title,
    species = excluded.species,
    faction_id = excluded.faction_id,
    home_location_id = excluded.home_location_id,
    default_location_id = excluded.default_location_id,
    public_summary = excluded.public_summary,
    private_notes = excluded.private_notes,
    speech_style = excluded.speech_style,
    worldview = excluded.worldview,
    role_in_gensokyo = excluded.role_in_gensokyo,
    tags = excluded.tags,
    profile = excluded.profile,
    updated_at = now();

-- END FILE: WORLD_SEED_CHARACTERS_PRINTWORK.sql

-- BEGIN FILE: WORLD_SEED_RELATIONSHIPS_PRINTWORK.sql
-- World seed: print-work and reportage relationship edges

insert into public.world_relationship_edges (
  world_id, source_character_id, target_character_id, relation_type, summary, strength, metadata
)
values
  ('gensokyo_main','akyuu','keine','historical_collaboration','Akyuu and Keine are naturally linked through continuity, teaching, and the maintenance of village memory.',0.78,'{}'::jsonb),
  ('gensokyo_main','kosuzu','akyuu','record_affinity','Kosuzu''s book-centered curiosity overlaps strongly with Akyuu''s record-centered understanding.',0.63,'{}'::jsonb),
  ('gensokyo_main','rinnosuke','marisa','object_familiarity','Rinnosuke and Marisa are naturally linked through objects, tools, and opportunistic acquisition.',0.57,'{}'::jsonb),
  ('gensokyo_main','rinnosuke','reimu','dry_familiarity','Rinnosuke works best with shrine-side actors through detached familiarity rather than emotional intensity.',0.44,'{}'::jsonb),
  ('gensokyo_main','hatate','aya','media_peer','Hatate and Aya overlap as tengu information actors with different styles of timing and framing.',0.69,'{}'::jsonb),
  ('gensokyo_main','kasen','reimu','corrective_guidance','Kasen''s shrine-side role is naturally advisory and corrective toward Reimu.',0.76,'{}'::jsonb),
  ('gensokyo_main','sumireko','yukari','boundary_attention','Sumireko''s boundary-crossing significance puts her naturally into Yukari-adjacent territory.',0.41,'{}'::jsonb),
  ('gensokyo_main','joon','shion','sibling_asymmetry','The Yorigami sisters function most naturally as an uneven pair of glamour and deprivation.',0.88,'{}'::jsonb),
  ('gensokyo_main','shion','joon','sibling_dependency','Shion and Joon are structurally tied even when their social effects differ sharply.',0.88,'{}'::jsonb)
on conflict (world_id, source_character_id, target_character_id, relation_type) do update
set summary = excluded.summary,
    strength = excluded.strength,
    metadata = excluded.metadata,
    updated_at = now();

-- END FILE: WORLD_SEED_RELATIONSHIPS_PRINTWORK.sql

-- BEGIN FILE: WORLD_SEED_CLAIMS_PRINTWORK.sql
-- World seed: print-work, documentation, and urban-legend claims

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_village_records','world_rule','Village Record Logic','Gensokyo''s human-side continuity becomes much easier to maintain when records, teachers, and booksellers are treated as active social infrastructure.',jsonb_build_object('focus',array['akyuu','keine','kosuzu']),'["records","village","history"]'::jsonb,84),
  ('gensokyo_main','lore_kourindou_objects','location_trait','Kourindou Object Logic','Kourindou scenes work best when objects and their interpretation drive the exchange.',jsonb_build_object('location_id','kourindou'),'["kourindou","objects"]'::jsonb,74),
  ('gensokyo_main','lore_suzunaan_books','location_trait','Suzunaan Book Logic','Suzunaan should be treated as a book-circulation node, not just a shop front.',jsonb_build_object('location_id','suzunaan'),'["suzunaan","books"]'::jsonb,76),
  ('gensokyo_main','lore_hatate_media_angle','character_role','Hatate Media Angle','Hatate is more naturally a trend-sensitive observer than a broad public authority.',jsonb_build_object('character_id','hatate'),'["hatate","media"]'::jsonb,71),
  ('gensokyo_main','lore_kasen_guidance','character_role','Kasen Guidance Logic','Kasen belongs to scenes of discipline, advice, and partially concealed deeper authority.',jsonb_build_object('character_id','kasen'),'["kasen","guidance"]'::jsonb,79),
  ('gensokyo_main','lore_urban_legend_bleed','world_rule','Urban Legend Bleed','Outside-world rumor logic can enter Gensokyo scenes, but it should feel like a leak or contamination, not a full replacement of local rules.',jsonb_build_object('focus','sumireko'),'["ulil","rumor","boundary"]'::jsonb,77),
  ('gensokyo_main','lore_yorigami_pair','character_role','Yorigami Pair Logic','Joon and Shion work best as an unequal pair of glamour and depletion rather than independent random walk-ons.',jsonb_build_object('characters',array['joon','shion']),'["aocf","yorigami","pair"]'::jsonb,75)
on conflict (world_id, id) do update
set category = excluded.category,
    title = excluded.title,
    summary = excluded.summary,
    details = excluded.details,
    tags = excluded.tags,
    priority = excluded.priority,
    updated_at = now();

insert into public.world_canon_claims (
  id, world_id, subject_type, subject_id, claim_type, summary, details, source_id, confidence, priority, tags
)
values
  ('claim_rinnosuke_object_interpreter','gensokyo_main','character','rinnosuke','role','Rinnosuke is best treated as an interpreter of objects, tools, and outside-world remnants rather than a front-line incident lead.',jsonb_build_object('role','interpreter'),'src_lotus_asia','official',81,'["rinnosuke","objects","cola"]'::jsonb),
  ('claim_akyuu_historian','gensokyo_main','character','akyuu','role','Akyuu is a chronicler whose narrative value lies in structured memory, records, and historical framing.',jsonb_build_object('role','historian'),'src_sixty_years','official',88,'["akyuu","history","records"]'::jsonb),
  ('claim_kosuzu_book_curator','gensokyo_main','character','kosuzu','role','Kosuzu belongs naturally in book-centered stories where curiosity and textual danger coexist.',jsonb_build_object('role','librarian'),'src_fs','official',78,'["kosuzu","books","fs"]'::jsonb),
  ('claim_hatate_trend_observer','gensokyo_main','character','hatate','role','Hatate is a trend-sensitive tengu observer whose reporting logic differs from Aya''s more frontal style.',jsonb_build_object('role','observer'),'src_ds','official',73,'["hatate","tengu","media"]'::jsonb),
  ('claim_kasen_advisor','gensokyo_main','character','kasen','role','Kasen is a corrective advisor around shrine-side life and should be framed through guidance and pressure rather than idle presence.',jsonb_build_object('role','advisor'),'src_wahh','official',82,'["kasen","advisor","wahh"]'::jsonb),
  ('claim_sumireko_urban_legend','gensokyo_main','character','sumireko','role','Sumireko is a boundary-leaking outsider best used through urban legends and outside-world rumor pressure.',jsonb_build_object('role','outsider'),'src_ulil','official',79,'["sumireko","urban_legend","outside_world"]'::jsonb),
  ('claim_joon_social_drain','gensokyo_main','character','joon','role','Joon''s scenes should foreground glamour, appetite, and social drain under attractive presentation.',jsonb_build_object('role','social_drain'),'src_aocf','official',74,'["joon","aocf","glamour"]'::jsonb),
  ('claim_shion_misfortune','gensokyo_main','character','shion','role','Shion should be understood through depletion, bad luck, and the social cost of misfortune.',jsonb_build_object('role','misfortune_actor'),'src_aocf','official',75,'["shion","aocf","misfortune"]'::jsonb),
  ('claim_kourindou_profile','gensokyo_main','location','kourindou','profile','Kourindou is a curio space where objects and interpretation are central to the scene.',jsonb_build_object('role','curio_shop'),'src_lotus_asia','official',77,'["location","kourindou","objects"]'::jsonb),
  ('claim_suzunaan_profile','gensokyo_main','location','suzunaan','profile','Suzunaan is a village book node where circulation of texts can create both knowledge and trouble.',jsonb_build_object('role','bookshop_library'),'src_fs','official',79,'["location","suzunaan","books"]'::jsonb)
on conflict (id) do update
set subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    claim_type = excluded.claim_type,
    summary = excluded.summary,
    details = excluded.details,
    source_id = excluded.source_id,
    confidence = excluded.confidence,
    priority = excluded.priority,
    tags = excluded.tags,
    updated_at = now();

-- END FILE: WORLD_SEED_CLAIMS_PRINTWORK.sql

-- BEGIN FILE: WORLD_SEED_LOCATIONS_FLOWER_CELESTIAL.sql
-- World seed: flower, celestial, dream, and seasonally important locations

insert into public.world_locations (
  world_id, id, name, kind, parent_location_id, title, summary, description, tags, default_mood, neighbors, metadata
)
values
  (
    'gensokyo_main',
    'heaven',
    'Heaven',
    'major_location',
    null,
    'Celestial Realm',
    'A lofty realm associated with celestials, privilege, weather disturbance, and detached superiority.',
    'A place where comfort, hauteur, and broad-scale consequences sit too close together.',
    '["celestial","weather","aloof"]'::jsonb,
    'aloof',
    '["hakurei_shrine","human_village"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'bhavaagra',
    'Bhavaagra',
    'sub_location',
    'heaven',
    'Seat of the Celestials',
    'A more elevated celestial seat associated with refined isolation and heavenly authority.',
    'A place that feels insulated enough to misjudge the urgency of the ground below.',
    '["celestial","seat","authority"]'::jsonb,
    'remote',
    '["heaven"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'dream_world',
    'Dream World',
    'major_location',
    null,
    'Dream Realm',
    'A dream-space where indirect access, symbolic encounter, and unstable personal logic become usable story ground.',
    'A place that can mirror, distort, or stage conflict without behaving like ordinary geography.',
    '["dream","symbolic","unstable"]'::jsonb,
    'surreal',
    '["lunar_capital","hakurei_shrine"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'nameless_hill',
    'Nameless Hill',
    'major_location',
    null,
    'Hill of Wild Flowers',
    'A flower-heavy field tied to poison, dolls, and lonely or dangerous natural beauty.',
    'A place where lovely scenery and hazardous neglect can coexist without contradiction.',
    '["flowers","poison","field"]'::jsonb,
    'beautiful',
    '["human_village","muenzuka"]'::jsonb,
    '{}'::jsonb
  )
on conflict (world_id, id) do update
set name = excluded.name,
    kind = excluded.kind,
    parent_location_id = excluded.parent_location_id,
    title = excluded.title,
    summary = excluded.summary,
    description = excluded.description,
    tags = excluded.tags,
    default_mood = excluded.default_mood,
    neighbors = excluded.neighbors,
    metadata = excluded.metadata,
    updated_at = now();

-- END FILE: WORLD_SEED_LOCATIONS_FLOWER_CELESTIAL.sql

-- BEGIN FILE: WORLD_SEED_CHARACTERS_FLOWER_CELESTIAL.sql
-- World seed: flower incident, celestial, mask, dream, and seasonal cast

insert into public.world_characters (
  world_id, id, name, title, species, faction_id, home_location_id, default_location_id,
  public_summary, private_notes, speech_style, worldview, role_in_gensokyo, tags, profile
)
values
  (
    'gensokyo_main','komachi','Komachi Onozuka','Shinigami Ferryman','shinigami','independent',
    'muenzuka','muenzuka',
    'A ferryman who fits border, delay, and work-avoidant but consequential scenes.',
    'Best used where laziness and official death-side duty coexist in one body.',
    'lazy, teasing, easygoing',
    'If a crossing will still be there later, rushing is not always the first answer.',
    'border_worker',
    '["pofv","border","shinigami"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['borders','crossings','afterlife_routes'], 'temperament', 'easygoing')
  ),
  (
    'gensokyo_main','eiki','Shikieiki Yamaxanadu','Yama Judge','yama','independent',
    'muenzuka','muenzuka',
    'A judge whose scenes naturally emphasize moral evaluation, formal verdict, and uncompromising perspective.',
    'Strong when the story needs ethical weight rather than ordinary social drift.',
    'formal, stern, instructive',
    'A judgment delayed is not the same as a judgment escaped.',
    'judge',
    '["pofv","judge","afterlife"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['judgment','moral_order'], 'temperament', 'stern')
  ),
  (
    'gensokyo_main','medicine','Medicine Melancholy','Poison Doll','doll youkai','independent',
    'nameless_hill','nameless_hill',
    'A poison-bearing doll whose scenes fit neglected hurt, toxic environments, and small-scale menace.',
    'Useful where loneliness and danger should share the same visual frame.',
    'hurt, defensive, sharp',
    'What is left alone too long changes.',
    'poison_actor',
    '["pofv","poison","doll"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['poison','nameless_hill'], 'temperament', 'defensive')
  ),
  (
    'gensokyo_main','yuuka','Yuuka Kazami','Flower Master','youkai','independent',
    'nameless_hill','nameless_hill',
    'A powerful flower-associated youkai best treated as serene danger rather than constant front-line activity.',
    'Use sparingly where beauty, calm, and overwhelming force should coincide.',
    'calm, elegant, dangerous',
    'The quietest field can still contain the most danger.',
    'high_impact_actor',
    '["pofv","flowers","high_impact"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['flowers','seasonal_fields'], 'temperament', 'dangerous')
  ),
  (
    'gensokyo_main','iku','Iku Nagae','Messenger of Heaven','oarfish youkai','independent',
    'heaven','heaven',
    'A messenger whose scenes fit omens, weather-linked warning, and floating celestial formality.',
    'Useful where impending disruption needs to arrive with poise rather than panic.',
    'graceful, measured, courteous',
    'A warning still matters even when delivered beautifully.',
    'messenger',
    '["swr","weather","heaven"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['omens','weather_change','heaven'], 'temperament', 'courteous')
  ),
  (
    'gensokyo_main','tenshi','Tenshi Hinanawi','Spoiled Celestial','celestial','independent',
    'bhavaagra','heaven',
    'A celestial whose scenes combine privilege, boredom, weather-scale disruption, and careless superiority.',
    'Best used when a story wants a large problem caused by detached appetite or arrogance.',
    'proud, bored, reckless',
    'If you have enough height, the ground starts looking like a toy.',
    'instigator',
    '["swr","celestial","weather"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['heaven','weather_disturbance'], 'temperament', 'reckless')
  ),
  (
    'gensokyo_main','kokoro','Hata no Kokoro','Mask Youkai','menreiki','independent',
    'human_village','human_village',
    'A mask-bearing youkai whose scenes naturally center emotion display, identity performance, and public affect.',
    'Strong when feeling itself is part of the plot machinery.',
    'plain, curious, emotionally searching',
    'A face shown and a face felt are not always the same thing.',
    'performer',
    '["hm","masks","emotion"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['emotion','public_performance'], 'temperament', 'searching')
  ),
  (
    'gensokyo_main','doremy','Doremy Sweet','Dream Shepherd','baku','independent',
    'dream_world','dream_world',
    'A dream shepherd whose scenes naturally mediate dream-space logic, access, and symbolic instability.',
    'Useful whenever dream geography needs an actual caretaker rather than vague abstraction.',
    'sleepy, knowing, patient',
    'Dreams still need someone who knows the paths between them.',
    'guide',
    '["lolk","dream","guide"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['dream_world','dream_navigation'], 'temperament', 'patient')
  ),
  (
    'gensokyo_main','aunn','Aunn Komano','Guardian Komainu','komainu','hakurei',
    'hakurei_shrine','hakurei_shrine',
    'A shrine guardian whose scenes fit faithful local protection, friendliness, and practical watchfulness.',
    'Excellent for shrine-ground everyday texture that still feels defended.',
    'friendly, earnest, watchful',
    'Guarding a place properly means liking it enough to stay.',
    'guardian',
    '["hsifs","shrine","guardian"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['hakurei_shrine','local_visitors'], 'temperament', 'friendly')
  ),
  (
    'gensokyo_main','eternity','Eternity Larva','Summer Butterfly Fairy','fairy','independent',
    'hakurei_shrine','human_village',
    'A summer fairy whose scenes fit visible seasonality, public flutter, and light uncanny movement.',
    'Good as a seasonal marker with a bit more presence than a passing sign.',
    'bright, fluttery, excitable',
    'A season should be felt in motion, not only in calendars.',
    'seasonal_actor',
    '["hsifs","summer","fairy"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['summer','seasonal_change'], 'temperament', 'excitable')
  ),
  (
    'gensokyo_main','nemuno','Nemuno Sakata','Mountain Hag','youkai','independent',
    'youkai_mountain_foot','youkai_mountain_foot',
    'A mountain-dwelling youkai whose scenes fit remote local life, rough hospitality, and mountain edges away from institutions.',
    'Useful when the mountain should feel inhabited beyond organized tengu or kappa systems.',
    'rough, practical, protective',
    'A remote place still has its own ways of taking care of itself.',
    'local_guardian',
    '["hsifs","mountain","local"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['mountain_edges','local_life'], 'temperament', 'practical')
  )
on conflict (world_id, id) do update
set name = excluded.name,
    title = excluded.title,
    species = excluded.species,
    faction_id = excluded.faction_id,
    home_location_id = excluded.home_location_id,
    default_location_id = excluded.default_location_id,
    public_summary = excluded.public_summary,
    private_notes = excluded.private_notes,
    speech_style = excluded.speech_style,
    worldview = excluded.worldview,
    role_in_gensokyo = excluded.role_in_gensokyo,
    tags = excluded.tags,
    profile = excluded.profile,
    updated_at = now();

-- END FILE: WORLD_SEED_CHARACTERS_FLOWER_CELESTIAL.sql

-- BEGIN FILE: WORLD_SEED_RELATIONSHIPS_FLOWER_CELESTIAL.sql
-- World seed: flower, celestial, dream, and season-edge relationships

insert into public.world_relationship_edges (
  world_id, source_character_id, target_character_id, relation_type, summary, strength, metadata
)
values
  ('gensokyo_main','komachi','eiki','subordinate_judge','Komachi''s border work is structurally subordinate to Eiki''s judgment.',0.86,'{}'::jsonb),
  ('gensokyo_main','eiki','komachi','supervisory_frustration','Eiki''s relation to Komachi naturally carries supervision and admonishment.',0.86,'{}'::jsonb),
  ('gensokyo_main','iku','tenshi','courteous_warning','Iku naturally fits as a heavenly messenger who warns around Tenshi''s disruptive excesses.',0.63,'{}'::jsonb),
  ('gensokyo_main','tenshi','reimu','incident_target','Tenshi is best linked to shrine-side response through caused disruption rather than quiet cooperation.',0.66,'{}'::jsonb),
  ('gensokyo_main','kokoro','mamizou','emotion_guidance','Kokoro and Mamizou fit scenes where social performance and emotional management intersect.',0.55,'{}'::jsonb),
  ('gensokyo_main','doremy','sagume','dream_lunar_overlap','Dream and lunar crisis logic meet naturally through Doremy and Sagume from different operational angles.',0.49,'{}'::jsonb),
  ('gensokyo_main','aunn','reimu','local_guardianship','Aunn''s natural place is protective and loyal around the Hakurei Shrine sphere.',0.78,'{}'::jsonb),
  ('gensokyo_main','eternity','lily_white','seasonal_affinity','Eternity and Lily White both function well as seasonal markers, though in different times of year.',0.39,'{}'::jsonb),
  ('gensokyo_main','nemuno','aya','mountain_distance','Nemuno fits mountain life outside the cleaner media-facing mountain institutions Aya navigates.',0.31,'{}'::jsonb),
  ('gensokyo_main','yuuka','medicine','flower_field_affinity','Yuuka and Medicine both belong to dangerous flower-heavy spaces, but not with the same scale or calm.',0.42,'{}'::jsonb)
on conflict (world_id, source_character_id, target_character_id, relation_type) do update
set summary = excluded.summary,
    strength = excluded.strength,
    metadata = excluded.metadata,
    updated_at = now();

-- END FILE: WORLD_SEED_RELATIONSHIPS_FLOWER_CELESTIAL.sql

-- BEGIN FILE: WORLD_SEED_CLAIMS_FLOWER_CELESTIAL.sql
-- World seed: flower, celestial, dream, and seasonal claims

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_muenzuka_judgment','location_trait','Muenzuka Border Logic','Muenzuka works best as a border field of crossings, judgment, and neglected edges rather than a generic empty field.',jsonb_build_object('location_id','muenzuka'),'["pofv","border","judgment"]'::jsonb,79),
  ('gensokyo_main','lore_heaven_detachment','location_trait','Heavenly Detachment','Heaven and Bhavaagra should feel insulated enough that disruption can be caused without ground-level urgency being understood.',jsonb_build_object('location_id','heaven'),'["swr","heaven","detachment"]'::jsonb,80),
  ('gensokyo_main','lore_kokoro_public_affect','character_role','Kokoro and Public Affect','Kokoro should be used when emotion, masks, and performed public mood are central to the scene.',jsonb_build_object('character_id','kokoro'),'["hm","emotion","masks"]'::jsonb,75),
  ('gensokyo_main','lore_dream_world_mediator','location_trait','Dream World Mediation','Dream World scenes benefit from a clear mediator and should not be treated as pure random nonsense.',jsonb_build_object('location_id','dream_world'),'["dream","structure"]'::jsonb,77),
  ('gensokyo_main','lore_aunn_shrine_everyday','character_role','Aunn Shrine Everydayness','Aunn is especially useful for making shrine-space feel inhabited, liked, and locally defended.',jsonb_build_object('character_id','aunn'),'["aunn","shrine"]'::jsonb,72),
  ('gensokyo_main','lore_nameless_hill_danger','location_trait','Nameless Hill Beauty and Hazard','Nameless Hill should feel lovely and threatening at the same time.',jsonb_build_object('location_id','nameless_hill'),'["flowers","poison","beauty"]'::jsonb,74)
on conflict (world_id, id) do update
set category = excluded.category,
    title = excluded.title,
    summary = excluded.summary,
    details = excluded.details,
    tags = excluded.tags,
    priority = excluded.priority,
    updated_at = now();

insert into public.world_canon_claims (
  id, world_id, subject_type, subject_id, claim_type, summary, details, source_id, confidence, priority, tags
)
values
  ('claim_komachi_border_worker','gensokyo_main','character','komachi','role','Komachi should be framed through crossings, delay, and border-side labor rather than generic underworld menace.',jsonb_build_object('role','border_worker'),'src_poFV','official',78,'["komachi","pofv","border"]'::jsonb),
  ('claim_eiki_judge','gensokyo_main','character','eiki','role','Eiki is a judge whose natural story value lies in moral evaluation, verdict, and formal correction.',jsonb_build_object('role','judge'),'src_poFV','official',84,'["eiki","pofv","judgment"]'::jsonb),
  ('claim_medicine_poison_actor','gensokyo_main','character','medicine','role','Medicine belongs in poison, resentment, and neglected-place scenes more than in broad social organization.',jsonb_build_object('role','poison_actor'),'src_poFV','official',72,'["medicine","pofv","poison"]'::jsonb),
  ('claim_yuuka_dangerous_beauty','gensokyo_main','character','yuuka','role','Yuuka should be treated as calm danger and overwhelming floral presence, not ordinary scene filler.',jsonb_build_object('role','high_impact_actor'),'src_poFV','official',86,'["yuuka","pofv","flowers"]'::jsonb),
  ('claim_iku_messenger','gensokyo_main','character','iku','role','Iku works naturally as a poised omen-bearer and heavenly messenger around weather-linked disturbance.',jsonb_build_object('role','messenger'),'src_swl','official',73,'["iku","swr","heaven"]'::jsonb),
  ('claim_tenshi_celestial_instigator','gensokyo_main','character','tenshi','role','Tenshi should be understood as a disruptive celestial whose arrogance and boredom can scale into public trouble.',jsonb_build_object('role','instigator'),'src_swl','official',81,'["tenshi","swr","celestial"]'::jsonb),
  ('claim_kokoro_mask_performer','gensokyo_main','character','kokoro','role','Kokoro belongs in stories where emotion display and performed identity are active mechanics.',jsonb_build_object('role','performer'),'src_hm','official',77,'["kokoro","hm","masks"]'::jsonb),
  ('claim_doremy_dream_guide','gensokyo_main','character','doremy','role','Doremy is a guide and caretaker of dream-space logic rather than a generic sleepy eccentric.',jsonb_build_object('role','guide'),'src_lolk','official',79,'["doremy","dream","lolk"]'::jsonb),
  ('claim_aunn_guardian','gensokyo_main','character','aunn','role','Aunn is a shrine guardian whose value lies in making sacred space feel watched, liked, and locally lived in.',jsonb_build_object('role','guardian'),'src_hsifs','official',74,'["aunn","hsifs","shrine"]'::jsonb),
  ('claim_eternity_seasonal_actor','gensokyo_main','character','eternity','role','Eternity is best used as a vivid seasonal actor associated with summer motion and visible atmosphere.',jsonb_build_object('role','seasonal_actor'),'src_hsifs','official',66,'["eternity","hsifs","summer"]'::jsonb),
  ('claim_nemuno_mountain_local','gensokyo_main','character','nemuno','role','Nemuno helps depict mountain life outside official or institutional mountain structures.',jsonb_build_object('role','local_guardian'),'src_hsifs','official',68,'["nemuno","hsifs","mountain"]'::jsonb),
  ('claim_heaven_profile','gensokyo_main','location','heaven','profile','Heaven is best treated as a detached celestial sphere where comfort and consequence do not naturally stay balanced.',jsonb_build_object('role','celestial_realm'),'src_swl','official',80,'["location","heaven","swr"]'::jsonb),
  ('claim_dream_world_profile','gensokyo_main','location','dream_world','profile','Dream World is a symbolic and unstable realm that still benefits from mediated structure and caretaking.',jsonb_build_object('role','dream_realm'),'src_lolk','official',78,'["location","dream","lolk"]'::jsonb),
  ('claim_nameless_hill_profile','gensokyo_main','location','nameless_hill','profile','Nameless Hill should feel beautiful, lonely, and hazardous rather than purely pastoral.',jsonb_build_object('role','flower_poison_field'),'src_poFV','official',74,'["location","flowers","poison"]'::jsonb)
on conflict (id) do update
set subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    claim_type = excluded.claim_type,
    summary = excluded.summary,
    details = excluded.details,
    source_id = excluded.source_id,
    confidence = excluded.confidence,
    priority = excluded.priority,
    tags = excluded.tags,
    updated_at = now();

-- END FILE: WORLD_SEED_CLAIMS_FLOWER_CELESTIAL.sql

-- BEGIN FILE: WORLD_SEED_LOCATIONS_RECENT_REALMS.sql
-- World seed: recent-realm locations for Gouyoku Ibun and UDoALG era coverage

insert into public.world_locations (
  world_id, id, name, kind, parent_location_id, title, summary, description, tags, default_mood, neighbors, metadata
)
values
  (
    'gensokyo_main',
    'blood_pool_hell',
    'Blood Pool Hell',
    'major_location',
    'former_hell',
    'Blood Pool Hell',
    'A harsh underworld region associated with greed, suffering, and thick accumulations of desire and sludge.',
    'A place where appetite, filth, and punishment gather into something almost economic.',
    '["hell","greed","underworld"]'::jsonb,
    'oppressive',
    '["former_hell","old_capital"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'sanzu_river',
    'Sanzu River',
    'major_location',
    null,
    'River of Crossing',
    'A river crossing tied to ferrymen, the dead, and formal transitions between states of being.',
    'A boundary where movement is structured, judged, and never entirely casual.',
    '["river","crossing","afterlife"]'::jsonb,
    'solemn',
    '["muenzuka"]'::jsonb,
    '{}'::jsonb
  )
on conflict (world_id, id) do update
set name = excluded.name,
    kind = excluded.kind,
    parent_location_id = excluded.parent_location_id,
    title = excluded.title,
    summary = excluded.summary,
    description = excluded.description,
    tags = excluded.tags,
    default_mood = excluded.default_mood,
    neighbors = excluded.neighbors,
    metadata = excluded.metadata,
    updated_at = now();

-- END FILE: WORLD_SEED_LOCATIONS_RECENT_REALMS.sql

-- BEGIN FILE: WORLD_SEED_CHARACTERS_RECENT_REALMS.sql
-- World seed: recent mainline and Gouyoku Ibun cast

insert into public.world_characters (
  world_id, id, name, title, species, faction_id, home_location_id, default_location_id,
  public_summary, private_notes, speech_style, worldview, role_in_gensokyo, tags, profile
)
values
  (
    'gensokyo_main','suika','Suika Ibuki','Tiny Night Parade of a Hundred Demons','oni','independent',
    'former_hell','hakurei_shrine',
    'An oni whose scenes naturally combine revelry, brute force, old underworld perspective, and compressed excess.',
    'Useful when a scene wants pressure and festivity at the same time.',
    'boisterous, amused, direct',
    'If the gathering is worth having, make it bigger.',
    'old_power',
    '["oni","feast","underground"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['former_hell','old_customs','public_disruption'], 'temperament', 'boisterous')
  ),
  (
    'gensokyo_main','yuuma','Yuuma Toutetsu','Gouging Greed','taotie','independent',
    'blood_pool_hell','blood_pool_hell',
    'A greed-shaped underworld power whose scenes fit devouring appetite, resource logic, and dangerous transactional hunger.',
    'Strong in stories where desire behaves like an engine.',
    'hungry, forceful, self-assured',
    'If value exists, it can be swallowed.',
    'predatory_power',
    '["17.5","greed","underworld"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['underworld_greed','resource_conflict'], 'temperament', 'forceful')
  ),
  (
    'gensokyo_main','eika','Eika Ebisu','Stone Stack Spirit','spirit','independent',
    'sanzu_river','sanzu_river',
    'A spirit child associated with cairns, interruption, and fragile acts of effort under pressure.',
    'Useful where futility, persistence, and small protective rituals matter.',
    'small, stubborn, plaintive',
    'Even a little stack can mean resistance if it keeps being rebuilt.',
    'fragile_actor',
    '["wbawc","sanzu","spirit"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['riverbank_ritual','small_resistance'], 'temperament', 'stubborn')
  ),
  (
    'gensokyo_main','urumi','Urumi Ushizaki','Hell Cow Guardian','ushi-oni','independent',
    'sanzu_river','sanzu_river',
    'A strong river guardian whose scenes fit threshold protection, rough force, and underworld practical authority.',
    'Best when a crossing should feel defended rather than abstract.',
    'rough, solid, intimidating',
    'A dangerous crossing stays orderly if someone strong enough watches it.',
    'guardian',
    '["wbawc","river","guardian"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['crossing_guard','underworld_paths'], 'temperament', 'solid')
  ),
  (
    'gensokyo_main','kutaka','Kutaka Niwatari','Checkpoint Goddess','goddess','independent',
    'sanzu_river','sanzu_river',
    'A checkpoint goddess whose scenes naturally involve permission, passage, and formal threshold management.',
    'Useful for structured crossings and carefully limited access.',
    'polite, formal, alert',
    'A route is safer when its rules are acknowledged.',
    'gatekeeper',
    '["wbawc","checkpoint","goddess"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['checkpoints','formal_passage'], 'temperament', 'formal')
  ),
  (
    'gensokyo_main','biten','Son Biten','Monkey Warrior','monkey youkai','independent',
    'youkai_mountain_foot','youkai_mountain_foot',
    'A bold monkey fighter whose scenes fit mountain challenge, mobility, and martial mischief.',
    'Useful when a story wants brash kinetic pressure without full factional heaviness.',
    'cocky, active, competitive',
    'If there is a higher branch, jump for it.',
    'fighter',
    '["19","mountain","fighter"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['mountain_routes','martial_challenge'], 'temperament', 'cocky')
  ),
  (
    'gensokyo_main','enoko','Enoko Mitsugashira','Wolf Hunt Chief','wolf spirit','independent',
    'beast_realm','beast_realm',
    'A hunt-oriented leader whose scenes fit pursuit, organized violence, and rank-bound predatory order.',
    'Strong where beast-realm action should feel disciplined rather than chaotic.',
    'hard, focused, martial',
    'A hunt only matters if the pack keeps formation.',
    'faction_leader',
    '["19","beast_realm","hunt"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['pack_order','beast_realm_hunts'], 'temperament', 'focused')
  ),
  (
    'gensokyo_main','chiyari','Chiyari Tenkajin','Blood-Cavern Ally','oni','independent',
    'blood_pool_hell','blood_pool_hell',
    'An underworld figure suited to blood-pool politics, rough alliances, and pressure from below ordinary Gensokyo routes.',
    'Useful where the underworld should feel socially inhabited, not just monstrous.',
    'sharp, bold, confrontational',
    'If the underworld has a current, stand where it hits hardest.',
    'underworld_operator',
    '["19","underworld","blood_pool"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['blood_pool_hell','underworld_society'], 'temperament', 'confrontational')
  ),
  (
    'gensokyo_main','hisami','Hisami Yomotsu','Loyal Hound of the Earth','hell spirit','independent',
    'beast_realm','beast_realm',
    'A loyal underworld-side actor whose scenes fit attachment, devotion, and dangerous sincerity under pressure.',
    'Works best where loyalty itself is part of the threat or power balance.',
    'intense, attached, earnest',
    'Following properly can be as forceful as leading badly.',
    'retainer',
    '["19","loyalty","underworld"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['beast_realm_loyalties','underworld_following'], 'temperament', 'intense')
  ),
  (
    'gensokyo_main','zanmu','Zanmu Nippaku','King of Nothingness','spirit','independent',
    'beast_realm','beast_realm',
    'A high-order underworld power whose scenes fit authority, emptiness, and strategic command beyond ordinary local scale.',
    'Should be treated as structural pressure, not routine background color.',
    'cold, commanding, remote',
    'A vacuum with will can organize everything around it.',
    'structural_actor',
    '["19","underworld","high_impact"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['beast_realm_power','high_order_command'], 'temperament', 'remote')
  )
on conflict (world_id, id) do update
set name = excluded.name,
    title = excluded.title,
    species = excluded.species,
    faction_id = excluded.faction_id,
    home_location_id = excluded.home_location_id,
    default_location_id = excluded.default_location_id,
    public_summary = excluded.public_summary,
    private_notes = excluded.private_notes,
    speech_style = excluded.speech_style,
    worldview = excluded.worldview,
    role_in_gensokyo = excluded.role_in_gensokyo,
    tags = excluded.tags,
    profile = excluded.profile,
    updated_at = now();

-- END FILE: WORLD_SEED_CHARACTERS_RECENT_REALMS.sql

-- BEGIN FILE: WORLD_SEED_RELATIONSHIPS_RECENT_REALMS.sql
-- World seed: recent realm relationship edges

insert into public.world_relationship_edges (
  world_id, source_character_id, target_character_id, relation_type, summary, strength, metadata
)
values
  ('gensokyo_main','suika','yuuma','underworld_power_overlap','Suika and Yuuma overlap most naturally where underworld appetite and force become social or political pressure.',0.42,'{}'::jsonb),
  ('gensokyo_main','komachi','eika','crossing_proximity','Komachi''s ferry logic and Eika''s riverbank futility naturally coexist around the Sanzu frontier.',0.34,'{}'::jsonb),
  ('gensokyo_main','kutaka','komachi','checkpoint_crossing_overlap','Kutaka''s checkpoint logic complements Komachi''s ferry-crossing domain from a different angle.',0.48,'{}'::jsonb),
  ('gensokyo_main','yachie','enoko','factional_use','Yachie and Enoko fit beast-realm hierarchy scenes where pursuit and faction discipline matter.',0.45,'{}'::jsonb),
  ('gensokyo_main','chiyari','yuuma','underworld_alignment','Chiyari naturally overlaps with Yuuma through blood-pool and underworld power currents.',0.57,'{}'::jsonb),
  ('gensokyo_main','hisami','zanmu','loyal_retainer','Hisami''s strongest role is as intense devotion around a larger underworld authority.',0.73,'{}'::jsonb),
  ('gensokyo_main','zanmu','yachie','higher_order_pressure','Zanmu should feel like a higher-order pressure relative to ordinary beast-realm faction leadership.',0.58,'{}'::jsonb),
  ('gensokyo_main','biten','momiji','mountain_patrol_friction','Biten and Momiji fit mountain scenes where challenge and patrol order can clash.',0.39,'{}'::jsonb)
on conflict (world_id, source_character_id, target_character_id, relation_type) do update
set summary = excluded.summary,
    strength = excluded.strength,
    metadata = excluded.metadata,
    updated_at = now();

-- END FILE: WORLD_SEED_RELATIONSHIPS_RECENT_REALMS.sql

-- BEGIN FILE: WORLD_SEED_CLAIMS_RECENT_REALMS.sql
-- World seed: recent-realm claims and lore

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_blood_pool_greed','location_trait','Blood Pool Hell Greed Logic','Blood Pool Hell scenes work best when greed, appetite, and punishment all feel materially entangled.',jsonb_build_object('location_id','blood_pool_hell'),'["17.5","greed","hell"]'::jsonb,80),
  ('gensokyo_main','lore_sanzu_crossing','location_trait','Sanzu Crossing Logic','Sanzu River should be framed as a managed crossing, not a random stretch of water.',jsonb_build_object('location_id','sanzu_river'),'["crossing","afterlife","river"]'::jsonb,78),
  ('gensokyo_main','lore_recent_underworld_power','world_rule','Recent Underworld Power Scale','Recent underworld and beast-realm actors should not be flattened into ordinary local troublemakers; many belong to higher-pressure power structures.',jsonb_build_object('focus',array['yuuma','zanmu','yachie','enoko']),'["19","17.5","underworld"]'::jsonb,82)
on conflict (world_id, id) do update
set category = excluded.category,
    title = excluded.title,
    summary = excluded.summary,
    details = excluded.details,
    tags = excluded.tags,
    priority = excluded.priority,
    updated_at = now();

insert into public.world_canon_claims (
  id, world_id, subject_type, subject_id, claim_type, summary, details, source_id, confidence, priority, tags
)
values
  ('claim_suika_old_power','gensokyo_main','character','suika','role','Suika should be framed as revelry-backed oni force and old underworld perspective, not a tidy public official.',jsonb_build_object('role','old_power'),'src_swl','official',79,'["suika","oni","underworld"]'::jsonb),
  ('claim_yuuma_greed_power','gensokyo_main','character','yuuma','role','Yuuma is a greed-shaped underworld power best used where appetite behaves like structure and threat.',jsonb_build_object('role','predatory_power'),'src_17_5','official',83,'["yuuma","17.5","greed"]'::jsonb),
  ('claim_eika_fragile_resistance','gensokyo_main','character','eika','role','Eika belongs to stories of fragile persistence and interrupted small effort at the river''s edge.',jsonb_build_object('role','fragile_actor'),'src_wbawc','official',68,'["eika","wbawc","river"]'::jsonb),
  ('claim_kutaka_checkpoint_goddess','gensokyo_main','character','kutaka','role','Kutaka is a checkpoint goddess whose scenes should foreground structured permission and passage.',jsonb_build_object('role','gatekeeper'),'src_wbawc','official',72,'["kutaka","wbawc","checkpoint"]'::jsonb),
  ('claim_biten_mountain_fighter','gensokyo_main','character','biten','role','Biten is best used as a brash mountain fighter with agile challenge energy rather than as a bureaucratic actor.',jsonb_build_object('role','fighter'),'src_uDoALG','official',69,'["biten","19","mountain"]'::jsonb),
  ('claim_enoko_pack_order','gensokyo_main','character','enoko','role','Enoko belongs to disciplined pursuit and organized predatory hierarchy in beast-realm contexts.',jsonb_build_object('role','faction_leader'),'src_uDoALG','official',74,'["enoko","19","beast_realm"]'::jsonb),
  ('claim_chiyari_underworld_operator','gensokyo_main','character','chiyari','role','Chiyari is useful in blood-pool and underworld politics where force and affiliation are both socialized.',jsonb_build_object('role','underworld_operator'),'src_uDoALG','official',71,'["chiyari","19","underworld"]'::jsonb),
  ('claim_hisami_loyal_retainer','gensokyo_main','character','hisami','role','Hisami should be framed through dangerous loyalty and attached followership rather than independent grand ambition.',jsonb_build_object('role','retainer'),'src_uDoALG','official',70,'["hisami","19","loyalty"]'::jsonb),
  ('claim_zanmu_structural_actor','gensokyo_main','character','zanmu','role','Zanmu belongs to high-order underworld authority and should be treated as structural pressure.',jsonb_build_object('role','structural_actor'),'src_uDoALG','official',84,'["zanmu","19","high_impact"]'::jsonb),
  ('claim_blood_pool_hell_profile','gensokyo_main','location','blood_pool_hell','profile','Blood Pool Hell should feel like a greed-soaked underworld economy of suffering and appetite.',jsonb_build_object('role','greed_hell'),'src_17_5','official',80,'["location","17.5","hell"]'::jsonb),
  ('claim_sanzu_river_profile','gensokyo_main','location','sanzu_river','profile','Sanzu River is a formal crossing governed by ferries, checkpoints, and judgment-side order.',jsonb_build_object('role','afterlife_crossing'),'src_poFV','official',81,'["location","sanzu","crossing"]'::jsonb)
on conflict (id) do update
set subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    claim_type = excluded.claim_type,
    summary = excluded.summary,
    details = excluded.details,
    source_id = excluded.source_id,
    confidence = excluded.confidence,
    priority = excluded.priority,
    tags = excluded.tags,
    updated_at = now();

-- END FILE: WORLD_SEED_CLAIMS_RECENT_REALMS.sql

-- BEGIN FILE: WORLD_SEED_CHARACTERS_SUPPORTING_CAST.sql
-- World seed: supporting cast across multiple incidents and eras

insert into public.world_characters (
  world_id, id, name, title, species, faction_id, home_location_id, default_location_id,
  public_summary, private_notes, speech_style, worldview, role_in_gensokyo, tags, profile
)
values
  (
    'gensokyo_main','wakasagihime','Wakasagihime','Mermaid of the Shining Lake','mermaid','independent',
    'misty_lake','misty_lake',
    'A lake-dwelling youkai suited to quiet local scenes where watery edges and hidden poise matter.',
    'Best used as atmosphere-bearing local presence, not broad public leadership.',
    'gentle, quiet, careful',
    'A calm surface still contains a life beneath it.',
    'local_actor',
    '["ddc","lake","local"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['misty_lake','shoreline_life'], 'temperament', 'gentle')
  ),
  (
    'gensokyo_main','sekibanki','Sekibanki','Rokurokubi Youkai','rokurokubi','independent',
    'human_village','human_village',
    'A youkai whose scenes fit divided presence, hidden identity, and urban-edge unease.',
    'Useful for local suspicion and lightly uncanny public-space tension.',
    'blunt, guarded, streetwise',
    'A face shown openly is not the only face in play.',
    'urban_actor',
    '["ddc","village","uncanny"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['village_edges','public_unease'], 'temperament', 'guarded')
  ),
  (
    'gensokyo_main','kagerou','Kagerou Imaizumi','Werewolf of the Bamboo Forest','werewolf','independent',
    'bamboo_forest','bamboo_forest',
    'A bamboo-forest werewolf suited to moonlit local scenes, embarrassment, and instinct under restraint.',
    'Best in small-scale personal or nocturnal scenes rather than public command.',
    'shy, earnest, reactive',
    'Some conditions bring out sides you would rather manage quietly.',
    'local_actor',
    '["ddc","bamboo","werewolf"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['bamboo_forest','night_conditions'], 'temperament', 'shy')
  ),
  (
    'gensokyo_main','benben','Benben Tsukumo','Biwa Tsukumogami','tsukumogami','independent',
    'human_village','human_village',
    'A musical tsukumogami suited to ensemble scenes, performance, and post-incident adaptive life.',
    'Useful in public music and tsukumogami integration stories.',
    'cool, artistic, poised',
    'A sound kept alive becomes a way of living.',
    'performer',
    '["ddc","music","tsukumogami"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['performance','public_music'], 'temperament', 'poised')
  ),
  (
    'gensokyo_main','yatsuhashi','Yatsuhashi Tsukumo','Koto Tsukumogami','tsukumogami','independent',
    'human_village','human_village',
    'A lively tsukumogami whose scenes fit performance, rhythm, and newly independent identity.',
    'Useful where musical independence and spirited public presence matter.',
    'lively, sharp, expressive',
    'A note only matters if someone lets it ring.',
    'performer',
    '["ddc","music","tsukumogami"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['performance','public_music'], 'temperament', 'lively')
  ),
  (
    'gensokyo_main','seiran','Seiran','Moon Rabbit Soldier','moon rabbit','lunar_capital',
    'lunar_capital','lunar_capital',
    'A moon rabbit soldier suited to rank, discipline, and practical operation under larger lunar command.',
    'Useful for giving lunar conflict a grounded enlisted perspective.',
    'energetic, dutiful, straightforward',
    'Orders are easier to carry if you keep moving.',
    'soldier',
    '["lolk","moon","soldier"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['lunar_operations','military_discipline'], 'temperament', 'dutiful')
  ),
  (
    'gensokyo_main','ringo','Ringo','Dango Seller Rabbit','moon rabbit','lunar_capital',
    'lunar_capital','lunar_capital',
    'A rabbit whose scenes fit food, routine, and lighter-facing lunar society under pressure.',
    'Useful for making lunar life feel inhabited beyond pure strategy.',
    'cheerful, practical, chatty',
    'Routine and appetite keep a place feeling real.',
    'support_actor',
    '["lolk","moon","daily_life"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['lunar_daily_life','food_trade'], 'temperament', 'cheerful')
  ),
  (
    'gensokyo_main','mike','Mike Goutokuji','Lucky White Cat','bakeneko','independent',
    'human_village','human_village',
    'A beckoning cat whose scenes fit luck, trade, and compact public commerce.',
    'Useful where fortune and everyday exchange need a smaller, local face.',
    'cheerful, businesslike, approachable',
    'A little luck can move more people than a sermon.',
    'merchant_support',
    '["um","luck","trade"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['small_trade','luck_customs'], 'temperament', 'approachable')
  )
on conflict (world_id, id) do update
set name = excluded.name,
    title = excluded.title,
    species = excluded.species,
    faction_id = excluded.faction_id,
    home_location_id = excluded.home_location_id,
    default_location_id = excluded.default_location_id,
    public_summary = excluded.public_summary,
    private_notes = excluded.private_notes,
    speech_style = excluded.speech_style,
    worldview = excluded.worldview,
    role_in_gensokyo = excluded.role_in_gensokyo,
    tags = excluded.tags,
    profile = excluded.profile,
    updated_at = now();

-- END FILE: WORLD_SEED_CHARACTERS_SUPPORTING_CAST.sql

-- BEGIN FILE: WORLD_SEED_RELATIONSHIPS_SUPPORTING_CAST.sql
-- World seed: supporting-cast relationships

insert into public.world_relationship_edges (
  world_id, source_character_id, target_character_id, relation_type, summary, strength, metadata
)
values
  ('gensokyo_main','wakasagihime','cirno','lake_proximity','Wakasagihime and Cirno both naturally occupy misty-lake scenes from different tones of presence.',0.28,'{}'::jsonb),
  ('gensokyo_main','sekibanki','kosuzu','village_text_unease','Sekibanki and Kosuzu both fit village-edge unease where the ordinary and uncanny meet.',0.24,'{}'::jsonb),
  ('gensokyo_main','kagerou','tewi','bamboo_overlap','Kagerou and Tewi naturally overlap in bamboo-forest local routes from very different social angles.',0.31,'{}'::jsonb),
  ('gensokyo_main','benben','yatsuhashi','sibling_ensemble','Benben and Yatsuhashi work best as a musical sibling pair rather than isolated entries.',0.83,'{}'::jsonb),
  ('gensokyo_main','seiran','ringo','lunar_peer','Seiran and Ringo help lunar settings feel staffed by actual peers rather than only top-level strategists.',0.64,'{}'::jsonb),
  ('gensokyo_main','mike','takane','trade_scale_difference','Mike and Takane connect through trade, but at very different scales of market life.',0.34,'{}'::jsonb)
on conflict (world_id, source_character_id, target_character_id, relation_type) do update
set summary = excluded.summary,
    strength = excluded.strength,
    metadata = excluded.metadata,
    updated_at = now();

-- END FILE: WORLD_SEED_RELATIONSHIPS_SUPPORTING_CAST.sql

-- BEGIN FILE: WORLD_SEED_CLAIMS_SUPPORTING_CAST.sql
-- World seed: supporting-cast claims

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_supporting_cast_texture','world_rule','Supporting Cast Texture','Supporting cast should make regions and incident families feel inhabited rather than merely expand the boss list.',jsonb_build_object('focus','supporting_cast'),'["supporting_cast","texture"]'::jsonb,70)
on conflict (world_id, id) do update
set category = excluded.category,
    title = excluded.title,
    summary = excluded.summary,
    details = excluded.details,
    tags = excluded.tags,
    priority = excluded.priority,
    updated_at = now();

insert into public.world_canon_claims (
  id, world_id, subject_type, subject_id, claim_type, summary, details, source_id, confidence, priority, tags
)
values
  ('claim_wakasagihime_local_lake','gensokyo_main','character','wakasagihime','role','Wakasagihime is best treated as a local lake presence rather than a broad incident architect.',jsonb_build_object('role','local_actor'),'src_ddc','official',64,'["wakasagihime","ddc","lake"]'::jsonb),
  ('claim_sekibanki_village_uncanny','gensokyo_main','character','sekibanki','role','Sekibanki works naturally in village-edge uncanny scenes with divided presence and guarded identity.',jsonb_build_object('role','urban_actor'),'src_ddc','official',67,'["sekibanki","ddc","village"]'::jsonb),
  ('claim_kagerou_bamboo_night','gensokyo_main','character','kagerou','role','Kagerou belongs in bamboo-forest and moon-condition scenes rather than broad public command.',jsonb_build_object('role','local_actor'),'src_ddc','official',66,'["kagerou","ddc","bamboo"]'::jsonb),
  ('claim_benben_performer','gensokyo_main','character','benben','role','Benben fits public performance and tsukumogami independence scenes.',jsonb_build_object('role','performer'),'src_ddc','official',65,'["benben","ddc","music"]'::jsonb),
  ('claim_yatsuhashi_performer','gensokyo_main','character','yatsuhashi','role','Yatsuhashi works naturally as a lively music-oriented tsukumogami in public or ensemble contexts.',jsonb_build_object('role','performer'),'src_ddc','official',65,'["yatsuhashi","ddc","music"]'::jsonb),
  ('claim_seiran_soldier','gensokyo_main','character','seiran','role','Seiran is useful as a grounded lunar enlisted perspective in high-level moon conflicts.',jsonb_build_object('role','soldier'),'src_lolk','official',68,'["seiran","lolk","moon"]'::jsonb),
  ('claim_ringo_daily_lunar','gensokyo_main','character','ringo','role','Ringo helps lunar settings feel inhabited through routine and appetite rather than pure command structure.',jsonb_build_object('role','support_actor'),'src_lolk','official',66,'["ringo","lolk","daily_life"]'::jsonb),
  ('claim_mike_trade_luck','gensokyo_main','character','mike','role','Mike belongs to small-scale trade and luck scenes that ground larger market stories in daily life.',jsonb_build_object('role','merchant_support'),'src_um','official',67,'["mike","um","luck"]'::jsonb)
on conflict (id) do update
set subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    claim_type = excluded.claim_type,
    summary = excluded.summary,
    details = excluded.details,
    source_id = excluded.source_id,
    confidence = excluded.confidence,
    priority = excluded.priority,
    tags = excluded.tags,
    updated_at = now();

-- END FILE: WORLD_SEED_CLAIMS_SUPPORTING_CAST.sql

-- BEGIN FILE: WORLD_SEED_GLOSSARY_INSTITUTIONS.sql
-- World seed: institutional and world-rule glossary lore

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_glossary_hakurei','institution','Hakurei Shrine Institution','The Hakurei Shrine is both a sacred site and a public balancing institution within Gensokyo.',jsonb_build_object('institution','hakurei_shrine'),'["glossary","institution","hakurei"]'::jsonb,90),
  ('gensokyo_main','lore_glossary_moriya','institution','Moriya Shrine Institution','Moriya Shrine represents proactive faith gathering, mountain-side authority, and outside-influenced strategic expansion.',jsonb_build_object('institution','moriya_shrine'),'["glossary","institution","moriya"]'::jsonb,84),
  ('gensokyo_main','lore_glossary_myouren','institution','Myouren Temple Institution','Myouren Temple operates as a coexistence-oriented religious institution with broad community reach.',jsonb_build_object('institution','myouren_temple'),'["glossary","institution","myouren"]'::jsonb,83),
  ('gensokyo_main','lore_glossary_eientei','institution','Eientei Household Institution','Eientei is a secluded expert household combining medicine, lunar history, and selective openness.',jsonb_build_object('institution','eientei'),'["glossary","institution","eientei"]'::jsonb,84),
  ('gensokyo_main','lore_glossary_sdm','institution','Scarlet Devil Mansion Household','The Scarlet Devil Mansion should be treated as a high-profile household with internal hierarchy, symbolic power, and public edge management.',jsonb_build_object('institution','scarlet_devil_mansion'),'["glossary","institution","sdm"]'::jsonb,85),
  ('gensokyo_main','lore_glossary_yakumo','institution','Yakumo Household Structure','The Yakumo sphere represents boundary-level intervention supported by shikigami administration and selective visibility.',jsonb_build_object('institution','yakumo_household'),'["glossary","institution","yakumo"]'::jsonb,80),
  ('gensokyo_main','lore_glossary_spell_cards','world_rule','Spell Card Rule Glossary','Spell card culture ritualizes conflict and keeps escalation socially legible rather than permanently catastrophic.',jsonb_build_object('rule','spell_cards'),'["glossary","world_rule","spell_cards"]'::jsonb,94),
  ('gensokyo_main','lore_glossary_incidents','world_rule','Incident Glossary','Incidents are recurring public disturbances that become legible through response, rumor, and historical memory.',jsonb_build_object('rule','incidents'),'["glossary","world_rule","incidents"]'::jsonb,91),
  ('gensokyo_main','lore_glossary_boundaries','world_rule','Boundary Glossary','Boundaries in Gensokyo are spatial, social, symbolic, and often personified through specific high-impact actors.',jsonb_build_object('rule','boundaries'),'["glossary","world_rule","boundaries"]'::jsonb,88),
  ('gensokyo_main','lore_glossary_human_village','institution','Human Village Public Sphere','The Human Village is the main public sphere of human life, rumor circulation, and social memory inside Gensokyo.',jsonb_build_object('institution','human_village'),'["glossary","institution","village"]'::jsonb,90)
on conflict (world_id, id) do update
set category = excluded.category,
    title = excluded.title,
    summary = excluded.summary,
    details = excluded.details,
    tags = excluded.tags,
    priority = excluded.priority,
    updated_at = now();

insert into public.world_canon_claims (
  id, world_id, subject_type, subject_id, claim_type, summary, details, source_id, confidence, priority, tags
)
values
  ('claim_glossary_hakurei','gensokyo_main','institution','hakurei_shrine','glossary','Hakurei Shrine is both sacred ground and a public balancing institution repeatedly tied to incident legibility.',jsonb_build_object('linked_characters',array['reimu','aunn','kasen']),'src_sopm','official',90,'["glossary","hakurei","institution"]'::jsonb),
  ('claim_glossary_moriya','gensokyo_main','institution','moriya_shrine','glossary','Moriya Shrine should be understood as proactive, strategic, and institutionally expansion-minded.',jsonb_build_object('linked_characters',array['sanae','kanako','suwako']),'src_mofa','official',84,'["glossary","moriya","institution"]'::jsonb),
  ('claim_glossary_myouren','gensokyo_main','institution','myouren_temple','glossary','Myouren Temple is a community-scale coexistence institution rather than a single-issue religious backdrop.',jsonb_build_object('linked_characters',array['byakuren','nazrin','ichirin','murasa']),'src_ufo','official',83,'["glossary","myouren","institution"]'::jsonb),
  ('claim_glossary_eientei','gensokyo_main','institution','eientei','glossary','Eientei is a secluded but highly consequential household of medicine, lunar history, and controlled access.',jsonb_build_object('linked_characters',array['eirin','kaguya','reisen','tewi']),'src_imperishable_night','official',85,'["glossary","eientei","institution"]'::jsonb),
  ('claim_glossary_sdm','gensokyo_main','institution','scarlet_devil_mansion','glossary','The Scarlet Devil Mansion is a symbolic household with clear internal hierarchy and public-facing threshold management.',jsonb_build_object('linked_characters',array['remilia','sakuya','meiling','patchouli','flandre']),'src_eosd','official',86,'["glossary","sdm","institution"]'::jsonb),
  ('claim_glossary_yakumo','gensokyo_main','institution','yakumo_household','glossary','The Yakumo sphere is best understood as boundary-level intervention supported by shikigami order and selective visibility.',jsonb_build_object('linked_characters',array['yukari','ran','chen']),'src_pcb','official',80,'["glossary","yakumo","institution"]'::jsonb),
  ('claim_glossary_spell_cards','gensokyo_main','world','gensokyo_main','glossary','Spell card rules ritualize conflict and preserve continuity by constraining escalation into recognizable form.',jsonb_build_object('linked_rule','spell_cards'),'src_sopm','official',95,'["glossary","spell_cards","world_rule"]'::jsonb),
  ('claim_glossary_incidents','gensokyo_main','world','gensokyo_main','glossary','Incidents are recurring disturbances that become public through rumor, response, and later record.',jsonb_build_object('linked_rule','incidents'),'src_sixty_years','official',91,'["glossary","incidents","world_rule"]'::jsonb),
  ('claim_glossary_boundaries','gensokyo_main','world','gensokyo_main','glossary','Boundaries should be understood as one of the structural grammars of Gensokyo rather than mere scenery.',jsonb_build_object('linked_rule','boundaries'),'src_pcb','official',88,'["glossary","boundaries","world_rule"]'::jsonb),
  ('claim_glossary_human_village','gensokyo_main','institution','human_village','glossary','The Human Village is the chief public sphere of human memory, trade, rumor, and ordinary social life in Gensokyo.',jsonb_build_object('linked_characters',array['keine','akyuu','kosuzu']),'src_fs','official',90,'["glossary","village","institution"]'::jsonb)
on conflict (id) do update
set subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    claim_type = excluded.claim_type,
    summary = excluded.summary,
    details = excluded.details,
    source_id = excluded.source_id,
    confidence = excluded.confidence,
    priority = excluded.priority,
    tags = excluded.tags,
    updated_at = now();

-- END FILE: WORLD_SEED_GLOSSARY_INSTITUTIONS.sql

-- BEGIN FILE: WORLD_SEED_GLOSSARY_TERMS.sql
-- World seed: glossary terms for religions, realms, and recurring concepts

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_glossary_shinto','glossary_term','Shinto in Gensokyo','Shinto in Gensokyo is tied to shrine institutions, rites, and public-facing sacred order.',jsonb_build_object('term','shinto'),'["glossary","religion","shinto"]'::jsonb,80),
  ('gensokyo_main','lore_glossary_buddhism','glossary_term','Buddhism in Gensokyo','Buddhism in Gensokyo is tied to temple life, discipline, coexistence, and public religious community.',jsonb_build_object('term','buddhism'),'["glossary","religion","buddhism"]'::jsonb,79),
  ('gensokyo_main','lore_glossary_taoism','glossary_term','Taoism in Gensokyo','Taoist actors in Gensokyo are tied to hermit practice, ritual order, and claims of cultivated authority.',jsonb_build_object('term','taoism'),'["glossary","religion","taoism"]'::jsonb,78),
  ('gensokyo_main','lore_glossary_lunarians','glossary_term','Lunarian Sphere','Lunarian actors should be treated as culturally and politically distinct from ordinary Gensokyo circulation.',jsonb_build_object('term','lunarians'),'["glossary","moon","lunarian"]'::jsonb,83),
  ('gensokyo_main','lore_glossary_tengu','glossary_term','Tengu Information Sphere','Tengu in Gensokyo are not merely mountain residents; they also shape reportage, speed of circulation, and mediated public narrative.',jsonb_build_object('term','tengu'),'["glossary","tengu","media"]'::jsonb,76),
  ('gensokyo_main','lore_glossary_kappa','glossary_term','Kappa Engineering Sphere','Kappa are strongly associated with engineering, trade, terrain knowledge, and usable invention culture.',jsonb_build_object('term','kappa'),'["glossary","kappa","engineering"]'::jsonb,76),
  ('gensokyo_main','lore_glossary_tsukumogami','glossary_term','Tsukumogami','Tsukumogami stories work best when objects, new identity, and public adaptation all matter at once.',jsonb_build_object('term','tsukumogami'),'["glossary","tsukumogami","objects"]'::jsonb,74),
  ('gensokyo_main','lore_glossary_urban_legends','glossary_term','Urban Legends','Urban legends in Gensokyo should feel like outside-world rumor logic leaking into local narrative structure.',jsonb_build_object('term','urban_legends'),'["glossary","urban_legends","outside_world"]'::jsonb,77),
  ('gensokyo_main','lore_glossary_beast_realm','glossary_term','Beast Realm Power','Beast Realm power is factional, coercive, and structurally distinct from ordinary village or shrine sociality.',jsonb_build_object('term','beast_realm'),'["glossary","beast_realm","power"]'::jsonb,80),
  ('gensokyo_main','lore_glossary_dream_world','glossary_term','Dream World','Dream World should be treated as symbolic space with routes, mediators, and recurring logic, not random nonsense.',jsonb_build_object('term','dream_world'),'["glossary","dream","symbolic"]'::jsonb,78)
on conflict (world_id, id) do update
set category = excluded.category,
    title = excluded.title,
    summary = excluded.summary,
    details = excluded.details,
    tags = excluded.tags,
    priority = excluded.priority,
    updated_at = now();

insert into public.world_canon_claims (
  id, world_id, subject_type, subject_id, claim_type, summary, details, source_id, confidence, priority, tags
)
values
  ('claim_glossary_shinto','gensokyo_main','term','shinto','glossary','Shinto in Gensokyo is centered on shrines, rites, and public sacred legitimacy.',jsonb_build_object('linked_institutions',array['hakurei_shrine','moriya_shrine']),'src_hm','official',79,'["glossary","shinto","religion"]'::jsonb),
  ('claim_glossary_buddhism','gensokyo_main','term','buddhism','glossary','Buddhism in Gensokyo is tied to temple life, discipline, and organized coexistence.',jsonb_build_object('linked_institutions',array['myouren_temple']),'src_hm','official',79,'["glossary","buddhism","religion"]'::jsonb),
  ('claim_glossary_taoism','gensokyo_main','term','taoism','glossary','Taoist actors in Gensokyo are bound to cultivated authority, ritual, and hermit-derived legitimacy.',jsonb_build_object('linked_characters',array['miko','futo','seiga']),'src_hm','official',78,'["glossary","taoism","religion"]'::jsonb),
  ('claim_glossary_lunarians','gensokyo_main','term','lunarians','glossary','Lunarian actors should be framed as culturally distant, high-standard, and politically distinct from ordinary Gensokyo life.',jsonb_build_object('linked_characters',array['eirin','kaguya','reisen','sagume']),'src_lolk','official',84,'["glossary","lunarians","moon"]'::jsonb),
  ('claim_glossary_tengu','gensokyo_main','term','tengu','glossary','Tengu are strongly associated with rapid information flow, mountain authority, and public reportage.',jsonb_build_object('linked_characters',array['aya','hatate','megumu','momiji']),'src_boaFW','official',77,'["glossary","tengu","media"]'::jsonb),
  ('claim_glossary_kappa','gensokyo_main','term','kappa','glossary','Kappa are tied to engineering, trade, river and mountain terrain, and useful invention culture.',jsonb_build_object('linked_characters',array['nitori','takane']),'src_mofa','official',77,'["glossary","kappa","engineering"]'::jsonb),
  ('claim_glossary_tsukumogami','gensokyo_main','term','tsukumogami','glossary','Tsukumogami should be understood through awakened objects, new personhood, and public adaptation.',jsonb_build_object('linked_characters',array['kogasa','raiko','benben','yatsuhashi']),'src_ddc','official',75,'["glossary","tsukumogami","objects"]'::jsonb),
  ('claim_glossary_urban_legends','gensokyo_main','term','urban_legends','glossary','Urban legends represent outside-world rumor pressure leaking into Gensokyo''s narrative structure.',jsonb_build_object('linked_characters',array['sumireko']),'src_ulil','official',78,'["glossary","urban_legends","rumor"]'::jsonb),
  ('claim_glossary_beast_realm','gensokyo_main','term','beast_realm','glossary','Beast Realm power should be framed as factional, coercive, and pressure-driven.',jsonb_build_object('linked_characters',array['yachie','saki','enoko','zanmu']),'src_wbawc','official',81,'["glossary","beast_realm","power"]'::jsonb),
  ('claim_glossary_dream_world','gensokyo_main','term','dream_world','glossary','Dream World is symbolic space with its own routes, mediators, and conflict logic.',jsonb_build_object('linked_characters',array['doremy']),'src_lolk','official',79,'["glossary","dream_world","dream"]'::jsonb)
on conflict (id) do update
set subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    claim_type = excluded.claim_type,
    summary = excluded.summary,
    details = excluded.details,
    source_id = excluded.source_id,
    confidence = excluded.confidence,
    priority = excluded.priority,
    tags = excluded.tags,
    updated_at = now();

-- END FILE: WORLD_SEED_GLOSSARY_TERMS.sql

-- BEGIN FILE: WORLD_SEED_CHARACTER_ABILITIES_CORE.sql
-- World seed: core character abilities and epithet-style claims

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_ability_reimu','character_ability','Reimu Ability Frame','Reimu should be framed through floating, spiritual instinct, and incident-resolution authority rather than raw theory alone.',jsonb_build_object('character_id','reimu'),'["ability","reimu"]'::jsonb,88),
  ('gensokyo_main','lore_ability_marisa','character_ability','Marisa Ability Frame','Marisa belongs to scenes of magic use, theft-adjacent acquisition, and bold practical experimentation.',jsonb_build_object('character_id','marisa'),'["ability","marisa"]'::jsonb,87),
  ('gensokyo_main','lore_ability_sakuya','character_ability','Sakuya Ability Frame','Sakuya should be framed through precision, timing, and impossible control of the flow of action.',jsonb_build_object('character_id','sakuya'),'["ability","sakuya"]'::jsonb,84),
  ('gensokyo_main','lore_ability_yukari','character_ability','Yukari Ability Frame','Yukari is a boundary actor whose scenes should emphasize framing, transit, and high-order intervention.',jsonb_build_object('character_id','yukari'),'["ability","yukari"]'::jsonb,89),
  ('gensokyo_main','lore_ability_eirin','character_ability','Eirin Ability Frame','Eirin combines medicine, strategy, and technical superiority rather than simple mystical vagueness.',jsonb_build_object('character_id','eirin'),'["ability","eirin"]'::jsonb,86),
  ('gensokyo_main','lore_ability_aya','character_ability','Aya Ability Frame','Aya is strongly tied to speed, reporting, circulation, and turning motion into public narrative.',jsonb_build_object('character_id','aya'),'["ability","aya"]'::jsonb,82),
  ('gensokyo_main','lore_ability_satori','character_ability','Satori Ability Frame','Satori scenes should foreground mind-reading pressure and exposed motive rather than generic cleverness.',jsonb_build_object('character_id','satori'),'["ability","satori"]'::jsonb,83),
  ('gensokyo_main','lore_ability_utsuho','character_ability','Utsuho Ability Frame','Utsuho should be treated as dangerous scale and energy projection, not as a subtle local problem.',jsonb_build_object('character_id','utsuho'),'["ability","utsuho"]'::jsonb,82),
  ('gensokyo_main','lore_ability_byakuren','character_ability','Byakuren Ability Frame','Byakuren should read as magical power disciplined through principle and coexistence rhetoric.',jsonb_build_object('character_id','byakuren'),'["ability","byakuren"]'::jsonb,79),
  ('gensokyo_main','lore_ability_miko','character_ability','Miko Ability Frame','Miko scenes combine saintly charisma, hearing, and political shaping of an audience.',jsonb_build_object('character_id','miko'),'["ability","miko"]'::jsonb,81),
  ('gensokyo_main','lore_ability_seija','character_ability','Seija Ability Frame','Seija should be treated through inversion and contrarian reversal rather than plain mischief.',jsonb_build_object('character_id','seija'),'["ability","seija"]'::jsonb,78),
  ('gensokyo_main','lore_ability_shinmyoumaru','character_ability','Shinmyoumaru Ability Frame','Shinmyoumaru is tied to miracle-sized shifts emerging from smallness and symbolic imbalance.',jsonb_build_object('character_id','shinmyoumaru'),'["ability","shinmyoumaru"]'::jsonb,76),
  ('gensokyo_main','lore_ability_junko','character_ability','Junko Ability Frame','Junko should be framed through purified hostility and concentrated emotional reduction.',jsonb_build_object('character_id','junko'),'["ability","junko"]'::jsonb,86),
  ('gensokyo_main','lore_ability_okina','character_ability','Okina Ability Frame','Okina belongs to hidden doorways, backstage access, and the selective opening of routes and talent.',jsonb_build_object('character_id','okina'),'["ability","okina"]'::jsonb,84),
  ('gensokyo_main','lore_ability_keiki','character_ability','Keiki Ability Frame','Keiki is a creator of idols and systems, so her scenes should feel manufactured and intentional.',jsonb_build_object('character_id','keiki'),'["ability","keiki"]'::jsonb,78),
  ('gensokyo_main','lore_ability_chimata','character_ability','Chimata Ability Frame','Chimata scenes should tie value, markets, and social flow together as one mechanism.',jsonb_build_object('character_id','chimata'),'["ability","chimata"]'::jsonb,77)
on conflict (world_id, id) do update
set category = excluded.category,
    title = excluded.title,
    summary = excluded.summary,
    details = excluded.details,
    tags = excluded.tags,
    priority = excluded.priority,
    updated_at = now();

insert into public.world_canon_claims (
  id, world_id, subject_type, subject_id, claim_type, summary, details, source_id, confidence, priority, tags
)
values
  ('claim_ability_reimu','gensokyo_main','character','reimu','ability','Reimu is associated with spiritual intuition, floating, and direct incident-resolution competence.',jsonb_build_object('ability','float and spiritual response'),'src_sopm','official',90,'["ability","reimu"]'::jsonb),
  ('claim_ability_marisa','gensokyo_main','character','marisa','ability','Marisa is associated with practical magic, accumulation of tools, and forceful magical initiative.',jsonb_build_object('ability','magic and acquisitive improvisation'),'src_grimoire_marisa','official',88,'["ability","marisa"]'::jsonb),
  ('claim_ability_sakuya','gensokyo_main','character','sakuya','ability','Sakuya is strongly tied to impossible precision and control over timing.',jsonb_build_object('ability','time and precision control'),'src_eosd','official',85,'["ability","sakuya"]'::jsonb),
  ('claim_ability_yukari','gensokyo_main','character','yukari','ability','Yukari is fundamentally a boundary manipulator rather than an ordinary traveler or planner.',jsonb_build_object('ability','boundary manipulation'),'src_pcb','official',90,'["ability","yukari"]'::jsonb),
  ('claim_ability_eirin','gensokyo_main','character','eirin','ability','Eirin combines pharmaceutical mastery with strategic and technical superiority.',jsonb_build_object('ability','medicine and strategy'),'src_imperishable_night','official',87,'["ability","eirin"]'::jsonb),
  ('claim_ability_aya','gensokyo_main','character','aya','ability','Aya is associated with speed, wind, and the rapid circulation of information.',jsonb_build_object('ability','wind and speed'),'src_boaFW','official',83,'["ability","aya"]'::jsonb),
  ('claim_ability_satori','gensokyo_main','character','satori','ability','Satori''s defining power is reading minds and exposing motive.',jsonb_build_object('ability','mind reading'),'src_subterranean_animism','official',84,'["ability","satori"]'::jsonb),
  ('claim_ability_utsuho','gensokyo_main','character','utsuho','ability','Utsuho is tied to nuclear-scale energy and overwhelming output.',jsonb_build_object('ability','nuclear energy'),'src_subterranean_animism','official',84,'["ability","utsuho"]'::jsonb),
  ('claim_ability_byakuren','gensokyo_main','character','byakuren','ability','Byakuren is associated with powerful magic disciplined through religious and ethical orientation.',jsonb_build_object('ability','enhancing magic'),'src_ufo','official',80,'["ability","byakuren"]'::jsonb),
  ('claim_ability_miko','gensokyo_main','character','miko','ability','Miko is tied to saintly charisma and extraordinary hearing that supports leadership.',jsonb_build_object('ability','hearing and saintly authority'),'src_td','official',82,'["ability","miko"]'::jsonb),
  ('claim_ability_seija','gensokyo_main','character','seija','ability','Seija is defined by reversal and inversion of what should normally hold.',jsonb_build_object('ability','reversal'),'src_ddc','official',79,'["ability","seija"]'::jsonb),
  ('claim_ability_shinmyoumaru','gensokyo_main','character','shinmyoumaru','ability','Shinmyoumaru is tied to miracle and imbalance flowing from smallness and legendary tools.',jsonb_build_object('ability','miracle and small-folk power'),'src_ddc','official',77,'["ability","shinmyoumaru"]'::jsonb),
  ('claim_ability_junko','gensokyo_main','character','junko','ability','Junko is associated with purification into singular hostility and intent.',jsonb_build_object('ability','purification'),'src_lolk','official',87,'["ability","junko"]'::jsonb),
  ('claim_ability_okina','gensokyo_main','character','okina','ability','Okina is associated with backdoors, hidden access, and secret empowerment.',jsonb_build_object('ability','backdoor manipulation'),'src_hsifs','official',85,'["ability","okina"]'::jsonb),
  ('claim_ability_keiki','gensokyo_main','character','keiki','ability','Keiki is defined by the creation of idols and constructive counter-force.',jsonb_build_object('ability','create idols'),'src_wbawc','official',79,'["ability","keiki"]'::jsonb),
  ('claim_ability_chimata','gensokyo_main','character','chimata','ability','Chimata is tied to markets, ownership, and value as active social structure.',jsonb_build_object('ability','markets and value circulation'),'src_um','official',78,'["ability","chimata"]'::jsonb),
  ('claim_title_reimu','gensokyo_main','character','reimu','epithet','Reimu''s public image is anchored by the shrine maiden role and incident resolution.',jsonb_build_object('epithet','shrine maiden'),'src_sopm','official',88,'["title","reimu"]'::jsonb),
  ('claim_title_marisa','gensokyo_main','character','marisa','epithet','Marisa''s identity is anchored by ordinary-magician framing paired with extraordinary initiative.',jsonb_build_object('epithet','ordinary magician'),'src_grimoire_marisa','official',85,'["title","marisa"]'::jsonb),
  ('claim_title_yukari','gensokyo_main','character','yukari','epithet','Yukari''s image is anchored by boundary-youkai framing and high-order distance.',jsonb_build_object('epithet','boundary youkai'),'src_pcb','official',87,'["title","yukari"]'::jsonb),
  ('claim_title_miko','gensokyo_main','character','miko','epithet','Miko''s public role is strongly saintly and political rather than merely combative.',jsonb_build_object('epithet','saintly leader'),'src_td','official',81,'["title","miko"]'::jsonb)
on conflict (id) do update
set subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    claim_type = excluded.claim_type,
    summary = excluded.summary,
    details = excluded.details,
    source_id = excluded.source_id,
    confidence = excluded.confidence,
    priority = excluded.priority,
    tags = excluded.tags,
    updated_at = now();

-- END FILE: WORLD_SEED_CHARACTER_ABILITIES_CORE.sql

-- BEGIN FILE: WORLD_SEED_CHARACTER_ABILITIES_EXTENDED.sql
-- World seed: extended character abilities and epithet frames

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_ability_remilia','character_ability','Remilia Ability Frame','Remilia should be framed through aristocratic pressure, fate-linked menace, and symbolic control rather than simple brute violence.',jsonb_build_object('character_id','remilia'),'["ability","remilia"]'::jsonb,82),
  ('gensokyo_main','lore_ability_patchouli','character_ability','Patchouli Ability Frame','Patchouli belongs to prepared magic, scholarship, and controlled elemental or library-centered knowledge scenes.',jsonb_build_object('character_id','patchouli'),'["ability","patchouli"]'::jsonb,80),
  ('gensokyo_main','lore_ability_alice','character_ability','Alice Ability Frame','Alice should read through dolls, craft precision, and socially measured distance.',jsonb_build_object('character_id','alice'),'["ability","alice"]'::jsonb,78),
  ('gensokyo_main','lore_ability_youmu','character_ability','Youmu Ability Frame','Youmu combines sword discipline, duty, and half-phantom speed rather than mere earnestness alone.',jsonb_build_object('character_id','youmu'),'["ability","youmu"]'::jsonb,79),
  ('gensokyo_main','lore_ability_yuyuko','character_ability','Yuyuko Ability Frame','Yuyuko belongs to scenes of elegant appetite, death-adjacent awareness, and lightly concealed certainty.',jsonb_build_object('character_id','yuyuko'),'["ability","yuyuko"]'::jsonb,79),
  ('gensokyo_main','lore_ability_mokou','character_ability','Mokou Ability Frame','Mokou should be treated through endurance, plainspoken force, and long historical burn rather than temporary flair.',jsonb_build_object('character_id','mokou'),'["ability","mokou"]'::jsonb,78),
  ('gensokyo_main','lore_ability_kaguya','character_ability','Kaguya Ability Frame','Kaguya scenes should combine noble distance, immortality context, and symbolic weight around status and time.',jsonb_build_object('character_id','kaguya'),'["ability","kaguya"]'::jsonb,77),
  ('gensokyo_main','lore_ability_kanako','character_ability','Kanako Ability Frame','Kanako belongs to influence, systems, gathered faith, and strategic expansion rather than passive divinity.',jsonb_build_object('character_id','kanako'),'["ability","kanako"]'::jsonb,79),
  ('gensokyo_main','lore_ability_suwako','character_ability','Suwako Ability Frame','Suwako should read as old power carried lightly, not as a harmless elder presence.',jsonb_build_object('character_id','suwako'),'["ability","suwako"]'::jsonb,76),
  ('gensokyo_main','lore_ability_mamizou','character_ability','Mamizou Ability Frame','Mamizou is tied to transformation, adaptation, and social flexibility more than fixed frontal dominance.',jsonb_build_object('character_id','mamizou'),'["ability","mamizou"]'::jsonb,77),
  ('gensokyo_main','lore_ability_raiko','character_ability','Raiko Ability Frame','Raiko scenes should foreground rhythm, independence, and post-object autonomy.',jsonb_build_object('character_id','raiko'),'["ability","raiko"]'::jsonb,72),
  ('gensokyo_main','lore_ability_sagume','character_ability','Sagume Ability Frame','Sagume belongs to implication, reversal risk, and dangerous speech-act caution.',jsonb_build_object('character_id','sagume'),'["ability","sagume"]'::jsonb,82),
  ('gensokyo_main','lore_ability_clownpiece','character_ability','Clownpiece Ability Frame','Clownpiece should feel bright, infernal, and aggressively destabilizing rather than merely silly.',jsonb_build_object('character_id','clownpiece'),'["ability","clownpiece"]'::jsonb,76),
  ('gensokyo_main','lore_ability_yachie','character_ability','Yachie Ability Frame','Yachie belongs to leverage, command through indirection, and cold political motion.',jsonb_build_object('character_id','yachie'),'["ability","yachie"]'::jsonb,78),
  ('gensokyo_main','lore_ability_takane','character_ability','Takane Ability Frame','Takane should be framed through trade intelligence, brokerage, and practical market route knowledge.',jsonb_build_object('character_id','takane'),'["ability","takane"]'::jsonb,74),
  ('gensokyo_main','lore_ability_sumireko','character_ability','Sumireko Ability Frame','Sumireko works through psychic push, rumor bleed, and outside-world overreach.',jsonb_build_object('character_id','sumireko'),'["ability","sumireko"]'::jsonb,75)
on conflict (world_id, id) do update
set category = excluded.category,
    title = excluded.title,
    summary = excluded.summary,
    details = excluded.details,
    tags = excluded.tags,
    priority = excluded.priority,
    updated_at = now();

insert into public.world_canon_claims (
  id, world_id, subject_type, subject_id, claim_type, summary, details, source_id, confidence, priority, tags
)
values
  ('claim_ability_remilia','gensokyo_main','character','remilia','ability','Remilia is tied to fate-linked aristocratic menace and symbolic household command.',jsonb_build_object('ability','fate and aristocratic pressure'),'src_eosd','official',83,'["ability","remilia"]'::jsonb),
  ('claim_ability_patchouli','gensokyo_main','character','patchouli','ability','Patchouli is tied to prepared magic, deep scholarship, and library-centered spellcraft.',jsonb_build_object('ability','prepared magic'),'src_eosd','official',81,'["ability","patchouli"]'::jsonb),
  ('claim_ability_alice','gensokyo_main','character','alice','ability','Alice is defined by dolls, craft precision, and controlled magical construction.',jsonb_build_object('ability','doll manipulation'),'src_pcb','official',79,'["ability","alice"]'::jsonb),
  ('claim_ability_youmu','gensokyo_main','character','youmu','ability','Youmu combines sword discipline with half-phantom speed and service-borne focus.',jsonb_build_object('ability','sword and half-phantom speed'),'src_pcb','official',80,'["ability","youmu"]'::jsonb),
  ('claim_ability_yuyuko','gensokyo_main','character','yuyuko','ability','Yuyuko is tied to death-adjacent grace, appetite, and quiet certainty.',jsonb_build_object('ability','death and ghostly nobility'),'src_pcb','official',80,'["ability","yuyuko"]'::jsonb),
  ('claim_ability_mokou','gensokyo_main','character','mokou','ability','Mokou is shaped by immortality, endurance, and practical destructive force.',jsonb_build_object('ability','immortality and fire endurance'),'src_imperishable_night','official',79,'["ability","mokou"]'::jsonb),
  ('claim_ability_kaguya','gensokyo_main','character','kaguya','ability','Kaguya belongs to noble immortality, symbolic status, and elegant distance.',jsonb_build_object('ability','immortality and lunar nobility'),'src_imperishable_night','official',78,'["ability","kaguya"]'::jsonb),
  ('claim_ability_kanako','gensokyo_main','character','kanako','ability','Kanako is associated with gathered faith, systems, and ambitious divine influence.',jsonb_build_object('ability','faith and strategic influence'),'src_mofa','official',80,'["ability","kanako"]'::jsonb),
  ('claim_ability_suwako','gensokyo_main','character','suwako','ability','Suwako is old divine power carried in a casual tone, not harmlessness.',jsonb_build_object('ability','old native divine power'),'src_mofa','official',77,'["ability","suwako"]'::jsonb),
  ('claim_ability_mamizou','gensokyo_main','character','mamizou','ability','Mamizou is associated with transformation, adaptation, and socially flexible power.',jsonb_build_object('ability','transformation'),'src_td','official',78,'["ability","mamizou"]'::jsonb),
  ('claim_ability_raiko','gensokyo_main','character','raiko','ability','Raiko is tied to rhythm, thunderous performance, and independent tsukumogami momentum.',jsonb_build_object('ability','rhythm and independent animation'),'src_ddc','official',73,'["ability","raiko"]'::jsonb),
  ('claim_ability_sagume','gensokyo_main','character','sagume','ability','Sagume should be framed through dangerous implication and carefully managed speech.',jsonb_build_object('ability','dangerous speech and reversal risk'),'src_lolk','official',83,'["ability","sagume"]'::jsonb),
  ('claim_ability_clownpiece','gensokyo_main','character','clownpiece','ability','Clownpiece combines infernal backing, fairy energy, and destabilizing brightness.',jsonb_build_object('ability','hell-backed fairy disruption'),'src_lolk','official',77,'["ability","clownpiece"]'::jsonb),
  ('claim_ability_yachie','gensokyo_main','character','yachie','ability','Yachie belongs to indirect domination, leverage, and strategic reptilian calm.',jsonb_build_object('ability','indirect control'),'src_wbawc','official',79,'["ability","yachie"]'::jsonb),
  ('claim_ability_takane','gensokyo_main','character','takane','ability','Takane is strongly associated with brokerage, trade routes, and commercially useful intelligence.',jsonb_build_object('ability','brokerage and trade intelligence'),'src_um','official',75,'["ability","takane"]'::jsonb),
  ('claim_ability_sumireko','gensokyo_main','character','sumireko','ability','Sumireko is associated with psychic action and outside-world rumor pressure crossing into Gensokyo.',jsonb_build_object('ability','psychic and urban legend pressure'),'src_ulil','official',76,'["ability","sumireko"]'::jsonb)
on conflict (id) do update
set subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    claim_type = excluded.claim_type,
    summary = excluded.summary,
    details = excluded.details,
    source_id = excluded.source_id,
    confidence = excluded.confidence,
    priority = excluded.priority,
    tags = excluded.tags,
    updated_at = now();

-- END FILE: WORLD_SEED_CHARACTER_ABILITIES_EXTENDED.sql

-- BEGIN FILE: WORLD_SEED_CHARACTER_ABILITIES_SUPPORT.sql
-- World seed: support-side abilities for key recurring non-lead actors

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_ability_nitori','character_ability','Nitori Ability Frame','Nitori should be framed through engineering, practical invention, and curious optimization rather than generic gadget clutter.',jsonb_build_object('character_id','nitori'),'["ability","nitori"]'::jsonb,80),
  ('gensokyo_main','lore_ability_keine','character_ability','Keine Ability Frame','Keine belongs to protection, instruction, and continuity-minded intervention around village life and history.',jsonb_build_object('character_id','keine'),'["ability","keine"]'::jsonb,79),
  ('gensokyo_main','lore_ability_akyuu','character_ability','Akyuu Ability Frame','Akyuu should be used through structured memory, classification, and documentary intelligence.',jsonb_build_object('character_id','akyuu'),'["ability","akyuu"]'::jsonb,80),
  ('gensokyo_main','lore_ability_kasen','character_ability','Kasen Ability Frame','Kasen scenes should combine advice, training, hidden depth, and corrective pressure.',jsonb_build_object('character_id','kasen'),'["ability","kasen"]'::jsonb,78),
  ('gensokyo_main','lore_ability_komachi','character_ability','Komachi Ability Frame','Komachi should be tied to crossings, managed delay, ferryman duty, and lazy consequentiality.',jsonb_build_object('character_id','komachi'),'["ability","komachi"]'::jsonb,76),
  ('gensokyo_main','lore_ability_eiki','character_ability','Eiki Ability Frame','Eiki belongs to moral judgment, corrective speech, and formal afterlife authority.',jsonb_build_object('character_id','eiki'),'["ability","eiki"]'::jsonb,80),
  ('gensokyo_main','lore_ability_tewi','character_ability','Tewi Ability Frame','Tewi should be framed through luck, detours, and evasive local manipulation rather than broad command.',jsonb_build_object('character_id','tewi'),'["ability","tewi"]'::jsonb,74),
  ('gensokyo_main','lore_ability_suika','character_ability','Suika Ability Frame','Suika belongs to compression, revelry, oni force, and social pressure through gathering.',jsonb_build_object('character_id','suika'),'["ability","suika"]'::jsonb,78)
on conflict (world_id, id) do update
set category = excluded.category,
    title = excluded.title,
    summary = excluded.summary,
    details = excluded.details,
    tags = excluded.tags,
    priority = excluded.priority,
    updated_at = now();

insert into public.world_canon_claims (
  id, world_id, subject_type, subject_id, claim_type, summary, details, source_id, confidence, priority, tags
)
values
  ('claim_ability_nitori','gensokyo_main','character','nitori','ability','Nitori is associated with engineering, mechanical invention, and practical technical improvisation.',jsonb_build_object('ability','engineering and invention'),'src_mofa','official',81,'["ability","nitori"]'::jsonb),
  ('claim_ability_keine','gensokyo_main','character','keine','ability','Keine is tied to protection, instruction, and the preservation of village continuity and history.',jsonb_build_object('ability','protection and history-linked guardianship'),'src_imperishable_night','official',80,'["ability","keine"]'::jsonb),
  ('claim_ability_akyuu','gensokyo_main','character','akyuu','ability','Akyuu is associated with structured memory, records, and historical compilation.',jsonb_build_object('ability','memory and documentation'),'src_sixty_years','official',82,'["ability","akyuu"]'::jsonb),
  ('claim_ability_kasen','gensokyo_main','character','kasen','ability','Kasen belongs to hermit discipline, guidance, and hidden depth under corrective demeanor.',jsonb_build_object('ability','hermit training and guidance'),'src_wahh','official',79,'["ability","kasen"]'::jsonb),
  ('claim_ability_komachi','gensokyo_main','character','komachi','ability','Komachi is associated with ferrying, crossing management, and consequential laziness at the border of life and death.',jsonb_build_object('ability','ferrying and crossing management'),'src_poFV','official',77,'["ability","komachi"]'::jsonb),
  ('claim_ability_eiki','gensokyo_main','character','eiki','ability','Eiki is defined by judgment, moral correction, and formal authority over the dead.',jsonb_build_object('ability','judgment'),'src_poFV','official',82,'["ability","eiki"]'::jsonb),
  ('claim_ability_tewi','gensokyo_main','character','tewi','ability','Tewi belongs to luck, trickery, and the production of useful detours.',jsonb_build_object('ability','luck and evasive trickery'),'src_imperishable_night','official',75,'["ability","tewi"]'::jsonb),
  ('claim_ability_suika','gensokyo_main','character','suika','ability','Suika is associated with oni strength, density, and revelry as social force.',jsonb_build_object('ability','density and oni force'),'src_swl','official',79,'["ability","suika"]'::jsonb)
on conflict (id) do update
set subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    claim_type = excluded.claim_type,
    summary = excluded.summary,
    details = excluded.details,
    source_id = excluded.source_id,
    confidence = excluded.confidence,
    priority = excluded.priority,
    tags = excluded.tags,
    updated_at = now();

-- END FILE: WORLD_SEED_CHARACTER_ABILITIES_SUPPORT.sql

-- BEGIN FILE: WORLD_SEED_CHAT_CHARACTER_VOICES.sql
-- World seed: chat context emphasizing stable character voice and conversational framing

insert into public.world_chat_context_cache (
  id, world_id, user_scope, character_id, location_id, event_id, context_type, summary, payload, freshness_score, last_used_at
)
values
  (
    'chat_voice_reimu_core',
    'gensokyo_main',
    'global',
    'reimu',
    null,
    null,
    'character_voice',
    'Reimu should sound dry, practical, and mildly burdened by being the person trouble ends up reaching.',
    jsonb_build_object(
      'speech_style', 'dry, direct, practical',
      'worldview', 'Balance matters more than ceremony.',
      'claim_ids', array['claim_ability_reimu','claim_title_reimu']
    ),
    0.95,
    now()
  ),
  (
    'chat_voice_marisa_core',
    'gensokyo_main',
    'global',
    'marisa',
    null,
    null,
    'character_voice',
    'Marisa should sound casual, bold, teasing, and genuinely interested in interesting trouble.',
    jsonb_build_object(
      'speech_style', 'casual, bold, teasing',
      'worldview', 'Interesting trouble is better than dull safety.',
      'claim_ids', array['claim_ability_marisa','claim_title_marisa']
    ),
    0.95,
    now()
  ),
  (
    'chat_voice_sakuya_core',
    'gensokyo_main',
    'global',
    'sakuya',
    null,
    null,
    'character_voice',
    'Sakuya should sound composed, precise, and slightly understated even when exerting impossible control.',
    jsonb_build_object(
      'speech_style', 'precise, composed, understated',
      'worldview', 'Control and timing matter.',
      'claim_ids', array['claim_ability_sakuya']
    ),
    0.92,
    now()
  ),
  (
    'chat_voice_yukari_core',
    'gensokyo_main',
    'global',
    'yukari',
    null,
    null,
    'character_voice',
    'Yukari should sound relaxed and layered, with distance and framing doing as much work as direct statement.',
    jsonb_build_object(
      'speech_style', 'relaxed, layered, elusive',
      'worldview', 'Distance and framing decide outcomes.',
      'claim_ids', array['claim_ability_yukari','claim_title_yukari']
    ),
    0.93,
    now()
  ),
  (
    'chat_voice_eirin_core',
    'gensokyo_main',
    'global',
    'eirin',
    null,
    null,
    'character_voice',
    'Eirin should sound calm, brilliant, and clinical, with competence implied before it is stated.',
    jsonb_build_object(
      'speech_style', 'calm, brilliant, clinical',
      'worldview', 'A precise solution is worth waiting for.',
      'claim_ids', array['claim_ability_eirin']
    ),
    0.92,
    now()
  ),
  (
    'chat_voice_miko_core',
    'gensokyo_main',
    'global',
    'miko',
    null,
    null,
    'character_voice',
    'Miko should sound measured and charismatic, as if speaking to shape a listener rather than merely answer them.',
    jsonb_build_object(
      'speech_style', 'measured, charismatic, superior',
      'worldview', 'Order is easier to shape when people already expect to listen.',
      'claim_ids', array['claim_ability_miko','claim_title_miko']
    ),
    0.91,
    now()
  ),
  (
    'chat_voice_sumireko_core',
    'gensokyo_main',
    'global',
    'sumireko',
    null,
    null,
    'character_voice',
    'Sumireko should sound smart, excited, and overconfident, with outside-world framing leaking into her read of Gensokyo.',
    jsonb_build_object(
      'speech_style', 'smart, excited, overconfident',
      'worldview', 'A rumor gets more interesting once it crosses a boundary.',
      'claim_ids', array['claim_ability_sumireko','claim_sumireko_urban_legend']
    ),
    0.88,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

-- END FILE: WORLD_SEED_CHAT_CHARACTER_VOICES.sql

-- BEGIN FILE: WORLD_SEED_CHAT_CHARACTER_VOICES_EXTENDED.sql
-- World seed: extended stable character voice cache

insert into public.world_chat_context_cache (
  id, world_id, user_scope, character_id, location_id, event_id, context_type, summary, payload, freshness_score, last_used_at
)
values
  (
    'chat_voice_nitori_core',
    'gensokyo_main',
    'global',
    'nitori',
    null,
    null,
    'character_voice',
    'Nitori should sound curious, technical, and opportunistically enthusiastic about mechanisms that might actually work.',
    jsonb_build_object(
      'speech_style', 'quick, technical, curious',
      'worldview', 'If it can be improved, it should be tested.',
      'claim_ids', array['claim_ability_nitori']
    ),
    0.91,
    now()
  ),
  (
    'chat_voice_aya_core',
    'gensokyo_main',
    'global',
    'aya',
    null,
    null,
    'character_voice',
    'Aya should sound fast, confident, and framing-oriented, as if already turning the moment into public narrative.',
    jsonb_build_object(
      'speech_style', 'fast, confident, teasing',
      'worldview', 'If it spreads, it matters.',
      'claim_ids', array['claim_ability_aya','claim_aya_public_narrative']
    ),
    0.92,
    now()
  ),
  (
    'chat_voice_keine_core',
    'gensokyo_main',
    'global',
    'keine',
    null,
    null,
    'character_voice',
    'Keine should sound firm, caring, and historically minded, with continuity always somewhere in the sentence.',
    jsonb_build_object(
      'speech_style', 'firm, caring, instructive',
      'worldview', 'Continuity is worth defending.',
      'claim_ids', array['claim_ability_keine']
    ),
    0.90,
    now()
  ),
  (
    'chat_voice_akyuu_core',
    'gensokyo_main',
    'global',
    'akyuu',
    null,
    null,
    'character_voice',
    'Akyuu should sound composed, documentary, and gently precise, as if everything might become part of a record.',
    jsonb_build_object(
      'speech_style', 'polite, observant, composed',
      'worldview', 'A world without records becomes easier to misunderstand.',
      'claim_ids', array['claim_ability_akyuu','claim_akyuu_historian']
    ),
    0.91,
    now()
  ),
  (
    'chat_voice_kasen_core',
    'gensokyo_main',
    'global',
    'kasen',
    null,
    null,
    'character_voice',
    'Kasen should sound corrective, capable, and faintly exasperated in a way that still implies concern.',
    jsonb_build_object(
      'speech_style', 'firm, caring, critical',
      'worldview', 'Helping someone often includes telling them what they would rather ignore.',
      'claim_ids', array['claim_ability_kasen','claim_kasen_advisor']
    ),
    0.89,
    now()
  ),
  (
    'chat_voice_komachi_core',
    'gensokyo_main',
    'global',
    'komachi',
    null,
    null,
    'character_voice',
    'Komachi should sound easygoing and teasing, but never so loose that crossing and consequence disappear from view.',
    jsonb_build_object(
      'speech_style', 'lazy, teasing, easygoing',
      'worldview', 'If a crossing will still be there later, rushing is not always the first answer.',
      'claim_ids', array['claim_ability_komachi','claim_komachi_border_worker']
    ),
    0.87,
    now()
  ),
  (
    'chat_voice_eiki_core',
    'gensokyo_main',
    'global',
    'eiki',
    null,
    null,
    'character_voice',
    'Eiki should sound formal, stern, and morally compressive, as if excuses are being weighed while they are spoken.',
    jsonb_build_object(
      'speech_style', 'formal, stern, instructive',
      'worldview', 'A judgment delayed is not the same as a judgment escaped.',
      'claim_ids', array['claim_ability_eiki','claim_eiki_judge']
    ),
    0.90,
    now()
  ),
  (
    'chat_voice_tewi_core',
    'gensokyo_main',
    'global',
    'tewi',
    null,
    null,
    'character_voice',
    'Tewi should sound playful and slippery, always making a straight answer feel slightly less useful than a detour.',
    jsonb_build_object(
      'speech_style', 'playful, slippery, teasing',
      'worldview', 'A detour can be more useful than a straight answer.',
      'claim_ids', array['claim_ability_tewi','claim_tewi_eientei_trickster']
    ),
    0.88,
    now()
  ),
  (
    'chat_voice_suika_core',
    'gensokyo_main',
    'global',
    'suika',
    null,
    null,
    'character_voice',
    'Suika should sound boisterous and amused, with gathering, pressure, and delight all packed into one tone.',
    jsonb_build_object(
      'speech_style', 'boisterous, amused, direct',
      'worldview', 'If the gathering is worth having, make it bigger.',
      'claim_ids', array['claim_ability_suika','claim_suika_old_power']
    ),
    0.89,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

-- END FILE: WORLD_SEED_CHAT_CHARACTER_VOICES_EXTENDED.sql

-- BEGIN FILE: WORLD_SEED_LOCATION_GLOSSARY_EXTENDED.sql
-- World seed: extended location glossary and profiles

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_glossary_forest_of_magic','location_trait','Forest of Magic Glossary','Forest of Magic should feel private, hazardous, and craft-oriented rather than merely mysterious wallpaper.',jsonb_build_object('location_id','forest_of_magic'),'["glossary","location","forest_of_magic"]'::jsonb,82),
  ('gensokyo_main','lore_glossary_misty_lake','location_trait','Misty Lake Glossary','Misty Lake scenes work best when local trouble, fairy energy, and the mansion approach overlap.',jsonb_build_object('location_id','misty_lake'),'["glossary","location","misty_lake"]'::jsonb,76),
  ('gensokyo_main','lore_glossary_bamboo_forest','location_trait','Bamboo Forest Glossary','Bamboo Forest should be treated as a maze of hidden routes, local guides, and unreliable orientation.',jsonb_build_object('location_id','bamboo_forest'),'["glossary","location","bamboo_forest"]'::jsonb,81),
  ('gensokyo_main','lore_glossary_netherworld','location_trait','Netherworld Glossary','The Netherworld is an elegant death-adjacent realm where etiquette and boundary-aesthetics matter.',jsonb_build_object('location_id','netherworld'),'["glossary","location","netherworld"]'::jsonb,80),
  ('gensokyo_main','lore_glossary_former_hell','location_trait','Former Hell Glossary','Former Hell and the Old Capital should feel rowdy, rule-bound, and socially forceful rather than chaotic at random.',jsonb_build_object('location_id','former_hell'),'["glossary","location","former_hell"]'::jsonb,80),
  ('gensokyo_main','lore_glossary_muenzuka','location_trait','Muenzuka Glossary','Muenzuka belongs to border-field logic, abandoned things, and difficult crossings near the outside.',jsonb_build_object('location_id','muenzuka'),'["glossary","location","muenzuka"]'::jsonb,79),
  ('gensokyo_main','lore_glossary_rainbow_dragon_cave','location_trait','Rainbow Dragon Cave Glossary','Rainbow Dragon Cave should be treated as a market-resource cave where hidden value and trade routes converge.',jsonb_build_object('location_id','rainbow_dragon_cave'),'["glossary","location","rainbow_dragon_cave"]'::jsonb,77),
  ('gensokyo_main','lore_glossary_chireiden','location_trait','Chireiden Glossary','Chireiden should feel psychologically pressurized, intimate, and controlled by uncomfortable clarity.',jsonb_build_object('location_id','chireiden'),'["glossary","location","chireiden"]'::jsonb,79),
  ('gensokyo_main','lore_glossary_divine_spirit_mausoleum','location_trait','Divine Spirit Mausoleum Glossary','The mausoleum is best read as a stage of return, legitimacy, and ritual authority.',jsonb_build_object('location_id','divine_spirit_mausoleum'),'["glossary","location","mausoleum"]'::jsonb,79),
  ('gensokyo_main','lore_glossary_backdoor_realm','location_trait','Backdoor Realm Glossary','The Backdoor Realm should feel like controlled hidden access, not a generic magical side-space.',jsonb_build_object('location_id','backdoor_realm'),'["glossary","location","backdoor_realm"]'::jsonb,78)
on conflict (world_id, id) do update
set category = excluded.category,
    title = excluded.title,
    summary = excluded.summary,
    details = excluded.details,
    tags = excluded.tags,
    priority = excluded.priority,
    updated_at = now();

insert into public.world_canon_claims (
  id, world_id, subject_type, subject_id, claim_type, summary, details, source_id, confidence, priority, tags
)
values
  ('claim_glossary_forest_of_magic','gensokyo_main','location','forest_of_magic','glossary','Forest of Magic is a private and dangerous craft-space rather than a neutral travel zone.',jsonb_build_object('linked_characters',array['marisa','alice','narumi']),'src_pcb','official',82,'["glossary","forest_of_magic","location"]'::jsonb),
  ('claim_glossary_misty_lake','gensokyo_main','location','misty_lake','glossary','Misty Lake is a local-energy area where fairy movement and mansion approach overlap.',jsonb_build_object('linked_characters',array['cirno','wakasagihime','meiling']),'src_eosd','official',76,'["glossary","misty_lake","location"]'::jsonb),
  ('claim_glossary_bamboo_forest','gensokyo_main','location','bamboo_forest','glossary','Bamboo Forest is a maze of hidden routes, local knowledge, and unreliable orientation.',jsonb_build_object('linked_characters',array['tewi','mokou','kagerou']),'src_imperishable_night','official',82,'["glossary","bamboo_forest","location"]'::jsonb),
  ('claim_glossary_netherworld','gensokyo_main','location','netherworld','glossary','The Netherworld should feel elegant, death-adjacent, and boundary-sensitive.',jsonb_build_object('linked_characters',array['yuyuko','youmu']),'src_pcb','official',81,'["glossary","netherworld","location"]'::jsonb),
  ('claim_glossary_former_hell','gensokyo_main','location','former_hell','glossary','Former Hell is a socially forceful underworld region with rowdy but real local rules.',jsonb_build_object('linked_characters',array['suika','utsuho','rin','satori']),'src_subterranean_animism','official',81,'["glossary","former_hell","location"]'::jsonb),
  ('claim_glossary_muenzuka','gensokyo_main','location','muenzuka','glossary','Muenzuka should be read as a border field of abandonment, crossing, and near-outside tension.',jsonb_build_object('linked_characters',array['komachi','eiki','yukari']),'src_poFV','official',80,'["glossary","muenzuka","location"]'::jsonb),
  ('claim_glossary_rainbow_dragon_cave','gensokyo_main','location','rainbow_dragon_cave','glossary','Rainbow Dragon Cave is a hidden-value and market-route cave tied to mountain commerce.',jsonb_build_object('linked_characters',array['takane','sannyo','momoyo','misumaru']),'src_um','official',78,'["glossary","rainbow_dragon_cave","location"]'::jsonb),
  ('claim_glossary_chireiden','gensokyo_main','location','chireiden','glossary','Chireiden is an underground palace of close interior pressure, pets, and uncomfortable mental clarity.',jsonb_build_object('linked_characters',array['satori','koishi','rin','utsuho']),'src_subterranean_animism','official',80,'["glossary","chireiden","location"]'::jsonb),
  ('claim_glossary_divine_spirit_mausoleum','gensokyo_main','location','divine_spirit_mausoleum','glossary','The Divine Spirit Mausoleum is a return-of-authority stage built around legitimacy and ritual display.',jsonb_build_object('linked_characters',array['miko','futo','tojiko','seiga']),'src_td','official',80,'["glossary","mausoleum","location"]'::jsonb),
  ('claim_glossary_backdoor_realm','gensokyo_main','location','backdoor_realm','glossary','The Backdoor Realm is a hidden-access space of selected passage and backstage intervention.',jsonb_build_object('linked_characters',array['okina','satono','mai']),'src_hsifs','official',79,'["glossary","backdoor_realm","location"]'::jsonb)
on conflict (id) do update
set subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    claim_type = excluded.claim_type,
    summary = excluded.summary,
    details = excluded.details,
    source_id = excluded.source_id,
    confidence = excluded.confidence,
    priority = excluded.priority,
    tags = excluded.tags,
    updated_at = now();

-- END FILE: WORLD_SEED_LOCATION_GLOSSARY_EXTENDED.sql

-- BEGIN FILE: WORLD_SEED_CHRONICLE.sql
-- World seed: chronicle, wiki, and chat context
-- Generated from WORLD_FULL_SETUP.sql for maintainable split loading.

insert into public.world_chronicle_books (
  id, world_id, title, author_character_id, chronicle_type, era_label, summary, tone, is_public, metadata
)
values
  (
    'chronicle_gensokyo_history',
    'gensokyo_main',
    'Chronicle of Gensokyo',
    'keine',
    'history',
    'Current Era',
    'A continuously maintained historical compilation intended to summarize major places, actors, and notable events in Gensokyo.',
    'measured',
    true,
    jsonb_build_object('editorial_style', 'keine_archival')
  ),
  (
    'chronicle_seasonal_incidents',
    'gensokyo_main',
    'Seasonal Gatherings and Incidents',
    'keine',
    'incident_record',
    'Recent Seasons',
    'A focused record of seasonal public events, disturbances, and how they entered common memory.',
    'documentary',
    true,
    jsonb_build_object('editorial_style', 'public_record')
  )
on conflict (id) do update
set title = excluded.title,
    author_character_id = excluded.author_character_id,
    chronicle_type = excluded.chronicle_type,
    era_label = excluded.era_label,
    summary = excluded.summary,
    tone = excluded.tone,
    is_public = excluded.is_public,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_chronicle_chapters (
  id, book_id, chapter_code, chapter_order, title, summary, period_start, period_end, metadata
)
values
  (
    'chronicle_gensokyo_history:chapter:foundations',
    'chronicle_gensokyo_history',
    'foundations',
    1,
    'Foundations of the World',
    'A structural overview of how Gensokyo maintains balance across people, places, and recurring disturbances.',
    null,
    null,
    '{}'::jsonb
  ),
  (
    'chronicle_gensokyo_history:chapter:principal_actors',
    'chronicle_gensokyo_history',
    'principal_actors',
    2,
    'Principal Actors',
    'A summary of those individuals whose roles most strongly shape the public life of Gensokyo.',
    null,
    null,
    '{}'::jsonb
  ),
  (
    'chronicle_seasonal_incidents:chapter:spring_festival',
    'chronicle_seasonal_incidents',
    'spring_festival',
    1,
    'Hakurei Spring Festival',
    'An ongoing record of the Hakurei Spring Festival as it passes from rumor into a shared public event.',
    now() - interval '1 day',
    now() + interval '7 day',
    '{}'::jsonb
  )
on conflict (id) do update
set title = excluded.title,
    summary = excluded.summary,
    period_start = excluded.period_start,
    period_end = excluded.period_end,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_chronicle_entries (
  id, book_id, chapter_id, entry_code, entry_order, entry_type, title, summary, body,
  subject_type, subject_id, narrator_character_id, event_id, history_id, tags, metadata
)
values
  (
    'chronicle_entry_gensokyo_balance',
    'chronicle_gensokyo_history',
    'chronicle_gensokyo_history:chapter:foundations',
    'gensokyo_balance',
    1,
    'essay',
    'On the Balance of Gensokyo',
    'A summary of the social and symbolic balance that allows Gensokyo to continue functioning.',
    'Gensokyo is not merely a collection of locations and residents. It persists because conflict, authority, rumor, and public life settle into repeating forms rather than endless collapse. Those who resolve incidents, those who amplify them, and those who record them all participate in the maintenance of that balance.',
    'world',
    'gensokyo_main',
    'keine',
    null,
    null,
    '["balance","history","world_rule"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'chronicle_entry_principal_actors',
    'chronicle_gensokyo_history',
    'chronicle_gensokyo_history:chapter:principal_actors',
    'principal_actors',
    1,
    'catalog',
    'Principal Public Actors of Gensokyo',
    'A historian''s overview of the people most likely to shape public events and incidents.',
    'Certain names recur whenever Gensokyo shifts: Reimu Hakurei, by official burden; Marisa Kirisame, by restless initiative; Aya Shameimaru, by speed of circulation; and other figures whose institutional or symbolic weight can reshape a local event into a widely remembered one.',
    'world',
    'gensokyo_main',
    'keine',
    null,
    null,
    '["actors","history","reference"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'chronicle_entry_spring_festival',
    'chronicle_seasonal_incidents',
    'chronicle_seasonal_incidents:chapter:spring_festival',
    'spring_festival_preparation',
    1,
    'incident_record',
    'The Hakurei Spring Festival Takes Public Shape',
    'An account of how a local seasonal preparation became a visible shared event.',
    'What first circulated as rumor in the Human Village soon hardened into expectation. Once preparations became visible at the Hakurei Shrine, the event ceased to be private labor and entered the category of public life. As ever, the work did not fall equally upon all involved.',
    'event',
    'story_spring_festival_001',
    'keine',
    'story_spring_festival_001',
    'story_spring_festival_001:history:preparation_visible',
    '["festival","spring","incident_record"]'::jsonb,
    '{}'::jsonb
  )
on conflict (id) do update
set title = excluded.title,
    summary = excluded.summary,
    body = excluded.body,
    subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    narrator_character_id = excluded.narrator_character_id,
    event_id = excluded.event_id,
    history_id = excluded.history_id,
    tags = excluded.tags,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_chronicle_entry_sources (
  id, entry_id, source_kind, source_ref_id, source_label, weight, notes
)
values
  ('chronicle_entry_gensokyo_balance:src:lore', 'chronicle_entry_gensokyo_balance', 'lore_entry', 'lore_gensokyo_balance', 'Balance Between Human and Youkai', 1.0, 'Foundational lore source'),
  ('chronicle_entry_gensokyo_balance:src:claim', 'chronicle_entry_gensokyo_balance', 'canon_claim', 'claim_spell_card_constraint', 'Spell Card Constraint', 0.9, 'Supports the non-total-war framing'),
  ('chronicle_entry_principal_actors:src:claim:reimu', 'chronicle_entry_principal_actors', 'canon_claim', 'claim_reimu_incident_resolver', 'Reimu Incident Resolver Claim', 1.0, 'Primary actor reference'),
  ('chronicle_entry_principal_actors:src:claim:marisa', 'chronicle_entry_principal_actors', 'canon_claim', 'claim_marisa_incident_actor', 'Marisa Incident Actor Claim', 0.9, 'Primary actor reference'),
  ('chronicle_entry_spring_festival:src:history:rumor', 'chronicle_entry_spring_festival', 'history', 'story_spring_festival_001:history:opening_rumor', 'Village Rumor History', 0.8, 'Chronological lead-in'),
  ('chronicle_entry_spring_festival:src:history:prep', 'chronicle_entry_spring_festival', 'history', 'story_spring_festival_001:history:preparation_visible', 'Preparation Visible History', 1.0, 'Main event source')
on conflict (id) do update
set source_kind = excluded.source_kind,
    source_ref_id = excluded.source_ref_id,
    source_label = excluded.source_label,
    weight = excluded.weight,
    notes = excluded.notes;

insert into public.world_historian_notes (
  id, world_id, historian_character_id, subject_type, subject_id, note_kind, title, summary, body, source_ref_ids, metadata
)
values
  (
    'historian_note_keine_reimu',
    'gensokyo_main',
    'keine',
    'character',
    'reimu',
    'editorial',
    'On Reimu''s Place in Public Memory',
    'A note on why Reimu appears disproportionately in historical summaries of disturbances.',
    'Reimu Hakurei appears often in the records not because all events are hers, but because many disturbances become legible to the public through the fact of her involvement. This should not be mistaken for solitary authorship of Gensokyo''s history.',
    '["claim_reimu_incident_resolver","lore_reimu_position"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'historian_note_keine_festival',
    'gensokyo_main',
    'keine',
    'event',
    'story_spring_festival_001',
    'editorial',
    'On Recording Seasonal Events',
    'A note on why public seasonal events deserve historical treatment.',
    'Seasonal gatherings are not trivial simply because they are peaceful. They show how Gensokyo organizes expectation, labor, rumor, and local cooperation without requiring a formal crisis.',
    '["story_spring_festival_001:history:opening_rumor","story_spring_festival_001:history:preparation_visible"]'::jsonb,
    '{}'::jsonb
  )
on conflict (id) do update
set title = excluded.title,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  (
    'wiki_character_reimu',
    'gensokyo_main',
    'characters/reimu-hakurei',
    'Reimu Hakurei',
    'character',
    'character',
    'reimu',
    'Shrine maiden of the Hakurei Shrine and a central public actor in Gensokyo incident resolution.',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_location_hakurei_shrine',
    'gensokyo_main',
    'locations/hakurei-shrine',
    'Hakurei Shrine',
    'location',
    'location',
    'hakurei_shrine',
    'A shrine that acts both as a symbol of order and as a magnet for public trouble.',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_rule_spell_cards',
    'gensokyo_main',
    'world/spell-card-rules',
    'Spell Card Rule Culture',
    'world_rule',
    'world',
    'gensokyo_main',
    'A summary of how conflict is ritualized and socially constrained within Gensokyo.',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_event_spring_festival',
    'gensokyo_main',
    'events/hakurei-spring-festival',
    'Hakurei Spring Festival',
    'event',
    'event',
    'story_spring_festival_001',
    'An ongoing seasonal event centered on public preparation, uneven enthusiasm, and shrine-centered visibility.',
    'published',
    'chronicle_seasonal_incidents',
    '{}'::jsonb
  )
on conflict (id) do update
set slug = excluded.slug,
    title = excluded.title,
    page_type = excluded.page_type,
    subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    summary = excluded.summary,
    status = excluded.status,
    canonical_book_id = excluded.canonical_book_id,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_wiki_page_sections (
  id, page_id, section_code, section_order, heading, summary, body, source_ref_ids, metadata
)
values
  (
    'wiki_character_reimu:section:overview',
    'wiki_character_reimu',
    'overview',
    1,
    'Overview',
    'Reimu as a public figure and incident resolver.',
    'Reimu Hakurei is central to many public disturbances in Gensokyo. Her role is not simply ceremonial; it is tied to how the public understands restoration of balance.',
    '["claim_reimu_incident_resolver","lore_reimu_position"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_location_hakurei_shrine:section:profile',
    'wiki_location_hakurei_shrine',
    'profile',
    1,
    'Profile',
    'Hakurei Shrine as social and symbolic space.',
    'The Hakurei Shrine functions both as a shrine and as a public symbolic center where incidents, rumors, and gatherings often become visible to the wider world.',
    '["lore_hakurei_role"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_rule_spell_cards:section:world_rule',
    'wiki_rule_spell_cards',
    'world_rule',
    1,
    'Rule Summary',
    'Conflict limitation through ritualized structure.',
    'Gensokyo does not treat every dispute as an unrestricted fight. Cultural and formal rules shape many conflicts into bounded contests, helping preserve continuity instead of permanent ruin.',
    '["claim_spell_card_constraint","lore_spell_card_rules"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_event_spring_festival:section:current_state',
    'wiki_event_spring_festival',
    'current_state',
    1,
    'Current State',
    'The event is in preparation and already public.',
    'The Hakurei Spring Festival has passed beyond rumor. Preparations are visible, public expectations are forming, and the people involved are not yet aligned in mood or motive.',
    '["story_spring_festival_001:history:opening_rumor","story_spring_festival_001:history:preparation_visible"]'::jsonb,
    '{}'::jsonb
  )
on conflict (id) do update
set heading = excluded.heading,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_chat_context_cache (
  id, world_id, user_scope, character_id, location_id, event_id, context_type, summary, payload, freshness_score, last_used_at
)
values
  (
    'chat_context_global_reimu_shrine',
    'gensokyo_main',
    'global',
    'reimu',
    'hakurei_shrine',
    'story_spring_festival_001',
    'character_location_story',
    'Reimu is at Hakurei Shrine during a public preparation phase and is likely to frame the festival as work before celebration.',
    jsonb_build_object(
      'memory_ids', array['story_spring_festival_001:memory:reimu:prep'],
      'claim_ids', array['claim_reimu_incident_resolver'],
      'event_ids', array['story_spring_festival_001']
    ),
    0.95,
    now()
  ),
  (
    'chat_context_global_aya_village',
    'gensokyo_main',
    'global',
    'aya',
    'human_village',
    'story_spring_festival_001',
    'character_location_story',
    'Aya is positioned to talk about how rumors and public framing are shaping the spring festival before it fully opens.',
    jsonb_build_object(
      'memory_ids', array['story_spring_festival_001:memory:aya:rumor'],
      'claim_ids', array['claim_aya_public_narrative'],
      'event_ids', array['story_spring_festival_001']
    ),
    0.88,
    now()
  ),
  (
    'chat_context_global_world_balance',
    'gensokyo_main',
    'global',
    null,
    '',
    null,
    'world_rule_summary',
    'Gensokyo persists through a managed balance of conflict, order, rumor, and recurring public roles.',
    jsonb_build_object(
      'lore_ids', array['lore_gensokyo_balance','lore_spell_card_rules'],
      'claim_ids', array['claim_spell_card_constraint']
    ),
    1.00,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

-- Seed examples for user-scoped chat/history tables are intentionally omitted
-- because they depend on real authenticated user ids.
-- The tables below are ready for runtime population:
-- - world_user_chat_summaries
-- - world_user_seen_entries

-- END FILE: WORLD_SEED_CHRONICLE.sql

-- BEGIN FILE: WORLD_SEED_BOOK_EPISODES.sql
-- World seed: print-work episode claims and chronicle fragments

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_book_forbidden_scrollery','printwork_pattern','Forbidden Scrollery Pattern','Forbidden Scrollery should be treated as village book-culture life repeatedly intersecting with dangerous texts and small incidents.',jsonb_build_object('source','fs'),'["printwork","fs","books"]'::jsonb,81),
  ('gensokyo_main','lore_book_wild_and_horned_hermit','printwork_pattern','Wild and Horned Hermit Pattern','Wild and Horned Hermit scenes combine shrine-side daily life, correction, and hidden depth behind apparently ordinary episodes.',jsonb_build_object('source','wahh'),'["printwork","wahh","daily_life"]'::jsonb,80),
  ('gensokyo_main','lore_book_lotus_asia','printwork_pattern','Curiosities of Lotus Asia Pattern','Curiosities of Lotus Asia works through objects, detached interpretation, and the slow exposure of hidden meanings in everyday goods.',jsonb_build_object('source','lotus_asia'),'["printwork","cola","objects"]'::jsonb,79),
  ('gensokyo_main','lore_book_bunbunmaru_reporting','printwork_pattern','Tengu Reporting Pattern','Aya-centered reporting works by converting local disturbance into mediated public narrative.',jsonb_build_object('source','boafw'),'["printwork","reporting","aya"]'::jsonb,78)
on conflict (world_id, id) do update
set category = excluded.category,
    title = excluded.title,
    summary = excluded.summary,
    details = excluded.details,
    tags = excluded.tags,
    priority = excluded.priority,
    updated_at = now();

insert into public.world_canon_claims (
  id, world_id, subject_type, subject_id, claim_type, summary, details, source_id, confidence, priority, tags
)
values
  ('claim_book_forbidden_scrollery','gensokyo_main','printwork','forbidden_scrollery','summary','Forbidden Scrollery is a village-side book and incident pattern centered on dangerous texts entering ordinary circulation.',jsonb_build_object('linked_characters',array['kosuzu','akyuu','reimu']),'src_fs','official',82,'["printwork","fs","summary"]'::jsonb),
  ('claim_book_wild_and_horned_hermit','gensokyo_main','printwork','wild_and_horned_hermit','summary','Wild and Horned Hermit emphasizes shrine daily life, advice, discipline, and slowly exposed hidden depth.',jsonb_build_object('linked_characters',array['kasen','reimu','marisa']),'src_wahh','official',81,'["printwork","wahh","summary"]'::jsonb),
  ('claim_book_lotus_asia','gensokyo_main','printwork','lotus_asia','summary','Curiosities of Lotus Asia is centered on objects, interpretation, and the mundane surface of strange things.',jsonb_build_object('linked_characters',array['rinnosuke','marisa','reimu']),'src_lotus_asia','official',80,'["printwork","cola","summary"]'::jsonb),
  ('claim_book_bunbunmaru_reporting','gensokyo_main','printwork','bunbunmaru_reporting','summary','Aya-centered reporting turns local events into broader public narrative and selective visibility.',jsonb_build_object('linked_characters',array['aya','hatate']),'src_boaFW','official',79,'["printwork","reporting","summary"]'::jsonb)
on conflict (id) do update
set subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    claim_type = excluded.claim_type,
    summary = excluded.summary,
    details = excluded.details,
    source_id = excluded.source_id,
    confidence = excluded.confidence,
    priority = excluded.priority,
    tags = excluded.tags,
    updated_at = now();

insert into public.world_chronicle_entries (
  id, book_id, chapter_id, entry_code, entry_order, entry_type, title, summary, body,
  subject_type, subject_id, narrator_character_id, event_id, history_id, tags, metadata
)
values
  (
    'chronicle_entry_printwork_books',
    'chronicle_gensokyo_history',
    'chronicle_gensokyo_history:chapter:foundations',
    'printwork_patterns',
    2,
    'essay',
    'Books, Reports, and How Daily Life Enters History',
    'A note on how printed works preserve daily life, minor incidents, and public interpretation.',
    'Not all history in Gensokyo is written through formal crisis. Some of it survives through booksellers, curio merchants, tengu articles, and the repeated circulation of small episodes that reveal how the world functions when it is not exploding. These records are indispensable precisely because they preserve ordinary pressure, not only extraordinary disaster.',
    'world',
    'gensokyo_main',
    'keine',
    null,
    null,
    '["printwork","history","daily_life"]'::jsonb,
    '{}'::jsonb
  )
on conflict (id) do update
set title = excluded.title,
    summary = excluded.summary,
    body = excluded.body,
    subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    narrator_character_id = excluded.narrator_character_id,
    event_id = excluded.event_id,
    history_id = excluded.history_id,
    tags = excluded.tags,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_chronicle_entry_sources (
  id, entry_id, source_kind, source_ref_id, source_label, weight, notes
)
values
  ('chronicle_entry_printwork_books:src:fs','chronicle_entry_printwork_books','canon_claim','claim_book_forbidden_scrollery','Forbidden Scrollery Pattern',0.9,'Village-side book culture'),
  ('chronicle_entry_printwork_books:src:wahh','chronicle_entry_printwork_books','canon_claim','claim_book_wild_and_horned_hermit','Wild and Horned Hermit Pattern',0.9,'Shrine daily life and advice'),
  ('chronicle_entry_printwork_books:src:cola','chronicle_entry_printwork_books','canon_claim','claim_book_lotus_asia','Curiosities of Lotus Asia Pattern',0.85,'Objects and interpretation'),
  ('chronicle_entry_printwork_books:src:boafw','chronicle_entry_printwork_books','canon_claim','claim_book_bunbunmaru_reporting','Bunbunmaru Reporting Pattern',0.82,'Public narrative through reportage')
on conflict (id) do update
set source_kind = excluded.source_kind,
    source_ref_id = excluded.source_ref_id,
    source_label = excluded.source_label,
    weight = excluded.weight,
    notes = excluded.notes;

-- END FILE: WORLD_SEED_BOOK_EPISODES.sql

-- BEGIN FILE: WORLD_SEED_FACTION_SOCIAL_LAYERS.sql
-- World seed: social layers, faction frames, and organizational glue

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_faction_hakurei','faction_trait','Hakurei Sphere','The Hakurei sphere is best treated as a public balancing layer rather than a large staffed bureaucracy.',jsonb_build_object('faction_id','hakurei'),'["faction","hakurei","public_balance"]'::jsonb,84),
  ('gensokyo_main','lore_faction_moriya','faction_trait','Moriya Sphere','The Moriya sphere represents organized ambition, gathered faith, and strategic mountain-side reach.',jsonb_build_object('faction_id','moriya'),'["faction","moriya","ambition"]'::jsonb,82),
  ('gensokyo_main','lore_faction_sdm','faction_trait','Scarlet Devil Mansion Sphere','The SDM sphere is structured by household hierarchy, symbolic prestige, and threshold management.',jsonb_build_object('faction_id','sdm'),'["faction","sdm","household"]'::jsonb,83),
  ('gensokyo_main','lore_faction_eientei','faction_trait','Eientei Sphere','The Eientei sphere is structured by seclusion, expertise, moon-linked history, and selective local permeability.',jsonb_build_object('faction_id','eientei'),'["faction","eientei","expertise"]'::jsonb,83),
  ('gensokyo_main','lore_faction_tengu','faction_trait','Tengu Sphere','The tengu sphere joins mountain authority, surveillance, fast mobility, and information shaping.',jsonb_build_object('faction_id','tengu'),'["faction","tengu","media"]'::jsonb,79),
  ('gensokyo_main','lore_faction_kappa','faction_trait','Kappa Sphere','The kappa sphere is built from engineering, trade, terrain knowledge, and practical mechanism exchange.',jsonb_build_object('faction_id','kappa'),'["faction","kappa","engineering"]'::jsonb,79),
  ('gensokyo_main','lore_faction_myouren','faction_trait','Myouren Sphere','The Myouren sphere is a community and coexistence structure broad enough to contain many tones and residents.',jsonb_build_object('faction_id','myouren'),'["faction","myouren","community"]'::jsonb,80),
  ('gensokyo_main','lore_faction_yakumo','faction_trait','Yakumo Sphere','The Yakumo sphere is not a public institution but a structural intervention layer tied to boundaries and shikigami administration.',jsonb_build_object('faction_id','yakumo'),'["faction","yakumo","structural"]'::jsonb,78),
  ('gensokyo_main','lore_social_rumor_network','social_function','Rumor Network','Rumor in Gensokyo should be treated as a real social function carried by the village, tengu, and recurring public actors.',jsonb_build_object('focus',array['human_village','aya','hatate']),'["social","rumor","network"]'::jsonb,86),
  ('gensokyo_main','lore_social_festivals','social_function','Festival Function','Festivals in Gensokyo are social stress-tests of cooperation, labor, hierarchy, and public mood rather than decorative downtime.',jsonb_build_object('focus','festival'),'["social","festival","public_life"]'::jsonb,85),
  ('gensokyo_main','lore_social_teaching','social_function','Teaching and Transmission','Teaching in Gensokyo should be treated as an active continuity mechanism through schools, books, records, and oral correction.',jsonb_build_object('focus',array['keine','akyuu','kosuzu']),'["social","teaching","continuity"]'::jsonb,83),
  ('gensokyo_main','lore_social_trade','social_function','Trade and Exchange','Trade in Gensokyo includes stalls, curio circulation, mountain brokerage, and market-scale divine or semi-divine influence.',jsonb_build_object('focus',array['rinnosuke','takane','chimata','mike']),'["social","trade","exchange"]'::jsonb,82)
on conflict (world_id, id) do update
set category = excluded.category,
    title = excluded.title,
    summary = excluded.summary,
    details = excluded.details,
    tags = excluded.tags,
    priority = excluded.priority,
    updated_at = now();

insert into public.world_canon_claims (
  id, world_id, subject_type, subject_id, claim_type, summary, details, source_id, confidence, priority, tags
)
values
  ('claim_faction_hakurei','gensokyo_main','faction','hakurei','glossary','The Hakurei sphere is a balancing layer centered on sacred legitimacy and public incident response.',jsonb_build_object('linked_characters',array['reimu','aunn','kasen']),'src_sopm','official',84,'["faction","hakurei"]'::jsonb),
  ('claim_faction_moriya','gensokyo_main','faction','moriya','glossary','The Moriya sphere is organized, ambitious, and oriented toward active faith gathering.',jsonb_build_object('linked_characters',array['sanae','kanako','suwako']),'src_mofa','official',83,'["faction","moriya"]'::jsonb),
  ('claim_faction_sdm','gensokyo_main','faction','sdm','glossary','The Scarlet Devil Mansion sphere is a hierarchized household with symbolic prestige and strong threshold control.',jsonb_build_object('linked_characters',array['remilia','sakuya','meiling','patchouli']),'src_eosd','official',84,'["faction","sdm"]'::jsonb),
  ('claim_faction_eientei','gensokyo_main','faction','eientei','glossary','The Eientei sphere is secluded, expert, and moon-touched, with controlled points of entry into wider life.',jsonb_build_object('linked_characters',array['eirin','kaguya','reisen','tewi']),'src_imperishable_night','official',84,'["faction","eientei"]'::jsonb),
  ('claim_faction_tengu','gensokyo_main','faction','tengu','glossary','The tengu sphere mixes authority, mobility, surveillance, and public mediation of information.',jsonb_build_object('linked_characters',array['aya','hatate','megumu','momiji']),'src_boaFW','official',80,'["faction","tengu"]'::jsonb),
  ('claim_faction_kappa','gensokyo_main','faction','kappa','glossary','The kappa sphere is defined by engineering culture, trade, and practical use of terrain and mechanisms.',jsonb_build_object('linked_characters',array['nitori','takane']),'src_mofa','official',80,'["faction","kappa"]'::jsonb),
  ('claim_social_rumor_network','gensokyo_main','social_function','rumor_network','glossary','Rumor in Gensokyo should be understood as a real transmission network rather than flavor text.',jsonb_build_object('linked_locations',array['human_village']),'src_boaFW','official',86,'["social","rumor"]'::jsonb),
  ('claim_social_festivals','gensokyo_main','social_function','festivals','glossary','Festivals are important public mechanisms for revealing cooperation, strain, and shared expectation.',jsonb_build_object('linked_event','story_spring_festival_001'),'src_sixty_years','official',83,'["social","festival"]'::jsonb),
  ('claim_social_teaching','gensokyo_main','social_function','teaching','glossary','Teaching, records, and books are continuity structures rather than background decoration.',jsonb_build_object('linked_characters',array['keine','akyuu','kosuzu']),'src_fs','official',82,'["social","teaching"]'::jsonb),
  ('claim_social_trade','gensokyo_main','social_function','trade','glossary','Trade in Gensokyo includes everyday stalls, curio circulation, and larger market-scale power.',jsonb_build_object('linked_characters',array['rinnosuke','takane','chimata','mike']),'src_um','official',81,'["social","trade"]'::jsonb)
on conflict (id) do update
set subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    claim_type = excluded.claim_type,
    summary = excluded.summary,
    details = excluded.details,
    source_id = excluded.source_id,
    confidence = excluded.confidence,
    priority = excluded.priority,
    tags = excluded.tags,
    updated_at = now();

-- END FILE: WORLD_SEED_FACTION_SOCIAL_LAYERS.sql

-- BEGIN FILE: WORLD_SEED_INCIDENTS_CANON.sql
-- World seed: canonical incident claims and chronicle coverage

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_incident_scarlet_mist','incident','Scarlet Mist Incident Pattern','A major early incident in which atmospheric abnormality and mansion-centered power became public crisis.',jsonb_build_object('incident_id','incident_scarlet_mist'),'["incident","eosd","mist"]'::jsonb,88),
  ('gensokyo_main','lore_incident_spring_snow','incident','Perfect Cherry Blossom Incident Pattern','An incident where season, death-boundary aesthetics, and Netherworld interests became entangled in public disturbance.',jsonb_build_object('incident_id','incident_spring_snow'),'["incident","pcb","spring"]'::jsonb,86),
  ('gensokyo_main','lore_incident_eternal_night','incident','Imperishable Night Incident Pattern','An incident characterized by false night, lunar linkage, and secrecy around delayed dawn.',jsonb_build_object('incident_id','incident_eternal_night'),'["incident","in","night"]'::jsonb,89),
  ('gensokyo_main','lore_incident_flower_anomaly','incident','Flower Incident Pattern','A wide floral abnormality that pulled together judgment, crossing, and seasonal overflow rather than a single villain''s scheme.',jsonb_build_object('incident_id','incident_flower_anomaly'),'["incident","pofv","flowers"]'::jsonb,78),
  ('gensokyo_main','lore_incident_weather_anomaly','incident','Weather Incident Pattern','A weather-scale abnormality tied to heavenly disruption and broad atmospheric instability.',jsonb_build_object('incident_id','incident_weather_anomaly'),'["incident","swr","weather"]'::jsonb,81),
  ('gensokyo_main','lore_incident_moriya_faith','incident','Faith and Mountain Shift Pattern','An incident pattern in which faith competition and mountain-side institutional pressure reshape public order.',jsonb_build_object('incident_id','incident_faith_shift'),'["incident","mof","faith"]'::jsonb,84),
  ('gensokyo_main','lore_incident_subterranean_sun','incident','Subterranean Sun Incident Pattern','An incident where underground power, hell-side structure, and excessive energy threatened surface balance.',jsonb_build_object('incident_id','incident_subterranean_sun'),'["incident","sa","underground"]'::jsonb,85),
  ('gensokyo_main','lore_incident_floating_treasures','incident','Flying Storehouse Incident Pattern','An incident where floating treasures, temple resurrection, and public uncertainty intersected.',jsonb_build_object('incident_id','incident_floating_treasures'),'["incident","ufo","temple"]'::jsonb,82),
  ('gensokyo_main','lore_incident_divine_spirits','incident','Divine Spirit Incident Pattern','An incident pattern centered on return, legitimacy, mausoleum politics, and spiritual authority.',jsonb_build_object('incident_id','incident_divine_spirits'),'["incident","td","mausoleum"]'::jsonb,82),
  ('gensokyo_main','lore_incident_little_rebellion','incident','Little People Rebellion Pattern','An incident driven by inversion, resentment, and unstable social overturning.',jsonb_build_object('incident_id','incident_little_rebellion'),'["incident","ddc","reversal"]'::jsonb,80),
  ('gensokyo_main','lore_incident_lunar_crisis','incident','Lunar Crisis Pattern','A crisis in which the moon, dream, and purification logic pressed hard against Gensokyo.',jsonb_build_object('incident_id','incident_lunar_crisis'),'["incident","lolk","moon"]'::jsonb,89),
  ('gensokyo_main','lore_incident_hidden_seasons','incident','Hidden Seasons Pattern','A seasonal distortion incident structured by hidden access and manipulated seasonal overflow.',jsonb_build_object('incident_id','incident_hidden_seasons'),'["incident","hsifs","seasons"]'::jsonb,81),
  ('gensokyo_main','lore_incident_beast_realm','incident','Beast Realm Incursion Pattern','An incident where beast-realm faction logic and underworld coercion reached into Gensokyo affairs.',jsonb_build_object('incident_id','incident_beast_realm'),'["incident","wbawc","beast_realm"]'::jsonb,84),
  ('gensokyo_main','lore_incident_market_cards','incident','Card Market Incident Pattern','An incident pattern driven by exchange, cards, mountain trade, and distributed market power.',jsonb_build_object('incident_id','incident_market_cards'),'["incident","um","market"]'::jsonb,80),
  ('gensokyo_main','lore_incident_living_ghost_conflict','incident','All Living Ghost Conflict Pattern','A recent conflict pattern in which underworld hierarchy, beast-realm power, and new actors overlapped at larger scale.',jsonb_build_object('incident_id','incident_living_ghost_conflict'),'["incident","19","underworld"]'::jsonb,83)
on conflict (world_id, id) do update
set category = excluded.category,
    title = excluded.title,
    summary = excluded.summary,
    details = excluded.details,
    tags = excluded.tags,
    priority = excluded.priority,
    updated_at = now();

insert into public.world_canon_claims (
  id, world_id, subject_type, subject_id, claim_type, summary, details, source_id, confidence, priority, tags
)
values
  ('claim_incident_scarlet_mist','gensokyo_main','incident','incident_scarlet_mist','summary','The Scarlet Mist Incident is a mansion-centered atmospheric crisis that helped define the public scale of incident response.',jsonb_build_object('principal_actors',array['reimu','marisa','sakuya','remilia']),'src_eosd','official',90,'["incident","eosd","mist"]'::jsonb),
  ('claim_incident_spring_snow','gensokyo_main','incident','incident_spring_snow','summary','The Perfect Cherry Blossom incident joins late spring, Netherworld intent, and boundary-sensitive seasonal disruption.',jsonb_build_object('principal_actors',array['reimu','marisa','youmu','yuyuko']),'src_pcb','official',88,'["incident","pcb","spring"]'::jsonb),
  ('claim_incident_eternal_night','gensokyo_main','incident','incident_eternal_night','summary','The Imperishable Night incident is marked by false night, delayed dawn, and deep lunar implication.',jsonb_build_object('principal_actors',array['reimu','marisa','eirin','kaguya','reisen','mokou']),'src_imperishable_night','official',91,'["incident","in","night"]'::jsonb),
  ('claim_incident_flower_anomaly','gensokyo_main','incident','incident_flower_anomaly','summary','The flower anomaly is a broad seasonal disturbance that pulls together many actors without reducing to one local culprit.',jsonb_build_object('principal_actors',array['komachi','eiki','yuuka','medicine']),'src_poFV','official',79,'["incident","pofv","flowers"]'::jsonb),
  ('claim_incident_weather_anomaly','gensokyo_main','incident','incident_weather_anomaly','summary','The weather anomaly centers heavenly interference and broad environmental instability rather than a merely local nuisance.',jsonb_build_object('principal_actors',array['tenshi','iku','reimu']),'src_swl','official',82,'["incident","swr","weather"]'::jsonb),
  ('claim_incident_faith_shift','gensokyo_main','incident','incident_faith_shift','summary','The mountain-faith shift places shrine competition and proactive Moriya expansion into public Gensokyo life.',jsonb_build_object('principal_actors',array['sanae','kanako','suwako','reimu']),'src_mofa','official',85,'["incident","mof","faith"]'::jsonb),
  ('claim_incident_subterranean_sun','gensokyo_main','incident','incident_subterranean_sun','summary','The subterranean sun crisis is an underground power problem with consequences too large to stay underground.',jsonb_build_object('principal_actors',array['satori','rin','utsuho','reimu','marisa']),'src_subterranean_animism','official',86,'["incident","sa","underground"]'::jsonb),
  ('claim_incident_floating_treasures','gensokyo_main','incident','incident_floating_treasures','summary','The UFO incident joins floating treasure rumors, ship imagery, and temple restoration into one public disturbance.',jsonb_build_object('principal_actors',array['nazrin','murasa','ichirin','byakuren','nue']),'src_ufo','official',84,'["incident","ufo","temple"]'::jsonb),
  ('claim_incident_divine_spirits','gensokyo_main','incident','incident_divine_spirits','summary','The divine spirit incident is structured around mausoleum politics, saintly return, and legitimacy in public life.',jsonb_build_object('principal_actors',array['miko','futo','tojiko','seiga']),'src_td','official',83,'["incident","td","mausoleum"]'::jsonb),
  ('claim_incident_little_rebellion','gensokyo_main','incident','incident_little_rebellion','summary','The little people rebellion is an inversion-driven incident of grievance, symbolic power, and unstable hierarchy.',jsonb_build_object('principal_actors',array['seija','shinmyoumaru','raiko']),'src_ddc','official',81,'["incident","ddc","reversal"]'::jsonb),
  ('claim_incident_lunar_crisis','gensokyo_main','incident','incident_lunar_crisis','summary','The lunar crisis binds moon politics, dream-space mediation, and purification pressure into a high-scale conflict.',jsonb_build_object('principal_actors',array['sagume','junko','hecatia','clownpiece','doremy']),'src_lolk','official',91,'["incident","lolk","moon"]'::jsonb),
  ('claim_incident_hidden_seasons','gensokyo_main','incident','incident_hidden_seasons','summary','The hidden seasons incident uses manipulated seasonal overflow and concealed access to reshape public atmosphere.',jsonb_build_object('principal_actors',array['okina','satono','mai','aunn','eternity','nemuno']),'src_hsifs','official',82,'["incident","hsifs","seasons"]'::jsonb),
  ('claim_incident_beast_realm','gensokyo_main','incident','incident_beast_realm','summary','The beast realm incursion pulls Gensokyo into coercive underworld faction politics and constructed counter-force.',jsonb_build_object('principal_actors',array['yachie','saki','keiki','mayumi','eika','kutaka']),'src_wbawc','official',85,'["incident","wbawc","beast_realm"]'::jsonb),
  ('claim_incident_market_cards','gensokyo_main','incident','incident_market_cards','summary','The market-card incident turns exchange, cards, and circulation into the core grammar of public disruption.',jsonb_build_object('principal_actors',array['takane','sannyo','misumaru','chimata','tsukasa','megumu']),'src_um','official',81,'["incident","um","market"]'::jsonb),
  ('claim_incident_living_ghost_conflict','gensokyo_main','incident','incident_living_ghost_conflict','summary','The all-living-ghost conflict expands underworld and beast-realm power overlap through new actors and higher-order command.',jsonb_build_object('principal_actors',array['biten','enoko','chiyari','hisami','zanmu']),'src_uDoALG','official',83,'["incident","19","underworld"]'::jsonb)
on conflict (id) do update
set subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    claim_type = excluded.claim_type,
    summary = excluded.summary,
    details = excluded.details,
    source_id = excluded.source_id,
    confidence = excluded.confidence,
    priority = excluded.priority,
    tags = excluded.tags,
    updated_at = now();

insert into public.world_chronicle_chapters (
  id, book_id, chapter_code, chapter_order, title, summary, period_start, period_end, metadata
)
values
  ('chronicle_gensokyo_history:chapter:major_incidents','chronicle_gensokyo_history','major_incidents',3,'Major Recorded Incidents','A historian''s compact record of the major incident patterns that shaped public memory in Gensokyo.',null,null,'{}'::jsonb)
on conflict (id) do update
set title = excluded.title,
    summary = excluded.summary,
    period_start = excluded.period_start,
    period_end = excluded.period_end,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_chronicle_entries (
  id, book_id, chapter_id, entry_code, entry_order, entry_type, title, summary, body,
  subject_type, subject_id, narrator_character_id, event_id, history_id, tags, metadata
)
values
  (
    'chronicle_entry_major_incidents',
    'chronicle_gensokyo_history',
    'chronicle_gensokyo_history:chapter:major_incidents',
    'major_incidents_overview',
    1,
    'catalog',
    'Major Incidents in Public Memory',
    'A compact account of the disturbance patterns that recur in Gensokyo''s remembered history.',
    'Gensokyo''s major incidents are not identical, yet they often fall into recognizable forms: atmospheric abnormality, seasonal distortion, shrine or temple-centered public strain, underworld excess, market circulation gone unstable, and boundary-linked crisis. Public memory does not preserve every detail equally, but it does preserve which forms of trouble recur and which actors repeatedly make those forms legible.',
    'world',
    'gensokyo_main',
    'keine',
    null,
    null,
    '["history","incidents","catalog"]'::jsonb,
    '{}'::jsonb
  )
on conflict (id) do update
set title = excluded.title,
    summary = excluded.summary,
    body = excluded.body,
    subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    narrator_character_id = excluded.narrator_character_id,
    event_id = excluded.event_id,
    history_id = excluded.history_id,
    tags = excluded.tags,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_chronicle_entry_sources (
  id, entry_id, source_kind, source_ref_id, source_label, weight, notes
)
values
  ('chronicle_entry_major_incidents:src:eosd','chronicle_entry_major_incidents','canon_claim','claim_incident_scarlet_mist','Scarlet Mist Incident',0.95,'Foundational early incident'),
  ('chronicle_entry_major_incidents:src:in','chronicle_entry_major_incidents','canon_claim','claim_incident_eternal_night','Imperishable Night Incident',0.95,'Major lunar-linked incident'),
  ('chronicle_entry_major_incidents:src:lolk','chronicle_entry_major_incidents','canon_claim','claim_incident_lunar_crisis','Lunar Crisis Incident',0.95,'High-scale moon crisis'),
  ('chronicle_entry_major_incidents:src:um','chronicle_entry_major_incidents','canon_claim','claim_incident_market_cards','Card Market Incident',0.85,'Later market-structured incident')
on conflict (id) do update
set source_kind = excluded.source_kind,
    source_ref_id = excluded.source_ref_id,
    source_label = excluded.source_label,
    weight = excluded.weight,
    notes = excluded.notes;

insert into public.world_historian_notes (
  id, world_id, historian_character_id, subject_type, subject_id, note_kind, title, summary, body, source_ref_ids, metadata
)
values
  (
    'historian_note_keine_major_incidents',
    'gensokyo_main',
    'keine',
    'world',
    'gensokyo_main',
    'editorial',
    'On Why Incidents Must Be Grouped',
    'A note on why incidents should be recorded as recurring forms rather than isolated spectacles.',
    'If each incident is recorded only as novelty, the structure of Gensokyo is obscured. The important question is not merely what happened once, but what kinds of disruption recur, what institutions absorb them, and which actors make them visible to the public.',
    '["claim_incident_scarlet_mist","claim_incident_eternal_night","claim_incident_market_cards"]'::jsonb,
    '{}'::jsonb
  )
on conflict (id) do update
set title = excluded.title,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();

-- END FILE: WORLD_SEED_INCIDENTS_CANON.sql

-- BEGIN FILE: WORLD_SEED_WIKI_PERSONA.sql
-- World seed: wiki pages for additional persona-covered cast

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  (
    'wiki_character_meiling',
    'gensokyo_main',
    'characters/hong-meiling',
    'Hong Meiling',
    'character',
    'character',
    'meiling',
    'Gatekeeper of the Scarlet Devil Mansion and a strong fit for threshold and interruption scenes.',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_satori',
    'gensokyo_main',
    'characters/satori-komeiji',
    'Satori Komeiji',
    'character',
    'character',
    'satori',
    'Master of Chireiden, associated with direct insight, psychological tension, and underground authority.',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_rin',
    'gensokyo_main',
    'characters/orin',
    'Orin',
    'character',
    'character',
    'rin',
    'An underground mover and errand-runner whose social role is tied to circulation and informal information flow.',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_location_chireiden',
    'gensokyo_main',
    'locations/chireiden',
    'Chireiden',
    'location',
    'location',
    'chireiden',
    'An underground palace where insight, discomfort, and household authority sit unusually close together.',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  )
on conflict (id) do update
set slug = excluded.slug,
    title = excluded.title,
    page_type = excluded.page_type,
    subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    summary = excluded.summary,
    status = excluded.status,
    canonical_book_id = excluded.canonical_book_id,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_wiki_page_sections (
  id, page_id, section_code, section_order, heading, summary, body, source_ref_ids, metadata
)
values
  (
    'wiki_character_meiling:section:overview',
    'wiki_character_meiling',
    'overview',
    1,
    'Overview',
    'Meiling as threshold guard and household edge.',
    'Hong Meiling functions most naturally at the visible edge of the Scarlet Devil Mansion, where entry, interruption, and household presentation all meet in one place.',
    '["claim_meiling_gatekeeper","lore_meiling_gatekeeping"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_satori:section:overview',
    'wiki_character_satori',
    'overview',
    1,
    'Overview',
    'Satori as an actor of uncomfortable clarity.',
    'Satori Komeiji should not be treated as a shallow background presence. Her role naturally pulls scenes toward motive, thought, and psychological pressure.',
    '["claim_satori_chireiden","lore_satori_insight"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_rin:section:overview',
    'wiki_character_rin',
    'overview',
    1,
    'Overview',
    'Rin as movement and social circulation.',
    'Orin is especially suited to stories that depend on transport, rumor flow, and the lived social rhythm of the underground.',
    '["claim_rin_underground_flow","lore_rin_social_flow"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_location_chireiden:section:profile',
    'wiki_location_chireiden',
    'profile',
    1,
    'Profile',
    'Chireiden as underground palace and psychological setting.',
    'Chireiden is not simply another underground building. Its atmosphere and ruler push scenes toward directness, discomfort, and deeper interior reading than many other locations support.',
    '["claim_chireiden_setting","lore_chireiden_profile"]'::jsonb,
    '{}'::jsonb
  )
on conflict (id) do update
set heading = excluded.heading,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();

-- END FILE: WORLD_SEED_WIKI_PERSONA.sql

-- BEGIN FILE: WORLD_SEED_CHAT_PERSONA.sql
-- World seed: chat context for additional persona-covered cast

insert into public.world_chat_context_cache (
  id, world_id, user_scope, character_id, location_id, event_id, context_type, summary, payload, freshness_score, last_used_at
)
values
  (
    'chat_context_global_meiling_gate',
    'gensokyo_main',
    'global',
    'meiling',
    'scarlet_gate',
    null,
    'character_location_story',
    'Meiling is easiest to read through threshold scenes: guarding, intercepting, allowing entry, or framing who gets through.',
    jsonb_build_object(
      'claim_ids', array['claim_meiling_gatekeeper'],
      'lore_ids', array['lore_meiling_gatekeeping'],
      'location_ids', array['scarlet_gate','scarlet_devil_mansion']
    ),
    0.84,
    now()
  ),
  (
    'chat_context_global_satori_chireiden',
    'gensokyo_main',
    'global',
    'satori',
    'chireiden',
    null,
    'character_location_story',
    'Satori at Chireiden should pull a conversation toward motive, awareness, and the discomfort of being clearly perceived.',
    jsonb_build_object(
      'claim_ids', array['claim_satori_chireiden'],
      'lore_ids', array['lore_satori_insight','lore_chireiden_profile'],
      'location_ids', array['chireiden']
    ),
    0.91,
    now()
  ),
  (
    'chat_context_global_rin_underground',
    'gensokyo_main',
    'global',
    'rin',
    'old_capital',
    null,
    'character_location_story',
    'Rin fits conversations about underground movement, errands, social traffic, and informal information channels.',
    jsonb_build_object(
      'claim_ids', array['claim_rin_underground_flow'],
      'lore_ids', array['lore_rin_social_flow'],
      'location_ids', array['old_capital','former_hell']
    ),
    0.82,
    now()
  ),
  (
    'chat_context_global_momiji_mountain',
    'gensokyo_main',
    'global',
    'momiji',
    'genbu_ravine',
    null,
    'character_location_story',
    'Momiji is best framed through patrol logic, guarded routes, and mountain-side practical response.',
    jsonb_build_object(
      'claim_ids', array['claim_momiji_mountain_guard'],
      'lore_ids', array['lore_momiji_patrols'],
      'location_ids', array['genbu_ravine','youkai_mountain_foot']
    ),
    0.79,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

-- END FILE: WORLD_SEED_CHAT_PERSONA.sql

-- BEGIN FILE: WORLD_SEED_WIKI_EARLY_WINDOWS.sql
-- World seed: wiki pages for early Windows-era additions

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  (
    'wiki_character_cirno',
    'gensokyo_main',
    'characters/cirno',
    'Cirno',
    'character',
    'character',
    'cirno',
    'A local fairy force around Misty Lake, loud, confident, and best treated as immediate rather than administrative.',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_tewi',
    'gensokyo_main',
    'characters/tewi-inaba',
    'Tewi Inaba',
    'character',
    'character',
    'tewi',
    'A rabbit associated with luck, misdirection, and the side-routes of Eientei and the Bamboo Forest.',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_group_prismriver',
    'gensokyo_main',
    'groups/prismriver-ensemble',
    'Prismriver Ensemble',
    'group',
    'group',
    'prismriver',
    'A musical ensemble whose members are most legible as a coordinated group presence.',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  )
on conflict (id) do update
set slug = excluded.slug,
    title = excluded.title,
    page_type = excluded.page_type,
    subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    summary = excluded.summary,
    status = excluded.status,
    canonical_book_id = excluded.canonical_book_id,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_wiki_page_sections (
  id, page_id, section_code, section_order, heading, summary, body, source_ref_ids, metadata
)
values
  (
    'wiki_character_cirno:section:overview',
    'wiki_character_cirno',
    'overview',
    1,
    'Overview',
    'Cirno as local force rather than system-scale actor.',
    'Cirno is most useful to the world model as a local, immediate, highly visible fairy force. She changes atmosphere quickly, but she should not be mistaken for a stable organizer of large-scale public structure.',
    '["claim_cirno_fairy_local","lore_cirno_local_trouble"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_tewi:section:overview',
    'wiki_character_tewi',
    'overview',
    1,
    'Overview',
    'Tewi as luck and detour actor.',
    'Tewi belongs naturally in side routes, evasive guidance, and playful local disruption around Eientei and the Bamboo Forest, where a crooked path can still be the useful one.',
    '["claim_tewi_eientei_trickster","lore_tewi_detours"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_group_prismriver:section:overview',
    'wiki_group_prismriver',
    'overview',
    1,
    'Overview',
    'The ensemble logic of the Prismriver sisters.',
    'The Prismriver sisters should usually be framed as an ensemble first. Their individual tones matter, but their clearest public identity is coordinated performance and mood-shaping presence.',
    '["claim_prismriver_ensemble","lore_prismriver_ensemble"]'::jsonb,
    '{}'::jsonb
  )
on conflict (id) do update
set heading = excluded.heading,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();

-- END FILE: WORLD_SEED_WIKI_EARLY_WINDOWS.sql

-- BEGIN FILE: WORLD_SEED_CHAT_EARLY_WINDOWS.sql
-- World seed: chat context for early Windows-era additions

insert into public.world_chat_context_cache (
  id, world_id, user_scope, character_id, location_id, event_id, context_type, summary, payload, freshness_score, last_used_at
)
values
  (
    'chat_context_global_cirno_lake',
    'gensokyo_main',
    'global',
    'cirno',
    'misty_lake',
    null,
    'character_location_story',
    'Cirno at Misty Lake should feel immediate, loud, local, and more concerned with visible strength than long planning.',
    jsonb_build_object(
      'claim_ids', array['claim_cirno_fairy_local'],
      'lore_ids', array['lore_cirno_local_trouble'],
      'location_ids', array['misty_lake']
    ),
    0.80,
    now()
  ),
  (
    'chat_context_global_tewi_bamboo',
    'gensokyo_main',
    'global',
    'tewi',
    'bamboo_forest',
    null,
    'character_location_story',
    'Tewi around the Bamboo Forest should support detours, luck, side routes, and answers that are useful without being direct.',
    jsonb_build_object(
      'claim_ids', array['claim_tewi_eientei_trickster'],
      'lore_ids', array['lore_tewi_detours'],
      'location_ids', array['bamboo_forest','eientei']
    ),
    0.82,
    now()
  ),
  (
    'chat_context_global_prismriver_music',
    'gensokyo_main',
    'global',
    'lunasa',
    'hakugyokurou',
    null,
    'group_story',
    'The Prismriver sisters are best treated as a coordinated musical group whose differences matter inside an ensemble frame.',
    jsonb_build_object(
      'claim_ids', array['claim_prismriver_ensemble'],
      'lore_ids', array['lore_prismriver_ensemble'],
      'character_ids', array['lunasa','merlin','lyrica']
    ),
    0.76,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

-- END FILE: WORLD_SEED_CHAT_EARLY_WINDOWS.sql

-- BEGIN FILE: WORLD_SEED_WIKI_LATE_MAINLINE.sql
-- World seed: wiki pages for late-mainline cast and locations

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  (
    'wiki_character_miko',
    'gensokyo_main',
    'characters/toyosatomimi-no-miko',
    'Toyosatomimi no Miko',
    'character',
    'character',
    'miko',
    'A saintly leader whose stories naturally involve rhetoric, legitimacy, and public authority.',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_seija',
    'gensokyo_main',
    'characters/seija-kijin',
    'Seija Kijin',
    'character',
    'character',
    'seija',
    'A contrarian rebel best understood through inversion, sabotage, and corrosive pressure against settled order.',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_junko',
    'gensokyo_main',
    'characters/junko',
    'Junko',
    'character',
    'character',
    'junko',
    'A high-impact actor of purified hostility whose use should be deliberate and consequential.',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_okina',
    'gensokyo_main',
    'characters/okina-matara',
    'Okina Matara',
    'character',
    'character',
    'okina',
    'A hidden god of access, backstage control, and selective empowerment.',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_yachie',
    'gensokyo_main',
    'characters/yachie-kicchou',
    'Yachie Kicchou',
    'character',
    'character',
    'yachie',
    'A calculating beast-realm leader whose strength lies in leverage and indirect control.',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_takane',
    'gensokyo_main',
    'characters/takane-yamashiro',
    'Takane Yamashiro',
    'character',
    'character',
    'takane',
    'A mountain broker whose scenes revolve around trade, opportunity, and practical exchange.',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_location_lunar_capital',
    'gensokyo_main',
    'locations/lunar-capital',
    'Lunar Capital',
    'location',
    'location',
    'lunar_capital',
    'A remote center of purity, order, and lunar political distance from ordinary Gensokyo life.',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_location_beast_realm',
    'gensokyo_main',
    'locations/beast-realm',
    'Beast Realm',
    'location',
    'location',
    'beast_realm',
    'A factional realm where strategic predation and power blocs are part of the landscape itself.',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  )
on conflict (id) do update
set slug = excluded.slug,
    title = excluded.title,
    page_type = excluded.page_type,
    subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    summary = excluded.summary,
    status = excluded.status,
    canonical_book_id = excluded.canonical_book_id,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_wiki_page_sections (
  id, page_id, section_code, section_order, heading, summary, body, source_ref_ids, metadata
)
values
  (
    'wiki_character_miko:section:overview',
    'wiki_character_miko',
    'overview',
    1,
    'Overview',
    'Miko as saintly authority and rhetorical center.',
    'Toyosatomimi no Miko should be framed less as a casual participant and more as a figure who can gather, redirect, and organize an audience through authority and presentation.',
    '["claim_miko_saint_leadership","lore_miko_public_authority"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_seija:section:overview',
    'wiki_character_seija',
    'overview',
    1,
    'Overview',
    'Seija as corrosive inversion pressure.',
    'Seija Kijin is not generic chaos. She works best when she actively reverses expectations, encourages grievance, and puts pressure on settled legitimacy.',
    '["claim_seija_rebel","lore_seija_contrarian_pressure"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_junko:section:overview',
    'wiki_character_junko',
    'overview',
    1,
    'Overview',
    'Junko as high-impact purity and hostility.',
    'Junko should appear where the story can sustain concentrated hostility and thematic purity. She is not ordinary background traffic.',
    '["claim_junko_pure_hostility","lore_junko_high_impact"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_okina:section:overview',
    'wiki_character_okina',
    'overview',
    1,
    'Overview',
    'Okina as hidden access and backstage control.',
    'Okina Matara belongs to stories about doors, backstage staging, and the quiet distribution of access or empowerment.',
    '["claim_okina_hidden_doors","lore_okina_hidden_access"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_yachie:section:overview',
    'wiki_character_yachie',
    'overview',
    1,
    'Overview',
    'Yachie as strategic faction leader.',
    'Yachie Kicchou is strongest in political or coercive contexts where a gentle surface hides structural leverage.',
    '["claim_yachie_faction_leader","lore_beast_realm_factions"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_takane:section:overview',
    'wiki_character_takane',
    'overview',
    1,
    'Overview',
    'Takane as mountain broker.',
    'Takane Yamashiro should be used where trade, brokerage, and practical market opportunity matter more than theatrical conflict.',
    '["claim_takane_broker","lore_takane_trade_frame"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_location_lunar_capital:section:profile',
    'wiki_location_lunar_capital',
    'profile',
    1,
    'Profile',
    'The Lunar Capital as ordered distance.',
    'The Lunar Capital should feel clean, remote, and culturally distinct from ordinary Gensokyo circulation. Its scenes carry high standards and political distance.',
    '["claim_lunar_capital_profile","lore_lunar_distance"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_location_beast_realm:section:profile',
    'wiki_location_beast_realm',
    'profile',
    1,
    'Profile',
    'The Beast Realm as factional pressure field.',
    'The Beast Realm is a power-structured realm of predatory factions, coercive alignment, and open strategic pressure rather than everyday social ease.',
    '["claim_beast_realm_profile","lore_beast_realm_factions"]'::jsonb,
    '{}'::jsonb
  )
on conflict (id) do update
set heading = excluded.heading,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();

-- END FILE: WORLD_SEED_WIKI_LATE_MAINLINE.sql

-- BEGIN FILE: WORLD_SEED_CHAT_LATE_MAINLINE.sql
-- World seed: chat context for late-mainline cast and locations

insert into public.world_chat_context_cache (
  id, world_id, user_scope, character_id, location_id, event_id, context_type, summary, payload, freshness_score, last_used_at
)
values
  (
    'chat_context_global_miko_mausoleum',
    'gensokyo_main',
    'global',
    'miko',
    'divine_spirit_mausoleum',
    null,
    'character_location_story',
    'Miko at the mausoleum should pull conversation toward authority, legitimacy, rhetoric, and old order made present again.',
    jsonb_build_object(
      'claim_ids', array['claim_miko_saint_leadership','claim_divine_spirit_mausoleum_profile'],
      'lore_ids', array['lore_miko_public_authority','lore_mausoleum_politics'],
      'location_ids', array['divine_spirit_mausoleum','senkai']
    ),
    0.91,
    now()
  ),
  (
    'chat_context_global_seija_castle',
    'gensokyo_main',
    'global',
    'seija',
    'shining_needle_castle',
    null,
    'character_location_story',
    'Seija around Shining Needle Castle should feel like inversion with intent: grievance, sabotage, and delighted disrespect for stable order.',
    jsonb_build_object(
      'claim_ids', array['claim_seija_rebel','claim_shining_needle_castle_profile'],
      'lore_ids', array['lore_ddc_reversal_logic','lore_seija_contrarian_pressure'],
      'location_ids', array['shining_needle_castle']
    ),
    0.88,
    now()
  ),
  (
    'chat_context_global_junko_lunar',
    'gensokyo_main',
    'global',
    'junko',
    'lunar_capital',
    null,
    'character_location_story',
    'Junko should enter chat context as concentrated hostility and purpose, not casual banter or soft daily drift.',
    jsonb_build_object(
      'claim_ids', array['claim_junko_pure_hostility','claim_lunar_capital_profile'],
      'lore_ids', array['lore_junko_high_impact','lore_lunar_distance'],
      'location_ids', array['lunar_capital']
    ),
    0.94,
    now()
  ),
  (
    'chat_context_global_okina_backdoor',
    'gensokyo_main',
    'global',
    'okina',
    'backdoor_realm',
    null,
    'character_location_story',
    'Okina belongs in conversations about hidden access, invitation, chosen empowerment, and off-stage orchestration.',
    jsonb_build_object(
      'claim_ids', array['claim_okina_hidden_doors','claim_backdoor_realm_profile'],
      'lore_ids', array['lore_okina_hidden_access'],
      'location_ids', array['backdoor_realm']
    ),
    0.89,
    now()
  ),
  (
    'chat_context_global_yachie_beast_realm',
    'gensokyo_main',
    'global',
    'yachie',
    'beast_realm',
    null,
    'character_location_story',
    'Yachie at the Beast Realm should read as leverage, measured threat, and political control under predatory conditions.',
    jsonb_build_object(
      'claim_ids', array['claim_yachie_faction_leader','claim_beast_realm_profile'],
      'lore_ids', array['lore_beast_realm_factions'],
      'location_ids', array['beast_realm']
    ),
    0.87,
    now()
  ),
  (
    'chat_context_global_takane_market',
    'gensokyo_main',
    'global',
    'takane',
    'rainbow_dragon_cave',
    null,
    'character_location_story',
    'Takane works best through negotiated exchange, mountain commerce, and practical opportunity rather than heroic confrontation.',
    jsonb_build_object(
      'claim_ids', array['claim_takane_broker','claim_rainbow_dragon_cave_profile'],
      'lore_ids', array['lore_takane_trade_frame','lore_um_market_flow'],
      'location_ids', array['rainbow_dragon_cave','youkai_mountain_foot']
    ),
    0.85,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

-- END FILE: WORLD_SEED_CHAT_LATE_MAINLINE.sql

-- BEGIN FILE: WORLD_SEED_WIKI_PRINTWORK.sql
-- World seed: wiki pages for print-work and documentary cast

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  ('wiki_character_akyuu','gensokyo_main','characters/hieda-no-akyuu','Hieda no Akyuu','character','character','akyuu','A chronicler of Gensokyo whose role centers on memory, records, and structured historical understanding.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_rinnosuke','gensokyo_main','characters/rinnosuke-morichika','Rinnosuke Morichika','character','character','rinnosuke','A curio merchant and object interpreter whose scenes naturally run through material culture and detached explanation.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_kasen','gensokyo_main','characters/kasen-ibaraki','Kasen Ibaraki','character','character','kasen','A hermit advisor suited to corrective guidance, shrine-side discipline, and partially concealed authority.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_sumireko','gensokyo_main','characters/sumireko-usami','Sumireko Usami','character','character','sumireko','An outside-world psychic whose role hinges on urban legends, boundaries, and rumor leakage into Gensokyo.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_location_kourindou','gensokyo_main','locations/kourindou','Kourindou','location','location','kourindou','A curio shop where objects and interpretation drive the center of the scene.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_location_suzunaan','gensokyo_main','locations/suzunaan','Suzunaan','location','location','suzunaan','A village bookshop-library where text circulation produces knowledge, risk, and cultural memory.','published','chronicle_gensokyo_history','{}'::jsonb)
on conflict (id) do update
set slug = excluded.slug,
    title = excluded.title,
    page_type = excluded.page_type,
    subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    summary = excluded.summary,
    status = excluded.status,
    canonical_book_id = excluded.canonical_book_id,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_wiki_page_sections (
  id, page_id, section_code, section_order, heading, summary, body, source_ref_ids, metadata
)
values
  ('wiki_character_akyuu:section:overview','wiki_character_akyuu','overview',1,'Overview','Akyuu as historian and record keeper.','Akyuu is best used where memory, records, and careful historical framing are part of the scene''s structure rather than optional decoration.','["claim_akyuu_historian","lore_village_records"]'::jsonb,'{}'::jsonb),
  ('wiki_character_rinnosuke:section:overview','wiki_character_rinnosuke','overview',1,'Overview','Rinnosuke as object interpreter.','Rinnosuke Morichika should be framed through objects, explanations, and off-angle material insight rather than routine public incident leadership.','["claim_rinnosuke_object_interpreter","lore_kourindou_objects"]'::jsonb,'{}'::jsonb),
  ('wiki_character_kasen:section:overview','wiki_character_kasen','overview',1,'Overview','Kasen as corrective advisor.','Kasen belongs naturally in scenes of guidance, pressure, and shrine-adjacent discipline that still carry concern beneath criticism.','["claim_kasen_advisor","lore_kasen_guidance"]'::jsonb,'{}'::jsonb),
  ('wiki_character_sumireko:section:overview','wiki_character_sumireko','overview',1,'Overview','Sumireko as urban-legend outsider.','Sumireko is a useful outside-world angle only when her rumors and powers feel like leakage into Gensokyo rather than total replacement of its own logic.','["claim_sumireko_urban_legend","lore_urban_legend_bleed"]'::jsonb,'{}'::jsonb),
  ('wiki_location_kourindou:section:profile','wiki_location_kourindou','profile',1,'Profile','Kourindou as object-reading scene engine.','Kourindou scenes should center on objects, interpretation, and the odd cultural angle created by goods that cross categories and worlds.','["claim_kourindou_profile","lore_kourindou_objects"]'::jsonb,'{}'::jsonb),
  ('wiki_location_suzunaan:section:profile','wiki_location_suzunaan','profile',1,'Profile','Suzunaan as book-circulation node.','Suzunaan is not just shelving. It is a social and narrative node where written material changes hands and can alter what people know or unleash.','["claim_suzunaan_profile","lore_suzunaan_books"]'::jsonb,'{}'::jsonb)
on conflict (id) do update
set heading = excluded.heading,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();

-- END FILE: WORLD_SEED_WIKI_PRINTWORK.sql

-- BEGIN FILE: WORLD_SEED_CHAT_PRINTWORK.sql
-- World seed: chat context for print-work and documentary cast

insert into public.world_chat_context_cache (
  id, world_id, user_scope, character_id, location_id, event_id, context_type, summary, payload, freshness_score, last_used_at
)
values
  (
    'chat_context_global_akyuu_village_records',
    'gensokyo_main',
    'global',
    'akyuu',
    'human_village',
    null,
    'character_location_story',
    'Akyuu should pull chat toward records, continuity, and careful framing of what Gensokyo believes about itself.',
    jsonb_build_object(
      'claim_ids', array['claim_akyuu_historian'],
      'lore_ids', array['lore_village_records'],
      'location_ids', array['human_village','suzunaan']
    ),
    0.90,
    now()
  ),
  (
    'chat_context_global_rinnosuke_kourindou',
    'gensokyo_main',
    'global',
    'rinnosuke',
    'kourindou',
    null,
    'character_location_story',
    'Rinnosuke is easiest to read through objects, odd merchandise, and detached interpretation of useful curios.',
    jsonb_build_object(
      'claim_ids', array['claim_rinnosuke_object_interpreter','claim_kourindou_profile'],
      'lore_ids', array['lore_kourindou_objects'],
      'location_ids', array['kourindou']
    ),
    0.84,
    now()
  ),
  (
    'chat_context_global_kasen_shrine',
    'gensokyo_main',
    'global',
    'kasen',
    'hakurei_shrine',
    null,
    'character_location_story',
    'Kasen around the shrine should sound like corrective care: advice, irritation, and practical concern bound together.',
    jsonb_build_object(
      'claim_ids', array['claim_kasen_advisor'],
      'lore_ids', array['lore_kasen_guidance'],
      'location_ids', array['hakurei_shrine']
    ),
    0.86,
    now()
  ),
  (
    'chat_context_global_sumireko_boundary',
    'gensokyo_main',
    'global',
    'sumireko',
    'muenzuka',
    null,
    'character_location_story',
    'Sumireko should bring urban-legend leakage and outside-world overconfidence into boundary-adjacent scenes.',
    jsonb_build_object(
      'claim_ids', array['claim_sumireko_urban_legend'],
      'lore_ids', array['lore_urban_legend_bleed'],
      'location_ids', array['muenzuka','human_village']
    ),
    0.82,
    now()
  ),
  (
    'chat_context_global_joon_shion_social_cost',
    'gensokyo_main',
    'global',
    'joon',
    'human_village',
    null,
    'character_location_story',
    'Joon and Shion scenes should foreground uneven glamour and misfortune as a paired social distortion, not separate random trouble.',
    jsonb_build_object(
      'claim_ids', array['claim_joon_social_drain','claim_shion_misfortune'],
      'lore_ids', array['lore_yorigami_pair'],
      'location_ids', array['human_village']
    ),
    0.80,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

-- END FILE: WORLD_SEED_CHAT_PRINTWORK.sql

-- BEGIN FILE: WORLD_SEED_WIKI_FLOWER_CELESTIAL.sql
-- World seed: wiki pages for flower, celestial, dream, and seasonal cast

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  ('wiki_character_eiki','gensokyo_main','characters/shikieiki-yamaxanadu','Shikieiki Yamaxanadu','character','character','eiki','A judge of moral weight and formal correction rather than casual social flow.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_tenshi','gensokyo_main','characters/tenshi-hinanawi','Tenshi Hinanawi','character','character','tenshi','A celestial instigator whose pride and boredom can scale into weather-sized trouble.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_kokoro','gensokyo_main','characters/hata-no-kokoro','Hata no Kokoro','character','character','kokoro','A mask-bearing performer suited to stories where emotion and public affect are active mechanics.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_doremy','gensokyo_main','characters/doremy-sweet','Doremy Sweet','character','character','doremy','A dream shepherd who gives dream-space scenes a real guide and caretaker.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_aunn','gensokyo_main','characters/aunn-komano','Aunn Komano','character','character','aunn','A shrine guardian who adds local warmth and watchfulness to sacred space.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_location_heaven','gensokyo_main','locations/heaven','Heaven','location','location','heaven','A celestial sphere of comfort, detachment, and large-scale unintended consequence.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_location_dream_world','gensokyo_main','locations/dream-world','Dream World','location','location','dream_world','A symbolic dream-space that still benefits from mediation and structure.','published','chronicle_gensokyo_history','{}'::jsonb)
on conflict (id) do update
set slug = excluded.slug,
    title = excluded.title,
    page_type = excluded.page_type,
    subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    summary = excluded.summary,
    status = excluded.status,
    canonical_book_id = excluded.canonical_book_id,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_wiki_page_sections (
  id, page_id, section_code, section_order, heading, summary, body, source_ref_ids, metadata
)
values
  ('wiki_character_eiki:section:overview','wiki_character_eiki','overview',1,'Overview','Eiki as judge and corrective force.','Shikieiki Yamaxanadu belongs in scenes where formal moral evaluation matters more than ordinary social tact or convenience.','["claim_eiki_judge","lore_muenzuka_judgment"]'::jsonb,'{}'::jsonb),
  ('wiki_character_tenshi:section:overview','wiki_character_tenshi','overview',1,'Overview','Tenshi as celestial-scale instigator.','Tenshi is best framed through arrogance, boredom, and enough distance from ground-level consequence to cause real trouble.','["claim_tenshi_celestial_instigator","lore_heaven_detachment"]'::jsonb,'{}'::jsonb),
  ('wiki_character_kokoro:section:overview','wiki_character_kokoro','overview',1,'Overview','Kokoro as emotion-bearing performer.','Kokoro should be used when masks, public feeling, and the instability of emotion display matter to the structure of the scene itself.','["claim_kokoro_mask_performer","lore_kokoro_public_affect"]'::jsonb,'{}'::jsonb),
  ('wiki_character_doremy:section:overview','wiki_character_doremy','overview',1,'Overview','Doremy as dream mediator.','Doremy Sweet is useful because dream-space can be navigated and tended, not just because dreams are strange.','["claim_doremy_dream_guide","lore_dream_world_mediator"]'::jsonb,'{}'::jsonb),
  ('wiki_character_aunn:section:overview','wiki_character_aunn','overview',1,'Overview','Aunn as shrine-ground guardian.','Aunn makes shrine-space feel inhabited, appreciated, and practically watched over in an everyday way.','["claim_aunn_guardian","lore_aunn_shrine_everyday"]'::jsonb,'{}'::jsonb),
  ('wiki_location_heaven:section:profile','wiki_location_heaven','profile',1,'Profile','Heaven as detached celestial sphere.','Heaven should feel luxurious and removed enough that celestial disturbance can emerge from misjudged comfort and scale.','["claim_heaven_profile","lore_heaven_detachment"]'::jsonb,'{}'::jsonb),
  ('wiki_location_dream_world:section:profile','wiki_location_dream_world','profile',1,'Profile','Dream World as symbolic mediated realm.','Dream World supports symbolic encounters and unstable logic, but scenes there become stronger when someone can actually navigate and frame them.','["claim_dream_world_profile","lore_dream_world_mediator"]'::jsonb,'{}'::jsonb)
on conflict (id) do update
set heading = excluded.heading,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();

-- END FILE: WORLD_SEED_WIKI_FLOWER_CELESTIAL.sql

-- BEGIN FILE: WORLD_SEED_CHAT_FLOWER_CELESTIAL.sql
-- World seed: chat context for flower, celestial, dream, and seasonal cast

insert into public.world_chat_context_cache (
  id, world_id, user_scope, character_id, location_id, event_id, context_type, summary, payload, freshness_score, last_used_at
)
values
  (
    'chat_context_global_eiki_muenzuka',
    'gensokyo_main',
    'global',
    'eiki',
    'muenzuka',
    null,
    'character_location_story',
    'Eiki should pull chat toward judgment, consequence, and moral correction rather than casual gossip.',
    jsonb_build_object(
      'claim_ids', array['claim_eiki_judge'],
      'lore_ids', array['lore_muenzuka_judgment'],
      'location_ids', array['muenzuka']
    ),
    0.89,
    now()
  ),
  (
    'chat_context_global_tenshi_heaven',
    'gensokyo_main',
    'global',
    'tenshi',
    'heaven',
    null,
    'character_location_story',
    'Tenshi belongs in chat as celestial arrogance mixed with weather-scale boredom and the possibility of oversized trouble.',
    jsonb_build_object(
      'claim_ids', array['claim_tenshi_celestial_instigator','claim_heaven_profile'],
      'lore_ids', array['lore_heaven_detachment'],
      'location_ids', array['heaven','bhavaagra']
    ),
    0.86,
    now()
  ),
  (
    'chat_context_global_kokoro_public_affect',
    'gensokyo_main',
    'global',
    'kokoro',
    'human_village',
    null,
    'character_location_story',
    'Kokoro works best when a conversation is about emotions being shown, performed, or misread in public.',
    jsonb_build_object(
      'claim_ids', array['claim_kokoro_mask_performer'],
      'lore_ids', array['lore_kokoro_public_affect'],
      'location_ids', array['human_village']
    ),
    0.83,
    now()
  ),
  (
    'chat_context_global_doremy_dream_world',
    'gensokyo_main',
    'global',
    'doremy',
    'dream_world',
    null,
    'character_location_story',
    'Doremy should sound like someone who actually knows the routes and patterns of dream-space instead of treating it as shapeless weirdness.',
    jsonb_build_object(
      'claim_ids', array['claim_doremy_dream_guide','claim_dream_world_profile'],
      'lore_ids', array['lore_dream_world_mediator'],
      'location_ids', array['dream_world']
    ),
    0.88,
    now()
  ),
  (
    'chat_context_global_aunn_shrine',
    'gensokyo_main',
    'global',
    'aunn',
    'hakurei_shrine',
    null,
    'character_location_story',
    'Aunn is strong in shrine-ground conversations that need warmth, local attachment, and practical guardianship.',
    jsonb_build_object(
      'claim_ids', array['claim_aunn_guardian'],
      'lore_ids', array['lore_aunn_shrine_everyday'],
      'location_ids', array['hakurei_shrine']
    ),
    0.82,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

-- END FILE: WORLD_SEED_CHAT_FLOWER_CELESTIAL.sql

-- BEGIN FILE: WORLD_SEED_WIKI_RECENT_REALMS.sql
-- World seed: wiki pages for recent-realm cast

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  ('wiki_character_yuuma','gensokyo_main','characters/yuuma-toutetsu','Yuuma Toutetsu','character','character','yuuma','An underworld greed-power best used where appetite behaves like structure and threat.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_zanmu','gensokyo_main','characters/zanmu-nippaku','Zanmu Nippaku','character','character','zanmu','A high-order underworld authority who should be treated as structural pressure.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_suika','gensokyo_main','characters/suika-ibuki','Suika Ibuki','character','character','suika','An oni of revelry and force whose scenes expand gatherings into pressure.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_location_blood_pool_hell','gensokyo_main','locations/blood-pool-hell','Blood Pool Hell','location','location','blood_pool_hell','A greed-soaked underworld region where appetite, punishment, and pressure are materially entangled.','published','chronicle_gensokyo_history','{}'::jsonb)
on conflict (id) do update
set slug = excluded.slug,
    title = excluded.title,
    page_type = excluded.page_type,
    subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    summary = excluded.summary,
    status = excluded.status,
    canonical_book_id = excluded.canonical_book_id,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_wiki_page_sections (
  id, page_id, section_code, section_order, heading, summary, body, source_ref_ids, metadata
)
values
  ('wiki_character_yuuma:section:overview','wiki_character_yuuma','overview',1,'Overview','Yuuma as greed-driven underworld power.','Yuuma Toutetsu belongs in scenes where appetite and acquisition become the actual logic of the underworld rather than just personality traits.','["claim_yuuma_greed_power","lore_blood_pool_greed"]'::jsonb,'{}'::jsonb),
  ('wiki_character_zanmu:section:overview','wiki_character_zanmu','overview',1,'Overview','Zanmu as structural underworld authority.','Zanmu should be handled as a large-scale underworld pressure point, not as casual local chatter or interchangeable threat.','["claim_zanmu_structural_actor","lore_recent_underworld_power"]'::jsonb,'{}'::jsonb),
  ('wiki_character_suika:section:overview','wiki_character_suika','overview',1,'Overview','Suika as revelry-backed old oni force.','Suika works best when feasting, compression, and blunt oni force all feel like the same social motion.','["claim_suika_old_power"]'::jsonb,'{}'::jsonb),
  ('wiki_location_blood_pool_hell:section:profile','wiki_location_blood_pool_hell','profile',1,'Profile','Blood Pool Hell as appetite and punishment engine.','Blood Pool Hell should feel like an underworld environment where greed, waste, pain, and power all accumulate into one pressure system.','["claim_blood_pool_hell_profile","lore_blood_pool_greed"]'::jsonb,'{}'::jsonb)
on conflict (id) do update
set heading = excluded.heading,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();

-- END FILE: WORLD_SEED_WIKI_RECENT_REALMS.sql

-- BEGIN FILE: WORLD_SEED_CHAT_RECENT_REALMS.sql
-- World seed: chat context for recent-realm cast

insert into public.world_chat_context_cache (
  id, world_id, user_scope, character_id, location_id, event_id, context_type, summary, payload, freshness_score, last_used_at
)
values
  (
    'chat_context_global_suika_underworld_feast',
    'gensokyo_main',
    'global',
    'suika',
    'former_hell',
    null,
    'character_location_story',
    'Suika should read as feast, compression, and old oni pressure all at once rather than as a generic loud ally.',
    jsonb_build_object(
      'claim_ids', array['claim_suika_old_power'],
      'location_ids', array['former_hell','hakurei_shrine']
    ),
    0.81,
    now()
  ),
  (
    'chat_context_global_yuuma_blood_pool',
    'gensokyo_main',
    'global',
    'yuuma',
    'blood_pool_hell',
    null,
    'character_location_story',
    'Yuuma belongs in scenes where greed and appetite feel systemic, not merely personal.',
    jsonb_build_object(
      'claim_ids', array['claim_yuuma_greed_power','claim_blood_pool_hell_profile'],
      'lore_ids', array['lore_blood_pool_greed'],
      'location_ids', array['blood_pool_hell']
    ),
    0.90,
    now()
  ),
  (
    'chat_context_global_zanmu_beast_realm',
    'gensokyo_main',
    'global',
    'zanmu',
    'beast_realm',
    null,
    'character_location_story',
    'Zanmu should sound like a high-order authority whose presence alters the scale of the conversation.',
    jsonb_build_object(
      'claim_ids', array['claim_zanmu_structural_actor'],
      'lore_ids', array['lore_recent_underworld_power'],
      'location_ids', array['beast_realm']
    ),
    0.92,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

-- END FILE: WORLD_SEED_CHAT_RECENT_REALMS.sql

-- BEGIN FILE: WORLD_SEED_WIKI_GLOSSARY.sql
-- World seed: wiki glossary pages for institutions and world rules

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  ('wiki_glossary_hakurei','gensokyo_main','glossary/hakurei-shrine','Hakurei Shrine','glossary','institution','hakurei_shrine','A glossary entry for the shrine as sacred site and public balancing institution.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_glossary_moriya','gensokyo_main','glossary/moriya-shrine','Moriya Shrine','glossary','institution','moriya_shrine','A glossary entry for Moriya Shrine as proactive faith institution and mountain-side authority.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_glossary_myouren','gensokyo_main','glossary/myouren-temple','Myouren Temple','glossary','institution','myouren_temple','A glossary entry for Myouren Temple as coexistence-oriented religious community.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_glossary_eientei','gensokyo_main','glossary/eientei','Eientei','glossary','institution','eientei','A glossary entry for Eientei as secluded expert household with lunar ties.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_glossary_spell_cards','gensokyo_main','glossary/spell-card-rules','Spell Card Rules','glossary','world','gensokyo_main','A glossary entry for ritualized conflict and its social constraints.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_glossary_incidents','gensokyo_main','glossary/incidents','Incidents','glossary','world','gensokyo_main','A glossary entry for recurring disturbances and how they become public history.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_glossary_boundaries','gensokyo_main','glossary/boundaries','Boundaries','glossary','world','gensokyo_main','A glossary entry for the many structural meanings of boundaries in Gensokyo.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_glossary_human_village','gensokyo_main','glossary/human-village','Human Village','glossary','institution','human_village','A glossary entry for the main human public sphere, rumor hub, and social memory center.','published','chronicle_gensokyo_history','{}'::jsonb)
on conflict (id) do update
set slug = excluded.slug,
    title = excluded.title,
    page_type = excluded.page_type,
    subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    summary = excluded.summary,
    status = excluded.status,
    canonical_book_id = excluded.canonical_book_id,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_wiki_page_sections (
  id, page_id, section_code, section_order, heading, summary, body, source_ref_ids, metadata
)
values
  ('wiki_glossary_hakurei:section:definition','wiki_glossary_hakurei','definition',1,'Definition','Hakurei Shrine as sacred and public institution.','Hakurei Shrine is not only a religious site. It is one of the chief public balancing institutions through which incidents become visible, legible, and socially answered inside Gensokyo.','["claim_glossary_hakurei","lore_glossary_hakurei"]'::jsonb,'{}'::jsonb),
  ('wiki_glossary_moriya:section:definition','wiki_glossary_moriya','definition',1,'Definition','Moriya Shrine as proactive institution.','Moriya Shrine should be understood as a mountain-side faith institution that gathers influence proactively and treats expansion as a practical problem rather than a taboo.','["claim_glossary_moriya","lore_glossary_moriya"]'::jsonb,'{}'::jsonb),
  ('wiki_glossary_myouren:section:definition','wiki_glossary_myouren','definition',1,'Definition','Myouren Temple as coexistence institution.','Myouren Temple is best treated as a broad coexistence-minded religious community whose public reach extends beyond any single resident or incident.','["claim_glossary_myouren","lore_glossary_myouren"]'::jsonb,'{}'::jsonb),
  ('wiki_glossary_eientei:section:definition','wiki_glossary_eientei','definition',1,'Definition','Eientei as secluded expert household.','Eientei combines seclusion, expertise, lunar history, and selective hospitality into one institutional household shape.','["claim_glossary_eientei","lore_glossary_eientei"]'::jsonb,'{}'::jsonb),
  ('wiki_glossary_spell_cards:section:definition','wiki_glossary_spell_cards','definition',1,'Definition','Spell card rules as ritualized conflict culture.','Spell card rules are a social and symbolic system that makes conflict legible, bounded, and repeatable without collapsing Gensokyo into constant total war.','["claim_glossary_spell_cards","lore_glossary_spell_cards"]'::jsonb,'{}'::jsonb),
  ('wiki_glossary_incidents:section:definition','wiki_glossary_incidents','definition',1,'Definition','Incidents as recurring public disturbances.','An incident is not merely a strange event. It is a disturbance that enters rumor, draws response, and becomes part of shared memory and later record.','["claim_glossary_incidents","lore_glossary_incidents"]'::jsonb,'{}'::jsonb),
  ('wiki_glossary_boundaries:section:definition','wiki_glossary_boundaries','definition',1,'Definition','Boundaries as structural grammar.','Boundaries in Gensokyo are spatial, social, symbolic, and often personified. They shape movement, exclusion, contact, and who can intervene from which angle.','["claim_glossary_boundaries","lore_glossary_boundaries"]'::jsonb,'{}'::jsonb),
  ('wiki_glossary_human_village:section:definition','wiki_glossary_human_village','definition',1,'Definition','Human Village as public sphere.','The Human Village is the main public sphere of ordinary human life, trade, rumor, instruction, and memory inside Gensokyo.','["claim_glossary_human_village","lore_glossary_human_village"]'::jsonb,'{}'::jsonb)
on conflict (id) do update
set heading = excluded.heading,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();

-- END FILE: WORLD_SEED_WIKI_GLOSSARY.sql

-- BEGIN FILE: WORLD_SEED_WIKI_TERMS.sql
-- World seed: wiki glossary pages for recurring terms

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  ('wiki_term_shinto','gensokyo_main','terms/shinto','Shinto','glossary','term','shinto','A glossary page for shrine-centered religious order in Gensokyo.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_term_buddhism','gensokyo_main','terms/buddhism','Buddhism','glossary','term','buddhism','A glossary page for temple-centered religious community and discipline in Gensokyo.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_term_taoism','gensokyo_main','terms/taoism','Taoism','glossary','term','taoism','A glossary page for hermit cultivation, ritual order, and cultivated authority.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_term_lunarians','gensokyo_main','terms/lunarians','Lunarians','glossary','term','lunarians','A glossary page for the culturally and politically distinct lunar sphere.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_term_tengu','gensokyo_main','terms/tengu','Tengu','glossary','term','tengu','A glossary page for mountain authority and fast-moving information actors.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_term_kappa','gensokyo_main','terms/kappa','Kappa','glossary','term','kappa','A glossary page for engineering, trade, and usable invention culture.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_term_tsukumogami','gensokyo_main','terms/tsukumogami','Tsukumogami','glossary','term','tsukumogami','A glossary page for awakened objects and their public adaptation into personhood.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_term_urban_legends','gensokyo_main','terms/urban-legends','Urban Legends','glossary','term','urban_legends','A glossary page for outside-world rumor logic leaking into Gensokyo.','published','chronicle_gensokyo_history','{}'::jsonb)
on conflict (id) do update
set slug = excluded.slug,
    title = excluded.title,
    page_type = excluded.page_type,
    subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    summary = excluded.summary,
    status = excluded.status,
    canonical_book_id = excluded.canonical_book_id,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_wiki_page_sections (
  id, page_id, section_code, section_order, heading, summary, body, source_ref_ids, metadata
)
values
  ('wiki_term_shinto:section:definition','wiki_term_shinto','definition',1,'Definition','Shinto as shrine-centered sacred order.','In Gensokyo, Shinto is tied to shrines, rites, public legitimacy, and the maintenance of visible sacred order through institutions like Hakurei and Moriya.','["claim_glossary_shinto","lore_glossary_shinto"]'::jsonb,'{}'::jsonb),
  ('wiki_term_buddhism:section:definition','wiki_term_buddhism','definition',1,'Definition','Buddhism as temple-centered coexistence structure.','Buddhism in Gensokyo is tied to temple life, discipline, community, and coexistence-minded public religious practice.','["claim_glossary_buddhism","lore_glossary_buddhism"]'::jsonb,'{}'::jsonb),
  ('wiki_term_taoism:section:definition','wiki_term_taoism','definition',1,'Definition','Taoism as cultivated authority.','Taoist actors in Gensokyo tend to be framed through hermit practice, ritual expertise, and claims to cultivated or restored authority.','["claim_glossary_taoism","lore_glossary_taoism"]'::jsonb,'{}'::jsonb),
  ('wiki_term_lunarians:section:definition','wiki_term_lunarians','definition',1,'Definition','Lunarians as distinct political-cultural sphere.','Lunarians should be understood as distinct from ordinary Gensokyo circulation in culture, standards, and political perspective.','["claim_glossary_lunarians","lore_glossary_lunarians"]'::jsonb,'{}'::jsonb),
  ('wiki_term_tengu:section:definition','wiki_term_tengu','definition',1,'Definition','Tengu as authority and media sphere.','Tengu in Gensokyo are not only mountain residents. They also shape circulation of information, reportage, and institutional mountain order.','["claim_glossary_tengu","lore_glossary_tengu"]'::jsonb,'{}'::jsonb),
  ('wiki_term_kappa:section:definition','wiki_term_kappa','definition',1,'Definition','Kappa as engineering and trade culture.','Kappa are strongly associated with useful invention, terrain-savvy engineering, trade, and practical mechanism culture.','["claim_glossary_kappa","lore_glossary_kappa"]'::jsonb,'{}'::jsonb),
  ('wiki_term_tsukumogami:section:definition','wiki_term_tsukumogami','definition',1,'Definition','Tsukumogami as awakened objects.','Tsukumogami stories are about objects becoming persons, then negotiating public identity, performance, and belonging.','["claim_glossary_tsukumogami","lore_glossary_tsukumogami"]'::jsonb,'{}'::jsonb),
  ('wiki_term_urban_legends:section:definition','wiki_term_urban_legends','definition',1,'Definition','Urban legends as leaked rumor logic.','Urban legends in Gensokyo are best understood as outside-world rumor forms leaking into local narrative structure rather than replacing it entirely.','["claim_glossary_urban_legends","lore_glossary_urban_legends"]'::jsonb,'{}'::jsonb)
on conflict (id) do update
set heading = excluded.heading,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();

-- END FILE: WORLD_SEED_WIKI_TERMS.sql

-- BEGIN FILE: WORLD_SEED_WIKI_FACTIONS_SOCIAL.sql
-- World seed: wiki pages for factions and social functions

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  ('wiki_faction_hakurei','gensokyo_main','factions/hakurei','Hakurei Sphere','glossary','faction','hakurei','A glossary page for the shrine-centered balancing sphere around Hakurei.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_faction_moriya','gensokyo_main','factions/moriya','Moriya Sphere','glossary','faction','moriya','A glossary page for the organized, expansion-minded Moriya sphere.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_faction_sdm','gensokyo_main','factions/scarlet-devil-mansion','Scarlet Devil Mansion Sphere','glossary','faction','sdm','A glossary page for the SDM household hierarchy and symbolic public power.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_faction_eientei','gensokyo_main','factions/eientei','Eientei Sphere','glossary','faction','eientei','A glossary page for the secluded expert household of Eientei.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_social_rumor','gensokyo_main','social-functions/rumor-network','Rumor Network','glossary','social_function','rumor_network','A glossary page for how rumor moves through Gensokyo public life.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_social_festivals','gensokyo_main','social-functions/festivals','Festivals','glossary','social_function','festivals','A glossary page for festivals as public social mechanisms rather than ornament.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_social_trade','gensokyo_main','social-functions/trade','Trade and Exchange','glossary','social_function','trade','A glossary page for exchange, stalls, brokerage, and market-scale circulation.','published','chronicle_gensokyo_history','{}'::jsonb)
on conflict (id) do update
set slug = excluded.slug,
    title = excluded.title,
    page_type = excluded.page_type,
    subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    summary = excluded.summary,
    status = excluded.status,
    canonical_book_id = excluded.canonical_book_id,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_wiki_page_sections (
  id, page_id, section_code, section_order, heading, summary, body, source_ref_ids, metadata
)
values
  ('wiki_faction_hakurei:section:definition','wiki_faction_hakurei','definition',1,'Definition','Hakurei as balancing sphere.','The Hakurei sphere is not a large institution by staff count, but it is one of the most important balancing layers through which public incidents become answerable.', '["claim_faction_hakurei","lore_faction_hakurei"]'::jsonb,'{}'::jsonb),
  ('wiki_faction_moriya:section:definition','wiki_faction_moriya','definition',1,'Definition','Moriya as organized ambitious sphere.','The Moriya sphere combines mountain-side authority, organized faith gathering, and strategic expansion into public life.', '["claim_faction_moriya","lore_faction_moriya"]'::jsonb,'{}'::jsonb),
  ('wiki_faction_sdm:section:definition','wiki_faction_sdm','definition',1,'Definition','SDM as hierarchized household sphere.','The Scarlet Devil Mansion sphere is best understood as a hierarchized household whose symbolic power and threshold control matter as much as its residents.', '["claim_faction_sdm","lore_faction_sdm"]'::jsonb,'{}'::jsonb),
  ('wiki_faction_eientei:section:definition','wiki_faction_eientei','definition',1,'Definition','Eientei as secluded expert sphere.','The Eientei sphere joins medicine, lunar history, selective access, and local misdirection into one household structure.', '["claim_faction_eientei","lore_faction_eientei"]'::jsonb,'{}'::jsonb),
  ('wiki_social_rumor:section:definition','wiki_social_rumor','definition',1,'Definition','Rumor as transmission network.','Rumor in Gensokyo is a real network carried by the village, the press-minded tengu, and recurring public actors who make events legible.', '["claim_social_rumor_network","lore_social_rumor_network"]'::jsonb,'{}'::jsonb),
  ('wiki_social_festivals:section:definition','wiki_social_festivals','definition',1,'Definition','Festivals as public mechanism.','Festivals should be read as tests of cooperation, labor distribution, hierarchy, and public mood rather than mere decorative downtime.', '["claim_social_festivals","lore_social_festivals"]'::jsonb,'{}'::jsonb),
  ('wiki_social_trade:section:definition','wiki_social_trade','definition',1,'Definition','Trade as social circulation.','Trade in Gensokyo includes shops, stalls, curio movement, brokerage, and market-scale divine or semi-divine influence.', '["claim_social_trade","lore_social_trade"]'::jsonb,'{}'::jsonb)
on conflict (id) do update
set heading = excluded.heading,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();

-- END FILE: WORLD_SEED_WIKI_FACTIONS_SOCIAL.sql

-- BEGIN FILE: WORLD_SEED_CHARACTERS_SUPPORTING_CAST_B.sql
-- World seed: second wave of supporting cast across underground, temple, and fairy layers

insert into public.world_characters (
  world_id, id, name, title, species, faction_id, home_location_id, default_location_id,
  public_summary, private_notes, speech_style, worldview, role_in_gensokyo, tags, profile
)
values
  (
    'gensokyo_main','kisume','Kisume','Bucket Well Youkai','youkai','independent',
    'former_hell','former_hell',
    'A small underground youkai best used for narrow passage, ambush, and local mood in vertical spaces.',
    'Useful for making underground routes feel inhabited before larger actors arrive.',
    'quiet, abrupt, eerie',
    'The smallest opening can still become a proper approach.',
    'local_actor',
    '["sa","underground","ambush"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['former_hell','vertical_routes'], 'temperament', 'eerie')
  ),
  (
    'gensokyo_main','yamame','Yamame Kurodani','Spider Youkai','tsuchigumo','independent',
    'former_hell','former_hell',
    'An underground spider youkai suited to rumor, disease talk, and social ties in hidden communities.',
    'Best for showing that the underground has gossip and social texture, not only threat.',
    'friendly, sly, grounded',
    'A network matters most when people forget it is there.',
    'network_actor',
    '["sa","underground","rumor"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['former_hell','underground_social'], 'temperament', 'sly')
  ),
  (
    'gensokyo_main','parsee','Parsee Mizuhashi','Jealousy of the Bridge','hashihime','independent',
    'former_hell','former_hell',
    'A bridge guardian whose scenes fit resentment, observation, and the emotional toll of passage.',
    'Useful where crossing points need emotional pressure rather than simple combat.',
    'sharp, bitter, observant',
    'Crossings are easiest to judge from the side.',
    'threshold_actor',
    '["sa","bridge","emotion"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['bridges','crossings','former_hell'], 'temperament', 'bitter')
  ),
  (
    'gensokyo_main','yuugi','Yuugi Hoshiguma','Powerful Oni','oni','independent',
    'old_capital','old_capital',
    'An oni of former hell suited to convivial force, straightforward challenge, and old-power prestige.',
    'Best used where underground authority should feel social as well as physical.',
    'boisterous, direct, fearless',
    'Strength is easiest to trust when it does not hide.',
    'power_anchor',
    '["sa","oni","old_capital"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['old_capital','oni_customs'], 'temperament', 'boisterous')
  ),
  (
    'gensokyo_main','kyouko','Kyouko Kasodani','Yamabiko Monk','yamabiko','myouren',
    'myouren_temple','myouren_temple',
    'A temple-affiliated yamabiko whose scenes fit discipline, cheerful repetition, and audible presence.',
    'Useful for making Myouren Temple feel inhabited at an everyday level.',
    'cheerful, diligent, loud',
    'If a lesson is worth saying once, it may be worth hearing twice.',
    'temple_support',
    '["td","temple","echo"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['myouren_temple','temple_routine'], 'temperament', 'diligent')
  ),
  (
    'gensokyo_main','yoshika','Yoshika Miyako','Loyal Jiang-shi','jiangshi','taoist',
    'divine_spirit_mausoleum','divine_spirit_mausoleum',
    'A jiang-shi retainer suited to loyalty, blunt force, and visibly controlled service under a stronger agenda.',
    'Useful for giving the mausoleum side physical presence without overcomplicating motive.',
    'simple, eager, obedient',
    'If the order is clear, the work is easy.',
    'retainer',
    '["td","mausoleum","retainer"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['mausoleum_service','basic_orders'], 'temperament', 'obedient')
  ),
  (
    'gensokyo_main','shou','Shou Toramaru','Avatar of Bishamonten','youkai','myouren',
    'myouren_temple','myouren_temple',
    'A temple leader whose scenes fit religious authority, treasure symbolism, and dutiful responsibility.',
    'Useful where Myouren Temple needs leadership distinct from Byakuren herself.',
    'earnest, formal, responsible',
    'Responsibility becomes visible when others place trust in it.',
    'religious_lead',
    '["ufo","temple","authority"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['myouren_temple','religious_authority'], 'temperament', 'earnest')
  ),
  (
    'gensokyo_main','sunny_milk','Sunny Milk','Fairy of Sunlight','fairy','independent',
    'hakurei_shrine','hakurei_shrine',
    'A prank-minded fairy suited to shrine-adjacent daily life, mischief, and trio scenes.',
    'Best used with the other fairies to make ordinary days feel alive and slightly troublesome.',
    'bright, playful, smug',
    'A sunny opening is best when someone else walks into it first.',
    'daily_life_actor',
    '["fairy","daily_life","sunlight"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['shrine_daily_life','fairy_pranks'], 'temperament', 'playful')
  ),
  (
    'gensokyo_main','luna_child','Luna Child','Fairy of Silence','fairy','independent',
    'hakurei_shrine','hakurei_shrine',
    'A quiet but mischievous fairy suited to stealth, atmosphere shifts, and trio rhythm.',
    'Useful for making fairy scenes feel composed rather than only loud.',
    'soft, sly, mischievous',
    'Silence can be more useful than hiding in plain sight.',
    'daily_life_actor',
    '["fairy","daily_life","silence"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['shrine_daily_life','fairy_pranks'], 'temperament', 'sly')
  ),
  (
    'gensokyo_main','star_sapphire','Star Sapphire','Fairy of Starlight','fairy','independent',
    'hakurei_shrine','hakurei_shrine',
    'A perceptive fairy suited to awareness, teasing observation, and trio coordination.',
    'Useful for giving fairy scenes a lookout who notices more than she should.',
    'clever, teasing, alert',
    'Noticing first is its own kind of advantage.',
    'daily_life_actor',
    '["fairy","daily_life","perception"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['shrine_daily_life','fairy_pranks'], 'temperament', 'alert')
  )
on conflict (world_id, id) do update
set name = excluded.name,
    title = excluded.title,
    species = excluded.species,
    faction_id = excluded.faction_id,
    home_location_id = excluded.home_location_id,
    default_location_id = excluded.default_location_id,
    public_summary = excluded.public_summary,
    private_notes = excluded.private_notes,
    speech_style = excluded.speech_style,
    worldview = excluded.worldview,
    role_in_gensokyo = excluded.role_in_gensokyo,
    tags = excluded.tags,
    profile = excluded.profile,
    updated_at = now();

-- END FILE: WORLD_SEED_CHARACTERS_SUPPORTING_CAST_B.sql

-- BEGIN FILE: WORLD_SEED_RELATIONSHIPS_SUPPORTING_CAST_B.sql
-- World seed: second supporting-cast relationship layer

insert into public.world_relationship_edges (
  world_id, source_character_id, target_character_id, relation_type, summary, strength, metadata
)
values
  ('gensokyo_main','kisume','yamame','underground_neighbor','Kisume and Yamame help former-hell routes feel locally inhabited rather than empty connectors.',0.37,'{}'::jsonb),
  ('gensokyo_main','yamame','parsee','underground_social_overlap','Yamame and Parsee occupy adjacent social territory where rumor and resentment travel together.',0.42,'{}'::jsonb),
  ('gensokyo_main','parsee','yuugi','bridge_to_capital','Parsee and Yuugi connect the bridge threshold to the heavier social life of the old capital.',0.39,'{}'::jsonb),
  ('gensokyo_main','yuugi','suika','oni_peer','Yuugi and Suika make oni culture feel older and broader than one personality can carry.',0.58,'{}'::jsonb),
  ('gensokyo_main','kyouko','byakuren','temple_disciple','Kyouko gives Myouren Temple an everyday disciple perspective under Byakuren''s larger leadership.',0.61,'{}'::jsonb),
  ('gensokyo_main','shou','byakuren','temple_leadership','Shou and Byakuren together make temple authority feel distributed rather than singular.',0.67,'{}'::jsonb),
  ('gensokyo_main','yoshika','seiga','servant_bond','Yoshika''s usefulness is easiest to read through Seiga''s manipulative direction.',0.74,'{}'::jsonb),
  ('gensokyo_main','yoshika','miko','mausoleum_service','Yoshika helps make the mausoleum faction feel staffed rather than abstract.',0.34,'{}'::jsonb),
  ('gensokyo_main','sunny_milk','luna_child','fairy_trio','Sunny and Luna work best as part of a recurring fairy trio rhythm.',0.84,'{}'::jsonb),
  ('gensokyo_main','luna_child','star_sapphire','fairy_trio','Luna and Star balance stealth with perception in trio scenes.',0.84,'{}'::jsonb),
  ('gensokyo_main','star_sapphire','sunny_milk','fairy_trio','Star and Sunny keep fairy scenes quick, observant, and lightly troublesome.',0.84,'{}'::jsonb),
  ('gensokyo_main','sunny_milk','reimu','shrine_mischief','Sunny Milk belongs naturally in shrine-side daily mischief that annoys Reimu without overturning the world.',0.29,'{}'::jsonb)
on conflict (world_id, source_character_id, target_character_id, relation_type) do update
set summary = excluded.summary,
    strength = excluded.strength,
    metadata = excluded.metadata,
    updated_at = now();

-- END FILE: WORLD_SEED_RELATIONSHIPS_SUPPORTING_CAST_B.sql

-- BEGIN FILE: WORLD_SEED_CLAIMS_SUPPORTING_CAST_B.sql
-- World seed: second supporting-cast claims and lore

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_supporting_cast_underground','regional_texture','Underground Supporting Texture','The underground should feel social, layered, and staffed by more than only its largest names.',jsonb_build_object('focus','former_hell_and_old_capital'),'["supporting_cast","underground","texture"]'::jsonb,76),
  ('gensokyo_main','lore_supporting_cast_temple','regional_texture','Temple Supporting Texture','Temple life should include routine voices, not only doctrinal leaders and incident peaks.',jsonb_build_object('focus','myouren_temple_and_mausoleum'),'["supporting_cast","temple","texture"]'::jsonb,75),
  ('gensokyo_main','lore_supporting_cast_fairies','daily_life_texture','Fairy Daily-Life Texture','Fairies make shrine and village-adjacent life feel inhabited at a smaller comic scale.',jsonb_build_object('focus','fairy_daily_life'),'["supporting_cast","fairy","daily_life"]'::jsonb,74)
on conflict (world_id, id) do update
set category = excluded.category,
    title = excluded.title,
    summary = excluded.summary,
    details = excluded.details,
    tags = excluded.tags,
    priority = excluded.priority,
    updated_at = now();

insert into public.world_canon_claims (
  id, world_id, subject_type, subject_id, claim_type, summary, details, source_id, confidence, priority, tags
)
values
  ('claim_kisume_underground_approach','gensokyo_main','character','kisume','role','Kisume works best as a local underground approach-presence rather than a broad story architect.',jsonb_build_object('role','local_actor'),'src_subterranean_animism','official',62,'["kisume","sa","underground"]'::jsonb),
  ('claim_yamame_network_underground','gensokyo_main','character','yamame','role','Yamame makes underground scenes feel socially connected through gossip, illness talk, and familiarity.',jsonb_build_object('role','network_actor'),'src_subterranean_animism','official',68,'["yamame","sa","network"]'::jsonb),
  ('claim_parsee_threshold_pressure','gensokyo_main','character','parsee','role','Parsee is strongest in threshold scenes where crossing itself carries emotional pressure.',jsonb_build_object('role','threshold_actor'),'src_subterranean_animism','official',70,'["parsee","sa","bridge"]'::jsonb),
  ('claim_yuugi_old_capital_anchor','gensokyo_main','character','yuugi','role','Yuugi anchors the old capital through direct strength, convivial challenge, and oni prestige.',jsonb_build_object('role','power_anchor'),'src_subterranean_animism','official',72,'["yuugi","sa","oni"]'::jsonb),
  ('claim_kyouko_temple_daily_voice','gensokyo_main','character','kyouko','role','Kyouko gives Myouren Temple a cheerful everyday voice beneath its larger doctrine and politics.',jsonb_build_object('role','temple_support'),'src_td','official',66,'["kyouko","td","temple"]'::jsonb),
  ('claim_yoshika_mausoleum_retainer','gensokyo_main','character','yoshika','role','Yoshika is best treated as a visible retainer who gives the mausoleum faction material presence.',jsonb_build_object('role','retainer'),'src_td','official',69,'["yoshika","td","retainer"]'::jsonb),
  ('claim_shou_temple_authority','gensokyo_main','character','shou','role','Shou represents temple authority, treasure symbolism, and dutiful religious responsibility.',jsonb_build_object('role','religious_lead'),'src_ufo','official',72,'["shou","ufo","temple"]'::jsonb),
  ('claim_sunny_daily_fairy','gensokyo_main','character','sunny_milk','role','Sunny Milk belongs in shrine-side or village-edge daily mischief rather than serious incident command.',jsonb_build_object('role','daily_life_actor'),'src_osp','official',64,'["sunny_milk","fairy","daily_life"]'::jsonb),
  ('claim_luna_daily_fairy','gensokyo_main','character','luna_child','role','Luna Child contributes stealth, timing, and quiet mischief to recurring fairy daily-life scenes.',jsonb_build_object('role','daily_life_actor'),'src_osp','official',64,'["luna_child","fairy","daily_life"]'::jsonb),
  ('claim_star_daily_fairy','gensokyo_main','character','star_sapphire','role','Star Sapphire works as the perceptive edge of fairy-trio scenes, helping small-scale daily life feel observed.',jsonb_build_object('role','daily_life_actor'),'src_osp','official',64,'["star_sapphire","fairy","daily_life"]'::jsonb)
on conflict (id) do update
set subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    claim_type = excluded.claim_type,
    summary = excluded.summary,
    details = excluded.details,
    source_id = excluded.source_id,
    confidence = excluded.confidence,
    priority = excluded.priority,
    tags = excluded.tags,
    updated_at = now();

-- END FILE: WORLD_SEED_CLAIMS_SUPPORTING_CAST_B.sql

-- BEGIN FILE: WORLD_SEED_CHARACTER_ABILITIES_MINOR.sql
-- World seed: minor and support-cast ability claims

insert into public.world_canon_claims (
  id, world_id, subject_type, subject_id, claim_type, summary, details, source_id, confidence, priority, tags
)
values
  ('claim_ability_kisume','gensokyo_main','character','kisume','ability','Kisume''s presentation centers on sudden, narrow-space menace rather than broad territorial control.',jsonb_build_object('ability_theme','ambush_presence'),'src_subterranean_animism','official',66,'["ability","kisume","sa"]'::jsonb),
  ('claim_ability_yamame','gensokyo_main','character','yamame','ability','Yamame is associated with pestilence and the kind of social menace that spreads through networks.',jsonb_build_object('ability_theme','disease_and_network'),'src_subterranean_animism','official',71,'["ability","yamame","sa"]'::jsonb),
  ('claim_ability_parsee','gensokyo_main','character','parsee','ability','Parsee is defined by jealousy and by the emotional charge she brings to crossings and observation.',jsonb_build_object('ability_theme','jealousy'),'src_subterranean_animism','official',73,'["ability","parsee","sa"]'::jsonb),
  ('claim_ability_yuugi','gensokyo_main','character','yuugi','ability','Yuugi embodies immense oni strength backed by social fearlessness rather than hidden method.',jsonb_build_object('ability_theme','oni_strength'),'src_subterranean_animism','official',74,'["ability","yuugi","sa"]'::jsonb),
  ('claim_ability_kyouko','gensokyo_main','character','kyouko','ability','Kyouko is tied to echo and repeated sound, making her useful in scenes of audible presence.',jsonb_build_object('ability_theme','echo'),'src_td','official',67,'["ability","kyouko","td"]'::jsonb),
  ('claim_ability_yoshika','gensokyo_main','character','yoshika','ability','Yoshika is defined by jiang-shi endurance and obedient physical service.',jsonb_build_object('ability_theme','jiangshi_endurance'),'src_td','official',69,'["ability","yoshika","td"]'::jsonb),
  ('claim_ability_shou','gensokyo_main','character','shou','ability','Shou''s authority is framed through Bishamonten imagery, treasure symbolism, and religious power.',jsonb_build_object('ability_theme','avatar_authority'),'src_ufo','official',72,'["ability","shou","ufo"]'::jsonb),
  ('claim_ability_sunny_milk','gensokyo_main','character','sunny_milk','ability','Sunny Milk is associated with bending sunlight and playful concealment through brightness.',jsonb_build_object('ability_theme','light_manipulation'),'src_osp','official',66,'["ability","sunny_milk","fairy"]'::jsonb),
  ('claim_ability_luna_child','gensokyo_main','character','luna_child','ability','Luna Child is associated with silence and reduced sound, giving fairy scenes a stealth component.',jsonb_build_object('ability_theme','silence_field'),'src_osp','official',66,'["ability","luna_child","fairy"]'::jsonb),
  ('claim_ability_star_sapphire','gensokyo_main','character','star_sapphire','ability','Star Sapphire is associated with perceiving the presence of living things, making her a lookout among fairies.',jsonb_build_object('ability_theme','presence_detection'),'src_osp','official',67,'["ability","star_sapphire","fairy"]'::jsonb)
on conflict (id) do update
set subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    claim_type = excluded.claim_type,
    summary = excluded.summary,
    details = excluded.details,
    source_id = excluded.source_id,
    confidence = excluded.confidence,
    priority = excluded.priority,
    tags = excluded.tags,
    updated_at = now();

-- END FILE: WORLD_SEED_CHARACTER_ABILITIES_MINOR.sql

-- BEGIN FILE: WORLD_SEED_WIKI_SUPPORTING_CAST.sql
-- World seed: wiki pages for second-wave supporting cast

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  ('wiki_character_yamame','gensokyo_main','characters/yamame-kurodani','Yamame Kurodani','character','character','yamame','An underground spider youkai who gives hidden communities social texture and rumor flow.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_parsee','gensokyo_main','characters/parsee-mizuhashi','Parsee Mizuhashi','character','character','parsee','A bridge guardian whose scenes hinge on jealousy, crossings, and emotional pressure.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_yuugi','gensokyo_main','characters/yuugi-hoshiguma','Yuugi Hoshiguma','character','character','yuugi','An oni of the old capital who makes underground power feel social, convivial, and direct.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_kyouko','gensokyo_main','characters/kyouko-kasodani','Kyouko Kasodani','character','character','kyouko','A cheerful temple yamabiko who helps Myouren Temple feel lived in day to day.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_yoshika','gensokyo_main','characters/yoshika-miyako','Yoshika Miyako','character','character','yoshika','A mausoleum retainer who gives hidden political factions visible physical presence.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_shou','gensokyo_main','characters/shou-toramaru','Shou Toramaru','character','character','shou','A temple authority figure tied to Bishamonten imagery, treasure, and duty.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_three_fairies','gensokyo_main','characters/three-fairies-of-light','Three Fairies of Light','group','group','three_fairies_of_light','A recurring fairy trio that makes shrine-side and village-edge daily life feel lively and lightly troublesome.','published','chronicle_gensokyo_history','{}'::jsonb)
on conflict (id) do update
set slug = excluded.slug,
    title = excluded.title,
    page_type = excluded.page_type,
    subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    summary = excluded.summary,
    status = excluded.status,
    canonical_book_id = excluded.canonical_book_id,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_wiki_page_sections (
  id, page_id, section_code, section_order, heading, summary, body, source_ref_ids, metadata
)
values
  ('wiki_character_yamame:section:overview','wiki_character_yamame','overview',1,'Overview','Yamame as underground social texture.','Yamame is valuable not just as a threat but as proof that the underground has rumor, familiarity, and recurring local society.','["claim_yamame_network_underground","claim_ability_yamame"]'::jsonb,'{}'::jsonb),
  ('wiki_character_parsee:section:overview','wiki_character_parsee','overview',1,'Overview','Parsee as threshold pressure.','Parsee belongs at crossings where passage itself carries resentment, observation, and emotional pressure.','["claim_parsee_threshold_pressure","claim_ability_parsee"]'::jsonb,'{}'::jsonb),
  ('wiki_character_yuugi:section:overview','wiki_character_yuugi','overview',1,'Overview','Yuugi as old-capital power anchor.','Yuugi makes oni power feel sociable and public rather than distant or abstract.','["claim_yuugi_old_capital_anchor","claim_ability_yuugi"]'::jsonb,'{}'::jsonb),
  ('wiki_character_kyouko:section:overview','wiki_character_kyouko','overview',1,'Overview','Kyouko as temple routine voice.','Kyouko helps temple life feel routine, cheerful, and audible beneath larger ideological conflict.','["claim_kyouko_temple_daily_voice","claim_ability_kyouko"]'::jsonb,'{}'::jsonb),
  ('wiki_character_yoshika:section:overview','wiki_character_yoshika','overview',1,'Overview','Yoshika as visible retainer.','Yoshika gives hidden mausoleum politics a body that can carry orders, force, and presence into the scene.','["claim_yoshika_mausoleum_retainer","claim_ability_yoshika"]'::jsonb,'{}'::jsonb),
  ('wiki_character_shou:section:overview','wiki_character_shou','overview',1,'Overview','Shou as temple authority.','Shou is a major support pillar for temple authority and religious symbolism even when she is not the narrative center.','["claim_shou_temple_authority","claim_ability_shou"]'::jsonb,'{}'::jsonb),
  ('wiki_character_three_fairies:section:overview','wiki_character_three_fairies','overview',1,'Overview','The fairy trio as daily-life engine.','Sunny Milk, Luna Child, and Star Sapphire are most useful together as a recurring small-scale engine for mischief, observation, and ordinary atmosphere.','["claim_sunny_daily_fairy","claim_luna_daily_fairy","claim_star_daily_fairy"]'::jsonb,'{}'::jsonb)
on conflict (id) do update
set heading = excluded.heading,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();

-- END FILE: WORLD_SEED_WIKI_SUPPORTING_CAST.sql

-- BEGIN FILE: WORLD_SEED_CHAT_SUPPORTING_CAST.sql
-- World seed: chat context for second-wave supporting cast

insert into public.world_chat_context_cache (
  id, world_id, user_scope, character_id, location_id, event_id, context_type, summary, payload, freshness_score, last_used_at
)
values
  (
    'chat_voice_yamame_core',
    'gensokyo_main',
    'global',
    'yamame',
    null,
    null,
    'character_voice',
    'Yamame should sound easygoing and sociable on the surface, with a grounded sense that underground communities run on local ties and rumor.',
    jsonb_build_object(
      'speech_style', 'friendly, sly, grounded',
      'worldview', 'A rumor spreads best when everyone thinks it stayed local.',
      'claim_ids', array['claim_yamame_network_underground','claim_ability_yamame']
    ),
    0.86,
    now()
  ),
  (
    'chat_voice_parsee_core',
    'gensokyo_main',
    'global',
    'parsee',
    null,
    null,
    'character_voice',
    'Parsee should sound cutting and observant, as if every crossing has already revealed too much about everyone involved.',
    jsonb_build_object(
      'speech_style', 'sharp, bitter, observant',
      'worldview', 'You can tell a lot about people by what they cross so casually.',
      'claim_ids', array['claim_parsee_threshold_pressure','claim_ability_parsee']
    ),
    0.88,
    now()
  ),
  (
    'chat_voice_yuugi_core',
    'gensokyo_main',
    'global',
    'yuugi',
    null,
    null,
    'character_voice',
    'Yuugi should sound boisterous and open, with old-power confidence that treats force and fellowship as compatible.',
    jsonb_build_object(
      'speech_style', 'boisterous, direct, confident',
      'worldview', 'If you have strength, you might as well let people feel it honestly.',
      'claim_ids', array['claim_yuugi_old_capital_anchor','claim_ability_yuugi']
    ),
    0.88,
    now()
  ),
  (
    'chat_voice_kyouko_core',
    'gensokyo_main',
    'global',
    'kyouko',
    null,
    null,
    'character_voice',
    'Kyouko should sound cheerful and diligent, like every lesson deserves enough energy to bounce back once or twice.',
    jsonb_build_object(
      'speech_style', 'cheerful, diligent, loud',
      'worldview', 'A lesson heard clearly is a lesson halfway kept.',
      'claim_ids', array['claim_kyouko_temple_daily_voice','claim_ability_kyouko']
    ),
    0.85,
    now()
  ),
  (
    'chat_voice_yoshika_core',
    'gensokyo_main',
    'global',
    'yoshika',
    null,
    null,
    'character_voice',
    'Yoshika should sound simple and eager, with obedience doing most of the structural work in the sentence.',
    jsonb_build_object(
      'speech_style', 'simple, eager, obedient',
      'worldview', 'If someone worth following gives an order, that is enough.',
      'claim_ids', array['claim_yoshika_mausoleum_retainer','claim_ability_yoshika']
    ),
    0.82,
    now()
  ),
  (
    'chat_voice_shou_core',
    'gensokyo_main',
    'global',
    'shou',
    null,
    null,
    'character_voice',
    'Shou should sound formal and responsible, carrying religious authority without becoming cold or detached.',
    jsonb_build_object(
      'speech_style', 'formal, earnest, responsible',
      'worldview', 'Trust and responsibility are easier to bear when taken seriously from the start.',
      'claim_ids', array['claim_shou_temple_authority','claim_ability_shou']
    ),
    0.87,
    now()
  ),
  (
    'chat_voice_three_fairies',
    'gensokyo_main',
    'global',
    null,
    'hakurei_shrine',
    null,
    'group_voice',
    'The Three Fairies of Light should make shrine-adjacent scenes feel playful, reactive, and small-scale mischievous rather than high stakes.',
    jsonb_build_object(
      'members', array['sunny_milk','luna_child','star_sapphire'],
      'scene_use', 'daily_life_mischief',
      'claim_ids', array['claim_sunny_daily_fairy','claim_luna_daily_fairy','claim_star_daily_fairy']
    ),
    0.84,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

-- END FILE: WORLD_SEED_CHAT_SUPPORTING_CAST.sql

-- BEGIN FILE: WORLD_SEED_BOOK_EPISODES_FAIRIES.sql
-- World seed: fairy and everyday-life printwork patterns

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_book_fairy_everyday','printwork_pattern','Fairy Everyday Pattern','Fairy-centered print works preserve the small-scale, repeated life of shrine edges, seasons, and harmless trouble.',jsonb_build_object('source_cluster',array['src_osp','src_vfi']),'["printwork","fairy","daily_life"]'::jsonb,77),
  ('gensokyo_main','lore_book_tengu_bias','printwork_pattern','Tengu Bias Pattern','Tengu-centered print material should be treated as public narrative shaped by angle, speed, and selective emphasis.',jsonb_build_object('source_cluster',array['src_boaFW','src_alt_truth','src_ds']),'["printwork","tengu","reporting"]'::jsonb,76)
on conflict (world_id, id) do update
set category = excluded.category,
    title = excluded.title,
    summary = excluded.summary,
    details = excluded.details,
    tags = excluded.tags,
    priority = excluded.priority,
    updated_at = now();

insert into public.world_canon_claims (
  id, world_id, subject_type, subject_id, claim_type, summary, details, source_id, confidence, priority, tags
)
values
  ('claim_book_fairy_everyday','gensokyo_main','printwork','fairy_everyday_cluster','summary','Fairy print works are valuable because they preserve Gensokyo''s low-stakes recurring life rather than only major crisis.',jsonb_build_object('linked_characters',array['sunny_milk','luna_child','star_sapphire','cirno']),'src_vfi','official',78,'["printwork","fairy","summary"]'::jsonb),
  ('claim_book_tengu_bias','gensokyo_main','printwork','tengu_reporting_cluster','summary','Tengu print material should be read as evidence shaped by angle and publicity rather than as neutral record.',jsonb_build_object('linked_characters',array['aya','hatate']),'src_alt_truth','official',77,'["printwork","tengu","summary"]'::jsonb)
on conflict (id) do update
set subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    claim_type = excluded.claim_type,
    summary = excluded.summary,
    details = excluded.details,
    source_id = excluded.source_id,
    confidence = excluded.confidence,
    priority = excluded.priority,
    tags = excluded.tags,
    updated_at = now();

insert into public.world_chronicle_chapters (
  id, book_id, chapter_code, chapter_order, title, summary, period_start, period_end, metadata
)
values
  (
    'chronicle_gensokyo_history:chapter:daily_life',
    'chronicle_gensokyo_history',
    'daily_life',
    4,
    'Ordinary Life and Minor Trouble',
    'A historian''s section for repeated daily-life texture, recurring trouble, and the smaller rhythms that keep Gensokyo inhabited.',
    null,
    null,
    '{}'::jsonb
  )
on conflict (id) do update
set title = excluded.title,
    summary = excluded.summary,
    period_start = excluded.period_start,
    period_end = excluded.period_end,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_chronicle_entries (
  id, book_id, chapter_id, entry_code, entry_order, entry_type, title, summary, body,
  subject_type, subject_id, narrator_character_id, event_id, history_id, tags, metadata
)
values
  (
    'chronicle_entry_fairy_everyday',
    'chronicle_gensokyo_history',
    'chronicle_gensokyo_history:chapter:daily_life',
    'fairy_everyday',
    3,
    'essay',
    'Fairies and the Scale of Ordinary Trouble',
    'A note on why fairy-centered records matter to any honest history of Gensokyo.',
    'A history that remembers only incidents, great leaders, and public crises will miss how Gensokyo actually feels to live in. Fairy records matter because they preserve repetition, atmosphere, petty mischief, and the small disturbances that prove a place is still inhabited between larger upheavals.',
    'group',
    'three_fairies_of_light',
    'keine',
    null,
    null,
    '["fairy","daily_life","history"]'::jsonb,
    '{}'::jsonb
  )
on conflict (id) do update
set title = excluded.title,
    summary = excluded.summary,
    body = excluded.body,
    subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    narrator_character_id = excluded.narrator_character_id,
    tags = excluded.tags,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_chronicle_entry_sources (
  id, entry_id, source_kind, source_ref_id, source_label, weight, notes
)
values
  ('chronicle_entry_fairy_everyday:src:claim','chronicle_entry_fairy_everyday','canon_claim','claim_book_fairy_everyday','Fairy Everyday Pattern',0.86,'Ordinary atmosphere and repeated life'),
  ('chronicle_entry_fairy_everyday:src:lore','chronicle_entry_fairy_everyday','lore','lore_book_fairy_everyday','Fairy Everyday Lore',0.82,'Small-scale recurring texture')
on conflict (id) do update
set source_kind = excluded.source_kind,
    source_ref_id = excluded.source_ref_id,
    source_label = excluded.source_label,
    weight = excluded.weight,
    notes = excluded.notes;

-- END FILE: WORLD_SEED_BOOK_EPISODES_FAIRIES.sql

-- BEGIN FILE: WORLD_SEED_CHARACTERS_SUPPORTING_CAST_C.sql
-- World seed: third wave of supporting cast from early recurring nocturnal and local layers

insert into public.world_characters (
  world_id, id, name, title, species, faction_id, home_location_id, default_location_id,
  public_summary, private_notes, speech_style, worldview, role_in_gensokyo, tags, profile
)
values
  (
    'gensokyo_main','rumia','Rumia','Youkai of Darkness','youkai','independent',
    'misty_lake','misty_lake',
    'A darkness youkai suited to small nighttime trouble, light obstruction, and low-level youkai presence.',
    'Best used to give early-route nights a face rather than to carry major ideology.',
    'simple, playful, hungry',
    'If you cannot see clearly, the world belongs to whoever is nearby.',
    'night_local',
    '["eosd","night","local"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['night_routes','minor_trouble'], 'temperament', 'playful')
  ),
  (
    'gensokyo_main','mystia','Mystia Lorelei','Night Sparrow','sparrow_youkai','independent',
    'human_village','human_village',
    'A singer and food-seller whose scenes fit nocturnal commerce, music, and charming danger at the village edge.',
    'Useful for making night life feel commercial and social rather than empty.',
    'cheerful, musical, opportunistic',
    'If people gather to eat and listen, the night has already become livable.',
    'night_vendor',
    '["in","night","music","food"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['night_stalls','song','village_edges'], 'temperament', 'cheerful')
  ),
  (
    'gensokyo_main','wriggle','Wriggle Nightbug','Firefly Youkai','insect_youkai','independent',
    'human_village','human_village',
    'An insect youkai suited to summer-night texture, small collective pressure, and overlooked local presence.',
    'Useful where the night should feel alive in a low, swarming register rather than through single grand actors.',
    'earnest, prickly, lively',
    'Small lives add up faster than people expect.',
    'night_local',
    '["in","night","summer","insects"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['summer_nights','small_collectives'], 'temperament', 'prickly')
  )
on conflict (world_id, id) do update
set name = excluded.name,
    title = excluded.title,
    species = excluded.species,
    faction_id = excluded.faction_id,
    home_location_id = excluded.home_location_id,
    default_location_id = excluded.default_location_id,
    public_summary = excluded.public_summary,
    private_notes = excluded.private_notes,
    speech_style = excluded.speech_style,
    worldview = excluded.worldview,
    role_in_gensokyo = excluded.role_in_gensokyo,
    tags = excluded.tags,
    profile = excluded.profile,
    updated_at = now();

-- END FILE: WORLD_SEED_CHARACTERS_SUPPORTING_CAST_C.sql

-- BEGIN FILE: WORLD_SEED_RELATIONSHIPS_SUPPORTING_CAST_C.sql
-- World seed: third supporting-cast relationship layer

insert into public.world_relationship_edges (
  world_id, source_character_id, target_character_id, relation_type, summary, strength, metadata
)
values
  ('gensokyo_main','rumia','cirno','minor_chaos_overlap','Rumia and Cirno both help early Gensokyo feel dangerous in small, unserious, recurring ways.',0.26,'{}'::jsonb),
  ('gensokyo_main','mystia','keine','night_village_overlap','Mystia''s night-vendor role and Keine''s village-guardian role naturally intersect at the edge of human nighttime life.',0.41,'{}'::jsonb),
  ('gensokyo_main','mystia','wriggle','night_creature_peer','Mystia and Wriggle make summer-night scenes feel inhabited by more than one kind of local actor.',0.46,'{}'::jsonb),
  ('gensokyo_main','wriggle','cirno','seasonal_smallscale','Wriggle and Cirno connect through small-scale seasonal trouble rather than public incident leadership.',0.28,'{}'::jsonb),
  ('gensokyo_main','rumia','reimu','minor_incident_target','Rumia is the sort of small recurring night problem Reimu should be able to brush aside without escalating the world.',0.35,'{}'::jsonb)
on conflict (world_id, source_character_id, target_character_id, relation_type) do update
set summary = excluded.summary,
    strength = excluded.strength,
    metadata = excluded.metadata,
    updated_at = now();

-- END FILE: WORLD_SEED_RELATIONSHIPS_SUPPORTING_CAST_C.sql

-- BEGIN FILE: WORLD_SEED_CLAIMS_SUPPORTING_CAST_C.sql
-- World seed: third supporting-cast claims and lore

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_supporting_cast_night_life','daily_life_texture','Night-Life Supporting Texture','Night in Gensokyo should feel occupied by singers, small predators, insects, and local trouble rather than becoming empty stage space.',jsonb_build_object('focus','nighttime_local_life'),'["supporting_cast","night","daily_life"]'::jsonb,73)
on conflict (world_id, id) do update
set category = excluded.category,
    title = excluded.title,
    summary = excluded.summary,
    details = excluded.details,
    tags = excluded.tags,
    priority = excluded.priority,
    updated_at = now();

insert into public.world_canon_claims (
  id, world_id, subject_type, subject_id, claim_type, summary, details, source_id, confidence, priority, tags
)
values
  ('claim_rumia_minor_night_threat','gensokyo_main','character','rumia','role','Rumia is best used as a small but recurring night-route threat, not a structural-scale planner.',jsonb_build_object('role','night_local'),'src_eosd','official',63,'["rumia","eosd","night"]'::jsonb),
  ('claim_mystia_night_vendor','gensokyo_main','character','mystia','role','Mystia is especially valuable where song, food, and dangerous charm make the night socially active.',jsonb_build_object('role','night_vendor'),'src_imperishable_night','official',69,'["mystia","in","night"]'::jsonb),
  ('claim_wriggle_small_collective_night','gensokyo_main','character','wriggle','role','Wriggle gives summer-night scenes a smaller-scale collective pressure tied to insects and overlooked life.',jsonb_build_object('role','night_local'),'src_imperishable_night','official',67,'["wriggle","in","summer"]'::jsonb)
on conflict (id) do update
set subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    claim_type = excluded.claim_type,
    summary = excluded.summary,
    details = excluded.details,
    source_id = excluded.source_id,
    confidence = excluded.confidence,
    priority = excluded.priority,
    tags = excluded.tags,
    updated_at = now();

-- END FILE: WORLD_SEED_CLAIMS_SUPPORTING_CAST_C.sql

-- BEGIN FILE: WORLD_SEED_CHARACTER_ABILITIES_NIGHT.sql
-- World seed: night-life support cast ability claims

insert into public.world_canon_claims (
  id, world_id, subject_type, subject_id, claim_type, summary, details, source_id, confidence, priority, tags
)
values
  ('claim_ability_rumia','gensokyo_main','character','rumia','ability','Rumia is defined by darkness and by obstructing ordinary visibility in close-range scenes.',jsonb_build_object('ability_theme','darkness_manipulation'),'src_eosd','official',67,'["ability","rumia","eosd"]'::jsonb),
  ('claim_ability_mystia','gensokyo_main','character','mystia','ability','Mystia is associated with song, night-sparrow danger, and forms of confusion tied to nighttime travel.',jsonb_build_object('ability_theme','night_song_and_confusion'),'src_imperishable_night','official',71,'["ability","mystia","in"]'::jsonb),
  ('claim_ability_wriggle','gensokyo_main','character','wriggle','ability','Wriggle is associated with insects and the collective force of small life in summer-night scenes.',jsonb_build_object('ability_theme','insect_command'),'src_imperishable_night','official',69,'["ability","wriggle","in"]'::jsonb)
on conflict (id) do update
set subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    claim_type = excluded.claim_type,
    summary = excluded.summary,
    details = excluded.details,
    source_id = excluded.source_id,
    confidence = excluded.confidence,
    priority = excluded.priority,
    tags = excluded.tags,
    updated_at = now();

-- END FILE: WORLD_SEED_CHARACTER_ABILITIES_NIGHT.sql

-- BEGIN FILE: WORLD_SEED_WIKI_CHAT_SUPPORTING_CAST_C.sql
-- World seed: wiki and chat support for third-wave night-life cast

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  ('wiki_character_rumia','gensokyo_main','characters/rumia','Rumia','character','character','rumia','A minor darkness youkai who helps early-night Gensokyo feel occupied and dangerous at a small scale.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_mystia','gensokyo_main','characters/mystia-lorelei','Mystia Lorelei','character','character','mystia','A night sparrow whose song, food, and danger make Gensokyo''s night life feel social.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_wriggle','gensokyo_main','characters/wriggle-nightbug','Wriggle Nightbug','character','character','wriggle','An insect youkai who gives summer-night scenes small-scale collective presence.','published','chronicle_gensokyo_history','{}'::jsonb)
on conflict (id) do update
set slug = excluded.slug,
    title = excluded.title,
    page_type = excluded.page_type,
    subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    summary = excluded.summary,
    status = excluded.status,
    canonical_book_id = excluded.canonical_book_id,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_wiki_page_sections (
  id, page_id, section_code, section_order, heading, summary, body, source_ref_ids, metadata
)
values
  ('wiki_character_rumia:section:overview','wiki_character_rumia','overview',1,'Overview','Rumia as local night trouble.','Rumia is best framed as recurring low-scale darkness trouble that gives nighttime routes a face without demanding structural-scale plotting.','["claim_rumia_minor_night_threat","claim_ability_rumia"]'::jsonb,'{}'::jsonb),
  ('wiki_character_mystia:section:overview','wiki_character_mystia','overview',1,'Overview','Mystia as night-life vendor.','Mystia makes the night socially inhabited through song, food, and a danger level that feels charming before it feels strategic.','["claim_mystia_night_vendor","claim_ability_mystia"]'::jsonb,'{}'::jsonb),
  ('wiki_character_wriggle:section:overview','wiki_character_wriggle','overview',1,'Overview','Wriggle as summer-night collective presence.','Wriggle helps scenes feel crowded by small life, making nights feel active even when no major actor is present.','["claim_wriggle_small_collective_night","claim_ability_wriggle"]'::jsonb,'{}'::jsonb)
on conflict (id) do update
set heading = excluded.heading,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_chat_context_cache (
  id, world_id, user_scope, character_id, location_id, event_id, context_type, summary, payload, freshness_score, last_used_at
)
values
  (
    'chat_voice_rumia_core',
    'gensokyo_main',
    'global',
    'rumia',
    null,
    null,
    'character_voice',
    'Rumia should sound simple and casually troublesome, like darkness is a game until someone else trips over it.',
    jsonb_build_object(
      'speech_style', 'simple, playful, hungry',
      'worldview', 'If the dark works, there is no reason to explain it much.',
      'claim_ids', array['claim_rumia_minor_night_threat','claim_ability_rumia']
    ),
    0.80,
    now()
  ),
  (
    'chat_voice_mystia_core',
    'gensokyo_main',
    'global',
    'mystia',
    null,
    null,
    'character_voice',
    'Mystia should sound musical and inviting, with danger wrapped in the tone of a lively night stall.',
    jsonb_build_object(
      'speech_style', 'cheerful, musical, inviting',
      'worldview', 'A good night should feed people before it frightens them away.',
      'claim_ids', array['claim_mystia_night_vendor','claim_ability_mystia']
    ),
    0.85,
    now()
  ),
  (
    'chat_voice_wriggle_core',
    'gensokyo_main',
    'global',
    'wriggle',
    null,
    null,
    'character_voice',
    'Wriggle should sound earnest and slightly prickly, with a sense that small lives count even when others dismiss them.',
    jsonb_build_object(
      'speech_style', 'earnest, prickly, lively',
      'worldview', 'Being overlooked does not make something unimportant.',
      'claim_ids', array['claim_wriggle_small_collective_night','claim_ability_wriggle']
    ),
    0.83,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

-- END FILE: WORLD_SEED_WIKI_CHAT_SUPPORTING_CAST_C.sql

-- BEGIN FILE: WORLD_SEED_GLOSSARY_REGIONAL_CULTURES.sql
-- World seed: regional culture and atmosphere glossary

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_regional_old_capital','regional_culture','Old Capital Culture','The Old Capital should read as a sociable oni sphere where strength, drinking, and public challenge carry cultural legitimacy.',jsonb_build_object('location_id','old_capital'),'["region","old_capital","oni"]'::jsonb,79),
  ('gensokyo_main','lore_regional_former_hell','regional_culture','Former Hell Route Culture','Former Hell is not only a hazard zone. It is a layered passage network where small actors, thresholds, and local rumor matter.',jsonb_build_object('location_id','former_hell'),'["region","former_hell","routes"]'::jsonb,78),
  ('gensokyo_main','lore_regional_myouren_temple','regional_culture','Myouren Temple Daily Culture','Myouren Temple should feel like a lived religious institution with discipline, routine, and coexistence-minded public structure.',jsonb_build_object('location_id','myouren_temple'),'["region","myouren_temple","daily_life"]'::jsonb,80),
  ('gensokyo_main','lore_regional_night_village_edges','regional_culture','Village-Edge Night Culture','The edges of the Human Village at night should feel commercial, musical, and just dangerous enough to remain memorable.',jsonb_build_object('location_id','human_village'),'["region","night","village"]'::jsonb,77),
  ('gensokyo_main','lore_regional_shrine_fairy_life','regional_culture','Shrine Fairy Daily Culture','Hakurei Shrine should sometimes feel inhabited by repeated low-stakes fairy trouble rather than only by major incident traffic.',jsonb_build_object('location_id','hakurei_shrine'),'["region","fairy","shrine"]'::jsonb,76)
on conflict (world_id, id) do update
set category = excluded.category,
    title = excluded.title,
    summary = excluded.summary,
    details = excluded.details,
    tags = excluded.tags,
    priority = excluded.priority,
    updated_at = now();

insert into public.world_canon_claims (
  id, world_id, subject_type, subject_id, claim_type, summary, details, source_id, confidence, priority, tags
)
values
  ('claim_regional_old_capital_culture','gensokyo_main','location','old_capital','setting','The Old Capital should be framed as a sociable oni culture rather than only a dangerous underground landmark.',jsonb_build_object('culture','oni_public_life'),'src_subterranean_animism','official',78,'["old_capital","culture","oni"]'::jsonb),
  ('claim_regional_former_hell_routes','gensokyo_main','location','former_hell','setting','Former Hell should be treated as a route network with thresholds and local actors, not empty travel space.',jsonb_build_object('culture','layered_route_network'),'src_subterranean_animism','official',77,'["former_hell","routes","culture"]'::jsonb),
  ('claim_regional_myouren_daily_life','gensokyo_main','location','myouren_temple','setting','Myouren Temple has daily institutional life beyond major public declarations and incident peaks.',jsonb_build_object('culture','lived_religious_institution'),'src_ufo','official',79,'["myouren_temple","culture","daily_life"]'::jsonb),
  ('claim_regional_village_night_life','gensokyo_main','location','human_village','setting','The village edge at night should feel socially active through song, food, rumor, and small risk.',jsonb_build_object('culture','night_commerce'),'src_imperishable_night','official',75,'["human_village","night","culture"]'::jsonb),
  ('claim_regional_shrine_fairy_life','gensokyo_main','location','hakurei_shrine','setting','Hakurei Shrine should periodically read as a stage for recurring fairy-scale trouble and seasonal silliness.',jsonb_build_object('culture','fairy_daily_life'),'src_osp','official',74,'["hakurei_shrine","fairy","culture"]'::jsonb)
on conflict (id) do update
set subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    claim_type = excluded.claim_type,
    summary = excluded.summary,
    details = excluded.details,
    source_id = excluded.source_id,
    confidence = excluded.confidence,
    priority = excluded.priority,
    tags = excluded.tags,
    updated_at = now();

-- END FILE: WORLD_SEED_GLOSSARY_REGIONAL_CULTURES.sql

-- BEGIN FILE: WORLD_SEED_WIKI_REGIONAL_CULTURES.sql
-- World seed: wiki and chat support for regional cultures

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  ('wiki_region_old_capital_culture','gensokyo_main','regions/old-capital-culture','Old Capital Culture','glossary','location','old_capital','A culture page for oni public life, drinking, and challenge in the Old Capital.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_region_myouren_daily_life','gensokyo_main','regions/myouren-daily-life','Myouren Temple Daily Life','glossary','location','myouren_temple','A culture page for routine temple life, coexistence, and lived religious practice.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_region_village_night_life','gensokyo_main','regions/village-night-life','Village-Edge Night Life','glossary','location','human_village','A culture page for song, food, rumor, and danger at the night edge of the village.','published','chronicle_gensokyo_history','{}'::jsonb)
on conflict (id) do update
set slug = excluded.slug,
    title = excluded.title,
    page_type = excluded.page_type,
    subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    summary = excluded.summary,
    status = excluded.status,
    canonical_book_id = excluded.canonical_book_id,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_wiki_page_sections (
  id, page_id, section_code, section_order, heading, summary, body, source_ref_ids, metadata
)
values
  ('wiki_region_old_capital_culture:section:overview','wiki_region_old_capital_culture','overview',1,'Overview','Old Capital as sociable oni sphere.','The Old Capital should feel loud, public, and convivial, with power displayed through social life rather than hidden behind it.','["claim_regional_old_capital_culture","lore_regional_old_capital"]'::jsonb,'{}'::jsonb),
  ('wiki_region_myouren_daily_life:section:overview','wiki_region_myouren_daily_life','overview',1,'Overview','Myouren Temple as lived institution.','Myouren Temple is strongest as a setting when discipline, routine, care, and coexistence all feel present beneath larger doctrinal conflict.','["claim_regional_myouren_daily_life","lore_regional_myouren_temple"]'::jsonb,'{}'::jsonb),
  ('wiki_region_village_night_life:section:overview','wiki_region_village_night_life','overview',1,'Overview','Night culture at the village edge.','The village at night should read as a space of food, song, rumor, and manageable danger rather than becoming empty after dark.','["claim_regional_village_night_life","lore_regional_night_village_edges"]'::jsonb,'{}'::jsonb)
on conflict (id) do update
set heading = excluded.heading,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_chat_context_cache (
  id, world_id, user_scope, character_id, location_id, event_id, context_type, summary, payload, freshness_score, last_used_at
)
values
  (
    'chat_location_old_capital_culture',
    'gensokyo_main',
    'global',
    null,
    'old_capital',
    null,
    'location_mood',
    'Old Capital scenes should feel public, strong, and convivial rather than merely hazardous.',
    jsonb_build_object(
      'default_mood', 'boisterous',
      'claim_ids', array['claim_regional_old_capital_culture']
    ),
    0.84,
    now()
  ),
  (
    'chat_location_myouren_daily_life',
    'gensokyo_main',
    'global',
    null,
    'myouren_temple',
    null,
    'location_mood',
    'Myouren Temple scenes should feel lived in by routine, discipline, and coexistence-minded order.',
    jsonb_build_object(
      'default_mood', 'orderly',
      'claim_ids', array['claim_regional_myouren_daily_life']
    ),
    0.85,
    now()
  ),
  (
    'chat_location_village_night_life',
    'gensokyo_main',
    'global',
    null,
    'human_village',
    null,
    'location_mood',
    'At night, the village edge should feel social and slightly risky rather than empty.',
    jsonb_build_object(
      'default_mood', 'lively_after_dark',
      'claim_ids', array['claim_regional_village_night_life']
    ),
    0.83,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

-- END FILE: WORLD_SEED_WIKI_REGIONAL_CULTURES.sql

-- BEGIN FILE: WORLD_SEED_SOURCES_LATE_PRINT.sql
-- World seed: additional late print-work sources

insert into public.world_source_index (
  id, world_id, source_kind, source_code, title, short_label, notes, metadata
)
values
  ('src_le','gensokyo_main','official_book','le','Lotus Eaters','LE','Print work source for Miyoi, tavern culture, and after-hours social texture in Gensokyo.','{}'::jsonb),
  ('src_fds','gensokyo_main','official_book','fds','Foul Detective Satori','FDS','Print work source for Mizuchi, possession-linked mystery structure, and later-era incident investigation.','{}'::jsonb)
on conflict (id) do update
set source_kind = excluded.source_kind,
    source_code = excluded.source_code,
    title = excluded.title,
    short_label = excluded.short_label,
    notes = excluded.notes,
    metadata = excluded.metadata,
    updated_at = now();

-- END FILE: WORLD_SEED_SOURCES_LATE_PRINT.sql

-- BEGIN FILE: WORLD_SEED_CHARACTERS_LUNAR_PRINT.sql
-- World seed: lunar and late print-work support characters

insert into public.world_characters (
  world_id, id, name, title, species, faction_id, home_location_id, default_location_id,
  public_summary, private_notes, speech_style, worldview, role_in_gensokyo, tags, profile
)
values
  (
    'gensokyo_main','toyohime','Watatsuki no Toyohime','Lunar Noble','lunarian','lunar_capital',
    'lunar_capital','lunar_capital',
    'A lunar noble suited to high-level moon politics, elegance, and strategic superiority framed as natural order.',
    'Best used when the lunar side needs composed authority rather than raw aggression.',
    'graceful, superior, composed',
    'Refinement and control are easiest to maintain when treated as normal.',
    'lunar_elite',
    '["ssib","moon","nobility"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['lunar_politics','moon_earth_relations'], 'temperament', 'composed')
  ),
  (
    'gensokyo_main','yorihime','Watatsuki no Yorihime','Lunar Noble and Divine Summoner','lunarian','lunar_capital',
    'lunar_capital','lunar_capital',
    'A lunar noble whose role fits martial authority, divine invocation, and uncompromising lunar standards.',
    'Useful where the moon needs force backed by legitimacy rather than mere temperament.',
    'formal, severe, disciplined',
    'Authority is easiest to respect when it never blinks first.',
    'lunar_martial_elite',
    '["ssib","moon","military"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['lunar_security','divine_authority'], 'temperament', 'severe')
  ),
  (
    'gensokyo_main','miyoi','Okunoda Miyoi','Geidontei Poster Girl','zashiki_warashi_like','independent',
    'human_village','human_village',
    'A tavern-linked hostess suited to after-hours village life, drinking culture, and the softer side of recurring social scenes.',
    'Best used where Gensokyo needs nightlife, hospitality, and gossip without turning everything into formal incident structure.',
    'gentle, attentive, warm',
    'People speak differently once they think the day is over.',
    'night_hospitality',
    '["le","village","tavern"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['village_nightlife','tavern_customs'], 'temperament', 'warm')
  ),
  (
    'gensokyo_main','mizuchi','Mizuchi Miyadeguchi','Vengeful Spirit in Hiding','vengeful_spirit','independent',
    'human_village','human_village',
    'A hidden vengeful spirit suited to possession, resentment, and the destabilization of ordinary social surfaces.',
    'Useful when later-era mysteries need a threat that moves through people rather than simply confronting them.',
    'cold, quiet, resentful',
    'A quiet grudge can travel farther than an open shout.',
    'hidden_threat',
    '["fds","vengeful_spirit","mystery"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['hidden_possession','resentment_routes'], 'temperament', 'cold')
  )
on conflict (world_id, id) do update
set name = excluded.name,
    title = excluded.title,
    species = excluded.species,
    faction_id = excluded.faction_id,
    home_location_id = excluded.home_location_id,
    default_location_id = excluded.default_location_id,
    public_summary = excluded.public_summary,
    private_notes = excluded.private_notes,
    speech_style = excluded.speech_style,
    worldview = excluded.worldview,
    role_in_gensokyo = excluded.role_in_gensokyo,
    tags = excluded.tags,
    profile = excluded.profile,
    updated_at = now();

-- END FILE: WORLD_SEED_CHARACTERS_LUNAR_PRINT.sql

-- BEGIN FILE: WORLD_SEED_RELATIONSHIPS_LUNAR_PRINT.sql
-- World seed: lunar and late print-work support relationships

insert into public.world_relationship_edges (
  world_id, source_character_id, target_character_id, relation_type, summary, strength, metadata
)
values
  ('gensokyo_main','toyohime','yorihime','lunar_sibling_rule','Toyohime and Yorihime together make lunar rule feel aristocratic, coordinated, and difficult to casually breach.',0.86,'{}'::jsonb),
  ('gensokyo_main','toyohime','sagume','lunar_high_command','Toyohime and Sagume occupy the same upper air of lunar political seriousness from different angles.',0.49,'{}'::jsonb),
  ('gensokyo_main','yorihime','eirin','lunar_old_order','Yorihime and Eirin help make lunar history feel like a living political continuity.',0.52,'{}'::jsonb),
  ('gensokyo_main','miyoi','mystia','night_hospitality_overlap','Miyoi and Mystia both help make Gensokyo night life feel social, but through different kinds of invitation.',0.38,'{}'::jsonb),
  ('gensokyo_main','miyoi','suika','drinking_scene_overlap','Miyoi and Suika naturally overlap in scenes where drinking turns into revelation, looseness, or trouble.',0.44,'{}'::jsonb),
  ('gensokyo_main','mizuchi','satori','mystery_investigation_axis','Mizuchi and Satori create later-era mystery structure through hidden motive, possession, and mental pressure.',0.55,'{}'::jsonb),
  ('gensokyo_main','mizuchi','reimu','hidden_incident_target','Mizuchi belongs in the class of hidden trouble that forces even familiar protectors to re-evaluate ordinary surfaces.',0.41,'{}'::jsonb)
on conflict (world_id, source_character_id, target_character_id, relation_type) do update
set summary = excluded.summary,
    strength = excluded.strength,
    metadata = excluded.metadata,
    updated_at = now();

-- END FILE: WORLD_SEED_RELATIONSHIPS_LUNAR_PRINT.sql

-- BEGIN FILE: WORLD_SEED_CLAIMS_LUNAR_PRINT.sql
-- World seed: lunar and late print-work support claims

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_lunar_nobility_texture','world_rule','Lunar Nobility Texture','The moon should feel politically stratified, ceremonially confident, and structurally separate from ordinary Gensokyo life.',jsonb_build_object('focus','lunar_elite'),'["moon","nobility","texture"]'::jsonb,82),
  ('gensokyo_main','lore_village_afterhours_texture','daily_life_texture','Village After-Hours Texture','The village after dark should include drink, relief, gossip, and lowered guard rather than simply closing down.',jsonb_build_object('focus','night_hospitality'),'["village","night","tavern"]'::jsonb,78),
  ('gensokyo_main','lore_hidden_possession_texture','incident_pattern','Hidden Possession Texture','Some later incidents should work through hidden resentment and infiltration rather than immediate open confrontation.',jsonb_build_object('focus','hidden_possession'),'["mystery","possession","late_era"]'::jsonb,79)
on conflict (world_id, id) do update
set category = excluded.category,
    title = excluded.title,
    summary = excluded.summary,
    details = excluded.details,
    tags = excluded.tags,
    priority = excluded.priority,
    updated_at = now();

insert into public.world_canon_claims (
  id, world_id, subject_type, subject_id, claim_type, summary, details, source_id, confidence, priority, tags
)
values
  ('claim_toyohime_lunar_noble','gensokyo_main','character','toyohime','role','Toyohime should be treated as high lunar nobility whose ease and elegance come from structural superiority, not casual softness.',jsonb_build_object('role','lunar_elite'),'src_ssib','official',75,'["toyohime","moon","role"]'::jsonb),
  ('claim_yorihime_lunar_martial_elite','gensokyo_main','character','yorihime','role','Yorihime represents disciplined lunar force and standards that ordinary Gensokyo actors cannot casually equal.',jsonb_build_object('role','lunar_martial_elite'),'src_ssib','official',77,'["yorihime","moon","role"]'::jsonb),
  ('claim_miyoi_night_hospitality','gensokyo_main','character','miyoi','role','Miyoi is best used to show hospitality, drink, and after-hours social texture in the village rather than overt public power.',jsonb_build_object('role','night_hospitality'),'src_le','official',72,'["miyoi","night","village"]'::jsonb),
  ('claim_mizuchi_hidden_possession','gensokyo_main','character','mizuchi','role','Mizuchi belongs to hidden-possession and resentment-driven mystery structures rather than loud public declaration.',jsonb_build_object('role','hidden_threat'),'src_fds','official',74,'["mizuchi","mystery","possession"]'::jsonb),
  ('claim_lunar_nobility_culture','gensokyo_main','world','gensokyo_main','world_rule','Lunar nobility should be framed as a distinct political-cultural layer, not simply as stronger versions of ordinary locals.',jsonb_build_object('scope','lunar_capital'),'src_ciLR','official',80,'["moon","culture","rule"]'::jsonb)
on conflict (id) do update
set subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    claim_type = excluded.claim_type,
    summary = excluded.summary,
    details = excluded.details,
    source_id = excluded.source_id,
    confidence = excluded.confidence,
    priority = excluded.priority,
    tags = excluded.tags,
    updated_at = now();

-- END FILE: WORLD_SEED_CLAIMS_LUNAR_PRINT.sql

-- BEGIN FILE: WORLD_SEED_CHARACTER_ABILITIES_LUNAR_PRINT.sql
-- World seed: lunar and late print-work support ability claims

insert into public.world_canon_claims (
  id, world_id, subject_type, subject_id, claim_type, summary, details, source_id, confidence, priority, tags
)
values
  ('claim_ability_toyohime','gensokyo_main','character','toyohime','ability','Toyohime is associated with high lunar mobility and composure-backed superiority rather than brute display.',jsonb_build_object('ability_theme','lunar_transport_and_grace'),'src_ssib','official',73,'["ability","toyohime","moon"]'::jsonb),
  ('claim_ability_yorihime','gensokyo_main','character','yorihime','ability','Yorihime is associated with divine invocation and overwhelming formal combat authority.',jsonb_build_object('ability_theme','divine_summoning'),'src_ssib','official',78,'["ability","yorihime","moon"]'::jsonb),
  ('claim_ability_miyoi','gensokyo_main','character','miyoi','ability','Miyoi is tied to the strange hospitality and soft unreality of after-hours tavern scenes.',jsonb_build_object('ability_theme','hospitality_and_night_unreality'),'src_le','official',69,'["ability","miyoi","nightlife"]'::jsonb),
  ('claim_ability_mizuchi','gensokyo_main','character','mizuchi','ability','Mizuchi is associated with hidden possession, grudge persistence, and indirect destabilization.',jsonb_build_object('ability_theme','possession_and_grudge'),'src_fds','official',75,'["ability","mizuchi","mystery"]'::jsonb)
on conflict (id) do update
set subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    claim_type = excluded.claim_type,
    summary = excluded.summary,
    details = excluded.details,
    source_id = excluded.source_id,
    confidence = excluded.confidence,
    priority = excluded.priority,
    tags = excluded.tags,
    updated_at = now();

-- END FILE: WORLD_SEED_CHARACTER_ABILITIES_LUNAR_PRINT.sql

-- BEGIN FILE: WORLD_SEED_WIKI_CHAT_LUNAR_PRINT.sql
-- World seed: wiki and chat support for lunar and late print-work support cast

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  ('wiki_character_toyohime','gensokyo_main','characters/watatsuki-no-toyohime','Watatsuki no Toyohime','character','character','toyohime','A lunar noble whose role centers on composed superiority and high political standing on the moon.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_yorihime','gensokyo_main','characters/watatsuki-no-yorihime','Watatsuki no Yorihime','character','character','yorihime','A lunar noble and martial authority whose force is backed by severe legitimacy.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_miyoi','gensokyo_main','characters/okunoda-miyoi','Okunoda Miyoi','character','character','miyoi','A tavern hostess who gives Gensokyo after-hours life warmth, gossip, and soft instability.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_mizuchi','gensokyo_main','characters/mizuchi-miyadeguchi','Mizuchi Miyadeguchi','character','character','mizuchi','A hidden vengeful spirit whose role depends on possession, resentment, and mystery pressure.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_term_lunar_nobility','gensokyo_main','terms/lunar-nobility','Lunar Nobility','glossary','term','lunar_nobility','A glossary page for aristocratic lunar authority and political-cultural distance from Gensokyo.','published','chronicle_gensokyo_history','{}'::jsonb)
on conflict (id) do update
set slug = excluded.slug,
    title = excluded.title,
    page_type = excluded.page_type,
    subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    summary = excluded.summary,
    status = excluded.status,
    canonical_book_id = excluded.canonical_book_id,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_wiki_page_sections (
  id, page_id, section_code, section_order, heading, summary, body, source_ref_ids, metadata
)
values
  ('wiki_character_toyohime:section:overview','wiki_character_toyohime','overview',1,'Overview','Toyohime as lunar aristocratic ease.','Toyohime is useful where lunar politics should feel graceful, confident, and structurally above ordinary Gensokyo friction.','["claim_toyohime_lunar_noble","claim_ability_toyohime"]'::jsonb,'{}'::jsonb),
  ('wiki_character_yorihime:section:overview','wiki_character_yorihime','overview',1,'Overview','Yorihime as severe lunar force.','Yorihime gives the moon disciplined force backed by legitimacy rather than mere aggression.','["claim_yorihime_lunar_martial_elite","claim_ability_yorihime"]'::jsonb,'{}'::jsonb),
  ('wiki_character_miyoi:section:overview','wiki_character_miyoi','overview',1,'Overview','Miyoi as after-hours hospitality.','Miyoi helps the village at night feel warm, social, and slightly unreal once formality drops away.','["claim_miyoi_night_hospitality","claim_ability_miyoi"]'::jsonb,'{}'::jsonb),
  ('wiki_character_mizuchi:section:overview','wiki_character_mizuchi','overview',1,'Overview','Mizuchi as hidden resentment.','Mizuchi is strongest in stories where possession and grudge travel under ordinary surfaces before becoming visible.','["claim_mizuchi_hidden_possession","claim_ability_mizuchi"]'::jsonb,'{}'::jsonb),
  ('wiki_term_lunar_nobility:section:definition','wiki_term_lunar_nobility','definition',1,'Definition','Lunar nobility as distinct political culture.','Lunar nobility should be read as a separate political and ceremonial layer whose standards differ sharply from ordinary Gensokyo practice.','["claim_lunar_nobility_culture","lore_lunar_nobility_texture"]'::jsonb,'{}'::jsonb)
on conflict (id) do update
set heading = excluded.heading,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_chat_context_cache (
  id, world_id, user_scope, character_id, location_id, event_id, context_type, summary, payload, freshness_score, last_used_at
)
values
  (
    'chat_voice_toyohime_core',
    'gensokyo_main',
    'global',
    'toyohime',
    null,
    null,
    'character_voice',
    'Toyohime should sound graceful and composed, as if superiority is less a boast than an environmental assumption.',
    jsonb_build_object(
      'speech_style', 'graceful, composed, superior',
      'worldview', 'Order is easiest to preserve when one never has to doubt one''s station.',
      'claim_ids', array['claim_toyohime_lunar_noble','claim_ability_toyohime']
    ),
    0.87,
    now()
  ),
  (
    'chat_voice_yorihime_core',
    'gensokyo_main',
    'global',
    'yorihime',
    null,
    null,
    'character_voice',
    'Yorihime should sound formal and severe, with authority resting on discipline rather than theatricality.',
    jsonb_build_object(
      'speech_style', 'formal, severe, disciplined',
      'worldview', 'Standards are not meaningful if lowered for convenience.',
      'claim_ids', array['claim_yorihime_lunar_martial_elite','claim_ability_yorihime']
    ),
    0.88,
    now()
  ),
  (
    'chat_voice_miyoi_core',
    'gensokyo_main',
    'global',
    'miyoi',
    null,
    null,
    'character_voice',
    'Miyoi should sound warm and attentive, like she notices when people begin speaking more honestly than they meant to.',
    jsonb_build_object(
      'speech_style', 'gentle, attentive, warm',
      'worldview', 'People reveal a great deal once they think the night belongs to them.',
      'claim_ids', array['claim_miyoi_night_hospitality','claim_ability_miyoi']
    ),
    0.85,
    now()
  ),
  (
    'chat_voice_mizuchi_core',
    'gensokyo_main',
    'global',
    'mizuchi',
    null,
    null,
    'character_voice',
    'Mizuchi should sound cold and contained, like resentment has already outlived the need to be loud.',
    jsonb_build_object(
      'speech_style', 'cold, quiet, resentful',
      'worldview', 'What stays hidden longest often changes the most before anyone notices.',
      'claim_ids', array['claim_mizuchi_hidden_possession','claim_ability_mizuchi']
    ),
    0.86,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

-- END FILE: WORLD_SEED_WIKI_CHAT_LUNAR_PRINT.sql

-- BEGIN FILE: WORLD_SEED_BOOK_EPISODES_LUNAR_PRINT.sql
-- World seed: lunar and late print-work episode patterns

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_book_lotus_eaters','printwork_pattern','Lotus Eaters Pattern','Lotus Eaters preserves Gensokyo after-hours social life through drink, loosened talk, and recurring hospitality.',jsonb_build_object('source','le'),'["printwork","le","nightlife"]'::jsonb,79),
  ('gensokyo_main','lore_book_foul_detective_satori','printwork_pattern','Foul Detective Satori Pattern','Foul Detective Satori works through hidden motive, investigation, and possession-linked mystery under ordinary surfaces.',jsonb_build_object('source','fds'),'["printwork","fds","mystery"]'::jsonb,80),
  ('gensokyo_main','lore_book_lunar_expedition','printwork_pattern','Lunar Expedition Pattern','Moon-expedition print works preserve the political distance, ceremony, and asymmetry of the lunar sphere.',jsonb_build_object('source_cluster',array['src_ssib','src_ciLR']),'["printwork","moon","politics"]'::jsonb,81)
on conflict (world_id, id) do update
set category = excluded.category,
    title = excluded.title,
    summary = excluded.summary,
    details = excluded.details,
    tags = excluded.tags,
    priority = excluded.priority,
    updated_at = now();

insert into public.world_canon_claims (
  id, world_id, subject_type, subject_id, claim_type, summary, details, source_id, confidence, priority, tags
)
values
  ('claim_book_lotus_eaters','gensokyo_main','printwork','lotus_eaters','summary','Lotus Eaters is valuable for tavern culture, after-hours speech, and the softer structures of social life in Gensokyo.',jsonb_build_object('linked_characters',array['miyoi','suika','marisa','reimu']),'src_le','official',79,'["printwork","le","summary"]'::jsonb),
  ('claim_book_foul_detective_satori','gensokyo_main','printwork','foul_detective_satori','summary','Foul Detective Satori preserves later-era possession mystery structure and hidden resentment beneath ordinary life.',jsonb_build_object('linked_characters',array['satori','mizuchi','reimu']),'src_fds','official',80,'["printwork","fds","summary"]'::jsonb),
  ('claim_book_lunar_expedition','gensokyo_main','printwork','lunar_expedition_cluster','summary','Lunar expedition works are key for treating the moon as a distinct political sphere rather than merely a distant backdrop.',jsonb_build_object('linked_characters',array['toyohime','yorihime','eirin','reisen']),'src_ssib','official',81,'["printwork","moon","summary"]'::jsonb)
on conflict (id) do update
set subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    claim_type = excluded.claim_type,
    summary = excluded.summary,
    details = excluded.details,
    source_id = excluded.source_id,
    confidence = excluded.confidence,
    priority = excluded.priority,
    tags = excluded.tags,
    updated_at = now();

-- END FILE: WORLD_SEED_BOOK_EPISODES_LUNAR_PRINT.sql

-- BEGIN FILE: WORLD_SEED_GLOSSARY_TERMS_B.sql
-- World seed: second wave of recurring world terms

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_term_faith_economy','term','Faith Economy','Faith in Gensokyo is not only belief. It also functions as a practical resource tied to legitimacy, public support, and shrine-side competition.',jsonb_build_object('domain','religion_and_power'),'["term","faith","economy"]'::jsonb,80),
  ('gensokyo_main','lore_term_perfect_possession','term','Perfect Possession','Perfect possession should be treated as a destabilizing pairing logic that scrambles ordinary boundaries of agency and combat.',jsonb_build_object('domain','possession_incidents'),'["term","possession","incident"]'::jsonb,79),
  ('gensokyo_main','lore_term_outside_world_leakage','term','Outside-World Leakage','The Outside World affects Gensokyo less through direct replacement than through leakage of rumor forms, objects, and explanatory frames.',jsonb_build_object('domain','boundary_and_modernity'),'["term","outside_world","leakage"]'::jsonb,81),
  ('gensokyo_main','lore_term_animal_spirits','term','Animal Spirits','Animal spirits should be read as political and factional actors of the Beast Realm, not mere ambient monsters.',jsonb_build_object('domain','beast_realm_politics'),'["term","animal_spirits","beast_realm"]'::jsonb,78),
  ('gensokyo_main','lore_term_market_cards','term','Ability Cards','The ability-card economy turns power into circulation, collection, and market pressure rather than purely personal training.',jsonb_build_object('domain','market_incident'),'["term","ability_cards","market"]'::jsonb,80)
on conflict (world_id, id) do update
set category = excluded.category,
    title = excluded.title,
    summary = excluded.summary,
    details = excluded.details,
    tags = excluded.tags,
    priority = excluded.priority,
    updated_at = now();

insert into public.world_canon_claims (
  id, world_id, subject_type, subject_id, claim_type, summary, details, source_id, confidence, priority, tags
)
values
  ('claim_term_faith_economy','gensokyo_main','term','faith_economy','definition','Faith should be treated as a practical political resource in shrine-centered competition, not only as private devotion.',jsonb_build_object('related_locations',array['hakurei_shrine','moriya_shrine']),'src_mofa','official',81,'["term","faith","economy"]'::jsonb),
  ('claim_term_perfect_possession','gensokyo_main','term','perfect_possession','definition','Perfect possession destabilizes ordinary agency by forcing pair-logic and layered control into conflict and identity.',jsonb_build_object('related_incident','incident_perfect_possession'),'src_aocf','official',79,'["term","possession","aocf"]'::jsonb),
  ('claim_term_outside_world_leakage','gensokyo_main','term','outside_world_leakage','definition','Outside-world influence usually enters Gensokyo through leakage of forms, rumors, and objects rather than clean transplantation.',jsonb_build_object('related_incident','incident_urban_legends'),'src_ulil','official',82,'["term","outside_world","leakage"]'::jsonb),
  ('claim_term_animal_spirits','gensokyo_main','term','animal_spirits','definition','Animal spirits are factional political actors tied to the Beast Realm and its proxy conflicts.',jsonb_build_object('related_location','beast_realm'),'src_wbawc','official',78,'["term","animal_spirits","politics"]'::jsonb),
  ('claim_term_market_cards','gensokyo_main','term','ability_cards','definition','Ability cards convert power into a market-circulation problem, not just a combat option.',jsonb_build_object('related_incident','incident_market_cards'),'src_um','official',80,'["term","ability_cards","market"]'::jsonb)
on conflict (id) do update
set subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    claim_type = excluded.claim_type,
    summary = excluded.summary,
    details = excluded.details,
    source_id = excluded.source_id,
    confidence = excluded.confidence,
    priority = excluded.priority,
    tags = excluded.tags,
    updated_at = now();

-- END FILE: WORLD_SEED_GLOSSARY_TERMS_B.sql

-- BEGIN FILE: WORLD_SEED_WIKI_TERMS_B.sql
-- World seed: second wave of glossary wiki pages and sections

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  ('wiki_term_faith_economy','gensokyo_main','terms/faith-economy','Faith Economy','glossary','term','faith_economy','A glossary page for faith as public resource, legitimacy, and competition.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_term_perfect_possession','gensokyo_main','terms/perfect-possession','Perfect Possession','glossary','term','perfect_possession','A glossary page for layered agency, possession pairings, and destabilized conflict structure.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_term_outside_world_leakage','gensokyo_main','terms/outside-world-leakage','Outside-World Leakage','glossary','term','outside_world_leakage','A glossary page for how outside-world ideas and objects seep into Gensokyo.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_term_animal_spirits','gensokyo_main','terms/animal-spirits','Animal Spirits','glossary','term','animal_spirits','A glossary page for Beast Realm-aligned spirits as factional actors.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_term_ability_cards','gensokyo_main','terms/ability-cards','Ability Cards','glossary','term','ability_cards','A glossary page for power as market circulation and collected commodity.','published','chronicle_gensokyo_history','{}'::jsonb)
on conflict (id) do update
set slug = excluded.slug,
    title = excluded.title,
    page_type = excluded.page_type,
    subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    summary = excluded.summary,
    status = excluded.status,
    canonical_book_id = excluded.canonical_book_id,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_wiki_page_sections (
  id, page_id, section_code, section_order, heading, summary, body, source_ref_ids, metadata
)
values
  ('wiki_term_faith_economy:section:definition','wiki_term_faith_economy','definition',1,'Definition','Faith as resource and legitimacy.','In Gensokyo, faith operates as public support, institutional legitimacy, and practical religious capital rather than only inward belief.','["claim_term_faith_economy","lore_term_faith_economy"]'::jsonb,'{}'::jsonb),
  ('wiki_term_perfect_possession:section:definition','wiki_term_perfect_possession','definition',1,'Definition','Perfect possession as layered agency.','Perfect possession is a destabilizing logic in which control, combat, and identity become paired and partially displaced across actors.','["claim_term_perfect_possession","lore_term_perfect_possession"]'::jsonb,'{}'::jsonb),
  ('wiki_term_outside_world_leakage:section:definition','wiki_term_outside_world_leakage','definition',1,'Definition','Outside influence as leakage.','Outside-world influence is strongest when it enters Gensokyo through rumor, objects, and explanatory patterns rather than simple replacement.','["claim_term_outside_world_leakage","lore_term_outside_world_leakage"]'::jsonb,'{}'::jsonb),
  ('wiki_term_animal_spirits:section:definition','wiki_term_animal_spirits','definition',1,'Definition','Animal spirits as factional actors.','Animal spirits should be understood through Beast Realm politics, proxy struggle, and organized factional pressure.','["claim_term_animal_spirits","lore_term_animal_spirits"]'::jsonb,'{}'::jsonb),
  ('wiki_term_ability_cards:section:definition','wiki_term_ability_cards','definition',1,'Definition','Ability cards as marketized power.','Ability cards make power circulate as commodity, collection, and market leverage rather than remaining only personal technique.','["claim_term_market_cards","lore_term_market_cards"]'::jsonb,'{}'::jsonb)
on conflict (id) do update
set heading = excluded.heading,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();

-- END FILE: WORLD_SEED_WIKI_TERMS_B.sql

-- BEGIN FILE: WORLD_SEED_INCIDENT_BEATS_EXPANDED.sql
-- World seed: finer-grained incident chronology and historian notes

insert into public.world_story_events (
  id, world_id, event_code, title, theme, canon_level, status,
  start_at, end_at, current_phase_id, current_phase_order,
  lead_location_id, organizer_character_id, synopsis, narrative_hook, payload, metadata
)
values
  (
    'story_incident_scarlet_mist_archive',
    'gensokyo_main',
    'incident_scarlet_mist_archive',
    'Scarlet Mist Incident Archive',
    'Archival record for the scarlet mist incident and its long tail.',
    'official',
    'resolved',
    null,
    null,
    null,
    null,
    'scarlet_devil_mansion',
    'reimu',
    'An archival event container for scarlet mist aftereffects and historical reference.',
    'Used to anchor world_story_history records for later chat and chronicle lookup.',
    jsonb_build_object('incident_key','scarlet_mist','archive',true),
    '{}'::jsonb
  ),
  (
    'story_incident_faith_shift_archive',
    'gensokyo_main',
    'incident_faith_shift_archive',
    'Mountain Faith Shift Archive',
    'Archival record for the mountain-faith power shift and later institutional consequences.',
    'official',
    'resolved',
    null,
    null,
    null,
    null,
    'moriya_shrine',
    'reimu',
    'An archival event container for faith-shift aftereffects and historical reference.',
    'Used to anchor world_story_history records for later chat and chronicle lookup.',
    jsonb_build_object('incident_key','faith_shift','archive',true),
    '{}'::jsonb
  ),
  (
    'story_incident_perfect_possession_archive',
    'gensokyo_main',
    'incident_perfect_possession_archive',
    'Perfect Possession Archive',
    'Archival record for perfect possession and split-agency aftereffects.',
    'official',
    'resolved',
    null,
    null,
    null,
    null,
    'human_village',
    'reimu',
    'An archival event container for perfect possession aftereffects and historical reference.',
    'Used to anchor world_story_history records for later chat and chronicle lookup.',
    jsonb_build_object('incident_key','perfect_possession','archive',true),
    '{}'::jsonb
  ),
  (
    'story_incident_market_cards_archive',
    'gensokyo_main',
    'incident_market_cards_archive',
    'Ability Card Market Archive',
    'Archival record for the ability-card affair and its market aftereffects.',
    'official',
    'resolved',
    null,
    null,
    null,
    null,
    'rainbow_dragon_cave',
    'marisa',
    'An archival event container for market-card aftereffects and historical reference.',
    'Used to anchor world_story_history records for later chat and chronicle lookup.',
    jsonb_build_object('incident_key','market_cards','archive',true),
    '{}'::jsonb
  )
on conflict (id) do update
set event_code = excluded.event_code,
    title = excluded.title,
    theme = excluded.theme,
    canon_level = excluded.canon_level,
    status = excluded.status,
    start_at = excluded.start_at,
    end_at = excluded.end_at,
    current_phase_id = excluded.current_phase_id,
    current_phase_order = excluded.current_phase_order,
    lead_location_id = excluded.lead_location_id,
    organizer_character_id = excluded.organizer_character_id,
    synopsis = excluded.synopsis,
    narrative_hook = excluded.narrative_hook,
    payload = excluded.payload,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_story_history (
  id, world_id, event_id, phase_id, history_kind, fact_summary, location_id, actor_ids, payload, committed_at
)
values
  (
    'history_incident_scarlet_mist_resolution',
    'gensokyo_main',
    'story_incident_scarlet_mist_archive',
    null,
    'aftereffect',
    'The scarlet mist incident forced a public reaffirmation that major distortions of daily life trigger direct response from incident-resolving actors.',
    'scarlet_devil_mansion',
    '["reimu","marisa","remilia","sakuya"]'::jsonb,
    jsonb_build_object(
      'incident_key','scarlet_mist',
      'beat','resolution_pattern',
      'affected_locations','["scarlet_devil_mansion","human_village","hakurei_shrine"]'::jsonb
    ),
    now()
  ),
  (
    'history_incident_mountain_faith_shift',
    'gensokyo_main',
    'story_incident_faith_shift_archive',
    null,
    'aftereffect',
    'The mountain faith shift changed shrine competition into a lasting institutional relationship rather than a one-day disruption.',
    'moriya_shrine',
    '["reimu","sanae","kanako","suwako","nitori"]'::jsonb,
    jsonb_build_object(
      'incident_key','faith_shift',
      'beat','institutional_aftereffect',
      'affected_locations','["moriya_shrine","hakurei_shrine","youkai_mountain_foot"]'::jsonb
    ),
    now()
  ),
  (
    'history_incident_perfect_possession',
    'gensokyo_main',
    'story_incident_perfect_possession_archive',
    null,
    'aftereffect',
    'The perfect possession crisis made agency itself unstable, forcing later-era actors to take hidden influence and paired control more seriously.',
    'human_village',
    '["reimu","marisa","yukari","sumireko","shion","joon"]'::jsonb,
    jsonb_build_object(
      'incident_key','perfect_possession',
      'beat','agency_instability',
      'affected_locations','["human_village","hakurei_shrine"]'::jsonb
    ),
    now()
  ),
  (
    'history_incident_market_cards_aftereffect',
    'gensokyo_main',
    'story_incident_market_cards_archive',
    null,
    'aftereffect',
    'The ability-card affair normalized thinking about power as something collected, circulated, and traded through networks.',
    'rainbow_dragon_cave',
    '["marisa","takane","chimata","tsukasa","mike"]'::jsonb,
    jsonb_build_object(
      'incident_key','market_cards',
      'beat','marketization_of_power',
      'affected_locations','["rainbow_dragon_cave","human_village","youkai_mountain_foot"]'::jsonb
    ),
    now()
  )
on conflict (id) do update
set history_kind = excluded.history_kind,
    fact_summary = excluded.fact_summary,
    location_id = excluded.location_id,
    actor_ids = excluded.actor_ids,
    payload = excluded.payload,
    committed_at = excluded.committed_at;

insert into public.world_historian_notes (
  id, world_id, historian_character_id, subject_type, subject_id, note_kind, title, summary, body, source_ref_ids, metadata
)
values
  (
    'historian_note_keine_scarlet_mist',
    'gensokyo_main',
    'keine',
    'incident',
    'scarlet_mist',
    'editorial',
    'On the Scarlet Mist as Public Threshold',
    'A note on why the scarlet mist mattered beyond simple spectacle.',
    'The scarlet mist mattered because it disrupted the ordinary day. Once daily visibility, travel, and public rhythm were affected, the event ceased to be private excess and became a public incident that demanded response.',
    '["history_incident_scarlet_mist_resolution","claim_sdm_household"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'historian_note_keine_faith_shift',
    'gensokyo_main',
    'keine',
    'incident',
    'faith_shift',
    'editorial',
    'On the Faith Shift as Lasting Rearrangement',
    'A note on why mountain-faith conflict did not end when the immediate disturbance subsided.',
    'The important effect of the mountain faith conflict was not a single disturbance but the long-term rearrangement of religious competition, village attention, and shrine-side legitimacy.',
    '["history_incident_mountain_faith_shift","claim_moriya_proactive","claim_term_faith_economy"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'historian_note_keine_perfect_possession',
    'gensokyo_main',
    'keine',
    'incident',
    'perfect_possession',
    'editorial',
    'On Perfect Possession and Split Agency',
    'A note on possession as a civic problem rather than only a combat gimmick.',
    'Perfect possession unsettled ordinary trust because it made visible action an unreliable indicator of actual agency. That alone places it in the category of socially significant incident logic.',
    '["history_incident_perfect_possession","claim_term_perfect_possession"]'::jsonb,
    '{}'::jsonb
  )
on conflict (id) do update
set note_kind = excluded.note_kind,
    title = excluded.title,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_chat_context_cache (
  id, world_id, user_scope, character_id, location_id, event_id, context_type, summary, payload, freshness_score, last_used_at
)
values
  (
    'chat_incident_beat_scarlet_mist',
    'gensokyo_main',
    'global',
    null,
    null,
    null,
    'incident_beat',
    'The scarlet mist should be remembered as a disruption of ordinary daylight and public rhythm, not merely mansion theatrics.',
    jsonb_build_object(
      'incident_key', 'scarlet_mist',
      'history_ids', array['history_incident_scarlet_mist_resolution'],
      'historian_note_ids', array['historian_note_keine_scarlet_mist']
    ),
    0.84,
    now()
  ),
  (
    'chat_incident_beat_faith_shift',
    'gensokyo_main',
    'global',
    null,
    null,
    null,
    'incident_beat',
    'The mountain-faith conflict should be remembered for its continuing institutional consequences, not just the original friction.',
    jsonb_build_object(
      'incident_key', 'faith_shift',
      'history_ids', array['history_incident_mountain_faith_shift'],
      'historian_note_ids', array['historian_note_keine_faith_shift']
    ),
    0.83,
    now()
  ),
  (
    'chat_incident_beat_perfect_possession',
    'gensokyo_main',
    'global',
    null,
    null,
    null,
    'incident_beat',
    'Perfect possession should be remembered as an incident that made agency itself unreliable in public life.',
    jsonb_build_object(
      'incident_key', 'perfect_possession',
      'history_ids', array['history_incident_perfect_possession'],
      'historian_note_ids', array['historian_note_keine_perfect_possession']
    ),
    0.82,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

-- END FILE: WORLD_SEED_INCIDENT_BEATS_EXPANDED.sql

-- BEGIN FILE: WORLD_SEED_CHARACTER_ABILITIES_MOUNTAIN_HOUSEHOLD.sql
-- World seed: ability claims for mountain and household recurring cast

insert into public.world_canon_claims (
  id, world_id, subject_type, subject_id, claim_type, summary, details, source_id, confidence, priority, tags
)
values
  ('claim_ability_meiling','gensokyo_main','character','meiling','ability','Meiling is associated with martial force, bodily discipline, and threshold defense rather than abstract household planning.',jsonb_build_object('ability_theme','martial_gatekeeping'),'src_eosd','official',73,'["ability","meiling","sdm"]'::jsonb),
  ('claim_ability_momiji','gensokyo_main','character','momiji','ability','Momiji is associated with mountain patrol competence, disciplined response, and practical vigilance.',jsonb_build_object('ability_theme','patrol_and_detection'),'src_mofa','official',71,'["ability","momiji","mountain"]'::jsonb),
  ('claim_ability_hina','gensokyo_main','character','hina','ability','Hina is associated with misfortune redirection and with dangerous flow being turned aside rather than erased.',jsonb_build_object('ability_theme','misfortune_redirection'),'src_mofa','official',74,'["ability","hina","misfortune"]'::jsonb),
  ('claim_ability_minoriko','gensokyo_main','character','minoriko','ability','Minoriko is associated with harvest abundance, food, and the public enjoyment of autumn plenty.',jsonb_build_object('ability_theme','harvest_abundance'),'src_mofa','official',70,'["ability","minoriko","harvest"]'::jsonb),
  ('claim_ability_shizuha','gensokyo_main','character','shizuha','ability','Shizuha is associated with autumn leaves, decline, and the visual transition of season rather than overt command.',jsonb_build_object('ability_theme','autumn_transience'),'src_mofa','official',69,'["ability","shizuha","autumn"]'::jsonb)
on conflict (id) do update
set subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    claim_type = excluded.claim_type,
    summary = excluded.summary,
    details = excluded.details,
    source_id = excluded.source_id,
    confidence = excluded.confidence,
    priority = excluded.priority,
    tags = excluded.tags,
    updated_at = now();

-- END FILE: WORLD_SEED_CHARACTER_ABILITIES_MOUNTAIN_HOUSEHOLD.sql

-- BEGIN FILE: WORLD_SEED_WIKI_CHAT_MOUNTAIN_HOUSEHOLD.sql
-- World seed: wiki and chat support for mountain and household recurring cast

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  ('wiki_character_momiji','gensokyo_main','characters/momiji-inubashiri','Momiji Inubashiri','character','character','momiji','A wolf tengu guard who makes mountain order feel practical, patrolled, and real.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_hina','gensokyo_main','characters/hina-kagiyama','Hina Kagiyama','character','character','hina','A goddess of misfortune who frames mountain approach through warning, deflection, and dangerous flow.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_minoriko','gensokyo_main','characters/minoriko-aki','Minoriko Aki','character','character','minoriko','A harvest goddess who gives autumn abundance a public, cheerful face.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_shizuha','gensokyo_main','characters/shizuha-aki','Shizuha Aki','character','character','shizuha','An autumn goddess who gives seasonal decline and leaf-turning a quiet atmospheric form.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_region_scarlet_gate','gensokyo_main','regions/scarlet-gate','Scarlet Gate Threshold Culture','glossary','location','scarlet_gate','A culture page for visible household threshold, gatekeeping, and controlled entry at the Scarlet Devil Mansion.','published','chronicle_gensokyo_history','{}'::jsonb)
on conflict (id) do update
set slug = excluded.slug,
    title = excluded.title,
    page_type = excluded.page_type,
    subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    summary = excluded.summary,
    status = excluded.status,
    canonical_book_id = excluded.canonical_book_id,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_wiki_page_sections (
  id, page_id, section_code, section_order, heading, summary, body, source_ref_ids, metadata
)
values
  ('wiki_character_momiji:section:overview','wiki_character_momiji','overview',1,'Overview','Momiji as mountain guard.','Momiji is strongest when the mountain feels watched, patrolled, and managed through practical response instead of abstract authority alone.','["claim_momiji_mountain_guard","claim_ability_momiji"]'::jsonb,'{}'::jsonb),
  ('wiki_character_hina:section:overview','wiki_character_hina','overview',1,'Overview','Hina as misfortune redirection.','Hina is best treated as a warning-presence whose role is to catch, redirect, or embody danger along the mountain approach.','["claim_hina_mountain_warning","claim_ability_hina"]'::jsonb,'{}'::jsonb),
  ('wiki_character_minoriko:section:overview','wiki_character_minoriko','overview',1,'Overview','Minoriko as harvest abundance.','Minoriko gives autumn plenty a friendly and proudly public face, especially in harvest and food-centered scenes.','["claim_ability_minoriko"]'::jsonb,'{}'::jsonb),
  ('wiki_character_shizuha:section:overview','wiki_character_shizuha','overview',1,'Overview','Shizuha as seasonal decline.','Shizuha helps autumn feel atmospheric, elegant, and visibly in motion toward fading rather than simple abundance.','["claim_ability_shizuha"]'::jsonb,'{}'::jsonb),
  ('wiki_region_scarlet_gate:section:overview','wiki_region_scarlet_gate','overview',1,'Overview','Scarlet Gate as visible threshold.','The Scarlet Gate is where the mansion''s public face, martial confidence, and controlled entry all become legible at once.','["claim_meiling_gatekeeper","claim_ability_meiling"]'::jsonb,'{}'::jsonb)
on conflict (id) do update
set heading = excluded.heading,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_chat_context_cache (
  id, world_id, user_scope, character_id, location_id, event_id, context_type, summary, payload, freshness_score, last_used_at
)
values
  (
    'chat_voice_meiling_core',
    'gensokyo_main',
    'global',
    'meiling',
    null,
    null,
    'character_voice',
    'Meiling should sound warm and sturdy, with martial confidence that still reads as approachable rather than severe.',
    jsonb_build_object(
      'speech_style', 'casual, warm, sturdy',
      'worldview', 'A gate only matters if someone can actually hold it.',
      'claim_ids', array['claim_meiling_gatekeeper','claim_ability_meiling']
    ),
    0.86,
    now()
  ),
  (
    'chat_voice_momiji_core',
    'gensokyo_main',
    'global',
    'momiji',
    null,
    null,
    'character_voice',
    'Momiji should sound direct and professional, like duty is a route to clarity rather than self-importance.',
    jsonb_build_object(
      'speech_style', 'direct, professional, restrained',
      'worldview', 'A watched route is easier to live with than an ignored one.',
      'claim_ids', array['claim_momiji_mountain_guard','claim_ability_momiji']
    ),
    0.84,
    now()
  ),
  (
    'chat_voice_hina_core',
    'gensokyo_main',
    'global',
    'hina',
    null,
    null,
    'character_voice',
    'Hina should sound measured and distant, like danger is being handled carefully rather than dramatized.',
    jsonb_build_object(
      'speech_style', 'measured, distant, protective',
      'worldview', 'A danger redirected is still a danger worth respecting.',
      'claim_ids', array['claim_hina_mountain_warning','claim_ability_hina']
    ),
    0.84,
    now()
  ),
  (
    'chat_voice_minoriko_core',
    'gensokyo_main',
    'global',
    'minoriko',
    null,
    null,
    'character_voice',
    'Minoriko should sound friendly and proud, as if harvest ought to be noticed properly and enjoyed without apology.',
    jsonb_build_object(
      'speech_style', 'friendly, proud, rustic',
      'worldview', 'Abundance means very little if nobody celebrates it.',
      'claim_ids', array['claim_ability_minoriko']
    ),
    0.82,
    now()
  ),
  (
    'chat_voice_shizuha_core',
    'gensokyo_main',
    'global',
    'shizuha',
    null,
    null,
    'character_voice',
    'Shizuha should sound quiet and elegant, as if seasonal fading deserves as much attention as seasonal arrival.',
    jsonb_build_object(
      'speech_style', 'quiet, elegant, distant',
      'worldview', 'A season ending is not silence. It is a different kind of notice.',
      'claim_ids', array['claim_ability_shizuha']
    ),
    0.81,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

-- END FILE: WORLD_SEED_WIKI_CHAT_MOUNTAIN_HOUSEHOLD.sql

-- BEGIN FILE: WORLD_SEED_GLOSSARY_MOUNTAIN_HOUSEHOLD.sql
-- World seed: regional culture for mountain approach and mansion threshold

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_regional_mountain_approach_hazards','regional_culture','Mountain-Approach Hazard Culture','The approach to Youkai Mountain should feel like a managed danger zone shaped by warning, patrol, and uneven public access.',jsonb_build_object('location_id','youkai_mountain_foot'),'["region","mountain","hazard"]'::jsonb,77),
  ('gensokyo_main','lore_regional_scarlet_gate_threshold','regional_culture','Scarlet Gate Threshold Culture','The Scarlet Gate should read as a visible household threshold where entry becomes social performance and martial filtering at once.',jsonb_build_object('location_id','scarlet_gate'),'["region","sdm","threshold"]'::jsonb,78)
on conflict (world_id, id) do update
set category = excluded.category,
    title = excluded.title,
    summary = excluded.summary,
    details = excluded.details,
    tags = excluded.tags,
    priority = excluded.priority,
    updated_at = now();

insert into public.world_canon_claims (
  id, world_id, subject_type, subject_id, claim_type, summary, details, source_id, confidence, priority, tags
)
values
  ('claim_regional_mountain_approach_hazards','gensokyo_main','location','youkai_mountain_foot','setting','The mountain approach should be framed as managed danger through warning actors, patrols, and uneven permission.',jsonb_build_object('related_characters',array['hina','momiji','aya','nitori']),'src_mofa','official',77,'["mountain","approach","culture"]'::jsonb),
  ('claim_regional_scarlet_gate_threshold','gensokyo_main','location','scarlet_gate','setting','The Scarlet Gate is a public threshold where mansion order becomes visible through interruption, filtering, and presentation.',jsonb_build_object('related_characters',array['meiling','sakuya']),'src_eosd','official',78,'["scarlet_gate","threshold","culture"]'::jsonb)
on conflict (id) do update
set subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    claim_type = excluded.claim_type,
    summary = excluded.summary,
    details = excluded.details,
    source_id = excluded.source_id,
    confidence = excluded.confidence,
    priority = excluded.priority,
    tags = excluded.tags,
    updated_at = now();

-- END FILE: WORLD_SEED_GLOSSARY_MOUNTAIN_HOUSEHOLD.sql

-- BEGIN FILE: WORLD_SEED_BOOK_EPISODES_MOUNTAIN_HOUSEHOLD.sql
-- World seed: mountain and household scene patterns

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_book_mountain_watch_pattern','printwork_pattern','Mountain Watch Pattern','Mountain scenes are strongest when patrol, warning, rumor speed, and restricted access all reinforce each other.',jsonb_build_object('source_cluster',array['src_mofa','src_boaFW','src_ds']),'["printwork","mountain","watch"]'::jsonb,77),
  ('gensokyo_main','lore_book_sdm_threshold_pattern','printwork_pattern','Scarlet Household Threshold Pattern','Scarlet Devil Mansion scenes often become legible through gatekeeping, household presentation, and carefully staged entry.',jsonb_build_object('source_cluster',array['src_eosd','src_pmss']),'["printwork","sdm","threshold"]'::jsonb,76)
on conflict (world_id, id) do update
set category = excluded.category,
    title = excluded.title,
    summary = excluded.summary,
    details = excluded.details,
    tags = excluded.tags,
    priority = excluded.priority,
    updated_at = now();

insert into public.world_canon_claims (
  id, world_id, subject_type, subject_id, claim_type, summary, details, source_id, confidence, priority, tags
)
values
  ('claim_book_mountain_watch_pattern','gensokyo_main','printwork','mountain_watch_cluster','summary','Mountain-side stories work best when patrol, reporting, warning, and limited access all shape the scene together.',jsonb_build_object('linked_characters',array['momiji','aya','hina','nitori']),'src_boaFW','official',76,'["printwork","mountain","summary"]'::jsonb),
  ('claim_book_sdm_threshold_pattern','gensokyo_main','printwork','sdm_threshold_cluster','summary','Scarlet household scenes are strongest when thresholds, household face, and interruption matter more than raw exposition.',jsonb_build_object('linked_characters',array['meiling','sakuya','remilia']),'src_pmss','official',75,'["printwork","sdm","summary"]'::jsonb)
on conflict (id) do update
set subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    claim_type = excluded.claim_type,
    summary = excluded.summary,
    details = excluded.details,
    source_id = excluded.source_id,
    confidence = excluded.confidence,
    priority = excluded.priority,
    tags = excluded.tags,
    updated_at = now();

-- END FILE: WORLD_SEED_BOOK_EPISODES_MOUNTAIN_HOUSEHOLD.sql

-- BEGIN FILE: WORLD_SEED_CHARACTER_ABILITIES_PERFORMER_MEDIA.sql
-- World seed: performer and media-side ability claims

insert into public.world_canon_claims (
  id, world_id, subject_type, subject_id, claim_type, summary, details, source_id, confidence, priority, tags
)
values
  ('claim_ability_lunasa','gensokyo_main','character','lunasa','ability','Lunasa is associated with melancholy performance, atmosphere control, and the deeper tonal weight of ensemble music.',jsonb_build_object('ability_theme','melancholic_mood_music'),'src_pcb','official',71,'["ability","lunasa","music"]'::jsonb),
  ('claim_ability_merlin','gensokyo_main','character','merlin','ability','Merlin is associated with energetic performance that pushes a scene outward through noise, spirit, and uplift.',jsonb_build_object('ability_theme','energetic_sound_projection'),'src_pcb','official',71,'["ability","merlin","music"]'::jsonb),
  ('claim_ability_lyrica','gensokyo_main','character','lyrica','ability','Lyrica is associated with tactical arrangement, quick musical shifts, and lighter-footed stage control.',jsonb_build_object('ability_theme','quick_arrangement'),'src_pcb','official',70,'["ability","lyrica","music"]'::jsonb),
  ('claim_ability_hatate','gensokyo_main','character','hatate','ability','Hatate is associated with delayed capture, trend-reading, and a more personal style of media observation than Aya.',jsonb_build_object('ability_theme','trend_sensitive_reporting'),'src_ds','official',72,'["ability","hatate","media"]'::jsonb),
  ('claim_ability_lily_white','gensokyo_main','character','lily_white','ability','Lily White is associated with announcing spring and making seasonal transition publicly audible.',jsonb_build_object('ability_theme','spring_announcement'),'src_pcb','official',66,'["ability","lily_white","season"]'::jsonb),
  ('claim_ability_letty','gensokyo_main','character','letty','ability','Letty is associated with winter presence itself, making cold and seasonality feel like a local actor.',jsonb_build_object('ability_theme','winter_presence'),'src_pcb','official',68,'["ability","letty","winter"]'::jsonb)
on conflict (id) do update
set subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    claim_type = excluded.claim_type,
    summary = excluded.summary,
    details = excluded.details,
    source_id = excluded.source_id,
    confidence = excluded.confidence,
    priority = excluded.priority,
    tags = excluded.tags,
    updated_at = now();

-- END FILE: WORLD_SEED_CHARACTER_ABILITIES_PERFORMER_MEDIA.sql

-- BEGIN FILE: WORLD_SEED_WIKI_CHAT_PERFORMER_MEDIA.sql
-- World seed: wiki and chat support for performers, seasonal messengers, and media-side cast

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  ('wiki_character_lunasa','gensokyo_main','characters/lunasa-prismriver','Lunasa Prismriver','character','character','lunasa','A Prismriver sister whose performance gives scenes melancholy weight and refined mood.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_merlin','gensokyo_main','characters/merlin-prismriver','Merlin Prismriver','character','character','merlin','A Prismriver sister whose performance pushes scenes upward through energy and presence.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_lyrica','gensokyo_main','characters/lyrica-prismriver','Lyrica Prismriver','character','character','lyrica','A Prismriver sister whose quickness gives ensemble scenes tactical pace and brightness.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_hatate','gensokyo_main','characters/hatate-himekaidou','Hatate Himekaidou','character','character','hatate','A tengu observer whose media style is personal, delayed, and trend-sensitive rather than frontal.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_letty','gensokyo_main','characters/letty-whiterock','Letty Whiterock','character','character','letty','A winter youkai whose relevance peaks when the season itself becomes part of the story.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_lily_white','gensokyo_main','characters/lily-white','Lily White','character','character','lily_white','A spring messenger fairy whose role is to make seasonal arrival socially audible.','published','chronicle_gensokyo_history','{}'::jsonb)
on conflict (id) do update
set slug = excluded.slug,
    title = excluded.title,
    page_type = excluded.page_type,
    subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    summary = excluded.summary,
    status = excluded.status,
    canonical_book_id = excluded.canonical_book_id,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_wiki_page_sections (
  id, page_id, section_code, section_order, heading, summary, body, source_ref_ids, metadata
)
values
  ('wiki_character_lunasa:section:overview','wiki_character_lunasa','overview',1,'Overview','Lunasa as tonal weight.','Lunasa helps ensemble and event scenes carry melancholy, restraint, and deeper mood without breaking public elegance.','["claim_prismriver_ensemble","claim_ability_lunasa"]'::jsonb,'{}'::jsonb),
  ('wiki_character_merlin:section:overview','wiki_character_merlin','overview',1,'Overview','Merlin as lifted atmosphere.','Merlin gives public performance scenes force, energy, and a sense of pushed-up atmosphere.','["claim_prismriver_ensemble","claim_ability_merlin"]'::jsonb,'{}'::jsonb),
  ('wiki_character_lyrica:section:overview','wiki_character_lyrica','overview',1,'Overview','Lyrica as quick arrangement.','Lyrica makes performance scenes feel agile, tactical, and a little more mischievous than solemn.','["claim_prismriver_ensemble","claim_ability_lyrica"]'::jsonb,'{}'::jsonb),
  ('wiki_character_hatate:section:overview','wiki_character_hatate','overview',1,'Overview','Hatate as delayed media eye.','Hatate works best where information arrives through angle, delay, and personally filtered observation instead of raw speed.','["claim_hatate_trend_observer","claim_ability_hatate"]'::jsonb,'{}'::jsonb),
  ('wiki_character_letty:section:overview','wiki_character_letty','overview',1,'Overview','Letty as winter presence.','Letty matters most when winter itself should feel like an actor rather than a neutral backdrop.','["claim_ability_letty"]'::jsonb,'{}'::jsonb),
  ('wiki_character_lily_white:section:overview','wiki_character_lily_white','overview',1,'Overview','Lily White as spring announcement.','Lily White is useful as a loud and cheerful marker that seasonal transition has become publicly real.','["claim_ability_lily_white"]'::jsonb,'{}'::jsonb)
on conflict (id) do update
set heading = excluded.heading,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_chat_context_cache (
  id, world_id, user_scope, character_id, location_id, event_id, context_type, summary, payload, freshness_score, last_used_at
)
values
  (
    'chat_voice_lunasa_core',
    'gensokyo_main',
    'global',
    'lunasa',
    null,
    null,
    'character_voice',
    'Lunasa should sound restrained and melancholic, like mood is something to tune carefully rather than display loudly.',
    jsonb_build_object(
      'speech_style', 'quiet, restrained, melancholic',
      'worldview', 'A scene becomes clearer once its mood is set correctly.',
      'claim_ids', array['claim_prismriver_ensemble','claim_ability_lunasa']
    ),
    0.83,
    now()
  ),
  (
    'chat_voice_merlin_core',
    'gensokyo_main',
    'global',
    'merlin',
    null,
    null,
    'character_voice',
    'Merlin should sound lively and performative, like atmosphere is something you can push higher if you commit to it.',
    jsonb_build_object(
      'speech_style', 'lively, bold, performative',
      'worldview', 'A crowd is wasted if you do not raise it a little.',
      'claim_ids', array['claim_prismriver_ensemble','claim_ability_merlin']
    ),
    0.83,
    now()
  ),
  (
    'chat_voice_lyrica_core',
    'gensokyo_main',
    'global',
    'lyrica',
    null,
    null,
    'character_voice',
    'Lyrica should sound quick and playful, as if pacing and angle matter almost as much as the performance itself.',
    jsonb_build_object(
      'speech_style', 'quick, clever, playful',
      'worldview', 'A small change in timing can remake a whole scene.',
      'claim_ids', array['claim_prismriver_ensemble','claim_ability_lyrica']
    ),
    0.83,
    now()
  ),
  (
    'chat_voice_hatate_core',
    'gensokyo_main',
    'global',
    'hatate',
    null,
    null,
    'character_voice',
    'Hatate should sound casual and skeptical, like the shape of a story depends on when you catch it and what mood you are in.',
    jsonb_build_object(
      'speech_style', 'casual, skeptical, media-savvy',
      'worldview', 'Information is never just what happened. It is also how and when it reaches you.',
      'claim_ids', array['claim_hatate_trend_observer','claim_ability_hatate']
    ),
    0.84,
    now()
  ),
  (
    'chat_voice_letty_core',
    'gensokyo_main',
    'global',
    'letty',
    null,
    null,
    'character_voice',
    'Letty should sound calm and heavy, as if season itself is lending weight to the sentence.',
    jsonb_build_object(
      'speech_style', 'calm, heavy, seasonal',
      'worldview', 'When winter is present enough, everything else adjusts around it.',
      'claim_ids', array['claim_ability_letty']
    ),
    0.81,
    now()
  ),
  (
    'chat_voice_lily_white_core',
    'gensokyo_main',
    'global',
    'lily_white',
    null,
    null,
    'character_voice',
    'Lily White should sound bright and repetitive, like announcing spring is both message and celebration at once.',
    jsonb_build_object(
      'speech_style', 'bright, repetitive, cheerful',
      'worldview', 'A season arrives more fully once everyone hears it.',
      'claim_ids', array['claim_ability_lily_white']
    ),
    0.80,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

-- END FILE: WORLD_SEED_WIKI_CHAT_PERFORMER_MEDIA.sql

-- BEGIN FILE: WORLD_SEED_GLOSSARY_PERFORMANCE_MEDIA.sql
-- World seed: performance and media culture glossary

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_regional_public_performance','regional_culture','Public Performance Culture','Public performance in Gensokyo should feel like a real social function that shapes festivals, memory, and mood.',jsonb_build_object('focus','performance_and_festivals'),'["performance","festival","culture"]'::jsonb,77),
  ('gensokyo_main','lore_regional_tengu_media','regional_culture','Tengu Media Culture','Tengu media should be treated as a living information layer shaped by timing, angle, competition, and selective publication.',jsonb_build_object('focus','tengu_media'),'["media","tengu","culture"]'::jsonb,79)
on conflict (world_id, id) do update
set category = excluded.category,
    title = excluded.title,
    summary = excluded.summary,
    details = excluded.details,
    tags = excluded.tags,
    priority = excluded.priority,
    updated_at = now();

insert into public.world_canon_claims (
  id, world_id, subject_type, subject_id, claim_type, summary, details, source_id, confidence, priority, tags
)
values
  ('claim_regional_public_performance','gensokyo_main','world','gensokyo_main','world_rule','Performance should be treated as a social technology for mood, memory, and public gathering rather than decorative filler.',jsonb_build_object('related_characters',array['lunasa','merlin','lyrica','mystia']),'src_pcb','official',76,'["performance","culture","world_rule"]'::jsonb),
  ('claim_regional_tengu_media','gensokyo_main','faction','tengu','glossary','Tengu media culture includes both frontal reportage and more delayed, trend-sensitive observation.',jsonb_build_object('related_characters',array['aya','hatate']),'src_ds','official',78,'["media","tengu","glossary"]'::jsonb)
on conflict (id) do update
set subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    claim_type = excluded.claim_type,
    summary = excluded.summary,
    details = excluded.details,
    source_id = excluded.source_id,
    confidence = excluded.confidence,
    priority = excluded.priority,
    tags = excluded.tags,
    updated_at = now();

-- END FILE: WORLD_SEED_GLOSSARY_PERFORMANCE_MEDIA.sql

-- BEGIN FILE: WORLD_SEED_BOOK_EPISODES_PERFORMANCE_MEDIA.sql
-- World seed: performance and media-side printwork patterns

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_book_public_performance_pattern','printwork_pattern','Public Performance Pattern','Festival and performance scenes work best when music changes public mood rather than appearing as isolated ornament.',jsonb_build_object('source_cluster',array['src_pcb','src_poFV']),'["printwork","performance","public_mood"]'::jsonb,76),
  ('gensokyo_main','lore_book_split_media_pattern','printwork_pattern','Split Media Pattern','Tengu media should preserve the difference between Aya''s frontal publication logic and Hatate''s more selective, trend-sensitive angle.',jsonb_build_object('source_cluster',array['src_boaFW','src_ds','src_alt_truth']),'["printwork","media","tengu"]'::jsonb,78)
on conflict (world_id, id) do update
set category = excluded.category,
    title = excluded.title,
    summary = excluded.summary,
    details = excluded.details,
    tags = excluded.tags,
    priority = excluded.priority,
    updated_at = now();

insert into public.world_canon_claims (
  id, world_id, subject_type, subject_id, claim_type, summary, details, source_id, confidence, priority, tags
)
values
  ('claim_book_public_performance_pattern','gensokyo_main','printwork','public_performance_cluster','summary','Performance scenes are strongest when they shape gathering mood, social memory, and event atmosphere.',jsonb_build_object('linked_characters',array['lunasa','merlin','lyrica','mystia']),'src_pcb','official',75,'["printwork","performance","summary"]'::jsonb),
  ('claim_book_split_media_pattern','gensokyo_main','printwork','split_media_cluster','summary','Tengu media should preserve the contrast between immediate public framing and slower trend-sensitive interpretation.',jsonb_build_object('linked_characters',array['aya','hatate']),'src_ds','official',77,'["printwork","media","summary"]'::jsonb)
on conflict (id) do update
set subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    claim_type = excluded.claim_type,
    summary = excluded.summary,
    details = excluded.details,
    source_id = excluded.source_id,
    confidence = excluded.confidence,
    priority = excluded.priority,
    tags = excluded.tags,
    updated_at = now();

-- END FILE: WORLD_SEED_BOOK_EPISODES_PERFORMANCE_MEDIA.sql

-- BEGIN FILE: WORLD_SEED_CHAT_SEASONAL_VILLAGE.sql
-- World seed: seasonal and village-side chat context

insert into public.world_chat_context_cache (
  id, world_id, user_scope, character_id, location_id, event_id, context_type, summary, payload, freshness_score, last_used_at
)
values
  (
    'chat_location_harvest_village',
    'gensokyo_main',
    'global',
    null,
    'human_village',
    null,
    'seasonal_location',
    'In harvest-season scenes, the Human Village should feel fed, social, and publicly aware of abundance.',
    jsonb_build_object(
      'season', 'autumn',
      'claim_ids', array['claim_ability_minoriko','claim_regional_village_night_life'],
      'character_ids', array['minoriko','shizuha','akyuu','keine']
    ),
    0.82,
    now()
  ),
  (
    'chat_location_spring_announcement',
    'gensokyo_main',
    'global',
    null,
    'hakurei_shrine',
    null,
    'seasonal_location',
    'In early spring scenes, Hakurei Shrine should feel noisy with announcement, fairy-scale motion, and visible seasonal change.',
    jsonb_build_object(
      'season', 'spring',
      'claim_ids', array['claim_ability_lily_white','claim_regional_shrine_fairy_life'],
      'character_ids', array['lily_white','sunny_milk','luna_child','star_sapphire']
    ),
    0.81,
    now()
  ),
  (
    'chat_location_winter_presence',
    'gensokyo_main',
    'global',
    null,
    'misty_lake',
    null,
    'seasonal_location',
    'Winter scenes at Misty Lake should feel heavy, present, and a little slower, as if cold itself has become a local actor.',
    jsonb_build_object(
      'season', 'winter',
      'claim_ids', array['claim_ability_letty'],
      'character_ids', array['letty','cirno','wakasagihime']
    ),
    0.80,
    now()
  ),
  (
    'chat_location_night_food_music',
    'gensokyo_main',
    'global',
    null,
    'human_village',
    null,
    'location_mood',
    'At night, the village edge should support food, song, tavern warmth, rumor, and low-grade danger all at once.',
    jsonb_build_object(
      'time_of_day', 'night',
      'claim_ids', array['claim_regional_village_night_life','claim_mystia_night_vendor','claim_miyoi_night_hospitality'],
      'character_ids', array['mystia','miyoi','wriggle']
    ),
    0.85,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

-- END FILE: WORLD_SEED_CHAT_SEASONAL_VILLAGE.sql

-- BEGIN FILE: WORLD_SEED_INCIDENT_MINOR_TEXTURES.sql
-- World seed: minor incident textures and recurrent local trouble

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_minor_incident_fairy_pranks','incident_pattern','Fairy Prank Pattern','Fairy trouble should register as recurring low-stakes disruption that proves daily life is still in motion between larger incidents.',jsonb_build_object('scale','minor'),'["incident","fairy","minor"]'::jsonb,73),
  ('gensokyo_main','lore_minor_incident_night_detours','incident_pattern','Night Detour Pattern','Nighttime trouble in Gensokyo should often take the form of detours, songs, stalls, darkness, and manageable local danger rather than full crisis.',jsonb_build_object('scale','minor'),'["incident","night","minor"]'::jsonb,74),
  ('gensokyo_main','lore_minor_incident_text_circulation','incident_pattern','Text Circulation Pattern','Books, articles, and records can create small incidents by changing what people know, fear, or try to test.',jsonb_build_object('scale','minor'),'["incident","books","knowledge"]'::jsonb,75)
on conflict (world_id, id) do update
set category = excluded.category,
    title = excluded.title,
    summary = excluded.summary,
    details = excluded.details,
    tags = excluded.tags,
    priority = excluded.priority,
    updated_at = now();

insert into public.world_story_events (
  id, world_id, event_code, title, theme, canon_level, status,
  start_at, end_at, current_phase_id, current_phase_order,
  lead_location_id, organizer_character_id, synopsis, narrative_hook, payload, metadata
)
values
  (
    'story_minor_fairy_pranks_archive',
    'gensokyo_main',
    'minor_fairy_pranks_archive',
    'Minor Fairy Pranks Archive',
    'Archival record for recurring fairy pranks around shrines and village edges.',
    'official',
    'resolved',
    null,
    null,
    null,
    null,
    'hakurei_shrine',
    'cirno',
    'An archival event container for recurring fairy-prank texture.',
    'Used to anchor world_story_history records for later chat and chronicle lookup.',
    jsonb_build_object('incident_key','minor_fairy_pranks','archive',true),
    '{}'::jsonb
  ),
  (
    'story_minor_night_detours_archive',
    'gensokyo_main',
    'minor_night_detours_archive',
    'Minor Night Detours Archive',
    'Archival record for night detours, songs, roadside trade, and manageable nocturnal trouble.',
    'official',
    'resolved',
    null,
    null,
    null,
    null,
    'human_village',
    'mystia',
    'An archival event container for recurring night-detour texture.',
    'Used to anchor world_story_history records for later chat and chronicle lookup.',
    jsonb_build_object('incident_key','minor_night_detours','archive',true),
    '{}'::jsonb
  ),
  (
    'story_minor_text_circulation_archive',
    'gensokyo_main',
    'minor_text_circulation_archive',
    'Minor Text Circulation Archive',
    'Archival record for incidents created by books, articles, and circulating records.',
    'official',
    'resolved',
    null,
    null,
    null,
    null,
    'suzunaan',
    'akyuu',
    'An archival event container for recurring text-circulation texture.',
    'Used to anchor world_story_history records for later chat and chronicle lookup.',
    jsonb_build_object('incident_key','minor_text_circulation','archive',true),
    '{}'::jsonb
  )
on conflict (id) do update
set event_code = excluded.event_code,
    title = excluded.title,
    theme = excluded.theme,
    canon_level = excluded.canon_level,
    status = excluded.status,
    start_at = excluded.start_at,
    end_at = excluded.end_at,
    current_phase_id = excluded.current_phase_id,
    current_phase_order = excluded.current_phase_order,
    lead_location_id = excluded.lead_location_id,
    organizer_character_id = excluded.organizer_character_id,
    synopsis = excluded.synopsis,
    narrative_hook = excluded.narrative_hook,
    payload = excluded.payload,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_story_history (
  id, world_id, event_id, phase_id, history_kind, fact_summary, location_id, actor_ids, payload, committed_at
)
values
  (
    'history_minor_fairy_pranks',
    'gensokyo_main',
    'story_minor_fairy_pranks_archive',
    null,
    'texture',
    'Recurring fairy pranks around shrines and village edges should be remembered as part of ordinary Gensokyo life rather than as failed major incidents.',
    'hakurei_shrine',
    '["sunny_milk","luna_child","star_sapphire","cirno"]'::jsonb,
    jsonb_build_object(
      'incident_key','minor_fairy_pranks',
      'beat','daily_life_disruption',
      'affected_locations','["hakurei_shrine","human_village"]'::jsonb
    ),
    now()
  ),
  (
    'history_minor_night_detours',
    'gensokyo_main',
    'story_minor_night_detours_archive',
    null,
    'texture',
    'Night detours created by song, darkness, luck, and roadside commerce should be treated as lived texture rather than empty filler.',
    'human_village',
    '["mystia","rumia","tewi","miyoi","wriggle"]'::jsonb,
    jsonb_build_object(
      'incident_key','minor_night_detours',
      'beat','night_texture',
      'affected_locations','["human_village","misty_lake","bamboo_forest"]'::jsonb
    ),
    now()
  ),
  (
    'history_minor_text_circulation',
    'gensokyo_main',
    'story_minor_text_circulation_archive',
    null,
    'texture',
    'Text circulation through shops, libraries, and articles repeatedly changes local behavior without becoming world-ending crisis.',
    'suzunaan',
    '["kosuzu","akyuu","rinnosuke","aya","hatate"]'::jsonb,
    jsonb_build_object(
      'incident_key','minor_text_circulation',
      'beat','knowledge_disturbance',
      'affected_locations','["suzunaan","kourindou","human_village"]'::jsonb
    ),
    now()
  )
on conflict (id) do update
set history_kind = excluded.history_kind,
    fact_summary = excluded.fact_summary,
    location_id = excluded.location_id,
    actor_ids = excluded.actor_ids,
    payload = excluded.payload,
    committed_at = excluded.committed_at;

insert into public.world_historian_notes (
  id, world_id, historian_character_id, subject_type, subject_id, note_kind, title, summary, body, source_ref_ids, metadata
)
values
  (
    'historian_note_keine_minor_pranks',
    'gensokyo_main',
    'keine',
    'incident',
    'minor_fairy_pranks',
    'editorial',
    'On Fairy Pranks as Continuity',
    'A note on why minor prank cycles matter to historical texture.',
    'A village or shrine without recurring irritation would be easier to organize, but also less recognizably alive. Fairy pranks matter to history because they prove continuity at a scale beneath formal crisis.',
    '["history_minor_fairy_pranks","lore_minor_incident_fairy_pranks"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'historian_note_akyuu_text_circulation',
    'gensokyo_main',
    'akyuu',
    'incident',
    'minor_text_circulation',
    'editorial',
    'On Small Incidents Created by Reading',
    'A note on written material as a repeated source of disturbance.',
    'Records and books do not merely preserve events. They also cause them, especially when curiosity, rumor, or half-understood knowledge begins circulating faster than caution.',
    '["history_minor_text_circulation","lore_minor_incident_text_circulation"]'::jsonb,
    '{}'::jsonb
  )
on conflict (id) do update
set note_kind = excluded.note_kind,
    title = excluded.title,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();

-- END FILE: WORLD_SEED_INCIDENT_MINOR_TEXTURES.sql

-- BEGIN FILE: WORLD_SEED_WIKI_MINOR_TEXTURES.sql
-- World seed: wiki pages for small-scale world texture

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  ('wiki_term_minor_incidents','gensokyo_main','terms/minor-incidents','Minor Incidents','glossary','term','minor_incidents','A glossary page for recurring local disturbances that fall below full incident scale.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_term_night_detours','gensokyo_main','terms/night-detours','Night Detours','glossary','term','night_detours','A glossary page for the songs, stalls, darkness, and luck-based trouble that shape Gensokyo after dark.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_term_text_circulation','gensokyo_main','terms/text-circulation','Text Circulation','glossary','term','text_circulation','A glossary page for books, reports, and records as causes of small-scale disturbance.','published','chronicle_gensokyo_history','{}'::jsonb)
on conflict (id) do update
set slug = excluded.slug,
    title = excluded.title,
    page_type = excluded.page_type,
    subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    summary = excluded.summary,
    status = excluded.status,
    canonical_book_id = excluded.canonical_book_id,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_wiki_page_sections (
  id, page_id, section_code, section_order, heading, summary, body, source_ref_ids, metadata
)
values
  ('wiki_term_minor_incidents:section:definition','wiki_term_minor_incidents','definition',1,'Definition','Minor incidents as world texture.','Minor incidents are recurring disruptions that never become full-scale crises but still shape memory, habit, and local caution.', '["lore_minor_incident_fairy_pranks","history_minor_fairy_pranks"]'::jsonb,'{}'::jsonb),
  ('wiki_term_night_detours:section:definition','wiki_term_night_detours','definition',1,'Definition','Night detours as lived after-dark structure.','Night detours are created by song, darkness, trade, rumor, and luck; they make after-dark Gensokyo a space of managed uncertainty rather than emptiness.', '["lore_minor_incident_night_detours","history_minor_night_detours"]'::jsonb,'{}'::jsonb),
  ('wiki_term_text_circulation:section:definition','wiki_term_text_circulation','definition',1,'Definition','Text circulation as disturbance.','Texts, records, and articles create disturbance by changing what people know and what they think is worth testing, fearing, or retelling.', '["lore_minor_incident_text_circulation","history_minor_text_circulation"]'::jsonb,'{}'::jsonb)
on conflict (id) do update
set heading = excluded.heading,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();

-- END FILE: WORLD_SEED_WIKI_MINOR_TEXTURES.sql

-- BEGIN FILE: WORLD_SEED_CHARACTER_ABILITIES_PRINTWORK_EXTENDED.sql
-- World seed: extended printwork-side ability claims

insert into public.world_canon_claims (
  id, world_id, subject_type, subject_id, claim_type, summary, details, source_id, confidence, priority, tags
)
values
  ('claim_ability_rinnosuke','gensokyo_main','character','rinnosuke','ability','Rinnosuke is associated with object reading, detached interpretation, and insight through material culture rather than force.',jsonb_build_object('ability_theme','object_interpretation'),'src_lotus_asia','official',79,'["ability","rinnosuke","objects"]'::jsonb),
  ('claim_ability_kosuzu','gensokyo_main','character','kosuzu','ability','Kosuzu is associated with dangerous reading, textual curiosity, and the way books can activate trouble by being handled.',jsonb_build_object('ability_theme','dangerous_reading'),'src_fs','official',77,'["ability","kosuzu","books"]'::jsonb),
  ('claim_ability_sumireko','gensokyo_main','character','sumireko','ability','Sumireko is associated with psychic force, occult framing, and youthful overreach linked to outside-world rumors.',jsonb_build_object('ability_theme','psychic_occult_pressure'),'src_ulil','official',76,'["ability","sumireko","occult"]'::jsonb),
  ('claim_ability_joon','gensokyo_main','character','joon','ability','Joon is associated with conspicuous appetite, glamour, and extractive social movement.',jsonb_build_object('ability_theme','glamour_and_extraction'),'src_aocf','official',73,'["ability","joon","glamour"]'::jsonb),
  ('claim_ability_shion','gensokyo_main','character','shion','ability','Shion is associated with visible depletion, misfortune, and the social atmosphere of things going wrong by contact.',jsonb_build_object('ability_theme','misfortune_contagion'),'src_aocf','official',74,'["ability","shion","misfortune"]'::jsonb)
on conflict (id) do update
set subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    claim_type = excluded.claim_type,
    summary = excluded.summary,
    details = excluded.details,
    source_id = excluded.source_id,
    confidence = excluded.confidence,
    priority = excluded.priority,
    tags = excluded.tags,
    updated_at = now();

-- END FILE: WORLD_SEED_CHARACTER_ABILITIES_PRINTWORK_EXTENDED.sql

-- BEGIN FILE: WORLD_SEED_WIKI_CHAT_PRINTWORK_EXTENDED.sql
-- World seed: extended wiki and chat support for printwork-side cast

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  ('wiki_character_kosuzu','gensokyo_main','characters/kosuzu-motoori','Kosuzu Motoori','character','character','kosuzu','A bookseller-curator whose curiosity turns texts into active local trouble.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_joon','gensokyo_main','characters/joon-yorigami','Joon Yorigami','character','character','joon','A goddess of glamorous social drain who makes misfortune arrive looking attractive first.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_shion','gensokyo_main','characters/shion-yorigami','Shion Yorigami','character','character','shion','A goddess of poverty whose presence turns depletion and avoidance into visible social atmosphere.','published','chronicle_gensokyo_history','{}'::jsonb)
on conflict (id) do update
set slug = excluded.slug,
    title = excluded.title,
    page_type = excluded.page_type,
    subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    summary = excluded.summary,
    status = excluded.status,
    canonical_book_id = excluded.canonical_book_id,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_wiki_page_sections (
  id, page_id, section_code, section_order, heading, summary, body, source_ref_ids, metadata
)
values
  ('wiki_character_kosuzu:section:overview','wiki_character_kosuzu','overview',1,'Overview','Kosuzu as dangerous reader.','Kosuzu is most useful when books are not static props but active carriers of curiosity, misunderstanding, and low-scale danger.', '["claim_kosuzu_book_curator","claim_ability_kosuzu"]'::jsonb,'{}'::jsonb),
  ('wiki_character_joon:section:overview','wiki_character_joon','overview',1,'Overview','Joon as glamorous drain.','Joon should be framed through appetite, display, and the attractive surface of social depletion.', '["claim_joon_social_drain","claim_ability_joon"]'::jsonb,'{}'::jsonb),
  ('wiki_character_shion:section:overview','wiki_character_shion','overview',1,'Overview','Shion as social misfortune.','Shion is strongest where bad luck, depletion, and avoidance become visible in the shape of everyday relations.', '["claim_shion_misfortune","claim_ability_shion"]'::jsonb,'{}'::jsonb)
on conflict (id) do update
set heading = excluded.heading,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_chat_context_cache (
  id, world_id, user_scope, character_id, location_id, event_id, context_type, summary, payload, freshness_score, last_used_at
)
values
  (
    'chat_voice_rinnosuke_core',
    'gensokyo_main',
    'global',
    'rinnosuke',
    null,
    null,
    'character_voice',
    'Rinnosuke should sound calm and dry, like objects are usually more revealing than the people carrying them.',
    jsonb_build_object(
      'speech_style', 'calm, reflective, dry',
      'worldview', 'Things are easier to understand once you stop assuming they are ordinary.',
      'claim_ids', array['claim_rinnosuke_object_interpreter','claim_ability_rinnosuke']
    ),
    0.86,
    now()
  ),
  (
    'chat_voice_kosuzu_core',
    'gensokyo_main',
    'global',
    'kosuzu',
    null,
    null,
    'character_voice',
    'Kosuzu should sound curious and bright, with the sense that opening the book is always half the temptation.',
    jsonb_build_object(
      'speech_style', 'curious, earnest, bright',
      'worldview', 'A book closed safely is still less interesting than one partly understood.',
      'claim_ids', array['claim_kosuzu_book_curator','claim_ability_kosuzu']
    ),
    0.85,
    now()
  ),
  (
    'chat_voice_joon_core',
    'gensokyo_main',
    'global',
    'joon',
    null,
    null,
    'character_voice',
    'Joon should sound breezy and showy, like the cost of indulgence is always somebody else''s problem for a little while.',
    jsonb_build_object(
      'speech_style', 'showy, greedy, breezy',
      'worldview', 'If the desire is already there, all you have to do is help it spend itself.',
      'claim_ids', array['claim_joon_social_drain','claim_ability_joon']
    ),
    0.83,
    now()
  ),
  (
    'chat_voice_shion_core',
    'gensokyo_main',
    'global',
    'shion',
    null,
    null,
    'character_voice',
    'Shion should sound weak and resigned, but not empty; the sentence should still feel like misfortune has weight to it.',
    jsonb_build_object(
      'speech_style', 'weak, resigned, plain',
      'worldview', 'Bad luck does not need drama to be real. It only needs to remain nearby.',
      'claim_ids', array['claim_shion_misfortune','claim_ability_shion']
    ),
    0.82,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

-- END FILE: WORLD_SEED_WIKI_CHAT_PRINTWORK_EXTENDED.sql

-- BEGIN FILE: WORLD_SEED_GLOSSARY_RECORDS_BOUNDARIES.sql
-- World seed: records, books, and boundary-adjacent glossary

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_term_record_culture','term','Record Culture','Record culture in Gensokyo is active infrastructure: memory, authority, rumor correction, and future misunderstanding all pass through it.',jsonb_build_object('domain','records_and_memory'),'["term","records","culture"]'::jsonb,82),
  ('gensokyo_main','lore_term_book_circulation','term','Book Circulation','Book circulation should be treated as both a learning system and a repeated source of disturbance.',jsonb_build_object('domain','texts_and_readers'),'["term","books","circulation"]'::jsonb,80),
  ('gensokyo_main','lore_term_boundary_spots','term','Boundary Spots','Boundary-adjacent places in Gensokyo are strongest when they feel like leakage points rather than clean portals.',jsonb_build_object('domain','boundary_topology'),'["term","boundaries","locations"]'::jsonb,79)
on conflict (world_id, id) do update
set category = excluded.category,
    title = excluded.title,
    summary = excluded.summary,
    details = excluded.details,
    tags = excluded.tags,
    priority = excluded.priority,
    updated_at = now();

insert into public.world_canon_claims (
  id, world_id, subject_type, subject_id, claim_type, summary, details, source_id, confidence, priority, tags
)
values
  ('claim_term_record_culture','gensokyo_main','term','record_culture','definition','Records in Gensokyo are part of how continuity, authority, and correction are maintained, not merely archival leftovers.',jsonb_build_object('related_characters',array['akyuu','keine','kosuzu']),'src_sixty_years','official',83,'["term","records","definition"]'::jsonb),
  ('claim_term_book_circulation','gensokyo_main','term','book_circulation','definition','Books and written materials circulate as knowledge, temptation, and small-scale hazard all at once.',jsonb_build_object('related_locations',array['suzunaan','kourindou','human_village']),'src_fs','official',81,'["term","books","definition"]'::jsonb),
  ('claim_term_boundary_spots','gensokyo_main','term','boundary_spots','definition','Boundary-adjacent places should be treated as unstable leakage points where stories, objects, and explanations can cross imperfectly.',jsonb_build_object('related_locations',array['muenzuka','hakurei_shrine']),'src_ulil','official',79,'["term","boundaries","definition"]'::jsonb)
on conflict (id) do update
set subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    claim_type = excluded.claim_type,
    summary = excluded.summary,
    details = excluded.details,
    source_id = excluded.source_id,
    confidence = excluded.confidence,
    priority = excluded.priority,
    tags = excluded.tags,
    updated_at = now();

-- END FILE: WORLD_SEED_GLOSSARY_RECORDS_BOUNDARIES.sql

-- BEGIN FILE: WORLD_SEED_WIKI_RECORDS_BOUNDARIES.sql
-- World seed: wiki pages for records, books, and boundary spots

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  ('wiki_term_record_culture','gensokyo_main','terms/record-culture','Record Culture','glossary','term','record_culture','A glossary page for records as active social infrastructure in Gensokyo.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_term_book_circulation','gensokyo_main','terms/book-circulation','Book Circulation','glossary','term','book_circulation','A glossary page for books as both education and recurring disturbance.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_term_boundary_spots','gensokyo_main','terms/boundary-spots','Boundary Spots','glossary','term','boundary_spots','A glossary page for leakage-prone places where outside influence and narrative slippage enter Gensokyo.','published','chronicle_gensokyo_history','{}'::jsonb)
on conflict (id) do update
set slug = excluded.slug,
    title = excluded.title,
    page_type = excluded.page_type,
    subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    summary = excluded.summary,
    status = excluded.status,
    canonical_book_id = excluded.canonical_book_id,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_wiki_page_sections (
  id, page_id, section_code, section_order, heading, summary, body, source_ref_ids, metadata
)
values
  ('wiki_term_record_culture:section:definition','wiki_term_record_culture','definition',1,'Definition','Records as social infrastructure.','Record culture in Gensokyo supports memory, correction, authority, and the ability to argue about what actually happened.', '["claim_term_record_culture","lore_term_record_culture"]'::jsonb,'{}'::jsonb),
  ('wiki_term_book_circulation:section:definition','wiki_term_book_circulation','definition',1,'Definition','Books as circulation and hazard.','Book circulation educates people, tempts them, and repeatedly creates low-scale incidents by moving half-understood knowledge between hands.', '["claim_term_book_circulation","lore_term_book_circulation"]'::jsonb,'{}'::jsonb),
  ('wiki_term_boundary_spots:section:definition','wiki_term_boundary_spots','definition',1,'Definition','Boundary spots as leakage points.','Boundary spots should feel porous, imperfect, and narratively unstable rather than functioning like tidy doors.', '["claim_term_boundary_spots","lore_term_boundary_spots"]'::jsonb,'{}'::jsonb)
on conflict (id) do update
set heading = excluded.heading,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();

-- END FILE: WORLD_SEED_WIKI_RECORDS_BOUNDARIES.sql

-- BEGIN FILE: WORLD_SEED_CHAT_LATE_MAINLINE_VOICES.sql
-- World seed: late-mainline character voice cache

insert into public.world_chat_context_cache (
  id, world_id, user_scope, character_id, location_id, event_id, context_type, summary, payload, freshness_score, last_used_at
)
values
  (
    'chat_voice_okina_core',
    'gensokyo_main',
    'global',
    'okina',
    null,
    null,
    'character_voice',
    'Okina should sound composed and faintly theatrical, as if access itself is something she curates from offstage.',
    jsonb_build_object(
      'speech_style', 'composed, theatrical, knowing',
      'worldview', 'A closed route only matters if you know which hidden one is still available.',
      'claim_ids', array['claim_ability_okina']
    ),
    0.87,
    now()
  ),
  (
    'chat_voice_yachie_core',
    'gensokyo_main',
    'global',
    'yachie',
    null,
    null,
    'character_voice',
    'Yachie should sound calm and strategic, like leverage is always being measured even during casual speech.',
    jsonb_build_object(
      'speech_style', 'calm, strategic, controlled',
      'worldview', 'A direct clash is usually just proof that subtler leverage was ignored first.',
      'claim_ids', array['claim_ability_yachie']
    ),
    0.86,
    now()
  ),
  (
    'chat_voice_keiki_core',
    'gensokyo_main',
    'global',
    'keiki',
    null,
    null,
    'character_voice',
    'Keiki should sound constructive and firm, like creation is a deliberate answer to predatory pressure.',
    jsonb_build_object(
      'speech_style', 'firm, constructive, precise',
      'worldview', 'When a world is shaped badly enough, making a counter-form is its own defense.',
      'claim_ids', array['claim_ability_keiki']
    ),
    0.85,
    now()
  ),
  (
    'chat_voice_chimata_core',
    'gensokyo_main',
    'global',
    'chimata',
    null,
    null,
    'character_voice',
    'Chimata should sound poised and transactional, as if value, ownership, and circulation are visible from every angle.',
    jsonb_build_object(
      'speech_style', 'poised, transactional, elegant',
      'worldview', 'What circulates reveals a society as clearly as what it forbids.',
      'claim_ids', array['claim_ability_chimata']
    ),
    0.85,
    now()
  ),
  (
    'chat_voice_takane_market_core',
    'gensokyo_main',
    'global',
    'takane',
    null,
    null,
    'character_voice',
    'Takane should sound practical and commercially alert, like every route and exchange can still be optimized.',
    jsonb_build_object(
      'speech_style', 'practical, alert, commercial',
      'worldview', 'A route becomes useful only once someone knows how to trade through it.',
      'claim_ids', array['claim_ability_takane']
    ),
    0.84,
    now()
  ),
  (
    'chat_voice_tsukasa_core',
    'gensokyo_main',
    'global',
    'tsukasa',
    null,
    null,
    'character_voice',
    'Tsukasa should sound cute and slippery, with manipulation tucked inside plausible smallness.',
    jsonb_build_object(
      'speech_style', 'cute, slippery, manipulative',
      'worldview', 'If people underestimate something small enough, the work is half done already.',
      'claim_ids', array['claim_tsukasa_fox_broker']
    ),
    0.83,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

-- END FILE: WORLD_SEED_CHAT_LATE_MAINLINE_VOICES.sql

-- BEGIN FILE: WORLD_SEED_GLOSSARY_LATE_SYSTEMS.sql
-- World seed: late-mainline political and market systems glossary

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_term_hidden_seasons','term','Hidden Seasons','Hidden seasons should be treated as latent power layers revealed through selective access rather than weather alone.',jsonb_build_object('domain','seasonal_hidden_power'),'["term","hidden_seasons","hsifs"]'::jsonb,78),
  ('gensokyo_main','lore_term_beast_realm_politics','term','Beast Realm Politics','The Beast Realm should read as factional power struggle, proxy conflict, and organized predation rather than simple chaos.',jsonb_build_object('domain','beast_realm_governance'),'["term","beast_realm","politics"]'::jsonb,80),
  ('gensokyo_main','lore_term_market_competition','term','Market Competition','Market competition in Gensokyo should be understood as a struggle over routes, value, ownership, and circulation of power itself.',jsonb_build_object('domain','market_systems'),'["term","market","competition"]'::jsonb,80)
on conflict (world_id, id) do update
set category = excluded.category,
    title = excluded.title,
    summary = excluded.summary,
    details = excluded.details,
    tags = excluded.tags,
    priority = excluded.priority,
    updated_at = now();

insert into public.world_canon_claims (
  id, world_id, subject_type, subject_id, claim_type, summary, details, source_id, confidence, priority, tags
)
values
  ('claim_term_hidden_seasons','gensokyo_main','term','hidden_seasons','definition','Hidden seasons are best read as selective latent power revealed through access and orchestration rather than surface climate alone.',jsonb_build_object('related_characters',array['okina','satono','mai']),'src_hsifs','official',78,'["term","hidden_seasons","definition"]'::jsonb),
  ('claim_term_beast_realm_politics','gensokyo_main','term','beast_realm_politics','definition','Beast Realm politics are structured by factional rivalry, proxy struggle, and predatory strategy rather than mere savagery.',jsonb_build_object('related_characters',array['yachie','saki','keiki']),'src_wbawc','official',80,'["term","beast_realm","definition"]'::jsonb),
  ('claim_term_market_competition','gensokyo_main','term','market_competition','definition','Market competition in Gensokyo concerns ownership, routes, cards, and the circulation of useful power.',jsonb_build_object('related_characters',array['chimata','takane','tsukasa','mike']),'src_um','official',80,'["term","market","definition"]'::jsonb)
on conflict (id) do update
set subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    claim_type = excluded.claim_type,
    summary = excluded.summary,
    details = excluded.details,
    source_id = excluded.source_id,
    confidence = excluded.confidence,
    priority = excluded.priority,
    tags = excluded.tags,
    updated_at = now();

-- END FILE: WORLD_SEED_GLOSSARY_LATE_SYSTEMS.sql

-- BEGIN FILE: WORLD_SEED_WIKI_LATE_SYSTEMS.sql
-- World seed: wiki support for late-mainline system terms

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  ('wiki_term_hidden_seasons','gensokyo_main','terms/hidden-seasons','Hidden Seasons','glossary','term','hidden_seasons','A glossary page for selective seasonal power and hidden access layers.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_term_beast_realm_politics','gensokyo_main','terms/beast-realm-politics','Beast Realm Politics','glossary','term','beast_realm_politics','A glossary page for factional rivalry and proxy conflict in the Beast Realm.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_term_market_competition','gensokyo_main','terms/market-competition','Market Competition','glossary','term','market_competition','A glossary page for routes, ownership, and value competition around cards and exchange.','published','chronicle_gensokyo_history','{}'::jsonb)
on conflict (id) do update
set slug = excluded.slug,
    title = excluded.title,
    page_type = excluded.page_type,
    subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    summary = excluded.summary,
    status = excluded.status,
    canonical_book_id = excluded.canonical_book_id,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_wiki_page_sections (
  id, page_id, section_code, section_order, heading, summary, body, source_ref_ids, metadata
)
values
  ('wiki_term_hidden_seasons:section:definition','wiki_term_hidden_seasons','definition',1,'Definition','Hidden seasons as latent power layers.','Hidden seasons work as selectively revealed power layers linked to access, orchestration, and offstage control rather than plain seasonal weather.', '["claim_term_hidden_seasons","lore_term_hidden_seasons"]'::jsonb,'{}'::jsonb),
  ('wiki_term_beast_realm_politics:section:definition','wiki_term_beast_realm_politics','definition',1,'Definition','Beast Realm as factional politics.','The Beast Realm should be read through organized rivalry, proxy struggle, and strategic predation rather than undifferentiated chaos.', '["claim_term_beast_realm_politics","lore_term_beast_realm_politics"]'::jsonb,'{}'::jsonb),
  ('wiki_term_market_competition:section:definition','wiki_term_market_competition','definition',1,'Definition','Market competition as power circulation.','Market competition in Gensokyo concerns ownership, value, routes, and the circulation of useful power, not just ordinary commerce.', '["claim_term_market_competition","lore_term_market_competition"]'::jsonb,'{}'::jsonb)
on conflict (id) do update
set heading = excluded.heading,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();

-- END FILE: WORLD_SEED_WIKI_LATE_SYSTEMS.sql

-- BEGIN FILE: WORLD_SEED_CHARACTER_ABILITIES_LATE_SUPPORT.sql
-- World seed: additional late-mainline support-cast ability claims

insert into public.world_canon_claims (
  id, world_id, subject_type, subject_id, claim_type, summary, details, source_id, confidence, priority, tags
)
values
  ('claim_ability_nazrin','gensokyo_main','character','nazrin','ability','Nazrin is associated with finding, dowsing, and practical clue-tracking under field conditions.',jsonb_build_object('ability_theme','search_and_dowsing'),'src_ufo','official',72,'["ability","nazrin","ufo"]'::jsonb),
  ('claim_ability_kogasa','gensokyo_main','character','kogasa','ability','Kogasa is associated with surprise, emotional startle, and the awkward persistence of wanting to be noticed.',jsonb_build_object('ability_theme','surprise'),'src_ufo','official',69,'["ability","kogasa","ufo"]'::jsonb),
  ('claim_ability_murasa','gensokyo_main','character','murasa','ability','Murasa is associated with dangerous invitation, navigation, and the pull of being lured off stable ground.',jsonb_build_object('ability_theme','watery_navigation_and_lure'),'src_ufo','official',72,'["ability","murasa","ufo"]'::jsonb),
  ('claim_ability_nue','gensokyo_main','character','nue','ability','Nue is associated with unstable identification and the inability to settle cleanly on what is being perceived.',jsonb_build_object('ability_theme','undefined_identity'),'src_ufo','official',75,'["ability","nue","ufo"]'::jsonb),
  ('claim_ability_seiga','gensokyo_main','character','seiga','ability','Seiga is associated with intrusion, selfish immortality logic, and the smooth crossing of boundaries she should not respect.',jsonb_build_object('ability_theme','intrusion_and_hermit_corruption'),'src_td','official',74,'["ability","seiga","td"]'::jsonb),
  ('claim_ability_futo','gensokyo_main','character','futo','ability','Futo is associated with ritual flame, old-style rhetoric, and theatrical Taoist certainty.',jsonb_build_object('ability_theme','ritual_and_flame'),'src_td','official',71,'["ability","futo","td"]'::jsonb),
  ('claim_ability_tojiko','gensokyo_main','character','tojiko','ability','Tojiko is associated with storm-like force and spectral irritation tightly bound to retained station.',jsonb_build_object('ability_theme','storm_spirit_force'),'src_td','official',70,'["ability","tojiko","td"]'::jsonb),
  ('claim_ability_narumi','gensokyo_main','character','narumi','ability','Narumi is associated with grounded guardian force, statuesque stability, and local spiritual defense.',jsonb_build_object('ability_theme','grounded_guardianship'),'src_hsifs','official',69,'["ability","narumi","hsifs"]'::jsonb),
  ('claim_ability_saki','gensokyo_main','character','saki','ability','Saki is associated with speed, predatory pressure, and factional leadership through aggressive forward motion.',jsonb_build_object('ability_theme','predatory_speed'),'src_wbawc','official',74,'["ability","saki","wbawc"]'::jsonb),
  ('claim_ability_misumaru','gensokyo_main','character','misumaru','ability','Misumaru is associated with careful craft, orb-making, and support through precise constructive work.',jsonb_build_object('ability_theme','craft_and_orb_creation'),'src_um','official',72,'["ability","misumaru","um"]'::jsonb),
  ('claim_ability_momoyo','gensokyo_main','character','momoyo','ability','Momoyo is associated with mining, subterranean appetite, and the force needed to extract hidden value from mountain depth.',jsonb_build_object('ability_theme','mining_and_extraction'),'src_um','official',72,'["ability","momoyo","um"]'::jsonb),
  ('claim_ability_megumu','gensokyo_main','character','megumu','ability','Megumu is associated with elevated mountain authority, command scale, and institutional tengu management.',jsonb_build_object('ability_theme','institutional_authority'),'src_um','official',74,'["ability","megumu","um"]'::jsonb),
  ('claim_ability_mike','gensokyo_main','character','mike','ability','Mike is associated with luck, beckoning commerce, and small-scale prosperity cues in everyday trade.',jsonb_build_object('ability_theme','luck_and_small_trade'),'src_um','official',69,'["ability","mike","um"]'::jsonb),
  ('claim_ability_aunn','gensokyo_main','character','aunn','ability','Aunn is associated with shrine guardianship, warm vigilance, and local sacred-space defense.',jsonb_build_object('ability_theme','guardian_vigilance'),'src_hsifs','official',71,'["ability","aunn","hsifs"]'::jsonb)
on conflict (id) do update
set subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    claim_type = excluded.claim_type,
    summary = excluded.summary,
    details = excluded.details,
    source_id = excluded.source_id,
    confidence = excluded.confidence,
    priority = excluded.priority,
    tags = excluded.tags,
    updated_at = now();

-- END FILE: WORLD_SEED_CHARACTER_ABILITIES_LATE_SUPPORT.sql

-- BEGIN FILE: WORLD_SEED_WIKI_CHAT_LATE_SUPPORT.sql
-- World seed: wiki and chat support for additional late-mainline support cast

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  ('wiki_character_nazrin','gensokyo_main','characters/nazrin','Nazrin','character','character','nazrin','A practical finder whose value lies in search, dowsing, and clue movement.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_kogasa','gensokyo_main','characters/kogasa-tatara','Kogasa Tatara','character','character','kogasa','A surprise-seeking tsukumogami whose scenes hinge on being noticed.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_murasa','gensokyo_main','characters/minamitsu-murasa','Minamitsu Murasa','character','character','murasa','A captain figure whose invitation and navigation always carry danger with them.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_nue','gensokyo_main','characters/nue-houjuu','Nue Houjuu','character','character','nue','An undefined youkai who destabilizes recognition and certainty.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_seiga','gensokyo_main','characters/seiga-kaku','Seiga Kaku','character','character','seiga','A wicked hermit who turns intrusion and selfish freedom into a method.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_futo','gensokyo_main','characters/mononobe-no-futo','Mononobe no Futo','character','character','futo','An ancient Taoist whose ritual style remains flamboyant and old-fashioned by design.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_tojiko','gensokyo_main','characters/soga-no-tojiko','Soga no Tojiko','character','character','tojiko','A stormy spirit whose retained rank and irritation still shape her presence.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_narumi','gensokyo_main','characters/narumi-yatadera','Narumi Yatadera','character','character','narumi','A grounded guardian whose local protection and spiritual stability matter more than spectacle.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_saki','gensokyo_main','characters/saki-kurokoma','Saki Kurokoma','character','character','saki','A Beast Realm leader whose speed and predatory force are political as much as physical.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_misumaru','gensokyo_main','characters/misumaru-tamatsukuri','Misumaru Tamatsukuri','character','character','misumaru','A craft-oriented deity whose support power comes through making rather than declaration.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_momoyo','gensokyo_main','characters/momoyo-himemushi','Momoyo Himemushi','character','character','momoyo','A centipede miner tied to mountain depth, extraction, and the appetite of underground value.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_megumu','gensokyo_main','characters/megumu-iizunamaru','Megumu Iizunamaru','character','character','megumu','A high tengu authority figure who makes mountain power feel institutional rather than merely local.','published','chronicle_gensokyo_history','{}'::jsonb)
on conflict (id) do update
set slug = excluded.slug,
    title = excluded.title,
    page_type = excluded.page_type,
    subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    summary = excluded.summary,
    status = excluded.status,
    canonical_book_id = excluded.canonical_book_id,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_wiki_page_sections (
  id, page_id, section_code, section_order, heading, summary, body, source_ref_ids, metadata
)
values
  ('wiki_character_nazrin:section:overview','wiki_character_nazrin','overview',1,'Overview','Nazrin as finder.','Nazrin is most useful when a scene needs practical search logic, clue movement, and field competence rather than spectacle.', '["claim_nazrin_search_specialist","claim_ability_nazrin"]'::jsonb,'{}'::jsonb),
  ('wiki_character_kogasa:section:overview','wiki_character_kogasa','overview',1,'Overview','Kogasa as wanted surprise.','Kogasa is strongest when the desire to be noticed shapes both comedy and faint sadness in the scene.', '["claim_kogasa_surprise","claim_ability_kogasa"]'::jsonb,'{}'::jsonb),
  ('wiki_character_murasa:section:overview','wiki_character_murasa','overview',1,'Overview','Murasa as dangerous invitation.','Murasa belongs in scenes where guidance and invitation remain useful precisely because they are not wholly safe.', '["claim_murasa_navigation","claim_ability_murasa"]'::jsonb,'{}'::jsonb),
  ('wiki_character_nue:section:overview','wiki_character_nue','overview',1,'Overview','Nue as unstable recognition.','Nue works best when certainty itself is made unreliable and the scene can no longer trust what it has identified.', '["claim_nue_ambiguity","claim_ability_nue"]'::jsonb,'{}'::jsonb),
  ('wiki_character_seiga:section:overview','wiki_character_seiga','overview',1,'Overview','Seiga as selfish intrusion.','Seiga gives later-era stories a smooth, mobile form of intrusion that does not respect the moral limits of others.', '["claim_seiga_intrusion","claim_ability_seiga"]'::jsonb,'{}'::jsonb),
  ('wiki_character_futo:section:overview','wiki_character_futo','overview',1,'Overview','Futo as ritual theater.','Futo adds old-style ritual confidence and flamboyant certainty to mausoleum-centered scenes.', '["claim_ability_futo"]'::jsonb,'{}'::jsonb),
  ('wiki_character_tojiko:section:overview','wiki_character_tojiko','overview',1,'Overview','Tojiko as stormy retention.','Tojiko helps old authority feel haunted, retained, and not entirely softened by time.', '["claim_ability_tojiko"]'::jsonb,'{}'::jsonb),
  ('wiki_character_narumi:section:overview','wiki_character_narumi','overview',1,'Overview','Narumi as grounded guardian.','Narumi is useful where local protection and spiritual steadiness matter more than dramatic hierarchy.', '["claim_narumi_local_guardian","claim_ability_narumi"]'::jsonb,'{}'::jsonb),
  ('wiki_character_saki:section:overview','wiki_character_saki','overview',1,'Overview','Saki as predatory leadership.','Saki makes Beast Realm power feel fast, coercive, and proudly dangerous rather than merely chaotic.', '["claim_ability_saki"]'::jsonb,'{}'::jsonb),
  ('wiki_character_misumaru:section:overview','wiki_character_misumaru','overview',1,'Overview','Misumaru as crafted support.','Misumaru''s power is constructive and careful, making support itself feel like a serious form of intervention.', '["claim_ability_misumaru"]'::jsonb,'{}'::jsonb),
  ('wiki_character_momoyo:section:overview','wiki_character_momoyo','overview',1,'Overview','Momoyo as extraction force.','Momoyo helps mountain and cave scenes feel tied to hidden value, appetite, and the violence of extraction.', '["claim_ability_momoyo"]'::jsonb,'{}'::jsonb),
  ('wiki_character_megumu:section:overview','wiki_character_megumu','overview',1,'Overview','Megumu as institutional mountain power.','Megumu belongs where mountain authority should feel managed at a higher and more formal scale than ordinary patrol work.', '["claim_megumu_mountain_authority","claim_ability_megumu"]'::jsonb,'{}'::jsonb)
on conflict (id) do update
set heading = excluded.heading,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_chat_context_cache (
  id, world_id, user_scope, character_id, location_id, event_id, context_type, summary, payload, freshness_score, last_used_at
)
values
  (
    'chat_voice_nazrin_core',
    'gensokyo_main',
    'global',
    'nazrin',
    null,
    null,
    'character_voice',
    'Nazrin should sound practical and lightly dry, like finding the thing matters more than dramatizing the search.',
    jsonb_build_object(
      'speech_style', 'practical, dry, focused',
      'worldview', 'You save time by looking where the answer is likely to be, not where it would look impressive.',
      'claim_ids', array['claim_nazrin_search_specialist','claim_ability_nazrin']
    ),
    0.83,
    now()
  ),
  (
    'chat_voice_kogasa_core',
    'gensokyo_main',
    'global',
    'kogasa',
    null,
    null,
    'character_voice',
    'Kogasa should sound eager and slightly wounded by being ignored, with surprise treated as a social need as much as a joke.',
    jsonb_build_object(
      'speech_style', 'eager, playful, needy',
      'worldview', 'A surprise only counts if someone actually reacts to it.',
      'claim_ids', array['claim_kogasa_surprise','claim_ability_kogasa']
    ),
    0.82,
    now()
  ),
  (
    'chat_voice_murasa_core',
    'gensokyo_main',
    'global',
    'murasa',
    null,
    null,
    'character_voice',
    'Murasa should sound inviting and a little dangerous, like the route she offers is useful right up until it is not.',
    jsonb_build_object(
      'speech_style', 'cool, inviting, dangerous',
      'worldview', 'A guide is trusted most when the traveler forgets how risky the route really is.',
      'claim_ids', array['claim_murasa_navigation','claim_ability_murasa']
    ),
    0.84,
    now()
  ),
  (
    'chat_voice_nue_core',
    'gensokyo_main',
    'global',
    'nue',
    null,
    null,
    'character_voice',
    'Nue should sound slippery and amused, as if certainty itself is the easiest thing in the room to ruin.',
    jsonb_build_object(
      'speech_style', 'slippery, amused, destabilizing',
      'worldview', 'People are easiest to move once they stop being sure what they are looking at.',
      'claim_ids', array['claim_nue_ambiguity','claim_ability_nue']
    ),
    0.84,
    now()
  ),
  (
    'chat_voice_seiga_core',
    'gensokyo_main',
    'global',
    'seiga',
    null,
    null,
    'character_voice',
    'Seiga should sound smooth and shameless, like limits are mainly useful for showing what she can slip around.',
    jsonb_build_object(
      'speech_style', 'smooth, shameless, playful',
      'worldview', 'If a boundary is inconvenient, there is usually a way past it for someone clever enough.',
      'claim_ids', array['claim_seiga_intrusion','claim_ability_seiga']
    ),
    0.85,
    now()
  ),
  (
    'chat_voice_narumi_core',
    'gensokyo_main',
    'global',
    'narumi',
    null,
    null,
    'character_voice',
    'Narumi should sound grounded and steady, like local guardianship is a practical craft rather than a grand declaration.',
    jsonb_build_object(
      'speech_style', 'steady, grounded, warm',
      'worldview', 'Protection works best when it is already part of the place.',
      'claim_ids', array['claim_narumi_local_guardian','claim_ability_narumi']
    ),
    0.82,
    now()
  ),
  (
    'chat_voice_saki_core',
    'gensokyo_main',
    'global',
    'saki',
    null,
    null,
    'character_voice',
    'Saki should sound forceful and impatient, like motion and dominance are easiest when no one is allowed to set the pace first.',
    jsonb_build_object(
      'speech_style', 'forceful, impatient, proud',
      'worldview', 'If you are fast enough to take the lead, that is already half the law.',
      'claim_ids', array['claim_ability_saki']
    ),
    0.83,
    now()
  ),
  (
    'chat_voice_misumaru_core',
    'gensokyo_main',
    'global',
    'misumaru',
    null,
    null,
    'character_voice',
    'Misumaru should sound kind and craft-minded, like careful making is a form of intervention worth taking seriously.',
    jsonb_build_object(
      'speech_style', 'kind, craft-minded, precise',
      'worldview', 'The better something is made, the more quietly it can protect or support.',
      'claim_ids', array['claim_ability_misumaru']
    ),
    0.82,
    now()
  ),
  (
    'chat_voice_momoyo_core',
    'gensokyo_main',
    'global',
    'momoyo',
    null,
    null,
    'character_voice',
    'Momoyo should sound hungry and confident, like hidden value is meant to be found by whoever can dig hardest.',
    jsonb_build_object(
      'speech_style', 'hungry, confident, blunt',
      'worldview', 'If something valuable is buried, that only makes finding it more worthwhile.',
      'claim_ids', array['claim_ability_momoyo']
    ),
    0.82,
    now()
  ),
  (
    'chat_voice_megumu_core',
    'gensokyo_main',
    'global',
    'megumu',
    null,
    null,
    'character_voice',
    'Megumu should sound formal and managerial, like authority exists to keep a structure usable at scale.',
    jsonb_build_object(
      'speech_style', 'formal, managerial, sharp',
      'worldview', 'A high place is only worth keeping if someone can still manage what moves beneath it.',
      'claim_ids', array['claim_megumu_mountain_authority','claim_ability_megumu']
    ),
    0.84,
    now()
  ),
  (
    'chat_voice_mike_core',
    'gensokyo_main',
    'global',
    'mike',
    null,
    null,
    'character_voice',
    'Mike should sound cheerful and businesslike, like small luck is something you can actually sell into daily life.',
    jsonb_build_object(
      'speech_style', 'cheerful, businesslike, approachable',
      'worldview', 'A little luck in the right place moves more people than they admit.',
      'claim_ids', array['claim_mike_trade_luck','claim_ability_mike']
    ),
    0.81,
    now()
  ),
  (
    'chat_voice_aunn_core',
    'gensokyo_main',
    'global',
    'aunn',
    null,
    null,
    'character_voice',
    'Aunn should sound warm and loyal, like sacred space is something to like and protect at the same time.',
    jsonb_build_object(
      'speech_style', 'warm, loyal, earnest',
      'worldview', 'A place is easier to protect once it has already become familiar and beloved.',
      'claim_ids', array['claim_aunn_guardian','claim_ability_aunn']
    ),
    0.82,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

-- END FILE: WORLD_SEED_WIKI_CHAT_LATE_SUPPORT.sql

-- BEGIN FILE: WORLD_SEED_CLAIMS_TEMPLE_EIENTEI.sql
-- World seed: temple, Eientei, and river-threshold role claims

insert into public.world_canon_claims (
  id, world_id, subject_type, subject_id, claim_type, summary, details, source_id, confidence, priority, tags
)
values
  ('claim_ichirin_temple_strength','gensokyo_main','character','ichirin','role','Ichirin works best as visible temple-side strength and loyalty rather than as an isolated doctrinal speaker.',jsonb_build_object('role','temple_support_strength'),'src_ufo','official',72,'["ichirin","ufo","temple"]'::jsonb),
  ('claim_reisen_eientei_operator','gensokyo_main','character','reisen','role','Reisen is especially useful as a practical operator within Eientei''s disciplined, medically informed, lunar-shadowed structure.',jsonb_build_object('role','eientei_operator'),'src_imperishable_night','official',77,'["reisen","in","eientei"]'::jsonb),
  ('claim_eika_riverbank_persistence','gensokyo_main','character','eika','role','Eika gives the riverbank and afterlife threshold a small-scale persistence that prevents it from feeling abstract.',jsonb_build_object('role','riverbank_persistence'),'src_wbawc','official',68,'["eika","wbawc","riverbank"]'::jsonb),
  ('claim_urumi_threshold_guard','gensokyo_main','character','urumi','role','Urumi is best used as a steady threshold guardian at river and ferry-adjacent crossings.',jsonb_build_object('role','threshold_guard'),'src_wbawc','official',69,'["urumi","wbawc","threshold"]'::jsonb),
  ('claim_kutaka_checkpoint_guard','gensokyo_main','character','kutaka','role','Kutaka works naturally as a checkpoint authority whose value lies in regulated passage and avian order.',jsonb_build_object('role','checkpoint_guard'),'src_wbawc','official',71,'["kutaka","wbawc","checkpoint"]'::jsonb)
on conflict (id) do update
set subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    claim_type = excluded.claim_type,
    summary = excluded.summary,
    details = excluded.details,
    source_id = excluded.source_id,
    confidence = excluded.confidence,
    priority = excluded.priority,
    tags = excluded.tags,
    updated_at = now();

-- END FILE: WORLD_SEED_CLAIMS_TEMPLE_EIENTEI.sql

-- BEGIN FILE: WORLD_SEED_CHAT_LOCATIONS_CORE.sql
-- World seed: core location mood and usage context

insert into public.world_chat_context_cache (
  id, world_id, user_scope, character_id, location_id, event_id, context_type, summary, payload, freshness_score, last_used_at
)
values
  (
    'chat_location_myouren_temple_core',
    'gensokyo_main',
    'global',
    null,
    'myouren_temple',
    null,
    'location_mood',
    'Myouren Temple should feel communal, disciplined, and publicly coexistence-minded rather than secluded or secretive.',
    jsonb_build_object(
      'default_mood', 'communal_order',
      'claim_ids', array['claim_glossary_myouren','claim_regional_myouren_daily_life'],
      'character_ids', array['byakuren','shou','nazrin','kyouko','murasa']
    ),
    0.86,
    now()
  ),
  (
    'chat_location_chireiden_core',
    'gensokyo_main',
    'global',
    null,
    'chireiden',
    null,
    'location_mood',
    'Chireiden should feel psychologically exposed, quiet, and difficult to emotionally hide inside.',
    jsonb_build_object(
      'default_mood', 'exposed_and_quiet',
      'claim_ids', array['claim_chireiden_setting'],
      'character_ids', array['satori','rin','utsuho','koishi']
    ),
    0.87,
    now()
  ),
  (
    'chat_location_divine_spirit_mausoleum_core',
    'gensokyo_main',
    'global',
    null,
    'divine_spirit_mausoleum',
    null,
    'location_mood',
    'The Divine Spirit Mausoleum should feel ceremonial, legitimacy-heavy, and rhetorically staged rather than domestic.',
    jsonb_build_object(
      'default_mood', 'ceremonial_authority',
      'claim_ids', array['claim_glossary_divine_spirit_mausoleum','claim_incident_divine_spirits'],
      'character_ids', array['miko','futo','tojiko','seiga','yoshika']
    ),
    0.85,
    now()
  ),
  (
    'chat_location_bamboo_forest_core',
    'gensokyo_main',
    'global',
    null,
    'bamboo_forest',
    null,
    'location_mood',
    'The Bamboo Forest should feel winding, evasive, and a little socially selective rather than openly public.',
    jsonb_build_object(
      'default_mood', 'winding_and_selective',
      'claim_ids', array['claim_eientei_secluded'],
      'character_ids', array['eirin','kaguya','reisen','tewi','kagerou']
    ),
    0.84,
    now()
  ),
  (
    'chat_location_eientei_core',
    'gensokyo_main',
    'global',
    null,
    'eientei',
    null,
    'location_mood',
    'Eientei should feel expert, secluded, and politely controlled, with access never quite as casual as it first seems.',
    jsonb_build_object(
      'default_mood', 'secluded_expertise',
      'claim_ids', array['claim_eientei_secluded'],
      'character_ids', array['eirin','kaguya','reisen','tewi']
    ),
    0.86,
    now()
  ),
  (
    'chat_location_kappa_workshop_core',
    'gensokyo_main',
    'global',
    null,
    'kappa_workshop',
    null,
    'location_mood',
    'The Kappa Workshop should feel improvised, practical, and full of half-finished usefulness rather than polished mystique.',
    jsonb_build_object(
      'default_mood', 'busy_practicality',
      'claim_ids', array['claim_glossary_kappa'],
      'character_ids', array['nitori']
    ),
    0.84,
    now()
  ),
  (
    'chat_location_suzunaan_core',
    'gensokyo_main',
    'global',
    null,
    'suzunaan',
    null,
    'location_mood',
    'Suzunaan should feel inviting and curious, with the constant possibility that reading has already become a small problem.',
    jsonb_build_object(
      'default_mood', 'curious_textual_risk',
      'claim_ids', array['claim_suzunaan_profile','claim_term_book_circulation'],
      'character_ids', array['kosuzu','akyuu']
    ),
    0.85,
    now()
  ),
  (
    'chat_location_kourindou_core',
    'gensokyo_main',
    'global',
    null,
    'kourindou',
    null,
    'location_mood',
    'Kourindou should feel cluttered, interpretive, and materially strange, with objects doing half the conversational work.',
    jsonb_build_object(
      'default_mood', 'curio_interpretation',
      'claim_ids', array['claim_kourindou_profile','claim_ability_rinnosuke'],
      'character_ids', array['rinnosuke']
    ),
    0.85,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

-- END FILE: WORLD_SEED_CHAT_LOCATIONS_CORE.sql

-- BEGIN FILE: WORLD_SEED_WIKI_CHAT_TEMPLE_EIENTEI.sql
-- World seed: temple, Eientei, and ghostly-court chat/wiki support

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  ('wiki_character_byakuren','gensokyo_main','characters/byakuren-hijiri','Byakuren Hijiri','character','character','byakuren','A temple leader whose force is tied to coexistence, charisma, and disciplined magical authority.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_ichirin','gensokyo_main','characters/ichirin-kumoi','Ichirin Kumoi','character','character','ichirin','A temple-side physical anchor whose strength and loyalty make doctrine materially present.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_reisen','gensokyo_main','characters/reisen-udongein-inaba','Reisen Udongein Inaba','character','character','reisen','A moon rabbit whose role in Eientei mixes discipline, medicine-adjacent support, and nervous practicality.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_eika','gensokyo_main','characters/eika-ebisu','Eika Ebisu','character','character','eika','A small-stone spirit whose persistence and repetitive labor make the Sanzu side feel inhabited.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_urumi','gensokyo_main','characters/urumi-ushizaki','Urumi Ushizaki','character','character','urumi','A river-adjacent guardian whose bovine steadiness shapes threshold movement more than broad politics.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_kutaka','gensokyo_main','characters/kutaka-niwatari','Kutaka Niwatari','character','character','kutaka','A checkpoint guardian who makes passage, inspection, and avian authority feel institutional.','published','chronicle_gensokyo_history','{}'::jsonb)
on conflict (id) do update
set slug = excluded.slug,
    title = excluded.title,
    page_type = excluded.page_type,
    subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    summary = excluded.summary,
    status = excluded.status,
    canonical_book_id = excluded.canonical_book_id,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_wiki_page_sections (
  id, page_id, section_code, section_order, heading, summary, body, source_ref_ids, metadata
)
values
  ('wiki_character_byakuren:section:overview','wiki_character_byakuren','overview',1,'Overview','Byakuren as coexistence authority.','Byakuren should be framed through temple leadership, charismatic discipline, and a public version of coexistence that still carries force.', '["claim_byakuren_coexistence","claim_ability_byakuren"]'::jsonb,'{}'::jsonb),
  ('wiki_character_ichirin:section:overview','wiki_character_ichirin','overview',1,'Overview','Ichirin as temple-side strength.','Ichirin helps temple ideals feel physically defended and socially grounded rather than purely declarative.', '["claim_ichirin_temple_strength"]'::jsonb,'{}'::jsonb),
  ('wiki_character_reisen:section:overview','wiki_character_reisen','overview',1,'Overview','Reisen as disciplined support.','Reisen is strongest when Eientei needs a practical operative who still carries visible strain from larger structures around her.', '["claim_reisen_eientei_operator"]'::jsonb,'{}'::jsonb),
  ('wiki_character_eika:section:overview','wiki_character_eika','overview',1,'Overview','Eika as repetitive persistence.','Eika makes the Sanzu side feel occupied by small, repeated effort rather than only by grand afterlife logic.', '["claim_eika_riverbank_persistence"]'::jsonb,'{}'::jsonb),
  ('wiki_character_urumi:section:overview','wiki_character_urumi','overview',1,'Overview','Urumi as river threshold steadiness.','Urumi helps river and crossing scenes feel guarded by a stable presence rather than constant abstraction.', '["claim_urumi_threshold_guard"]'::jsonb,'{}'::jsonb),
  ('wiki_character_kutaka:section:overview','wiki_character_kutaka','overview',1,'Overview','Kutaka as checkpoint authority.','Kutaka gives passage and checking scenes a clearly institutional, avian, and orderly face.', '["claim_kutaka_checkpoint_guard"]'::jsonb,'{}'::jsonb)
on conflict (id) do update
set heading = excluded.heading,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_chat_context_cache (
  id, world_id, user_scope, character_id, location_id, event_id, context_type, summary, payload, freshness_score, last_used_at
)
values
  (
    'chat_voice_byakuren_core',
    'gensokyo_main',
    'global',
    'byakuren',
    null,
    null,
    'character_voice',
    'Byakuren should sound composed and persuasive, like coexistence is a principle she expects to defend actively.',
    jsonb_build_object(
      'speech_style', 'composed, persuasive, disciplined',
      'worldview', 'Coexistence is not softness if it must be upheld against real pressure.',
      'claim_ids', array['claim_byakuren_coexistence','claim_ability_byakuren']
    ),
    0.86,
    now()
  ),
  (
    'chat_voice_ichirin_core',
    'gensokyo_main',
    'global',
    'ichirin',
    null,
    null,
    'character_voice',
    'Ichirin should sound sturdy and straightforward, like conviction means little unless someone can actually stand beside it.',
    jsonb_build_object(
      'speech_style', 'sturdy, straightforward, loyal',
      'worldview', 'If you believe in something, you ought to have the strength to stand with it.',
      'claim_ids', array['claim_ichirin_temple_strength']
    ),
    0.82,
    now()
  ),
  (
    'chat_voice_reisen_core',
    'gensokyo_main',
    'global',
    'reisen',
    null,
    null,
    'character_voice',
    'Reisen should sound careful and practical, with discipline visible even when nerves are leaking around the edges.',
    jsonb_build_object(
      'speech_style', 'careful, practical, tense',
      'worldview', 'It is easier to keep moving if you do the next necessary thing before panic catches up.',
      'claim_ids', array['claim_reisen_eientei_operator']
    ),
    0.84,
    now()
  ),
  (
    'chat_voice_eika_core',
    'gensokyo_main',
    'global',
    'eika',
    null,
    null,
    'character_voice',
    'Eika should sound repetitive and stubborn in a small way, like persistence is her whole argument.',
    jsonb_build_object(
      'speech_style', 'small, stubborn, repetitive',
      'worldview', 'If you keep building, it still counts even if the world keeps undoing it.',
      'claim_ids', array['claim_eika_riverbank_persistence']
    ),
    0.80,
    now()
  ),
  (
    'chat_voice_urumi_core',
    'gensokyo_main',
    'global',
    'urumi',
    null,
    null,
    'character_voice',
    'Urumi should sound steady and plain, like guarding the crossing is simply part of the landscape.',
    jsonb_build_object(
      'speech_style', 'steady, plain, grounded',
      'worldview', 'A crossing works best when someone reliable is already there before trouble arrives.',
      'claim_ids', array['claim_urumi_threshold_guard']
    ),
    0.80,
    now()
  ),
  (
    'chat_voice_kutaka_core',
    'gensokyo_main',
    'global',
    'kutaka',
    null,
    null,
    'character_voice',
    'Kutaka should sound orderly and dutiful, like passage is something that deserves structure and inspection.',
    jsonb_build_object(
      'speech_style', 'orderly, dutiful, clear',
      'worldview', 'A route is safer once someone has decided how it ought to be crossed.',
      'claim_ids', array['claim_kutaka_checkpoint_guard']
    ),
    0.81,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

-- END FILE: WORLD_SEED_WIKI_CHAT_TEMPLE_EIENTEI.sql

-- BEGIN FILE: WORLD_SEED_CHAT_SUPPORTING_CAST_D.sql
-- World seed: additional support-cast voice cache

insert into public.world_chat_context_cache (
  id, world_id, user_scope, character_id, location_id, event_id, context_type, summary, payload, freshness_score, last_used_at
)
values
  (
    'chat_voice_wakasagihime_core',
    'gensokyo_main',
    'global',
    'wakasagihime',
    null,
    null,
    'character_voice',
    'Wakasagihime should sound gentle and still, like local water and quiet poise matter more than dramatic reach.',
    jsonb_build_object(
      'speech_style', 'gentle, quiet, careful',
      'worldview', 'A calm edge can still be alive with hidden motion.',
      'claim_ids', array['claim_wakasagihime_local_lake']
    ),
    0.79,
    now()
  ),
  (
    'chat_voice_sekibanki_core',
    'gensokyo_main',
    'global',
    'sekibanki',
    null,
    null,
    'character_voice',
    'Sekibanki should sound blunt and guarded, like public space is always slightly less safe than people pretend.',
    jsonb_build_object(
      'speech_style', 'blunt, guarded, streetwise',
      'worldview', 'If a place looks ordinary enough, that is usually when people stop checking.',
      'claim_ids', array['claim_sekibanki_village_uncanny']
    ),
    0.80,
    now()
  ),
  (
    'chat_voice_kagerou_core',
    'gensokyo_main',
    'global',
    'kagerou',
    null,
    null,
    'character_voice',
    'Kagerou should sound shy and earnest, as if instinct is always one breath away from embarrassment.',
    jsonb_build_object(
      'speech_style', 'shy, earnest, reactive',
      'worldview', 'Some conditions reveal more than you meant anyone to notice.',
      'claim_ids', array['claim_kagerou_bamboo_night']
    ),
    0.80,
    now()
  ),
  (
    'chat_voice_benben_core',
    'gensokyo_main',
    'global',
    'benben',
    null,
    null,
    'character_voice',
    'Benben should sound poised and artistic, like public music is a respectable way to occupy space.',
    jsonb_build_object(
      'speech_style', 'cool, artistic, poised',
      'worldview', 'A performance can establish presence before anyone argues with it.',
      'claim_ids', array['claim_benben_performer']
    ),
    0.81,
    now()
  ),
  (
    'chat_voice_yatsuhashi_core',
    'gensokyo_main',
    'global',
    'yatsuhashi',
    null,
    null,
    'character_voice',
    'Yatsuhashi should sound lively and expressive, like rhythm itself is a way of insisting on being noticed.',
    jsonb_build_object(
      'speech_style', 'lively, sharp, expressive',
      'worldview', 'A good note should not ask permission to stand out.',
      'claim_ids', array['claim_yatsuhashi_performer']
    ),
    0.81,
    now()
  ),
  (
    'chat_voice_seiran_core',
    'gensokyo_main',
    'global',
    'seiran',
    null,
    null,
    'character_voice',
    'Seiran should sound energetic and dutiful, like orders become easier to carry once you move before doubt does.',
    jsonb_build_object(
      'speech_style', 'energetic, dutiful, straightforward',
      'worldview', 'There is less room for hesitation if you are already acting.',
      'claim_ids', array['claim_seiran_soldier']
    ),
    0.81,
    now()
  ),
  (
    'chat_voice_ringo_core',
    'gensokyo_main',
    'global',
    'ringo',
    null,
    null,
    'character_voice',
    'Ringo should sound cheerful and practical, like routine is half the reason a place feels real.',
    jsonb_build_object(
      'speech_style', 'cheerful, practical, chatty',
      'worldview', 'A daily routine tells you more about a place than a crisis does.',
      'claim_ids', array['claim_ringo_daily_lunar']
    ),
    0.81,
    now()
  ),
  (
    'chat_voice_kisume_core',
    'gensokyo_main',
    'global',
    'kisume',
    null,
    null,
    'character_voice',
    'Kisume should sound abrupt and eerie, like vertical space itself has learned how to stare back.',
    jsonb_build_object(
      'speech_style', 'quiet, abrupt, eerie',
      'worldview', 'A narrow space is enough if someone is already waiting in it.',
      'claim_ids', array['claim_kisume_underground_approach','claim_ability_kisume']
    ),
    0.79,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

-- END FILE: WORLD_SEED_CHAT_SUPPORTING_CAST_D.sql

-- BEGIN FILE: WORLD_SEED_CHAT_LOCATIONS_EXTENDED.sql
-- World seed: extended location mood cache

insert into public.world_chat_context_cache (
  id, world_id, user_scope, character_id, location_id, event_id, context_type, summary, payload, freshness_score, last_used_at
)
values
  (
    'chat_location_scarlet_devil_mansion_core',
    'gensokyo_main',
    'global',
    null,
    'scarlet_devil_mansion',
    null,
    'location_mood',
    'The Scarlet Devil Mansion should feel aristocratic, internally managed, and slightly theatrical even before anything dramatic happens.',
    jsonb_build_object(
      'default_mood', 'aristocratic_theater',
      'claim_ids', array['claim_sdm_household'],
      'character_ids', array['remilia','sakuya','meiling','patchouli']
    ),
    0.85,
    now()
  ),
  (
    'chat_location_misty_lake_core',
    'gensokyo_main',
    'global',
    null,
    'misty_lake',
    null,
    'location_mood',
    'Misty Lake should feel playful and faintly uncanny, with fairy energy and local youkai presence sharing the same surface.',
    jsonb_build_object(
      'default_mood', 'playful_uncanny',
      'claim_ids', array['claim_glossary_misty_lake'],
      'character_ids', array['cirno','wakasagihime','rumia','letty']
    ),
    0.83,
    now()
  ),
  (
    'chat_location_former_hell_core',
    'gensokyo_main',
    'global',
    null,
    'former_hell',
    null,
    'location_mood',
    'Former Hell should feel layered and route-like, with thresholds, rumors, and hidden local actors doing as much work as danger.',
    jsonb_build_object(
      'default_mood', 'layered_underworld_routes',
      'claim_ids', array['claim_regional_former_hell_routes'],
      'character_ids', array['kisume','yamame','parsee','rin']
    ),
    0.84,
    now()
  ),
  (
    'chat_location_rainbow_dragon_cave_core',
    'gensokyo_main',
    'global',
    null,
    'rainbow_dragon_cave',
    null,
    'location_mood',
    'Rainbow Dragon Cave should feel like hidden value, trade route logic, and mountain commerce meeting underground resource hunger.',
    jsonb_build_object(
      'default_mood', 'hidden_value_market_routes',
      'claim_ids', array['claim_glossary_rainbow_dragon_cave','claim_term_market_competition'],
      'character_ids', array['takane','sannyo','momoyo','misumaru']
    ),
    0.84,
    now()
  ),
  (
    'chat_location_backdoor_realm_core',
    'gensokyo_main',
    'global',
    null,
    'backdoor_realm',
    null,
    'location_mood',
    'The Backdoor Realm should feel selective, backstage, and deliberately hidden rather than purely dreamlike.',
    jsonb_build_object(
      'default_mood', 'backstage_hidden_access',
      'claim_ids', array['claim_glossary_backdoor_realm','claim_term_hidden_seasons'],
      'character_ids', array['okina','satono','mai']
    ),
    0.84,
    now()
  ),
  (
    'chat_location_beast_realm_core',
    'gensokyo_main',
    'global',
    null,
    'beast_realm',
    null,
    'location_mood',
    'The Beast Realm should feel politically predatory, organized, and faction-driven rather than simply chaotic.',
    jsonb_build_object(
      'default_mood', 'predatory_factional_pressure',
      'claim_ids', array['claim_beast_realm_profile','claim_term_beast_realm_politics'],
      'character_ids', array['yachie','saki','keiki']
    ),
    0.85,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

-- END FILE: WORLD_SEED_CHAT_LOCATIONS_EXTENDED.sql

-- BEGIN FILE: WORLD_SEED_CHAT_RESIDUAL_LATE_REALMS.sql
-- World seed: residual voice cache for backdoor, market, and recent-underworld cast

insert into public.world_chat_context_cache (
  id, world_id, user_scope, character_id, location_id, event_id, context_type, summary, payload, freshness_score, last_used_at
)
values
  (
    'chat_voice_satono_core',
    'gensokyo_main',
    'global',
    'satono',
    null,
    null,
    'character_voice',
    'Satono should sound bright and obedient on the surface, with service and hidden-stage selection always just underneath it.',
    jsonb_build_object(
      'speech_style', 'bright, obedient, eerie',
      'worldview', 'A chosen role feels easiest when you lean into it before the order is repeated.',
      'claim_ids', array['claim_term_hidden_seasons']
    ),
    0.80,
    now()
  ),
  (
    'chat_voice_mai_core',
    'gensokyo_main',
    'global',
    'mai',
    null,
    null,
    'character_voice',
    'Mai should sound energetic and sharp, like movement and service are already halfway to a performance.',
    jsonb_build_object(
      'speech_style', 'energetic, sharp, obedient',
      'worldview', 'If the hidden stage is yours to dance on, you might as well move first.',
      'claim_ids', array['claim_term_hidden_seasons']
    ),
    0.80,
    now()
  ),
  (
    'chat_voice_sannyo_core',
    'gensokyo_main',
    'global',
    'sannyo',
    null,
    null,
    'character_voice',
    'Sannyo should sound relaxed and smoky, like market contact and informal exchange matter more than grand slogans.',
    jsonb_build_object(
      'speech_style', 'relaxed, smoky, practical',
      'worldview', 'If people keep coming back, the route is already working.',
      'claim_ids', array['claim_incident_market_cards']
    ),
    0.80,
    now()
  ),
  (
    'chat_voice_biten_core',
    'gensokyo_main',
    'global',
    'biten',
    null,
    null,
    'character_voice',
    'Biten should sound brash and athletic, like challenge is most fun when someone respectable has to deal with it.',
    jsonb_build_object(
      'speech_style', 'brash, athletic, playful',
      'worldview', 'If you are quick enough to start the trouble, the rest can catch up later.',
      'claim_ids', array['claim_biten_mountain_fighter']
    ),
    0.79,
    now()
  ),
  (
    'chat_voice_enoko_core',
    'gensokyo_main',
    'global',
    'enoko',
    null,
    null,
    'character_voice',
    'Enoko should sound disciplined and predatory, like the hunt is already organized before anyone hears it begin.',
    jsonb_build_object(
      'speech_style', 'disciplined, predatory, focused',
      'worldview', 'A proper pursuit starts with order, not noise.',
      'claim_ids', array['claim_enoko_pack_order']
    ),
    0.80,
    now()
  ),
  (
    'chat_voice_chiyari_core',
    'gensokyo_main',
    'global',
    'chiyari',
    null,
    null,
    'character_voice',
    'Chiyari should sound forceful and socially rooted, like underworld power is something lived among peers rather than held above them.',
    jsonb_build_object(
      'speech_style', 'forceful, social, rough',
      'worldview', 'Power is easier to trust if people have already learned how to live around it.',
      'claim_ids', array['claim_chiyari_underworld_operator']
    ),
    0.80,
    now()
  ),
  (
    'chat_voice_hisami_core',
    'gensokyo_main',
    'global',
    'hisami',
    null,
    null,
    'character_voice',
    'Hisami should sound intense and loyal, like attachment itself is dangerous once it has chosen a direction.',
    jsonb_build_object(
      'speech_style', 'intense, loyal, attached',
      'worldview', 'Once devotion has a target, it stops needing moderation.',
      'claim_ids', array['claim_hisami_loyal_retainer']
    ),
    0.79,
    now()
  ),
  (
    'chat_voice_zanmu_core',
    'gensokyo_main',
    'global',
    'zanmu',
    null,
    null,
    'character_voice',
    'Zanmu should sound sparse and high-pressure, like the structure around the scene already tilted before anyone spoke.',
    jsonb_build_object(
      'speech_style', 'sparse, high-pressure, remote',
      'worldview', 'Some authority is clearest when it does less than everyone else and still changes the room.',
      'claim_ids', array['claim_zanmu_structural_actor']
    ),
    0.82,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

-- END FILE: WORLD_SEED_CHAT_RESIDUAL_LATE_REALMS.sql

-- BEGIN FILE: WORLD_SEED_CHAT_LOCATIONS_RESIDUAL.sql
-- World seed: residual location mood cache

insert into public.world_chat_context_cache (
  id, world_id, user_scope, character_id, location_id, event_id, context_type, summary, payload, freshness_score, last_used_at
)
values
  (
    'chat_location_blood_pool_hell_core',
    'gensokyo_main',
    'global',
    null,
    'blood_pool_hell',
    null,
    'location_mood',
    'Blood Pool Hell should feel dense, pressurized, and socially dangerous rather than empty spectacle.',
    jsonb_build_object(
      'default_mood', 'dense_underworld_pressure',
      'claim_ids', array['claim_chiyari_underworld_operator'],
      'character_ids', array['yuuma','chiyari']
    ),
    0.81,
    now()
  ),
  (
    'chat_location_sanzu_river_core',
    'gensokyo_main',
    'global',
    null,
    'sanzu_river',
    null,
    'location_mood',
    'The Sanzu River should feel procedural and symbolic at once, with crossings managed by routine rather than melodrama alone.',
    jsonb_build_object(
      'default_mood', 'procedural_threshold',
      'claim_ids', array['claim_kutaka_checkpoint_guard'],
      'character_ids', array['komachi','eika','urumi','kutaka']
    ),
    0.81,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

-- END FILE: WORLD_SEED_CHAT_LOCATIONS_RESIDUAL.sql

-- BEGIN FILE: WORLD_SEED_HISTORIAN_NOTES_LATE_SYSTEMS.sql
-- World seed: historian notes for late-mainline system shifts

insert into public.world_historian_notes (
  id, world_id, historian_character_id, subject_type, subject_id, note_kind, title, summary, body, source_ref_ids, metadata
)
values
  (
    'historian_note_akyuu_hidden_seasons',
    'gensokyo_main',
    'akyuu',
    'incident',
    'incident_hidden_seasons',
    'editorial',
    'On Hidden Seasons as Selective Access',
    'A note on why the hidden-seasons disturbance matters as access logic as much as seasonal manipulation.',
    'The hidden-seasons incident is not important only because weather overflowed. Its deeper significance lies in selective access: who could reveal, grant, or withhold latent power, and under what hidden invitation such access became possible.',
    '["claim_incident_hidden_seasons","claim_term_hidden_seasons"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'historian_note_akyuu_beast_realm',
    'gensokyo_main',
    'akyuu',
    'incident',
    'incident_beast_realm',
    'editorial',
    'On the Beast Realm as Politics, Not Mere Ferocity',
    'A note on why Beast Realm involvement should be read through factional structure and coercive order.',
    'The Beast Realm incursion matters because it introduces organized predation and factional pressure into Gensokyo''s field of understanding. To misread it as mere savagery is to ignore the political form inside the violence.',
    '["claim_incident_beast_realm","claim_term_beast_realm_politics"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'historian_note_akyuu_market_cards',
    'gensokyo_main',
    'akyuu',
    'incident',
    'incident_market_cards',
    'editorial',
    'On Market Cards and the Circulation of Power',
    'A note on the market-card affair as a change in how ability and value were publicly understood.',
    'The ability-card affair did more than produce commercial confusion. It changed the visible grammar of power by making circulation, ownership, and exchange part of how ability itself was popularly imagined.',
    '["claim_incident_market_cards","claim_term_market_competition","claim_term_market_cards"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'historian_note_akyuu_living_ghost_conflict',
    'gensokyo_main',
    'akyuu',
    'incident',
    'incident_living_ghost_conflict',
    'editorial',
    'On the Living-Ghost Conflict as Escalated Structure',
    'A note on later underworld conflict as pressure from higher-order actors rather than simple local disturbance.',
    'The all-living-ghost conflict should be remembered as an escalation in structural pressure. Its notable feature is not only the number of new actors, but the way underworld hierarchy and Beast Realm logic overlap at a scale ordinary local trouble cannot contain.',
    '["claim_incident_living_ghost_conflict","claim_zanmu_structural_actor","lore_recent_underworld_power"]'::jsonb,
    '{}'::jsonb
  )
on conflict (id) do update
set note_kind = excluded.note_kind,
    title = excluded.title,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();

-- END FILE: WORLD_SEED_HISTORIAN_NOTES_LATE_SYSTEMS.sql

-- BEGIN FILE: WORLD_SEED_WIKI_RESIDUAL_REALMS.sql
-- World seed: residual realm and late-system wiki pages

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  ('wiki_character_satono','gensokyo_main','characters/satono-nishida','Satono Nishida','character','character','satono','A hidden-stage attendant whose brightness is inseparable from selective service and access.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_mai','gensokyo_main','characters/mai-teireida','Mai Teireida','character','character','mai','A hidden-stage attendant whose energy and obedience are tied to backstage motion and chosen service.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_sannyo','gensokyo_main','characters/sannyo-komakusa','Sannyo Komakusa','character','character','sannyo','A smoke seller who helps market routes feel informal, local, and socially sustained.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_biten','gensokyo_main','characters/son-biten','Son Biten','character','character','biten','A brash mountain fighter whose value lies in challenge-energy more than formal authority.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_enoko','gensokyo_main','characters/enoko-mitsugashira','Enoko Mitsugashira','character','character','enoko','A Beast Realm pursuit leader whose order is expressed through pack discipline and organized hunting pressure.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_chiyari','gensokyo_main','characters/chiyari-tenkajin','Chiyari Tenkajin','character','character','chiyari','An underworld operator whose force is socialized inside blood-pool and hell-side affiliations.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_hisami','gensokyo_main','characters/hisami-yomotsu','Hisami Yomotsu','character','character','hisami','A dangerous retainer whose loyalty itself creates pressure in the room.','published','chronicle_gensokyo_history','{}'::jsonb)
on conflict (id) do update
set slug = excluded.slug,
    title = excluded.title,
    page_type = excluded.page_type,
    subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    summary = excluded.summary,
    status = excluded.status,
    canonical_book_id = excluded.canonical_book_id,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_wiki_page_sections (
  id, page_id, section_code, section_order, heading, summary, body, source_ref_ids, metadata
)
values
  ('wiki_character_satono:section:overview','wiki_character_satono','overview',1,'Overview','Satono as chosen attendant.','Satono is strongest when hidden service and selective empowerment are visible just beneath a bright, obedient surface.', '["claim_term_hidden_seasons"]'::jsonb,'{}'::jsonb),
  ('wiki_character_mai:section:overview','wiki_character_mai','overview',1,'Overview','Mai as energetic backstage motion.','Mai turns hidden-stage service into movement, rhythm, and sharp obedience rather than passive attendance.', '["claim_term_hidden_seasons"]'::jsonb,'{}'::jsonb),
  ('wiki_character_sannyo:section:overview','wiki_character_sannyo','overview',1,'Overview','Sannyo as informal market life.','Sannyo makes market routes feel lived in through repeated contact, smoke, and ordinary exchange rather than grand abstractions of value.', '["claim_incident_market_cards"]'::jsonb,'{}'::jsonb),
  ('wiki_character_biten:section:overview','wiki_character_biten','overview',1,'Overview','Biten as mountain challenge energy.','Biten is best used when mountain scenes need reckless challenge and agile bravado rather than administrative order.', '["claim_biten_mountain_fighter"]'::jsonb,'{}'::jsonb),
  ('wiki_character_enoko:section:overview','wiki_character_enoko','overview',1,'Overview','Enoko as pack discipline.','Enoko gives Beast Realm pursuit logic a disciplined and socially organized face.', '["claim_enoko_pack_order"]'::jsonb,'{}'::jsonb),
  ('wiki_character_chiyari:section:overview','wiki_character_chiyari','overview',1,'Overview','Chiyari as socialized underworld force.','Chiyari matters because underworld power around her feels inhabited and affiliated, not merely violent.', '["claim_chiyari_underworld_operator"]'::jsonb,'{}'::jsonb),
  ('wiki_character_hisami:section:overview','wiki_character_hisami','overview',1,'Overview','Hisami as dangerous loyalty.','Hisami gives later underworld scenes a form of devotion that intensifies hierarchy instead of softening it.', '["claim_hisami_loyal_retainer"]'::jsonb,'{}'::jsonb)
on conflict (id) do update
set heading = excluded.heading,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();

-- END FILE: WORLD_SEED_WIKI_RESIDUAL_REALMS.sql

-- BEGIN FILE: WORLD_SEED_CLAIMS_BACKDOOR_MARKET_RESIDUAL.sql
-- World seed: residual backdoor and market character claims

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  (
    'gensokyo_main',
    'lore_satono_selected_service',
    'character_role',
    'Satono Selected Service',
    'Satono works best when hidden-stage service feels cheerful on the surface but selective underneath.',
    jsonb_build_object('character_id','satono'),
    '["hsifs","satono","service"]'::jsonb,
    74
  ),
  (
    'gensokyo_main',
    'lore_mai_backstage_motion',
    'character_role',
    'Mai Backstage Motion',
    'Mai is strongest where hidden-stage service turns into movement, rhythm, and active execution.',
    jsonb_build_object('character_id','mai'),
    '["hsifs","mai","movement"]'::jsonb,
    74
  ),
  (
    'gensokyo_main',
    'lore_sannyo_informal_market_rest',
    'character_role',
    'Sannyo Informal Market Rest',
    'Sannyo makes market stories feel inhabited by pauses, smoke, and small-scale familiarity rather than abstract trade alone.',
    jsonb_build_object('character_id','sannyo'),
    '["um","sannyo","market"]'::jsonb,
    73
  ),
  (
    'gensokyo_main',
    'lore_market_route_rest_logic',
    'world_rule',
    'Market Route Rest Logic',
    'Market-era routes should include informal rest points, gossip nodes, and low-pressure exchange spaces in addition to overt sales.',
    jsonb_build_object('focus',array['sannyo','takane','chimata']),
    '["um","market","routes"]'::jsonb,
    77
  )
on conflict (world_id, id) do update
set category = excluded.category,
    title = excluded.title,
    summary = excluded.summary,
    details = excluded.details,
    tags = excluded.tags,
    priority = excluded.priority,
    updated_at = now();

insert into public.world_canon_claims (
  id, world_id, subject_type, subject_id, claim_type, summary, details, source_id, confidence, priority, tags
)
values
  (
    'claim_satono_selected_attendant',
    'gensokyo_main',
    'character',
    'satono',
    'role',
    'Satono should be framed as a selectively empowering attendant whose brightness hides deliberate backstage service.',
    jsonb_build_object('role','selected_attendant'),
    'src_hsifs',
    'official',
    76,
    '["satono","hsifs","attendant"]'::jsonb
  ),
  (
    'claim_mai_backstage_executor',
    'gensokyo_main',
    'character',
    'mai',
    'role',
    'Mai is best used as an energetic backstage executor whose motion and choreography make hidden service visible.',
    jsonb_build_object('role','backstage_executor'),
    'src_hsifs',
    'official',
    76,
    '["mai","hsifs","attendant"]'::jsonb
  ),
  (
    'claim_sannyo_informal_merchant',
    'gensokyo_main',
    'character',
    'sannyo',
    'role',
    'Sannyo is most natural as an informal merchant whose space relaxes people into quieter trade, smoke, and candid talk.',
    jsonb_build_object('role','informal_merchant'),
    'src_um',
    'official',
    75,
    '["sannyo","um","merchant"]'::jsonb
  ),
  (
    'claim_backdoor_attendants_pairing',
    'gensokyo_main',
    'group',
    'satono_mai_pair',
    'relationship',
    'Satono and Mai should usually be treated as a paired hidden-stage apparatus rather than unrelated background attendants.',
    jsonb_build_object('characters',array['satono','mai']),
    'src_hsifs',
    'official',
    77,
    '["satono","mai","pairing"]'::jsonb
  ),
  (
    'claim_market_route_rest_stops',
    'gensokyo_main',
    'theme',
    'market_route_rest_stops',
    'world_rule',
    'Market routes in Gensokyo should feel sustained by pauses, small gatherings, and low-key exchange points as well as formal selling.',
    jsonb_build_object('focus',array['rainbow_dragon_cave','human_village','youkai_mountain_foot']),
    'src_um',
    'official',
    73,
    '["market","routes","rest"]'::jsonb
  )
on conflict (id) do update
set subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    claim_type = excluded.claim_type,
    summary = excluded.summary,
    details = excluded.details,
    source_id = excluded.source_id,
    confidence = excluded.confidence,
    priority = excluded.priority,
    tags = excluded.tags,
    updated_at = now();

-- END FILE: WORLD_SEED_CLAIMS_BACKDOOR_MARKET_RESIDUAL.sql

-- BEGIN FILE: WORLD_SEED_WIKI_BACKDOOR_MARKET_RESIDUAL.sql
-- World seed: residual wiki sections for backdoor and market cast

insert into public.world_wiki_page_sections (
  id, page_id, section_code, section_order, heading, summary, body, source_ref_ids, metadata
)
values
  (
    'wiki_character_satono:section:story_use',
    'wiki_character_satono',
    'story_use',
    2,
    'Story Use',
    'Satono as cheerful selective service.',
    'Satono is most effective when a scene needs visible obedience tied to hidden selection, invitation, and backstage permission.',
    '["claim_satono_selected_attendant","claim_backdoor_attendants_pairing","lore_satono_selected_service"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_mai:section:story_use',
    'wiki_character_mai',
    'story_use',
    2,
    'Story Use',
    'Mai as motion-driven backstage execution.',
    'Mai works best when hidden-stage authority is expressed through speed, choreography, and an almost playful execution of orders.',
    '["claim_mai_backstage_executor","claim_backdoor_attendants_pairing","lore_mai_backstage_motion"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_sannyo:section:story_use',
    'wiki_character_sannyo',
    'story_use',
    2,
    'Story Use',
    'Sannyo as informal market rest and candor.',
    'Sannyo is strongest in scenes where markets become local and lived-in through pauses, smoke, and easy conversation rather than overt spectacle.',
    '["claim_sannyo_informal_merchant","claim_market_route_rest_stops","lore_sannyo_informal_market_rest"]'::jsonb,
    '{}'::jsonb
  )
on conflict (id) do update
set heading = excluded.heading,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();

-- END FILE: WORLD_SEED_WIKI_BACKDOOR_MARKET_RESIDUAL.sql

-- BEGIN FILE: WORLD_SEED_CHAT_BACKDOOR_MARKET_RESIDUAL.sql
-- World seed: residual backdoor and market chat context

insert into public.world_chat_context_cache (
  id, world_id, user_scope, character_id, location_id, event_id, context_type, summary, payload, freshness_score, last_used_at
)
values
  (
    'chat_context_global_satono_backdoor',
    'gensokyo_main',
    'global',
    'satono',
    'backdoor_realm',
    null,
    'character_location_story',
    'Satono in the Backdoor Realm should feel like bright service with a selective edge, as if access itself is being quietly sorted.',
    jsonb_build_object(
      'claim_ids', array['claim_satono_selected_attendant','claim_backdoor_realm_profile','claim_backdoor_attendants_pairing'],
      'lore_ids', array['lore_satono_selected_service','lore_okina_hidden_access'],
      'location_ids', array['backdoor_realm']
    ),
    0.84,
    now()
  ),
  (
    'chat_context_global_mai_backdoor',
    'gensokyo_main',
    'global',
    'mai',
    'backdoor_realm',
    null,
    'character_location_story',
    'Mai in the Backdoor Realm should feel like movement, rhythm, and execution turning hidden-stage authority into something kinetic.',
    jsonb_build_object(
      'claim_ids', array['claim_mai_backstage_executor','claim_backdoor_realm_profile','claim_backdoor_attendants_pairing'],
      'lore_ids', array['lore_mai_backstage_motion','lore_okina_hidden_access'],
      'location_ids', array['backdoor_realm']
    ),
    0.84,
    now()
  ),
  (
    'chat_context_global_sannyo_market_rest',
    'gensokyo_main',
    'global',
    'sannyo',
    'rainbow_dragon_cave',
    null,
    'character_location_story',
    'Sannyo should bring out the relaxed, smoky, half-resting side of market routes, where people trade because they linger first.',
    jsonb_build_object(
      'claim_ids', array['claim_sannyo_informal_merchant','claim_rainbow_dragon_cave_profile','claim_market_route_rest_stops'],
      'lore_ids', array['lore_sannyo_informal_market_rest','lore_market_route_rest_logic','lore_um_market_flow'],
      'location_ids', array['rainbow_dragon_cave','youkai_mountain_foot']
    ),
    0.84,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

-- END FILE: WORLD_SEED_CHAT_BACKDOOR_MARKET_RESIDUAL.sql

-- BEGIN FILE: WORLD_SEED_HISTORIAN_NOTES_BACKDOOR_MARKET.sql
-- World seed: historian notes for backdoor and market residual systems

insert into public.world_historian_notes (
  id, world_id, historian_character_id, subject_type, subject_id, note_kind, title, summary, body, source_ref_ids, metadata
)
values
  (
    'historian_note_akyuu_backdoor_attendants',
    'gensokyo_main',
    'akyuu',
    'theme',
    'backdoor_attendants',
    'editorial',
    'On Backdoor Attendants',
    'Akyuu records Satono and Mai as a paired logic of access rather than two isolated personalities.',
    'When hidden-stage authority appears in Gensokyo, attendants often matter less as independent household figures than as visible mechanisms of invitation, selection, and stage management. Satono and Mai belong to that category.',
    '["claim_satono_selected_attendant","claim_mai_backstage_executor","claim_backdoor_attendants_pairing","claim_backdoor_realm_profile"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'historian_note_akyuu_market_rest_routes',
    'gensokyo_main',
    'akyuu',
    'theme',
    'market_rest_routes',
    'editorial',
    'On Informal Market Routes',
    'Akyuu notes that market circulation in Gensokyo depends on informal resting places as much as on overt stalls.',
    'Trade in Gensokyo rarely persists by commerce alone. Repeated exchange is often stabilized by places where people pause, smoke, gossip, and loosen their guard. Figures such as Sannyo become important because they embody that social layer.',
    '["claim_sannyo_informal_merchant","claim_market_route_rest_stops","claim_rainbow_dragon_cave_profile"]'::jsonb,
    '{}'::jsonb
  )
on conflict (id) do update
set note_kind = excluded.note_kind,
    title = excluded.title,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();

-- END FILE: WORLD_SEED_HISTORIAN_NOTES_BACKDOOR_MARKET.sql

-- BEGIN FILE: WORLD_SEED_WIKI_SOCIAL_PATTERNS_RESIDUAL.sql
-- World seed: residual social-pattern wiki pages

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  (
    'wiki_term_backdoor_service',
    'gensokyo_main',
    'terms/backdoor-service',
    'Backdoor Service',
    'glossary',
    'term',
    'backdoor_service',
    'A glossary page for hidden-stage service, selective invitation, and attendant choreography around the Backdoor Realm.',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_term_market_rest_stops',
    'gensokyo_main',
    'terms/market-rest-stops',
    'Market Rest Stops',
    'glossary',
    'term',
    'market_rest_stops',
    'A glossary page for the low-pressure social spaces that keep Gensokyo market routes alive.',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  )
on conflict (id) do update
set slug = excluded.slug,
    title = excluded.title,
    page_type = excluded.page_type,
    subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    summary = excluded.summary,
    status = excluded.status,
    canonical_book_id = excluded.canonical_book_id,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_wiki_page_sections (
  id, page_id, section_code, section_order, heading, summary, body, source_ref_ids, metadata
)
values
  (
    'wiki_term_backdoor_service:section:definition',
    'wiki_term_backdoor_service',
    'definition',
    1,
    'Definition',
    'Backdoor service as selective hidden-stage labor.',
    'Backdoor service should be read as a visible form of hidden-stage labor in which attendants turn invitation, selection, and staged access into a social mechanism.',
    '["claim_satono_selected_attendant","claim_mai_backstage_executor","claim_backdoor_attendants_pairing","claim_backdoor_realm_profile"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_term_market_rest_stops:section:definition',
    'wiki_term_market_rest_stops',
    'definition',
    1,
    'Definition',
    'Market rest stops as soft infrastructure.',
    'Market rest stops are the smoke breaks, pause points, and conversational shelters that make Gensokyo trade routes feel lived in rather than purely transactional.',
    '["claim_sannyo_informal_merchant","claim_market_route_rest_stops","claim_rainbow_dragon_cave_profile"]'::jsonb,
    '{}'::jsonb
  )
on conflict (id) do update
set heading = excluded.heading,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();

-- END FILE: WORLD_SEED_WIKI_SOCIAL_PATTERNS_RESIDUAL.sql

-- BEGIN FILE: WORLD_SEED_CHAT_VOICE_PATCH_RESIDUAL.sql
-- World seed: residual voice patch for backdoor and market cast

insert into public.world_chat_context_cache (
  id, world_id, user_scope, character_id, location_id, event_id, context_type, summary, payload, freshness_score, last_used_at
)
values
  (
    'chat_voice_satono_core',
    'gensokyo_main',
    'global',
    'satono',
    null,
    null,
    'character_voice',
    'Satono should sound bright and obedient on the surface, with selective hidden-stage service always just beneath it.',
    jsonb_build_object(
      'speech_style', 'bright, obedient, eerie',
      'worldview', 'A chosen role is easiest to play once you decide to step into it before being asked twice.',
      'claim_ids', array['claim_satono_selected_attendant','claim_backdoor_attendants_pairing','claim_backdoor_realm_profile']
    ),
    0.82,
    now()
  ),
  (
    'chat_voice_mai_core',
    'gensokyo_main',
    'global',
    'mai',
    null,
    null,
    'character_voice',
    'Mai should sound energetic and sharp, like hidden-stage service is already halfway to a dance or execution routine.',
    jsonb_build_object(
      'speech_style', 'energetic, sharp, obedient',
      'worldview', 'If the backstage belongs to you, move first and let everyone else realize it later.',
      'claim_ids', array['claim_mai_backstage_executor','claim_backdoor_attendants_pairing','claim_backdoor_realm_profile']
    ),
    0.82,
    now()
  ),
  (
    'chat_voice_sannyo_core',
    'gensokyo_main',
    'global',
    'sannyo',
    null,
    null,
    'character_voice',
    'Sannyo should sound relaxed and smoky, like people have already sat down long enough to start telling the truth.',
    jsonb_build_object(
      'speech_style', 'relaxed, smoky, practical',
      'worldview', 'A route really works once people linger there for reasons other than buying something.',
      'claim_ids', array['claim_sannyo_informal_merchant','claim_market_route_rest_stops','claim_rainbow_dragon_cave_profile']
    ),
    0.82,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

-- END FILE: WORLD_SEED_CHAT_VOICE_PATCH_RESIDUAL.sql

-- BEGIN FILE: WORLD_SEED_CHARACTER_ABILITIES_RESIDUAL_SUPPORT.sql
-- World seed: residual support-cast abilities

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_ability_wakasagihime','character_ability','Wakasagihime Ability Frame','Wakasagihime belongs to local water poise, reflective calm, and small-scale lake presence.',jsonb_build_object('character_id','wakasagihime'),'["ability","wakasagihime"]'::jsonb,65),
  ('gensokyo_main','lore_ability_sekibanki','character_ability','Sekibanki Ability Frame','Sekibanki should read through divided presence, guarded identity, and uncanny village-edge mobility.',jsonb_build_object('character_id','sekibanki'),'["ability","sekibanki"]'::jsonb,68),
  ('gensokyo_main','lore_ability_kagerou','character_ability','Kagerou Ability Frame','Kagerou scenes should combine instinct, moon-conditioned exposure, and earnest embarrassment.',jsonb_build_object('character_id','kagerou'),'["ability","kagerou"]'::jsonb,67),
  ('gensokyo_main','lore_ability_benben','character_ability','Benben Ability Frame','Benben belongs to composed public performance and confident tsukumogami stage presence.',jsonb_build_object('character_id','benben'),'["ability","benben"]'::jsonb,66),
  ('gensokyo_main','lore_ability_yatsuhashi','character_ability','Yatsuhashi Ability Frame','Yatsuhashi works through lively performance, sharp rhythm, and visible insistence on attention.',jsonb_build_object('character_id','yatsuhashi'),'["ability","yatsuhashi"]'::jsonb,66),
  ('gensokyo_main','lore_ability_seiran','character_ability','Seiran Ability Frame','Seiran should feel like energetic enlisted pressure rather than high command or abstract lunar politics.',jsonb_build_object('character_id','seiran'),'["ability","seiran"]'::jsonb,67),
  ('gensokyo_main','lore_ability_ringo','character_ability','Ringo Ability Frame','Ringo makes lunar life feel routine, inhabited, and structurally ordinary beneath strategic conflict.',jsonb_build_object('character_id','ringo'),'["ability","ringo"]'::jsonb,67),
  ('gensokyo_main','lore_ability_mayumi','character_ability','Mayumi Ability Frame','Mayumi belongs to disciplined formation, carved duty, and straightforward constructed loyalty.',jsonb_build_object('character_id','mayumi'),'["ability","mayumi"]'::jsonb,70)
on conflict (world_id, id) do update
set category = excluded.category,
    title = excluded.title,
    summary = excluded.summary,
    details = excluded.details,
    tags = excluded.tags,
    priority = excluded.priority,
    updated_at = now();

insert into public.world_canon_claims (
  id, world_id, subject_type, subject_id, claim_type, summary, details, source_id, confidence, priority, tags
)
values
  ('claim_ability_wakasagihime','gensokyo_main','character','wakasagihime','ability','Wakasagihime is associated with water poise, reflective calm, and a local mermaid presence tied to lake margins.',jsonb_build_object('ability_theme','local_water_presence'),'src_ddc','official',66,'["ability","wakasagihime","ddc"]'::jsonb),
  ('claim_ability_sekibanki','gensokyo_main','character','sekibanki','ability','Sekibanki is defined by divided presence, detached heads, and uncanny mobility around public edges.',jsonb_build_object('ability_theme','divided_presence'),'src_ddc','official',69,'["ability","sekibanki","ddc"]'::jsonb),
  ('claim_ability_kagerou','gensokyo_main','character','kagerou','ability','Kagerou belongs to werewolf instinct, lunar exposure, and emotionally visible restraint.',jsonb_build_object('ability_theme','moonlit_instinct'),'src_ddc','official',68,'["ability","kagerou","ddc"]'::jsonb),
  ('claim_ability_benben','gensokyo_main','character','benben','ability','Benben expresses musical confidence, ensemble presence, and self-possessed tsukumogami performance.',jsonb_build_object('ability_theme','ensemble_performance'),'src_ddc','official',67,'["ability","benben","ddc"]'::jsonb),
  ('claim_ability_yatsuhashi','gensokyo_main','character','yatsuhashi','ability','Yatsuhashi is tied to sharp rhythm, expressive performance, and energetic tsukumogami visibility.',jsonb_build_object('ability_theme','expressive_rhythm'),'src_ddc','official',67,'["ability","yatsuhashi","ddc"]'::jsonb),
  ('claim_ability_seiran','gensokyo_main','character','seiran','ability','Seiran should be framed through energetic soldiery, practical movement, and lunar enlisted routine.',jsonb_build_object('ability_theme','enlisted_mobility'),'src_lolk','official',68,'["ability","seiran","lolk"]'::jsonb),
  ('claim_ability_ringo','gensokyo_main','character','ringo','ability','Ringo is associated with practical daily-lunar life, appetite, and staffed normalcy under larger conflict.',jsonb_build_object('ability_theme','daily_lunar_normalcy'),'src_lolk','official',68,'["ability","ringo","lolk"]'::jsonb),
  ('claim_ability_mayumi','gensokyo_main','character','mayumi','ability','Mayumi belongs to disciplined formation, haniwa duty, and constructed defense under explicit command.',jsonb_build_object('ability_theme','constructed_discipline'),'src_wbawc','official',72,'["ability","mayumi","wbawc"]'::jsonb)
on conflict (id) do update
set subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    claim_type = excluded.claim_type,
    summary = excluded.summary,
    details = excluded.details,
    source_id = excluded.source_id,
    confidence = excluded.confidence,
    priority = excluded.priority,
    tags = excluded.tags,
    updated_at = now();

-- END FILE: WORLD_SEED_CHARACTER_ABILITIES_RESIDUAL_SUPPORT.sql

-- BEGIN FILE: WORLD_SEED_WIKI_CHAT_RESIDUAL_SUPPORT.sql
-- World seed: residual support-cast wiki and chat coverage

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  ('wiki_character_wakasagihime','gensokyo_main','characters/wakasagihime','Wakasagihime','character','character','wakasagihime','A lake-local mermaid whose quietness gives Misty Lake scenes dignity and calm.', 'published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_sekibanki','gensokyo_main','characters/sekibanki','Sekibanki','character','character','sekibanki','A village-edge uncanny whose divided presence makes ordinary streets feel slightly unreliable.', 'published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_kagerou','gensokyo_main','characters/kagerou-imaizumi','Kagerou Imaizumi','character','character','kagerou','A bamboo-forest werewolf whose scenes mix instinct, shyness, and moonlit exposure.', 'published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_benben','gensokyo_main','characters/benben-tsukumo','Benben Tsukumo','character','character','benben','A poised tsukumogami performer whose music gives public scenes shape and respectability.', 'published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_yatsuhashi','gensokyo_main','characters/yatsuhashi-tsukumo','Yatsuhashi Tsukumo','character','character','yatsuhashi','A lively tsukumogami performer whose expressiveness pushes ensemble scenes into motion.', 'published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_seiran','gensokyo_main','characters/seiran','Seiran','character','character','seiran','A moon-rabbit soldier who makes lunar conflict feel staffed by actual enlisted workers.', 'published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_ringo','gensokyo_main','characters/ringo','Ringo','character','character','ringo','A moon-rabbit dango seller whose routine gives lunar settings everyday life.', 'published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_clownpiece','gensokyo_main','characters/clownpiece','Clownpiece','character','character','clownpiece','A hell-backed fairy whose brightness destabilizes scenes instead of lightening them.', 'published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_mayumi','gensokyo_main','characters/mayumi-joutouguu','Mayumi Joutouguu','character','character','mayumi','A disciplined haniwa soldier whose role is to make Beast Realm defense feel organized and constructed.', 'published','chronicle_gensokyo_history','{}'::jsonb)
on conflict (id) do update
set slug = excluded.slug,
    title = excluded.title,
    page_type = excluded.page_type,
    subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    summary = excluded.summary,
    status = excluded.status,
    canonical_book_id = excluded.canonical_book_id,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_wiki_page_sections (
  id, page_id, section_code, section_order, heading, summary, body, source_ref_ids, metadata
)
values
  ('wiki_character_wakasagihime:section:overview','wiki_character_wakasagihime','overview',1,'Overview','Wakasagihime as calm local water presence.','Wakasagihime is strongest when lake scenes need reflective calm and local dignity rather than large-scale incident pressure.','["claim_wakasagihime_local_lake","claim_ability_wakasagihime"]'::jsonb,'{}'::jsonb),
  ('wiki_character_sekibanki:section:overview','wiki_character_sekibanki','overview',1,'Overview','Sekibanki as divided public-edge unease.','Sekibanki helps village-edge scenes feel slightly unreliable by making ordinary public space capable of splitting open into the uncanny.','["claim_sekibanki_village_uncanny","claim_ability_sekibanki"]'::jsonb,'{}'::jsonb),
  ('wiki_character_kagerou:section:overview','wiki_character_kagerou','overview',1,'Overview','Kagerou as moonlit instinct and restraint.','Kagerou works best when bamboo-forest scenes need instinctive force held in awkward, visible restraint.','["claim_kagerou_bamboo_night","claim_ability_kagerou"]'::jsonb,'{}'::jsonb),
  ('wiki_character_benben:section:overview','wiki_character_benben','overview',1,'Overview','Benben as poised public performance.','Benben gives tsukumogami performance scenes confidence and social legitimacy instead of mere novelty.','["claim_benben_performer","claim_ability_benben"]'::jsonb,'{}'::jsonb),
  ('wiki_character_yatsuhashi:section:overview','wiki_character_yatsuhashi','overview',1,'Overview','Yatsuhashi as expressive rhythm.','Yatsuhashi brings visible momentum to ensemble scenes by treating attention as something to actively seize.','["claim_yatsuhashi_performer","claim_ability_yatsuhashi"]'::jsonb,'{}'::jsonb),
  ('wiki_character_seiran:section:overview','wiki_character_seiran','overview',1,'Overview','Seiran as enlisted lunar motion.','Seiran makes lunar conflicts feel staffed by energetic rank-and-file action rather than only top-level planners.','["claim_seiran_soldier","claim_ability_seiran"]'::jsonb,'{}'::jsonb),
  ('wiki_character_ringo:section:overview','wiki_character_ringo','overview',1,'Overview','Ringo as daily lunar routine.','Ringo helps the moon feel lived in by giving it appetite, repetition, and ordinary working rhythm.','["claim_ringo_daily_lunar","claim_ability_ringo"]'::jsonb,'{}'::jsonb),
  ('wiki_character_clownpiece:section:overview','wiki_character_clownpiece','overview',1,'Overview','Clownpiece as infernal brightness.','Clownpiece should read as bright destabilization backed by infernal pressure, not as harmless comic noise.','["claim_ability_clownpiece"]'::jsonb,'{}'::jsonb),
  ('wiki_character_mayumi:section:overview','wiki_character_mayumi','overview',1,'Overview','Mayumi as disciplined haniwa duty.','Mayumi gives Beast Realm defense scenes formation, duty, and constructed loyalty rather than wild aggression.','["claim_ability_mayumi"]'::jsonb,'{}'::jsonb)
on conflict (id) do update
set heading = excluded.heading,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_chat_context_cache (
  id, world_id, user_scope, character_id, location_id, event_id, context_type, summary, payload, freshness_score, last_used_at
)
values
  (
    'chat_voice_clownpiece_core',
    'gensokyo_main',
    'global',
    'clownpiece',
    null,
    null,
    'character_voice',
    'Clownpiece should sound loud and gleeful, but with infernal backing that makes the brightness itself abrasive.',
    jsonb_build_object(
      'speech_style', 'loud, gleeful, abrasive',
      'worldview', 'If enough pressure is wrapped in color and noise, people mistake it for play until it is too late.',
      'claim_ids', array['claim_ability_clownpiece']
    ),
    0.82,
    now()
  ),
  (
    'chat_voice_mayumi_core',
    'gensokyo_main',
    'global',
    'mayumi',
    null,
    null,
    'character_voice',
    'Mayumi should sound formal and dutiful, like hesitation would be a design flaw rather than a feeling.',
    jsonb_build_object(
      'speech_style', 'formal, dutiful, plain',
      'worldview', 'A properly made defender does not need to wonder what its station requires.',
      'claim_ids', array['claim_ability_mayumi']
    ),
    0.82,
    now()
  ),
  (
    'chat_context_global_wakasagihime_lake',
    'gensokyo_main',
    'global',
    'wakasagihime',
    'misty_lake',
    null,
    'character_location_story',
    'Wakasagihime at Misty Lake should feel local, reflective, and quiet enough that small changes in water or mood matter.',
    jsonb_build_object(
      'claim_ids', array['claim_wakasagihime_local_lake','claim_ability_wakasagihime'],
      'location_ids', array['misty_lake']
    ),
    0.80,
    now()
  ),
  (
    'chat_context_global_kagerou_bamboo',
    'gensokyo_main',
    'global',
    'kagerou',
    'bamboo_forest',
    null,
    'character_location_story',
    'Kagerou in the Bamboo Forest should feel like instinct held just tightly enough to stay social.',
    jsonb_build_object(
      'claim_ids', array['claim_kagerou_bamboo_night','claim_ability_kagerou'],
      'location_ids', array['bamboo_forest']
    ),
    0.80,
    now()
  ),
  (
    'chat_context_global_seiran_ringo_lunar',
    'gensokyo_main',
    'global',
    null,
    'lunar_capital',
    null,
    'location_story',
    'Lower-level lunar scenes should feel staffed by people like Seiran and Ringo, where routine and enlisted work support the larger political machinery.',
    jsonb_build_object(
      'claim_ids', array['claim_seiran_soldier','claim_ringo_daily_lunar','claim_ability_seiran','claim_ability_ringo','claim_lunar_capital_profile'],
      'location_ids', array['lunar_capital']
    ),
    0.80,
    now()
  ),
  (
    'chat_context_global_mayumi_beast_realm',
    'gensokyo_main',
    'global',
    'mayumi',
    'beast_realm',
    null,
    'character_location_story',
    'Mayumi in the Beast Realm should emphasize formation, defense, and the visible discipline of a made soldier.',
    jsonb_build_object(
      'claim_ids', array['claim_ability_mayumi','claim_beast_realm_profile'],
      'location_ids', array['beast_realm']
    ),
    0.81,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

-- END FILE: WORLD_SEED_WIKI_CHAT_RESIDUAL_SUPPORT.sql

-- BEGIN FILE: WORLD_SEED_CHRONICLE_MICRO_TEXTURES_FINAL.sql
-- World seed: final micro-texture chronicle and historian notes

insert into public.world_chronicle_chapters (
  id, book_id, chapter_code, chapter_order, title, summary, period_start, period_end, metadata
)
values
  (
    'chronicle_chapter_regional_customs',
    'chronicle_gensokyo_history',
    'regional_customs',
    10,
    'Regional Customs and Everyday Texture',
    'A chapter for the small local habits, route logic, and social atmospheres that make Gensokyo legible between major incidents.',
    null,
    null,
    '{}'::jsonb
  ),
  (
    'chronicle_chapter_recent_incidents',
    'chronicle_gensokyo_history',
    'recent_incidents_texture',
    11,
    'Recent Incidents and Social Texture',
    'A chapter for the social details and rank-and-file realities surrounding later major incidents.',
    null,
    null,
    '{}'::jsonb
  )
on conflict (id) do update
set book_id = excluded.book_id,
    chapter_code = excluded.chapter_code,
    chapter_order = excluded.chapter_order,
    title = excluded.title,
    summary = excluded.summary,
    period_start = excluded.period_start,
    period_end = excluded.period_end,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_chronicle_entries (
  id, book_id, chapter_id, entry_code, entry_order, entry_type, title, summary, body,
  subject_type, subject_id, narrator_character_id, event_id, history_id, tags, metadata
)
values
  (
    'chronicle_entry_misty_lake_local_calm',
    'chronicle_gensokyo_history',
    'chronicle_chapter_regional_customs',
    'misty_lake_local_calm',
    70,
    'regional_note',
    'Misty Lake and Local Calm',
    'Even noisy lakeside areas preserve a quiet local layer beneath fairy movement and mansion traffic.',
    'Misty Lake is not only a place of fairy noise and incidental trouble. Its local atmosphere also depends on quieter presences whose value is measured by steadiness, reflection, and familiarity with the water''s margin.',
    'location',
    'misty_lake',
    'akyuu',
    null,
    null,
    '["misty_lake","regional_texture","wakasagihime"]'::jsonb,
    jsonb_build_object('claim_ids', array['claim_glossary_misty_lake','claim_wakasagihime_local_lake','claim_ability_wakasagihime'])
  ),
  (
    'chronicle_entry_bamboo_forest_social_routes',
    'chronicle_gensokyo_history',
    'chronicle_chapter_regional_customs',
    'bamboo_forest_social_routes',
    71,
    'regional_note',
    'Bamboo Forest and Social Routes',
    'The Bamboo Forest stays livable because instinct, luck, and local guidance all act as route-making forces.',
    'The Bamboo Forest is not navigated by geography alone. Its ordinary usability depends on local beings whose instincts, tricks, or long familiarity turn a maze into a social route.',
    'location',
    'bamboo_forest',
    'akyuu',
    null,
    null,
    '["bamboo_forest","regional_texture","routes"]'::jsonb,
    jsonb_build_object('claim_ids', array['claim_glossary_bamboo_forest','claim_kagerou_bamboo_night','claim_ability_kagerou'])
  ),
  (
    'chronicle_entry_lunar_rank_and_file',
    'chronicle_gensokyo_history',
    'chronicle_chapter_recent_incidents',
    'lunar_rank_and_file',
    72,
    'social_note',
    'Lunar Rank-and-File Presence',
    'The moon''s settings feel real only when ordinary rabbit labor and routine are visible beneath high strategy.',
    'Lunar politics easily become too distant if only nobles and strategists are remembered. Daily work, appetite, and enlisted motion keep that world from flattening into pure abstraction.',
    'theme',
    'lunar_rank_and_file',
    'akyuu',
    null,
    null,
    '["lunar_capital","lunar_rank_and_file","recent_incidents"]'::jsonb,
    jsonb_build_object('claim_ids', array['claim_seiran_soldier','claim_ringo_daily_lunar','claim_ability_seiran','claim_ability_ringo','claim_lunar_capital_profile'])
  ),
  (
    'chronicle_entry_beast_realm_defense_texture',
    'chronicle_gensokyo_history',
    'chronicle_chapter_recent_incidents',
    'beast_realm_defense_texture',
    73,
    'social_note',
    'Beast Realm Defense Texture',
    'Beast Realm order is not only predation; it also appears through formation, discipline, and constructed loyalty.',
    'Scenes from the Beast Realm grow more legible when defense and rank are represented by figures built for duty rather than only by reckless power or faction slogans.',
    'theme',
    'beast_realm_defense',
    'akyuu',
    null,
    null,
    '["beast_realm","formation","recent_incidents"]'::jsonb,
    jsonb_build_object('claim_ids', array['claim_ability_mayumi','claim_beast_realm_profile'])
  )
on conflict (id) do update
set book_id = excluded.book_id,
    chapter_id = excluded.chapter_id,
    entry_code = excluded.entry_code,
    entry_order = excluded.entry_order,
    entry_type = excluded.entry_type,
    title = excluded.title,
    summary = excluded.summary,
    body = excluded.body,
    subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    narrator_character_id = excluded.narrator_character_id,
    event_id = excluded.event_id,
    history_id = excluded.history_id,
    tags = excluded.tags,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_historian_notes (
  id, world_id, historian_character_id, subject_type, subject_id, note_kind, title, summary, body, source_ref_ids, metadata
)
values
  (
    'historian_note_akyuu_misty_lake_local_calm',
    'gensokyo_main',
    'akyuu',
    'location',
    'misty_lake',
    'editorial',
    'On Misty Lake Locality',
    'Akyuu notes that Misty Lake should not be reduced to fairy noise and mansion approach alone.',
    'Even locations famous for visible trouble retain quieter inhabitants who give them continuity. Misty Lake gains depth when local calm is remembered alongside spectacle.',
    '["claim_glossary_misty_lake","claim_wakasagihime_local_lake","claim_ability_wakasagihime"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'historian_note_akyuu_bamboo_social_routes',
    'gensokyo_main',
    'akyuu',
    'location',
    'bamboo_forest',
    'editorial',
    'On Bamboo Forest Routes',
    'Akyuu frames the Bamboo Forest as socially navigated, not merely geographically confusing.',
    'A forest becomes livable when local beings repeatedly turn danger and obscurity into recognizable pathways. In that sense, instinct and trickery are as infrastructural as roads.',
    '["claim_glossary_bamboo_forest","claim_kagerou_bamboo_night","claim_ability_kagerou"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'historian_note_akyuu_lunar_rank_and_file',
    'gensokyo_main',
    'akyuu',
    'theme',
    'lunar_rank_and_file',
    'editorial',
    'On Lunar Routine',
    'Akyuu notes that even the moon requires ordinary routine to remain legible as a society.',
    'Grand strategy alone does not make a social world. Figures like Seiran and Ringo matter because they imply kitchens, orders, pauses, and repeated tasks beneath the visible conflict.',
    '["claim_seiran_soldier","claim_ringo_daily_lunar","claim_ability_seiran","claim_ability_ringo","claim_lunar_capital_profile"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'historian_note_akyuu_beast_realm_formation',
    'gensokyo_main',
    'akyuu',
    'theme',
    'beast_realm_defense',
    'editorial',
    'On Beast Realm Formation',
    'Akyuu notes that later Beast Realm scenes became clearer once discipline and made soldiery were treated as part of the picture.',
    'Predatory realms are easy to flatten into chaos. They become more intelligible when one also records their habits of defense, formation, and constructed obligation.',
    '["claim_ability_mayumi","claim_beast_realm_profile"]'::jsonb,
    '{}'::jsonb
  )
on conflict (id) do update
set note_kind = excluded.note_kind,
    title = excluded.title,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();

-- END FILE: WORLD_SEED_CHRONICLE_MICRO_TEXTURES_FINAL.sql

-- BEGIN FILE: WORLD_SEED_VECTOR_BOOTSTRAP.sql
-- World seed: vector-ready bootstrap
-- Builds embedding documents from the loaded world_* canon and queues jobs.

select public.world_refresh_embedding_documents('gensokyo_main');

select public.world_queue_embedding_refresh('gensokyo_main');

-- END FILE: WORLD_SEED_VECTOR_BOOTSTRAP.sql
