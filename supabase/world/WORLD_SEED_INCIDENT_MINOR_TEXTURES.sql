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
