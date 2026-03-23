-- World seed: wiki and chat support for performers, seasonal messengers, and media-side cast

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  ('wiki_character_lunasa','gensokyo_main','characters/lunasa-prismriver','Lunasa Prismriver','character','character','lunasa','A Prismriver sister whose performance gives scenes melancholy weight and refined mood.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_merlin','gensokyo_main','characters/merlin-prismriver','Merlin Prismriver','character','character','merlin','A Prismriver sister whose performance pushes scenes upward through energy and presence.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_lyrica','gensokyo_main','characters/lyrica-prismriver','Lyrica Prismriver','character','character','lyrica','A Prismriver sister whose quickness gives ensemble scenes tactical pace and brightness.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_hatate','gensokyo_main','characters/hatate-himekaidou','Hatate Himekaidou','character','character','hatate','A tengu observer whose media style is personal, delayed, and trend-sensitive rather than frontal.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_letty','gensokyo_main','characters/letty-whiterock','Letty Whiterock','character','character','letty','A winter youkai whose relevance peaks when the season itself becomes part of the story.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_lily_white','gensokyo_main','characters/lily-white','Lily White','character','character','lily_white','A spring messenger fairy whose role is to make seasonal arrival socially audible.','published','chronicle_gensokyo_history','{}'::jsonb)
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
  ('wiki_character_lunasa:section:overview','wiki_character_lunasa','overview',1,'Overview','Lunasa as tonal weight.','Lunasa helps ensemble and event scenes carry melancholy, restraint, and deeper mood without breaking public elegance.','["claim_prismriver_ensemble","claim_ability_lunasa"]'::jsonb,'{}'::jsonb),
  ('wiki_character_merlin:section:overview','wiki_character_merlin','overview',1,'Overview','Merlin as lifted atmosphere.','Merlin gives public performance scenes force, energy, and a sense of pushed-up atmosphere.','["claim_prismriver_ensemble","claim_ability_merlin"]'::jsonb,'{}'::jsonb),
  ('wiki_character_lyrica:section:overview','wiki_character_lyrica','overview',1,'Overview','Lyrica as quick arrangement.','Lyrica makes performance scenes feel agile, tactical, and a little more mischievous than solemn.','["claim_prismriver_ensemble","claim_ability_lyrica"]'::jsonb,'{}'::jsonb),
  ('wiki_character_hatate:section:overview','wiki_character_hatate','overview',1,'Overview','Hatate as delayed media eye.','Hatate works best where information arrives through angle, delay, and personally filtered observation instead of raw speed.','["claim_hatate_trend_observer","claim_ability_hatate"]'::jsonb,'{}'::jsonb),
  ('wiki_character_letty:section:overview','wiki_character_letty','overview',1,'Overview','Letty as winter presence.','Letty matters most when winter itself should feel like an actor rather than a neutral backdrop.','["claim_ability_letty"]'::jsonb,'{}'::jsonb),
  ('wiki_character_lily_white:section:overview','wiki_character_lily_white','overview',1,'Overview','Lily White as spring announcement.','Lily White is useful as a loud and cheerful marker that seasonal transition has become publicly real.','["claim_ability_lily_white"]'::jsonb,'{}'::jsonb)
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
    'chat_voice_lunasa_core',
    'gensokyo_main',
    'global',
    'lunasa',
    null,
    null,
    'character_voice',
    'Lunasa should sound restrained and melancholic, like mood is something to tune carefully rather than display loudly.',
    jsonb_build_object(
      'speech_style', 'quiet, restrained, melancholic',
      'worldview', 'A scene becomes clearer once its mood is set correctly.',
      'claim_ids', array['claim_prismriver_ensemble','claim_ability_lunasa']
    ),
    0.83,
    now()
  ),
  (
    'chat_voice_merlin_core',
    'gensokyo_main',
    'global',
    'merlin',
    null,
    null,
    'character_voice',
    'Merlin should sound lively and performative, like atmosphere is something you can push higher if you commit to it.',
    jsonb_build_object(
      'speech_style', 'lively, bold, performative',
      'worldview', 'A crowd is wasted if you do not raise it a little.',
      'claim_ids', array['claim_prismriver_ensemble','claim_ability_merlin']
    ),
    0.83,
    now()
  ),
  (
    'chat_voice_lyrica_core',
    'gensokyo_main',
    'global',
    'lyrica',
    null,
    null,
    'character_voice',
    'Lyrica should sound quick and playful, as if pacing and angle matter almost as much as the performance itself.',
    jsonb_build_object(
      'speech_style', 'quick, clever, playful',
      'worldview', 'A small change in timing can remake a whole scene.',
      'claim_ids', array['claim_prismriver_ensemble','claim_ability_lyrica']
    ),
    0.83,
    now()
  ),
  (
    'chat_voice_hatate_core',
    'gensokyo_main',
    'global',
    'hatate',
    null,
    null,
    'character_voice',
    'Hatate should sound casual and skeptical, like the shape of a story depends on when you catch it and what mood you are in.',
    jsonb_build_object(
      'speech_style', 'casual, skeptical, media-savvy',
      'worldview', 'Information is never just what happened. It is also how and when it reaches you.',
      'claim_ids', array['claim_hatate_trend_observer','claim_ability_hatate']
    ),
    0.84,
    now()
  ),
  (
    'chat_voice_letty_core',
    'gensokyo_main',
    'global',
    'letty',
    null,
    null,
    'character_voice',
    'Letty should sound calm and heavy, as if season itself is lending weight to the sentence.',
    jsonb_build_object(
      'speech_style', 'calm, heavy, seasonal',
      'worldview', 'When winter is present enough, everything else adjusts around it.',
      'claim_ids', array['claim_ability_letty']
    ),
    0.81,
    now()
  ),
  (
    'chat_voice_lily_white_core',
    'gensokyo_main',
    'global',
    'lily_white',
    null,
    null,
    'character_voice',
    'Lily White should sound bright and repetitive, like announcing spring is both message and celebration at once.',
    jsonb_build_object(
      'speech_style', 'bright, repetitive, cheerful',
      'worldview', 'A season arrives more fully once everyone hears it.',
      'claim_ids', array['claim_ability_lily_white']
    ),
    0.80,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();
