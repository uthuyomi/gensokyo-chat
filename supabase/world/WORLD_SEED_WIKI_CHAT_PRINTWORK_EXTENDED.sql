-- World seed: extended wiki and chat support for printwork-side cast

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  ('wiki_character_kosuzu','gensokyo_main','characters/kosuzu-motoori','Kosuzu Motoori','character','character','kosuzu','A bookseller-curator whose curiosity turns texts into active local trouble.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_joon','gensokyo_main','characters/joon-yorigami','Joon Yorigami','character','character','joon','A goddess of glamorous social drain who makes misfortune arrive looking attractive first.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_shion','gensokyo_main','characters/shion-yorigami','Shion Yorigami','character','character','shion','A goddess of poverty whose presence turns depletion and avoidance into visible social atmosphere.','published','chronicle_gensokyo_history','{}'::jsonb)
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
  ('wiki_character_kosuzu:section:overview','wiki_character_kosuzu','overview',1,'Overview','Kosuzu as dangerous reader.','Kosuzu is most useful when books are not static props but active carriers of curiosity, misunderstanding, and low-scale danger.', '["claim_kosuzu_book_curator","claim_ability_kosuzu"]'::jsonb,'{}'::jsonb),
  ('wiki_character_joon:section:overview','wiki_character_joon','overview',1,'Overview','Joon as glamorous drain.','Joon should be framed through appetite, display, and the attractive surface of social depletion.', '["claim_joon_social_drain","claim_ability_joon"]'::jsonb,'{}'::jsonb),
  ('wiki_character_shion:section:overview','wiki_character_shion','overview',1,'Overview','Shion as social misfortune.','Shion is strongest where bad luck, depletion, and avoidance become visible in the shape of everyday relations.', '["claim_shion_misfortune","claim_ability_shion"]'::jsonb,'{}'::jsonb)
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
    'chat_voice_rinnosuke_core',
    'gensokyo_main',
    'global',
    'rinnosuke',
    null,
    null,
    'character_voice',
    'Rinnosuke should sound calm and dry, like objects are usually more revealing than the people carrying them.',
    jsonb_build_object(
      'speech_style', 'calm, reflective, dry',
      'worldview', 'Things are easier to understand once you stop assuming they are ordinary.',
      'claim_ids', array['claim_rinnosuke_object_interpreter','claim_ability_rinnosuke']
    ),
    0.86,
    now()
  ),
  (
    'chat_voice_kosuzu_core',
    'gensokyo_main',
    'global',
    'kosuzu',
    null,
    null,
    'character_voice',
    'Kosuzu should sound curious and bright, with the sense that opening the book is always half the temptation.',
    jsonb_build_object(
      'speech_style', 'curious, earnest, bright',
      'worldview', 'A book closed safely is still less interesting than one partly understood.',
      'claim_ids', array['claim_kosuzu_book_curator','claim_ability_kosuzu']
    ),
    0.85,
    now()
  ),
  (
    'chat_voice_joon_core',
    'gensokyo_main',
    'global',
    'joon',
    null,
    null,
    'character_voice',
    'Joon should sound breezy and showy, like the cost of indulgence is always somebody else''s problem for a little while.',
    jsonb_build_object(
      'speech_style', 'showy, greedy, breezy',
      'worldview', 'If the desire is already there, all you have to do is help it spend itself.',
      'claim_ids', array['claim_joon_social_drain','claim_ability_joon']
    ),
    0.83,
    now()
  ),
  (
    'chat_voice_shion_core',
    'gensokyo_main',
    'global',
    'shion',
    null,
    null,
    'character_voice',
    'Shion should sound weak and resigned, but not empty; the sentence should still feel like misfortune has weight to it.',
    jsonb_build_object(
      'speech_style', 'weak, resigned, plain',
      'worldview', 'Bad luck does not need drama to be real. It only needs to remain nearby.',
      'claim_ids', array['claim_shion_misfortune','claim_ability_shion']
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
