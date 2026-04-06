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
