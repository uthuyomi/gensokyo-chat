-- World seed: chat context for flower, celestial, dream, and seasonal cast

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
    'Eiki should pull chat toward judgment, consequence, and moral correction rather than casual gossip.',
    jsonb_build_object(
      'claim_ids', array['claim_eiki_judge'],
      'lore_ids', array['lore_muenzuka_judgment'],
      'location_ids', array['muenzuka']
    ),
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
    'Tenshi belongs in chat as celestial arrogance mixed with weather-scale boredom and the possibility of oversized trouble.',
    jsonb_build_object(
      'claim_ids', array['claim_tenshi_celestial_instigator','claim_heaven_profile'],
      'lore_ids', array['lore_heaven_detachment'],
      'location_ids', array['heaven','bhavaagra']
    ),
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
    'Kokoro works best when a conversation is about emotions being shown, performed, or misread in public.',
    jsonb_build_object(
      'claim_ids', array['claim_kokoro_mask_performer'],
      'lore_ids', array['lore_kokoro_public_affect'],
      'location_ids', array['human_village']
    ),
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
    'Doremy should sound like someone who actually knows the routes and patterns of dream-space instead of treating it as shapeless weirdness.',
    jsonb_build_object(
      'claim_ids', array['claim_doremy_dream_guide','claim_dream_world_profile'],
      'lore_ids', array['lore_dream_world_mediator'],
      'location_ids', array['dream_world']
    ),
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
    'Aunn is strong in shrine-ground conversations that need warmth, local attachment, and practical guardianship.',
    jsonb_build_object(
      'claim_ids', array['claim_aunn_guardian'],
      'lore_ids', array['lore_aunn_shrine_everyday'],
      'location_ids', array['hakurei_shrine']
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
