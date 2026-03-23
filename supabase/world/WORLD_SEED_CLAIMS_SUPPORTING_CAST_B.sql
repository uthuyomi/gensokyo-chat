-- World seed: second supporting-cast claims and lore

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_supporting_cast_underground','regional_texture','Underground Supporting Texture','The underground should feel social, layered, and staffed by more than only its largest names.',jsonb_build_object('focus','former_hell_and_old_capital'),'["supporting_cast","underground","texture"]'::jsonb,76),
  ('gensokyo_main','lore_supporting_cast_temple','regional_texture','Temple Supporting Texture','Temple life should include routine voices, not only doctrinal leaders and incident peaks.',jsonb_build_object('focus','myouren_temple_and_mausoleum'),'["supporting_cast","temple","texture"]'::jsonb,75),
  ('gensokyo_main','lore_supporting_cast_fairies','daily_life_texture','Fairy Daily-Life Texture','Fairies make shrine and village-adjacent life feel inhabited at a smaller comic scale.',jsonb_build_object('focus','fairy_daily_life'),'["supporting_cast","fairy","daily_life"]'::jsonb,74)
on conflict (world_id, id) do update
set category = excluded.category,
    title = excluded.title,
    summary = excluded.summary,
    details = excluded.details,
    tags = excluded.tags,
    priority = excluded.priority,
    updated_at = now();

insert into public.world_canon_claims (
  id, world_id, subject_type, subject_id, claim_type, summary, details, source_id, confidence, priority, tags
)
values
  ('claim_kisume_underground_approach','gensokyo_main','character','kisume','role','Kisume works best as a local underground approach-presence rather than a broad story architect.',jsonb_build_object('role','local_actor'),'src_subterranean_animism','official',62,'["kisume","sa","underground"]'::jsonb),
  ('claim_yamame_network_underground','gensokyo_main','character','yamame','role','Yamame makes underground scenes feel socially connected through gossip, illness talk, and familiarity.',jsonb_build_object('role','network_actor'),'src_subterranean_animism','official',68,'["yamame","sa","network"]'::jsonb),
  ('claim_parsee_threshold_pressure','gensokyo_main','character','parsee','role','Parsee is strongest in threshold scenes where crossing itself carries emotional pressure.',jsonb_build_object('role','threshold_actor'),'src_subterranean_animism','official',70,'["parsee","sa","bridge"]'::jsonb),
  ('claim_yuugi_old_capital_anchor','gensokyo_main','character','yuugi','role','Yuugi anchors the old capital through direct strength, convivial challenge, and oni prestige.',jsonb_build_object('role','power_anchor'),'src_subterranean_animism','official',72,'["yuugi","sa","oni"]'::jsonb),
  ('claim_kyouko_temple_daily_voice','gensokyo_main','character','kyouko','role','Kyouko gives Myouren Temple a cheerful everyday voice beneath its larger doctrine and politics.',jsonb_build_object('role','temple_support'),'src_td','official',66,'["kyouko","td","temple"]'::jsonb),
  ('claim_yoshika_mausoleum_retainer','gensokyo_main','character','yoshika','role','Yoshika is best treated as a visible retainer who gives the mausoleum faction material presence.',jsonb_build_object('role','retainer'),'src_td','official',69,'["yoshika","td","retainer"]'::jsonb),
  ('claim_shou_temple_authority','gensokyo_main','character','shou','role','Shou represents temple authority, treasure symbolism, and dutiful religious responsibility.',jsonb_build_object('role','religious_lead'),'src_ufo','official',72,'["shou","ufo","temple"]'::jsonb),
  ('claim_sunny_daily_fairy','gensokyo_main','character','sunny_milk','role','Sunny Milk belongs in shrine-side or village-edge daily mischief rather than serious incident command.',jsonb_build_object('role','daily_life_actor'),'src_osp','official',64,'["sunny_milk","fairy","daily_life"]'::jsonb),
  ('claim_luna_daily_fairy','gensokyo_main','character','luna_child','role','Luna Child contributes stealth, timing, and quiet mischief to recurring fairy daily-life scenes.',jsonb_build_object('role','daily_life_actor'),'src_osp','official',64,'["luna_child","fairy","daily_life"]'::jsonb),
  ('claim_star_daily_fairy','gensokyo_main','character','star_sapphire','role','Star Sapphire works as the perceptive edge of fairy-trio scenes, helping small-scale daily life feel observed.',jsonb_build_object('role','daily_life_actor'),'src_osp','official',64,'["star_sapphire","fairy","daily_life"]'::jsonb)
on conflict (id) do update
set subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    claim_type = excluded.claim_type,
    summary = excluded.summary,
    details = excluded.details,
    source_id = excluded.source_id,
    confidence = excluded.confidence,
    priority = excluded.priority,
    tags = excluded.tags,
    updated_at = now();
