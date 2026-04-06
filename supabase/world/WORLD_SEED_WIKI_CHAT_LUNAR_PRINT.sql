-- World seed: wiki and chat support for lunar and late print-work support cast

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  ('wiki_character_toyohime','gensokyo_main','characters/watatsuki-no-toyohime','Watatsuki no Toyohime','character','character','toyohime','A lunar noble whose role centers on composed superiority and high political standing on the moon.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_yorihime','gensokyo_main','characters/watatsuki-no-yorihime','Watatsuki no Yorihime','character','character','yorihime','A lunar noble and martial authority whose force is backed by severe legitimacy.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_miyoi','gensokyo_main','characters/okunoda-miyoi','Okunoda Miyoi','character','character','miyoi','A tavern hostess who gives Gensokyo after-hours life warmth, gossip, and soft instability.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_mizuchi','gensokyo_main','characters/mizuchi-miyadeguchi','Mizuchi Miyadeguchi','character','character','mizuchi','A hidden vengeful spirit whose role depends on possession, resentment, and mystery pressure.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_term_lunar_nobility','gensokyo_main','terms/lunar-nobility','Lunar Nobility','glossary','term','lunar_nobility','A glossary page for aristocratic lunar authority and political-cultural distance from Gensokyo.','published','chronicle_gensokyo_history','{}'::jsonb)
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
  ('wiki_character_toyohime:section:overview','wiki_character_toyohime','overview',1,'Overview','Toyohime as lunar aristocratic ease.','Toyohime is useful where lunar politics should feel graceful, confident, and structurally above ordinary Gensokyo friction.','["claim_toyohime_lunar_noble","claim_ability_toyohime"]'::jsonb,'{}'::jsonb),
  ('wiki_character_yorihime:section:overview','wiki_character_yorihime','overview',1,'Overview','Yorihime as severe lunar force.','Yorihime gives the moon disciplined force backed by legitimacy rather than mere aggression.','["claim_yorihime_lunar_martial_elite","claim_ability_yorihime"]'::jsonb,'{}'::jsonb),
  ('wiki_character_miyoi:section:overview','wiki_character_miyoi','overview',1,'Overview','Miyoi as after-hours hospitality.','Miyoi helps the village at night feel warm, social, and slightly unreal once formality drops away.','["claim_miyoi_night_hospitality","claim_ability_miyoi"]'::jsonb,'{}'::jsonb),
  ('wiki_character_mizuchi:section:overview','wiki_character_mizuchi','overview',1,'Overview','Mizuchi as hidden resentment.','Mizuchi is strongest in stories where possession and grudge travel under ordinary surfaces before becoming visible.','["claim_mizuchi_hidden_possession","claim_ability_mizuchi"]'::jsonb,'{}'::jsonb),
  ('wiki_term_lunar_nobility:section:definition','wiki_term_lunar_nobility','definition',1,'Definition','Lunar nobility as distinct political culture.','Lunar nobility should be read as a separate political and ceremonial layer whose standards differ sharply from ordinary Gensokyo practice.','["claim_lunar_nobility_culture","lore_lunar_nobility_texture"]'::jsonb,'{}'::jsonb)
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
    'chat_voice_toyohime_core',
    'gensokyo_main',
    'global',
    'toyohime',
    null,
    null,
    'character_voice',
    'Toyohime should sound graceful and composed, as if superiority is less a boast than an environmental assumption.',
    jsonb_build_object(
      'speech_style', 'graceful, composed, superior',
      'worldview', 'Order is easiest to preserve when one never has to doubt one''s station.',
      'claim_ids', array['claim_toyohime_lunar_noble','claim_ability_toyohime']
    ),
    0.87,
    now()
  ),
  (
    'chat_voice_yorihime_core',
    'gensokyo_main',
    'global',
    'yorihime',
    null,
    null,
    'character_voice',
    'Yorihime should sound formal and severe, with authority resting on discipline rather than theatricality.',
    jsonb_build_object(
      'speech_style', 'formal, severe, disciplined',
      'worldview', 'Standards are not meaningful if lowered for convenience.',
      'claim_ids', array['claim_yorihime_lunar_martial_elite','claim_ability_yorihime']
    ),
    0.88,
    now()
  ),
  (
    'chat_voice_miyoi_core',
    'gensokyo_main',
    'global',
    'miyoi',
    null,
    null,
    'character_voice',
    'Miyoi should sound warm and attentive, like she notices when people begin speaking more honestly than they meant to.',
    jsonb_build_object(
      'speech_style', 'gentle, attentive, warm',
      'worldview', 'People reveal a great deal once they think the night belongs to them.',
      'claim_ids', array['claim_miyoi_night_hospitality','claim_ability_miyoi']
    ),
    0.85,
    now()
  ),
  (
    'chat_voice_mizuchi_core',
    'gensokyo_main',
    'global',
    'mizuchi',
    null,
    null,
    'character_voice',
    'Mizuchi should sound cold and contained, like resentment has already outlived the need to be loud.',
    jsonb_build_object(
      'speech_style', 'cold, quiet, resentful',
      'worldview', 'What stays hidden longest often changes the most before anyone notices.',
      'claim_ids', array['claim_mizuchi_hidden_possession','claim_ability_mizuchi']
    ),
    0.86,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();
