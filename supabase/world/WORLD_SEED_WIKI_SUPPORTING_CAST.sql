-- World seed: wiki pages for second-wave supporting cast

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  ('wiki_character_yamame','gensokyo_main','characters/yamame-kurodani','Yamame Kurodani','character','character','yamame','An underground spider youkai who gives hidden communities social texture and rumor flow.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_parsee','gensokyo_main','characters/parsee-mizuhashi','Parsee Mizuhashi','character','character','parsee','A bridge guardian whose scenes hinge on jealousy, crossings, and emotional pressure.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_yuugi','gensokyo_main','characters/yuugi-hoshiguma','Yuugi Hoshiguma','character','character','yuugi','An oni of the old capital who makes underground power feel social, convivial, and direct.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_kyouko','gensokyo_main','characters/kyouko-kasodani','Kyouko Kasodani','character','character','kyouko','A cheerful temple yamabiko who helps Myouren Temple feel lived in day to day.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_yoshika','gensokyo_main','characters/yoshika-miyako','Yoshika Miyako','character','character','yoshika','A mausoleum retainer who gives hidden political factions visible physical presence.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_shou','gensokyo_main','characters/shou-toramaru','Shou Toramaru','character','character','shou','A temple authority figure tied to Bishamonten imagery, treasure, and duty.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_three_fairies','gensokyo_main','characters/three-fairies-of-light','Three Fairies of Light','group','group','three_fairies_of_light','A recurring fairy trio that makes shrine-side and village-edge daily life feel lively and lightly troublesome.','published','chronicle_gensokyo_history','{}'::jsonb)
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
  ('wiki_character_yamame:section:overview','wiki_character_yamame','overview',1,'Overview','Yamame as underground social texture.','Yamame is valuable not just as a threat but as proof that the underground has rumor, familiarity, and recurring local society.','["claim_yamame_network_underground","claim_ability_yamame"]'::jsonb,'{}'::jsonb),
  ('wiki_character_parsee:section:overview','wiki_character_parsee','overview',1,'Overview','Parsee as threshold pressure.','Parsee belongs at crossings where passage itself carries resentment, observation, and emotional pressure.','["claim_parsee_threshold_pressure","claim_ability_parsee"]'::jsonb,'{}'::jsonb),
  ('wiki_character_yuugi:section:overview','wiki_character_yuugi','overview',1,'Overview','Yuugi as old-capital power anchor.','Yuugi makes oni power feel sociable and public rather than distant or abstract.','["claim_yuugi_old_capital_anchor","claim_ability_yuugi"]'::jsonb,'{}'::jsonb),
  ('wiki_character_kyouko:section:overview','wiki_character_kyouko','overview',1,'Overview','Kyouko as temple routine voice.','Kyouko helps temple life feel routine, cheerful, and audible beneath larger ideological conflict.','["claim_kyouko_temple_daily_voice","claim_ability_kyouko"]'::jsonb,'{}'::jsonb),
  ('wiki_character_yoshika:section:overview','wiki_character_yoshika','overview',1,'Overview','Yoshika as visible retainer.','Yoshika gives hidden mausoleum politics a body that can carry orders, force, and presence into the scene.','["claim_yoshika_mausoleum_retainer","claim_ability_yoshika"]'::jsonb,'{}'::jsonb),
  ('wiki_character_shou:section:overview','wiki_character_shou','overview',1,'Overview','Shou as temple authority.','Shou is a major support pillar for temple authority and religious symbolism even when she is not the narrative center.','["claim_shou_temple_authority","claim_ability_shou"]'::jsonb,'{}'::jsonb),
  ('wiki_character_three_fairies:section:overview','wiki_character_three_fairies','overview',1,'Overview','The fairy trio as daily-life engine.','Sunny Milk, Luna Child, and Star Sapphire are most useful together as a recurring small-scale engine for mischief, observation, and ordinary atmosphere.','["claim_sunny_daily_fairy","claim_luna_daily_fairy","claim_star_daily_fairy"]'::jsonb,'{}'::jsonb)
on conflict (id) do update
set heading = excluded.heading,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();
