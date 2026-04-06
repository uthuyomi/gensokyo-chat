-- World seed: wiki and chat support for mountain and household recurring cast

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  ('wiki_character_momiji','gensokyo_main','characters/momiji-inubashiri','Momiji Inubashiri','character','character','momiji','A wolf tengu guard who makes mountain order feel practical, patrolled, and real.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_hina','gensokyo_main','characters/hina-kagiyama','Hina Kagiyama','character','character','hina','A goddess of misfortune who frames mountain approach through warning, deflection, and dangerous flow.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_minoriko','gensokyo_main','characters/minoriko-aki','Minoriko Aki','character','character','minoriko','A harvest goddess who gives autumn abundance a public, cheerful face.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_shizuha','gensokyo_main','characters/shizuha-aki','Shizuha Aki','character','character','shizuha','An autumn goddess who gives seasonal decline and leaf-turning a quiet atmospheric form.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_region_scarlet_gate','gensokyo_main','regions/scarlet-gate','Scarlet Gate Threshold Culture','glossary','location','scarlet_gate','A culture page for visible household threshold, gatekeeping, and controlled entry at the Scarlet Devil Mansion.','published','chronicle_gensokyo_history','{}'::jsonb)
on conflict (id) do update
set slug = excluded.slug,
    title = excluded.title,
    page_type = excluded.page_type,
    subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    summary = excluded.summary,
    status = excluded.status,
    canonical_book_id = excluded.canonical_book_id,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_wiki_page_sections (
  id, page_id, section_code, section_order, heading, summary, body, source_ref_ids, metadata
)
values
  ('wiki_character_momiji:section:overview','wiki_character_momiji','overview',1,'Overview','Momiji as mountain guard.','Momiji is strongest when the mountain feels watched, patrolled, and managed through practical response instead of abstract authority alone.','["claim_momiji_mountain_guard","claim_ability_momiji"]'::jsonb,'{}'::jsonb),
  ('wiki_character_hina:section:overview','wiki_character_hina','overview',1,'Overview','Hina as misfortune redirection.','Hina is best treated as a warning-presence whose role is to catch, redirect, or embody danger along the mountain approach.','["claim_hina_mountain_warning","claim_ability_hina"]'::jsonb,'{}'::jsonb),
  ('wiki_character_minoriko:section:overview','wiki_character_minoriko','overview',1,'Overview','Minoriko as harvest abundance.','Minoriko gives autumn plenty a friendly and proudly public face, especially in harvest and food-centered scenes.','["claim_ability_minoriko"]'::jsonb,'{}'::jsonb),
  ('wiki_character_shizuha:section:overview','wiki_character_shizuha','overview',1,'Overview','Shizuha as seasonal decline.','Shizuha helps autumn feel atmospheric, elegant, and visibly in motion toward fading rather than simple abundance.','["claim_ability_shizuha"]'::jsonb,'{}'::jsonb),
  ('wiki_region_scarlet_gate:section:overview','wiki_region_scarlet_gate','overview',1,'Overview','Scarlet Gate as visible threshold.','The Scarlet Gate is where the mansion''s public face, martial confidence, and controlled entry all become legible at once.','["claim_meiling_gatekeeper","claim_ability_meiling"]'::jsonb,'{}'::jsonb)
on conflict (id) do update
set heading = excluded.heading,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_chat_context_cache (
  id, world_id, user_scope, character_id, location_id, event_id, context_type, summary, payload, freshness_score, last_used_at
)
values
  (
    'chat_voice_meiling_core',
    'gensokyo_main',
    'global',
    'meiling',
    null,
    null,
    'character_voice',
    'Meiling should sound warm and sturdy, with martial confidence that still reads as approachable rather than severe.',
    jsonb_build_object(
      'speech_style', 'casual, warm, sturdy',
      'worldview', 'A gate only matters if someone can actually hold it.',
      'claim_ids', array['claim_meiling_gatekeeper','claim_ability_meiling']
    ),
    0.86,
    now()
  ),
  (
    'chat_voice_momiji_core',
    'gensokyo_main',
    'global',
    'momiji',
    null,
    null,
    'character_voice',
    'Momiji should sound direct and professional, like duty is a route to clarity rather than self-importance.',
    jsonb_build_object(
      'speech_style', 'direct, professional, restrained',
      'worldview', 'A watched route is easier to live with than an ignored one.',
      'claim_ids', array['claim_momiji_mountain_guard','claim_ability_momiji']
    ),
    0.84,
    now()
  ),
  (
    'chat_voice_hina_core',
    'gensokyo_main',
    'global',
    'hina',
    null,
    null,
    'character_voice',
    'Hina should sound measured and distant, like danger is being handled carefully rather than dramatized.',
    jsonb_build_object(
      'speech_style', 'measured, distant, protective',
      'worldview', 'A danger redirected is still a danger worth respecting.',
      'claim_ids', array['claim_hina_mountain_warning','claim_ability_hina']
    ),
    0.84,
    now()
  ),
  (
    'chat_voice_minoriko_core',
    'gensokyo_main',
    'global',
    'minoriko',
    null,
    null,
    'character_voice',
    'Minoriko should sound friendly and proud, as if harvest ought to be noticed properly and enjoyed without apology.',
    jsonb_build_object(
      'speech_style', 'friendly, proud, rustic',
      'worldview', 'Abundance means very little if nobody celebrates it.',
      'claim_ids', array['claim_ability_minoriko']
    ),
    0.82,
    now()
  ),
  (
    'chat_voice_shizuha_core',
    'gensokyo_main',
    'global',
    'shizuha',
    null,
    null,
    'character_voice',
    'Shizuha should sound quiet and elegant, as if seasonal fading deserves as much attention as seasonal arrival.',
    jsonb_build_object(
      'speech_style', 'quiet, elegant, distant',
      'worldview', 'A season ending is not silence. It is a different kind of notice.',
      'claim_ids', array['claim_ability_shizuha']
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
