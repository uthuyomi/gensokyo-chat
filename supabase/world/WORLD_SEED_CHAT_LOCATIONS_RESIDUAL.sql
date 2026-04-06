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
