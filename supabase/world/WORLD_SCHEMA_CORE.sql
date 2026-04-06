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

