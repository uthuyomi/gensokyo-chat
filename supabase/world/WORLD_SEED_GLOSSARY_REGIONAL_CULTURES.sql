-- World seed: regional culture and atmosphere glossary

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_regional_old_capital','regional_culture','Old Capital Culture','The Old Capital should read as a sociable oni sphere where strength, drinking, and public challenge carry cultural legitimacy.',jsonb_build_object('location_id','old_capital'),'["region","old_capital","oni"]'::jsonb,79),
  ('gensokyo_main','lore_regional_former_hell','regional_culture','Former Hell Route Culture','Former Hell is not only a hazard zone. It is a layered passage network where small actors, thresholds, and local rumor matter.',jsonb_build_object('location_id','former_hell'),'["region","former_hell","routes"]'::jsonb,78),
  ('gensokyo_main','lore_regional_myouren_temple','regional_culture','Myouren Temple Daily Culture','Myouren Temple should feel like a lived religious institution with discipline, routine, and coexistence-minded public structure.',jsonb_build_object('location_id','myouren_temple'),'["region","myouren_temple","daily_life"]'::jsonb,80),
  ('gensokyo_main','lore_regional_night_village_edges','regional_culture','Village-Edge Night Culture','The edges of the Human Village at night should feel commercial, musical, and just dangerous enough to remain memorable.',jsonb_build_object('location_id','human_village'),'["region","night","village"]'::jsonb,77),
  ('gensokyo_main','lore_regional_shrine_fairy_life','regional_culture','Shrine Fairy Daily Culture','Hakurei Shrine should sometimes feel inhabited by repeated low-stakes fairy trouble rather than only by major incident traffic.',jsonb_build_object('location_id','hakurei_shrine'),'["region","fairy","shrine"]'::jsonb,76)
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
  ('claim_regional_old_capital_culture','gensokyo_main','location','old_capital','setting','The Old Capital should be framed as a sociable oni culture rather than only a dangerous underground landmark.',jsonb_build_object('culture','oni_public_life'),'src_subterranean_animism','official',78,'["old_capital","culture","oni"]'::jsonb),
  ('claim_regional_former_hell_routes','gensokyo_main','location','former_hell','setting','Former Hell should be treated as a route network with thresholds and local actors, not empty travel space.',jsonb_build_object('culture','layered_route_network'),'src_subterranean_animism','official',77,'["former_hell","routes","culture"]'::jsonb),
  ('claim_regional_myouren_daily_life','gensokyo_main','location','myouren_temple','setting','Myouren Temple has daily institutional life beyond major public declarations and incident peaks.',jsonb_build_object('culture','lived_religious_institution'),'src_ufo','official',79,'["myouren_temple","culture","daily_life"]'::jsonb),
  ('claim_regional_village_night_life','gensokyo_main','location','human_village','setting','The village edge at night should feel socially active through song, food, rumor, and small risk.',jsonb_build_object('culture','night_commerce'),'src_imperishable_night','official',75,'["human_village","night","culture"]'::jsonb),
  ('claim_regional_shrine_fairy_life','gensokyo_main','location','hakurei_shrine','setting','Hakurei Shrine should periodically read as a stage for recurring fairy-scale trouble and seasonal silliness.',jsonb_build_object('culture','fairy_daily_life'),'src_osp','official',74,'["hakurei_shrine","fairy","culture"]'::jsonb)
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
