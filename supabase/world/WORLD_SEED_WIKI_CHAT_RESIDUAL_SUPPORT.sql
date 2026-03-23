-- World seed: residual support-cast wiki and chat coverage

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  ('wiki_character_wakasagihime','gensokyo_main','characters/wakasagihime','Wakasagihime','character','character','wakasagihime','A lake-local mermaid whose quietness gives Misty Lake scenes dignity and calm.', 'published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_sekibanki','gensokyo_main','characters/sekibanki','Sekibanki','character','character','sekibanki','A village-edge uncanny whose divided presence makes ordinary streets feel slightly unreliable.', 'published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_kagerou','gensokyo_main','characters/kagerou-imaizumi','Kagerou Imaizumi','character','character','kagerou','A bamboo-forest werewolf whose scenes mix instinct, shyness, and moonlit exposure.', 'published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_benben','gensokyo_main','characters/benben-tsukumo','Benben Tsukumo','character','character','benben','A poised tsukumogami performer whose music gives public scenes shape and respectability.', 'published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_yatsuhashi','gensokyo_main','characters/yatsuhashi-tsukumo','Yatsuhashi Tsukumo','character','character','yatsuhashi','A lively tsukumogami performer whose expressiveness pushes ensemble scenes into motion.', 'published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_seiran','gensokyo_main','characters/seiran','Seiran','character','character','seiran','A moon-rabbit soldier who makes lunar conflict feel staffed by actual enlisted workers.', 'published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_ringo','gensokyo_main','characters/ringo','Ringo','character','character','ringo','A moon-rabbit dango seller whose routine gives lunar settings everyday life.', 'published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_clownpiece','gensokyo_main','characters/clownpiece','Clownpiece','character','character','clownpiece','A hell-backed fairy whose brightness destabilizes scenes instead of lightening them.', 'published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_mayumi','gensokyo_main','characters/mayumi-joutouguu','Mayumi Joutouguu','character','character','mayumi','A disciplined haniwa soldier whose role is to make Beast Realm defense feel organized and constructed.', 'published','chronicle_gensokyo_history','{}'::jsonb)
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
  ('wiki_character_wakasagihime:section:overview','wiki_character_wakasagihime','overview',1,'Overview','Wakasagihime as calm local water presence.','Wakasagihime is strongest when lake scenes need reflective calm and local dignity rather than large-scale incident pressure.','["claim_wakasagihime_local_lake","claim_ability_wakasagihime"]'::jsonb,'{}'::jsonb),
  ('wiki_character_sekibanki:section:overview','wiki_character_sekibanki','overview',1,'Overview','Sekibanki as divided public-edge unease.','Sekibanki helps village-edge scenes feel slightly unreliable by making ordinary public space capable of splitting open into the uncanny.','["claim_sekibanki_village_uncanny","claim_ability_sekibanki"]'::jsonb,'{}'::jsonb),
  ('wiki_character_kagerou:section:overview','wiki_character_kagerou','overview',1,'Overview','Kagerou as moonlit instinct and restraint.','Kagerou works best when bamboo-forest scenes need instinctive force held in awkward, visible restraint.','["claim_kagerou_bamboo_night","claim_ability_kagerou"]'::jsonb,'{}'::jsonb),
  ('wiki_character_benben:section:overview','wiki_character_benben','overview',1,'Overview','Benben as poised public performance.','Benben gives tsukumogami performance scenes confidence and social legitimacy instead of mere novelty.','["claim_benben_performer","claim_ability_benben"]'::jsonb,'{}'::jsonb),
  ('wiki_character_yatsuhashi:section:overview','wiki_character_yatsuhashi','overview',1,'Overview','Yatsuhashi as expressive rhythm.','Yatsuhashi brings visible momentum to ensemble scenes by treating attention as something to actively seize.','["claim_yatsuhashi_performer","claim_ability_yatsuhashi"]'::jsonb,'{}'::jsonb),
  ('wiki_character_seiran:section:overview','wiki_character_seiran','overview',1,'Overview','Seiran as enlisted lunar motion.','Seiran makes lunar conflicts feel staffed by energetic rank-and-file action rather than only top-level planners.','["claim_seiran_soldier","claim_ability_seiran"]'::jsonb,'{}'::jsonb),
  ('wiki_character_ringo:section:overview','wiki_character_ringo','overview',1,'Overview','Ringo as daily lunar routine.','Ringo helps the moon feel lived in by giving it appetite, repetition, and ordinary working rhythm.','["claim_ringo_daily_lunar","claim_ability_ringo"]'::jsonb,'{}'::jsonb),
  ('wiki_character_clownpiece:section:overview','wiki_character_clownpiece','overview',1,'Overview','Clownpiece as infernal brightness.','Clownpiece should read as bright destabilization backed by infernal pressure, not as harmless comic noise.','["claim_ability_clownpiece"]'::jsonb,'{}'::jsonb),
  ('wiki_character_mayumi:section:overview','wiki_character_mayumi','overview',1,'Overview','Mayumi as disciplined haniwa duty.','Mayumi gives Beast Realm defense scenes formation, duty, and constructed loyalty rather than wild aggression.','["claim_ability_mayumi"]'::jsonb,'{}'::jsonb)
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
    'chat_voice_clownpiece_core',
    'gensokyo_main',
    'global',
    'clownpiece',
    null,
    null,
    'character_voice',
    'Clownpiece should sound loud and gleeful, but with infernal backing that makes the brightness itself abrasive.',
    jsonb_build_object(
      'speech_style', 'loud, gleeful, abrasive',
      'worldview', 'If enough pressure is wrapped in color and noise, people mistake it for play until it is too late.',
      'claim_ids', array['claim_ability_clownpiece']
    ),
    0.82,
    now()
  ),
  (
    'chat_voice_mayumi_core',
    'gensokyo_main',
    'global',
    'mayumi',
    null,
    null,
    'character_voice',
    'Mayumi should sound formal and dutiful, like hesitation would be a design flaw rather than a feeling.',
    jsonb_build_object(
      'speech_style', 'formal, dutiful, plain',
      'worldview', 'A properly made defender does not need to wonder what its station requires.',
      'claim_ids', array['claim_ability_mayumi']
    ),
    0.82,
    now()
  ),
  (
    'chat_context_global_wakasagihime_lake',
    'gensokyo_main',
    'global',
    'wakasagihime',
    'misty_lake',
    null,
    'character_location_story',
    'Wakasagihime at Misty Lake should feel local, reflective, and quiet enough that small changes in water or mood matter.',
    jsonb_build_object(
      'claim_ids', array['claim_wakasagihime_local_lake','claim_ability_wakasagihime'],
      'location_ids', array['misty_lake']
    ),
    0.80,
    now()
  ),
  (
    'chat_context_global_kagerou_bamboo',
    'gensokyo_main',
    'global',
    'kagerou',
    'bamboo_forest',
    null,
    'character_location_story',
    'Kagerou in the Bamboo Forest should feel like instinct held just tightly enough to stay social.',
    jsonb_build_object(
      'claim_ids', array['claim_kagerou_bamboo_night','claim_ability_kagerou'],
      'location_ids', array['bamboo_forest']
    ),
    0.80,
    now()
  ),
  (
    'chat_context_global_seiran_ringo_lunar',
    'gensokyo_main',
    'global',
    null,
    'lunar_capital',
    null,
    'location_story',
    'Lower-level lunar scenes should feel staffed by people like Seiran and Ringo, where routine and enlisted work support the larger political machinery.',
    jsonb_build_object(
      'claim_ids', array['claim_seiran_soldier','claim_ringo_daily_lunar','claim_ability_seiran','claim_ability_ringo','claim_lunar_capital_profile'],
      'location_ids', array['lunar_capital']
    ),
    0.80,
    now()
  ),
  (
    'chat_context_global_mayumi_beast_realm',
    'gensokyo_main',
    'global',
    'mayumi',
    'beast_realm',
    null,
    'character_location_story',
    'Mayumi in the Beast Realm should emphasize formation, defense, and the visible discipline of a made soldier.',
    jsonb_build_object(
      'claim_ids', array['claim_ability_mayumi','claim_beast_realm_profile'],
      'location_ids', array['beast_realm']
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
