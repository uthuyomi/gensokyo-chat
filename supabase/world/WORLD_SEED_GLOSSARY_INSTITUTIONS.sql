-- World seed: institutional and world-rule glossary lore

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_glossary_hakurei','institution','Hakurei Shrine Institution','The Hakurei Shrine is both a sacred site and a public balancing institution within Gensokyo.',jsonb_build_object('institution','hakurei_shrine'),'["glossary","institution","hakurei"]'::jsonb,90),
  ('gensokyo_main','lore_glossary_moriya','institution','Moriya Shrine Institution','Moriya Shrine represents proactive faith gathering, mountain-side authority, and outside-influenced strategic expansion.',jsonb_build_object('institution','moriya_shrine'),'["glossary","institution","moriya"]'::jsonb,84),
  ('gensokyo_main','lore_glossary_myouren','institution','Myouren Temple Institution','Myouren Temple operates as a coexistence-oriented religious institution with broad community reach.',jsonb_build_object('institution','myouren_temple'),'["glossary","institution","myouren"]'::jsonb,83),
  ('gensokyo_main','lore_glossary_eientei','institution','Eientei Household Institution','Eientei is a secluded expert household combining medicine, lunar history, and selective openness.',jsonb_build_object('institution','eientei'),'["glossary","institution","eientei"]'::jsonb,84),
  ('gensokyo_main','lore_glossary_sdm','institution','Scarlet Devil Mansion Household','The Scarlet Devil Mansion should be treated as a high-profile household with internal hierarchy, symbolic power, and public edge management.',jsonb_build_object('institution','scarlet_devil_mansion'),'["glossary","institution","sdm"]'::jsonb,85),
  ('gensokyo_main','lore_glossary_yakumo','institution','Yakumo Household Structure','The Yakumo sphere represents boundary-level intervention supported by shikigami administration and selective visibility.',jsonb_build_object('institution','yakumo_household'),'["glossary","institution","yakumo"]'::jsonb,80),
  ('gensokyo_main','lore_glossary_spell_cards','world_rule','Spell Card Rule Glossary','Spell card culture ritualizes conflict and keeps escalation socially legible rather than permanently catastrophic.',jsonb_build_object('rule','spell_cards'),'["glossary","world_rule","spell_cards"]'::jsonb,94),
  ('gensokyo_main','lore_glossary_incidents','world_rule','Incident Glossary','Incidents are recurring public disturbances that become legible through response, rumor, and historical memory.',jsonb_build_object('rule','incidents'),'["glossary","world_rule","incidents"]'::jsonb,91),
  ('gensokyo_main','lore_glossary_boundaries','world_rule','Boundary Glossary','Boundaries in Gensokyo are spatial, social, symbolic, and often personified through specific high-impact actors.',jsonb_build_object('rule','boundaries'),'["glossary","world_rule","boundaries"]'::jsonb,88),
  ('gensokyo_main','lore_glossary_human_village','institution','Human Village Public Sphere','The Human Village is the main public sphere of human life, rumor circulation, and social memory inside Gensokyo.',jsonb_build_object('institution','human_village'),'["glossary","institution","village"]'::jsonb,90)
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
  ('claim_glossary_hakurei','gensokyo_main','institution','hakurei_shrine','glossary','Hakurei Shrine is both sacred ground and a public balancing institution repeatedly tied to incident legibility.',jsonb_build_object('linked_characters',array['reimu','aunn','kasen']),'src_sopm','official',90,'["glossary","hakurei","institution"]'::jsonb),
  ('claim_glossary_moriya','gensokyo_main','institution','moriya_shrine','glossary','Moriya Shrine should be understood as proactive, strategic, and institutionally expansion-minded.',jsonb_build_object('linked_characters',array['sanae','kanako','suwako']),'src_mofa','official',84,'["glossary","moriya","institution"]'::jsonb),
  ('claim_glossary_myouren','gensokyo_main','institution','myouren_temple','glossary','Myouren Temple is a community-scale coexistence institution rather than a single-issue religious backdrop.',jsonb_build_object('linked_characters',array['byakuren','nazrin','ichirin','murasa']),'src_ufo','official',83,'["glossary","myouren","institution"]'::jsonb),
  ('claim_glossary_eientei','gensokyo_main','institution','eientei','glossary','Eientei is a secluded but highly consequential household of medicine, lunar history, and controlled access.',jsonb_build_object('linked_characters',array['eirin','kaguya','reisen','tewi']),'src_imperishable_night','official',85,'["glossary","eientei","institution"]'::jsonb),
  ('claim_glossary_sdm','gensokyo_main','institution','scarlet_devil_mansion','glossary','The Scarlet Devil Mansion is a symbolic household with clear internal hierarchy and public-facing threshold management.',jsonb_build_object('linked_characters',array['remilia','sakuya','meiling','patchouli','flandre']),'src_eosd','official',86,'["glossary","sdm","institution"]'::jsonb),
  ('claim_glossary_yakumo','gensokyo_main','institution','yakumo_household','glossary','The Yakumo sphere is best understood as boundary-level intervention supported by shikigami order and selective visibility.',jsonb_build_object('linked_characters',array['yukari','ran','chen']),'src_pcb','official',80,'["glossary","yakumo","institution"]'::jsonb),
  ('claim_glossary_spell_cards','gensokyo_main','world','gensokyo_main','glossary','Spell card rules ritualize conflict and preserve continuity by constraining escalation into recognizable form.',jsonb_build_object('linked_rule','spell_cards'),'src_sopm','official',95,'["glossary","spell_cards","world_rule"]'::jsonb),
  ('claim_glossary_incidents','gensokyo_main','world','gensokyo_main','glossary','Incidents are recurring disturbances that become public through rumor, response, and later record.',jsonb_build_object('linked_rule','incidents'),'src_sixty_years','official',91,'["glossary","incidents","world_rule"]'::jsonb),
  ('claim_glossary_boundaries','gensokyo_main','world','gensokyo_main','glossary','Boundaries should be understood as one of the structural grammars of Gensokyo rather than mere scenery.',jsonb_build_object('linked_rule','boundaries'),'src_pcb','official',88,'["glossary","boundaries","world_rule"]'::jsonb),
  ('claim_glossary_human_village','gensokyo_main','institution','human_village','glossary','The Human Village is the chief public sphere of human memory, trade, rumor, and ordinary social life in Gensokyo.',jsonb_build_object('linked_characters',array['keine','akyuu','kosuzu']),'src_fs','official',90,'["glossary","village","institution"]'::jsonb)
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
