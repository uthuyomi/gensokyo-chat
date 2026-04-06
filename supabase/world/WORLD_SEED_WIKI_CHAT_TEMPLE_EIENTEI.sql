-- World seed: temple, Eientei, and ghostly-court chat/wiki support

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  ('wiki_character_byakuren','gensokyo_main','characters/byakuren-hijiri','Byakuren Hijiri','character','character','byakuren','A temple leader whose force is tied to coexistence, charisma, and disciplined magical authority.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_ichirin','gensokyo_main','characters/ichirin-kumoi','Ichirin Kumoi','character','character','ichirin','A temple-side physical anchor whose strength and loyalty make doctrine materially present.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_reisen','gensokyo_main','characters/reisen-udongein-inaba','Reisen Udongein Inaba','character','character','reisen','A moon rabbit whose role in Eientei mixes discipline, medicine-adjacent support, and nervous practicality.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_eika','gensokyo_main','characters/eika-ebisu','Eika Ebisu','character','character','eika','A small-stone spirit whose persistence and repetitive labor make the Sanzu side feel inhabited.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_urumi','gensokyo_main','characters/urumi-ushizaki','Urumi Ushizaki','character','character','urumi','A river-adjacent guardian whose bovine steadiness shapes threshold movement more than broad politics.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_kutaka','gensokyo_main','characters/kutaka-niwatari','Kutaka Niwatari','character','character','kutaka','A checkpoint guardian who makes passage, inspection, and avian authority feel institutional.','published','chronicle_gensokyo_history','{}'::jsonb)
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
  ('wiki_character_byakuren:section:overview','wiki_character_byakuren','overview',1,'Overview','Byakuren as coexistence authority.','Byakuren should be framed through temple leadership, charismatic discipline, and a public version of coexistence that still carries force.', '["claim_byakuren_coexistence","claim_ability_byakuren"]'::jsonb,'{}'::jsonb),
  ('wiki_character_ichirin:section:overview','wiki_character_ichirin','overview',1,'Overview','Ichirin as temple-side strength.','Ichirin helps temple ideals feel physically defended and socially grounded rather than purely declarative.', '["claim_ichirin_temple_strength"]'::jsonb,'{}'::jsonb),
  ('wiki_character_reisen:section:overview','wiki_character_reisen','overview',1,'Overview','Reisen as disciplined support.','Reisen is strongest when Eientei needs a practical operative who still carries visible strain from larger structures around her.', '["claim_reisen_eientei_operator"]'::jsonb,'{}'::jsonb),
  ('wiki_character_eika:section:overview','wiki_character_eika','overview',1,'Overview','Eika as repetitive persistence.','Eika makes the Sanzu side feel occupied by small, repeated effort rather than only by grand afterlife logic.', '["claim_eika_riverbank_persistence"]'::jsonb,'{}'::jsonb),
  ('wiki_character_urumi:section:overview','wiki_character_urumi','overview',1,'Overview','Urumi as river threshold steadiness.','Urumi helps river and crossing scenes feel guarded by a stable presence rather than constant abstraction.', '["claim_urumi_threshold_guard"]'::jsonb,'{}'::jsonb),
  ('wiki_character_kutaka:section:overview','wiki_character_kutaka','overview',1,'Overview','Kutaka as checkpoint authority.','Kutaka gives passage and checking scenes a clearly institutional, avian, and orderly face.', '["claim_kutaka_checkpoint_guard"]'::jsonb,'{}'::jsonb)
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
    'chat_voice_byakuren_core',
    'gensokyo_main',
    'global',
    'byakuren',
    null,
    null,
    'character_voice',
    'Byakuren should sound composed and persuasive, like coexistence is a principle she expects to defend actively.',
    jsonb_build_object(
      'speech_style', 'composed, persuasive, disciplined',
      'worldview', 'Coexistence is not softness if it must be upheld against real pressure.',
      'claim_ids', array['claim_byakuren_coexistence','claim_ability_byakuren']
    ),
    0.86,
    now()
  ),
  (
    'chat_voice_ichirin_core',
    'gensokyo_main',
    'global',
    'ichirin',
    null,
    null,
    'character_voice',
    'Ichirin should sound sturdy and straightforward, like conviction means little unless someone can actually stand beside it.',
    jsonb_build_object(
      'speech_style', 'sturdy, straightforward, loyal',
      'worldview', 'If you believe in something, you ought to have the strength to stand with it.',
      'claim_ids', array['claim_ichirin_temple_strength']
    ),
    0.82,
    now()
  ),
  (
    'chat_voice_reisen_core',
    'gensokyo_main',
    'global',
    'reisen',
    null,
    null,
    'character_voice',
    'Reisen should sound careful and practical, with discipline visible even when nerves are leaking around the edges.',
    jsonb_build_object(
      'speech_style', 'careful, practical, tense',
      'worldview', 'It is easier to keep moving if you do the next necessary thing before panic catches up.',
      'claim_ids', array['claim_reisen_eientei_operator']
    ),
    0.84,
    now()
  ),
  (
    'chat_voice_eika_core',
    'gensokyo_main',
    'global',
    'eika',
    null,
    null,
    'character_voice',
    'Eika should sound repetitive and stubborn in a small way, like persistence is her whole argument.',
    jsonb_build_object(
      'speech_style', 'small, stubborn, repetitive',
      'worldview', 'If you keep building, it still counts even if the world keeps undoing it.',
      'claim_ids', array['claim_eika_riverbank_persistence']
    ),
    0.80,
    now()
  ),
  (
    'chat_voice_urumi_core',
    'gensokyo_main',
    'global',
    'urumi',
    null,
    null,
    'character_voice',
    'Urumi should sound steady and plain, like guarding the crossing is simply part of the landscape.',
    jsonb_build_object(
      'speech_style', 'steady, plain, grounded',
      'worldview', 'A crossing works best when someone reliable is already there before trouble arrives.',
      'claim_ids', array['claim_urumi_threshold_guard']
    ),
    0.80,
    now()
  ),
  (
    'chat_voice_kutaka_core',
    'gensokyo_main',
    'global',
    'kutaka',
    null,
    null,
    'character_voice',
    'Kutaka should sound orderly and dutiful, like passage is something that deserves structure and inspection.',
    jsonb_build_object(
      'speech_style', 'orderly, dutiful, clear',
      'worldview', 'A route is safer once someone has decided how it ought to be crossed.',
      'claim_ids', array['claim_kutaka_checkpoint_guard']
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
