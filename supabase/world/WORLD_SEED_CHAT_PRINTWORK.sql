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
