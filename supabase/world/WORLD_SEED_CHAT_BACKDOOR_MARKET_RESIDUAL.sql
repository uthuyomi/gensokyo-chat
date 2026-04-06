-- World seed: residual backdoor and market chat context

insert into public.world_chat_context_cache (
  id, world_id, user_scope, character_id, location_id, event_id, context_type, summary, payload, freshness_score, last_used_at
)
values
  (
    'chat_context_global_satono_backdoor',
    'gensokyo_main',
    'global',
    'satono',
    'backdoor_realm',
    null,
    'character_location_story',
    'Satono in the Backdoor Realm should feel like bright service with a selective edge, as if access itself is being quietly sorted.',
    jsonb_build_object(
      'claim_ids', array['claim_satono_selected_attendant','claim_backdoor_realm_profile','claim_backdoor_attendants_pairing'],
      'lore_ids', array['lore_satono_selected_service','lore_okina_hidden_access'],
      'location_ids', array['backdoor_realm']
    ),
    0.84,
    now()
  ),
  (
    'chat_context_global_mai_backdoor',
    'gensokyo_main',
    'global',
    'mai',
    'backdoor_realm',
    null,
    'character_location_story',
    'Mai in the Backdoor Realm should feel like movement, rhythm, and execution turning hidden-stage authority into something kinetic.',
    jsonb_build_object(
      'claim_ids', array['claim_mai_backstage_executor','claim_backdoor_realm_profile','claim_backdoor_attendants_pairing'],
      'lore_ids', array['lore_mai_backstage_motion','lore_okina_hidden_access'],
      'location_ids', array['backdoor_realm']
    ),
    0.84,
    now()
  ),
  (
    'chat_context_global_sannyo_market_rest',
    'gensokyo_main',
    'global',
    'sannyo',
    'rainbow_dragon_cave',
    null,
    'character_location_story',
    'Sannyo should bring out the relaxed, smoky, half-resting side of market routes, where people trade because they linger first.',
    jsonb_build_object(
      'claim_ids', array['claim_sannyo_informal_merchant','claim_rainbow_dragon_cave_profile','claim_market_route_rest_stops'],
      'lore_ids', array['lore_sannyo_informal_market_rest','lore_market_route_rest_logic','lore_um_market_flow'],
      'location_ids', array['rainbow_dragon_cave','youkai_mountain_foot']
    ),
    0.84,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();
