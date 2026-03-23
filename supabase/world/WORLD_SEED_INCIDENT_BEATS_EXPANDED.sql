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
