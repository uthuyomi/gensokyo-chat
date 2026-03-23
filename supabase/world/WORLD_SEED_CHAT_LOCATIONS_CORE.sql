-- World seed: core location mood and usage context

insert into public.world_chat_context_cache (
  id, world_id, user_scope, character_id, location_id, event_id, context_type, summary, payload, freshness_score, last_used_at
)
values
  (
    'chat_location_myouren_temple_core',
    'gensokyo_main',
    'global',
    null,
    'myouren_temple',
    null,
    'location_mood',
    'Myouren Temple should feel communal, disciplined, and publicly coexistence-minded rather than secluded or secretive.',
    jsonb_build_object(
      'default_mood', 'communal_order',
      'claim_ids', array['claim_glossary_myouren','claim_regional_myouren_daily_life'],
      'character_ids', array['byakuren','shou','nazrin','kyouko','murasa']
    ),
    0.86,
    now()
  ),
  (
    'chat_location_chireiden_core',
    'gensokyo_main',
    'global',
    null,
    'chireiden',
    null,
    'location_mood',
    'Chireiden should feel psychologically exposed, quiet, and difficult to emotionally hide inside.',
    jsonb_build_object(
      'default_mood', 'exposed_and_quiet',
      'claim_ids', array['claim_chireiden_setting'],
      'character_ids', array['satori','rin','utsuho','koishi']
    ),
    0.87,
    now()
  ),
  (
    'chat_location_divine_spirit_mausoleum_core',
    'gensokyo_main',
    'global',
    null,
    'divine_spirit_mausoleum',
    null,
    'location_mood',
    'The Divine Spirit Mausoleum should feel ceremonial, legitimacy-heavy, and rhetorically staged rather than domestic.',
    jsonb_build_object(
      'default_mood', 'ceremonial_authority',
      'claim_ids', array['claim_glossary_divine_spirit_mausoleum','claim_incident_divine_spirits'],
      'character_ids', array['miko','futo','tojiko','seiga','yoshika']
    ),
    0.85,
    now()
  ),
  (
    'chat_location_bamboo_forest_core',
    'gensokyo_main',
    'global',
    null,
    'bamboo_forest',
    null,
    'location_mood',
    'The Bamboo Forest should feel winding, evasive, and a little socially selective rather than openly public.',
    jsonb_build_object(
      'default_mood', 'winding_and_selective',
      'claim_ids', array['claim_eientei_secluded'],
      'character_ids', array['eirin','kaguya','reisen','tewi','kagerou']
    ),
    0.84,
    now()
  ),
  (
    'chat_location_eientei_core',
    'gensokyo_main',
    'global',
    null,
    'eientei',
    null,
    'location_mood',
    'Eientei should feel expert, secluded, and politely controlled, with access never quite as casual as it first seems.',
    jsonb_build_object(
      'default_mood', 'secluded_expertise',
      'claim_ids', array['claim_eientei_secluded'],
      'character_ids', array['eirin','kaguya','reisen','tewi']
    ),
    0.86,
    now()
  ),
  (
    'chat_location_kappa_workshop_core',
    'gensokyo_main',
    'global',
    null,
    'kappa_workshop',
    null,
    'location_mood',
    'The Kappa Workshop should feel improvised, practical, and full of half-finished usefulness rather than polished mystique.',
    jsonb_build_object(
      'default_mood', 'busy_practicality',
      'claim_ids', array['claim_glossary_kappa'],
      'character_ids', array['nitori']
    ),
    0.84,
    now()
  ),
  (
    'chat_location_suzunaan_core',
    'gensokyo_main',
    'global',
    null,
    'suzunaan',
    null,
    'location_mood',
    'Suzunaan should feel inviting and curious, with the constant possibility that reading has already become a small problem.',
    jsonb_build_object(
      'default_mood', 'curious_textual_risk',
      'claim_ids', array['claim_suzunaan_profile','claim_term_book_circulation'],
      'character_ids', array['kosuzu','akyuu']
    ),
    0.85,
    now()
  ),
  (
    'chat_location_kourindou_core',
    'gensokyo_main',
    'global',
    null,
    'kourindou',
    null,
    'location_mood',
    'Kourindou should feel cluttered, interpretive, and materially strange, with objects doing half the conversational work.',
    jsonb_build_object(
      'default_mood', 'curio_interpretation',
      'claim_ids', array['claim_kourindou_profile','claim_ability_rinnosuke'],
      'character_ids', array['rinnosuke']
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
