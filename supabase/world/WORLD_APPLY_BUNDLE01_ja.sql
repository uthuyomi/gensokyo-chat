-- 自動生成された日本語版: WORLD_APPLY_BUNDLE01.sql



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
        '主張: ' || c.summary,
        '対象: ' || c.subject_type || ' / ' || c.subject_id,
        '分類: ' || c.claim_type,
        '詳細: ' || coalesce(c.details::text, '{}')
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
        '分類: ' || l.category,
        '詳細: ' || coalesce(l.details::text, '{}')
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
        '文脈種別: ' || c.context_type,
        case when c.character_id is not null then '対象キャラクター: ' || c.character_id else null end,
        case when c.location_id is not null and c.location_id <> '' then '対象地点: ' || c.location_id else null end,
        case when c.event_id is not null then '対象イベント: ' || c.event_id else null end,
        '内容: ' || coalesce(c.payload::text, '{}')
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
insert into public.worlds (
  id, layer_id, name
)
values (
  'gensokyo_main',
  'gensokyo',
  '幻想郷'
)
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
    '博麗神社',
    'major_location',
    null,
    '博麗神社の地域情報',
    '博麗神社に関する基本地点情報です。',
    '博麗神社の特徴や周辺とのつながりを日本語で整理した説明です。',
    '["shrine","public","outdoor"]'::jsonb,
    '落ち着いた雰囲気',
    '["human_village","youkai_mountain_foot"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'human_village',
    '人里',
    'major_location',
    null,
    '人里の地域情報',
    '人里に関する基本地点情報です。',
    '人里の特徴や周辺とのつながりを日本語で整理した説明です。',
    '["village","public","busy"]'::jsonb,
    '落ち着いた雰囲気',
    '["hakurei_shrine","forest_of_magic"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'forest_of_magic',
    '魔法の森',
    'major_location',
    null,
    '魔法の森の地域情報',
    '魔法の森に関する基本地点情報です。',
    '魔法の森の特徴や周辺とのつながりを日本語で整理した説明です。',
    '["forest","quiet","magic"]'::jsonb,
    '落ち着いた雰囲気',
    '["human_village"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'youkai_mountain_foot',
    '妖怪の山の麓',
    'major_location',
    null,
    '妖怪の山の麓の地域情報',
    '妖怪の山の麓に関する基本地点情報です。',
    '妖怪の山の麓の特徴や周辺とのつながりを日本語で整理した説明です。',
    '["mountain","outdoor"]'::jsonb,
    '落ち着いた雰囲気',
    '["hakurei_shrine","kappa_workshop"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'kappa_workshop',
    '河童工房',
    'major_location',
    null,
    '河童工房の地域情報',
    '河童工房に関する基本地点情報です。',
    '河童工房の特徴や周辺とのつながりを日本語で整理した説明です。',
    '["indoor","kappa","engineering"]'::jsonb,
    '落ち着いた雰囲気',
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
  world_id, id, name, title, species, faction_id, home_location_id, default_location_id, public_summary, private_notes, speech_style, worldview, role_in_gensokyo, tags, profile
)
values
  (
    'gensokyo_main',
    'reimu',
    '博麗 霊夢',
    '楽園の巫女',
    '人間',
    'hakurei',
    'hakurei_shrine',
    'hakurei_shrine',
    '博麗 霊夢に関する基本人物紹介です。',
    '博麗 霊夢を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '博麗 霊夢の価値観や見方を整理した文面です。',
    '博麗 霊夢の役割です。',
    '["lead","shrine","official"]'::jsonb,
    jsonb_build_object('表示名', '博麗 霊夢', '肩書き', '楽園の巫女', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'marisa',
    '霧雨 魔理沙',
    '普通の魔法使い',
    '人間',
    'independent',
    'forest_of_magic',
    'forest_of_magic',
    '霧雨 魔理沙に関する基本人物紹介です。',
    '霧雨 魔理沙を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '霧雨 魔理沙の価値観や見方を整理した文面です。',
    '霧雨 魔理沙の役割です。',
    '["lead","magic","mobile"]'::jsonb,
    jsonb_build_object('表示名', '霧雨 魔理沙', '肩書き', '普通の魔法使い', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'sanae',
    '東風谷 早苗',
    '祀られる風の人間',
    '人間',
    'moriya',
    'youkai_mountain_foot',
    'youkai_mountain_foot',
    '東風谷 早苗に関する基本人物紹介です。',
    '東風谷 早苗を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '東風谷 早苗の価値観や見方を整理した文面です。',
    '東風谷 早苗の役割です。',
    '["support","ritual","festival"]'::jsonb,
    jsonb_build_object('表示名', '東風谷 早苗', '肩書き', '祀られる風の人間', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'nitori',
    '河城 にとり',
    '超妖怪弾頭',
    '河童',
    'kappa',
    'kappa_workshop',
    'kappa_workshop',
    '河城 にとりに関する基本人物紹介です。',
    '河城 にとりを配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '河城 にとりの価値観や見方を整理した文面です。',
    '河城 にとりの役割です。',
    '["kappa","engineering","observer"]'::jsonb,
    jsonb_build_object('表示名', '河城 にとり', '肩書き', '超妖怪弾頭', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'aya',
    '射命丸 文',
    '伝統の幻想ブン屋',
    '天狗',
    'tengu',
    'youkai_mountain_foot',
    'youkai_mountain_foot',
    '射命丸 文に関する基本人物紹介です。',
    '射命丸 文を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '射命丸 文の価値観や見方を整理した文面です。',
    '射命丸 文の役割です。',
    '["reporter","tengu","rumor"]'::jsonb,
    jsonb_build_object('表示名', '射命丸 文', '肩書き', '伝統の幻想ブン屋', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
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
  (
    'gensokyo_main',
    'reimu',
    'marisa',
    'familiar_rival',
    '博麗 霊夢と霧雨 魔理沙のあいだにある気心の知れた好敵手関係を示す関係データです。',
    0.82,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'marisa',
    'reimu',
    'familiar_rival',
    '霧雨 魔理沙と博麗 霊夢のあいだにある気心の知れた好敵手関係を示す関係データです。',
    0.82,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'reimu',
    'sanae',
    'competing_peer',
    '博麗 霊夢と東風谷 早苗のあいだにある競い合う同格関係を示す関係データです。',
    0.58,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'sanae',
    'reimu',
    'competing_peer',
    '東風谷 早苗と博麗 霊夢のあいだにある競い合う同格関係を示す関係データです。',
    0.58,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'nitori',
    'aya',
    'mutual_observer',
    '河城 にとりと射命丸 文のあいだにある互いを観察し合う関係を示す関係データです。',
    0.51,
    '{}'::jsonb
  )
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
    '幻想郷設定項目',
    '幻想郷全体に関わる基本ルールを整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'world_rule', '説明', '日本語表示向けに整理した説明データです。'),
    '["canon","balance","constraint"]'::jsonb,
    100
  ),
  (
    'gensokyo_main',
    'lore_hakurei_role',
    'character_role',
    '幻想郷設定項目',
    '人物の立ち位置や役割を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_role', '説明', '日本語表示向けに整理した説明データです。'),
    '["reimu","shrine","canon"]'::jsonb,
    90
  ),
  (
    'gensokyo_main',
    'lore_village_rumor',
    'location_trait',
    '幻想郷設定項目',
    '土地ごとの性質や役割を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'location_trait', '説明', '日本語表示向けに整理した説明データです。'),
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
  (
    'gensokyo_main',
    '',
    'day',
    'clear',
    'spring',
    'waxing',
    null
  ),
  (
    'gensokyo_main',
    'hakurei_shrine',
    'day',
    'clear',
    'spring',
    'waxing',
    null
  ),
  (
    'gensokyo_main',
    'human_village',
    'day',
    'clear',
    'spring',
    'waxing',
    null
  ),
  (
    'gensokyo_main',
    'forest_of_magic',
    'day',
    'clear',
    'spring',
    'waxing',
    null
  ),
  (
    'gensokyo_main',
    'kappa_workshop',
    'day',
    'clear',
    'spring',
    'waxing',
    null
  )
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
  (
    'gensokyo_main',
    'reimu',
    'hakurei_shrine',
    'organizing',
    'guarded'
  ),
  (
    'gensokyo_main',
    'marisa',
    'forest_of_magic',
    'preparing',
    'curious'
  ),
  (
    'gensokyo_main',
    'sanae',
    'youkai_mountain_foot',
    'coordinating',
    'optimistic'
  ),
  (
    'gensokyo_main',
    'nitori',
    'kappa_workshop',
    'building',
    'focused'
  ),
  (
    'gensokyo_main',
    'aya',
    'human_village',
    'gathering_rumors',
    'interested'
  )
on conflict (world_id, npc_id) do update
set location_id = excluded.location_id,
    action = excluded.action,
    emotion = excluded.emotion,
    updated_at = now();

insert into public.world_story_events (
  id, world_id, event_code, title, theme, canon_level, status, start_at, end_at, current_phase_id, current_phase_order, lead_location_id, organizer_character_id, synopsis, narrative_hook, payload, metadata
)
values (
  'story_spring_festival_001',
  'gensokyo_main',
  'spring_festival_001',
  '博麗神社春祭り',
  '博麗神社春祭りに関する主題をまとめた文面です。',
  'official',
  'active',
  now() - interval '6 hour',
  now() + interval '6 day',
  'story_spring_festival_001:phase:preparation',
  2,
  'hakurei_shrine',
  'reimu',
  '博麗神社春祭りの概要を日本語で整理した物語説明です。',
  '博麗神社春祭りに参加するときの導入文です。',
  jsonb_build_object('概要', '博麗神社春祭りの概要を日本語で整理した物語説明です。'),
  jsonb_build_object('状態', '日本語化済み')
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
  id, event_id, phase_code, phase_order, title, status, summary, start_condition, end_condition, required_beats, allowed_locations, active_cast, metadata
)
values
  (
    'story_spring_festival_001:phase:rumor',
    'story_spring_festival_001',
    'rumor',
    1,
    '噂の拡散段階',
    'completed',
    '噂の拡散段階における進行状況をまとめた説明です。',
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
    '準備段階',
    'active',
    '準備段階における進行状況をまとめた説明です。',
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
    '祭り当日段階',
    'pending',
    '祭り当日段階における進行状況をまとめた説明です。',
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
    '事後整理段階',
    'pending',
    '事後整理段階における進行状況をまとめた説明です。',
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
  id, event_id, phase_id, beat_code, beat_kind, title, summary, location_id, actor_ids, is_required, status, happens_at, payload
)
values
  (
    'story_spring_festival_001:beat:rumor_spreads',
    'story_spring_festival_001',
    'story_spring_festival_001:phase:rumor',
    'rumor_spreads',
    'rumor',
    '里に噂が広がります',
    '里に噂が広がりますで起きる要点をまとめた記録です。',
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
    '飾り付け資材が届きます',
    '飾り付け資材が届きますで起きる要点をまとめた記録です。',
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
    '役割分担にずれが見えます',
    '役割分担にずれが見えますで起きる要点をまとめた記録です。',
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
  (
    'story_spring_festival_001:cast:reimu',
    'story_spring_festival_001',
    'reimu',
    'lead',
    'full',
    true,
    'hakurei_shrine',
    '{}'::jsonb,
    '博麗 霊夢がこの出来事で担う役割を示す補足です。'
  ),
  (
    'story_spring_festival_001:cast:marisa',
    'story_spring_festival_001',
    'marisa',
    'disruptor',
    'partial',
    true,
    'hakurei_shrine',
    '{}'::jsonb,
    '霧雨 魔理沙がこの出来事で担う役割を示す補足です。'
  ),
  (
    'story_spring_festival_001:cast:sanae',
    'story_spring_festival_001',
    'sanae',
    'support',
    'full',
    true,
    'hakurei_shrine',
    '{}'::jsonb,
    '東風谷 早苗がこの出来事で担う役割を示す補足です。'
  ),
  (
    'story_spring_festival_001:cast:nitori',
    'story_spring_festival_001',
    'nitori',
    'support',
    'partial',
    false,
    'kappa_workshop',
    '{}'::jsonb,
    '河城 にとりがこの出来事で担う役割を示す補足です。'
  ),
  (
    'story_spring_festival_001:cast:aya',
    'story_spring_festival_001',
    'aya',
    'observer',
    'full',
    false,
    'human_village',
    '{}'::jsonb,
    '射命丸 文がこの出来事で担う役割を示す補足です。'
  )
on conflict (id) do update
set role_type = excluded.role_type,
    knowledge_level = excluded.knowledge_level,
    must_appear = excluded.must_appear,
    primary_location_id = excluded.primary_location_id,
    availability = excluded.availability,
    notes = excluded.notes,
    updated_at = now();

insert into public.world_story_actions (
  id, event_id, phase_id, action_code, title, description, action_kind, location_id, actor_id, is_repeatable, is_active, result_summary, payload
)
values
  (
    'story_spring_festival_001:action:talk_reimu',
    'story_spring_festival_001',
    'story_spring_festival_001:phase:preparation',
    'talk_reimu',
    '霊夢に準備状況を聞きます',
    '博麗神社で霊夢に祭り準備の状況を聞き取る行動です。',
    'talk',
    'hakurei_shrine',
    'reimu',
    true,
    true,
    '祭り準備に対する霊夢の現実的な見方を把握できます。',
    '{}'::jsonb
  ),
  (
    'story_spring_festival_001:action:hear_rumors',
    'story_spring_festival_001',
    'story_spring_festival_001:phase:preparation',
    'hear_rumors',
    '里の噂を集めます',
    '人里で祭りに関する噂や受け止め方を集める行動です。',
    'investigate',
    'human_village',
    'aya',
    true,
    true,
    '祭りが始まる前から世間の空気が形作られていることを確認できます。',
    '{}'::jsonb
  ),
  (
    'story_spring_festival_001:action:help_preparation',
    'story_spring_festival_001',
    'story_spring_festival_001:phase:preparation',
    'help_preparation',
    '準備作業を手伝います',
    '祭りの準備作業に参加して関与の実感を得る行動です。',
    'assist',
    'hakurei_shrine',
    'sanae',
    false,
    true,
    '準備段階への参加記録を残せます。',
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
    '博麗神社春祭りに関する履歴記録です。',
    'human_village',
    '["aya"]'::jsonb,
    jsonb_build_object('説明', '博麗神社春祭りに関する履歴記録です。'),
    now() - interval '4 hour'
  ),
  (
    'story_spring_festival_001:history:preparation_visible',
    'gensokyo_main',
    'story_spring_festival_001',
    'story_spring_festival_001:phase:preparation',
    'canon_fact',
    '博麗神社春祭りに関する履歴記録です。',
    'hakurei_shrine',
    '["reimu","sanae"]'::jsonb,
    jsonb_build_object('説明', '博麗神社春祭りに関する履歴記録です。'),
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
    '博麗 霊夢が出来事をどう受け止めたかをまとめた記憶データです。',
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
    '霧雨 魔理沙が出来事をどう受け止めたかをまとめた記憶データです。',
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
    '射命丸 文が出来事をどう受け止めたかをまとめた記憶データです。',
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
insert into public.world_event_channels (
  channel, world_id, layer_id, location_id, current_seq
)
values
  (
    'world:gensokyo_main',
    'gensokyo_main',
    'gensokyo',
    null,
    0
  ),
  (
    'world:gensokyo_main:hakurei_shrine',
    'gensokyo_main',
    'gensokyo',
    'hakurei_shrine',
    0
  )
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
  (
    'gensokyo_main',
    'misty_lake',
    '霧の湖',
    'major_location',
    null,
    '霧の湖の地域情報',
    '霧の湖に関する基本地点情報です。',
    '霧の湖の特徴や周辺とのつながりを日本語で整理した説明です。',
    '["lake","outdoor","fairy"]'::jsonb,
    '落ち着いた雰囲気',
    '["scarlet_devil_mansion","human_village"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'scarlet_devil_mansion',
    '紅魔館',
    'major_location',
    null,
    '紅魔館の地域情報',
    '紅魔館に関する基本地点情報です。',
    '紅魔館の特徴や周辺とのつながりを日本語で整理した説明です。',
    '["mansion","indoors","elite"]'::jsonb,
    '落ち着いた雰囲気',
    '["misty_lake"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'bamboo_forest',
    '迷いの竹林',
    'major_location',
    null,
    '迷いの竹林の地域情報',
    '迷いの竹林に関する基本地点情報です。',
    '迷いの竹林の特徴や周辺とのつながりを日本語で整理した説明です。',
    '["forest","maze","bamboo"]'::jsonb,
    '落ち着いた雰囲気',
    '["eientei","human_village"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'eientei',
    '永遠亭',
    'major_location',
    null,
    '永遠亭の地域情報',
    '永遠亭に関する基本地点情報です。',
    '永遠亭の特徴や周辺とのつながりを日本語で整理した説明です。',
    '["estate","medicine","lunar"]'::jsonb,
    '落ち着いた雰囲気',
    '["bamboo_forest"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'netherworld',
    '冥界',
    'major_location',
    null,
    '冥界の地域情報',
    '冥界に関する基本地点情報です。',
    '冥界の特徴や周辺とのつながりを日本語で整理した説明です。',
    '["afterlife","spirits","boundary"]'::jsonb,
    '落ち着いた雰囲気',
    '["hakugyokurou"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'hakugyokurou',
    '白玉楼',
    'major_location',
    'netherworld',
    '白玉楼の地域情報',
    '白玉楼に関する基本地点情報です。',
    '白玉楼の特徴や周辺とのつながりを日本語で整理した説明です。',
    '["mansion","spirits","formal"]'::jsonb,
    '落ち着いた雰囲気',
    '["netherworld"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'moriya_shrine',
    '守矢神社',
    'major_location',
    null,
    '守矢神社の地域情報',
    '守矢神社に関する基本地点情報です。',
    '守矢神社の特徴や周辺とのつながりを日本語で整理した説明です。',
    '["shrine","mountain","faith"]'::jsonb,
    '落ち着いた雰囲気',
    '["youkai_mountain_foot"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'former_hell',
    '旧地獄',
    'major_location',
    null,
    '旧地獄の地域情報',
    '旧地獄に関する基本地点情報です。',
    '旧地獄の特徴や周辺とのつながりを日本語で整理した説明です。',
    '["underground","oni","dangerous"]'::jsonb,
    '落ち着いた雰囲気',
    '["old_capital"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'old_capital',
    '旧都',
    'major_location',
    'former_hell',
    '旧都の地域情報',
    '旧都に関する基本地点情報です。',
    '旧都の特徴や周辺とのつながりを日本語で整理した説明です。',
    '["underground","city","oni"]'::jsonb,
    '落ち着いた雰囲気',
    '["former_hell"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'muenzuka',
    '無縁塚',
    'major_location',
    null,
    '無縁塚の地域情報',
    '無縁塚に関する基本地点情報です。',
    '無縁塚の特徴や周辺とのつながりを日本語で整理した説明です。',
    '["boundary","field","liminal"]'::jsonb,
    '落ち着いた雰囲気',
    '["human_village"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'genbu_ravine',
    '玄武の沢',
    'major_location',
    null,
    '玄武の沢の地域情報',
    '玄武の沢に関する基本地点情報です。',
    '玄武の沢の特徴や周辺とのつながりを日本語で整理した説明です。',
    '["mountain","ravine","kappa"]'::jsonb,
    '落ち着いた雰囲気',
    '["youkai_mountain_foot","kappa_workshop"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'myouren_temple',
    '命蓮寺',
    'major_location',
    null,
    '命蓮寺の地域情報',
    '命蓮寺に関する基本地点情報です。',
    '命蓮寺の特徴や周辺とのつながりを日本語で整理した説明です。',
    '["temple","religion","community"]'::jsonb,
    '落ち着いた雰囲気',
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

insert into public.world_characters (
  world_id, id, name, title, species, faction_id, home_location_id, default_location_id, public_summary, private_notes, speech_style, worldview, role_in_gensokyo, tags, profile
)
values
  (
    'gensokyo_main',
    'sakuya',
    '十六夜 咲夜',
    '完全で瀟洒な従者',
    '人間',
    'sdm',
    'scarlet_devil_mansion',
    'scarlet_devil_mansion',
    '十六夜 咲夜に関する基本人物紹介です。',
    '十六夜 咲夜を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '十六夜 咲夜の価値観や見方を整理した文面です。',
    '十六夜 咲夜の役割です。',
    '["maid","sdm","disciplined"]'::jsonb,
    jsonb_build_object('表示名', '十六夜 咲夜', '肩書き', '完全で瀟洒な従者', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'remilia',
    'レミリア・スカーレット',
    '永遠に紅い幼き月',
    '種族',
    'sdm',
    'scarlet_devil_mansion',
    'scarlet_devil_mansion',
    'レミリア・スカーレットに関する基本人物紹介です。',
    'レミリア・スカーレットを配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    'レミリア・スカーレットの価値観や見方を整理した文面です。',
    'レミリア・スカーレットの役割です。',
    '["vampire","sdm","leader"]'::jsonb,
    jsonb_build_object('表示名', 'レミリア・スカーレット', '肩書き', '永遠に紅い幼き月', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'flandre',
    'フランドール・スカーレット',
    '紅魔館のもう一人の主',
    '種族',
    'sdm',
    'scarlet_devil_mansion',
    'scarlet_devil_mansion',
    'フランドール・スカーレットに関する基本人物紹介です。',
    'フランドール・スカーレットを配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    'フランドール・スカーレットの価値観や見方を整理した文面です。',
    'フランドール・スカーレットの役割です。',
    '["vampire","sdm","volatile"]'::jsonb,
    jsonb_build_object('表示名', 'フランドール・スカーレット', '肩書き', '紅魔館のもう一人の主', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'patchouli',
    'パチュリー・ノーレッジ',
    '知識と日陰の少女',
    '魔法使い',
    'sdm',
    'scarlet_devil_mansion',
    'scarlet_devil_mansion',
    'パチュリー・ノーレッジに関する基本人物紹介です。',
    'パチュリー・ノーレッジを配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    'パチュリー・ノーレッジの価値観や見方を整理した文面です。',
    'パチュリー・ノーレッジの役割です。',
    '["magician","sdm","library"]'::jsonb,
    jsonb_build_object('表示名', 'パチュリー・ノーレッジ', '肩書き', '知識と日陰の少女', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'alice',
    'アリス・マーガトロイド',
    '七色の人形遣い',
    '魔法使い',
    'independent',
    'forest_of_magic',
    'forest_of_magic',
    'アリス・マーガトロイドに関する基本人物紹介です。',
    'アリス・マーガトロイドを配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    'アリス・マーガトロイドの価値観や見方を整理した文面です。',
    'アリス・マーガトロイドの役割です。',
    '["magician","puppets","independent"]'::jsonb,
    jsonb_build_object('表示名', 'アリス・マーガトロイド', '肩書き', '七色の人形遣い', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'youmu',
    '魂魄 妖夢',
    '半人半霊の庭師',
    '半人半霊',
    'hakugyokurou',
    'hakugyokurou',
    'hakugyokurou',
    '魂魄 妖夢に関する基本人物紹介です。',
    '魂魄 妖夢を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '魂魄 妖夢の価値観や見方を整理した文面です。',
    '魂魄 妖夢の役割です。',
    '["sword","netherworld","disciplined"]'::jsonb,
    jsonb_build_object('表示名', '魂魄 妖夢', '肩書き', '半人半霊の庭師', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'yuyuko',
    '西行寺 幽々子',
    '華胥の亡霊',
    '種族',
    'hakugyokurou',
    'hakugyokurou',
    'hakugyokurou',
    '西行寺 幽々子に関する基本人物紹介です。',
    '西行寺 幽々子を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '西行寺 幽々子の価値観や見方を整理した文面です。',
    '西行寺 幽々子の役割です。',
    '["ghost","netherworld","noble"]'::jsonb,
    jsonb_build_object('表示名', '西行寺 幽々子', '肩書き', '華胥の亡霊', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'yukari',
    '八雲 紫',
    '神隠しの主犯',
    '妖怪',
    'yakumo',
    'muenzuka',
    'muenzuka',
    '八雲 紫に関する基本人物紹介です。',
    '八雲 紫を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '八雲 紫の価値観や見方を整理した文面です。',
    '八雲 紫の役割です。',
    '["youkai","boundary","high_impact"]'::jsonb,
    jsonb_build_object('表示名', '八雲 紫', '肩書き', '神隠しの主犯', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'chen',
    '橙',
    '凶兆の黒猫',
    '化け猫',
    'yakumo',
    'muenzuka',
    'human_village',
    '橙に関する基本人物紹介です。',
    '橙を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '橙の価値観や見方を整理した文面です。',
    '橙の役割です。',
    '["cat","shikigami","mobile"]'::jsonb,
    jsonb_build_object('表示名', '橙', '肩書き', '凶兆の黒猫', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'ran',
    '八雲 藍',
    'すきま妖怪の式',
    '狐',
    'yakumo',
    'muenzuka',
    'muenzuka',
    '八雲 藍に関する基本人物紹介です。',
    '八雲 藍を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '八雲 藍の価値観や見方を整理した文面です。',
    '八雲 藍の役割です。',
    '["fox","shikigami","competent"]'::jsonb,
    jsonb_build_object('表示名', '八雲 藍', '肩書き', 'すきま妖怪の式', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'keine',
    '上白沢 慧音',
    '歴史を喰らう半獣',
    '半獣',
    'human_village',
    'human_village',
    'human_village',
    '上白沢 慧音に関する基本人物紹介です。',
    '上白沢 慧音を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '上白沢 慧音の価値観や見方を整理した文面です。',
    '上白沢 慧音の役割です。',
    '["teacher","village","protector"]'::jsonb,
    jsonb_build_object('表示名', '上白沢 慧音', '肩書き', '歴史を喰らう半獣', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'mokou',
    '藤原 妹紅',
    '蓬莱の人の形',
    '人間',
    'independent',
    'bamboo_forest',
    'bamboo_forest',
    '藤原 妹紅に関する基本人物紹介です。',
    '藤原 妹紅を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '藤原 妹紅の価値観や見方を整理した文面です。',
    '藤原 妹紅の役割です。',
    '["immortal","bamboo","fighter"]'::jsonb,
    jsonb_build_object('表示名', '藤原 妹紅', '肩書き', '蓬莱の人の形', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'eirin',
    '八意 永琳',
    '月の頭脳',
    '月人',
    'eientei',
    'eientei',
    'eientei',
    '八意 永琳に関する基本人物紹介です。',
    '八意 永琳を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '八意 永琳の価値観や見方を整理した文面です。',
    '八意 永琳の役割です。',
    '["medicine","lunar","strategist"]'::jsonb,
    jsonb_build_object('表示名', '八意 永琳', '肩書き', '月の頭脳', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'kaguya',
    '蓬莱山 輝夜',
    '永遠と須臾の姫君',
    '月人',
    'eientei',
    'eientei',
    'eientei',
    '蓬莱山 輝夜に関する基本人物紹介です。',
    '蓬莱山 輝夜を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '蓬莱山 輝夜の価値観や見方を整理した文面です。',
    '蓬莱山 輝夜の役割です。',
    '["princess","lunar","eientei"]'::jsonb,
    jsonb_build_object('表示名', '蓬莱山 輝夜', '肩書き', '永遠と須臾の姫君', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'reisen',
    '鈴仙・優曇華院・イナバ',
    '狂気の月の兎',
    '月の兎',
    'eientei',
    'eientei',
    'eientei',
    '鈴仙・優曇華院・イナバに関する基本人物紹介です。',
    '鈴仙・優曇華院・イナバを配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '鈴仙・優曇華院・イナバの価値観や見方を整理した文面です。',
    '鈴仙・優曇華院・イナバの役割です。',
    '["rabbit","lunar","assistant"]'::jsonb,
    jsonb_build_object('表示名', '鈴仙・優曇華院・イナバ', '肩書き', '狂気の月の兎', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'kanako',
    '八坂 神奈子',
    '山と湖の化身',
    '神格',
    'moriya',
    'moriya_shrine',
    'moriya_shrine',
    '八坂 神奈子に関する基本人物紹介です。',
    '八坂 神奈子を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '八坂 神奈子の価値観や見方を整理した文面です。',
    '八坂 神奈子の役割です。',
    '["goddess","moriya","leadership"]'::jsonb,
    jsonb_build_object('表示名', '八坂 神奈子', '肩書き', '山と湖の化身', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'suwako',
    '洩矢 諏訪子',
    '土着神の頂点',
    '神格',
    'moriya',
    'moriya_shrine',
    'moriya_shrine',
    '洩矢 諏訪子に関する基本人物紹介です。',
    '洩矢 諏訪子を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '洩矢 諏訪子の価値観や見方を整理した文面です。',
    '洩矢 諏訪子の役割です。',
    '["goddess","moriya","ancient"]'::jsonb,
    jsonb_build_object('表示名', '洩矢 諏訪子', '肩書き', '土着神の頂点', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'byakuren',
    '聖 白蓮',
    '命蓮寺の住職',
    '魔法使い',
    'myouren',
    'myouren_temple',
    'myouren_temple',
    '聖 白蓮に関する基本人物紹介です。',
    '聖 白蓮を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '聖 白蓮の価値観や見方を整理した文面です。',
    '聖 白蓮の役割です。',
    '["temple","leader","coexistence"]'::jsonb,
    jsonb_build_object('表示名', '聖 白蓮', '肩書き', '命蓮寺の住職', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'utsuho',
    '霊烏路 空',
    '熱かい悩む神の火',
    '地獄鴉',
    'former_hell',
    'former_hell',
    'former_hell',
    '霊烏路 空に関する基本人物紹介です。',
    '霊烏路 空を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '霊烏路 空の価値観や見方を整理した文面です。',
    '霊烏路 空の役割です。',
    '["underground","nuclear","power"]'::jsonb,
    jsonb_build_object('表示名', '霊烏路 空', '肩書き', '熱かい悩む神の火', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'koishi',
    '古明地 こいし',
    '閉じた恋の瞳',
    'さとり妖怪',
    'former_hell',
    'former_hell',
    'old_capital',
    '古明地 こいしに関する基本人物紹介です。',
    '古明地 こいしを配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '古明地 こいしの価値観や見方を整理した文面です。',
    '古明地 こいしの役割です。',
    '["underground","unconscious","unpredictable"]'::jsonb,
    jsonb_build_object('表示名', '古明地 こいし', '肩書き', '閉じた恋の瞳', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
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
  (
    'gensokyo_main',
    'sakuya',
    'remilia',
    'retainer',
    '十六夜 咲夜とレミリア・スカーレットのあいだにある従者関係を示す関係データです。',
    0.92,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'remilia',
    'sakuya',
    'trusted_servant',
    'レミリア・スカーレットと十六夜 咲夜のあいだにある信頼された奉仕関係を示す関係データです。',
    0.92,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'patchouli',
    'remilia',
    'resident_ally',
    'パチュリー・ノーレッジとレミリア・スカーレットのあいだにある同居する協力関係を示す関係データです。',
    0.73,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'alice',
    'marisa',
    'complicated_peer',
    'アリス・マーガトロイドと霧雨 魔理沙のあいだにある複雑な同格関係を示す関係データです。',
    0.55,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'youmu',
    'yuyuko',
    'retainer',
    '魂魄 妖夢と西行寺 幽々子のあいだにある従者関係を示す関係データです。',
    0.89,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'yuyuko',
    'youmu',
    'fond_superior',
    '西行寺 幽々子と魂魄 妖夢のあいだにある親愛を含む主従関係を示す関係データです。',
    0.89,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'ran',
    'yukari',
    'shikigami_loyalty',
    '八雲 藍と八雲 紫のあいだにある式としての忠誠関係を示す関係データです。',
    0.94,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'chen',
    'ran',
    'family_loyalty',
    '橙と八雲 藍のあいだにある家族的な忠誠関係を示す関係データです。',
    0.88,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'keine',
    'mokou',
    'protective_ally',
    '上白沢 慧音と藤原 妹紅のあいだにある保護を伴う協力関係を示す関係データです。',
    0.74,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'eirin',
    'kaguya',
    'protective_companion',
    '八意 永琳と蓬莱山 輝夜のあいだにある保護を伴う同伴関係を示す関係データです。',
    0.87,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'reisen',
    'eirin',
    'disciplined_superior',
    '鈴仙・優曇華院・イナバと八意 永琳のあいだにある規律を与える上下関係を示す関係データです。',
    0.79,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'kanako',
    'suwako',
    'shared_shrine_authority',
    '八坂 神奈子と洩矢 諏訪子のあいだにある神社運営を共有する関係を示す関係データです。',
    0.71,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'sanae',
    'kanako',
    'devotional_service',
    '東風谷 早苗と八坂 神奈子のあいだにある信仰と奉仕に基づく関係を示す関係データです。',
    0.78,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'sanae',
    'suwako',
    'devotional_service',
    '東風谷 早苗と洩矢 諏訪子のあいだにある信仰と奉仕に基づく関係を示す関係データです。',
    0.76,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'aya',
    'reimu',
    'public_observer',
    '射命丸 文と博麗 霊夢のあいだにある公的に注視する関係を示す関係データです。',
    0.62,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'reimu',
    'aya',
    'annoyed_familiarity',
    '博麗 霊夢と射命丸 文のあいだにある煩わしさを含む顔なじみ関係を示す関係データです。',
    0.62,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'byakuren',
    'reimu',
    'institutional_peer',
    '聖 白蓮と博麗 霊夢のあいだにある制度上の並立関係を示す関係データです。',
    0.49,
    '{}'::jsonb
  )
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
    'lore_spell_card_rules',
    'world_rule',
    '幻想郷設定項目',
    '幻想郷全体に関わる基本ルールを整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'world_rule', '説明', '日本語表示向けに整理した説明データです。'),
    '["rules","duel","canon"]'::jsonb,
    95
  ),
  (
    'gensokyo_main',
    'lore_incident_resolution',
    'world_rule',
    '幻想郷設定項目',
    '幻想郷全体に関わる基本ルールを整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'world_rule', '説明', '日本語表示向けに整理した説明データです。'),
    '["incidents","structure"]'::jsonb,
    92
  ),
  (
    'gensokyo_main',
    'lore_human_village_function',
    'location_trait',
    '幻想郷設定項目',
    '土地ごとの性質や役割を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'location_trait', '説明', '日本語表示向けに整理した説明データです。'),
    '["village","social"]'::jsonb,
    88
  ),
  (
    'gensokyo_main',
    'lore_mansion_profile',
    'location_trait',
    '幻想郷設定項目',
    '土地ごとの性質や役割を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'location_trait', '説明', '日本語表示向けに整理した説明データです。'),
    '["mansion","symbol"]'::jsonb,
    84
  ),
  (
    'gensokyo_main',
    'lore_eientei_profile',
    'location_trait',
    '幻想郷設定項目',
    '土地ごとの性質や役割を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'location_trait', '説明', '日本語表示向けに整理した説明データです。'),
    '["eientei","medicine","lunar"]'::jsonb,
    84
  ),
  (
    'gensokyo_main',
    'lore_moriya_profile',
    'location_trait',
    '幻想郷設定項目',
    '土地ごとの性質や役割を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'location_trait', '説明', '日本語表示向けに整理した説明データです。'),
    '["moriya","faith"]'::jsonb,
    82
  ),
  (
    'gensokyo_main',
    'lore_netherworld_profile',
    'location_trait',
    '幻想郷設定項目',
    '土地ごとの性質や役割を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'location_trait', '説明', '日本語表示向けに整理した説明データです。'),
    '["netherworld","spirits"]'::jsonb,
    80
  ),
  (
    'gensokyo_main',
    'lore_kappa_engineering',
    'faction_trait',
    '幻想郷設定項目',
    '勢力や集団の性質を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'faction_trait', '説明', '日本語表示向けに整理した説明データです。'),
    '["kappa","engineering"]'::jsonb,
    78
  ),
  (
    'gensokyo_main',
    'lore_yakumo_boundaries',
    'character_role',
    '幻想郷設定項目',
    '人物の立ち位置や役割を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_role', '説明', '日本語表示向けに整理した説明データです。'),
    '["boundary","high_impact"]'::jsonb,
    83
  ),
  (
    'gensokyo_main',
    'lore_reimu_position',
    'character_role',
    '幻想郷設定項目',
    '人物の立ち位置や役割を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_role', '説明', '日本語表示向けに整理した説明データです。'),
    '["reimu","incident"]'::jsonb,
    96
  ),
  (
    'gensokyo_main',
    'lore_marisa_position',
    'character_role',
    '幻想郷設定項目',
    '人物の立ち位置や役割を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_role', '説明', '日本語表示向けに整理した説明データです。'),
    '["marisa","incident"]'::jsonb,
    93
  ),
  (
    'gensokyo_main',
    'lore_sakuya_position',
    'character_role',
    '幻想郷設定項目',
    '人物の立ち位置や役割を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_role', '説明', '日本語表示向けに整理した説明データです。'),
    '["sakuya","household"]'::jsonb,
    85
  ),
  (
    'gensokyo_main',
    'lore_eirin_position',
    'character_role',
    '幻想郷設定項目',
    '人物の立ち位置や役割を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_role', '説明', '日本語表示向けに整理した説明データです。'),
    '["eirin","medicine","lunar"]'::jsonb,
    87
  ),
  (
    'gensokyo_main',
    'lore_sanae_position',
    'character_role',
    '幻想郷設定項目',
    '人物の立ち位置や役割を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_role', '説明', '日本語表示向けに整理した説明データです。'),
    '["sanae","public_action"]'::jsonb,
    81
  ),
  (
    'gensokyo_main',
    'lore_aya_position',
    'character_role',
    '幻想郷設定項目',
    '人物の立ち位置や役割を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_role', '説明', '日本語表示向けに整理した説明データです。'),
    '["aya","news","rumor"]'::jsonb,
    82
  ),
  (
    'gensokyo_main',
    'lore_event_design_constraint',
    'world_rule',
    '幻想郷設定項目',
    '幻想郷全体に関わる基本ルールを整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'world_rule', '説明', '日本語表示向けに整理した説明データです。'),
    '["events","design"]'::jsonb,
    97
  )
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
  (
    'src_eosd',
    'gensokyo_main',
    'official_game',
    'eosd',
    '東方紅魔郷',
    '東方紅魔郷',
    '東方紅魔郷に関する参照用ソース情報です。',
    '{}'::jsonb
  ),
  (
    'src_pcb',
    'gensokyo_main',
    'official_game',
    'pcb',
    '東方妖々夢',
    '東方妖々夢',
    '東方妖々夢に関する参照用ソース情報です。',
    '{}'::jsonb
  ),
  (
    'src_imperishable_night',
    'gensokyo_main',
    'official_game',
    'in',
    '東方永夜抄',
    '東方永夜抄',
    '東方永夜抄に関する参照用ソース情報です。',
    '{}'::jsonb
  ),
  (
    'src_mofa',
    'gensokyo_main',
    'official_game',
    'mofa',
    '東方風神録',
    '東方風神録',
    '東方風神録に関する参照用ソース情報です。',
    '{}'::jsonb
  ),
  (
    'src_subterranean_animism',
    'gensokyo_main',
    'official_game',
    'sa',
    '東方地霊殿',
    '東方地霊殿',
    '東方地霊殿に関する参照用ソース情報です。',
    '{}'::jsonb
  ),
  (
    'src_pmss',
    'gensokyo_main',
    'official_book',
    'pmiss',
    '東方求聞史紀',
    '東方求聞史紀',
    '東方求聞史紀に関する参照用ソース情報です。',
    '{}'::jsonb
  ),
  (
    'src_sopm',
    'gensokyo_main',
    'official_book',
    'sopm',
    '求聞口授',
    '求聞口授',
    '求聞口授に関する参照用ソース情報です。',
    '{}'::jsonb
  )
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
  (
    'claim_reimu_incident_resolver',
    'gensokyo_main',
    'character',
    'reimu',
    'role',
    '博麗 霊夢に関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '博麗 霊夢', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_pmss',
    'official',
    100,
    '["reimu","incident","role"]'::jsonb
  ),
  (
    'claim_marisa_incident_actor',
    'gensokyo_main',
    'character',
    'marisa',
    'role',
    '霧雨 魔理沙に関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '霧雨 魔理沙', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_pmss',
    'official',
    96,
    '["marisa","incident","role"]'::jsonb
  ),
  (
    'claim_sdm_household',
    'gensokyo_main',
    'location',
    'scarlet_devil_mansion',
    'setting',
    '紅魔館に関する正史設定です。分類は設定です。',
    jsonb_build_object('対象', '紅魔館', '分類', '設定', '説明', '日本語表示向けに整理した説明データです。'),
    'src_eosd',
    'official',
    88,
    '["mansion","household"]'::jsonb
  ),
  (
    'claim_eientei_secluded',
    'gensokyo_main',
    'location',
    'eientei',
    'setting',
    '永遠亭に関する正史設定です。分類は設定です。',
    jsonb_build_object('対象', '永遠亭', '分類', '設定', '説明', '日本語表示向けに整理した説明データです。'),
    'src_imperishable_night',
    'official',
    88,
    '["eientei","seclusion"]'::jsonb
  ),
  (
    'claim_moriya_proactive',
    'gensokyo_main',
    'location',
    'moriya_shrine',
    'setting',
    '守矢神社に関する正史設定です。分類は設定です。',
    jsonb_build_object('対象', '守矢神社', '分類', '設定', '説明', '日本語表示向けに整理した説明データです。'),
    'src_mofa',
    'official',
    86,
    '["moriya","faith"]'::jsonb
  ),
  (
    'claim_human_village_social_core',
    'gensokyo_main',
    'location',
    'human_village',
    'setting',
    '人里に関する正史設定です。分類は設定です。',
    jsonb_build_object('対象', '人里', '分類', '設定', '説明', '日本語表示向けに整理した説明データです。'),
    'src_pmss',
    'official',
    92,
    '["village","social"]'::jsonb
  ),
  (
    'claim_spell_card_constraint',
    'gensokyo_main',
    'world',
    'gensokyo_main',
    'world_rule',
    '幻想郷に関する正史設定です。分類は世界ルールです。',
    jsonb_build_object('対象', '幻想郷', '分類', '世界ルール', '説明', '日本語表示向けに整理した説明データです。'),
    'src_sopm',
    'official',
    94,
    '["rules","conflict"]'::jsonb
  ),
  (
    'claim_yukari_high_impact',
    'gensokyo_main',
    'character',
    'yukari',
    'usage_constraint',
    '八雲 紫に関する正史設定です。分類は使用上の制約です。',
    jsonb_build_object('対象', '八雲 紫', '分類', '使用上の制約', '説明', '日本語表示向けに整理した説明データです。'),
    'src_pmss',
    'official',
    82,
    '["yukari","constraint"]'::jsonb
  ),
  (
    'claim_sakuya_household_control',
    'gensokyo_main',
    'character',
    'sakuya',
    'role',
    '十六夜 咲夜に関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '十六夜 咲夜', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_eosd',
    'official',
    84,
    '["sakuya","role"]'::jsonb
  ),
  (
    'claim_eirin_strategic',
    'gensokyo_main',
    'character',
    'eirin',
    'role',
    '八意 永琳に関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '八意 永琳', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_imperishable_night',
    'official',
    85,
    '["eirin","strategy","medicine"]'::jsonb
  ),
  (
    'claim_aya_public_narrative',
    'gensokyo_main',
    'character',
    'aya',
    'role',
    '射命丸 文に関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '射命丸 文', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_sopm',
    'official',
    80,
    '["aya","rumor","news"]'::jsonb
  ),
  (
    'claim_byakuren_coexistence',
    'gensokyo_main',
    'character',
    'byakuren',
    'role',
    '聖 白蓮に関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '聖 白蓮', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_sopm',
    'official',
    78,
    '["byakuren","temple"]'::jsonb
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

insert into public.world_derivative_overlays (
  id, world_id, overlay_scope, subject_type, subject_id, title, summary, payload, enabled
)
values (
  'overlay_story_festival_expanded_cast',
  'gensokyo_main',
  'story_event',
  'event',
  'story_spring_festival_001',
  '拡張差分スロット',
  '将来の差分追加に備えた予備スロットです。',
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

insert into public.world_source_index (
  id, world_id, source_kind, source_code, title, short_label, notes, metadata
)
values
  (
    'src_poFV',
    'gensokyo_main',
    'official_game',
    'pofv',
    '公式資料 pofv',
    '公式資料 pofv',
    '公式資料 pofvに関する参照用ソース情報です。',
    '{}'::jsonb
  ),
  (
    'src_ds',
    'gensokyo_main',
    'official_game',
    'ds',
    'ダブルスポイラー',
    'ダブルスポイラー',
    'ダブルスポイラーに関する参照用ソース情報です。',
    '{}'::jsonb
  ),
  (
    'src_gfw',
    'gensokyo_main',
    'official_game',
    'gfw',
    '公式資料 gfw',
    '公式資料 gfw',
    '公式資料 gfwに関する参照用ソース情報です。',
    '{}'::jsonb
  ),
  (
    'src_swl',
    'gensokyo_main',
    'official_game',
    'swl',
    '公式資料 swl',
    '公式資料 swl',
    '公式資料 swlに関する参照用ソース情報です。',
    '{}'::jsonb
  ),
  (
    'src_hm',
    'gensokyo_main',
    'official_game',
    'hm',
    '公式資料 hm',
    '公式資料 hm',
    '公式資料 hmに関する参照用ソース情報です。',
    '{}'::jsonb
  ),
  (
    'src_ulil',
    'gensokyo_main',
    'official_game',
    'ulil',
    '公式資料 ulil',
    '公式資料 ulil',
    '公式資料 ulilに関する参照用ソース情報です。',
    '{}'::jsonb
  ),
  (
    'src_aocf',
    'gensokyo_main',
    'official_game',
    'aocf',
    '公式資料 aocf',
    '公式資料 aocf',
    '公式資料 aocfに関する参照用ソース情報です。',
    '{}'::jsonb
  ),
  (
    'src_ufo',
    'gensokyo_main',
    'official_game',
    'ufo',
    '東方星蓮船',
    '東方星蓮船',
    '東方星蓮船に関する参照用ソース情報です。',
    '{}'::jsonb
  ),
  (
    'src_td',
    'gensokyo_main',
    'official_game',
    'td',
    '東方神霊廟',
    '東方神霊廟',
    '東方神霊廟に関する参照用ソース情報です。',
    '{}'::jsonb
  ),
  (
    'src_ddc',
    'gensokyo_main',
    'official_game',
    'ddc',
    '公式資料 ddc',
    '公式資料 ddc',
    '公式資料 ddcに関する参照用ソース情報です。',
    '{}'::jsonb
  ),
  (
    'src_lolk',
    'gensokyo_main',
    'official_game',
    'lolk',
    '公式資料 lolk',
    '公式資料 lolk',
    '公式資料 lolkに関する参照用ソース情報です。',
    '{}'::jsonb
  ),
  (
    'src_hsifs',
    'gensokyo_main',
    'official_game',
    'hsifs',
    '公式資料 hsifs',
    '公式資料 hsifs',
    '公式資料 hsifsに関する参照用ソース情報です。',
    '{}'::jsonb
  ),
  (
    'src_wbawc',
    'gensokyo_main',
    'official_game',
    'wbawc',
    '公式資料 wbawc',
    '公式資料 wbawc',
    '公式資料 wbawcに関する参照用ソース情報です。',
    '{}'::jsonb
  ),
  (
    'src_17_5',
    'gensokyo_main',
    'official_game',
    '17_5',
    '公式資料 17_5',
    '公式資料 17_5',
    '公式資料 17_5に関する参照用ソース情報です。',
    '{}'::jsonb
  ),
  (
    'src_um',
    'gensokyo_main',
    'official_game',
    'um',
    '公式資料 um',
    '公式資料 um',
    '公式資料 umに関する参照用ソース情報です。',
    '{}'::jsonb
  ),
  (
    'src_uDoALG',
    'gensokyo_main',
    'official_game',
    'udoalg',
    '公式資料 udoalg',
    '公式資料 udoalg',
    '公式資料 udoalgに関する参照用ソース情報です。',
    '{}'::jsonb
  ),
  (
    'src_boaFW',
    'gensokyo_main',
    'official_book',
    'boafw',
    '公式資料 boafw',
    '公式資料 boafw',
    '公式資料 boafwに関する参照用ソース情報です。',
    '{}'::jsonb
  ),
  (
    'src_sixty_years',
    'gensokyo_main',
    'official_book',
    'sixty_years',
    '公式資料 sixty_years',
    '公式資料 sixty_years',
    '公式資料 sixty_yearsに関する参照用ソース情報です。',
    '{}'::jsonb
  ),
  (
    'src_ssib',
    'gensokyo_main',
    'official_book',
    'ssib',
    '公式資料 ssib',
    '公式資料 ssib',
    '公式資料 ssibに関する参照用ソース情報です。',
    '{}'::jsonb
  ),
  (
    'src_ciLR',
    'gensokyo_main',
    'official_book',
    'cilr',
    '公式資料 cilr',
    '公式資料 cilr',
    '公式資料 cilrに関する参照用ソース情報です。',
    '{}'::jsonb
  ),
  (
    'src_wahh',
    'gensokyo_main',
    'official_book',
    'wahh',
    '公式資料 wahh',
    '公式資料 wahh',
    '公式資料 wahhに関する参照用ソース情報です。',
    '{}'::jsonb
  ),
  (
    'src_fs',
    'gensokyo_main',
    'official_book',
    'fs',
    '公式資料 fs',
    '公式資料 fs',
    '公式資料 fsに関する参照用ソース情報です。',
    '{}'::jsonb
  ),
  (
    'src_cds',
    'gensokyo_main',
    'official_book',
    'cds',
    '公式資料 cds',
    '公式資料 cds',
    '公式資料 cdsに関する参照用ソース情報です。',
    '{}'::jsonb
  ),
  (
    'src_osp',
    'gensokyo_main',
    'official_book',
    'osp',
    '東方三月精',
    '東方三月精',
    '東方三月精に関する参照用ソース情報です。',
    '{}'::jsonb
  ),
  (
    'src_vfi',
    'gensokyo_main',
    'official_book',
    'vfi',
    'ビジョナリー・フェアリーズ・イン・シュライン',
    'ビジョナリー・フェアリーズ・イン・シュライン',
    'ビジョナリー・フェアリーズ・イン・シュラインに関する参照用ソース情報です。',
    '{}'::jsonb
  ),
  (
    'src_lotus_asia',
    'gensokyo_main',
    'official_book',
    'lotus_asia',
    '公式資料 lotus_asia',
    '公式資料 lotus_asia',
    '公式資料 lotus_asiaに関する参照用ソース情報です。',
    '{}'::jsonb
  ),
  (
    'src_grimoire_marisa',
    'gensokyo_main',
    'official_book',
    'grimoire_marisa',
    '公式資料 grimoire_marisa',
    '公式資料 grimoire_marisa',
    '公式資料 grimoire_marisaに関する参照用ソース情報です。',
    '{}'::jsonb
  ),
  (
    'src_alt_truth',
    'gensokyo_main',
    'official_book',
    'alt_truth',
    '東方鈴奈庵外伝資料群',
    '東方鈴奈庵外伝資料群',
    '東方鈴奈庵外伝資料群に関する参照用ソース情報です。',
    '{}'::jsonb
  )
on conflict (id) do update
set source_kind = excluded.source_kind,
    source_code = excluded.source_code,
    title = excluded.title,
    short_label = excluded.short_label,
    notes = excluded.notes,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_locations (
  world_id, id, name, kind, parent_location_id, title, summary, description, tags, default_mood, neighbors, metadata
)
values
  (
    'gensokyo_main',
    'chireiden',
    '地霊殿',
    'major_location',
    'former_hell',
    '地霊殿の地域情報',
    '地霊殿に関する基本地点情報です。',
    '地霊殿の特徴や周辺とのつながりを日本語で整理した説明です。',
    '["underground","palace","satori"]'::jsonb,
    '落ち着いた雰囲気',
    '["old_capital","former_hell"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'scarlet_gate',
    '紅魔館の門',
    'sub_location',
    'scarlet_devil_mansion',
    '紅魔館の門の地域情報',
    '紅魔館の門に関する基本地点情報です。',
    '紅魔館の門の特徴や周辺とのつながりを日本語で整理した説明です。',
    '["gate","mansion","threshold"]'::jsonb,
    '落ち着いた雰囲気',
    '["misty_lake","scarlet_devil_mansion"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'mansion_library',
    '紅魔館図書館',
    'sub_location',
    'scarlet_devil_mansion',
    '紅魔館図書館の地域情報',
    '紅魔館図書館に関する基本地点情報です。',
    '紅魔館図書館の特徴や周辺とのつながりを日本語で整理した説明です。',
    '["library","magic","indoors"]'::jsonb,
    '落ち着いた雰囲気',
    '["scarlet_devil_mansion"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'moriya_upper_precinct',
    '守矢神社 上社',
    'sub_location',
    'moriya_shrine',
    '守矢神社 上社の地域情報',
    '守矢神社 上社に関する基本地点情報です。',
    '守矢神社 上社の特徴や周辺とのつながりを日本語で整理した説明です。',
    '["shrine","mountain","formal"]'::jsonb,
    '落ち着いた雰囲気',
    '["moriya_shrine","youkai_mountain_foot"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'bamboo_path',
    '竹林の小径',
    'sub_location',
    'bamboo_forest',
    '竹林の小径の地域情報',
    '竹林の小径に関する基本地点情報です。',
    '竹林の小径の特徴や周辺とのつながりを日本語で整理した説明です。',
    '["forest","path","maze"]'::jsonb,
    '落ち着いた雰囲気',
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

insert into public.world_characters (
  world_id, id, name, title, species, faction_id, home_location_id, default_location_id, public_summary, private_notes, speech_style, worldview, role_in_gensokyo, tags, profile
)
values
  (
    'gensokyo_main',
    'meiling',
    '紅 美鈴',
    '華人小娘',
    '妖怪',
    'sdm',
    'scarlet_devil_mansion',
    'scarlet_gate',
    '紅 美鈴に関する基本人物紹介です。',
    '紅 美鈴を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '紅 美鈴の価値観や見方を整理した文面です。',
    '紅 美鈴の役割です。',
    '["sdm","guard","martial"]'::jsonb,
    jsonb_build_object('表示名', '紅 美鈴', '肩書き', '華人小娘', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'momiji',
    '犬走 椛',
    '山の天狗の見張り番',
    '白狼天狗',
    'tengu',
    'youkai_mountain_foot',
    'genbu_ravine',
    '犬走 椛に関する基本人物紹介です。',
    '犬走 椛を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '犬走 椛の価値観や見方を整理した文面です。',
    '犬走 椛の役割です。',
    '["tengu","guard","mountain"]'::jsonb,
    jsonb_build_object('表示名', '犬走 椛', '肩書き', '山の天狗の見張り番', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'satori',
    '古明地 さとり',
    'みんなの心を読む妖怪',
    'さとり妖怪',
    'former_hell',
    'chireiden',
    'chireiden',
    '古明地 さとりに関する基本人物紹介です。',
    '古明地 さとりを配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '古明地 さとりの価値観や見方を整理した文面です。',
    '古明地 さとりの役割です。',
    '["satori","underground","mind"]'::jsonb,
    jsonb_build_object('表示名', '古明地 さとり', '肩書き', 'みんなの心を読む妖怪', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'rin',
    '火焔猫 燐',
    '地獄の輪禍',
    '種族',
    'former_hell',
    'former_hell',
    'old_capital',
    '火焔猫 燐に関する基本人物紹介です。',
    '火焔猫 燐を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '火焔猫 燐の価値観や見方を整理した文面です。',
    '火焔猫 燐の役割です。',
    '["underground","kasha","mobile"]'::jsonb,
    jsonb_build_object('表示名', '火焔猫 燐', '肩書き', '地獄の輪禍', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
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
  (
    'gensokyo_main',
    'meiling',
    'sakuya',
    'household_colleague',
    '紅 美鈴と十六夜 咲夜のあいだにある関係を示す関係データです。',
    0.66,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'sakuya',
    'meiling',
    'household_colleague',
    '十六夜 咲夜と紅 美鈴のあいだにある関係を示す関係データです。',
    0.66,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'meiling',
    'remilia',
    'household_loyalty',
    '紅 美鈴とレミリア・スカーレットのあいだにある関係を示す関係データです。',
    0.72,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'momiji',
    'aya',
    'information_chain',
    '犬走 椛と射命丸 文のあいだにある関係を示す関係データです。',
    0.53,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'aya',
    'momiji',
    'information_chain',
    '射命丸 文と犬走 椛のあいだにある関係を示す関係データです。',
    0.53,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'satori',
    'koishi',
    'family_bond',
    '古明地 さとりと古明地 こいしのあいだにある関係を示す関係データです。',
    0.90,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'koishi',
    'satori',
    'family_bond',
    '古明地 こいしと古明地 さとりのあいだにある関係を示す関係データです。',
    0.90,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'satori',
    'rin',
    'household_supervision',
    '古明地 さとりと火焔猫 燐のあいだにある関係を示す関係データです。',
    0.71,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'rin',
    'satori',
    'household_loyalty',
    '火焔猫 燐と古明地 さとりのあいだにある関係を示す関係データです。',
    0.71,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'satori',
    'okuu',
    'household_supervision',
    '古明地 さとりと対象項目のあいだにある関係を示す関係データです。',
    0.76,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'okuu',
    'satori',
    'household_loyalty',
    '対象項目と古明地 さとりのあいだにある関係を示す関係データです。',
    0.76,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'rin',
    'okuu',
    'close_companion',
    '火焔猫 燐と対象項目のあいだにある関係を示す関係データです。',
    0.84,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'okuu',
    'rin',
    'close_companion',
    '対象項目と火焔猫 燐のあいだにある関係を示す関係データです。',
    0.84,
    '{}'::jsonb
  )
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
    'lore_meiling_gatekeeping',
    'character_role',
    '幻想郷設定項目',
    '人物の立ち位置や役割を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_role', '説明', '日本語表示向けに整理した説明データです。'),
    '["meiling","threshold","sdm"]'::jsonb,
    74
  ),
  (
    'gensokyo_main',
    'lore_momiji_patrols',
    'character_role',
    '幻想郷設定項目',
    '人物の立ち位置や役割を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_role', '説明', '日本語表示向けに整理した説明データです。'),
    '["momiji","mountain","guard"]'::jsonb,
    72
  ),
  (
    'gensokyo_main',
    'lore_satori_insight',
    'character_role',
    '幻想郷設定項目',
    '人物の立ち位置や役割を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_role', '説明', '日本語表示向けに整理した説明データです。'),
    '["satori","mind","insight"]'::jsonb,
    79
  ),
  (
    'gensokyo_main',
    'lore_rin_social_flow',
    'character_role',
    '幻想郷設定項目',
    '人物の立ち位置や役割を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_role', '説明', '日本語表示向けに整理した説明データです。'),
    '["rin","underground","movement"]'::jsonb,
    70
  ),
  (
    'gensokyo_main',
    'lore_chireiden_profile',
    'location_trait',
    '幻想郷設定項目',
    '土地ごとの性質や役割を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'location_trait', '説明', '日本語表示向けに整理した説明データです。'),
    '["chireiden","mind","underground"]'::jsonb,
    78
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
    'claim_meiling_gatekeeper',
    'gensokyo_main',
    'character',
    'meiling',
    'role',
    '紅 美鈴に関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '紅 美鈴', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_eosd',
    'official',
    76,
    '["meiling","sdm","gate"]'::jsonb
  ),
  (
    'claim_momiji_mountain_guard',
    'gensokyo_main',
    'character',
    'momiji',
    'role',
    '犬走 椛に関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '犬走 椛', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_mofa',
    'official',
    72,
    '["momiji","guard","mountain"]'::jsonb
  ),
  (
    'claim_satori_chireiden',
    'gensokyo_main',
    'character',
    'satori',
    'role',
    '古明地 さとりに関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '古明地 さとり', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_subterranean_animism',
    'official',
    84,
    '["satori","chireiden","mind"]'::jsonb
  ),
  (
    'claim_rin_underground_flow',
    'gensokyo_main',
    'character',
    'rin',
    'role',
    '火焔猫 燐に関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '火焔猫 燐', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_subterranean_animism',
    'official',
    75,
    '["rin","underground","movement"]'::jsonb
  ),
  (
    'claim_chireiden_setting',
    'gensokyo_main',
    'location',
    'chireiden',
    'setting',
    '地霊殿に関する正史設定です。分類は設定です。',
    jsonb_build_object('対象', '地霊殿', '分類', '設定', '説明', '日本語表示向けに整理した説明データです。'),
    'src_subterranean_animism',
    'official',
    80,
    '["chireiden","setting"]'::jsonb
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

insert into public.world_characters (
  world_id, id, name, title, species, faction_id, home_location_id, default_location_id, public_summary, private_notes, speech_style, worldview, role_in_gensokyo, tags, profile
)
values
  (
    'gensokyo_main',
    'cirno',
    'チルノ',
    '氷の妖精',
    '種族',
    'independent',
    'misty_lake',
    'misty_lake',
    'チルノに関する基本人物紹介です。',
    'チルノを配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    'チルノの価値観や見方を整理した文面です。',
    'チルノの役割です。',
    '["fairy","ice","energetic"]'::jsonb,
    jsonb_build_object('表示名', 'チルノ', '肩書き', '氷の妖精', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'letty',
    'レティ・ホワイトロック',
    '冬の忘れ物',
    '妖怪',
    'independent',
    'misty_lake',
    'misty_lake',
    'レティ・ホワイトロックに関する基本人物紹介です。',
    'レティ・ホワイトロックを配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    'レティ・ホワイトロックの価値観や見方を整理した文面です。',
    'レティ・ホワイトロックの役割です。',
    '["winter","seasonal","youkai"]'::jsonb,
    jsonb_build_object('表示名', 'レティ・ホワイトロック', '肩書き', '冬の忘れ物', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'lily_white',
    'リリーホワイト',
    '春を告げる妖精',
    '種族',
    'independent',
    'hakurei_shrine',
    'human_village',
    'リリーホワイトに関する基本人物紹介です。',
    'リリーホワイトを配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    'リリーホワイトの価値観や見方を整理した文面です。',
    'リリーホワイトの役割です。',
    '["fairy","spring","messenger"]'::jsonb,
    jsonb_build_object('表示名', 'リリーホワイト', '肩書き', '春を告げる妖精', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'lunasa',
    'ルナサ・プリズムリバー',
    '騒霊ヴァイオリニスト',
    '種族',
    'prismriver',
    'netherworld',
    'hakugyokurou',
    'ルナサ・プリズムリバーに関する基本人物紹介です。',
    'ルナサ・プリズムリバーを配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    'ルナサ・プリズムリバーの価値観や見方を整理した文面です。',
    'ルナサ・プリズムリバーの役割です。',
    '["music","phantom","ensemble"]'::jsonb,
    jsonb_build_object('表示名', 'ルナサ・プリズムリバー', '肩書き', '騒霊ヴァイオリニスト', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'merlin',
    'メルラン・プリズムリバー',
    '騒霊トランペッター',
    '種族',
    'prismriver',
    'netherworld',
    'hakugyokurou',
    'メルラン・プリズムリバーに関する基本人物紹介です。',
    'メルラン・プリズムリバーを配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    'メルラン・プリズムリバーの価値観や見方を整理した文面です。',
    'メルラン・プリズムリバーの役割です。',
    '["music","phantom","ensemble"]'::jsonb,
    jsonb_build_object('表示名', 'メルラン・プリズムリバー', '肩書き', '騒霊トランペッター', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'lyrica',
    'リリカ・プリズムリバー',
    '騒霊キーボーディスト',
    '種族',
    'prismriver',
    'netherworld',
    'hakugyokurou',
    'リリカ・プリズムリバーに関する基本人物紹介です。',
    'リリカ・プリズムリバーを配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    'リリカ・プリズムリバーの価値観や見方を整理した文面です。',
    'リリカ・プリズムリバーの役割です。',
    '["music","phantom","ensemble"]'::jsonb,
    jsonb_build_object('表示名', 'リリカ・プリズムリバー', '肩書き', '騒霊キーボーディスト', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'hina',
    '鍵山 雛',
    '厄の女神',
    '神格',
    'independent',
    'youkai_mountain_foot',
    'youkai_mountain_foot',
    '鍵山 雛に関する基本人物紹介です。',
    '鍵山 雛を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '鍵山 雛の価値観や見方を整理した文面です。',
    '鍵山 雛の役割です。',
    '["mountain","misfortune","goddess"]'::jsonb,
    jsonb_build_object('表示名', '鍵山 雛', '肩書き', '厄の女神', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'minoriko',
    '秋 穣子',
    '豊穣の神',
    '神格',
    'independent',
    'human_village',
    'human_village',
    '秋 穣子に関する基本人物紹介です。',
    '秋 穣子を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '秋 穣子の価値観や見方を整理した文面です。',
    '秋 穣子の役割です。',
    '["harvest","autumn","goddess"]'::jsonb,
    jsonb_build_object('表示名', '秋 穣子', '肩書き', '豊穣の神', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'shizuha',
    '秋 静葉',
    '寂しさと終焉の象徴',
    '神格',
    'independent',
    'human_village',
    'human_village',
    '秋 静葉に関する基本人物紹介です。',
    '秋 静葉を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '秋 静葉の価値観や見方を整理した文面です。',
    '秋 静葉の役割です。',
    '["autumn","goddess","atmosphere"]'::jsonb,
    jsonb_build_object('表示名', '秋 静葉', '肩書き', '寂しさと終焉の象徴', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'tewi',
    '因幡 てゐ',
    '幸運の素兎',
    '地上の兎',
    'eientei',
    'eientei',
    'bamboo_forest',
    '因幡 てゐに関する基本人物紹介です。',
    '因幡 てゐを配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '因幡 てゐの価値観や見方を整理した文面です。',
    '因幡 てゐの役割です。',
    '["rabbit","luck","eientei"]'::jsonb,
    jsonb_build_object('表示名', '因幡 てゐ', '肩書き', '幸運の素兎', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
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
  (
    'gensokyo_main',
    'cirno',
    'remilia',
    'territorial_overlap',
    'チルノとレミリア・スカーレットのあいだにある関係を示す関係データです。',
    0.31,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'lily_white',
    'reimu',
    'seasonal_contact',
    'リリーホワイトと博麗 霊夢のあいだにある関係を示す関係データです。',
    0.36,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'lunasa',
    'merlin',
    'ensemble_sibling',
    'ルナサ・プリズムリバーとメルラン・プリズムリバーのあいだにある関係を示す関係データです。',
    0.88,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'merlin',
    'lyrica',
    'ensemble_sibling',
    'メルラン・プリズムリバーとリリカ・プリズムリバーのあいだにある関係を示す関係データです。',
    0.88,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'lunasa',
    'lyrica',
    'ensemble_sibling',
    'ルナサ・プリズムリバーとリリカ・プリズムリバーのあいだにある関係を示す関係データです。',
    0.88,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'minoriko',
    'shizuha',
    'seasonal_sibling',
    '秋 穣子と秋 静葉のあいだにある関係を示す関係データです。',
    0.84,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'shizuha',
    'minoriko',
    'seasonal_sibling',
    '秋 静葉と秋 穣子のあいだにある関係を示す関係データです。',
    0.84,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'tewi',
    'reisen',
    'eientei_local',
    '因幡 てゐと鈴仙・優曇華院・イナバのあいだにある関係を示す関係データです。',
    0.63,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'reisen',
    'tewi',
    'eientei_local',
    '鈴仙・優曇華院・イナバと因幡 てゐのあいだにある関係を示す関係データです。',
    0.63,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'hina',
    'momiji',
    'mountain_proximity',
    '鍵山 雛と犬走 椛のあいだにある関係を示す関係データです。',
    0.41,
    '{}'::jsonb
  )
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
    'lore_cirno_local_trouble',
    'character_role',
    '幻想郷設定項目',
    '人物の立ち位置や役割を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_role', '説明', '日本語表示向けに整理した説明データです。'),
    '["cirno","fairy","local"]'::jsonb,
    68
  ),
  (
    'gensokyo_main',
    'lore_lily_seasonal_marker',
    'character_role',
    '幻想郷設定項目',
    '人物の立ち位置や役割を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_role', '説明', '日本語表示向けに整理した説明データです。'),
    '["lily_white","spring","seasonal"]'::jsonb,
    67
  ),
  (
    'gensokyo_main',
    'lore_prismriver_ensemble',
    'character_role',
    '幻想郷設定項目',
    '人物の立ち位置や役割を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_role', '説明', '日本語表示向けに整理した説明データです。'),
    '["prismriver","music","group"]'::jsonb,
    71
  ),
  (
    'gensokyo_main',
    'lore_aki_seasonality',
    'character_role',
    '幻想郷設定項目',
    '人物の立ち位置や役割を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_role', '説明', '日本語表示向けに整理した説明データです。'),
    '["aki","autumn","seasonal"]'::jsonb,
    69
  ),
  (
    'gensokyo_main',
    'lore_tewi_detours',
    'character_role',
    '幻想郷設定項目',
    '人物の立ち位置や役割を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_role', '説明', '日本語表示向けに整理した説明データです。'),
    '["tewi","luck","detour"]'::jsonb,
    72
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
    'claim_cirno_fairy_local',
    'gensokyo_main',
    'character',
    'cirno',
    'role',
    'チルノに関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', 'チルノ', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_eosd',
    'official',
    66,
    '["cirno","fairy"]'::jsonb
  ),
  (
    'claim_lily_spring_marker',
    'gensokyo_main',
    'character',
    'lily_white',
    'role',
    'リリーホワイトに関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', 'リリーホワイト', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_pcb',
    'official',
    68,
    '["lily_white","spring"]'::jsonb
  ),
  (
    'claim_prismriver_ensemble',
    'gensokyo_main',
    'character',
    'lunasa',
    'group_role',
    'ルナサ・プリズムリバーに関する正史設定です。分類は設定です。',
    jsonb_build_object('対象', 'ルナサ・プリズムリバー', '分類', '設定', '説明', '日本語表示向けに整理した説明データです。'),
    'src_pcb',
    'official',
    74,
    '["prismriver","ensemble"]'::jsonb
  ),
  (
    'claim_hina_mountain_warning',
    'gensokyo_main',
    'character',
    'hina',
    'role',
    '鍵山 雛に関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '鍵山 雛', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_mofa',
    'official',
    70,
    '["hina","mountain"]'::jsonb
  ),
  (
    'claim_tewi_eientei_trickster',
    'gensokyo_main',
    'character',
    'tewi',
    'role',
    '因幡 てゐに関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '因幡 てゐ', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_imperishable_night',
    'official',
    73,
    '["tewi","eientei","luck"]'::jsonb
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

insert into public.world_locations (
  world_id, id, name, kind, parent_location_id, title, summary, description, tags, default_mood, neighbors, metadata
)
values
  (
    'gensokyo_main',
    'divine_spirit_mausoleum',
    '神霊廟',
    'major_location',
    null,
    '神霊廟の地域情報',
    '神霊廟に関する基本地点情報です。',
    '神霊廟の特徴や周辺とのつながりを日本語で整理した説明です。',
    '["mausoleum","ritual","authority"]'::jsonb,
    '落ち着いた雰囲気',
    '["human_village","senkai"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'senkai',
    '仙界',
    'major_location',
    null,
    '仙界の地域情報',
    '仙界に関する基本地点情報です。',
    '仙界の特徴や周辺とのつながりを日本語で整理した説明です。',
    '["realm","hermit","hidden"]'::jsonb,
    '落ち着いた雰囲気',
    '["divine_spirit_mausoleum"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'shining_needle_castle',
    '輝針城',
    'major_location',
    null,
    '輝針城の地域情報',
    '輝針城に関する基本地点情報です。',
    '輝針城の特徴や周辺とのつながりを日本語で整理した説明です。',
    '["castle","reversal","inchling"]'::jsonb,
    '落ち着いた雰囲気',
    '["human_village","hakurei_shrine"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'lunar_capital',
    '月の都',
    'major_location',
    null,
    '月の都の地域情報',
    '月の都に関する基本地点情報です。',
    '月の都の特徴や周辺とのつながりを日本語で整理した説明です。',
    '["moon","capital","purity"]'::jsonb,
    '落ち着いた雰囲気',
    '["eientei"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'backdoor_realm',
    '後戸の国',
    'major_location',
    null,
    '後戸の国の地域情報',
    '後戸の国に関する基本地点情報です。',
    '後戸の国の特徴や周辺とのつながりを日本語で整理した説明です。',
    '["realm","backdoor","hidden"]'::jsonb,
    '落ち着いた雰囲気',
    '["forest_of_magic","hakurei_shrine","youkai_mountain_foot"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'beast_realm',
    '畜生界',
    'major_location',
    null,
    '畜生界の地域情報',
    '畜生界に関する基本地点情報です。',
    '畜生界の特徴や周辺とのつながりを日本語で整理した説明です。',
    '["realm","beast","factional"]'::jsonb,
    '落ち着いた雰囲気',
    '["former_hell","old_capital"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'rainbow_dragon_cave',
    '虹龍洞',
    'major_location',
    null,
    '虹龍洞の地域情報',
    '虹龍洞に関する基本地点情報です。',
    '虹龍洞の特徴や周辺とのつながりを日本語で整理した説明です。',
    '["cave","market","mountain"]'::jsonb,
    '落ち着いた雰囲気',
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

insert into public.world_characters (
  world_id, id, name, title, species, faction_id, home_location_id, default_location_id, public_summary, private_notes, speech_style, worldview, role_in_gensokyo, tags, profile
)
values
  (
    'gensokyo_main',
    'nazrin',
    'ナズーリン',
    'ダウザーの小さな大将',
    '鼠妖怪',
    'myouren',
    'myouren_temple',
    'myouren_temple',
    'ナズーリンに関する基本人物紹介です。',
    'ナズーリンを配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    'ナズーリンの価値観や見方を整理した文面です。',
    'ナズーリンの役割です。',
    '["ufo","search","temple"]'::jsonb,
    jsonb_build_object('表示名', 'ナズーリン', '肩書き', 'ダウザーの小さな大将', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'kogasa',
    '多々良 小傘',
    '愉快な忘れ傘',
    '種族',
    'independent',
    'human_village',
    'human_village',
    '多々良 小傘に関する基本人物紹介です。',
    '多々良 小傘を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '多々良 小傘の価値観や見方を整理した文面です。',
    '多々良 小傘の役割です。',
    '["ufo","tsukumogami","surprise"]'::jsonb,
    jsonb_build_object('表示名', '多々良 小傘', '肩書き', '愉快な忘れ傘', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'ichirin',
    '雲居 一輪',
    '入道使いの尼僧',
    '妖怪',
    'myouren',
    'myouren_temple',
    'myouren_temple',
    '雲居 一輪に関する基本人物紹介です。',
    '雲居 一輪を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '雲居 一輪の価値観や見方を整理した文面です。',
    '雲居 一輪の役割です。',
    '["ufo","temple","guardian"]'::jsonb,
    jsonb_build_object('表示名', '雲居 一輪', '肩書き', '入道使いの尼僧', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'murasa',
    '村紗 水蜜',
    '愉快な忘れ傘',
    '種族',
    'myouren',
    'myouren_temple',
    'myouren_temple',
    '村紗 水蜜に関する基本人物紹介です。',
    '村紗 水蜜を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '村紗 水蜜の価値観や見方を整理した文面です。',
    '村紗 水蜜の役割です。',
    '["ufo","captain","movement"]'::jsonb,
    jsonb_build_object('表示名', '村紗 水蜜', '肩書き', '愉快な忘れ傘', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'nue',
    '封獣 ぬえ',
    '正体不明の妖怪',
    '妖怪',
    'independent',
    'myouren_temple',
    'human_village',
    '封獣 ぬえに関する基本人物紹介です。',
    '封獣 ぬえを配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '封獣 ぬえの価値観や見方を整理した文面です。',
    '封獣 ぬえの役割です。',
    '["ufo","unknown","ambiguity"]'::jsonb,
    jsonb_build_object('表示名', '封獣 ぬえ', '肩書き', '正体不明の妖怪', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'seiga',
    '霍 青娥',
    '壁抜けの邪仙',
    '種族',
    'independent',
    'senkai',
    'divine_spirit_mausoleum',
    '霍 青娥に関する基本人物紹介です。',
    '霍 青娥を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '霍 青娥の価値観や見方を整理した文面です。',
    '霍 青娥の役割です。',
    '["td","hermit","intrusion"]'::jsonb,
    jsonb_build_object('表示名', '霍 青娥', '肩書き', '壁抜けの邪仙', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'miko',
    '豊聡耳 神子',
    '聖徳道士',
    '種族',
    'divine_spirit',
    'divine_spirit_mausoleum',
    'divine_spirit_mausoleum',
    '豊聡耳 神子に関する基本人物紹介です。',
    '豊聡耳 神子を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '豊聡耳 神子の価値観や見方を整理した文面です。',
    '豊聡耳 神子の役割です。',
    '["td","saint","leadership"]'::jsonb,
    jsonb_build_object('表示名', '豊聡耳 神子', '肩書き', '聖徳道士', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'futo',
    '物部 布都',
    '古代の道士',
    '人間',
    'divine_spirit',
    'divine_spirit_mausoleum',
    'divine_spirit_mausoleum',
    '物部 布都に関する基本人物紹介です。',
    '物部 布都を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '物部 布都の価値観や見方を整理した文面です。',
    '物部 布都の役割です。',
    '["td","ritual","retainer"]'::jsonb,
    jsonb_build_object('表示名', '物部 布都', '肩書き', '古代の道士', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'tojiko',
    '蘇我 屠自古',
    '入鹿の雷',
    '種族',
    'divine_spirit',
    'divine_spirit_mausoleum',
    'divine_spirit_mausoleum',
    '蘇我 屠自古に関する基本人物紹介です。',
    '蘇我 屠自古を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '蘇我 屠自古の価値観や見方を整理した文面です。',
    '蘇我 屠自古の役割です。',
    '["td","spirit","retainer"]'::jsonb,
    jsonb_build_object('表示名', '蘇我 屠自古', '肩書き', '入鹿の雷', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'mamizou',
    '二ッ岩 マミゾウ',
    '古参の化け狸',
    '種族',
    'independent',
    'human_village',
    'myouren_temple',
    '二ッ岩 マミゾウに関する基本人物紹介です。',
    '二ッ岩 マミゾウを配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '二ッ岩 マミゾウの価値観や見方を整理した文面です。',
    '二ッ岩 マミゾウの役割です。',
    '["td","tanuki","mediator"]'::jsonb,
    jsonb_build_object('表示名', '二ッ岩 マミゾウ', '肩書き', '古参の化け狸', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'seija',
    '鬼人 正邪',
    '逆襲のあまのじゃく',
    '種族',
    'independent',
    'shining_needle_castle',
    'human_village',
    '鬼人 正邪に関する基本人物紹介です。',
    '鬼人 正邪を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '鬼人 正邪の価値観や見方を整理した文面です。',
    '鬼人 正邪の役割です。',
    '["ddc","reversal","rebel"]'::jsonb,
    jsonb_build_object('表示名', '鬼人 正邪', '肩書き', '逆襲のあまのじゃく', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'shinmyoumaru',
    '少名 針妙丸',
    '小人の末裔',
    '種族',
    'independent',
    'shining_needle_castle',
    'shining_needle_castle',
    '少名 針妙丸に関する基本人物紹介です。',
    '少名 針妙丸を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '少名 針妙丸の価値観や見方を整理した文面です。',
    '少名 針妙丸の役割です。',
    '["ddc","inchling","princess"]'::jsonb,
    jsonb_build_object('表示名', '少名 針妙丸', '肩書き', '小人の末裔', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'raiko',
    '堀川 雷鼓',
    '夢幻のパーカッショニスト',
    '種族',
    'independent',
    'human_village',
    'human_village',
    '堀川 雷鼓に関する基本人物紹介です。',
    '堀川 雷鼓を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '堀川 雷鼓の価値観や見方を整理した文面です。',
    '堀川 雷鼓の役割です。',
    '["ddc","music","independent"]'::jsonb,
    jsonb_build_object('表示名', '堀川 雷鼓', '肩書き', '夢幻のパーカッショニスト', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'sagume',
    '稀神 サグメ',
    '片翼の白鷺',
    '月人',
    'lunar_capital',
    'lunar_capital',
    'lunar_capital',
    '稀神 サグメに関する基本人物紹介です。',
    '稀神 サグメを配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '稀神 サグメの価値観や見方を整理した文面です。',
    '稀神 サグメの役割です。',
    '["lolk","moon","strategy"]'::jsonb,
    jsonb_build_object('表示名', '稀神 サグメ', '肩書き', '片翼の白鷺', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'clownpiece',
    'クラウンピース',
    '地獄の妖精',
    '種族',
    'independent',
    'lunar_capital',
    'former_hell',
    'クラウンピースに関する基本人物紹介です。',
    'クラウンピースを配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    'クラウンピースの価値観や見方を整理した文面です。',
    'クラウンピースの役割です。',
    '["lolk","fairy","hell"]'::jsonb,
    jsonb_build_object('表示名', 'クラウンピース', '肩書き', '地獄の妖精', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'junko',
    '純狐',
    '純化された怨念',
    '神霊',
    'independent',
    'lunar_capital',
    'lunar_capital',
    '純狐に関する基本人物紹介です。',
    '純狐を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '純狐の価値観や見方を整理した文面です。',
    '純狐の役割です。',
    '["lolk","purity","vengeance"]'::jsonb,
    jsonb_build_object('表示名', '純狐', '肩書き', '純化された怨念', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'hecatia',
    'ヘカーティア・ラピスラズリ',
    '多元世界の女神',
    '神格',
    'independent',
    'lunar_capital',
    'lunar_capital',
    'ヘカーティア・ラピスラズリに関する基本人物紹介です。',
    'ヘカーティア・ラピスラズリを配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    'ヘカーティア・ラピスラズリの価値観や見方を整理した文面です。',
    'ヘカーティア・ラピスラズリの役割です。',
    '["lolk","goddess","high_impact"]'::jsonb,
    jsonb_build_object('表示名', 'ヘカーティア・ラピスラズリ', '肩書き', '多元世界の女神', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'okina',
    '摩多羅 隠岐奈',
    '秘神',
    '種族',
    'independent',
    'backdoor_realm',
    'backdoor_realm',
    '摩多羅 隠岐奈に関する基本人物紹介です。',
    '摩多羅 隠岐奈を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '摩多羅 隠岐奈の価値観や見方を整理した文面です。',
    '摩多羅 隠岐奈の役割です。',
    '["hsifs","secret","backdoor"]'::jsonb,
    jsonb_build_object('表示名', '摩多羅 隠岐奈', '肩書き', '秘神', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'satono',
    '爾子田 里乃',
    '後戸の扉を開く従者',
    '人間',
    'independent',
    'backdoor_realm',
    'backdoor_realm',
    '爾子田 里乃に関する基本人物紹介です。',
    '爾子田 里乃を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '爾子田 里乃の価値観や見方を整理した文面です。',
    '爾子田 里乃の役割です。',
    '["hsifs","servant","backdoor"]'::jsonb,
    jsonb_build_object('表示名', '爾子田 里乃', '肩書き', '後戸の扉を開く従者', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'mai',
    '丁礼田 舞',
    '後戸で舞う従者',
    '人間',
    'independent',
    'backdoor_realm',
    'backdoor_realm',
    '丁礼田 舞に関する基本人物紹介です。',
    '丁礼田 舞を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '丁礼田 舞の価値観や見方を整理した文面です。',
    '丁礼田 舞の役割です。',
    '["hsifs","servant","backdoor"]'::jsonb,
    jsonb_build_object('表示名', '丁礼田 舞', '肩書き', '後戸で舞う従者', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'narumi',
    '矢田寺 成美',
    '魔法地蔵',
    '種族',
    'independent',
    'forest_of_magic',
    'forest_of_magic',
    '矢田寺 成美に関する基本人物紹介です。',
    '矢田寺 成美を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '矢田寺 成美の価値観や見方を整理した文面です。',
    '矢田寺 成美の役割です。',
    '["hsifs","forest","jizo"]'::jsonb,
    jsonb_build_object('表示名', '矢田寺 成美', '肩書き', '魔法地蔵', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'yachie',
    '吉弔 八千慧',
    '鬼傑組組長',
    '動物霊',
    'beast_realm',
    'beast_realm',
    'beast_realm',
    '吉弔 八千慧に関する基本人物紹介です。',
    '吉弔 八千慧を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '吉弔 八千慧の価値観や見方を整理した文面です。',
    '吉弔 八千慧の役割です。',
    '["wbawc","beast_realm","strategy"]'::jsonb,
    jsonb_build_object('表示名', '吉弔 八千慧', '肩書き', '鬼傑組組長', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'mayumi',
    '杖刀偶 磨弓',
    '埴輪の武人',
    '種族',
    'beast_realm',
    'beast_realm',
    'beast_realm',
    '杖刀偶 磨弓に関する基本人物紹介です。',
    '杖刀偶 磨弓を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '杖刀偶 磨弓の価値観や見方を整理した文面です。',
    '杖刀偶 磨弓の役割です。',
    '["wbawc","haniwa","duty"]'::jsonb,
    jsonb_build_object('表示名', '杖刀偶 磨弓', '肩書き', '埴輪の武人', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'keiki',
    '埴安神 袿姫',
    '偶像を創る神',
    '種族',
    'independent',
    'beast_realm',
    'beast_realm',
    '埴安神 袿姫に関する基本人物紹介です。',
    '埴安神 袿姫を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '埴安神 袿姫の価値観や見方を整理した文面です。',
    '埴安神 袿姫の役割です。',
    '["wbawc","creator","craft"]'::jsonb,
    jsonb_build_object('表示名', '埴安神 袿姫', '肩書き', '偶像を創る神', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'saki',
    '驪駒 早鬼',
    '地獄の最高速ライダー',
    '動物霊',
    'beast_realm',
    'beast_realm',
    'beast_realm',
    '驪駒 早鬼に関する基本人物紹介です。',
    '驪駒 早鬼を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '驪駒 早鬼の価値観や見方を整理した文面です。',
    '驪駒 早鬼の役割です。',
    '["wbawc","beast_realm","force"]'::jsonb,
    jsonb_build_object('表示名', '驪駒 早鬼', '肩書き', '地獄の最高速ライダー', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'takane',
    '山城 たかね',
    '山奥のビジネス妖怪',
    '種族',
    'mountain',
    'rainbow_dragon_cave',
    'youkai_mountain_foot',
    '山城 たかねに関する基本人物紹介です。',
    '山城 たかねを配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '山城 たかねの価値観や見方を整理した文面です。',
    '山城 たかねの役割です。',
    '["um","trade","mountain"]'::jsonb,
    jsonb_build_object('表示名', '山城 たかね', '肩書き', '山奥のビジネス妖怪', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'sannyo',
    '駒草 山如',
    '山の煙草商',
    '妖怪',
    'independent',
    'rainbow_dragon_cave',
    'rainbow_dragon_cave',
    '駒草 山如に関する基本人物紹介です。',
    '駒草 山如を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '駒草 山如の価値観や見方を整理した文面です。',
    '駒草 山如の役割です。',
    '["um","market","seller"]'::jsonb,
    jsonb_build_object('表示名', '駒草 山如', '肩書き', '山の煙草商', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'misumaru',
    '玉造 魅須丸',
    '勾玉職人',
    '種族',
    'independent',
    'rainbow_dragon_cave',
    'rainbow_dragon_cave',
    '玉造 魅須丸に関する基本人物紹介です。',
    '玉造 魅須丸を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '玉造 魅須丸の価値観や見方を整理した文面です。',
    '玉造 魅須丸の役割です。',
    '["um","craft","orbs"]'::jsonb,
    jsonb_build_object('表示名', '玉造 魅須丸', '肩書き', '勾玉職人', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'chimata',
    '天弓 千亦',
    '市場を司る神',
    '種族',
    'independent',
    'human_village',
    'human_village',
    '天弓 千亦に関する基本人物紹介です。',
    '天弓 千亦を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '天弓 千亦の価値観や見方を整理した文面です。',
    '天弓 千亦の役割です。',
    '["um","market","exchange"]'::jsonb,
    jsonb_build_object('表示名', '天弓 千亦', '肩書き', '市場を司る神', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'momoyo',
    '姫虫 百々世',
    '龍を食らう大百足',
    '百足妖怪',
    'independent',
    'rainbow_dragon_cave',
    'rainbow_dragon_cave',
    '姫虫 百々世に関する基本人物紹介です。',
    '姫虫 百々世を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '姫虫 百々世の価値観や見方を整理した文面です。',
    '姫虫 百々世の役割です。',
    '["um","mountain","mining"]'::jsonb,
    jsonb_build_object('表示名', '姫虫 百々世', '肩書き', '龍を食らう大百足', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'tsukasa',
    '菅牧 典',
    '高貴なる策謀家',
    '種族',
    'independent',
    'youkai_mountain_foot',
    'human_village',
    '菅牧 典に関する基本人物紹介です。',
    '菅牧 典を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '菅牧 典の価値観や見方を整理した文面です。',
    '菅牧 典の役割です。',
    '["um","fox","manipulation"]'::jsonb,
    jsonb_build_object('表示名', '菅牧 典', '肩書き', '高貴なる策謀家', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'megumu',
    '飯綱丸 龍',
    '大天狗の長',
    '天狗',
    'mountain',
    'moriya_shrine',
    'youkai_mountain_foot',
    '飯綱丸 龍に関する基本人物紹介です。',
    '飯綱丸 龍を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '飯綱丸 龍の価値観や見方を整理した文面です。',
    '飯綱丸 龍の役割です。',
    '["um","tengu","leadership"]'::jsonb,
    jsonb_build_object('表示名', '飯綱丸 龍', '肩書き', '大天狗の長', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
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
  (
    'gensokyo_main',
    'nazrin',
    'byakuren',
    'subordinate_respect',
    'ナズーリンと聖 白蓮のあいだにある関係を示す関係データです。',
    0.67,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'ichirin',
    'byakuren',
    'devotional_service',
    '雲居 一輪と聖 白蓮のあいだにある信仰と奉仕に基づく関係を示す関係データです。',
    0.81,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'murasa',
    'byakuren',
    'group_alignment',
    '村紗 水蜜と聖 白蓮のあいだにある関係を示す関係データです。',
    0.74,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'nue',
    'byakuren',
    'uneasy_affiliation',
    '封獣 ぬえと聖 白蓮のあいだにある関係を示す関係データです。',
    0.46,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'kogasa',
    'byakuren',
    'friendly_affiliation',
    '多々良 小傘と聖 白蓮のあいだにある関係を示す関係データです。',
    0.41,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'miko',
    'futo',
    'leader_retainer',
    '豊聡耳 神子と物部 布都のあいだにある関係を示す関係データです。',
    0.86,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'miko',
    'tojiko',
    'leader_retainer',
    '豊聡耳 神子と蘇我 屠自古のあいだにある関係を示す関係データです。',
    0.82,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'seiga',
    'miko',
    'provocative_enabler',
    '霍 青娥と豊聡耳 神子のあいだにある関係を示す関係データです。',
    0.61,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'mamizou',
    'byakuren',
    'institutional_ally',
    '二ッ岩 マミゾウと聖 白蓮のあいだにある関係を示す関係データです。',
    0.58,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'mamizou',
    'reimu',
    'experienced_peer',
    '二ッ岩 マミゾウと博麗 霊夢のあいだにある関係を示す関係データです。',
    0.39,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'seija',
    'shinmyoumaru',
    'rebel_alignment',
    '鬼人 正邪と少名 針妙丸のあいだにある関係を示す関係データです。',
    0.83,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'shinmyoumaru',
    'seija',
    'desperate_ally',
    '少名 針妙丸と鬼人 正邪のあいだにある関係を示す関係データです。',
    0.79,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'raiko',
    'shinmyoumaru',
    'post_incident_affinity',
    '堀川 雷鼓と少名 針妙丸のあいだにある関係を示す関係データです。',
    0.42,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'sagume',
    'junko',
    'crisis_opposition',
    '稀神 サグメと純狐のあいだにある関係を示す関係データです。',
    0.92,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'clownpiece',
    'junko',
    'aligned_agent',
    'クラウンピースと純狐のあいだにある関係を示す関係データです。',
    0.86,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'hecatia',
    'clownpiece',
    'patron_support',
    'ヘカーティア・ラピスラズリとクラウンピースのあいだにある関係を示す関係データです。',
    0.74,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'okina',
    'satono',
    'master_attendant',
    '摩多羅 隠岐奈と爾子田 里乃のあいだにある関係を示す関係データです。',
    0.88,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'okina',
    'mai',
    'master_attendant',
    '摩多羅 隠岐奈と丁礼田 舞のあいだにある関係を示す関係データです。',
    0.88,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'satono',
    'mai',
    'paired_service',
    '爾子田 里乃と丁礼田 舞のあいだにある関係を示す関係データです。',
    0.77,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'yachie',
    'mayumi',
    'strategic_use',
    '吉弔 八千慧と杖刀偶 磨弓のあいだにある関係を示す関係データです。',
    0.49,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'keiki',
    'mayumi',
    'creator_creation',
    '埴安神 袿姫と杖刀偶 磨弓のあいだにある関係を示す関係データです。',
    0.84,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'yachie',
    'saki',
    'factional_rival',
    '吉弔 八千慧と驪駒 早鬼のあいだにある関係を示す関係データです。',
    0.73,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'takane',
    'chimata',
    'market_affinity',
    '山城 たかねと天弓 千亦のあいだにある関係を示す関係データです。',
    0.66,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'sannyo',
    'chimata',
    'vendor_affinity',
    '駒草 山如と天弓 千亦のあいだにある関係を示す関係データです。',
    0.62,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'misumaru',
    'reimu',
    'craft_support',
    '玉造 魅須丸と博麗 霊夢のあいだにある関係を示す関係データです。',
    0.48,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'tsukasa',
    'megumu',
    'opportunistic_alignment',
    '菅牧 典と飯綱丸 龍のあいだにある関係を示す関係データです。',
    0.37,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'momoyo',
    'takane',
    'mountain_trade_overlap',
    '姫虫 百々世と山城 たかねのあいだにある関係を示す関係データです。',
    0.43,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'megumu',
    'aya',
    'institutional_tengu_peer',
    '飯綱丸 龍と射命丸 文のあいだにある関係を示す関係データです。',
    0.57,
    '{}'::jsonb
  )
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
    'lore_myouren_public_plurality',
    'faction_trait',
    '幻想郷設定項目',
    '勢力や集団の性質を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'faction_trait', '説明', '日本語表示向けに整理した説明データです。'),
    '["ufo","temple","community"]'::jsonb,
    80
  ),
  (
    'gensokyo_main',
    'lore_mausoleum_politics',
    'location_trait',
    '幻想郷設定項目',
    '土地ごとの性質や役割を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'location_trait', '説明', '日本語表示向けに整理した説明データです。'),
    '["td","mausoleum","authority"]'::jsonb,
    82
  ),
  (
    'gensokyo_main',
    'lore_ddc_reversal_logic',
    'world_rule',
    '幻想郷設定項目',
    '幻想郷全体に関わる基本ルールを整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'world_rule', '説明', '日本語表示向けに整理した説明データです。'),
    '["ddc","reversal","legitimacy"]'::jsonb,
    79
  ),
  (
    'gensokyo_main',
    'lore_lunar_distance',
    'world_rule',
    '幻想郷設定項目',
    '幻想郷全体に関わる基本ルールを整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'world_rule', '説明', '日本語表示向けに整理した説明データです。'),
    '["lolk","moon","distance"]'::jsonb,
    86
  ),
  (
    'gensokyo_main',
    'lore_okina_hidden_access',
    'character_role',
    '幻想郷設定項目',
    '人物の立ち位置や役割を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_role', '説明', '日本語表示向けに整理した説明データです。'),
    '["hsifs","backdoor","secret"]'::jsonb,
    84
  ),
  (
    'gensokyo_main',
    'lore_beast_realm_factions',
    'location_trait',
    '幻想郷設定項目',
    '土地ごとの性質や役割を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'location_trait', '説明', '日本語表示向けに整理した説明データです。'),
    '["wbawc","faction","power"]'::jsonb,
    83
  ),
  (
    'gensokyo_main',
    'lore_um_market_flow',
    'world_rule',
    '幻想郷設定項目',
    '幻想郷全体に関わる基本ルールを整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'world_rule', '説明', '日本語表示向けに整理した説明データです。'),
    '["um","market","trade"]'::jsonb,
    81
  ),
  (
    'gensokyo_main',
    'lore_nazrin_search_role',
    'character_role',
    '幻想郷設定項目',
    '人物の立ち位置や役割を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_role', '説明', '日本語表示向けに整理した説明データです。'),
    '["nazrin","search"]'::jsonb,
    72
  ),
  (
    'gensokyo_main',
    'lore_miko_public_authority',
    'character_role',
    '幻想郷設定項目',
    '人物の立ち位置や役割を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_role', '説明', '日本語表示向けに整理した説明データです。'),
    '["miko","authority"]'::jsonb,
    84
  ),
  (
    'gensokyo_main',
    'lore_seija_contrarian_pressure',
    'character_role',
    '幻想郷設定項目',
    '人物の立ち位置や役割を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_role', '説明', '日本語表示向けに整理した説明データです。'),
    '["seija","reversal"]'::jsonb,
    76
  ),
  (
    'gensokyo_main',
    'lore_junko_high_impact',
    'character_role',
    '幻想郷設定項目',
    '人物の立ち位置や役割を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_role', '説明', '日本語表示向けに整理した説明データです。'),
    '["junko","high_impact"]'::jsonb,
    88
  ),
  (
    'gensokyo_main',
    'lore_takane_trade_frame',
    'character_role',
    '幻想郷設定項目',
    '人物の立ち位置や役割を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_role', '説明', '日本語表示向けに整理した説明データです。'),
    '["takane","trade"]'::jsonb,
    73
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
    'claim_nazrin_search_specialist',
    'gensokyo_main',
    'character',
    'nazrin',
    'role',
    'ナズーリンに関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', 'ナズーリン', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_ufo',
    'official',
    72,
    '["nazrin","ufo","search"]'::jsonb
  ),
  (
    'claim_kogasa_surprise',
    'gensokyo_main',
    'character',
    'kogasa',
    'role',
    '多々良 小傘に関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '多々良 小傘', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_ufo',
    'official',
    68,
    '["kogasa","ufo","surprise"]'::jsonb
  ),
  (
    'claim_murasa_navigation',
    'gensokyo_main',
    'character',
    'murasa',
    'role',
    '村紗 水蜜に関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '村紗 水蜜', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_ufo',
    'official',
    71,
    '["murasa","ufo","captain"]'::jsonb
  ),
  (
    'claim_nue_ambiguity',
    'gensokyo_main',
    'character',
    'nue',
    'role',
    '封獣 ぬえに関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '封獣 ぬえ', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_ufo',
    'official',
    75,
    '["nue","ufo","ambiguity"]'::jsonb
  ),
  (
    'claim_miko_saint_leadership',
    'gensokyo_main',
    'character',
    'miko',
    'role',
    '豊聡耳 神子に関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '豊聡耳 神子', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_td',
    'official',
    84,
    '["miko","td","leadership"]'::jsonb
  ),
  (
    'claim_seiga_intrusion',
    'gensokyo_main',
    'character',
    'seiga',
    'role',
    '霍 青娥に関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '霍 青娥', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_td',
    'official',
    74,
    '["seiga","td","intrusion"]'::jsonb
  ),
  (
    'claim_mamizou_mediator',
    'gensokyo_main',
    'character',
    'mamizou',
    'role',
    '二ッ岩 マミゾウに関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '二ッ岩 マミゾウ', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_td',
    'official',
    76,
    '["mamizou","td","mediator"]'::jsonb
  ),
  (
    'claim_seija_rebel',
    'gensokyo_main',
    'character',
    'seija',
    'role',
    '鬼人 正邪に関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '鬼人 正邪', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_ddc',
    'official',
    79,
    '["seija","ddc","rebel"]'::jsonb
  ),
  (
    'claim_shinmyoumaru_symbolic_rule',
    'gensokyo_main',
    'character',
    'shinmyoumaru',
    'role',
    '少名 針妙丸に関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '少名 針妙丸', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_ddc',
    'official',
    78,
    '["shinmyoumaru","ddc","inchling"]'::jsonb
  ),
  (
    'claim_raiko_independent_tsukumogami',
    'gensokyo_main',
    'character',
    'raiko',
    'role',
    '堀川 雷鼓に関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '堀川 雷鼓', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_ddc',
    'official',
    70,
    '["raiko","ddc","music"]'::jsonb
  ),
  (
    'claim_sagume_lunar_strategy',
    'gensokyo_main',
    'character',
    'sagume',
    'role',
    '稀神 サグメに関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '稀神 サグメ', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_lolk',
    'official',
    85,
    '["sagume","lolk","moon"]'::jsonb
  ),
  (
    'claim_junko_pure_hostility',
    'gensokyo_main',
    'character',
    'junko',
    'role',
    '純狐に関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '純狐', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_lolk',
    'official',
    90,
    '["junko","lolk","purity"]'::jsonb
  ),
  (
    'claim_hecatia_scale',
    'gensokyo_main',
    'character',
    'hecatia',
    'role',
    'ヘカーティア・ラピスラズリに関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', 'ヘカーティア・ラピスラズリ', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_lolk',
    'official',
    88,
    '["hecatia","lolk","scale"]'::jsonb
  ),
  (
    'claim_okina_hidden_doors',
    'gensokyo_main',
    'character',
    'okina',
    'role',
    '摩多羅 隠岐奈に関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '摩多羅 隠岐奈', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_hsifs',
    'official',
    86,
    '["okina","hsifs","backdoor"]'::jsonb
  ),
  (
    'claim_narumi_local_guardian',
    'gensokyo_main',
    'character',
    'narumi',
    'role',
    '矢田寺 成美に関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '矢田寺 成美', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_hsifs',
    'official',
    67,
    '["narumi","hsifs","forest"]'::jsonb
  ),
  (
    'claim_yachie_faction_leader',
    'gensokyo_main',
    'character',
    'yachie',
    'role',
    '吉弔 八千慧に関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '吉弔 八千慧', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_wbawc',
    'official',
    83,
    '["yachie","wbawc","faction"]'::jsonb
  ),
  (
    'claim_keiki_creator_order',
    'gensokyo_main',
    'character',
    'keiki',
    'role',
    '埴安神 袿姫に関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '埴安神 袿姫', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_wbawc',
    'official',
    80,
    '["keiki","wbawc","creator"]'::jsonb
  ),
  (
    'claim_takane_broker',
    'gensokyo_main',
    'character',
    'takane',
    'role',
    '山城 たかねに関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '山城 たかね', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_um',
    'official',
    75,
    '["takane","um","trade"]'::jsonb
  ),
  (
    'claim_chimata_market_patron',
    'gensokyo_main',
    'character',
    'chimata',
    'role',
    '天弓 千亦に関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '天弓 千亦', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_um',
    'official',
    80,
    '["chimata","um","market"]'::jsonb
  ),
  (
    'claim_tsukasa_soft_corruption',
    'gensokyo_main',
    'character',
    'tsukasa',
    'role',
    '菅牧 典に関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '菅牧 典', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_um',
    'official',
    74,
    '["tsukasa","um","manipulation"]'::jsonb
  ),
  (
    'claim_megumu_mountain_authority',
    'gensokyo_main',
    'character',
    'megumu',
    'role',
    '飯綱丸 龍に関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '飯綱丸 龍', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_um',
    'official',
    77,
    '["megumu","um","tengu"]'::jsonb
  ),
  (
    'claim_divine_spirit_mausoleum_profile',
    'gensokyo_main',
    'location',
    'divine_spirit_mausoleum',
    'profile',
    '神霊廟に関する正史設定です。分類は輪郭です。',
    jsonb_build_object('対象', '神霊廟', '分類', '輪郭', '説明', '日本語表示向けに整理した説明データです。'),
    'src_td',
    'official',
    83,
    '["location","td","mausoleum"]'::jsonb
  ),
  (
    'claim_shining_needle_castle_profile',
    'gensokyo_main',
    'location',
    'shining_needle_castle',
    'profile',
    '輝針城に関する正史設定です。分類は輪郭です。',
    jsonb_build_object('対象', '輝針城', '分類', '輪郭', '説明', '日本語表示向けに整理した説明データです。'),
    'src_ddc',
    'official',
    78,
    '["location","ddc","castle"]'::jsonb
  ),
  (
    'claim_lunar_capital_profile',
    'gensokyo_main',
    'location',
    'lunar_capital',
    'profile',
    '月の都に関する正史設定です。分類は輪郭です。',
    jsonb_build_object('対象', '月の都', '分類', '輪郭', '説明', '日本語表示向けに整理した説明データです。'),
    'src_lolk',
    'official',
    87,
    '["location","lolk","moon"]'::jsonb
  ),
  (
    'claim_backdoor_realm_profile',
    'gensokyo_main',
    'location',
    'backdoor_realm',
    'profile',
    '後戸の国に関する正史設定です。分類は輪郭です。',
    jsonb_build_object('対象', '後戸の国', '分類', '輪郭', '説明', '日本語表示向けに整理した説明データです。'),
    'src_hsifs',
    'official',
    84,
    '["location","hsifs","backdoor"]'::jsonb
  ),
  (
    'claim_beast_realm_profile',
    'gensokyo_main',
    'location',
    'beast_realm',
    'profile',
    '畜生界に関する正史設定です。分類は輪郭です。',
    jsonb_build_object('対象', '畜生界', '分類', '輪郭', '説明', '日本語表示向けに整理した説明データです。'),
    'src_wbawc',
    'official',
    84,
    '["location","wbawc","beast_realm"]'::jsonb
  ),
  (
    'claim_rainbow_dragon_cave_profile',
    'gensokyo_main',
    'location',
    'rainbow_dragon_cave',
    'profile',
    '虹龍洞に関する正史設定です。分類は輪郭です。',
    jsonb_build_object('対象', '虹龍洞', '分類', '輪郭', '説明', '日本語表示向けに整理した説明データです。'),
    'src_um',
    'official',
    79,
    '["location","um","market"]'::jsonb
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

insert into public.world_locations (
  world_id, id, name, kind, parent_location_id, title, summary, description, tags, default_mood, neighbors, metadata
)
values
  (
    'gensokyo_main',
    'kourindou',
    '香霖堂',
    'major_location',
    'human_village',
    '香霖堂の地域情報',
    '香霖堂に関する基本地点情報です。',
    '香霖堂の特徴や周辺とのつながりを日本語で整理した説明です。',
    '["shop","objects","curio"]'::jsonb,
    '落ち着いた雰囲気',
    '["human_village","hakurei_shrine"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'suzunaan',
    '鈴奈庵',
    'major_location',
    'human_village',
    '鈴奈庵の地域情報',
    '鈴奈庵に関する基本地点情報です。',
    '鈴奈庵の特徴や周辺とのつながりを日本語で整理した説明です。',
    '["books","village","records"]'::jsonb,
    '落ち着いた雰囲気',
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

insert into public.world_characters (
  world_id, id, name, title, species, faction_id, home_location_id, default_location_id, public_summary, private_notes, speech_style, worldview, role_in_gensokyo, tags, profile
)
values
  (
    'gensokyo_main',
    'rinnosuke',
    '森近 霖之助',
    '独自理論の道具屋',
    '種族',
    'independent',
    'kourindou',
    'kourindou',
    '森近 霖之助に関する基本人物紹介です。',
    '森近 霖之助を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '森近 霖之助の価値観や見方を整理した文面です。',
    '森近 霖之助の役割です。',
    '["cola","objects","merchant"]'::jsonb,
    jsonb_build_object('表示名', '森近 霖之助', '肩書き', '独自理論の道具屋', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'akyuu',
    '稗田 阿求',
    '御阿礼の子',
    '人間',
    'human_village',
    'human_village',
    'human_village',
    '稗田 阿求に関する基本人物紹介です。',
    '稗田 阿求を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '稗田 阿求の価値観や見方を整理した文面です。',
    '稗田 阿求の役割です。',
    '["pmiss","records","history"]'::jsonb,
    jsonb_build_object('表示名', '稗田 阿求', '肩書き', '御阿礼の子', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'kosuzu',
    '本居 小鈴',
    '鈴奈庵の看板娘',
    '人間',
    'human_village',
    'suzunaan',
    'suzunaan',
    '本居 小鈴に関する基本人物紹介です。',
    '本居 小鈴を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '本居 小鈴の価値観や見方を整理した文面です。',
    '本居 小鈴の役割です。',
    '["fs","books","village"]'::jsonb,
    jsonb_build_object('表示名', '本居 小鈴', '肩書き', '鈴奈庵の看板娘', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'hatate',
    '姫海棠 はたて',
    '流行を追う天狗記者',
    '天狗',
    'mountain',
    'youkai_mountain_foot',
    'youkai_mountain_foot',
    '姫海棠 はたてに関する基本人物紹介です。',
    '姫海棠 はたてを配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '姫海棠 はたての価値観や見方を整理した文面です。',
    '姫海棠 はたての役割です。',
    '["ds","reportage","tengu"]'::jsonb,
    jsonb_build_object('表示名', '姫海棠 はたて', '肩書き', '流行を追う天狗記者', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'kasen',
    '茨木 華扇',
    '片腕有角の仙人',
    '種族',
    'independent',
    'hakurei_shrine',
    'hakurei_shrine',
    '茨木 華扇に関する基本人物紹介です。',
    '茨木 華扇を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '茨木 華扇の価値観や見方を整理した文面です。',
    '茨木 華扇の役割です。',
    '["wahh","hermit","advisor"]'::jsonb,
    jsonb_build_object('表示名', '茨木 華扇', '肩書き', '片腕有角の仙人', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'sumireko',
    '宇佐見 菫子',
    '超能力を操る高校生',
    '人間',
    'independent',
    'muenzuka',
    'human_village',
    '宇佐見 菫子に関する基本人物紹介です。',
    '宇佐見 菫子を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '宇佐見 菫子の価値観や見方を整理した文面です。',
    '宇佐見 菫子の役割です。',
    '["ulil","outside_world","urban_legend"]'::jsonb,
    jsonb_build_object('表示名', '宇佐見 菫子', '肩書き', '超能力を操る高校生', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'joon',
    '依神 女苑',
    '浪費を呼ぶ疫病神',
    '神格',
    'independent',
    'human_village',
    'human_village',
    '依神 女苑に関する基本人物紹介です。',
    '依神 女苑を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '依神 女苑の価値観や見方を整理した文面です。',
    '依神 女苑の役割です。',
    '["aocf","poverty","glamour"]'::jsonb,
    jsonb_build_object('表示名', '依神 女苑', '肩書き', '浪費を呼ぶ疫病神', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'shion',
    '依神 紫苑',
    '最凶最悪の双子の妹',
    '神格',
    'independent',
    'human_village',
    'human_village',
    '依神 紫苑に関する基本人物紹介です。',
    '依神 紫苑を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '依神 紫苑の価値観や見方を整理した文面です。',
    '依神 紫苑の役割です。',
    '["aocf","poverty","misfortune"]'::jsonb,
    jsonb_build_object('表示名', '依神 紫苑', '肩書き', '最凶最悪の双子の妹', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
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
  (
    'gensokyo_main',
    'akyuu',
    'keine',
    'historical_collaboration',
    '稗田 阿求と上白沢 慧音のあいだにある関係を示す関係データです。',
    0.78,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'kosuzu',
    'akyuu',
    'record_affinity',
    '本居 小鈴と稗田 阿求のあいだにある関係を示す関係データです。',
    0.63,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'rinnosuke',
    'marisa',
    'object_familiarity',
    '森近 霖之助と霧雨 魔理沙のあいだにある関係を示す関係データです。',
    0.57,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'rinnosuke',
    'reimu',
    'dry_familiarity',
    '森近 霖之助と博麗 霊夢のあいだにある関係を示す関係データです。',
    0.44,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'hatate',
    'aya',
    'media_peer',
    '姫海棠 はたてと射命丸 文のあいだにある関係を示す関係データです。',
    0.69,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'kasen',
    'reimu',
    'corrective_guidance',
    '茨木 華扇と博麗 霊夢のあいだにある関係を示す関係データです。',
    0.76,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'sumireko',
    'yukari',
    'boundary_attention',
    '宇佐見 菫子と八雲 紫のあいだにある関係を示す関係データです。',
    0.41,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'joon',
    'shion',
    'sibling_asymmetry',
    '依神 女苑と依神 紫苑のあいだにある関係を示す関係データです。',
    0.88,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'shion',
    'joon',
    'sibling_dependency',
    '依神 紫苑と依神 女苑のあいだにある関係を示す関係データです。',
    0.88,
    '{}'::jsonb
  )
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
    'lore_village_records',
    'world_rule',
    '幻想郷設定項目',
    '幻想郷全体に関わる基本ルールを整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'world_rule', '説明', '日本語表示向けに整理した説明データです。'),
    '["records","village","history"]'::jsonb,
    84
  ),
  (
    'gensokyo_main',
    'lore_kourindou_objects',
    'location_trait',
    '幻想郷設定項目',
    '土地ごとの性質や役割を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'location_trait', '説明', '日本語表示向けに整理した説明データです。'),
    '["kourindou","objects"]'::jsonb,
    74
  ),
  (
    'gensokyo_main',
    'lore_suzunaan_books',
    'location_trait',
    '幻想郷設定項目',
    '土地ごとの性質や役割を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'location_trait', '説明', '日本語表示向けに整理した説明データです。'),
    '["suzunaan","books"]'::jsonb,
    76
  ),
  (
    'gensokyo_main',
    'lore_hatate_media_angle',
    'character_role',
    '幻想郷設定項目',
    '人物の立ち位置や役割を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_role', '説明', '日本語表示向けに整理した説明データです。'),
    '["hatate","media"]'::jsonb,
    71
  ),
  (
    'gensokyo_main',
    'lore_kasen_guidance',
    'character_role',
    '幻想郷設定項目',
    '人物の立ち位置や役割を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_role', '説明', '日本語表示向けに整理した説明データです。'),
    '["kasen","guidance"]'::jsonb,
    79
  ),
  (
    'gensokyo_main',
    'lore_urban_legend_bleed',
    'world_rule',
    '幻想郷設定項目',
    '幻想郷全体に関わる基本ルールを整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'world_rule', '説明', '日本語表示向けに整理した説明データです。'),
    '["ulil","rumor","boundary"]'::jsonb,
    77
  ),
  (
    'gensokyo_main',
    'lore_yorigami_pair',
    'character_role',
    '幻想郷設定項目',
    '人物の立ち位置や役割を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_role', '説明', '日本語表示向けに整理した説明データです。'),
    '["aocf","yorigami","pair"]'::jsonb,
    75
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
    'claim_rinnosuke_object_interpreter',
    'gensokyo_main',
    'character',
    'rinnosuke',
    'role',
    '森近 霖之助に関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '森近 霖之助', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_lotus_asia',
    'official',
    81,
    '["rinnosuke","objects","cola"]'::jsonb
  ),
  (
    'claim_akyuu_historian',
    'gensokyo_main',
    'character',
    'akyuu',
    'role',
    '稗田 阿求に関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '稗田 阿求', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_sixty_years',
    'official',
    88,
    '["akyuu","history","records"]'::jsonb
  ),
  (
    'claim_kosuzu_book_curator',
    'gensokyo_main',
    'character',
    'kosuzu',
    'role',
    '本居 小鈴に関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '本居 小鈴', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_fs',
    'official',
    78,
    '["kosuzu","books","fs"]'::jsonb
  ),
  (
    'claim_hatate_trend_observer',
    'gensokyo_main',
    'character',
    'hatate',
    'role',
    '姫海棠 はたてに関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '姫海棠 はたて', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_ds',
    'official',
    73,
    '["hatate","tengu","media"]'::jsonb
  ),
  (
    'claim_kasen_advisor',
    'gensokyo_main',
    'character',
    'kasen',
    'role',
    '茨木 華扇に関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '茨木 華扇', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_wahh',
    'official',
    82,
    '["kasen","advisor","wahh"]'::jsonb
  ),
  (
    'claim_sumireko_urban_legend',
    'gensokyo_main',
    'character',
    'sumireko',
    'role',
    '宇佐見 菫子に関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '宇佐見 菫子', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_ulil',
    'official',
    79,
    '["sumireko","urban_legend","outside_world"]'::jsonb
  ),
  (
    'claim_joon_social_drain',
    'gensokyo_main',
    'character',
    'joon',
    'role',
    '依神 女苑に関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '依神 女苑', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_aocf',
    'official',
    74,
    '["joon","aocf","glamour"]'::jsonb
  ),
  (
    'claim_shion_misfortune',
    'gensokyo_main',
    'character',
    'shion',
    'role',
    '依神 紫苑に関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '依神 紫苑', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_aocf',
    'official',
    75,
    '["shion","aocf","misfortune"]'::jsonb
  ),
  (
    'claim_kourindou_profile',
    'gensokyo_main',
    'location',
    'kourindou',
    'profile',
    '香霖堂に関する正史設定です。分類は輪郭です。',
    jsonb_build_object('対象', '香霖堂', '分類', '輪郭', '説明', '日本語表示向けに整理した説明データです。'),
    'src_lotus_asia',
    'official',
    77,
    '["location","kourindou","objects"]'::jsonb
  ),
  (
    'claim_suzunaan_profile',
    'gensokyo_main',
    'location',
    'suzunaan',
    'profile',
    '鈴奈庵に関する正史設定です。分類は輪郭です。',
    jsonb_build_object('対象', '鈴奈庵', '分類', '輪郭', '説明', '日本語表示向けに整理した説明データです。'),
    'src_fs',
    'official',
    79,
    '["location","suzunaan","books"]'::jsonb
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

insert into public.world_locations (
  world_id, id, name, kind, parent_location_id, title, summary, description, tags, default_mood, neighbors, metadata
)
values
  (
    'gensokyo_main',
    'heaven',
    '天界',
    'major_location',
    null,
    '天界の地域情報',
    '天界に関する基本地点情報です。',
    '天界の特徴や周辺とのつながりを日本語で整理した説明です。',
    '["celestial","weather","aloof"]'::jsonb,
    '落ち着いた雰囲気',
    '["hakurei_shrine","human_village"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'bhavaagra',
    '有頂天',
    'sub_location',
    'heaven',
    '有頂天の地域情報',
    '有頂天に関する基本地点情報です。',
    '有頂天の特徴や周辺とのつながりを日本語で整理した説明です。',
    '["celestial","seat","authority"]'::jsonb,
    '落ち着いた雰囲気',
    '["heaven"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'dream_world',
    '夢の世界',
    'major_location',
    null,
    '夢の世界の地域情報',
    '夢の世界に関する基本地点情報です。',
    '夢の世界の特徴や周辺とのつながりを日本語で整理した説明です。',
    '["dream","symbolic","unstable"]'::jsonb,
    '落ち着いた雰囲気',
    '["lunar_capital","hakurei_shrine"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'nameless_hill',
    '無名の丘',
    'major_location',
    null,
    '無名の丘の地域情報',
    '無名の丘に関する基本地点情報です。',
    '無名の丘の特徴や周辺とのつながりを日本語で整理した説明です。',
    '["flowers","poison","field"]'::jsonb,
    '落ち着いた雰囲気',
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

insert into public.world_characters (
  world_id, id, name, title, species, faction_id, home_location_id, default_location_id, public_summary, private_notes, speech_style, worldview, role_in_gensokyo, tags, profile
)
values
  (
    'gensokyo_main',
    'komachi',
    '小野塚 小町',
    '三途の水先案内人',
    '種族',
    'independent',
    'muenzuka',
    'muenzuka',
    '小野塚 小町に関する基本人物紹介です。',
    '小野塚 小町を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '小野塚 小町の価値観や見方を整理した文面です。',
    '小野塚 小町の役割です。',
    '["pofv","border","shinigami"]'::jsonb,
    jsonb_build_object('表示名', '小野塚 小町', '肩書き', '三途の水先案内人', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'eiki',
    '四季映姫・ヤマザナドゥ',
    '楽園の最高裁判長',
    '種族',
    'independent',
    'muenzuka',
    'muenzuka',
    '四季映姫・ヤマザナドゥに関する基本人物紹介です。',
    '四季映姫・ヤマザナドゥを配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '四季映姫・ヤマザナドゥの価値観や見方を整理した文面です。',
    '四季映姫・ヤマザナドゥの役割です。',
    '["pofv","judge","afterlife"]'::jsonb,
    jsonb_build_object('表示名', '四季映姫・ヤマザナドゥ', '肩書き', '楽園の最高裁判長', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'medicine',
    'メディスン・メランコリー',
    '小さなスイートポイズン',
    '種族',
    'independent',
    'nameless_hill',
    'nameless_hill',
    'メディスン・メランコリーに関する基本人物紹介です。',
    'メディスン・メランコリーを配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    'メディスン・メランコリーの価値観や見方を整理した文面です。',
    'メディスン・メランコリーの役割です。',
    '["pofv","poison","doll"]'::jsonb,
    jsonb_build_object('表示名', 'メディスン・メランコリー', '肩書き', '小さなスイートポイズン', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'yuuka',
    '風見 幽香',
    '四季のフラワーマスター',
    '妖怪',
    'independent',
    'nameless_hill',
    'nameless_hill',
    '風見 幽香に関する基本人物紹介です。',
    '風見 幽香を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '風見 幽香の価値観や見方を整理した文面です。',
    '風見 幽香の役割です。',
    '["pofv","flowers","high_impact"]'::jsonb,
    jsonb_build_object('表示名', '風見 幽香', '肩書き', '四季のフラワーマスター', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'iku',
    '永江 衣玖',
    '竜宮の使い遊泳弾',
    '種族',
    'independent',
    'heaven',
    'heaven',
    '永江 衣玖に関する基本人物紹介です。',
    '永江 衣玖を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '永江 衣玖の価値観や見方を整理した文面です。',
    '永江 衣玖の役割です。',
    '["swr","weather","heaven"]'::jsonb,
    jsonb_build_object('表示名', '永江 衣玖', '肩書き', '竜宮の使い遊泳弾', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'tenshi',
    '比那名居 天子',
    '非想非非想天の娘',
    '種族',
    'independent',
    'bhavaagra',
    'heaven',
    '比那名居 天子に関する基本人物紹介です。',
    '比那名居 天子を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '比那名居 天子の価値観や見方を整理した文面です。',
    '比那名居 天子の役割です。',
    '["swr","celestial","weather"]'::jsonb,
    jsonb_build_object('表示名', '比那名居 天子', '肩書き', '非想非非想天の娘', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'kokoro',
    '秦 こころ',
    '感情豊かなポーカーフェイス',
    '種族',
    'independent',
    'human_village',
    'human_village',
    '秦 こころに関する基本人物紹介です。',
    '秦 こころを配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '秦 こころの価値観や見方を整理した文面です。',
    '秦 こころの役割です。',
    '["hm","masks","emotion"]'::jsonb,
    jsonb_build_object('表示名', '秦 こころ', '肩書き', '感情豊かなポーカーフェイス', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'doremy',
    'ドレミー・スイート',
    '夢の支配者',
    '種族',
    'independent',
    'dream_world',
    'dream_world',
    'ドレミー・スイートに関する基本人物紹介です。',
    'ドレミー・スイートを配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    'ドレミー・スイートの価値観や見方を整理した文面です。',
    'ドレミー・スイートの役割です。',
    '["lolk","dream","guide"]'::jsonb,
    jsonb_build_object('表示名', 'ドレミー・スイート', '肩書き', '夢の支配者', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'aunn',
    '高麗野 あうん',
    '神社を守る狛犬',
    '種族',
    'hakurei',
    'hakurei_shrine',
    'hakurei_shrine',
    '高麗野 あうんに関する基本人物紹介です。',
    '高麗野 あうんを配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '高麗野 あうんの価値観や見方を整理した文面です。',
    '高麗野 あうんの役割です。',
    '["hsifs","shrine","guardian"]'::jsonb,
    jsonb_build_object('表示名', '高麗野 あうん', '肩書き', '神社を守る狛犬', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'eternity',
    'エタニティラルバ',
    '真夏の蝶の妖精',
    '種族',
    'independent',
    'hakurei_shrine',
    'human_village',
    'エタニティラルバに関する基本人物紹介です。',
    'エタニティラルバを配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    'エタニティラルバの価値観や見方を整理した文面です。',
    'エタニティラルバの役割です。',
    '["hsifs","summer","fairy"]'::jsonb,
    jsonb_build_object('表示名', 'エタニティラルバ', '肩書き', '真夏の蝶の妖精', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'nemuno',
    '坂田 ネムノ',
    '近代の山姥',
    '妖怪',
    'independent',
    'youkai_mountain_foot',
    'youkai_mountain_foot',
    '坂田 ネムノに関する基本人物紹介です。',
    '坂田 ネムノを配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '坂田 ネムノの価値観や見方を整理した文面です。',
    '坂田 ネムノの役割です。',
    '["hsifs","mountain","local"]'::jsonb,
    jsonb_build_object('表示名', '坂田 ネムノ', '肩書き', '近代の山姥', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
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
  (
    'gensokyo_main',
    'komachi',
    'eiki',
    'subordinate_judge',
    '小野塚 小町と四季映姫・ヤマザナドゥのあいだにある関係を示す関係データです。',
    0.86,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'eiki',
    'komachi',
    'supervisory_frustration',
    '四季映姫・ヤマザナドゥと小野塚 小町のあいだにある関係を示す関係データです。',
    0.86,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'iku',
    'tenshi',
    'courteous_warning',
    '永江 衣玖と比那名居 天子のあいだにある関係を示す関係データです。',
    0.63,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'tenshi',
    'reimu',
    'incident_target',
    '比那名居 天子と博麗 霊夢のあいだにある関係を示す関係データです。',
    0.66,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'kokoro',
    'mamizou',
    'emotion_guidance',
    '秦 こころと二ッ岩 マミゾウのあいだにある関係を示す関係データです。',
    0.55,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'doremy',
    'sagume',
    'dream_lunar_overlap',
    'ドレミー・スイートと稀神 サグメのあいだにある関係を示す関係データです。',
    0.49,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'aunn',
    'reimu',
    'local_guardianship',
    '高麗野 あうんと博麗 霊夢のあいだにある関係を示す関係データです。',
    0.78,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'eternity',
    'lily_white',
    'seasonal_affinity',
    'エタニティラルバとリリーホワイトのあいだにある関係を示す関係データです。',
    0.39,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'nemuno',
    'aya',
    'mountain_distance',
    '坂田 ネムノと射命丸 文のあいだにある関係を示す関係データです。',
    0.31,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'yuuka',
    'medicine',
    'flower_field_affinity',
    '風見 幽香とメディスン・メランコリーのあいだにある関係を示す関係データです。',
    0.42,
    '{}'::jsonb
  )
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
    'lore_muenzuka_judgment',
    'location_trait',
    '幻想郷設定項目',
    '土地ごとの性質や役割を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'location_trait', '説明', '日本語表示向けに整理した説明データです。'),
    '["pofv","border","judgment"]'::jsonb,
    79
  ),
  (
    'gensokyo_main',
    'lore_heaven_detachment',
    'location_trait',
    '幻想郷設定項目',
    '土地ごとの性質や役割を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'location_trait', '説明', '日本語表示向けに整理した説明データです。'),
    '["swr","heaven","detachment"]'::jsonb,
    80
  ),
  (
    'gensokyo_main',
    'lore_kokoro_public_affect',
    'character_role',
    '幻想郷設定項目',
    '人物の立ち位置や役割を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_role', '説明', '日本語表示向けに整理した説明データです。'),
    '["hm","emotion","masks"]'::jsonb,
    75
  ),
  (
    'gensokyo_main',
    'lore_dream_world_mediator',
    'location_trait',
    '幻想郷設定項目',
    '土地ごとの性質や役割を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'location_trait', '説明', '日本語表示向けに整理した説明データです。'),
    '["dream","structure"]'::jsonb,
    77
  ),
  (
    'gensokyo_main',
    'lore_aunn_shrine_everyday',
    'character_role',
    '幻想郷設定項目',
    '人物の立ち位置や役割を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_role', '説明', '日本語表示向けに整理した説明データです。'),
    '["aunn","shrine"]'::jsonb,
    72
  ),
  (
    'gensokyo_main',
    'lore_nameless_hill_danger',
    'location_trait',
    '幻想郷設定項目',
    '土地ごとの性質や役割を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'location_trait', '説明', '日本語表示向けに整理した説明データです。'),
    '["flowers","poison","beauty"]'::jsonb,
    74
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
    'claim_komachi_border_worker',
    'gensokyo_main',
    'character',
    'komachi',
    'role',
    '小野塚 小町に関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '小野塚 小町', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_poFV',
    'official',
    78,
    '["komachi","pofv","border"]'::jsonb
  ),
  (
    'claim_eiki_judge',
    'gensokyo_main',
    'character',
    'eiki',
    'role',
    '四季映姫・ヤマザナドゥに関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '四季映姫・ヤマザナドゥ', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_poFV',
    'official',
    84,
    '["eiki","pofv","judgment"]'::jsonb
  ),
  (
    'claim_medicine_poison_actor',
    'gensokyo_main',
    'character',
    'medicine',
    'role',
    'メディスン・メランコリーに関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', 'メディスン・メランコリー', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_poFV',
    'official',
    72,
    '["medicine","pofv","poison"]'::jsonb
  ),
  (
    'claim_yuuka_dangerous_beauty',
    'gensokyo_main',
    'character',
    'yuuka',
    'role',
    '風見 幽香に関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '風見 幽香', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_poFV',
    'official',
    86,
    '["yuuka","pofv","flowers"]'::jsonb
  ),
  (
    'claim_iku_messenger',
    'gensokyo_main',
    'character',
    'iku',
    'role',
    '永江 衣玖に関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '永江 衣玖', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_swl',
    'official',
    73,
    '["iku","swr","heaven"]'::jsonb
  ),
  (
    'claim_tenshi_celestial_instigator',
    'gensokyo_main',
    'character',
    'tenshi',
    'role',
    '比那名居 天子に関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '比那名居 天子', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_swl',
    'official',
    81,
    '["tenshi","swr","celestial"]'::jsonb
  ),
  (
    'claim_kokoro_mask_performer',
    'gensokyo_main',
    'character',
    'kokoro',
    'role',
    '秦 こころに関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '秦 こころ', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_hm',
    'official',
    77,
    '["kokoro","hm","masks"]'::jsonb
  ),
  (
    'claim_doremy_dream_guide',
    'gensokyo_main',
    'character',
    'doremy',
    'role',
    'ドレミー・スイートに関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', 'ドレミー・スイート', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_lolk',
    'official',
    79,
    '["doremy","dream","lolk"]'::jsonb
  ),
  (
    'claim_aunn_guardian',
    'gensokyo_main',
    'character',
    'aunn',
    'role',
    '高麗野 あうんに関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '高麗野 あうん', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_hsifs',
    'official',
    74,
    '["aunn","hsifs","shrine"]'::jsonb
  ),
  (
    'claim_eternity_seasonal_actor',
    'gensokyo_main',
    'character',
    'eternity',
    'role',
    'エタニティラルバに関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', 'エタニティラルバ', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_hsifs',
    'official',
    66,
    '["eternity","hsifs","summer"]'::jsonb
  ),
  (
    'claim_nemuno_mountain_local',
    'gensokyo_main',
    'character',
    'nemuno',
    'role',
    '坂田 ネムノに関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '坂田 ネムノ', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_hsifs',
    'official',
    68,
    '["nemuno","hsifs","mountain"]'::jsonb
  ),
  (
    'claim_heaven_profile',
    'gensokyo_main',
    'location',
    'heaven',
    'profile',
    '天界に関する正史設定です。分類は輪郭です。',
    jsonb_build_object('対象', '天界', '分類', '輪郭', '説明', '日本語表示向けに整理した説明データです。'),
    'src_swl',
    'official',
    80,
    '["location","heaven","swr"]'::jsonb
  ),
  (
    'claim_dream_world_profile',
    'gensokyo_main',
    'location',
    'dream_world',
    'profile',
    '夢の世界に関する正史設定です。分類は輪郭です。',
    jsonb_build_object('対象', '夢の世界', '分類', '輪郭', '説明', '日本語表示向けに整理した説明データです。'),
    'src_lolk',
    'official',
    78,
    '["location","dream","lolk"]'::jsonb
  ),
  (
    'claim_nameless_hill_profile',
    'gensokyo_main',
    'location',
    'nameless_hill',
    'profile',
    '無名の丘に関する正史設定です。分類は輪郭です。',
    jsonb_build_object('対象', '無名の丘', '分類', '輪郭', '説明', '日本語表示向けに整理した説明データです。'),
    'src_poFV',
    'official',
    74,
    '["location","flowers","poison"]'::jsonb
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

insert into public.world_locations (
  world_id, id, name, kind, parent_location_id, title, summary, description, tags, default_mood, neighbors, metadata
)
values
  (
    'gensokyo_main',
    'blood_pool_hell',
    '血の池地獄',
    'major_location',
    'former_hell',
    '血の池地獄の地域情報',
    '血の池地獄に関する基本地点情報です。',
    '血の池地獄の特徴や周辺とのつながりを日本語で整理した説明です。',
    '["hell","greed","underworld"]'::jsonb,
    '落ち着いた雰囲気',
    '["former_hell","old_capital"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'sanzu_river',
    '三途の川',
    'major_location',
    null,
    '三途の川の地域情報',
    '三途の川に関する基本地点情報です。',
    '三途の川の特徴や周辺とのつながりを日本語で整理した説明です。',
    '["river","crossing","afterlife"]'::jsonb,
    '落ち着いた雰囲気',
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

insert into public.world_characters (
  world_id, id, name, title, species, faction_id, home_location_id, default_location_id, public_summary, private_notes, speech_style, worldview, role_in_gensokyo, tags, profile
)
values
  (
    'gensokyo_main',
    'suika',
    '伊吹 萃香',
    '伊吹の萃香',
    '種族',
    'independent',
    'former_hell',
    'hakurei_shrine',
    '伊吹 萃香に関する基本人物紹介です。',
    '伊吹 萃香を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '伊吹 萃香の価値観や見方を整理した文面です。',
    '伊吹 萃香の役割です。',
    '["oni","feast","underground"]'::jsonb,
    jsonb_build_object('表示名', '伊吹 萃香', '肩書き', '伊吹の萃香', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'yuuma',
    '饕餮 尤魔',
    '強欲な獣の霊',
    '種族',
    'independent',
    'blood_pool_hell',
    'blood_pool_hell',
    '饕餮 尤魔に関する基本人物紹介です。',
    '饕餮 尤魔を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '饕餮 尤魔の価値観や見方を整理した文面です。',
    '饕餮 尤魔の役割です。',
    '["17.5","greed","underworld"]'::jsonb,
    jsonb_build_object('表示名', '饕餮 尤魔', '肩書き', '強欲な獣の霊', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'eika',
    '戎 瓔花',
    '積み石の河原の亡霊',
    '種族',
    'independent',
    'sanzu_river',
    'sanzu_river',
    '戎 瓔花に関する基本人物紹介です。',
    '戎 瓔花を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '戎 瓔花の価値観や見方を整理した文面です。',
    '戎 瓔花の役割です。',
    '["wbawc","sanzu","spirit"]'::jsonb,
    jsonb_build_object('表示名', '戎 瓔花', '肩書き', '積み石の河原の亡霊', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'urumi',
    '牛崎 潤美',
    '水没した沈愁地獄',
    '種族',
    'independent',
    'sanzu_river',
    'sanzu_river',
    '牛崎 潤美に関する基本人物紹介です。',
    '牛崎 潤美を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '牛崎 潤美の価値観や見方を整理した文面です。',
    '牛崎 潤美の役割です。',
    '["wbawc","river","guardian"]'::jsonb,
    jsonb_build_object('表示名', '牛崎 潤美', '肩書き', '水没した沈愁地獄', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'kutaka',
    '庭渡 久侘歌',
    '地獄の関所を守る神',
    '神格',
    'independent',
    'sanzu_river',
    'sanzu_river',
    '庭渡 久侘歌に関する基本人物紹介です。',
    '庭渡 久侘歌を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '庭渡 久侘歌の価値観や見方を整理した文面です。',
    '庭渡 久侘歌の役割です。',
    '["wbawc","checkpoint","goddess"]'::jsonb,
    jsonb_build_object('表示名', '庭渡 久侘歌', '肩書き', '地獄の関所を守る神', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'biten',
    '孫 美天',
    '花果子念報の闘士',
    '種族',
    'independent',
    'youkai_mountain_foot',
    'youkai_mountain_foot',
    '孫 美天に関する基本人物紹介です。',
    '孫 美天を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '孫 美天の価値観や見方を整理した文面です。',
    '孫 美天の役割です。',
    '["19","mountain","fighter"]'::jsonb,
    jsonb_build_object('表示名', '孫 美天', '肩書き', '花果子念報の闘士', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'enoko',
    '三頭 慧ノ子',
    '狼組の頭領',
    '種族',
    'independent',
    'beast_realm',
    'beast_realm',
    '三頭 慧ノ子に関する基本人物紹介です。',
    '三頭 慧ノ子を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '三頭 慧ノ子の価値観や見方を整理した文面です。',
    '三頭 慧ノ子の役割です。',
    '["19","beast_realm","hunt"]'::jsonb,
    jsonb_build_object('表示名', '三頭 慧ノ子', '肩書き', '狼組の頭領', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'chiyari',
    '天火人 ちやり',
    '血の池地獄の案内役',
    '種族',
    'independent',
    'blood_pool_hell',
    'blood_pool_hell',
    '天火人 ちやりに関する基本人物紹介です。',
    '天火人 ちやりを配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '天火人 ちやりの価値観や見方を整理した文面です。',
    '天火人 ちやりの役割です。',
    '["19","underworld","blood_pool"]'::jsonb,
    jsonb_build_object('表示名', '天火人 ちやり', '肩書き', '血の池地獄の案内役', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'hisami',
    '豫母都 日狭美',
    '黄泉へ誘う案内人',
    '種族',
    'independent',
    'beast_realm',
    'beast_realm',
    '豫母都 日狭美に関する基本人物紹介です。',
    '豫母都 日狭美を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '豫母都 日狭美の価値観や見方を整理した文面です。',
    '豫母都 日狭美の役割です。',
    '["19","loyalty","underworld"]'::jsonb,
    jsonb_build_object('表示名', '豫母都 日狭美', '肩書き', '黄泉へ誘う案内人', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'zanmu',
    '日白 残無',
    '無の獄王',
    '種族',
    'independent',
    'beast_realm',
    'beast_realm',
    '日白 残無に関する基本人物紹介です。',
    '日白 残無を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '日白 残無の価値観や見方を整理した文面です。',
    '日白 残無の役割です。',
    '["19","underworld","high_impact"]'::jsonb,
    jsonb_build_object('表示名', '日白 残無', '肩書き', '無の獄王', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
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
  (
    'gensokyo_main',
    'suika',
    'yuuma',
    'underworld_power_overlap',
    '伊吹 萃香と饕餮 尤魔のあいだにある関係を示す関係データです。',
    0.42,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'komachi',
    'eika',
    'crossing_proximity',
    '小野塚 小町と戎 瓔花のあいだにある関係を示す関係データです。',
    0.34,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'kutaka',
    'komachi',
    'checkpoint_crossing_overlap',
    '庭渡 久侘歌と小野塚 小町のあいだにある関係を示す関係データです。',
    0.48,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'yachie',
    'enoko',
    'factional_use',
    '吉弔 八千慧と三頭 慧ノ子のあいだにある関係を示す関係データです。',
    0.45,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'chiyari',
    'yuuma',
    'underworld_alignment',
    '天火人 ちやりと饕餮 尤魔のあいだにある関係を示す関係データです。',
    0.57,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'hisami',
    'zanmu',
    'loyal_retainer',
    '豫母都 日狭美と日白 残無のあいだにある関係を示す関係データです。',
    0.73,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'zanmu',
    'yachie',
    'higher_order_pressure',
    '日白 残無と吉弔 八千慧のあいだにある関係を示す関係データです。',
    0.58,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'biten',
    'momiji',
    'mountain_patrol_friction',
    '孫 美天と犬走 椛のあいだにある関係を示す関係データです。',
    0.39,
    '{}'::jsonb
  )
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
    'lore_blood_pool_greed',
    'location_trait',
    '幻想郷設定項目',
    '土地ごとの性質や役割を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'location_trait', '説明', '日本語表示向けに整理した説明データです。'),
    '["17.5","greed","hell"]'::jsonb,
    80
  ),
  (
    'gensokyo_main',
    'lore_sanzu_crossing',
    'location_trait',
    '幻想郷設定項目',
    '土地ごとの性質や役割を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'location_trait', '説明', '日本語表示向けに整理した説明データです。'),
    '["crossing","afterlife","river"]'::jsonb,
    78
  ),
  (
    'gensokyo_main',
    'lore_recent_underworld_power',
    'world_rule',
    '幻想郷設定項目',
    '幻想郷全体に関わる基本ルールを整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'world_rule', '説明', '日本語表示向けに整理した説明データです。'),
    '["19","17.5","underworld"]'::jsonb,
    82
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
    'claim_suika_old_power',
    'gensokyo_main',
    'character',
    'suika',
    'role',
    '伊吹 萃香に関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '伊吹 萃香', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_swl',
    'official',
    79,
    '["suika","oni","underworld"]'::jsonb
  ),
  (
    'claim_yuuma_greed_power',
    'gensokyo_main',
    'character',
    'yuuma',
    'role',
    '饕餮 尤魔に関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '饕餮 尤魔', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_17_5',
    'official',
    83,
    '["yuuma","17.5","greed"]'::jsonb
  ),
  (
    'claim_eika_fragile_resistance',
    'gensokyo_main',
    'character',
    'eika',
    'role',
    '戎 瓔花に関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '戎 瓔花', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_wbawc',
    'official',
    68,
    '["eika","wbawc","river"]'::jsonb
  ),
  (
    'claim_kutaka_checkpoint_goddess',
    'gensokyo_main',
    'character',
    'kutaka',
    'role',
    '庭渡 久侘歌に関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '庭渡 久侘歌', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_wbawc',
    'official',
    72,
    '["kutaka","wbawc","checkpoint"]'::jsonb
  ),
  (
    'claim_biten_mountain_fighter',
    'gensokyo_main',
    'character',
    'biten',
    'role',
    '孫 美天に関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '孫 美天', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_uDoALG',
    'official',
    69,
    '["biten","19","mountain"]'::jsonb
  ),
  (
    'claim_enoko_pack_order',
    'gensokyo_main',
    'character',
    'enoko',
    'role',
    '三頭 慧ノ子に関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '三頭 慧ノ子', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_uDoALG',
    'official',
    74,
    '["enoko","19","beast_realm"]'::jsonb
  ),
  (
    'claim_chiyari_underworld_operator',
    'gensokyo_main',
    'character',
    'chiyari',
    'role',
    '天火人 ちやりに関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '天火人 ちやり', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_uDoALG',
    'official',
    71,
    '["chiyari","19","underworld"]'::jsonb
  ),
  (
    'claim_hisami_loyal_retainer',
    'gensokyo_main',
    'character',
    'hisami',
    'role',
    '豫母都 日狭美に関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '豫母都 日狭美', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_uDoALG',
    'official',
    70,
    '["hisami","19","loyalty"]'::jsonb
  ),
  (
    'claim_zanmu_structural_actor',
    'gensokyo_main',
    'character',
    'zanmu',
    'role',
    '日白 残無に関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '日白 残無', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_uDoALG',
    'official',
    84,
    '["zanmu","19","high_impact"]'::jsonb
  ),
  (
    'claim_blood_pool_hell_profile',
    'gensokyo_main',
    'location',
    'blood_pool_hell',
    'profile',
    '血の池地獄に関する正史設定です。分類は輪郭です。',
    jsonb_build_object('対象', '血の池地獄', '分類', '輪郭', '説明', '日本語表示向けに整理した説明データです。'),
    'src_17_5',
    'official',
    80,
    '["location","17.5","hell"]'::jsonb
  ),
  (
    'claim_sanzu_river_profile',
    'gensokyo_main',
    'location',
    'sanzu_river',
    'profile',
    '三途の川に関する正史設定です。分類は輪郭です。',
    jsonb_build_object('対象', '三途の川', '分類', '輪郭', '説明', '日本語表示向けに整理した説明データです。'),
    'src_poFV',
    'official',
    81,
    '["location","sanzu","crossing"]'::jsonb
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

insert into public.world_characters (
  world_id, id, name, title, species, faction_id, home_location_id, default_location_id, public_summary, private_notes, speech_style, worldview, role_in_gensokyo, tags, profile
)
values
  (
    'gensokyo_main',
    'wakasagihime',
    'わかさぎ姫',
    '秘境の人魚',
    '種族',
    'independent',
    'misty_lake',
    'misty_lake',
    'わかさぎ姫に関する基本人物紹介です。',
    'わかさぎ姫を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    'わかさぎ姫の価値観や見方を整理した文面です。',
    'わかさぎ姫の役割です。',
    '["ddc","lake","local"]'::jsonb,
    jsonb_build_object('表示名', 'わかさぎ姫', '肩書き', '秘境の人魚', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'sekibanki',
    '赤蛮奇',
    'ろくろ首の怪奇',
    '種族',
    'independent',
    'human_village',
    'human_village',
    '赤蛮奇に関する基本人物紹介です。',
    '赤蛮奇を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '赤蛮奇の価値観や見方を整理した文面です。',
    '赤蛮奇の役割です。',
    '["ddc","village","uncanny"]'::jsonb,
    jsonb_build_object('表示名', '赤蛮奇', '肩書き', 'ろくろ首の怪奇', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'kagerou',
    '今泉 影狼',
    '竹林の狼人',
    '種族',
    'independent',
    'bamboo_forest',
    'bamboo_forest',
    '今泉 影狼に関する基本人物紹介です。',
    '今泉 影狼を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '今泉 影狼の価値観や見方を整理した文面です。',
    '今泉 影狼の役割です。',
    '["ddc","bamboo","werewolf"]'::jsonb,
    jsonb_build_object('表示名', '今泉 影狼', '肩書き', '竹林の狼人', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'benben',
    '九十九 弁々',
    '琵琶の付喪神',
    '種族',
    'independent',
    'human_village',
    'human_village',
    '九十九 弁々に関する基本人物紹介です。',
    '九十九 弁々を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '九十九 弁々の価値観や見方を整理した文面です。',
    '九十九 弁々の役割です。',
    '["ddc","music","tsukumogami"]'::jsonb,
    jsonb_build_object('表示名', '九十九 弁々', '肩書き', '琵琶の付喪神', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'yatsuhashi',
    '九十九 八橋',
    '古びた琴の付喪神',
    '種族',
    'independent',
    'human_village',
    'human_village',
    '九十九 八橋に関する基本人物紹介です。',
    '九十九 八橋を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '九十九 八橋の価値観や見方を整理した文面です。',
    '九十九 八橋の役割です。',
    '["ddc","music","tsukumogami"]'::jsonb,
    jsonb_build_object('表示名', '九十九 八橋', '肩書き', '古びた琴の付喪神', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'seiran',
    '清蘭',
    '浅葱色のイーグルラヴィ',
    '月の兎',
    'lunar_capital',
    'lunar_capital',
    'lunar_capital',
    '清蘭に関する基本人物紹介です。',
    '清蘭を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '清蘭の価値観や見方を整理した文面です。',
    '清蘭の役割です。',
    '["lolk","moon","soldier"]'::jsonb,
    jsonb_build_object('表示名', '清蘭', '肩書き', '浅葱色のイーグルラヴィ', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'ringo',
    '鈴瑚',
    '団子を食べる月の兎',
    '月の兎',
    'lunar_capital',
    'lunar_capital',
    'lunar_capital',
    '鈴瑚に関する基本人物紹介です。',
    '鈴瑚を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '鈴瑚の価値観や見方を整理した文面です。',
    '鈴瑚の役割です。',
    '["lolk","moon","daily_life"]'::jsonb,
    jsonb_build_object('表示名', '鈴瑚', '肩書き', '団子を食べる月の兎', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'mike',
    '豪徳寺 ミケ',
    '招福の白猫',
    '化け猫',
    'independent',
    'human_village',
    'human_village',
    '豪徳寺 ミケに関する基本人物紹介です。',
    '豪徳寺 ミケを配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '豪徳寺 ミケの価値観や見方を整理した文面です。',
    '豪徳寺 ミケの役割です。',
    '["um","luck","trade"]'::jsonb,
    jsonb_build_object('表示名', '豪徳寺 ミケ', '肩書き', '招福の白猫', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
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
  (
    'gensokyo_main',
    'wakasagihime',
    'cirno',
    'lake_proximity',
    'わかさぎ姫とチルノのあいだにある関係を示す関係データです。',
    0.28,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'sekibanki',
    'kosuzu',
    'village_text_unease',
    '赤蛮奇と本居 小鈴のあいだにある関係を示す関係データです。',
    0.24,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'kagerou',
    'tewi',
    'bamboo_overlap',
    '今泉 影狼と因幡 てゐのあいだにある関係を示す関係データです。',
    0.31,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'benben',
    'yatsuhashi',
    'sibling_ensemble',
    '九十九 弁々と九十九 八橋のあいだにある関係を示す関係データです。',
    0.83,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'seiran',
    'ringo',
    'lunar_peer',
    '清蘭と鈴瑚のあいだにある関係を示す関係データです。',
    0.64,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'mike',
    'takane',
    'trade_scale_difference',
    '豪徳寺 ミケと山城 たかねのあいだにある関係を示す関係データです。',
    0.34,
    '{}'::jsonb
  )
on conflict (world_id, source_character_id, target_character_id, relation_type) do update
set summary = excluded.summary,
    strength = excluded.strength,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values (
  'gensokyo_main',
  'lore_supporting_cast_texture',
  'world_rule',
  '幻想郷設定項目',
  '幻想郷全体に関わる基本ルールを整理した設定項目です。',
  jsonb_build_object('対象', '幻想郷', '分類', 'world_rule', '説明', '日本語表示向けに整理した説明データです。'),
  '["supporting_cast","texture"]'::jsonb,
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

insert into public.world_canon_claims (
  id, world_id, subject_type, subject_id, claim_type, summary, details, source_id, confidence, priority, tags
)
values
  (
    'claim_wakasagihime_local_lake',
    'gensokyo_main',
    'character',
    'wakasagihime',
    'role',
    'わかさぎ姫に関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', 'わかさぎ姫', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_ddc',
    'official',
    64,
    '["wakasagihime","ddc","lake"]'::jsonb
  ),
  (
    'claim_sekibanki_village_uncanny',
    'gensokyo_main',
    'character',
    'sekibanki',
    'role',
    '赤蛮奇に関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '赤蛮奇', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_ddc',
    'official',
    67,
    '["sekibanki","ddc","village"]'::jsonb
  ),
  (
    'claim_kagerou_bamboo_night',
    'gensokyo_main',
    'character',
    'kagerou',
    'role',
    '今泉 影狼に関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '今泉 影狼', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_ddc',
    'official',
    66,
    '["kagerou","ddc","bamboo"]'::jsonb
  ),
  (
    'claim_benben_performer',
    'gensokyo_main',
    'character',
    'benben',
    'role',
    '九十九 弁々に関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '九十九 弁々', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_ddc',
    'official',
    65,
    '["benben","ddc","music"]'::jsonb
  ),
  (
    'claim_yatsuhashi_performer',
    'gensokyo_main',
    'character',
    'yatsuhashi',
    'role',
    '九十九 八橋に関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '九十九 八橋', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_ddc',
    'official',
    65,
    '["yatsuhashi","ddc","music"]'::jsonb
  ),
  (
    'claim_seiran_soldier',
    'gensokyo_main',
    'character',
    'seiran',
    'role',
    '清蘭に関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '清蘭', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_lolk',
    'official',
    68,
    '["seiran","lolk","moon"]'::jsonb
  ),
  (
    'claim_ringo_daily_lunar',
    'gensokyo_main',
    'character',
    'ringo',
    'role',
    '鈴瑚に関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '鈴瑚', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_lolk',
    'official',
    66,
    '["ringo","lolk","daily_life"]'::jsonb
  ),
  (
    'claim_mike_trade_luck',
    'gensokyo_main',
    'character',
    'mike',
    'role',
    '豪徳寺 ミケに関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '豪徳寺 ミケ', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_um',
    'official',
    67,
    '["mike","um","luck"]'::jsonb
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

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  (
    'gensokyo_main',
    'lore_glossary_hakurei',
    'institution',
    '幻想郷設定項目',
    '幻想郷の制度や枠組みをまとめた設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'institution', '説明', '日本語表示向けに整理した説明データです。'),
    '["glossary","institution","hakurei"]'::jsonb,
    90
  ),
  (
    'gensokyo_main',
    'lore_glossary_moriya',
    'institution',
    '幻想郷設定項目',
    '幻想郷の制度や枠組みをまとめた設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'institution', '説明', '日本語表示向けに整理した説明データです。'),
    '["glossary","institution","moriya"]'::jsonb,
    84
  ),
  (
    'gensokyo_main',
    'lore_glossary_myouren',
    'institution',
    '幻想郷設定項目',
    '幻想郷の制度や枠組みをまとめた設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'institution', '説明', '日本語表示向けに整理した説明データです。'),
    '["glossary","institution","myouren"]'::jsonb,
    83
  ),
  (
    'gensokyo_main',
    'lore_glossary_eientei',
    'institution',
    '幻想郷設定項目',
    '幻想郷の制度や枠組みをまとめた設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'institution', '説明', '日本語表示向けに整理した説明データです。'),
    '["glossary","institution","eientei"]'::jsonb,
    84
  ),
  (
    'gensokyo_main',
    'lore_glossary_sdm',
    'institution',
    '幻想郷設定項目',
    '幻想郷の制度や枠組みをまとめた設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'institution', '説明', '日本語表示向けに整理した説明データです。'),
    '["glossary","institution","sdm"]'::jsonb,
    85
  ),
  (
    'gensokyo_main',
    'lore_glossary_yakumo',
    'institution',
    '幻想郷設定項目',
    '幻想郷の制度や枠組みをまとめた設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'institution', '説明', '日本語表示向けに整理した説明データです。'),
    '["glossary","institution","yakumo"]'::jsonb,
    80
  ),
  (
    'gensokyo_main',
    'lore_glossary_spell_cards',
    'world_rule',
    '幻想郷設定項目',
    '幻想郷全体に関わる基本ルールを整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'world_rule', '説明', '日本語表示向けに整理した説明データです。'),
    '["glossary","world_rule","spell_cards"]'::jsonb,
    94
  ),
  (
    'gensokyo_main',
    'lore_glossary_incidents',
    'world_rule',
    '幻想郷設定項目',
    '幻想郷全体に関わる基本ルールを整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'world_rule', '説明', '日本語表示向けに整理した説明データです。'),
    '["glossary","world_rule","incidents"]'::jsonb,
    91
  ),
  (
    'gensokyo_main',
    'lore_glossary_boundaries',
    'world_rule',
    '幻想郷設定項目',
    '幻想郷全体に関わる基本ルールを整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'world_rule', '説明', '日本語表示向けに整理した説明データです。'),
    '["glossary","world_rule","boundaries"]'::jsonb,
    88
  ),
  (
    'gensokyo_main',
    'lore_glossary_human_village',
    'institution',
    '幻想郷設定項目',
    '幻想郷の制度や枠組みをまとめた設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'institution', '説明', '日本語表示向けに整理した説明データです。'),
    '["glossary","institution","village"]'::jsonb,
    90
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
    'claim_glossary_hakurei',
    'gensokyo_main',
    'institution',
    'hakurei_shrine',
    'glossary',
    '博麗神社に関する正史設定です。分類は用語です。',
    jsonb_build_object('対象', '博麗神社', '分類', '用語', '説明', '日本語表示向けに整理した説明データです。'),
    'src_sopm',
    'official',
    90,
    '["glossary","hakurei","institution"]'::jsonb
  ),
  (
    'claim_glossary_moriya',
    'gensokyo_main',
    'institution',
    'moriya_shrine',
    'glossary',
    '守矢神社に関する正史設定です。分類は用語です。',
    jsonb_build_object('対象', '守矢神社', '分類', '用語', '説明', '日本語表示向けに整理した説明データです。'),
    'src_mofa',
    'official',
    84,
    '["glossary","moriya","institution"]'::jsonb
  ),
  (
    'claim_glossary_myouren',
    'gensokyo_main',
    'institution',
    'myouren_temple',
    'glossary',
    '命蓮寺に関する正史設定です。分類は用語です。',
    jsonb_build_object('対象', '命蓮寺', '分類', '用語', '説明', '日本語表示向けに整理した説明データです。'),
    'src_ufo',
    'official',
    83,
    '["glossary","myouren","institution"]'::jsonb
  ),
  (
    'claim_glossary_eientei',
    'gensokyo_main',
    'institution',
    'eientei',
    'glossary',
    '永遠亭に関する正史設定です。分類は用語です。',
    jsonb_build_object('対象', '永遠亭', '分類', '用語', '説明', '日本語表示向けに整理した説明データです。'),
    'src_imperishable_night',
    'official',
    85,
    '["glossary","eientei","institution"]'::jsonb
  ),
  (
    'claim_glossary_sdm',
    'gensokyo_main',
    'institution',
    'scarlet_devil_mansion',
    'glossary',
    '紅魔館に関する正史設定です。分類は用語です。',
    jsonb_build_object('対象', '紅魔館', '分類', '用語', '説明', '日本語表示向けに整理した説明データです。'),
    'src_eosd',
    'official',
    86,
    '["glossary","sdm","institution"]'::jsonb
  ),
  (
    'claim_glossary_yakumo',
    'gensokyo_main',
    'institution',
    'yakumo_household',
    'glossary',
    '八雲家に関する正史設定です。分類は用語です。',
    jsonb_build_object('対象', '八雲家', '分類', '用語', '説明', '日本語表示向けに整理した説明データです。'),
    'src_pcb',
    'official',
    80,
    '["glossary","yakumo","institution"]'::jsonb
  ),
  (
    'claim_glossary_spell_cards',
    'gensokyo_main',
    'world',
    'gensokyo_main',
    'glossary',
    '幻想郷に関する正史設定です。分類は用語です。',
    jsonb_build_object('対象', '幻想郷', '分類', '用語', '説明', '日本語表示向けに整理した説明データです。'),
    'src_sopm',
    'official',
    95,
    '["glossary","spell_cards","world_rule"]'::jsonb
  ),
  (
    'claim_glossary_incidents',
    'gensokyo_main',
    'world',
    'gensokyo_main',
    'glossary',
    '幻想郷に関する正史設定です。分類は用語です。',
    jsonb_build_object('対象', '幻想郷', '分類', '用語', '説明', '日本語表示向けに整理した説明データです。'),
    'src_sixty_years',
    'official',
    91,
    '["glossary","incidents","world_rule"]'::jsonb
  ),
  (
    'claim_glossary_boundaries',
    'gensokyo_main',
    'world',
    'gensokyo_main',
    'glossary',
    '幻想郷に関する正史設定です。分類は用語です。',
    jsonb_build_object('対象', '幻想郷', '分類', '用語', '説明', '日本語表示向けに整理した説明データです。'),
    'src_pcb',
    'official',
    88,
    '["glossary","boundaries","world_rule"]'::jsonb
  ),
  (
    'claim_glossary_human_village',
    'gensokyo_main',
    'institution',
    'human_village',
    'glossary',
    '人里に関する正史設定です。分類は用語です。',
    jsonb_build_object('対象', '人里', '分類', '用語', '説明', '日本語表示向けに整理した説明データです。'),
    'src_fs',
    'official',
    90,
    '["glossary","village","institution"]'::jsonb
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

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  (
    'gensokyo_main',
    'lore_glossary_shinto',
    'glossary_term',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'glossary_term', '説明', '日本語表示向けに整理した説明データです。'),
    '["glossary","religion","shinto"]'::jsonb,
    80
  ),
  (
    'gensokyo_main',
    'lore_glossary_buddhism',
    'glossary_term',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'glossary_term', '説明', '日本語表示向けに整理した説明データです。'),
    '["glossary","religion","buddhism"]'::jsonb,
    79
  ),
  (
    'gensokyo_main',
    'lore_glossary_taoism',
    'glossary_term',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'glossary_term', '説明', '日本語表示向けに整理した説明データです。'),
    '["glossary","religion","taoism"]'::jsonb,
    78
  ),
  (
    'gensokyo_main',
    'lore_glossary_lunarians',
    'glossary_term',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'glossary_term', '説明', '日本語表示向けに整理した説明データです。'),
    '["glossary","moon","lunarian"]'::jsonb,
    83
  ),
  (
    'gensokyo_main',
    'lore_glossary_tengu',
    'glossary_term',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'glossary_term', '説明', '日本語表示向けに整理した説明データです。'),
    '["glossary","tengu","media"]'::jsonb,
    76
  ),
  (
    'gensokyo_main',
    'lore_glossary_kappa',
    'glossary_term',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'glossary_term', '説明', '日本語表示向けに整理した説明データです。'),
    '["glossary","kappa","engineering"]'::jsonb,
    76
  ),
  (
    'gensokyo_main',
    'lore_glossary_tsukumogami',
    'glossary_term',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'glossary_term', '説明', '日本語表示向けに整理した説明データです。'),
    '["glossary","tsukumogami","objects"]'::jsonb,
    74
  ),
  (
    'gensokyo_main',
    'lore_glossary_urban_legends',
    'glossary_term',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'glossary_term', '説明', '日本語表示向けに整理した説明データです。'),
    '["glossary","urban_legends","outside_world"]'::jsonb,
    77
  ),
  (
    'gensokyo_main',
    'lore_glossary_beast_realm',
    'glossary_term',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'glossary_term', '説明', '日本語表示向けに整理した説明データです。'),
    '["glossary","beast_realm","power"]'::jsonb,
    80
  ),
  (
    'gensokyo_main',
    'lore_glossary_dream_world',
    'glossary_term',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'glossary_term', '説明', '日本語表示向けに整理した説明データです。'),
    '["glossary","dream","symbolic"]'::jsonb,
    78
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
    'claim_glossary_shinto',
    'gensokyo_main',
    'term',
    'shinto',
    'glossary',
    '神道に関する正史設定です。分類は用語です。',
    jsonb_build_object('対象', '神道', '分類', '用語', '説明', '日本語表示向けに整理した説明データです。'),
    'src_hm',
    'official',
    79,
    '["glossary","shinto","religion"]'::jsonb
  ),
  (
    'claim_glossary_buddhism',
    'gensokyo_main',
    'term',
    'buddhism',
    'glossary',
    '仏教に関する正史設定です。分類は用語です。',
    jsonb_build_object('対象', '仏教', '分類', '用語', '説明', '日本語表示向けに整理した説明データです。'),
    'src_hm',
    'official',
    79,
    '["glossary","buddhism","religion"]'::jsonb
  ),
  (
    'claim_glossary_taoism',
    'gensokyo_main',
    'term',
    'taoism',
    'glossary',
    '道教に関する正史設定です。分類は用語です。',
    jsonb_build_object('対象', '道教', '分類', '用語', '説明', '日本語表示向けに整理した説明データです。'),
    'src_hm',
    'official',
    78,
    '["glossary","taoism","religion"]'::jsonb
  ),
  (
    'claim_glossary_lunarians',
    'gensokyo_main',
    'term',
    'lunarians',
    'glossary',
    '月人に関する正史設定です。分類は用語です。',
    jsonb_build_object('対象', '月人', '分類', '用語', '説明', '日本語表示向けに整理した説明データです。'),
    'src_lolk',
    'official',
    84,
    '["glossary","lunarians","moon"]'::jsonb
  ),
  (
    'claim_glossary_tengu',
    'gensokyo_main',
    'term',
    'tengu',
    'glossary',
    '天狗に関する正史設定です。分類は用語です。',
    jsonb_build_object('対象', '天狗', '分類', '用語', '説明', '日本語表示向けに整理した説明データです。'),
    'src_boaFW',
    'official',
    77,
    '["glossary","tengu","media"]'::jsonb
  ),
  (
    'claim_glossary_kappa',
    'gensokyo_main',
    'term',
    'kappa',
    'glossary',
    '河童に関する正史設定です。分類は用語です。',
    jsonb_build_object('対象', '河童', '分類', '用語', '説明', '日本語表示向けに整理した説明データです。'),
    'src_mofa',
    'official',
    77,
    '["glossary","kappa","engineering"]'::jsonb
  ),
  (
    'claim_glossary_tsukumogami',
    'gensokyo_main',
    'term',
    'tsukumogami',
    'glossary',
    '付喪神に関する正史設定です。分類は用語です。',
    jsonb_build_object('対象', '付喪神', '分類', '用語', '説明', '日本語表示向けに整理した説明データです。'),
    'src_ddc',
    'official',
    75,
    '["glossary","tsukumogami","objects"]'::jsonb
  ),
  (
    'claim_glossary_urban_legends',
    'gensokyo_main',
    'term',
    'urban_legends',
    'glossary',
    '都市伝説に関する正史設定です。分類は用語です。',
    jsonb_build_object('対象', '都市伝説', '分類', '用語', '説明', '日本語表示向けに整理した説明データです。'),
    'src_ulil',
    'official',
    78,
    '["glossary","urban_legends","rumor"]'::jsonb
  ),
  (
    'claim_glossary_beast_realm',
    'gensokyo_main',
    'term',
    'beast_realm',
    'glossary',
    '畜生界に関する正史設定です。分類は用語です。',
    jsonb_build_object('対象', '畜生界', '分類', '用語', '説明', '日本語表示向けに整理した説明データです。'),
    'src_wbawc',
    'official',
    81,
    '["glossary","beast_realm","power"]'::jsonb
  ),
  (
    'claim_glossary_dream_world',
    'gensokyo_main',
    'term',
    'dream_world',
    'glossary',
    '夢の世界に関する正史設定です。分類は用語です。',
    jsonb_build_object('対象', '夢の世界', '分類', '用語', '説明', '日本語表示向けに整理した説明データです。'),
    'src_lolk',
    'official',
    79,
    '["glossary","dream_world","dream"]'::jsonb
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

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  (
    'gensokyo_main',
    'lore_ability_reimu',
    'character_ability',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_ability', '説明', '日本語表示向けに整理した説明データです。'),
    '["ability","reimu"]'::jsonb,
    88
  ),
  (
    'gensokyo_main',
    'lore_ability_marisa',
    'character_ability',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_ability', '説明', '日本語表示向けに整理した説明データです。'),
    '["ability","marisa"]'::jsonb,
    87
  ),
  (
    'gensokyo_main',
    'lore_ability_sakuya',
    'character_ability',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_ability', '説明', '日本語表示向けに整理した説明データです。'),
    '["ability","sakuya"]'::jsonb,
    84
  ),
  (
    'gensokyo_main',
    'lore_ability_yukari',
    'character_ability',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_ability', '説明', '日本語表示向けに整理した説明データです。'),
    '["ability","yukari"]'::jsonb,
    89
  ),
  (
    'gensokyo_main',
    'lore_ability_eirin',
    'character_ability',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_ability', '説明', '日本語表示向けに整理した説明データです。'),
    '["ability","eirin"]'::jsonb,
    86
  ),
  (
    'gensokyo_main',
    'lore_ability_aya',
    'character_ability',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_ability', '説明', '日本語表示向けに整理した説明データです。'),
    '["ability","aya"]'::jsonb,
    82
  ),
  (
    'gensokyo_main',
    'lore_ability_satori',
    'character_ability',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_ability', '説明', '日本語表示向けに整理した説明データです。'),
    '["ability","satori"]'::jsonb,
    83
  ),
  (
    'gensokyo_main',
    'lore_ability_utsuho',
    'character_ability',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_ability', '説明', '日本語表示向けに整理した説明データです。'),
    '["ability","utsuho"]'::jsonb,
    82
  ),
  (
    'gensokyo_main',
    'lore_ability_byakuren',
    'character_ability',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_ability', '説明', '日本語表示向けに整理した説明データです。'),
    '["ability","byakuren"]'::jsonb,
    79
  ),
  (
    'gensokyo_main',
    'lore_ability_miko',
    'character_ability',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_ability', '説明', '日本語表示向けに整理した説明データです。'),
    '["ability","miko"]'::jsonb,
    81
  ),
  (
    'gensokyo_main',
    'lore_ability_seija',
    'character_ability',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_ability', '説明', '日本語表示向けに整理した説明データです。'),
    '["ability","seija"]'::jsonb,
    78
  ),
  (
    'gensokyo_main',
    'lore_ability_shinmyoumaru',
    'character_ability',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_ability', '説明', '日本語表示向けに整理した説明データです。'),
    '["ability","shinmyoumaru"]'::jsonb,
    76
  ),
  (
    'gensokyo_main',
    'lore_ability_junko',
    'character_ability',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_ability', '説明', '日本語表示向けに整理した説明データです。'),
    '["ability","junko"]'::jsonb,
    86
  ),
  (
    'gensokyo_main',
    'lore_ability_okina',
    'character_ability',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_ability', '説明', '日本語表示向けに整理した説明データです。'),
    '["ability","okina"]'::jsonb,
    84
  ),
  (
    'gensokyo_main',
    'lore_ability_keiki',
    'character_ability',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_ability', '説明', '日本語表示向けに整理した説明データです。'),
    '["ability","keiki"]'::jsonb,
    78
  ),
  (
    'gensokyo_main',
    'lore_ability_chimata',
    'character_ability',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_ability', '説明', '日本語表示向けに整理した説明データです。'),
    '["ability","chimata"]'::jsonb,
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
    'claim_ability_reimu',
    'gensokyo_main',
    'character',
    'reimu',
    'ability',
    '博麗 霊夢に関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '博麗 霊夢', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_sopm',
    'official',
    90,
    '["ability","reimu"]'::jsonb
  ),
  (
    'claim_ability_marisa',
    'gensokyo_main',
    'character',
    'marisa',
    'ability',
    '霧雨 魔理沙に関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '霧雨 魔理沙', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_grimoire_marisa',
    'official',
    88,
    '["ability","marisa"]'::jsonb
  ),
  (
    'claim_ability_sakuya',
    'gensokyo_main',
    'character',
    'sakuya',
    'ability',
    '十六夜 咲夜に関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '十六夜 咲夜', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_eosd',
    'official',
    85,
    '["ability","sakuya"]'::jsonb
  ),
  (
    'claim_ability_yukari',
    'gensokyo_main',
    'character',
    'yukari',
    'ability',
    '八雲 紫に関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '八雲 紫', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_pcb',
    'official',
    90,
    '["ability","yukari"]'::jsonb
  ),
  (
    'claim_ability_eirin',
    'gensokyo_main',
    'character',
    'eirin',
    'ability',
    '八意 永琳に関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '八意 永琳', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_imperishable_night',
    'official',
    87,
    '["ability","eirin"]'::jsonb
  ),
  (
    'claim_ability_aya',
    'gensokyo_main',
    'character',
    'aya',
    'ability',
    '射命丸 文に関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '射命丸 文', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_boaFW',
    'official',
    83,
    '["ability","aya"]'::jsonb
  ),
  (
    'claim_ability_satori',
    'gensokyo_main',
    'character',
    'satori',
    'ability',
    '古明地 さとりに関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '古明地 さとり', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_subterranean_animism',
    'official',
    84,
    '["ability","satori"]'::jsonb
  ),
  (
    'claim_ability_utsuho',
    'gensokyo_main',
    'character',
    'utsuho',
    'ability',
    '霊烏路 空に関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '霊烏路 空', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_subterranean_animism',
    'official',
    84,
    '["ability","utsuho"]'::jsonb
  ),
  (
    'claim_ability_byakuren',
    'gensokyo_main',
    'character',
    'byakuren',
    'ability',
    '聖 白蓮に関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '聖 白蓮', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_ufo',
    'official',
    80,
    '["ability","byakuren"]'::jsonb
  ),
  (
    'claim_ability_miko',
    'gensokyo_main',
    'character',
    'miko',
    'ability',
    '豊聡耳 神子に関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '豊聡耳 神子', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_td',
    'official',
    82,
    '["ability","miko"]'::jsonb
  ),
  (
    'claim_ability_seija',
    'gensokyo_main',
    'character',
    'seija',
    'ability',
    '鬼人 正邪に関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '鬼人 正邪', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_ddc',
    'official',
    79,
    '["ability","seija"]'::jsonb
  ),
  (
    'claim_ability_shinmyoumaru',
    'gensokyo_main',
    'character',
    'shinmyoumaru',
    'ability',
    '少名 針妙丸に関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '少名 針妙丸', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_ddc',
    'official',
    77,
    '["ability","shinmyoumaru"]'::jsonb
  ),
  (
    'claim_ability_junko',
    'gensokyo_main',
    'character',
    'junko',
    'ability',
    '純狐に関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '純狐', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_lolk',
    'official',
    87,
    '["ability","junko"]'::jsonb
  ),
  (
    'claim_ability_okina',
    'gensokyo_main',
    'character',
    'okina',
    'ability',
    '摩多羅 隠岐奈に関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '摩多羅 隠岐奈', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_hsifs',
    'official',
    85,
    '["ability","okina"]'::jsonb
  ),
  (
    'claim_ability_keiki',
    'gensokyo_main',
    'character',
    'keiki',
    'ability',
    '埴安神 袿姫に関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '埴安神 袿姫', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_wbawc',
    'official',
    79,
    '["ability","keiki"]'::jsonb
  ),
  (
    'claim_ability_chimata',
    'gensokyo_main',
    'character',
    'chimata',
    'ability',
    '天弓 千亦に関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '天弓 千亦', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_um',
    'official',
    78,
    '["ability","chimata"]'::jsonb
  ),
  (
    'claim_title_reimu',
    'gensokyo_main',
    'character',
    'reimu',
    'epithet',
    '博麗 霊夢に関する正史設定です。分類は設定です。',
    jsonb_build_object('対象', '博麗 霊夢', '分類', '設定', '説明', '日本語表示向けに整理した説明データです。'),
    'src_sopm',
    'official',
    88,
    '["title","reimu"]'::jsonb
  ),
  (
    'claim_title_marisa',
    'gensokyo_main',
    'character',
    'marisa',
    'epithet',
    '霧雨 魔理沙に関する正史設定です。分類は設定です。',
    jsonb_build_object('対象', '霧雨 魔理沙', '分類', '設定', '説明', '日本語表示向けに整理した説明データです。'),
    'src_grimoire_marisa',
    'official',
    85,
    '["title","marisa"]'::jsonb
  ),
  (
    'claim_title_yukari',
    'gensokyo_main',
    'character',
    'yukari',
    'epithet',
    '八雲 紫に関する正史設定です。分類は設定です。',
    jsonb_build_object('対象', '八雲 紫', '分類', '設定', '説明', '日本語表示向けに整理した説明データです。'),
    'src_pcb',
    'official',
    87,
    '["title","yukari"]'::jsonb
  ),
  (
    'claim_title_miko',
    'gensokyo_main',
    'character',
    'miko',
    'epithet',
    '豊聡耳 神子に関する正史設定です。分類は設定です。',
    jsonb_build_object('対象', '豊聡耳 神子', '分類', '設定', '説明', '日本語表示向けに整理した説明データです。'),
    'src_td',
    'official',
    81,
    '["title","miko"]'::jsonb
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

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  (
    'gensokyo_main',
    'lore_ability_remilia',
    'character_ability',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_ability', '説明', '日本語表示向けに整理した説明データです。'),
    '["ability","remilia"]'::jsonb,
    82
  ),
  (
    'gensokyo_main',
    'lore_ability_patchouli',
    'character_ability',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_ability', '説明', '日本語表示向けに整理した説明データです。'),
    '["ability","patchouli"]'::jsonb,
    80
  ),
  (
    'gensokyo_main',
    'lore_ability_alice',
    'character_ability',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_ability', '説明', '日本語表示向けに整理した説明データです。'),
    '["ability","alice"]'::jsonb,
    78
  ),
  (
    'gensokyo_main',
    'lore_ability_youmu',
    'character_ability',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_ability', '説明', '日本語表示向けに整理した説明データです。'),
    '["ability","youmu"]'::jsonb,
    79
  ),
  (
    'gensokyo_main',
    'lore_ability_yuyuko',
    'character_ability',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_ability', '説明', '日本語表示向けに整理した説明データです。'),
    '["ability","yuyuko"]'::jsonb,
    79
  ),
  (
    'gensokyo_main',
    'lore_ability_mokou',
    'character_ability',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_ability', '説明', '日本語表示向けに整理した説明データです。'),
    '["ability","mokou"]'::jsonb,
    78
  ),
  (
    'gensokyo_main',
    'lore_ability_kaguya',
    'character_ability',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_ability', '説明', '日本語表示向けに整理した説明データです。'),
    '["ability","kaguya"]'::jsonb,
    77
  ),
  (
    'gensokyo_main',
    'lore_ability_kanako',
    'character_ability',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_ability', '説明', '日本語表示向けに整理した説明データです。'),
    '["ability","kanako"]'::jsonb,
    79
  ),
  (
    'gensokyo_main',
    'lore_ability_suwako',
    'character_ability',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_ability', '説明', '日本語表示向けに整理した説明データです。'),
    '["ability","suwako"]'::jsonb,
    76
  ),
  (
    'gensokyo_main',
    'lore_ability_mamizou',
    'character_ability',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_ability', '説明', '日本語表示向けに整理した説明データです。'),
    '["ability","mamizou"]'::jsonb,
    77
  ),
  (
    'gensokyo_main',
    'lore_ability_raiko',
    'character_ability',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_ability', '説明', '日本語表示向けに整理した説明データです。'),
    '["ability","raiko"]'::jsonb,
    72
  ),
  (
    'gensokyo_main',
    'lore_ability_sagume',
    'character_ability',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_ability', '説明', '日本語表示向けに整理した説明データです。'),
    '["ability","sagume"]'::jsonb,
    82
  ),
  (
    'gensokyo_main',
    'lore_ability_clownpiece',
    'character_ability',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_ability', '説明', '日本語表示向けに整理した説明データです。'),
    '["ability","clownpiece"]'::jsonb,
    76
  ),
  (
    'gensokyo_main',
    'lore_ability_yachie',
    'character_ability',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_ability', '説明', '日本語表示向けに整理した説明データです。'),
    '["ability","yachie"]'::jsonb,
    78
  ),
  (
    'gensokyo_main',
    'lore_ability_takane',
    'character_ability',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_ability', '説明', '日本語表示向けに整理した説明データです。'),
    '["ability","takane"]'::jsonb,
    74
  ),
  (
    'gensokyo_main',
    'lore_ability_sumireko',
    'character_ability',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_ability', '説明', '日本語表示向けに整理した説明データです。'),
    '["ability","sumireko"]'::jsonb,
    75
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
    'claim_ability_remilia',
    'gensokyo_main',
    'character',
    'remilia',
    'ability',
    'レミリア・スカーレットに関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', 'レミリア・スカーレット', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_eosd',
    'official',
    83,
    '["ability","remilia"]'::jsonb
  ),
  (
    'claim_ability_patchouli',
    'gensokyo_main',
    'character',
    'patchouli',
    'ability',
    'パチュリー・ノーレッジに関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', 'パチュリー・ノーレッジ', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_eosd',
    'official',
    81,
    '["ability","patchouli"]'::jsonb
  ),
  (
    'claim_ability_alice',
    'gensokyo_main',
    'character',
    'alice',
    'ability',
    'アリス・マーガトロイドに関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', 'アリス・マーガトロイド', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_pcb',
    'official',
    79,
    '["ability","alice"]'::jsonb
  ),
  (
    'claim_ability_youmu',
    'gensokyo_main',
    'character',
    'youmu',
    'ability',
    '魂魄 妖夢に関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '魂魄 妖夢', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_pcb',
    'official',
    80,
    '["ability","youmu"]'::jsonb
  ),
  (
    'claim_ability_yuyuko',
    'gensokyo_main',
    'character',
    'yuyuko',
    'ability',
    '西行寺 幽々子に関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '西行寺 幽々子', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_pcb',
    'official',
    80,
    '["ability","yuyuko"]'::jsonb
  ),
  (
    'claim_ability_mokou',
    'gensokyo_main',
    'character',
    'mokou',
    'ability',
    '藤原 妹紅に関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '藤原 妹紅', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_imperishable_night',
    'official',
    79,
    '["ability","mokou"]'::jsonb
  ),
  (
    'claim_ability_kaguya',
    'gensokyo_main',
    'character',
    'kaguya',
    'ability',
    '蓬莱山 輝夜に関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '蓬莱山 輝夜', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_imperishable_night',
    'official',
    78,
    '["ability","kaguya"]'::jsonb
  ),
  (
    'claim_ability_kanako',
    'gensokyo_main',
    'character',
    'kanako',
    'ability',
    '八坂 神奈子に関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '八坂 神奈子', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_mofa',
    'official',
    80,
    '["ability","kanako"]'::jsonb
  ),
  (
    'claim_ability_suwako',
    'gensokyo_main',
    'character',
    'suwako',
    'ability',
    '洩矢 諏訪子に関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '洩矢 諏訪子', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_mofa',
    'official',
    77,
    '["ability","suwako"]'::jsonb
  ),
  (
    'claim_ability_mamizou',
    'gensokyo_main',
    'character',
    'mamizou',
    'ability',
    '二ッ岩 マミゾウに関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '二ッ岩 マミゾウ', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_td',
    'official',
    78,
    '["ability","mamizou"]'::jsonb
  ),
  (
    'claim_ability_raiko',
    'gensokyo_main',
    'character',
    'raiko',
    'ability',
    '堀川 雷鼓に関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '堀川 雷鼓', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_ddc',
    'official',
    73,
    '["ability","raiko"]'::jsonb
  ),
  (
    'claim_ability_sagume',
    'gensokyo_main',
    'character',
    'sagume',
    'ability',
    '稀神 サグメに関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '稀神 サグメ', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_lolk',
    'official',
    83,
    '["ability","sagume"]'::jsonb
  ),
  (
    'claim_ability_clownpiece',
    'gensokyo_main',
    'character',
    'clownpiece',
    'ability',
    'クラウンピースに関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', 'クラウンピース', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_lolk',
    'official',
    77,
    '["ability","clownpiece"]'::jsonb
  ),
  (
    'claim_ability_yachie',
    'gensokyo_main',
    'character',
    'yachie',
    'ability',
    '吉弔 八千慧に関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '吉弔 八千慧', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_wbawc',
    'official',
    79,
    '["ability","yachie"]'::jsonb
  ),
  (
    'claim_ability_takane',
    'gensokyo_main',
    'character',
    'takane',
    'ability',
    '山城 たかねに関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '山城 たかね', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_um',
    'official',
    75,
    '["ability","takane"]'::jsonb
  ),
  (
    'claim_ability_sumireko',
    'gensokyo_main',
    'character',
    'sumireko',
    'ability',
    '宇佐見 菫子に関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '宇佐見 菫子', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_ulil',
    'official',
    76,
    '["ability","sumireko"]'::jsonb
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

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  (
    'gensokyo_main',
    'lore_ability_nitori',
    'character_ability',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_ability', '説明', '日本語表示向けに整理した説明データです。'),
    '["ability","nitori"]'::jsonb,
    80
  ),
  (
    'gensokyo_main',
    'lore_ability_keine',
    'character_ability',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_ability', '説明', '日本語表示向けに整理した説明データです。'),
    '["ability","keine"]'::jsonb,
    79
  ),
  (
    'gensokyo_main',
    'lore_ability_akyuu',
    'character_ability',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_ability', '説明', '日本語表示向けに整理した説明データです。'),
    '["ability","akyuu"]'::jsonb,
    80
  ),
  (
    'gensokyo_main',
    'lore_ability_kasen',
    'character_ability',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_ability', '説明', '日本語表示向けに整理した説明データです。'),
    '["ability","kasen"]'::jsonb,
    78
  ),
  (
    'gensokyo_main',
    'lore_ability_komachi',
    'character_ability',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_ability', '説明', '日本語表示向けに整理した説明データです。'),
    '["ability","komachi"]'::jsonb,
    76
  ),
  (
    'gensokyo_main',
    'lore_ability_eiki',
    'character_ability',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_ability', '説明', '日本語表示向けに整理した説明データです。'),
    '["ability","eiki"]'::jsonb,
    80
  ),
  (
    'gensokyo_main',
    'lore_ability_tewi',
    'character_ability',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_ability', '説明', '日本語表示向けに整理した説明データです。'),
    '["ability","tewi"]'::jsonb,
    74
  ),
  (
    'gensokyo_main',
    'lore_ability_suika',
    'character_ability',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_ability', '説明', '日本語表示向けに整理した説明データです。'),
    '["ability","suika"]'::jsonb,
    78
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
    'claim_ability_nitori',
    'gensokyo_main',
    'character',
    'nitori',
    'ability',
    '河城 にとりに関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '河城 にとり', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_mofa',
    'official',
    81,
    '["ability","nitori"]'::jsonb
  ),
  (
    'claim_ability_keine',
    'gensokyo_main',
    'character',
    'keine',
    'ability',
    '上白沢 慧音に関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '上白沢 慧音', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_imperishable_night',
    'official',
    80,
    '["ability","keine"]'::jsonb
  ),
  (
    'claim_ability_akyuu',
    'gensokyo_main',
    'character',
    'akyuu',
    'ability',
    '稗田 阿求に関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '稗田 阿求', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_sixty_years',
    'official',
    82,
    '["ability","akyuu"]'::jsonb
  ),
  (
    'claim_ability_kasen',
    'gensokyo_main',
    'character',
    'kasen',
    'ability',
    '茨木 華扇に関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '茨木 華扇', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_wahh',
    'official',
    79,
    '["ability","kasen"]'::jsonb
  ),
  (
    'claim_ability_komachi',
    'gensokyo_main',
    'character',
    'komachi',
    'ability',
    '小野塚 小町に関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '小野塚 小町', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_poFV',
    'official',
    77,
    '["ability","komachi"]'::jsonb
  ),
  (
    'claim_ability_eiki',
    'gensokyo_main',
    'character',
    'eiki',
    'ability',
    '四季映姫・ヤマザナドゥに関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '四季映姫・ヤマザナドゥ', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_poFV',
    'official',
    82,
    '["ability","eiki"]'::jsonb
  ),
  (
    'claim_ability_tewi',
    'gensokyo_main',
    'character',
    'tewi',
    'ability',
    '因幡 てゐに関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '因幡 てゐ', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_imperishable_night',
    'official',
    75,
    '["ability","tewi"]'::jsonb
  ),
  (
    'claim_ability_suika',
    'gensokyo_main',
    'character',
    'suika',
    'ability',
    '伊吹 萃香に関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '伊吹 萃香', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_swl',
    'official',
    79,
    '["ability","suika"]'::jsonb
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
    '博麗 霊夢の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '博麗 霊夢の会話や振る舞いに関する文脈データです。'),
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
    '霧雨 魔理沙の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '霧雨 魔理沙の会話や振る舞いに関する文脈データです。'),
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
    '十六夜 咲夜の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '十六夜 咲夜の会話や振る舞いに関する文脈データです。'),
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
    '八雲 紫の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '八雲 紫の会話や振る舞いに関する文脈データです。'),
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
    '八意 永琳の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '八意 永琳の会話や振る舞いに関する文脈データです。'),
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
    '豊聡耳 神子の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '豊聡耳 神子の会話や振る舞いに関する文脈データです。'),
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
    '宇佐見 菫子の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '宇佐見 菫子の会話や振る舞いに関する文脈データです。'),
    0.88,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

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
    '河城 にとりの会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '河城 にとりの会話や振る舞いに関する文脈データです。'),
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
    '射命丸 文の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '射命丸 文の会話や振る舞いに関する文脈データです。'),
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
    '上白沢 慧音の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '上白沢 慧音の会話や振る舞いに関する文脈データです。'),
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
    '稗田 阿求の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '稗田 阿求の会話や振る舞いに関する文脈データです。'),
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
    '茨木 華扇の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '茨木 華扇の会話や振る舞いに関する文脈データです。'),
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
    '小野塚 小町の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '小野塚 小町の会話や振る舞いに関する文脈データです。'),
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
    '四季映姫・ヤマザナドゥの会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '四季映姫・ヤマザナドゥの会話や振る舞いに関する文脈データです。'),
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
    '因幡 てゐの会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '因幡 てゐの会話や振る舞いに関する文脈データです。'),
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
    '伊吹 萃香の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '伊吹 萃香の会話や振る舞いに関する文脈データです。'),
    0.89,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  (
    'gensokyo_main',
    'lore_glossary_forest_of_magic',
    'location_trait',
    '幻想郷設定項目',
    '土地ごとの性質や役割を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'location_trait', '説明', '日本語表示向けに整理した説明データです。'),
    '["glossary","location","forest_of_magic"]'::jsonb,
    82
  ),
  (
    'gensokyo_main',
    'lore_glossary_misty_lake',
    'location_trait',
    '幻想郷設定項目',
    '土地ごとの性質や役割を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'location_trait', '説明', '日本語表示向けに整理した説明データです。'),
    '["glossary","location","misty_lake"]'::jsonb,
    76
  ),
  (
    'gensokyo_main',
    'lore_glossary_bamboo_forest',
    'location_trait',
    '幻想郷設定項目',
    '土地ごとの性質や役割を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'location_trait', '説明', '日本語表示向けに整理した説明データです。'),
    '["glossary","location","bamboo_forest"]'::jsonb,
    81
  ),
  (
    'gensokyo_main',
    'lore_glossary_netherworld',
    'location_trait',
    '幻想郷設定項目',
    '土地ごとの性質や役割を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'location_trait', '説明', '日本語表示向けに整理した説明データです。'),
    '["glossary","location","netherworld"]'::jsonb,
    80
  ),
  (
    'gensokyo_main',
    'lore_glossary_former_hell',
    'location_trait',
    '幻想郷設定項目',
    '土地ごとの性質や役割を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'location_trait', '説明', '日本語表示向けに整理した説明データです。'),
    '["glossary","location","former_hell"]'::jsonb,
    80
  ),
  (
    'gensokyo_main',
    'lore_glossary_muenzuka',
    'location_trait',
    '幻想郷設定項目',
    '土地ごとの性質や役割を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'location_trait', '説明', '日本語表示向けに整理した説明データです。'),
    '["glossary","location","muenzuka"]'::jsonb,
    79
  ),
  (
    'gensokyo_main',
    'lore_glossary_rainbow_dragon_cave',
    'location_trait',
    '幻想郷設定項目',
    '土地ごとの性質や役割を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'location_trait', '説明', '日本語表示向けに整理した説明データです。'),
    '["glossary","location","rainbow_dragon_cave"]'::jsonb,
    77
  ),
  (
    'gensokyo_main',
    'lore_glossary_chireiden',
    'location_trait',
    '幻想郷設定項目',
    '土地ごとの性質や役割を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'location_trait', '説明', '日本語表示向けに整理した説明データです。'),
    '["glossary","location","chireiden"]'::jsonb,
    79
  ),
  (
    'gensokyo_main',
    'lore_glossary_divine_spirit_mausoleum',
    'location_trait',
    '幻想郷設定項目',
    '土地ごとの性質や役割を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'location_trait', '説明', '日本語表示向けに整理した説明データです。'),
    '["glossary","location","mausoleum"]'::jsonb,
    79
  ),
  (
    'gensokyo_main',
    'lore_glossary_backdoor_realm',
    'location_trait',
    '幻想郷設定項目',
    '土地ごとの性質や役割を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'location_trait', '説明', '日本語表示向けに整理した説明データです。'),
    '["glossary","location","backdoor_realm"]'::jsonb,
    78
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
    'claim_glossary_forest_of_magic',
    'gensokyo_main',
    'location',
    'forest_of_magic',
    'glossary',
    '魔法の森に関する正史設定です。分類は用語です。',
    jsonb_build_object('対象', '魔法の森', '分類', '用語', '説明', '日本語表示向けに整理した説明データです。'),
    'src_pcb',
    'official',
    82,
    '["glossary","forest_of_magic","location"]'::jsonb
  ),
  (
    'claim_glossary_misty_lake',
    'gensokyo_main',
    'location',
    'misty_lake',
    'glossary',
    '霧の湖に関する正史設定です。分類は用語です。',
    jsonb_build_object('対象', '霧の湖', '分類', '用語', '説明', '日本語表示向けに整理した説明データです。'),
    'src_eosd',
    'official',
    76,
    '["glossary","misty_lake","location"]'::jsonb
  ),
  (
    'claim_glossary_bamboo_forest',
    'gensokyo_main',
    'location',
    'bamboo_forest',
    'glossary',
    '迷いの竹林に関する正史設定です。分類は用語です。',
    jsonb_build_object('対象', '迷いの竹林', '分類', '用語', '説明', '日本語表示向けに整理した説明データです。'),
    'src_imperishable_night',
    'official',
    82,
    '["glossary","bamboo_forest","location"]'::jsonb
  ),
  (
    'claim_glossary_netherworld',
    'gensokyo_main',
    'location',
    'netherworld',
    'glossary',
    '冥界に関する正史設定です。分類は用語です。',
    jsonb_build_object('対象', '冥界', '分類', '用語', '説明', '日本語表示向けに整理した説明データです。'),
    'src_pcb',
    'official',
    81,
    '["glossary","netherworld","location"]'::jsonb
  ),
  (
    'claim_glossary_former_hell',
    'gensokyo_main',
    'location',
    'former_hell',
    'glossary',
    '旧地獄に関する正史設定です。分類は用語です。',
    jsonb_build_object('対象', '旧地獄', '分類', '用語', '説明', '日本語表示向けに整理した説明データです。'),
    'src_subterranean_animism',
    'official',
    81,
    '["glossary","former_hell","location"]'::jsonb
  ),
  (
    'claim_glossary_muenzuka',
    'gensokyo_main',
    'location',
    'muenzuka',
    'glossary',
    '無縁塚に関する正史設定です。分類は用語です。',
    jsonb_build_object('対象', '無縁塚', '分類', '用語', '説明', '日本語表示向けに整理した説明データです。'),
    'src_poFV',
    'official',
    80,
    '["glossary","muenzuka","location"]'::jsonb
  ),
  (
    'claim_glossary_rainbow_dragon_cave',
    'gensokyo_main',
    'location',
    'rainbow_dragon_cave',
    'glossary',
    '虹龍洞に関する正史設定です。分類は用語です。',
    jsonb_build_object('対象', '虹龍洞', '分類', '用語', '説明', '日本語表示向けに整理した説明データです。'),
    'src_um',
    'official',
    78,
    '["glossary","rainbow_dragon_cave","location"]'::jsonb
  ),
  (
    'claim_glossary_chireiden',
    'gensokyo_main',
    'location',
    'chireiden',
    'glossary',
    '地霊殿に関する正史設定です。分類は用語です。',
    jsonb_build_object('対象', '地霊殿', '分類', '用語', '説明', '日本語表示向けに整理した説明データです。'),
    'src_subterranean_animism',
    'official',
    80,
    '["glossary","chireiden","location"]'::jsonb
  ),
  (
    'claim_glossary_divine_spirit_mausoleum',
    'gensokyo_main',
    'location',
    'divine_spirit_mausoleum',
    'glossary',
    '神霊廟に関する正史設定です。分類は用語です。',
    jsonb_build_object('対象', '神霊廟', '分類', '用語', '説明', '日本語表示向けに整理した説明データです。'),
    'src_td',
    'official',
    80,
    '["glossary","mausoleum","location"]'::jsonb
  ),
  (
    'claim_glossary_backdoor_realm',
    'gensokyo_main',
    'location',
    'backdoor_realm',
    'glossary',
    '後戸の国に関する正史設定です。分類は用語です。',
    jsonb_build_object('対象', '後戸の国', '分類', '用語', '説明', '日本語表示向けに整理した説明データです。'),
    'src_hsifs',
    'official',
    79,
    '["glossary","backdoor_realm","location"]'::jsonb
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

insert into public.world_chronicle_books (
  id, world_id, title, author_character_id, chronicle_type, era_label, summary, tone, is_public, metadata
)
values
  (
    'chronicle_gensokyo_history',
    'gensokyo_main',
    '幻想郷年代記',
    'keine',
    'history',
    '現代',
    '幻想郷年代記の概要です。',
    '記録調',
    true,
    jsonb_build_object('editorial_style', 'keine_archival')
  ),
  (
    'chronicle_seasonal_incidents',
    'gensokyo_main',
    '季節行事記録集',
    'keine',
    'incident_record',
    '近年',
    '季節行事記録集の概要です。',
    '記録調',
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
    '年代記の章',
    '年代記の章の内容を整理した章説明です。',
    null,
    null,
    '{}'::jsonb
  ),
  (
    'chronicle_gensokyo_history:chapter:principal_actors',
    'chronicle_gensokyo_history',
    'principal_actors',
    2,
    '年代記の章',
    '年代記の章の内容を整理した章説明です。',
    null,
    null,
    '{}'::jsonb
  ),
  (
    'chronicle_seasonal_incidents:chapter:spring_festival',
    'chronicle_seasonal_incidents',
    'spring_festival',
    1,
    '年代記の章',
    '年代記の章の内容を整理した章説明です。',
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
  id, book_id, chapter_id, entry_code, entry_order, entry_type, title, summary, body, subject_type, subject_id, narrator_character_id, event_id, history_id, tags, metadata
)
values
  (
    'chronicle_entry_gensokyo_balance',
    'chronicle_gensokyo_history',
    'chronicle_gensokyo_history:chapter:foundations',
    'gensokyo_balance',
    1,
    'essay',
    '幻想郷に関する年代記',
    '幻想郷に関する年代記の記録です。',
    '幻想郷に関する経緯や位置づけを日本語で整理した本文です。',
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
    '幻想郷に関する年代記',
    '幻想郷に関する年代記の記録です。',
    '幻想郷に関する経緯や位置づけを日本語で整理した本文です。',
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
    '博麗神社春祭りに関する年代記',
    '博麗神社春祭りに関する年代記の記録です。',
    '博麗神社春祭りに関する経緯や位置づけを日本語で整理した本文です。',
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
  (
    'chronicle_entry_gensokyo_balance:src:lore',
    'chronicle_entry_gensokyo_balance',
    'lore_entry',
    'lore_gensokyo_balance',
    '参照資料',
    1.0,
    '年代記の根拠として参照した資料です。'
  ),
  (
    'chronicle_entry_gensokyo_balance:src:claim',
    'chronicle_entry_gensokyo_balance',
    'canon_claim',
    'claim_spell_card_constraint',
    '参照資料',
    0.9,
    '年代記の根拠として参照した資料です。'
  ),
  (
    'chronicle_entry_principal_actors:src:claim:reimu',
    'chronicle_entry_principal_actors',
    'canon_claim',
    'claim_reimu_incident_resolver',
    '参照資料',
    1.0,
    '年代記の根拠として参照した資料です。'
  ),
  (
    'chronicle_entry_principal_actors:src:claim:marisa',
    'chronicle_entry_principal_actors',
    'canon_claim',
    'claim_marisa_incident_actor',
    '参照資料',
    0.9,
    '年代記の根拠として参照した資料です。'
  ),
  (
    'chronicle_entry_spring_festival:src:history:rumor',
    'chronicle_entry_spring_festival',
    'history',
    'story_spring_festival_001:history:opening_rumor',
    '参照資料',
    0.8,
    '年代記の根拠として参照した資料です。'
  ),
  (
    'chronicle_entry_spring_festival:src:history:prep',
    'chronicle_entry_spring_festival',
    'history',
    'story_spring_festival_001:history:preparation_visible',
    '参照資料',
    1.0,
    '年代記の根拠として参照した資料です。'
  )
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
    '博麗 霊夢に関する注記',
    '博麗 霊夢を歴史記録として扱うための補足注記です。',
    '博麗 霊夢に関する記録上の見方や整理方針をまとめた歴史家注記です。',
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
    '博麗神社春祭りに関する注記',
    '博麗神社春祭りを歴史記録として扱うための補足注記です。',
    '博麗神社春祭りに関する記録上の見方や整理方針をまとめた歴史家注記です。',
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
    '博麗 霊夢',
    'character',
    'character',
    'reimu',
    '博麗 霊夢に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_location_hakurei_shrine',
    'gensokyo_main',
    'locations/hakurei-shrine',
    '博麗神社',
    'location',
    'location',
    'hakurei_shrine',
    '博麗神社に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_rule_spell_cards',
    'gensokyo_main',
    'world/spell-card-rules',
    '幻想郷',
    'world_rule',
    'world',
    'gensokyo_main',
    '幻想郷に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_event_spring_festival',
    'gensokyo_main',
    'events/hakurei-spring-festival',
    '博麗神社春祭り',
    'event',
    'event',
    'story_spring_festival_001',
    '博麗神社春祭りに関する幻想郷事典項目です。',
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
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_reimu_incident_resolver","lore_reimu_position"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_location_hakurei_shrine:section:profile',
    'wiki_location_hakurei_shrine',
    'profile',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["lore_hakurei_role"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_rule_spell_cards:section:world_rule',
    'wiki_rule_spell_cards',
    'world_rule',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_spell_card_constraint","lore_spell_card_rules"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_event_spring_festival:section:current_state',
    'wiki_event_spring_festival',
    'current_state',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
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
    '博麗 霊夢の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '博麗 霊夢の会話や振る舞いに関する文脈データです。'),
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
    '射命丸 文の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '射命丸 文の会話や振る舞いに関する文脈データです。'),
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
    '幻想郷の会話文脈を整理したデータです。',
    jsonb_build_object('説明', '幻想郷の会話文脈を整理したデータです。'),
    1.00,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  (
    'gensokyo_main',
    'lore_book_forbidden_scrollery',
    'printwork_pattern',
    '幻想郷設定項目',
    '書籍や媒体に見られる傾向を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'printwork_pattern', '説明', '日本語表示向けに整理した説明データです。'),
    '["printwork","fs","books"]'::jsonb,
    81
  ),
  (
    'gensokyo_main',
    'lore_book_wild_and_horned_hermit',
    'printwork_pattern',
    '幻想郷設定項目',
    '書籍や媒体に見られる傾向を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'printwork_pattern', '説明', '日本語表示向けに整理した説明データです。'),
    '["printwork","wahh","daily_life"]'::jsonb,
    80
  ),
  (
    'gensokyo_main',
    'lore_book_lotus_asia',
    'printwork_pattern',
    '幻想郷設定項目',
    '書籍や媒体に見られる傾向を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'printwork_pattern', '説明', '日本語表示向けに整理した説明データです。'),
    '["printwork","cola","objects"]'::jsonb,
    79
  ),
  (
    'gensokyo_main',
    'lore_book_bunbunmaru_reporting',
    'printwork_pattern',
    '幻想郷設定項目',
    '書籍や媒体に見られる傾向を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'printwork_pattern', '説明', '日本語表示向けに整理した説明データです。'),
    '["printwork","reporting","aya"]'::jsonb,
    78
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
    'claim_book_forbidden_scrollery',
    'gensokyo_main',
    'printwork',
    'forbidden_scrollery',
    'summary',
    '鈴奈庵記録に関する正史設定です。分類は要約です。',
    jsonb_build_object('対象', '鈴奈庵記録', '分類', '要約', '説明', '日本語表示向けに整理した説明データです。'),
    'src_fs',
    'official',
    82,
    '["printwork","fs","summary"]'::jsonb
  ),
  (
    'claim_book_wild_and_horned_hermit',
    'gensokyo_main',
    'printwork',
    'wild_and_horned_hermit',
    'summary',
    '茨歌仙記録に関する正史設定です。分類は要約です。',
    jsonb_build_object('対象', '茨歌仙記録', '分類', '要約', '説明', '日本語表示向けに整理した説明データです。'),
    'src_wahh',
    'official',
    81,
    '["printwork","wahh","summary"]'::jsonb
  ),
  (
    'claim_book_lotus_asia',
    'gensokyo_main',
    'printwork',
    'lotus_asia',
    'summary',
    '香霖堂記録に関する正史設定です。分類は要約です。',
    jsonb_build_object('対象', '香霖堂記録', '分類', '要約', '説明', '日本語表示向けに整理した説明データです。'),
    'src_lotus_asia',
    'official',
    80,
    '["printwork","cola","summary"]'::jsonb
  ),
  (
    'claim_book_bunbunmaru_reporting',
    'gensokyo_main',
    'printwork',
    'bunbunmaru_reporting',
    'summary',
    '文々。新聞報道に関する正史設定です。分類は要約です。',
    jsonb_build_object('対象', '文々。新聞報道', '分類', '要約', '説明', '日本語表示向けに整理した説明データです。'),
    'src_boaFW',
    'official',
    79,
    '["printwork","reporting","summary"]'::jsonb
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

insert into public.world_chronicle_entries (
  id, book_id, chapter_id, entry_code, entry_order, entry_type, title, summary, body, subject_type, subject_id, narrator_character_id, event_id, history_id, tags, metadata
)
values (
  'chronicle_entry_printwork_books',
  'chronicle_gensokyo_history',
  'chronicle_gensokyo_history:chapter:foundations',
  'printwork_patterns',
  2,
  'essay',
  '幻想郷に関する年代記',
  '幻想郷に関する年代記の記録です。',
  '幻想郷に関する経緯や位置づけを日本語で整理した本文です。',
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
  (
    'chronicle_entry_printwork_books:src:fs',
    'chronicle_entry_printwork_books',
    'canon_claim',
    'claim_book_forbidden_scrollery',
    '参照資料',
    0.9,
    '年代記の根拠として参照した資料です。'
  ),
  (
    'chronicle_entry_printwork_books:src:wahh',
    'chronicle_entry_printwork_books',
    'canon_claim',
    'claim_book_wild_and_horned_hermit',
    '参照資料',
    0.9,
    '年代記の根拠として参照した資料です。'
  ),
  (
    'chronicle_entry_printwork_books:src:cola',
    'chronicle_entry_printwork_books',
    'canon_claim',
    'claim_book_lotus_asia',
    '参照資料',
    0.85,
    '年代記の根拠として参照した資料です。'
  ),
  (
    'chronicle_entry_printwork_books:src:boafw',
    'chronicle_entry_printwork_books',
    'canon_claim',
    'claim_book_bunbunmaru_reporting',
    '参照資料',
    0.82,
    '年代記の根拠として参照した資料です。'
  )
on conflict (id) do update
set source_kind = excluded.source_kind,
    source_ref_id = excluded.source_ref_id,
    source_label = excluded.source_label,
    weight = excluded.weight,
    notes = excluded.notes;

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  (
    'gensokyo_main',
    'lore_faction_hakurei',
    'faction_trait',
    '幻想郷設定項目',
    '勢力や集団の性質を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'faction_trait', '説明', '日本語表示向けに整理した説明データです。'),
    '["faction","hakurei","public_balance"]'::jsonb,
    84
  ),
  (
    'gensokyo_main',
    'lore_faction_moriya',
    'faction_trait',
    '幻想郷設定項目',
    '勢力や集団の性質を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'faction_trait', '説明', '日本語表示向けに整理した説明データです。'),
    '["faction","moriya","ambition"]'::jsonb,
    82
  ),
  (
    'gensokyo_main',
    'lore_faction_sdm',
    'faction_trait',
    '幻想郷設定項目',
    '勢力や集団の性質を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'faction_trait', '説明', '日本語表示向けに整理した説明データです。'),
    '["faction","sdm","household"]'::jsonb,
    83
  ),
  (
    'gensokyo_main',
    'lore_faction_eientei',
    'faction_trait',
    '幻想郷設定項目',
    '勢力や集団の性質を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'faction_trait', '説明', '日本語表示向けに整理した説明データです。'),
    '["faction","eientei","expertise"]'::jsonb,
    83
  ),
  (
    'gensokyo_main',
    'lore_faction_tengu',
    'faction_trait',
    '幻想郷設定項目',
    '勢力や集団の性質を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'faction_trait', '説明', '日本語表示向けに整理した説明データです。'),
    '["faction","tengu","media"]'::jsonb,
    79
  ),
  (
    'gensokyo_main',
    'lore_faction_kappa',
    'faction_trait',
    '幻想郷設定項目',
    '勢力や集団の性質を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'faction_trait', '説明', '日本語表示向けに整理した説明データです。'),
    '["faction","kappa","engineering"]'::jsonb,
    79
  ),
  (
    'gensokyo_main',
    'lore_faction_myouren',
    'faction_trait',
    '幻想郷設定項目',
    '勢力や集団の性質を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'faction_trait', '説明', '日本語表示向けに整理した説明データです。'),
    '["faction","myouren","community"]'::jsonb,
    80
  ),
  (
    'gensokyo_main',
    'lore_faction_yakumo',
    'faction_trait',
    '幻想郷設定項目',
    '勢力や集団の性質を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'faction_trait', '説明', '日本語表示向けに整理した説明データです。'),
    '["faction","yakumo","structural"]'::jsonb,
    78
  ),
  (
    'gensokyo_main',
    'lore_social_rumor_network',
    'social_function',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'social_function', '説明', '日本語表示向けに整理した説明データです。'),
    '["social","rumor","network"]'::jsonb,
    86
  ),
  (
    'gensokyo_main',
    'lore_social_festivals',
    'social_function',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'social_function', '説明', '日本語表示向けに整理した説明データです。'),
    '["social","festival","public_life"]'::jsonb,
    85
  ),
  (
    'gensokyo_main',
    'lore_social_teaching',
    'social_function',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'social_function', '説明', '日本語表示向けに整理した説明データです。'),
    '["social","teaching","continuity"]'::jsonb,
    83
  ),
  (
    'gensokyo_main',
    'lore_social_trade',
    'social_function',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'social_function', '説明', '日本語表示向けに整理した説明データです。'),
    '["social","trade","exchange"]'::jsonb,
    82
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
    'claim_faction_hakurei',
    'gensokyo_main',
    'faction',
    'hakurei',
    'glossary',
    '博麗神社側に関する正史設定です。分類は用語です。',
    jsonb_build_object('対象', '博麗神社側', '分類', '用語', '説明', '日本語表示向けに整理した説明データです。'),
    'src_sopm',
    'official',
    84,
    '["faction","hakurei"]'::jsonb
  ),
  (
    'claim_faction_moriya',
    'gensokyo_main',
    'faction',
    'moriya',
    'glossary',
    '守矢神社側に関する正史設定です。分類は用語です。',
    jsonb_build_object('対象', '守矢神社側', '分類', '用語', '説明', '日本語表示向けに整理した説明データです。'),
    'src_mofa',
    'official',
    83,
    '["faction","moriya"]'::jsonb
  ),
  (
    'claim_faction_sdm',
    'gensokyo_main',
    'faction',
    'sdm',
    'glossary',
    '紅魔館勢に関する正史設定です。分類は用語です。',
    jsonb_build_object('対象', '紅魔館勢', '分類', '用語', '説明', '日本語表示向けに整理した説明データです。'),
    'src_eosd',
    'official',
    84,
    '["faction","sdm"]'::jsonb
  ),
  (
    'claim_faction_eientei',
    'gensokyo_main',
    'faction',
    'eientei',
    'glossary',
    '永遠亭に関する正史設定です。分類は用語です。',
    jsonb_build_object('対象', '永遠亭', '分類', '用語', '説明', '日本語表示向けに整理した説明データです。'),
    'src_imperishable_night',
    'official',
    84,
    '["faction","eientei"]'::jsonb
  ),
  (
    'claim_faction_tengu',
    'gensokyo_main',
    'faction',
    'tengu',
    'glossary',
    '天狗に関する正史設定です。分類は用語です。',
    jsonb_build_object('対象', '天狗', '分類', '用語', '説明', '日本語表示向けに整理した説明データです。'),
    'src_boaFW',
    'official',
    80,
    '["faction","tengu"]'::jsonb
  ),
  (
    'claim_faction_kappa',
    'gensokyo_main',
    'faction',
    'kappa',
    'glossary',
    '河童に関する正史設定です。分類は用語です。',
    jsonb_build_object('対象', '河童', '分類', '用語', '説明', '日本語表示向けに整理した説明データです。'),
    'src_mofa',
    'official',
    80,
    '["faction","kappa"]'::jsonb
  ),
  (
    'claim_social_rumor_network',
    'gensokyo_main',
    'social_function',
    'rumor_network',
    'glossary',
    '噂網に関する正史設定です。分類は用語です。',
    jsonb_build_object('対象', '噂網', '分類', '用語', '説明', '日本語表示向けに整理した説明データです。'),
    'src_boaFW',
    'official',
    86,
    '["social","rumor"]'::jsonb
  ),
  (
    'claim_social_festivals',
    'gensokyo_main',
    'social_function',
    'festivals',
    'glossary',
    '祭礼に関する正史設定です。分類は用語です。',
    jsonb_build_object('対象', '祭礼', '分類', '用語', '説明', '日本語表示向けに整理した説明データです。'),
    'src_sixty_years',
    'official',
    83,
    '["social","festival"]'::jsonb
  ),
  (
    'claim_social_teaching',
    'gensokyo_main',
    'social_function',
    'teaching',
    'glossary',
    '教育に関する正史設定です。分類は用語です。',
    jsonb_build_object('対象', '教育', '分類', '用語', '説明', '日本語表示向けに整理した説明データです。'),
    'src_fs',
    'official',
    82,
    '["social","teaching"]'::jsonb
  ),
  (
    'claim_social_trade',
    'gensokyo_main',
    'social_function',
    'trade',
    'glossary',
    '交易に関する正史設定です。分類は用語です。',
    jsonb_build_object('対象', '交易', '分類', '用語', '説明', '日本語表示向けに整理した説明データです。'),
    'src_um',
    'official',
    81,
    '["social","trade"]'::jsonb
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

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  (
    'gensokyo_main',
    'lore_incident_scarlet_mist',
    'incident',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'incident', '説明', '日本語表示向けに整理した説明データです。'),
    '["incident","eosd","mist"]'::jsonb,
    88
  ),
  (
    'gensokyo_main',
    'lore_incident_spring_snow',
    'incident',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'incident', '説明', '日本語表示向けに整理した説明データです。'),
    '["incident","pcb","spring"]'::jsonb,
    86
  ),
  (
    'gensokyo_main',
    'lore_incident_eternal_night',
    'incident',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'incident', '説明', '日本語表示向けに整理した説明データです。'),
    '["incident","in","night"]'::jsonb,
    89
  ),
  (
    'gensokyo_main',
    'lore_incident_flower_anomaly',
    'incident',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'incident', '説明', '日本語表示向けに整理した説明データです。'),
    '["incident","pofv","flowers"]'::jsonb,
    78
  ),
  (
    'gensokyo_main',
    'lore_incident_weather_anomaly',
    'incident',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'incident', '説明', '日本語表示向けに整理した説明データです。'),
    '["incident","swr","weather"]'::jsonb,
    81
  ),
  (
    'gensokyo_main',
    'lore_incident_moriya_faith',
    'incident',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'incident', '説明', '日本語表示向けに整理した説明データです。'),
    '["incident","mof","faith"]'::jsonb,
    84
  ),
  (
    'gensokyo_main',
    'lore_incident_subterranean_sun',
    'incident',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'incident', '説明', '日本語表示向けに整理した説明データです。'),
    '["incident","sa","underground"]'::jsonb,
    85
  ),
  (
    'gensokyo_main',
    'lore_incident_floating_treasures',
    'incident',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'incident', '説明', '日本語表示向けに整理した説明データです。'),
    '["incident","ufo","temple"]'::jsonb,
    82
  ),
  (
    'gensokyo_main',
    'lore_incident_divine_spirits',
    'incident',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'incident', '説明', '日本語表示向けに整理した説明データです。'),
    '["incident","td","mausoleum"]'::jsonb,
    82
  ),
  (
    'gensokyo_main',
    'lore_incident_little_rebellion',
    'incident',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'incident', '説明', '日本語表示向けに整理した説明データです。'),
    '["incident","ddc","reversal"]'::jsonb,
    80
  ),
  (
    'gensokyo_main',
    'lore_incident_lunar_crisis',
    'incident',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'incident', '説明', '日本語表示向けに整理した説明データです。'),
    '["incident","lolk","moon"]'::jsonb,
    89
  ),
  (
    'gensokyo_main',
    'lore_incident_hidden_seasons',
    'incident',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'incident', '説明', '日本語表示向けに整理した説明データです。'),
    '["incident","hsifs","seasons"]'::jsonb,
    81
  ),
  (
    'gensokyo_main',
    'lore_incident_beast_realm',
    'incident',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'incident', '説明', '日本語表示向けに整理した説明データです。'),
    '["incident","wbawc","beast_realm"]'::jsonb,
    84
  ),
  (
    'gensokyo_main',
    'lore_incident_market_cards',
    'incident',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'incident', '説明', '日本語表示向けに整理した説明データです。'),
    '["incident","um","market"]'::jsonb,
    80
  ),
  (
    'gensokyo_main',
    'lore_incident_living_ghost_conflict',
    'incident',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'incident', '説明', '日本語表示向けに整理した説明データです。'),
    '["incident","19","underworld"]'::jsonb,
    83
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
    'claim_incident_scarlet_mist',
    'gensokyo_main',
    'incident',
    'incident_scarlet_mist',
    'summary',
    '紅霧異変に関する正史設定です。分類は要約です。',
    jsonb_build_object('対象', '紅霧異変', '分類', '要約', '説明', '日本語表示向けに整理した説明データです。'),
    'src_eosd',
    'official',
    90,
    '["incident","eosd","mist"]'::jsonb
  ),
  (
    'claim_incident_spring_snow',
    'gensokyo_main',
    'incident',
    'incident_spring_snow',
    'summary',
    '春雪異変に関する正史設定です。分類は要約です。',
    jsonb_build_object('対象', '春雪異変', '分類', '要約', '説明', '日本語表示向けに整理した説明データです。'),
    'src_pcb',
    'official',
    88,
    '["incident","pcb","spring"]'::jsonb
  ),
  (
    'claim_incident_eternal_night',
    'gensokyo_main',
    'incident',
    'incident_eternal_night',
    'summary',
    '永夜異変に関する正史設定です。分類は要約です。',
    jsonb_build_object('対象', '永夜異変', '分類', '要約', '説明', '日本語表示向けに整理した説明データです。'),
    'src_imperishable_night',
    'official',
    91,
    '["incident","in","night"]'::jsonb
  ),
  (
    'claim_incident_flower_anomaly',
    'gensokyo_main',
    'incident',
    'incident_flower_anomaly',
    'summary',
    '花異変に関する正史設定です。分類は要約です。',
    jsonb_build_object('対象', '花異変', '分類', '要約', '説明', '日本語表示向けに整理した説明データです。'),
    'src_poFV',
    'official',
    79,
    '["incident","pofv","flowers"]'::jsonb
  ),
  (
    'claim_incident_weather_anomaly',
    'gensokyo_main',
    'incident',
    'incident_weather_anomaly',
    'summary',
    '天候異変に関する正史設定です。分類は要約です。',
    jsonb_build_object('対象', '天候異変', '分類', '要約', '説明', '日本語表示向けに整理した説明データです。'),
    'src_swl',
    'official',
    82,
    '["incident","swr","weather"]'::jsonb
  ),
  (
    'claim_incident_faith_shift',
    'gensokyo_main',
    'incident',
    'incident_faith_shift',
    'summary',
    '信仰異変に関する正史設定です。分類は要約です。',
    jsonb_build_object('対象', '信仰異変', '分類', '要約', '説明', '日本語表示向けに整理した説明データです。'),
    'src_mofa',
    'official',
    85,
    '["incident","mof","faith"]'::jsonb
  ),
  (
    'claim_incident_subterranean_sun',
    'gensokyo_main',
    'incident',
    'incident_subterranean_sun',
    'summary',
    '地底太陽異変に関する正史設定です。分類は要約です。',
    jsonb_build_object('対象', '地底太陽異変', '分類', '要約', '説明', '日本語表示向けに整理した説明データです。'),
    'src_subterranean_animism',
    'official',
    86,
    '["incident","sa","underground"]'::jsonb
  ),
  (
    'claim_incident_floating_treasures',
    'gensokyo_main',
    'incident',
    'incident_floating_treasures',
    'summary',
    '宝船異変に関する正史設定です。分類は要約です。',
    jsonb_build_object('対象', '宝船異変', '分類', '要約', '説明', '日本語表示向けに整理した説明データです。'),
    'src_ufo',
    'official',
    84,
    '["incident","ufo","temple"]'::jsonb
  ),
  (
    'claim_incident_divine_spirits',
    'gensokyo_main',
    'incident',
    'incident_divine_spirits',
    'summary',
    '神霊異変に関する正史設定です。分類は要約です。',
    jsonb_build_object('対象', '神霊異変', '分類', '要約', '説明', '日本語表示向けに整理した説明データです。'),
    'src_td',
    'official',
    83,
    '["incident","td","mausoleum"]'::jsonb
  ),
  (
    'claim_incident_little_rebellion',
    'gensokyo_main',
    'incident',
    'incident_little_rebellion',
    'summary',
    '小人の反逆に関する正史設定です。分類は要約です。',
    jsonb_build_object('対象', '小人の反逆', '分類', '要約', '説明', '日本語表示向けに整理した説明データです。'),
    'src_ddc',
    'official',
    81,
    '["incident","ddc","reversal"]'::jsonb
  ),
  (
    'claim_incident_lunar_crisis',
    'gensokyo_main',
    'incident',
    'incident_lunar_crisis',
    'summary',
    '月都異変に関する正史設定です。分類は要約です。',
    jsonb_build_object('対象', '月都異変', '分類', '要約', '説明', '日本語表示向けに整理した説明データです。'),
    'src_lolk',
    'official',
    91,
    '["incident","lolk","moon"]'::jsonb
  ),
  (
    'claim_incident_hidden_seasons',
    'gensokyo_main',
    'incident',
    'incident_hidden_seasons',
    'summary',
    '四季異変に関する正史設定です。分類は要約です。',
    jsonb_build_object('対象', '四季異変', '分類', '要約', '説明', '日本語表示向けに整理した説明データです。'),
    'src_hsifs',
    'official',
    82,
    '["incident","hsifs","seasons"]'::jsonb
  ),
  (
    'claim_incident_beast_realm',
    'gensokyo_main',
    'incident',
    'incident_beast_realm',
    'summary',
    '畜生界異変に関する正史設定です。分類は要約です。',
    jsonb_build_object('対象', '畜生界異変', '分類', '要約', '説明', '日本語表示向けに整理した説明データです。'),
    'src_wbawc',
    'official',
    85,
    '["incident","wbawc","beast_realm"]'::jsonb
  ),
  (
    'claim_incident_market_cards',
    'gensokyo_main',
    'incident',
    'incident_market_cards',
    'summary',
    '能力カード騒動に関する正史設定です。分類は要約です。',
    jsonb_build_object('対象', '能力カード騒動', '分類', '要約', '説明', '日本語表示向けに整理した説明データです。'),
    'src_um',
    'official',
    81,
    '["incident","um","market"]'::jsonb
  ),
  (
    'claim_incident_living_ghost_conflict',
    'gensokyo_main',
    'incident',
    'incident_living_ghost_conflict',
    'summary',
    '生ける亡霊騒動に関する正史設定です。分類は要約です。',
    jsonb_build_object('対象', '生ける亡霊騒動', '分類', '要約', '説明', '日本語表示向けに整理した説明データです。'),
    'src_uDoALG',
    'official',
    83,
    '["incident","19","underworld"]'::jsonb
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

insert into public.world_chronicle_chapters (
  id, book_id, chapter_code, chapter_order, title, summary, period_start, period_end, metadata
)
values (
  'chronicle_gensokyo_history:chapter:major_incidents',
  'chronicle_gensokyo_history',
  'major_incidents',
  3,
  '年代記の章',
  '年代記の章の内容を整理した章説明です。',
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
  id, book_id, chapter_id, entry_code, entry_order, entry_type, title, summary, body, subject_type, subject_id, narrator_character_id, event_id, history_id, tags, metadata
)
values (
  'chronicle_entry_major_incidents',
  'chronicle_gensokyo_history',
  'chronicle_gensokyo_history:chapter:major_incidents',
  'major_incidents_overview',
  1,
  'catalog',
  '幻想郷に関する年代記',
  '幻想郷に関する年代記の記録です。',
  '幻想郷に関する経緯や位置づけを日本語で整理した本文です。',
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
  (
    'chronicle_entry_major_incidents:src:eosd',
    'chronicle_entry_major_incidents',
    'canon_claim',
    'claim_incident_scarlet_mist',
    '参照資料',
    0.95,
    '年代記の根拠として参照した資料です。'
  ),
  (
    'chronicle_entry_major_incidents:src:in',
    'chronicle_entry_major_incidents',
    'canon_claim',
    'claim_incident_eternal_night',
    '参照資料',
    0.95,
    '年代記の根拠として参照した資料です。'
  ),
  (
    'chronicle_entry_major_incidents:src:lolk',
    'chronicle_entry_major_incidents',
    'canon_claim',
    'claim_incident_lunar_crisis',
    '参照資料',
    0.95,
    '年代記の根拠として参照した資料です。'
  ),
  (
    'chronicle_entry_major_incidents:src:um',
    'chronicle_entry_major_incidents',
    'canon_claim',
    'claim_incident_market_cards',
    '参照資料',
    0.85,
    '年代記の根拠として参照した資料です。'
  )
on conflict (id) do update
set source_kind = excluded.source_kind,
    source_ref_id = excluded.source_ref_id,
    source_label = excluded.source_label,
    weight = excluded.weight,
    notes = excluded.notes;

insert into public.world_historian_notes (
  id, world_id, historian_character_id, subject_type, subject_id, note_kind, title, summary, body, source_ref_ids, metadata
)
values (
  'historian_note_keine_major_incidents',
  'gensokyo_main',
  'keine',
  'world',
  'gensokyo_main',
  'editorial',
  '幻想郷に関する注記',
  '幻想郷を歴史記録として扱うための補足注記です。',
  '幻想郷に関する記録上の見方や整理方針をまとめた歴史家注記です。',
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

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  (
    'wiki_character_meiling',
    'gensokyo_main',
    'characters/hong-meiling',
    '紅 美鈴',
    'character',
    'character',
    'meiling',
    '紅 美鈴に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_satori',
    'gensokyo_main',
    'characters/satori-komeiji',
    '古明地 さとり',
    'character',
    'character',
    'satori',
    '古明地 さとりに関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_rin',
    'gensokyo_main',
    'characters/orin',
    '火焔猫 燐',
    'character',
    'character',
    'rin',
    '火焔猫 燐に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_location_chireiden',
    'gensokyo_main',
    'locations/chireiden',
    '地霊殿',
    'location',
    'location',
    'chireiden',
    '地霊殿に関する幻想郷事典項目です。',
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
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_meiling_gatekeeper","lore_meiling_gatekeeping"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_satori:section:overview',
    'wiki_character_satori',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_satori_chireiden","lore_satori_insight"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_rin:section:overview',
    'wiki_character_rin',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_rin_underground_flow","lore_rin_social_flow"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_location_chireiden:section:profile',
    'wiki_location_chireiden',
    'profile',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
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
    '紅 美鈴の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '紅 美鈴の会話や振る舞いに関する文脈データです。'),
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
    '古明地 さとりの会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '古明地 さとりの会話や振る舞いに関する文脈データです。'),
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
    '火焔猫 燐の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '火焔猫 燐の会話や振る舞いに関する文脈データです。'),
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
    '犬走 椛の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '犬走 椛の会話や振る舞いに関する文脈データです。'),
    0.79,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  (
    'wiki_character_cirno',
    'gensokyo_main',
    'characters/cirno',
    'チルノ',
    'character',
    'character',
    'cirno',
    'チルノに関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_tewi',
    'gensokyo_main',
    'characters/tewi-inaba',
    '因幡 てゐ',
    'character',
    'character',
    'tewi',
    '因幡 てゐに関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_group_prismriver',
    'gensokyo_main',
    'groups/prismriver-ensemble',
    '対象項目',
    'group',
    'group',
    'prismriver',
    '対象項目に関する幻想郷事典項目です。',
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
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_cirno_fairy_local","lore_cirno_local_trouble"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_tewi:section:overview',
    'wiki_character_tewi',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_tewi_eientei_trickster","lore_tewi_detours"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_group_prismriver:section:overview',
    'wiki_group_prismriver',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
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
    'チルノの会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', 'チルノの会話や振る舞いに関する文脈データです。'),
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
    '因幡 てゐの会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '因幡 てゐの会話や振る舞いに関する文脈データです。'),
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
    'ルナサ・プリズムリバーの会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', 'ルナサ・プリズムリバーの会話や振る舞いに関する文脈データです。'),
    0.76,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  (
    'wiki_character_miko',
    'gensokyo_main',
    'characters/toyosatomimi-no-miko',
    '豊聡耳 神子',
    'character',
    'character',
    'miko',
    '豊聡耳 神子に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_seija',
    'gensokyo_main',
    'characters/seija-kijin',
    '鬼人 正邪',
    'character',
    'character',
    'seija',
    '鬼人 正邪に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_junko',
    'gensokyo_main',
    'characters/junko',
    '純狐',
    'character',
    'character',
    'junko',
    '純狐に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_okina',
    'gensokyo_main',
    'characters/okina-matara',
    '摩多羅 隠岐奈',
    'character',
    'character',
    'okina',
    '摩多羅 隠岐奈に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_yachie',
    'gensokyo_main',
    'characters/yachie-kicchou',
    '吉弔 八千慧',
    'character',
    'character',
    'yachie',
    '吉弔 八千慧に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_takane',
    'gensokyo_main',
    'characters/takane-yamashiro',
    '山城 たかね',
    'character',
    'character',
    'takane',
    '山城 たかねに関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_location_lunar_capital',
    'gensokyo_main',
    'locations/lunar-capital',
    '月の都',
    'location',
    'location',
    'lunar_capital',
    '月の都に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_location_beast_realm',
    'gensokyo_main',
    'locations/beast-realm',
    '畜生界',
    'location',
    'location',
    'beast_realm',
    '畜生界に関する幻想郷事典項目です。',
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
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_miko_saint_leadership","lore_miko_public_authority"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_seija:section:overview',
    'wiki_character_seija',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_seija_rebel","lore_seija_contrarian_pressure"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_junko:section:overview',
    'wiki_character_junko',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_junko_pure_hostility","lore_junko_high_impact"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_okina:section:overview',
    'wiki_character_okina',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_okina_hidden_doors","lore_okina_hidden_access"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_yachie:section:overview',
    'wiki_character_yachie',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_yachie_faction_leader","lore_beast_realm_factions"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_takane:section:overview',
    'wiki_character_takane',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_takane_broker","lore_takane_trade_frame"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_location_lunar_capital:section:profile',
    'wiki_location_lunar_capital',
    'profile',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_lunar_capital_profile","lore_lunar_distance"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_location_beast_realm:section:profile',
    'wiki_location_beast_realm',
    'profile',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
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
    '豊聡耳 神子の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '豊聡耳 神子の会話や振る舞いに関する文脈データです。'),
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
    '鬼人 正邪の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '鬼人 正邪の会話や振る舞いに関する文脈データです。'),
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
    '純狐の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '純狐の会話や振る舞いに関する文脈データです。'),
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
    '摩多羅 隠岐奈の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '摩多羅 隠岐奈の会話や振る舞いに関する文脈データです。'),
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
    '吉弔 八千慧の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '吉弔 八千慧の会話や振る舞いに関する文脈データです。'),
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
    '山城 たかねの会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '山城 たかねの会話や振る舞いに関する文脈データです。'),
    0.85,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  (
    'wiki_character_akyuu',
    'gensokyo_main',
    'characters/hieda-no-akyuu',
    '稗田 阿求',
    'character',
    'character',
    'akyuu',
    '稗田 阿求に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_rinnosuke',
    'gensokyo_main',
    'characters/rinnosuke-morichika',
    '森近 霖之助',
    'character',
    'character',
    'rinnosuke',
    '森近 霖之助に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_kasen',
    'gensokyo_main',
    'characters/kasen-ibaraki',
    '茨木 華扇',
    'character',
    'character',
    'kasen',
    '茨木 華扇に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_sumireko',
    'gensokyo_main',
    'characters/sumireko-usami',
    '宇佐見 菫子',
    'character',
    'character',
    'sumireko',
    '宇佐見 菫子に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_location_kourindou',
    'gensokyo_main',
    'locations/kourindou',
    '香霖堂',
    'location',
    'location',
    'kourindou',
    '香霖堂に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_location_suzunaan',
    'gensokyo_main',
    'locations/suzunaan',
    '鈴奈庵',
    'location',
    'location',
    'suzunaan',
    '鈴奈庵に関する幻想郷事典項目です。',
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
    'wiki_character_akyuu:section:overview',
    'wiki_character_akyuu',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_akyuu_historian","lore_village_records"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_rinnosuke:section:overview',
    'wiki_character_rinnosuke',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_rinnosuke_object_interpreter","lore_kourindou_objects"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_kasen:section:overview',
    'wiki_character_kasen',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_kasen_advisor","lore_kasen_guidance"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_sumireko:section:overview',
    'wiki_character_sumireko',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_sumireko_urban_legend","lore_urban_legend_bleed"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_location_kourindou:section:profile',
    'wiki_location_kourindou',
    'profile',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_kourindou_profile","lore_kourindou_objects"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_location_suzunaan:section:profile',
    'wiki_location_suzunaan',
    'profile',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_suzunaan_profile","lore_suzunaan_books"]'::jsonb,
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
    'chat_context_global_akyuu_village_records',
    'gensokyo_main',
    'global',
    'akyuu',
    'human_village',
    null,
    'character_location_story',
    '稗田 阿求の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '稗田 阿求の会話や振る舞いに関する文脈データです。'),
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
    '森近 霖之助の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '森近 霖之助の会話や振る舞いに関する文脈データです。'),
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
    '茨木 華扇の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '茨木 華扇の会話や振る舞いに関する文脈データです。'),
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
    '宇佐見 菫子の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '宇佐見 菫子の会話や振る舞いに関する文脈データです。'),
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
    '依神 女苑の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '依神 女苑の会話や振る舞いに関する文脈データです。'),
    0.80,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  (
    'wiki_character_eiki',
    'gensokyo_main',
    'characters/shikieiki-yamaxanadu',
    '四季映姫・ヤマザナドゥ',
    'character',
    'character',
    'eiki',
    '四季映姫・ヤマザナドゥに関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_tenshi',
    'gensokyo_main',
    'characters/tenshi-hinanawi',
    '比那名居 天子',
    'character',
    'character',
    'tenshi',
    '比那名居 天子に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_kokoro',
    'gensokyo_main',
    'characters/hata-no-kokoro',
    '秦 こころ',
    'character',
    'character',
    'kokoro',
    '秦 こころに関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_doremy',
    'gensokyo_main',
    'characters/doremy-sweet',
    'ドレミー・スイート',
    'character',
    'character',
    'doremy',
    'ドレミー・スイートに関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_aunn',
    'gensokyo_main',
    'characters/aunn-komano',
    '高麗野 あうん',
    'character',
    'character',
    'aunn',
    '高麗野 あうんに関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_location_heaven',
    'gensokyo_main',
    'locations/heaven',
    '天界',
    'location',
    'location',
    'heaven',
    '天界に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_location_dream_world',
    'gensokyo_main',
    'locations/dream-world',
    '夢の世界',
    'location',
    'location',
    'dream_world',
    '夢の世界に関する幻想郷事典項目です。',
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
    'wiki_character_eiki:section:overview',
    'wiki_character_eiki',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_eiki_judge","lore_muenzuka_judgment"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_tenshi:section:overview',
    'wiki_character_tenshi',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_tenshi_celestial_instigator","lore_heaven_detachment"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_kokoro:section:overview',
    'wiki_character_kokoro',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_kokoro_mask_performer","lore_kokoro_public_affect"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_doremy:section:overview',
    'wiki_character_doremy',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_doremy_dream_guide","lore_dream_world_mediator"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_aunn:section:overview',
    'wiki_character_aunn',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_aunn_guardian","lore_aunn_shrine_everyday"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_location_heaven:section:profile',
    'wiki_location_heaven',
    'profile',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_heaven_profile","lore_heaven_detachment"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_location_dream_world:section:profile',
    'wiki_location_dream_world',
    'profile',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_dream_world_profile","lore_dream_world_mediator"]'::jsonb,
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
    'chat_context_global_eiki_muenzuka',
    'gensokyo_main',
    'global',
    'eiki',
    'muenzuka',
    null,
    'character_location_story',
    '四季映姫・ヤマザナドゥの会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '四季映姫・ヤマザナドゥの会話や振る舞いに関する文脈データです。'),
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
    '比那名居 天子の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '比那名居 天子の会話や振る舞いに関する文脈データです。'),
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
    '秦 こころの会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '秦 こころの会話や振る舞いに関する文脈データです。'),
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
    'ドレミー・スイートの会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', 'ドレミー・スイートの会話や振る舞いに関する文脈データです。'),
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
    '高麗野 あうんの会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '高麗野 あうんの会話や振る舞いに関する文脈データです。'),
    0.82,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  (
    'wiki_character_yuuma',
    'gensokyo_main',
    'characters/yuuma-toutetsu',
    '饕餮 尤魔',
    'character',
    'character',
    'yuuma',
    '饕餮 尤魔に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_zanmu',
    'gensokyo_main',
    'characters/zanmu-nippaku',
    '日白 残無',
    'character',
    'character',
    'zanmu',
    '日白 残無に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_suika',
    'gensokyo_main',
    'characters/suika-ibuki',
    '伊吹 萃香',
    'character',
    'character',
    'suika',
    '伊吹 萃香に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_location_blood_pool_hell',
    'gensokyo_main',
    'locations/blood-pool-hell',
    '血の池地獄',
    'location',
    'location',
    'blood_pool_hell',
    '血の池地獄に関する幻想郷事典項目です。',
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
    'wiki_character_yuuma:section:overview',
    'wiki_character_yuuma',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_yuuma_greed_power","lore_blood_pool_greed"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_zanmu:section:overview',
    'wiki_character_zanmu',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_zanmu_structural_actor","lore_recent_underworld_power"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_suika:section:overview',
    'wiki_character_suika',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_suika_old_power"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_location_blood_pool_hell:section:profile',
    'wiki_location_blood_pool_hell',
    'profile',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_blood_pool_hell_profile","lore_blood_pool_greed"]'::jsonb,
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
    'chat_context_global_suika_underworld_feast',
    'gensokyo_main',
    'global',
    'suika',
    'former_hell',
    null,
    'character_location_story',
    '伊吹 萃香の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '伊吹 萃香の会話や振る舞いに関する文脈データです。'),
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
    '饕餮 尤魔の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '饕餮 尤魔の会話や振る舞いに関する文脈データです。'),
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
    '日白 残無の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '日白 残無の会話や振る舞いに関する文脈データです。'),
    0.92,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  (
    'wiki_glossary_hakurei',
    'gensokyo_main',
    'glossary/hakurei-shrine',
    '博麗神社',
    'glossary',
    'institution',
    'hakurei_shrine',
    '博麗神社に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_glossary_moriya',
    'gensokyo_main',
    'glossary/moriya-shrine',
    '守矢神社',
    'glossary',
    'institution',
    'moriya_shrine',
    '守矢神社に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_glossary_myouren',
    'gensokyo_main',
    'glossary/myouren-temple',
    '命蓮寺',
    'glossary',
    'institution',
    'myouren_temple',
    '命蓮寺に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_glossary_eientei',
    'gensokyo_main',
    'glossary/eientei',
    '永遠亭',
    'glossary',
    'institution',
    'eientei',
    '永遠亭に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_glossary_spell_cards',
    'gensokyo_main',
    'glossary/spell-card-rules',
    '幻想郷',
    'glossary',
    'world',
    'gensokyo_main',
    '幻想郷に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_glossary_incidents',
    'gensokyo_main',
    'glossary/incidents',
    '幻想郷',
    'glossary',
    'world',
    'gensokyo_main',
    '幻想郷に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_glossary_boundaries',
    'gensokyo_main',
    'glossary/boundaries',
    '幻想郷',
    'glossary',
    'world',
    'gensokyo_main',
    '幻想郷に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_glossary_human_village',
    'gensokyo_main',
    'glossary/human-village',
    '人里',
    'glossary',
    'institution',
    'human_village',
    '人里に関する幻想郷事典項目です。',
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
    'wiki_glossary_hakurei:section:definition',
    'wiki_glossary_hakurei',
    'definition',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_glossary_hakurei","lore_glossary_hakurei"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_glossary_moriya:section:definition',
    'wiki_glossary_moriya',
    'definition',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_glossary_moriya","lore_glossary_moriya"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_glossary_myouren:section:definition',
    'wiki_glossary_myouren',
    'definition',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_glossary_myouren","lore_glossary_myouren"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_glossary_eientei:section:definition',
    'wiki_glossary_eientei',
    'definition',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_glossary_eientei","lore_glossary_eientei"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_glossary_spell_cards:section:definition',
    'wiki_glossary_spell_cards',
    'definition',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_glossary_spell_cards","lore_glossary_spell_cards"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_glossary_incidents:section:definition',
    'wiki_glossary_incidents',
    'definition',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_glossary_incidents","lore_glossary_incidents"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_glossary_boundaries:section:definition',
    'wiki_glossary_boundaries',
    'definition',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_glossary_boundaries","lore_glossary_boundaries"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_glossary_human_village:section:definition',
    'wiki_glossary_human_village',
    'definition',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_glossary_human_village","lore_glossary_human_village"]'::jsonb,
    '{}'::jsonb
  )
on conflict (id) do update
set heading = excluded.heading,
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
    'wiki_term_shinto',
    'gensokyo_main',
    'terms/shinto',
    '神道',
    'glossary',
    'term',
    'shinto',
    '神道に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_term_buddhism',
    'gensokyo_main',
    'terms/buddhism',
    '仏教',
    'glossary',
    'term',
    'buddhism',
    '仏教に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_term_taoism',
    'gensokyo_main',
    'terms/taoism',
    '道教',
    'glossary',
    'term',
    'taoism',
    '道教に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_term_lunarians',
    'gensokyo_main',
    'terms/lunarians',
    '月人',
    'glossary',
    'term',
    'lunarians',
    '月人に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_term_tengu',
    'gensokyo_main',
    'terms/tengu',
    '天狗',
    'glossary',
    'term',
    'tengu',
    '天狗に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_term_kappa',
    'gensokyo_main',
    'terms/kappa',
    '河童',
    'glossary',
    'term',
    'kappa',
    '河童に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_term_tsukumogami',
    'gensokyo_main',
    'terms/tsukumogami',
    '付喪神',
    'glossary',
    'term',
    'tsukumogami',
    '付喪神に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_term_urban_legends',
    'gensokyo_main',
    'terms/urban-legends',
    '都市伝説',
    'glossary',
    'term',
    'urban_legends',
    '都市伝説に関する幻想郷事典項目です。',
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
    'wiki_term_shinto:section:definition',
    'wiki_term_shinto',
    'definition',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_glossary_shinto","lore_glossary_shinto"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_term_buddhism:section:definition',
    'wiki_term_buddhism',
    'definition',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_glossary_buddhism","lore_glossary_buddhism"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_term_taoism:section:definition',
    'wiki_term_taoism',
    'definition',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_glossary_taoism","lore_glossary_taoism"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_term_lunarians:section:definition',
    'wiki_term_lunarians',
    'definition',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_glossary_lunarians","lore_glossary_lunarians"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_term_tengu:section:definition',
    'wiki_term_tengu',
    'definition',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_glossary_tengu","lore_glossary_tengu"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_term_kappa:section:definition',
    'wiki_term_kappa',
    'definition',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_glossary_kappa","lore_glossary_kappa"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_term_tsukumogami:section:definition',
    'wiki_term_tsukumogami',
    'definition',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_glossary_tsukumogami","lore_glossary_tsukumogami"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_term_urban_legends:section:definition',
    'wiki_term_urban_legends',
    'definition',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_glossary_urban_legends","lore_glossary_urban_legends"]'::jsonb,
    '{}'::jsonb
  )
on conflict (id) do update
set heading = excluded.heading,
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
    'wiki_faction_hakurei',
    'gensokyo_main',
    'factions/hakurei',
    '博麗神社側',
    'glossary',
    'faction',
    'hakurei',
    '博麗神社側に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_faction_moriya',
    'gensokyo_main',
    'factions/moriya',
    '守矢神社側',
    'glossary',
    'faction',
    'moriya',
    '守矢神社側に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_faction_sdm',
    'gensokyo_main',
    'factions/scarlet-devil-mansion',
    '紅魔館勢',
    'glossary',
    'faction',
    'sdm',
    '紅魔館勢に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_faction_eientei',
    'gensokyo_main',
    'factions/eientei',
    '永遠亭',
    'glossary',
    'faction',
    'eientei',
    '永遠亭に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_social_rumor',
    'gensokyo_main',
    'social-functions/rumor-network',
    '噂網',
    'glossary',
    'social_function',
    'rumor_network',
    '噂網に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_social_festivals',
    'gensokyo_main',
    'social-functions/festivals',
    '祭礼',
    'glossary',
    'social_function',
    'festivals',
    '祭礼に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_social_trade',
    'gensokyo_main',
    'social-functions/trade',
    '交易',
    'glossary',
    'social_function',
    'trade',
    '交易に関する幻想郷事典項目です。',
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
    'wiki_faction_hakurei:section:definition',
    'wiki_faction_hakurei',
    'definition',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_faction_hakurei","lore_faction_hakurei"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_faction_moriya:section:definition',
    'wiki_faction_moriya',
    'definition',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_faction_moriya","lore_faction_moriya"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_faction_sdm:section:definition',
    'wiki_faction_sdm',
    'definition',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_faction_sdm","lore_faction_sdm"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_faction_eientei:section:definition',
    'wiki_faction_eientei',
    'definition',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_faction_eientei","lore_faction_eientei"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_social_rumor:section:definition',
    'wiki_social_rumor',
    'definition',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_social_rumor_network","lore_social_rumor_network"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_social_festivals:section:definition',
    'wiki_social_festivals',
    'definition',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_social_festivals","lore_social_festivals"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_social_trade:section:definition',
    'wiki_social_trade',
    'definition',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_social_trade","lore_social_trade"]'::jsonb,
    '{}'::jsonb
  )
on conflict (id) do update
set heading = excluded.heading,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_characters (
  world_id, id, name, title, species, faction_id, home_location_id, default_location_id, public_summary, private_notes, speech_style, worldview, role_in_gensokyo, tags, profile
)
values
  (
    'gensokyo_main',
    'kisume',
    'キスメ',
    '桶に潜む井戸妖怪',
    '妖怪',
    'independent',
    'former_hell',
    'former_hell',
    'キスメに関する基本人物紹介です。',
    'キスメを配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    'キスメの価値観や見方を整理した文面です。',
    'キスメの役割です。',
    '["sa","underground","ambush"]'::jsonb,
    jsonb_build_object('表示名', 'キスメ', '肩書き', '桶に潜む井戸妖怪', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'yamame',
    '黒谷 ヤマメ',
    '暗い洞窟の明るい網',
    '種族',
    'independent',
    'former_hell',
    'former_hell',
    '黒谷 ヤマメに関する基本人物紹介です。',
    '黒谷 ヤマメを配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '黒谷 ヤマメの価値観や見方を整理した文面です。',
    '黒谷 ヤマメの役割です。',
    '["sa","underground","rumor"]'::jsonb,
    jsonb_build_object('表示名', '黒谷 ヤマメ', '肩書き', '暗い洞窟の明るい網', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'parsee',
    '水橋 パルスィ',
    '地殻の下の嫉妬心',
    '種族',
    'independent',
    'former_hell',
    'former_hell',
    '水橋 パルスィに関する基本人物紹介です。',
    '水橋 パルスィを配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '水橋 パルスィの価値観や見方を整理した文面です。',
    '水橋 パルスィの役割です。',
    '["sa","bridge","emotion"]'::jsonb,
    jsonb_build_object('表示名', '水橋 パルスィ', '肩書き', '地殻の下の嫉妬心', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'yuugi',
    '星熊 勇儀',
    '語られる怪力乱神',
    '種族',
    'independent',
    'old_capital',
    'old_capital',
    '星熊 勇儀に関する基本人物紹介です。',
    '星熊 勇儀を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '星熊 勇儀の価値観や見方を整理した文面です。',
    '星熊 勇儀の役割です。',
    '["sa","oni","old_capital"]'::jsonb,
    jsonb_build_object('表示名', '星熊 勇儀', '肩書き', '語られる怪力乱神', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'kyouko',
    '幽谷 響子',
    '山彦の僧侶',
    '種族',
    'myouren',
    'myouren_temple',
    'myouren_temple',
    '幽谷 響子に関する基本人物紹介です。',
    '幽谷 響子を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '幽谷 響子の価値観や見方を整理した文面です。',
    '幽谷 響子の役割です。',
    '["td","temple","echo"]'::jsonb,
    jsonb_build_object('表示名', '幽谷 響子', '肩書き', '山彦の僧侶', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'yoshika',
    '宮古 芳香',
    '忠実なキョンシー',
    '種族',
    'taoist',
    'divine_spirit_mausoleum',
    'divine_spirit_mausoleum',
    '宮古 芳香に関する基本人物紹介です。',
    '宮古 芳香を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '宮古 芳香の価値観や見方を整理した文面です。',
    '宮古 芳香の役割です。',
    '["td","mausoleum","retainer"]'::jsonb,
    jsonb_build_object('表示名', '宮古 芳香', '肩書き', '忠実なキョンシー', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'shou',
    '寅丸 星',
    '毘沙門天の弟子',
    '妖怪',
    'myouren',
    'myouren_temple',
    'myouren_temple',
    '寅丸 星に関する基本人物紹介です。',
    '寅丸 星を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '寅丸 星の価値観や見方を整理した文面です。',
    '寅丸 星の役割です。',
    '["ufo","temple","authority"]'::jsonb,
    jsonb_build_object('表示名', '寅丸 星', '肩書き', '毘沙門天の弟子', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'sunny_milk',
    'サニーミルク',
    '日光の妖精',
    '種族',
    'independent',
    'hakurei_shrine',
    'hakurei_shrine',
    'サニーミルクに関する基本人物紹介です。',
    'サニーミルクを配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    'サニーミルクの価値観や見方を整理した文面です。',
    'サニーミルクの役割です。',
    '["fairy","daily_life","sunlight"]'::jsonb,
    jsonb_build_object('表示名', 'サニーミルク', '肩書き', '日光の妖精', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'luna_child',
    'ルナチャイルド',
    '静寂の妖精',
    '種族',
    'independent',
    'hakurei_shrine',
    'hakurei_shrine',
    'ルナチャイルドに関する基本人物紹介です。',
    'ルナチャイルドを配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    'ルナチャイルドの価値観や見方を整理した文面です。',
    'ルナチャイルドの役割です。',
    '["fairy","daily_life","silence"]'::jsonb,
    jsonb_build_object('表示名', 'ルナチャイルド', '肩書き', '静寂の妖精', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'star_sapphire',
    'スターサファイア',
    '星の光の妖精',
    '種族',
    'independent',
    'hakurei_shrine',
    'hakurei_shrine',
    'スターサファイアに関する基本人物紹介です。',
    'スターサファイアを配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    'スターサファイアの価値観や見方を整理した文面です。',
    'スターサファイアの役割です。',
    '["fairy","daily_life","perception"]'::jsonb,
    jsonb_build_object('表示名', 'スターサファイア', '肩書き', '星の光の妖精', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
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
  (
    'gensokyo_main',
    'kisume',
    'yamame',
    'underground_neighbor',
    'キスメと黒谷 ヤマメのあいだにある関係を示す関係データです。',
    0.37,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'yamame',
    'parsee',
    'underground_social_overlap',
    '黒谷 ヤマメと水橋 パルスィのあいだにある関係を示す関係データです。',
    0.42,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'parsee',
    'yuugi',
    'bridge_to_capital',
    '水橋 パルスィと星熊 勇儀のあいだにある関係を示す関係データです。',
    0.39,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'yuugi',
    'suika',
    'oni_peer',
    '星熊 勇儀と伊吹 萃香のあいだにある関係を示す関係データです。',
    0.58,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'kyouko',
    'byakuren',
    'temple_disciple',
    '幽谷 響子と聖 白蓮のあいだにある関係を示す関係データです。',
    0.61,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'shou',
    'byakuren',
    'temple_leadership',
    '寅丸 星と聖 白蓮のあいだにある関係を示す関係データです。',
    0.67,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'yoshika',
    'seiga',
    'servant_bond',
    '宮古 芳香と霍 青娥のあいだにある関係を示す関係データです。',
    0.74,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'yoshika',
    'miko',
    'mausoleum_service',
    '宮古 芳香と豊聡耳 神子のあいだにある関係を示す関係データです。',
    0.34,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'sunny_milk',
    'luna_child',
    'fairy_trio',
    'サニーミルクとルナチャイルドのあいだにある関係を示す関係データです。',
    0.84,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'luna_child',
    'star_sapphire',
    'fairy_trio',
    'ルナチャイルドとスターサファイアのあいだにある関係を示す関係データです。',
    0.84,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'star_sapphire',
    'sunny_milk',
    'fairy_trio',
    'スターサファイアとサニーミルクのあいだにある関係を示す関係データです。',
    0.84,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'sunny_milk',
    'reimu',
    'shrine_mischief',
    'サニーミルクと博麗 霊夢のあいだにある関係を示す関係データです。',
    0.29,
    '{}'::jsonb
  )
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
    'lore_supporting_cast_underground',
    'regional_texture',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'regional_texture', '説明', '日本語表示向けに整理した説明データです。'),
    '["supporting_cast","underground","texture"]'::jsonb,
    76
  ),
  (
    'gensokyo_main',
    'lore_supporting_cast_temple',
    'regional_texture',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'regional_texture', '説明', '日本語表示向けに整理した説明データです。'),
    '["supporting_cast","temple","texture"]'::jsonb,
    75
  ),
  (
    'gensokyo_main',
    'lore_supporting_cast_fairies',
    'daily_life_texture',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'daily_life_texture', '説明', '日本語表示向けに整理した説明データです。'),
    '["supporting_cast","fairy","daily_life"]'::jsonb,
    74
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
    'claim_kisume_underground_approach',
    'gensokyo_main',
    'character',
    'kisume',
    'role',
    'キスメに関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', 'キスメ', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_subterranean_animism',
    'official',
    62,
    '["kisume","sa","underground"]'::jsonb
  ),
  (
    'claim_yamame_network_underground',
    'gensokyo_main',
    'character',
    'yamame',
    'role',
    '黒谷 ヤマメに関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '黒谷 ヤマメ', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_subterranean_animism',
    'official',
    68,
    '["yamame","sa","network"]'::jsonb
  ),
  (
    'claim_parsee_threshold_pressure',
    'gensokyo_main',
    'character',
    'parsee',
    'role',
    '水橋 パルスィに関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '水橋 パルスィ', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_subterranean_animism',
    'official',
    70,
    '["parsee","sa","bridge"]'::jsonb
  ),
  (
    'claim_yuugi_old_capital_anchor',
    'gensokyo_main',
    'character',
    'yuugi',
    'role',
    '星熊 勇儀に関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '星熊 勇儀', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_subterranean_animism',
    'official',
    72,
    '["yuugi","sa","oni"]'::jsonb
  ),
  (
    'claim_kyouko_temple_daily_voice',
    'gensokyo_main',
    'character',
    'kyouko',
    'role',
    '幽谷 響子に関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '幽谷 響子', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_td',
    'official',
    66,
    '["kyouko","td","temple"]'::jsonb
  ),
  (
    'claim_yoshika_mausoleum_retainer',
    'gensokyo_main',
    'character',
    'yoshika',
    'role',
    '宮古 芳香に関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '宮古 芳香', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_td',
    'official',
    69,
    '["yoshika","td","retainer"]'::jsonb
  ),
  (
    'claim_shou_temple_authority',
    'gensokyo_main',
    'character',
    'shou',
    'role',
    '寅丸 星に関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '寅丸 星', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_ufo',
    'official',
    72,
    '["shou","ufo","temple"]'::jsonb
  ),
  (
    'claim_sunny_daily_fairy',
    'gensokyo_main',
    'character',
    'sunny_milk',
    'role',
    'サニーミルクに関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', 'サニーミルク', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_osp',
    'official',
    64,
    '["sunny_milk","fairy","daily_life"]'::jsonb
  ),
  (
    'claim_luna_daily_fairy',
    'gensokyo_main',
    'character',
    'luna_child',
    'role',
    'ルナチャイルドに関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', 'ルナチャイルド', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_osp',
    'official',
    64,
    '["luna_child","fairy","daily_life"]'::jsonb
  ),
  (
    'claim_star_daily_fairy',
    'gensokyo_main',
    'character',
    'star_sapphire',
    'role',
    'スターサファイアに関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', 'スターサファイア', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_osp',
    'official',
    64,
    '["star_sapphire","fairy","daily_life"]'::jsonb
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

