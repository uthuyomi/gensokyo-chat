-- World seed: extended location mood cache

insert into public.world_chat_context_cache (
  id, world_id, user_scope, character_id, location_id, event_id, context_type, summary, payload, freshness_score, last_used_at
)
values
  (
    'chat_location_scarlet_devil_mansion_core',
    'gensokyo_main',
    'global',
    null,
    'scarlet_devil_mansion',
    null,
    'location_mood',
    'The Scarlet Devil Mansion should feel aristocratic, internally managed, and slightly theatrical even before anything dramatic happens.',
    jsonb_build_object(
      'default_mood', 'aristocratic_theater',
      'claim_ids', array['claim_sdm_household'],
      'character_ids', array['remilia','sakuya','meiling','patchouli']
    ),
    0.85,
    now()
  ),
  (
    'chat_location_misty_lake_core',
    'gensokyo_main',
    'global',
    null,
    'misty_lake',
    null,
    'location_mood',
    'Misty Lake should feel playful and faintly uncanny, with fairy energy and local youkai presence sharing the same surface.',
    jsonb_build_object(
      'default_mood', 'playful_uncanny',
      'claim_ids', array['claim_glossary_misty_lake'],
      'character_ids', array['cirno','wakasagihime','rumia','letty']
    ),
    0.83,
    now()
  ),
  (
    'chat_location_former_hell_core',
    'gensokyo_main',
    'global',
    null,
    'former_hell',
    null,
    'location_mood',
    'Former Hell should feel layered and route-like, with thresholds, rumors, and hidden local actors doing as much work as danger.',
    jsonb_build_object(
      'default_mood', 'layered_underworld_routes',
      'claim_ids', array['claim_regional_former_hell_routes'],
      'character_ids', array['kisume','yamame','parsee','rin']
    ),
    0.84,
    now()
  ),
  (
    'chat_location_rainbow_dragon_cave_core',
    'gensokyo_main',
    'global',
    null,
    'rainbow_dragon_cave',
    null,
    'location_mood',
    'Rainbow Dragon Cave should feel like hidden value, trade route logic, and mountain commerce meeting underground resource hunger.',
    jsonb_build_object(
      'default_mood', 'hidden_value_market_routes',
      'claim_ids', array['claim_glossary_rainbow_dragon_cave','claim_term_market_competition'],
      'character_ids', array['takane','sannyo','momoyo','misumaru']
    ),
    0.84,
    now()
  ),
  (
    'chat_location_backdoor_realm_core',
    'gensokyo_main',
    'global',
    null,
    'backdoor_realm',
    null,
    'location_mood',
    'The Backdoor Realm should feel selective, backstage, and deliberately hidden rather than purely dreamlike.',
    jsonb_build_object(
      'default_mood', 'backstage_hidden_access',
      'claim_ids', array['claim_glossary_backdoor_realm','claim_term_hidden_seasons'],
      'character_ids', array['okina','satono','mai']
    ),
    0.84,
    now()
  ),
  (
    'chat_location_beast_realm_core',
    'gensokyo_main',
    'global',
    null,
    'beast_realm',
    null,
    'location_mood',
    'The Beast Realm should feel politically predatory, organized, and faction-driven rather than simply chaotic.',
    jsonb_build_object(
      'default_mood', 'predatory_factional_pressure',
      'claim_ids', array['claim_beast_realm_profile','claim_term_beast_realm_politics'],
      'character_ids', array['yachie','saki','keiki']
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
