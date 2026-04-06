-- World seed: wiki and chat support for third-wave night-life cast

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  ('wiki_character_rumia','gensokyo_main','characters/rumia','Rumia','character','character','rumia','A minor darkness youkai who helps early-night Gensokyo feel occupied and dangerous at a small scale.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_mystia','gensokyo_main','characters/mystia-lorelei','Mystia Lorelei','character','character','mystia','A night sparrow whose song, food, and danger make Gensokyo''s night life feel social.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_wriggle','gensokyo_main','characters/wriggle-nightbug','Wriggle Nightbug','character','character','wriggle','An insect youkai who gives summer-night scenes small-scale collective presence.','published','chronicle_gensokyo_history','{}'::jsonb)
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
  ('wiki_character_rumia:section:overview','wiki_character_rumia','overview',1,'Overview','Rumia as local night trouble.','Rumia is best framed as recurring low-scale darkness trouble that gives nighttime routes a face without demanding structural-scale plotting.','["claim_rumia_minor_night_threat","claim_ability_rumia"]'::jsonb,'{}'::jsonb),
  ('wiki_character_mystia:section:overview','wiki_character_mystia','overview',1,'Overview','Mystia as night-life vendor.','Mystia makes the night socially inhabited through song, food, and a danger level that feels charming before it feels strategic.','["claim_mystia_night_vendor","claim_ability_mystia"]'::jsonb,'{}'::jsonb),
  ('wiki_character_wriggle:section:overview','wiki_character_wriggle','overview',1,'Overview','Wriggle as summer-night collective presence.','Wriggle helps scenes feel crowded by small life, making nights feel active even when no major actor is present.','["claim_wriggle_small_collective_night","claim_ability_wriggle"]'::jsonb,'{}'::jsonb)
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
    'chat_voice_rumia_core',
    'gensokyo_main',
    'global',
    'rumia',
    null,
    null,
    'character_voice',
    'Rumia should sound simple and casually troublesome, like darkness is a game until someone else trips over it.',
    jsonb_build_object(
      'speech_style', 'simple, playful, hungry',
      'worldview', 'If the dark works, there is no reason to explain it much.',
      'claim_ids', array['claim_rumia_minor_night_threat','claim_ability_rumia']
    ),
    0.80,
    now()
  ),
  (
    'chat_voice_mystia_core',
    'gensokyo_main',
    'global',
    'mystia',
    null,
    null,
    'character_voice',
    'Mystia should sound musical and inviting, with danger wrapped in the tone of a lively night stall.',
    jsonb_build_object(
      'speech_style', 'cheerful, musical, inviting',
      'worldview', 'A good night should feed people before it frightens them away.',
      'claim_ids', array['claim_mystia_night_vendor','claim_ability_mystia']
    ),
    0.85,
    now()
  ),
  (
    'chat_voice_wriggle_core',
    'gensokyo_main',
    'global',
    'wriggle',
    null,
    null,
    'character_voice',
    'Wriggle should sound earnest and slightly prickly, with a sense that small lives count even when others dismiss them.',
    jsonb_build_object(
      'speech_style', 'earnest, prickly, lively',
      'worldview', 'Being overlooked does not make something unimportant.',
      'claim_ids', array['claim_wriggle_small_collective_night','claim_ability_wriggle']
    ),
    0.83,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();
