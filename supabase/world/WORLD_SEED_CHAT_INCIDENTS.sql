-- World seed: chat context for major incident summaries

insert into public.world_chat_context_cache (
  id, world_id, user_scope, character_id, location_id, event_id, context_type, summary, payload, freshness_score, last_used_at
)
values
  (
    'chat_incident_scarlet_mist_summary',
    'gensokyo_main',
    'global',
    null,
    'scarlet_devil_mansion',
    null,
    'incident_summary',
    'The Scarlet Mist Incident should be recalled as a mansion-centered atmospheric crisis that clarified the public scale of incident response.',
    jsonb_build_object(
      'claim_ids', array['claim_incident_scarlet_mist'],
      'lore_ids', array['lore_incident_scarlet_mist'],
      'location_ids', array['scarlet_devil_mansion','misty_lake']
    ),
    0.86,
    now()
  ),
  (
    'chat_incident_eternal_night_summary',
    'gensokyo_main',
    'global',
    null,
    'eientei',
    null,
    'incident_summary',
    'Imperishable Night should be recalled through false night, delayed dawn, lunar implication, and secrecy under pressure.',
    jsonb_build_object(
      'claim_ids', array['claim_incident_eternal_night'],
      'lore_ids', array['lore_incident_eternal_night'],
      'location_ids', array['eientei','bamboo_forest','lunar_capital']
    ),
    0.88,
    now()
  ),
  (
    'chat_incident_faith_shift_summary',
    'gensokyo_main',
    'global',
    null,
    'moriya_shrine',
    null,
    'incident_summary',
    'The mountain faith shift is best remembered as proactive shrine competition and institutional influence becoming publicly visible.',
    jsonb_build_object(
      'claim_ids', array['claim_incident_faith_shift'],
      'lore_ids', array['lore_incident_moriya_faith'],
      'location_ids', array['moriya_shrine','youkai_mountain_foot']
    ),
    0.84,
    now()
  ),
  (
    'chat_incident_lunar_crisis_summary',
    'gensokyo_main',
    'global',
    null,
    'lunar_capital',
    null,
    'incident_summary',
    'The lunar crisis should read as moon politics, purification, and dream mediation colliding at a scale beyond ordinary local trouble.',
    jsonb_build_object(
      'claim_ids', array['claim_incident_lunar_crisis'],
      'lore_ids', array['lore_incident_lunar_crisis'],
      'location_ids', array['lunar_capital','dream_world']
    ),
    0.90,
    now()
  ),
  (
    'chat_incident_market_cards_summary',
    'gensokyo_main',
    'global',
    null,
    'rainbow_dragon_cave',
    null,
    'incident_summary',
    'The card market incident should be recalled as an exchange-driven disruption where circulation and value became the engine of the problem.',
    jsonb_build_object(
      'claim_ids', array['claim_incident_market_cards'],
      'lore_ids', array['lore_incident_market_cards'],
      'location_ids', array['rainbow_dragon_cave','human_village']
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
