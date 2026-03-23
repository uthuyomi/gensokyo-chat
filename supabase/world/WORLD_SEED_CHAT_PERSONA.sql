-- World seed: chat context for additional persona-covered cast

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
    'Meiling is easiest to read through threshold scenes: guarding, intercepting, allowing entry, or framing who gets through.',
    jsonb_build_object(
      'claim_ids', array['claim_meiling_gatekeeper'],
      'lore_ids', array['lore_meiling_gatekeeping'],
      'location_ids', array['scarlet_gate','scarlet_devil_mansion']
    ),
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
    'Satori at Chireiden should pull a conversation toward motive, awareness, and the discomfort of being clearly perceived.',
    jsonb_build_object(
      'claim_ids', array['claim_satori_chireiden'],
      'lore_ids', array['lore_satori_insight','lore_chireiden_profile'],
      'location_ids', array['chireiden']
    ),
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
    'Rin fits conversations about underground movement, errands, social traffic, and informal information channels.',
    jsonb_build_object(
      'claim_ids', array['claim_rin_underground_flow'],
      'lore_ids', array['lore_rin_social_flow'],
      'location_ids', array['old_capital','former_hell']
    ),
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
    'Momiji is best framed through patrol logic, guarded routes, and mountain-side practical response.',
    jsonb_build_object(
      'claim_ids', array['claim_momiji_mountain_guard'],
      'lore_ids', array['lore_momiji_patrols'],
      'location_ids', array['genbu_ravine','youkai_mountain_foot']
    ),
    0.79,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();
