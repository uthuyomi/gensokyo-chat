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

insert into public.worlds (id, layer_id, name)
values ('gensokyo_main', 'gensokyo', 'Gensokyo Main World')
on conflict (id) do update
set layer_id = excluded.layer_id,
    name = excluded.name;

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
  ('world:gensokyo_main:hakurei_shrine', 'gensokyo_main', 'gensokyo', 'hakurei_shrine', 0),
  ('world:gensokyo_main:human_village', 'gensokyo_main', 'gensokyo', 'human_village', 0)
on conflict (channel) do nothing;

-- ------------------------------------------------------------
-- Extended canon/source tables for broader official-setting use
-- ------------------------------------------------------------

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

-- ------------------------------------------------------------
-- Chronicle / wiki / chat knowledge layer
-- ------------------------------------------------------------

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
