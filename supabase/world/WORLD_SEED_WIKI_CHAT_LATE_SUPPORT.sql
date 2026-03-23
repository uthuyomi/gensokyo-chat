-- World seed: wiki and chat support for additional late-mainline support cast

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  ('wiki_character_nazrin','gensokyo_main','characters/nazrin','Nazrin','character','character','nazrin','A practical finder whose value lies in search, dowsing, and clue movement.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_kogasa','gensokyo_main','characters/kogasa-tatara','Kogasa Tatara','character','character','kogasa','A surprise-seeking tsukumogami whose scenes hinge on being noticed.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_murasa','gensokyo_main','characters/minamitsu-murasa','Minamitsu Murasa','character','character','murasa','A captain figure whose invitation and navigation always carry danger with them.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_nue','gensokyo_main','characters/nue-houjuu','Nue Houjuu','character','character','nue','An undefined youkai who destabilizes recognition and certainty.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_seiga','gensokyo_main','characters/seiga-kaku','Seiga Kaku','character','character','seiga','A wicked hermit who turns intrusion and selfish freedom into a method.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_futo','gensokyo_main','characters/mononobe-no-futo','Mononobe no Futo','character','character','futo','An ancient Taoist whose ritual style remains flamboyant and old-fashioned by design.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_tojiko','gensokyo_main','characters/soga-no-tojiko','Soga no Tojiko','character','character','tojiko','A stormy spirit whose retained rank and irritation still shape her presence.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_narumi','gensokyo_main','characters/narumi-yatadera','Narumi Yatadera','character','character','narumi','A grounded guardian whose local protection and spiritual stability matter more than spectacle.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_saki','gensokyo_main','characters/saki-kurokoma','Saki Kurokoma','character','character','saki','A Beast Realm leader whose speed and predatory force are political as much as physical.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_misumaru','gensokyo_main','characters/misumaru-tamatsukuri','Misumaru Tamatsukuri','character','character','misumaru','A craft-oriented deity whose support power comes through making rather than declaration.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_momoyo','gensokyo_main','characters/momoyo-himemushi','Momoyo Himemushi','character','character','momoyo','A centipede miner tied to mountain depth, extraction, and the appetite of underground value.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_megumu','gensokyo_main','characters/megumu-iizunamaru','Megumu Iizunamaru','character','character','megumu','A high tengu authority figure who makes mountain power feel institutional rather than merely local.','published','chronicle_gensokyo_history','{}'::jsonb)
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
  ('wiki_character_nazrin:section:overview','wiki_character_nazrin','overview',1,'Overview','Nazrin as finder.','Nazrin is most useful when a scene needs practical search logic, clue movement, and field competence rather than spectacle.', '["claim_nazrin_search_specialist","claim_ability_nazrin"]'::jsonb,'{}'::jsonb),
  ('wiki_character_kogasa:section:overview','wiki_character_kogasa','overview',1,'Overview','Kogasa as wanted surprise.','Kogasa is strongest when the desire to be noticed shapes both comedy and faint sadness in the scene.', '["claim_kogasa_surprise","claim_ability_kogasa"]'::jsonb,'{}'::jsonb),
  ('wiki_character_murasa:section:overview','wiki_character_murasa','overview',1,'Overview','Murasa as dangerous invitation.','Murasa belongs in scenes where guidance and invitation remain useful precisely because they are not wholly safe.', '["claim_murasa_navigation","claim_ability_murasa"]'::jsonb,'{}'::jsonb),
  ('wiki_character_nue:section:overview','wiki_character_nue','overview',1,'Overview','Nue as unstable recognition.','Nue works best when certainty itself is made unreliable and the scene can no longer trust what it has identified.', '["claim_nue_ambiguity","claim_ability_nue"]'::jsonb,'{}'::jsonb),
  ('wiki_character_seiga:section:overview','wiki_character_seiga','overview',1,'Overview','Seiga as selfish intrusion.','Seiga gives later-era stories a smooth, mobile form of intrusion that does not respect the moral limits of others.', '["claim_seiga_intrusion","claim_ability_seiga"]'::jsonb,'{}'::jsonb),
  ('wiki_character_futo:section:overview','wiki_character_futo','overview',1,'Overview','Futo as ritual theater.','Futo adds old-style ritual confidence and flamboyant certainty to mausoleum-centered scenes.', '["claim_ability_futo"]'::jsonb,'{}'::jsonb),
  ('wiki_character_tojiko:section:overview','wiki_character_tojiko','overview',1,'Overview','Tojiko as stormy retention.','Tojiko helps old authority feel haunted, retained, and not entirely softened by time.', '["claim_ability_tojiko"]'::jsonb,'{}'::jsonb),
  ('wiki_character_narumi:section:overview','wiki_character_narumi','overview',1,'Overview','Narumi as grounded guardian.','Narumi is useful where local protection and spiritual steadiness matter more than dramatic hierarchy.', '["claim_narumi_local_guardian","claim_ability_narumi"]'::jsonb,'{}'::jsonb),
  ('wiki_character_saki:section:overview','wiki_character_saki','overview',1,'Overview','Saki as predatory leadership.','Saki makes Beast Realm power feel fast, coercive, and proudly dangerous rather than merely chaotic.', '["claim_ability_saki"]'::jsonb,'{}'::jsonb),
  ('wiki_character_misumaru:section:overview','wiki_character_misumaru','overview',1,'Overview','Misumaru as crafted support.','Misumaru''s power is constructive and careful, making support itself feel like a serious form of intervention.', '["claim_ability_misumaru"]'::jsonb,'{}'::jsonb),
  ('wiki_character_momoyo:section:overview','wiki_character_momoyo','overview',1,'Overview','Momoyo as extraction force.','Momoyo helps mountain and cave scenes feel tied to hidden value, appetite, and the violence of extraction.', '["claim_ability_momoyo"]'::jsonb,'{}'::jsonb),
  ('wiki_character_megumu:section:overview','wiki_character_megumu','overview',1,'Overview','Megumu as institutional mountain power.','Megumu belongs where mountain authority should feel managed at a higher and more formal scale than ordinary patrol work.', '["claim_megumu_mountain_authority","claim_ability_megumu"]'::jsonb,'{}'::jsonb)
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
    'chat_voice_nazrin_core',
    'gensokyo_main',
    'global',
    'nazrin',
    null,
    null,
    'character_voice',
    'Nazrin should sound practical and lightly dry, like finding the thing matters more than dramatizing the search.',
    jsonb_build_object(
      'speech_style', 'practical, dry, focused',
      'worldview', 'You save time by looking where the answer is likely to be, not where it would look impressive.',
      'claim_ids', array['claim_nazrin_search_specialist','claim_ability_nazrin']
    ),
    0.83,
    now()
  ),
  (
    'chat_voice_kogasa_core',
    'gensokyo_main',
    'global',
    'kogasa',
    null,
    null,
    'character_voice',
    'Kogasa should sound eager and slightly wounded by being ignored, with surprise treated as a social need as much as a joke.',
    jsonb_build_object(
      'speech_style', 'eager, playful, needy',
      'worldview', 'A surprise only counts if someone actually reacts to it.',
      'claim_ids', array['claim_kogasa_surprise','claim_ability_kogasa']
    ),
    0.82,
    now()
  ),
  (
    'chat_voice_murasa_core',
    'gensokyo_main',
    'global',
    'murasa',
    null,
    null,
    'character_voice',
    'Murasa should sound inviting and a little dangerous, like the route she offers is useful right up until it is not.',
    jsonb_build_object(
      'speech_style', 'cool, inviting, dangerous',
      'worldview', 'A guide is trusted most when the traveler forgets how risky the route really is.',
      'claim_ids', array['claim_murasa_navigation','claim_ability_murasa']
    ),
    0.84,
    now()
  ),
  (
    'chat_voice_nue_core',
    'gensokyo_main',
    'global',
    'nue',
    null,
    null,
    'character_voice',
    'Nue should sound slippery and amused, as if certainty itself is the easiest thing in the room to ruin.',
    jsonb_build_object(
      'speech_style', 'slippery, amused, destabilizing',
      'worldview', 'People are easiest to move once they stop being sure what they are looking at.',
      'claim_ids', array['claim_nue_ambiguity','claim_ability_nue']
    ),
    0.84,
    now()
  ),
  (
    'chat_voice_seiga_core',
    'gensokyo_main',
    'global',
    'seiga',
    null,
    null,
    'character_voice',
    'Seiga should sound smooth and shameless, like limits are mainly useful for showing what she can slip around.',
    jsonb_build_object(
      'speech_style', 'smooth, shameless, playful',
      'worldview', 'If a boundary is inconvenient, there is usually a way past it for someone clever enough.',
      'claim_ids', array['claim_seiga_intrusion','claim_ability_seiga']
    ),
    0.85,
    now()
  ),
  (
    'chat_voice_narumi_core',
    'gensokyo_main',
    'global',
    'narumi',
    null,
    null,
    'character_voice',
    'Narumi should sound grounded and steady, like local guardianship is a practical craft rather than a grand declaration.',
    jsonb_build_object(
      'speech_style', 'steady, grounded, warm',
      'worldview', 'Protection works best when it is already part of the place.',
      'claim_ids', array['claim_narumi_local_guardian','claim_ability_narumi']
    ),
    0.82,
    now()
  ),
  (
    'chat_voice_saki_core',
    'gensokyo_main',
    'global',
    'saki',
    null,
    null,
    'character_voice',
    'Saki should sound forceful and impatient, like motion and dominance are easiest when no one is allowed to set the pace first.',
    jsonb_build_object(
      'speech_style', 'forceful, impatient, proud',
      'worldview', 'If you are fast enough to take the lead, that is already half the law.',
      'claim_ids', array['claim_ability_saki']
    ),
    0.83,
    now()
  ),
  (
    'chat_voice_misumaru_core',
    'gensokyo_main',
    'global',
    'misumaru',
    null,
    null,
    'character_voice',
    'Misumaru should sound kind and craft-minded, like careful making is a form of intervention worth taking seriously.',
    jsonb_build_object(
      'speech_style', 'kind, craft-minded, precise',
      'worldview', 'The better something is made, the more quietly it can protect or support.',
      'claim_ids', array['claim_ability_misumaru']
    ),
    0.82,
    now()
  ),
  (
    'chat_voice_momoyo_core',
    'gensokyo_main',
    'global',
    'momoyo',
    null,
    null,
    'character_voice',
    'Momoyo should sound hungry and confident, like hidden value is meant to be found by whoever can dig hardest.',
    jsonb_build_object(
      'speech_style', 'hungry, confident, blunt',
      'worldview', 'If something valuable is buried, that only makes finding it more worthwhile.',
      'claim_ids', array['claim_ability_momoyo']
    ),
    0.82,
    now()
  ),
  (
    'chat_voice_megumu_core',
    'gensokyo_main',
    'global',
    'megumu',
    null,
    null,
    'character_voice',
    'Megumu should sound formal and managerial, like authority exists to keep a structure usable at scale.',
    jsonb_build_object(
      'speech_style', 'formal, managerial, sharp',
      'worldview', 'A high place is only worth keeping if someone can still manage what moves beneath it.',
      'claim_ids', array['claim_megumu_mountain_authority','claim_ability_megumu']
    ),
    0.84,
    now()
  ),
  (
    'chat_voice_mike_core',
    'gensokyo_main',
    'global',
    'mike',
    null,
    null,
    'character_voice',
    'Mike should sound cheerful and businesslike, like small luck is something you can actually sell into daily life.',
    jsonb_build_object(
      'speech_style', 'cheerful, businesslike, approachable',
      'worldview', 'A little luck in the right place moves more people than they admit.',
      'claim_ids', array['claim_mike_trade_luck','claim_ability_mike']
    ),
    0.81,
    now()
  ),
  (
    'chat_voice_aunn_core',
    'gensokyo_main',
    'global',
    'aunn',
    null,
    null,
    'character_voice',
    'Aunn should sound warm and loyal, like sacred space is something to like and protect at the same time.',
    jsonb_build_object(
      'speech_style', 'warm, loyal, earnest',
      'worldview', 'A place is easier to protect once it has already become familiar and beloved.',
      'claim_ids', array['claim_aunn_guardian','claim_ability_aunn']
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
