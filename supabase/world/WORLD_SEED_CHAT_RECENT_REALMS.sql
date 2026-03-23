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
