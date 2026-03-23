-- World seed: chat context for late-mainline cast and locations

insert into public.world_chat_context_cache (
  id, world_id, user_scope, character_id, location_id, event_id, context_type, summary, payload, freshness_score, last_used_at
)
values
  (
    'chat_context_global_miko_mausoleum',
    'gensokyo_main',
    'global',
    'miko',
    'divine_spirit_mausoleum',
    null,
    'character_location_story',
    'Miko at the mausoleum should pull conversation toward authority, legitimacy, rhetoric, and old order made present again.',
    jsonb_build_object(
      'claim_ids', array['claim_miko_saint_leadership','claim_divine_spirit_mausoleum_profile'],
      'lore_ids', array['lore_miko_public_authority','lore_mausoleum_politics'],
      'location_ids', array['divine_spirit_mausoleum','senkai']
    ),
    0.91,
    now()
  ),
  (
    'chat_context_global_seija_castle',
    'gensokyo_main',
    'global',
    'seija',
    'shining_needle_castle',
    null,
    'character_location_story',
    'Seija around Shining Needle Castle should feel like inversion with intent: grievance, sabotage, and delighted disrespect for stable order.',
    jsonb_build_object(
      'claim_ids', array['claim_seija_rebel','claim_shining_needle_castle_profile'],
      'lore_ids', array['lore_ddc_reversal_logic','lore_seija_contrarian_pressure'],
      'location_ids', array['shining_needle_castle']
    ),
    0.88,
    now()
  ),
  (
    'chat_context_global_junko_lunar',
    'gensokyo_main',
    'global',
    'junko',
    'lunar_capital',
    null,
    'character_location_story',
    'Junko should enter chat context as concentrated hostility and purpose, not casual banter or soft daily drift.',
    jsonb_build_object(
      'claim_ids', array['claim_junko_pure_hostility','claim_lunar_capital_profile'],
      'lore_ids', array['lore_junko_high_impact','lore_lunar_distance'],
      'location_ids', array['lunar_capital']
    ),
    0.94,
    now()
  ),
  (
    'chat_context_global_okina_backdoor',
    'gensokyo_main',
    'global',
    'okina',
    'backdoor_realm',
    null,
    'character_location_story',
    'Okina belongs in conversations about hidden access, invitation, chosen empowerment, and off-stage orchestration.',
    jsonb_build_object(
      'claim_ids', array['claim_okina_hidden_doors','claim_backdoor_realm_profile'],
      'lore_ids', array['lore_okina_hidden_access'],
      'location_ids', array['backdoor_realm']
    ),
    0.89,
    now()
  ),
  (
    'chat_context_global_yachie_beast_realm',
    'gensokyo_main',
    'global',
    'yachie',
    'beast_realm',
    null,
    'character_location_story',
    'Yachie at the Beast Realm should read as leverage, measured threat, and political control under predatory conditions.',
    jsonb_build_object(
      'claim_ids', array['claim_yachie_faction_leader','claim_beast_realm_profile'],
      'lore_ids', array['lore_beast_realm_factions'],
      'location_ids', array['beast_realm']
    ),
    0.87,
    now()
  ),
  (
    'chat_context_global_takane_market',
    'gensokyo_main',
    'global',
    'takane',
    'rainbow_dragon_cave',
    null,
    'character_location_story',
    'Takane works best through negotiated exchange, mountain commerce, and practical opportunity rather than heroic confrontation.',
    jsonb_build_object(
      'claim_ids', array['claim_takane_broker','claim_rainbow_dragon_cave_profile'],
      'lore_ids', array['lore_takane_trade_frame','lore_um_market_flow'],
      'location_ids', array['rainbow_dragon_cave','youkai_mountain_foot']
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
